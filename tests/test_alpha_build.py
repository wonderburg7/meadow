"""Structural checks for the Windows alpha build configuration."""

import configparser
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


class AlphaBuildTest(unittest.TestCase):
    def test_windows_export_metadata(self):
        config = configparser.ConfigParser(interpolation=None)
        config.read(ROOT / "export_presets.cfg", encoding="utf-8")
        preset_sections = [
            section for section in config.sections()
            if section.startswith("preset.") and not section.endswith(".options")
        ]
        self.assertEqual(preset_sections, ["preset.0"])
        preset = config["preset.0"]
        self.assertEqual(preset["name"].strip('"'), "Windows Desktop")
        self.assertEqual(preset["platform"].strip('"'), "Windows Desktop")
        self.assertEqual(preset["export_path"].strip('"'), "build/windows/Meadow.exe")
        self.assertEqual(preset["export_filter"].strip('"'), "all_resources")
        options = config["preset.0.options"]
        self.assertEqual(options["architectures/x86_64"], "true")
        self.assertEqual(options["application/product_name"].strip('"'), "Meadow")
        self.assertEqual(options["application/file_description"].strip('"'), "Meadow")

    def test_version_build_ignore_and_helper_are_configured(self):
        project = (ROOT / "project.godot").read_text(encoding="utf-8")
        self.assertRegex(project, r'(?m)^config/version="[^"]+"$')
        # The name is the window title and the user:// folder; "Meadow - Claude"
        # shipped in the first alpha build until Dave renamed it, 7 Oct 2026.
        self.assertRegex(project, r'(?m)^config/name="Meadow"$')
        self.assertIn("build/", (ROOT / ".gitignore").read_text(encoding="utf-8").splitlines())
        helper = (ROOT / "tools" / "build_alpha.ps1").read_text(encoding="utf-8")
        self.assertIn('--export-release "Windows Desktop"', helper)
        self.assertIn("Compress-Archive", helper)

    def test_export_does_not_stop_before_godot_does(self):
        """The three reasons build_alpha.ps1 never built, found 7 Oct 2026:
        Godot logs an error for each missing preset filter key; Windows
        PowerShell 5.1 under "Stop" aborts on Godot's first stderr line; and a
        GUI Godot.exe returns before exporting, with no exit code."""
        options = configparser.ConfigParser(interpolation=None)
        options.read(ROOT / "export_presets.cfg", encoding="utf-8")
        self.assertIn("include_filter", options["preset.0"])
        self.assertIn("exclude_filter", options["preset.0"])
        helper = (ROOT / "tools" / "build_alpha.ps1").read_text(encoding="utf-8")
        export_line = helper.index('--export-release "Windows Desktop"')
        self.assertIn('$ErrorActionPreference = "Continue"', helper[:export_line])
        self.assertIn("_console.exe", helper)
        self.assertIn("export_templates", helper)

    def test_editor_addons_stay_out_of_the_export(self):
        """Until 7 Oct 2026 the alpha packed 350 editor-only addon files.
        godot_ai strips its own autoload at export (mcp_export_plugin.gd), so
        excluding addons/ leaves the game's autoloads intact."""
        options = configparser.ConfigParser(interpolation=None)
        options.read(ROOT / "export_presets.cfg", encoding="utf-8")
        excluded = [p.strip() for p in options["preset.0"]["exclude_filter"].strip('"').split(",")]
        self.assertIn("addons/*", excluded)
        self.assertIn("godot-copy-all-errors-*/*", excluded)
        project = (ROOT / "project.godot").read_text(encoding="utf-8")
        autoload = project.split("[autoload]", 1)[1].split("\n[", 1)[0]
        for line in autoload.splitlines():
            if "res://addons/" in line:
                self.assertTrue(line.startswith("_mcp_game_helper="), line)
