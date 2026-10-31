"""Unit tests for the helper functions in tools/godot_compile_check.py."""

from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
import tempfile
import unittest
from unittest.mock import MagicMock, patch

from tools import godot_compile_check


class TestCanWrite(unittest.TestCase):
    def test_returns_true_for_writable_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            self.assertTrue(godot_compile_check._can_write(Path(tmp_dir)))

    def test_creates_directory_if_it_does_not_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            nested = Path(tmp_dir) / "nested" / "sub"
            self.assertTrue(godot_compile_check._can_write(nested))
            self.assertTrue(nested.is_dir())

    def test_returns_false_on_oserror(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            probe_parent = Path(tmp_dir)
            with patch.object(Path, "mkdir", side_effect=OSError("Permission denied")):
                self.assertFalse(godot_compile_check._can_write(probe_parent))


class TestReportMissingImports(unittest.TestCase):
    def test_returns_false_when_no_missing_imports(self) -> None:
        mock_cache = MagicMock()
        mock_cache.missing_imports.return_value = []
        with patch.object(godot_compile_check, "_godot_cache", return_value=mock_cache):
            self.assertFalse(godot_compile_check.report_missing_imports(["some failure line"]))

    def test_returns_true_and_reports_fault_when_missing_imports_exist(self) -> None:
        mock_cache = MagicMock()
        mock_cache.missing_imports.return_value = ["sprite.png"]
        mock_cache.cache_fault.return_value = "godot cache: FAILED (missing imports)"

        hits = [
            'SCRIPT ERROR: Parse Error: Could not preload "res://sprite.png".',
            'SCRIPT ERROR: Compile Error: Failed to compile.',
        ]
        out = StringIO()
        with patch.object(godot_compile_check, "_godot_cache", return_value=mock_cache), \
             redirect_stdout(out):
            result = godot_compile_check.report_missing_imports(hits)

        self.assertTrue(result)
        mock_cache.cache_fault.assert_called_once()
        printed = out.getvalue()
        self.assertIn("godot cache: FAILED (missing imports)", printed)
        self.assertIn(hits[0], printed)
        self.assertIn(hits[1], printed)


if __name__ == "__main__":
    unittest.main()
