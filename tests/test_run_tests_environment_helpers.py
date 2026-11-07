"""Unit tests for environment and process helper functions in tools/run_tests.py (standing task S-1).

Tests cover:
- timings_path: git common dir discovery and error handling.
- machine_godot_count: process counting across platforms, error and non-digit handling.
- private_user_home: creation of private user test directories and .gdignore marker.
"""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tools import run_tests


class TestRunTestsEnvironmentHelpers(unittest.TestCase):
    def test_timings_path_success(self) -> None:
        fake_common_dir = "/path/to/.git"
        completed = subprocess.CompletedProcess(
            args=["git", "-C", str(run_tests.ROOT), "rev-parse"],
            returncode=0,
            stdout=f"{fake_common_dir}\n",
        )
        with mock.patch("subprocess.run", return_value=completed):
            path = run_tests.timings_path()
            self.assertEqual(path, Path(fake_common_dir) / "meadow-test-timings.json")

    def test_timings_path_empty_output(self) -> None:
        completed = subprocess.CompletedProcess(
            args=["git", "-C", str(run_tests.ROOT), "rev-parse"],
            returncode=0,
            stdout="",
        )
        with mock.patch("subprocess.run", return_value=completed):
            path = run_tests.timings_path()
            self.assertIsNone(path)

    def test_timings_path_error(self) -> None:
        with mock.patch("subprocess.run", side_effect=subprocess.CalledProcessError(1, "git")):
            self.assertIsNone(run_tests.timings_path())
        with mock.patch("subprocess.run", side_effect=OSError("binary not found")):
            self.assertIsNone(run_tests.timings_path())

    def test_machine_godot_count_posix_success(self) -> None:
        completed = subprocess.CompletedProcess(
            args=["pgrep", "-c", "-i", "godot"],
            returncode=0,
            stdout="3\n",
        )
        with mock.patch.object(os, "name", "posix"):
            with mock.patch("subprocess.run", return_value=completed):
                self.assertEqual(run_tests.machine_godot_count(), 3)

    def test_machine_godot_count_posix_nondigit(self) -> None:
        completed = subprocess.CompletedProcess(
            args=["pgrep", "-c", "-i", "godot"],
            returncode=1,
            stdout="",
        )
        with mock.patch.object(os, "name", "posix"):
            with mock.patch("subprocess.run", return_value=completed):
                self.assertEqual(run_tests.machine_godot_count(), 0)

    def test_machine_godot_count_posix_exception(self) -> None:
        with mock.patch.object(os, "name", "posix"):
            with mock.patch("subprocess.run", side_effect=subprocess.SubprocessError("timeout")):
                self.assertEqual(run_tests.machine_godot_count(), 0)
            with mock.patch("subprocess.run", side_effect=OSError("no pgrep")):
                self.assertEqual(run_tests.machine_godot_count(), 0)

    def test_private_user_home_creates_directory_and_gdignore(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            fake_root = Path(tmp_dir) / "private_user"
            with mock.patch.object(run_tests, "PRIVATE_USER_ROOT", fake_root):
                worker = 2
                run_id = "testrun"
                home = run_tests.private_user_home(worker, run_id)
                self.assertTrue(home.is_dir())
                self.assertEqual(home.name, f"tests-{run_id}-{worker}")
                gdignore = fake_root / ".gdignore"
                self.assertTrue(gdignore.is_file())
                self.assertEqual(gdignore.read_text(encoding="utf-8"), "")

                # Idempotent: re-calling does not overwrite existing marker
                gdignore.write_text("existing", encoding="utf-8")
                home2 = run_tests.private_user_home(worker, run_id)
                self.assertEqual(home, home2)
                self.assertEqual(gdignore.read_text(encoding="utf-8"), "existing")


if __name__ == "__main__":
    unittest.main()
