#!/usr/bin/env python3
"""Check test scenario action verbs against scripts/scenario_actions.gd offline.

Why this exists
---------------
E30-2 in docs/jules-efficiency/e-30.md:
A misspelt "do" verb in test_scenarios/*.json (such as "mine_queue" instead of
"queue_mine") is only reported once Godot boots and executes the scenario.

This tool:
1. Dynamically derives recognised action verbs from scripts/scenario_actions.gd:
   the string match arms of _execute() plus the sequence verbs handled in
   run_pending() ("assert", "wait", "settle"). The verb list is never hard-coded.
2. Walks every action dictionary in test_scenarios/**/*.json (both top-level
   and nested).
3. Fails reporting file and action index if an unknown verb, missing "do", or
   non-string "do" is found. Allows no comment, disabled, or mock bypasses.
4. Supports --list to print derived verbs, one per line.

Usage
-----
    python tools/check_scenarios.py [--list] [root_dir]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

SEQUENCE_VERBS = ("assert", "wait", "settle")


def extract_execute_verbs(script_content: str) -> list[str]:
    """Extract verb string literals from the match statement inside _execute()."""
    # Locate func _execute
    m = re.search(
        r"static\s+func\s+_execute\(.*?\n(?:static\s+)?func |\Z",
        script_content,
        re.DOTALL,
    )
    if not m:
        raise ValueError("static func _execute(...) not found in scenario_actions.gd")
    body = m.group(0)

    # In GDScript, the match arms inside _execute are strings like: \t\t"assign_role":
    verbs = re.findall(r'^[ \t]*"([a-zA-Z0-9_]+)":', body, re.MULTILINE)
    return verbs


def derive_recognised_verbs(scenario_actions_path: Path) -> set[str]:
    """Derive the complete set of valid scenario action verbs."""
    if not scenario_actions_path.is_file():
        raise FileNotFoundError(f"Missing {scenario_actions_path}")
    content = scenario_actions_path.read_text(encoding="utf-8")
    execute_verbs = extract_execute_verbs(content)
    all_verbs = set(execute_verbs)
    for seq_verb in SEQUENCE_VERBS:
        all_verbs.add(seq_verb)
    return all_verbs


def check_action_dict(
    action: object,
    index_repr: str,
    filepath: Path,
    recognised_verbs: set[str],
) -> list[str]:
    """Validate a single action dictionary."""
    problems: list[str] = []
    if not isinstance(action, dict):
        problems.append(f"{filepath} action {index_repr}: action is not a dictionary ({type(action).__name__})")
        return problems

    if "do" not in action:
        problems.append(f"{filepath} action {index_repr}: missing 'do' field")
        return problems

    do_val = action["do"]
    if not isinstance(do_val, str):
        problems.append(
            f"{filepath} action {index_repr}: non-string 'do' value ({type(do_val).__name__}: {do_val!r})"
        )
        return problems

    if do_val not in recognised_verbs:
        problems.append(
            f"{filepath} action {index_repr}: unknown 'do' verb {do_val!r}"
        )

    return problems


def walk_and_check_actions(
    obj: object,
    filepath: Path,
    recognised_verbs: set[str],
    current_path: str = "",
) -> list[str]:
    """Recursively search for action lists and check every action dictionary."""
    problems: list[str] = []

    if isinstance(obj, dict):
        for k, v in obj.items():
            child_path = f"{current_path}.{k}" if current_path else str(k)
            if k == "actions" and isinstance(v, list):
                for idx, act in enumerate(v):
                    item_path = f"{child_path}[{idx}]"
                    problems.extend(
                        check_action_dict(act, item_path, filepath, recognised_verbs)
                    )
                    # Also walk inside the action itself if it contains nested structures
                    problems.extend(
                        walk_and_check_actions(act, filepath, recognised_verbs, item_path)
                    )
            else:
                problems.extend(
                    walk_and_check_actions(v, filepath, recognised_verbs, child_path)
                )
    elif isinstance(obj, list):
        for idx, item in enumerate(obj):
            child_path = f"{current_path}[{idx}]"
            problems.extend(
                walk_and_check_actions(item, filepath, recognised_verbs, child_path)
            )

    return problems


def check_scenario_file(
    json_path: Path, recognised_verbs: set[str]
) -> list[str]:
    """Check a single scenario JSON file."""
    try:
        content = json_path.read_text(encoding="utf-8")
        data = json.loads(content)
    except Exception as err:
        return [f"{json_path}: failed to read/parse JSON ({err})"]

    return walk_and_check_actions(data, json_path, recognised_verbs)


def check_repo(root: Path) -> tuple[set[str], list[str]]:
    """Derive verbs and check all test scenarios in the repository."""
    actions_script = root / "scripts" / "scenario_actions.gd"
    recognised_verbs = derive_recognised_verbs(actions_script)

    scenarios_dir = root / "test_scenarios"
    if not scenarios_dir.is_dir():
        return recognised_verbs, [f"test_scenarios directory not found: {scenarios_dir}"]

    scenario_files = sorted(scenarios_dir.rglob("*.json"))
    problems: list[str] = []
    for sf in scenario_files:
        problems.extend(check_scenario_file(sf, recognised_verbs))

    return recognised_verbs, problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check test scenario action verbs against scripts/scenario_actions.gd offline."
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="Print derived recognised verbs, one per line, and exit.",
    )
    parser.add_argument(
        "root",
        nargs="?",
        default=str(ROOT),
        help="Repository root directory (defaults to repo root).",
    )
    args = parser.parse_args(argv)

    root = Path(args.root).resolve()
    actions_script = root / "scripts" / "scenario_actions.gd"

    try:
        recognised_verbs = derive_recognised_verbs(actions_script)
    except Exception as err:
        print(f"Error deriving verbs from {actions_script}: {err}", file=sys.stderr)
        return 1

    if args.list:
        for verb in sorted(recognised_verbs):
            print(verb)
        return 0

    _, problems = check_repo(root)
    if problems:
        print(f"FAILED -- check_scenarios found {len(problems)} problem(s):", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print(
        f"check_scenarios: checked scenarios against {len(recognised_verbs)} derived verbs, clean"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
