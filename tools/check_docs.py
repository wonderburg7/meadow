"""Cheap checks for Meadow's current planning/documentation entry points."""

from __future__ import annotations

from datetime import date
from pathlib import Path
import re
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))

import backlog  # noqa: E402


ROOT = Path(__file__).resolve().parent.parent
PLAN_PATTERN = re.compile(r"^Status:\s*(.+)$", re.MULTILINE)
REQUIRED_STATUS_FIELDS = ("owner:", "next:", "dependency:", "verified:")
TERMINAL_STATES = ("complete", "completed", "archived", "abandoned", "retired")
TERMINAL_NEXT = re.compile(r"\|\s*next:\s*none\b")
MD_LINK_PATTERN = re.compile(r"(?<!!)\[[^]]*\]\(([^)]+)\)")


def current_plans(root: Path | None = None) -> list[Path]:
    """Return the small, routable plan layers; history is intentionally excluded."""
    root = root or ROOT
    layers = ("now", "active", "design", "reference")
    return sorted(
        path
        for layer in layers
        for path in (root / "plans" / layer).glob("*.md")
    )


def plan_is_terminal(text: str) -> bool:
    """The terminal-plan rule: a Status line in the first 8 lines whose state
    (the field before the first `|`) names a finished state, or whose Next
    field is `None` (closeout's "Next: None -- plan complete"). Other fields
    are free text: a Next slice title that says "completed" is not terminal.
    tools/archive_slice.py --complete-plans archives exactly the plans this
    says belong in plans/archive/."""
    match = PLAN_PATTERN.search("\n".join(text.splitlines()[:8]))
    if not match:
        return False
    status = match.group(1).lower()
    state = status.split("|", 1)[0]
    return any(word in state for word in TERMINAL_STATES) or bool(TERMINAL_NEXT.search(status))


def terminal_plan_awaits_closeout(plan: Path) -> bool:
    """A finishing worktree retains its last plan until its ledger row is removed."""
    checkout = primary_checkout()
    if ROOT == checkout:
        return False
    ledger = checkout / "plans" / "workstreams.md"
    if not ledger.exists():
        return False
    reference = f"`{plan.relative_to(ROOT).as_posix()}`"
    return any(
        line.startswith("|") and reference in line
        for line in ledger.read_text(encoding="utf-8").splitlines()
    )


def check_plan_metadata(errors: list[str], warnings: list[str]) -> None:
    for plan in current_plans():
        text = plan.read_text(encoding="utf-8")
        first_lines = "\n".join(text.splitlines()[:8])
        match = PLAN_PATTERN.search(first_lines)
        if not match:
            errors.append(f"{plan.relative_to(ROOT)}: active plan has no Status line in its first 8 lines")
            continue

        metadata = first_lines.lower()
        if plan_is_terminal(text) and not terminal_plan_awaits_closeout(plan):
            errors.append(f"{plan.relative_to(ROOT)}: terminal plan belongs in plans/archive, not a live layer")

        missing = [field[:-1].title() for field in REQUIRED_STATUS_FIELDS if field not in metadata]
        if missing:
            errors.append(f"{plan.relative_to(ROOT)}: Status line is missing {', '.join(missing)}")

        verified = re.search(r"verified:\s*(\d{4}-\d{2}-\d{2})", metadata)
        if not verified:
            continue
        try:
            verified_on = date.fromisoformat(verified.group(1))
        except ValueError:
            errors.append(f"{plan.relative_to(ROOT)}: Verified must use YYYY-MM-DD")
            continue
        age = (date.today() - verified_on).days
        if age > 28:
            warnings.append(f"{plan.relative_to(ROOT)}: verification date is {age} days old")
        elif age < 0:
            warnings.append(f"{plan.relative_to(ROOT)}: verification date is in the future")


SHIPPED_HEADING = re.compile(
    r"^#{2,4} .*\b(DONE|shipped|delivered|landed|superseded)\b",
    re.MULTILINE | re.IGNORECASE,
)
LIVE_PLAN_SOFT_LIMIT = 260


def check_live_plans_hold_only_open_work(errors: list[str], warnings: list[str]) -> None:
    """A live plan holds open slices; a shipped one is history and belongs in plans/archive/.

    X3 is the case this exists for. UI-P-2 shipped on 31 Aug 2026 inside a
    batch commit, `plans/now/ui.md` kept its full pre-fix diagnosis, and three
    days later it was queued as ready work with a worktree opened for it. A
    shipped slice left in a live plan does not just cost context -- it reads
    as startable. Size is the same failure earlier: a plan that has grown past
    the soft limit is nearly always carrying delivered slices."""
    for plan in current_plans():
        if plan.parent.name != "now":
            continue
        text = plan.read_text(encoding="utf-8")
        for match in SHIPPED_HEADING.finditer(text):
            line_no = text[: match.start()].count(chr(10)) + 1
            heading = match.group(0).strip()
            errors.append(
                f"{plan.relative_to(ROOT)}:{line_no}: heading marks delivered work "
                f"-- move it to plans/archive/ and leave a one-line pointer: {heading}"
            )
        line_count = len(text.splitlines())
        if line_count > LIVE_PLAN_SOFT_LIMIT:
            warnings.append(
                f"{plan.relative_to(ROOT)}: {line_count} lines (soft limit "
                f"{LIVE_PLAN_SOFT_LIMIT}) -- check it is not holding delivered slices"
            )


def check_context_layout(errors: list[str]) -> None:
    legacy_root_plans = sorted(ROOT.glob("*_PLAN.md"))
    if legacy_root_plans:
        names = ", ".join(path.name for path in legacy_root_plans)
        errors.append(f"root planning files must move under plans/: {names}")
    if (ROOT / "CHATGPT_NEXTSTEPS.md").exists():
        errors.append("CHATGPT_NEXTSTEPS.md is retired; use the shared NEXTSTEPS.md and plans/")


# Normally LANE_SIZE_MAX in each lane (five slices keep a lane stocked). The
# floor is what the queue is allowed to drop to when a slice ships with no
# genuinely startable successor -- refilling with a not-yet-ready item would
# violate the admission test.
#
# The floor drifted 5 -> 4 -> 3 -> 2 across 3-4 Sep 2026, once per slice that
# landed with nothing ready behind it. Dave answered D-2 on 8 Sep 2026:
# **the floor is 3, and it does not move again.** A slice shipping with no
# successor is now treated as the defect it is, and caught at the other end
# instead -- see check_queue_successors below, which requires every queue
# item to name the slice that follows it or to state that its plan is
# finished. Together those two rules are what makes the queue refill itself:
# promoting an item's named successor is a lookup, not an investigation.
QUEUE_SIZE_MIN = 3
# Each lane holds up to five items under its own "### <Lane> lane" heading
# (Dave, 17 Sep 2026: two lanes, five next steps each). The floor above still
# counts the whole queue.
LANE_SIZE_MAX = 5
LANES = ("Claude", "Codex")
NEXT_UP_SECTION = re.compile(r"^## Next up\s*$([\s\S]*?)(?=^## |\Z)", re.MULTILINE)
LANE_HEADING = re.compile(r"^###\s+(\w+)\s+lane\s*$", re.MULTILINE)
QUEUE_ITEM_HEAD = re.compile(r"^\*\*\[(\w+)\]\s+(.+?)\s+--")


