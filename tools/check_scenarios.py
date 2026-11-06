#!/usr/bin/env python3
"""Check test scenario action verbs statically against scripts/scenario_actions.gd.

Why this exists
---------------
E30-2 in docs/jules-efficiency/e-30.md (#126, accepted 6 Nov 2026): a misspelt
"do" verb in test_scenarios/*.json is only reported once Godot runs the scenario.

This tool checks that:
1. Valid verbs are derived dynamically at runtime from scripts/scenario_actions.gd:
   the match arms in static func _execute(...) plus the sequence verbs process
   (run_pending) handles ('assert', 'wait', 'settle').
2. Every action in test_scenarios/**/*.json contains a valid string "do" attribute
   belonging to the derived verb set.
3. Errors fail with the file path and action index.
4. No comments, disabled, or mock bypasses are allowed.

Usage
-----
    python tools/check_scenarios.py [files...]
    python tools/check_scenarios.py --list
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCENARIO_ACTIONS_GD = ROOT / "scripts" / "scenario_actions.gd"
SEQUENCE_VERBS = ("assert", "wait", "settle")


def derive_execute_arms(actions_script_path: Path | str | None = None) -> list[str]:
    """Extract string match arms from _execute in scripts/scenario_actions.gd."""
    path = Path(actions_script_path) if actions_script_path else SCENARIO_ACTIONS_GD
    text = path.read_text(encoding="utf-8")

    m = re.search(
        r"static func _execute\(main:\s*Node2D,\s*action:\s*Dictionary\)\s*->\s*void:(.*?)(?=\n(?:static\s+)?func |\Z)",
        text,
        re.DOTALL,
    )
    if not m:
        raise ValueError(f"Could not locate static func _execute in {path}")

    body = m.group(1)
    # Match arms of the form: "verb_name":
    arms = re.findall(r'^[ \t]*"([a-zA-Z0-9_]+)":', body, flags=re.MULTILINE)
    return arms


def derive_verbs(actions_script_path: Path | str | None = None) -> set[str]:
    """Derive the recognized scenario verbs from scripts/scenario_actions.gd."""
    arms = derive_execute_arms(actions_script_path)
    return set(arms) | set(SEQUENCE_VERBS)


def _walk_actions(obj: object, index_prefix: str = "") -> list[tuple[str, object]]:
    """Recursively collect (action_index, action_dict) from a scenario json structure."""
    collected: list[tuple[str, object]] = []
    if isinstance(obj, dict):
        if "do" in obj or "when" in obj or "every_days" in obj:
            collected.append((index_prefix or "0", obj))
        for k, v in obj.items():
            sub_prefix = f"{index_prefix}.{k}" if index_prefix else k
            collected.extend(_walk_actions(v, sub_prefix))
    elif isinstance(obj, list):
        for idx, item in enumerate(obj):
            sub_prefix = f"{index_prefix}[{idx}]" if index_prefix else str(idx)
            collected.extend(_walk_actions(item, sub_prefix))
    return collected


def check_scenario_file(filepath: Path | str, verbs: set[str]) -> list[str]:
    """Check a single scenario json file for valid action verbs."""
    path = Path(filepath)
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:
        return [f"{path}: invalid JSON: {e}"]

    findings: list[str] = []

    # Top-level "actions" key if present
    actions = data.get("actions")
    if actions is not None:
        if not isinstance(actions, list):
            findings.append(f"{path}: 'actions' field must be a list")
            return findings
        for idx, act in enumerate(actions):
            act_idx_label = str(idx)
            if not isinstance(act, dict):
                findings.append(f"{path}: action {act_idx_label} is not a dictionary: {type(act).__name__}")
                continue
            if "do" not in act:
                findings.append(f"{path}: action {act_idx_label} missing 'do' field")
                continue
            verb = act["do"]
            if not isinstance(verb, str):
                findings.append(f"{path}: action {act_idx_label} 'do' field is not a string: {verb!r}")
                continue
            if verb not in verbs:
                findings.append(f"{path}: action {act_idx_label} unknown 'do' verb: {verb!r}")
            # Also walk nested structures inside this action if any
            for k, v in act.items():
                if isinstance(v, (list, dict)):
                    for nested_idx, nested_act in _walk_actions(v, f"{act_idx_label}.{k}"):
                        if isinstance(nested_act, dict) and "do" in nested_act:
                            n_verb = nested_act["do"]
                            if not isinstance(n_verb, str):
                                findings.append(f"{path}: action {nested_idx} 'do' field is not a string: {n_verb!r}")
                            elif n_verb not in verbs:
                                findings.append(f"{path}: action {nested_idx} unknown 'do' verb: {n_verb!r}")
    else:
        # Check any nested actions elsewhere in the document
        for idx_label, act in _walk_actions(data):
            if isinstance(act, dict) and "do" in act:
                verb = act["do"]
                if not isinstance(verb, str):
                    findings.append(f"{path}: action {idx_label} 'do' field is not a string: {verb!r}")
                elif verb not in verbs:
                    findings.append(f"{path}: action {idx_label} unknown 'do' verb: {verb!r}")

    return findings


def check_scenarios(
    files: list[Path] | None = None,
    actions_script_path: Path | str | None = None,
) -> tuple[int, list[str]]:
    """Scan scenario files and return (total_files_checked, findings)."""
    verbs = derive_verbs(actions_script_path)
    if files:
        target_files = files
    else:
        target_files = sorted(ROOT.glob("test_scenarios/**/*.json"))

    all_findings: list[str] = []
    for f in target_files:
        all_findings.extend(check_scenario_file(f, verbs))

    return len(target_files), all_findings


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check scenario action verbs against scripts/scenario_actions.gd."
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="Print the derived scenario verbs, one per line, and exit.",
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="Scenario files to check (defaults to test_scenarios/**/*.json).",
    )
    args = parser.parse_args(argv)

    if args.list:
        verbs = sorted(derive_verbs())
        for verb in verbs:
            print(verb)
        return 0

    target_files = [Path(f) for f in args.files] if args.files else None
    count, findings = check_scenarios(target_files)

    if findings:
        print(f"FAILED -- scenario action check found {len(findings)} problem(s):", file=sys.stderr)
        for finding in findings:
            print(f"  {finding}", file=sys.stderr)
        return 1

    print(f"scenario action check: {count} scenario file(s) checked, all verbs valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
