"""FR-2: Auto scouting is a Foraging tier-2 purchase that replaces Orientation flight.

Runs test_scenarios/fr2_auto_scouting_test.json once: the colony owns
Orientation flight (granted), buys Auto scouting, and must see scouts settle
(`scouting_settled`) while no `orientation_flight` event ever fires. The
scenario's own "when"-gated asserts carry both claims; a failed assert is a
rejected action in the session log.
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

FIXTURE = ROOT / "test_scenarios" / "fr2_auto_scouting_test.json"


class AutoScoutingRunTest(unittest.TestCase):
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

    def test_every_action_and_assert_resolves(self):
        self.assertEqual(self.rejected, [], self.rejected)
        self.assertGreaterEqual(len(self.asserts), 2, self.asserts)

    def test_scouts_settle(self):
        self.assertGreaterEqual(self._events("scouting_settled"), 3)

    def test_no_orientation_flight_runs(self):
        self.assertEqual(self._events("orientation_flight"), 0)


if __name__ == "__main__":
    unittest.main()
