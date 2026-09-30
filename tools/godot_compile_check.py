#!/usr/bin/env python3
"""Boot the project headlessly and fail on any script error.

Why this exists
---------------
`tools/verify.ps1` runs Python suites only, so it cannot see a GDScript
parse error. On 12 September 2026 `scripts/hud.gd` called
`Rect2.get_closest_point()`, which does not exist in Godot 4. That is a
*parse* error, so it failed the compile of every script depending on it,
`scripts/main.gd` included -- the game booted with no HUD at all, every
panel and label gone, and stayed that way across several merges because
nothing in verification opens Godot.

A single headless boot of the project's own main scene loads `main.gd` and
everything it depends on, which is the whole runtime. Any `SCRIPT ERROR`,
parse failure or "Failed to load script" line in that boot's output is a
build that a player cannot run.

Skipping
--------
Godot is not installed in every environment that runs verification. A binary
can also be installed but unable to initialise headlessly on that host. In
either case this prints a skip line and exits 0 rather than attributing an
engine crash to the project. Set `MEADOW_GODOT_PATH` to point at a working
non-default install. A sandbox that denies Godot's user:// folder (Codex's
does) is not a skip: `ensure_writable_user_dir` redirects it first.
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

DEFAULT_GODOT_PATH = r"C:\Program Files\Godot\Godot.exe"

# How many frames to run before quitting. The boot itself is what compiles
# the scripts; a couple of seconds of frames also catches an error raised
# from _ready or the first _process rather than at parse time.
QUIT_AFTER_FRAMES = 120

TIMEOUT_SECONDS = 180

# Lines that mean the build is not runnable. Matched case-sensitively
# against Godot's own prefixes so an ordinary `push_warning` or a line of
# game text containing the word "error" does not fail the stage.
FAILURE_PATTERNS = [
    re.compile(r"^SCRIPT ERROR:"),
    re.compile(r"^\s*Parse Error:"),
    re.compile(r'^ERROR: Failed to load script '),
    re.compile(r"^\s*Compile Error:"),
]


def find_godot() -> str | None:
    # GODOT_PATH is the older name the layout tests read; accept both so no
    # tool silently skips on a host that set only one.
    override = (os.environ.get("MEADOW_GODOT_PATH") or os.environ.get("GODOT_PATH") or "").strip()
    if override:
        return override if Path(override).is_file() else None
    if Path(DEFAULT_GODOT_PATH).is_file():
        return DEFAULT_GODOT_PATH
    for name in ("godot", "godot4", "Godot"):
        found = shutil.which(name)
        if found:
            return found
    return None


def ensure_writable_user_dir() -> str | None:
    """Point APPDATA at a temp folder when Godot could not write its own.

    Godot keeps user:// under %APPDATA%\\Godot\\app_userdata\\<config/name>.
    When it cannot open its log there, 4.7.1 dereferences the null file: an
    access violation reading 0x58, exit 0xC0000005, before the project
    loads. Codex's sandbox denies that folder, and that crash was every
    "engine crashed before opening the project" skip. Godot reads the folder
    from APPDATA, so redirecting it for this process gives every Godot child
    a writable user://, and run_scenario.log_dir() follows. Returns the line
    to print when it redirects, else None.
    """
    appdata = os.environ.get("APPDATA", "")
    if appdata and _can_write(Path(appdata) / "Godot"):
        return None
    fallback = Path(tempfile.gettempdir()) / "meadow-godot-appdata"
    fallback.mkdir(parents=True, exist_ok=True)
    os.environ["APPDATA"] = str(fallback)
    return ("godot user dir: %s\\Godot is not writable here; using %s"
            % (appdata or "%APPDATA%", fallback))


def _can_write(folder: Path) -> bool:
    # One plain write, not tempfile: on Windows tempfile retries a denied
    # create whenever os.access says writable, which ignores ACLs, so in a
    # denied folder it loops up to TMP_MAX (2**31) times.
    probe = folder / (".meadow-write-probe-%d" % os.getpid())
    try:
        folder.mkdir(parents=True, exist_ok=True)
        probe.write_bytes(b"")
        probe.unlink()
    except OSError:
        return False
    return True


def failing_lines(output: str) -> list[str]:
    hits: list[str] = []
    for line in output.splitlines():
        for pattern in FAILURE_PATTERNS:
            if pattern.search(line):
                hits.append(line.rstrip())
                break
    return hits


def engine_can_boot(godot: str) -> bool:
    """Return whether this host's Godot can initialise before opening Meadow."""
    command = [
        godot, "--headless", "--disable-crash-handler", "--quit-after", "1",
    ]
    try:
        finished = subprocess.run(
            command, capture_output=True, text=True,
            encoding="utf-8", errors="replace", timeout=TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        print("godot compile check: skipped -- the installed Godot engine did "
              "not initialise headlessly within %d seconds" % TIMEOUT_SECONDS)
        return False
    except OSError as exc:
        print("godot compile check: skipped -- could not launch %r: %s"
              % (godot, exc))
        return False
    if finished.returncode != 0:
        print("godot compile check: skipped -- the installed Godot engine "
              "crashed before opening the project (exit code %d)"
              % finished.returncode)
        return False
    return True


def boot(godot: str, root: Path) -> subprocess.CompletedProcess:
    """Boot root's main scene headlessly. Raises TimeoutExpired or OSError."""
    command = [
        godot, "--headless", "--disable-crash-handler",
        "--quit-after", str(QUIT_AFTER_FRAMES),
        "--path", str(root),
    ]
    return subprocess.run(
        command, capture_output=True, text=True,
        encoding="utf-8", errors="replace", timeout=TIMEOUT_SECONDS,
    )


def combined_output(finished: subprocess.CompletedProcess) -> str:
    return (finished.stdout or "") + "\n" + (finished.stderr or "")


def boot_failures(godot: str, root: Path) -> list[str]:
    """Return why root does not boot cleanly, or [] when it does.

    tools/godot_cache.py asks this of the primary checkout before copying
    its cache: a cache from a checkout that cannot boot is no cure.
    """
    try:
        finished = boot(godot, root)
    except subprocess.TimeoutExpired:
        return ["the boot did not finish within %d seconds" % TIMEOUT_SECONDS]
    except OSError as exc:
        return ["could not launch %r: %s" % (godot, exc)]
    hits = failing_lines(combined_output(finished))
    if finished.returncode != 0 and not hits:
        return ["the boot exited with code %d" % finished.returncode]
    return hits


def _godot_cache():
    # tools/ is on sys.path when run as a script; the package root in tests.
    try:
        import godot_cache
    except ImportError:
        from tools import godot_cache
    return godot_cache


def prepare_cache(godot: str) -> bool:
    """Seed or refresh a worktree's .godot before booting; False means stop."""
    ok, line = _godot_cache().ensure_cache(REPO_ROOT, godot)
    print(line)
    return ok


def refresh_cache_after(godot: str, output: str) -> bool:
    """Refresh once after an unresolved-script boot; True means boot again."""
    retry, line = _godot_cache().refresh_after_failure(REPO_ROOT, godot, output)
    if line:
        print(line)
    return retry


def mark_cache_fresh() -> None:
    _godot_cache().mark_fresh(REPO_ROOT)


def main() -> int:
    godot = find_godot()
    if godot is None:
        print("godot compile check: skipped -- no Godot binary found "
              "(set MEADOW_GODOT_PATH to run it here)")
        return 0
    redirected = ensure_writable_user_dir()
    if redirected:
        print(redirected)
    if not engine_can_boot(godot):
        return 0
    if not prepare_cache(godot):
        return 1

    try:
        finished = boot(godot, REPO_ROOT)
        combined = combined_output(finished)
        # A worktree cache left behind by a merge fails the boot on a script
        # it cannot resolve. Refresh it from the primary and try once more.
        if failing_lines(combined) and refresh_cache_after(godot, combined):
            finished = boot(godot, REPO_ROOT)
            combined = combined_output(finished)
    except subprocess.TimeoutExpired:
        print("godot compile check: FAILED -- the boot did not finish within "
              "%d seconds" % TIMEOUT_SECONDS)
        return 1
    except OSError as exc:
        print("godot compile check: skipped -- could not launch %r: %s"
              % (godot, exc))
        return 0

    hits = failing_lines(combined)

    # A crash or non-zero exit is a failure even when no line matched: the
    # boot did not get far enough to tell us it was fine.
    if finished.returncode != 0 and not hits:
        print("godot compile check: FAILED -- the boot exited with code %d"
              % finished.returncode)
        tail = [line for line in combined.splitlines() if line.strip()][-15:]
        for line in tail:
            print("  %s" % line)
        return 1

    if hits:
        print("godot compile check: FAILED -- the project does not boot cleanly")
        seen: set[str] = set()
        for line in hits:
            if line in seen:
                continue
            seen.add(line)
            print("  %s" % line)
            if len(seen) >= 20:
                print("  ... and more")
                break
        return 1

    mark_cache_fresh()
    print("godot compile check: the project boots with no script errors")
    return 0


if __name__ == "__main__":
    sys.exit(main())
