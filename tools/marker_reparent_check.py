#!/usr/bin/env python3
"""Check GDScript for shared marker reparenting coverage across stage branches.

Why this exists
---------------
`docs/known-pitfalls.md`, "A marker reparented by some branches and not others
ends up in the wrong world":
`challenge_runner.gd::_update_marker` reparents the shared stage marker in two
of its four branches. The branch covering stages 1.2, 1.5, 1.12, and 1.15 set
a hive-local position and showed the marker without reparenting, so after the
meadow tour at 1.7/1.10 the marker stayed in the meadow and a yellow dot
appeared in open ground. If several branches share one node, the parent belongs
in one place that always runs, not in each branch that remembers.

This tool verifies that:
1. Functions managing shared marker display (`_update_marker` in
   `challenge_runner.gd`) assign a world parent for every stage branch that
   shows or positions the marker.
2. The reparenting logic occurs before position assignment so that local
   coordinates are never set in the wrong coordinate space.
3. Every branch where `_set_marker_visible(true)` or `_marker.position` is set
   is covered by an explicit parent assignment.

Usage
-----
    python tools/marker_reparent_check.py [files...]
"""

from __future__ import annotations

import argparse
import ast
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def strip_code(line: str) -> str:
    """Drop string literals and trailing comments from a line of code."""
    out = []
    i = 0
    n = len(line)
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


def extract_function_body(text: str, func_name: str) -> tuple[str, int] | None:
    """Extract the body lines and starting line number of a GDScript function."""
    lines = text.splitlines()
    func_pattern = re.compile(rf"^\s*func\s+{re.escape(func_name)}\s*\(")
    start_idx = None

    for idx, line in enumerate(lines):
        if func_pattern.match(line):
            start_idx = idx
            break

    if start_idx is None:
        return None

    # Collect indented lines
    body_lines = [lines[start_idx]]
    for line in lines[start_idx + 1:]:
        if not line.strip():
            body_lines.append(line)
            continue
        if re.match(r"^\t|^ {4}", line):
            body_lines.append(line)
        else:
            break

    return "\n".join(body_lines), start_idx + 1


def parse_stages_from_condition(condition_str: str) -> list[str]:
    """Parse string literal stage IDs from GDScript conditions like stage_id in [...]."""
    matches = re.findall(r'["\']([0-9]+\.[0-9]+)["\']', condition_str)
    return matches


def check_marker_reparenting(filepath: str, text: str) -> list[str]:
    """Check a script for marker reparenting coverage and ordering."""
    problems: list[str] = []

    # If the file does not have _update_marker, nothing to check here
    func_info = extract_function_body(text, "_update_marker")
    if not func_info:
        return problems

    body_text, start_lineno = func_info
    lines = body_text.splitlines()

    # Track parent assignment branches and marker visible branches
    # We want to ensure:
    # 1. Reparenting happens before position setting
    # 2. Any stage where _marker.position is set has a parent assignment
    parent_stages: set[str] = set()
    visible_stages: set[str] = set()

    reparent_call_line = -1
    first_position_line = -1

    for idx, raw_line in enumerate(lines):
        lineno = start_lineno + idx
        clean = strip_code(raw_line)

        # Look for reparenting call
        if "_marker.reparent(" in raw_line:
            reparent_call_line = lineno

        # Look for position assignment
        if "_marker.position" in raw_line and first_position_line == -1:
            first_position_line = lineno

        # Parse parent assignment branches
        if "marker_parent" in raw_line and ("=" in raw_line or "main." in raw_line):
            # Check previous line or current line for condition
            cond_lines = " ".join(lines[max(0, idx - 2):idx + 1])
            stages = parse_stages_from_condition(cond_lines)
            parent_stages.update(stages)

        # Parse position/visible branches
        if "_marker.position" in raw_line or "_set_marker_visible(true)" in raw_line:
            cond_lines = " ".join(lines[max(0, idx - 5):idx + 1])
            stages = parse_stages_from_condition(cond_lines)
            visible_stages.update(stages)

    if reparent_call_line == -1:
        problems.append(
            f"{filepath}:{start_lineno}: _update_marker lacks _marker.reparent call"
        )
        return problems

    if first_position_line != -1 and reparent_call_line > first_position_line:
        problems.append(
            f"{filepath}:{reparent_call_line}: _marker.reparent is called at line "
            f"{reparent_call_line} after _marker.position was assigned at line {first_position_line}"
        )

    # Check for visible stages missing from parent assignment
    unparented = visible_stages - parent_stages
    if unparented:
        stages_sorted = sorted(list(unparented))
        problems.append(
            f"{filepath}:{start_lineno}: stages {stages_sorted} set marker position "
            "or visibility but have no marker_parent assigned before reparenting"
        )

    return problems


def check_file(path: Path) -> list[str]:
    """Check a single GDScript file."""
    try:
        content = path.read_text(encoding="utf-8")
    except Exception as exc:
        return [f"{path}: could not read: {exc}"]
    return check_marker_reparenting(str(path), content)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check that shared stage marker reparenting covers all branches."
    )
    parser.add_argument(
        "files",
        nargs="*",
        default=["scripts/challenge_runner.gd"],
        help="GDScript files to check (default: scripts/challenge_runner.gd)",
    )
    args = parser.parse_args(argv)

    all_problems: list[str] = []
    for file_str in args.files:
        path = Path(file_str)
        if not path.is_file():
            # If default file does not exist, report error
            all_problems.append(f"{file_str}: file not found")
            continue
        problems = check_file(path)
        all_problems.extend(problems)

    if all_problems:
        print("FAILED -- marker reparent check found problems:", file=sys.stderr)
        for prob in all_problems:
            print(f"  {prob}", file=sys.stderr)
        return 1

    print(f"OK -- marker reparent check clean ({len(args.files)} file(s) checked).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