def queue_item_chunks(text: str) -> list[tuple[str | None, str]] | None:
    """Every '## Next up' item as (lane heading it sits under, item text).

    Items are split per '### <Lane> lane' subsection first, so the next
    subsection's heading and preamble never run on into the last item's
    `Next after:` line. None when the section is missing."""
    match = NEXT_UP_SECTION.search(text)
    if not match:
        return None
    chunks: list[tuple[str | None, str]] = []
    for part in re.split(r"^(?=### )", match.group(1), flags=re.MULTILINE):
        heading = LANE_HEADING.match(part)
        lane = heading.group(1) if heading else None
        for chunk in re.split(r"^\d+\.\s+", part, flags=re.MULTILINE)[1:]:
            chunks.append((lane, chunk))
    return chunks
REQUIRED_ITEM_FIELDS = ("Plan:", "Files:", "Check:", "Proof:", "Next after:")
PROOF_LABEL = re.compile(r"^\s*-\s*Proof:\s*(.*?)\s*$", re.MULTILINE)
PROOF_LINE = re.compile(r"^\s*-\s*Proof:\s*`([^`]*)`\s*$", re.MULTILINE)
FILES_BLOCK = re.compile(
    r"^\s*-\s*Files:\s*([\s\S]*?)(?=^\s*-\s[A-Z]|\Z)", re.MULTILINE
)
NOT_READY_PHRASES = (
    "blocked on",
    "needs dave",
    "needs a live",
    "needs its own live",
    "awaiting dave",
    "hands-on confirmation first",
    "before any code is written",
)
PATH_TOKEN = re.compile(r"`([^`]+)`")


def _item_files(body: str) -> set[str]:
    """Paths named on an item's Files: line, so two lanes can be proved disjoint."""
    match = FILES_BLOCK.search(body)
    if not match:
        return set()
    return {
        token.strip()
        for token in PATH_TOKEN.findall(match.group(1))
        if token.strip()
    }


def _active_slice_ids() -> set[str]:
    return {
        raw_path.replace("\\", "/").rstrip("/").rsplit("/", 1)[-1]
        for raw_path, _ in ledger_worktree_rows()
    }


def _is_repository_relative_file(raw: str) -> bool:
    path = Path(raw)
    return (
        bool(raw)
        and not path.is_absolute()
        and not re.match(r"^[A-Za-z]:", raw)
        and "://" not in raw
        and ".." not in path.parts
        and bool(path.suffix)
    )


def validate_queue_files(body: str, index: int, errors: list[str]) -> None:
    """Reject prose placeholders while allowing exact paths for files created by a slice."""
    match = FILES_BLOCK.search(body)
    if not match:
        return  # check_next_steps reports the missing field

    raw = match.group(1).strip()
    tokens = [token.strip() for token in PATH_TOKEN.findall(raw)]
    residue = PATH_TOKEN.sub("", raw)
    residue = re.sub(r"[\s,]", "", residue)
    invalid = [
        token
        for token in tokens
        if not _is_repository_relative_file(token)
    ]
    if not tokens or residue or invalid:
        errors.append(
            f"NEXTSTEPS.md item {index}: Files: must contain only backticked "
            "repository-relative paths separated by commas; placeholder prose is not allowed"
        )


def validate_queue_proof(body: str, index: int, root: Path, errors: list[str]) -> None:
    """Validate one queue proof's exact shape and truth against root."""
    label_match = PROOF_LABEL.search(body)
    proof_match = PROOF_LINE.search(body)
    if not proof_match:
        detail = "missing" if not label_match else "must be backticked"
        errors.append(
            f"NEXTSTEPS.md item {index}: Proof: {detail}; use "
            "`present|absent: <path> :: <substring>`"
        )
        return

    raw = proof_match.group(1).strip()
    mode, sep, rest = raw.partition(":")
    mode = mode.strip()
    if not sep or mode not in ("present", "absent"):
        errors.append(
            f"NEXTSTEPS.md item {index}: Proof: must start with 'present:' or 'absent:', got `{raw}`"
        )
        return

    rel_path, sep, needle = rest.partition("::")
    rel_path = rel_path.strip()
    needle = needle.strip()
    if not sep or not needle or not _is_repository_relative_file(rel_path):
        errors.append(
            f"NEXTSTEPS.md item {index}: Proof: must be `{mode}: <path> :: <substring>`, got `{raw}`"
        )
        return

    target = root / rel_path
    if not target.is_file():
        errors.append(f"NEXTSTEPS.md item {index}: Proof: names a file that does not exist: {rel_path}")
        return

    content = target.read_text(encoding="utf-8")
    found = needle in content
    holds = found if mode == "present" else not found
    if not holds:
        errors.append(
            f"NEXTSTEPS.md item {index}: proof no longer holds -- this may already be built. "
            f"Open {rel_path} before requeuing it."
        )


def check_queue_files(errors: list[str], text: str | None = None) -> None:
    """Every unclaimed item must expose the exact file set used by overlap checks."""
    if text is None:
        text = (ROOT / "NEXTSTEPS.md").read_text(encoding="utf-8")
    items = queue_item_chunks(text)
    if items is None:
        return
    active_slice_ids = _active_slice_ids()
    for index, (_, chunk) in enumerate(items, start=1):
        item_match = re.match(r"\*\*\[\w+\]\s+([\w.-]+)\s+--", chunk)
        if item_match and item_match.group(1) in active_slice_ids:
            continue
        validate_queue_files(chunk, index, errors)


