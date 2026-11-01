#!/usr/bin/env python3
"""Check that nearest flower search excludes recently drained or visited flowers.

Why this exists
---------------
`docs/known-pitfalls.md`, "Nearest-thing searches picking the thing you're standing on":
"A flower recharges every frame, so the one a bee just drained keeps winning at
distance zero. Any 'find the nearest X' needs an exclusion."

In `scripts/bee_foraging.gd`, `nearest_flower()` builds an `accept` callable for
flower candidates. Recently visited or drained flowers recorded in the bee's
`flower_cooldowns` dictionary must be rejected unconditionally before any relaxed
search pass (`if strict:`), and `finish_collecting()` / `reject_flower()` must
update `bee.flower_cooldowns`.

Usage
-----
    python tools/drained_flower_exclusion_check.py [files...]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def strip_comments(text: str) -> str:
    """Strip comment lines to avoid matching mentions of code patterns in comments."""
    cleaned = []
    for line in text.splitlines():
        code = line.split("#")[0]
        cleaned.append(code)
    return "\n".join(cleaned)


def check_nearest_flower_exclusion(
    content: str, filepath: str = "scripts/bee_foraging.gd"
) -> list[str]:
    """Check bee_foraging.gd content for drained flower exclusion rules."""
    problems: list[str] = []

    # Find the nearest_flower function definition
    func_pattern = re.compile(
        r"static\s+func\s+nearest_flower\s*\([^)]*\)\s*->\s*Node2D\s*:",
        re.MULTILINE,
    )
    match = func_pattern.search(content)
    if not match:
        problems.append(
            f"{filepath}: static func nearest_flower(...) not found"
        )
        return problems

    start_pos = match.end()
    # Find the extent of the nearest_flower function body (up to next function at column 0)
    rest_lines = content[start_pos:].splitlines()
    body_lines: list[str] = []
    for line in rest_lines:
        if line.startswith("func ") or line.startswith("static func "):
            break
        body_lines.append(line)
    body_text = "\n".join(body_lines)
    code_text = strip_comments(body_text)

    # Verify flower_cooldowns check exists in accept lambda
    if "flower_cooldowns" not in code_text:
        problems.append(
            f"{filepath}: nearest_flower does not reference flower_cooldowns"
        )
        return problems

    cooldown_check = re.search(
        r"if\s+bee\.flower_cooldowns\.has\s*\(\s*(\w+)\s*\)",
        code_text,
    )
    if not cooldown_check:
        problems.append(
            f"{filepath}: nearest_flower accept predicate lacks bee.flower_cooldowns.has(...) check"
        )
    else:
        # Verify it occurs before code statement 'if strict:'
        strict_match = re.search(r"^\s*if\s+strict\s*:", code_text, re.MULTILINE)
        if strict_match:
            strict_idx = strict_match.start()
            cooldown_idx = cooldown_check.start()
            if cooldown_idx > strict_idx:
                problems.append(
                    f"{filepath}: bee.flower_cooldowns check is inside or after 'if strict:' block (must remain unrelaxed)"
                )

    # Verify finish_collecting sets flower_cooldowns
    fc_pattern = re.compile(
        r"static\s+func\s+finish_collecting\s*\([^)]*\)\s*->\s*void\s*:",
        re.MULTILINE,
    )
    fc_match = fc_pattern.search(content)
    if not fc_match:
        problems.append(
            f"{filepath}: static func finish_collecting(...) not found"
        )
    else:
        fc_start = fc_match.end()
        fc_lines: list[str] = []
        for line in content[fc_start:].splitlines():
            if line.startswith("func ") or line.startswith("static func "):
                break
            fc_lines.append(line)
        fc_body = strip_comments("\n".join(fc_lines))
        if "flower_cooldowns[" not in fc_body:
            problems.append(
                f"{filepath}: finish_collecting does not assign flower_cooldowns on completion"
            )

    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Verify nearest flower search excludes drained/recent flowers."
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="Files to check (defaults to scripts/bee_foraging.gd).",
    )
    args = parser.parse_args(argv)

    paths = [Path(f) for f in args.files] if args.files else [
        ROOT / "scripts" / "bee_foraging.gd"
    ]

    all_problems: list[str] = []
    for path in paths:
        if not path.is_file():
            all_problems.append(f"{path}: file not found")
            continue
        content = path.read_text(encoding="utf-8")
        all_problems.extend(check_nearest_flower_exclusion(content, str(path)))

    if all_problems:
        print(
            "FAILED -- drained flower exclusion check found problems:",
            file=sys.stderr,
        )
        for problem in all_problems:
            print(f"  {problem}", file=sys.stderr)
        return 1

    print(
        f"drained flower exclusion check: {len(paths)} files checked, clean"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
