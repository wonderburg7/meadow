"""Unit tests for pure helper functions in tools/freeze_bee_check.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from freeze_bee_check import code_only, function  # noqa: E402


class FreezeBeeCheckHelpersTests(unittest.TestCase):
    def test_code_only_masks_comments(self) -> None:
        code = "var a = 1 # inline comment\n# whole comment\nvar b = 2\n"
        result = code_only(code)
        self.assertNotIn("inline comment", result)
        self.assertNotIn("whole comment", result)
        self.assertIn("var a = 1", result)
        self.assertIn("var b = 2", result)
        self.assertEqual(len(result), len(code))

    def test_code_only_masks_strings(self) -> None:
        double_quoted = 'var msg = "hello world"\n'
        single_quoted = "var msg = 'single quote'\n"
        self.assertNotIn("hello world", code_only(double_quoted))
        self.assertNotIn("single quote", code_only(single_quoted))
        self.assertEqual(len(code_only(double_quoted)), len(double_quoted))
        self.assertEqual(len(code_only(single_quoted)), len(single_quoted))

    def test_code_only_masks_multiline_docstrings(self) -> None:
        triple_double = '"""Doc line 1\nDoc line 2"""\nvar x = 5\n'
        triple_single = "'''Single line 1\nSingle line 2'''\nvar y = 6\n"
        res_double = code_only(triple_double)
        res_single = code_only(triple_single)
        self.assertNotIn("Doc line 1", res_double)
        self.assertNotIn("Single line 1", res_single)
        self.assertEqual(res_double.count("\n"), triple_double.count("\n"))
        self.assertEqual(res_single.count("\n"), triple_single.count("\n"))
        self.assertEqual(len(res_double), len(triple_double))
        self.assertEqual(len(res_single), len(triple_single))

    def test_code_only_retains_keep_match(self) -> None:
        code = 'var cmd = "freeze_bee:queen"\nvar other = "something else"\n'
        result = code_only(code, keep='"freeze_bee:queen"')
        self.assertIn('"freeze_bee:queen"', result)
        self.assertNotIn("something else", result)
        self.assertEqual(len(result), len(code))

    def test_function_extracts_named_function_body(self) -> None:
        text = (
            "func first(arg: int) -> void:\n"
            "    print(arg)\n"
            "\n"
            "func second() -> bool:\n"
            "    return true\n"
        )
        body = function(text, "first")
        self.assertIn("print(arg)", body)
        self.assertNotIn("return true", body)

    def test_function_returns_empty_when_not_found(self) -> None:
        text = "func foo() -> void:\n    pass\n"
        self.assertEqual(function(text, "bar"), "")


if __name__ == "__main__":
    unittest.main()
