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

`--confirm C-<n> [C-<n> ...]` is the other half: when Dave reports a pass,
it moves each ready record into that archive under today's hands-on-pass
heading, deletes the record, regenerates `checks/ready.md`, and lists the
live plans and queue lines that still mention the id -- the work a pass may
have unblocked. The same denial made this a shell edit to a file the agent
could not read, paid on every processed batch.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from datetime import date
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


def record_text(check_id: int, name: str, owner: str, runner: str) -> str:
    """The exact shape check_docs.py::check_checks accepts: one '# C-<n> -- <name>'
    heading, one PASS: line, one Owner: line naming a plan that exists. The
    Runner: line tells a check pass who runs it
    (`plans/reference/check-runner.md`, "Choosing a runner")."""
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
        f"Runner: {runner}\n"
        "\n"
        f"Owner: `{owner}`\n"
    )


ARCHIVE_REL = "docs/archive/HANDS_ON_CHECKS_ARCHIVE.md"
RUNNERS = ("haiku", "sonnet", "opus", "dave")


def parse_check_id(raw: str) -> int:
    """'C-42', 'c-42' or '42' -> 42."""
    match = re.fullmatch(r"(?:[Cc]-)?(\d+)", raw.strip().rstrip(","))
    if not match:
        raise ValueError(f"not a check id: {raw} -- use C-<n>")
    return int(match.group(1))


MONTHS = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")


def day_label(today: date) -> str:
    """'9 Sep 2026' -- the archive's date style, whatever the machine's locale."""
    return f"{today.day} {MONTHS[today.month - 1]} {today.year}"


def pass_heading(today: date) -> str:
    """The archive's heading for one day's pass, in the form its older sections use."""
    return f"## {day_label(today)} -- Dave's hands-on pass"


def insert_entries(archive_text: str, heading: str, block: str) -> str:
    """Put `block` under `heading`, newest pass first.

    If today's pass is already the top section (a second batch the same day),
    the entries join its end; otherwise a new section goes above the first."""
    sections = re.split(r"(?m)^(?=## )", archive_text)
    preamble, passes = sections[0], sections[1:]
    if passes and passes[0].split("\n", 1)[0].strip() == heading:
        passes[0] = passes[0].rstrip("\n") + "\n\n" + block + "\n\n"
    else:
        passes.insert(0, heading + "\n\n" + block + "\n\n")
    return (preamble.rstrip("\n") + "\n\n" + "".join(passes)).rstrip("\n") + "\n"


def confirm_checks(
    root: Path, check_ids: list[int], today: date, note: str | None = None
) -> list[Path]:
    """Archive each ready record under today's pass heading, then delete it.

    All-or-nothing: every id is validated before anything is written, and the
    archive is written before any record is deleted. Returns the deleted paths."""
    archive = root / ARCHIVE_REL
    if not archive.is_file():
        raise ValueError(f"{ARCHIVE_REL} is missing")
    records = []
    for check_id in dict.fromkeys(check_ids):
        path = root / "checks" / "ready" / f"C-{check_id}.md"
        if not path.is_file():
            raise ValueError(
                f"C-{check_id} has no record in checks/ready/ -- only a ready check can be "
                "confirmed; a blocked one moves back to checks/ready/ first"
            )
        records.append(path)

    entries = []
    for path in records:
        text = path.read_text(encoding="utf-8").strip()
        # A ready record is headed '# C-<n> -- ...'; in the archive it sits
        # one level under the pass heading, as '### C-<n> -- ...'.
        entry = "##" + text if text.startswith("# ") else text
        if note:
            entry += f"\n\nConfirmed {day_label(today)}: {note.strip()}"
        entries.append(entry)

    text = archive.read_text(encoding="utf-8")
    archive.write_text(
        insert_entries(text, pass_heading(today), "\n\n".join(entries)), encoding="utf-8"
    )
    for path in records:
        path.unlink()
    return records


def still_mentioned(root: Path, check_ids: list[int]) -> list[str]:
    """Live lines that still name a confirmed id: work the pass may have released."""
    pattern = re.compile(r"\bC-(?:" + "|".join(str(n) for n in check_ids) + r")\b")
    files = [root / "NEXTSTEPS.md", root / "checks" / "blocked.md"]
    for layer in ("now", "active", "design", "reference"):
        files.extend(sorted((root / "plans" / layer).glob("*.md")))
    hits = []
    for path in files:
        if not path.is_file():
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if pattern.search(line):
                hits.append(f"{path.relative_to(root).as_posix()}:{number}: {line.strip()[:160]}")
    return hits


def confirm_main(raw_ids: list[str], note: str | None) -> int:
    try:
        check_ids = [parse_check_id(raw) for raw in raw_ids]
        removed = confirm_checks(ROOT, check_ids, date.today(), note)
    except ValueError as error:
        print(error, file=sys.stderr)
        return 1
    for path in removed:
        print(f"{path.stem} archived to {ARCHIVE_REL}")
    # check_docs.py owns the index's format, so regenerate it rather than edit it.
    index = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "check_docs.py"), "--write-ready-index"], cwd=ROOT
    )
    if index.returncode != 0:
        print(
            "checks/ready.md was not regenerated -- run python tools/check_docs.py --write-ready-index",
            file=sys.stderr,
        )
        return 1
    hits = still_mentioned(ROOT, check_ids)
    if hits:
        print("Still named here -- release any work these checks were holding back:")
        for hit in hits:
            print(f"  {hit}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--name", help="short name after the id in the heading")
    parser.add_argument(
        "--owner",
        help="repository-relative path of the plan that owns the check, e.g. plans/now/ui.md",
    )
    parser.add_argument(
        "--runner",
        choices=RUNNERS,
        help="who runs it in a check pass: a haiku, sonnet or opus check-runner subagent, or dave "
        "when only his keyboard or eye can judge it (plans/reference/check-runner.md)",
    )
    parser.add_argument(
        "--id", type=int, default=None, help="force a specific number instead of the next free one"
    )
    parser.add_argument(
        "--confirm",
        nargs="+",
        metavar="C-<n>",
        help="archive these ready checks as passed, instead of filing a new one",
    )
    parser.add_argument(
        "--note", help="with --confirm: one line recorded under each archived entry"
    )
    args = parser.parse_args()

    if args.confirm:
        if args.name or args.owner or args.runner or args.id is not None:
            parser.error("--confirm cannot be combined with --name, --owner, --runner or --id")
        return confirm_main(args.confirm, args.note)
    if args.note:
        parser.error("--note only goes with --confirm")
    if not args.name or not args.owner or not args.runner:
        parser.error("--name, --owner and --runner are required to file a check")

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
    path.write_text(record_text(check_id, args.name.strip(), owner, args.runner), encoding="utf-8")

    # The path, so the caller can open it and fill the three placeholders;
    # the id, because that is what Dave replies with.
    print(f"C-{check_id}  {path.relative_to(ROOT).as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
