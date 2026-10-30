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

if __package__:
    from .presentation_gate_check import blank_comments_and_strings
else:
    from presentation_gate_check import blank_comments_and_strings

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


def check_layout_setters(text: str, file_path: str = "scripts/ui_panel_layout.gd") -> list[str]:
    """Check source text for forbidden layout setters or assignments.

    Returns a list of diagnostic strings for any violations.
    """
    cleaned_code = blank_comments_and_strings(text)
    raw_lines = text.splitlines()
    diagnostics: list[str] = []
    findings = [(match, "property assignment") for match in ASSIGN_PATTERN.finditer(cleaned_code)]
    findings += [(match, "method call") for match in METHOD_PATTERN.finditer(cleaned_code)]
    for match, kind in sorted(findings, key=lambda finding: finding[0].start()):
        line_num = cleaned_code.count("\n", 0, match.start()) + 1
        raw_line = raw_lines[line_num - 1]
        diagnostics.append(
            f"{file_path}:{line_num}: forbidden layout {kind} in `{raw_line.strip()}`; use offsets instead"
        )

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
        except (OSError, UnicodeError) as err:
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
