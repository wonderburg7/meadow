"""Pure-Python coverage for the closed-alpha pacing report."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path


TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

from pacing_gates import (  # noqa: E402
    DEFAULT_SEEDS, FIRST_AUTOMATION_DAYS, FIRST_WORKER_BY_DAY, build_rows, colony_lived,
    in_band, in_days, render_seed_rows, render_table, seed_rows, target_day, winter_schedule,
)


SCHEDULE_SETTINGS = {"season_length_days": 30.0, "winter_length_days": 10.0}


class PacingGatesTest(unittest.TestCase):
    def test_target_minutes_convert_using_the_run_day_length(self):
        self.assertEqual(1.5, target_day(5, 200))
        self.assertEqual(18.0, target_day(60, 200))

    def test_band_is_inclusive_and_rejects_missing_milestones(self):
        self.assertTrue(in_band(7.5, 6.0))
        self.assertTrue(in_band(4.5, 6.0))
        self.assertFalse(in_band(4.49, 6.0))
        self.assertFalse(in_band(None, 6.0))

    def test_rows_show_five_product_gates_and_mark_missing_facts_unavailable(self):
        analyses = [
            {"settings": SCHEDULE_SETTINGS, "milestone_times": {"first_worker_day": 1.5, "winter_survived_day": 41},
             "alpha_route": {"first_automation_day": 3, "first_gyne_day": 26, "victory_day": 27}},
            {"settings": SCHEDULE_SETTINGS, "milestone_times": {"first_worker_day": 1.5, "winter_survived_day": 41},
             "alpha_route": {"first_automation_day": 3, "first_gyne_day": 26, "victory_day": 27}},
            {"settings": SCHEDULE_SETTINGS, "milestone_times": {"first_worker_day": 1.5, "winter_survived_day": 41},
             "alpha_route": {"first_automation_day": 3, "first_gyne_day": 26, "victory_day": 27}},
        ]
        rows = build_rows(analyses, 200)
        self.assertEqual(["first worker", "first automation", "crisis response", "winter survival", "gyne/victory"],
                         [row["milestone"] for row in rows])
        self.assertEqual(1.5, rows[0]["median_day"])
        self.assertTrue(rows[0]["inside_band"])
        self.assertEqual(3, rows[1]["median_day"])
        self.assertEqual("unavailable", rows[2]["status"])
        self.assertEqual("hands-on question", rows[2]["boundary"])
        self.assertTrue(rows[3]["inside_band"])
        self.assertTrue(rows[4]["inside_band"])

        analyses[-1]["alpha_route"].pop("first_gyne_day")
        gyne = build_rows(analyses, 200)[4]
        self.assertIsNone(gyne["median_day"])
        self.assertEqual("unavailable", gyne["status"])
        self.assertFalse(gyne["inside_band"])

    def test_table_is_compact_and_names_missing_evidence(self):
        rows = build_rows([{"settings": SCHEDULE_SETTINGS,
                            "milestone_times": {"first_worker_day": 2, "winter_survived_day": 41},
                            "alpha_route": {"first_automation_day": 2, "first_gyne_day": 2, "victory_day": 2}}], 200)
        table = render_table(rows, 200, 1)
        self.assertLess(len(table.splitlines()), 40)
        self.assertIn("evidence boundary", table)
        self.assertIn("Not instrumented: 20m forage/weather crisis; 90m gyne release.", table)
        self.assertIn("crisis response", table)
        self.assertIn("hands-on question", table)
        self.assertIn("2.00", table)

    def test_first_worker_at_two_elapsed_days_is_within_the_calendar_target(self):
        rows = build_rows([{"settings": SCHEDULE_SETTINGS, "milestone_times": {"first_worker_day": 2.0}}], 200)
        self.assertTrue(rows[0]["inside_band"])

    def test_first_worker_after_day_seventeen_is_outside_the_calendar_target(self):
        rows = build_rows([{"settings": SCHEDULE_SETTINGS, "milestone_times": {"first_worker_day": 17.5}}], 200)
        self.assertEqual(17.0, FIRST_WORKER_BY_DAY)
        self.assertFalse(rows[0]["inside_band"])

    def test_first_automation_uses_the_inclusive_calendar_window(self):
        self.assertEqual((5.0, 8.0), FIRST_AUTOMATION_DAYS)
        for day in (5.0, 8.0):
            with self.subTest(day=day):
                rows = build_rows([{"settings": SCHEDULE_SETTINGS, "milestone_times": {},
                                    "alpha_route": {"first_automation_day": day}}], 200)
                self.assertTrue(rows[1]["inside_band"])
        for day in (4.9, 8.1):
            with self.subTest(day=day):
                rows = build_rows([{"settings": SCHEDULE_SETTINGS, "milestone_times": {},
                                    "alpha_route": {"first_automation_day": day}}], 200)
                self.assertFalse(rows[1]["inside_band"])


    def test_winter_rows_are_judged_against_the_col4_schedule(self):
        self.assertTrue(in_days(30.02, 31))
        self.assertFalse(in_days(35.0, 31))
        analyses = [{"settings": SCHEDULE_SETTINGS, "milestone_times": {"winter_entered_day": 30.02, "winter_survived_day": 40.05}}]
        rows = build_rows(analyses, 200)
        self.assertEqual(41.0, rows[3]["target_day"])
        self.assertTrue(rows[3]["inside_band"])

    def test_each_repeat_has_its_own_seed(self):
        self.assertEqual(len(DEFAULT_SEEDS), len(set(DEFAULT_SEEDS)))
        self.assertGreaterEqual(len(DEFAULT_SEEDS), 3)

    def test_winter_schedule_comes_from_logged_lengths(self):
        self.assertEqual((31.0, 41.0), winter_schedule([{"settings": SCHEDULE_SETTINGS}]))
        with self.assertRaises(ValueError):
            winter_schedule([{"settings": {"season_length_days": 30.0}}])

    def test_colony_lived_needs_a_queen_workers_and_a_finished_winter(self):
        entries = [{"type": "snapshot", "population": {"total": 5}}]
        survived = {"milestone_times": {"winter_survived_day": 40}, "summary": {"queen_alive": True}}
        self.assertTrue(colony_lived(entries, survived)["lived"])
        self.assertFalse(colony_lived(entries, {**survived, "summary": {"queen_alive": False}})["lived"])
        self.assertFalse(colony_lived([{"type": "snapshot", "population": {"total": 1}}], survived)["lived"])
        self.assertFalse(colony_lived(entries, {"milestone_times": {}, "summary": {"queen_alive": True}})["lived"])

    def test_seed_block_names_every_seed_and_its_verdict(self):
        analyses = [
            {"seed": 7, "milestone_times": {"first_worker_day": 3}, "colony": {"lived": True, "population": 4}},
            {"seed": 8, "milestone_times": {}, "colony": {"lived": False, "population": 1}},
        ]
        text = render_seed_rows(seed_rows(analyses), 31, 41)
        self.assertIn("lived (4 bees)", text)
        self.assertIn("died", text)
        self.assertIn("missing", text)


if __name__ == "__main__":
    unittest.main()
