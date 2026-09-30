#!/usr/bin/env python3
"""Print one GDScript function: its doc comment, its body, and nothing else.

`tools/heading.py` does this for a Markdown section, because routing tells a
session to open a named heading rather than a whole file. Plans route the same
way into code -- "in `hud.gd`: `_build_nursery_controls`, `_make_hatch_menu`,
`show_cell_popup`" -- and until now the only ways to follow that were to read
the file (3,278 lines for `hud.gd`), to read `FUNCTION_MAP.md`'s section for
it first, or to grep and guess how far the function ran. All three cost far
more than the function does.

    python tools/func.py scripts/hud.gd _build_nursery_controls
    python tools/func.py scripts/bee.gd _try_role_work _idle_dispatch

A function runs from its `func` (or `static func`) line to the next one at the
same indentation, or to the next `# --- section ---` header, whichever comes
first. The `##` doc comment block immediately above it is part of it: in this
codebase that comment is usually the reason the function is worth reading.

Exit status is 0 when every named function was found, 1 otherwise, so a script
can tell "printed nothing" from "printed something".
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys

DEF = re.compile(r"^(?P<indent>[ \t]*)(?:static\s+)?func\s+(?P<name>\w+)\s*\(")
SECTION = re.compile(r"^#\s*---")


def extract(lines: list[str], name: str) -> tuple[int, int] | None:
    """The half-open line range of `name`, doc comment included."""
    for index, line in enumerate(lines):
        match = DEF.match(line)
        if not match or match.group("name") != name:
            continue

        start = index
        while start > 0:
            above = lines[start - 1].strip()
            if above.startswith("##") or (above.startswith("#") and not SECTION.match(lines[start - 1])):
                start -= 1
                continue
            break

        indent = match.group("indent")
        end = len(lines)
        for later in range(index + 1, len(lines)):
            if SECTION.match(lines[later]):
                end = later
                break
            later_def = DEF.match(lines[later])
            if later_def and later_def.group("indent") == indent:
                end = later
                break
        while end > index + 1 and not lines[end - 1].strip():
            end -= 1
        return start, end
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("path", help="the .gd file to read")
    parser.add_argument("names", nargs="+", help="one or more function names")
    args = parser.parse_args()

    # Same reason as tools/heading.py: a Windows console defaults to cp1252,
    # and hud.gd's em dashes and arrows raised UnicodeEncodeError after the
    # first header line (HF-6, 30 Sep 2026), so the routed read failed on
    # exactly the UI files that carry typographic characters.
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8", errors="replace")

    path = pathlib.Path(args.path)
    if not path.is_file():
        print("error: no such file: %s" % path, file=sys.stderr)
        return 1
    lines = path.read_text(encoding="utf-8").splitlines()

    missing: list[str] = []
    for position, name in enumerate(args.names):
        span = extract(lines, name)
        if span is None:
            missing.append(name)
            continue
        start, end = span
        if position:
            print()
        print("# %s:%d" % (path.as_posix(), start + 1))
        print("\n".join(lines[start:end]))

    for name in missing:
        print("error: %s has no function named %r" % (path.as_posix(), name), file=sys.stderr)
    return 1 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
