#!/usr/bin/env python3
"""Check test scenario action verbs against scenario_actions.gd offline.

Why this exists
---------------
E30-2 in docs/jules-efficiency/e-30.md (#126, accepted 6 Nov 2026):
a misspelt "do" verb in test_scenarios/*.json is only reported once Godot runs
the scenario. This tool validates scenario action verbs offline before running.

Recognised verbs are derived dynamically from scripts/scenario_actions.gd:
the string match arms of _execute plus the sequence verbs handled by run_pending
("assert", "wait", "settle"). The verb list is never hard-coded.

Usage
-----
    python tools/check_scenarios.py [--list] [scenarios_dir]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCENARIO_ACTIONS_GD = ROOT / "scripts" / "scenario_actions.gd"
DEFAULT_SCENARIOS_DIR = ROOT / "test_scenarios"

SEQUENCE_VERBS = ("assert", "wait", "settle")


def extract_execute_arms(source_text: str) -> list[str]:
    """Extract string match arms from _execute in scenario_actions.gd source."""
    m = re.search(
        r"static func _execute\(main: Node2D, action: Dictionary\) -> void:\s*\n"
        r"\s*match action\.get\(\"do\", \"\"\):\s*\n(.*?)(?=\n\s*var other:|\nstatic func|\Z)",
        source_text,
        re.DOTALL,
    )
    if not m:
        return []
    body = m.group(1)
    # Find all arms formatted as "verb":
    return re.findall(r'"([a-zA-Z0-9_]+)":', body)


def derive_recognised_verbs(actions_script: Path | str = SCENARIO_ACTIONS_GD) -> set[str]:
    """Derive recognised scenario verbs from scripts/scenario_actions.gd."""
    path = Path(actions_script)
    text = path.read_text(encoding="utf-8")
    arms = extract_execute_arms(text)
    verbs = set(arms)
    verbs.update(SEQUENCE_VERBS)
    return verbs


def walk_actions(data: object) -> list[tuple[int, dict]]:
    """Walk scenario JSON structure and return list of (action_index, action_dict)."""
    actions: list[tuple[int, dict]] = []

    def _walk(obj: object) -> None:
        if isinstance(obj, dict):
            # Check if this object contains an 'actions' list
            if "actions" in obj and isinstance(obj["actions"], list):
                for idx, item in enumerate(obj["actions"]):
                    if isinstance(item, dict):
                        actions.append((idx, item))
                    else:
                        # Non-dict action entry in actions array
                        actions.append((idx, item))
            # Continue traversing nested objects
            for k, v in obj.items():
                if k != "actions":
                    _walk(v)
        elif isinstance(obj, list):
            for item in obj:
                _walk(item)

    _walk(data)
    return actions


def check_scenario_file(filepath: Path | str, recognised_verbs: set[str]) -> list[str]:
    """Check a single scenario JSON file for invalid or missing action verbs."""
    path = Path(filepath)
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:
        return [f"{path}: JSON decode error: {e}"]

    findings: list[str] = []
    actions = walk_actions(data)

    for idx, act in actions:
        if not isinstance(act, dict):
            findings.append(f"{path}: action [{idx}] is not a dictionary: {act!r}")
            continue

        if "do" not in act:
            findings.append(f"{path}: action [{idx}] missing 'do' verb: {act}")
            continue

        verb = act["do"]
        if not isinstance(verb, str):
            findings.append(f"{path}: action [{idx}] 'do' verb is not a string (got {type(verb).__name__}): {verb!r}")
            continue

        if verb not in recognised_verbs:
            findings.append(f"{path}: action [{idx}] unknown 'do' verb: {verb!r}")

    return findings


def check_all_scenarios(
    scenarios_dir: Path | str = DEFAULT_SCENARIOS_DIR,
    recognised_verbs: set[str] | None = None,
) -> list[str]:
    """Check all scenario JSON files in scenarios_dir."""
    s_dir = Path(scenarios_dir)
    if recognised_verbs is None:
        recognised_verbs = derive_recognised_verbs()

    findings: list[str] = []
    for json_path in sorted(s_dir.glob("**/*.json")):
        findings.extend(check_scenario_file(json_path, recognised_verbs))

    return findings


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check scenario action verbs against scenario_actions.gd offline."
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="Print derived recognized verbs, one per line, and exit.",
    )
    parser.add_argument(
        "scenarios_dir",
        nargs="?",
        default=str(DEFAULT_SCENARIOS_DIR),
        help="Path to scenarios directory (default: test_scenarios).",
    )
    parser.add_argument(
        "--actions-script",
        default=str(SCENARIO_ACTIONS_GD),
        help="Path to scenario_actions.gd script (default: scripts/scenario_actions.gd).",
    )
    args = parser.parse_args(argv)

    verbs = derive_recognised_verbs(Path(args.actions_script))

    if args.list:
        for v in sorted(verbs):
            print(v)
        return 0

    findings = check_all_scenarios(Path(args.scenarios_dir), recognised_verbs=verbs)
    if findings:
        for f in findings:
            print(f, file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
