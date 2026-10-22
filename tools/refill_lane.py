"""Delete a delivered item from its lane in NEXTSTEPS.md, and refill the lane.

    python tools/refill_lane.py --delete L-11
    python tools/refill_lane.py --add L-12
    python tools/refill_lane.py --top-up --lane Claude
    python tools/refill_lane.py --delete L-11 --top-up

`--delete` removes the item whose id is L-11 from whichever `### <Lane> lane`
subsection holds it, renumbers that lane from 1, and leaves every other byte of
the file -- the other lane above all -- exactly as it was. The two lanes are
separate subsections so that two closing branches merge cleanly; a tool that
reflowed both would undo that.

`--add` and `--top-up` are the other half: they copy a slice's queue block out
of its plan (`tools/backlog.py`) and append it to the lane, so a lane refills
itself from the backlog instead of from five lines rewritten out of plan prose
at closeout. `--top-up` fills to five where the backlog can, and says in plain
words what it rejected and why when it cannot. It is deliberately best-effort:
five is a ceiling the backlog reaches when it has admissible work, never a
reason to queue a slice that is not startable (Dave, 21 Sep 2026). The
admission test is unchanged -- a candidate joins a lane only if its `Proof:`
still holds, its files do not collide with the other lane, and it is not
already queued or deferred.

Before writing, every mode runs tools/check_docs.py's queue checks over the
result and refuses to write a queue that would fail verification -- for example
one whose lanes would share a file, or whose item has lost its `Proof:`. A
queue under the three-item floor, or a lane left with no item, is written
(L-32, Dave, 22 Oct 2026: the floor governs admission only, and a verified
slice merges even when it leaves its lane dry); the run then prints each
`lane dry` warning check_docs gives, so the refill happens before the next
`start` rather than inside `finish`.

`## Not in the queue, and why` is left alone with one exception: a bullet
whose only reason is that this lane is full ("startable, but the Claude lane
is full.") is a fact about the lane's size, not a judgement. When `--top-up`
finds a free slot it queues that item and deletes its bullet, rather than
leaving a sentence that went false with the last closeout to fail
check_docs (2 Oct 2026: GC-4, UT-3 and HO-7 each needed a hand edit). A
bullet that gives another reason as well stays, and the log says to reword it.

Every writing mode holds the slice lifecycle lock
(`<git common dir>/meadow-slice-lifecycle.lock`, the one `tools/slice.ps1`
holds through `start`, `finish`, `resume` and `abort`) while it reads and
rewrites NEXTSTEPS.md (L-19). On 4-5 Oct 2026 a sibling session moved an item
between lanes while a `finish` was mid-closeout, and the finish's merge
conflicted. A run that finds the lock held waits for it the way slice.ps1
does -- one line naming the holder, a check every 5 s, a refusal past
`--lock-wait-seconds` (default 600) -- and then reads the queue fresh.
slice.ps1's own calls skip the wait: it sets MEADOW_LIFECYCLE_LOCK_HELD to the
lock's path for the child while it holds that lock, so its refill does not
wait on itself. `--dry-run` and `--json` write nothing and take no lock.
"""

from __future__ import annotations

import argparse
import contextlib
import datetime
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import backlog  # noqa: E402
import check_docs  # noqa: E402

LANE_SPLIT = re.compile(r"^(?=### )", re.MULTILINE)
ITEM_SPLIT = re.compile(r"^(?=\d+\.\s+)", re.MULTILINE)
ITEM_NUMBER = re.compile(r"^\d+\.\s+")
ITEM_HEAD = re.compile(r"^\d+\.\s+\*\*\[(?P<lane>\w+)\]\s+(?P<id>[\w.-]+)\s+--")
NOT_IN_QUEUE = re.compile(
    r"^## Not in the queue, and why\s*$([\s\S]*?)(?=^## |\Z)", re.MULTILINE
)


def _sections(text: str) -> tuple[str, list[str], str]:
    """`## Next up` split into (everything before, one part per lane, after)."""
    match = check_docs.NEXT_UP_SECTION.search(text)
    if not match:
        raise SystemExit("NEXTSTEPS.md: missing a '## Next up' section")
    return (
        text[: match.start(1)],
        LANE_SPLIT.split(match.group(1)),
        text[match.end(1):],
    )


