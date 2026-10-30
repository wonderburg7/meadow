"""Tell Google Jules which of its tasks is free, and whether a path is safe to edit.

Jules works from GitHub on a Linux VM, so it cannot run `tools/slice.ps1
owner`. This is that check for Jules, read from `origin` alone:

    python tools/jules_preflight.py --next              # the first free task (or due review), in full
    python tools/jules_preflight.py <path> [<path> ...] # free or owned
    python tools/jules_preflight.py --scope [J-n|R-x]   # files this branch changes outside the task
    python tools/jules_preflight.py --queue             # every task's and review's state, and how many are free
    python tools/jules_preflight.py --ledger            # every unmerged Jules branch: unreviewed, returned, closed

A path is owned when `NEXTSTEPS.md` or a live plan in `plans/now/` names it
on `origin/master` (a queued or planned slice will edit it), or when an
unmerged `origin/claude/*`, `origin/codex/*` or `origin/jules/*` branch
changes it. A Claude or Codex branch that was never pushed is invisible here;
`slice.ps1 owner` on their side sees Jules's branches, so the check holds
from both ends.

A task in `plans/reference/jules.md` is done when a commit on
`origin/master` has a message line starting `J-<n>:` (the pull request title)
or names a `jules/j-<n>-` branch; closed when the ledger closes it; taken when
an unmerged `origin/jules/j-<n>-*` branch exists that the ledger has not
processed; blocked while a task in its `After:` line is not done. `--next`
prints the first task that is none of those and whose files are all free,
with its Files/After/Why/Do lines so the rest of the task list need not be
read.

When no numbered task is free, `--next` prints the first due review of the
rota (`plans/reference/jules-reviews.md`): the review files in
`plans/reference/reviews/` whose `Jules:` line puts them on it, by priority.
A review is due when no unprocessed `jules/r-<name>-*` branch exists, its
last review (a dated record, or a ledger `closed` row) is at least its `every`
days old, and at least its `min` commits have touched its watched paths
since that record's `Reviewed:` commit. Exit 0 when every path is free or a
task or review was found, 1 otherwise.

The ledger (`plans/reference/jules-ledger.md`, kept by Claude and Codex) says
what happened to each Jules branch that was not merged as it stood: `merged`
(integrated another way), `returned` (not merged; the task is free again and
the row says what to correct) or `closed` (not merged and finished with:
its findings went elsewhere, or it was rejected). A branch with no row is
merged when its task has a `J-<n>:` line on master or every file it changes
already matches master, and otherwise unreviewed. `--ledger` lists them.

`--scope` lists what a pull request would change (`origin/master...ref`, the
view GitHub shows) and flags every changed file the task's `Files:` line does
not name. A Jules commit can carry a snapshot older than master (a task
started as a follow-up in a finished session, or master moving mid-task),
which shows as reverts of files nobody meant to touch: PR 4 (J-2 and J-3)
changed 19 files and its J-3 commit deleted J-2's own two. Each `off` line
says how to put the file back; Jules runs this before
stopping, Claude before merging (`--ref origin/jules/j-<n>-...`). Exit 1 on any
`off` line. `--queue` is for whoever refills the list: it prints each task's
state and exits 1 when fewer than `LOW_WATER` tasks are free.
"""

from __future__ import annotations

import argparse
import datetime
import fnmatch
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import review_due  # noqa: E402 -- the review files' header lines and record lookup


ROOT = Path(__file__).resolve().parent.parent
BASE = "origin/master"
TASK_FILE = "plans/reference/jules.md"
LEDGER_FILE = "plans/reference/jules-ledger.md"
REVIEWS_DIR = "plans/reference/reviews"
REPORT_DIR = "docs/jules-reviews"
REVIEW_METHOD = "plans/reference/jules-reviews.md"
PLANNED = ["NEXTSTEPS.md", "plans/now"]
BRANCH_PREFIXES = ("origin/claude/", "origin/codex/", "origin/jules/")
TASK_HEADING = re.compile(r"^###\s+(J-\d+)\s+--\s+(.*?)\s*$")
BRANCH_TASK = re.compile(r"jules/(j-\d+|r-[a-z]+)(?:-|$)", re.IGNORECASE)
LEDGER_STATES = ("merged", "returned", "closed")
LOW_WATER = 10  # free tasks below which the list needs a refill: a session may now take 20 (30 Oct 2026)


