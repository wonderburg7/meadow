#!/usr/bin/env python3
"""Check that bee flower-seeking and focus transitions prevent indoor coordinate mismatches.

Why this exists
---------------
`docs/known-pitfalls.md`, "A bee under `hive_root` is in hive-local coordinates; a flower is not (19 Sep 2026)":
Parenting decides the space `bee.position` is in. A Forager idling indoors was
dispatched to flower-seeking where she stood, compared her hive-local position
with meadow flower positions, and flew to, and drank from, points inside the hive
where no flower was -- C-7's pollen half failed on this through three passes
while each fix looked elsewhere. Any behaviour that compares a bee's position
with a meadow thing must first put her in the meadow; for flowers that rule
lives in `bee_foraging.gd::_walk_out_if_indoors`, and `bee.gd::set_focus` says the
same for focus changes.

This tool checks that:
1. `scripts/bee_foraging.gd` defines `_walk_out_if_indoors(bee)`.
2. `_walk_out_if_indoors` checks `not bee._is_inside_hive(): return false`,
   routes an indoor bee via `bee.state = autonomous_state(bee, State.IN_HIVE_TO_EXIT)`,
   and returns `true`.
3. Flower perception / search entry functions (`seek_flower` and `search_for_flower`)
   guard their entry with `if _walk_out_if_indoors(bee):` and immediately `return`.
4. `scripts/bee.gd`'s `set_focus()` only ever assigns `State.SEEK_FLOWER` inside an
   `if not _is_inside_hive():` block, with no subsequent or unguarded assignments
   to `State.SEEK_FLOWER`, and routes indoor bees to `State.IN_HIVE_TO_EXIT`.

Usage
-----
    python tools/indoor_flower_check.py [files...]
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def strip_code_line(line: str) -> str:
    """Drop string literals and trailing comments from a single line of code."""
    out, i, n = [], 0, len(line)
    while i < n:
        c = line[i]
        if c == "#":
            break
        if c in ('"', "'"):
            quote = c
            i += 1
            while i < n:
                if line[i] == "\\":
                    i += 2
                    continue
                if line[i] == quote:
                    i += 1
                    break
                i += 1
            out.append('""')
            continue
        out.append(c)
        i += 1
    return "".join(out)


def strip_code(text: str) -> str:
    """Strip strings and comments from text preserving line breaks."""
    return "\n".join(strip_code_line(line) for line in text.splitlines())


def _extract_func_body(lines: list[str], func_name: str) -> tuple[int, list[str]]:
    """Extract (start_line_no, body_lines) for a function in GDScript lines."""
    in_func = False
    func_indent = -1
    body_lines: list[str] = []
    start_line = -1

    for line_no, raw_line in enumerate(lines, 1):
        stripped = strip_code_line(raw_line)
        if in_func:
            if not raw_line.strip():
                body_lines.append(raw_line)
                continue
            indent = len(raw_line) - len(raw_line.lstrip())
            if indent <= func_indent:
                break
            body_lines.append(raw_line)
        else:
            m = re.match(
                r"^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:static\s+)?func\s+"
                + re.escape(func_name)
                + r"\b",
                stripped,
            )
            if m:
                in_func = True
                func_indent = len(raw_line) - len(raw_line.lstrip())
                start_line = line_no

    return start_line, body_lines


def check_bee_foraging(text: str, filename: str = "scripts/bee_foraging.gd") -> list[str]:
    """Check bee_foraging.gd for proper indoor flower perception guards."""
    problems: list[str] = []
    lines = text.splitlines()

    start, walk_out_body = _extract_func_body(lines, "_walk_out_if_indoors")
    if start == -1:
        problems.append(f"{filename}: static func _walk_out_if_indoors(bee) not found")
        return problems

    walk_out_text = "\n".join(walk_out_body)
    stripped_walk_out = strip_code(walk_out_text)

    # Check that when outdoors, it returns false
    if not re.search(r"if\s+not\s+bee\._is_inside_hive\(\)\s*:\s*\n\s*return\s+false\b", stripped_walk_out):
        problems.append(
            f"{filename}:{start}: _walk_out_if_indoors must return false when not bee._is_inside_hive()"
        )

    # Check that when indoors, it sets State.IN_HIVE_TO_EXIT via autonomous_state
    if not re.search(r"bee\.state\s*=\s*autonomous_state\(\s*bee\s*,\s*State\.IN_HIVE_TO_EXIT\s*\)", stripped_walk_out):
        problems.append(
            f"{filename}:{start}: _walk_out_if_indoors must set State.IN_HIVE_TO_EXIT via autonomous_state"
        )

    # Check that it returns true when walking out indoors
    if not re.search(r"\n\s*return\s+true\b", stripped_walk_out):
        problems.append(
            f"{filename}:{start}: _walk_out_if_indoors must return true when bee is inside hive"
        )

    for guarded_func in ("seek_flower", "search_for_flower"):
        f_start, f_body = _extract_func_body(lines, guarded_func)
        if f_start == -1:
            problems.append(f"{filename}: func {guarded_func} not found")
            continue

        exec_statements: list[tuple[str, int]] = []
        for line in f_body:
            st = strip_code_line(line).strip()
            if st:
                exec_statements.append((st, len(line) - len(line.lstrip())))

        if not exec_statements:
            problems.append(f"{filename}:{f_start}: func {guarded_func} has empty body")
            continue

        first_stmt, first_indent = exec_statements[0]
        if first_stmt != "if _walk_out_if_indoors(bee):":
            problems.append(
                f"{filename}:{f_start}: {guarded_func} must start with 'if _walk_out_if_indoors(bee):', found: '{first_stmt}'"
            )
            continue

        if len(exec_statements) < 2:
            problems.append(f"{filename}:{f_start}: {guarded_func} missing body for 'if _walk_out_if_indoors(bee):'")
            continue

        second_stmt, second_indent = exec_statements[1]
        if second_indent <= first_indent or second_stmt != "return":
            problems.append(
                f"{filename}:{f_start}: {guarded_func} must immediately 'return' when _walk_out_if_indoors(bee) is true, found: '{second_stmt}'"
            )

    return problems


def check_bee_focus(text: str, filename: str = "scripts/bee.gd") -> list[str]:
    """Check bee.gd::set_focus to ensure indoor bees are not dispatched straight to flowers."""
    problems: list[str] = []
    lines = text.splitlines()

    start, body = _extract_func_body(lines, "set_focus")
    if start == -1:
        problems.append(f"{filename}: func set_focus not found")
        return problems

    # Parse enclosing control flow line by line
    seek_flower_assign_re = re.compile(r"^\s*state\s*=\s*(?:BeeEnums\.)?State\.SEEK_FLOWER\b")
    enclosed_in_outdoor_check = False
    outdoor_indent = -1
    found_seek_flower_assignment = False

    for idx, raw_line in enumerate(body, start + 1):
        stripped = strip_code_line(raw_line).strip()
        if not stripped:
            continue
        indent = len(raw_line) - len(raw_line.lstrip())

        if enclosed_in_outdoor_check and indent <= outdoor_indent:
            enclosed_in_outdoor_check = False

        if re.match(r"^if\s+not\s+_is_inside_hive\(\)\s*:", stripped):
            enclosed_in_outdoor_check = True
            outdoor_indent = indent

        if seek_flower_assign_re.match(stripped):
            found_seek_flower_assignment = True
            if not enclosed_in_outdoor_check:
                problems.append(
                    f"{filename}:{idx}: assignment 'state = State.SEEK_FLOWER' is not enclosed in 'if not _is_inside_hive():'"
                )

    if not found_seek_flower_assignment:
        problems.append(
            f"{filename}:{start}: set_focus() contains no assignment to State.SEEK_FLOWER"
        )

    # And indoor bees must be routed to State.IN_HIVE_TO_EXIT
    stripped_body = strip_code("\n".join(body))
    exit_check = re.search(
        r"state\s*=\s*(?:BeeEnums\.)?State\.IN_HIVE_TO_EXIT",
        stripped_body,
    )
    if not exit_check:
        problems.append(
            f"{filename}:{start}: set_focus() does not route indoor bees to State.IN_HIVE_TO_EXIT"
        )

    return problems


def check_file(filepath: Path | str, text: str | None = None) -> list[str]:
    """Check a script file for indoor flower coordinate pitfall guards."""
    path = Path(filepath)
    if text is None:
        text = path.read_text(encoding="utf-8")

    name = path.name
    problems: list[str] = []
    if name == "bee_foraging.gd":
        problems.extend(check_bee_foraging(text, path.as_posix()))
    elif name == "bee.gd":
        problems.extend(check_bee_focus(text, path.as_posix()))
    else:
        # Check against both if filename is generic / fixture
        if "func _walk_out_if_indoors" in text or "func seek_flower" in text:
            problems.extend(check_bee_foraging(text, path.as_posix()))
        if "func set_focus" in text:
            problems.extend(check_bee_focus(text, path.as_posix()))

    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check that flower-seeking and focus changes prevent indoor coordinate mismatches."
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="GDScript files to check (defaults to scripts/bee_foraging.gd and scripts/bee.gd).",
    )
    args = parser.parse_args(argv)

    if args.files:
        files = [Path(f) for f in args.files]
    else:
        files = [ROOT / "scripts" / "bee_foraging.gd", ROOT / "scripts" / "bee.gd"]

    problems: list[str] = []
    for path in files:
        if not path.is_file():
            problems.append(f"{path}: file not found")
            continue
        problems.extend(check_file(path))

    if problems:
        print("FAILED -- indoor flower check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print(f"indoor flower check: {len(files)} file(s) checked, coordinate space invariants verified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
