#!/usr/bin/env python3
"""Check that frozen bees and State.IDLING have explicit wake-up paths.

Why this exists
---------------
`docs/known-pitfalls.md`, "A bee on `State.IDLING` never dispatches again":
`bee.gd` handles that state with `pass   # waits for orders and nothing else`.
The historical focus-change bug was fixed in set_focus: IDLING now assigns
IN_HIVE_TO_EXIT. This guard protects that actual transition and the explicit
command mechanism used after a challenge freeze. It does not prove runtime
reachability for arbitrary stage scripts.

This tool checks that:
1. `challenge_runner.gd::_run_stage_effects` implements `freeze_bee:queen`
   by releasing everything, clearing navigation state, and setting state to
   `State.IDLING`.
2. `bee.gd::set_focus` explicitly handles `State.IDLING` to ensure changing
   focus wakes a parked/frozen bee indoors.
3. Every stage in `challenge_stages.gd` that applies `freeze_bee:queen`
   is followed by a stage unlocking queen_commands. Executable move/exit
   dispatch and state assignments are checked separately; player_driven,
   instructions and debug setup values alone do not prove a wake.

Usage
-----
    python tools/freeze_bee_check.py [root_dir]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


TOKEN = re.compile(r"""(?s)\x22{3}.*?\x22{3}|\x27{3}.*?\x27{3}|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\#[^\n]*""")


def code_only(text: str, keep: str | None = None) -> str:
    """Mask non-code, retaining only an explicitly requested match label."""
    return TOKEN.sub(lambda m: m.group() if m.group() == keep else
                     ''.join('\n' if c == '\n' else ' ' for c in m.group()), text)


def function(text: str, name: str) -> str:
    m = re.search(r"^func " + name + r"\([^\n]*\)[^\n]*:\s*\n(.*?)(?=^func |\Z)",
                  code_only(text).expandtabs(4), re.M | re.S)
    return m.group(1) if m else ""


def check_challenge_runner_freeze(text: str) -> list[str]:
    """Require executable release, reset and idle assignment in the freeze arm."""
    clean = code_only(text, '"freeze_bee:queen"').expandtabs(4)
    m = re.search(r'^([ ]*)"freeze_bee:queen":\s*\n(.*?)(?=^\1\S|\Z)', clean, re.M | re.S)
    if not m:
        return ["challenge_runner.gd: freeze_bee:queen effect handler not found"]
    body = m.group(2)
    required = [
        (r"^ +main\.queen\._release_everything\(\)\s*$", "_release_everything()"),
        (r"^ +main\.queen\.clear_navigation_state\(\)\s*$", "clear_navigation_state()"),
        (r"^ +main\.queen\.state\s*=(?!=)\s*main\.Bee\.State\.IDLING\s*$", "State.IDLING"),
    ]
    return [f"challenge_runner.gd: freeze_bee:queen missing executable {label}"
            for pattern, label in required if not re.search(pattern, body, re.M)]


def check_bee_set_focus(text: str) -> list[str]:
    """Require the idle branch's actual exit-state assignment, not a state token."""
    body = function(text, "set_focus")
    branch = re.search(r"^([ ]*)(?:if|elif) (state == State\.IDLING(?: or .+)?):\s*\n", body, re.M)
    if not branch:
        return ["bee.gd: set_focus does not handle 'State.IDLING'"]
    # For the supported branch, IDLING must be a sufficient alternative. Reject
    # and/false/not bypasses rather than attempting general expression evaluation.
    condition = branch.group(2)
    if condition != "state == State.IDLING" and not condition.startswith("state == State.IDLING or ("):
        return ["bee.gd: unsupported IDLING wake condition"]
    indent = len(branch.group(1))
    suite = []
    for line in body[branch.end():].splitlines():
        if line.strip() and len(line) - len(line.lstrip()) <= indent:
            break
        suite.append(line)
    assignment = re.compile(r"^ {" + str(indent+4) + r"}state\s*=(?!=)\s*State\.IN_HIVE_TO_EXIT\s*$", re.M)
    if not assignment.search("\n".join(suite)):
        return ["bee.gd: IDLING branch has no executable exit-state assignment"]
    return []