def check_next_steps(errors: list[str], warnings: list[str], text: str | None = None) -> None:
    """The queue holds at least QUEUE_SIZE_MIN ready slices, at most
    LANE_SIZE_MAX per lane, in two lanes that share no file.

    `text` lets tools/refill_lane.py check a candidate queue before writing
    it; the other queue checks take it for the same reason."""
    if text is None:
        text = (ROOT / "NEXTSTEPS.md").read_text(encoding="utf-8")
    items = queue_item_chunks(text)
    if items is None:
        errors.append("NEXTSTEPS.md: missing a '## Next up' section")
        return
    section = NEXT_UP_SECTION.search(text).group(1)

    if len(items) < QUEUE_SIZE_MIN:
        errors.append(
            f"NEXTSTEPS.md: expected at least {QUEUE_SIZE_MIN} next-step items, found {len(items)}"
        )

    lane_order: list[tuple[str, str]] = []
    for index, (heading_lane, chunk) in enumerate(items, start=1):
        lane_match = re.match(r"\*\*\[(\w+)\]", chunk)
        if not lane_match or lane_match.group(1) not in LANES:
            errors.append(
                f"NEXTSTEPS.md item {index}: must open with a lane tag, one of "
                + ", ".join(f"**[{lane}]" for lane in LANES)
            )
            continue
        item_head = QUEUE_ITEM_HEAD.match(chunk)
        if item_head and any(character.isspace() for character in item_head.group(2)):
            errors.append(
                f"NEXTSTEPS.md item {index}: id contains whitespace: {item_head.group(2)!r}"
            )
        if heading_lane is not None and heading_lane != lane_match.group(1):
            errors.append(
                f"NEXTSTEPS.md item {index}: tagged [{lane_match.group(1)}] but listed "
                f"under '### {heading_lane} lane'"
            )
        lane_order.append((lane_match.group(1), chunk))

        # Proof has a stricter dedicated validator below, including the wholly
        # missing case, so do not emit a second generic error for it here.
        missing = [
            field
            for field in REQUIRED_ITEM_FIELDS
            if field != "Proof:" and f"- {field}" not in chunk
        ]
        if missing:
            errors.append(
                f"NEXTSTEPS.md item {index}: missing {', '.join(field.rstrip(':') for field in missing)}"
            )

    lanes_present = {lane for lane, _ in lane_order}
    for lane in LANES:
        lane_size = sum(1 for item_lane, _ in lane_order if item_lane == lane)
        if lane_size > LANE_SIZE_MAX:
            errors.append(
                f"NEXTSTEPS.md: the {lane} lane holds {lane_size} items; at most {LANE_SIZE_MAX}"
            )
        if lane not in lanes_present:
            errors.append(f"NEXTSTEPS.md: no [{lane}] item -- both lanes must have work to run in parallel")

    # Only ready work belongs here; anything waiting on Dave lives under "Not in the queue".
    lowered = section.lower()
    for phrase in NOT_READY_PHRASES:
        if phrase in lowered:
            errors.append(
                f"NEXTSTEPS.md: '{phrase}' appears in the queue -- work waiting on Dave "
                "belongs under '## Not in the queue, and why', not '## Next up'"
            )

    # The two lanes run at the same time, so their leading items must not share a file.
    heads = {}
    for lane, chunk in lane_order:
        heads.setdefault(lane, _item_files(chunk))
    if len(heads) == len(LANES):
        first, second = (heads[lane] for lane in LANES)
        shared = first & second
        if shared:
            errors.append(
                "NEXTSTEPS.md: the leading items in each lane share "
                + ", ".join(sorted(shared))
                + " -- reorder the lanes so simultaneous work cannot collide"
            )

    # A non-leading item becomes a leading one as soon as its lane empties, so
    # cross-lane overlap further down the queue is a collision waiting for a
    # merge -- an error since 17 Sep 2026, when the lanes became two
    # independent five-item queues. Same-lane overlap is fine: a lane is
    # worked top to bottom.
    for lane_a, chunk_a in lane_order:
        for lane_b, chunk_b in lane_order:
            if lane_a >= lane_b:
                continue
            overlap = _item_files(chunk_a) & _item_files(chunk_b)
            if overlap:
                errors.append(
                    f"NEXTSTEPS.md: a [{lane_a}] and a [{lane_b}] item both name "
                    + ", ".join(sorted(overlap))
                    + " -- they will collide once both lanes reach them; put them "
                    "in one lane, or make the shared file its own earlier slice"
                )


# A "Next after:" line only refills the queue automatically if it names
# something. "none named -- pull the next ready slice from an owning plan"
# is not a successor: it is an investigation deferred to whoever empties the
# lane, and it is what let the floor drift 5 -> 2 over two days. Dave, D-2,
# 8 Sep 2026: every slice names its successor, or states that its plan is
# finished. Those are the only two endings.
NO_SUCCESSOR = re.compile(r"^\s*-\s*Next after:\s*(.+?)\s*$", re.MULTILINE)
PLAN_COMPLETE = re.compile("none.*(complete|finished|last slice)", re.IGNORECASE)
# The text before the first " -- " is what tools/slice.ps1's Get-SuccessorId
# looks up as the successor, so it must be a slice id (PERF-3, BS-D, G3,
# UI-X-2). PERF-3's "close candidate A in ..." (29 Sep 2026) was an action,
# and it stopped finish at the refill gate.
SUCCESSOR_ID = re.compile(r"[A-Z][A-Za-z0-9]*(?:-[A-Za-z0-9]+)*")


def check_queue_successors(errors: list[str], text: str | None = None) -> None:
    """Every queue item names the slice that follows it, or says its plan is done."""
    if text is None:
        text = (ROOT / "NEXTSTEPS.md").read_text(encoding="utf-8")
    items = queue_item_chunks(text)
    if items is None:
        return
    for index, (_, chunk) in enumerate(items, start=1):
        line = NO_SUCCESSOR.search(chunk)
        if not line:
            continue   # check_next_steps already reports the missing field
        value = line.group(1)
        if not value.lower().startswith("none"):
            lead = value.split("--", 1)[0].strip()
            if not SUCCESSOR_ID.fullmatch(lead):
                errors.append(
                    f"NEXTSTEPS.md item {index}: 'Next after: {value}' does not lead with a slice id. "
                    "Write '<id> -- <title>' for the slice that follows it, or "
                    "'none -- <plan> is complete' and put any follow-up action after that"
                )
            continue
        if PLAN_COMPLETE.search(value):
            continue
        errors.append(
            f"NEXTSTEPS.md item {index}: 'Next after: {value}' names no successor. "
            "Name the slice that follows it, or write "
            "'none -- <plan> is complete' if its owning plan has no further work "
            "(Dave, D-2, 8 Sep 2026)"
        )


def check_queue_lookahead(warnings: list[str], text: str | None = None,
                          root: Path | None = None, entries: list | None = None) -> None:
    """Warn when closing a lane's first item would strand the next slice (L-24).

    Reuses the function behind `refill_lane.py --top-up --dry-run --json`
    (L-18's `dry_after_report`): when deleting the lane's first item would
    empty the lane or take the queue under QUEUE_SIZE_MIN and the top-up adds
    nothing, `finish` would stop at the refill gate. Say so while the slice
    can still be specified before it is built. A warning, never an error."""
    try:
        import refill_lane  # imported here: refill_lane imports this module
    except ModuleNotFoundError:
        return   # a partial tools/ copy: the lookahead is advice, so skip it

    root = root or ROOT
    if text is None:
        text = (root / "NEXTSTEPS.md").read_text(encoding="utf-8")
    if entries is None:
        entries = refill_lane.load_backlog(root)
    queued = refill_lane.queued_ids(text)
    for lane in LANES:
        first = next((slice_id for item_lane, slice_id in queued if item_lane == lane), None)
        if first is None:
            continue
        report = refill_lane.dry_after_report(text, lane, first, root, entries)
        if report["dry_after"]:
            advice = refill_lane.dry_lane_advice(
                report, {slice_id for _, slice_id in queued})
            warnings.append(
                f"lookahead: closing {first} would leave the {lane} lane short with "
                "nothing admissible behind it; specify the owning plan's next slice"
                + ("; " + "; ".join(advice) if advice else "")
            )


def check_queue_items_state_a_level(warnings: list[str]) -> None:
    """Every queued item's plan states the reasoning level for that slice.

    `tools/slice.ps1`'s Get-SliceLevel reads a `Level:` line inside the
    slice's own section, else its row in the plan's "Open slices at a glance"
    table, and reports "unstated" when it finds neither -- which turns the
    model and connector advice in `start`/`doctor` into a guess. A warning,
    not an error: an item can be queued before its plan has been rewritten,
    but nobody should have to discover it at `start`.
    """
    path = ROOT / "NEXTSTEPS.md"
    text = path.read_text(encoding="utf-8")
    items = queue_item_chunks(text)
    if items is None:
        return
    for index, (_, chunk) in enumerate(items, start=1):
        plan_match = re.search(r"- Plan: `([^`]+)` -- \"([^\"]+)\"", chunk)
        item_match = re.match(r"\*\*\[\w+\]\s+([\w.-]+)\s+--", chunk)
        if not plan_match or not item_match:
            continue
        plan_path = ROOT / plan_match.group(1)
        if not plan_path.is_file():
            continue   # check_queue_files reports a missing plan
        plan_text = plan_path.read_text(encoding="utf-8")
        heading, slice_id = plan_match.group(2), item_match.group(1)
        section = ""
        heading_match = re.search(
            r"(?m)^(#{1,6})\s+.*%s.*$" % re.escape(heading), plan_text
        )
        if heading_match:
            depth = len(heading_match.group(1))
            rest = plan_text[heading_match.end():]
            end = re.search(r"(?m)^#{1,%d}\s" % depth, rest)
            section = rest[: end.start()] if end else rest
        if re.search(r"(?i)Level:(?:\*\*)?\s*(low|medium|high)\b", section):
            continue
        row = r"(?im)^\|\s*%s\s*\|.*\|\s*(low|medium|high)\s*\|\s*$" % re.escape(slice_id)
        if re.search(row, plan_text):
            continue
        warnings.append(
            f"NEXTSTEPS.md item {index} ({slice_id}): its plan states no reasoning level, "
            "so tools/slice.ps1 can only guess which model to advise. Add a "
            "'Level: low|medium|high' line to the slice's section, or a level "
            "column to its row in the plan's open-slices table"
        )