def _lane_of(part: str) -> str | None:
    heading = check_docs.LANE_HEADING.match(part)
    return heading.group(1) if heading else None


def _items(part: str) -> tuple[str, list[str]]:
    """One lane part as (its heading and preamble, its numbered items)."""
    pieces = ITEM_SPLIT.split(part)
    return pieces[0], pieces[1:]


def _rebuild(preamble: str, items: list[str]) -> str:
    """A lane part renumbered from 1, each item closed by one blank line.

    Normalising the spacing here is what lets an appended item sit against the
    next `### ` heading exactly as a hand-written one does."""
    rendered = [
        ITEM_NUMBER.sub(f"{number}. ", item.rstrip("\n"), count=1) + "\n\n"
        for number, item in enumerate(items, start=1)
    ]
    return preamble + "".join(rendered)


def delete_item(text: str, slice_id: str) -> str:
    """The queue text with `slice_id`'s item gone and its lane renumbered."""
    before, lane_parts, after = _sections(text)
    head = re.compile(rf"^\d+\.\s+\*\*\[\w+\]\s+{re.escape(slice_id)}\s+--")
    rebuilt = []
    removed = False
    for part in lane_parts:
        preamble, items = _items(part)
        if not any(head.match(item) for item in items):
            rebuilt.append(part)
            continue
        if removed:
            raise SystemExit(f"{slice_id}: appears in more than one lane")
        removed = True
        rebuilt.append(_rebuild(preamble, [i for i in items if not head.match(i)]))
    if not removed:
        raise SystemExit(f"{slice_id}: no item with that id in '## Next up'")
    return before + "".join(rebuilt) + after


def append_item(text: str, entry: backlog.Entry) -> str:
    """The queue text with `entry` appended to the end of its own lane."""
    before, lane_parts, after = _sections(text)
    rebuilt = []
    placed = False
    for part in lane_parts:
        if _lane_of(part) != entry.lane or placed:
            rebuilt.append(part)
            continue
        placed = True
        preamble, items = _items(part)
        rebuilt.append(_rebuild(preamble, items + [entry.queue_text(len(items) + 1)]))
    if not placed:
        raise SystemExit(
            f"{entry.slice_id}: NEXTSTEPS.md has no '### {entry.lane} lane' subsection "
            f"to hold it (its block in {entry.plan} carries the [{entry.lane}] tag)"
        )
    return before + "".join(rebuilt) + after


def queued_ids(text: str) -> list[tuple[str, str]]:
    """Every `## Next up` item as (lane, id), in queue order."""
    found = []
    for lane_heading, chunk in check_docs.queue_item_chunks(text) or []:
        match = re.match(r"\*\*\[(\w+)\]\s+([\w.-]+)\s+--", chunk)
        if match:
            found.append((lane_heading or match.group(1), match.group(2)))
    return found


def deferred_ids(text: str) -> set[str]:
    """Ids whose bolded lead appears under '## Not in the queue, and why'.

    Only the bolded lead counts -- the same rule check_queue_section_agreement
    uses -- so prose naming another id as the reason stays allowed."""
    section = NOT_IN_QUEUE.search(text)
    if not section:
        return set()
    return {
        token
        for lead in re.findall(r"^-\s+\*\*(.+?)\*\*", section.group(1), re.MULTILINE)
        for token in re.findall(r"[\w.-]+", lead)
    }


# A reason that is only "this lane is full", optionally after "startable
# (...), but". Anything after the lane clause (a "; it follows X" or a second
# sentence) makes it a judgement as well, which a refill must not erase.
CAPACITY_ONLY = re.compile(
    r"^(?:startable\b[^;]*?,\s*but\s+)?"
    r"(?:(?:the\s+)?(?P<a>Claude|Codex) lane is full"
    r"|waits for a free slot in the (?P<b>Claude|Codex) lane)\.?$",
    re.IGNORECASE,
)
BULLET = re.compile(r"^-\s+\*\*(?P<lead>.+?)\*\*(?P<rest>.*)$", re.MULTILINE)


