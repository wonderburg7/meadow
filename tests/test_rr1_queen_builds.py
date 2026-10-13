"""RR-1: the queen can build a cell in every run.

Runs test_scenarios/rr1_queen_builds_test.json in a headless Godot: a colony
with no cells and no workers, so the queen is alone as in a Colony Run, outside
any Challenge. She must be offered Build cell, and after the Build cell tool
and a click on the hive floor she builds one cell within two game days. Also
checks the source: orders_zones.gd owns the general build. Requires a real
Godot for the scenario test.
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

FIXTURE = ROOT / "test_scenarios" / "rr1_queen_builds_test.json"


class QueenBuildsTest(unittest.TestCase):
    def test_lone_queen_is_offered_build_cell_and_builds_one(self):
        godot_path = find_godot()
        if not godot_path:
            self.skipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(FIXTURE, godot_path, timeout=240, fixed_fps=30)
        self.assertIsNotNone(session_file, "scenario run produced no session log")
        actions = [e for e in load_entries(session_file) if e.get("type") == "action"]
        bad = [e for e in actions if e.get("result") != "accepted"]
        self.assertEqual(bad, [], "actions not accepted: %s" % bad)
        done = [e for e in actions if e.get("do") == "assert" and "built_cells_at_least" in str(e.get("target"))]
        self.assertTrue(done, "the built-cell assertion never ran")

    def test_orders_zones_owns_the_general_build(self):
        source = (ROOT / "scripts" / "orders_zones.gd").read_text(encoding="utf-8")
        self.assertIn("func queen_build_at(", source)
        runner = (ROOT / "scripts" / "challenge_runner.gd").read_text(encoding="utf-8")
        self.assertIn("orders_zones.queen_build_at(", runner)


if __name__ == "__main__":
    unittest.main()
