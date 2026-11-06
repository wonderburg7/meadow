"""Unit tests for tools/indoor_flower_check.py.

Guards the coordinate space pitfall (docs/known-pitfalls.md):
"A bee under hive_root is in hive-local coordinates; a flower is not (19 Sep 2026)."
"""

from __future__ import annotations

import io
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

from tools.indoor_flower_check import (
    check_bee_focus,
    check_bee_foraging,
    check_file,
    main,
    strip_code,
    strip_code_line,
)

VALID_FORAGING_FIXTURE = """\
static func _walk_out_if_indoors(bee: Node2D) -> bool:
\tif not bee._is_inside_hive():
\t\treturn false
\tbee.state = autonomous_state(bee, State.IN_HIVE_TO_EXIT)
\treturn true

static func seek_flower(bee: Node2D) -> void:
\tif _walk_out_if_indoors(bee):
\t\treturn
\tvar best := _perceive_flower(bee)

static func search_for_flower(bee: Node2D, delta: float) -> void:
\tif _walk_out_if_indoors(bee):
\t\treturn
\tBeeMovement.move_towards(bee, bee.search_waypoint, delta)
"""

VALID_BEE_FOCUS_FIXTURE = """\
func set_focus(type: String) -> void:
\tif not _is_inside_hive():
\t\tstate = State.SEEK_FLOWER
\telif state == State.IDLING:
\t\tstate = State.IN_HIVE_TO_EXIT
"""


class TestIndoorFlowerCheckHelpers(unittest.TestCase):
    def test_strip_code_line(self) -> None:
        self.assertEqual(strip_code_line('var x = "hello # not a comment" # comment'), 'var x = "" ')
        self.assertEqual(strip_code_line("   # full comment"), "   ")
        self.assertEqual(strip_code_line("var a = 1"), "var a = 1")

    def test_strip_code(self) -> None:
        text = "var a = 1 # first\n# full\nvar b = 'two'"
        self.assertEqual(strip_code(text), 'var a = 1 \n\nvar b = ""')


