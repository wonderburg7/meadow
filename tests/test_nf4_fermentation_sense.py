"""NF-4: the fermentation sense skill.

Runs test_scenarios/nf4_fermentation_sense.json twice: as written (no skill),
then from a copy that adds skill.colony.fermentation_sense to skill_grants.
Each run's saves are read from its own user:// (scenario_saves_dir). The fixture has three phases:

1. Honey. W, beside the designated honey cell HP, is the only nectar, so both
   honey makers lift from it and end up fanning HP. O (far from HP) is stocked
   four seconds before Y (beside HP); both are fresh. Saves every 3 s show
   which of the two they draw from first.
2. Nurses and restocking. Honey stops ripening (so it is never food), F1 and
   F2 are stocked and left to ferment, then a restock order names F2 as the
   only source for the empty cell R, and pollen lets the queen lay. Hunger is
   low, the honey makers are fanning for good, and the order draws from F2
   only, so anything F1 loses went to a nurse.
3. Eating. Fresh nectar E is stocked after F1 in index order, and hunger is
   raised to 98% so every bee eats. Seven comb workers make twelve bees, more
   than E's six walls, so some find E full while F1 and F2 have room.

From the saves: with the skill, honey makers take the oldest nectar (O) first,
no nurse carries nectar while only fermented nectar is stored, F1 and F2 are
never touched, R gets nothing, and no bee is ever tipsy while E still holds
fresh nectar. Without it, honey makers take the closest (Y) first, nurses
empty fermented F1, the restock order fills R from fermented F2, and hungry
bees eat fermented nectar and go tipsy.

RR-15: DepositTest runs a second, generated fixture. One cell holds sour
nectar with room left, the rest are empty; a comb worker is sent foraging
and the queen is set to forage carrying nectar. With the skill the sour
cell never gains nectar and the fresh deposits land elsewhere; without it
the sour cell is topped up.
"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once, scenario_saves_dir  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "nf4_fermentation_sense.json"
SKILL = "skill.colony.fermentation_sense"
HONEY = ["h-%d" % i for i in range(30)]
NURSE = ["nr-start"] + ["nr-%d" % i for i in range(15)]
EAT = ["eat-%d" % i for i in range(12)]
SAVES = HONEY + NURSE + EAT
NURSERY = 1   # bee_enums.gd Role.NURSERY
O, Y = (-2, 1), (2, -2)
F1, F2, R, E = (0, -1), (1, -1), (1, 0), (1, -2)
CONFIG = json.loads(FIXTURE.read_text(encoding="utf-8"))["config_overrides"]
FERMENT_SECONDS = float(CONFIG["nectar_ferment_hours"]) * float(CONFIG["seconds_per_day"]) / 24.0


def _run(fixture: dict, names: list = SAVES, prefix: str = "nf4") -> tuple[list, dict]:
    with tempfile.TemporaryDirectory(prefix="nf4-fixture-", dir=ROOT) as folder:
        path = Path(folder) / "nf4_fixture.json"
        path.write_text(json.dumps(fixture), encoding="utf-8")
        session_file = run_once(path, find_godot(), timeout=900, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        rejected = [e for e in load_entries(session_file)
                    if e.get("type") == "action" and e.get("result") == "rejected"]
        scratch = scenario_saves_dir(session_file)
        saves = {}
        for name in names:
            save = scratch / ("%s-%s.json" % (prefix, name))
            if save.exists():
                saves[name] = json.loads(save.read_text(encoding="utf-8"))
    return rejected, saves


def _nectar(save: dict, hex_: tuple) -> float:
    for cell in save["cells"]:
        if (int(cell["q"]), int(cell["r"])) == hex_:
            return float(cell["amount"]) if cell.get("content") == "nectar" else 0.0
    raise AssertionError("no cell at %s" % (hex_,))


def _fermented(save: dict, hex_: tuple, after: float = FERMENT_SECONDS) -> bool:
    for cell in save["cells"]:
        if (int(cell["q"]), int(cell["r"])) == hex_ and cell.get("content") == "nectar":
            since = float(cell.get("nectar_since", -1.0))
            return since >= 0.0 and float(save["clock"]["sim_time"]) - since > after
    return False


def _tipsy(save: dict) -> list:
    return [b["id"] for b in save["bees"] if float(b.get("tipsy", 0.0)) > 0.0]


def _nurses_carrying_nectar(save: dict) -> list:
    return [b["id"] for b in save["bees"] if int(b.get("role", -1)) == NURSERY
            and b.get("nurse_carb_type") == "nectar" and float(b.get("nurse_carb", 0.0)) > 0.0]


def _first_honey_draw(saves: dict) -> str:
    """'O' or 'Y': which cell honey makers drew from first, from the first
    save where either holds less than at the first save; '' if neither did
    or both changed between the same two saves."""
    o0, y0 = _nectar(saves[HONEY[0]], O), _nectar(saves[HONEY[0]], Y)
    for name in HONEY[1:]:
        o, y = _nectar(saves[name], O), _nectar(saves[name], Y)
        if o < o0 and y >= y0:
            return "O"
        if y < y0 and o >= o0:
            return "Y"
        if o < o0 or y < y0:
            return ""
    return ""


class FermentationSenseTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not find_godot():
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
        cls.plain_rejected, cls.plain = _run(fixture)
        sensing = dict(fixture)
        sensing["skill_grants"] = list(fixture.get("skill_grants", [])) + [SKILL]
        cls.sense_rejected, cls.sense = _run(sensing)

    def setUp(self):
        self.assertEqual(self.plain_rejected, [], "a scenario action was rejected without the skill")
        self.assertEqual(self.sense_rejected, [], "a scenario action was rejected with the skill")
        for label, saves in (("without", self.plain), ("with", self.sense)):
            missing = [n for n in SAVES if n not in saves]
            self.assertEqual(missing, [], "the run %s the skill did not write every save" % label)
        self.assertNotIn(SKILL, json.dumps(self.plain["nr-start"].get("skills", {})))
        self.assertIn(SKILL, json.dumps(self.sense["nr-start"].get("skills", {})))
        for saves in (self.plain, self.sense):
            start = saves["nr-start"]
            self.assertTrue(_fermented(start, F1) and _fermented(start, F2),
                            "F1 and F2 had not fermented when the nurse phase began")
            self.assertGreater(_nectar(start, F1), 0.0)
            self.assertGreater(_nectar(start, F2), 0.0)
            self.assertEqual(_nectar(start, R), 0.0)

    # --- honey makers -----------------------------------------------------

    def test_with_the_skill_honey_makers_take_the_oldest_nectar_first(self):
        self.assertEqual(_first_honey_draw(self.sense), "O")
        for name in HONEY:
            if _nectar(self.sense[name], Y) < _nectar(self.sense[HONEY[0]], Y):
                self.assertEqual(_nectar(self.sense[name], O), 0.0,
                                 "the younger cell was drawn on before the older one was empty (%s)" % name)

    def test_without_it_honey_makers_take_the_closest_nectar_first(self):
        self.assertEqual(_first_honey_draw(self.plain), "Y")
        for name in HONEY:
            if _nectar(self.plain[name], O) < _nectar(self.plain[HONEY[0]], O):
                self.assertEqual(_nectar(self.plain[name], Y), 0.0,
                                 "the far cell was drawn on before the near one was empty (%s)" % name)

    # --- nurses -----------------------------------------------------------

    def test_with_the_skill_nurses_never_take_fermented_nectar(self):
        start = self.sense["nr-start"]
        for name in NURSE + EAT:
            self.assertAlmostEqual(_nectar(self.sense[name], F1), _nectar(start, F1), places=3,
                                   msg="fermented F1 lost nectar at %s" % name)
        for name in NURSE:
            self.assertEqual(_nurses_carrying_nectar(self.sense[name]), [],
                             "a nurse carried nectar while only fermented nectar was stored (%s)" % name)
        # The nurses were working: they loaded pollen for the brood.
        self.assertTrue(any(float(b.get("nurse_pollen", 0.0)) > 0.0 for name in NURSE
                            for b in self.sense[name]["bees"] if int(b.get("role", -1)) == NURSERY),
                        "no nurse ever loaded pollen, so the phase proves nothing")

    def test_without_it_nurses_take_fermented_nectar(self):
        self.assertLess(_nectar(self.plain["nr-14"], F1), _nectar(self.plain["nr-start"], F1),
                        "no nurse took from fermented F1")
        self.assertTrue(any(_nurses_carrying_nectar(self.plain[name]) for name in NURSE),
                        "no nurse was seen carrying nectar")

    # --- restock orders ---------------------------------------------------

    def test_with_the_skill_a_restock_order_never_draws_from_a_fermented_cell(self):
        start = self.sense["nr-start"]
        for name in NURSE + EAT:
            self.assertEqual(_nectar(self.sense[name], R), 0.0, "R was restocked at %s" % name)
            self.assertAlmostEqual(_nectar(self.sense[name], F2), _nectar(start, F2), places=3,
                                   msg="fermented F2 lost nectar at %s" % name)

    def test_without_it_a_restock_order_draws_from_a_fermented_cell(self):
        self.assertGreater(_nectar(self.plain["nr-14"], R), 0.0, "R was never restocked from F2")
        self.assertLess(_nectar(self.plain["nr-14"], F2), _nectar(self.plain["nr-start"], F2))

    # --- eating -----------------------------------------------------------

    def test_with_the_skill_no_bee_goes_tipsy_while_fresh_food_is_left(self):
        for name in SAVES:
            self.assertEqual(_tipsy(self.sense[name]), [], "a bee was tipsy at %s" % name)
        before, after = _nectar(self.sense["nr-14"], E), _nectar(self.sense[EAT[-1]], E)
        self.assertEqual(before, 0.0)
        self.assertGreater(_nectar(self.sense[EAT[0]], E), 0.0)
        self.assertGreater(after, 0.0, "fresh food ran out, so the phase proves nothing")
        self.assertLess(after, 200.0, "nobody ate the fresh nectar")

    def test_with_the_skill_a_bee_waits_for_fresh_food_rather_than_drink_sour(self):
        # Twelve hungry bees and one fresh cell with six walls: those that
        # find it full wait for a wall (no tipsiness, above) and still eat,
        # rather than starving while switching between it and a sour cell.
        bees = self.sense[EAT[-1]]["bees"]
        self.assertGreater(len(bees), 6, "too few bees to fill the fresh cell's walls")
        hungry = [b for b in self.sense["nr-14"]["bees"] if float(b["energy"]) < 95.0]
        self.assertGreater(len(hungry), 6, "too few hungry bees to fill the fresh cell's walls")
        fed = {b["id"]: float(b["energy"]) for b in bees}
        for bee in hungry:
            self.assertGreaterEqual(fed.get(bee["id"], 0.0), 95.0, "bee %s never got to eat" % bee["id"])

    def test_without_it_hungry_bees_eat_fermented_nectar_and_go_tipsy(self):
        self.assertTrue(any(_tipsy(self.plain[name]) for name in EAT), "no bee went tipsy")
        self.assertTrue(all(_nectar(self.plain[name], E) > 0.0 for name in EAT),
                        "the fresh nectar ran out, so the tipsiness proves nothing")


DEP_SAVES = ["start"] + ["d-%d" % i for i in range(12)]
SOUR = (0, -1)
DEP_FERMENT_SECONDS = 10.0   # 12 ferment hours at 20 s a day


def _deposit_fixture() -> dict:
    actions = [
        {"do": "set_cell_contents", "hex": list(SOUR), "resource": "nectar", "amount": 60},
        {"do": "wait", "seconds": 12},
        {"do": "save_run", "name": "NF4 dep start"},
        {"do": "assign_role", "target": {"current_role": "comb_worker"}, "role": "forager_nectar"},
        {"do": "assign_role", "target": {"queen": True}, "role": "forager_nectar"},
        {"do": "set_queen_load", "resource": "nectar", "amount": 5, "state": "IN_HIVE_TO_CELL"},
    ]
    for i in range(12):
        actions += [{"do": "wait", "seconds": 5}, {"do": "save_run", "name": "NF4 dep d %d" % i}]
    return {
        "cells": 7, "nectar_foragers": 0, "pollen_foragers": 0, "nurses": 0, "builders": 2,
        "miners": 0, "honey_makers": 0, "weather": False, "disease": False, "rival_hive": False,
        "winter": False, "random_seed": 5404,
        "config_overrides": {"seconds_per_day": 20, "nectar_ferment_hours": 12,
                             "hunger_threshold": 0.05, "energy_burn_rate": 0.02},
        "actions": actions, "stop": {"when_actions_resolved": True, "max_days": 5},
    }


def _stored_elsewhere(save: dict) -> float:
    return sum(float(c["amount"]) for c in save["cells"]
               if c.get("content") == "nectar" and (int(c["q"]), int(c["r"])) != SOUR)


class DepositTest(unittest.TestCase):
    """RR-15: find_cell_for keeps fresh nectar out of a sour cell."""

    @classmethod
    def setUpClass(cls):
        if not find_godot():
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        fixture = _deposit_fixture()
        cls.plain_rejected, cls.plain = _run(fixture, DEP_SAVES, "nf4-dep")
        sensing = dict(fixture)
        sensing["skill_grants"] = [SKILL]
        cls.sense_rejected, cls.sense = _run(sensing, DEP_SAVES, "nf4-dep")

    def setUp(self):
        self.assertEqual(self.plain_rejected, [], "a scenario action was rejected without the skill")
        self.assertEqual(self.sense_rejected, [], "a scenario action was rejected with the skill")
        for saves in (self.plain, self.sense):
            self.assertEqual([n for n in DEP_SAVES if n not in saves], [])
            self.assertTrue(_fermented(saves["start"], SOUR, DEP_FERMENT_SECONDS), "the sour cell had not fermented")
            self.assertEqual(_nectar(saves["start"], SOUR), 60.0)

    def test_with_the_skill_no_depositing_bee_tops_up_a_sour_cell(self):
        for name in DEP_SAVES:
            self.assertLessEqual(_nectar(self.sense[name], SOUR), 60.0 + 1e-6,
                                 "a bee poured fresh nectar into the sour cell at %s" % name)
        self.assertGreater(_stored_elsewhere(self.sense[DEP_SAVES[-1]]), 0.0,
                           "nobody deposited anywhere, so the run proves nothing")

    def test_without_the_skill_a_depositing_bee_can_top_up_a_sour_cell(self):
        self.assertTrue(any(_nectar(self.plain[name], SOUR) > 60.0 + 1e-6 for name in DEP_SAVES),
                        "no bee topped up the sour cell")


if __name__ == "__main__":
    unittest.main()
