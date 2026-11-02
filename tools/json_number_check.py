#!/usr/bin/env python3
"""Check GDScript files for uncoerced JSON numbers in membership and lookup checks.

Why this exists
---------------
`docs/known-pitfalls.md`, "JSON numbers come back as floats, and `Array.has()` is type-strict":
`JSON.parse_string` turns numbers into floats (`1` -> `1.0`). In GDScript, `[1.0].has(1)` is false.
Reading numeric values or elements from parsed JSON data structures and checking them against
arrays without `int()` coercion causes silent lookup failures.

This tool scans `scripts/**/*.gd` for patterns where values extracted from JSON dictionaries
or deserialised numeric containers are tested via `.has()` or `.find()` without an explicit
`int(...)` cast, while properly tracking loop scope and distinguishing numeric containers from
string or key collections.

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

# Known numeric keys or attributes in JSON payloads that return numbers or number lists
NUMERIC_KEY_PATTERN = re.compile(
    r"""(?i)["'](?:completed_challenges|level|levels|stage|stages|count|version|seed)["']"""
)

# Known string or general dictionary keys that are not raw numbers
NON_NUMERIC_KEY_PATTERN = re.compile(
    r"""(?i)["'](?:names?|keys?|tags?|prefs|preferences|settings?|strings?|paths?|slugs?|slots?|preset|ids?)["']"""
)


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


def get_indent(line: str) -> int:
    """Calculate the indentation level of a line (tabs count as 4 spaces or 1 level)."""
    expanded = line.expandtabs(4)
    return len(expanded) - len(expanded.lstrip())


def is_numeric_json_container(container_expr: str) -> bool:
    """Determine whether a container expression likely produces numeric elements."""
    if NON_NUMERIC_KEY_PATTERN.search(container_expr):
        return False
    if NUMERIC_KEY_PATTERN.search(container_expr):
        return True
    return False


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

    # Loop pattern: for <var> in <container>:
    loop_pattern = re.compile(
        r"^\s*for\s+([a-zA-Z_]\w*)\s*(?::\s*[^=\s]+)?\s+in\s+(.+):"
    )

    # Membership pattern: <target>.has(<arg>) or <target>.find(<arg>)
    has_call_pattern = re.compile(
        r"\b([a-zA-Z_]\w*)\.(?:has|find)\s*\(\s*([^)]+?)\s*\)"
    )

    # Direct raw .get lookup pattern: <dict>.get("key", default)
    # E.g. levels.has(data.get("level"))
    raw_get_pattern = re.compile(
        r"""\b[a-zA-Z_]\w*\.get\s*\(\s*(["'][^"']+["'])"""
    )

    # Active tainted iterators: dict[var_name, tuple[line_no, indent_level]]
    uncoerced_iterators: dict[str, tuple[int, int]] = {}

    for line_no, raw_line in enumerate(lines, 1):
        if not raw_line.strip() or raw_line.strip().startswith("#"):
            continue

        indent = get_indent(raw_line)

        # Expire any taint whose loop scope has ended (indent <= loop indent)
        expired = [
            var for var, (_, loop_indent) in uncoerced_iterators.items()
            if indent <= loop_indent
        ]
        for var in expired:
            del uncoerced_iterators[var]

        # Reset all taints if function/class level boundary reached
        if indent == 0 or raw_line.lstrip().startswith("func ") or raw_line.lstrip().startswith("static func "):
            uncoerced_iterators.clear()

        # 1. Check for loops over numeric JSON data
        m_loop = loop_pattern.match(raw_line)
        if m_loop:
            var_name, container = m_loop.group(1), m_loop.group(2)
            if (".get(" in container or "[" in container) and is_numeric_json_container(container):
                uncoerced_iterators[var_name] = (line_no, indent)
                continue

        # 2. Check for .has(...) or .find(...) calls on this line
        for m_has in has_call_pattern.finditer(raw_line):
            target_obj, arg_expr = m_has.group(1), m_has.group(2).strip()

            # Direct raw get numeric lookup: arr.has(data.get("level")) without int(...)
            if ".get(" in arg_expr and not arg_expr.startswith("int(") and not arg_expr.startswith("str("):
                m_get = raw_get_pattern.search(arg_expr)
                if m_get and is_numeric_json_container(m_get.group(1)):
                    problems.append(
                        f"{rel_path}:{line_no} uncoerced JSON numeric get '{arg_expr}' "
                        f"checked with {target_obj}.has/{target_obj}.find: {raw_line.strip()}"
                    )
                    continue

            # Loop variable lookup
            if arg_expr in uncoerced_iterators:
                # If the line does not coerce the variable with int(...)
                # e.g., if int(arg_expr) is not used in the has call or before it
                if f"int({arg_expr})" not in raw_line:
                    problems.append(
                        f"{rel_path}:{line_no} uncoerced JSON loop variable '{arg_expr}' "
                        f"checked with {target_obj}.has/{target_obj}.find: {raw_line.strip()}"
                    )

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