@dataclass
class Task:
    id: str
    title: str
    files: list[str] = field(default_factory=list)
    after: list[str] = field(default_factory=list)
    body: list[str] = field(default_factory=list)  # the block's lines under its heading, for --next

    @property
    def branch_stem(self) -> str:
        return f"jules/{self.id.lower()}-"


@dataclass
class LedgerRow:
    item: str
    branch: str
    state: str
    date: str
    by: str
    outcome: str


@dataclass
class Review:
    id: str
    key: str
    title: str
    path: str
    priority: int
    every_days: int
    min_commits: int
    watches: list[str]

    @property
    def report_pattern(self) -> str:
        return f"{REPORT_DIR}/{self.key}-*.md"


def git(root: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(
        ["git", "-C", str(root), *args], capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    if check and result.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)}: {result.stderr.strip()}")
    return result.stdout


def fetch(root: Path) -> None:
    """Fetch master and every branch, deepening a shallow clone so `base...branch` has a merge base."""
    args = ["fetch", "--quiet", "--prune", "origin", "+refs/heads/*:refs/remotes/origin/*"]
    if git(root, "rev-parse", "--is-shallow-repository").strip() == "true":
        args.insert(1, "--unshallow")
    git(root, *args)


def parse_tasks(text: str) -> list[Task]:
    """Every `### J-<n> -- title` block, with the paths of its `Files:` line and the ids of its `After:` line."""
    tasks: list[Task] = []
    open_block = False
    for line in text.splitlines():
        heading = TASK_HEADING.match(line)
        if heading:
            tasks.append(Task(heading.group(1), heading.group(2)))
            open_block = True
            continue
        if line.startswith("#"):
            open_block = False  # any other heading (Standing tasks, Not tasks yet) ends the last task
        if not tasks or not open_block:
            continue
        tasks[-1].body.append(line)
        stripped = line.strip().lstrip("-* ").strip()
        if stripped.startswith("Files:"):
            # A file the task creates is written bare with "(new)": check_docs.py
            # fails a backticked path that does not exist yet.
            entries = stripped.removeprefix("Files:").split(",")
            tasks[-1].files = [entry.replace("(new)", "").strip().strip("`") for entry in entries if entry.strip()]
        elif stripped.startswith("After:"):
            tasks[-1].after = re.findall(r"J-\d+", stripped)
    return tasks


# --- ledger ---


def parse_ledger(text: str) -> dict[str, LedgerRow]:
    """Each table row whose third cell is a ledger state, by branch name without `origin/`.
    A later row for the same branch replaces an earlier one."""
    rows: dict[str, LedgerRow] = {}
    for line in text.splitlines():
        if not line.lstrip().startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) < 6 or cells[2].lower() not in LEDGER_STATES:
            continue
        branch = cells[1].strip("`").removeprefix("origin/")
        rows[branch] = LedgerRow(cells[0], branch, cells[2].lower(), cells[3], cells[4], " | ".join(cells[5:]))
    return rows


def load_ledger(root: Path, base: str = BASE) -> dict[str, LedgerRow]:
    return parse_ledger(git(root, "show", f"{base}:{LEDGER_FILE}", check=False))


def ledger_notes(ledger: dict[str, LedgerRow], item: str) -> list[str]:
    """What the ledger says to correct, for each returned branch of this task or review."""
    return [
        f"returned {row.date} by {row.by} ({row.branch}): {row.outcome}"
        for row in ledger.values()
        if row.state == "returned" and row.item.upper() == item.upper()
    ]


def closed_items(ledger: dict[str, LedgerRow]) -> set[str]:
    return {row.item.upper() for row in ledger.values() if row.state == "closed"}


# --- ownership ---


def planned_mentions(root: Path, path: str, base: str = BASE) -> list[str]:
    """`file:line` for each line of the queue or a live plan on `base` that names `path`."""
    out = git(root, "grep", "-n", "-F", "-e", path, base, "--", *PLANNED, check=False)
    mentions = []
    for line in out.splitlines():
        name, number, _ = line.removeprefix(f"{base}:").split(":", 2)
        mentions.append(f"{name}:{number}")
    return mentions


