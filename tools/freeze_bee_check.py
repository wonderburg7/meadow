#!/usr/bin/env python3
"""Check that frozen bees and State.IDLING have explicit wake-up paths.

Why this exists
---------------
`docs/known-pitfalls.md`, "A bee on `State.IDLING` never dispatches again":
`bee.gd` handles that state with `pass   # waits for orders and nothing else`.
Assigning a role wakes her, because `_apply_role()` ends by setting
`_default_state_for_role()`; changing her focus does not, because `set_focus()`
deliberately leaves the state alone inside the hive and relies on `_go_to_exit()`
to pick the change up -- which a parked bee never reaches. Challenge 1's
`freeze_bee:queen` effect is what parks her, so a stage that freezes a bee has
to say how she starts again.

This tool checks that:
1. `challenge_runner.gd::_run_stage_effects` implements `freeze_bee:queen`
   by releasing everything, clearing navigation state, and setting state to
   `State.IDLING`.
2. `bee.gd::set_focus` explicitly handles `State.IDLING` to ensure changing
   focus wakes a parked/frozen bee indoors.
3. Every stage in `challenge_stages.gd` that applies `freeze_bee:queen`
   is followed by a stage providing a wake-up path (player commands, role
   assignment, or focus change).

Usage
-----
    python tools/freeze_bee_check.py [root_dir]
"""

from __future__ import annotations

import argparse
import json
import os
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


def check_challenge_runner_freeze(text: str) -> list[str]:
    """Check that challenge_runner.gd correctly implements freeze_bee:queen."""
    problems: list[str] = []
    # Find freeze_bee:queen effect handler
    m = re.search(
        r'"freeze_bee:queen":\s*(.*?)(?=\n\t\t\t"[a-zA-Z_0-9:]+":|\nfunc |\Z)',
        text,
        re.DOTALL,
    )
    if not m:
        problems.append("challenge_runner.gd: 'freeze_bee:queen' effect handler not found")
        return problems

    body = m.group(1)
    if "_release_everything" not in body:
        problems.append("challenge_runner.gd: freeze_bee:queen missing '_release_everything()'")
    if "clear_navigation_state" not in body:
        problems.append("challenge_runner.gd: freeze_bee:queen missing 'clear_navigation_state()'")
    if "State.IDLING" not in body:
        problems.append("challenge_runner.gd: freeze_bee:queen missing assignment to 'State.IDLING'")

    return problems


def check_bee_set_focus(text: str) -> list[str]:
    """Check that bee.gd::set_focus wakes bees parked on State.IDLING."""
    problems: list[str] = []
    m = re.search(
        r"func set_focus\(.*?\)\s*->\s*void:(.*?)(?=\nfunc |\Z)",
        text,
        re.DOTALL,
    )
    if not m:
        problems.append("bee.gd: func set_focus(...) -> void not found")
        return problems

    body = m.group(1)
    # Check that State.IDLING is explicitly handled to wake bee
    if "State.IDLING" not in body:
        problems.append(
            "bee.gd: set_focus does not handle 'State.IDLING'; parked bees will never dispatch"
        )
    elif not re.search(r"state\s*==\s*State\.IDLING", body):
        problems.append(
            "bee.gd: set_focus does not test 'state == State.IDLING' to wake parked bees"
        )

    return problems


def check_challenge_stages_wake_path(text: str) -> list[str]:
    """Check that every stage exiting with freeze_bee:queen has a wake-up path."""
    problems: list[str] = []

    stages: list[tuple[str, str]] = []
    lines = text.splitlines()
    current_id: str | None = None
    current_lines: list[str] = []

    for line in lines:
        m_id = re.search(r'"id":\s*"([^"]+)"', line)
        if m_id and "trigger" not in line:  # not a prompt trigger
            if current_id:
                stages.append((current_id, "\n".join(current_lines)))
                current_lines = []
            current_id = m_id.group(1)
        if current_id:
            current_lines.append(line)

    if current_id:
        stages.append((current_id, "\n".join(current_lines)))

    for i, (stage_id, stage_body) in enumerate(stages):
        if "freeze_bee:queen" in stage_body:
            # Check if this stage freezes the queen on_exit
            if '"on_exit"' in stage_body and "freeze_bee:queen" in stage_body:
                # Next stage must provide a wake-up path
                if i + 1 >= len(stages):
                    problems.append(
                        f"challenge_stages.gd: stage {stage_id} freezes queen on_exit but is terminal"
                    )
                    continue

                next_id, next_body = stages[i + 1]
                # A wake path can be:
                # - queen_commands in unlocked_keys
                # - player_driven: true
                # - role unlock or instruction to assign role/focus
                # - queen_at or queen_role in next stage's setup
                has_wake_path = False
                if "queen_commands" in next_body or "player_driven" in next_body:
                    has_wake_path = True
                elif "queen_role" in next_body:
                    has_wake_path = True
                elif any(
                    k in next_body
                    for k in ("forager", "builder", "miner", "nurse", "egg_layer", "laying")
                ):
                    has_wake_path = True

                if not has_wake_path:
                    problems.append(
                        f"challenge_stages.gd: stage {stage_id} freezes queen on_exit, "
                        f"but subsequent stage {next_id} provides no wake-up path or commands"
                    )

    return problems


def check_repo(root: Path) -> list[str]:
    """Check challenge_runner.gd, bee.gd, and challenge_stages.gd."""
    problems: list[str] = []

    runner_path = root / "scripts" / "challenge_runner.gd"
    bee_path = root / "scripts" / "bee.gd"
    stages_path = root / "scripts" / "challenge_stages.gd"

    if runner_path.is_file():
        problems.extend(check_challenge_runner_freeze(runner_path.read_text(encoding="utf-8")))
    else:
        problems.append(f"Missing file: {runner_path}")

    if bee_path.is_file():
        problems.extend(check_bee_set_focus(bee_path.read_text(encoding="utf-8")))
    else:
        problems.append(f"Missing file: {bee_path}")

    if stages_path.is_file():
        problems.extend(check_challenge_stages_wake_path(stages_path.read_text(encoding="utf-8")))
    else:
        problems.append(f"Missing file: {stages_path}")

    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check that frozen bees and State.IDLING have explicit wake-up paths."
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
        print("FAILED -- freeze bee check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print("freeze bee check: all frozen bee states have verified wake-up paths")
    return 0


if __name__ == "__main__":
    sys.exit(main())
