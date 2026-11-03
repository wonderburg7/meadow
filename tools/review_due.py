"""Which of Dave's reviews has something to review, and where each one starts.

Each review's steps live in `plans/reference/reviews/<file>.md`, which opens
with a `Record key:` line (the stem of its dated record in `docs/`) and a
`Watches:` line (the paths whose change makes it due). Review contract rule 2
says a review starts from its last record, reviews only what changed since
that record's commit, and stops when nothing it owns has changed. Finding
that out by hand cost every review a file listing, a header read and a diff
before it learned whether it had anything to do -- and Dave could not see
which reviews were due without opening a session for each.

    python tools/review_due.py          one line per review, plus the check backlog
    python tools/review_due.py <key>    one review's starting point: its last
                                        record, the SINCE commit, and the watched
                                        files changed since

A review file's `Jules:` line says whether Google Jules runs it on its rota
(`plans/reference/jules-reviews.md`): `Jules: R-<name> | priority <n> | every
<d> days | min <c> commits`, or `Jules: no -- <reason>`. Both outputs say when
a Jules report for a review is waiting to be processed, because processing it
replaces the review's own sweep.
"""

from __future__ import annotations

import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROMPTS_DIR = Path("plans/reference/reviews")
RECORD_NAME = re.compile(r"^(?:docs/(?P<a>.+)-|plans/archive/(?P<b>.+)_)(?P<date>\d{4}-\d{2}-\d{2})\.md$")
REVIEWED = re.compile(r"^Reviewed:\s*([0-9a-f]{7,40})\b", re.MULTILINE)
DETAIL_FILE_LIMIT = 60
JULES_ROTA = re.compile(
    r"^(R-[a-z]+)\s*\|\s*priority\s+(\d+)\s*\|\s*every\s+(\d+)\s+days?\s*\|\s*min\s+(\d+)\s+commits?\s*$"
)


@dataclass
class JulesRota:
    id: str
    priority: int
    every_days: int
    min_commits: int


@dataclass
class Prompt:
    path: Path
    key: str | None
    watches: list[str]
    reasoning: str = "unstated"
    jules: JulesRota | None = None
    jules_note: str = "no Jules line"  # the line's text when Jules does not run it


def parse_jules(value: str) -> tuple[JulesRota | None, str]:
    """A `Jules:` line's value: the rota entry, or None and the reason it is not on the rota."""
    match = JULES_ROTA.match(value.strip())
    if match:
        return JulesRota(match.group(1), int(match.group(2)), int(match.group(3)), int(match.group(4))), ""
    if value.strip().lower().startswith("no"):
        return None, value.strip()
    return None, f"unreadable Jules line: {value.strip()}"


def parse_prompt(path: Path, text: str) -> Prompt:
    key = None
    watches: list[str] = []
    reasoning = "unstated"
    jules, jules_note = None, "no Jules line"
    for line in text.splitlines()[:8]:
        if line.startswith("Record key:"):
            value = line.split(":", 1)[1].strip().split()[0] if line.split(":", 1)[1].strip() else ""
            key = None if value in ("", "none") else value.strip("`")
        elif line.startswith("Watches:"):
            watches = line.split(":", 1)[1].split()
        elif line.startswith("Reasoning:"):
            reasoning = line.split(":", 1)[1].strip() or "unstated"
        elif line.startswith("Jules:"):
            jules, jules_note = parse_jules(line.split(":", 1)[1])
    return Prompt(path, key, watches, reasoning, jules, jules_note)


def waiting_jules_reports(root: Path = ROOT) -> dict[str, str]:
    """Rota id -> the unprocessed Jules review branch for it, from the remote refs as last fetched.
    Empty when the refs or the tool are unavailable: this is a hint, never a gate."""
    try:
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        import jules_preflight  # imported here: it imports this module

        return jules_preflight.waiting_reports(root)
    except Exception:  # noqa: BLE001 -- a missing remote must not stop the review list
        return {}


def load_prompts(root: Path = ROOT) -> list[Prompt]:
    return [
        parse_prompt(path.relative_to(root), path.read_text(encoding="utf-8"))
        for path in sorted((root / PROMPTS_DIR).glob("*.md"))
        if path.name != "README.md"
    ]


def missing_watches(prompts: list[Prompt], root: Path = ROOT) -> list[str]:
    """Watched paths that name nothing -- a moved file silently stops a review being due."""
    return [
        f"{prompt.path.as_posix()}: watches a path that does not exist: {watch}"
        for prompt in prompts
        for watch in prompt.watches
        if not (root / watch).exists()
    ]


def latest_record(key: str, tracked: list[str]) -> tuple[str, str] | None:
    """The newest `docs/<key>-<date>.md` (or archived `<key>_<date>.md`): (path, date)."""
    best: tuple[str, str] | None = None
    for name in tracked:
        match = RECORD_NAME.match(name)
        if not match or (match.group("a") or match.group("b")) != key:
            continue
        if best is None or match.group("date") > best[1]:
            best = (name, match.group("date"))
    return best


def reviewed_commit(text: str) -> str | None:
    match = REVIEWED.search(text)
    return match.group(1) if match else None


