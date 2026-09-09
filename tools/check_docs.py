"""Cheap checks for Meadow's current planning/documentation entry points."""

from __future__ import annotations

from datetime import date
from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent
PLAN_PATTERN = re.compile(r"^Status:\s*(.+)$", re.MULTILINE)
REQUIRED_STATUS_FIELDS = ("owner:", "next:", "dependency:", "verified:")
TERMINAL_STATES = ("complete", "completed", "archived", "abandoned", "retired")
MD_LINK_PATTERN = re.compile(r"(?<!!)\[[^]]*\]\(([^)]+)\)")


def current_plans() -> list[Path]:
    """Return the small, routable plan layers; history is intentionally excluded."""
    layers = ("now", "active", "design", "reference")
    return sorted(
        path
        for layer in layers
        for path in (ROOT / "plans" / layer).glob("*.md")
    )


def check_plan_metadata(errors: list[str], warnings: list[str]) -> None:
    for plan in current_plans():
        text = plan.read_text(encoding="utf-8")
        first_lines = "\n".join(text.splitlines()[:8])
        match = PLAN_PATTERN.search(first_lines)
        if not match:
            errors.append(f"{plan.relative_to(ROOT)}: active plan has no Status line in its first 8 lines")
            continue

        status = match.group(1).lower()
        metadata = first_lines.lower()
        if any(state in status for state in TERMINAL_STATES):
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


# Normally exactly QUEUE_SIZE_MAX (five slices keep both lanes stocked). The
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
QUEUE_SIZE_MAX = 5
LANES = ("Claude", "Codex")
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


def check_queue_files(errors: list[str]) -> None:
    """Every unclaimed item must expose the exact file set used by overlap checks."""
    path = ROOT / "NEXTSTEPS.md"
    text = path.read_text(encoding="utf-8")
    match = re.search(r"^## Next up\s*$([\s\S]*?)(?=^## |\Z)", text, re.MULTILINE)
    if not match:
        return
    chunks = re.split(r"^\d+\.\s+", match.group(1), flags=re.MULTILINE)[1:]
    active_slice_ids = _active_slice_ids()
    for index, chunk in enumerate(chunks, start=1):
        item_match = re.match(r"\*\*\[\w+\]\s+([\w.-]+)\s+--", chunk)
        if item_match and item_match.group(1) in active_slice_ids:
            continue
        validate_queue_files(chunk, index, errors)


