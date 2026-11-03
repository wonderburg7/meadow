"""Persist Jules's alternating tasks in commit trailers, without a new state file.

Used by python tools/jules_preflight.py --next and --scope E-<n>.
Ordinary PRs carry odd sequence numbers; efficiency reports carry even ones.
Read master and all fetched Jules branches so an unmerged PR also advances
next session's turn. Corrections keep their number; integrators preserve it.
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

METHOD = "plans/reference/jules-efficiency.md"
FOCUSES = (
    "slice briefs and acceptance criteria",
    "code navigation and understanding ownership",
    "implementing game slices without rediscovering contracts",
    "verification, failure diagnosis and useful test output",
    "review, integration and recommendation handoffs",
    "development tools, documentation routing and repeated setup",
)
TRAILER = re.compile(r"^Jules-Sequence: ([1-9][0-9]*) (ordinary|efficiency)$", re.MULTILINE)


def next_turn(root: Path, base: str = "origin/master") -> tuple[int, str]:
    """Return the next sequence number and the previous task's commit (or empty).

    Only fetched shared refs count, never local experiments. A single serial
    Jules session publishes each PR before picking again. Branch corrections
    and copied/squashed commits do not advance the same sequence twice.
    """
    result = subprocess.run(
        ["git", "-C", str(root), "log", base, "--glob=refs/remotes/origin/jules/*",
         "--format=%H%x1f%B%x00", "--extended-regexp", "--grep=^Jules-Sequence:"],
        capture_output=True, text=True, encoding="utf-8", errors="replace", check=True,
    )
    latest, previous = 0, ""
    for entry in result.stdout.split("\0"):
        if "\x1f" not in entry:
            continue
        commit, message = entry.strip().split("\x1f", 1)
        for match in TRAILER.finditer(message):
            number = int(match[1])
            expected = "ordinary" if number % 2 else "efficiency"
            if match[2] != expected:
                raise ValueError(f"invalid Jules-Sequence on {commit}: {match[0]}")
            if number > latest:
                latest, previous = number, commit
    return latest + 1, previous


def report_path(number: int) -> str:
    return f"docs/jules-efficiency/e-{number}.md"


def scope_path(wanted: str) -> str | None:
    """Only positive even E-ids name efficiency reports, with no wildcard scope."""
    match = re.fullmatch(r"E-([1-9][0-9]*)", wanted)
    if match and int(match[1]) % 2 == 0:
        return report_path(int(match[1]))
    return None


def task_block(number: int, previous: str) -> list[str]:
    focus = FOCUSES[(number // 2 - 1) % len(FOCUSES)]
    return [
        f"next  E-{number} -- Token efficiency: {focus}",
        f"      branch: jules/e-{number}-<topic>   pull request title: E-{number}: <outcome>",
        f"      Files: {report_path(number)} (the only file you add or change)",
        f"      Focus: {focus}",
        f"      Previous task commit: {previous}",
        f'      method: python tools/heading.py {METHOD} "Running an efficiency task"',
        "      Quality: preserve behaviour, contracts, checks and decision evidence.",
    ]
