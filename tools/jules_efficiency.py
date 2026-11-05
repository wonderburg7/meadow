"""Number Jules's turns in commit trailers, and offer an efficiency turn only when a topic is due.

Used by python tools/jules_preflight.py --next, --scope E-<n> and --sequence.
Every published PR carries `Jules-Sequence: <n> <ordinary|efficiency>`;
numbers increase and are unique, and the kind word (not the number's
parity) says what the turn was. Read master and all fetched Jules branches
so an unmerged PR also advances the next session's number. Corrections keep
their number; integrators preserve it.

Until 5 Nov 2026 every even turn was an efficiency report and the six
topics recurred every 12 turns whether or not anything had changed: 9 of the
14 E reports in the 5 Nov review were closed as repeats (F7). An efficiency
turn is now offered only after an ordinary one, and only when a topic is
due by the rule the R-review rota uses (plans/reference/jules-reviews.md):
its previous report is processed, and at least EVERY_DAYS days and
MIN_COMMITS commits on its watched paths have passed since its last run.
"""

from __future__ import annotations

import datetime
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path

METHOD = "plans/reference/jules-efficiency.md"
REPORT_DIR = "docs/jules-efficiency"
FOCUSES = (
    "slice briefs and acceptance criteria",
    "code navigation and understanding ownership",
    "implementing game slices without rediscovering contracts",
    "verification, failure diagnosis and useful test output",
    "review, integration and recommendation handoffs",
    "development tools, documentation routing and repeated setup",
)
# Paths whose churn can make a topic's last report out of date, one tuple per FOCUSES entry.
WATCHES = (
    ("NEXTSTEPS.md", "plans/now", "plans/README.md"),
    ("FUNCTION_MAP.md", "GAME_MODEL.md", "tools/func.py", "tools/heading.py"),
    ("scripts", ".claude/rules", "docs/known-pitfalls.md"),
    ("tools/verify.ps1", "tools/prefinish.py", "tools/run_tests.py", "tests"),
    ("plans/reference/closeout.md", "plans/reference/reviews", "plans/reference/check-loop.md", "tools/slice.ps1"),
    ("tools", "CLAUDE.md", "AGENTS.md", "docs/agent-rules.md"),
)
EVERY_DAYS = 14   # a topic rests this long after its last report
MIN_COMMITS = 20  # and needs this many commits on its watched paths since
TRAILER = re.compile(r"^Jules-Sequence: ([1-9][0-9]*) (ordinary|efficiency)$", re.MULTILINE)
FOCUS_LINE = re.compile(r"^[-*\s]*Focus:\s*(.+?)\s*$", re.MULTILINE | re.IGNORECASE)
REPORT_NUMBER = re.compile(r"e-([1-9][0-9]*)\.md$")


def next_turn(root: Path, base: str = "origin/master") -> tuple[int, str, str]:
    """Return the next sequence number, the previous task's commit (or empty) and its kind (or empty).

    Only fetched shared refs count, never local experiments. Branch
    corrections and copied/squashed commits do not advance the same number
    twice. One number published with both kinds is a stop: two sessions
    disagreed about what that turn was.
    """
    result = subprocess.run(
        ["git", "-C", str(root), "log", base, "--glob=refs/remotes/origin/jules/*",
         "--format=%H%x1f%B%x00", "--extended-regexp", "--grep=^Jules-Sequence:"],
        capture_output=True, text=True, encoding="utf-8", errors="replace", check=True,
    )
    latest, previous, kind = 0, "", ""
    kinds: dict[int, tuple[str, str]] = {}
    for entry in result.stdout.split("\0"):
        if "\x1f" not in entry:
            continue
        commit, message = entry.strip().split("\x1f", 1)
        for match in TRAILER.finditer(message):
            number = int(match[1])
            seen = kinds.setdefault(number, (match[2], commit))
            if seen[0] != match[2]:
                raise ValueError(f"invalid Jules-Sequence on {commit}: {match[0]} (also '{seen[0]}' on {seen[1]})")
            if number > latest:
                latest, previous, kind = number, commit, match[2]
    return latest + 1, previous, kind


