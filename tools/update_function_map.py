#!/usr/bin/env python3
"""Regenerate FUNCTION_MAP.md from every scripts/*.gd file over the threshold.

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

# A scripts/*.gd file longer than this gets indexed below -- the number the
# map's own header already claims.
LINE_THRESHOLD = 700

# filename -> one-line description, in the same voice as the file next to
# it. Every scripts/*.gd file over LINE_THRESHOLD needs an entry here;
# --check fails naming any file that crosses the threshold without one.
DESCRIPTIONS = {
    "hud.gd": "Corner readouts, panels, popups, warnings, the problem strip, the\n"
              "Challenge goal readout.",
    "main_menu.gd": "The main menu overlay: the honeycomb of stage hexes, their name fitting,\n"
                    "and the menu buttons.",
    "bee.gd": "A bee's dispatch loop, player commands, display text, vars.",
    "debug_panel.gd": "The settings window (the cog icon): tuner rows, save/load buttons,\n"
                       "restart.",
    "settings_catalogue.gd": "Every setting's key, label, range and tip, plus the read/write and Prerequisites-cascade functions the window is a view of.",
    "hive_cell.gd": "One cell: contents, brood, honey ripening, how it draws.",
    "hive.gd": "The comb as a whole: cells, navigation, finding a cell.",
    "main.gd": "Per-frame entry point, everything not yet split out of main.",
    "bee_foraging.gd": "The forager's search, scouting, recruitment and species-preference\n"
                        "behaviour.",
    "challenge_runner.gd": "The stage machine, goal checks and stage effects.",
    "diagnostic_log.gd": "The session JSONL writer, counters and capture profiles.",
    "scenario_actions.gd": "The headless verbs, `when` clauses and layout assertions.",
    "game_config.gd": "The balance fields.",
    "input_selection.gd": "Selection, drag and placement resolution.",
}

# Only top-level (column-0) section headers and function definitions --
# indented closures inside a function body aren't a navigation target.
LINE_RE = re.compile(r"^(# --- .*|static func .*|func .*)$")

PREAMBLE = """\
# Function map

A line-numbered index of every function and section header in every
scripts/*.gd file over {threshold} lines. Smaller files don't need this --
grep their `# --- section ---` headers directly, per CLAUDE.md.

**How to use it:** grep this file for the function name (or the area you
want, e.g. "popup", "restock") to get its line number, then either `Read`
the source file with an offset near that line, or grep the source file
directly for the exact signature before editing. Line numbers here are a
pointer, not a guarantee -- they drift as the file changes.

**How to keep it updated:** this file is generated, not hand-maintained.
After adding, removing, renaming or moving a function in one of the files
below, run:

```
python3 tools/update_function_map.py
```

`--check` exits non-zero (and prints which files moved) instead of
writing, for a pre-commit or CI check. Whether the map was actually
regenerated after a given change is a `git log` question, not something
recorded in this file.
""".format(threshold=LINE_THRESHOLD)


def discover_files() -> list[tuple[str, int]]:
    """Every scripts/*.gd file over LINE_THRESHOLD, biggest first."""
    found = []
    for path in SCRIPTS.glob("*.gd"):
        line_count = len(path.read_text(encoding="utf-8").splitlines())
        if line_count > LINE_THRESHOLD:
            found.append((path.name, line_count))
    found.sort(key=lambda item: (-item[1], item[0]))
    return found


def build_section(filename: str, line_count: int, description: str) -> str:
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
        f"## {filename} ({line_count:,} lines)\n\n"
        f"{description}\n\n"
        f"```\n{body}\n```\n"
    )


def build_file(discovered: list[tuple[str, int]]) -> str:
    sections = "\n".join(
        build_section(name, line_count, DESCRIPTIONS[name])
        for name, line_count in discovered
    )
    return PREAMBLE + "\n---\n\n" + sections


# A file this long wants a `# --- section ---` header early enough to route
# to, not one buried near the end: CLAUDE.md sends a session to grep for them
# instead of reading the file. A tenth of the way in is generous -- past that,
# the whole head of the file is unsignposted. A warning rather than a failure,
# so a new large file doesn't block a commit, but the gap is never invisible.
HEADER_RE = re.compile(r"^# --- ")


def header_warnings(discovered: list[tuple[str, int]]) -> list[str]:
    warnings = []
    for name, line_count in discovered:
        lines = (SCRIPTS / name).read_text(encoding="utf-8").splitlines()
        first = next(
            (n for n, line in enumerate(lines, start=1) if HEADER_RE.match(line)),
            None,
        )
        cutoff = max(1, line_count // 10)
        if first is None:
            warnings.append(
                f"warning: {name} ({line_count:,} lines) has no "
                "`# --- section ---` header at all -- nothing to grep for."
            )
        elif first > cutoff:
            warnings.append(
                f"warning: {name} ({line_count:,} lines) has no "
                f"`# --- section ---` header until line {first} -- its first "
                f"{cutoff} lines are unsignposted."
            )
    return warnings


def main() -> int:
    check = "--check" in sys.argv
    discovered = discover_files()

    missing = [name for name, _ in discovered if name not in DESCRIPTIONS]
    if missing:
        for name in missing:
            print(
                f"FUNCTION_MAP.md is stale -- {name} crossed {LINE_THRESHOLD} "
                "lines and has no description in tools/update_function_map.py's "
                "DESCRIPTIONS."
            )
        return 1

    for warning in header_warnings(discovered):
        print(warning)

    content = build_file(discovered)

    if check:
        current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else ""
        if current != content:
            print("FUNCTION_MAP.md is stale -- run `python3 tools/update_function_map.py`.")
            return 1
        print("FUNCTION_MAP.md is up to date.")
        return 0

    before = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else None
    if before == content:
        print(f"unchanged {OUTPUT.relative_to(ROOT)}")
        return 0
    with OUTPUT.open("w", encoding="utf-8", newline="\n") as f:
        f.write(content)
    print(f"regenerated {OUTPUT.relative_to(ROOT)} (was stale)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
