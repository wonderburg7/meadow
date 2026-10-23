"""Unit tests for tools/gdscript_warnings.py's parsing and main runner."""

from contextlib import redirect_stdout
from io import StringIO
import subprocess
import unittest
from unittest.mock import patch

from tools import gdscript_warnings


SAMPLE_BOOT_OUTPUT = """Godot Engine v4.7.1.stable - https://godotengine.org
OpenGL API 3.3.0 - Compatibility - Using Device: Mesa

WARNING: The integer division "1 / 2" implies floating-point division.
   at: GDScript::reload (res://scripts/hud.gd:629)
WARNING: Unused parameter "delta".
   at: GDScript::reload (res://scripts/main.gd:42)
WARNING: Unused parameter "delta".
   at: GDScript::reload (res://scripts/main.gd:42)
Unrelated stdout line
"""


class GDScriptWarningsTest(unittest.TestCase):
    def test_script_warnings_parses_and_deduplicates(self):
        warnings = gdscript_warnings.script_warnings(SAMPLE_BOOT_OUTPUT)
        self.assertEqual(len(warnings), 2)
        self.assertEqual(
            warnings[0],
            ("res://scripts/hud.gd", 629, 'The integer division "1 / 2" implies floating-point division.')
        )
        self.assertEqual(
            warnings[1],
            ("res://scripts/main.gd", 42, 'Unused parameter "delta".')
        )

    def test_script_warnings_empty_on_no_matches(self):
        self.assertEqual(gdscript_warnings.script_warnings("No warnings here\nJust text"), [])

    def test_as_res_path_converts_paths(self):
        self.assertEqual(gdscript_warnings.as_res_path("res://scripts/hud.gd"), "res://scripts/hud.gd")
        self.assertEqual(gdscript_warnings.as_res_path("scripts/hud.gd"), "res://scripts/hud.gd")
        self.assertEqual(gdscript_warnings.as_res_path("./scripts/hud.gd"), "res://scripts/hud.gd")
        self.assertEqual(gdscript_warnings.as_res_path("scripts\\hud.gd"), "res://scripts/hud.gd")

    def test_main_skips_when_godot_missing(self):
        output = StringIO()
        with patch.object(gdscript_warnings.gcc, "find_godot", return_value=None), \
             redirect_stdout(output):
            res = gdscript_warnings.main([])
        self.assertEqual(res, 0)
        self.assertIn("skipped -- no Godot binary found", output.getvalue())

    def test_main_skips_when_engine_cannot_boot(self):
        output = StringIO()
        with patch.object(gdscript_warnings.gcc, "find_godot", return_value="godot"), \
             patch.object(gdscript_warnings.gcc, "ensure_writable_user_dir", return_value=None), \
             patch.object(gdscript_warnings.gcc, "engine_can_boot", return_value=False), \
             redirect_stdout(output):
            res = gdscript_warnings.main([])
        self.assertEqual(res, 0)

    def test_main_fails_on_cache_prepare_failure(self):
        output = StringIO()
        with patch.object(gdscript_warnings.gcc, "find_godot", return_value="godot"), \
             patch.object(gdscript_warnings.gcc, "ensure_writable_user_dir", return_value=None), \
             patch.object(gdscript_warnings.gcc, "engine_can_boot", return_value=True), \
             patch.object(gdscript_warnings.gcc, "prepare_cache", return_value=False), \
             redirect_stdout(output):
            res = gdscript_warnings.main([])
        self.assertEqual(res, 1)

    def test_main_fails_on_timeout(self):
        output = StringIO()
        with patch.object(gdscript_warnings.gcc, "find_godot", return_value="godot"), \
             patch.object(gdscript_warnings.gcc, "ensure_writable_user_dir", return_value=None), \
             patch.object(gdscript_warnings.gcc, "engine_can_boot", return_value=True), \
             patch.object(gdscript_warnings.gcc, "prepare_cache", return_value=True), \
             patch.object(gdscript_warnings, "boot_with_debugger", side_effect=subprocess.TimeoutExpired(["cmd"], 10)), \
             redirect_stdout(output):
            res = gdscript_warnings.main([])
        self.assertEqual(res, 1)
        self.assertIn("FAILED -- the boot did not finish", output.getvalue())

    def test_main_fails_when_warnings_found_and_no_paths(self):
        output = StringIO()
        with patch.object(gdscript_warnings.gcc, "find_godot", return_value="godot"), \
             patch.object(gdscript_warnings.gcc, "ensure_writable_user_dir", return_value=None), \
             patch.object(gdscript_warnings.gcc, "engine_can_boot", return_value=True), \
             patch.object(gdscript_warnings.gcc, "prepare_cache", return_value=True), \
             patch.object(gdscript_warnings, "boot_with_debugger", return_value=SAMPLE_BOOT_OUTPUT), \
             redirect_stdout(output):
            res = gdscript_warnings.main([])
        self.assertEqual(res, 1)
        self.assertIn("FAILED -- 2 warning(s) in the project", output.getvalue())

    def test_main_fails_when_warning_in_named_file(self):
        output = StringIO()
        with patch.object(gdscript_warnings.gcc, "find_godot", return_value="godot"), \
             patch.object(gdscript_warnings.gcc, "ensure_writable_user_dir", return_value=None), \
             patch.object(gdscript_warnings.gcc, "engine_can_boot", return_value=True), \
             patch.object(gdscript_warnings.gcc, "prepare_cache", return_value=True), \
             patch.object(gdscript_warnings, "boot_with_debugger", return_value=SAMPLE_BOOT_OUTPUT), \
             redirect_stdout(output):
            res = gdscript_warnings.main(["scripts/hud.gd"])
        self.assertEqual(res, 1)
        self.assertIn("FAILED -- 1 warning(s) in the named files", output.getvalue())

    def test_main_passes_when_warning_not_in_named_file(self):
        output = StringIO()
        with patch.object(gdscript_warnings.gcc, "find_godot", return_value="godot"), \
             patch.object(gdscript_warnings.gcc, "ensure_writable_user_dir", return_value=None), \
             patch.object(gdscript_warnings.gcc, "engine_can_boot", return_value=True), \
             patch.object(gdscript_warnings.gcc, "prepare_cache", return_value=True), \
             patch.object(gdscript_warnings, "boot_with_debugger", return_value=SAMPLE_BOOT_OUTPUT), \
             redirect_stdout(output):
            res = gdscript_warnings.main(["scripts/other.gd"])
        self.assertEqual(res, 0)
        self.assertIn("the named files raise none (2 elsewhere)", output.getvalue())

    def test_main_passes_when_no_warnings(self):
        output = StringIO()
        with patch.object(gdscript_warnings.gcc, "find_godot", return_value="godot"), \
             patch.object(gdscript_warnings.gcc, "ensure_writable_user_dir", return_value=None), \
             patch.object(gdscript_warnings.gcc, "engine_can_boot", return_value=True), \
             patch.object(gdscript_warnings.gcc, "prepare_cache", return_value=True), \
             patch.object(gdscript_warnings, "boot_with_debugger", return_value="Clean boot\n"), \
             redirect_stdout(output):
            res = gdscript_warnings.main([])
        self.assertEqual(res, 0)
        self.assertIn("the project raises none (0 elsewhere)", output.getvalue())


if __name__ == "__main__":
    unittest.main()
