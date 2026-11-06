#!/usr/bin/env python3
"""Check scenario action verbs against the harness offline.

Why this exists
---------------
E30-2 in docs/jules-efficiency/e-30.md (#126, accepted 6 Nov 2026):
A misspelt "do" verb in test_scenarios/*.json is only reported once Godot runs
the scenario. This tool validates scenario action dictionaries offline against
verbs recognised by scripts/scenario_actions.gd.

Verbs are derived dynamically each run from scripts/scenario_actions.gd:
the string match arms of _execute plus the sequence verbs handled in
run_pending (assert, wait, settle). The verb list is never hard-coded.

Usage
-----
    python tools/check_scenarios.py [--list] [files...]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

SEQUENCE_VERBS: tuple[str, ...] = ("assert", "wait", "settle")


def extract_execute_arms(gdscript_text: str) -> list[str]:
    """Extract string match arm verbs from _execute in scenario_actions.gd."""
    match = re.search(
        r"static func _execute\([^)]*\)\s*->\s*void:\s*\n"
        r"(?:\t+match\b[^\n]*\n)?"
        r"((?:\t+[^\n]*\n)+)",
        gdscript_text,
    )
    if not match:
        raise ValueError("Could not find static func _execute body in GDScript text")
    body = match.group(1)
    arms = re.findall(r'^\t\t"([a-zA-Z0-9_]+)":', body, re.MULTILINE)
    if not arms:
        raise ValueError("No string match arms found in _execute body")
    return arms


def derive_recognised_verbs(actions_gd_path: Path | str = "scripts/scenario_actions.gd") -> set[str]:
    """Derive all recognised action verbs dynamically from scenario_actions.gd."""
    path = Path(actions_gd_path)
    text = path.read_text(encoding="utf-8")
    arms = extract_execute_arms(text)
    verbs = set(arms) | set(SEQUENCE_VERBS)
    return verbs


def find_action_dicts(obj: object, path_prefix: str = "") -> list[tuple[str, int, object]]:
    """Recursively collect action dictionaries or candidates from scenario JSON data.

    Returns a list of tuples: (location_description, action_index, action_dict_or_item).
    Walks all top-level and nested action dictionaries or lists of actions.
    """
    results: list[tuple[str, int, object]] = []

    def _walk(node: object, loc: str) -> None:
        if isinstance(node, dict):
            # Check if this node has an "actions" list
            if "actions" in node and isinstance(node["actions"], list):
                for idx, item in enumerate(node["actions"]):
                    item_loc = f"{loc}.actions" if loc else "actions"
                    results.append((item_loc, idx, item))
                    _walk(item, f"{item_loc}[{idx}]")
            # Walk any other dict fields
            for key, val in node.items():
                if key == "actions":
                    continue
                child_loc = f"{loc}.{key}" if loc else key
                _walk(val, child_loc)
        elif isinstance(node, list):
            for idx, item in enumerate(node):
                _walk(item, f"{loc}[{idx}]")

    _walk(obj, path_prefix)
    return results


def check_scenario_file(file_path: Path, recognised_verbs: set[str]) -> list[str]:
    """Check a single scenario JSON file for action verb errors.

    Fails with file path and action index for:
    - an unknown verb
    - a missing "do"
    - a non-string "do"
    Allows no comment, disabled, or mock bypass.
    """
    errors: list[str] = []
    try:
        data = json.loads(file_path.read_text(encoding="utf-8"))
    except Exception as exc:
        return [f"{file_path}: failed to parse JSON: {exc}"]

    actions = find_action_dicts(data)
    for loc, idx, action in actions:
        if not isinstance(action, dict):
            errors.append(f"{file_path}:{loc}[{idx}]: action is not a dictionary ({type(action).__name__})")
            continue

        if "do" not in action:
            errors.append(f"{file_path}:{loc}[{idx}]: missing 'do' verb")
            continue

        verb = action["do"]
        if not isinstance(verb, str):
            errors.append(f"{file_path}:{loc}[{idx}]: 'do' verb is not a string ({type(verb).__name__}: {verb!r})")
            continue

        if verb not in recognised_verbs:
            errors.append(f"{file_path}:{loc}[{idx}]: unknown verb {verb!r}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Check scenario action verbs offline.")
    parser.add_argument(
        "--list",
        action="store_true",
        help="Print recognised action verbs one per line and exit.",
    )
    parser.add_argument(
        "--actions-gd",
        type=Path,
        default=Path("scripts/scenario_actions.gd"),
        help="Path to scripts/scenario_actions.gd (default: scripts/scenario_actions.gd)",
    )
    parser.add_argument(
        "files",
        nargs="*",
        type=Path,
        help="Scenario JSON files to check. If omitted, checks test_scenarios/**/*.json",
    )
    args = parser.parse_args()

    try:
        recognised_verbs = derive_recognised_verbs(args.actions_gd)
    except Exception as exc:
        print(f"Error deriving verbs from {args.actions_gd}: {exc}", file=sys.stderr)
        return 2

    if args.list:
        for verb in sorted(recognised_verbs):
            print(verb)
        return 0

    if args.files:
        files_to_check: list[Path] = []
        for f in args.files:
            if f.is_dir():
                files_to_check.extend(sorted(f.rglob("*.json")))
            else:
                files_to_check.append(f)
    else:
        files_to_check = sorted(Path("test_scenarios").rglob("*.json"))

    if not files_to_check:
        print("No scenario files found to check.", file=sys.stderr)
        return 2

    all_errors: list[str] = []
    for file_path in files_to_check:
        errs = check_scenario_file(file_path, recognised_verbs)
        all_errors.extend(errs)

    if all_errors:
        for err in all_errors:
            print(f"error: {err}", file=sys.stderr)
        print(f"\n{len(all_errors)} action verb error(s) found across {len(files_to_check)} scenario file(s).", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
