"""T2-5: rain skills and level weather policy in a headless Godot run."""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402


class RainSkillsTest(unittest.TestCase):
    def test_active_nuptial_flight_keeps_its_own_return(self):
        text = (ROOT / "scripts" / "bee.gd").read_text(encoding="utf-8")
        call = text.index("BeeForaging.recall_for_rain(self)")
        guard = text[:call].splitlines()[-2]
        self.assertIn("nuptial_phase == NUPTIAL_NONE", guard)

    def test_skill_entries_enable_the_live_behaviours(self):
        text = (ROOT / "scripts" / "skills.gd").read_text(encoding="utf-8")
        for skill, key in (("WEATHER_SENSING", "weather_sensing_on"),
                           ("RAIN_RECALL", "rain_recall_on")):
            start = text.index('"id": ' + skill + ', "name":')
            entry = text[start:text.index("\n\t},", start)]
            self.assertIn('"status": "existing"', entry)
            self.assertIn('{"type": "enable_behaviour", "key": "' + key + '"}', entry)

    def test_rain_skills_and_level_policy(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
             "--script", "res://tests/t2_5_rain_skills_test.gd"],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120,
        )
        output = gcc.combined_output(finished)
        failures = [line for line in output.splitlines() if line.startswith("T2_5 FAIL")]
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("T2_5 PASS", output, output[-1500:])


if __name__ == "__main__":
    unittest.main()
