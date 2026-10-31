"""Unit tests for tools/variable_shadow_check.py."""

from __future__ import annotations

import io
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

from tools import variable_shadow_check


class TestVariableShadowCheck(unittest.TestCase):
    def test_clean_script_passes(self):
        script = """extends Node2D

var bee_count: int = 0

func _ready() -> void:
	for i in range(10):
		print(i)
"""
        problems = variable_shadow_check.check_file("scripts/fake.gd", script)
        self.assertEqual(problems, [])

    def test_refcounted_does_not_shadow_node2d_properties(self):
        # A RefCounted script declaring var offset or var scale is fine
        script = """extends RefCounted

var offset: Vector2 = Vector2.ZERO
var scale: float = 1.0

func _process_step() -> void:
	var name := "sample"
"""
        problems = variable_shadow_check.check_file("scripts/fake_ref.gd", script)
        self.assertEqual(problems, [])

    def test_polygon2d_offset_shadowing_detected(self):
        script = """extends Polygon2D

var offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	pass
"""
        problems = variable_shadow_check.check_file("scripts/fake_poly.gd", script)
        self.assertEqual(len(problems), 1)
        self.assertIn("variable 'offset' shadows built-in property from Polygon2D", problems[0])

    def test_node2d_scale_shadowing_detected(self):
        script = """extends Node2D

func resize() -> void:
	var scale: float = 2.0
"""
        problems = variable_shadow_check.check_file("scripts/fake_node2d.gd", script)
        self.assertEqual(len(problems), 1)
        self.assertIn("variable 'scale' shadows built-in property from Node2D", problems[0])

    def test_node_name_loop_variable_shadowing_detected(self):
        script = """extends Node

func inspect_items() -> void:
	for name in items:
		print(name)
"""
        problems = variable_shadow_check.check_file("scripts/fake_node.gd", script)
        self.assertEqual(len(problems), 1)
        self.assertIn("loop variable 'name' shadows built-in property from Node", problems[0])

    def test_comments_and_strings_ignored(self):
        script = """extends Node2D

# var scale: float = 1.0
func test() -> void:
	var msg := "var scale = 2.0"
	# for position in items:
"""
        problems = variable_shadow_check.check_file("scripts/fake_comments.gd", script)
        self.assertEqual(problems, [])

    def test_game_panel_inherits_canvaslayer_properties(self):
        script = """extends GamePanel

var offset: Vector2 = Vector2.ZERO
"""
        problems = variable_shadow_check.check_file("scripts/fake_panel.gd", script)
        self.assertEqual(len(problems), 1)
        self.assertIn("variable 'offset' shadows built-in property from GamePanel", problems[0])

    def test_strip_code_helper(self):
        self.assertEqual(variable_shadow_check.strip_code('var x = "hello # world" # comment'), 'var x = "" ')
        self.assertEqual(variable_shadow_check.strip_code("var y = 123"), "var y = 123")

    def test_main_cli_exit_codes(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            clean_file = Path(tmpdir) / "clean.gd"
            clean_file.write_text("extends RefCounted\nvar clean := 1\n", encoding="utf-8")

            bad_file = Path(tmpdir) / "bad.gd"
            bad_file.write_text("extends Node2D\nvar scale := 1.0\n", encoding="utf-8")

            # Clean run exits 0
            stdout_buf = io.StringIO()
            with redirect_stdout(stdout_buf):
                exit_code = variable_shadow_check.main([str(clean_file)])
            self.assertEqual(exit_code, 0)
            self.assertIn("no shadowed properties", stdout_buf.getvalue())

            # Bad run exits 1
            stderr_buf = io.StringIO()
            with redirect_stderr(stderr_buf):
                exit_code = variable_shadow_check.main([str(bad_file)])
            self.assertEqual(exit_code, 1)
            self.assertIn("FAILED -- variable shadow check found problems", stderr_buf.getvalue())


if __name__ == "__main__":
    unittest.main()
