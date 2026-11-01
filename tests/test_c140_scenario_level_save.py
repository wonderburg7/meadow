"""C-140: a scenario check save keeps its level rules, and a load during the
first crisis's lead shows the warning again."""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402


class ScenarioLevelSaveTest(unittest.TestCase):
    def test_a_scenario_save_writes_its_level_row(self):
        text = (ROOT / "scripts" / "save_game.gd").read_text(encoding="utf-8")
        self.assertIn('data["scenario_level"] = Levels.scenario_override.duplicate(true)', text)

    def test_a_warned_restore_shows_the_warning_again(self):
        text = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
        body = text.split("\nfunc restore_first_crisis(", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn('str(first_crisis.state) == "warned"', body)
        self.assertIn("hud.show_warning(_first_crisis_warning_text(", body)

    def test_the_load_route_puts_the_scenario_level_back(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
             "--script", "res://tests/c140_scenario_level_save_test.gd"],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120,
        )
        output = gcc.combined_output(finished)
        failures = [line for line in output.splitlines() if line.startswith("C140 FAIL")]
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("C140 PASS", output, output[-1500:])


if __name__ == "__main__":
    unittest.main()
