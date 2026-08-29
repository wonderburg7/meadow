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


def check_next_steps(errors: list[str]) -> None:
    path = ROOT / "NEXTSTEPS.md"
    text = path.read_text(encoding="utf-8")
    match = re.search(r"^## Next up\s*$([\s\S]*?)(?=^## |\Z)", text, re.MULTILINE)
    if not match:
        errors.append("NEXTSTEPS.md: missing a '## Next up' section")
        return
    items = re.findall(r"^\d+\.\s+", match.group(1), re.MULTILINE)
    if len(items) != 3:
        errors.append(f"NEXTSTEPS.md: expected exactly 3 next-step items, found {len(items)}")


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
        rows.append((raw_path, (ROOT / raw_path).resolve()))
    return rows


def check_workstreams(errors: list[str]) -> None:
    """A worktree/branch is registered in plans/workstreams.md for exactly as long as it exists."""
    registered = git_worktree_paths()
    if registered is None:
        errors.append("could not run 'git worktree list' to validate plans/workstreams.md")
        return

    worktree_dir = (ROOT / ".worktrees").resolve()
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