def legacy_focus(number: int) -> str | None:
    """The topic the old even-number rotation gave report E-<number>; None for odd numbers."""
    return FOCUSES[(number // 2 - 1) % len(FOCUSES)] if number > 0 and number % 2 == 0 else None


def report_focus(text: str, number: int) -> str | None:
    """A report's topic: its `Focus:` header line, else the old even-number rotation."""
    for found in FOCUS_LINE.finditer(text):
        wanted = found[1].lower()
        for focus in FOCUSES:
            if wanted.startswith(focus) or focus.startswith(wanted):
                return focus
    return legacy_focus(number)


def git(root: Path, *args: str) -> str:
    result = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True,
                            encoding="utf-8", errors="replace")
    return result.stdout if result.returncode == 0 else ""


@dataclass
class TopicRun:
    focus: str
    date: str    # yyyy-mm-dd the run counted (report landed, or closed in the ledger)
    source: str  # the report path or ledger branch
    commit: str = ""  # the commit that landed the report on base; empty for a ledger-only run


def topic_runs(root: Path, base: str, closed: list[tuple[int, str, str]]) -> list[TopicRun]:
    """Every finished efficiency run: each report on `base` (dated by the commit that last
    landed it) and each `closed` ledger row, given as (number, date, branch)."""
    runs: list[TopicRun] = []
    for path in git(root, "ls-tree", "-r", "--name-only", base, "--", REPORT_DIR).split():
        found = REPORT_NUMBER.search(path)
        if not found:
            continue
        focus = report_focus(git(root, "show", f"{base}:{path}"), int(found[1]))
        landed = git(root, "log", "-1", "--format=%H %cs", base, "--", path).split()
        if focus and len(landed) == 2:
            runs.append(TopicRun(focus, landed[1], path, landed[0]))
    for number, date, branch in closed:
        text = git(root, "show", f"origin/{branch}:{report_path(number)}")
        focus = report_focus(text, number)
        if focus:
            runs.append(TopicRun(focus, date, branch))
    return runs


def topic_states(
    root: Path,
    base: str,
    today: datetime.date,
    closed: list[tuple[int, str, str]],
    waiting: list[tuple[int, str]],
) -> list[tuple[str, str, str, str]]:
    """(focus, state, reason, last date or "") per topic: taken (a report waits to be processed),
    rests (inside EVERY_DAYS), quiet (fewer than MIN_COMMITS on its watched paths) or due.
    `waiting` is (number, ref) for each unprocessed efficiency branch."""
    runs = topic_runs(root, base, closed)
    pending: dict[str, str] = {}
    for number, ref in waiting:
        focus = report_focus(git(root, "show", f"{ref}:{report_path(number)}"), number)
        if focus:
            pending.setdefault(focus, ref.removeprefix("origin/"))
    states: list[tuple[str, str, str, str]] = []
    for focus, watches in zip(FOCUSES, WATCHES):
        if focus in pending:
            states.append((focus, "taken", f"report waiting on {pending[focus]} to be processed", ""))
            continue
        mine = [run for run in runs if run.focus == focus]
        if not mine:
            states.append((focus, "due", "first run: no report yet", ""))
            continue
        latest = max(mine, key=lambda run: (run.date, bool(run.commit)))
        last = latest.date
        due_on = datetime.date.fromisoformat(last) + datetime.timedelta(days=EVERY_DAYS)
        if today < due_on:
            states.append((focus, "rests", f"last run {last}; due again {due_on.isoformat()}", last))
            continue
        since = [f"{latest.commit}..{base}"] if latest.commit else [f"--since={last}T00:00:00", base]
        count = git(root, "rev-list", "--count", *since, "--", *watches).strip()
        commits = int(count) if count.isdigit() else 0
        if commits < MIN_COMMITS:
            states.append((focus, "quiet", f"{commits} commits on its watched paths since {last}; "
                                           f"it needs {MIN_COMMITS}", last))
            continue
        states.append((focus, "due", f"{commits} commits on its watched paths since {last}", last))
    return states


def next_topic(states: list[tuple[str, str, str, str]]) -> tuple[str | None, str, list[str]]:
    """The due topic whose last run is oldest (never run first, then FOCUSES order), its reason,
    and a line on every topic passed over."""
    due = [(last, index, focus, reason) for index, (focus, state, reason, last) in enumerate(states)
           if state == "due"]
    skipped = [f"{focus}: {state} -- {reason}" for focus, state, reason, _ in states if state != "due"]
    if not due:
        return None, "", skipped
    _, _, focus, reason = min(due)
    return focus, reason, skipped


def report_path(number: int) -> str:
    return f"docs/jules-efficiency/e-{number}.md"


def scope_path(wanted: str) -> str | None:
    """A positive E-id names its one efficiency report, with no wildcard scope. Any number:
    since 5 Nov 2026 the trailer's kind word, not parity, marks an efficiency turn."""
    match = re.fullmatch(r"E-([1-9][0-9]*)", wanted)
    return report_path(int(match[1])) if match else None


def task_block(number: int, previous: str, focus: str, reason: str = "") -> list[str]:
    return [
        f"next  E-{number} -- Token efficiency: {focus}",
        f"      branch: jules/e-{number}-<topic>   pull request title: E-{number}: <outcome>",
        f"      Files: {report_path(number)} (the only file you add or change)",
        f"      Focus: {focus}" + (f"  (due: {reason})" if reason else ""),
        f"      Previous task commit: {previous}",
        f'      method: python tools/heading.py {METHOD} "Running an efficiency task"',
        "      Quality: preserve behaviour, contracts, checks and decision evidence.",
    ]
