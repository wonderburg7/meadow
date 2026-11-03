"""Tests for tools/marker_reparent_check.py."""

from __future__ import annotations

import io
import os
import sys
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

# Add repo root to sys.path so marker_reparent_check is importable.
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import marker_reparent_check  # noqa: E402


class MarkerReparentCheckTests(unittest.TestCase):
    def test_challenge_runner_passes(self) -> None:
        """The committed challenge_runner.gd passes the marker reparent check."""
        path = ROOT / "scripts" / "challenge_runner.gd"
        self.assertTrue(path.is_file(), "scripts/challenge_runner.gd missing")
        problems = marker_reparent_check.check_file(path)
        self.assertEqual([], problems)

    def test_main_cli_default(self) -> None:
        """Running main() with default args succeeds and prints success message."""
        buf = io.StringIO()
        with redirect_stdout(buf):
            code = marker_reparent_check.main([])
        self.assertEqual(0, code)
        self.assertIn("reparenting is centralised", buf.getvalue())

    def test_main_cli_nonexistent_file_exits_nonzero(self) -> None:
        """A nonexistent requested input file causes main() to exit non-zero."""
        err_buf = io.StringIO()
        with redirect_stderr(err_buf):
            code = marker_reparent_check.main(["nonexistent_challenge_runner.gd"])
        self.assertEqual(1, code)
        self.assertIn("File not found", err_buf.getvalue())

    def test_missing_function_reported(self) -> None:
        """A file missing _update_marker reports an error."""
        sample = "func foo() -> void:\n\tpass\n"
        problems = marker_reparent_check.check_file("scripts/fake.gd", text=sample)
        self.assertTrue(any("func _update_marker not found" in p for p in problems))

    def test_commented_out_central_reparent_detected(self) -> None:
        """Commenting out the real central reparent must fail."""
        sample = """
func _update_marker(stage_id: String) -> void:
\tvar marker_parent: Node2D = null
\tif stage_id in ["1.2", "1.5", "1.6", "1.12", "1.15", "1.19"]:
\t\tmarker_parent = main.hive_root
\telif stage_id == "1.10":
\t\tmarker_parent = main.meadow_root
\t# if marker_parent != null and _marker.get_parent() != marker_parent:
\t# \t_marker.reparent(marker_parent, false)
\tif stage_id in ["1.2", "1.5"]:
\t\t_marker.position = Vector2.ZERO
"""
        problems = marker_reparent_check.check_update_marker(sample)
        self.assertTrue(any("does not perform centralised reparenting" in p for p in problems))

    def test_missing_parent_assignment_detected(self) -> None:
        """Missing parent assignment for meadow or hive stages must fail."""
        # Missing hive_root assignment
        sample_missing_hive = """
func _update_marker(stage_id: String) -> void:
\tvar marker_parent: Node2D = null
\telif stage_id == "1.10":
\t\tmarker_parent = main.meadow_root
\tif marker_parent != null and _marker.get_parent() != marker_parent:
\t\t_marker.reparent(marker_parent, false)
\tif stage_id in ["1.2", "1.5"]:
\t\t_marker.position = Vector2.ZERO
"""
        problems = marker_reparent_check.check_update_marker(sample_missing_hive)
        self.assertTrue(any("missing centralised hive_root assignment" in p for p in problems))

        # Missing meadow_root assignment
        sample_missing_meadow = """
func _update_marker(stage_id: String) -> void:
\tvar marker_parent: Node2D = null
\tif stage_id in ["1.2", "1.5", "1.6", "1.12", "1.15", "1.19"]:
\t\tmarker_parent = main.hive_root
\tif marker_parent != null and _marker.get_parent() != marker_parent:
\t\t_marker.reparent(marker_parent, false)
\tif stage_id in ["1.2", "1.5"]:
\t\t_marker.position = Vector2.ZERO
"""
        problems = marker_reparent_check.check_update_marker(sample_missing_meadow)
        self.assertTrue(any("missing centralised meadow_root assignment" in p for p in problems))

    def test_uncovered_marker_stages_detected(self) -> None:
        """Uncovered marker stages (omitting an expected stage) must fail."""
        sample = """
func _update_marker(stage_id: String) -> void:
\tvar marker_parent: Node2D = null
\tif stage_id in ["1.2", "1.5", "1.6", "1.12", "1.19"]:
\t\tmarker_parent = main.hive_root
\telif stage_id == "1.10":
\t\tmarker_parent = main.meadow_root
\tif marker_parent != null and _marker.get_parent() != marker_parent:
\t\t_marker.reparent(marker_parent, false)

\tif stage_id in ["1.2", "1.5", "1.12", "1.15"]:
\t\t_marker.position = main.world_building._hive_centre_local()
"""
        problems = marker_reparent_check.check_update_marker(sample)
        self.assertTrue(any("missing expected stages: ['1.15']" in p for p in problems))

    def test_wrong_ordering_detected(self) -> None:
        """Positioning before reparenting must fail in both functions."""
        # In _update_marker
        bad_update_order = """
func _update_marker(stage_id: String) -> void:
\tvar marker_parent: Node2D = null
\t_marker.position = Vector2.ZERO
\tif stage_id in ["1.2", "1.5", "1.6", "1.12", "1.15", "1.19"]:
\t\tmarker_parent = main.hive_root
\telif stage_id == "1.10":
\t\tmarker_parent = main.meadow_root
\tif marker_parent != null and _marker.get_parent() != marker_parent:
\t\t_marker.reparent(marker_parent, false)
"""
        problems = marker_reparent_check.check_update_marker(bad_update_order)
        self.assertTrue(any("sets '_marker.position' before centralised reparenting" in p for p in problems))

        # In _show_current_visit_point
        bad_visit_order = """
func _show_current_visit_point() -> void:
\t_marker.position = _visit_points[_visit_point_index].position
\tif _marker.get_parent() != _visit_marker_parent:
\t\t_marker.reparent(_visit_marker_parent, false)
"""
        problems = marker_reparent_check.check_visit_point(bad_visit_order)
        self.assertTrue(any("sets '_marker.position' before reparenting" in p for p in problems))

    def test_branch_local_reparent_detected(self) -> None:
        """Mutation: reintroducing per-branch reparenting after centralised block fails."""
        sample = """
func _update_marker(stage_id: String) -> void:
\tvar marker_parent: Node2D = null
\tif stage_id in ["1.2", "1.5", "1.6", "1.12", "1.15", "1.19"]:
\t\tmarker_parent = main.hive_root
\telif stage_id == "1.10":
\t\tmarker_parent = main.meadow_root
\tif marker_parent != null and _marker.get_parent() != marker_parent:
\t\t_marker.reparent(marker_parent, false)

\tif stage_id == "1.10":
\t\t_marker.reparent(main.meadow_root, false)
\t\t_marker.position = main.hive.position
"""
        problems = marker_reparent_check.check_update_marker(sample)
        self.assertTrue(any("branch-local '_marker.reparent' call" in p for p in problems))

    def test_show_current_visit_point_valid(self) -> None:
        """_show_current_visit_point valid executable code passes."""
        sample = """
func _show_current_visit_point() -> void:
\tif _marker == null or not is_instance_valid(_marker):
\t\treturn
\tif _visit_point_index >= _visit_points.size():
\t\t_set_marker_visible(false)
\t\treturn
\tif _marker.get_parent() != _visit_marker_parent:
\t\t_marker.reparent(_visit_marker_parent, false)
\t_marker.position = _visit_points[_visit_point_index].position
\t_set_marker_visible(true)
"""
        problems = marker_reparent_check.check_visit_point(sample)
        self.assertEqual([], problems)


if __name__ == "__main__":
    unittest.main()
