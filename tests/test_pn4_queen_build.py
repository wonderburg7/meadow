"""PN-4: the queen finishes a cell she was told to build.

Two headless scenarios, each with the queen on Forager:
- pn4_queen_build_after_meal.json: she is ordered to build, gets hungry
  mid-build (hunger_threshold raised to 0.9), eats, and must still finish the
  cell. Before PN-4 the meal overwrote target_cell and she went back to
  foraging.
- pn4_queen_build_from_meadow.json: she is ordered to build while out in the
  meadow, and must walk in and build it inside the hive. Before PN-4 she flew
  to a meadow point matching the site's hive coordinates and "built" it there.

Also checks the source: orders_zones.gd holds the order across the meal.
Requires a real Godot for the scenario tests.
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once  # noqa: E402

SCENARIOS = ROOT / "test_scenarios"


class QueenFinishesOrderedBuildTest(unittest.TestCase):
    def _run(self, name: str) -> list:
        godot_path = find_godot()
        if not godot_path:
            self.skipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(SCENARIOS / name, godot_path, timeout=300, fixed_fps=30)
        self.assertIsNotNone(session_file, "scenario run produced no session log")
        actions = [e for e in load_entries(session_file) if e.get("type") == "action"]
        bad = [e for e in actions if e.get("result") != "accepted"]
        self.assertEqual(bad, [], "actions not accepted: %s" % bad)
        return actions

    def _assert_built(self, actions: list) -> None:
        done = [e for e in actions if e.get("do") == "assert" and "built_cells_at_least" in str(e.get("target"))]
        self.assertTrue(done, "the built-cell assertion never ran")

    def test_forager_queen_finishes_the_cell_after_eating(self):
        actions = self._run("pn4_queen_build_after_meal.json")
        fed = [e for e in actions if e.get("do") == "assert" and "FEEDING" in str(e.get("target"))]
        self.assertTrue(fed, "the queen never ate mid-build, so the meal was not tested")
        self._assert_built(actions)

    def test_queen_ordered_from_the_meadow_walks_in_and_builds(self):
        actions = self._run("pn4_queen_build_from_meadow.json")
        self._assert_built(actions)

    def test_orders_zones_holds_the_order_over_a_meal(self):
        source = (ROOT / "scripts" / "orders_zones.gd").read_text(encoding="utf-8")
        self.assertIn("var ordered_site", source)
        self.assertIn("func resume_ordered_build(", source)
        survival = (ROOT / "scripts" / "bee_survival.gd").read_text(encoding="utf-8")
        self.assertIn(".resume_ordered_build(bee)", survival)


if __name__ == "__main__":
    unittest.main()