def open_branches(root: Path, base: str = BASE) -> list[str]:
    current = git(root, "rev-parse", "--abbrev-ref", "HEAD", check=False).strip()
    names = git(root, "branch", "-r", "--no-merged", base, "--format=%(refname:short)").split()
    return [name for name in names if name.startswith(BRANCH_PREFIXES) and name != f"origin/{current}"]


def branch_files(root: Path, branch: str, base: str = BASE) -> set[str]:
    return set(git(root, "diff", "--name-only", f"{base}...{branch}").split())


def owners(
    root: Path, paths: list[str], base: str = BASE, ledger: dict[str, LedgerRow] | None = None
) -> dict[str, list[str]]:
    """For each path, why it is owned: a planned mention or an unmerged branch. Empty means free.
    A Jules branch the ledger has processed (returned or closed) owns nothing."""
    ledger = load_ledger(root, base) if ledger is None else ledger
    found: dict[str, list[str]] = {path: [] for path in paths}
    for path in paths:
        found[path] += [f"named in {mention}" for mention in planned_mentions(root, path, base)]
    for branch in open_branches(root, base):
        if not unprocessed(branch, ledger):
            continue
        changed = branch_files(root, branch, base)
        for path in paths:
            if path in changed:
                found[path].append(f"changed on unmerged {branch}")
    return found


# --- tasks ---


def has_done_line(root: Path, item: str, base: str = BASE) -> bool:
    pattern = f"(^{item}:|jules/{item.lower()}-)"
    return bool(git(root, "log", base, "-E", "-i", f"--grep={pattern}", "--format=%h", "-1").strip())


def is_done(root: Path, task: Task, base: str = BASE) -> bool:
    return has_done_line(root, task.id, base)


def unprocessed(name: str, ledger: dict[str, LedgerRow]) -> bool:
    return name.removeprefix("origin/") not in ledger


def is_taken(root: Path, task: Task, base: str = BASE, ledger: dict[str, LedgerRow] | None = None) -> bool:
    """An open branch for the task that the ledger has not processed (a returned or closed one takes nothing)."""
    ledger = load_ledger(root, base) if ledger is None else ledger
    return any(
        name.startswith(f"origin/{task.branch_stem}") and unprocessed(name, ledger) for name in open_branches(root, base)
    )


def classify(
    root: Path, tasks: list[Task], base: str = BASE, ledger: dict[str, LedgerRow] | None = None
) -> list[tuple[Task, str, str]]:
    """(task, state, reason) per task in order; state is done, closed, taken, waits, owned or free."""
    ledger = load_ledger(root, base) if ledger is None else ledger
    done = {task.id for task in tasks if is_done(root, task, base)}
    closed = closed_items(ledger)
    states: list[tuple[Task, str, str]] = []
    for task in tasks:
        if task.id in done:
            states.append((task, "done", "done"))
        elif task.id.upper() in closed:
            states.append((task, "closed", f"closed in {LEDGER_FILE}"))
        elif is_taken(root, task, base, ledger):
            states.append((task, "taken", f"taken by an open {task.branch_stem}* branch"))
        elif [dep for dep in task.after if dep not in done]:
            states.append((task, "waits", f"waits for {', '.join(dep for dep in task.after if dep not in done)}"))
        else:
            busy = {path: why for path, why in owners(root, task.files, base, ledger).items() if why}
            if busy:
                reason = "; ".join(f"{path} {why[0]}" for path, why in busy.items())
                states.append((task, "owned", reason))
            else:
                states.append((task, "free", "free"))
    return states


def next_task(
    root: Path, tasks: list[Task], base: str = BASE, ledger: dict[str, LedgerRow] | None = None
) -> tuple[Task | None, list[str]]:
    """The first open, unblocked task whose files are free, and a line on each task passed over."""
    skipped: list[str] = []
    for task, state, reason in classify(root, tasks, base, ledger):
        if state == "free":
            return task, skipped
        skipped.append(f"{task.id}: {reason}")
    return None, skipped


def task_for_ref(root: Path, ref: str) -> str | None:
    """The task or review id a branch name carries (`jules/j-4-...` is J-4, `jules/r-save-...` R-SAVE), or None."""
    name = ref if ref != "HEAD" else git(root, "rev-parse", "--abbrev-ref", "HEAD", check=False).strip()
    found = BRANCH_TASK.search(name)
    return found.group(1).upper() if found else None


