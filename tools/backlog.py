"""The backlog `NEXTSTEPS.md` refills itself from: queue blocks in live plans.

An open slice section in a live plan may carry one fenced block holding the
exact lines that slice would be queued with::

    ```queue
    **[Claude] L-12 -- a plan's slice section carries its queue lines**
    - Plan: `plans/now/agent-lifecycle.md` -- "L-12 — ..."
    - Files: `tools/check_docs.py`
    - Check: ...
    - Proof: `absent: tools/check_docs.py :: check_plan_queue_blocks`
    - Next after: L-13 -- closeout is one command.
    ```

The body is byte-for-byte a `## Next up` item minus its number, so refilling a
lane is a copy rather than five lines rewritten from prose at closeout -- which
is where the refill gate usually stopped one. It is also where the `Proof:`
line gets written: one validated when the plan is written cannot be improvised
three days later against code that has moved, which is how X3 was queued after
it had shipped.

``queue-gated`` instead of ``queue`` marks a slice that is specified but not
admissible yet. It stays out of the lanes, and out of every count of what the
backlog can offer, until whoever clears the gate changes the fence.

This module only reads. `tools/refill_lane.py` writes the queue and
`tools/check_docs.py` proves a block and its live queue entry agree.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

# The fence, its body, and where in the file it starts. `queue-gated` is the
# same block with the candidacy withheld.
FENCE = re.compile(
    r"^```queue(?P<gated>-gated)?[ \t]*\r?$\r?\n(?P<body>[\s\S]*?)^```[ \t]*\r?$",
    re.MULTILINE,
)
# The first line of a block is the queue's own item line, so that a refill is a
# copy: `**[Claude] V-3 -- the routing rule's section headers actually exist**`.
ITEM_HEAD = re.compile(r"^\*\*\[(?P<lane>\w+)\]\s+(?P<id>[\w.-]+)\s+--\s+(?P<title>.+?)\*\*\s*$")
ITEM_HEAD_WITH_ANY_ID = re.compile(
    r"^\*\*\[(?P<lane>\w+)\]\s+(?P<id>.+?)\s+--\s+(?P<title>.+?)\*\*\s*$"
)
FIELD = re.compile(r"^-\s+(Plan|Files|Check|Proof|Next after):", re.MULTILINE)
REQUIRED_FIELDS = ("Plan", "Files", "Check", "Proof", "Next after")
# Indentation the queue gives an item's field lines under its number.
QUEUE_INDENT = "   "


@dataclass(frozen=True)
class Entry:
    """One backlog block: a slice specified in a plan, ready to be copied."""

    plan: str          # repository-relative path of the plan holding it
    line: int          # 1-based line the fence opens on, for error messages
    lane: str          # the lane tag the block carries, "Claude" or "Codex"
    slice_id: str
    title: str
    body: str          # the block exactly as written, no trailing newline
    gated: bool

    def queue_text(self, number: int) -> str:
        """This block as a numbered `## Next up` item, indentation and all."""
        lines = self.body.split("\n")
        rendered = [f"{number}. {lines[0]}"]
        rendered += [QUEUE_INDENT + line if line else line for line in lines[1:]]
        return "\n".join(rendered) + "\n"


def parse_blocks(text: str, plan: str) -> tuple[list[Entry], list[str]]:
    """Every queue block in one plan, and what is wrong with the malformed ones.

    A block that does not parse is reported rather than skipped: a plan whose
    block is silently ignored looks refillable and is not, which is the same
    trap as a stale queue entry."""
    entries: list[Entry] = []
    problems: list[str] = []
    for match in FENCE.finditer(text):
        line_number = text.count("\n", 0, match.start()) + 1
        body = match.group("body").rstrip("\n").replace("\r", "")
        where = f"{plan}:{line_number}"
        if not body.strip():
            problems.append(f"{where}: empty queue block")
            continue
        first_line = body.split("\n", 1)[0]
        broad_head = ITEM_HEAD_WITH_ANY_ID.match(first_line)
        if broad_head and any(character.isspace() for character in broad_head.group("id")):
            problems.append(
                f"{where}: id contains whitespace: {broad_head.group('id')!r}"
            )
            continue
        head = ITEM_HEAD.match(first_line)
        if not head:
            problems.append(
                f"{where}: a queue block's first line must be the queue's own item line, "
                '`**[Claude|Codex] <id> -- <title>**`'
            )
            continue
        missing = [
            field for field in REQUIRED_FIELDS
            if not re.search(rf"^-\s+{re.escape(field)}:", body, re.MULTILINE)
        ]
        if missing:
            problems.append(f"{where}: queue block is missing {', '.join(missing)}")
            continue
        entries.append(Entry(
            plan=plan,
            line=line_number,
            lane=head.group("lane"),
            slice_id=head.group("id"),
            title=head.group("title").strip(),
            body=body,
            gated=bool(match.group("gated")),
        ))
    return entries, problems


def collect(plans: list[Path], root: Path) -> tuple[list[Entry], list[str]]:
    """Every queue block across `plans`, in plan order then file order.

    That order is the backlog's priority order, so a plan decides which of its
    own slices is offered first by where it writes the block."""
    entries: list[Entry] = []
    problems: list[str] = []
    for path in plans:
        relative = path.relative_to(root).as_posix()
        found, trouble = parse_blocks(path.read_text(encoding="utf-8"), relative)
        entries.extend(found)
        problems.extend(trouble)
    seen: dict[str, Entry] = {}
    for entry in entries:
        if entry.slice_id in seen:
            problems.append(
                f"{entry.plan}:{entry.line}: {entry.slice_id} already has a queue block in "
                f"{seen[entry.slice_id].plan} -- one slice, one block"
            )
            continue
        seen[entry.slice_id] = entry
    return entries, problems
