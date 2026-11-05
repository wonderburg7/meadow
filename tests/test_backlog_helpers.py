"""Unit tests for pure helpers and data structures in tools/backlog.py."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools import backlog


class TestBacklogEntry(unittest.TestCase):
    def test_queue_text_formatting(self) -> None:
        """Entry.queue_text indents subsequent lines by 3 spaces and numbers the head."""
        body = (
            "**[Claude] T-1 -- sample title**\n"
            "- Plan: `plans/now/test.md`\n"
            "- Files: `tools/backlog.py`\n"
            "- Check: run test\n"
            "- Proof: pass\n"
            "- Next after: T-2 -- follow up"
        )
        entry = backlog.Entry(
            plan="plans/now/test.md",
            line=10,
            lane="Claude",
            slice_id="T-1",
            title="sample title",
            body=body,
            gated=False,
        )
        rendered = entry.queue_text(1)
        expected = (
            "1. **[Claude] T-1 -- sample title**\n"
            "   - Plan: `plans/now/test.md`\n"
            "   - Files: `tools/backlog.py`\n"
            "   - Check: run test\n"
            "   - Proof: pass\n"
            "   - Next after: T-2 -- follow up\n"
        )
        self.assertEqual(rendered, expected)

    def test_queue_text_preserves_empty_lines_without_trailing_spaces(self) -> None:
        """Empty lines in body are not given trailing spaces."""
        body = "**[Codex] T-2 -- title**\n\n- Plan: `plans/now/test.md`"
        entry = backlog.Entry(
            plan="plans/now/test.md",
            line=5,
            lane="Codex",
            slice_id="T-2",
            title="title",
            body=body,
            gated=False,
        )
        rendered = entry.queue_text(2)
        expected = "2. **[Codex] T-2 -- title**\n\n   - Plan: `plans/now/test.md`\n"
        self.assertEqual(rendered, expected)


class TestParseBlocks(unittest.TestCase):
    def test_parse_valid_block(self) -> None:
        """A properly formatted queue block is parsed with all metadata."""
        text = (
            "Some preamble.\n\n"
            "```queue\n"
            "**[Claude] SL-1 -- first slice title**\n"
            "- Plan: `plans/now/first.md`\n"
            "- Files: `tools/backlog.py`\n"
            "- Check: test\n"
            "- Proof: pass\n"
            "- Next after: SL-2\n"
            "```\n"
        )
        entries, problems = backlog.parse_blocks(text, "plans/now/first.md")
        self.assertEqual(problems, [])
        self.assertEqual(len(entries), 1)
        e = entries[0]
        self.assertEqual(e.plan, "plans/now/first.md")
        self.assertEqual(e.line, 3)
        self.assertEqual(e.lane, "Claude")
        self.assertEqual(e.slice_id, "SL-1")
        self.assertEqual(e.title, "first slice title")
        self.assertFalse(e.gated)
        self.assertTrue(e.body.startswith("**[Claude] SL-1"))

    def test_parse_gated_block(self) -> None:
        """A block with queue-gated sets gated to True."""
        text = (
            "```queue-gated\n"
            "**[Codex] GT-1 -- gated slice title**\n"
            "- Plan: `plans/now/gated.md`\n"
            "- Files: `tools/backlog.py`\n"
            "- Check: check\n"
            "- Proof: proof\n"
            "- Next after: none\n"
            "```\n"
        )
        entries, problems = backlog.parse_blocks(text, "plans/now/gated.md")
        self.assertEqual(problems, [])
        self.assertEqual(len(entries), 1)
        self.assertTrue(entries[0].gated)
        self.assertEqual(entries[0].slice_id, "GT-1")

    def test_empty_block_reported(self) -> None:
        """An empty queue block reports a problem."""
        text = "```queue\n\n   \n```\n"
        entries, problems = backlog.parse_blocks(text, "plans/now/empty.md")
        self.assertEqual(entries, [])
        self.assertEqual(len(problems), 1)
        self.assertIn("empty queue block", problems[0])
        self.assertIn("plans/now/empty.md:1", problems[0])

    def test_whitespace_in_id_reported(self) -> None:
        """An id containing whitespace is rejected."""
        text = (
            "```queue\n"
            "**[Claude] SL 1 -- spaced id**\n"
            "- Plan: `plans/now/bad.md`\n"
            "- Files: `tools/backlog.py`\n"
            "- Check: c\n"
            "- Proof: p\n"
            "- Next after: n\n"
            "```\n"
        )
        entries, problems = backlog.parse_blocks(text, "plans/now/bad.md")
        self.assertEqual(entries, [])
        self.assertEqual(len(problems), 1)
        self.assertIn("id contains whitespace", problems[0])

    def test_malformed_first_line_reported(self) -> None:
        """A first line not matching the item header format is rejected."""
        text = (
            "```queue\n"
            "Invalid first line without markup\n"
            "- Plan: `plans/now/bad.md`\n"
            "- Files: `tools/backlog.py`\n"
            "- Check: c\n"
            "- Proof: p\n"
            "- Next after: n\n"
            "```\n"
        )
        entries, problems = backlog.parse_blocks(text, "plans/now/bad.md")
        self.assertEqual(entries, [])
        self.assertEqual(len(problems), 1)
        self.assertIn("a queue block's first line must be the queue's own item line", problems[0])

    def test_missing_required_fields_reported(self) -> None:
        """Missing any of the required fields reports the missing list."""
        text = (
            "```queue\n"
            "**[Claude] MF-1 -- missing fields**\n"
            "- Plan: `plans/now/missing.md`\n"
            "- Files: `tools/backlog.py`\n"
            "```\n"
        )
        entries, problems = backlog.parse_blocks(text, "plans/now/missing.md")
        self.assertEqual(entries, [])
        self.assertEqual(len(problems), 1)
        self.assertIn("queue block is missing Check, Proof, Next after", problems[0])


class TestCollect(unittest.TestCase):
    def test_collect_from_multiple_plans(self) -> None:
        """collect parses blocks across multiple plans in order."""
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            p1 = root / "plan1.md"
            p2 = root / "plan2.md"

            p1.write_text(
                "```queue\n"
                "**[Claude] C-1 -- item 1**\n"
                "- Plan: `plan1.md`\n"
                "- Files: `a.py`\n"
                "- Check: check\n"
                "- Proof: proof\n"
                "- Next after: none\n"
                "```\n",
                encoding="utf-8",
            )
            p2.write_text(
                "```queue\n"
                "**[Codex] C-2 -- item 2**\n"
                "- Plan: `plan2.md`\n"
                "- Files: `b.py`\n"
                "- Check: check\n"
                "- Proof: proof\n"
                "- Next after: none\n"
                "```\n",
                encoding="utf-8",
            )

            entries, problems = backlog.collect([p1, p2], root)
            self.assertEqual(problems, [])
            self.assertEqual(len(entries), 2)
            self.assertEqual([e.slice_id for e in entries], ["C-1", "C-2"])

    def test_collect_duplicate_ids_reported(self) -> None:
        """Duplicate slice IDs across plans are reported as problems."""
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            p1 = root / "plan1.md"
            p2 = root / "plan2.md"

            block = (
                "```queue\n"
                "**[Claude] DUP-1 -- duplicate item**\n"
                "- Plan: `test.md`\n"
                "- Files: `a.py`\n"
                "- Check: check\n"
                "- Proof: proof\n"
                "- Next after: none\n"
                "```\n"
            )
            p1.write_text(block, encoding="utf-8")
            p2.write_text(block, encoding="utf-8")

            entries, problems = backlog.collect([p1, p2], root)
            self.assertEqual(len(problems), 1)
            self.assertIn("DUP-1 already has a queue block", problems[0])
            self.assertIn("one slice, one block", problems[0])


if __name__ == "__main__":
    unittest.main()