def check_queue_ids_are_unused(warnings: list[str]) -> None:
    """A queued id that already has an archive record is an id reused.

    `plans/now/ui-w.md`'s UI-W-1 to UI-W-4 reuse the ids of four different
    slices that shipped from `plans/now/ui-windows.md` on 8 Sep 2026. Two
    things then go wrong: grepping the archive for the id finds the wrong
    slice, and `tools/slice.ps1 finish`'s archive gate sees a
    `plans/archive/<id>_*.md` that was written for something else. The gate
    now also requires that file to name the slice's own heading, and this
    warning is the earlier notice. Found by the 17 Sep 2026 plan review.
    """
    path = ROOT / "NEXTSTEPS.md"
    text = path.read_text(encoding="utf-8")
    items = queue_item_chunks(text)
    if items is None:
        return
    for index, (_, chunk) in enumerate(items, start=1):
        item_match = re.match(r"\*\*\[\w+\]\s+([\w.-]+)\s+--", chunk)
        if not item_match:
            continue
        slice_id = item_match.group(1)
        existing = sorted((ROOT / "plans" / "archive").glob(f"{slice_id}_*.md"))
        if not existing:
            continue
        plan_match = re.search(r"- Plan: `([^`]+)`", chunk)
        if plan_match:
            plan_path = ROOT / plan_match.group(1)
            # An owning plan that says the id is reused, and why, has already
            # answered this; the closeout gate still requires the archive
            # record to be one the slice's own branch wrote.
            if plan_path.is_file() and "reuses the id" in plan_path.read_text(encoding="utf-8"):
                continue
        names = ", ".join(f.name for f in existing)
        warnings.append(
            f"NEXTSTEPS.md item {index} ({slice_id}): that id already has an archive "
            f"record ({names}). Reusing a slice id makes both the archive and "
            "tools/slice.ps1's archive gate ambiguous -- give the open slice a "
            "fresh id, or say in its plan why the id is being reused"
        )


def check_queue_section_agreement(errors: list[str], text: str | None = None) -> None:
    """An id cannot be both ready ('## Next up') and waiting ('## Not in the
    queue, and why') at once -- that is what let UI-U-1 sit in both places
    with nothing to catch it."""
    if text is None:
        text = (ROOT / "NEXTSTEPS.md").read_text(encoding="utf-8")
    items = queue_item_chunks(text)
    not_queued_match = re.search(
        r"^## Not in the queue, and why\s*$([\s\S]*?)(?=^## |\Z)", text, re.MULTILINE
    )
    if items is None or not not_queued_match:
        return

    next_ids = []
    for _, chunk in items:
        item_match = re.match(r"\*\*\[\w+\]\s+([\w.-]+)\s+--", chunk)
        if item_match:
            next_ids.append(item_match.group(1))

    # Only the bolded lead of each bullet counts -- the prose that follows it
    # legitimately mentions other ids as the reason this one is waiting.
    for bullet_match in re.finditer(
        r"^-\s+\*\*(.+?)\*\*", not_queued_match.group(1), re.MULTILINE
    ):
        bold_lead = bullet_match.group(1)
        for next_id in next_ids:
            if re.search(rf"\b{re.escape(next_id)}\b", bold_lead):
                errors.append(
                    f"NEXTSTEPS.md: '{next_id}' is listed as ready in '## Next up' and also "
                    "named in '## Not in the queue, and why' -- it cannot be both"
                )


# A "Not in the queue" bullet that blames a full lane is only true while that
# lane holds LANE_SIZE_MAX items. On 18 Sep 2026 two such bullets (L-10/L-11
# and WD-1..4) sat under a Claude lane holding three items: two slots idle on
# a sentence that had been true when it was written and nothing to notice.
LANE_FULL_REASON = re.compile(r"(lane is full|full at five|free slot)", re.IGNORECASE)
LANE_NAMED = re.compile(r"\b(Claude|Codex) lane\b")


def check_not_in_queue_reasons(errors: list[str], text: str | None = None) -> None:
    """A waiting item that blames a full lane is wrong the moment that lane
    has a free slot; say which lane, and be right about it."""
    if text is None:
        text = (ROOT / "NEXTSTEPS.md").read_text(encoding="utf-8")
    items = queue_item_chunks(text)
    not_queued_match = re.search(
        r"^## Not in the queue, and why\s*$([\s\S]*?)(?=^## |\Z)", text, re.MULTILINE
    )
    if items is None or not not_queued_match:
        return
    lane_sizes = {lane: 0 for lane in LANES}
    for _, chunk in items:
        lane_match = re.match(r"\*\*\[(\w+)\]", chunk)
        if lane_match and lane_match.group(1) in lane_sizes:
            lane_sizes[lane_match.group(1)] += 1
    for bullet in re.findall(r"^-\s+.*$", not_queued_match.group(1), re.MULTILINE):
        if not LANE_FULL_REASON.search(bullet):
            continue
        lead = re.match(r"^-\s+\*\*(.+?)\*\*", bullet)
        name = lead.group(1) if lead else bullet[:40]
        lane_match = LANE_NAMED.search(bullet)
        if not lane_match:
            errors.append(
                f"NEXTSTEPS.md: '{name}' waits for a lane slot but names no lane -- "
                "write 'the Claude lane' or 'the Codex lane' so the claim can be checked"
            )
            continue
        lane = lane_match.group(1)
        if lane_sizes[lane] < LANE_SIZE_MAX:
            errors.append(
                f"NEXTSTEPS.md: '{name}' waits for a free slot in the {lane} lane, "
                f"but that lane holds {lane_sizes[lane]} of {LANE_SIZE_MAX} -- run python "
                f"tools/refill_lane.py --top-up --lane {lane} (it queues the item and clears "
                "a bullet whose only reason is the full lane), or state the real reason it waits"
            )


