#!/usr/bin/env python3
"""Check GDScript steering code for premature obstacle commitment drops.

Why this exists
---------------
`docs/known-pitfalls.md`, "Commitments dropped on a single frame":
`skirt_obstacle` is held so a bee does not re-pick which way round an obstacle to
go and flip at the halfway angle. Clearing it the first frame the way looks clear
defeats that, because the check can momentarily miss part-way past. Any hysteresis
needs to survive one bad frame (e.g., SKIRT_FORGET_FRAMES / frame counter).

This tool scans GDScript files to ensure `skirt_obstacle = null` is enclosed
inside an active debounce conditional block rather than being cleared directly or
moved outside the debounce condition within obstacle avoidance logic.
It also rejects single-frame thresholds (such as >= 1 or > 0) within supported
debounce shapes, while accepting intentional navigation resets.

Usage
-----
    python tools/skirt_commitment_check.py [files...]
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def strip_code(line: str) -> str:
    """Drop string literals and trailing comments from a line of code."""
    out: list[str] = []
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


@dataclass
class ScopeBlock:
    indent: int
    is_null_check: bool = False
    is_debounce_guard: bool = False
    has_meaningful_debounce: bool = False


def is_single_frame_condition(expr: str) -> bool:
    """Check whether a debounce condition only requires a single frame."""
    # Look for patterns like >= 1, == 1, > 0, <= 1, etc.
    # Single frame: >= 1, > 0, == 1
    if re.search(r'>=\s*1\b', expr) or re.search(r'>\s*0\b', expr) or re.search(r'==\s*1\b', expr):
        return True
    return False


def is_multi_frame_condition(expr: str) -> bool:
    """Check whether a debounce condition checks frames with a multi-frame threshold."""
    # Match patterns like:
    # skirt_clear_frames >= SKIRT_FORGET_FRAMES
    # frames >= 2, count > 1, etc.
    # Disallow single-frame conditions
    if is_single_frame_condition(expr):
        return False
    if re.search(r'\b(?:skirt_clear_frames|clear_frames|frames|count)\b\s*(?:>=|>|==)\s*\w+', expr):
        return True
    return False


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

    # Scope stack tracking block indentation and conditional status
    scope_stack: list[ScopeBlock] = []

    # Regex patterns
    # Match null check on blocker / obstacle, e.g. `if blocker == null:` or `if not blocker:`
    re_null_check = re.compile(r'^\s*if\s+(?:(?:var\s+)?\w+\s*==\s*null|not\s+\w+)\s*:', re.IGNORECASE)
    # Match general `if` / `elif` statement
    re_if = re.compile(r'^\s*(?:if|elif)\s+(.+?):')
    # Match skirt_obstacle assignment to null
    re_skirt_clear = re.compile(r'\b(?:bee\.)?skirt_obstacle\s*=\s*null\b')

    for line_no, raw_line in enumerate(lines, 1):
        stripped = strip_code(raw_line)
        line_content = stripped.strip()
        if not line_content:
            continue

        # Calculate indentation (expand tabs if any)
        # Note: Godot standard is tabs (or spaces). We can count leading whitespace length,
        # but to be consistent, convert leading tabs to 4 spaces or count tab depth if tabs used.
        indent = len(raw_line) - len(raw_line.lstrip())

        # Pop scopes that have ended
        while scope_stack and indent <= scope_stack[-1].indent:
            scope_stack.pop()

        # Check if inside any null blocker check
        in_null_context = any(s.is_null_check for s in scope_stack)

        # Check if this line is an `if` / `elif`
        m_if = re_if.match(stripped)
        if m_if:
            cond_expr = m_if.group(1)
            is_null = bool(re_null_check.match(stripped) and ("blocker" in stripped or "obstacle" in stripped))
            is_debounce = False
            has_meaningful = False

            if in_null_context or is_null:
                if is_multi_frame_condition(cond_expr):
                    is_debounce = True
                    has_meaningful = True
                elif is_single_frame_condition(cond_expr) and re.search(
                    r'\b(?:skirt_clear_frames|clear_frames|frames|count)\b', cond_expr
                ):
                    is_debounce = True
                    has_meaningful = False

            scope_stack.append(ScopeBlock(
                indent=indent,
                is_null_check=is_null,
                is_debounce_guard=is_debounce,
                has_meaningful_debounce=has_meaningful,
            ))
            continue

        # Check if line defines a new block (e.g., else, for, while, func)
        if line_content.endswith(":"):
            scope_stack.append(ScopeBlock(
                indent=indent,
                is_null_check=False,
                is_debounce_guard=False,
                has_meaningful_debounce=False,
            ))

        # Check for skirt_obstacle = null assignment
        if re_skirt_clear.search(stripped):
            if in_null_context:
                # We are inside a null-blocker check context.
                # Must be enclosed inside an active debounce conditional with meaningful debounce.
                # Active debounce conditional means an enclosing scope in scope_stack has is_debounce_guard.
                debounce_scopes = [s for s in scope_stack if s.is_debounce_guard]
                if not debounce_scopes:
                    problems.append(
                        f"{rel_path}:{line_no}: skirt_obstacle cleared on a single null-blocker frame "
                        f"outside debounce conditional: {line_content}"
                    )
                else:
                    # Check if any enclosing debounce scope has meaningful debounce
                    if not any(s.has_meaningful_debounce for s in debounce_scopes):
                        problems.append(
                            f"{rel_path}:{line_no}: skirt_obstacle cleared using single-frame threshold "
                            f"in debounce conditional: {line_content}"
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
        else:
            problems.append(f"File not found: {path}")

    if problems:
        print("FAILED -- skirt commitment check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print(f"skirt commitment check: {len(files)} files checked, all obstacle commitments debounced properly")
    return 0


if __name__ == "__main__":
    sys.exit(main())
