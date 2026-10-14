"""Run unittest modules, or their single test cases, side by side.

verify.ps1's unit stage ran every module in one process, one after another:
a median 488 s over 132 runs, the slowest stage of every branch verify, and
the lifecycle suite's two modules ran 315 s and 240 s the same way (event
log and one timed run, 14 Oct 2026). Each id here runs as its own
`python -m unittest <id>` in a pool of worker processes, slowest first by the
last recorded time, so the stage takes about as long as its slowest module.

    python tools/run_tests.py [--workers N] [--cases] [--private-user]
                              [--game-tests-since BASE] <module> [<module> ...]

--cases splits each module into its test cases (the lifecycle suite, whose
cases each build their own temporary repository). --private-user gives each
worker its own user:// (see private_user_home). --game-tests-since BASE drops
the modules that boot Godot when nothing changed since BASE can reach them
(see game_tests_reached). A passing id prints one line; a failing one prints
everything it wrote. Exits 1 if any id failed.
"""
from __future__ import annotations

import argparse
import ast
import itertools
import json
import os
import subprocess
import sys
import threading
import time
import unittest
import uuid
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
TESTS = ROOT / "tests"

# The same folder run_scenario.private_user_env uses, so .gitignore and the
# .gdignore marker already cover it and its six-hour pruning clears ours too.
PRIVATE_USER_ROOT = ROOT / ".headless_user"

# Paths a branch can change without reaching a game test, unless a game test
# imports the file (game_test_files). Anything else -- scripts/, scenes/,
# test_scenarios/, assets, project.godot, a tests/*.gd script -- reaches them.
NON_GAME_DIRS = ("docs/", "plans/", "checks/", ".claude/", ".codex/", ".agents/")
NON_GAME_CODE_DIRS = ("tools/", "tests/")


