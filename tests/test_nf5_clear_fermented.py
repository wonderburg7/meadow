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


if __name__ == "__main__":
    unittest.main()
