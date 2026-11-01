"""CF-1: exercise the alpha packager and the menu's optional build stamp."""

from __future__ import annotations

import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import godot_compile_check as gcc


class BuildArchiveTest(unittest.TestCase):
    def test_stamp_and_note_are_packaged_and_temporary_files_are_removed(self):
        self._package(export_exit=0)

    def test_failed_export_removes_temporary_stamp_and_uid(self):
        self._package(export_exit=7)

    def _package(self, export_exit):
        shell = shutil.which("pwsh") or shutil.which("powershell")
        if not shell:
            self.skipTest("PowerShell is required to exercise the Windows packager")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for folder in ("tools", "scripts", "docs"):
                (root / folder).mkdir()
            shutil.copyfile(ROOT / "tools/build_alpha.ps1", root / "tools/build_alpha.ps1")
            shutil.copyfile(ROOT / "docs/alpha-start-here.md", root / "docs/alpha-start-here.md")
            (root / "project.godot").write_text('config/version="0.1.2"\n', encoding="utf-8")
            for args in (["init", "-q"], ["add", "."],
                         ["-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                          "commit", "-qm", "Fixture"]):
                subprocess.run(["git", "-C", str(root), *args], check=True, capture_output=True)
            short_hash = subprocess.check_output(
                ["git", "-C", str(root), "rev-parse", "--short", "HEAD"], text=True).strip()
            template = root / "Godot/export_templates/4.7.0.stable/windows_release_x86_64.exe"
            template.parent.mkdir(parents=True)
            template.touch()
            # A native-command substitute records what exists at export time,
            # including a generated uid, on both success and failure.
            fake = root / "fake_godot.ps1"
            fake.write_text('''if ($args -contains "--version") {
    Write-Output "4.7.0.stable.official"; exit 0
}
Copy-Item scripts/build_info.gd captured-stamp.txt
Set-Content scripts/build_info.gd.uid "uid://fixture"
Set-Content build/windows/Meadow.exe "fixture exe"
Set-Content build/windows/Meadow.pck "fixture pack"
exit EXPORT_EXIT
'''.replace("EXPORT_EXIT", str(export_exit)), encoding="utf-8")
            result = subprocess.run(
                [shell, "-NoProfile", "-File", str(root / "tools/build_alpha.ps1"),
                 "-Godot", str(fake)], cwd=root, env={**os.environ, "APPDATA": str(root)},
                capture_output=True, text=True, timeout=60)
            stamp = (root / "captured-stamp.txt").read_text(encoding="utf-8-sig")
            match = re.search(r'const BUILD_ID := "(0\.1\.2-' + short_hash + r'-\d{4}-\d{2}-\d{2})"', stamp)
            self.assertIsNotNone(match, stamp)
            self.assertFalse((root / "scripts/build_info.gd").exists())
            self.assertFalse((root / "scripts/build_info.gd.uid").exists())
            if export_exit:
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("Godot export failed with exit code 7", result.stdout + result.stderr)
                self.assertEqual(list((root / "build").glob("*.zip")), [])
            else:
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                archive = root / "build" / ("Meadow-" + match[1] + "-windows.zip")
                with zipfile.ZipFile(archive) as zipped:
                    self.assertEqual(set(zipped.namelist()), {"Meadow.exe", "Meadow.pck", "START-HERE.txt"})
                    self.assertEqual(zipped.read("START-HERE.txt"), (root / "docs/alpha-start-here.md").read_bytes())


class MenuBuildIdTest(unittest.TestCase):
    def test_menu_displays_development_or_stamped_id(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("a real Godot is required for the menu build-id check")
        source = (ROOT / "scripts/main_menu.gd").read_text(encoding="utf-8")
        # Run the production methods in an isolated project so neither the
        # checkout nor a tester's real profile needs a temporary stamp.
        methods = []
        for name in ("_build_build_id", "_build_id_text"):
            match = re.search(r"(?m)^(?:static )?func " + name + r"\([^\n]*\n(?:\t[^\n]*\n|\n)*", source)
            self.assertIsNotNone(match, name)
            methods.append(match[0])
        self.assertIn('_build_build_id(right_pane)', source)
        self.assertNotIn('font_size', methods[0])
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts").mkdir()
            (root / "project.godot").write_text('config_version=5\n', encoding="utf-8")
            (root / "menu.gd").write_text('''extends Node
class UiTheme:
    static func bind_color(_node, _property, _role):
        pass
''' + "\n".join(methods).expandtabs(4), encoding="utf-8")
            for expected in ("development build", "0.1.2-abcdef1-2026-11-01"):
                if expected != "development build":
                    (root / "scripts/build_info.gd").write_text(
                        'extends RefCounted\nconst BUILD_ID := "' + expected + '"\n', encoding="utf-8")
                (root / "check.gd").write_text('''extends SceneTree
func _initialize():
    var menu = load("res://menu.gd").new()
    var pane = VBoxContainer.new()
    menu._build_build_id(pane)
    var label = pane.get_child(0)
    if label.text != "EXPECTED" or label.theme_type_variation != "Small":
        push_error("CF1 wrong build label: " + label.text)
        quit(1)
        return
    pane.free()
    menu.free()
    print("CF1 PASS")
    quit(0)
'''.replace("EXPECTED", expected), encoding="utf-8")
                result = subprocess.run(
                    [godot, "--headless", "--disable-crash-handler", "--quit-after", "10",
                     "--path", str(root), "--script", "res://check.gd"],
                    capture_output=True, text=True, timeout=60)
                output = gcc.combined_output(result)
                self.assertEqual(gcc.failing_lines(output), [], output)
                self.assertEqual(result.returncode, 0, output)
                self.assertIn("CF1 PASS", output)


if __name__ == "__main__":
    unittest.main()
