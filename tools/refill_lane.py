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
one that drops below the three-item floor, or that loses a lane entirely.

Nothing here touches `## Not in the queue, and why`: a deferral is a judgement,
and stays one.
"""

from __future__ import annotations

import argparse
import re
import sys
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


def lane_files(text: str, lane: str) -> set[str]:
    """Every path named on a `Files:` line in `lane`."""
    paths: set[str] = set()
    for lane_heading, chunk in check_docs.queue_item_chunks(text) or []:
        tag = re.match(r"\*\*\[(\w+)\]", chunk)
        if (lane_heading or (tag.group(1) if tag else None)) == lane:
            paths |= check_docs._item_files(chunk)
    return paths


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


def rejection(entry: backlog.Entry, text: str, root: Path) -> str | None:
    """Why `entry` may not join its lane now, or None if it may.

    These are the admission test written out: already queued, deliberately
    deferred, a proof that no longer holds, or a file the other lane owns."""
    queued = dict((slice_id, lane) for lane, slice_id in queued_ids(text))
    if entry.slice_id in queued:
        return "already in the queue"
    if entry.slice_id in deferred_ids(text):
        return "deferred under '## Not in the queue, and why'"
    if entry.lane not in check_docs.LANES:
        return f"its block carries an unknown lane tag [{entry.lane}]"
    proof_errors: list[str] = []
    check_docs.validate_queue_proof(entry.body, 0, root, proof_errors)
    if proof_errors:
        return "its proof no longer holds -- it may already be built"
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
    for entry in candidates:
        if held >= check_docs.LANE_SIZE_MAX:
            break
        reason = rejection(entry, text, root)
        if reason:
            if reason != "already in the queue":
                log.append(f"  not added: {entry.slice_id} ({entry.plan}) -- {reason}")
            continue
        candidate = append_item(text, entry)
        errors = queue_errors(candidate, root)
        if errors:
            log.append(f"  not added: {entry.slice_id} ({entry.plan}) -- {errors[0]}")
            continue
        text, held = candidate, held + 1
        log.append(f"  added:     {entry.slice_id} -- {entry.title} (from {entry.plan})")
    if held < check_docs.LANE_SIZE_MAX:
        log.append(f"  the {lane} lane holds {held} of {check_docs.LANE_SIZE_MAX}; the backlog "
                   "has no further admissible block for it.")
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
    parser.add_argument("--root", default=str(Path(__file__).resolve().parent.parent),
                        help="repository root (default: this checkout)")
    args = parser.parse_args()
    if not (args.delete or args.add or args.top_up):
        parser.error("give at least one of --delete, --add or --top-up")
    root = Path(args.root).resolve()
    # Plans carry em dashes and curly quotes; a Windows console defaults to
    # cp1252, so ask for UTF-8 the way tools/heading.py does.
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8", errors="replace")
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
    if args.dry_run:
        print("dry run: NEXTSTEPS.md was not written")
    elif candidate == original:
        print("NEXTSTEPS.md is unchanged")
    print("next:    python tools/check_docs.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
