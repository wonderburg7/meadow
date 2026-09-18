"""Move a closing slice's plan section into plans/archive/ and leave a pointer.

    python tools/archive_slice.py L-10

resolves the slice's `Plan:` file and `Heading:` from the queue as committed
on master (the branch's own copy may already have the item deleted), cuts the
section under that heading with tools/heading.py's boundary logic, writes it
verbatim to plans/archive/<id>_<date>.md under a two-line preamble, replaces
it in the live plan with a one-line pointer, and drops the slice's row from
the plan's open-slices table if it has one.

It refuses to run on a dirty working tree, so `git checkout -- <plan>` and
deleting the new archive file always undo it: a bad move would otherwise
destroy a plan section. It does not commit, does not touch NEXTSTEPS.md
(tools/refill_lane.py) and does not change tools/slice.ps1's gates -- those
read the result and are satisfied by it.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from check_docs import queue_item_chunks  # noqa: E402
from heading import headings, section  # noqa: E402

PLAN_LINE = re.compile(r"- Plan: `([^`]+)` -- \"([^\"]+)\"")


def _git(root: Path, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True)


def queue_text(root: Path, base: str) -> str:
    """The queue as committed on `base`, else the working tree's copy."""
    if base:
        shown = _git(root, "show", f"{base}:NEXTSTEPS.md")
        if shown.returncode == 0 and shown.stdout.strip():
            return shown.stdout
    return (root / "NEXTSTEPS.md").read_text(encoding="utf-8")


def resolve_item(text: str, slice_id: str) -> tuple[str, str] | None:
    """(plan path, heading text) for the queue item whose id is `slice_id`."""
    items = queue_item_chunks(text) or []
    for _, chunk in items:
        head = re.match(r"\*\*\[\w+\]\s+(.+?)\s+--", chunk)
        if not head or head.group(1) != slice_id:
            continue
        plan = PLAN_LINE.search(chunk)
        if not plan:
            return None
        return plan.group(1), plan.group(2)
    return None


def find_section(lines: list[str], heading: str, slice_id: str) -> tuple[int, int, str] | None:
    """The heading whose text contains `heading`; prefer one naming the id."""
    found = headings(lines)
    wanted = heading.casefold()
    matches = [entry for entry in found if wanted in entry[2].casefold()]
    if not matches:
        return None
    for entry in matches:
        if re.search(rf"(?<![\w.-]){re.escape(slice_id)}(?![\w.-])", entry[2]):
            return entry
    return matches[0]


def archive(root: Path, slice_id: str, plan_rel: str, heading: str, when: str,
            branch: str) -> tuple[Path, str]:
    plan_path = root / plan_rel
    lines = plan_path.read_text(encoding="utf-8").splitlines()
    hit = find_section(lines, heading, slice_id)
    if hit is None:
        raise SystemExit(f"{plan_rel}: no heading contains {heading!r}")
    start, level, text = hit
    found = headings(lines)
    body = section(lines, start, level, found)

    archive_dir = root / "plans" / "archive"
    archive_dir.mkdir(parents=True, exist_ok=True)
    archive_rel = f"plans/archive/{slice_id}_{when}.md"
    archive_path = root / archive_rel
    if archive_path.exists():
        raise SystemExit(f"{archive_rel} already exists; nothing written")

    preamble = [
        f"Landed {when} on `{branch}`. Live plan: `{plan_rel}`.",
        "",
    ]
    archive_path.write_text("\n".join(preamble + body) + "\n", encoding="utf-8")

    pointer = f"{slice_id} shipped {when}; its specification is `{archive_rel}`."
    end = start + len(body)
    trailing_blank = body and body[-1].strip() == ""
    replacement = [pointer, ""] if trailing_blank else [pointer]
    new_lines = lines[:start] + replacement + lines[end:]

    # The open-slices table row, if the plan keeps one: mechanical, and the
    # slice.ps1 level lookup would otherwise still find the shipped row.
    row = re.compile(rf"^\|\s*{re.escape(slice_id)}\s*\|")
    new_lines = [line for line in new_lines if not row.match(line)]

    plan_path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
    return archive_path, text


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("id", help="the slice id, exactly as the queue writes it")
    parser.add_argument("--root", default=str(Path(__file__).resolve().parent.parent),
                        help="repository root (default: this checkout)")
    parser.add_argument("--base", default="master",
                        help="branch whose NEXTSTEPS.md names the plan and heading; "
                             "'' reads the working tree's copy")
    parser.add_argument("--date", default=date.today().isoformat(),
                        help="date in the archive file's name (default: today)")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    # Plans carry em dashes and curly quotes; a Windows console defaults to
    # cp1252, so ask for UTF-8 the way tools/heading.py does.
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8", errors="replace")

    status = _git(root, "status", "--porcelain", "--untracked-files=no")
    if status.returncode != 0:
        print(f"{root}: not a git working tree", file=sys.stderr)
        return 2
    if status.stdout.strip():
        print("working tree has uncommitted changes; commit or stash them first so "
              "`git checkout -- <plan>` can undo this move", file=sys.stderr)
        return 2

    resolved = resolve_item(queue_text(root, args.base), args.id)
    if resolved is None:
        print(f"{args.id}: no queue item with a `Plan: <file> -- \"<heading>\"` line "
              f"names it (looked on {args.base or 'the working tree'})", file=sys.stderr)
        return 1
    plan_rel, heading = resolved
    if not (root / plan_rel).is_file():
        print(f"{plan_rel}: not found", file=sys.stderr)
        return 1

    branch = _git(root, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip() or "?"
    archive_path, text = archive(root, args.id, plan_rel, heading, args.date, branch)
    print(f"archived: {archive_path.relative_to(root).as_posix()}")
    print(f"pointer:  {plan_rel} (was '{text}')")
    print("next:     update the plan's Status line, then python tools/refill_lane.py "
          f"--delete {args.id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
