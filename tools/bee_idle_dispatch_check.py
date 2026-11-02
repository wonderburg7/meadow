#!/usr/bin/env python3
"""Check Challenge stages and bee state transitions for parked IDLING bees.

Why this exists
---------------
`docs/known-pitfalls.md`, "A bee on `State.IDLING` never dispatches again":
`bee.gd` handles `State.IDLING` with `pass   # waits for orders and nothing else`.
Assigning a role wakes her (via `_default_state_for_role()`); changing her focus
does not, because `set_focus()` deliberately leaves the state alone inside the hive
and relies on `_go_to_exit()` to pick the change up -- which a parked bee never reaches.
Challenge 1's `freeze_bee:queen` effect is what parks her, so a stage that freezes a bee
has to say how she starts again (via subsequent stage setup, role change instruction,
unfreeze effect, or focus dispatch guard).

This tool scans:
1. `scripts/challenge_stages.gd` (and any other challenge stage definitions) for
   `freeze_bee` effects or setup assigning `State.IDLING`, ensuring subsequent stages
   or setups define how the bee starts again (e.g. assigning a new role or explicit wake-up).
2. `scripts/bee.gd` ensuring `set_focus` properly handles `State.IDLING` bees so
   that focus changes wake parked bees into `State.IN_HIVE_TO_EXIT`.

Usage
-----
    python tools/bee_idle_dispatch_check.py [files...]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


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


def check_focus_idle_dispatch(bee_gd_text: str, filename: str = "scripts/bee.gd") -> list[str]:
    """Verify that bee.gd::set_focus handles State.IDLING so focus changes wake parked bees."""
    problems: list[str] = []
    lines = bee_gd_text.splitlines()

    in_set_focus = False
    found_idling_branch = False
    dispatches_to_exit = False

    for raw_line in lines:
        stripped = strip_code(raw_line)
        if re.match(r"^\s*(?:func\s+set_focus)\b", stripped):
            in_set_focus = True
            continue

        if in_set_focus:
            if re.match(r"^\s*func\s+", stripped):
                break
            if "State.IDLING" in stripped:
                found_idling_branch = True
            if found_idling_branch and "State.IN_HIVE_TO_EXIT" in stripped:
                dispatches_to_exit = True

    if not (found_idling_branch and dispatches_to_exit):
        problems.append(
            f"{filename}: set_focus() does not handle State.IDLING to dispatch parked bees into State.IN_HIVE_TO_EXIT"
        )

    return problems


def _extract_dict_objects(text: str) -> list[tuple[str, int]]:
    """Parse top-level dictionary objects within lists or blocks with line numbers."""
    objects: list[tuple[str, int]] = []
    i, n = 0, len(text)
    brace_depth = 0
    start_pos = -1
    in_str = None

    while i < n:
        c = text[i]
        if in_str:
            if c == "\\":
                i += 2
                continue
            if c == in_str:
                in_str = None
            i += 1
            continue

        if c in ('"', "'"):
            in_str = c
            i += 1
            continue

        if c == "#":
            while i < n and text[i] != "\n":
                i += 1
            continue

        if c == "{":
            if brace_depth == 0:
                start_pos = i
            brace_depth += 1
        elif c == "}":
            brace_depth -= 1
            if brace_depth == 0 and start_pos != -1:
                line_no = text[:start_pos].count("\n") + 1
                objects.append((text[start_pos : i + 1], line_no))
                start_pos = -1

        i += 1

    return objects


def check_challenge_stages(stages_gd_text: str, filename: str = "scripts/challenge_stages.gd") -> list[str]:
    """Check stage definitions for frozen bees without an unfreeze, setup, or resume path."""
    problems: list[str] = []

    raw_stages = _extract_dict_objects(stages_gd_text)
    stages: list[dict[str, object]] = []

    for block, line_no in raw_stages:
        m = re.search(r'"id":\s*"([^"]+)"', block)
        if not m:
            continue
        stage_id = m.group(1)
        has_freeze = "freeze_bee" in block
        stages.append({
            "id": stage_id,
            "has_freeze": has_freeze,
            "block": block,
            "line": line_no,
        })

    for i, st in enumerate(stages):
        if bool(st["has_freeze"]):
            # If a stage freezes a bee, verify subsequent stage provides explicit resume/setup
            if i + 1 < len(stages):
                next_st = stages[i + 1]
                next_block = str(next_st["block"])
                has_resume = (
                    "queen_role" in next_block
                    or "queen_focus" in next_block
                    or "unfreeze" in next_block
                    or ("instruction" in next_block and any(k in next_block.lower() for k in ("role", "focus", "build", "wake", "give her")))
                )
                if not has_resume:
                    problems.append(
                        f"{filename}:{st['line']} stage {st['id']} freezes bee, but subsequent "
                        f"stage {next_st['id']} does not define how the bee starts again"
                    )

    return problems


def check_file(filepath: Path | str, text: str | None = None) -> list[str]:
    """Run check on a specific file."""
    path = Path(filepath)
    if text is None:
        text = path.read_text(encoding="utf-8")

    name = path.name
    if name == "bee.gd":
        return check_focus_idle_dispatch(text, path.as_posix())
    if "stage" in name:
        return check_challenge_stages(text, path.as_posix())
    return []


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check that bees parked on State.IDLING have dispatch and resume handling."
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="Files to check (defaults to scripts/bee.gd and scripts/challenge_stages.gd).",
    )
    args = parser.parse_args(argv)

    if args.files:
        files = [Path(f) for f in args.files]
    else:
        files = [ROOT / "scripts" / "bee.gd", ROOT / "scripts" / "challenge_stages.gd"]

    problems: list[str] = []
    for path in files:
        if path.is_file():
            problems.extend(check_file(path))

    if problems:
        print("FAILED -- bee idle dispatch check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print(f"bee idle dispatch check: {len(files)} files checked, no unhandled IDLING states")
    return 0


if __name__ == "__main__":
    sys.exit(main())
