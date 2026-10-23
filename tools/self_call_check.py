#!/usr/bin/env python3
"""Check GDScript source files for bare recursive function self-calls.

Why this exists
---------------
`docs/known-pitfalls.md`, "A refactor leaves a function calling itself":
a refactor left a function calling itself unconditionally, causing a 4 fps
drop from stack recursion that went unnoticed.

This tool scans `scripts/**/*.gd` for bare `<name>(` calls inside the body
of `func <name>(`. Qualified calls like `super.<name>(`, `self.<name>(` or
`other.<name>(` are ignored, as are calls inside comments or strings.

Any intended recursion on `origin/master` is recorded in `ALLOWLIST` with
a one-line explanation.

Usage
-----
    python tools/self_call_check.py [files...]
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Intended recursion on origin/master -> reason.
ALLOWLIST: dict[tuple[str, str], str] = {
    ("scripts/progression.gd", "_add_with_prerequisites"):
        "Recursive prerequisite gathering for skill tree paths.",
    ("scripts/scenario_actions.gd", "_resolve_bees"):
        "Recursive resolution of nested bee specifiers.",
    ("scripts/scenario_actions.gd", "_force_layout"):
        "Recursive UI layout pass down container hierarchy.",
    ("scripts/scenario_actions.gd", "_collect_empty_labels"):
        "Recursive node traversal collecting empty visible labels.",
    ("scripts/scenario_actions.gd", "_collect_collapsed_controls"):
        "Recursive node traversal collecting collapsed controls.",
    ("scripts/settings_catalogue.gd", "_cascade_dependents_off_static"):
        "Recursive setting dependency cascading.",
}


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
    """Check a single GDScript file for bare self-calls."""
    path = Path(filepath)
    if text is None:
        text = path.read_text(encoding="utf-8")

    try:
        rel_path = path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        rel_path = path.as_posix()

    lines = text.splitlines()
    problems: list[str] = []
    scope_stack: list[dict[str, object]] = []

    for line_no, raw_line in enumerate(lines, 1):
        stripped = strip_code(raw_line)
        if not raw_line.strip() or raw_line.strip().startswith("#"):
            continue

        indent = len(raw_line) - len(raw_line.lstrip())

        while scope_stack and indent <= int(scope_stack[-1]["indent"]):
            scope_stack.pop()

        m = re.match(
            r"^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:static\s+)?func\s+(\w+)",
            stripped,
        )
        if m:
            func_name = m.group(1)
            in_header = ":" not in stripped
            scope_stack.append({
                "name": func_name,
                "indent": indent,
                "in_header": in_header,
            })
            continue

        if scope_stack:
            top = scope_stack[-1]
            if bool(top["in_header"]):
                if ":" in stripped:
                    top["in_header"] = False
                continue

            func_name = str(top["name"])
            pattern = r"(?<![\w.$])" + re.escape(func_name) + r"\s*\("
            if re.search(pattern, stripped):
                key = (rel_path, func_name)
                if key in ALLOWLIST:
                    continue
                problems.append(
                    f"{rel_path}:{line_no} in function {func_name}(): "
                    f"self-call -> {raw_line.strip()}"
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
        description="Check GDScript files for bare self-calls."
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
        print("FAILED -- self-call check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print(
        f"self call check: {len(files)} files checked, no unexpected self-calls"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
