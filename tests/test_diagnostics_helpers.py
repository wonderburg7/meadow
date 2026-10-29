"""Unit tests for tools/diagnostics.py helper functions log_path and write_event."""

import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.diagnostics import MAX_BYTES, log_path, read_events, write_event


class TestDiagnosticsHelpers(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.path = Path(self.temp_dir.name)

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_log_path_valid_git_repo(self):
        # Current repo root should be a valid git repo
        path = log_path(Path.cwd())
        self.assertIsNotNone(path)
        self.assertTrue(str(path).endswith("meadow-diagnostics.jsonl"))

    def test_log_path_invalid_git_repo(self):
        # When both root and cwd are not git repos (e.g., when git command fails or returns non-zero)
        with patch("subprocess.run") as mock_run:
            mock_run.return_value.returncode = 128
            path = log_path(self.path)
            self.assertIsNone(path)

    def test_write_event_basic(self):
        log_file = self.path / "meadow-diagnostics.jsonl"
        with patch("tools.diagnostics.log_path", return_value=log_file):
            write_event("session_start", key1="val1", key2=123)
            events = list(read_events(self.path))

        self.assertTrue(log_file.exists())
        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]["kind"], "session_start")
        self.assertEqual(events[0]["key1"], "val1")
        self.assertEqual(events[0]["key2"], 123)
        self.assertIn("ts", events[0])

    def test_write_event_truncates_long_strings_and_ignores_empty(self):
        log_file = self.path / "meadow-diagnostics.jsonl"
        long_str = "a" * 500
        with patch("tools.diagnostics.log_path", return_value=log_file):
            write_event(
                "slice_claimed",
                long_param=long_str,
                empty_param="",
                none_param=None,
            )
            events = list(read_events(self.path))

        self.assertEqual(len(events), 1)
        self.assertEqual(len(events[0]["long_param"]), 300)
        self.assertNotIn("empty_param", events[0])
        self.assertNotIn("none_param", events[0])

    def test_write_event_rotates_file_on_max_bytes(self):
        log_file = self.path / "meadow-diagnostics.jsonl"
        # Create file exceeding MAX_BYTES
        log_file.write_bytes(b"x" * (MAX_BYTES + 10))

        with patch("tools.diagnostics.log_path", return_value=log_file):
            write_event("session_end")
            events = list(read_events(self.path))

        rotated_file = log_file.with_suffix(log_file.suffix + ".1")
        self.assertTrue(rotated_file.exists())
        self.assertEqual(rotated_file.stat().st_size, MAX_BYTES + 10)

        # The new file should have 1 line
        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]["kind"], "session_end")

    def test_write_event_swallows_exceptions(self):
        with patch("tools.diagnostics.log_path", side_effect=RuntimeError("Disk full")):
            # Should not raise exception
            write_event("session_start")


if __name__ == "__main__":
    unittest.main()
