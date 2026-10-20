"""T3-2: Restocking becomes a purchase.

Static part: the Stocking mode names the skill, so the HUD hides it unowned
(and, with it, the keep-full controls); the order handlers and the restock
job refuse without it. Run part (test_scenarios/t3_2_restocking_gate.json):
an unowned colony's keep-full order is refused and the target cell stays
empty; once the skill is granted the same order is accepted and the Comb
worker fills the cell. (The Anything-mode skip in find_restock_job is shown
by the static test only: no scenario action takes a skill away, and a saved
order cannot exist without the skill.)
Keep-empty is a cell setting the gate does not touch.
"""

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

FIXTURE = ROOT / "test_scenarios" / "t3_2_restocking_gate.json"
SKILL = "skill.colony.restocking"


def _read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def _target_amount(save: dict) -> float:
    for cell in save["cells"]:
        if cell["q"] == 0 and cell["r"] == 0:
            return float(cell["amount"]) if cell["content"] == "nectar" else 0.0
    raise AssertionError("no cell at 0,0 in the save")


class StaticGateTest(unittest.TestCase):
    def test_stocking_mode_names_the_skill(self):
        text = _read("scripts/roles.gd")
        self.assertIn('{"key": "restock", "skill": "%s"' % SKILL, text)

    def test_keep_full_controls_and_mode_hidden_unowned(self):
        hud = _read("scripts/hud.gd")
        self.assertIn('first.architect_mode == "restock" and Availability.mode_query(Roles.COMB_WORKER, "restock"', hud)
        self.assertIn("common_role == Roles.COMB_WORKER or common_role == Roles.MINER) and not Availability.mode_query(", hud)

    def test_handlers_and_job_refuse(self):
        zones = _read("scripts/orders_zones.gd")
        self.assertEqual(zones.count("if _restocking_refused():"), 2)
        self.assertIn('mode_key == "restock" and _restocking_refused()', zones)
        building = _read("scripts/bee_building.gd")
        job = building[building.index("static func find_restock_job"):]
        self.assertIn("if not restocking_owned():", job[:job.index("\nstatic func ")] if "\nstatic func " in job else job)

    def test_keep_empty_is_not_gated(self):
        zones = _read("scripts/orders_zones.gd")
        self.assertNotIn("keep_empty", zones[zones.index("func _restocking_refused"):zones.index("func _on_restock_clear_requested")])


class RestockingGateRunTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(FIXTURE, godot_path, timeout=600, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        entries = load_entries(session_file)
        scratch = scenario_saves_dir(session_file)
        cls.saves = {}
        for name in ("unowned", "owned"):
            path = scratch / ("t3-2-%s.json" % name)
            if path.exists():
                cls.saves[name] = json.loads(path.read_text(encoding="utf-8"))
        cls.actions = [e for e in entries if e.get("type") == "action"]

    def test_run_wrote_all_saves(self):
        self.assertEqual(sorted(self.saves), ["owned", "unowned"])

    def test_unowned_order_is_refused_and_nothing_is_stocked(self):
        orders = [a for a in self.actions if a.get("do") == "set_restock_order"]
        self.assertEqual([a.get("result") for a in orders], ["accepted"])
        self.assertEqual(_target_amount(self.saves["unowned"]), 0.0)
        for bee in self.saves["unowned"]["bees"]:
            self.assertEqual(bee.get("restock_targets", []), [], "an unowned order stuck")

    def test_owned_stocking_fills_the_target(self):
        self.assertGreater(_target_amount(self.saves["owned"]), _target_amount(self.saves["unowned"]))


if __name__ == "__main__":
    unittest.main()
