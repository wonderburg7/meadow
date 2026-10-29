#!/usr/bin/env python3
"""Check scripts/ui_panel_layout.gd for layout size/position setters.

Why this exists
---------------
`scripts/ui_panel_layout.gd` enforces an offset-only layout budget contract for
persistent HUD panels. Sizing controls via `.size`, `.position`,
`.global_position`, `.set_size()`, `.set_position()` or `.reset_size()`
silently converts bottom-anchored panel pins into top pins, causing panels to
grow past the viewport bottom.

This tool ensures `scripts/ui_panel_layout.gd` never uses forbidden setters or
assignments, while allowing reads and offset assignments.

Usage
-----
    python tools/layout_setter_check.py [files...]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_TARGET = ROOT / "scripts" / "ui_panel_layout.gd"

# Pattern for prohibited property assignments:
# matches .size, .position, .global_position (with optional component like .x)
# followed by assignment (=, +=, -=, *=, /=, %=, &=, |=, ^=, etc.)
ASSIGN_PATTERN = re.compile(
    r"\.(?:size|position|global_position)(?:\.[A-Za-z_]\w*)?\s*(?:[+\-*/%&|^]|\*\*|<<|>>)?=(?!=)"
)

# Pattern for prohibited method calls:
# matches .set_size(...), .set_position(...), .reset_size(...)
METHOD_PATTERN = re.compile(
    r"\.(?:set_size|set_position|reset_size)\s*\("
)


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


def check_layout_setters(text: str, file_path: str = "scripts/ui_panel_layout.gd") -> list[str]:
    """Check source text for forbidden layout setters or assignments.

    Returns a list of diagnostic strings for any violations.
    """
    cleaned_code = blank_comments_and_strings(text)
    raw_lines = text.splitlines()
    cleaned_lines = cleaned_code.splitlines()

    diagnostics: list[str] = []

    for idx, cleaned_line in enumerate(cleaned_lines):
        line_num = idx + 1
        raw_line = raw_lines[idx] if idx < len(raw_lines) else ""

        assign_match = ASSIGN_PATTERN.search(cleaned_line)
        if assign_match:
            diagnostics.append(
                f"{file_path}:{line_num}: forbidden layout property assignment in `{raw_line.strip()}`"
            )
            continue

        method_match = METHOD_PATTERN.search(cleaned_line)
        if method_match:
            diagnostics.append(
                f"{file_path}:{line_num}: forbidden layout method call in `{raw_line.strip()}`"
            )
            continue

    return diagnostics


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check scripts/ui_panel_layout.gd for forbidden layout setters."
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="Files to check (defaults to scripts/ui_panel_layout.gd).",
    )
    args = parser.parse_args(argv)

    if args.files:
        target_paths = [Path(f) for f in args.files]
    else:
        target_paths = [DEFAULT_TARGET]

    all_diagnostics: list[str] = []

    for target in target_paths:
        if not target.is_file():
            all_diagnostics.append(f"{target}: file not found")
            continue

        try:
            rel_path = target.resolve().relative_to(ROOT.resolve()).as_posix()
        except ValueError:
            rel_path = target.as_posix()

        try:
            content = target.read_text(encoding="utf-8")
        except OSError as err:
            all_diagnostics.append(f"{rel_path}: read error: {err}")
            continue

        diagnostics = check_layout_setters(content, file_path=rel_path)
        all_diagnostics.extend(diagnostics)

    if all_diagnostics:
        print("FAILED -- layout setter check found problems:", file=sys.stderr)
        for diag in all_diagnostics:
            print(f"  {diag}", file=sys.stderr)
        return 1

    print(f"layout setter check: {len(target_paths)} file(s) checked, no forbidden setters found")
    return 0


if __name__ == "__main__":
    sys.exit(main())
