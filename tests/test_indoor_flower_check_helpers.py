"""Unit tests for pure helper functions in tools/indoor_flower_check.py."""

from __future__ import annotations

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

from indoor_flower_check import (  # noqa: E402
    _extract_func_body,
    strip_code,
    strip_code_line,
)


class TestIndoorFlowerCheckHelpers(unittest.TestCase):
    def test_extract_func_body_normal_func(self) -> None:
        lines = [
            "extends Node",
            "",
            "func foo() -> void:",
            "\tvar x := 1",
            "\tvar y := 2",
            "",
            "func bar() -> void:",
            "\tpass",
        ]
        start_line, body = _extract_func_body(lines, "foo")
        self.assertEqual(start_line, 3)
        self.assertEqual(body, ["\tvar x := 1", "\tvar y := 2", ""])

    def test_extract_func_body_static_func(self) -> None:
        lines = [
            "static func calculate(a: int) -> int:",
            "    return a + 1",
            "",
            "static func other():",
            "    return 0",
        ]
        start_line, body = _extract_func_body(lines, "calculate")
        self.assertEqual(start_line, 1)
        self.assertEqual(body, ["    return a + 1", ""])

    def test_extract_func_body_annotated_func(self) -> None:
        lines = [
            "@warning_ignore(\"unused_parameter\")",
            "func on_event(event) -> void:",
            "\tprint(event)",
        ]
        start_line, body = _extract_func_body(lines, "on_event")
        self.assertEqual(start_line, 2)
        self.assertEqual(body, ["\tprint(event)"])

    def test_extract_func_body_missing_func(self) -> None:
        lines = [
            "func existing() -> void:",
            "\tpass",
        ]
        start_line, body = _extract_func_body(lines, "missing")
        self.assertEqual(start_line, -1)
        self.assertEqual(body, [])

    def test_extract_func_body_empty_body(self) -> None:
        lines = [
            "func empty() -> void:",
            "func next_func() -> void:",
            "\tpass",
        ]
        start_line, body = _extract_func_body(lines, "empty")
        self.assertEqual(start_line, 1)
        self.assertEqual(body, [])

    def test_extract_func_body_nested_indent(self) -> None:
        lines = [
            "func complex_logic() -> void:",
            "\tif true:",
            "\t\tif false:",
            "\t\t\tpass",
            "\t\telse:",
            "\t\t\treturn",
            "\tprint(\"done\")",
            "func sibling() -> void:",
            "\tpass",
        ]
        start_line, body = _extract_func_body(lines, "complex_logic")
        self.assertEqual(start_line, 1)
        self.assertEqual(len(body), 6)
        self.assertEqual(body[-1], "\tprint(\"done\")")

    def test_extract_func_body_preserves_blank_lines_inside(self) -> None:
        lines = [
            "func with_blanks() -> void:",
            "\tvar a = 1",
            "",
            "",
            "\tvar b = 2",
        ]
        start_line, body = _extract_func_body(lines, "with_blanks")
        self.assertEqual(start_line, 1)
        self.assertEqual(body, ["\tvar a = 1", "", "", "\tvar b = 2"])

    def test_strip_code_line_escaped_quotes(self) -> None:
        line = r'var s = "escaped \" quote" # comment'
        stripped = strip_code_line(line)
        self.assertEqual(stripped, 'var s = "" ')

    def test_strip_code_line_single_quotes(self) -> None:
        line = "var s = 'single \\' quote' # comment"
        stripped = strip_code_line(line)
        self.assertEqual(stripped, 'var s = "" ')

    def test_strip_code_line_hash_in_string(self) -> None:
        line = 'var s = "value # not comment" # real comment'
        stripped = strip_code_line(line)
        self.assertEqual(stripped, 'var s = "" ')

    def test_strip_code_multiline(self) -> None:
        text = 'var a = "str"\n# comment\nvar b = 10'
        stripped = strip_code(text)
        self.assertEqual(stripped, 'var a = ""\n\nvar b = 10')


if __name__ == "__main__":
    unittest.main()