# --- review rota ---


def parse_reviews(root: Path, base: str = BASE) -> list[Review]:
    """Every review file on `base` whose `Jules:` line puts it on the rota, highest priority first."""
    reviews: list[Review] = []
    for name in sorted(git(root, "ls-tree", "--name-only", f"{base}:{REVIEWS_DIR}", check=False).split()):
        if not name.endswith(".md") or name == "README.md":
            continue
        path = f"{REVIEWS_DIR}/{name}"
        text = git(root, "show", f"{base}:{path}", check=False)
        prompt = review_due.parse_prompt(Path(path), text)
        if not prompt.jules or not prompt.key:
            continue
        title = next((line[2:].strip() for line in text.splitlines() if line.startswith("# ")), prompt.key)
        rota = prompt.jules
        reviews.append(
            Review(rota.id, prompt.key, title, path, rota.priority, rota.every_days, rota.min_commits, prompt.watches)
        )
    return sorted(reviews, key=lambda review: (review.priority, review.id))


def review_branch(review_id: str, name: str) -> bool:
    stem = f"origin/jules/{review_id.lower()}"
    return name == stem or name.startswith(f"{stem}-")


def waiting_reports(root: Path = ROOT, base: str = BASE) -> dict[str, str]:
    """Rota id -> an unmerged `jules/r-<name>-*` branch the ledger has not processed (its report awaits Claude or Codex)."""
    ledger = load_ledger(root, base)
    found: dict[str, str] = {}
    for name in open_branches(root, base):
        item = task_for_ref(root, name)
        if item and item.startswith("R-") and unprocessed(name, ledger) and not matches_base(root, name, base):
            found.setdefault(f"R-{item[2:].lower()}", name.removeprefix("origin/"))
    return found


def review_state(
    root: Path,
    review: Review,
    base: str = BASE,
    today: datetime.date | None = None,
    ledger: dict[str, LedgerRow] | None = None,
) -> tuple[str, str]:
    """(state, reason): taken (a report waits), rests (reviewed within `every` days), quiet (too few commits) or due."""
    today = today or datetime.date.today()
    ledger = load_ledger(root, base) if ledger is None else ledger
    waiting = [
        name
        for name in open_branches(root, base)
        if review_branch(review.id, name) and unprocessed(name, ledger) and not matches_base(root, name, base)
    ]
    if waiting:
        return "taken", f"report waiting on {waiting[0].removeprefix('origin/')} for Claude or Codex to process"
    tracked = git(root, "ls-tree", "-r", "--name-only", base, "--", "docs", "plans/archive").split()
    record = review_due.latest_record(review.key, tracked)
    dates = [record[1]] if record else []
    dates += [row.date for row in ledger.values() if row.state == "closed" and row.item.upper() == review.id.upper()]
    if dates:
        last = max(dates)
        due_on = datetime.date.fromisoformat(last) + datetime.timedelta(days=review.every_days)
        if today < due_on:
            return "rests", f"last reviewed {last}; due again {due_on.isoformat()}"
    if not record:
        return "due", "first run: no record yet"
    since = review_due.reviewed_commit(git(root, "show", f"{base}:{record[0]}", check=False))
    if not since:
        return "due", f"{record[0]} has no Reviewed: commit; review everything it owns"
    count = git(root, "rev-list", "--count", f"{since}..{base}", "--", *review.watches, check=False).strip()
    commits = int(count) if count.isdigit() else review.min_commits
    if commits < review.min_commits:
        return "quiet", f"{commits} commits on its watched paths since {since}; it needs {review.min_commits}"
    return "due", f"{commits} commits on its watched paths since {since} ({record[0]})"


def next_review(
    root: Path, base: str = BASE, today: datetime.date | None = None, ledger: dict[str, LedgerRow] | None = None
) -> tuple[Review | None, str, list[str]]:
    """The highest-priority due review and why it is due, and a line on each review passed over."""
    ledger = load_ledger(root, base) if ledger is None else ledger
    skipped: list[str] = []
    for review in parse_reviews(root, base):
        state, reason = review_state(root, review, base, today, ledger)
        if state == "due":
            return review, reason, skipped
        skipped.append(f"{review.id}: {state} -- {reason}")
    return None, "", skipped


