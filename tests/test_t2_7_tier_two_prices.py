"""T2-7: the first tier-2 metric. The price rule itself is progression.gd's;
this proves the analyser and pacing row that read its snapshot boolean, and
that the arc scenario and both field whitelists carry the field."""

from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import analyze  # noqa: E402
import pacing_gates  # noqa: E402
from headless.profiles import SNAPSHOT_FIELDS  # noqa: E402

FIELD = "resources.first_tier2_affordable"
SETTINGS = {"seconds_per_day": 200.0, "season_length_days": 30, "winter_length_days": 10}


def snapshot(day, affordable):
    return {"type": "snapshot", "day": day, "game_time": day * 200.0,
            "population": {"total": 3}, "environment": {"winter_here": False},
            "resources": {"food_stores": 0, "first_tier2_affordable": affordable}}


def analysed(flags):
    entries = [{"type": "config", "game_time": 0.0, "settings": SETTINGS}]
    entries += [snapshot(day, flag) for day, flag in flags]
    return analyze(entries)


class FirstTierTwoDay(unittest.TestCase):
    def test_first_true_snapshot_sets_the_day(self):
        result = analysed([(1, False), (4, True), (6, True)])
        self.assertEqual(4, result["milestones"]["first_tier2_day"])
        self.assertEqual(4.0, result["milestone_times"]["first_tier2_day"])

    def test_never_true_sets_nothing(self):
        result = analysed([(1, False), (4, False)])
        self.assertNotIn("first_tier2_day", result["milestones"])
        self.assertNotIn("first_tier2_day", result["milestone_times"])

    def test_pacing_row_against_day_five_leaves_the_gates_alone(self):
        gates_before = [g.label for g in pacing_gates.GATES]
        hit = pacing_gates.tier2_row([analysed([(5, True)])] * 3)
        self.assertEqual("in band", hit["status"])
        self.assertEqual(5.0, hit["target_day"])
        miss = pacing_gates.tier2_row([analysed([(5, False)])] * 3)
        self.assertEqual("unavailable", miss["status"])
        self.assertEqual(5, len(pacing_gates.GATES))
        self.assertEqual(gates_before, [g.label for g in pacing_gates.GATES])
        self.assertIn("first tier-2", pacing_gates.render_tier2_row(hit))


class FieldIsLogged(unittest.TestCase):
    def test_arc_and_whitelists_carry_the_field(self):
        scenario = json.loads((ROOT / "test_scenarios" / "alpha_arc_test.json").read_text(encoding="utf-8"))
        self.assertIn(FIELD, scenario["diagnostics"]["snapshots"]["fields"])
        self.assertIn(FIELD, SNAPSHOT_FIELDS)
        probes = (ROOT / "scripts" / "headless" / "diagnostic_probes.gd").read_text(encoding="utf-8")
        self.assertRegex(probes, r'SNAPSHOT_FIELDS := \[[^\]]*"%s"' % re.escape(FIELD))

    def test_resolver_rule_reuses_the_afford_rule(self):
        source = (ROOT / "scripts" / "progression.gd").read_text(encoding="utf-8")
        self.assertIn("func first_tier2_path_covered", source)
        self.assertGreaterEqual(source.count("_covers("), 3, "can_afford and the path rule share _covers")


if __name__ == "__main__":
    unittest.main()
