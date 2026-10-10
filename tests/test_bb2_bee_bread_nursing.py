"""BB-2: Nurses feed Bee Bread; a worker's outcome is fixed at emergence and saved.

Runs test_scenarios/bb2_bee_bread_nursing.json once, on the game's own
ration and outcomes. The fixture stocks one cell with 60 units of bee bread
(a full, sealed cell) and makes it ripe within seconds (bee_bread_ripen_hours
set to 1), stocks pollen and nectar, reserves five nursery cells, and leaves
the queen and two nurses to raise brood: first beside the ripe bee bread,
then, once the nurses have used it up, beside none. It saves at 300 and 600
game seconds, restores the second save and saves once more.

From that run: the nurses draw the bee bread cell down; a worker that emerged
while the colony still held bee bread was raised on it, and every worker
emerging after it ran out with nothing but pollen was raised on pollen; each
outcome's lifespan, speed and carrying capacity apply (the save's per-bee
"stats" readout, against game_config.gd's values and the bee's rolled trait);
the outcomes and stats survive save and restore; and the founding bees, whose
save entries carry no outcome at all -- the shape of every bee in a save made
before BB-2 -- load as today's workers, 25 days at 100%.

The run gets a user:// of its own (APPDATA pointed at a temporary folder),
for the reason test_bb1_bee_bread.py gives.
"""

from __future__ import annotations

import json
import os
import re
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import log_dir, run_once  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "bb2_bee_bread_nursing.json"
GAME_CONFIG = ROOT / "scripts" / "game_config.gd"
SAVES = ("mid", "late", "restored")
BEE_BREAD_HEX = (0, 0)


def _config(name: str) -> float:
    match = re.search(r"^var %s: float = ([0-9.]+)" % name, GAME_CONFIG.read_text(encoding="utf-8"), re.M)
    if match is None:
        raise AssertionError("game_config.gd has no float %s" % name)
    return float(match.group(1))


def _raised(save: dict, outcome: str | None = None) -> dict:
    """Bees with an outcome (or with the one named), by id."""
    return {int(b["id"]): b for b in save["bees"]
            if b.get("brood_outcome") and (outcome is None or b["brood_outcome"] == outcome)}


class BeeBreadNursingRunTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        # An outcome's lifespan is a factor on bee_lifespan_days (25 and 15
        # days by default), so a scenario's bee_lifespan_days still governs.
        days = _config("bee_lifespan_days")
        cls.outcomes = {
            "bee_bread": (days * _config("bee_bread_raised_lifespan_factor"), _config("bee_bread_raised_stat_factor")),
            "pollen": (days * _config("pollen_raised_lifespan_factor"), _config("pollen_raised_stat_factor")),
        }
        cls.base = {
            "speed": ("speed", _config("bee_speed")),
            "nectar_capacity": ("nectar_stomach_capacity", _config("nectar_stomach_capacity")),
            "pollen_capacity": ("pollen_stomach_capacity", _config("pollen_stomach_capacity")),
        }
        cls.standard_days = _config("bee_lifespan_days")
        old_appdata = os.environ.get("APPDATA")
        with tempfile.TemporaryDirectory(prefix="meadow-bb2-") as appdata:
            os.environ["APPDATA"] = appdata
            try:
                session_file = run_once(FIXTURE, godot_path, timeout=600, fixed_fps=30)
                if session_file is None:
                    raise AssertionError("scenario run produced no session log")
                entries = load_entries(session_file)
                scratch = log_dir().parent / "scenario_saves"
                cls.saves = {}
                for name in SAVES:
                    path = scratch / ("bb2-%s.json" % name)
                    if path.exists():
                        cls.saves[name] = json.loads(path.read_text(encoding="utf-8"))
            finally:
                if old_appdata is None:
                    os.environ.pop("APPDATA", None)
                else:
                    os.environ["APPDATA"] = old_appdata
        cls.rejected = [e for e in entries if e.get("type") == "action" and e.get("result") == "rejected"]
        cls.snapshots = [e for e in entries if e.get("type") == "snapshot"]

    def setUp(self):
        self.assertEqual(self.rejected, [], "a scenario action was rejected")
        missing = [n for n in SAVES if n not in self.saves]
        self.assertEqual(missing, [], "the run did not write every save")
        self.assertTrue(self.snapshots, "the run logged no snapshots")

    def _ran_out_at(self) -> float:
        """Game time of the first snapshot with no bee bread left in the comb."""
        stocked = [s for s in self.snapshots if s["cells"]["stored_bee_bread"] > 0.0]
        self.assertTrue(stocked, "the bee bread cell was never stocked")
        empty = [s["game_time"] for s in self.snapshots
                 if s["game_time"] > stocked[0]["game_time"] and s["cells"]["stored_bee_bread"] <= 0.0]
        self.assertTrue(empty, "the nurses never used up the bee bread")
        return empty[0]

    def _emerged_at(self, bee: dict, save: str) -> float:
        return float(self.saves[save]["clock"]["sim_time"]) - float(bee["age"])

    def _assert_stats(self, bee: dict, days: float, factor: float):
        stats = bee["stats"]
        self.assertAlmostEqual(float(stats["lifespan_days"]), days, places=3, msg="bee %s lifespan" % bee["id"])
        for key, (trait, base) in self.base.items():
            expected = base * factor
            if bee.get("trait_stat") == trait:
                expected *= 1.0 + float(bee["trait_pct"])
            self.assertAlmostEqual(float(stats[key]), expected, places=3, msg="bee %s %s" % (bee["id"], key))

    def test_the_nurses_feed_the_bee_bread(self):
        stored = [s["cells"]["stored_bee_bread"] for s in self.snapshots]
        self.assertAlmostEqual(max(stored), 60.0, places=3)
        for earlier, later in zip(stored, stored[1:]):
            self.assertLessEqual(later, earlier + 0.001, "bee bread came back with no fermenter")
        self.assertGreater(self._ran_out_at(), 0.0)

    def test_a_larva_fed_bee_bread_emerges_with_the_bee_bread_outcome(self):
        with_bread = _raised(self.saves["mid"], "bee_bread")
        self.assertGreaterEqual(len(with_bread), 2, "too few workers raised on bee bread")
        ran_out = self._ran_out_at()
        early = [b for b in self.saves["late"]["bees"]
                 if b.get("brood_outcome") and self._emerged_at(b, "late") < ran_out]
        self.assertTrue(early, "no worker emerged while the colony still held bee bread")
        for bee in early:
            self.assertEqual(bee["brood_outcome"], "bee_bread", "bee %s emerged beside bee bread" % bee["id"])
        days, factor = self.outcomes["bee_bread"]
        self.assertAlmostEqual(days, 25.0, places=6)
        self.assertAlmostEqual(factor, 1.05, places=6)
        for bee in _raised(self.saves["late"], "bee_bread").values():
            self._assert_stats(bee, days, factor)

    def test_a_larva_fed_only_pollen_emerges_with_the_pollen_outcome(self):
        pollen = _raised(self.saves["late"], "pollen")
        self.assertGreaterEqual(len(pollen), 2, "too few workers raised on pollen")
        ran_out = self._ran_out_at()
        for bee in pollen.values():
            self.assertGreater(self._emerged_at(bee, "late"), ran_out,
                               "bee %s was raised on pollen while bee bread was ripe" % bee["id"])
        days, factor = self.outcomes["pollen"]
        self.assertAlmostEqual(days, 15.0, places=6)
        self.assertAlmostEqual(factor, 0.95, places=6)
        for bee in pollen.values():
            self._assert_stats(bee, days, factor)

    def test_the_outcome_survives_save_and_restore(self):
        before, after = _raised(self.saves["late"]), _raised(self.saves["restored"])
        self.assertEqual(sorted(after), sorted(before))
        for bee_id, bee in before.items():
            self.assertEqual(after[bee_id]["brood_outcome"], bee["brood_outcome"])
            for key, value in bee["stats"].items():
                self.assertAlmostEqual(float(after[bee_id]["stats"][key]), float(value), places=3,
                                       msg="bee %d %s" % (bee_id, key))
        cells = {(c["q"], c["r"]): c for c in self.saves["late"]["cells"]}
        for cell in self.saves["restored"]["cells"]:
            if cell["content"] == "brood":
                self.assertEqual(cell["brood_food"], cells[(cell["q"], cell["r"])]["brood_food"])

    def test_a_bee_saved_without_an_outcome_loads_as_todays_worker(self):
        # A founder's entry has no brood_outcome key, exactly as every bee in a
        # save from before BB-2; the restored save went through that default.
        for name in SAVES:
            founders = [b for b in self.saves[name]["bees"] if "brood_outcome" not in b]
            self.assertEqual(len(founders), 3, "%s: the queen and two nurses" % name)
            for bee in founders:
                if bee.get("queen"):
                    continue
                self._assert_stats(bee, self.standard_days, 1.0)


if __name__ == "__main__":
    unittest.main()
