"""Unit tests for the pure helper functions in tools/json_number_check.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from json_number_check import (  # noqa: E402
    get_indent,
    is_numeric_json_container,
    strip_code,
)


class TestStripCodeHelper(unittest.TestCase):
    def test_plain_code_unmodified(self) -> None:
        self.assertEqual(strip_code("var x: int = 10"), "var x: int = 10")
        self.assertEqual(strip_code("for val in arr:"), "for val in arr:")

    def test_empty_and_whitespace(self) -> None:
        self.assertEqual(strip_code(""), "")
        self.assertEqual(strip_code("   "), "   ")
        self.assertEqual(strip_code("\t\t"), "\t\t")

    def test_comments_stripped(self) -> None:
        self.assertEqual(strip_code("# comment only"), "")
        self.assertEqual(strip_code("    # indented comment"), "    ")
        self.assertEqual(strip_code("var x = 1 # trailing comment"), "var x = 1 ")

    def test_string_literals_replaced_with_empty_quotes(self) -> None:
        self.assertEqual(strip_code('var s = "hello world"'), 'var s = ""')
        self.assertEqual(strip_code("var s = 'single quote'"), 'var s = ""')
        self.assertEqual(strip_code('var compound = "part1" + \'part2\''), 'var compound = "" + ""')

    def test_escaped_quotes_handled(self) -> None:
        self.assertEqual(strip_code(r'var s = "escaped \" quotes"'), 'var s = ""')
        self.assertEqual(strip_code(r"var s = 'escaped \' quotes'"), 'var s = ""')
        self.assertEqual(strip_code(r'var backslash = "ends with \\"'), 'var backslash = ""')

    def test_hash_inside_quotes_not_treated_as_comment(self) -> None:
        self.assertEqual(strip_code('var c = "#ff0000"'), 'var c = ""')
        self.assertEqual(strip_code('var c = "#ff0000" # real comment'), 'var c = "" ')

    def test_quotes_inside_comments_ignored(self) -> None:
        self.assertEqual(strip_code('var x = 1 # "double" and \'single\' quotes'), 'var x = 1 ')


class TestGetIndentHelper(unittest.TestCase):
    def test_no_indent(self) -> None:
        self.assertEqual(get_indent("var x = 1"), 0)
        self.assertEqual(get_indent("func foo() -> void:"), 0)

    def test_space_indent(self) -> None:
        self.assertEqual(get_indent("    var x = 1"), 4)
        self.assertEqual(get_indent("        var y = 2"), 8)

    def test_tab_indent(self) -> None:
        # expandtabs(4) converts each tab to 4 spaces
        self.assertEqual(get_indent("\tvar x = 1"), 4)
        self.assertEqual(get_indent("\t\tvar y = 2"), 8)

    def test_mixed_indent(self) -> None:
        self.assertEqual(get_indent("\t    var x = 1"), 8)
        self.assertEqual(get_indent("    \tvar y = 2"), 8)

    def test_empty_line(self) -> None:
        self.assertEqual(get_indent(""), 0)

    def test_whitespace_only_lines(self) -> None:
        # get_indent measures leading whitespace up to the first non-whitespace character
        # or the end of the line if there are no non-whitespace characters
        self.assertEqual(get_indent("    "), 4)
        self.assertEqual(get_indent("\t\t"), 8)


class TestIsNumericJsonContainerHelper(unittest.TestCase):
    def test_numeric_containers(self) -> None:
        numeric_cases = [
            'data.get("completed_challenges")',
            "data.get('completed_challenges')",
            'payload["level"]',
            'data.get("levels", [])',
            'result.get("stage")',
            'response["stages"]',
            'info.get("count")',
            'save_data["version"]',
            'config.get("seed")',
        ]
        for expr in numeric_cases:
            with self.subTest(expr=expr):
                self.assertTrue(
                    is_numeric_json_container(expr),
                    f"Expected {expr} to be recognized as numeric container",
                )

    def test_non_numeric_containers(self) -> None:
        non_numeric_cases = [
            'data.get("names")',
            'data.get("name")',
            'record["keys"]',
            'entry.get("key")',
            'item["tags"]',
            'item.get("tag")',
            'data.get("prefs")',
            'data.get("preferences")',
            'settings.get("settings")',
            'config.get("setting")',
            'data.get("strings")',
            'data.get("string")',
            'file_info.get("paths")',
            'file_info.get("path")',
            'slug_dict.get("slugs")',
            'slug_dict.get("slug")',
            'slots.get("slots")',
            'slots.get("slot")',
            'preset.get("preset")',
            'data.get("ids")',
            'data.get("id")',
        ]
        for expr in non_numeric_cases:
            with self.subTest(expr=expr):
                self.assertFalse(
                    is_numeric_json_container(expr),
                    f"Expected {expr} to NOT be recognized as numeric container",
                )

    def test_non_numeric_takes_precedence_over_numeric(self) -> None:
        # NON_NUMERIC_KEY_PATTERN is checked before NUMERIC_KEY_PATTERN
        # e.g., expression containing both "keys" and "level"
        expr = 'data.get("keys_for_level")'
        self.assertFalse(is_numeric_json_container(expr))

    def test_unmatched_expressions(self) -> None:
        unmatched_cases = [
            'data.get("unknown_field")',
            'other_dict["unrelated"]',
            "simple_array",
        ]
        for expr in unmatched_cases:
            with self.subTest(expr=expr):
                self.assertFalse(is_numeric_json_container(expr))


if __name__ == "__main__":
    unittest.main()
