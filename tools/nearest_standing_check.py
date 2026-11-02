#!/usr/bin/env python3
"""Check GDScript sources for nearest-candidate exclusions.

Why this exists
---------------
`docs/known-pitfalls.md`, "Nearest-thing searches picking the thing you're standing on":
"A flower recharges every frame, so the one a bee just drained keeps winning at
distance zero. Any 'find the nearest X' needs an exclusion."

In `scripts/bee_foraging.gd::nearest_flower`, flower search uses a candidate
acceptance predicate. A bee's memory of a recently drained or rejected flower
(`bee.flower_cooldowns`) and predator encounters (`bee.predator_flower_cooldowns`)
must be checked to prevent a bee from repeatedly targeting the flower under her feet.

This tool checks that `nearest_flower` excludes candidates using cooldown checks.

Usage
-----
    python tools/nearest_standing_check.py [files...]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_TARGET = ROOT / "scripts" / "bee_foraging.gd"


def extract_function_body(source: str, func_name: str) -> str | None:
    """Extract the body of a top-level function in GDScript source."""
    pattern = re.compile(
        r"^(?:static\s+)?func\s+" + re.escape(func_name) + r"\s*\([^)]*\).*?:[ \t]*(?:\n|\Z)",
        re.MULTILINE,
    )
    match = pattern.search(source)
    if not match:
        return None

    body_start = match.end()
    lines = source[body_start:].splitlines(keepends=True)
    body_lines: list[str] = []

    for line in lines:
        if line.strip() and not line.startswith((" ", "\t", "#")):
            break
        body_lines.append(line)

    return "".join(body_lines)


def check_foraging_nearest_exclusions(text: str, file_path: str = "scripts/bee_foraging.gd") -> list[str]:
    """Check that nearest_flower in bee_foraging.gd checks cooldown exclusions."""
    diagnostics: list[str] = []
    body = extract_function_body(text, "nearest_flower")
    if body is None:
        return diagnostics

    if "flower_cooldowns" not in body:
        diagnostics.append(
            f"{file_path}: nearest_flower missing candidate cooldown exclusion 'flower_cooldowns'"
        )

    return diagnostics


def check_file(filepath: Path | str, text: str | None = None) -> list[str]:
    """Check a single GDScript file for nearest-thing exclusion compliance."""
    path = Path(filepath)
    if text is None:
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as err:
            return [f"{path}: read error: {err}"]

    try:
        rel_path = path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        rel_path = path.as_posix()

    if rel_path == "scripts/bee_foraging.gd" or "nearest_flower" in text:
        return check_foraging_nearest_exclusions(text, rel_path)

    return []


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check GDScript files for nearest-candidate exclusions."
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="Files to check (defaults to scripts/bee_foraging.gd).",
    )
    args = parser.parse_args(argv)

    if args.files:
        target_paths = [Path(f) for f in args.files]
    else:
        target_paths = [DEFAULT_TARGET]

    all_diagnostics: list[str] = []

    for target in target_paths:
        if not target.is_file():
            all_diagnostics.append(f"{target}: file not found")
            continue

        diagnostics = check_file(target)
        all_diagnostics.extend(diagnostics)

    if all_diagnostics:
        print("FAILED -- nearest standing check found problems:", file=sys.stderr)
        for diag in all_diagnostics:
            print(f"  {diag}", file=sys.stderr)
        return 1

    print(f"nearest standing check: {len(target_paths)} file(s) checked, no missing exclusions found")
    return 0


if __name__ == "__main__":
    sys.exit(main())
