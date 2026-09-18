"""Delete a delivered item from its lane in NEXTSTEPS.md and renumber the lane.

    python tools/refill_lane.py --delete L-11

removes the item whose id is L-11 from whichever `### <Lane> lane` subsection
holds it, renumbers that lane from 1, and leaves every other byte of the file
-- the other lane above all -- exactly as it was. The two lanes are separate
subsections so that two closing branches merge cleanly; a tool that reflowed
both would undo that.

Before writing, it runs tools/check_docs.py's queue checks over the result
and refuses to write a queue that would fail verification -- for example one
that drops below the three-item floor, or that loses a lane entirely.

It does not add the successor (that is prose judgement until L-12 exists)
and does not touch `## Not in the queue, and why`.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_docs  # noqa: E402

LANE_SPLIT = re.compile(r"^(?=### )", re.MULTILINE)
ITEM_SPLIT = re.compile(r"^(?=\d+\.\s+)", re.MULTILINE)
ITEM_NUMBER = re.compile(r"^\d+\.\s+")


def delete_item(text: str, slice_id: str) -> str:
    """The queue text with `slice_id`'s item gone and its lane renumbered."""
    match = check_docs.NEXT_UP_SECTION.search(text)
    if not match:
        raise SystemExit("NEXTSTEPS.md: missing a '## Next up' section")
    before = text[: match.start(1)]
    after = text[match.end(1):]
    lane_parts = LANE_SPLIT.split(match.group(1))

    head = re.compile(rf"^\d+\.\s+\*\*\[\w+\]\s+{re.escape(slice_id)}\s+--")
    rebuilt = []
    removed = False
    for part in lane_parts:
        pieces = ITEM_SPLIT.split(part)
        preamble, items = pieces[0], pieces[1:]
        if not any(head.match(item) for item in items):
            rebuilt.append(part)
            continue
        if removed:
            raise SystemExit(f"{slice_id}: appears in more than one lane")
        removed = True
        survivors = [item for item in items if not head.match(item)]
        renumbered = [
            ITEM_NUMBER.sub(f"{number}. ", item, count=1)
            for number, item in enumerate(survivors, start=1)
        ]
        rebuilt.append(preamble + "".join(renumbered))
    if not removed:
        raise SystemExit(f"{slice_id}: no item with that id in '## Next up'")
    return before + "".join(rebuilt) + after


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


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--delete", required=True, metavar="ID",
                        help="the delivered slice's id, exactly as the queue writes it")
    parser.add_argument("--root", default=str(Path(__file__).resolve().parent.parent),
                        help="repository root (default: this checkout)")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    # Plans carry em dashes and curly quotes; a Windows console defaults to
    # cp1252, so ask for UTF-8 the way tools/heading.py does.
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8", errors="replace")
    queue_path = root / "NEXTSTEPS.md"

    original = queue_path.read_text(encoding="utf-8")
    candidate = delete_item(original, args.delete)
    errors = queue_errors(candidate, root)
    if errors:
        print(f"not written: deleting {args.delete} would leave a queue that fails "
              "tools/check_docs.py:", file=sys.stderr)
        for error in errors:
            print(f"  {error}", file=sys.stderr)
        print("add the successor (or the next ready, file-disjoint slice from an "
              "owning plan) to the lane first, then retry", file=sys.stderr)
        return 1

    queue_path.write_text(candidate, encoding="utf-8")
    print(f"deleted {args.delete} from NEXTSTEPS.md; its lane is renumbered")
    print("next:    add its successor to the lane, or to '## Not in the queue, and "
          "why' if it is not startable; then python tools/check_docs.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
