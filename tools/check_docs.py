"""Cheap checks for Meadow's current planning/documentation entry points."""

from __future__ import annotations

from datetime import date
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parent.parent
PLAN_PATTERN = re.compile(r"^Status:\s*(.+)$", re.MULTILINE)
REQUIRED_STATUS_FIELDS = ("owner:", "next:", "dependency:", "verified:")
TERMINAL_STATES = ("complete", "completed", "archived", "abandoned", "retired")
MD_LINK_PATTERN = re.compile(r"(?<!!)\[[^]]*\]\(([^)]+)\)")


def current_plans() -> list[Path]:
    return sorted(ROOT.glob("*_PLAN.md"))


def check_plan_metadata(errors: list[str], warnings: list[str]) -> None:
    for plan in current_plans():
        text = plan.read_text(encoding="utf-8")
        first_lines = "\n".join(text.splitlines()[:8])
        match = PLAN_PATTERN.search(first_lines)
        if not match:
            errors.append(f"{plan.name}: active root plan has no Status line in its first 8 lines")
            continue

        status = match.group(1).lower()
        metadata = first_lines.lower()
        if any(state in status for state in TERMINAL_STATES):
            errors.append(f"{plan.name}: terminal plan belongs in docs/archive, not the root")

        missing = [field[:-1].title() for field in REQUIRED_STATUS_FIELDS if field not in metadata]
        if missing:
            errors.append(f"{plan.name}: Status line is missing {', '.join(missing)}")

        verified = re.search(r"verified:\s*(\d{4}-\d{2}-\d{2})", metadata)
        if not verified:
            continue
        try:
            verified_on = date.fromisoformat(verified.group(1))
        except ValueError:
            errors.append(f"{plan.name}: Verified must use YYYY-MM-DD")
            continue
        age = (date.today() - verified_on).days
        if age > 28:
            warnings.append(f"{plan.name}: verification date is {age} days old")
        elif age < 0:
            warnings.append(f"{plan.name}: verification date is in the future")


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
    files = list(ROOT.glob("*.md")) + list((ROOT / "docs").glob("*.md"))
    for path in files:
        text = path.read_text(encoding="utf-8")
        for raw_target in MD_LINK_PATTERN.findall(text):
            target = raw_target.strip().split("#", 1)[0].strip()
            if not target or "://" in target or target.startswith("mailto:"):
                continue
            if not (path.parent / target).resolve().is_file():
                errors.append(f"{path.relative_to(ROOT)}: broken Markdown link: {raw_target}")


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    check_plan_metadata(errors, warnings)
    check_next_steps(errors)
    check_markdown_links(errors)

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
