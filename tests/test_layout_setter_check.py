#!/usr/bin/env python3
"""Tests for tools/layout_setter_check.py."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.layout_setter_check import ROOT, check_layout_setters


class TestLayoutSetterCheck(unittest.TestCase):
    def test_repository_file_passes(self) -> None:
        target = ROOT / "scripts" / "ui_panel_layout.gd"
        text = target.read_text(encoding="utf-8")
        diagnostics = check_layout_setters(text, file_path="scripts/ui_panel_layout.gd")
        self.assertEqual(
            diagnostics,
            [],
            f"Expected scripts/ui_panel_layout.gd to have no forbidden setters, got: {diagnostics}",
        )

    def test_allowed_constructs(self) -> None:
        code = """extends RefCounted

static func apply(panel: PanelContainer, rect: Rect2) -> void:
	panel.anchor_left = 0.0
	panel.offset_left = rect.position.x
	panel.offset_right = rect.position.x + rect.size.x
	var height: float = minf(panel.get_combined_minimum_size().y, rect.size.y)
"""
        diagnostics = check_layout_setters(code, file_path="test_file.gd")
        self.assertEqual(diagnostics, [])

    def test_comment_and_string_exclusions(self) -> None:
        code = """extends RefCounted
# panel.size = Vector2(10, 10)
# panel.set_size(Vector2(10, 10))
# panel.position.x = 5
static func apply(panel: PanelContainer) -> void:
	var msg = "panel.size = Vector2(10, 10) and panel.reset_size()"
	var multiline = \"\"\"
	panel.global_position.y += 10
	panel.set_position(Vector2.ZERO)
	\"\"\"
"""
        diagnostics = check_layout_setters(code, file_path="test_file.gd")
        self.assertEqual(diagnostics, [])

    def test_forbidden_assignments_and_setters(self) -> None:
        cases = [
            ("panel.size = Vector2(100, 100)", "forbidden layout property assignment"),
            ("panel.size.x = 100", "forbidden layout property assignment"),
            ("panel.size.y += 20", "forbidden layout property assignment"),
            ("panel.position = Vector2(0, 0)", "forbidden layout property assignment"),
            ("panel.position.x -= 5", "forbidden layout property assignment"),
            ("panel.global_position = Vector2(10, 10)", "forbidden layout property assignment"),
            ("panel.global_position.y *= 2", "forbidden layout property assignment"),
            ("panel.set_size(Vector2(50, 50))", "forbidden layout method call"),
            ("panel.set_position(Vector2(10, 10))", "forbidden layout method call"),
            ("panel.reset_size()", "forbidden layout method call"),
        ]

        for code_line, expected_substring in cases:
            with self.subTest(code_line=code_line):
                code = f"func test():\n\t{code_line}\n"
                diagnostics = check_layout_setters(code, file_path="test_file.gd")
                self.assertTrue(
                    len(diagnostics) == 1 and expected_substring in diagnostics[0],
                    f"Expected diagnostic containing '{expected_substring}' for '{code_line}', got: {diagnostics}",
                )


if __name__ == "__main__":
    unittest.main()