class TestIndoorFlowerCheckLogic(unittest.TestCase):
    def test_valid_fixtures_pass(self) -> None:
        self.assertEqual(check_bee_foraging(VALID_FORAGING_FIXTURE), [])
        self.assertEqual(check_bee_focus(VALID_BEE_FOCUS_FIXTURE), [])

    def test_missing_walk_out_fails(self) -> None:
        broken = """\
static func seek_flower(bee: Node2D) -> void:
\tvar best := _perceive_flower(bee)
"""
        problems = check_bee_foraging(broken)
        self.assertTrue(any("static func _walk_out_if_indoors(bee) not found" in p for p in problems))

    def test_seek_flower_missing_indoor_guard_fails(self) -> None:
        broken = """\
static func _walk_out_if_indoors(bee: Node2D) -> bool:
\tif not bee._is_inside_hive():
\t\treturn false
\tbee.state = autonomous_state(bee, State.IN_HIVE_TO_EXIT)
\treturn true

static func seek_flower(bee: Node2D) -> void:
\tvar best := _perceive_flower(bee)

static func search_for_flower(bee: Node2D, delta: float) -> void:
\tif _walk_out_if_indoors(bee):
\t\treturn
"""
        problems = check_bee_foraging(broken)
        self.assertTrue(any("seek_flower must start with 'if _walk_out_if_indoors(bee):'" in p for p in problems))

    def test_guarded_returns_become_pass_fails(self) -> None:
        broken = """\
static func _walk_out_if_indoors(bee: Node2D) -> bool:
\tif not bee._is_inside_hive():
\t\treturn false
\tbee.state = autonomous_state(bee, State.IN_HIVE_TO_EXIT)
\treturn true

static func seek_flower(bee: Node2D) -> void:
\tif _walk_out_if_indoors(bee):
\t\tpass
\tvar best := _perceive_flower(bee)

static func search_for_flower(bee: Node2D, delta: float) -> void:
\tif _walk_out_if_indoors(bee):
\t\tpass
\tBeeMovement.move_towards(bee, bee.search_waypoint, delta)
"""
        problems = check_bee_foraging(broken)
        self.assertEqual(len(problems), 2)
        self.assertTrue(any("seek_flower must immediately 'return'" in p for p in problems))
        self.assertTrue(any("search_for_flower must immediately 'return'" in p for p in problems))

    def test_walk_out_returns_false_indoors_fails(self) -> None:
        broken = """\
static func _walk_out_if_indoors(bee: Node2D) -> bool:
\tif bee._is_inside_hive():
\t\treturn false
\tbee.state = autonomous_state(bee, State.IN_HIVE_TO_EXIT)
\treturn true

static func seek_flower(bee: Node2D) -> void:
\tif _walk_out_if_indoors(bee):
\t\treturn

static func search_for_flower(bee: Node2D, delta: float) -> void:
\tif _walk_out_if_indoors(bee):
\t\treturn
"""
        problems = check_bee_foraging(broken)
        self.assertTrue(any("_walk_out_if_indoors must return false when not bee._is_inside_hive()" in p for p in problems))

    def test_walk_out_missing_return_true_fails(self) -> None:
        broken = """\
static func _walk_out_if_indoors(bee: Node2D) -> bool:
\tif not bee._is_inside_hive():
\t\treturn false
\tbee.state = autonomous_state(bee, State.IN_HIVE_TO_EXIT)

static func seek_flower(bee: Node2D) -> void:
\tif _walk_out_if_indoors(bee):
\t\treturn

static func search_for_flower(bee: Node2D, delta: float) -> void:
\tif _walk_out_if_indoors(bee):
\t\treturn
"""
        problems = check_bee_foraging(broken)
        self.assertTrue(any("_walk_out_if_indoors must return true when bee is inside hive" in p for p in problems))

    def test_walk_out_missing_autonomous_state_fails(self) -> None:
        broken = """\
static func _walk_out_if_indoors(bee: Node2D) -> bool:
\tif not bee._is_inside_hive():
\t\treturn false
\tbee.state = State.IN_HIVE_TO_EXIT
\treturn true

static func seek_flower(bee: Node2D) -> void:
\tif _walk_out_if_indoors(bee):
\t\treturn

static func search_for_flower(bee: Node2D, delta: float) -> void:
\tif _walk_out_if_indoors(bee):
\t\treturn
"""
        problems = check_bee_foraging(broken)
        self.assertTrue(any("must set State.IN_HIVE_TO_EXIT via autonomous_state" in p for p in problems))

    def test_set_focus_unguarded_seek_flower_fails(self) -> None:
        broken = """\
func set_focus(type: String) -> void:
\tstate = State.SEEK_FLOWER
\tstate = State.IN_HIVE_TO_EXIT
"""
        problems = check_bee_focus(broken)
        self.assertTrue(any("is not enclosed in 'if not _is_inside_hive():'" in p for p in problems))

    def test_set_focus_final_unguarded_seek_flower_fails(self) -> None:
        broken = """\
func set_focus(type: String) -> void:
\tif not _is_inside_hive():
\t\tstate = State.SEEK_FLOWER
\telif state == State.IDLING:
\t\tstate = State.IN_HIVE_TO_EXIT
\tstate = State.SEEK_FLOWER
"""
        problems = check_bee_focus(broken)
        self.assertTrue(any("is not enclosed in 'if not _is_inside_hive():'" in p for p in problems))

    def test_set_focus_missing_indoor_exit_fails(self) -> None:
        broken = """\
func set_focus(type: String) -> void:
\tif not _is_inside_hive():
\t\tstate = State.SEEK_FLOWER
"""
        problems = check_bee_focus(broken)
        self.assertTrue(any("does not route indoor bees to State.IN_HIVE_TO_EXIT" in p for p in problems))


class TestIndoorFlowerCheckCLI(unittest.TestCase):
    def test_main_on_real_repo_files(self) -> None:
        out = io.StringIO()
        err = io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            exit_code = main([])
        self.assertEqual(exit_code, 0)
        self.assertIn("indoor flower check: 2 file(s) checked, coordinate space invariants verified", out.getvalue())

    def test_main_on_nonexistent_file(self) -> None:
        err = io.StringIO()
        with redirect_stderr(err):
            exit_code = main(["nonexistent_file.gd"])
        self.assertEqual(exit_code, 1)
        self.assertIn("nonexistent_file.gd: file not found", err.getvalue())

    def test_main_on_failing_fixture_file(self) -> None:
        with tempfile.NamedTemporaryFile("w", suffix=".gd", delete=False) as f:
            f.write("func set_focus(type: String) -> void:\n\tstate = State.SEEK_FLOWER\n")
            temp_path = f.name
        try:
            err = io.StringIO()
            with redirect_stderr(err):
                exit_code = main([temp_path])
            self.assertEqual(exit_code, 1)
            self.assertIn("FAILED -- indoor flower check found problems:", err.getvalue())
        finally:
            Path(temp_path).unlink(missing_ok=True)


if __name__ == "__main__":
    unittest.main()
