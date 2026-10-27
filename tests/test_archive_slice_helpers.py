"""Unit tests for tools/archive_slice.py text helpers."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

# Add tools directory to path so archive_slice can be imported.
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from archive_slice import (  # noqa: E402
    _drop_routing_rows,
    _foreign_queue_blocks,
    find_section,
    resolve_item,
)


class TestArchiveSliceHelpers(unittest.TestCase):
    """Tests for resolve_item, find_section, _foreign_queue_blocks, and _drop_routing_rows."""

    def test_resolve_item(self) -> None:
        queue_text = (
            "## Next up\n\n"
            "### Claude lane\n\n"
            '1. **[Claude] X-1 -- Item 1**\n   - Plan: `plans/a.md` -- "Heading 1 \\"escaped\\""\n\n'
            '2. **[Claude] X-2 -- Item 2**\n   - Plan: `plans/b.md` -- "Heading 2"\n\n'
            "3. **[Claude] X-3 -- Item 3**\n   no plan line\n"
        )

        res1 = resolve_item(queue_text, "X-1")
        self.assertEqual(res1, ("plans/a.md", 'Heading 1 "escaped"'))

        res2 = resolve_item(queue_text, "X-2")
        self.assertEqual(res2, ("plans/b.md", "Heading 2"))

        res3 = resolve_item(queue_text, "X-3")
        self.assertIsNone(res3)

        res4 = resolve_item(queue_text, "X-99")
        self.assertIsNone(res4)

    def test_find_section(self) -> None:
        lines = [
            "# Title",
            "## Feature Section",
            "Intro text",
            "## Feature Section for X-1",
            "More text",
            "## Feature Section for X-10",
            "Other text",
        ]

        # Picks second heading because only it names X-1
        hit1 = find_section(lines, "feature section", "X-1")
        self.assertIsNotNone(hit1)
        self.assertEqual(hit1, (3, 2, "Feature Section for X-1"))

        # Picks first heading when neither names X-2
        hit2 = find_section(lines, "feature section", "X-2")
        self.assertIsNotNone(hit2)
        self.assertEqual(hit2, (1, 2, "Feature Section"))

        # Matches case-insensitively
        hit3 = find_section(lines, "FEATURE SECTION", "X-1")
        self.assertIsNotNone(hit3)
        self.assertEqual(hit3, (3, 2, "Feature Section for X-1"))

        # Does not treat X-1 as matching X-10
        lines_x10 = [
            "# Title",
            "## Feature Section",
            "## Feature Section for X-10",
        ]
        hit4 = find_section(lines_x10, "feature section", "X-1")
        self.assertIsNotNone(hit4)
        self.assertEqual(hit4, (1, 2, "Feature Section"))

        # Returns None when nothing matches
        hit5 = find_section(lines, "nonexistent section", "X-1")
        self.assertIsNone(hit5)

    def test_foreign_queue_blocks(self) -> None:
        section_text = (
            "Introduction\n"
            "```queue\n"
            "**[Claude] X-1 -- First item**\n"
            '- Plan: `plans/a.md` -- "H"\n'
            "```\n"
            "Middle text\n"
            "```queue-gated\n"
            "**[Claude] X-2 -- Second item**\n"
            '- Plan: `plans/a.md` -- "H"\n'
            "```\n"
            "Trailing text\n"
            "```queue\n"
            "Unclosed fence line 1\n"
            "Unclosed fence line 2\n"
        )

        blocks = _foreign_queue_blocks(section_text, "X-1")
        self.assertEqual(blocks, [(6, 9, "X-2")])

    def test_drop_routing_rows(self) -> None:
        table_text = (
            "| If the queue names | Read |\n"
            "| --- | --- |\n"
            "| Item 1 | `plans/a.md` |\n"
            "| Item 2 `plans/a.md` | `plans/b.md` |\n"
            "| Item 3 | `plans/c.md` |\n"
        )

        result = _drop_routing_rows(table_text, "plans/a.md")
        expected = (
            "| If the queue names | Read |\n"
            "| --- | --- |\n"
            "| Item 2 `plans/a.md` | `plans/b.md` |\n"
            "| Item 3 | `plans/c.md` |\n"
        )
        self.assertEqual(result, expected)


if __name__ == "__main__":
    unittest.main()
