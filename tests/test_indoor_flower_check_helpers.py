"""Pure function-body extraction cases selected from Jules PRs #149 and #156."""

from __future__ import annotations

import unittest
from tools.indoor_flower_check import (
    _extract_func_body,
)


class TestIndoorFlowerCheckHelpers(unittest.TestCase):
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

    def test_extract_func_body_annotated_func(self) -> None:
        lines = [
            "@warning_ignore(\"unused_parameter\")",
            "func on_event(event) -> void:",
            "\tprint(event)",
        ]
        start_line, body = _extract_func_body(lines, "on_event")
        self.assertEqual(start_line, 2)
        self.assertEqual(body, ["\tprint(event)"])


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



if __name__ == "__main__":
    unittest.main()
