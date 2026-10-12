"""T2-9: a skill not offered in this run never blocks the tier above it.

Runs test_scenarios/t2_9_c2_comb_worker_test.json (Challenge 2). Cell
capacity, Colony's only tier-1 skill, is not unlocked by the stage, so it
cannot be bought; Comb worker (2.7) and Miner (2.8), Colony tier 2, must
still be bought. A source check confirms branch_tier_open uses the filter.
"""
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "t2_9_c2_comb_worker_test.json"


class UnavailableTierSourceTest(unittest.TestCase):
    def test_branch_tier_open_filters_by_offered_in_run(self):
        text = (ROOT / "scripts" / "progression.gd").read_text(encoding="utf-8")
        start = text.index("func branch_tier_open")
        body = text[start:text.index("\nfunc ", start + 1)]
        self.assertIn("_offered_in_run(", body)
        self.assertIn("func _offered_in_run(skill_id: String) -> bool:", text)
        self.assertIn("is_permitted(skill_id) and feature_valid(skill_id)", text)


class UnavailableTierRunTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(FIXTURE, godot_path, timeout=900, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        log = session_file.parent / "godot.log"
        text = log.read_text(encoding="utf-8", errors="replace") if log.exists() else ""
        cls.script_errors = [l for l in text.splitlines() if "SCRIPT ERROR" in l]
        cls.actions = [e for e in load_entries(session_file) if e.get("type") == "action"]

    def test_run_raises_no_script_error(self):
        self.assertEqual(self.script_errors, [], self.script_errors[:5])

    def test_every_action_accepted(self):
        rejected = [e for e in self.actions if e.get("result") == "rejected"]
        self.assertEqual(rejected, [], rejected)
        buys = [e for e in self.actions if e.get("do") == "buy_skill"]
        self.assertEqual(len(buys), 3, buys)
        asserts = [e for e in self.actions if e.get("do") == "assert"]
        self.assertEqual(len(asserts), 4, asserts)


if __name__ == "__main__":
    unittest.main()
