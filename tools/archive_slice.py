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

    python tools/archive_slice.py --complete-plans

archives every live plan (plans/now/, active/, design/, reference/) that
check_docs' terminal-plan rule rejects -- the plan a closeout leaves behind
with "Next: None -- plan complete" once it has archived the plan's last slice
(CB-2, T-3, V-4 and ST-1 each did). It `git mv`s the plan to
plans/archive/<name>_<date>.md, sets its Status to complete, repoints every
tracked Markdown file that names the old path (an archived slice record's
`Live plan:` line gains "(archived)"), stages all of it and prints one
`touched: <path>` line per file for the caller to commit. It keeps a plan
live, and says why, while NEXTSTEPS.md or plans/workstreams.md still cite it
-- the queue item and ledger row `finish` removes first -- or while a file it
would touch has uncommitted changes. `tools/slice.ps1 finish` runs it after
the merge, once the ledger row is gone. NEXTSTEPS.md holds a plan live only
through a queue item or an id-led "Not in the queue" bullet; a prose mention
is repointed. A `plans/README.md` routing row whose Read cell is the plan is
dropped, not repointed: the table routes to live work only.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from check_docs import current_plans, plan_is_terminal, queue_item_chunks  # noqa: E402
from heading import headings, section  # noqa: E402

# The heading may hold escaped quotes (`-- "RR-2 -- \"Saves...\" works"`);
# resolve_item unescapes them (RR-2, 11 Oct 2026).
PLAN_LINE = re.compile(r"- Plan: `([^`]+)` -- \"((?:[^\"\\]|\\.)+)\"")


def _git(root: Path, *args: str) -> subprocess.CompletedProcess:
    # Decoded as UTF-8 explicitly: the queue carries em dashes, and a text
    # pipe on Windows would otherwise decode `git show` as cp1252, mangling
    # the heading this tool then fails to find.
    return subprocess.run(["git", "-C", str(root), *args], capture_output=True,
                          text=True, encoding="utf-8", errors="replace")


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
        return plan.group(1), re.sub(r"\\(.)", r"\1", plan.group(2))
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


# The files that cite a plan while its work is in flight: the queue item and
# the worktree ledger row. Both must go before the plan moves, or the move
# leaves check_docs a dangling backticked path.
IN_FLIGHT_CITERS = ("NEXTSTEPS.md", "plans/workstreams.md")
QUEUE_FILE = "NEXTSTEPS.md"
ROUTING_FILE = "plans/README.md"
ID_LED_BULLET = re.compile(r"^-\s+\*\*(.+?)\*\*(.*)$", re.MULTILINE)
SLICE_ID_TOKEN = re.compile(r"\b[A-Z][A-Za-z0-9]*-[A-Za-z0-9]+\b")
STATUS_FIELD = re.compile(r"^Status:\s*([^|\n]*)", re.MULTILINE)


def _citing_files(root: Path, plan_rel: str) -> list[str]:
    """Tracked Markdown files, other than the plan itself, that name `plan_rel`."""
    found = _git(root, "grep", "-l", "-F", plan_rel, "--", "*.md")
    return sorted(line.strip() for line in found.stdout.splitlines()
                  if line.strip() and line.strip() != plan_rel)


def _queue_holds(root: Path, plan_rel: str) -> bool:
    """True while NEXTSTEPS.md has work in flight on `plan_rel`.

    That is a queue item naming it, or a bullet whose bolded lead names a
    slice id (a deferred slice). Any other mention is a pointer in prose and
    is repointed like any other citer: on 8 and 16 Oct 2026 one such pointer
    kept a finished plan live, and the next closeout's primary verify failed
    on check_docs' terminal-plan rule.
    """
    text = (root / QUEUE_FILE).read_text(encoding="utf-8")
    if any(plan_rel in chunk for _, chunk in queue_item_chunks(text) or []):
        return True
    return any(SLICE_ID_TOKEN.search(bullet.group(1)) and plan_rel in bullet.group(0)
               for bullet in ID_LED_BULLET.finditer(text))


def _drop_routing_rows(body: str, plan_rel: str) -> str:
    """plans/README.md without the routing rows whose Read cell is `plan_rel`.

    Repointing them left a row per finished plan aimed into plans/archive/:
    16 of 30 rows by 15 Oct 2026, each plan review cutting them by hand. A row
    that only mentions the plan in its first cell is repointed as before.
    """
    row = re.compile(rf"^\|[^\n]*\|[ \t]*`{re.escape(plan_rel)}`[^|\n]*\|[ \t]*\n", re.MULTILINE)
    return row.sub("", body)


