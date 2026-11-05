"""FR-4: an unmatched scout does not wait at the entrance; an established low-rate forager does.

Replaces the C-143 hands-on check. Runs test_scenarios/fr4_scout_entrance.json
once. Its "when"-gated asserts carry the claims (a failed assert is a rejected
action in the session log): scouts are never in AT_ENTRANCE_SEEKING while
walking to the door or after leaving it, and a forager given a trip history
(trips_scored 5, avg_collection_rate 0) is in AT_ENTRANCE_SEEKING.
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

FIXTURE = ROOT / "test_scenarios" / "fr4_scout_entrance.json"


class ScoutEntranceRunTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(FIXTURE, godot_path, timeout=900, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        cls.entries = load_entries(session_file)
        godot_log = session_file.parent / "godot.log"
        log_text = godot_log.read_text(encoding="utf-8", errors="replace") if godot_log.exists() else ""
        cls.script_errors = [line for line in log_text.splitlines() if "SCRIPT ERROR" in line]
        actions = [e for e in cls.entries if e.get("type") == "action"]
        cls.rejected = [e for e in actions if e.get("result") == "rejected"]
        cls.asserts = [e for e in actions if e.get("do") == "assert"]

    def _events(self, kind: str) -> int:
        return sum(1 for e in self.entries if e.get("type") == kind)

    def test_run_raises_no_script_error(self):
        self.assertEqual(self.script_errors, [], self.script_errors[:5])

    def _accepted(self, do: str) -> list:
        return [e for e in self.entries if e.get("type") == "action" and e.get("do") == do and e.get("result") == "accepted"]

    def test_every_action_and_assert_resolves(self):
        self.assertEqual(self.rejected, [], self.rejected)
        self.assertEqual(len(self._accepted("assert")), 3, self.asserts)

    def test_stats_were_set(self):
        self.assertEqual(len(self._accepted("set_bee_stats")), 1)


if __name__ == "__main__":
    unittest.main()
