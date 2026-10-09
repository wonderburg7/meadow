"""NF-2: nectar left past GameConfig.nectar_ferment_hours ferments.

Runs test_scenarios/nf2_fermentation.json once. The fixture has no honey
makers and a 12-hour threshold (10 seconds at its 20-second days). It stocks
one cell with nectar, lets it ferment and saves; tops it up and turns two
miners into honey makers, waits and saves; stocks a second, fresh cell as a
control, waits and saves; then restores the first save and saves again.

The saves are read back from the scenario scratch root (save_slots.gd's
SCRATCH_ROOT) and show, from the run itself, that the cell ferments, that the
honey makers leave it alone while they do turn fresh nectar into honey, that
the top-up keeps the old stamp, and that the stamp survives save and restore.
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
from run_scenario import log_dir, run_once  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "nf2_fermentation.json"
SAVES = ("fermented", "skipped", "control", "restored")


def _cell(save: dict, q: int, r: int) -> dict:
    return next(c for c in save["cells"] if int(c["q"]) == q and int(c["r"]) == r)


def _honey(save: dict) -> float:
    return sum(float(c.get("amount", 0.0)) for c in save["cells"] if c.get("content") == "honey")


class FermentationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        scenario = json.loads(FIXTURE.read_text(encoding="utf-8"))
        cls.hour = float(scenario["config_overrides"]["seconds_per_day"]) / 24.0
        cls.threshold = float(scenario["config_overrides"]["nectar_ferment_hours"]) * cls.hour
        session_file = run_once(FIXTURE, godot_path, timeout=300, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        cls.rejected = [e for e in load_entries(session_file)
                        if e.get("type") == "action" and e.get("result") == "rejected"]
        scratch = log_dir().parent / "scenario_saves"
        cls.saves = {}
        for name in SAVES:
            path = scratch / ("nf2-%s.json" % name)
            if path.exists():
                cls.saves[name] = json.loads(path.read_text(encoding="utf-8"))

    def setUp(self):
        self.assertEqual(self.rejected, [], "a scenario action was rejected")
        missing = [n for n in SAVES if n not in self.saves]
        self.assertEqual(missing, [], "the run did not write every save")
        # The stocked cell: the first built cell, found by its nectar in the
        # first save (the only nectar cell then, since no forager brings any).
        nectar = [c for c in self.saves["fermented"]["cells"] if c.get("content") == "nectar"]
        self.assertEqual(len(nectar), 1, "expected exactly one nectar cell in the first save")
        self.q, self.r = int(nectar[0]["q"]), int(nectar[0]["r"])

    def _age(self, name: str) -> float:
        save = self.saves[name]
        return float(save["clock"]["sim_time"]) - float(_cell(save, self.q, self.r)["nectar_since"])

    def test_a_nectar_cell_ferments(self):
        cell = _cell(self.saves["fermented"], self.q, self.r)
        self.assertGreaterEqual(float(cell["nectar_since"]), 0.0, "the nectar was never stamped")
        self.assertGreater(self._age("fermented"), self.threshold)

    def test_honey_makers_skip_it_but_use_fresh_nectar(self):
        skipped = self.saves["skipped"]
        cell = _cell(skipped, self.q, self.r)
        self.assertEqual(cell["content"], "nectar")
        self.assertEqual(_honey(skipped), 0.0, "honey makers made honey from fermented nectar")
        # The control: fresh nectar in a second cell is turned into honey by
        # the same bees, so they were working and chose to skip the first.
        self.assertGreater(_honey(self.saves["control"]), 0.0, "honey makers made no honey from fresh nectar")

    def test_a_top_up_leaves_it_fermented(self):
        before = _cell(self.saves["fermented"], self.q, self.r)
        after = _cell(self.saves["skipped"], self.q, self.r)
        self.assertEqual(float(after["nectar_since"]), float(before["nectar_since"]))
        self.assertGreater(self._age("skipped"), self.threshold)

    def test_its_stamp_survives_save_and_restore(self):
        saved = _cell(self.saves["fermented"], self.q, self.r)
        restored = _cell(self.saves["restored"], self.q, self.r)
        self.assertEqual(restored["content"], "nectar")
        self.assertAlmostEqual(float(restored["nectar_since"]), float(saved["nectar_since"]), places=3)
        self.assertGreater(self._age("restored"), self.threshold)


if __name__ == "__main__":
    unittest.main()
