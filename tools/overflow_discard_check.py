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
1. `scripts/challenge_stages.gd` declares `C1_DISCARD_STAGES` once, as
   executable top-level code (not a comment), naming only allowed discard
   stages (specifically ["1.14"]).
2. `scripts/challenge_runner.gd::discards_overflow(bee)` is one `return` whose
   predicate is a top-level `and` chain containing the conjunct
   `<stage>.id in Stages.C1_DISCARD_STAGES`. Token presence is not enough:
   `not in`, a top-level `or`, or a membership test moved into a local the
   return ignores all leave the discard unrestricted and are reported.
   Restructuring the function (an early-return guard, say) also fails, by
   design: update this check with it.

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
    """Extract stage IDs from the executable `const C1_DISCARD_STAGES := [...]`.

    Only a top-level declaration at column zero counts, so a commented-out or
    indented copy cannot stand in for the real one. Returns (stage_list, problems).
    """
    problems: list[str] = []
    pattern = re.compile(
        r"^const\s+C1_DISCARD_STAGES\s*(?::=|=|:\s*Array(?:\[String\])?\s*=)\s*(\[[^\]]*\])",
        re.MULTILINE,
    )
    matches = pattern.findall(stages_text)
    if not matches:
        problems.append("const C1_DISCARD_STAGES is not defined in challenge_stages.gd")
        return [], problems
    if len(matches) > 1:
        problems.append("const C1_DISCARD_STAGES is declared more than once")
        return [], problems

    raw_list = matches[0]
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
    """Extract the body of func discards_overflow.

    The body runs until the next non-blank, non-comment line at column zero;
    a comment at column zero inside the function does not end it.
    """
    lines = runner_text.splitlines(keepends=True)
    header = re.compile(r"^(?:static\s+)?func\s+discards_overflow\s*\(")
    for i, line in enumerate(lines):
        if header.match(line):
            body: list[str] = []
            for nxt in lines[i + 1:]:
                stripped = nxt.strip()
                if stripped and not stripped.startswith("#") and not nxt[0].isspace():
                    break
                body.append(nxt)
            return "".join(body)
    return None


# The stage conjunct: `<stage expression>.id in Stages.C1_DISCARD_STAGES`, with
# no `not`, `or` or other operator inside it (whitespace already collapsed).
STAGE_CONJUNCT_RE = re.compile(r"^[A-Za-z_][\w.()\[\]]*\.id in (?:Stages\.)?C1_DISCARD_STAGES$")


def _return_expression(clean_body: str) -> tuple[str | None, str | None]:
    """Return (expression, problem) for a body that must be one `return` statement."""
    text = clean_body.strip()
    if not re.match(r"return\b", text):
        return None, "must consist of a single `return <predicate>` statement"
    expr_start = len("return")
    depth = 0
    end = len(text)
    for i in range(expr_start, len(text)):
        c = text[i]
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == "\n" and depth == 0:
            end = i
            break
    if text[end:].strip():
        return None, "must consist of a single `return <predicate>` statement"
    return text[expr_start:end].strip(), None


def _strip_outer_parens(expr: str) -> str:
    while expr.startswith("(") and expr.endswith(")"):
        depth = 0
        for i, c in enumerate(expr):
            depth += c == "("
            depth -= c == ")"
            if depth == 0 and i < len(expr) - 1:
                return expr
        expr = expr[1:-1].strip()
    return expr


def _split_top_level(expr: str) -> tuple[list[str], list[str]]:
    """Split expr at depth-0 boolean operators; return (operands, operators)."""
    operands: list[str] = []
    operators: list[str] = []
    depth = 0
    start = 0
    i = 0
    token = re.compile(r"(?<![\w.])(and|or)(?![\w])|&&|\|\|")
    while i < len(expr):
        c = expr[i]
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif depth == 0:
            m = token.match(expr, i)
            if m:
                operands.append(expr[start:i])
                operators.append({"&&": "and", "||": "or"}.get(m.group(0), m.group(0)))
                i = m.end()
                start = i
                continue
        i += 1
    operands.append(expr[start:])
    return [" ".join(o.split()) for o in operands], operators


def check_discards_overflow_predicate(runner_text: str) -> list[str]:
    """Check that discards_overflow's executable return requires the stage.

    The body must be one `return` whose predicate is a top-level `and` chain
    with a conjunct `<stage>.id in Stages.C1_DISCARD_STAGES`. A top-level
    `or`, a negated membership, or a membership test moved out of the return
    each leave the discard unrestricted, so each is reported.
    """
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
        return problems

    expr, problem = _return_expression(clean_body)
    if problem:
        problems.append(f"challenge_runner.gd::discards_overflow {problem}")
        return problems

    expr = _strip_outer_parens(expr)
    if re.match(r"(not\b|!)", expr):
        problems.append("challenge_runner.gd::discards_overflow negates its whole predicate")
        return problems
    conjuncts, operators = _split_top_level(expr)
    if "or" in operators:
        problems.append(
            "challenge_runner.gd::discards_overflow has a top-level `or`; the stage restriction no longer binds"
        )
    if not any(STAGE_CONJUNCT_RE.match(c) for c in conjuncts):
        problems.append(
            "challenge_runner.gd::discards_overflow must require `<stage>.id in Stages.C1_DISCARD_STAGES` "
            "as a conjunct of its return predicate"
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
