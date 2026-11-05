"""Unit tests for pure helper functions in tools/json_number_check.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import json_number_check  # noqa: E402


class TestJsonNumberCheckHelpers(unittest.TestCase):
    def test_strip_code_removes_comments(self) -> None:
        """strip_code drops comments while keeping code."""
        line = "var a := 1 # trailing comment"
        self.assertEqual(json_number_check.strip_code(line), "var a := 1 ")

    def test_strip_code_masks_string_literals(self) -> None:
        """strip_code replaces string literals with empty strings to avoid parsing noise."""
        line = 'var s := "hello world" + \'test\''
        self.assertEqual(json_number_check.strip_code(line), 'var s := "" + ""')

    def test_strip_code_handles_escaped_quotes(self) -> None:
        """strip_code handles escaped quotes correctly inside string literals."""
        line = r'var s := "escaped \" quote" # comment'
        self.assertEqual(json_number_check.strip_code(line), 'var s := "" ')

    def test_get_indent_spaces_and_tabs(self) -> None:
        """get_indent computes indentation width expanding tabs to 4 spaces."""
        self.assertEqual(json_number_check.get_indent(""), 0)
        self.assertEqual(json_number_check.get_indent("var x = 1"), 0)
        self.assertEqual(json_number_check.get_indent("    var x = 1"), 4)
        self.assertEqual(json_number_check.get_indent("\tvar x = 1"), 4)
        self.assertEqual(json_number_check.get_indent("\t\tvar x = 1"), 8)
        self.assertEqual(json_number_check.get_indent("  \tvar x = 1"), 4)

    def test_is_numeric_json_container_identifies_numeric_keys(self) -> None:
        """is_numeric_json_container returns True for recognized numeric payload containers."""
        for key in [
            'data.get("completed_challenges")',
            "payload['level']",
            'dict["levels"]',
            'obj.get("stage")',
            'stages_list["stages"]',
            'record["count"]',
            'save.get("version")',
            'config["seed"]',
        ]:
            with self.subTest(key=key):
                self.assertTrue(
                    json_number_check.is_numeric_json_container(key),
                    f"Expected {key} to be recognized as numeric container",
                )

    def test_is_numeric_json_container_rejects_non_numeric_keys(self) -> None:
        """is_numeric_json_container returns False for recognized non-numeric containers."""
        for key in [
            'data.get("names")',
            'data.get("name")',
            "payload['keys']",
            "payload['key']",
            'dict["tags"]',
            'dict["tag"]',
            'obj.get("prefs")',
            'obj.get("preferences")',
            'record["settings"]',
            'save.get("strings")',
            'config["paths"]',
            'config["slugs"]',
            'config["slots"]',
            'config["ids"]',
            'config["id"]',
        ]:
            with self.subTest(key=key):
                self.assertFalse(
                    json_number_check.is_numeric_json_container(key),
                    f"Expected {key} to be recognized as non-numeric container",
                )

    def test_is_numeric_json_container_priority_non_numeric(self) -> None:
        """Non-numeric key patterns take priority over numeric key matches."""
        # e.g., 'stage_names' contains 'stage' (numeric) and 'names' (non-numeric)
        expr = 'data.get("stage_names")'
        self.assertFalse(json_number_check.is_numeric_json_container(expr))

    def test_is_numeric_json_container_unrecognized_returns_false(self) -> None:
        """Expressions without recognized numeric keys return False."""
        self.assertFalse(json_number_check.is_numeric_json_container("foo.bar()"))
        self.assertFalse(json_number_check.is_numeric_json_container('data.get("unknown_field")'))


if __name__ == "__main__":
    unittest.main()