def git(*args: str, root: Path = ROOT) -> str:
    result = subprocess.run(
        ["git", *args], cwd=root, capture_output=True, text=True, encoding="utf-8"
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout


@dataclass
class Status:
    prompt: Prompt
    record: str | None = None
    date: str | None = None
    since: str | None = None
    commits: int = 0
    changed: list[str] | None = None
    problem: str | None = None


def status_of(prompt: Prompt, tracked: list[str], root: Path = ROOT) -> Status:
    status = Status(prompt)
    found = latest_record(prompt.key or "", tracked)
    if not found:
        status.problem = "no record yet -- first run"
        return status
    status.record, status.date = found
    status.since = reviewed_commit((root / status.record).read_text(encoding="utf-8"))
    if not status.since:
        status.problem = f"{status.record} has no 'Reviewed: <commit>' line"
        return status
    span = f"{status.since}..HEAD"
    try:
        status.changed = git("diff", "--name-only", span, "--", *prompt.watches, root=root).split()
        status.commits = int(git("rev-list", "--count", span, "--", *prompt.watches, root=root))
    except RuntimeError as error:
        status.problem = f"cannot diff from {status.since}: {error}"
    return status


def check_backlog(root: Path = ROOT) -> str:
    runners: dict[str, int] = {}
    for record in sorted((root / "checks" / "ready").glob("C-*.md")):
        match = re.search(r"^Runner:\s*(\w+)", record.read_text(encoding="utf-8"), re.MULTILINE)
        runner = match.group(1) if match else "unset"
        runners[runner] = runners.get(runner, 0) + 1
    total = sum(runners.values())
    detail = ", ".join(f"{count} {runner}" for runner, count in sorted(runners.items()))
    return f"hands-on checks waiting: {total}" + (f" ({detail})" if detail else "")


def summary(root: Path = ROOT) -> int:
    prompts = load_prompts(root)
    tracked = git("ls-files", "docs", "plans/archive", root=root).split()
    waiting = waiting_jules_reports(root)
    rows = []
    for prompt in prompts:
        if not prompt.watches:
            continue
        status = status_of(prompt, tracked, root)
        if status.problem:
            verdict, last, since = "first" if not status.record else "check", status.date or "-", status.problem
        else:
            verdict = "moved" if status.changed else "quiet"
            last = status.date or "-"
            since = f"{status.commits} commits, {len(status.changed or [])} files since {status.since}"
        if prompt.jules and prompt.jules.id in waiting:
            since += f"  [Jules report waiting: {waiting[prompt.jules.id]}]"
        rows.append((prompt.key or prompt.path.stem, prompt.reasoning, verdict, last, since))
    width = max(len(row[0]) for row in rows)
    for key, reasoning, verdict, last, since in rows:
        print(f"{key:<{width}}  {reasoning:<6}  {verdict:<5}  last {last:<10}  {since}")
    print(check_backlog(root))
    for problem in missing_watches(prompts, root):
        print(f"warning: {problem}")
    for prompt in prompts:
        if prompt.jules_note.startswith("unreadable"):
            print(f"warning: {prompt.path.as_posix()}: {prompt.jules_note}")
    if waiting:
        print('a waiting Jules report replaces that review\'s sweep: plans/reference/jules-reviews.md "Processing a Jules review"')
    print("one review's starting point: python tools/review_due.py <key>")
    return 0


def detail(key: str, root: Path = ROOT) -> int:
    prompts = {prompt.key: prompt for prompt in load_prompts(root) if prompt.key}
    if key not in prompts:
        print(f"unknown review key {key!r}; known: {', '.join(sorted(prompts))}")
        return 2
    prompt = prompts[key]
    status = status_of(prompt, git("ls-files", "docs", "plans/archive", root=root).split(), root)
    print(f"prompt:   {prompt.path.as_posix()} (reasoning: {prompt.reasoning})")
    print(f"record:   {status.record or 'none'}")
    if prompt.jules:
        branch = waiting_jules_reports(root).get(prompt.jules.id)
        print(
            f"jules:    {prompt.jules.id} report waiting on {branch} -- process it instead of sweeping"
            ' (plans/reference/jules-reviews.md "Processing a Jules review")'
            if branch
            else f"jules:    {prompt.jules.id} on the rota (priority {prompt.jules.priority}); no report waiting"
        )
    else:
        print(f"jules:    not on the Jules rota ({prompt.jules_note})")
    if status.problem:
        print(f"SINCE:    unknown -- {status.problem}")
        return 0
    print(f"SINCE:    {status.since} ({status.date})")
    changed = status.changed or []
    print(f"changed:  {status.commits} commits touch {len(changed)} watched files")
    for name in changed[:DETAIL_FILE_LIMIT]:
        print(f"  {name}")
    if len(changed) > DETAIL_FILE_LIMIT:
        print(f"  ... and {len(changed) - DETAIL_FILE_LIMIT} more (git diff --stat {status.since}..HEAD -- <path>)")
    if not changed:
        print("nothing this review watches has changed: audit the record's follow-through, then stop (contract rule 2)")
    return 0


def main(argv: list[str]) -> int:
    if len(argv) > 1 or (argv and argv[0] in ("-h", "--help")):
        print(__doc__)
        return 0 if argv and argv[0] in ("-h", "--help") else 2
    return detail(argv[0]) if argv else summary()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
