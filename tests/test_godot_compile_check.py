"""Unit tests for the Godot boot verifier's host/project boundary."""

from contextlib import redirect_stdout
from io import StringIO
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from tools import godot_compile_check


def completed(returncode: int, stdout: str = "", stderr: str = ""):
    return subprocess.CompletedProcess(["Godot"], returncode, stdout, stderr)


class GodotCompileCheckTest(unittest.TestCase):
    def run_main(self, responses, refresh=False):
        output = StringIO()
        with patch.object(godot_compile_check, "find_godot", return_value="Godot"), \
             patch.object(godot_compile_check.subprocess, "run", side_effect=responses), \
             patch.object(godot_compile_check, "prepare_cache", return_value=True), \
             patch.object(godot_compile_check, "refresh_cache_after", return_value=refresh), \
             patch.object(godot_compile_check, "mark_cache_fresh"), \
             redirect_stdout(output):
            result = godot_compile_check.main()
        return result, output.getvalue()

    def test_skips_when_the_engine_crashes_before_a_project_is_opened(self):
        result, output = self.run_main([completed(-1073741819)])

        self.assertEqual(result, 0)
        self.assertIn("skipped", output)
        self.assertIn("before opening the project", output)

    def test_checks_project_after_a_usable_engine_preflight(self):
        result, output = self.run_main([
            completed(0),
            completed(0, "SCRIPT ERROR: Parse Error: bad script"),
        ])

        self.assertEqual(result, 1)
        self.assertIn("project does not boot cleanly", output)


    def test_retries_once_after_a_cache_refresh(self):
        result, output = self.run_main([
            completed(0),
            completed(0, 'SCRIPT ERROR: Parse Error: Could not resolve script "res://x.gd".'),
            completed(0, "booted"),
        ], refresh=True)

        self.assertEqual(result, 0)
        self.assertIn("boots with no script errors", output)


class WritableUserDirTest(unittest.TestCase):
    """Codex's sandbox denies %APPDATA%, and Godot 4.7.1 crashes at 0x58
    before boot when it cannot open user://logs/godot.log there."""

    def test_leaves_a_writable_appdata_alone(self):
        with tempfile.TemporaryDirectory() as appdata,              patch.dict(os.environ, {"APPDATA": appdata}):
            self.assertIsNone(godot_compile_check.ensure_writable_user_dir())
            self.assertEqual(os.environ["APPDATA"], appdata)

    def test_redirects_an_appdata_godot_cannot_write(self):
        with tempfile.TemporaryDirectory() as scratch:
            blocked = Path(scratch) / "a-file"
            blocked.write_text("", encoding="utf-8")
            temp = Path(scratch) / "temp"
            with patch.dict(os.environ, {"APPDATA": str(blocked)}),                  patch.object(godot_compile_check.tempfile, "gettempdir", return_value=str(temp)):
                line = godot_compile_check.ensure_writable_user_dir()
                redirected = os.environ["APPDATA"]

            self.assertIn("not writable", line)
            self.assertEqual(Path(redirected), temp / "meadow-godot-appdata")
            self.assertTrue(Path(redirected).is_dir())


if __name__ == "__main__":
    unittest.main()
