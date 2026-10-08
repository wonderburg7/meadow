"""T2-1: Comb worker and Miner are bought roles; the queen builds without the skill.

Runs test_scenarios/t2_1_queen_builds.json (the Colony Run's start plus one
seeded forager) in a headless Godot: the queen draws a cell as a Comb worker
with no skill owned, while the worker is refused both Comb worker and Miner.
Also checks the data: roles.gd names the two skills and Challenge 2's stages
2.7 and 2.8 free them. Requires a real Godot for the scenario test.
"""

from __future__ import annotations

import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "t2_1_queen_builds.json"
COMB = "skill.colony.comb_worker"
MINER = "skill.colony.miner"


def _stage_block(text: str, stage_id: str) -> str:
    start = text.index('"id": "%s"' % stage_id)
    end = text.index("\n\t},", start)
    return text[start:end]


class CombMinerGateTest(unittest.TestCase):
    def test_roles_name_their_skills(self):
        text = (ROOT / "scripts" / "roles.gd").read_text(encoding="utf-8")
        for key, skill in (("comb_worker", COMB), ("miner", MINER)):
            self.assertRegex(text, r'"key": "%s",[^\n]*\n\s*"skill": "%s",' % (key, re.escape(skill)))

    def test_challenge_two_frees_them_at_2_7_and_2_8(self):
        text = (ROOT / "scripts" / "challenge_stages.gd").read_text(encoding="utf-8")
        self.assertIn('const COMB_SKILL := "%s"' % COMB, text)
        self.assertIn('const MINER_SKILL := "%s"' % MINER, text)
        s27 = _stage_block(text, "2.7")
        s28 = _stage_block(text, "2.8")
        self.assertIn("COMB_SKILL", s27.split('"unlocked_keys"')[0])
        self.assertNotIn("MINER_SKILL", s27)
        self.assertNotIn("COMB_SKILL", s28.split('"unlocked_keys"')[0])
        self.assertIn("COMB_SKILL", s28.split('"unlocked_keys"')[1])
        self.assertIn("MINER_SKILL", s28.split('"unlocked_keys"')[0])
        self.assertIn("MINER_SKILL", s28.split('"unlocked_keys"')[1])
        s26 = _stage_block(text, "2.6")
        self.assertNotIn("COMB_SKILL", s26)

    def test_queen_builds_unbought_and_no_worker_does(self):
        godot_path = find_godot()
        if not godot_path:
            self.skipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(FIXTURE, godot_path, timeout=180, fixed_fps=30)
        self.assertIsNotNone(session_file, "scenario run produced no session log")
        actions = [e for e in load_entries(session_file) if e.get("type") == "action"]
        bad = [e for e in actions if e.get("result") != "accepted"]
        self.assertEqual(bad, [], "actions not accepted: %s" % bad)
        done = [e["do"] for e in actions]
        self.assertEqual(done.count("assign_role"), 3)
        self.assertEqual(done.count("queue_build"), 1)
        self.assertEqual(done.count("assert"), 4)


if __name__ == "__main__":
    unittest.main()
