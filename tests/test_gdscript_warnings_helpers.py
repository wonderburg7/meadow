"""Unit tests for pure helper functions in tools/gdscript_warnings.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from gdscript_warnings import as_res_path, script_warnings  # noqa: E402


class GdscriptWarningsHelpersTest(unittest.TestCase):
    def test_as_res_path_preserves_res_prefix(self) -> None:
        self.assertEqual(as_res_path("res://scripts/hud.gd"), "res://scripts/hud.gd")
        self.assertEqual(as_res_path("res://scenes/Main.tscn"), "res://scenes/Main.tscn")

    def test_as_res_path_normalises_relative_and_windows_paths(self) -> None:
        self.assertEqual(as_res_path("scripts/hud.gd"), "res://scripts/hud.gd")
        self.assertEqual(as_res_path("./scripts/hud.gd"), "res://scripts/hud.gd")
        self.assertEqual(as_res_path("scripts\\hud.gd"), "res://scripts/hud.gd")
        self.assertEqual(as_res_path(".\\scripts\\sub\\tool.gd"), "res://scripts/sub/tool.gd")

    def test_script_warnings_empty_when_no_warnings(self) -> None:
        output = "Godot Engine v4.7.dev.custom_build\nBooting meadow...\nSimulation complete.\n"
        self.assertEqual(script_warnings(output), [])

    def test_script_warnings_parses_warning_and_reload_location(self) -> None:
        output = (
            "WARNING: The variable 'counter' is never used.\n"
            "   at: GDScript::reload (res://scripts/hud.gd:629)\n"
            "Normal stdout log message.\n"
            "WARNING: Narrowing conversion from float to int.\n"
            "   at: GDScript::reload (res://scripts/bee.gd:105)\n"
        )
        expected = [
            ("res://scripts/hud.gd", 629, "The variable 'counter' is never used."),
            ("res://scripts/bee.gd", 105, "Narrowing conversion from float to int."),
        ]
        self.assertEqual(script_warnings(output), expected)

    def test_script_warnings_ignores_orphan_warning_line(self) -> None:
        output = (
            "WARNING: Standalone warning without GDScript reload stack frame\n"
            "Another irrelevant line\n"
            "WARNING: The property 'shadow' is shadowed.\n"
            "   at: GDScript::reload (res://scripts/flower.gd:42)\n"
        )
        self.assertEqual(
            script_warnings(output),
            [("res://scripts/flower.gd", 42, "The property 'shadow' is shadowed.")],
        )

    def test_script_warnings_deduplicates_identical_warnings(self) -> None:
        output = (
            "WARNING: The variable 'unused' is never used.\n"
            "   at: GDScript::reload (res://scripts/hud.gd:12)\n"
            "WARNING: The variable 'unused' is never used.\n"
            "   at: GDScript::reload (res://scripts/hud.gd:12)\n"
        )
        self.assertEqual(
            script_warnings(output),
            [("res://scripts/hud.gd", 12, "The variable 'unused' is never used.")],
        )


if __name__ == "__main__":
    unittest.main()
