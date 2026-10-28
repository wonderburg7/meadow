"""Unit tests for tools/heading.py pure helper functions."""

import unittest
from tools import heading


class TestHeadingHelpers(unittest.TestCase):
    def test_headings_basic_atx(self):
        lines = [
            "# Header 1",
            "Some text",
            "## Header 2",
            "More text",
            "### Header 3  ",
        ]
        expected = [
            (0, 1, "Header 1"),
            (2, 2, "Header 2"),
            (4, 3, "Header 3"),
        ]
        self.assertEqual(heading.headings(lines), expected)

    def test_headings_skips_fenced_blocks(self):
        lines = [
            "# Outside Header",
            "```gdscript",
            "## Inside Fence 1",
            "### Inside Fence 2",
            "```",
            "## Outside Header 2",
        ]
        expected = [
            (0, 1, "Outside Header"),
            (5, 2, "Outside Header 2"),
        ]
        self.assertEqual(heading.headings(lines), expected)

    def test_section_extracts_until_same_or_shallower(self):
        lines = [
            "# Title",
            "Intro text",
            "## Section 1",
            "Section 1 content",
            "### Subsection 1.1",
            "Subcontent",
            "## Section 2",
            "Section 2 content",
        ]
        found = heading.headings(lines)
        # Extract Section 1 (index 2, level 2)
        sec_lines = heading.section(lines, 2, 2, found)
        expected = [
            "## Section 1",
            "Section 1 content",
            "### Subsection 1.1",
            "Subcontent",
        ]
        self.assertEqual(sec_lines, expected)

    def test_section_extracts_to_end_of_file_if_no_later_shallower(self):
        lines = [
            "# Title",
            "## Section 1",
            "Content",
            "### Subsection",
            "More content",
        ]
        found = heading.headings(lines)
        sec_lines = heading.section(lines, 1, 2, found)
        self.assertEqual(sec_lines, lines[1:])


if __name__ == "__main__":
    unittest.main()
