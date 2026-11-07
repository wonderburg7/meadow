#!/usr/bin/env python3
"""Check scenario action verbs against the harness offline.

Why this exists
---------------
E30-2 in docs/jules-efficiency/e-30.md (#126, accepted 6 Nov 2026):
A misspelt "do" verb in test_scenarios/*.json is only reported once Godot runs
the scenario. This tool validates scenario action dictionaries offline against
verbs recognised by scripts/scenario_actions.gd.

Verbs are derived dynamically each run from scripts/scenario_actions.gd:
the string match arms of _execute plus the verbs run_pending compares the
"do" value against before it reaches _execute (assert, wait, settle today).
Comments never count, and blank or column-zero comment lines do not end a
function. The verb list is never hard-coded.

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

ROOT = Path(__file__).resolve().parent.parent
ACTIONS_GD = ROOT / "scripts" / "scenario_actions.gd"
SCENARIOS_DIR = ROOT / "test_scenarios"

_STRING = r'"(?:[^"\\]|\\.)*"'


def code_only(line: str) -> str:
    """Drop a GDScript `#` comment that is outside a string literal."""
    quote = ""
    i = 0
    while i < len(line):
        c = line[i]
        if quote:
            if c == "\\":
                i += 2
                continue
            if c == quote:
                quote = ""
        elif c in "\"'":
            quote = c
        elif c == "#":
            return line[:i].rstrip()
        i += 1
    return line.rstrip()


def function_body(gdscript_text: str, name: str) -> list[str]:
    """Return the code lines of `func <name>`, comments blanked.

    The body runs until the next line at column zero that holds code, so blank
    lines and comments (at any indent, column zero included) never end it.
    """
    lines = gdscript_text.splitlines()
    header = re.compile(rf"^(?:static\s+)?func\s+{re.escape(name)}\s*\(")
    for i, line in enumerate(lines):
        if header.match(line):
            body: list[str] = []
            for raw in lines[i + 1:]:
                code = code_only(raw)
                if code.strip() and not raw[:1].isspace():
                    break
                body.append(code)
            return body
    raise ValueError(f"Could not find func {name} in GDScript text")


def _indent(line: str) -> int:
    return len(line) - len(line.lstrip())


def _arm_pattern(line: str) -> str:
    """The pattern part of a match arm line: everything before its own ':'."""
    quote = ""
    depth = 0
    for i, c in enumerate(line):
        if quote:
            if c == quote and line[i - 1] != "\\":
                quote = ""
        elif c in "\"'":
            quote = c
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == ":" and depth == 0:
            return line[:i]
    return ""


def extract_execute_arms(gdscript_text: str) -> list[str]:
    """Extract the string-literal match arm verbs of `_execute`.

    Arms are the lines one indent level inside `_execute`'s `match` on the
    action's "do" value; an arm may list several strings or carry a `when`
    guard. Binding and wildcard arms (`var other:`, `_:`) name no verb.
    """
    body = function_body(gdscript_text, "_execute")
    match_re = re.compile(r'^\s*match\s+.*\bget\(\s*"do"')
    for start, line in enumerate(body):
        if match_re.match(line):
            break
    else:
        raise ValueError('No `match` on the "do" value found in _execute')
    match_indent = _indent(body[start])
    arm_indent = None
    arms: list[str] = []
    for line in body[start + 1:]:
        if not line.strip():
            continue
        indent = _indent(line)
        if indent <= match_indent:
            break
        if arm_indent is None:
            arm_indent = indent
        if indent != arm_indent:
            continue
        pattern = re.split(r"\bwhen\b", _arm_pattern(line), maxsplit=1)[0].strip()
        if re.fullmatch(rf"{_STRING}(?:\s*,\s*{_STRING})*", pattern):
            arms.extend(re.findall(r'"((?:[^"\\]|\\.)*)"', pattern))
    if not arms:
        raise ValueError("No string match arms found in _execute body")
    return arms


def extract_sequence_verbs(gdscript_text: str) -> list[str]:
    """Extract the verbs `run_pending` handles itself before `_execute`.

    Each is a comparison of the action's "do" value with a string literal,
    in either order.
    """
    code = "\n".join(function_body(gdscript_text, "run_pending"))
    get_do = r'\.get\(\s*"do"\s*(?:,\s*' + _STRING + r'\s*)?\)\)?'
    verbs = re.findall(get_do + r'\s*==\s*"(\w+)"', code)
    verbs += re.findall(r'"(\w+)"\s*==\s*(?:str\()?[\w.]*' + get_do, code)
    if not verbs:
        raise ValueError("No sequence verb comparisons found in run_pending")
    return list(dict.fromkeys(verbs))


def derive_recognised_verbs(actions_gd_path: Path | str = ACTIONS_GD) -> set[str]:
    """Derive all recognised action verbs from scenario_actions.gd's executable code."""
    text = Path(actions_gd_path).read_text(encoding="utf-8")
    return set(extract_execute_arms(text)) | set(extract_sequence_verbs(text))


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
        default=ACTIONS_GD,
        help="Path to scripts/scenario_actions.gd (default: the repository's)",
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
        files_to_check = sorted(SCENARIOS_DIR.rglob("*.json"))

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
