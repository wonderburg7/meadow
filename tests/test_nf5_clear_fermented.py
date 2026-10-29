"""NF-5: the "Discard all sour nectar" order clears fermented cells.

Runs test_scenarios/nf5_clear_fermented.json once (short fermentation, two
comb workers, no honey makers). It ferments three nectar cells, stocks a fresh
control cell, runs clear_fermented, saves while the workers are partway
through, restores that save and lets them finish. It then ferments one more
cell and empties it with empty_cell (the move path). The saves, read back from
the run's own scenario scratch root (scenario_saves_dir), show the marks, their survival, the three cells
ending empty, the control untouched, and nothing laundered into another cell.
"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once, scenario_saves_dir  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "nf5_clear_fermented.json"
SAVES = ("before", "marked", "partway", "restored", "done", "moved")


def _nectar(save: dict) -> dict:
    return {(int(c["q"]), int(c["r"])): c for c in save["cells"] if c.get("content") == "nectar"}


def _cell(save: dict, key: tuple) -> dict:
    return next(c for c in save["cells"] if (int(c["q"]), int(c["r"])) == key)


class ClearFermentedTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(FIXTURE, godot_path, timeout=300, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        cls.rejected = [e for e in load_entries(session_file)
                        if e.get("type") == "action" and e.get("result") == "rejected"]
        scratch = scenario_saves_dir(session_file)
        cls.saves = {}
        for name in SAVES:
            path = scratch / ("nf5-%s.json" % name)
            if path.exists():
                cls.saves[name] = json.loads(path.read_text(encoding="utf-8"))

    def setUp(self):
        self.assertEqual(self.rejected, [], "a scenario action was rejected")
        missing = [n for n in SAVES if n not in self.saves]
        self.assertEqual(missing, [], "the run did not write every save")
        before = _nectar(self.saves["before"])
        self.assertEqual(len(before), 4, "expected three sour cells and one control")
        # The control was stocked last, so it has the newest stamp.
        self.control = max(before, key=lambda k: float(before[k]["nectar_since"]))
        self.sour = [k for k in before if k != self.control]

    def test_exactly_the_fermented_cells_are_marked(self):
        marked = self.saves["marked"]
        for key in self.sour:
            cell = _cell(marked, key)
            self.assertTrue(cell.get("evict"), "a fermented cell was not marked")
            self.assertEqual(cell.get("evict_mode"), "discard")
        control = _cell(marked, self.control)
        self.assertFalse(control.get("evict", False), "the fresh control cell was marked")

    def test_marks_survive_save_and_restore(self):
        partway = self.saves["partway"]
        still = [k for k in self.sour if _cell(partway, k).get("content") == "nectar"]
        self.assertTrue(still, "every cell was already empty when the save was taken")
        restored = self.saves["restored"]
        for key in still:
            cell = _cell(restored, key)
            if cell.get("content") == "nectar":
                self.assertTrue(cell.get("evict"), "a mark was lost across the restore")
                self.assertEqual(cell.get("evict_mode"), "discard")

    def test_all_three_end_empty_and_the_control_is_untouched(self):
        done = self.saves["done"]
        for key in self.sour:
            self.assertNotEqual(_cell(done, key).get("content"), "nectar", "a sour cell kept its nectar")
        before = _cell(self.saves["before"], self.control)
        after = _cell(done, self.control)
        self.assertEqual(after["content"], "nectar")
        self.assertAlmostEqual(float(after["amount"]), float(before["amount"]), places=3)
        self.assertEqual(float(after["nectar_since"]), float(before["nectar_since"]))

    def test_no_empty_cell_gained_nectar(self):
        self.assertEqual(set(_nectar(self.saves["done"])), {self.control})

    def test_a_moved_fermented_cell_goes_outside(self):
        self.assertEqual(set(_nectar(self.saves["moved"])), {self.control},
                         "the moved nectar went into another cell or stayed put")
        before = float(_cell(self.saves["before"], self.control)["amount"])
        after = float(_cell(self.saves["moved"], self.control)["amount"])
        self.assertAlmostEqual(after, before, places=3, msg="the control cell took the moved nectar")

# RR-14. A sour cell given a new designation keeps its stock and is emptied by
# a comb worker, while a fresh nectar cell given the same designation is not
# marked. Its own fixture, written to a scratch folder, so the NF-5 run above
# and its saves are untouched.
DESIGNATE_FIXTURE = {
    "cells": 15, "nectar_foragers": 0, "pollen_foragers": 0,
    "nurses": 0, "builders": 2, "miners": 0, "honey_makers": 0,
    "weather": False, "disease": False, "rival_hive": False, "winter": False,
    "random_seed": 5205,
    "config_overrides": {"seconds_per_day": 20, "nectar_ferment_hours": 12},
    "actions": [
        {"do": "set_cell_contents", "cell": {"hex": [0, 0]}, "resource": "nectar", "amount": 60},
        {"do": "wait", "seconds": 15},
        {"do": "set_cell_contents", "cell": {"hex": [1, 0]}, "resource": "nectar", "amount": 60},
        {"do": "save_run", "name": "RR14 before"},
        {"do": "designate_cell", "hex": [0, 0], "content": "honey"},
        {"do": "designate_cell", "hex": [1, 0], "content": "honey"},
        {"do": "save_run", "name": "RR14 designated"},
        {"do": "wait", "seconds": 40},
        {"do": "save_run", "name": "RR14 done"},
    ],
    "stop": {"when_actions_resolved": True, "max_days": 10},
}
DESIGNATE_SAVES = ("before", "designated", "done")
SOUR_HEX = (0, 0)
FRESH_HEX = (1, 0)


class DesignateSourCellTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        cls._tmp = tempfile.TemporaryDirectory()
        fixture = Path(cls._tmp.name) / "rr14_designate_sour.json"
        fixture.write_text(json.dumps(DESIGNATE_FIXTURE), encoding="utf-8")
        session_file = run_once(fixture, godot_path, timeout=300, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        cls.rejected = [e for e in load_entries(session_file)
                        if e.get("type") == "action" and e.get("result") == "rejected"]
        scratch = scenario_saves_dir(session_file)
        cls.saves = {}
        for name in DESIGNATE_SAVES:
            path = scratch / ("rr14-%s.json" % name)
            if path.exists():
                cls.saves[name] = json.loads(path.read_text(encoding="utf-8"))

    @classmethod
    def tearDownClass(cls):
        cls._tmp.cleanup()

    def setUp(self):
        self.assertEqual(self.rejected, [], "a scenario action was rejected")
        missing = [n for n in DESIGNATE_SAVES if n not in self.saves]
        self.assertEqual(missing, [], "the run did not write every save")

    def test_sour_cell_takes_the_designation_and_keeps_its_stock(self):
        cell = _cell(self.saves["designated"], SOUR_HEX)
        self.assertEqual(cell.get("designated"), "honey")
        self.assertTrue(cell.get("evict"), "the sour cell was not marked for discard")
        self.assertEqual(cell.get("evict_mode"), "discard")
        self.assertEqual(cell.get("content"), "nectar", "the sour cell was emptied at once")
        self.assertGreater(float(cell.get("amount", 0.0)), 0.0)

    def test_fresh_cell_given_the_same_designation_is_not_marked(self):
        cell = _cell(self.saves["designated"], FRESH_HEX)
        self.assertEqual(cell.get("designated"), "honey")
        self.assertFalse(cell.get("evict", False), "the fresh nectar cell was marked")

    def test_comb_worker_empties_the_sour_cell(self):
        cell = _cell(self.saves["done"], SOUR_HEX)
        self.assertNotEqual(cell.get("content"), "nectar", "no comb worker emptied the sour cell")


class QueenDiscardsSourTest(unittest.TestCase):
    """RR-17: leftover foraging cargo must not block a queen's comb work."""

    def test_queen_on_comb_work_empties_sour_cell_within_40_seconds(self):
        godot_path = find_godot()
        if not godot_path:
            self.skipTest("no Godot executable found -- this test needs a real headless boot")
        fixture = ROOT / "test_scenarios" / "rr17_queen_discards_sour.json"
        session_file = run_once(fixture, godot_path, timeout=300, fixed_fps=30)
        self.assertIsNotNone(session_file, "scenario run produced no session log")
        entries = load_entries(session_file)
        rejected = [e for e in entries if e.get("type") == "action" and e.get("result") == "rejected"]
        self.assertEqual(rejected, [], "a scenario action was rejected")
        scratch = scenario_saves_dir(session_file)
        saves = {}
        for name in ("before", "marked", "done"):
            path = scratch / ("rr17-%s.json" % name)
            self.assertTrue(path.exists(), "the run did not write " + name)
            saves[name] = json.loads(path.read_text(encoding="utf-8"))
        source = (0, 0)
        for name in saves:
            bees = saves[name]["bees"]
            self.assertEqual(len(bees), 1, "another bee could have cleared the cell")
            self.assertTrue(bees[0]["queen"])
            self.assertEqual(bees[0]["role"], 2, "the queen was not on comb work")
            self.assertEqual(bees[0]["architect_mode"], "both")
        self.assertEqual(saves["before"]["bees"][0]["load_type"], "pollen")
        self.assertEqual(saves["before"]["bees"][0]["load"], 5)
        self.assertEqual(_cell(saves["before"], source)["content"], "nectar")
        marked = _cell(saves["marked"], source)
        self.assertTrue(marked.get("evict"), "the sour cell was not marked")
        self.assertEqual(marked.get("evict_mode"), "discard")
        self.assertNotEqual(_cell(saves["done"], source)["content"], "nectar",
                            "the lone queen did not empty the sour cell within 40 seconds")
        self.assertEqual(_nectar(saves["done"]), {}, "sour nectar was moved into another cell")
        pollen = sum(float(c.get("amount", 0)) for c in saves["done"]["cells"]
                     if c.get("content") == "pollen")
        self.assertAlmostEqual(pollen, 5, places=3, msg="the queen lost her leftover pollen")


if __name__ == "__main__":
    unittest.main()
