#!/usr/bin/env python3
"""The checks to run before `tools/slice.ps1 finish`, as one command.

Why this exists
---------------
`finish` is the last, expensive step: its branch verify runs every suite,
and the lifecycle suite too when workflow tooling changed. PP-3 (12 Oct
2026) reached it with two faults a few seconds of checking would have
shown: a GDScript parse error (98 minutes of Godot-booting tests running to
their timeouts) and then a preload of skills.gd that tests/source_checks.py
bars. The pre-finish checks were a list in CHATGPT.md to remember; this is
that list as one command, stopping at the first failure:

1. the boot check (tools/godot_compile_check.py), which also brings the
   worktree's Godot import cache up to date -- exit 3 there is the cache,
   not the code, and its line names the fix;
2. tests/source_checks.py;
3. the unit test modules that name a file this branch changed (diffed
   against master, plus uncommitted and untracked files), and any changed
   test module itself.

It is a subset of `finish`'s verify, never a replacement: no balance tests,
no lifecycle suite, no generated-file stages. Typically under a minute.

Run it from the worktree (Windows PowerShell or Git Bash), as its own copy --
never ../../tools/prefinish.py, which checks another checkout and now stops:
    python tools/prefinish.py [--base master]
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Minutes each, and `finish` runs them whenever the branch can reach them.
LIFECYCLE_MODULES = {"test_slice_lifecycle", "test_two_lane_closeout"}

# Changed files whose name says nothing a test would search for.
UNSEARCHED = {"__init__.py"}

# A file more test modules name than this is shared infrastructure (45
# Godot-booting tests import godot_compile_check for find_godot alone): only
# its own test_<name> modules run here, and `finish` runs the rest.
BROAD = 8


def wrong_checkout(cwd: Path) -> str | None:
    """Why this copy must not run from `cwd`, or None when it may.

    This copy checks ROOT, not the checkout you stand in. On 12 Oct 2026
    Codex, in .worktrees/CD-3, ran `python ../../tools/prefinish.py`: it
    checked the primary checkout and passed a branch it never looked at.
    Outside any git checkout there is nothing to confuse, so it may run."""
    try:
        out = subprocess.run(["git", "-C", str(cwd), "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True)
    except OSError:
        return None
    top = out.stdout.strip()
    if out.returncode != 0 or not top:
        return None
    if os.path.normcase(str(Path(top).resolve())) == os.path.normcase(str(ROOT)):
        return None
    return ("prefinish: stopped -- this is the prefinish.py of %s, but you are inside %s.\n"
            "It would check %s, not your checkout. Run your checkout's own copy:\n"
            "    cd %s; python tools/prefinish.py" % (ROOT, top, ROOT, top))


def git_lines(*args: str) -> list[str]:
    try:
        out = subprocess.run(["git", *args], cwd=ROOT, capture_output=True,
                             text=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        return []
    return [line.strip() for line in out.splitlines() if line.strip()]


def changed_files(base: str) -> list[str]:
    """Files this branch changed against base, committed or not."""
    names: list[str] = []
    for listing in (git_lines("diff", "--name-only", "%s...HEAD" % base),
                    git_lines("diff", "--name-only", "HEAD"),
                    git_lines("ls-files", "--others", "--exclude-standard")):
        for name in listing:
            name = name.replace("\\", "/")
            if name not in names:
                names.append(name)
    return names


def search_term(path: str) -> str | None:
    """What a test that drives path would contain: a Python module's name
    (it is imported, not named by file), any other file's name."""
    name = path.rsplit("/", 1)[-1]
    if name in UNSEARCHED:
        return None
    if name.endswith(".py"):
        return name[:-3]
    return name


def module_name(path: str) -> str | None:
    """"tests.test_x" for a test module path, else None."""
    match = re.fullmatch(r"tests/(test_\w+)\.py", path)
    return "tests." + match.group(1) if match else None


def tests_naming(term: str) -> list[str]:
    """Test module paths whose text contains term as a whole word."""
    return git_lines("grep", "-l", "--untracked", "-w", "-F", "-e", term,
                     "--", "tests/test_*.py")


def select_modules(changed: list[str], grep=tests_naming,
                   broad: list[str] | None = None) -> dict[str, list[str]]:
    """Map each unit test module to run onto the changed files that chose it.

    A changed file named by more than BROAD modules chooses only the modules
    named after it, and is appended to broad (when given) to be reported.
    """
    chosen: dict[str, list[str]] = {}

    def choose(test_path: str, reason: str) -> None:
        module = module_name(test_path)
        if module is None or module.split(".")[1] in LIFECYCLE_MODULES:
            return
        if not (ROOT / test_path).is_file():
            return  # deleted on this branch
        chosen.setdefault(module, [])
        if reason not in chosen[module]:
            chosen[module].append(reason)

    for path in changed:
        if module_name(path):
            choose(path, path)
            continue
        term = search_term(path)
        if not term:
            continue
        found = [test_path.replace("\\", "/") for test_path in grep(term)]
        if len(found) > BROAD:
            stem = term.split(".")[0]
            found = [t for t in found if t.rsplit("/", 1)[-1].startswith("test_%s" % stem)]
            if broad is not None:
                broad.append(path)
        for test_path in found:
            choose(test_path, path)
    return dict(sorted(chosen.items()))


def run_step(name: str, command: list[str]) -> int:
    print("prefinish: %s ..." % name, flush=True)
    started = time.monotonic()
    code = subprocess.run(command, cwd=ROOT).returncode
    print("prefinish: %s %s (%.0f s)" % (name, "OK" if code == 0 else "FAILED, exit %d" % code,
                                         time.monotonic() - started), flush=True)
    return code


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base", default="master", help="branch to diff against (default master)")
    args = parser.parse_args(argv)
    python = sys.executable

    refusal = wrong_checkout(Path.cwd())
    if refusal:
        print(refusal)
        return 2

    code = run_step("godot boot", [python, "tools/godot_compile_check.py"])
    if code != 0:
        if code == 3:
            print("prefinish: stopped -- the Godot import cache, not the code; run the Fix command above")
        else:
            print("prefinish: stopped -- the project does not boot; every Godot test would time out")
        return code
    code = run_step("source checks", [python, "tests/source_checks.py"])
    if code != 0:
        print("prefinish: stopped -- a source rule failed (tests/source_checks.py names it)")
        return code

    broad: list[str] = []
    modules = select_modules(changed_files(args.base), broad=broad)
    for path in broad:
        print("prefinish: %s is named by more than %d test modules; only its own run here, "
              "finish runs the rest" % (path, BROAD))
    if not modules:
        print("prefinish: no unit test module names a changed file")
    else:
        for module, reasons in modules.items():
            print("  %s  <- %s" % (module, ", ".join(reasons)))
        code = run_step("unit tests (%d modules)" % len(modules), [python, "-m", "unittest", *modules])
        if code != 0:
            print("prefinish: stopped -- a unit test failed")
            return code
    print("prefinish: all checks passed; finish runs the full verify")
    return 0


if __name__ == "__main__":
    sys.exit(main())
