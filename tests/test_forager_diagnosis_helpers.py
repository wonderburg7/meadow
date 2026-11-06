"""Unit tests for pure helpers, contracts and boundary cases in tools/forager_diagnosis.py."""

from __future__ import annotations

import unittest

from tools import forager_diagnosis as diagnosis


def _sample_measurement(food: float = 1.0, seed: int = 7, matches: int = 0) -> dict:
    return {
        "seed": seed,
        "food": food,
        "deliveries": 10,
        "matches": matches,
        "settled": 1,
        "settlement_day": 2.5,
        "peak_foragers": 12,
        "seeking_sample_mean": 1.25,
        "mentoring_sample_mean": 0.5,
        "delivery_events_per_sim_minute": 3.0,
        "folder": "/mock/folder",
    }


class TestForagerDiagnosisHelpers(unittest.TestCase):
    def test_cases_structure_and_overrides(self) -> None:
        """CASES constant has expected length and specific toggle combinations."""
        self.assertEqual(len(diagnosis.CASES), 8)
        self.assertEqual(diagnosis.CASES[4][0], "Recruitment, 1-second wait")
        self.assertEqual(diagnosis.CASES[4][1]["recruit_wait_seconds"], 1.0)
        self.assertEqual(diagnosis.CASES[5][0], "No mentors, 15-second wait")
        self.assertEqual(diagnosis.CASES[5][1]["recruit_upper_threshold_nectar"], 1e9)
        self.assertEqual(diagnosis.CASES[5][1]["recruit_upper_threshold_pollen"], 1e9)
        self.assertEqual(diagnosis.CASES[6][0], "No mentors, 1-second wait")
        self.assertEqual(diagnosis.CASES[6][1]["recruit_wait_seconds"], 1.0)
        self.assertEqual(diagnosis.CASES[7][0], "Scouting with species restrictions, no recruitment")
        self.assertFalse(diagnosis.CASES[7][1]["auto_recruitment_on"])

    def test_scenario_generation(self) -> None:
        """scenario returns a valid configuration with defaults and case overrides."""
        scen = diagnosis.scenario(0, 123)
        self.assertIn("config_overrides", scen)
        self.assertEqual(scen["random_seed"], 123)
        for key in diagnosis.tuning.DEFAULTS:
            self.assertIn(key, scen["config_overrides"])

    def test_paired_changes_zero_baseline(self) -> None:
        """paired_changes returns None when baseline food is 0.0."""
        before = [_sample_measurement(food=0.0, seed=s) for s in diagnosis.stages.SEEDS]
        after = [_sample_measurement(food=5.0, seed=s) for s in diagnosis.stages.SEEDS]
        changes = diagnosis.paired_changes(before, after)
        self.assertEqual(changes, [None] * len(diagnosis.stages.SEEDS))

    def test_paired_changes_seed_mismatch_raises(self) -> None:
        """paired_changes raises ValueError if seed lists do not match diagnosis.stages.SEEDS."""
        before = [_sample_measurement(food=1.0, seed=s) for s in diagnosis.stages.SEEDS]
        wrong_seeds = list(diagnosis.stages.SEEDS)
        wrong_seeds[0] += 999
        after = [_sample_measurement(food=2.0, seed=s) for s in wrong_seeds]
        with self.assertRaisesRegex(ValueError, "Every comparison needs the same five ordered seeds"):
            diagnosis.paired_changes(before, after)

    def test_render_output_format(self) -> None:
        """render produces a markdown document containing table headers and sections."""
        values = [
            [_sample_measurement(food=1.0, seed=s, matches=0) for s in diagnosis.stages.SEEDS]
            for _ in diagnosis.CASES
        ]
        out = diagnosis.render(values, "test-fingerprint-123")
        self.assertIn("### FR-1c controlled diagnosis", out)
        self.assertIn("Simulation fingerprint: `test-fingerprint-123`.", out)
        self.assertIn("| Case | Median food | Food per seed | Matches per seed | Settled per seed |", out)
        self.assertIn("Paired food changes (each seed compared with itself):", out)
        self.assertIn("Queue/population samples", out)

    def test_render_with_all_zero_baselines(self) -> None:
        """render handles all zero-baselines gracefully with 'undefined (zero baseline)'."""
        values = [
            [_sample_measurement(food=0.0, seed=s, matches=0) for s in diagnosis.stages.SEEDS]
            for _ in diagnosis.CASES
        ]
        out = diagnosis.render(values, "zero-fingerprint")
        self.assertIn("undefined (zero baseline)", out)


if __name__ == "__main__":
    unittest.main()
