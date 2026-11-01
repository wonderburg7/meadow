#!/usr/bin/env python3
"""Check that shared stage marker reparenting is centralised across all stages.

Why this exists
---------------
`docs/known-pitfalls.md`, "A marker reparented by some branches and not others
ends up in the wrong world":
`challenge_runner.gd::_update_marker` reparented the shared stage marker in two
of its four branches. The branch covering stages 1.2, 1.5, 1.12 and 1.15 set a
hive-local position and showed the marker without reparenting, so after the
meadow tour at 1.7/1.10 the marker stayed in the meadow and a yellow dot
appeared in open ground. If several branches share one node, the parent belongs
in one place that always runs, not in each branch that remembers.

This tool checks that:
1. `_update_marker` selects `marker_parent` in a centralised block before
   positioning branches run.
2. Every stage that positions the marker directly in hive or meadow space is
   accounted for in `marker_parent` selection.
3. No stage positioning branch performs branch-local `_marker.reparent(...)`
   calls instead of using the centralised reparenting mechanism.
4. `_show_current_visit_point` verifies parentage against `_visit_marker_parent`
   before setting marker position.

Usage
-----
    python tools/marker_reparent_check.py [files...]
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Stages known to position _marker in hive coordinates.
EXPECTED_HIVE_STAGES = {"1.2", "1.5", "1.6", "1.12", "1.15", "1.19"}

# Stages known to position _marker in meadow coordinates.
EXPECTED_MEADOW_STAGES = {"1.10"}


def check_update_marker(text: str) -> list[str]:
    """Check _update_marker function body for centralised reparenting."""
    problems: list[str] = []

    m = re.search(
        r"func _update_marker\(stage_id:\s*String\)\s*->\s*void:(.*?)(?=\nfunc |\Z)",
        text,
        re.DOTALL,
    )
    if not m:
        return ["func _update_marker not found in source"]

    body = m.group(1)

    # Check for centralised reparent call
    reparent_match = re.search(
        r"_marker\.reparent\(\s*marker_parent\s*,\s*false\s*\)",
        body,
    )
    if not reparent_match:
        problems.append(
            "_update_marker does not perform centralised reparenting via "
            "'_marker.reparent(marker_parent, false)'"
        )
        return problems

    reparent_pos = reparent_match.start()
    reparent_end = reparent_match.end()
    pre_reparent = body[:reparent_pos]
    post_reparent = body[reparent_end:]

    # Check that hive parent assignment includes all expected hive stages
    hive_match = re.search(
        r'if\s+stage_id\s+in\s+\[([^\]]+)\]:\s*\n\s*marker_parent\s*=\s*main\.hive_root',
        pre_reparent,
    )
    if not hive_match:
        problems.append(
            "_update_marker missing centralised hive_root assignment for stage_id"
        )
    else:
        stages_listed = set(re.findall(r'"([^"]+)"', hive_match.group(1)))
        missing = EXPECTED_HIVE_STAGES - stages_listed
        if missing:
            problems.append(
                f"_update_marker hive_root stages missing expected stages: {sorted(missing)}"
            )

    # Check that meadow parent assignment includes all expected meadow stages
    meadow_match = re.search(
        r'elif\s+stage_id\s+(?:==\s*"([^"]+)"|in\s+\[([^\]]+)\]):\s*\n\s*marker_parent\s*=\s*main\.meadow_root',
        pre_reparent,
    )
    if not meadow_match:
        problems.append(
            "_update_marker missing centralised meadow_root assignment for stage_id"
        )
    else:
        stages_listed = set()
        if meadow_match.group(1):
            stages_listed.add(meadow_match.group(1))
        if meadow_match.group(2):
            stages_listed.update(re.findall(r'"([^"]+)"', meadow_match.group(2)))
        missing = EXPECTED_MEADOW_STAGES - stages_listed
        if missing:
            problems.append(
                f"_update_marker meadow_root stages missing expected stages: {sorted(missing)}"
            )

    # Check that positioning branches do not do branch-local reparenting
    # Any other .reparent() calls inside post_reparent are forbidden
    if "_marker.reparent" in post_reparent:
        problems.append(
            "_update_marker has branch-local '_marker.reparent' call after centralised block"
        )

    # Ensure positioning branches follow the centralised reparent call
    pos_match = re.search(r"_marker\.position\s*=", post_reparent)
    if not pos_match:
        problems.append(
            "_update_marker does not set '_marker.position' after centralised reparenting"
        )

    return problems


def check_visit_point(text: str) -> list[str]:
    """Check _show_current_visit_point function body for parentage check before positioning."""
    problems: list[str] = []

    m = re.search(
        r"func _show_current_visit_point\(\)\s*->\s*void:(.*?)(?=\nfunc |\Z)",
        text,
        re.DOTALL,
    )
    if not m:
        return ["func _show_current_visit_point not found in source"]

    body = m.group(1)

    reparent_match = re.search(
        r"_marker\.get_parent\(\)\s*!=\s*_visit_marker_parent:.*?"
        r"_marker\.reparent\(_visit_marker_parent,\s*false\)",
        body,
        re.DOTALL,
    )
    if not reparent_match:
        problems.append(
            "_show_current_visit_point does not verify or reparent '_marker' to '_visit_marker_parent'"
        )
        return problems

    pos_match = re.search(r"_marker\.position\s*=", body)
    if not pos_match or pos_match.start() < reparent_match.end():
        problems.append(
            "_show_current_visit_point sets '_marker.position' before reparenting to '_visit_marker_parent'"
        )

    return problems


def check_file(filepath: Path | str, text: str | None = None) -> list[str]:
    """Check a challenge runner script for marker reparenting issues."""
    path = Path(filepath)
    if text is None:
        text = path.read_text(encoding="utf-8")

    problems: list[str] = []
    problems.extend(check_update_marker(text))
    problems.extend(check_visit_point(text))
    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check that shared stage marker reparenting is centralised."
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="Files to check (defaults to scripts/challenge_runner.gd).",
    )
    args = parser.parse_args(argv)

    if args.files:
        files = [Path(f) for f in args.files]
    else:
        files = [ROOT / "scripts" / "challenge_runner.gd"]

    problems: list[str] = []
    for path in files:
        if path.is_file():
            problems.extend(check_file(path))

    if problems:
        print("FAILED -- marker reparent check found problems:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1

    print(
        f"marker reparent check: {len(files)} file(s) checked, reparenting is centralised"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