def review_block(review: Review, reason: str, notes: list[str]) -> list[str]:
    lines = [
        f"next  {review.id} -- {review.title}",
        f"      branch: jules/{review.id.lower()}-<topic>   pull request title: {review.id}: <one-line verdict>",
        f"      why now: {reason}",
        f"      report: {REPORT_DIR}/{review.key}-<YYYY-MM-DD>.md, the only file you add",
        f"      steps:  {review.path}; its \"If Jules runs this\" section wins where they differ",
        f"      start:  python tools/review_due.py {review.key}   (SINCE and the watched files changed since)",
        f"      method: python tools/heading.py {REVIEW_METHOD} \"Running a review\"",
    ]
    return lines + [f"      {note}" for note in notes]


# --- branches the ledger accounts for ---


def matches_base(root: Path, branch: str, base: str = BASE) -> bool:
    """Every file the branch changes already reads the same on `base` (it was taken by file checkout)."""
    files = sorted(branch_files(root, branch, base))
    return not files or not git(root, "diff", "--name-only", base, branch, "--", *files).strip()


def jules_branches(root: Path, ledger: dict[str, LedgerRow], base: str = BASE) -> list[tuple[str, str, str]]:
    """(branch, state, detail) for every unmerged `origin/jules/*` branch."""
    out: list[tuple[str, str, str]] = []
    for ref in open_branches(root, base):
        if not ref.startswith("origin/jules/"):
            continue
        name = ref.removeprefix("origin/")
        row = ledger.get(name)
        if row:
            out.append((name, row.state, f"{row.item}, {row.date} by {row.by}: {row.outcome}"))
            continue
        item = task_for_ref(root, ref) or ""
        if item.startswith("J-") and has_done_line(root, item, base):
            out.append((name, "merged", f"{item} has a line on {base}"))
        elif matches_base(root, ref, base):
            out.append((name, "merged", f"every file it changes already matches {base}"))
        else:
            subject = git(root, "log", "-1", "--format=%cs %s", ref).strip()
            out.append((name, "unreviewed", subject))
    return out


def ledger_report(root: Path, base: str = BASE) -> list[str]:
    branches = jules_branches(root, load_ledger(root, base), base)
    lines = [
        f"{state:<10} {name} -- {detail}"
        for wanted in ("unreviewed", "returned", "closed")
        for name, state, detail in branches
        if state == wanted
    ]
    counts = {state: sum(1 for _, found, _ in branches if found == state) for state in ("unreviewed", *LEDGER_STATES)}
    lines.append("total      " + ", ".join(f"{count} {state}" for state, count in counts.items()))
    if counts["unreviewed"]:
        lines.append(f"next       process the unreviewed ones, then add a row each to {LEDGER_FILE}")
    return lines


# --- scope ---


def is_pattern(path: str) -> bool:
    return any(char in path for char in "*?[")


def scope_report(root: Path, task: Task, ref: str = "HEAD", base: str = BASE) -> list[str]:
    """One line per file whose content differs between `base` and `ref`: `ok` if the task names it, else `off`
    with the command that puts it back. A two-dot tree diff, so a stale snapshot shows as the reverts it is."""
    lines: list[str] = []
    for entry in git(root, "diff", "--name-status", "--no-renames", f"{base}...{ref}").splitlines():
        status, path = entry.split("\t", 1)
        if any(fnmatch.fnmatchcase(path, named) for named in task.files):
            lines.append(f"ok    {status} {path}")
        elif status == "A":
            lines.append(f"off   {status} {path} -- not in Files; delete it: git rm -f {path}")
        else:
            lines.append(f"off   {status} {path} -- not in Files; restore it: git checkout {base} -- {path}")
    plain = {path for path in task.files if not is_pattern(path)}
    untouched = sorted(plain - {line.split()[2] for line in lines})
    lines += [f"note  {path} -- named in Files but unchanged" for path in untouched]
    return lines


