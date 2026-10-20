"""RR-10: fermented nectar cannot buy skills or be spent by a skill purchase."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once, scenario_saves_dir  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "rr10_fermented_not_currency.json"
FERMENTED = 100.0
FRESH = 140.0
CELL_CAPACITY_COST = 130.0


def _nectar_amounts(save: dict) -> list[float]:
    return sorted(float(cell["amount"]) for cell in save["cells"] if cell.get("content") == "nectar")


class FermentedNectarCurrencyRunTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(FIXTURE, godot_path, timeout=300, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        cls.actions = [entry for entry in load_entries(session_file) if entry.get("type") == "action"]
        scratch = scenario_saves_dir(session_file)
        cls.saves = {}
        for name in ("refused", "bought"):
            path = scratch / ("rr10-%s.json" % name)
            if path.exists():
                cls.saves[name] = json.loads(path.read_text(encoding="utf-8"))

    def setUp(self):
        self.assertEqual([action for action in self.actions if action.get("result") == "rejected"], [],
                         "a scenario action was rejected")
        self.assertEqual(sorted(self.saves), ["bought", "refused"], "the run did not write both saves")

    def test_a_skill_costing_more_than_fresh_nectar_is_refused_without_spending_either_cell(self):
        refused = [action for action in self.actions
                   if action.get("do") == "buy_skill" and action.get("reason") == "refused as expected"]
        self.assertEqual(len(refused), 1, "the unaffordable skill was not refused")
        self.assertNotIn("skill.brood.honey_worker", json.dumps(self.saves["refused"].get("skills", {})))
        self.assertEqual(_nectar_amounts(self.saves["refused"]), [FERMENTED, FRESH])

    def test_a_skill_within_fresh_nectar_spends_only_the_fresh_cell(self):
        self.assertIn("skill.colony.cell_capacity", json.dumps(self.saves["bought"].get("skills", {})))
        self.assertEqual(_nectar_amounts(self.saves["bought"]), [FRESH - CELL_CAPACITY_COST, FERMENTED])


if __name__ == "__main__":
    unittest.main()
