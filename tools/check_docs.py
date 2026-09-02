"""Cheap checks for Meadow's current planning/documentation entry points."""

from __future__ import annotations

from datetime import date
from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent
PLAN_PATTERN = re.compile(r"^Status:\s*(.+)$", re.MULTILINE)
REQUIRED_STATUS_FIELDS = ("owner:", "next:", "dependency:", "verified:")
TERMINAL_STATES = ("complete", "completed", "archived", "abandoned", "retired")
MD_LINK_PATTERN = re.compile(r"(?<!!)\[[^]]*\]\(([^)]+)\)")


def current_plans() -> list[Path]:
    """Return the small, routable plan layers; history is intentionally excluded."""
    layers = ("now", "active", "design", "reference")
    return sorted(
        path
        for layer in layers
        for path in (ROOT / "plans" / layer).glob("*.md")
    )


def check_plan_metadata(errors: list[str], warnings: list[str]) -> None:
    for plan in current_plans():
        text = plan.read_text(encoding="utf-8")
        first_lines = "\n".join(text.splitlines()[:8])
        match = PLAN_PATTERN.search(first_lines)
        if not match:
            errors.append(f"{plan.relative_to(ROOT)}: active plan has no Status line in its first 8 lines")
            continue

        status = match.group(1).lower()
        metadata = first_lines.lower()
        if any(state in status for state in TERMINAL_STATES):
            errors.append(f"{plan.relative_to(ROOT)}: terminal plan belongs in plans/archive, not a live layer")

        missing = [field[:-1].title() for field in REQUIRED_STATUS_FIELDS if field not in metadata]
        if missing:
            errors.append(f"{plan.relative_to(ROOT)}: Status line is missing {', '.join(missing)}")

        verified = re.search(r"verified:\s*(\d{4}-\d{2}-\d{2})", metadata)
        if not verified:
            continue
        try:
            verified_on = date.fromisoformat(verified.group(1))
        except ValueError:
            errors.append(f"{plan.relative_to(ROOT)}: Verified must use YYYY-MM-DD")
            continue
        age = (date.today() - verified_on).days
        if age > 28:
            warnings.append(f"{plan.relative_to(ROOT)}: verification date is {age} days old")
        elif age < 0:
            warnings.append(f"{plan.relative_to(ROOT)}: verification date is in the future")


def check_context_layout(errors: list[str]) -> None:
    legacy_root_plans = sorted(ROOT.glob("*_PLAN.md"))
    if legacy_root_plans:
        names = ", ".join(path.name for path in legacy_root_plans)
        errors.append(f"root planning files must move under plans/: {names}")
    if (ROOT / "CHATGPT_NEXTSTEPS.md").exists():
        errors.append("CHATGPT_NEXTSTEPS.md is retired; use the shared NEXTSTEPS.md and plans/")


QUEUE_SIZE = 5
LANES = ("Claude", "Codex")
REQUIRED_ITEM_FIELDS = ("Plan:", "Files:", "Check:", "Next after:")
NOT_READY_PHRASES = (
    "blocked on",
    "needs dave",
    "needs a live",
    "needs its own live",
    "awaiting dave",
    "hands-on confirmation first",
    "before any code is written",
)
PATH_TOKEN = re.compile(r"`([^`]+)`")


def _item_files(body: str) -> set[str]:
    """Paths named on an item's Files: line, so two lanes can be proved disjoint."""
    match = re.search(r"^\s*-\s*Files:\s*([\s\S]*?)(?=^\s*-\s[A-Z]|\Z)", body, re.MULTILINE)
    if not match:
        return set()
    return {
        token.strip()
        for token in PATH_TOKEN.findall(match.group(1))
        if "/" in token
    }


def check_next_steps(errors: list[str]) -> None:
    """The queue is exactly QUEUE_SIZE ready slices, in two lanes that cannot collide."""
    path = ROOT / "NEXTSTEPS.md"
    text = path.read_text(encoding="utf-8")
    match = re.search(r"^## Next up\s*$([\s\S]*?)(?=^## |\Z)", text, re.MULTILINE)
    if not match:
        errors.append("NEXTSTEPS.md: missing a '## Next up' section")
        return
    section = match.group(1)

    chunks = re.split(r"^\d+\.\s+", section, flags=re.MULTILINE)[1:]
    if len(chunks) != QUEUE_SIZE:
        errors.append(
            f"NEXTSTEPS.md: expected exactly {QUEUE_SIZE} next-step items, found {len(chunks)}"
        )

    lane_order: list[tuple[str, str]] = []
    for index, chunk in enumerate(chunks, start=1):
        lane_match = re.match(r"\*\*\[(\w+)\]", chunk)
        if not lane_match or lane_match.group(1) not in LANES:
            errors.append(
                f"NEXTSTEPS.md item {index}: must open with a lane tag, one of "
                + ", ".join(f"**[{lane}]" for lane in LANES)
            )
            continue
        lane_order.append((lane_match.group(1), chunk))

        missing = [field for field in REQUIRED_ITEM_FIELDS if f"- {field}" not in chunk]
        if missing:
            errors.append(
                f"NEXTSTEPS.md item {index}: missing {', '.join(field.rstrip(':') for field in missing)}"
            )

    lanes_present = {lane for lane, _ in lane_order}
    for lane in LANES:
        if lane not in lanes_present:
            errors.append(f"NEXTSTEPS.md: no [{lane}] item -- both lanes must have work to run in parallel")

    # Only ready work belongs here; anything waiting on Dave lives under "Not in the queue".
    lowered = section.lower()
    for phrase in NOT_READY_PHRASES:
        if phrase in lowered:
            errors.append(
                f"NEXTSTEPS.md: '{phrase}' appears in the queue -- work waiting on Dave "
                "belongs under '## Not in the queue, and why', not '## Next up'"
            )

    # The two lanes run at the same time, so their leading items must not share a file.
    heads = {}
    for lane, chunk in lane_order:
        heads.setdefault(lane, _item_files(chunk))
    if len(heads) == len(LANES):
        first, second = (heads[lane] for lane in LANES)
        shared = first & second
        if shared:
            errors.append(
                "NEXTSTEPS.md: the leading items in each lane share "
                + ", ".join(sorted(shared))
                + " -- reorder the lanes so simultaneous work cannot collide"
            )


