"""Unit tests for helpers and edge cases in tools/typed_array_assign_check.py."""

from __future__ import annotations

import io
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from tools.typed_array_assign_check import (
    check_typed_array_assignments,
    collect_typed_properties,
    find_assignments_in_content,
    main,
)


class TestTypedArrayAssignCheckHelpers(unittest.TestCase):
    def test_collect_typed_properties_no_scripts_dir(self) -> None:
        """When scripts/ directory does not exist, return an empty dictionary."""
        with tempfile.TemporaryDirectory() as tmpdir:
            props = collect_typed_properties(tmpdir)
            self.assertEqual(props, {})

    def test_collect_typed_properties_read_error_skipped(self) -> None:
        """Files that raise read errors during collect_typed_properties are skipped."""
        with tempfile.TemporaryDirectory() as tmpdir:
            scripts_dir = Path(tmpdir) / "scripts"
            scripts_dir.mkdir()
            good_script = scripts_dir / "good.gd"
            good_script.write_text("var good_arr: Array[int] = []\n", encoding="utf-8")

            bad_script = scripts_dir / "unreadable.gd"
            bad_script.write_text("var bad_arr: Array[int] = []\n", encoding="utf-8")

            orig_read_text = Path.read_text

            def mock_read_text(self_path: Path, *args, **kwargs) -> str:
                if self_path.name == "unreadable.gd":
                    raise OSError("Simulated read error")
                return orig_read_text(self_path, *args, **kwargs)

            with patch.object(Path, "read_text", autospec=True, side_effect=mock_read_text):
                props = collect_typed_properties(tmpdir)
                self.assertIn("good_arr", props)
                self.assertNotIn("bad_arr", props)

    def test_collect_typed_properties_ignores_commented_declarations(self) -> None:
        """Declarations inside comments are ignored."""
        with tempfile.TemporaryDirectory() as tmpdir:
            scripts_dir = Path(tmpdir) / "scripts"
            scripts_dir.mkdir()
            script = scripts_dir / "comments.gd"
            script.write_text(
                "# var comment_arr: Array[String] = []\n"
                "var valid_arr: Array[float] = [] # var inline_comment: Array[int] = []\n",
                encoding="utf-8",
            )
            props = collect_typed_properties(tmpdir)
            self.assertIn("valid_arr", props)
            self.assertNotIn("comment_arr", props)
            self.assertNotIn("inline_comment", props)

    def test_collect_typed_properties_with_annotations(self) -> None:
        """Declarations with Godot annotations (@export, @onready) are recognized."""
        with tempfile.TemporaryDirectory() as tmpdir:
            scripts_dir = Path(tmpdir) / "scripts"
            scripts_dir.mkdir()
            script = scripts_dir / "annotated.gd"
            script.write_text(
                "@export var annotated_arr: Array[Vector2] = []\n"
                "@export_category('HUD')\n"
                "@export var categorized_dict: Dictionary[String, int] = {}\n",
                encoding="utf-8",
            )
            props = collect_typed_properties(tmpdir)
            self.assertIn("annotated_arr", props)
            self.assertIn("categorized_dict", props)

    def test_find_assignments_in_content_ignores_commented_assignments(self) -> None:
        """Assignments inside comments must not trigger errors."""
        content = (
            "# target.known_patches = []\n"
            "var x = 1 # target.known_patches = []\n"
        )
        properties = {
            "known_patches": [("/some/other/file.gd", "Array")]
        }
        errors = find_assignments_in_content(content, "/current/file.gd", properties)
        self.assertEqual(errors, [])

    def test_find_assignments_in_content_type_mismatch_ignored(self) -> None:
        """Bare [] assigned to Dictionary or {} to Array does not match typed error."""
        content = (
            "target.my_dict = []\n"
            "target.my_arr = {}\n"
        )
        properties = {
            "my_dict": [("/other/decl.gd", "Dictionary")],
            "my_arr": [("/other/decl.gd", "Array")],
        }
        errors = find_assignments_in_content(content, "/current/file.gd", properties)
        self.assertEqual(errors, [])

    def test_check_typed_array_assignments_skips_hidden_and_backups(self) -> None:
        """Hidden folders (.godot) and _backups/ are skipped during traversal."""
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            scripts_dir = root / "scripts"
            scripts_dir.mkdir()
            (scripts_dir / "decl.gd").write_text("var target_arr: Array[int] = []\n", encoding="utf-8")

            # Create bad file in hidden dir
            hidden_dir = root / ".godot" / "scripts"
            hidden_dir.mkdir(parents=True)
            (hidden_dir / "bad.gd").write_text("other.target_arr = []\n", encoding="utf-8")

            # Create bad file in _backups dir
            backups_dir = root / "_backups" / "scripts"
            backups_dir.mkdir(parents=True)
            (backups_dir / "bad.gd").write_text("other.target_arr = []\n", encoding="utf-8")

            errors = check_typed_array_assignments(tmpdir)
            self.assertEqual(errors, [])

    def test_check_typed_array_assignments_handles_unreadable_file(self) -> None:
        """Unreadable .gd files encountered during traversal are safely ignored."""
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            scripts_dir = root / "scripts"
            scripts_dir.mkdir()
            (scripts_dir / "decl.gd").write_text("var target_arr: Array[int] = []\n", encoding="utf-8")

            other_dir = root / "other"
            other_dir.mkdir()
            bad_file = other_dir / "unreadable.gd"
            bad_file.write_text("other.target_arr = []\n", encoding="utf-8")

            orig_read_text = Path.read_text

            def mock_read_text(self_path: Path, *args, **kwargs) -> str:
                if self_path.name == "unreadable.gd":
                    raise OSError("Simulated read error during scan")
                return orig_read_text(self_path, *args, **kwargs)

            with patch.object(Path, "read_text", autospec=True, side_effect=mock_read_text):
                errors = check_typed_array_assignments(tmpdir)
                self.assertEqual(errors, [])

    def test_main_cli_success(self) -> None:
        """main() prints OK message and exits with 0 on clean tree."""
        with tempfile.TemporaryDirectory() as tmpdir:
            scripts_dir = Path(tmpdir) / "scripts"
            scripts_dir.mkdir()
            (scripts_dir / "decl.gd").write_text("var target_arr: Array[int] = []\n", encoding="utf-8")

            out = io.StringIO()
            with patch("os.getcwd", return_value=tmpdir), \
                 redirect_stdout(out), \
                 self.assertRaises(SystemExit) as cm:
                main()
            self.assertEqual(cm.exception.code, 0)
            self.assertIn("OK: No cross-script bare [] or {} assignments", out.getvalue())

    def test_main_cli_failure(self) -> None:
        """main() prints error message and exits with 1 when bare assignments exist."""
        with tempfile.TemporaryDirectory() as tmpdir:
            scripts_dir = Path(tmpdir) / "scripts"
            scripts_dir.mkdir()
            (scripts_dir / "decl.gd").write_text("var target_arr: Array[int] = []\n", encoding="utf-8")

            consumer_dir = Path(tmpdir) / "consumer"
            consumer_dir.mkdir()
            (consumer_dir / "use.gd").write_text("func reset():\n    other.target_arr = []\n", encoding="utf-8")

            out = io.StringIO()
            with patch("os.getcwd", return_value=tmpdir), \
                 redirect_stdout(out), \
                 self.assertRaises(SystemExit) as cm:
                main()
            self.assertEqual(cm.exception.code, 1)
            output = out.getvalue()
            self.assertIn("Error: Found 1 bare [] or {} assignment(s)", output)
            self.assertIn("Property 'target_arr'", output)


if __name__ == "__main__":
    unittest.main()
