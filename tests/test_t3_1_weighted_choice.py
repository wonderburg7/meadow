"""T3-1: weighted flower choice becomes a purchase."""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402


class WeightedChoiceTest(unittest.TestCase):
    def test_skill_entry_enables_behaviour(self):
        text = (ROOT / "scripts" / "skills.gd").read_text(encoding="utf-8")
        start = text.index('"id": WEIGHTED_FLOWER_CHOICE, "name":')
        entry = text[start:text.index("\n\t},", start)]
        self.assertIn('"status": "existing"', entry)
        self.assertIn('{"type": "enable_behaviour", "key": "probabilistic_choice_on"}', entry)

    def test_direct_reads_use_helper(self):
        text = (ROOT / "scripts" / "bee_foraging.gd").read_text(encoding="utf-8")
        self.assertNotIn("if GameConfig.probabilistic_choice_on:", text)
        self.assertEqual(text.count("if probabilistic_choice_on():"), 2)

    def test_setting_is_developer_only(self):
        cat = (ROOT / "scripts" / "settings_catalogue.gd").read_text(encoding="utf-8")
        start = cat.index('"key": "probabilistic_choice_on"')
        row = cat[start:cat.index("\n\t},", start)]
        self.assertIn('"dev_only": true', row)
        panel = (ROOT / "scripts" / "debug_panel.gd").read_text(encoding="utf-8")
        self.assertIn('entry.get("dev_only", false)', panel)
        self.assertIn("dev_row.visible = Session.developer_mode", panel)

    def test_choice_gated_by_skill(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
             "--script", "res://tests/t3_1_weighted_choice_test.gd"],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120,
        )
        output = gcc.combined_output(finished)
        failures = [line for line in output.splitlines() if line.startswith("T3_1 FAIL")]
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("T3_1 PASS", output, output[-1500:])


if __name__ == "__main__":
    unittest.main()
