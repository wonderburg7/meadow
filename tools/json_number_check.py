#!/usr/bin/env python3
"""Check GDScript files for uncoerced JSON numbers in membership and equality checks.

Why this exists
---------------
`docs/known-pitfalls.md`, "JSON numbers come back as floats, and `Array.has()` is type-strict":
`JSON.parse_string` turns numbers into floats (`1` -> `1.0`). In GDScript, `[1.0].has(1)` is false.
Reading numeric values or elements from parsed JSON data structures and checking them against
arrays or integer targets without `int()` coercion causes silent lookup failures.

This tool scans `scripts/**/*.gd` for patterns where values extracted from JSON dictionaries
or deserialised containers are tested via `.has()`, `.find()`, or compared directly without
an explicit `int(...)` cast.

Usage
-----
    python tools/json_number_check.py [files...]
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def strip_code(line: str) -> str:
    """Drop string literals and trailing comments from a line of code."""
    out, i, n = [], 0, len(line)
    while i < n:
        c = line[i]
        if c == "#":
            break
        if c in ('"', "'"):
            quote = c
            i += 1
            while i < n:
                if line[i] == "\\":
                    i += 2
                    continue
                if line[i] == quote:
                    i += 1
                    break
                i += 1
            out.append('""')
            continue
        out.append(c)
        i += 1
    return "".join(out)


def check_file(filepath: Path | str, text: str | None = None) -> list[str]:
    """Check a single GDScript file for uncoerced JSON number lookups."""
    path = Path(filepath)
    if text is None:
        text = path.read_text(encoding="utf-8")

    try:
        rel_path = path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        rel_path = path.as_posix()

    lines = text.splitlines()
    problems: list[str] = []

    # Track variables known to hold raw data from JSON or parsed dictionary
    # E.g. in loops: for val in data.get(...): if not arr.has(val): ...
    loop_var_pattern = re.compile(
        r"^\s*for\s+([a-zA-Z_]\w*)\s*(?::\s*\w+)?\s+in\s+([a-zA-Z_]\w*(?:\.get\([^)]+\)|\[[^\]]+\])):"
    )
    # Check if a variable assigned directly from .get(...) or [...] is used in .has() or .find()
    # without int(...) coercion
    has_call_pattern = re.compile(
        r"\b([a-zA-Z_]\w*)\.(?:has|find)\s*\(\s*([a-zA-Z_]\w*)\s*\)"
    )

    uncoerced_iterators: dict[str, int] = {}

    for line_no, raw_line in enumerate(lines, 1):
        stripped = strip_code(raw_line)
        if not stripped.strip():
            continue

        # Check for uncoerced iteration over data.get(...)
        m_loop = loop_var_pattern.match(stripped)
        if m_loop:
            var_name, container = m_loop.group(1), m_loop.group(2)
            if "data" in container or "json" in container.lower() or "parsed" in container.lower():
                uncoerced_iterators[var_name] = line_no
                continue

        # Check if an uncoerced loop variable is checked with .has(var) or .find(var)
        for m_has in has_call_pattern.finditer(stripped):
            target_obj, arg_var = m_has.group(1), m_has.group(2)
            if arg_var in uncoerced_iterators:
                # If the line does not coerce with int(arg_var)
                if f"int({arg_var})" not in stripped:
                    problems.append(
                        f"{rel_path}:{line_no} uncoerced JSON loop variable '{arg_var}' "
                        f"checked with {target_obj}.has/{target_obj}.find: {raw_line.strip()}"
                    )

        # Clear iterators when indent drops or exits loop scope
        indent = len(raw_line) - len(raw_line.lstrip())
        if indent == 0:
            uncoerced_iterators.clear()

    return problems


def tracked_gd_files(root: Path) -> list[Path]:
    """Find all GDScript files in scripts/."""
    scripts_dir = root / "scripts"
    if not scripts_dir.exists():
        return []
    return sorted(scripts_dir.rglob("*.gd"))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check GDScript files for uncoerced JSON numbers in membership checks."
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="GDScript files to check (defaults to scripts/**/*.gd).",
    )
    args = parser.parse_args(argv)

    if args.files:
        files = [Path(f) for f in args.files]
    else:
        files = tracked_gd_files(ROOT)

    problems: list[str] = []
    for path in files:
        if path.is_file():
            problems.extend(check_file(path))

    if problems:
        print("FAILED -- JSON number check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print(
        f"json number check: {len(files)} files checked, no uncoerced JSON number lookups"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
