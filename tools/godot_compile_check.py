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
Godot is not installed in every environment that runs verification (the
Codex runtime has no Godot). When the binary cannot be found this prints a
skip line and exits 0 rather than failing a machine that was never able to
answer the question. Set `MEADOW_GODOT_PATH` to point at a non-default
install.
"""

import os
import re
import shutil
import subprocess
import sys
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
    override = os.environ.get("MEADOW_GODOT_PATH", "").strip()
    if override:
        return override if Path(override).is_file() else None
    if Path(DEFAULT_GODOT_PATH).is_file():
        return DEFAULT_GODOT_PATH
    for name in ("godot", "godot4", "Godot"):
        found = shutil.which(name)
        if found:
            return found
    return None


def failing_lines(output: str) -> list[str]:
    hits: list[str] = []
    for line in output.splitlines():
        for pattern in FAILURE_PATTERNS:
            if pattern.search(line):
                hits.append(line.rstrip())
                break
    return hits


def main() -> int:
    godot = find_godot()
    if godot is None:
        print("godot compile check: skipped -- no Godot binary found "
              "(set MEADOW_GODOT_PATH to run it here)")
        return 0

    command = [
        godot, "--headless", "--disable-crash-handler",
        "--quit-after", str(QUIT_AFTER_FRAMES),
        "--path", str(REPO_ROOT),
    ]
    try:
        finished = subprocess.run(
            command, capture_output=True, text=True,
            encoding="utf-8", errors="replace", timeout=TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        print("godot compile check: FAILED -- the boot did not finish within "
              "%d seconds" % TIMEOUT_SECONDS)
        return 1
    except OSError as exc:
        print("godot compile check: skipped -- could not launch %r: %s"
              % (godot, exc))
        return 0

    combined = (finished.stdout or "") + "\n" + (finished.stderr or "")
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

    print("godot compile check: the project boots with no script errors")
    return 0


if __name__ == "__main__":
    sys.exit(main())
