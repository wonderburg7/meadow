#!/usr/bin/env python3
"""Check that hive navigation rebuild does not scan rings wider than built chamber.

Why this exists
---------------
`docs/known-pitfalls.md`, "A navigable-area loop one ring wider than the area actually built":
`hive.gd::build_navigation` scanned hex rings 0..reach inclusive;
`world_building.gd`'s own dig loops stop at reach - 1. Ring reach never got a
floor, soil or rock tile, so _is_solid(hex) reported open floor by default,
adding a phantom walkable ring outside the rock wall where bees could wander.

This tool checks that:
1. `scripts/hive.gd` calculates `reach` using the total hive chamber rings
   (interior rings + soil depth + rock rings).
2. The ring iteration in `build_navigation` uses `range(0, reach)` (stopping at
   reach - 1, strictly exclusive of reach).
3. `scripts/world_building.gd` builds outer rock tiles up to the same bound.

Usage
-----
    python tools/nav_reach_check.py [root_dir]
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def check_hive_navigation(text: str) -> list[str]:
    """Check build_navigation in hive.gd for correct ring loop bounds."""
    problems: list[str] = []

    func_match = re.search(
        r"func build_navigation\(\)\s*->\s*void:(.*?)(?=\nfunc |\Z)",
        text,
        re.DOTALL,
    )
    if not func_match:
        return ["scripts/hive.gd: func build_navigation() -> void not found"]

    body = func_match.group(1)

    # 1. reach calculation must include interior_rings, soil_depth, and rock_rings
    reach_match = re.search(
        r"var\s+reach\s*:=\s*int\((.*?)\)",
        body,
    )
    if not reach_match:
        problems.append("scripts/hive.gd: reach calculation not found in build_navigation")
    else:
        reach_expr = reach_match.group(1)
        for term in ("hive_interior_rings", "hive_soil_depth", "hive_rock_rings"):
            if term not in reach_expr:
                problems.append(
                    f"scripts/hive.gd: reach definition in build_navigation missing {term}: {reach_expr.strip()}"
                )

    # 2. Ring loop must iterate over range(0, reach) and not reach + 1 or inclusive bounds
    loop_match = re.search(
        r"for\s+(\w+)\s*:\s*int\s+in\s+range\((.*?)\):",
        body,
    )
    if not loop_match:
        problems.append("scripts/hive.gd: ring loop `for <var>: int in range(...)` not found in build_navigation")
    else:
        args = [a.strip() for a in loop_match.group(2).split(",")]
        if len(args) != 2:
            problems.append(f"scripts/hive.gd: unexpected range arguments in ring loop: {loop_match.group(0)}")
        else:
            start, stop = args[0], args[1]
            if start != "0":
                problems.append(f"scripts/hive.gd: ring loop start must be 0, got {start}")
            if stop != "reach":
                problems.append(
                    f"scripts/hive.gd: ring loop stop bound must be exactly 'reach' (exclusive), got {stop}"
                )

    return problems


def check_world_building_chamber(text: str) -> list[str]:
    """Check _dig_out_chamber in world_building.gd for outer boundary agreement."""
    problems: list[str] = []

    func_match = re.search(
        r"func _dig_out_chamber\((.*?)\)\s*->\s*void:(.*?)(?=\nfunc |\Z)",
        text,
        re.DOTALL,
    )
    if not func_match:
        return ["scripts/world_building.gd: func _dig_out_chamber() -> void not found"]

    body = func_match.group(2)

    # _dig_out_chamber builds bedrock/rock up to interior_rings + soil_depth + rock_rings
    rock_loop = re.search(
        r"for\s+\w+\s*:\s*int\s+in\s+range\(\s*interior_rings\s*\+\s*soil_depth\s*,\s*([^)]+)\):",
        body,
    )
    if not rock_loop:
        problems.append("scripts/world_building.gd: outer rock ring loop not found in _dig_out_chamber")
    else:
        upper_bound = rock_loop.group(1).replace(" ", "")
        expected = "interior_rings+soil_depth+rock_rings"
        if upper_bound != expected:
            problems.append(
                f"scripts/world_building.gd: outer rock ring bound should be {expected}, got {upper_bound}"
            )

    return problems


def check_repo(root: Path) -> list[str]:
    """Check scripts/hive.gd and scripts/world_building.gd."""
    problems: list[str] = []
    hive_path = root / "scripts" / "hive.gd"
    wb_path = root / "scripts" / "world_building.gd"

    if not hive_path.is_file():
        problems.append(f"Missing file: {hive_path}")
    else:
        problems.extend(check_hive_navigation(hive_path.read_text(encoding="utf-8")))

    if not wb_path.is_file():
        problems.append(f"Missing file: {wb_path}")
    else:
        problems.extend(check_world_building_chamber(wb_path.read_text(encoding="utf-8")))

    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check hive navigation loop reach boundary against chamber construction."
    )
    parser.add_argument(
        "root",
        nargs="?",
        default=str(ROOT),
        help="Repository root directory (defaults to repo root).",
    )
    args = parser.parse_args(argv)

    root = Path(args.root).resolve()
    problems = check_repo(root)

    if problems:
        print("FAILED -- nav reach check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print("nav reach check: navigation loop bound matches chamber bounds")
    return 0


if __name__ == "__main__":
    sys.exit(main())