def check_stale_deferrals(warnings: list[str], text: str | None = None,
                          root: Path | None = None) -> None:
    """Warn when a deferred item's stated gate has already shipped.

    The bold lead identifies the deferred item, so only its following reason is
    inspected.  A reason may deliberately record that a gate landed; that is a
    historical note rather than a stale restriction.
    """
    if text is None:
        text = (ROOT / "NEXTSTEPS.md").read_text(encoding="utf-8")
    root = root or ROOT
    not_queued_match = re.search(
        r"^## Not in the queue, and why\s*$([\s\S]*?)(?=^## |\Z)", text, re.MULTILINE
    )
    if not not_queued_match:
        return

    slice_id = re.compile(r"\b[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*-\d+[a-z]?\b")
    for bullet in re.findall(r"^-\s+.*$", not_queued_match.group(1), re.MULTILINE):
        lead = re.match(r"^-\s+\*\*(.+?)\*\*", bullet)
        name = lead.group(1) if lead else bullet[:40]
        reason = bullet[lead.end():] if lead else bullet
        for match in slice_id.finditer(reason):
            gate = match.group(0)
            clause = re.split(r"[.;]", reason[match.end():], maxsplit=1)[0]
            if re.search(r"\b(?:landed|shipped)\b", clause, re.IGNORECASE):
                continue
            archives = sorted((root / "plans" / "archive").glob(f"{gate}_*.md"))
            for archive in archives:
                warnings.append(
                    f"NEXTSTEPS.md: '{name}' waits for a shipped slice {gate} "
                    f"({archive.relative_to(root).as_posix()}) -- update the deferral; "
                    "see plans/README.md rule 9"
                )


def check_released_blocked_checks(warnings: list[str], text: str | None = None,
                                   root: Path | None = None) -> None:
    """Warn when every slice a blocked check names has already shipped.

    Only the `Blocked by:` line's lead, up to the first ` -- `, is inspected
    for slice ids; prose there besides the ids (a dependency not yet named by
    id, or a clause qualifying one) means the check still waits on something
    this cannot verify, so it is left alone.
    """
    if text is None:
        blocked_path = ROOT / "checks" / "blocked.md"
        if not blocked_path.is_file():
            return
        text = blocked_path.read_text(encoding="utf-8")
    root = root or ROOT

    slice_id = re.compile(r"\b[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*-\d+[a-z]?\b")
    archive_dir = root / "plans" / "archive"

    for entry in re.finditer(r"^### (C-\d+)\b.*$", text, re.MULTILINE):
        check_id = entry.group(1)
        section_start = entry.end()
        next_entry = re.search(r"^### C-\d+\b", text[section_start:], re.MULTILINE)
        section_end = section_start + next_entry.start() if next_entry else len(text)
        section = text[section_start:section_end]

        blocked_match = re.search(r"^Blocked by:\s*(.*)$", section, re.MULTILINE)
        if not blocked_match:
            continue
        lead = blocked_match.group(1).split(" -- ", 1)[0]

        ids = slice_id.findall(lead)
        if not ids:
            continue
        if not all(list(archive_dir.glob(f"{sid}_*.md")) for sid in ids):
            continue

        remainder = slice_id.sub("", re.sub(r"`[^`]*`", "", lead))
        remainder = re.sub(r"[(),.]", "", remainder)
        remainder = re.sub(r"\band\b", "", remainder)
        if remainder.strip():
            continue

        warnings.append(
            f"checks/blocked.md: {check_id} waits only for shipped slices "
            f"{', '.join(ids)} -- move it to checks/ready/ (the check "
            "processor's first step)"
        )


def check_queue_proofs(errors: list[str], text: str | None = None) -> None:
    """Each queue item's Proof: line must still hold against the code it names.

    X3 sat at the head of a lane, with a worktree open, for a fix that had
    shipped three days earlier -- this is what would have caught it. An
    in-progress slice is the exception: its proof is expected to flip while
    its registered worktree is being verified for merge."""
    if text is None:
        text = (ROOT / "NEXTSTEPS.md").read_text(encoding="utf-8")
    items = queue_item_chunks(text)
    if items is None:
        return
    active_slice_ids = _active_slice_ids()

    for index, (_, chunk) in enumerate(items, start=1):
        item_match = re.match(r"\*\*\[\w+\]\s+([\w.-]+)\s+--", chunk)
        if item_match and item_match.group(1) in active_slice_ids:
            continue
        validate_queue_proof(chunk, index, ROOT, errors)


# --- the backlog NEXTSTEPS.md refills itself from ---------------------------
#
# A live plan's open slice section may carry a fenced ```queue block holding
# the exact item that slice would be queued as (tools/backlog.py). Two things
# then have to stay true: the block and any live queue entry for that id must
# say the same thing, and a lane short of five while an admissible block waits
# is a lane nobody topped up. The second is a warning, because five is a
# ceiling the backlog reaches when it has startable work, never a reason to
# queue something that is not (Dave, 21 Sep 2026).


def plan_queue_blocks() -> list:
    """Every parseable queue block in the live plans; malformed ones are the
    business of check_plan_queue_blocks, which reports them as errors."""
    entries, _ = backlog.collect(current_plans(), ROOT)
    return entries


def _block_shape(body: str) -> str:
    """A queue item or a block body reduced to what the two must share."""
    lines = [line[len(backlog.QUEUE_INDENT):]
             if line.startswith(backlog.QUEUE_INDENT) else line
             for line in body.replace("\r", "").split("\n")]
    return "\n".join(line.rstrip() for line in lines).strip("\n")


def refill_ready_ids(text: str, root: Path, entries: list[backlog.Entry],
                     lane: str) -> list[str]:
    """Blocks a real refill would add to this lane now."""
    try:
        import refill_lane  # imported here: refill_lane imports this module
    except ModuleNotFoundError as exc:
        if exc.name != "refill_lane":
            raise
        return []  # a partial tools/ copy cannot run the refill admission test

    queued = {slice_id for _, slice_id in refill_lane.queued_ids(text)}
    refilled = refill_lane.top_up(text, lane, root, [], entries, [])
    return [slice_id for item_lane, slice_id in refill_lane.queued_ids(refilled)
            if item_lane == lane and slice_id not in queued]


def check_plan_queue_blocks(errors: list[str], warnings: list[str],
                            text: str | None = None, root: Path | None = None,
                            entries: list[backlog.Entry] | None = None) -> None:
    """Plan blocks parse, agree with the live queue, and get used."""
    root = root or ROOT
    if text is None:
        text = (root / "NEXTSTEPS.md").read_text(encoding="utf-8")
    if entries is None:
        entries, problems = backlog.collect(current_plans(), root)
        errors.extend(problems)

    items = queue_item_chunks(text) or []
    queued: dict[str, str] = {}
    for _, chunk in items:
        match = re.match(r"\*\*\[\w+\]\s+([\w.-]+)\s+--", chunk)
        if match:
            queued[match.group(1)] = chunk

    for entry in entries:
        chunk = queued.get(entry.slice_id)
        if chunk is None:
            continue
        # The block is what a refill copies in. If the two have drifted, the
        # next refill of that id would quietly queue the stale one.
        if _block_shape(chunk) != _block_shape(entry.body):
            errors.append(
                f"{entry.plan}:{entry.line}: {entry.slice_id}'s queue block and its live "
                "'## Next up' entry disagree. They are the same five lines written twice; "
                "make the block match the queue, or the queue match the block"
            )
        if entry.gated:
            errors.append(
                f"{entry.plan}:{entry.line}: {entry.slice_id} is queued in '## Next up' but "
                "its block is fenced ```queue-gated. Open the fence to ```queue, or take "
                "the item out of the lane"
            )

    # A gated block whose proof has stopped holding is work that happened while
    # the gate was shut -- the X3 failure, caught one step earlier.
    for entry in entries:
        if not entry.gated or entry.slice_id in queued:
            continue
        proof_errors: list[str] = []
        validate_queue_proof(entry.body, 0, root, proof_errors)
        if proof_errors:
            warnings.append(
                f"{entry.plan}:{entry.line}: {entry.slice_id} is gated, but its Proof: no "
                "longer holds -- the defect it describes may already be fixed. Re-verify it "
                "before the gate is opened"
            )

    lane_sizes = {lane: 0 for lane in LANES}
    for _, chunk in items:
        match = re.match(r"\*\*\[(\w+)\]", chunk)
        if match and match.group(1) in lane_sizes:
            lane_sizes[match.group(1)] += 1
    for lane, size in lane_sizes.items():
        if size >= LANE_SIZE_MAX:
            continue
        waiting = refill_ready_ids(text, root, entries, lane)
        if waiting:
            warnings.append(
                f"NEXTSTEPS.md: the {lane} lane holds {size} of {LANE_SIZE_MAX} and the "
                f"backlog offers {', '.join(waiting)} -- run "
                f"python tools/refill_lane.py --top-up --lane {lane}"
            )


