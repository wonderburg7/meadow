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
             patch.object(godot_compile_check, "refresh_cache_after", return_value=(refresh, False)), \
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

    def test_a_refused_cache_is_exit_3_not_a_code_failure(self):
        output = StringIO()
        with patch.object(godot_compile_check, "find_godot", return_value="Godot"), \
             patch.object(godot_compile_check.subprocess, "run", side_effect=[completed(0)]), \
             patch.object(godot_compile_check, "prepare_cache", return_value=False), \
             redirect_stdout(output):
            result = godot_compile_check.main()

        self.assertEqual(result, godot_compile_check._godot_cache().CACHE_FAULT_EXIT)

    def test_a_failed_rebuild_is_exit_3(self):
        output = StringIO()
        with patch.object(godot_compile_check, "find_godot", return_value="Godot"), \
             patch.object(godot_compile_check.subprocess, "run", side_effect=[
                 completed(0),
                 completed(0, 'SCRIPT ERROR: Parse Error: Could not resolve script "res://x.gd".'),
             ]), \
             patch.object(godot_compile_check, "prepare_cache", return_value=True), \
             patch.object(godot_compile_check, "refresh_cache_after", return_value=(False, True)), \
             redirect_stdout(output):
            result = godot_compile_check.main()

        self.assertEqual(result, 3)
        self.assertNotIn("does not boot cleanly", output.getvalue())


# What a boot printed on 12 Oct 2026 when the cache lacked one sprite import.
MISSING_SPRITE_BOOT = "\n".join([
    'SCRIPT ERROR: Parse Error: Could not preload resource file "res://assets/sprites/meadow/hive_skep_rival_sheet.png".',
    'SCRIPT ERROR: Parse Error: Cannot infer the type of "HIVE_SKEP_RIVAL_SHEET" constant because the value doesn\'t have a set type.',
    "SCRIPT ERROR: Compile Error: Failed to compile depended scripts.",
    'SCRIPT ERROR: Parse Error: Could not resolve external class member "HIVE_SKEP_RIVAL_SHEET".',
    'ERROR: Failed to load script "res://scripts/main.gd" with error "Compilation failed".',
])


class MissingImportBootTest(unittest.TestCase):
    """A boot that fails only for want of an import names the cache and its
    fix; after a cold rebuild the same lines are the branch's to fix."""

    def run_main(self, root, responses, refresh):
        output = StringIO()
        with patch.object(godot_compile_check, "REPO_ROOT", root), \
             patch.object(godot_compile_check, "find_godot", return_value="Godot"), \
             patch.object(godot_compile_check.subprocess, "run", side_effect=responses), \
             patch.object(godot_compile_check, "prepare_cache", return_value=True), \
             patch.object(godot_compile_check, "refresh_cache_after", return_value=refresh), \
             patch.object(godot_compile_check, "mark_cache_fresh"), \
             patch.object(godot_compile_check._godot_cache(), "primary_root", return_value=root), \
             redirect_stdout(output):
            result = godot_compile_check.main()
        return result, output.getvalue()

    def make_root(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        sprite = root / "assets" / "sprites" / "meadow" / "hive_skep_rival_sheet.png"
        sprite.parent.mkdir(parents=True)
        sprite.write_bytes(b"png")
        return root

    def test_primary_missing_import_names_the_cache_and_the_import_command(self):
        root = self.make_root()
        result, output = self.run_main(root, [completed(0), completed(0, MISSING_SPRITE_BOOT)], (False, False))

        self.assertEqual(result, 3)
        self.assertIn("godot cache: FAILED (not a code fault)", output)
        self.assertIn("hive_skep_rival_sheet.png", output)
        self.assertIn("--headless --import --path .", output)
        self.assertIn("cd %s" % root, output)
        self.assertNotIn("Fix master first", output)

    def test_after_a_cold_rebuild_the_same_lines_are_a_code_fault(self):
        root = self.make_root()
        result, output = self.run_main(root, [
            completed(0), completed(0, MISSING_SPRITE_BOOT), completed(0, MISSING_SPRITE_BOOT),
        ], (True, False))

        self.assertEqual(result, 1)
        self.assertIn("project does not boot cleanly", output)
        self.assertNotIn("not a code fault", output)


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
