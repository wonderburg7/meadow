"""One admission test for a queue item, shared by check_docs, start and closeout (L-33).

    python tools/admission.py L-34            # one item
    python tools/admission.py --all           # every queued item
    python tools/admission.py --all --json
    python tools/admission.py --clear-landed L-33

An item is `admissible` only when all four tests pass, else `blocked: <reason>`:

1. every dependency it names is archived or merged (a dependency is an id in
   its `## Not in the queue, and why` bullet or its plan section's `**Gate.**`
   paragraph, unless that clause says it landed or shipped);
2. no file in `Files:` is in the other lane, or in an unmerged branch -- local
   branches, and the open `origin/jules/*` branches `slice.ps1 owner` fetches;
3. its plan section's `**Open decisions:**` line is `none` (a missing line is a
   warning, so plans written before L-33 still pass);
4. every path in `Files:` exists, or sits in a folder that does so (a missing
   `Plan:` file is a warning: the slice may be about to write it).

`FUNCTION_MAP.md`, `checks/ready.md` and `plans/workstreams.md` are unowned
(Dave, 23 Oct 2026): `finish` restores master's copy and the closeout on master
regenerates them, so none counts toward ownership.

`--clear-landed <id>` is the post-merge half: it drops that id from other
items' gates and `## Not in the queue` reasons, and rewrites `plans/now/`
references to a plan that has since been archived. A reason that still names
the id afterwards (it waited for nothing else) is reported as `ambiguous:`,
not rewritten, for the queue steward's `gates` job.

`--queue-only` skips the unmerged-branch scan. `slice.ps1 start` uses it: the
checkout holds dozens of stale session branches, and the scan is for ad-hoc
work and `admission.py <id>` runs.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import backlog  # noqa: E402
import check_docs  # noqa: E402

UNOWNED = ("FUNCTION_MAP.md", "checks/ready.md", "plans/workstreams.md")
SLICE_ID = re.compile(r"\b[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*-\d+[a-z]?\b")
NOT_IN_QUEUE = re.compile(
    r"^## Not in the queue, and why\s*$([\s\S]*?)(?=^## |\Z)", re.MULTILINE
)
BULLET = re.compile(r"^-\s+\*\*(?P<lead>.+?)\*\*(?P<rest>.*)$", re.MULTILINE)
PLAN_LINE = re.compile(r"^\s*-\s*Plan:\s*`([^`]+)`(?:\s*--\s*\"(.+?)\")?", re.MULTILINE)
OPEN_DECISIONS = re.compile(r"\*\*Open decisions:?\*\*:?\s*(.*)")
GATE_PARAGRAPH = re.compile(r"^\*\*Gate\.\*\*([\s\S]*?)(?=^\s*$|\Z)", re.MULTILINE)
LANDED = re.compile(r"\b(?:landed|shipped)\b", re.IGNORECASE)


@dataclass
class Item:
    slice_id: str
    lane: str
    body: str
    queued: bool

    @property
    def files(self) -> set[str]:
        return check_docs._item_files(self.body)

    @property
    def plan(self) -> tuple[str, str]:
        match = PLAN_LINE.search(self.body)
        return (match.group(1), match.group(2) or "") if match else ("", "")


@dataclass
class Verdict:
    slice_id: str
    reasons: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    @property
    def admissible(self) -> bool:
        return not self.reasons

    def line(self) -> str:
        if self.admissible:
            return "admissible"
        return "blocked: " + "; ".join(self.reasons)


def is_unowned(path: str) -> bool:
    return path.replace("\\", "/").strip() in UNOWNED


def owns(owned: str, wanted: str) -> bool:
    """slice.ps1's Test-OwnedPath: same file, or one is a folder holding the other."""
    a = owned.replace("\\", "/").strip()
    b = wanted.replace("\\", "/").strip()
    if a == b:
        return True
    return (a.endswith("/") and b.startswith(a)) or (b.endswith("/") and a.startswith(b))


def shared_paths(mine: set[str], theirs: set[str]) -> list[str]:
    return sorted(
        path for path in mine
        if not is_unowned(path) and any(owns(other, path) for other in theirs)
    )


def queue_items(text: str) -> list[Item]:
    items = []
    for lane_heading, chunk in check_docs.queue_item_chunks(text) or []:
        match = re.match(r"\*\*\[(\w+)\]\s+([\w.-]+)\s+--", chunk)
        if match:
            items.append(Item(match.group(2), lane_heading or match.group(1), chunk, True))
    return items


def find_item(text: str, root: Path, slice_id: str) -> Item | None:
    for item in queue_items(text):
        if item.slice_id == slice_id:
            return item
    check_docs.ROOT = root
    entries, _ = backlog.collect(check_docs.current_plans(root), root)
    for entry in entries:
        if entry.slice_id == slice_id:
            return Item(entry.slice_id, entry.lane, entry.body, False)
    return None


