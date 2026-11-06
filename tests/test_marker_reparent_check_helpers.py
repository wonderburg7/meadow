"""Unit tests for pure helper functions in tools/marker_reparent_check.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from marker_reparent_check import strip_comments  # noqa: E402


class MarkerReparentCheckHelpersTests(unittest.TestCase):
    def test_plain_code_unmodified(self) -> None:
        code = "func _update_marker(stage_id: String) -> void:\n\tvar x = 1\n"
        self.assertEqual(strip_comments(code), code)

    def test_single_line_comments_replaced_with_whitespace(self) -> None:
        code = "var a = 1 # inline comment\n# whole line comment\nvar b = 2\n"
        result = strip_comments(code)
        self.assertNotIn("inline comment", result)
        self.assertNotIn("whole line comment", result)
        self.assertIn("var a = 1", result)
        self.assertIn("var b = 2", result)
        self.assertEqual(len(result), len(code))

    def test_stage_id_literals_preserved(self) -> None:
        code = 'if stage_id in ["1.2", "1.5", "1.6", "1.12", "1.15", "1.19"]:\n\telif stage_id == "1.10":\n'
        result = strip_comments(code)
        self.assertEqual(result, code)

    def test_non_stage_strings_masked_with_whitespace(self) -> None:
        double_quoted = 'var msg = "hello world"\n'
        single_quoted = "var msg = 'custom string'\n"
        self.assertNotIn("hello world", strip_comments(double_quoted))
        self.assertNotIn("custom string", strip_comments(single_quoted))
        self.assertEqual(len(strip_comments(double_quoted)), len(double_quoted))
        self.assertEqual(len(strip_comments(single_quoted)), len(single_quoted))

    def test_multiline_docstrings_masked_preserving_newlines(self) -> None:
        code = '"""First line\nSecond line\nThird line"""\nvar ready = true\n'
        result = strip_comments(code)
        self.assertNotIn("First line", result)
        self.assertNotIn("Second line", result)
        self.assertIn("var ready = true", result)
        self.assertEqual(code.count("\n"), result.count("\n"))
        self.assertEqual(len(result), len(code))

    def test_single_quoted_multiline_strings_masked(self) -> None:
        code = "'''Line 1\nLine 2'''\npass\n"
        result = strip_comments(code)
        self.assertNotIn("Line 1", result)
        self.assertIn("pass", result)
        self.assertEqual(code.count("\n"), result.count("\n"))
        self.assertEqual(len(result), len(code))

    def test_escaped_quotes_inside_strings_handled(self) -> None:
        code = r'var escaped = "nested \"quote\" inside"' + "\n"
        result = strip_comments(code)
        self.assertNotIn("nested", result)
        self.assertNotIn("quote", result)
        self.assertEqual(len(result), len(code))


if __name__ == "__main__":
    unittest.main()
