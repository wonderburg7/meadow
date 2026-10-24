"""Unit tests for tools/typed_array_assign_check.py."""

import os
import sys
import tempfile
import unittest
from pathlib import Path

# Add repo root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from tools.typed_array_assign_check import (
    collect_typed_properties,
    find_assignments_in_content,
    check_typed_array_assignments,
)


class TestTypedArrayAssignCheck(unittest.TestCase):

    def test_repo_passes_check(self):
        """The repository itself must pass typed_array_assign_check."""
        repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        errors = check_typed_array_assignments(repo_root)
        self.assertEqual(errors, [], f"Expected no errors on repo, got: {errors}")

    def test_collect_typed_properties(self):
        """Test collecting var declarations of Array[...] and Dictionary[...] types."""
        with tempfile.TemporaryDirectory() as tmpdir:
            scripts_dir = Path(tmpdir) / "scripts"
            scripts_dir.mkdir()

            script_a = scripts_dir / "script_a.gd"
            script_a.write_text(
                "var known_patches: Array[Vector2] = []\n"
                "var my_dict: Dictionary[String, int] = {}\n"
                "var plain_var = 123\n",
                encoding="utf-8"
            )

            props = collect_typed_properties(tmpdir)
            self.assertIn("known_patches", props)
            self.assertIn("my_dict", props)
            self.assertNotIn("plain_var", props)

            decl_path, prop_type = props["known_patches"][0]
            self.assertEqual(decl_path, str(script_a.resolve()))
            self.assertEqual(prop_type, "Array")

            decl_path, prop_type = props["my_dict"][0]
            self.assertEqual(decl_path, str(script_a.resolve()))
            self.assertEqual(prop_type, "Dictionary")

    def test_same_file_assignment_passes(self):
        """Assignments within the same declaring script must pass."""
        with tempfile.TemporaryDirectory() as tmpdir:
            scripts_dir = Path(tmpdir) / "scripts"
            scripts_dir.mkdir()

            script_a = scripts_dir / "script_a.gd"
            script_a.write_text(
                "var known_patches: Array[Vector2] = []\n"
                "func reset():\n"
                "    self.known_patches = []\n",
                encoding="utf-8"
            )

            props = collect_typed_properties(tmpdir)
            errors = find_assignments_in_content(
                script_a.read_text(encoding="utf-8"),
                str(script_a),
                props
            )
            self.assertEqual(errors, [])

    def test_cross_file_assignment_fails(self):
        """Assignments across different script files must fail."""
        with tempfile.TemporaryDirectory() as tmpdir:
            scripts_dir = Path(tmpdir) / "scripts"
            scripts_dir.mkdir()

            script_a = scripts_dir / "script_a.gd"
            script_a.write_text(
                "var known_patches: Array[Vector2] = []\n",
                encoding="utf-8"
            )

            script_b = scripts_dir / "script_b.gd"
            script_b.write_text(
                "func _process(delta):\n"
                "    bee.known_patches = []\n",
                encoding="utf-8"
            )

            props = collect_typed_properties(tmpdir)
            errors = find_assignments_in_content(
                script_b.read_text(encoding="utf-8"),
                str(script_b),
                props
            )
            self.assertEqual(len(errors), 1)
            self.assertEqual(errors[0]["property"], "known_patches")
            self.assertEqual(errors[0]["assigned_val"], "[]")
            self.assertEqual(errors[0]["line"], 2)

    def test_bee_known_patches_mutation_proof(self):
        """Adding `bee.known_patches = []` to a fixture/script causes check_typed_array_assignments to fail."""
        with tempfile.TemporaryDirectory() as tmpdir:
            scripts_dir = Path(tmpdir) / "scripts"
            scripts_dir.mkdir()

            bee_script = scripts_dir / "bee.gd"
            bee_script.write_text(
                "var known_patches: Array[Vector2] = []\n",
                encoding="utf-8"
            )

            other_script = scripts_dir / "other.gd"
            other_script.write_text(
                "func clear_bee(bee):\n"
                "    bee.known_patches = []\n",
                encoding="utf-8"
            )

            errors = check_typed_array_assignments(tmpdir)
            self.assertEqual(len(errors), 1)
            self.assertEqual(errors[0]["property"], "known_patches")


if __name__ == "__main__":
    unittest.main()