def check_next_steps(errors: list[str], warnings: list[str]) -> None:
    """The queue holds QUEUE_SIZE_MIN-QUEUE_SIZE_MAX ready slices, in two lanes that cannot collide."""
    path = ROOT / "NEXTSTEPS.md"
    text = path.read_text(encoding="utf-8")
    match = re.search(r"^## Next up\s*$([\s\S]*?)(?=^## |\Z)", text, re.MULTILINE)
    if not match:
        errors.append("NEXTSTEPS.md: missing a '## Next up' section")
        return
    section = match.group(1)

    chunks = re.split(r"^\d+\.\s+", section, flags=re.MULTILINE)[1:]
    if not (QUEUE_SIZE_MIN <= len(chunks) <= QUEUE_SIZE_MAX):
        errors.append(
            f"NEXTSTEPS.md: expected {QUEUE_SIZE_MIN}-{QUEUE_SIZE_MAX} next-step items, found {len(chunks)}"
        )

    lane_order: list[tuple[str, str]] = []
    for index, chunk in enumerate(chunks, start=1):
        lane_match = re.match(r"\*\*\[(\w+)\]", chunk)
        if not lane_match or lane_match.group(1) not in LANES:
            errors.append(
                f"NEXTSTEPS.md item {index}: must open with a lane tag, one of "
                + ", ".join(f"**[{lane}]" for lane in LANES)
            )
            continue
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
    # merge. Same-lane overlap is fine: a lane is worked top to bottom.
    for lane_a, chunk_a in lane_order:
        for lane_b, chunk_b in lane_order:
            if lane_a >= lane_b:
                continue
            overlap = _item_files(chunk_a) & _item_files(chunk_b)
            if overlap:
                warnings.append(
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


def check_queue_successors(errors: list[str]) -> None:
    """Every queue item names the slice that follows it, or says its plan is done."""
    path = ROOT / "NEXTSTEPS.md"
    text = path.read_text(encoding="utf-8")
    match = re.search(r"^## Next up\s*$([\s\S]*?)(?=^## |\Z)", text, re.MULTILINE)
    if not match:
        return
    chunks = re.split(r"^\d+\.\s+", match.group(1), flags=re.MULTILINE)[1:]
    for index, chunk in enumerate(chunks, start=1):
        line = NO_SUCCESSOR.search(chunk)
        if not line:
            continue   # check_next_steps already reports the missing field
        value = line.group(1)
        if not value.lower().startswith("none"):
            continue
        if PLAN_COMPLETE.search(value):
            continue
        errors.append(
            f"NEXTSTEPS.md item {index}: 'Next after: {value}' names no successor. "
            "Name the slice that follows it, or write "
            "'none -- <plan> is complete' if its owning plan has no further work "
            "(Dave, D-2, 8 Sep 2026)"
        )


def check_queue_proofs(errors: list[str]) -> None:
    """Each queue item's Proof: line must still hold against the code it names.

    X3 sat at the head of a lane, with a worktree open, for a fix that had
    shipped three days earlier -- this is what would have caught it. An
    in-progress slice is the exception: its proof is expected to flip while
    its registered worktree is being verified for merge."""
    path = ROOT / "NEXTSTEPS.md"
    text = path.read_text(encoding="utf-8")
    match = re.search(r"^## Next up\s*$([\s\S]*?)(?=^## |\Z)", text, re.MULTILINE)
    if not match:
        return
    section = match.group(1)
    chunks = re.split(r"^\d+\.\s+", section, flags=re.MULTILINE)[1:]
    active_slice_ids = _active_slice_ids()

    for index, chunk in enumerate(chunks, start=1):
        item_match = re.match(r"\*\*\[\w+\]\s+([\w.-]+)\s+--", chunk)
        if item_match and item_match.group(1) in active_slice_ids:
            continue
        validate_queue_proof(chunk, index, ROOT, errors)


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
)
BACKTICK_TOKEN = re.compile(r"`([^`\n]+)`")
ROUTABLE_SUFFIX = re.compile(r"\.(md|gd|py|ps1|json|tscn|tres|cfg)$")


def routable_docs() -> list[Path]:
    seen: dict[Path, None] = {}
    for pattern in DOC_GLOBS:
        for path in sorted(ROOT.glob(pattern)):
            seen[path] = None
    return list(seen)


def check_backticked_paths(errors: list[str]) -> None:
    """A backticked repo path must name a file that exists.

    Almost all of this project's routing is written as `plans/now/ui.md`, not
    as a Markdown link -- CLAUDE.md's whole "Where to route a change" table is
    backticks. check_markdown_links never saw any of it, so a pointer left
    behind by a move stayed green: check-loop.md moved to plans/reference/ on
    4 Sep 2026 and DESIGN_BACKLOG.md still sent readers to plans/now/. The
    cost of a dead pointer is not tidiness -- it is a session opening a file
    that is not there and then searching for it, which is exactly the
    expensive path the routing tables exist to avoid."""
    for path in routable_docs():
        for raw in BACKTICK_TOKEN.findall(path.read_text(encoding="utf-8")):
            token = raw.strip()
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
        "This index is generated during slice closeout. Move a confirmed or superseded",
        "entry to `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`; move an on-demand check",
        "that cannot run to `checks/blocked.md`, naming its unblocker.",
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
    there (CLAUDE.md, "Coordinating and closing out workstreams"), so a branch
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


def check_workstreams(errors: list[str]) -> None:
    """A worktree/branch is registered in plans/workstreams.md for exactly as long as it exists."""
    registered = git_worktree_paths()
    if registered is None:
        errors.append("could not run 'git worktree list' to validate plans/workstreams.md")
        return

    worktree_dir = (primary_checkout() / ".worktrees").resolve()
    if worktree_dir.is_dir():
        for entry in sorted(worktree_dir.iterdir()):
            if entry.is_dir() and entry.resolve() not in registered:
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
    check_queue_successors(errors)
    check_markdown_links(errors)
    check_backticked_paths(errors)
    check_no_landed_records_in_live_plans(errors)
    check_checks(errors)
    check_workstreams(errors)

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
