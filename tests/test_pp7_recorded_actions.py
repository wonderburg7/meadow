"""PP-7: "recorded" action entries are log lines, not problems.

pollination.gd logs its ledger lines through DiagnosticLog.log_action with the
result "recorded". Those must count in by_result but never reach `problems`,
or every scenario with "pollination_log": true reports failed. "rejected" and
"unresolved" still surface as problems.

Also pins the scenario that measures the pollination log without a purchase.
"""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import analyze_session  # noqa: E402


def action(result, do="buy_skill", target="skill.x", reason=""):
    return {"type": "action", "do": do, "target": target, "result": result, "reason": reason}


class RecordedActionsTest(unittest.TestCase):
    def test_recorded_counts_but_is_not_a_problem(self):
        summary = analyze_session._action_summary(
            [action("recorded", do="pollination_visit"), action("recorded", do="pollination_spent")]
        )
        self.assertEqual(summary["by_result"], {"recorded": 2})
        self.assertEqual(summary["problems"], [])

    def test_rejected_and_unresolved_are_still_problems(self):
        summary = analyze_session._action_summary(
            [action("recorded", do="pollination_visit"),
             action("rejected", reason="not enough points"),
             action("unresolved", reason="when never fired")]
        )
        self.assertEqual(summary["by_result"], {"recorded": 1, "rejected": 1, "unresolved": 1})
        self.assertEqual(sorted(p["result"] for p in summary["problems"]), ["rejected", "unresolved"])

    def test_analyze_passes_a_pollination_log_run(self):
        entries = [
            {"type": "config", "settings": {}},
            {"type": "action", "do": "pollination_visit", "target": "flower", "result": "recorded", "reason": ""},
            {"type": "action", "do": "grant_skill", "target": "skill.a", "result": "accepted", "reason": ""},
        ]
        self.assertEqual(analyze_session.analyze(entries)["actions"]["problems"], [])

    def test_watch_scenario_has_no_purchase_and_stops_on_days(self):
        path = ROOT / "test_scenarios" / "pp2_points_watch.json"
        scenario = json.loads(path.read_text(encoding="utf-8"))
        dos = [a["do"] for a in scenario["actions"]]
        self.assertNotIn("buy_skill", dos)
        self.assertNotIn("save_run", dos)
        self.assertNotIn("assert", dos)
        self.assertTrue(scenario["pollination_log"])
        self.assertEqual(scenario["stop"], {"max_days": 6})


if __name__ == "__main__":
    unittest.main()