def default_workers() -> int:
    override = os.environ.get("MEADOW_TEST_WORKERS", "").strip()
    if override.isdigit() and int(override) > 0:
        return int(override)
    # A Godot module keeps about one core busy; leave room for the other
    # verify jobs and other sessions on the same machine.
    return max(2, min(6, (os.cpu_count() or 4) // 3))


# --- timings ---

def timings_path() -> Path | None:
    """One file for every worktree, in the git common dir beside the
    diagnostic log, so a fresh worktree still orders its first run well."""
    try:
        common = subprocess.run(
            ["git", "-C", str(ROOT), "rev-parse", "--path-format=absolute", "--git-common-dir"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return None
    return Path(common) / "meadow-test-timings.json" if common else None


def load_timings(path: Path | None) -> dict[str, float]:
    if path is None:
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}
    return {k: float(v) for k, v in data.items() if isinstance(v, (int, float))} if isinstance(data, dict) else {}


def save_timings(path: Path | None, measured: dict[str, float]) -> None:
    if path is None or not measured:
        return
    merged = load_timings(path)
    merged.update({k: round(v, 1) for k, v in measured.items()})
    temp = path.with_name(path.name + ".%s.tmp" % uuid.uuid4().hex[:8])
    try:
        temp.write_text(json.dumps(merged, indent=0, sort_keys=True), encoding="utf-8")
        os.replace(temp, path)
    except OSError:
        temp.unlink(missing_ok=True)


def slowest_first(ids: list[str], timings: dict[str, float]) -> list[str]:
    """Unknown ids first (a new module may be a slow Godot one), then by
    last time, longest first, so no long module starts last."""
    return sorted(ids, key=lambda i: (i in timings, -timings.get(i, 0.0), i))


# --- game tests ---

def is_game_test(module: str) -> bool:
    """A module that boots Godot: every one of them finds it through
    godot_compile_check.find_godot and skips itself without it."""
    try:
        return "find_godot(" in module_file(module).read_text(encoding="utf-8")
    except OSError:
        return True


def module_file(module: str) -> Path:
    return ROOT / (module.replace(".", "/") + ".py")


def local_imports(path: Path) -> set[Path]:
    """tools/ and tests/ modules `path` imports by name (the tests put tools/
    on sys.path and import its modules bare)."""
    try:
        tree = ast.parse(path.read_text(encoding="utf-8"))
    except (OSError, SyntaxError, ValueError):
        return set()
    names: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            names.update(alias.name for alias in node.names)
        elif isinstance(node, ast.ImportFrom) and node.module and not node.level:
            names.add(node.module)
    found = set()
    for name in names:
        tail = name.split(".")[-1]
        for folder in (TOOLS, TESTS):
            candidate = folder / (tail + ".py")
            if candidate.is_file():
                found.add(candidate)
    return found


def game_test_files(game_modules: list[str]) -> set[str]:
    """Each game test module and every tools/ or tests/ file it imports,
    transitively, as repo-relative paths."""
    seen: set[Path] = set()
    pending = [module_file(m) for m in game_modules]
    while pending:
        path = pending.pop()
        if path in seen:
            continue
        seen.add(path)
        pending.extend(local_imports(path) - seen)
    return {p.relative_to(ROOT).as_posix() for p in seen}


def changed_files(base: str) -> list[str] | None:
    """Files changed since `base` (committed, staged, unstaged or new), or
    None if git cannot say."""
    commands = (
        ["diff", "--name-only", "%s...HEAD" % base],
        ["diff", "--name-only", "HEAD"],
        ["ls-files", "--others", "--exclude-standard"],
    )
    changed: list[str] = []
    for args in commands:
        try:
            result = subprocess.run(["git", "-C", str(ROOT)] + args, capture_output=True, text=True)
        except OSError:
            return None
        if result.returncode != 0:
            return None
        changed.extend(line.strip() for line in result.stdout.splitlines() if line.strip())
    return sorted(set(changed))


def reaches_game(path: str, game_files: set[str]) -> bool:
    if path in game_files:
        return True
    if path.endswith(".md") or path.startswith(NON_GAME_DIRS):
        return False
    if path.startswith(NON_GAME_CODE_DIRS) and path.endswith((".py", ".ps1")):
        return False
    return True


def game_tests_reached(base: str, game_modules: list[str]) -> tuple[bool, str]:
    """Whether the branch's changes since `base` can reach a game test, and
    why. Dave chose this skip on 14 Oct 2026: a branch that changes only
    tooling, its tests or documents no longer proves the game still boots
    and plays, for ~150 s off its verify. The game tests always run when git
    cannot say what changed, and on a checkout with nothing changed at all
    (a plain verify on master is a full check)."""
    changed = changed_files(base)
    if changed is None:
        return True, "git could not list the changed files"
    if not changed:
        return True, "nothing changed since %s, so a full run" % base
    game_files = game_test_files(game_modules)
    for path in changed:
        if reaches_game(path, game_files):
            return True, "reached by %s" % path
    return False, "the branch reaches no game file"


# --- running ---

def expand_cases(modules: list[str]) -> list[str]:
    """Each module's test case ids, in definition order."""
    sys.path.insert(0, str(ROOT))
    ids: list[str] = []

    def walk(suite):
        for item in suite:
            if isinstance(item, unittest.TestSuite):
                walk(item)
            else:
                ids.append(item.id())

    for module in modules:
        walk(unittest.defaultTestLoader.loadTestsFromName(module))
    return ids


def private_user_home(worker: int, run: str) -> Path:
    """Each worker's own user://. The modules that launch Godot with
    --script read and write the one user:// every Godot on the machine
    shares; side by side, one module's save or settings would land in
    another's run (run_scenario.private_user_env, 9 Oct 2026)."""
    PRIVATE_USER_ROOT.mkdir(exist_ok=True)
    marker = PRIVATE_USER_ROOT / ".gdignore"
    if not marker.exists():
        marker.write_text("", encoding="utf-8")
    home = PRIVATE_USER_ROOT / ("tests-%s-%d" % (run, worker))
    home.mkdir(exist_ok=True)
    return home


def run_all(ids: list[str], workers: int, private_user: bool) -> tuple[list[str], dict[str, float]]:
    run = uuid.uuid4().hex[:8]
    local = threading.local()
    counter = itertools.count()
    counter_lock = threading.Lock()
    print_lock = threading.Lock()
    failed: list[str] = []
    measured: dict[str, float] = {}

    def worker_env() -> dict[str, str]:
        if not hasattr(local, "env"):
            env = dict(os.environ)
            env["PYTHONDONTWRITEBYTECODE"] = "1"
            if private_user:
                with counter_lock:
                    worker = next(counter)
                home = private_user_home(worker, run)
                env["APPDATA" if os.name == "nt" else "XDG_DATA_HOME"] = str(home)
            local.env = env
        return local.env

    def run_one(test_id: str) -> None:
        start = time.time()
        result = subprocess.run(
            [sys.executable, "-m", "unittest", test_id], cwd=ROOT, env=worker_env(),
            capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
        seconds = time.time() - start
        with print_lock:
            measured[test_id] = seconds
            if result.returncode == 0:
                print("ok    %6.1fs  %s" % (seconds, test_id), flush=True)
            else:
                failed.append(test_id)
                print("FAILED %5.1fs  %s (exit %d)" % (seconds, test_id, result.returncode), flush=True)
                print(result.stdout.rstrip(), flush=True)
                print(result.stderr.rstrip(), flush=True)

    with ThreadPoolExecutor(max_workers=workers) as pool:
        list(pool.map(run_one, ids))
    return failed, measured


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("modules", nargs="*")
    parser.add_argument("--workers", type=int, default=0)
    parser.add_argument("--cases", action="store_true")
    parser.add_argument("--private-user", action="store_true")
    parser.add_argument("--game-tests-since", default="")
    parser.add_argument("--label", default="tests")
    args = parser.parse_args(argv)

    modules = list(args.modules)
    if args.game_tests_since:
        game_modules = [m for m in modules if is_game_test(m)]
        reached, why = game_tests_reached(args.game_tests_since, game_modules)
        if game_modules and not reached:
            modules = [m for m in modules if m not in game_modules]
            print("game tests: skipped -- %s (%d modules)" % (why, len(game_modules)), flush=True)
        elif game_modules:
            print("game tests: run -- %s" % why, flush=True)
    if not modules:
        print("%s: none to run" % args.label)
        return 0

    ids = expand_cases(modules) if args.cases else modules
    path = timings_path()
    ids = slowest_first(ids, load_timings(path))
    workers = min(args.workers or default_workers(), len(ids))
    start = time.time()
    failed, measured = run_all(ids, workers, args.private_user)
    save_timings(path, measured)
    print("%s: ran %d %s in %.0f s on %d workers; %d failed" % (
        args.label, len(ids), "cases" if args.cases else "modules", time.time() - start, workers, len(failed)))
    for test_id in failed:
        print("failed: %s -- rerun alone with: python -m unittest %s" % (test_id, test_id))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
