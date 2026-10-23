"""Tell Google Jules which of its tasks is free, and whether a path is safe to edit.

Jules works from GitHub on a Linux VM, so it cannot run `tools/slice.ps1
owner`. This is that check for Jules, read from `origin` alone:

    python tools/jules_preflight.py --next              # the first free task
    python tools/jules_preflight.py <path> [<path> ...] # free or owned

A path is owned when `NEXTSTEPS.md` or a live plan in `plans/now/` names it
on `origin/master` (a queued or planned slice will edit it), or when an
unmerged `origin/claude/*`, `origin/codex/*` or `origin/jules/*` branch
changes it. A Claude or Codex branch that was never pushed is invisible here;
`slice.ps1 owner` on their side sees Jules's branches, so the check holds
from both ends.

A task in `plans/reference/jules.md` is done when a commit on
`origin/master` has a message line starting `J-<n>:` (the pull request title)
or names a `jules/j-<n>-` branch; taken when an unmerged `origin/jules/j-<n>-*`
branch exists; blocked while a task in its `After:` line is not done.
`--next` prints the first task that is none of those and whose files are all
free. Exit 0 when every path is free or a task was found, 1 otherwise.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
BASE = "origin/master"
TASK_FILE = "plans/reference/jules.md"
PLANNED = ["NEXTSTEPS.md", "plans/now"]
BRANCH_PREFIXES = ("origin/claude/", "origin/codex/", "origin/jules/")
TASK_HEADING = re.compile(r"^###\s+(J-\d+)\s+--\s+(.*?)\s*$")


@dataclass
class Task:
    id: str
    title: str
    files: list[str] = field(default_factory=list)
    after: list[str] = field(default_factory=list)

    @property
    def branch_stem(self) -> str:
        return f"jules/{self.id.lower()}-"


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
    for line in text.splitlines():
        heading = TASK_HEADING.match(line)
        if heading:
            tasks.append(Task(heading.group(1), heading.group(2)))
            continue
        if not tasks:
            continue
        stripped = line.strip().lstrip("-* ").strip()
        if stripped.startswith("Files:"):
            # A file the task creates is written bare with "(new)": check_docs.py
            # fails a backticked path that does not exist yet.
            entries = stripped.removeprefix("Files:").split(",")
            tasks[-1].files = [entry.replace("(new)", "").strip().strip("`") for entry in entries if entry.strip()]
        elif stripped.startswith("After:"):
            tasks[-1].after = re.findall(r"J-\d+", stripped)
    return tasks


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


def owners(root: Path, paths: list[str], base: str = BASE) -> dict[str, list[str]]:
    """For each path, why it is owned: a planned mention or an unmerged branch. Empty means free."""
    found: dict[str, list[str]] = {path: [] for path in paths}
    for path in paths:
        found[path] += [f"named in {mention}" for mention in planned_mentions(root, path, base)]
    for branch in open_branches(root, base):
        changed = branch_files(root, branch, base)
        for path in paths:
            if path in changed:
                found[path].append(f"changed on unmerged {branch}")
    return found


def is_done(root: Path, task: Task, base: str = BASE) -> bool:
    pattern = f"(^{task.id}:|{task.branch_stem})"
    return bool(git(root, "log", base, "-E", "-i", f"--grep={pattern}", "--format=%h", "-1").strip())


def is_taken(root: Path, task: Task, base: str = BASE) -> bool:
    return any(name.startswith(f"origin/{task.branch_stem}") for name in open_branches(root, base))


def next_task(root: Path, tasks: list[Task], base: str = BASE) -> tuple[Task | None, list[str]]:
    """The first open, unblocked task whose files are free, and a line on each task passed over."""
    skipped: list[str] = []
    done = {task.id for task in tasks if is_done(root, task, base)}
    for task in tasks:
        if task.id in done:
            skipped.append(f"{task.id}: done")
        elif is_taken(root, task, base):
            skipped.append(f"{task.id}: taken by an open {task.branch_stem}* branch")
        elif [dep for dep in task.after if dep not in done]:
            skipped.append(f"{task.id}: waits for {', '.join(dep for dep in task.after if dep not in done)}")
        else:
            busy = {path: why for path, why in owners(root, task.files, base).items() if why}
            if not busy:
                return task, skipped
            skipped.append(f"{task.id}: {'; '.join(f'{path} {why[0]}' for path, why in busy.items())}")
    return None, skipped


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("paths", nargs="*", help="repo-relative paths to check")
    parser.add_argument("--next", action="store_true", help=f"print the first free task in {TASK_FILE}")
    parser.add_argument("--no-fetch", action="store_true", help="use the remote branches as last fetched")
    args = parser.parse_args(argv)
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8", errors="replace")
    if not args.next and not args.paths:
        parser.error("give --next or at least one path")

    if not args.no_fetch:
        fetch(ROOT)

    if args.next:
        text = git(ROOT, "show", f"{BASE}:{TASK_FILE}")
        task, skipped = next_task(ROOT, parse_tasks(text))
        for line in skipped:
            print(f"skip  {line}")
        if task is None:
            print("none  no numbered task is free: take a standing task (plans/reference/jules.md)")
            return 1
        print(f"next  {task.id} -- {task.title}")
        print(f"      branch: {task.branch_stem}<topic>   pull request title: {task.id}: <summary>")
        print(f"      files: {', '.join(task.files)}")
        return 0

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
