"""The queen obeys a direct order to discard sour nectar without Cleaning."""
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from analyze_session import load_entries
from godot_compile_check import find_godot
from run_scenario import run_once, scenario_saves_dir


class QueenEmptiesSourTest(unittest.TestCase):
    def test_direct_order_discards_sour_nectar(self):
        godot = find_godot()
        if not godot:
            self.skipTest("no Godot executable found")
        session = run_once(ROOT / "test_scenarios/pn18_queen_empties_sour.json", godot,
                           timeout=300, fixed_fps=30)
        self.assertIsNotNone(session)
        rejected = [e for e in load_entries(session)
                    if e.get("type") == "action" and e.get("result") == "rejected"]
        self.assertEqual(rejected, [])
        scratch = scenario_saves_dir(session)
        before, done = [json.loads((scratch / f"pn18-{name}.json").read_text(encoding="utf-8"))
                        for name in ("before", "done")]
        self.assertEqual(len(before["bees"]), 1)
        self.assertTrue(before["bees"][0]["queen"])
        self.assertNotEqual(before["bees"][0]["role"], 2, "queen is a comb worker")
        self.assertIn("skill.hive_mind.cleaning", before["skill_policy"]["bans"])
        source = next(c for c in before["cells"] if (c["q"], c["r"]) == (0, 0))
        self.assertEqual(source["content"], "nectar")
        self.assertGreater(before["clock"]["sim_time"] - source["nectar_since"], 10,
                           "nectar had not soured before the order")
        source_done = next(c for c in done["cells"] if (c["q"], c["r"]) == (0, 0))
        self.assertEqual(source_done.get("content"), "", "the queen did not empty the cell")
        self.assertFalse(any(c.get("content") == "nectar" for c in done["cells"]),
                         "sour nectar was moved instead of discarded")
