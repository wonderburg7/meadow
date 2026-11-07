"""Unit tests for _clean_string in tools/goal_default_check.py."""

from __future__ import annotations

import unittest
from tools.goal_default_check import _clean_string


class TestGoalDefaultCheckCleanString(unittest.TestCase):
    def test_clean_triple_double_quoted_string(self) -> None:
        self.assertEqual(_clean_string('"""foo"""'), "foo")

    def test_clean_triple_single_quoted_string(self) -> None:
        self.assertEqual(_clean_string("'''bar'''"), "bar")

    def test_clean_double_quoted_string(self) -> None:
        self.assertEqual(_clean_string('"hello"'), "hello")

    def test_clean_single_quoted_string(self) -> None:
        self.assertEqual(_clean_string("'world'"), "world")

    def test_clean_empty_quoted_strings(self) -> None:
        self.assertEqual(_clean_string('""'), "")
        self.assertEqual(_clean_string("''"), "")
        self.assertEqual(_clean_string('""""""'), "")
        self.assertEqual(_clean_string("''''''"), "")

    def test_clean_unquoted_string(self) -> None:
        self.assertEqual(_clean_string("raw_text"), "raw_text")

    def test_clean_mismatched_quotes(self) -> None:
        self.assertEqual(_clean_string('"mismatched\''), '"mismatched\'')

    def test_clean_empty_string(self) -> None:
        self.assertEqual(_clean_string(""), "")

    def test_clean_multiline_triple_quotes(self) -> None:
        self.assertEqual(_clean_string('"""line1\nline2"""'), "line1\nline2")
        self.assertEqual(_clean_string("'''line1\nline2'''"), "line1\nline2")


if __name__ == "__main__":
    unittest.main()
