"""Unit tests for pure helper functions in tools/marker_reparent_check.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from marker_reparent_check import strip_comments  # noqa: E402


class MarkerReparentCheckHelpersTests(unittest.TestCase):
    def test_empty_string(self) -> None:
        self.assertEqual(strip_comments(""), "")

    def test_strip_single_line_comment(self) -> None:
        source = "var x = 1 # inline comment\n# whole line comment\nvar y = 2"
        result = strip_comments(source)
        self.assertNotIn("comment", result)
        self.assertNotIn("#", result)
        self.assertEqual(len(result), len(source))
        self.assertTrue(result.startswith("var x = 1 "))
        self.assertTrue(result.endswith("\nvar y = 2"))

    def test_preserves_stage_id_literals(self) -> None:
        source = 'if stage_id in ["1.2", "1.10", "1.15"]:\n\tpass'
        result = strip_comments(source)
        self.assertIn('"1.2"', result)
        self.assertIn('"1.10"', result)
        self.assertIn('"1.15"', result)

    def test_strips_non_stage_strings(self) -> None:
        source = 'var name = "hive_root"\nvar msg = \'hello world\''
        result = strip_comments(source)
        self.assertNotIn("hive_root", result)
        self.assertNotIn("hello world", result)
        self.assertEqual(len(result), len(source))

    def test_strips_triple_quoted_strings_preserving_newlines(self) -> None:
        source = 'var doc = """line one\nline two\nline three"""\nvar next = 1'
        result = strip_comments(source)
        self.assertNotIn("line one", result)
        self.assertNotIn("line two", result)
        self.assertNotIn("line three", result)
        self.assertEqual(result.count("\n"), source.count("\n"))
        self.assertTrue(result.endswith("\nvar next = 1"))

    def test_strips_triple_single_quoted_strings(self) -> None:
        source = "'''multi\nline\nsingle'''\nvar a = 0"
        result = strip_comments(source)
        self.assertNotIn("multi", result)
        self.assertEqual(result.count("\n"), source.count("\n"))

    def test_escaped_quotes_inside_strings(self) -> None:
        source = r'var escaped = "quote \" here"' + "\nvar b = 2"
        result = strip_comments(source)
        self.assertNotIn("quote", result)
        self.assertTrue(result.endswith("\nvar b = 2"))


if __name__ == "__main__":
    unittest.main()
