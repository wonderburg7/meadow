#!/usr/bin/env python3
"""Check scenario action verbs against the harness offline.

Derives the recognised verb set dynamically from scripts/scenario_actions.gd:
the string match arms of _execute plus the sequence verbs process/run_pending
handles ('assert', 'wait', 'settle').

Validates every action dictionary across test_scenarios/**/*.json.

Usage:
    python tools/check_scenarios.py [--list] [files...]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
HARNESS_PATH = ROOT / "scripts" / "scenario_actions.gd"
SEQUENCE_VERBS = ("assert", "wait", "settle")


def extract_execute_arms(harness_text: str) -> list[str]:
    """Extract string match arm values from static func _execute in scenario_actions.gd."""
    match = re.search(
        r"static func _execute\(.*?\).*?:\n(.*?)(?=\n(?:static\s+)?func\s|\n#\s*---)",
        harness_text,
        re.DOTALL,
    )
    if not match:
        raise ValueError(f"Could not locate static func _execute in {HARNESS_PATH}")
    lines = match.group(1).splitlines()
    arms: list[str] = []
    for line in lines:
        m = re.match(r'^\s*"([a-zA-Z0-9_]+)":', line)
        if m:
            arms.append(m.group(1))
    return arms


def derive_recognised_verbs(harness_path: Path = HARNESS_PATH) -> set[str]:
    """Derive the full set of recognised verbs from the harness script."""
    text = harness_path.read_text(encoding="utf-8")
    arms = extract_execute_arms(text)
    return set(arms) | set(SEQUENCE_VERBS)


def collect_actions(data: Any) -> list[tuple[int, Any]]:
    """Recursively collect (index, action) pairs from data structures containing 'actions' lists."""
    results: list[tuple[int, Any]] = []
    if isinstance(data, dict):
        if "actions" in data and isinstance(data["actions"], list):
            for idx, action in enumerate(data["actions"]):
                results.append((idx, action))
        for key, value in data.items():
            if key != "actions":
                results.extend(collect_actions(value))
    elif isinstance(data, list):
        for item in data:
            results.extend(collect_actions(item))
    return results


def check_scenario_file(path: Path, recognised_verbs: set[str]) -> list[str]:
    """Check a single scenario JSON file for valid action verbs."""
    try:
        content = path.read_text(encoding="utf-8")
        data = json.loads(content)
    except Exception as exc:
        return [f"{path}: failed to load JSON: {exc}"]

    actions = collect_actions(data)
    errors: list[str] = []
    for idx, action in actions:
        if not isinstance(action, dict):
            errors.append(f"{path}:{idx}: action is not a dictionary: {action!r}")
            continue

        if "do" not in action:
            errors.append(f"{path}:{idx}: missing 'do' verb: {action!r}")
            continue

        verb = action["do"]
        if not isinstance(verb, str):
            errors.append(f"{path}:{idx}: non-string 'do' verb ({type(verb).__name__}): {verb!r}")
            continue

        if verb not in recognised_verbs:
            errors.append(f"{path}:{idx}: unknown verb '{verb}': {action!r}")
            continue

    return errors


def check_all_scenarios(scenario_files: list[Path], recognised_verbs: set[str]) -> list[str]:
    """Check a collection of scenario files and return all error messages."""
    errors: list[str] = []
    for file_path in scenario_files:
        errors.extend(check_scenario_file(file_path, recognised_verbs))
    return errors


def find_scenario_files(root: Path = ROOT) -> list[Path]:
    """Find all .json files under test_scenarios/."""
    scenarios_dir = root / "test_scenarios"
    if not scenarios_dir.exists():
        return []
    return sorted(scenarios_dir.rglob("*.json"))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check scenario action verbs against scripts/scenario_actions.gd offline."
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="Print derived recognized verbs, one per line, and exit.",
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="Scenario files to check (defaults to test_scenarios/**/*.json).",
    )
    args = parser.parse_args(argv)

    recognised_verbs = derive_recognised_verbs()

    if args.list:
        for verb in sorted(recognised_verbs):
            print(verb)
        return 0

    if args.files:
        files = [Path(f) for f in args.files]
    else:
        files = find_scenario_files(ROOT)

    errors = check_all_scenarios(files, recognised_verbs)
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print(f"Checked {len(files)} scenario files: all action verbs recognized.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