def archive_plan(root: Path, plan: Path, when: str) -> tuple[list[str], str]:
    """Move one terminal plan into plans/archive/: (touched paths, why it was kept)."""
    plan_rel = plan.relative_to(root).as_posix()
    archive_rel = f"plans/archive/{plan.stem}_{when}.md"
    if (root / archive_rel).exists():
        return [], f"{archive_rel} already exists"
    citing = _citing_files(root, plan_rel)
    in_flight = [path for path in citing if path in IN_FLIGHT_CITERS
                 and (path != QUEUE_FILE or _queue_holds(root, plan_rel))]
    if in_flight:
        return [], f"{' and '.join(in_flight)} still cite it; the queue item and ledger row go first"
    dirty = _git(root, "status", "--porcelain", "--", plan_rel, *citing).stdout.strip()
    if dirty:
        return [], f"files it would touch have uncommitted changes:\n{dirty}"

    (root / "plans" / "archive").mkdir(parents=True, exist_ok=True)
    moved = _git(root, "mv", plan_rel, archive_rel)
    if moved.returncode != 0:
        return [], f"git mv failed: {moved.stderr.strip()}"
    archive_path = root / archive_rel
    text = archive_path.read_text(encoding="utf-8")
    # "Status: active | ... | Next: None -- plan complete" is terminal by the
    # rule, but its first field still says active; the archived copy says so.
    status = STATUS_FIELD.search(text)
    if status and not plan_is_terminal(f"Status: {status.group(1)}"):
        text = text[:status.start(1)] + "complete " + text[status.end(1):]
        archive_path.write_text(text, encoding="utf-8")

    live_line = re.compile(rf"Live plan: `{re.escape(plan_rel)}`(?! \(archived\))")
    for rel in citing:
        path = root / rel
        body = live_line.sub(f"Live plan: `{archive_rel}` (archived)", path.read_text(encoding="utf-8"))
        if rel == ROUTING_FILE:
            body = _drop_routing_rows(body, plan_rel)
        path.write_text(body.replace(plan_rel, archive_rel), encoding="utf-8")
    _git(root, "add", "--", archive_rel, *citing)
    return [plan_rel, archive_rel, *citing], ""


def archive_complete_plans(root: Path, when: str) -> int:
    """Archive every terminal live plan; 1 if any had to be kept live."""
    kept = 0
    for plan in current_plans(root):
        if not plan_is_terminal(plan.read_text(encoding="utf-8")):
            continue
        plan_rel = plan.relative_to(root).as_posix()
        touched, reason = archive_plan(root, plan, when)
        if reason:
            kept += 1
            print(f"plan kept live: {plan_rel} -- {reason}", file=sys.stderr)
            continue
        print(f"plan archived: {plan_rel} -> {touched[1]}")
        for rel in touched:
            print(f"touched: {rel}")
    return 1 if kept else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("id", nargs="?", help="the slice id, exactly as the queue writes it")
    parser.add_argument("--complete-plans", action="store_true",
                        help="instead of a slice, archive every live plan whose Status is terminal")
    parser.add_argument("--root", default=str(Path(__file__).resolve().parent.parent),
                        help="repository root (default: this checkout)")
    parser.add_argument("--base", default="master",
                        help="branch whose NEXTSTEPS.md names the plan and heading; "
                             "'' reads the working tree's copy")
    parser.add_argument("--date", default=date.today().isoformat(),
                        help="date in the archive file's name (default: today)")
    args = parser.parse_args()
    if bool(args.id) == args.complete_plans:
        parser.error("give a slice id or --complete-plans, not both")
    root = Path(args.root).resolve()
    # Plans carry em dashes and curly quotes; a Windows console defaults to
    # cp1252, so ask for UTF-8 the way tools/heading.py does.
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8", errors="replace")
    if args.complete_plans:
        return archive_complete_plans(root, args.date)

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
    print("next:     update the plan's Status line (after its last slice, Next: None -- "
          "plan complete; finish archives the plan itself after the merge), then "
          f"python tools/refill_lane.py --delete {args.id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