def check_markdown_links(errors: list[str]) -> None:
    files = (
        list(ROOT.glob("*.md"))
        + list((ROOT / "docs").glob("*.md"))
        + list((ROOT / "plans").glob("*.md"))
        + [
            path
            for layer in ("now", "active", "design", "reference")
            for path in (ROOT / "plans" / layer).glob("*.md")
        ]
        + list((ROOT / "checks").glob("*.md"))
        + list((ROOT / "checks" / "ready").glob("*.md"))
    )
    for path in files:
        text = path.read_text(encoding="utf-8")
        for raw_target in MD_LINK_PATTERN.findall(text):
            target = raw_target.strip().split("#", 1)[0].strip()
            if not target or "://" in target or target.startswith("mailto:"):
                continue
            if not (path.parent / target).resolve().is_file():
                errors.append(f"{path.relative_to(ROOT)}: broken Markdown link: {raw_target}")


DOC_GLOBS = (
    "*.md",
    "docs/*.md",
    "plans/*.md",
    "plans/now/*.md",
    "plans/active/*.md",
    "plans/design/*.md",
    "plans/reference/*.md",
    "checks/*.md",
    "checks/ready/*.md",
    ".claude/rules/*.md",
    "plans/reference/reviews/*.md",
)
BACKTICK_TOKEN = re.compile(r"`([^`\n]+)`")
ROUTABLE_SUFFIX = re.compile(r"\.(md|gd|py|ps1|json|tscn|tres|cfg)$")


def routable_docs() -> list[Path]:
    seen: dict[Path, None] = {}
    for pattern in DOC_GLOBS:
        for path in sorted(ROOT.glob(pattern)):
            seen[path] = None
    return list(seen)


def queue_declared_files() -> set[str]:
    """Paths named on a queue item's `Files:` line, which may not exist yet.

    validate_queue_files deliberately allows a slice to name a file it is
    going to create -- that is how a queue entry reserves the thing it is
    about to add. check_backticked_paths then rejected exactly those paths,
    so the two rules contradicted each other and H3 had to reserve a sibling
    file instead of the tool it creates. Dave settled it on 11 Sep 2026: the
    existence check gives way, because validate_queue_files has already
    proved the path's shape and a queue entry is the one place in the repo
    where a not-yet-existing path is the point rather than a mistake."""
    path = ROOT / "NEXTSTEPS.md"
    if not path.is_file():
        return set()
    text = path.read_text(encoding="utf-8")
    items = queue_item_chunks(text)
    if items is None:
        return set()
    declared: set[str] = set()
    for _, chunk in items:
        declared |= _item_files(chunk)
    # A backlog block is the same reservation written one step earlier: it is
    # where a slice first names the file it is going to create, so it needs the
    # same licence the queue item it will become already has.
    for entry in plan_queue_blocks():
        declared |= _item_files(entry.body)
    return declared


def check_backticked_paths(errors: list[str]) -> None:
    """A backticked repo path must name a file that exists.

    Almost all of this project's routing is written as `plans/now/ui.md`, not
    as a Markdown link -- CLAUDE.md's whole "Where to route a change" table is
    backticks. check_markdown_links never saw any of it, so a pointer left
    behind by a move stayed green: check-loop.md moved to plans/reference/ on
    4 Sep 2026 and DESIGN_BACKLOG.md still sent readers to plans/now/. The
    cost of a dead pointer is not tidiness -- it is a session opening a file
    that is not there and then searching for it, which is exactly the
    expensive path the routing tables exist to avoid.

    The one exception is a path a queue item declares on its `Files:` line --
    see queue_declared_files above."""
    declared = queue_declared_files()
    for path in routable_docs():
        for raw in BACKTICK_TOKEN.findall(path.read_text(encoding="utf-8")):
            token = raw.strip()
            if token in declared:
                continue
            if "/" not in token or " " in token or "://" in token.replace("res://", ""):
                continue
            if "*" in token or "?" in token:
                continue  # a glob, e.g. `scripts/**/*.gd`
            target = token[len("res://"):] if token.startswith("res://") else token
            target = target.split("::", 1)[0].split("#", 1)[0].rstrip(".,;:")
            if not ROUTABLE_SUFFIX.search(target):
                continue
            if not (ROOT / target).is_file():
                errors.append(
                    f"{path.relative_to(ROOT)}: backticked path does not exist: {token}"
                )


LANDED_RECORD = re.compile(r"^\s*\*\*Landed\b[^*]*\*\*", re.MULTILINE)


def check_no_landed_records_in_live_plans(errors: list[str]) -> None:
    """A landed slice's record belongs in plans/archive/, in every live layer.

    check_live_plans_hold_only_open_work catches a *heading* marked shipped,
    and only under plans/now/. Neither half held for plans/design/: the two
    slices Phase A shipped on 4 Sep 2026 were written up as bold paragraphs
    inside progression.md's section 11 -- the scheduling section every
    following slice is routed to read. Two landed slices had already added
    ~60 lines to it, and the pattern grows with each one, so the next slice
    pays for the history of the ones before it on every request of its
    session. Keep the decisions later steps inherit; archive the record."""
    for plan in current_plans():
        text = plan.read_text(encoding="utf-8")
        for match in LANDED_RECORD.finditer(text):
            line_no = text[: match.start()].count(chr(10)) + 1
            errors.append(
                f"{plan.relative_to(ROOT)}:{line_no}: a landed slice's record belongs in "
                f"plans/archive/ -- keep only what a later slice inherits: {match.group(0).strip()}"
            )


READY_CHECKS_DIR = ROOT / "checks" / "ready"
READY_INDEX = ROOT / "checks" / "ready.md"
CHECK_FILES = ("checks/blocked.md",)
CHECK_ID = re.compile(r"^C-(\d+) -- \S")
OWNER_NONE = re.compile(r"^Owner:\s*none\b", re.IGNORECASE)


def ready_check_files() -> list[tuple[str, Path]]:
    """Ready checks are independently owned records; ready.md is only their index.

    A feature branch that needs a player check creates one uniquely named file,
    rather than appending to a page another lane is likely to edit.  The index
    is rebuilt during integration, after the branch has merged.
    """
    if not READY_CHECKS_DIR.is_dir():
        return []
    return [
        (f"checks/ready/{path.name}", path)
        for path in sorted(READY_CHECKS_DIR.glob("C-*.md"))
    ]


