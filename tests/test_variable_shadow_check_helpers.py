"""Unit tests for pure helper functions in tools/variable_shadow_check.py."""

from __future__ import annotations

from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import variable_shadow_check  # noqa: E402


class VariableShadowCheckHelpersTests(unittest.TestCase):
    def test_get_inherited_properties_object_and_refcounted_empty(self) -> None:
        self.assertEqual(variable_shadow_check.get_inherited_properties("Object"), set())
        self.assertEqual(variable_shadow_check.get_inherited_properties("RefCounted"), set())

    def test_get_inherited_properties_unknown_class_empty(self) -> None:
        self.assertEqual(variable_shadow_check.get_inherited_properties("NonexistentClass"), set())

    def test_get_inherited_properties_node_hierarchy(self) -> None:
        node_props = variable_shadow_check.get_inherited_properties("Node")
        self.assertIn("name", node_props)
        self.assertIn("owner", node_props)
        self.assertIn("process_mode", node_props)

    def test_get_inherited_properties_canvas_item_hierarchy(self) -> None:
        canvas_props = variable_shadow_check.get_inherited_properties("CanvasItem")
        # Direct CanvasItem properties
        self.assertIn("visible", canvas_props)
        self.assertIn("modulate", canvas_props)
        self.assertIn("z_index", canvas_props)
        # Inherited from Node
        self.assertIn("name", canvas_props)
        self.assertIn("owner", canvas_props)

    def test_get_inherited_properties_node2d_hierarchy(self) -> None:
        node2d_props = variable_shadow_check.get_inherited_properties("Node2D")
        # Direct Node2D properties
        self.assertIn("position", node2d_props)
        self.assertIn("rotation", node2d_props)
        self.assertIn("scale", node2d_props)
        # Inherited from CanvasItem
        self.assertIn("visible", node2d_props)
        # Inherited from Node
        self.assertIn("name", node2d_props)

    def test_get_inherited_properties_polygon2d_hierarchy(self) -> None:
        poly_props = variable_shadow_check.get_inherited_properties("Polygon2D")
        # Direct Polygon2D properties
        self.assertIn("offset", poly_props)
        self.assertIn("polygon", poly_props)
        # Inherited from Node2D
        self.assertIn("scale", poly_props)
        self.assertIn("position", poly_props)
        # Inherited from CanvasItem
        self.assertIn("visible", poly_props)
        # Inherited from Node
        self.assertIn("name", poly_props)

    def test_get_inherited_properties_custom_base_class(self) -> None:
        panel_props = variable_shadow_check.get_inherited_properties("GamePanel")
        # GamePanel -> CanvasLayer -> Node
        self.assertIn("layer", panel_props)
        self.assertIn("offset", panel_props)
        self.assertIn("visible", panel_props)
        self.assertIn("name", panel_props)

    def test_tracked_gd_files_returns_empty_when_no_scripts_dir(self) -> None:
        with tempfile.TemporaryDirectory() as scratch:
            scratch_path = Path(scratch)
            files = variable_shadow_check.tracked_gd_files(scratch_path)
            self.assertEqual(files, [])

    def test_tracked_gd_files_finds_all_gd_files_sorted(self) -> None:
        with tempfile.TemporaryDirectory() as scratch:
            scratch_path = Path(scratch)
            scripts_dir = scratch_path / "scripts"
            nested_dir = scripts_dir / "sub"
            nested_dir.mkdir(parents=True)

            (scripts_dir / "b.gd").write_text("extends Node\n", encoding="utf-8")
            (scripts_dir / "a.gd").write_text("extends Node\n", encoding="utf-8")
            (nested_dir / "c.gd").write_text("extends Node\n", encoding="utf-8")
            (scripts_dir / "ignore.txt").write_text("hello\n", encoding="utf-8")

            files = variable_shadow_check.tracked_gd_files(scratch_path)
            rel_files = [f.relative_to(scratch_path).as_posix() for f in files]
            self.assertEqual(rel_files, ["scripts/a.gd", "scripts/b.gd", "scripts/sub/c.gd"])


if __name__ == "__main__":
    unittest.main()
