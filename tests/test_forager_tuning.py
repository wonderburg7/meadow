"""Keep FR-1b's tuning evidence paired, strict and safe to resume."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from io import StringIO
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from tools import forager_tuning as tuning


class ForagerTuningTests(unittest.TestCase):
    def test_unrounded_threshold_and_every_stage_must_improve(self) -> None:
        def rows(*values):
            return [[value] * 5 for value in values]

        self.assertTrue(tuning.accepted(rows(1.0, 2.0, 2.6, 2.7)))
        self.assertFalse(tuning.accepted(rows(1.0, 2.0, 2.5999, 2.7)))
        self.assertFalse(tuning.accepted(rows(2.0, 2.0, 2.6, 2.7)))
        self.assertFalse(tuning.accepted(rows(1.0, 2.0, 2.6, 2.6)))
        self.assertFalse(tuning.accepted(rows(0.0, 2.0, 2.6, 2.7)))
        # A single lucky seed must not satisfy a median-based target.
        self.assertFalse(tuning.accepted([[1] * 5, [2] * 5, [2, 2, 2, 10, 10], [11] * 5]))

    def test_candidates_only_tune_existing_values_and_keep_the_colony_fixed(self) -> None:
        candidates = (tuning.band_candidates(tuning.DEFAULTS)
                      + tuning.refinement_candidates(tuning.DEFAULTS))
        original = json.loads(tuning.stages.SCENARIO.read_text(encoding="utf-8"))
        for candidate in candidates:
            self.assertEqual(set(candidate), set(tuning.DEFAULTS))
            self.assertGreaterEqual(candidate["recruit_wait_seconds"], 1)
            for stage, (_, toggles) in enumerate(tuning.stages.STAGES):
                scenario = tuning.scenario(candidate, stage, 555)
                overrides = scenario.pop("config_overrides")
                self.assertEqual(scenario.pop("random_seed"), 555)
                self.assertEqual(scenario, {k: v for k, v in original.items() if k != "config_overrides"})
                self.assertTrue(all(overrides[key] == value for key, value in toggles.items()))
                self.assertTrue(all(overrides[key] == value for key, value in candidate.items()))

    def test_measure_pairs_all_stages_with_all_five_seeds(self) -> None:
        with patch.object(tuning, "run_one", side_effect=lambda settings, stage, seed, *rest: stage * 100000 + seed) as run:
            result = tuning.measure(tuning.DEFAULTS, Path("unused"), "identity", None, 2)
        self.assertEqual(run.call_count, 20)
        self.assertEqual(result["values"], [[stage * 100000 + seed for seed in tuning.stages.SEEDS] for stage in range(4)])

    def test_cache_retains_grace_for_scouting_and_all_values_for_recruitment(self) -> None:
        self.assertEqual(tuning.effective_settings(tuning.DEFAULTS, 0), {"forage_start_radius": 450.0})
        self.assertEqual(tuning.effective_settings(tuning.DEFAULTS, 1),
                         {"forage_start_radius": 450.0, "recruit_grace_trips": 3.0})
        self.assertEqual(tuning.effective_settings(tuning.DEFAULTS, 2), tuning.DEFAULTS)

    def test_radius_screen_measures_only_the_first_gate_on_all_five_seeds(self) -> None:
        with patch.object(tuning, "run_one", return_value=1.0) as run:
            result = tuning.measure(tuning.DEFAULTS, Path("unused"), "identity", None, 2, stage_count=2)
        self.assertEqual(run.call_count, 10)
        self.assertEqual(result["values"], [[1.0] * 5, [1.0] * 5])
        report = tuning.render([{"settings": tuning.DEFAULTS, "values": [[v] * 5 for v in (6, 5, 4, 3)]}],
                               "identity", [result])
        self.assertIn("Intermediate-radius first-gate screen", report)

    def test_cache_reuses_measurement_but_invalidates_on_simulation_change(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            report = root / "report.json"
            report.write_text(json.dumps({"summary": {"forager_delivery_amount": 220}}), encoding="utf-8")
            completed = SimpleNamespace(returncode=0, stdout=f"status=passed result={root / 'result.json'}", stderr="")
            with patch.object(tuning.subprocess, "run", return_value=completed) as run:
                self.assertEqual(tuning.run_one(tuning.DEFAULTS, 2, 7, root, "first", None), 1.0)
                self.assertEqual(tuning.run_one(tuning.DEFAULTS, 2, 7, root, "first", None), 1.0)
                self.assertEqual(run.call_count, 1)
                tuning.run_one(tuning.DEFAULTS, 2, 7, root, "changed", None)
                self.assertEqual(run.call_count, 2)

    def test_failed_run_or_leaked_toggle_is_never_cached(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            report = root / "report.json"
            report.write_text(json.dumps({"summary": {"forager_delivery_amount": 220, "orientation_flights": 1}}), encoding="utf-8")
            for completed in (SimpleNamespace(returncode=1, stdout="status=failed", stderr="failure"),
                              SimpleNamespace(returncode=0, stdout=f"status=passed result={root / 'result.json'}", stderr="")):
                with patch.object(tuning.subprocess, "run", return_value=completed), self.assertRaises(RuntimeError):
                    tuning.run_one(tuning.DEFAULTS, 2, 7, root, "first", None)
                self.assertEqual(list(root.rglob("measurement.json")), [])

    def test_failed_sweep_is_recorded_idempotently_in_its_own_section(self) -> None:
        result = {"settings": tuning.DEFAULTS, "values": [[value] * 5 for value in (6, 5, 4, 3)]}
        report = tuning.render([result], "identity")
        self.assertIn("DECISION REQUIRED", report)
        self.assertIn("not selected for gameplay", report)
        self.assertNotIn("**PASS**", report)
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "plan.md"
            path.write_text("Keep status\n## FR-1b -- tune the measured foraging-stage order\nKeep brief\n\n## FR-2 -- successor\nKeep next\n", encoding="utf-8")
            tuning.record_plan(report, path)
            first = path.read_text(encoding="utf-8")
            tuning.record_plan(report, path)
            self.assertEqual(path.read_text(encoding="utf-8"), first)
            self.assertTrue(first.startswith("Keep status\n"))
            self.assertIn("Keep brief", first)
            self.assertTrue(first.endswith("## FR-2 -- successor\nKeep next\n"))

    def test_main_records_both_success_and_decision_required_verdicts(self) -> None:
        for values, expected in (((6, 5, 4, 3), 2), ((1, 2, 3, 4), 0)):
            with self.subTest(expected=expected), tempfile.TemporaryDirectory() as temporary:
                def measure(settings, *args, stage_count=4):
                    return {"settings": settings, "values": [[value] * 5 for value in values[:stage_count]]}

                with patch.object(tuning, "measure", side_effect=measure), \
                     patch.object(tuning, "fingerprint", return_value="identity"), \
                     patch.object(tuning, "record_plan") as record, \
                     patch.object(sys, "argv", ["forager_tuning.py", "--output", temporary]), \
                     patch("sys.stdout", new_callable=StringIO):
                    self.assertEqual(tuning.main(), expected)
                self.assertEqual(record.call_count, 1)
                self.assertIn("DECISION REQUIRED" if expected == 2 else "**PASS**", record.call_args.args[0])


if __name__ == "__main__":
    unittest.main()
