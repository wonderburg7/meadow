#!/usr/bin/env python3
"""Check test scenario action verbs against scenario_actions.gd offline.

Why this exists
---------------
E30-2 in docs/jules-efficiency/e-30.md:
A misspelt "do" verb in test_scenarios/*.json is only reported once Godot runs
the scenario at runtime. This tool statically validates that every action
dictionary across test_scenarios/**/*.json contains a valid "do" verb recognized
by scripts/scenario_actions.gd.

Verbs are derived dynamically from scripts/scenario_actions.gd:
- Match arms inside static func _execute(main: Node2D, action: Dictionary)
- Sequence verbs handled by run_pending: "assert", "wait", "settle"

Usage
-----
    python tools/check_scenarios.py [--list] [paths...]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCENARIO_ACTIONS_PATH = ROOT / "scripts" / "scenario_actions.gd"
DEFAULT_SCENARIOS_DIR = ROOT / "test_scenarios"

SEQUENCE_VERBS = ("assert", "wait", "settle")


def extract_execute_arms(source_text: str) -> list[str]:
    """Extract string match arms from static func _execute in scenario_actions.gd."""
    match_func = re.search(
        r"static func _execute\(.*?\n(\t+)match action\.get\(\"do\", \"\"\):\n(.*?)(?=\nfunc |\nstatic func |\Z)",
        source_text,
        re.DOTALL,
    )
    if not match_func:
        return []
    indent = match_func.group(1)
    body = match_func.group(2)
    # Each arm has indent + one extra tab
    arm_indent = re.escape(indent + "\t")
    arms = re.findall(rf"^{arm_indent}\"([a-zA-Z0-9_]+)\":", body, re.MULTILINE)
    return arms


def derive_verbs(scenario_actions_path: Path | str = SCENARIO_ACTIONS_PATH) -> set[str]:
    """Derive recognised action verbs dynamically from scripts/scenario_actions.gd."""
    path = Path(scenario_actions_path)
    if not path.is_file():
        raise FileNotFoundError(f"scenario_actions.gd not found at: {path}")
    source_text = path.read_text(encoding="utf-8")
    arms = extract_execute_arms(source_text)
    if not arms:
        raise ValueError(f"Could not extract _execute match arms from {path}")
    verbs = set(arms) | set(SEQUENCE_VERBS)
    return verbs


def walk_actions(data: object, path_prefix: str = "") -> list[tuple[str, object]]:
    """Recursively collect action dictionaries with their structural index path."""
    found: list[tuple[str, object]] = []
    if isinstance(data, dict):
        if "actions" in data and isinstance(data["actions"], list):
            for idx, item in enumerate(data["actions"]):
                item_prefix = f"{path_prefix}actions[{idx}]" if not path_prefix else f"{path_prefix}.actions[{idx}]"
                found.append((item_prefix, item))
                found.extend(walk_actions(item, item_prefix))
        elif "do" in data and not path_prefix:
            found.append(("action[0]", data))
    elif isinstance(data, list):
        for idx, item in enumerate(data):
            item_prefix = f"[{idx}]" if not path_prefix else f"{path_prefix}[{idx}]"
            found.append((item_prefix, item))
            found.extend(walk_actions(item, item_prefix))
    return found


def validate_scenario_data(data: object, filepath: str, valid_verbs: set[str]) -> list[str]:
    """Validate all action dictionaries in parsed scenario data."""
    problems: list[str] = []
    actions = walk_actions(data)
    for index_str, action in actions:
        if not isinstance(action, dict):
            problems.append(f"{filepath}: {index_str}: action is not a dictionary ({type(action).__name__})")
            continue
        if "do" not in action:
            problems.append(f"{filepath}: {index_str}: missing 'do' field in action")
            continue
        do_val = action["do"]
        if not isinstance(do_val, str):
            problems.append(f"{filepath}: {index_str}: 'do' field must be a string, got {type(do_val).__name__} ({do_val!r})")
            continue
        if do_val not in valid_verbs:
            problems.append(f"{filepath}: {index_str}: unknown verb '{do_val}'")
    return problems


def check_file(filepath: Path | str, valid_verbs: set[str]) -> list[str]:
    """Check a single scenario JSON file."""
    path = Path(filepath)
    if not path.is_file():
        return [f"{filepath}: file not found"]
    try:
        content = path.read_text(encoding="utf-8")
        data = json.loads(content)
    except Exception as exc:
        return [f"{filepath}: failed to parse JSON: {exc}"]
    try:
        rel_path = path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        rel_path = path.as_posix()
    return validate_scenario_data(data, rel_path, valid_verbs)


def find_scenario_files(root: Path | str = DEFAULT_SCENARIOS_DIR) -> list[Path]:
    """Find all JSON files under test_scenarios/."""
    path = Path(root)
    if not path.exists():
        return []
    if path.is_file():
        return [path]
    return sorted(path.rglob("*.json"))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check test scenario action verbs against scripts/scenario_actions.gd."
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="Print derived action verbs (one per line) and exit.",
    )
    parser.add_argument(
        "paths",
        nargs="*",
        help="Specific scenario files or directories to check (defaults to test_scenarios/**/*.json).",
    )
    args = parser.parse_args(argv)

    try:
        valid_verbs = derive_verbs()
    except Exception as exc:
        print(f"Error deriving verbs: {exc}", file=sys.stderr)
        return 2

    if args.list:
        for verb in sorted(valid_verbs):
            print(verb)
        return 0

    if args.paths:
        files: list[Path] = []
        for p in args.paths:
            path_obj = Path(p)
            if path_obj.is_dir():
                files.extend(find_scenario_files(path_obj))
            else:
                files.append(path_obj)
    else:
        files = find_scenario_files()

    problems: list[str] = []
    for f in files:
        problems.extend(check_file(f, valid_verbs))

    if problems:
        print(f"FAILED -- check_scenarios found {len(problems)} problem(s):", file=sys.stderr)
        for prob in problems:
            print(f"  {prob}", file=sys.stderr)
        return 1

    print(f"check_scenarios: {len(files)} files checked against {len(valid_verbs)} verbs, all clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
