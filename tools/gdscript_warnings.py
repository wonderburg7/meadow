#!/usr/bin/env python3
"""List the GDScript warnings a headless boot raises, and fail on any named.

Why this exists
---------------
A GDScript warning (an integer division, a shadowed property, an unused
parameter) is sent only to an attached debugger, so the ordinary headless
boot in `tools/godot_compile_check.py` never prints one. SC-3 (2 Oct 2026)
was checked against "a headless boot prints no `GDScript::reload` warning"
and nobody could see the warnings either before or after the fix. Booting
with `-d` attaches Godot's local stdout debugger, which prints each one as

    WARNING: <text>
       at: GDScript::reload (res://scripts/hud.gd:629)

Usage
-----
    python tools/gdscript_warnings.py                      # every warning
    python tools/gdscript_warnings.py scripts/hud.gd ...   # fail on these

With no paths it lists every warning and exits 1 if there are any. With
paths (repo-relative or `res://`) it lists every warning but exits 1 only if
one is in a named file. Godot missing or unable to boot is a skip (exit 0),
as in the compile check.
"""

import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import godot_compile_check as gcc  # noqa: E402

WARNING_LINE = re.compile(r"^WARNING: (.*)$")
RELOAD_LINE = re.compile(r"^\s*at: GDScript::reload \((res://[^:)]+):(\d+)\)")


def boot_with_debugger(godot: str, root: Path) -> str:
    """Boot root's main scene with the local debugger; return its output."""
    command = [
        godot, "--headless", "--disable-crash-handler", "-d",
        "--quit-after", str(gcc.QUIT_AFTER_FRAMES),
        "--path", str(root),
    ]
    # stdin closed: the local debugger would otherwise wait on a prompt if a
    # script error broke into it.
    finished = subprocess.run(
        command, capture_output=True, text=True, stdin=subprocess.DEVNULL,
        encoding="utf-8", errors="replace", timeout=gcc.TIMEOUT_SECONDS,
    )
    return gcc.combined_output(finished)


def script_warnings(output: str) -> list[tuple[str, int, str]]:
    """(res path, line, text) for each warning raised while a script loads."""
    found: list[tuple[str, int, str]] = []
    lines = output.splitlines()
    for index, line in enumerate(lines[:-1]):
        warning = WARNING_LINE.match(line)
        where = RELOAD_LINE.match(lines[index + 1]) if warning else None
        if where:
            item = (where.group(1), int(where.group(2)), warning.group(1))
            if item not in found:
                found.append(item)
    return found


def as_res_path(path: str) -> str:
    if path.startswith("res://"):
        return path
    return "res://" + path.replace("\\", "/").lstrip("./")


def main(argv: list[str]) -> int:
    named = {as_res_path(path) for path in argv}
    godot = gcc.find_godot()
    if godot is None:
        print("gdscript warnings: skipped -- no Godot binary found "
              "(set MEADOW_GODOT_PATH to run it here)")
        return 0
    redirected = gcc.ensure_writable_user_dir()
    if redirected:
        print(redirected)
    if not gcc.engine_can_boot(godot):
        return 0
    if not gcc.prepare_cache(godot):
        return 1
    try:
        output = boot_with_debugger(godot, gcc.REPO_ROOT)
    except subprocess.TimeoutExpired:
        print("gdscript warnings: FAILED -- the boot did not finish within "
              "%d seconds" % gcc.TIMEOUT_SECONDS)
        return 1

    warnings = script_warnings(output)
    for path, line, text in warnings:
        print("  %s:%d  %s" % (path, line, text))
    failing = [w for w in warnings if not named or w[0] in named]
    if failing:
        scope = "in the named files" if named else "in the project"
        print("gdscript warnings: FAILED -- %d warning(s) %s"
              % (len(failing), scope))
        return 1
    scope = "the named files raise" if named else "the project raises"
    print("gdscript warnings: %s none (%d elsewhere)"
          % (scope, len(warnings)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
