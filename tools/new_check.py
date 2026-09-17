"""Allocate the next free hands-on-check id and write its record skeleton.

Filing a check by hand costs a directory listing, a scan for the highest id
in use, and a recall of the format `tools/check_docs.py::check_checks`
enforces -- every slice that files one pays it again. None of that needs a
model.

The id search reads `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md` as well as the
live files. That archive is deliberately hidden from an agent's own file
tools (`.claude/settings.json` denies `Read(./docs/archive/**)`), so a
session allocating an id by hand sees only the live records and can reuse an
id that a confirmed check already spent. A script has no such restriction,
which is the whole reason this is a script.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
READY_DIR = ROOT / "checks" / "ready"
# Every place a C-<n> id can have been spent. The archive is included so a
# retired id is never handed out again -- check_docs.py's uniqueness rule
# only sees the first two.
ID_SOURCES = (
    READY_DIR,
    ROOT / "checks" / "blocked.md",
    ROOT / "docs" / "archive" / "HANDS_ON_CHECKS_ARCHIVE.md",
)
CHECK_ID = re.compile(r"\bC-(\d+)\b")


def used_ids() -> set[int]:
    """Every C-<n> number mentioned anywhere a check lives, live or archived."""
    used: set[int] = set()
    for source in ID_SOURCES:
        files = sorted(source.glob("C-*.md")) if source.is_dir() else [source]
        for path in files:
            try:
                text = path.read_text(encoding="utf-8")
            except OSError:
                continue
            used.update(int(n) for n in CHECK_ID.findall(text))
            used.update(int(n) for n in CHECK_ID.findall(path.name))
    return used


def next_free_id() -> int:
    used = used_ids()
    return max(used) + 1 if used else 1


def record_text(check_id: int, name: str, owner: str) -> str:
    """The exact shape check_docs.py::check_checks accepts: one '# C-<n> -- <name>'
    heading, one PASS: line, one Owner: line naming a plan that exists."""
    return (
        f"# C-{check_id} -- {name}\n"
        "\n"
        "What this checks: <what Dave does, and where: the screen, the setting,\n"
        "the control. Plain language -- say how to reach it, not what the code\n"
        "does. One or two sentences.>\n"
        "\n"
        "PASS: <the single condition, on this one line>\n"
        "\n"
        "If it fails, <what a failure would change -- the value, the file, or the\n"
        "slice it reopens. A check whose failure changes nothing does not belong\n"
        "here.>\n"
        "\n"
        f"Owner: `{owner}`\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--name", required=True, help="short name after the id in the heading")
    parser.add_argument(
        "--owner",
        required=True,
        help="repository-relative path of the plan that owns the check, e.g. plans/now/ui.md",
    )
    parser.add_argument(
        "--id", type=int, default=None, help="force a specific number instead of the next free one"
    )
    args = parser.parse_args()

    owner = args.owner.replace("\\", "/").strip().strip("`")
    if not (ROOT / owner).is_file():
        print(f"owner plan does not exist: {owner}", file=sys.stderr)
        return 1

    check_id = args.id if args.id is not None else next_free_id()
    if args.id is not None and args.id in used_ids():
        print(f"C-{args.id} is already in use -- ids are never reused", file=sys.stderr)
        return 1

    READY_DIR.mkdir(parents=True, exist_ok=True)
    path = READY_DIR / f"C-{check_id}.md"
    if path.exists():
        print(f"{path.relative_to(ROOT)} already exists", file=sys.stderr)
        return 1
    path.write_text(record_text(check_id, args.name.strip(), owner), encoding="utf-8")

    # The path, so the caller can open it and fill the three placeholders;
    # the id, because that is what Dave replies with.
    print(f"C-{check_id}  {path.relative_to(ROOT).as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
