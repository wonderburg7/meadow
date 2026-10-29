"""Unit tests for parity between tools.archive_slice and tools.backlog queue fence readers.

Tests the common contract across Python readers for ```queue and ```queue-gated fences,
verifying slice ID extraction, line endings, trailing whitespace, gated flag preservation,
unrelated fence filtering, and current slice exclusion in archiving.
"""

import unittest
from tools.archive_slice import _foreign_queue_blocks
from tools.backlog import parse_blocks


class TestQueueFenceParity(unittest.TestCase):
    def setUp(self) -> None:
        self.sample_queue_block = (
            "```queue\n"
            "**[Codex] S-101 -- Test Title One**\n"
            "- Plan: plans/test.md\n"
            "- Files: test.py\n"
            "- Check: python tests/source_checks.py\n"
            "- Proof: None\n"
            "- Next after: S-100\n"
            "```\n"
        )
        self.sample_gated_block = (
            "```queue-gated\n"
            "**[Claude] S-102 -- Test Title Two**\n"
            "- Plan: plans/test.md\n"
            "- Files: test2.py\n"
            "- Check: python tests/source_checks.py\n"
            "- Proof: None\n"
            "- Next after: S-101\n"
            "```\n"
        )

    def test_common_domain_parity(self) -> None:
        """Verify archive_slice and backlog find the exact same slice IDs on common foreign blocks."""
        text = f"# Section Header\n\n{self.sample_queue_block}\n{self.sample_gated_block}"
        current_slice = "S-000"

        archived = _foreign_queue_blocks(text, current_slice)
        archived_ids = [item[2] for item in archived]

        backlog_entries, problems = parse_blocks(text, "plans/test.md")
        self.assertEqual(problems, [])
        backlog_ids = [entry.slice_id for entry in backlog_entries]

        self.assertEqual(archived_ids, ["S-101", "S-102"])
        self.assertEqual(archived_ids, backlog_ids)

    def test_line_endings_and_trailing_whitespace(self) -> None:
        """Verify fence parsers handle LF, CRLF, and trailing horizontal whitespace on fences/lines."""
        raw_text = (
            "```queue \t \n"
            "**[Codex] S-103 -- LF Trailing**  \n"
            "- Plan: plans/test.md\n"
            "- Files: test.py\n"
            "- Check: ok\n"
            "- Proof: ok\n"
            "- Next after: ok\n"
            "``` \t \n\n"
            "```queue-gated \t \r\n"
            "**[Claude] S-104 -- CRLF Trailing** \t \r\n"
            "- Plan: plans/test.md\r\n"
            "- Files: test.py\r\n"
            "- Check: ok\r\n"
            "- Proof: ok\r\n"
            "- Next after: ok\r\n"
            "``` \t \r\n"
        )
        archived = _foreign_queue_blocks(raw_text, "S-000")
        archived_ids = [item[2] for item in archived]

        backlog_entries, problems = parse_blocks(raw_text, "plans/test.md")
        self.assertEqual(problems, [])
        backlog_ids = [entry.slice_id for entry in backlog_entries]

        self.assertEqual(archived_ids, ["S-103", "S-104"])
        self.assertEqual(archived_ids, backlog_ids)

    def test_unrelated_fences_ignored(self) -> None:
        """Verify python, generic, and unclosed code fences are ignored by both readers."""
        text = (
            "```python\n"
            "**[Codex] S-999 -- Python Fake Block**\n"
            "- Plan: plans/test.md\n"
            "- Files: test.py\n"
            "- Check: ok\n"
            "- Proof: ok\n"
            "- Next after: ok\n"
            "```\n\n"
            "```\n"
            "**[Claude] S-888 -- Generic Block**\n"
            "```\n\n"
            f"{self.sample_queue_block}"
        )
        archived = _foreign_queue_blocks(text, "S-000")
        archived_ids = [item[2] for item in archived]

        backlog_entries, problems = parse_blocks(text, "plans/test.md")
        self.assertEqual(problems, [])
        backlog_ids = [entry.slice_id for entry in backlog_entries]

        self.assertEqual(archived_ids, ["S-101"])
        self.assertEqual(backlog_ids, ["S-101"])

    def test_backlog_gated_flag_preserved(self) -> None:
        """Verify parse_blocks preserves entry.gated accurately for queue vs queue-gated."""
        text = f"{self.sample_queue_block}\n{self.sample_gated_block}"
        entries, problems = parse_blocks(text, "plans/test.md")
        self.assertEqual(problems, [])
        self.assertEqual(len(entries), 2)

        self.assertEqual(entries[0].slice_id, "S-101")
        self.assertFalse(entries[0].gated)

        self.assertEqual(entries[1].slice_id, "S-102")
        self.assertTrue(entries[1].gated)

    def test_archive_slice_excludes_current_slice(self) -> None:
        """Verify _foreign_queue_blocks intentionally excludes current slice_id, while backlog parses it."""
        current_id = "S-101"
        text = f"{self.sample_queue_block}\n{self.sample_gated_block}"

        archived = _foreign_queue_blocks(text, current_id)
        archived_ids = [item[2] for item in archived]

        backlog_entries, problems = parse_blocks(text, "plans/test.md")
        self.assertEqual(problems, [])
        backlog_ids = [entry.slice_id for entry in backlog_entries]

        self.assertEqual(archived_ids, ["S-102"])
        self.assertEqual(backlog_ids, ["S-101", "S-102"])


if __name__ == "__main__":
    unittest.main()