def _bullet_reason(rest: str) -> str:
    """The reason part of a bullet: what follows its ' -- '."""
    parts = re.split(r"\s--\s", rest, maxsplit=1)
    return parts[1].strip() if len(parts) == 2 else rest.strip()


def capacity_deferrals(text: str, lane: str) -> tuple[set[str], set[str]]:
    """Ids deferred under '## Not in the queue, and why' because `lane` is full.

    Returns (only, mixed): `only` gives no other reason, so a free slot
    makes the bullet false and a refill may clear it; `mixed` blames the
    full lane alongside another reason, so a person has to reword it. Only
    single-id leads count -- a bullet covering several ids is left alone."""
    only: set[str] = set()
    mixed: set[str] = set()
    section = NOT_IN_QUEUE.search(text)
    if not section:
        return only, mixed
    for bullet in BULLET.finditer(section.group(1)):
        ids = re.findall(r"[\w.-]+", bullet.group("lead"))
        if len(ids) != 1:
            continue
        reason = _bullet_reason(bullet.group("rest"))
        match = CAPACITY_ONLY.match(reason)
        if match and (match.group("a") or match.group("b")).lower() == lane.lower():
            only.add(ids[0])
        elif (check_docs.LANE_FULL_REASON.search(reason)
              and re.search(rf"\b{re.escape(lane)} lane\b", reason, re.IGNORECASE)):
            mixed.add(ids[0])
    return only, mixed


def clear_deferral(text: str, slice_id: str) -> str:
    """The queue text without `slice_id`'s bullet under '## Not in the queue'."""
    section = NOT_IN_QUEUE.search(text)
    if not section:
        return text
    body = section.group(1)
    for bullet in BULLET.finditer(body):
        if re.findall(r"[\w.-]+", bullet.group("lead")) == [slice_id]:
            end = bullet.end()
            if body[end:end + 2] == "\r\n":
                end += 2
            elif body[end:end + 1] == "\n":
                end += 1
            body = body[:bullet.start()] + body[end:]
            break
    return text[:section.start(1)] + body + text[section.end(1):]


def lane_files(text: str, lane: str) -> set[str]:
    """Every path named on a `Files:` line in `lane`."""
    paths: set[str] = set()
    for lane_heading, chunk in check_docs.queue_item_chunks(text) or []:
        tag = re.match(r"\*\*\[(\w+)\]", chunk)
        if (lane_heading or (tag.group(1) if tag else None)) == lane:
            paths |= check_docs._item_files(chunk)
    return paths


def dry_lane_warnings(candidate: str, root: Path) -> list[str]:
    """check_docs's `lane dry` warnings for `candidate` (L-32): a queue under
    the floor, or a lane with no item. Written anyway; said out loud."""
    check_docs.ROOT = root
    warnings: list[str] = []
    check_docs.check_next_steps([], warnings, text=candidate)
    return [warning for warning in warnings if "lane dry" in warning]


def queue_errors(candidate: str, root: Path) -> list[str]:
    """What tools/check_docs.py's queue checks would say about `candidate`."""
    check_docs.ROOT = root
    errors: list[str] = []
    warnings: list[str] = []
    check_docs.check_next_steps(errors, warnings, text=candidate)
    check_docs.check_queue_files(errors, text=candidate)
    check_docs.check_queue_proofs(errors, text=candidate)
    check_docs.check_queue_successors(errors, text=candidate)
    check_docs.check_queue_section_agreement(errors, text=candidate)
    return errors


