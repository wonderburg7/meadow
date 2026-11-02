#!/usr/bin/env python3
"""Check GDScript source files for variable declarations shadowing built-in properties.

Why this exists
---------------
`docs/known-pitfalls.md`, "Variable shadowing built-in properties":
`offset` on Polygon2D, `scale` on Node2D, and `name` on Node: declaring a
variable or loop variable shadowing built-in properties causes runtime issues
or GDScript shadowed-variable warnings (`SHADOWED_VARIABLE_BASE_CLASS`).

This tool scans `scripts/**/*.gd` for script-level or local variable declarations
(`var <name>` or `for <name> in`) that match built-in properties of the script's
base class hierarchy (e.g. `Polygon2D`, `Node2D`, `CanvasItem`, `Node`).

Usage
-----
    python tools/variable_shadow_check.py [files...]
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Built-in properties inherited by common Godot base classes.
CLASS_PROPERTIES: dict[str, set[str]] = {
    "Object": set(),
    "RefCounted": set(),
    "Node": {"name", "owner", "process_mode"},
    "CanvasItem": {"visible", "modulate", "self_modulate", "z_index"},
    "Node2D": {"position", "rotation", "scale", "skew", "transform", "global_position", "global_rotation", "global_scale"},
    "Polygon2D": {"offset", "polygon", "uv", "color", "texture", "skeleton"},
    "Control": {"size", "position", "rotation", "scale", "pivot_offset", "custom_minimum_size"},
    "CanvasLayer": {"layer", "visible", "offset", "rotation", "scale", "transform", "custom_viewport"},
}

# Base class inheritance map
CLASS_PARENTS: dict[str, str] = {
    "RefCounted": "Object",
    "Node": "Object",
    "CanvasItem": "Node",
    "Node2D": "CanvasItem",
    "Polygon2D": "Node2D",
    "Control": "CanvasItem",
    "CanvasLayer": "Node",
}

# Explicit custom base classes in scripts/
CUSTOM_BASE_PARENTS: dict[str, str] = {
    "GamePanel": "CanvasLayer",
}


def get_inherited_properties(base_class: str) -> set[str]:
    """Return all built-in property names inherited by base_class."""
    props: set[str] = set()
    current: str | None = base_class
    while current:
        if current in CLASS_PROPERTIES:
            props.update(CLASS_PROPERTIES[current])
        current = CLASS_PARENTS.get(current) or CUSTOM_BASE_PARENTS.get(current)
    return props


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
    """Check a single GDScript file for variables shadowing inherited properties."""
    path = Path(filepath)
    if text is None:
        text = path.read_text(encoding="utf-8")

    try:
        rel_path = path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        rel_path = path.as_posix()

    lines = text.splitlines()

    # Determine base class
    base_class = "RefCounted"  # default base class in GDScript if not specified
    for raw_line in lines:
        stripped = strip_code(raw_line).strip()
        m_extends = re.match(r"^extends\s+([a-zA-Z0-9_]+)", stripped)
        if m_extends:
            base_class = m_extends.group(1)
            break

    inherited_props = get_inherited_properties(base_class)
    if not inherited_props:
        return []

    problems: list[str] = []

    # Patterns matching variable declaration or loop variable
    # var x ... or var x: Type ... or var x := ...
    # for x in ...
    var_re = re.compile(r"^\s*(?:@\w+(?:\([^)]*\))?\s+)*var\s+([a-zA-Z_]\w*)\b")
    for_re = re.compile(r"^\s*for\s+([a-zA-Z_]\w*)\s+in\b")

    for line_no, raw_line in enumerate(lines, 1):
        stripped = strip_code(raw_line)
        if not stripped.strip():
            continue

        var_match = var_re.search(stripped)
        if var_match:
            var_name = var_match.group(1)
            if var_name in inherited_props:
                problems.append(
                    f"{rel_path}:{line_no} variable '{var_name}' shadows "
                    f"built-in property from {base_class}: {raw_line.strip()}"
                )
            continue

        for_match = for_re.search(stripped)
        if for_match:
            for_var = for_match.group(1)
            if for_var in inherited_props:
                problems.append(
                    f"{rel_path}:{line_no} loop variable '{for_var}' shadows "
                    f"built-in property from {base_class}: {raw_line.strip()}"
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
        description="Check GDScript files for variables shadowing built-in properties."
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
        print("FAILED -- variable shadow check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print(
        f"variable shadow check: {len(files)} files checked, no shadowed properties"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
