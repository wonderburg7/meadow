"""Unit tests for the pure helper functions in tools/self_call_check.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from self_call_check import strip_code  # noqa: E402


class TestStripCodeHelper(unittest.TestCase):
    def test_plain_code_without_strings_or_comments_is_unmodified(self) -> None:
        self.assertEqual(strip_code("var x: int = 10"), "var x: int = 10")
        self.assertEqual(strip_code("func calculate(a: int, b: int) -> int:"), "func calculate(a: int, b: int) -> int:")
        self.assertEqual(strip_code("    return a + b"), "    return a + b")

    def test_empty_and_whitespace_only_lines(self) -> None:
        self.assertEqual(strip_code(""), "")
        self.assertEqual(strip_code("   "), "   ")
        self.assertEqual(strip_code("\t\t"), "\t\t")

    def test_comments_are_stripped(self) -> None:
        self.assertEqual(strip_code("# whole line comment"), "")
        self.assertEqual(strip_code("   # indented comment"), "   ")
        self.assertEqual(strip_code("var x = 1 # trailing comment"), "var x = 1 ")

    def test_strings_are_replaced_by_empty_quotes(self) -> None:
        self.assertEqual(strip_code('var name = "Meadow"'), 'var name = ""')
        self.assertEqual(strip_code("var name = 'Meadow'"), "var name = \"\"")
        self.assertEqual(strip_code('var full = "Hello" + " " + "World"'), 'var full = "" + "" + ""')

    def test_escaped_quotes_inside_strings(self) -> None:
        self.assertEqual(strip_code('var escaped = "escaped \\"quote\\""'), 'var escaped = ""')
        self.assertEqual(strip_code("var escaped = 'escaped \\'quote\\''"), "var escaped = \"\"")
        self.assertEqual(strip_code('var backslash = "ends with backslash\\\\\\"'), 'var backslash = ""')

    def test_hash_inside_strings_is_not_treated_as_comment(self) -> None:
        self.assertEqual(strip_code('var colour = "#ff00aa"'), 'var colour = ""')
        self.assertEqual(strip_code("var colour = '#ff00aa'"), "var colour = \"\"")
        self.assertEqual(
            strip_code('var text = "code # not a comment" # real comment'),
            'var text = "" ',
        )

    def test_quotes_inside_comments_are_ignored(self) -> None:
        self.assertEqual(strip_code('# A comment with "double" and \'single\' quotes'), "")
        self.assertEqual(strip_code('var y = 2 # comment saying "call_func()"'), "var y = 2 ")

    def test_unterminated_string_at_end_of_line(self) -> None:
        self.assertEqual(strip_code('var broken = "unfinished'), 'var broken = ""')


if __name__ == "__main__":
    unittest.main()
