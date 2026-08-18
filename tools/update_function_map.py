#!/usr/bin/env python3
"""Regenerate FUNCTION_MAP.md from the six biggest scripts/*.gd files.

FUNCTION_MAP.md exists so a session can grep a function name (or a rough
area, e.g. "popup", "restock") and get a line number instead of reading
800-1,500 lines top to bottom. Line numbers drift as a file changes, so
this script re-derives them from the source rather than trusting a
hand-maintained copy.

Usage:
    python3 tools/update_function_map.py            # write FUNCTION_MAP.md
    python3 tools/update_function_map.py --check    # exit 1 if it's stale
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "scripts"
OUTPUT = ROOT / "FUNCTION_MAP.md"

# (filename, one-line description shown under its heading). Order matches
# the routing table in CLAUDE.md.
FILES = [
    ("hud.gd", "Corner readouts, panels, popups, warnings, the problem strip, the\n"
                "Challenge goal readout."),
    ("bee.gd", "A bee's dispatch loop, player commands, display text, vars."),
    ("debug_panel.gd", "The settings window (the cog icon): tuner rows, save/load buttons,\n"
                        "restart."),
    ("hive_cell.gd", "One cell: contents, brood, honey ripening, how it draws."),
    ("hive.gd", "The comb as a whole: cells, navigation, finding a cell."),
    ("main.gd", "Per-frame entry point, everything not yet split out of main."),
]

# Only top-level (column-0) section headers and function definitions --
# indented closures inside a function body aren't a navigation target.
LINE_RE = re.compile(r"^(# --- .*|static func .*|func .*)$")

PREAMBLE = """\
# Function map

A line-numbered index of every function and section header in the six
scripts still over ~700 lines after the `bee.gd` / `main.gd` splits.
Smaller files don't need this -- grep their `# --- section ---` headers
directly, per CLAUDE.md.

**How to use it:** grep this file for the function name (or the area you
want, e.g. "popup", "restock") to get its line number, then either `Read`
the source file with an offset near that line, or grep the source file
directly for the exact signature before editing. Line numbers here are a
pointer, not a guarantee -- they drift as the file changes.

**How to keep it updated:** this file is generated, not hand-maintained.
After adding, removing, renaming or moving a function in one of the six
files below, run:

```
python3 tools/update_function_map.py
```

`--check` exits non-zero (and prints which files moved) instead of
writing, for a pre-commit or CI check. Whether the map was actually
regenerated after a given change is a `git log` question, not something
recorded in this file.
"""


def build_section(filename: str, description: str) -> str:
    path = SCRIPTS / filename
    lines = path.read_text(encoding="utf-8").splitlines()
    entries = []
    for lineno, line in enumerate(lines, start=1):
        match = LINE_RE.match(line)
        if not match:
            continue
        text = match.group(1).rstrip()
        if text.endswith(":"):
            text = text[:-1]
        entries.append(f"{lineno:<4} {text}")
    body = "\n".join(entries)
    return (
        f"## {filename} ({len(lines):,} lines)\n\n"
        f"{description}\n\n"
        f"```\n{body}\n```\n"
    )


def build_file() -> str:
    sections = "\n".join(build_section(name, desc) for name, desc in FILES)
    return PREAMBLE + "\n---\n\n" + sections


def main() -> int:
    check = "--check" in sys.argv
    content = build_file()

    if check:
        current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else ""
        if current != content:
            print("FUNCTION_MAP.md is stale -- run `python3 tools/update_function_map.py`.")
            return 1
        print("FUNCTION_MAP.md is up to date.")
        return 0

    with OUTPUT.open("w", encoding="utf-8", newline="\n") as f:
        f.write(content)
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
