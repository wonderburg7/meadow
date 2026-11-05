#!/usr/bin/env python3
"""Check that stage conditions checking cell designation distinguish explicit choice.

Why this exists
---------------
`docs/known-pitfalls.md`, "A goal that asks 'is any of them X' passes on the one
that was always X":
Challenge 1's stage 1.13 asks the player to set the second cell aside for
pollen; its goal check returned true for any cell with any designation, and
HiveCell.add_resource auto-designates a cell on its first deposit. The first cell
had been nectar-designated since stage 1.10, so the stage cleared in the frame it
opened and was never seen. A goal that names a player's choice must distinguish
the choice from the automatic default by requiring `"explicit": true`.

This tool scans GDScript stage definitions (defaulting to
`scripts/challenge_stages.gd`) for stage condition dictionaries containing
`"cell_count"` with `"designated"`. Any such specification must explicitly set
`"explicit": true`.

Usage
-----
    python tools/goal_default_check.py [files...]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

DEFAULT_FILES = [
    ROOT / "scripts" / "challenge_stages.gd",
]

# Match "cell_count": { ... } blocks
CELL_COUNT_BLOCK_RE = re.compile(
    r'"cell_count"\s*:\s*\{([^}]+)\}',
    re.DOTALL,
)


def strip_code(line: str) -> str:
    """Drop comments from a line of code, preserving strings."""
    out = []
    i = 0
    n = len(line)
    in_quote = ""
    while i < n:
        c = line[i]
        if in_quote:
            if c == "\\":
                out.append(c)
                if i + 1 < n:
                    out.append(line[i + 1])
                    i += 2
                    continue
            elif c == in_quote:
                in_quote = ""
            out.append(c)
        else:
            if c in ('"', "'"):
                in_quote = c
                out.append(c)
            elif c == "#":
                break
            else:
                out.append(c)
        i += 1
    return "".join(out)


def check_content(content: str, filename: str = "challenge_stages.gd") -> list[str]:
    """Check text content for cell_count designation conditions lacking explicit requirement."""
    problems: list[str] = []

    # Strip line comments while tracking character positions to find line numbers
    lines = content.splitlines(keepends=True)
    code_lines = [strip_code(line) for line in lines]
    clean_text = "".join(code_lines)

    for match in CELL_COUNT_BLOCK_RE.finditer(clean_text):
        block = match.group(1)
        # Check if the cell_count specification specifies "designated"
        has_designated = re.search(r'"designated"\s*:', block) is not None
        if not has_designated:
            continue

        # Check if it specifies "explicit": true
        has_explicit_true = re.search(r'"explicit"\s*:\s*true\b', block) is not None
        if not has_explicit_true:
            # Find line number of the match
            start_pos = match.start()
            line_no = clean_text[:start_pos].count("\n") + 1
            problems.append(
                f"{filename}:{line_no} cell_count specifies 'designated' without '\"explicit\": true': {match.group(0)}"
            )

    return problems


def check_file(path: Path) -> list[str]:
    """Check a single file for cell_count designation defaults."""
    if not path.exists():
        return [f"{path}: file does not exist"]
    try:
        content = path.read_text(encoding="utf-8")
    except OSError as err:
        return [f"{path}: could not read file ({err})"]

    try:
        rel = path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        rel = path.as_posix()

    return check_content(content, filename=rel)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check that cell designation goal conditions require 'explicit: true'."
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="GDScript files to check (defaults to scripts/challenge_stages.gd).",
    )
    args = parser.parse_args(argv)

    target_files = [Path(f) for f in args.files] if args.files else DEFAULT_FILES

    problems: list[str] = []
    for path in target_files:
        problems.extend(check_file(path))

    if problems:
        print("FAILED -- goal default check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print(
        f"goal default check: {len(target_files)} files checked, no unguarded designation goal conditions"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