def check_markdown_links(errors: list[str]) -> None:
    files = (
        list(ROOT.glob("*.md"))
        + list((ROOT / "docs").glob("*.md"))
        + list((ROOT / "plans").glob("*.md"))
        + [
            path
            for layer in ("now", "active", "design", "reference")
            for path in (ROOT / "plans" / layer).glob("*.md")
        ]
        + list((ROOT / "checks").glob("*.md"))
    )
    for path in files:
        text = path.read_text(encoding="utf-8")
        for raw_target in MD_LINK_PATTERN.findall(text):
            target = raw_target.strip().split("#", 1)[0].strip()
            if not target or "://" in target or target.startswith("mailto:"):
                continue
            if not (path.parent / target).resolve().is_file():
                errors.append(f"{path.relative_to(ROOT)}: broken Markdown link: {raw_target}")


def git_worktree_paths() -> set[Path] | None:
    """Resolved paths of every worktree Git currently knows about, or None if git is unavailable."""
    try:
        result = subprocess.run(
            ["git", "worktree", "list", "--porcelain"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    paths: set[Path] = set()
    for line in result.stdout.splitlines():
        if line.startswith("worktree "):
            paths.add(Path(line[len("worktree "):]).resolve())
    return paths


def primary_checkout() -> Path:
    """The main checkout's root, which is what a `.worktrees/x` path in the
    ledger is relative to.

    Not the same as ROOT when this runs inside a worktree: there, ROOT is the
    worktree itself, and resolving `.worktrees/x` against it looks for a
    nested copy that has never existed, so every ledger row read as stale and
    verify.ps1 could not pass from the branch it was checking."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--git-common-dir"],
            cwd=ROOT, capture_output=True, text=True, check=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return ROOT
    return (ROOT / result.stdout.strip()).resolve().parent


def ledger_worktree_rows() -> list[tuple[str, Path]]:
    """(raw path as written, resolved path) for each data row in plans/workstreams.md."""
    ledger = ROOT / "plans" / "workstreams.md"
    if not ledger.exists():
        return []
    rows: list[tuple[str, Path]] = []
    for line in ledger.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        cells = line.split("|")
        if len(cells) < 2:
            continue
        match = re.search(r"`([^`]+)`", cells[1])
        if not match:
            continue
        raw_path = match.group(1)
        rows.append((raw_path, (primary_checkout() / raw_path).resolve()))
    return rows


def check_workstreams(errors: list[str]) -> None:
    """A worktree/branch is registered in plans/workstreams.md for exactly as long as it exists."""
    registered = git_worktree_paths()
    if registered is None:
        errors.append("could not run 'git worktree list' to validate plans/workstreams.md")
        return

    worktree_dir = (primary_checkout() / ".worktrees").resolve()
    if worktree_dir.is_dir():
        for entry in sorted(worktree_dir.iterdir()):
            if entry.is_dir() and entry.resolve() not in registered:
                errors.append(
                    f".worktrees/{entry.name}: orphaned directory, not registered with 'git worktree' -- remove it"
                )

    ledger_rows = ledger_worktree_rows()
    for raw_path, resolved in ledger_rows:
        if resolved not in registered:
            errors.append(f"plans/workstreams.md: stale row, worktree no longer exists: {raw_path}")

    ledger_paths = {resolved for _, resolved in ledger_rows}
    for wt_path in registered:
        try:
            wt_path.relative_to(worktree_dir)
        except ValueError:
            continue
        if wt_path not in ledger_paths:
            errors.append(f"plans/workstreams.md: worktree {wt_path} is registered with Git but has no ledger row")


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    check_plan_metadata(errors, warnings)
    check_context_layout(errors)
    check_next_steps(errors)
    check_markdown_links(errors)
    check_workstreams(errors)

    for warning in warnings:
        print(f"WARNING: {warning}")
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    if errors:
        return 1
    print("Documentation checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