def deferral_reason(text: str, slice_id: str) -> str:
    section = NOT_IN_QUEUE.search(text)
    if not section:
        return ""
    for bullet in BULLET.finditer(section.group(1)):
        if re.search(rf"(?<![\w.-]){re.escape(slice_id)}(?![\w.-])", bullet.group("lead")):
            return bullet.group("rest")
    return ""


def plan_section(root: Path, plan: str, heading: str) -> str:
    path = root / plan
    if not plan or not path.is_file():
        return ""
    body = path.read_text(encoding="utf-8")
    if not heading:
        return body
    start = re.search(rf"^##+\s+{re.escape(heading)}\s*$", body, re.MULTILINE)
    if not start:
        return ""
    end = re.search(r"^## ", body[start.end():], re.MULTILINE)
    return body[start.start():start.end() + end.start()] if end else body[start.start():]


def dependency_ids(text: str, item: Item, section: str) -> list[str]:
    """Ids this item waits for, minus those whose clause says they landed."""
    clauses = [deferral_reason(text, item.slice_id)]
    clauses += [match.group(1) for match in GATE_PARAGRAPH.finditer(section)]
    found: list[str] = []
    for clause in clauses:
        for match in SLICE_ID.finditer(clause):
            tail = re.split(r"[.;]", clause[match.end():], maxsplit=1)[0]
            dep = match.group(0)
            if dep != item.slice_id and not LANDED.search(tail) and dep not in found:
                found.append(dep)
    return found


def is_landed(root: Path, dep: str, merged: set[str]) -> bool:
    if dep in merged:
        return True
    return any((root / "plans" / "archive").glob(f"{dep}_*.md"))


def git_lines(root: Path, *args: str) -> list[str]:
    try:
        run = subprocess.run(["git", "-C", str(root), *args], capture_output=True,
                             text=True, check=False)
    except OSError:
        return []
    if run.returncode != 0:
        return []
    return [line.strip() for line in run.stdout.splitlines() if line.strip()]


def merged_ids(root: Path) -> set[str]:
    """Branch leaf names already merged to master (`claude/L-33` -> `L-33`)."""
    return {name.rsplit("/", 1)[-1] for name in git_lines(
        root, "branch", "--merged", "master", "--format=%(refname:short)")}


def unmerged_branch_files(root: Path, skip: set[str]) -> dict[str, set[str]]:
    """Files changed by every unmerged local branch and open origin/jules/* branch."""
    changed: dict[str, set[str]] = {}
    sources = [
        ("master", ["branch", "--no-merged", "master", "--format=%(refname:short)"]),
        ("origin/master", ["branch", "-r", "--no-merged", "origin/master", "--list",
                           "origin/jules/*", "--format=%(refname:short)"]),
    ]
    for base, args in sources:
        for branch in git_lines(root, *args):
            if branch in skip or branch.rsplit("/", 1)[-1] in skip:
                continue
            changed[branch] = set(git_lines(root, "diff", "--name-only", f"{base}...{branch}"))
    return changed


def check_item(text: str, root: Path, item: Item, *, branches: dict[str, set[str]] | None = None,
               merged: set[str] | None = None) -> Verdict:
    """The four tests. `branches` is None to skip the branch scan."""
    verdict = Verdict(item.slice_id)
    plan, heading = item.plan
    section = plan_section(root, plan, heading)

    for dep in dependency_ids(text, item, section):
        if not is_landed(root, dep, merged or set()):
            verdict.reasons.append(f"waits for {dep}, which has not landed")

    for other in queue_items(text):
        if other.lane == item.lane or other.slice_id == item.slice_id:
            continue
        shared = shared_paths(item.files, other.files)
        if shared:
            verdict.reasons.append(f"the {other.lane} lane's {other.slice_id} owns {', '.join(shared)}")
    for branch, changed in (branches or {}).items():
        shared = shared_paths(item.files, changed)
        if shared:
            verdict.reasons.append(f"unmerged branch {branch} changes {', '.join(shared)}")

    if section:
        decisions = OPEN_DECISIONS.search(section)
        if not decisions:
            verdict.warnings.append(f"{plan}: no 'Open decisions:' line")
        elif decisions.group(1).strip().rstrip(".").lower() != "none":
            verdict.reasons.append(f"open decision: {decisions.group(1).strip()}")

    if plan and not (root / plan).is_file():
        verdict.warnings.append(f"plan {plan} does not exist")
    for path in sorted(item.files):
        target = root / path
        if not target.exists() and not target.parent.is_dir():
            verdict.reasons.append(f"{path} does not exist and neither does its folder")
    return verdict


def lane_conflicts(text: str, lane: str, files: set[str]) -> list[str]:
    """Files of `files` that the other lane's queued items own (refill_lane's test)."""
    owned: set[str] = set()
    for item in queue_items(text):
        if item.lane != lane:
            owned |= item.files
    return shared_paths(files, owned)


