"""Pure-Python coverage for the closed-alpha pacing report."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path


TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

from pacing_gates import build_rows, in_band, render_table, target_day  # noqa: E402


class PacingGatesTest(unittest.TestCase):
    def test_target_minutes_convert_using_the_run_day_length(self):
        self.assertEqual(1.5, target_day(5, 200))
        self.assertEqual(18.0, target_day(60, 200))

    def test_band_is_inclusive_and_rejects_missing_milestones(self):
        self.assertTrue(in_band(7.5, 6.0))
        self.assertTrue(in_band(4.5, 6.0))
        self.assertFalse(in_band(4.49, 6.0))
        self.assertFalse(in_band(None, 6.0))

    def test_rows_use_the_median_and_mark_an_incomplete_gate_outside_band(self):
        analyses = [
            {"milestones": {"first_worker_day": 1, "food_secure_day": 3,
                            "winter_entered_day": 17, "winter_survived_day": 28}},
            {"milestones": {"first_worker_day": 2, "food_secure_day": 3,
                            "winter_entered_day": 18, "winter_survived_day": 27}},
            {"milestones": {"first_worker_day": 2, "food_secure_day": 4,
                            "winter_entered_day": 19}},
        ]
        rows = build_rows(analyses, 200)
        self.assertEqual(2, rows[0]["median_day"])
        self.assertEqual(3, rows[1]["median_day"])
        self.assertEqual(18, rows[2]["median_day"])
        self.assertIsNone(rows[3]["median_day"])
        self.assertFalse(rows[3]["inside_band"])

    def test_table_is_compact_and_names_missing_evidence(self):
        rows = build_rows([{"milestones": {gate: 2 for gate in (
            "first_worker_day", "food_secure_day", "winter_entered_day", "winter_survived_day",
        )}}], 200)
        table = render_table(rows, 200, 1)
        self.assertLess(len(table.splitlines()), 40)
        self.assertIn("milestone        median day  target day  in band", table)
        self.assertIn("Not instrumented: 20m forage/weather crisis; 90m gyne release.", table)


if __name__ == "__main__":
    unittest.main()
