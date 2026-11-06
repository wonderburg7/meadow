#!/usr/bin/env python3
"""Check that stage conditions checking cell designation distinguish explicit choice.

Why this exists
---------------
`docs/known-pitfalls.md`, "A goal that asks 'is any of them X' passes on the one
that was always X":
Challenge 1's stage 1.13 asks the player to set the second cell aside for
pollen; its goal check returned true for any cell with any designation, and
HiveCell.add_resource auto-designates a cell on its first deposit. The first cell
had been nectar-designated since stage 1.10, so the stage cleared in the frame it
opened and was never seen. A goal that names a player's choice must distinguish
the choice from the automatic default by requiring `"explicit": true`.

This tool scans GDScript stage definitions (defaulting to
`scripts/challenge_stages.gd`) for stage condition dictionaries containing
`"cell_count"` with `"designated"`. Any such specification must explicitly set
`"explicit": true`.

Usage
-----
    python tools/goal_default_check.py [files...]
"""

from __future__ import annotations

import argparse
import io
import sys
import tokenize
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

DEFAULT_FILES = [
    ROOT / "scripts" / "challenge_stages.gd",
]


def _clean_string(s: str) -> str:
    """Extract string value without outer quotes."""
    if (s.startswith('"""') and s.endswith('"""')) or (s.startswith("'''") and s.endswith("'''")):
        return s[3:-3]
    if (s.startswith('"') and s.endswith('"')) or (s.startswith("'") and s.endswith("'")):
        return s[1:-1]
    return s


def check_content(content: str, filename: str = "challenge_stages.gd") -> list[str]:
    """Check text content for cell_count designation conditions lacking explicit requirement."""
    try:
        tokens = list(tokenize.tokenize(io.BytesIO(content.encode("utf-8")).readline))
    except Exception as err:
        return [f"{filename}: could not tokenize file ({err})"]

    problems: list[str] = []
    i = 0
    n = len(tokens)

    while i < n:
        tok = tokens[i]
        # Check if token is string literal evaluating to "cell_count"
        if tok.type == tokenize.STRING:
            s_val = _clean_string(tok.string)
            if s_val == "cell_count":
                # Look ahead for colon and opening brace
                j = i + 1
                while j < n and tokens[j].type in (tokenize.NL, tokenize.COMMENT):
                    j += 1
                if j < n and tokens[j].exact_type == tokenize.COLON:
                    j += 1
                    while j < n and tokens[j].type in (tokenize.NL, tokenize.COMMENT):
                        j += 1
                    if j < n and tokens[j].exact_type == tokenize.LBRACE:
                        # Extract inner dictionary tokens matching this brace level
                        brace_depth = 1
                        k = j + 1
                        inner_tokens: list[tokenize.TokenInfo] = []
                        while k < n and brace_depth > 0:
                            if tokens[k].exact_type == tokenize.LBRACE:
                                brace_depth += 1
                            elif tokens[k].exact_type == tokenize.RBRACE:
                                brace_depth -= 1
                                if brace_depth == 0:
                                    break
                            inner_tokens.append(tokens[k])
                            k += 1

                        # Parse key-value pairs at top level of inner dictionary
                        keys_and_values: dict[str, list[tokenize.TokenInfo]] = {}
                        depth = 0
                        current_key: str | None = None
                        expecting_key = True
                        val_tokens: list[tokenize.TokenInfo] = []

                        m = 0
                        while m < len(inner_tokens):
                            t = inner_tokens[m]
                            if t.exact_type in (tokenize.LBRACE, tokenize.LSQB, tokenize.LPAR):
                                depth += 1
                                if not expecting_key:
                                    val_tokens.append(t)
                            elif t.exact_type in (tokenize.RBRACE, tokenize.RSQB, tokenize.RPAR):
                                depth -= 1
                                if not expecting_key:
                                    val_tokens.append(t)
                            elif depth == 0:
                                if expecting_key:
                                    if t.type == tokenize.STRING:
                                        k_str = _clean_string(t.string)
                                        # Look ahead for COLON
                                        m_next = m + 1
                                        while (
                                            m_next < len(inner_tokens)
                                            and inner_tokens[m_next].type
                                            in (tokenize.NL, tokenize.COMMENT)
                                        ):
                                            m_next += 1
                                        if (
                                            m_next < len(inner_tokens)
                                            and inner_tokens[m_next].exact_type == tokenize.COLON
                                        ):
                                            current_key = k_str
                                            expecting_key = False
                                            val_tokens = []
                                            m = m_next
                                elif t.exact_type == tokenize.COMMA:
                                    if current_key is not None:
                                        keys_and_values[current_key] = val_tokens
                                        current_key = None
                                        expecting_key = True
                                        val_tokens = []
                                else:
                                    val_tokens.append(t)
                            else:
                                val_tokens.append(t)
                            m += 1

                        if current_key is not None:
                            keys_and_values[current_key] = val_tokens

                        # If "designated" is specified, require "explicit": true
                        if "designated" in keys_and_values:
                            explicit_tokens = keys_and_values.get("explicit", [])
                            meaningful = [
                                t
                                for t in explicit_tokens
                                if t.type not in (tokenize.NL, tokenize.COMMENT)
                            ]
                            has_explicit_true = len(meaningful) == 1 and meaningful[0].string == "true"
                            if not has_explicit_true:
                                problems.append(
                                    f"{filename}:{tok.start[0]} cell_count specifies 'designated' without 'explicit: true'"
                                )
        i += 1

    return problems


def check_file(path: Path) -> list[str]:
    """Check a single file for cell_count designation defaults."""
    if not path.exists():
        return [f"{path}: file does not exist"]
    try:
        content = path.read_text(encoding="utf-8")
    except OSError as err:
        return [f"{path}: could not read file ({err})"]

    try:
        rel = path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        rel = path.as_posix()

    return check_content(content, filename=rel)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check that cell designation goal conditions require 'explicit: true'."
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="GDScript files to check (defaults to scripts/challenge_stages.gd).",
    )
    args = parser.parse_args(argv)

    target_files = [Path(f) for f in args.files] if args.files else DEFAULT_FILES

    problems: list[str] = []
    for path in target_files:
        problems.extend(check_file(path))

    if problems:
        print("FAILED -- goal default check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print(
        f"goal default check: {len(target_files)} files checked, no unguarded designation goal conditions"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