# --- --clear-landed ---------------------------------------------------------

def archived_plan_for(root: Path, plan_rel: str) -> str | None:
    """`plans/archive/<NAME>_<date>.md` for a plans/now/ plan that has moved."""
    stem = Path(plan_rel).stem.upper().replace("-", "_")
    archive = root / "plans" / "archive"
    matches = sorted(archive.glob(f"{stem}_*.md")) if archive.is_dir() else []
    return matches[-1].relative_to(root).as_posix() if matches else None


def _drop_id(reason: str, slice_id: str) -> str:
    """Remove `slice_id` from a list of ids in a gate clause."""
    token = re.escape(slice_id)
    reason = re.sub(rf",\s*(?:and\s+)?{token}\b", "", reason)
    reason = re.sub(rf"\b{token}\s*,\s*", "", reason)
    reason = re.sub(rf"\b(\w+)\s+and\s+{token}\b", r"\1", reason)
    return re.sub(rf"\band\s+{token}\s+", "", reason)


def clear_landed(text: str, slice_id: str) -> tuple[str, list[str]]:
    """`text` with `slice_id` dropped from lists of gates; plus lines left to the steward."""
    section = NOT_IN_QUEUE.search(text)
    notes: list[str] = []
    if not section:
        return text, notes
    mention = re.compile(rf"(?<![\w.-]){re.escape(slice_id)}(?![\w.-])")

    def rewrite(match: re.Match) -> str:
        line = match.group(0)
        if mention.search(match.group("lead")):
            return line
        rest = match.group("rest")
        if not mention.search(rest):
            return line
        new_rest = _drop_id(rest, slice_id)
        if mention.search(new_rest):
            notes.append(f"{match.group('lead')}: still names {slice_id}; the gates job rewrites it")
            return line
        return f"- **{match.group('lead')}**{new_rest}"

    body = BULLET.sub(rewrite, section.group(1))
    return text[:section.start(1)] + body + text[section.end(1):], notes


def rewrite_archived_refs(root: Path) -> list[str]:
    """Point `plans/now/<plan>.md` references at the archive once that plan has moved."""
    changed: list[str] = []
    pattern = re.compile(r"plans/now/[\w.-]+\.md")
    docs = [root / "NEXTSTEPS.md", *check_docs.current_plans(root)]
    for path in docs:
        if not path.is_file():
            continue
        original = path.read_text(encoding="utf-8")

        def swap(match: re.Match) -> str:
            ref = match.group(0)
            if (root / ref).exists():
                return ref
            return archived_plan_for(root, ref) or ref

        updated = pattern.sub(swap, original)
        if updated != original:
            path.write_text(updated, encoding="utf-8", newline="")
            changed.append(path.relative_to(root).as_posix())
    return changed


def run_clear_landed(root: Path, slice_id: str) -> int:
    path = root / "NEXTSTEPS.md"
    text = path.read_text(encoding="utf-8")
    updated, notes = clear_landed(text, slice_id)
    if updated != text:
        path.write_text(updated, encoding="utf-8", newline="")
        print("touched: NEXTSTEPS.md")
    for ref in rewrite_archived_refs(root):
        print(f"touched: {ref}")
    for note in notes:
        print(f"ambiguous: {note}")
    return 0


# --- command line -----------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("slice_id", nargs="?")
    parser.add_argument("--all", action="store_true", help="every queued item")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--queue-only", action="store_true",
                        help="skip the unmerged-branch scan")
    parser.add_argument("--clear-landed", metavar="ID")
    parser.add_argument("--root", type=Path, default=check_docs.ROOT)
    args = parser.parse_args(argv)
    root = args.root
    check_docs.ROOT = root

    if args.clear_landed:
        return run_clear_landed(root, args.clear_landed)
    text = (root / "NEXTSTEPS.md").read_text(encoding="utf-8")
    if args.all:
        items = queue_items(text)
    elif args.slice_id:
        found = find_item(text, root, args.slice_id)
        if not found:
            print(f"{args.slice_id}: not in the queue or a plan's queue block", file=sys.stderr)
            return 2
        items = [found]
    else:
        parser.error("give a slice id, --all or --clear-landed")

    merged = merged_ids(root)
    skip = {item.slice_id for item in items} | set(git_lines(root, "branch", "--show-current"))
    branches = None if args.queue_only else unmerged_branch_files(root, skip)
    verdicts = [check_item(text, root, item, branches=branches, merged=merged) for item in items]
    if args.json:
        print(json.dumps([{"id": v.slice_id, "status": v.line(), "admissible": v.admissible,
                           "warnings": v.warnings} for v in verdicts]))
    else:
        for verdict in verdicts:
            print(f"{verdict.slice_id}: {verdict.line()}")
            for warning in verdict.warnings:
                print(f"  warning: {warning}")
    return 0 if all(v.admissible for v in verdicts) else 1


if __name__ == "__main__":
    raise SystemExit(main())
