#!/usr/bin/env python3
"""Check GDScript steering code for premature obstacle commitment drops.

Why this exists
---------------
`docs/known-pitfalls.md`, "Commitments dropped on a single frame":
`skirt_obstacle` is held so a bee doesn't re-pick which way round an obstacle to
go and flip at the halfway angle. Clearing it the first frame the way looks clear
defeats that, because the check can momentarily miss part-way past. Any hysteresis
needs to survive one bad frame (e.g., SKIRT_FORGET_FRAMES / frame counter).

This tool scans GDScript files to ensure `skirt_obstacle = null` is not executed
directly when a blocker check returns null without checking a debounce/frame counter.

Usage
-----
    python tools/skirt_commitment_check.py [files...]
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
    """Check a single GDScript file for premature skirt commitment drops."""
    path = Path(filepath)
    if text is None:
        text = path.read_text(encoding="utf-8")

    try:
        rel_path = path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        rel_path = path.as_posix()

    lines = text.splitlines()
    problems: list[str] = []

    # Look for functions where avoid_obstacles or steering logic runs.
    # Specifically, inside an `if blocker == null:` (or similar null check on blocker/obstacle),
    # setting `skirt_obstacle = null` immediately without an intervening frame check (like `skirt_clear_frames` or `>=`)
    # is a bug.
    in_null_block = False
    null_block_indent = -1
    has_frame_guard = False

    for line_no, raw_line in enumerate(lines, 1):
        stripped = strip_code(raw_line)
        if not stripped.strip():
            continue

        indent = len(raw_line) - len(raw_line.lstrip())

        if in_null_block:
            if indent <= null_block_indent:
                in_null_block = False
                has_frame_guard = False
            else:
                if re.search(r'\b(?:skirt_clear_frames|frames|count)\b\s*(?:>=|>|==)', stripped):
                    has_frame_guard = True
                if re.search(r'\b(?:bee\.)?skirt_obstacle\s*=\s*null\b', stripped):
                    if not has_frame_guard:
                        problems.append(
                            f"{rel_path}:{line_no}: skirt_obstacle cleared on a single null-blocker frame "
                            f"without frame debounce guard: {raw_line.strip()}"
                        )

        # Detect entering an `if blocker == null:` or `if not blocker:` block
        m = re.match(r'^\s*if\s+(?:(?:var\s+)?\w+\s*==\s*null|not\s+\w+)\s*:', stripped)
        if m and ("blocker" in stripped or "obstacle" in stripped):
            in_null_block = True
            null_block_indent = indent
            has_frame_guard = False

    return problems


def tracked_gd_files(root: Path) -> list[Path]:
    """Find all GDScript files in scripts/."""
    scripts_dir = root / "scripts"
    if not scripts_dir.exists():
        return []
    return sorted(scripts_dir.rglob("*.gd"))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check GDScript steering code for premature obstacle commitment drops."
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
        print("FAILED -- skirt commitment check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print(f"skirt commitment check: {len(files)} files checked, all obstacle commitments debounced properly")
    return 0


if __name__ == "__main__":
    sys.exit(main())
