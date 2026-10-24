"""CQ-R12: Challenge 2 restores pollen when its opening stock is exhausted."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "cq_r12_c2_pollen_rescue_test.json"


class ChallengeTwoPollenRescueTest(unittest.TestCase):
    def test_empty_opening_pollen_stock_is_rescued(self):
        godot_path = find_godot()
        if not godot_path:
            self.skipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(FIXTURE, godot_path, timeout=180, fixed_fps=30)
        self.assertIsNotNone(session_file, "scenario run produced no session log")
        entries = load_entries(session_file)
        actions = [entry for entry in entries if entry.get("type") == "action"]
        problems = [entry for entry in actions if entry.get("result") not in ("accepted", "recorded")]
        self.assertEqual(problems, [], "an action was rejected or never fired: %s" % problems)


if __name__ == "__main__":
    unittest.main()
