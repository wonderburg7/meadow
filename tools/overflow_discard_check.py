#!/usr/bin/env python3
"""Check that challenge_runner.gd restricts overflow discards to specific stages.

Why this exists
---------------
`docs/known-pitfalls.md`, "A restriction that lives in the comment and not in
the predicate":
`challenge_runner.gd::discards_overflow` was intended for Challenge 1's pollen
automation stage only, but earlier versions tested the Challenge, the bee,
the resource, and nothing about the stage -- so a rule meant for one stage
destroyed the queen's nectar at every stage.

This tool checks that:
1. `scripts/challenge_stages.gd` defines `C1_DISCARD_STAGES` explicitly naming
   only allowed discard stages (specifically ["1.14"]).
2. `scripts/challenge_runner.gd::discards_overflow(bee)` explicitly checks stage
   membership against `Stages.C1_DISCARD_STAGES` (or `C1_DISCARD_STAGES`) in its
   return predicate rather than discarding across all stages.

Usage
-----
    python tools/overflow_discard_check.py [options] [files...]
"""

from __future__ import annotations

import argparse
import ast
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

RUNNER_DEFAULT = ROOT / "scripts" / "challenge_runner.gd"
STAGES_DEFAULT = ROOT / "scripts" / "challenge_stages.gd"

# Exact allowed stages for discard in Challenge 1. Stage 1.14 is the only
# pollen automation stage where all cells can be legitimately unavailable for nectar.
ALLOWED_DISCARD_STAGES = {"1.14"}


def strip_comments(text: str) -> str:
    """Mask comments and string literals with spaces, preserving offsets and newlines."""
    out = []
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if c == "#":
            start = i
            while i < n and text[i] != "\n":
                i += 1
            out.append(" " * (i - start))
            continue
        if text[i : i + 3] in ('"""', "'''"):
            quote = text[i : i + 3]
            start = i
            i += 3
            while i < n and text[i : i + 3] != quote:
                if text[i] == "\n":
                    out.append("\n")
                else:
                    out.append(" ")
                i += 1
            if i < n:
                i += 3
            out.append(" " * (i - start - len("".join(c for c in text[start:i] if c == "\n"))))
            continue
        if c in ('"', "'"):
            quote = c
            start = i
            i += 1
            while i < n and text[i] != quote:
                if text[i] == "\\":
                    i += 2
                    continue
                if text[i] == "\n":
                    break
                i += 1
            if i < n and text[i] == quote:
                i += 1
            out.append(" " * (i - start))
            continue
        out.append(c)
        i += 1
    return "".join(out)


def parse_stages_constant(stages_text: str) -> tuple[list[str], list[str]]:
    """Extract stage IDs from `const C1_DISCARD_STAGES := [...]`.

    Returns (stage_list, problems).
    """
    problems: list[str] = []
    pattern = re.compile(r"const\s+C1_DISCARD_STAGES\s*(?::=|=)\s*(\[[^\]]*\])")
    match = pattern.search(stages_text)
    if not match:
        problems.append("const C1_DISCARD_STAGES is not defined in challenge_stages.gd")
        return [], problems

    raw_list = match.group(1)
    try:
        parsed = ast.literal_eval(raw_list)
        if not isinstance(parsed, list):
            problems.append(f"C1_DISCARD_STAGES must evaluate to a list, got {type(parsed)}")
            return [], problems
        stage_list = [str(item) for item in parsed]
    except Exception as err:
        problems.append(f"could not parse C1_DISCARD_STAGES list literal: {err}")
        return [], problems

    if not stage_list:
        problems.append("C1_DISCARD_STAGES is empty; must name discard stages")
    for s in stage_list:
        if s not in ALLOWED_DISCARD_STAGES:
            problems.append(
                f"C1_DISCARD_STAGES contains unauthorized stage {s!r}; only {sorted(ALLOWED_DISCARD_STAGES)} permitted"
            )

    return stage_list, problems


def extract_discards_overflow_body(runner_text: str) -> str | None:
    """Extract the body of func discards_overflow."""
    pattern = re.compile(
        r"^(?:static\s+)?func\s+discards_overflow\s*\([^)]*\)\s*(?:->\s*bool)?\s*:\s*\n"
        r"(?P<body>(?:[ \t]+.*\n|\s*\n)*)",
        re.MULTILINE,
    )
    m = pattern.search(runner_text)
    return m.group("body") if m else None


def check_discards_overflow_predicate(runner_text: str) -> list[str]:
    """Check that discards_overflow restricts discard to Stages.C1_DISCARD_STAGES."""
    problems: list[str] = []
    body = extract_discards_overflow_body(runner_text)
    if body is None:
        problems.append("func discards_overflow(...) not found in challenge_runner.gd")
        return problems

    clean_body = strip_comments(body)
    if "C1_DISCARD_STAGES" not in clean_body:
        problems.append(
            "challenge_runner.gd::discards_overflow must check C1_DISCARD_STAGES in predicate"
        )
    if not re.search(r"\bin\s+(?:Stages\.)?C1_DISCARD_STAGES\b", clean_body):
        problems.append(
            "challenge_runner.gd::discards_overflow must check stage membership with 'in Stages.C1_DISCARD_STAGES'"
        )

    return problems


def check_repo(
    runner_path: Path | str = RUNNER_DEFAULT,
    stages_path: Path | str = STAGES_DEFAULT,
) -> list[str]:
    """Run all discard checks on the provided or default paths."""
    runner = Path(runner_path)
    stages = Path(stages_path)
    problems: list[str] = []

    if not runner.is_file():
        problems.append(f"runner file not found: {runner}")
    if not stages.is_file():
        problems.append(f"stages file not found: {stages}")

    if problems:
        return problems

    runner_text = runner.read_text(encoding="utf-8")
    stages_text = stages.read_text(encoding="utf-8")

    _, stages_problems = parse_stages_constant(stages_text)
    for p in stages_problems:
        problems.append(f"{stages.as_posix()}: {p}")

    runner_problems = check_discards_overflow_predicate(runner_text)
    for p in runner_problems:
        problems.append(f"{runner.as_posix()}: {p}")

    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--runner", type=Path, default=RUNNER_DEFAULT, help="Path to challenge_runner.gd")
    parser.add_argument("--stages", type=Path, default=STAGES_DEFAULT, help="Path to challenge_stages.gd")
    args = parser.parse_args(argv)

    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")

    problems = check_repo(runner_path=args.runner, stages_path=args.stages)
    if problems:
        print("FAILED -- overflow discard stage restriction check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print("overflow discard stage check: OK, discards restricted to authorized stages")
    return 0


if __name__ == "__main__":
    sys.exit(main())
