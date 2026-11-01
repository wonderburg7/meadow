"""Unit tests for tools/marker_reparent_check.py."""

from __future__ import annotations

import io
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

from tools import marker_reparent_check


class TestMarkerReparentCheck(unittest.TestCase):
    def test_clean_challenge_runner_passes(self):
        problems = marker_reparent_check.check_file(
            Path("scripts/challenge_runner.gd")
        )
        self.assertEqual(problems, [])

    def test_script_without_update_marker_is_ignored(self):
        script = """extends Node2D

func other_func() -> void:
\tpass
"""
        problems = marker_reparent_check.check_marker_reparenting("scripts/other.gd", script)
        self.assertEqual(problems, [])

    def test_missing_marker_reparent_call_fails(self):
        script = """extends Node2D

func _update_marker(stage_id: String) -> void:
\tif stage_id in ["1.2"]:
\t\t_marker.position = Vector2(10, 20)
\t\t_set_marker_visible(true)
"""
        problems = marker_reparent_check.check_marker_reparenting("scripts/test.gd", script)
        self.assertEqual(len(problems), 1)
        self.assertIn("lacks _marker.reparent call", problems[0])

    def test_reparent_after_position_assignment_fails(self):
        script = """extends Node2D

func _update_marker(stage_id: String) -> void:
\tif stage_id in ["1.2"]:
\t\t_marker.position = Vector2(10, 20)
\t\t_set_marker_visible(true)
\t_marker.reparent(main.hive_root, false)
"""
        problems = marker_reparent_check.check_marker_reparenting("scripts/test.gd", script)
        self.assertTrue(any("after _marker.position was assigned" in p for p in problems))

    def test_unparented_stage_branch_detected(self):
        # Reproduces the pitfall from docs/known-pitfalls.md:
        # stages 1.2, 1.5, 1.12, 1.15 missing from marker_parent assignment.
        script = """extends Node2D

func _update_marker(stage_id: String) -> void:
\tvar marker_parent: Node2D = null
\tif stage_id in ["1.6", "1.19"]:
\t\tmarker_parent = main.hive_root
\telif stage_id == "1.10":
\t\tmarker_parent = main.meadow_root
\tif marker_parent != null and _marker.get_parent() != marker_parent:
\t\t_marker.reparent(marker_parent, false)

\tif stage_id in ["1.2", "1.5", "1.12", "1.15"]:
\t\t_marker.position = Vector2.ZERO
\t\t_set_marker_visible(true)
\telif stage_id in ["1.6", "1.19"]:
\t\t_marker.position = Vector2(10, 10)
\t\t_set_marker_visible(true)
\telif stage_id == "1.10":
\t\t_marker.position = Vector2(20, 20)
\t\t_set_marker_visible(true)
"""
        problems = marker_reparent_check.check_marker_reparenting("scripts/test.gd", script)
        self.assertEqual(len(problems), 1)
        self.assertIn("stages ['1.12', '1.15', '1.2', '1.5'] set marker position", problems[0])
        self.assertIn("have no marker_parent assigned before reparenting", problems[0])

    def test_strip_code_helper(self):
        self.assertEqual(marker_reparent_check.strip_code('var x = "hello # not comment" # comment'), 'var x = "" ')
        self.assertEqual(marker_reparent_check.strip_code("var y = 123"), "var y = 123")

    def test_main_cli_exit_codes(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            clean_file = Path(tmpdir) / "clean.gd"
            clean_file.write_text("""extends Node2D

func _update_marker(stage_id: String) -> void:
\tvar marker_parent: Node2D = null
\tif stage_id in ["1.2"]:
\t\tmarker_parent = main.hive_root
\tif marker_parent != null:
\t\t_marker.reparent(marker_parent, false)
\tif stage_id in ["1.2"]:
\t\t_marker.position = Vector2.ZERO
\t\t_set_marker_visible(true)
""", encoding="utf-8")

            bad_file = Path(tmpdir) / "bad.gd"
            bad_file.write_text("""extends Node2D

func _update_marker(stage_id: String) -> void:
\t_marker.position = Vector2.ZERO
\t_set_marker_visible(true)
""", encoding="utf-8")

            stdout_buf = io.StringIO()
            with redirect_stdout(stdout_buf):
                exit_code = marker_reparent_check.main([str(clean_file)])
            self.assertEqual(exit_code, 0)
            self.assertIn("marker reparent check clean", stdout_buf.getvalue())

            stderr_buf = io.StringIO()
            with redirect_stderr(stderr_buf):
                exit_code = marker_reparent_check.main([str(bad_file)])
            self.assertEqual(exit_code, 1)
            self.assertIn("FAILED -- marker reparent check found problems", stderr_buf.getvalue())

            missing_stderr = io.StringIO()
            with redirect_stderr(missing_stderr):
                exit_code = marker_reparent_check.main([str(Path(tmpdir) / "nonexistent.gd")])
            self.assertEqual(exit_code, 1)
            self.assertIn("file not found", missing_stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
