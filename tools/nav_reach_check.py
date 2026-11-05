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
1. `scripts/hive.gd` calculates `reach` as the exact sum of total chamber rings
   (GameConfig.hive_interior_rings + GameConfig.hive_soil_depth + GameConfig.hive_rock_rings).
   It verifies the arithmetic semantically: mutations like adding + 1, subtracting
   rock rings, or omitting terms are detected and rejected, while ordinary
   formatting changes pass.
2. The ring iteration in `build_navigation` uses `range(0, reach)` (stopping at
   reach - 1, strictly exclusive of reach).
3. `scripts/world_building.gd` builds outer rock tiles up to the same bound.

Usage
-----
    python tools/nav_reach_check.py [root_dir]
"""

from __future__ import annotations

import argparse
import ast
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

EXPECTED_HIVE_TERMS = {
    "GameConfig.hive_interior_rings",
    "GameConfig.hive_soil_depth",
    "GameConfig.hive_rock_rings",
}

EXPECTED_WB_TERMS = {
    "interior_rings",
    "soil_depth",
    "rock_rings",
}


def _extract_sum_terms(expr_str: str) -> list[str] | None:
    """Parse an expression string and return list of additive terms if strictly a sum.

    Returns None if the expression cannot be parsed or is not purely an addition
    of terms (e.g. contains subtraction, multiplication, or other non-additive operators).
    """
    clean_expr = expr_str.strip()
    try:
        parsed = ast.parse(clean_expr, mode="eval")
    except Exception:
        return None

    node = parsed.body

    # Allow wrapping in int(...)
    if (
        isinstance(node, ast.Call)
        and isinstance(node.func, ast.Name)
        and node.func.id == "int"
        and len(node.args) == 1
    ):
        node = node.args[0]

    terms: list[str] = []

    def collect(n: ast.AST) -> bool:
        if isinstance(n, ast.BinOp):
            if isinstance(n.op, ast.Add):
                return collect(n.left) and collect(n.right)
            return False
        terms.append(ast.unparse(n).replace(" ", ""))
        return True

    if not collect(node):
        return None

    return terms


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

    # 1. reach calculation must be the exact sum of the three expected terms
    reach_match = re.search(
        r"var\s+reach\s*:=\s*(.*?)(?=\n\s*(?:var |for |while |if |#|return |\Z))",
        body,
        re.DOTALL,
    )
    if not reach_match:
        problems.append("scripts/hive.gd: reach calculation not found in build_navigation")
    else:
        reach_expr = reach_match.group(1).strip()
        terms = _extract_sum_terms(reach_expr)
        if terms is None:
            problems.append(
                f"scripts/hive.gd: reach definition in build_navigation is not a valid sum expression: {reach_expr}"
            )
        elif sorted(terms) != sorted(EXPECTED_HIVE_TERMS):
            problems.append(
                f"scripts/hive.gd: reach definition must evaluate to the sum of {sorted(EXPECTED_HIVE_TERMS)}, got terms {sorted(terms)}"
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
    rock_loop_matches = re.findall(
        r"for\s+\w+\s*:\s*int\s+in\s+range\((.*?)\):",
        body,
    )
    outer_loop_arg = None
    for args_str in rock_loop_matches:
        parts = [p.strip() for p in args_str.split(",")]
        if len(parts) == 2 and "rock_rings" in parts[1]:
            outer_loop_arg = parts[1]
            break

    if outer_loop_arg is None:
        # Fallback to the second range loop if exactly two loops exist
        two_arg_loops = [
            [p.strip() for p in s.split(",")]
            for s in rock_loop_matches
            if len([p.strip() for p in s.split(",")]) == 2
        ]
        if len(two_arg_loops) >= 2:
            outer_loop_arg = two_arg_loops[1][1]

    if outer_loop_arg is None:
        problems.append("scripts/world_building.gd: outer rock ring loop not found in _dig_out_chamber")
    else:
        terms = _extract_sum_terms(outer_loop_arg)
        if terms is None:
            problems.append(
                f"scripts/world_building.gd: outer rock ring bound is not a valid sum expression: {outer_loop_arg}"
            )
        elif sorted(terms) != sorted(EXPECTED_WB_TERMS):
            problems.append(
                f"scripts/world_building.gd: outer rock ring bound must evaluate to {sorted(EXPECTED_WB_TERMS)}, got {sorted(terms)}"
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
