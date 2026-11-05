"""Open and close an ad-hoc worktree with its plans/workstreams.md row, atomically.

    python tools/worktree.py open --name <n> --branch <b> --lane <Review|Jules|Policy> \\
        --scope "<text>" --owner <Claude|Codex|Dave> --plan <path>
    python tools/worktree.py close --name <n> [--abandon]

`tools/slice.ps1 start` registers a claimed slice's worktree in the same
commit that creates it. Ad-hoc worktrees (Jules batches, reviews, policy
work) were made by hand, and the gap only surfaced at verify: the 4 Nov
Jules batch failed `tools/check_docs.py` on a policy worktree that Git knew
and the ledger did not. This tool does for ad-hoc work what `start` and
`finish` do for slices, in Python so it also runs in cloud sessions that
have no PowerShell.

Run it from the primary checkout on `master`, never from inside
`.worktrees/`: the ledger is edited only there (`plans/workstreams.md`
header). `open` creates `.worktrees/<n>` on a new branch from
`origin/master`, appends the row, commits and pushes. `close` refuses a
branch not merged into `origin/master` unless `--abandon`, then removes the
worktree, the local branch and the row, commits and pushes. A push that
fails is reported, not undone: the next push carries the commit.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LEDGER = "plans/workstreams.md"
LANES = ("Review", "Jules", "Policy")
OWNERS = ("Claude", "Codex", "Dave")
NAME = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]*")


class Stop(Exception):
    """A refusal: printed as `worktree <command> stopped: <reason>`, exit 1."""


def git(root: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True,
                            encoding="utf-8", errors="replace")
    if check and result.returncode != 0:
        raise Stop(f"git {' '.join(args)}: {result.stderr.strip() or result.stdout.strip()}")
    return result


def lane_trailer(root: Path, owner: str) -> str:
    """The co-author trailer `tools/slice.ps1` uses (`Get-LaneTrailer`), read from the script so the
    two never drift: its Codex line for Codex, its default line otherwise."""
    script = root / "tools" / "slice.ps1"
    text = script.read_text(encoding="utf-8") if script.exists() else ""
    found = re.search(r"function Get-LaneTrailer \{(.*?)\n\}", text, re.DOTALL)
    lines = re.findall(r'return "(Co-Authored-By: [^"]+)"', found[1]) if found else []
    if len(lines) < 2:
        raise Stop("could not read Get-LaneTrailer's two trailers from tools/slice.ps1")
    return lines[0] if owner == "Codex" else lines[-1]


def check_primary(root: Path) -> None:
    git_dir = Path(git(root, "rev-parse", "--absolute-git-dir").stdout.strip())
    common = git(root, "rev-parse", "--git-common-dir").stdout.strip()
    common_dir = (root / common).resolve() if not Path(common).is_absolute() else Path(common).resolve()
    if git_dir.resolve() != common_dir or ".worktrees" in root.resolve().parts:
        raise Stop("run it from the primary checkout, not from inside a worktree")
    branch = git(root, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
    if branch != "master":
        raise Stop(f"the primary checkout is on {branch}; switch it to master first")
    if git(root, "status", "--porcelain", "--", LEDGER).stdout.strip():
        raise Stop(f"{LEDGER} has uncommitted changes; commit or discard them first")
    git(root, "fetch", "--quiet", "origin", "master")
    if git(root, "merge-base", "--is-ancestor", "HEAD", "origin/master", check=False).returncode != 0 and \
            git(root, "merge-base", "--is-ancestor", "origin/master", "HEAD", check=False).returncode != 0:
        raise Stop("master and origin/master have diverged; pull first")
    if git(root, "merge-base", "--is-ancestor", "origin/master", "HEAD", check=False).returncode != 0:
        git(root, "merge", "--ff-only", "--quiet", "origin/master")


def ref_exists(root: Path, ref: str) -> bool:
    return git(root, "rev-parse", "--verify", "--quiet", ref, check=False).returncode == 0


def row_for(name: str, branch: str, lane: str, scope: str, owner: str, plan: str) -> str:
    return f"| `.worktrees/{name}` (`{branch}`) | {lane} | {scope} | {owner} | in progress | none | `{plan}` |"


def find_row(text: str, name: str) -> tuple[int, str] | None:
    """(line index, branch) of the row whose worktree is `.worktrees/<name>`."""
    pattern = re.compile(r"^\|\s*`\.worktrees/" + re.escape(name) + r"`\s*\(`([^`]+)`\)")
    for index, line in enumerate(text.split("\n")):
        found = pattern.match(line)
        if found:
            return index, found[1]
    return None


def commit_ledger(root: Path, message: str, owner: str) -> None:
    git(root, "add", "--", LEDGER)
    git(root, "commit", "--quiet", "-m", f"{message}\n\n{lane_trailer(root, owner)}", "--", LEDGER)


def push(root: Path, command: str) -> None:
    result = git(root, "push", "--quiet", "origin", "master", check=False)
    if result.returncode != 0:
        print(f"worktree {command}: could not push master ({result.stderr.strip()}); the next push carries it",
              file=sys.stderr)


def open_worktree(root: Path, args: argparse.Namespace) -> int:
    if not NAME.fullmatch(args.name):
        raise Stop(f"name {args.name!r} must be letters, digits, '.', '_' or '-'")
    if "|" in args.scope or "\n" in args.scope:
        raise Stop("scope must be one line without '|'")
    check_primary(root)
    path = root / ".worktrees" / args.name
    ledger = root / LEDGER
    text = ledger.read_text(encoding="utf-8")
    if path.exists() or find_row(text, args.name):
        raise Stop(f".worktrees/{args.name} already exists or has a row in {LEDGER}")
    if ref_exists(root, f"refs/heads/{args.branch}") or ref_exists(root, f"refs/remotes/origin/{args.branch}"):
        raise Stop(f"branch {args.branch} already exists (locally or on origin)")

    git(root, "worktree", "add", "--quiet", str(Path(".worktrees") / args.name), "-b", args.branch, "origin/master")
    try:
        row = row_for(args.name, args.branch, args.lane, args.scope, args.owner, args.plan)
        ledger.write_text(text + ("" if text.endswith("\n") else "\n") + row + "\n", encoding="utf-8")
        commit_ledger(root, f"Register the {args.name} worktree in the ledger", args.owner)
    except Stop:
        # Roll back so Git and the ledger never disagree.
        ledger.write_text(text, encoding="utf-8")
        git(root, "worktree", "remove", "--force", str(path), check=False)
        git(root, "branch", "-D", args.branch, check=False)
        raise
    push(root, "open")
    print(f"opened .worktrees/{args.name} on {args.branch} (from origin/master) and registered it in {LEDGER}")
    print(f"next: work in .worktrees/{args.name}; close with python tools/worktree.py close --name {args.name}")
    return 0


def close_worktree(root: Path, args: argparse.Namespace) -> int:
    check_primary(root)
    ledger = root / LEDGER
    text = ledger.read_text(encoding="utf-8")
    found = find_row(text, args.name)
    if not found:
        raise Stop(f"no row for .worktrees/{args.name} in {LEDGER}")
    index, branch = found
    if ref_exists(root, f"refs/heads/{branch}") and not args.abandon:
        if git(root, "merge-base", "--is-ancestor", branch, "origin/master", check=False).returncode != 0:
            raise Stop(f"{branch} is not merged into origin/master; merge it, or pass --abandon to discard it")
    path = root / ".worktrees" / args.name
    if path.exists():
        remove = ["worktree", "remove", str(path)] + (["--force"] if args.abandon else [])
        git(root, *remove)
    git(root, "worktree", "prune")
    if ref_exists(root, f"refs/heads/{branch}"):
        git(root, "branch", "-D" if args.abandon else "-d", branch)
    lines = text.split("\n")
    del lines[index]
    ledger.write_text("\n".join(lines), encoding="utf-8")
    verb = "Abandon" if args.abandon else "Close"
    owner = next((cell.strip() for cell in text.split("\n")[index].split("|")[4:5]), "Claude")
    commit_ledger(root, f"{verb} the {args.name} worktree in the ledger", owner)
    push(root, "close")
    print(f"closed .worktrees/{args.name}: worktree, local branch {branch} and its row removed")
    if ref_exists(root, f"refs/remotes/origin/{branch}"):
        print(f"note: origin/{branch} still exists; delete it once nothing needs it: git push origin --delete {branch}")
    return 0


def main(argv: list[str] | None = None, root: Path = ROOT) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    commands = parser.add_subparsers(dest="command", required=True)
    opener = commands.add_parser("open", help="create .worktrees/<name> on a new branch and register it")
    opener.add_argument("--name", required=True)
    opener.add_argument("--branch", required=True)
    opener.add_argument("--lane", required=True, choices=LANES)
    opener.add_argument("--scope", required=True)
    opener.add_argument("--owner", required=True, choices=OWNERS)
    opener.add_argument("--plan", required=True, help="repo-relative plan or record the work follows")
    closer = commands.add_parser("close", help="remove a merged worktree, its local branch and its row")
    closer.add_argument("--name", required=True)
    closer.add_argument("--abandon", action="store_true", help="close even if unmerged, discarding its changes")
    args = parser.parse_args(argv)
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")
    try:
        return open_worktree(root, args) if args.command == "open" else close_worktree(root, args)
    except Stop as stop:
        print(f"worktree {args.command} stopped: {stop}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
