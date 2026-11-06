"""Unit tests for helper functions in tools/indoor_flower_check.py."""

from __future__ import annotations

import unittest
from tools.indoor_flower_check import (
    _extract_func_body,
    strip_code,
    strip_code_line,
)


class TestIndoorFlowerCheckHelpers(unittest.TestCase):
    def test_strip_code_line_basic(self) -> None:
        self.assertEqual(strip_code_line("var x = 10"), "var x = 10")
        self.assertEqual(strip_code_line("   # just a comment"), "   ")
        self.assertEqual(strip_code_line(""), "")

    def test_strip_code_line_strings(self) -> None:
        self.assertEqual(strip_code_line('var s = "hello"'), 'var s = ""')
        self.assertEqual(strip_code_line("var s = 'world'"), 'var s = ""')
        self.assertEqual(strip_code_line('var s = "escaped \\" quote"'), 'var s = ""')
        self.assertEqual(strip_code_line(r"var s = 'escaped \' quote'"), 'var s = ""')
        self.assertEqual(strip_code_line('var s = "with # hash" # and comment'), 'var s = "" ')

    def test_strip_code(self) -> None:
        lines = [
            "var a = 1 # first",
            "# comment line",
            'var b = "two"',
        ]
        text = "\n".join(lines)
        expected = "var a = 1 \n\nvar b = \"\""
        self.assertEqual(strip_code(text), expected)

    def test_extract_func_body_not_found(self) -> None:
        lines = [
            "extends Node2D",
            "var x = 1",
            "func other_func():",
            "\tpass",
        ]
        start_line, body = _extract_func_body(lines, "target_func")
        self.assertEqual(start_line, -1)
        self.assertEqual(body, [])

    def test_extract_func_body_standard(self) -> None:
        lines = [
            "extends Node2D",
            "",
            "func target_func(a: int) -> void:",
            "\tvar b = a + 1",
            "\treturn b",
            "",
            "func next_func():",
            "\tpass",
        ]
        start_line, body = _extract_func_body(lines, "target_func")
        self.assertEqual(start_line, 3)
        self.assertEqual(body, ["\tvar b = a + 1", "\treturn b", ""])

    def test_extract_func_body_static(self) -> None:
        lines = [
            "static func helper() -> bool:",
            "\tvar x = true",
            "\treturn x",
        ]
        start_line, body = _extract_func_body(lines, "helper")
        self.assertEqual(start_line, 1)
        self.assertEqual(body, ["\tvar x = true", "\treturn x"])

    def test_extract_func_body_annotated_on_same_line(self) -> None:
        lines = [
            "@warning_ignore('unused_parameter') func guarded(bee: Node2D) -> void:",
            "\tvar y = 2",
            "\treturn",
        ]
        start_line, body = _extract_func_body(lines, "guarded")
        self.assertEqual(start_line, 1)
        self.assertEqual(body, ["\tvar y = 2", "\treturn"])

    def test_extract_func_body_with_spaces_indent(self) -> None:
        lines = [
            "class_name Example",
            "",
            "    func indented_method():",
            "        var a = 1",
            "        var b = 2",
            "    func sibling():",
            "        pass",
        ]
        start_line, body = _extract_func_body(lines, "indented_method")
        self.assertEqual(start_line, 3)
        self.assertEqual(body, ["        var a = 1", "        var b = 2"])

    def test_extract_func_body_empty_function(self) -> None:
        lines = [
            "func empty():",
            "func next():",
            "\tpass",
        ]
        start_line, body = _extract_func_body(lines, "empty")
        self.assertEqual(start_line, 1)
        self.assertEqual(body, [])


if __name__ == "__main__":
    unittest.main()
