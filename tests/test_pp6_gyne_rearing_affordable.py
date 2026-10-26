"""PP-6: the day Gyne rearing's whole path first becomes affordable. The price
rule is progression.gd's; this proves the analyser, the pacing row against the
11 days after winter, and that the field is logged and whitelisted."""

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

FIELD = "resources.gyne_rearing_affordable"
SETTINGS = {"seconds_per_day": 200.0, "season_length_days": 30, "winter_length_days": 10}


def snapshot(day, affordable):
    return {"type": "snapshot", "day": day, "game_time": day * 200.0,
            "population": {"total": 3}, "environment": {"winter_here": False},
            "resources": {"food_stores": 0, "gyne_rearing_affordable": affordable}}


def analysed(flags):
    entries = [{"type": "config", "game_time": 0.0, "settings": SETTINGS}]
    entries += [snapshot(day, flag) for day, flag in flags]
    result = analyze(entries)
    result["settings"] = SETTINGS
    return result


class GyneRearingDay(unittest.TestCase):
    def test_first_true_snapshot_sets_the_day(self):
        result = analysed([(1, False), (45, True), (50, True)])
        self.assertEqual(45.0, result["milestone_times"]["gyne_rearing_affordable_day"])

    def test_never_true_sets_nothing(self):
        result = analysed([(1, False), (45, False)])
        self.assertNotIn("gyne_rearing_affordable_day", result["milestone_times"])

    def test_band_is_days_42_to_52(self):
        for day, status in ((41, "out of band"), (42, "in band"), (52, "in band"), (53, "out of band")):
            row = pacing_gates.gyne_rearing_affordable([analysed([(day, True)])] * 3)
            self.assertEqual(status, row["status"], day)
        row = pacing_gates.gyne_rearing_affordable([analysed([(45, False)])] * 3)
        self.assertEqual("unavailable", row["status"])
        self.assertEqual((42.0, 52.0), row["band"])
        self.assertIn("Gyne rearing affordable", pacing_gates.render_gyne_rearing_row(row))

    def test_gates_are_unchanged(self):
        self.assertEqual(5, len(pacing_gates.GATES))


class FieldIsLogged(unittest.TestCase):
    def test_arc_and_whitelists_carry_the_field(self):
        scenario = json.loads((ROOT / "test_scenarios" / "alpha_arc_test.json").read_text(encoding="utf-8"))
        self.assertIn(FIELD, scenario["diagnostics"]["snapshots"]["fields"])
        self.assertIn(FIELD, SNAPSHOT_FIELDS)
        probes = (ROOT / "scripts" / "headless" / "diagnostic_probes.gd").read_text(encoding="utf-8")
        self.assertRegex(probes, r'SNAPSHOT_FIELDS := \[[^\]]*"%s"' % re.escape(FIELD))

    def test_rule_sums_the_path_with_the_shared_cover(self):
        source = (ROOT / "scripts" / "progression.gd").read_text(encoding="utf-8")
        self.assertIn("func gyne_rearing_path_covered", source)
        self.assertIn("_path_cost(path)", source)


if __name__ == "__main__":
    unittest.main()