def ready_index_text() -> str:
    lines = [
        "# Ready hands-on checks",
        "",
        "<!-- CONTEXT: player-checks | LAYER: on-demand -->",
        "",
        "Shipped behaviours that static checks cannot prove. Each ready check has its own",
        "record, so parallel feature slices do not edit a shared page. Reply by id, for",
        'example: "C-1 pass" or "C-1 fails: <what I saw>".',
        "",
        "This index is generated during slice closeout. Archive a confirmed check with",
        "`python tools/new_check.py --confirm C-<n>`, which also regenerates this page;",
        "move a superseded entry to `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md` by hand,",
        "and an on-demand check that cannot run to `checks/blocked.md`, naming its",
        "unblocker.",
        "",
        "## Ready to run",
        "",
    ]
    for rel, path in ready_check_files():
        heading = path.read_text(encoding="utf-8").splitlines()[0].removeprefix("# ").strip()
        lines.append(f"- [{heading}](ready/{path.name})")
    return "\n".join(lines) + "\n"


def write_ready_index() -> None:
    READY_INDEX.write_text(ready_index_text(), encoding="utf-8")


def _owner_plan(line: str) -> str | None:
    """The plan path an Owner: line names, written either as a Markdown link or in backticks."""
    for raw in MD_LINK_PATTERN.findall(line) + PATH_TOKEN.findall(line):
        target = raw.strip().split("#", 1)[0].strip()
        if "/" in target:
            return target
    return None


TEMPLATE_MARKERS = ("<what Dave does", "<the single condition", "<what a failure would change")
# Who runs a ready check in a pass (plans/reference/check-runner.md, "Choosing a runner").
CHECK_RUNNER = re.compile(r"^Runner: (haiku|sonnet|opus|dave)(?: -- \S.*)?$")


def check_checks(errors: list[str]) -> None:
    """Every hands-on check is addressable by id, with one PASS line and one owning plan.

    Dave replies "C-4 pass, C-7 fails: <what I saw>", so an entry with no id,
    or two entries sharing one, makes a reply ambiguous -- the 3 Sep pass had
    to read at least one item's meaning out of surrounding prose. The format
    was a convention until this ran."""
    seen: dict[str, str] = {}
    check_files = ready_check_files() + [(rel, ROOT / rel) for rel in CHECK_FILES]
    if not READY_CHECKS_DIR.is_dir():
        errors.append("checks/ready/: missing -- each ready hands-on check needs its own file")
    for rel, path in check_files:
        if not path.is_file():
            errors.append(f"{rel}: missing -- the hands-on checks live here")
            continue
        # Ready records contain exactly one entry headed with '#'; blocked.md
        # remains a collection headed with '###'.
        source = path.read_text(encoding="utf-8")
        entries = (
            [source.removeprefix("# ")]
            if rel.startswith("checks/ready/")
            else re.split(r"^### ", source, flags=re.MULTILINE)[1:]
        )
        for entry in entries:
            heading, _, body = entry.partition("\n")
            heading = heading.strip()
            id_match = CHECK_ID.match(heading)
            if not id_match:
                errors.append(
                    f"{rel}: entry '{heading}' must open with an id, as '### C-<n> -- <short name>' "
                    "-- Dave replies by id, so an unnamed entry cannot be answered"
                )
                continue
            check_id = f"C-{id_match.group(1)}"
            if check_id in seen:
                errors.append(
                    f"{rel}: {check_id} is already used by {seen[check_id]} -- an id follows its "
                    "entry between the two files and is never reused"
                )
            else:
                seen[check_id] = f"{rel} '{heading}'"

            if rel.startswith("checks/ready/") and path.name != f"{check_id}.md":
                errors.append(
                    f"{rel}: ready-check filename must be {check_id}.md -- one check has one independently owned record"
                )

            lines = [line.strip() for line in body.splitlines()]
            if not any(line.startswith("PASS:") for line in lines):
                errors.append(
                    f"{rel}: {check_id} has no line beginning 'PASS:' -- an entry states its single "
                    "pass condition on one line"
                )
            if any(m in body for m in TEMPLATE_MARKERS):
                errors.append(
                    f"{rel}: {check_id} still holds new_check.py's template text -- write what Dave does, "
                    "its PASS line and what a failure changes before filing it"
                )
            runners = [line for line in lines if line.startswith("Runner:")]
            if rel.startswith("checks/ready/") and (
                len(runners) != 1 or not CHECK_RUNNER.match(runners[0])
            ):
                errors.append(
                    f"{rel}: {check_id} needs one 'Runner: haiku|sonnet|opus|dave' line -- a check pass "
                    "dispatches by it (plans/reference/check-runner.md, \"Choosing a runner\")"
                )

            owners = [line for line in lines if line.startswith("Owner:")]
            if not owners:
                errors.append(f"{rel}: {check_id} has no 'Owner:' line naming the plan that owns it")
                continue
            owner = owners[0]
            target = _owner_plan(owner)
            if target is None:
                # A blocked check can outlive its plan: C-6's evidence campaign closed with
                # nothing to pick it up, and its Blocked by: line says what would.
                if rel == "checks/blocked.md" and OWNER_NONE.match(owner):
                    continue
                errors.append(f"{rel}: {check_id}'s Owner: line names no plan file -- {owner}")
            elif not (ROOT / target).is_file():
                errors.append(f"{rel}: {check_id}'s Owner: names a plan that does not exist: {target}")


# A review record opts in with this header; the older free-form reviews in
# docs/ (which use `CONTEXT: review` or `CONTEXT: workflow-audit`) are not held to it.
REVIEW_RECORD_MARKER = re.compile(r"<!--\s*CONTEXT:\s*review-record\b")
REVIEW_CONTRACT = "plans/reference/review-contract.md"
FINDING_DISPOSITIONS = ("fixed", "queued", "gated", "decided", "rejected")
# A finding from the previous run may also have shipped since.
FOLLOW_THROUGH_DISPOSITIONS = FINDING_DISPOSITIONS + ("shipped",)
REVIEW_SECTION = re.compile(r"^## +(.+?)\s*$([\s\S]*?)(?=^## |\Z)", re.MULTILINE)
TABLE_SEPARATOR = re.compile(r"^\|?\s*:?-{3,}")
SLICE_ID = re.compile(r"\b[A-Z][A-Z0-9]*-?\d+[a-z]?\b")


def _table_cells(row: str) -> list[str]:
    return [cell.strip() for cell in row.strip().strip("|").replace("\\|", "/").split("|")]


def _disposition_errors(rel: str, section: str, body: str, allowed: tuple[str, ...]) -> list[str]:
    """Every row of the section's table ends in one allowed disposition, with its detail."""
    rows = [line for line in body.splitlines() if line.lstrip().startswith("|")]
    if not rows:
        if "none" in body.lower():
            return []
        return [
            f"{rel}: '## {section}' has no table -- give one with a Disposition column, "
            f"or say 'None' ({REVIEW_CONTRACT})"
        ]
    header = [cell.strip("*").strip().lower() for cell in _table_cells(rows[0])]
    if "disposition" not in header:
        return [f"{rel}: '## {section}' table has no Disposition column ({REVIEW_CONTRACT})"]
    column = header.index("disposition")
    errors = []
    for row in rows[1:]:
        if TABLE_SEPARATOR.match(row.strip()):
            continue
        cells = _table_cells(row)
        label = cells[0] if cells else row.strip()
        cell = cells[column] if column < len(cells) else ""
        plain = cell.replace("**", "").replace("`", " ").strip()
        word, _, detail = plain.partition(" ")
        word = word.rstrip(":,;.").lower()
        detail = detail.strip(" -:–—")
        if word not in allowed:
            errors.append(
                f"{rel}: '## {section}' row '{label}' has no disposition -- its cell must start "
                f"with one of {', '.join(w.title() for w in allowed)} ({REVIEW_CONTRACT} rule 5): {cell}"
            )
        elif not re.search(r"[A-Za-z0-9]{2}", detail):
            errors.append(
                f"{rel}: '## {section}' row '{label}' says {word.title()} but not how, where or why "
                f"({REVIEW_CONTRACT} rule 5)"
            )
        elif word in ("queued", "gated") and "plans/" not in detail and not SLICE_ID.search(detail):
            errors.append(
                f"{rel}: '## {section}' row '{label}' is {word.title()} without naming the slice id "
                f"or plan that holds it ({REVIEW_CONTRACT} rule 5)"
            )
    return errors