def check_challenge_stages_wake_path(text: str) -> list[str]:
    """Check literal stage dictionaries, never instructional wording.

    Supported mechanism: the next stage unlocks queen_commands. check_repo
    separately checks executable command dispatch and the Bee wake assignment.
    player_driven and debug setup values alone cannot wake a parked bee.
    """
    import ast
    # Mask comments but retain strings as data; braces inside strings never
    # participate in extraction. Only outermost dictionaries are stage records.
    chunks: list[str] = []
    depth = 0
    start = 0
    masked = TOKEN.sub(lambda m: " " * len(m.group()) if m.group().startswith("#")
                       else m.group(), text)
    structure = TOKEN.sub(lambda m: " " * len(m.group()), masked)
    for i, char in enumerate(structure):
        if char == "{":
            if depth == 0:
                start = i
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                chunks.append(masked[start:i+1])
    stages = []
    for chunk in chunks:
        # Preserve literals, replace GDScript names (prompt delay constants etc).
        lex = re.compile(r"""("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')|\b[A-Za-z_]\w*\b""")
        converted = lex.sub(lambda m: m.group() if m.group(1) else
                            {"true": "True", "false": "False", "null": "None"}.get(m.group(), "None"), chunk)
        try:
            node = ast.parse(converted, mode="eval").body
            fields = {ast.literal_eval(k): v for k, v in zip(node.keys, node.values)}
            if "id" not in fields:
                continue
            stage = {key: ast.literal_eval(fields[key]) for key in
                     ("id", "on_exit", "unlocked_keys") if key in fields}
        except (SyntaxError, ValueError, AttributeError, TypeError):
            return ["challenge_stages.gd: unsupported stage dictionary; cannot prove wake path"]
        stages.append(stage)
    if not stages:
        return ["challenge_stages.gd: no stage dictionaries found"]
    problems = []
    for i, stage in enumerate(stages):
        if "freeze_bee:queen" not in stage.get("on_exit", []):
            continue
        if i + 1 == len(stages):
            problems.append(f"challenge_stages.gd: stage {stage['id']} freezes queen but is terminal (see docs/challenge-stages.md)")
            continue
        next_stage = stages[i+1]
        keys = [entry.get("key") if isinstance(entry, dict) else entry
                for entry in next_stage.get("unlocked_keys", [])]
        if "queen_commands" not in keys:
            problems.append(f"challenge_stages.gd: stage {stage['id']} -> {next_stage['id']} provides no wake-up path or commands (see docs/challenge-stages.md)")
    return problems


def check_command_wake(bee: str, runner: str, selection: str) -> list[str]:
    """Tie the supported stage mechanism to executable move and exit commands."""
    problems = []
    for name, state in [("command_move_to", "MOVE_TO_POINT"), ("command_exit_hive", "IN_HIVE_TO_EXIT")]:
        if not re.search(r"^ +state\s*=(?!=)\s*State\." + state + r"\s*$", function(bee, name), re.M):
            problems.append(f"bee.gd: {name} has no wake assignment")
        if not re.search(r"^ +b\." + name + r"\(", code_only(selection).expandtabs(4), re.M):
            problems.append(f"input_selection.gd: no executable {name} dispatch")
    if not re.search(r"main\.stage_gate\.set_unlocked_keys\(_stage_unlock_keys\(stage\.unlocked_keys\)\)",
                     function(runner, "_enter_stage")):
        problems.append("challenge_runner.gd: stage command keys not applied")
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

    selection_path = root / "scripts" / "input_selection.gd"
    if selection_path.is_file() and bee_path.is_file() and runner_path.is_file():
        problems.extend(check_command_wake(bee_path.read_text(encoding="utf-8"),
            runner_path.read_text(encoding="utf-8"), selection_path.read_text(encoding="utf-8")))
    elif not selection_path.is_file():
        problems.append(f"Missing file: {selection_path}")
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

    print("freeze bee check: supported freeze and command wake source contracts pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
