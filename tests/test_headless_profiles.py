"""Focused contract tests for Slice 3 diagnostic capture profiles."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path


TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

from headless.profiles import PROFILE_VERSION, validate_diagnostics  # noqa: E402
from headless.verdicts import ContractError  # noqa: E402
from analyze_session import analyze  # noqa: E402


class HeadlessProfileTest(unittest.TestCase):
    def test_omitted_block_retains_standard_compatibility_selection(self):
        selection = validate_diagnostics(None)
        self.assertEqual("standard", selection["profile"])
        self.assertEqual(PROFILE_VERSION, selection["version"])
        self.assertIsNone(selection["snapshots"])

    def test_verdict_is_action_and_failure_capture_without_snapshots(self):
        selection = validate_diagnostics({"profile": "verdict"})
        self.assertEqual(["action", "death"], selection["events"])
        self.assertIsNone(selection["snapshots"])

    def test_custom_snapshot_is_exactly_allowlisted(self):
        selection = validate_diagnostics({
            "profile": "custom", "events": ["stall_recovery"],
            "snapshots": {"every_sim_seconds": 30, "only_when_changed": True,
                          "fields": ["population.total", "resources.food_stores", "role_outcomes.cells_completed_total"]},
            "limits": {"event_lines_per_type": 2, "snapshot_lines": 3},
        })
        self.assertEqual(["stall_recovery"], selection["events"])
        self.assertEqual(30.0, selection["snapshots"]["every_sim_seconds"])
        self.assertTrue(selection["snapshots"]["only_when_changed"])

    def test_forager_survival_events_remain_opt_in_and_bounded(self):
        selection = validate_diagnostics({
            "profile": "custom", "events": ["forager_return", "flight_start_resolved"],
            "limits": {"event_lines_per_type": 2},
        })
        self.assertEqual(["forager_return", "flight_start_resolved"], selection["events"])
        self.assertEqual(2, selection["limits"]["event_lines_per_type"])

    def test_day_interval_is_retained_only_for_its_supported_profiles(self):
        selection = validate_diagnostics({"profile": "balance"})
        self.assertEqual("day", selection["snapshots"]["every_sim_seconds"])
        with self.assertRaisesRegex(ContractError, "positive number"):
            validate_diagnostics({"profile": "custom", "snapshots": {
                "every_sim_seconds": "day", "fields": ["population.total"],
            }})

    def test_unknown_or_expensive_requests_fail_before_godot_launch(self):
        with self.assertRaisesRegex(ContractError, "unknown diagnostic profile"):
            validate_diagnostics({"profile": "everything"})
        with self.assertRaisesRegex(ContractError, "unknown diagnostics.snapshots.fields"):
            validate_diagnostics({"profile": "custom", "snapshots": {
                "every_sim_seconds": 1, "fields": ["world.run_arbitrary_code"],
            }})
        with self.assertRaisesRegex(ContractError, "positive integer"):
            validate_diagnostics({"profile": "custom", "limits": {"snapshot_lines": 0}})

    def test_legacy_analysis_accepts_a_partial_selected_snapshot(self):
        analysis = analyze([
            {"type": "config", "settings": {}},
            {"type": "snapshot", "day": 1, "game_time": 10,
             "population": {"total": 4}, "resources": {"food_stores": 12}},
            {"type": "summary", "outcome": "actions_resolved", "total_deaths": 0,
             "gynes_released": 0, "deaths_by_cause": {}, "deaths_by_role": {}},
        ])
        self.assertEqual([{"day": 1, "total": 4, "by_role": {}}], analysis["population_curve"])
        self.assertEqual([], analysis["honey_fill_vs_winter"])


if __name__ == "__main__":
    unittest.main()
