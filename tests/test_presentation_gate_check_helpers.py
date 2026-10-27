"""Unit tests for blank_comments_and_strings in tools/presentation_gate_check.py."""

from __future__ import annotations

import unittest
from tools.presentation_gate_check import blank_comments_and_strings


class TestBlankCommentsAndStrings(unittest.TestCase):
    def test_blank_comments(self) -> None:
        code = "var x = 10 # comment here\nvar y = 20"
        expected = "var x = 10               \nvar y = 20"
        result = blank_comments_and_strings(code)
        self.assertEqual(result, expected)
        self.assertEqual(len(result), len(code))

    def test_blank_double_quoted_strings(self) -> None:
        code = 'var msg = "hello \\"world\\""\nvar a = 1'
        expected = 'var msg =                  \nvar a = 1'
        result = blank_comments_and_strings(code)
        self.assertEqual(result, expected)
        self.assertEqual(len(result), len(code))

    def test_blank_single_quoted_strings(self) -> None:
        code = "var msg = 'hello \\'world\\''\nvar a = 1"
        expected = "var msg =                  \nvar a = 1"
        result = blank_comments_and_strings(code)
        self.assertEqual(result, expected)
        self.assertEqual(len(result), len(code))

    def test_blank_triple_double_quoted_strings(self) -> None:
        code = 'var doc = """line1\nline2\n"""\nvar x = 1'
        expected = 'var doc =         \n     \n   \nvar x = 1'
        result = blank_comments_and_strings(code)
        self.assertEqual(result, expected)
        self.assertEqual(len(result), len(code))

    def test_blank_triple_single_quoted_strings(self) -> None:
        code = "var doc = '''line1\nline2\n'''\nvar x = 1"
        expected = "var doc =         \n     \n   \nvar x = 1"
        result = blank_comments_and_strings(code)
        self.assertEqual(result, expected)
        self.assertEqual(len(result), len(code))


if __name__ == "__main__":
    unittest.main()
