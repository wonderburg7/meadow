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