def review_record_errors(rel: str, text: str) -> list[str]:
    sections = {
        heading.strip().lower(): (heading.strip(), body)
        for heading, body in REVIEW_SECTION.findall(text)
    }
    errors = []
    for name, allowed in (
        ("Follow-through", FOLLOW_THROUGH_DISPOSITIONS),
        ("Findings", FINDING_DISPOSITIONS),
    ):
        match = next(
            (value for key, value in sections.items() if key.startswith(name.lower())), None
        )
        if match is None:
            errors.append(
                f"{rel}: review record has no '## {name}' section ({REVIEW_CONTRACT} rule 8)"
            )
            continue
        errors.extend(_disposition_errors(rel, match[0], match[1], allowed))
    return errors


def check_review_records(errors: list[str]) -> None:
    """A review record leaves no finding as prose.

    Every review run from Dave's prompt library ends each finding in exactly
    one of fixed, queued, gated, decided or rejected, and audits the previous
    run's findings the same way (`plans/reference/review-contract.md`). The
    18 Sep 2026 codebase review ended instead with "Next: route the items ...
    into their owning plans" -- a second step that nothing checked, so a
    finding could be written down and never reach a plan. This makes the
    routing part of writing the record."""
    for path in sorted((ROOT / "docs").glob("*.md")):
        text = path.read_text(encoding="utf-8")
        if REVIEW_RECORD_MARKER.search("\n".join(text.splitlines()[:6])):
            errors.extend(review_record_errors(path.relative_to(ROOT).as_posix(), text))

def git_worktree_paths() -> set[Path] | None:
    """Resolved paths of every worktree Git currently knows about, or None if git is unavailable."""
    try:
        result = subprocess.run(
            ["git", "worktree", "list", "--porcelain"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    paths: set[Path] = set()
    for line in result.stdout.splitlines():
        if line.startswith("worktree "):
            paths.add(Path(line[len("worktree "):]).resolve())
    return paths


def primary_checkout() -> Path:
    """The main checkout's root, which is what a `.worktrees/x` path in the
    ledger is relative to.

    Not the same as ROOT when this runs inside a worktree: there, ROOT is the
    worktree itself, and resolving `.worktrees/x` against it looks for a
    nested copy that has never existed, so every ledger row read as stale and
    verify.ps1 could not pass from the branch it was checking."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--git-common-dir"],
            cwd=ROOT, capture_output=True, text=True, check=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return ROOT
    return (ROOT / result.stdout.strip()).resolve().parent


def ledger_worktree_rows() -> list[tuple[str, Path]]:
    """(raw path as written, resolved path) for each data row in plans/workstreams.md.

    Read from the primary checkout, not from ROOT. The ledger is edited only
    there (plans/reference/closeout.md, "Branches follow the lanes"), so a branch
    carries whatever copy it forked from -- reading the local one made every
    row look stale from inside a worktree and pushed sessions into editing the
    ledger on the branch, which is the conflict the rule exists to prevent."""
    ledger = primary_checkout() / "plans" / "workstreams.md"
    if not ledger.exists():
        return []
    rows: list[tuple[str, Path]] = []
    for line in ledger.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        cells = line.split("|")
        if len(cells) < 2:
            continue
        match = re.search(r"`([^`]+)`", cells[1])
        if not match:
            continue
        raw_path = match.group(1)
        rows.append((raw_path, (primary_checkout() / raw_path).resolve()))
    return rows


def pending_worktree_deletions() -> set[str]:
    """Directory names slice.ps1 could not delete at closeout and queued for
    a later slice command to retry (tools/slice.ps1, meadow-slice-pending-deletions).

    These sit outside Git's worktree registry until the retry succeeds, so
    check_workstreams must not mistake them for orphans."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--git-common-dir"],
            cwd=ROOT, capture_output=True, text=True, check=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return set()
    queue_path = (ROOT / result.stdout.strip()).resolve() / "meadow-slice-pending-deletions"
    if not queue_path.exists():
        return set()
    names: set[str] = set()
    for line in queue_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            names.add(Path(line).name)
    return names


def check_workstreams(errors: list[str], warnings: list[str]) -> None:
    """A worktree/branch is registered in plans/workstreams.md for exactly as long as it exists."""
    registered = git_worktree_paths()
    if registered is None:
        errors.append("could not run 'git worktree list' to validate plans/workstreams.md")
        return

    pending = pending_worktree_deletions()
    worktree_dir = (primary_checkout() / ".worktrees").resolve()
    if worktree_dir.is_dir():
        for entry in sorted(worktree_dir.iterdir()):
            if entry.is_dir() and entry.resolve() not in registered:
                if entry.name in pending:
                    warnings.append(
                        f".worktrees/{entry.name}: not registered with 'git worktree', but queued in "
                        "meadow-slice-pending-deletions -- skipping, not an orphan"
                    )
                    continue
                errors.append(
                    f".worktrees/{entry.name}: orphaned directory, not registered with 'git worktree' -- remove it"
                )

    ledger_rows = ledger_worktree_rows()
    for raw_path, resolved in ledger_rows:
        if resolved not in registered:
            errors.append(f"plans/workstreams.md: stale row, worktree no longer exists: {raw_path}")

    ledger_paths = {resolved for _, resolved in ledger_rows}
    for wt_path in registered:
        try:
            wt_path.relative_to(worktree_dir)
        except ValueError:
            continue
        if wt_path not in ledger_paths:
            errors.append(f"plans/workstreams.md: worktree {wt_path} is registered with Git but has no ledger row")


def main() -> int:
    if sys.argv[1:] == ["--write-ready-index"]:
        write_ready_index()
        return 0
    if sys.argv[1:]:
        print("usage: check_docs.py [--write-ready-index]", file=sys.stderr)
        return 2
    errors: list[str] = []
    warnings: list[str] = []
    check_plan_metadata(errors, warnings)
    check_context_layout(errors)
    check_live_plans_hold_only_open_work(errors, warnings)
    check_next_steps(errors, warnings)
    check_queue_files(errors)
    check_queue_proofs(errors)
    check_queue_items_state_a_level(warnings)
    check_queue_ids_are_unused(warnings)
    check_queue_successors(errors)
    check_queue_lookahead(warnings)
    check_queue_section_agreement(errors)
    check_not_in_queue_reasons(errors)
    check_stale_deferrals(warnings)
    check_released_blocked_checks(warnings)
    check_plan_queue_blocks(errors, warnings)
    check_markdown_links(errors)
    check_backticked_paths(errors)
    check_no_landed_records_in_live_plans(errors)
    check_checks(errors)
    check_review_records(errors)
    check_workstreams(errors, warnings)

    for warning in warnings:
        print(f"WARNING: {warning}")
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    if errors:
        return 1
    print("Documentation checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
