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
search pass (`if strict:`), returning false. Furthermore, `finish_collecting()` must
perform an actual assignment to `bee.flower_cooldowns[...] = ...` rather than
a read or comment.

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
    """Mask strings and comments, including multiline and escaped strings."""
    token = re.compile(r"""(?s)\x22{3}.*?\x22{3}|\x27{3}.*?\x27{3}|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\#[^\n]*""")
    return token.sub(lambda m: ''.join('\n' if c == '\n' else ' ' for c in m.group()), text)


def check_nearest_flower_exclusion(
    content: str, filepath: str = "scripts/bee_foraging.gd"
) -> list[str]:
    """Prove the supported accept-lambda predicate and completion assignment.

    This is a deliberately narrow structural guard, not general flow analysis:
    the unconditional cooldown rejection must be a direct child of accept.
    """
    clean = strip_comments(content).expandtabs(4)
    problems: list[str] = []
    def body(name: str) -> str | None:
        m = re.search(r"^static\s+func\s+" + name + r"\([^\n]*\)[^\n]*:\s*\n(.*?)(?=^(?:static\s+)?func\s|\Z)", clean, re.M | re.S)
        return m.group(1) if m else None

    nearest = body("nearest_flower")
    if nearest is None:
        return [f"{filepath}: static func nearest_flower(...) not found"]
    accept = re.search(r"^( +)var accept\s*:?=\s*func\(f:\s*Variant\)\s*->\s*bool:\s*$", nearest, re.M)
    expected = "bee.flower_cooldowns.has(f)andSession.sim_time<bee.flower_cooldowns[f]"
    found = False
    lines = nearest.splitlines()
    for i, line in enumerate(lines):
        m = re.match(r"^( +)if\s+(.+):\s*$", line)
        if not m or "bee.flower_cooldowns" not in m.group(2):
            continue
        found = True
        indent = len(m.group(1))
        if (accept is None or indent != len(accept.group(1)) + 4
                or re.sub(r"\s+", "", m.group(2)) != expected):
            problems.append(f"{filepath}: cooldown rejection must remain unrelaxed in accept")
        following = [row for row in lines[i+1:] if row.strip()]
        if (not following or following[0].strip() != "return false"
                or len(following[0]) - len(following[0].lstrip()) <= indent):
            problems.append(f"{filepath}: flower_cooldowns predicate does not reject candidate")
    if not found:
        problems.append(f"{filepath}: accept predicate lacks bee.flower_cooldowns check")
    completion = body("finish_collecting")
    if completion is None:
        problems.append(f"{filepath}: static func finish_collecting(...) not found")
    elif not re.search(r"^ +bee\.flower_cooldowns\s*\[[^\]\n]+\]\s*=(?!=)\s*\S", completion, re.M):
        problems.append(f"{filepath}: finish_collecting does not assign flower_cooldowns on completion")
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
