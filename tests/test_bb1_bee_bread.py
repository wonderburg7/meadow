"""BB-1: Fermenting honey workers make Bee Bread in a store cell.

Runs test_scenarios/bb1_bee_bread.json once, on the game's own recipe (no
config overrides for it). The fixture owns the Bee bread skill, stocks
pollen and honey, reserves the cell at hex (0, 0) for bee bread and turns
both honey workers to Fermenting. It saves at the end of day one, makes every
adult eat at each chance (hunger_threshold 0.98), saves again past day three,
then restores the first save and saves once more.

From that run: the reserved cell fills and seals within the first day; the
diagnostic snapshots (every 10 game seconds) count no ripe bee bread before
bee_bread_ripen_hours have passed since the seal and count it after; the
sealed cell keeps every unit while the adults eat, and the colony's bee bread
never goes down; pollen and ripe honey never run out; and the cell's seal
stamp and contents and the bees' Fermenting flag survive save and restore.
A static check keeps the three bee bread colours apart from every other
cell-content colour.
"""

from __future__ import annotations

import json
import math
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import log_dir, run_once  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "bb1_bee_bread.json"
GAME_CONFIG = ROOT / "scripts" / "game_config.gd"
HIVE_CELL = ROOT / "scripts" / "hive_cell.gd"
SAVES = ("day1", "day3", "restored")
HONEY_ROLE = 6   # roles.gd HONEY
RESERVED_HEX = (0, 0)


def _config(name: str) -> float:
    match = re.search(r"^var %s: float = ([0-9.]+)" % name, GAME_CONFIG.read_text(encoding="utf-8"), re.M)
    if match is None:
        raise AssertionError("game_config.gd has no float %s" % name)
    return float(match.group(1))


def _cell(save: dict, q: int, r: int) -> dict:
    return next(c for c in save["cells"] if int(c["q"]) == q and int(c["r"]) == r)


def _honey_bees(save: dict) -> dict:
    return {int(b["id"]): b for b in save["bees"] if int(b["role"]) == HONEY_ROLE}


# --- OKLab, for the colour check ----------------------------------

def _linear(channel: float) -> float:
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4


