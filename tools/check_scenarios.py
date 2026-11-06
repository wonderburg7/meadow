#!/usr/bin/env python3
"""Check test scenario action verbs against scenario_actions.gd offline.

Why this exists
---------------
E30-2 in docs/jules-efficiency/e-30.md:
A misspelt "do" verb in test_scenarios/*.json is only reported once Godot
runs the scenario in headless mode. Validating action verbs statically catches
scenario authoring mistakes instantly without waiting for Godot boot cycles.

Verbs are derived dynamically from scripts/scenario_actions.gd each run:
the match arms of _execute() plus the sequence verbs handled in run_pending()
(assert, wait, settle).

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
from typing import Any, Iterator

ROOT = Path(__file__).resolve().parent.parent
SCENARIO_ACTIONS_PATH = ROOT / "scripts" / "scenario_actions.gd"
DEFAULT_SCENARIOS_DIR = ROOT / "test_scenarios"
SEQUENCE_VERBS = ("assert", "wait", "settle")


def extract_execute_arms(source_text: str) -> list[str]:
    """Extract string match arms from static func _execute in scenario_actions.gd."""
    func_pattern = re.compile(
        r"static\s+func\s+_execute\s*\([^)]*\)\s*(?:->\s*void\s*)?:\s*\n(.*?)(?=\n(?:static\s+)?func|\Z)",
        re.DOTALL,
    )
    match = func_pattern.search(source_text)
    if not match:
        raise ValueError("Could not find static func _execute in scenario_actions.gd")
    body = match.group(1)
    # Match arms inside match action.get("do", ""):
    arm_pattern = re.compile(r'^\s*"([a-zA-Z0-9_]+)":', re.MULTILINE)
    return arm_pattern.findall(body)


def derive_verbs(scenario_actions_path: Path = SCENARIO_ACTIONS_PATH) -> set[str]:
    """Derive recognized verbs from scripts/scenario_actions.gd."""
    text = scenario_actions_path.read_text(encoding="utf-8")
    arms = extract_execute_arms(text)
    verbs = set(arms)
    verbs.update(SEQUENCE_VERBS)
    return verbs


def walk_action_dicts(obj: Any, path_prefix: str = "") -> Iterator[tuple[str, int, Any]]:
    """Walk all action entries in a JSON structure.

    Yields (location_descriptor, action_index, action_value).
    """
    if isinstance(obj, dict):
        if "actions" in obj and isinstance(obj["actions"], list):
            loc = f"{path_prefix}.actions" if path_prefix else "actions"
            for idx, action in enumerate(obj["actions"]):
                yield (f"{loc}[{idx}]", idx, action)
        for k, v in obj.items():
            child_prefix = f"{path_prefix}.{k}" if path_prefix else k
            yield from walk_action_dicts(v, child_prefix)
    elif isinstance(obj, list):
        for idx, item in enumerate(obj):
            child_prefix = f"{path_prefix}[{idx}]"
            yield from walk_action_dicts(item, child_prefix)


def check_scenario_file(
    file_path: Path, recognized_verbs: set[str], root: Path = ROOT
) -> list[str]:
    """Check a single scenario file for valid action verbs."""
    problems: list[str] = []
    try:
        rel_path = file_path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        rel_path = file_path.as_posix()

    try:
        content = file_path.read_text(encoding="utf-8")
        data = json.loads(content)
    except Exception as exc:
        return [f"{rel_path}: error reading/parsing JSON: {exc}"]

    for loc, idx, action in walk_action_dicts(data):
        if not isinstance(action, dict):
            problems.append(
                f"{rel_path}: action at index {idx} ({loc}) is not an object/dictionary: {action!r}"
            )
            continue

        if "do" not in action:
            problems.append(
                f"{rel_path}: action at index {idx} ({loc}) missing required 'do' field"
            )
            continue

        verb = action["do"]
        if not isinstance(verb, str):
            problems.append(
                f"{rel_path}: action at index {idx} ({loc}) has non-string 'do' verb {verb!r}"
            )
            continue

        if verb not in recognized_verbs:
            problems.append(
                f"{rel_path}: action at index {idx} ({loc}) has unknown 'do' verb {verb!r}"
            )

    return problems


def collect_scenario_files(paths: list[Path]) -> list[Path]:
    """Collect JSON files from paths or default directory."""
    files: list[Path] = []
    for p in paths:
        if p.is_file() and p.suffix.lower() == ".json":
            files.append(p)
        elif p.is_dir():
            files.extend(sorted(p.rglob("*.json")))
    return sorted(files)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check test scenario action verbs against scenario_actions.gd offline."
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="Print derived recognized verbs, one per line, and exit.",
    )
    parser.add_argument(
        "paths",
        nargs="*",
        help="Scenario files or directories to check (defaults to test_scenarios/).",
    )
    args = parser.parse_args(argv)

    if not SCENARIO_ACTIONS_PATH.is_file():
        print(f"Error: {SCENARIO_ACTIONS_PATH} not found", file=sys.stderr)
        return 1

    recognized_verbs = derive_verbs(SCENARIO_ACTIONS_PATH)

    if args.list:
        for verb in sorted(recognized_verbs):
            print(verb)
        return 0

    if args.paths:
        target_paths = [Path(p) for p in args.paths]
    else:
        target_paths = [DEFAULT_SCENARIOS_DIR]

    scenario_files = collect_scenario_files(target_paths)
    if not scenario_files:
        print("No scenario JSON files found to check.")
        return 0

    all_problems: list[str] = []
    for sf in scenario_files:
        all_problems.extend(check_scenario_file(sf, recognized_verbs, ROOT))

    if all_problems:
        print("FAILED -- check_scenarios found invalid action verbs:", file=sys.stderr)
        for p in all_problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print(
        f"check_scenarios: {len(scenario_files)} scenario files checked, "
        f"all action verbs valid against {len(recognized_verbs)} derived verbs"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
