#!/usr/bin/env python3
"""Check GDScript nearest-candidate queries for self-exclusion / cooldown guards.

Why this exists
---------------
`docs/known-pitfalls.md`, "Nearest-thing searches picking the thing you're standing on":
A flower recharges every frame, so the one a bee just drained keeps winning at
distance zero. Any "find the nearest X" needs an exclusion. In Meadow,
`BeeForaging.nearest_flower()` enforces this via the bee's personal
`flower_cooldowns` dictionary checked outside the relaxed `strict` block.
Without this guard, a bee with nothing else in range falls straight back onto
the exact flower she just left, landing repeatedly forever instead of giving
search behaviour a chance to run.

This tool verifies that nearest-flower search routines in `scripts/**/*.gd`
properly exclude candidate flowers currently on personal cooldown for the bee.

Usage
-----
    python tools/nearest_exclusion_check.py [files...]
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
    """Check a single GDScript file for nearest-thing exclusion compliance."""
    path = Path(filepath)
    if text is None:
        text = path.read_text(encoding="utf-8")

    try:
        rel_path = path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        rel_path = path.as_posix()

    lines = text.splitlines()
    problems: list[str] = []

    # Look for nearest_flower definitions and verify that flower_cooldowns is consulted.
    in_target_func = False
    target_func_indent = -1
    target_func_name = ""
    has_cooldown_check = False
    cooldown_inside_strict = False
    in_strict_block = False
    strict_block_indent = -1

    for line_no, raw_line in enumerate(lines, 1):
        stripped = strip_code(raw_line)
        if not raw_line.strip() or raw_line.strip().startswith("#"):
            continue

        indent = len(raw_line) - len(raw_line.lstrip())

        if in_target_func:
            if indent <= target_func_indent:
                if not has_cooldown_check:
                    problems.append(
                        f"{rel_path}: function {target_func_name}() missing flower_cooldowns exclusion check"
                    )
                elif cooldown_inside_strict:
                    problems.append(
                        f"{rel_path}: function {target_func_name}() flower_cooldowns check is nested inside strict block (must apply unconditionally)"
                    )
                in_target_func = False
                has_cooldown_check = False
                cooldown_inside_strict = False
                in_strict_block = False
            else:
                if in_strict_block and indent <= strict_block_indent:
                    in_strict_block = False

                if re.match(r"^\s*if\s+(?:strict|is_strict)\b.*:", stripped):
                    in_strict_block = True
                    strict_block_indent = indent

                if re.search(r"(?<!predator_)flower_cooldowns\b", stripped):
                    has_cooldown_check = True
                    if in_strict_block:
                        cooldown_inside_strict = True

        m = re.match(
            r"^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:static\s+)?func\s+(\w+)",
            stripped,
        )
        if m:
            func_name = m.group(1)
            if func_name == "nearest_flower":
                in_target_func = True
                target_func_indent = indent
                target_func_name = func_name
                has_cooldown_check = False
                cooldown_inside_strict = False
                in_strict_block = False

    if in_target_func:
        if not has_cooldown_check:
            problems.append(
                f"{rel_path}: function {target_func_name}() missing flower_cooldowns exclusion check"
            )
        elif cooldown_inside_strict:
            problems.append(
                f"{rel_path}: function {target_func_name}() flower_cooldowns check is nested inside strict block (must apply unconditionally)"
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
        description="Check GDScript nearest-candidate queries for self-exclusion / cooldown guards."
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
        print("FAILED -- nearest exclusion check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print(
        f"nearest exclusion check: {len(files)} files checked, nearest queries properly exclude cooldowns"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
