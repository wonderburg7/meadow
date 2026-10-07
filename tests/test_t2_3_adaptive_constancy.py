"""T2-3: adaptive constancy is a bought behaviour.

Static checks on the skill entry and the helper, plus a headless run of the
bought scenario (buy accepted with the setting off).
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402
from analyze_session import load_entries  # noqa: E402
from run_scenario import run_once  # noqa: E402

SCENARIO = ROOT / "test_scenarios" / "t2_3_bought_constancy_test.json"


class BoughtConstancyTest(unittest.TestCase):
    def test_skill_entry_enables_behaviour(self):
        text = (ROOT / "scripts" / "skills.gd").read_text(encoding="utf-8")
        start = text.index('"id": ADAPTIVE_CONSTANCY')
        block = text[start:text.index("\n\t},", start)]
        self.assertIn('{"type": "enable_behaviour", "key": "adaptive_constancy_on"}', block)
        self.assertIn('"status": "existing"', block)

    def test_helper_replaces_direct_reads(self):
        text = (ROOT / "scripts" / "bee_foraging.gd").read_text(encoding="utf-8")
        self.assertIn("static func adaptive_constancy_on() -> bool:", text)
        self.assertNotIn("if GameConfig.adaptive_constancy_on:", text)
        self.assertEqual(text.count("if adaptive_constancy_on():"), 3)

    def test_scenario_buys_with_setting_off(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        session = run_once(SCENARIO, godot, timeout=180)
        self.assertIsNotNone(session, "scenario run produced no session log")
        rejected = [
            e for e in load_entries(session)
            if e.get("type") == "action" and e.get("do") in ("assert", "buy_skill")
            and e.get("result") != "accepted"
        ]
        self.assertEqual(rejected, [], rejected)


if __name__ == "__main__":
    unittest.main()