def load_backlog(root: Path) -> list[backlog.Entry]:
    check_docs.ROOT = root
    entries, problems = backlog.collect(check_docs.current_plans(), root)
    if problems:
        print("queue blocks that do not parse (they cannot be refilled from):",
              file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
    return entries


def rejection(entry: backlog.Entry, text: str, root: Path,
              undeferred: set[str] | None = None) -> str | None:
    """Why `entry` may not join its lane now, or None if it may.

    These are the admission test written out: already queued, deliberately
    deferred, a proof that no longer holds, or a file the other lane owns.
    `undeferred` holds ids whose only deferral is a full lane that now has
    room; the caller clears their bullet when it queues them."""
    queued = dict((slice_id, lane) for lane, slice_id in queued_ids(text))
    if entry.slice_id in queued:
        return "already in the queue"
    if entry.slice_id in deferred_ids(text) and entry.slice_id not in (undeferred or set()):
        return "deferred under '## Not in the queue, and why'"
    if entry.lane not in check_docs.LANES:
        return f"its block carries an unknown lane tag [{entry.lane}]"
    proof_errors: list[str] = []
    check_docs.validate_queue_proof(entry.body, 0, root, proof_errors)
    if proof_errors:
        # A malformed Proof: is a planning fault, not built work; FR-1b's
        # `contains:` hid behind the "already built" wording and left the
        # Codex lane dry at AR-5's finish (21 Oct 2026).
        if not check_docs.proof_error_is_shape(proof_errors[0]):
            return "its proof no longer holds -- it may already be built"
        return f"its block's {proof_errors[0].removeprefix('NEXTSTEPS.md item 0: ')}"
    other = [lane for lane in check_docs.LANES if lane != entry.lane]
    shared = check_docs._item_files(entry.body) & lane_files(text, other[0])
    if shared:
        return f"the {other[0]} lane already owns {', '.join(sorted(shared))}"
    return None


def gated_reason(text: str, slice_id: str) -> str:
    """What '## Not in the queue, and why' says `slice_id` waits for.

    A gated block without a bullet there is a gate nobody wrote down, which is
    worth saying out loud at the moment a lane comes up short."""
    section = NOT_IN_QUEUE.search(text)
    if section:
        for bullet in re.finditer(r"^-\s+\*\*(.+?)\*\*(.*)$", section.group(1), re.MULTILINE):
            if re.search(rf"\b{re.escape(slice_id)}\b", bullet.group(1)):
                rest = bullet.group(2).strip()
                parts = re.split(r"\s--\s", rest, maxsplit=1)
                return parts[1].strip() if len(parts) == 2 else (rest or "no reason recorded")
    return "no bullet under '## Not in the queue, and why' says what it waits for"


def _successor(text: str, slice_id: str) -> str:
    """The closing item's named next slice, if it has one."""
    for _, chunk in check_docs.queue_item_chunks(text) or []:
        if not re.match(rf"\*\*\[\w+\]\s+{re.escape(slice_id)}\s+--", chunk):
            continue
        line = check_docs.NO_SUCCESSOR.search(chunk)
        if line and not line.group(1).lower().startswith("none"):
            return line.group(1).split("--", 1)[0].strip()
    return ""


def _entry_level(entry: backlog.Entry, root: Path) -> str:
    """Read the level stated in a block's own plan section or open-slices row."""
    plan_path = root / entry.plan
    if not plan_path.is_file():
        return ""
    plan = plan_path.read_text(encoding="utf-8")
    heading = re.search(rf"(?m)^#{{1,6}}\s+{re.escape(entry.slice_id)}\s+--.*$", plan)
    if heading:
        depth = len(heading.group().split()[0])
        rest = plan[heading.end():]
        end = re.search(rf"(?m)^#{{1,{depth}}}\s", rest)
        section = rest[:end.start()] if end else rest
        level = re.search(r"(?im)^(?:\*\*)?Level:(?:\*\*)?\s*(low|medium|high)\b", section)
        if level:
            return level.group(1).lower()
    row = re.search(rf"(?m)^\|\s*{re.escape(entry.slice_id)}\s*\|[^\n]*\|\s*(low|medium|high)\s*\|", plan)
    return row.group(1).lower() if row else ""


def borrowable_blocks(text: str, lane: str, root: Path,
                      entries: list[backlog.Entry]) -> list[dict[str, str]]:
    """Ready blocks in the other lane whose files do not touch this lane."""
    queued = {slice_id for _, slice_id in queued_ids(text)}
    deferred = deferred_ids(text)
    owned = lane_files(text, lane)
    found: list[dict[str, str]] = []
    for entry in entries:
        if entry.lane == lane or entry.gated or entry.slice_id in queued | deferred:
            continue
        level = _entry_level(entry, root)
        if level not in {"low", "medium"} or check_docs._item_files(entry.body) & owned:
            continue
        proof_errors: list[str] = []
        check_docs.validate_queue_proof(entry.body, 0, root, proof_errors)
        if not proof_errors:
            found.append({"id": entry.slice_id, "plan": entry.plan, "level": level})
    return found


def dry_lane_advice(report: dict, queued: set[str] | None = None) -> list[str]:
    """Actionable human wording for both the refill log and lookahead."""
    advice = []
    if (report["successor"] and not report["successor_deferred"]
            and report["successor"] not in (queued or set())):
        advice.append(f"{report['successor']} is neither queued nor deferred -- add its bullet "
                      "under '## Not in the queue, and why'")
    for entry in report["borrowable"]:
        other_lane = next(lane for lane in check_docs.LANES if lane != report["lane"])
        advice.append(f"the {other_lane} backlog holds {entry['id']} "
                      f"({entry['level']}, {entry['plan']}) that this lane could take "
                      "if Dave reassigns it")
    return advice


def top_up(text: str, lane: str, root: Path, prefer: list[str],
           entries: list[backlog.Entry], log: list[str],
           closed: set[str] | None = None) -> str:
    """Append admissible backlog blocks to `lane` until it holds five.

    Best-effort by decision: when the backlog runs out the lane stays short and
    `log` says which candidate was refused for what. `prefer` puts the closing
    slice's named successor first, so the ordinary case reads as the plan
    intended rather than as whatever the file order happened to be.

    `closed` holds ids this same run deleted. Ordinarily their block has
    already gone to the archive with the rest of the slice's section, but a
    session that ran `--delete X --top-up` without archiving first would
    otherwise watch the refill put X straight back."""
    closed = closed or set()
    candidates = [e for e in entries
                  if e.lane == lane and not e.gated and e.slice_id not in closed]
    candidates.sort(key=lambda e: prefer.index(e.slice_id) if e.slice_id in prefer else len(prefer))
    held = sum(1 for item_lane, _ in queued_ids(text) if item_lane == lane)
    capacity_only, capacity_mixed = capacity_deferrals(text, lane)
    for entry in candidates:
        if held >= check_docs.LANE_SIZE_MAX:
            break
        reason = rejection(entry, text, root, undeferred=capacity_only)
        if reason:
            if reason != "already in the queue":
                log.append(f"  not added: {entry.slice_id} ({entry.plan}) -- {reason}")
            continue
        candidate = append_item(text, entry)
        cleared = entry.slice_id in capacity_only and entry.slice_id in deferred_ids(text)
        if cleared:
            candidate = clear_deferral(candidate, entry.slice_id)
        errors = queue_errors(candidate, root)
        if errors:
            log.append(f"  not added: {entry.slice_id} ({entry.plan}) -- {errors[0]}")
            continue
        text, held = candidate, held + 1
        note = "; its 'lane is full' deferral is cleared" if cleared else ""
        log.append(f"  added:     {entry.slice_id} -- {entry.title} (from {entry.plan}{note})")
    if held < check_docs.LANE_SIZE_MAX:
        stale = sorted(capacity_mixed & deferred_ids(text))
        for slice_id in stale:
            log.append(f"  reword:    {slice_id} -- its bullet under '## Not in the queue, and why' "
                       f"blames a full {lane} lane, which has a free slot; keep only its other reason")
        log.append(f"  the {lane} lane holds {held} of {check_docs.LANE_SIZE_MAX}; the backlog "
                   "has no further admissible block for it.")
        report = {"lane": lane, "successor": prefer[0] if prefer else "",
                  "successor_deferred": bool(prefer and prefer[0] in deferred_ids(text)),
                  "borrowable": borrowable_blocks(text, lane, root, entries)}
        log.extend(f"    {line}" for line in
                   dry_lane_advice(report, {slice_id for _, slice_id in queued_ids(text)}))
        gated = [e for e in entries if e.lane == lane and e.gated]
        for entry in gated:
            log.append(f"    gated: {entry.slice_id} ({entry.plan}) -- {gated_reason(text, entry.slice_id)}")
        if gated:
            log.append("    each is specified and proof-checked already; open its fence from "
                       "```queue-gated to ```queue when its gate clears and the next refill "
                       "takes it.")
        else:
            log.append("    specify the next slice in its plan with a ```queue block, or say "
                       "under '## Not in the queue, and why' what it waits for.")
    return text


def dry_after_report(text: str, lane: str, slice_id: str, root: Path,
                     entries: list[backlog.Entry]) -> dict:
    """What closing `slice_id` would leave, as data (L-18).

    Runs the same delete and top-up `finish` runs, on a copy, and reports the
    lane's and the queue's size afterwards, the ids the top-up would add and
    the gated ids still waiting. `dry_after` is true when closing would empty
    the lane or take the whole queue under the floor and the top-up adds
    nothing: the case `finish` merges and reports as `lane dry` (L-32)."""
    after = delete_item(text, slice_id)
    before_ids = {i for _, i in queued_ids(after)}
    refilled = top_up(after, lane, root, [], entries, [], closed={slice_id})
    added = [i for _, i in queued_ids(refilled) if i not in before_ids]
    lane_after = sum(1 for item_lane, _ in queued_ids(after) if item_lane == lane)
    queue_after = len(queued_ids(after))
    gated = [e.slice_id for e in entries if e.lane == lane and e.gated]
    short = lane_after == 0 or queue_after < check_docs.QUEUE_SIZE_MIN
    successor = _successor(text, slice_id)
    borrowable = borrowable_blocks(after, lane, root, entries)
    return {"id": slice_id, "lane": lane, "lane_after": lane_after,
            "queue_after": queue_after, "would_add": added, "gated": gated,
            "dry_after": bool(short and not added), "successor": successor,
            "successor_deferred": bool(successor and successor in deferred_ids(text)),
            "borrowable": borrowable}


# --- the lifecycle lock (L-19) ---

LOCK_NAME = "meadow-slice-lifecycle.lock"
LOCK_HELD_ENV = "MEADOW_LIFECYCLE_LOCK_HELD"
LOCK_WAIT_DEFAULT = 600
LOCK_POLL_SECONDS = 5


class LockBusy(Exception):
    """The lifecycle lock stayed held past the wait bound."""


def lifecycle_lock_path(root: Path) -> Path | None:
    """The lock `slice.ps1` holds, or None when `root` is not in a Git checkout
    (a test fixture, say): no checkout, no lifecycle to wait for."""
    try:
        result = subprocess.run(["git", "-C", str(root), "rev-parse", "--git-common-dir"],
                                capture_output=True, text=True)
    except OSError:
        return None
    common = result.stdout.strip()
    if result.returncode != 0 or not common:
        return None
    common_path = Path(common)
    if not common_path.is_absolute():
        common_path = root / common_path
    return common_path / LOCK_NAME


def _same_path(a: str, b: Path) -> bool:
    def norm(path: str) -> str:
        return os.path.normcase(os.path.normpath(os.path.abspath(path)))
    return norm(a) == norm(str(b))


def _holder_label(lock_path: Path) -> str:
    """Who holds the lock, worded as slice.ps1's Get-LifecycleHolderLabel."""
    try:
        holder = json.loads(lock_path.read_bytes().decode("utf-8-sig"))
    except (OSError, ValueError):
        return "another lifecycle command (its holder note is not readable)"
    if not isinstance(holder, dict):
        return "another lifecycle command (its holder note is not readable)"
    if holder.get("tool"):
        what = f"`{holder['tool']}`"
    else:
        what = f"`slice.ps1 {holder.get('command', '')}`"
    if holder.get("id"):
        what += f" on {holder['id']}"
    elif holder.get("lane"):
        what += f" ({holder['lane']} lane)"
    return (f"{what} (PID {holder.get('pid')}, run from {holder.get('cwd')}), "
            f"which took it at {holder.get('started')}")


def _open_exclusive(lock_path: Path):
    """The lock file opened for writing with others limited to reading, as
    slice.ps1's [System.IO.File]::Open(..., Write, FileShare.Read) opens it;
    None while another process holds it. Python's own open() shares writes,
    so on Windows the share mode has to be asked for through CreateFileW."""
    if os.name == "nt":
        import ctypes
        import msvcrt
        from ctypes import wintypes
        kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
        kernel32.CreateFileW.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD,
                                         wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD,
                                         wintypes.HANDLE]
        kernel32.CreateFileW.restype = wintypes.HANDLE
        generic_write, file_share_read, open_always, normal = 0x40000000, 0x1, 4, 0x80
        handle = kernel32.CreateFileW(str(lock_path), generic_write, file_share_read, None,
                                      open_always, normal, None)
        if handle in (None, wintypes.HANDLE(-1).value):
            error = ctypes.get_last_error()
            if error in (5, 32, 33):  # access denied (pending delete), sharing, lock violation
                return None
            raise ctypes.WinError(error)
        return os.fdopen(msvcrt.open_osfhandle(handle, os.O_WRONLY), "wb")
    import fcntl
    stream = open(lock_path, "ab")
    try:
        fcntl.flock(stream.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        stream.close()
        return None
    return stream


@contextlib.contextmanager
def lifecycle_lock(root: Path, wait_seconds: int, tool: str):
    """Hold the lifecycle lock for the body, waiting for it like slice.ps1."""
    lock_path = lifecycle_lock_path(root)
    held_by_parent = os.environ.get(LOCK_HELD_ENV, "")
    if lock_path is None or (held_by_parent and _same_path(held_by_parent, lock_path)):
        yield
        return
    started_wait = time.monotonic()
    announced = False
    while True:
        stream = _open_exclusive(lock_path)
        if stream:
            break
        remaining = wait_seconds - (time.monotonic() - started_wait)
        if remaining <= 0:
            waited = f" after waiting {wait_seconds} s (--lock-wait-seconds)" if wait_seconds > 0 else ""
            raise LockBusy(f"slice lifecycle is busy{waited}: {_holder_label(lock_path)}; "
                           "NEXTSTEPS.md is unchanged -- retry once it ends")
        if not announced:
            bound = f"{wait_seconds // 60} min" if wait_seconds >= 120 else f"{wait_seconds} s"
            print(f"slice lifecycle is busy: waiting for {_holder_label(lock_path)} -- this "
                  f"command continues when it ends (checking every {LOCK_POLL_SECONDS} s, "
                  f"for up to {bound})", file=sys.stderr, flush=True)
            announced = True
        time.sleep(min(LOCK_POLL_SECONDS, remaining))
    try:
        note = {"command": tool, "tool": tool, "id": "", "lane": "", "pid": os.getpid(),
                "cwd": os.getcwd(),
                "started": datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")}
        stream.write(json.dumps(note, separators=(",", ":")).encode("utf-8"))
        stream.truncate()
        stream.flush()
        yield
    finally:
        stream.close()
        # slice.ps1 removes its lock file on release too; a holder that took
        # it in between keeps it (no delete sharing), which is what we want.
        with contextlib.suppress(OSError):
            lock_path.unlink()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--delete", metavar="ID",
                        help="the delivered slice's id, exactly as the queue writes it")
    parser.add_argument("--add", metavar="ID",
                        help="copy one slice's queue block out of its plan into its lane")
    parser.add_argument("--top-up", action="store_true",
                        help="fill each lane to five from the backlog, as far as it can")
    parser.add_argument("--lane", choices=check_docs.LANES,
                        help="with --top-up, the one lane to fill (default: both)")
    parser.add_argument("--dry-run", action="store_true",
                        help="say what would change and write nothing")
    parser.add_argument("--json", action="store_true",
                        help="with --delete ID --top-up --lane L: print what closing ID would "
                             "leave as one JSON object (implies --dry-run)")
    parser.add_argument("--root", default=str(Path(__file__).resolve().parent.parent),
                        help="repository root (default: this checkout)")
    parser.add_argument("--lock-wait-seconds", type=int, default=LOCK_WAIT_DEFAULT,
                        help="how long a writing run waits for a running slice.ps1 "
                             "lifecycle command to release the lock (default 600)")
    args = parser.parse_args()
    if not (args.delete or args.add or args.top_up):
        parser.error("give at least one of --delete, --add or --top-up")
    root = Path(args.root).resolve()
    # Plans carry em dashes and curly quotes; a Windows console defaults to
    # cp1252, so ask for UTF-8 the way tools/heading.py does.
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8", errors="replace")
    if args.json:
        if not (args.delete and args.top_up and args.lane):
            parser.error("--json needs --delete ID, --top-up and --lane")
        original = (root / "NEXTSTEPS.md").read_text(encoding="utf-8")
        print(json.dumps(dry_after_report(original, args.lane, args.delete, root,
                                          load_backlog(root))))
        return 0
    if args.dry_run:
        return refill(args, root)
    # The read and the write both sit inside the lock: a queue read before
    # a running finish merged would be written back over its edit.
    try:
        with lifecycle_lock(root, args.lock_wait_seconds, "tools/refill_lane.py"):
            return refill(args, root)
    except LockBusy as busy:
        print(busy, file=sys.stderr)
        return 1


def refill(args: argparse.Namespace, root: Path) -> int:
    """--delete, --add and --top-up over NEXTSTEPS.md, written unless --dry-run."""
    queue_path = root / "NEXTSTEPS.md"
    original = queue_path.read_text(encoding="utf-8")
    candidate = original
    log: list[str] = []
    successor: list[str] = []

    if args.delete:
        for _, chunk in check_docs.queue_item_chunks(original) or []:
            if re.match(rf"\*\*\[\w+\]\s+{re.escape(args.delete)}\s+--", chunk):
                line = check_docs.NO_SUCCESSOR.search(chunk)
                if line and not line.group(1).lower().startswith("none"):
                    successor = [line.group(1).split("--", 1)[0].strip()]
        candidate = delete_item(candidate, args.delete)
        log.append(f"deleted {args.delete} from NEXTSTEPS.md; its lane is renumbered")

    if args.add or args.top_up:
        entries = load_backlog(root)
        if args.add:
            match = [e for e in entries if e.slice_id == args.add]
            if not match:
                print(f"{args.add}: no ```queue block in any live plan. Write one in the "
                      "slice's own section first -- see tools/backlog.py.", file=sys.stderr)
                return 1
            entry = match[0]
            reason = rejection(entry, candidate, root)
            if reason:
                print(f"not added: {entry.slice_id} -- {reason}", file=sys.stderr)
                return 1
            candidate = append_item(candidate, entry)
            log.append(f"added {entry.slice_id} to the {entry.lane} lane from {entry.plan}")
        if args.top_up:
            lanes = [args.lane] if args.lane else list(check_docs.LANES)
            for lane in lanes:
                log.append(f"topping up the {lane} lane:")
                candidate = top_up(candidate, lane, root, successor, entries, log,
                                   closed={args.delete} if args.delete else set())

    errors = queue_errors(candidate, root)
    if errors:
        action = "deleting " + args.delete if args.delete else "this refill"
        print(f"not written: {action} would leave a queue that fails "
              "tools/check_docs.py:", file=sys.stderr)
        for error in errors:
            print(f"  {error}", file=sys.stderr)
        print("add the successor (or the next ready, file-disjoint slice from an "
              "owning plan) to the lane first, then retry", file=sys.stderr)
        return 1

    if not args.dry_run and candidate != original:
        queue_path.write_text(candidate, encoding="utf-8")
    for line in log:
        print(line)
    for warning in dry_lane_warnings(candidate, root):
        print(f"warning: {warning}")
    if args.dry_run:
        print("dry run: NEXTSTEPS.md was not written")
    elif candidate == original:
        print("NEXTSTEPS.md is unchanged")
    print("next:    python tools/check_docs.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
