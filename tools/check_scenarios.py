#!/usr/bin/env python3
"""Check test scenario action verbs offline against scripts/scenario_actions.gd.

Why this exists
---------------
E30-2 in `docs/jules-efficiency/e-30.md`:
A misspelt `"do"` verb in `test_scenarios/*.json` is only reported once Godot
runs the scenario. This tool checks every action dictionary in test scenario
files statically before launching Godot headless boots.

Recognized verbs are derived dynamically on each run from
`scripts/scenario_actions.gd`:
- The string match arms of `_execute`
- Sequence verbs handled by `run_pending` / `process`: `assert`, `wait`, `settle`
The list is never hard-coded.

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

SEQUENCE_VERBS = frozenset({"assert", "wait", "settle"})


def strip_comments_and_strings(code: str) -> str:
    """Mask GDScript comments while preserving code structure."""
    # We only mask comments; match arm strings need to be parsed
    token = re.compile(r"#[^\n]*")
    return token.sub("", code)


def parse_execute_arms(script_text: str) -> list[str]:
    """Extract string match arms from `static func _execute` in scenario_actions.gd."""
    # Locate static func _execute
    m_func = re.search(
        r"static\s+func\s+_execute\s*\([^)]*\)\s*->\s*void:\s*\n"
        r"(?:[ \t]+#[^\n]*\n)*"
        r"([ \t]+)match\s+action\.get\(\"do\",\s*\"\"\):\s*\n"
        r"(.*?)(?=\n\1[a-zA-Z_]|\Z)",
        script_text,
        re.DOTALL,
    )
    if not m_func:
        raise ValueError("Could not find `static func _execute` match block in scenario_actions.gd")

    match_body = m_func.group(2)
    # Match arms are written like: "assign_role": or 'assign_role':
    arm_matches = re.findall(r'^[ \t]*["\']([a-zA-Z0-9_]+)["\']\s*:', match_body, re.MULTILINE)
    return arm_matches


def derive_verbs(repo_root: Path | str = ROOT) -> set[str]:
    """Derive the recognized verb set dynamically from scripts/scenario_actions.gd."""
    script_path = Path(repo_root) / "scripts" / "scenario_actions.gd"
    if not script_path.is_file():
        raise FileNotFoundError(f"Missing script: {script_path}")

    text = script_path.read_text(encoding="utf-8")
    execute_arms = parse_execute_arms(text)
    return set(execute_arms) | SEQUENCE_VERBS


def collect_action_dicts(obj: object) -> list[tuple[int, dict[str, object]]]:
    """Walk an object tree and find all action dictionaries, recording their index."""
    results: list[tuple[int, dict[str, object]]] = []

    def _walk(node: object) -> None:
        if isinstance(node, dict):
            if "actions" in node and isinstance(node["actions"], list):
                for idx, item in enumerate(node["actions"]):
                    if isinstance(item, dict):
                        results.append((idx, item))
                        _walk(item)
                    else:
                        # Non-dict action entry
                        results.append((idx, item))  # type: ignore[arg-type]
            else:
                for v in node.values():
                    if isinstance(v, (dict, list)):
                        _walk(v)
        elif isinstance(node, list):
            for item in node:
                _walk(item)

    _walk(obj)
    return results


def check_scenario_file(file_path: Path, recognized_verbs: set[str]) -> list[str]:
    """Check a single scenario JSON file for valid action verbs."""
    problems: list[str] = []
    try:
        content = file_path.read_text(encoding="utf-8")
        data = json.loads(content)
    except Exception as exc:
        return [f"{file_path}: failed to load JSON: {exc}"]

    actions = collect_action_dicts(data)
    for idx, action in actions:
        if not isinstance(action, dict):
            problems.append(f"{file_path}: action {idx} is not a dictionary: {action!r}")
            continue

        if "do" not in action:
            problems.append(f"{file_path}: action {idx} missing 'do' verb")
            continue

        verb = action["do"]
        if not isinstance(verb, str):
            problems.append(f"{file_path}: action {idx} 'do' verb is not a string: {verb!r}")
            continue

        if verb not in recognized_verbs:
            problems.append(f"{file_path}: action {idx} unknown 'do' verb '{verb}'")

    return problems


def check_all_scenarios(repo_root: Path | str = ROOT) -> list[str]:
    """Check all scenario JSON files under test_scenarios/ in repo_root."""
    root = Path(repo_root)
    recognized_verbs = derive_verbs(root)
    scenarios_dir = root / "test_scenarios"
    if not scenarios_dir.exists():
        return [f"Directory not found: {scenarios_dir}"]

    problems: list[str] = []
    scenario_files = sorted(scenarios_dir.rglob("*.json"))
    for file_path in scenario_files:
        problems.extend(check_scenario_file(file_path, recognized_verbs))

    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check scenario action verbs offline against scripts/scenario_actions.gd."
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="Print derived recognized verbs, one per line, and exit.",
    )
    parser.add_argument(
        "root_dir",
        nargs="?",
        default=str(ROOT),
        help="Repository root directory (defaults to repo root).",
    )
    args = parser.parse_args(argv)

    root = Path(args.root_dir).resolve()
    try:
        verbs = derive_verbs(root)
    except Exception as exc:
        print(f"Error deriving verbs: {exc}", file=sys.stderr)
        return 1

    if args.list:
        for verb in sorted(verbs):
            print(verb)
        return 0

    problems = check_all_scenarios(root)
    if problems:
        print("FAILED -- check scenarios found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    scenario_count = len(list((root / "test_scenarios").rglob("*.json")))
    print(f"check scenarios: {scenario_count} scenarios checked, all action verbs recognised")
    return 0


if __name__ == "__main__":
    sys.exit(main())