def scope_task(root: Path, wanted: str, base: str = BASE) -> Task | None:
    """The task, or for a review the report it may add, that `--scope` checks a branch against."""
    if wanted.startswith("R-"):
        review = next((item for item in parse_reviews(root, base) if item.id.upper() == wanted), None)
        return Task(review.id, review.title, files=[review.report_pattern]) if review else None
    tasks = parse_tasks(git(root, "show", f"{base}:{TASK_FILE}"))
    return next((item for item in tasks if item.id == wanted), None)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("paths", nargs="*", help="repo-relative paths to check")
    parser.add_argument("--next", action="store_true", help=f"print the first free task in {TASK_FILE}, else a due review")
    parser.add_argument("--queue", action="store_true", help="print every task's state; exit 1 when the list is short")
    parser.add_argument("--ledger", action="store_true", help="list unmerged Jules branches by what happened to them")
    parser.add_argument(
        "--scope",
        nargs="?",
        const="",
        metavar="J-n",
        help="list files --ref changes outside the task's Files (default task: from the branch name)",
    )
    parser.add_argument("--ref", default="HEAD", help="commit or branch --scope compares with origin/master")
    parser.add_argument("--no-fetch", action="store_true", help="use the remote branches as last fetched")
    args = parser.parse_args(argv)
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8", errors="replace")
    if not (args.next or args.queue or args.ledger or args.scope is not None or args.paths):
        parser.error("give --next, --queue, --ledger, --scope or at least one path")

    if not args.no_fetch:
        fetch(ROOT)

    if args.scope is not None:
        wanted = (args.scope or task_for_ref(ROOT, args.ref) or "").upper()
        task = scope_task(ROOT, wanted)
        if task is None:
            print(f"stop  no task {wanted or '(none in the branch name)'} on {BASE}: name it, as --scope J-n")
            return 1
        report = scope_report(ROOT, task, args.ref)
        print(f"scope {task.id} -- {task.title}")
        print("\n".join(report) if report else "      no file differs from " + BASE)
        return 1 if any(line.startswith("off") for line in report) else 0

    if args.ledger:
        print("\n".join(ledger_report(ROOT)))
        return 0

    tasks = parse_tasks(git(ROOT, "show", f"{BASE}:{TASK_FILE}")) if (args.next or args.queue) else []
    ledger = load_ledger(ROOT)

    if args.queue:
        states = classify(ROOT, tasks, ledger=ledger)
        for task, state, reason in states:
            if state not in ("done", "closed"):
                print(f"{state:<5} {task.id} -- {task.title}" + ("" if state == "free" else f" ({reason})"))
        for review in parse_reviews(ROOT):
            state, reason = review_state(ROOT, review, ledger=ledger)
            print(f"{state:<5} {review.id} -- {review.title} ({reason})")
        unreviewed = sum(1 for _, state, _ in jules_branches(ROOT, ledger) if state == "unreviewed")
        if unreviewed:
            print(f"review {unreviewed} unreviewed Jules branches: python tools/jules_preflight.py --ledger")
        open_tasks = [state for _, state, _ in states if state not in ("done", "closed")]
        free = open_tasks.count("free")
        print(f"free  {free} of {len(open_tasks)} open tasks")
        if free < LOW_WATER:
            print(f"short fewer than {LOW_WATER} free: refill the list (plans/reference/jules.md, \"Keeping this list\")")
            return 1
        return 0

    if args.next:
        task, skipped = next_task(ROOT, tasks, ledger=ledger)
        for line in skipped:
            print(f"skip  {line}")
        if task is not None:
            print(f"next  {task.id} -- {task.title}")
            print(f"      branch: {task.branch_stem}<topic>   pull request title: {task.id}: <summary>")
            print("\n".join(line.rstrip() for line in task.body).strip("\n"))
            for note in ledger_notes(ledger, task.id):
                print(f"- Correct: {note}")
            return 0
        review, reason, passed = next_review(ROOT, ledger=ledger)
        for line in passed:
            print(f"skip  {line}")
        if review is not None:
            print("\n".join(review_block(review, reason, ledger_notes(ledger, review.id))))
            return 0
        print("none  no numbered task is free and no review is due: take a standing task (plans/reference/jules.md)")
        return 1

    busy = False
    for path, why in owners(ROOT, args.paths).items():
        if why:
            busy = True
            print(f"owned {path} -- " + "; ".join(why))
        else:
            print(f"free  {path}")
    return 1 if busy else 0


if __name__ == "__main__":
    raise SystemExit(main())