def _oklab(rgb: tuple) -> tuple:
    r, g, b = (_linear(c) for c in rgb)
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l, m, s = (math.copysign(abs(v) ** (1.0 / 3.0), v) for v in (l, m, s))
    return (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


class BeeBreadColourTest(unittest.TestCase):
    def test_bee_bread_colours_stand_apart(self):
        source = HIVE_CELL.read_text(encoding="utf-8")
        colours = {
            name: tuple(float(v) for v in values)
            for name, *values in re.findall(
                r"^const (\w+_COLOR) := Color\(([0-9.]+), ([0-9.]+), ([0-9.]+)\)", source, re.M)
        }
        ours = [name for name in colours if name.startswith("BEE_BREAD")]
        self.assertEqual(sorted(ours), ["BEE_BREAD_COLOR", "BEE_BREAD_RIPE_COLOR", "BEE_BREAD_SEALED_COLOR"])
        for name in ours:
            for other, rgb in colours.items():
                if other == name:
                    continue
                gap = math.dist(_oklab(colours[name]), _oklab(rgb))
                self.assertGreaterEqual(gap, 0.10, "%s is only %.3f from %s" % (name, gap, other))


class BeeBreadRunTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        cls.capacity = _config("bee_bread_cell_capacity")
        cls.day = _config("seconds_per_day")
        cls.ripen = _config("bee_bread_ripen_hours") * cls.day / 24.0
        session_file = run_once(FIXTURE, godot_path, timeout=600, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        entries = load_entries(session_file)
        cls.rejected = [e for e in entries if e.get("type") == "action" and e.get("result") == "rejected"]
        cls.snapshots = [e for e in entries if e.get("type") == "snapshot"]
        scratch = log_dir().parent / "scenario_saves"
        cls.saves = {}
        for name in SAVES:
            path = scratch / ("bb1-%s.json" % name)
            if path.exists():
                cls.saves[name] = json.loads(path.read_text(encoding="utf-8"))

    def setUp(self):
        self.assertEqual(self.rejected, [], "a scenario action was rejected")
        missing = [n for n in SAVES if n not in self.saves]
        self.assertEqual(missing, [], "the run did not write every save")
        self.assertTrue(self.snapshots, "the run logged no snapshots")

    def _reserved(self, name: str) -> dict:
        return _cell(self.saves[name], *RESERVED_HEX)

    def _sealed_at(self) -> float:
        return float(self._reserved("day1")["bee_bread_sealed_at"])

    def test_fermenters_fill_and_seal_the_reserved_cell_on_day_one(self):
        bees = _honey_bees(self.saves["day1"])
        self.assertEqual(len(bees), 2)
        self.assertTrue(all(b["fermenting"] for b in bees.values()), "a honey worker was not Fermenting")
        cell = self._reserved("day1")
        self.assertEqual(cell["designated"], "bee_bread")
        self.assertEqual(cell["content"], "bee_bread")
        self.assertAlmostEqual(float(cell["amount"]), self.capacity, places=3)
        self.assertGreaterEqual(self._sealed_at(), 0.0, "the full cell never sealed")
        self.assertLess(self._sealed_at(), self.day, "the cell did not seal within the first game-day")

    def test_it_ripens_only_after_the_ripening_hours(self):
        sealed_at = self._sealed_at()
        self.assertLessEqual(sealed_at + self.ripen, 3.0 * self.day, "not ripe within three game-days")
        before = [s for s in self.snapshots if s["game_time"] < sealed_at + self.ripen - 0.5]
        after = [s for s in self.snapshots if s["game_time"] > sealed_at + self.ripen + 0.5]
        self.assertTrue(before and after, "the run does not span the ripening")
        for snap in before:
            self.assertEqual(snap["cells"]["bee_bread_ripe"], 0, "ripe at %.1f s" % snap["game_time"])
            if snap["game_time"] > sealed_at + 0.5:
                self.assertGreaterEqual(snap["cells"]["bee_bread_sealed"], 1)
        for snap in after:
            self.assertGreaterEqual(snap["cells"]["bee_bread_ripe"], 1, "unripe at %.1f s" % snap["game_time"])

    def test_no_adult_eats_it(self):
        self.assertAlmostEqual(float(self._reserved("day3")["amount"]), self.capacity, places=3)
        self.assertEqual(self._reserved("day3")["bee_bread_sealed_at"], self._reserved("day1")["bee_bread_sealed_at"])
        stored = [s["cells"]["stored_bee_bread"] for s in self.snapshots]
        for earlier, later in zip(stored, stored[1:]):
            self.assertGreaterEqual(later, earlier - 0.001, "the colony's bee bread went down")
        # Adults were eating meanwhile -- from honey, not from the bee bread.
        after_day1 = [s for s in self.snapshots if s["game_time"] > self.day + 1.0]
        eating = sum(s["population"]["by_state"].get("FEEDING", 0) + s["population"]["by_state"].get("TO_FEED_CELL", 0)
                     for s in after_day1)
        self.assertGreater(eating, 0, "no adult was caught eating after day one")

    def test_pollen_and_honey_never_run_out(self):
        for snap in self.snapshots:
            self.assertGreater(snap["resources"]["stored_pollen"], 0.0, "pollen ran out at %.1f s" % snap["game_time"])
        ripe = [s["resources"]["food_stores"] for s in self.snapshots]
        first = next(i for i, amount in enumerate(ripe) if amount > 0.0)
        self.assertTrue(all(amount > 0.0 for amount in ripe[first:]), "ripe honey ran out")

    def test_the_cell_and_the_mode_survive_save_and_restore(self):
        saved, restored = self._reserved("day1"), self._reserved("restored")
        for field in ("content", "designated"):
            self.assertEqual(restored[field], saved[field])
        self.assertAlmostEqual(float(restored["amount"]), float(saved["amount"]), places=3)
        self.assertAlmostEqual(float(restored["bee_bread_sealed_at"]), float(saved["bee_bread_sealed_at"]), places=3)
        before, after = _honey_bees(self.saves["day1"]), _honey_bees(self.saves["restored"])
        self.assertEqual(sorted(after), sorted(before))
        for bee_id, bee in before.items():
            self.assertEqual(after[bee_id]["fermenting"], bee["fermenting"])
            self.assertAlmostEqual(float(after[bee_id]["bee_bread_load"]), float(bee["bee_bread_load"]), places=3)


if __name__ == "__main__":
    unittest.main()
