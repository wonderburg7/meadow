"""Print one Markdown section: the heading that matches, and nothing after it.

Routing tells a session to open a named heading, not a whole file. This makes
that literal:

    python tools/heading.py plans/now/flowers.md "Slice 1"

prints the matching `#`-prefixed line and everything up to the next heading at
the same or a shallower level.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


HEADING_PATTERN = re.compile(r"^(#{1,6})\s+(.*?)\s*$")


def headings(lines: list[str]) -> list[tuple[int, int, str]]:
    """Return (line index, level, text) for every ATX heading in the file."""
    found = []
    for index, line in enumerate(lines):
        match = HEADING_PATTERN.match(line)
        if match:
            found.append((index, len(match.group(1)), match.group(2)))
    return found


def section(lines: list[str], start: int, level: int) -> list[str]:
    """Return the heading line and everything up to the next same-or-shallower heading."""
    for index in range(start + 1, len(lines)):
        match = HEADING_PATTERN.match(lines[index])
        if match and len(match.group(1)) <= level:
            return lines[start:index]
    return lines[start:]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("file", help="Markdown file to read")
    parser.add_argument("heading", help="heading text; case-insensitive substring match")
    args = parser.parse_args()

    # Sections carry em dashes and the like; a narrow console should degrade,
    # not raise part-way through a printed section.
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(errors="replace")

    path = Path(args.file)
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        print(f"{args.file}: {error}", file=sys.stderr)
        return 1

    found = headings(lines)
    wanted = args.heading.casefold()
    matches = [entry for entry in found if wanted in entry[2].casefold()]

    if not matches:
        print(f"{args.file}: no heading matches {args.heading!r}. Headings are:", file=sys.stderr)
        for _, level, text in found:
            print(f"  {'#' * level} {text}", file=sys.stderr)
        return 1

    start, level, text = matches[0]
    for line in section(lines, start, level):
        print(line)

    if len(matches) > 1:
        others = ", ".join(repr(entry[2]) for entry in matches[1:])
        print(f"\nNote: {len(matches)} headings matched; printed {text!r}. Also: {others}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
