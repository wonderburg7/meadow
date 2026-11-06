"""Unit tests for pure helper functions in tools/drained_flower_exclusion_check.py."""

from __future__ import annotations

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

from drained_flower_exclusion_check import strip_comments  # noqa: E402


class TestDrainedFlowerExclusionCheckHelpers(unittest.TestCase):
    def test_strip_single_line_comment(self) -> None:
        source = "var x = 1 # this is a comment\nvar y = 2\n"
        result = strip_comments(source)
        # strip_comments replaces comment characters with spaces, preserving offsets and line count
        self.assertEqual(len(result), len(source))
        lines = result.splitlines()
        self.assertEqual(lines[0].rstrip(), "var x = 1")
        self.assertEqual(lines[1], "var y = 2")

    def test_strip_string_literals(self) -> None:
        source = 'var s = "hello world"\nvar c = \'single quoted\''
        result = strip_comments(source)
        # Strings are replaced with whitespace of equivalent length
        self.assertEqual(result.splitlines(), ['var s =              ', 'var c =                '])

    def test_strip_escaped_string(self) -> None:
        source = r'var escaped = "line with \"quotes\" inside"'
        result = strip_comments(source)
        self.assertEqual(len(result), len(source))
        self.assertTrue(result.startswith("var escaped = "))
        self.assertTrue(result[len("var escaped = "):].isspace())

    def test_strip_triple_quoted_multiline_string(self) -> None:
        source = 'var doc = """first line\nsecond line\nthird line"""\nvar z = 3'
        result = strip_comments(source)
        # Line count is preserved, newlines retained inside masked multiline string
        self.assertEqual(result.count("\n"), source.count("\n"))
        lines = result.splitlines()
        self.assertEqual(len(lines), 4)
        self.assertEqual(lines[3], "var z = 3")
        self.assertTrue(lines[1].isspace())
        self.assertTrue(lines[2].isspace())

    def test_hash_inside_string_not_comment(self) -> None:
        source = 'var tag = "#not_a_comment"\n# actual comment'
        result = strip_comments(source)
        lines = result.splitlines()
        self.assertEqual(len(lines), 2)
        # First line had string with #, whole string turned into spaces
        self.assertEqual(lines[0], 'var tag =                 ')
        # Second line was comment, masked into spaces
        self.assertEqual(lines[1], '                ')


if __name__ == "__main__":
    unittest.main()
