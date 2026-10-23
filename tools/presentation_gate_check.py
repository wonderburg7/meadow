"""Check that `is_on_screen` calls in GDScript files are presentation-only.

Usage:
    python tools/presentation_gate_check.py [directory_or_file ...]

By default, scans `scripts/` for any calls to `is_on_screen(`. Every call site
must belong to an allowlisted presentation-only function (e.g. visual updates)
and never gate simulation or state logic.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# Allowlist maps (file_path_relative_to_repo, function_name) to justification.
# Only presentation-only functions (visual updates, label formatting, rings)
# and engine wrapper definitions may call `is_on_screen`.
ALLOWLIST: dict[tuple[str, str], str] = {
    ("scripts/bee.gd", "_update_label"): (
        "Presentation only: skips bee label text updates and body darkening when off screen."
    ),
    ("scripts/bee.gd", "_update_alarm_ring"): (
        "Presentation only: skips updating alarm and attack ring visibility when off screen."
    ),
    ("scripts/bee.gd", "_update_heading_marker"): (
        "Presentation only: skips heading marker rotation and visibility updates when off screen."
    ),
    ("scripts/bee.gd", "_update_search_ring"): (
        "Presentation only: skips search ring scale pulse calculations when off screen."
    ),
    ("scripts/bee.gd", "_update_dance_ring"): (
        "Presentation only: skips recruitment dance highlight ring pulse calculations when off screen."
    ),
    ("scripts/bee.gd", "_update_wander_flight"): (
        "Presentation only: skips visual_root flight wander trig and easing calculations when off screen."
    ),
    ("scripts/bee.gd", "_update_dance_circle"): (
        "Presentation only: skips mentor visual_root orbit offset calculations when off screen."
    ),
    ("scripts/main.gd", "is_on_screen"): (
        "Wrapper definition: main.gd delegates is_on_screen to world_building."
    ),
}

FUNC_DEF_PATTERN = re.compile(r"^\s*(?:static\s+)?func\s+([A-Za-z0-9_]+)\b")
CALL_PATTERN = re.compile(r"(?<!func\s)\bis_on_screen\s*\(")


def blank_comments_and_strings(code: str) -> str:
    """Replace contents of comments and string literals with spaces.

    Preserves newlines and character positions so line numbers remain exact.
    """
    chars = list(code)
    length = len(chars)
    i = 0
    state = "NORMAL"

    while i < length:
        ch = chars[i]

        if state == "NORMAL":
            if ch == "#":
                # Comment until end of line
                chars[i] = " "
                i += 1
                while i < length and chars[i] != "\n":
                    chars[i] = " "
                    i += 1
                continue
            elif ch == '"':
                if i + 2 < length and chars[i + 1] == '"' and chars[i + 2] == '"':
                    state = "TRIPLE_DOUBLE"
                    chars[i] = chars[i + 1] = chars[i + 2] = " "
                    i += 3
                    continue
                else:
                    state = "DOUBLE"
                    chars[i] = " "
                    i += 1
                    continue
            elif ch == "'":
                if i + 2 < length and chars[i + 1] == "'" and chars[i + 2] == "'":
                    state = "TRIPLE_SINGLE"
                    chars[i] = chars[i + 1] = chars[i + 2] = " "
                    i += 3
                    continue
                else:
                    state = "SINGLE"
                    chars[i] = " "
                    i += 1
                    continue
        elif state == "DOUBLE":
            if ch == "\\":
                chars[i] = " "
                if i + 1 < length and chars[i + 1] != "\n":
                    chars[i + 1] = " "
                    i += 2
                    continue
            elif ch == '"':
                state = "NORMAL"
                chars[i] = " "
                i += 1
                continue
            elif ch != "\n":
                chars[i] = " "
        elif state == "SINGLE":
            if ch == "\\":
                chars[i] = " "
                if i + 1 < length and chars[i + 1] != "\n":
                    chars[i + 1] = " "
                    i += 2
                    continue
            elif ch == "'":
                state = "NORMAL"
                chars[i] = " "
                i += 1
                continue
            elif ch != "\n":
                chars[i] = " "
        elif state == "TRIPLE_DOUBLE":
            if ch == '"' and i + 2 < length and chars[i + 1] == '"' and chars[i + 2] == '"':
                state = "NORMAL"
                chars[i] = chars[i + 1] = chars[i + 2] = " "
                i += 3
                continue
            elif ch != "\n":
                chars[i] = " "
        elif state == "TRIPLE_SINGLE":
            if ch == "'" and i + 2 < length and chars[i + 1] == "'" and chars[i + 2] == "'":
                state = "NORMAL"
                chars[i] = chars[i + 1] = chars[i + 2] = " "
                i += 3
                continue
            elif ch != "\n":
                chars[i] = " "

        i += 1

    return "".join(chars)


def find_is_on_screen_calls(code: str, file_path: str = "") -> list[dict]:
    """Find all calls to `is_on_screen(` in GDScript code.

    Returns a list of dicts with keys:
    - file_path: str
    - line_number: int (1-based)
    - function_name: str (enclosing function, or "<outer>" if outside a function)
    - line_content: str
    """
    cleaned_code = blank_comments_and_strings(code)
    raw_lines = code.splitlines()
    cleaned_lines = cleaned_code.splitlines()

    results = []
    current_func = "<outer>"

    for idx, line in enumerate(cleaned_lines):
        line_num = idx + 1
        raw_line = raw_lines[idx] if idx < len(raw_lines) else ""

        # Check for function header definition
        func_match = FUNC_DEF_PATTERN.match(line)
        if func_match:
            current_func = func_match.group(1)

        # Check for call site (excluding function header itself)
        if CALL_PATTERN.search(line):
            results.append({
                "file_path": file_path,
                "line_number": line_num,
                "function_name": current_func,
                "line_content": raw_line.strip(),
            })

    return results


def check_paths(paths: list[Path], root_dir: Path | None = None) -> tuple[list[dict], list[dict]]:
    """Scan GDScript files in paths for is_on_screen calls.

    Returns (allowlisted_calls, unallowlisted_calls).
    """
    if root_dir is None:
        root_dir = Path.cwd()

    all_calls = []
    for path in paths:
        if path.is_dir():
            gd_files = sorted(path.rglob("*.gd"))
        elif path.suffix == ".gd" and path.exists():
            gd_files = [path]
        else:
            continue

        for gd_file in gd_files:
            try:
                rel_path = str(gd_file.relative_to(root_dir)).replace("\\", "/")
            except ValueError:
                rel_path = str(gd_file).replace("\\", "/")

            try:
                content = gd_file.read_text(encoding="utf-8")
            except OSError:
                continue

            calls = find_is_on_screen_calls(content, file_path=rel_path)
            all_calls.extend(calls)

    allowlisted = []
    unallowlisted = []

    for call in all_calls:
        key = (call["file_path"], call["function_name"])
        if key in ALLOWLIST:
            allowlisted.append(call)
        else:
            unallowlisted.append(call)

    return allowlisted, unallowlisted


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "paths",
        nargs="*",
        default=["scripts"],
        help="Directories or files to scan (default: scripts)",
    )
    args = parser.parse_args()

    repo_root = Path.cwd()
    target_paths = [repo_root / p for p in args.paths]

    allowlisted, unallowlisted = check_paths(target_paths, root_dir=repo_root)

    print(f"Scanned for `is_on_screen` calls in: {', '.join(args.paths)}")
    print(f"Found {len(allowlisted) + len(unallowlisted)} call site(s):")
    for call in allowlisted:
        print(f"  [OK - Allowlisted] {call['file_path']}:{call['line_number']} in `{call['function_name']}()` -> {call['line_content']}")

    if unallowlisted:
        print("\nERROR: Found unallowlisted `is_on_screen` call site(s):", file=sys.stderr)
        for call in unallowlisted:
            print(f"  [FAIL] {call['file_path']}:{call['line_number']} in `{call['function_name']}()`: {call['line_content']}", file=sys.stderr)
        print("\nIf this is presentation-only, add it to ALLOWLIST in tools/presentation_gate_check.py with justification.", file=sys.stderr)
        print("If it gates simulation or game state logic, it is a gameplay bug that must be refactored.", file=sys.stderr)
        return 1

    print("\nAll `is_on_screen` calls are verified presentation-only.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
