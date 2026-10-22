"""Contracts for paired causal controls, complete windows and source-matched reuse."""

import json
import sys
import tempfile
import unittest
from io import StringIO
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from tools import forager_diagnosis as diagnosis


def measurement(food=1.0, seed=7):
    return {"seed": seed, "food": food, "deliveries": 4, "matches": 0, "settled": 2,
            "settlement_day": 3.0, "peak_foragers": 11, "seeking_sample_mean": 1.5,
            "mentoring_sample_mean": 0.0, "delivery_events_per_sim_minute": 1.0}


class ForagerDiagnosisTests(unittest.TestCase):
    def test_controls_preserve_the_colony_and_change_only_the_named_factor(self):
        original = diagnosis.stages._scenario(diagnosis.stages.STAGES[0][1], 555)
        for case in range(len(diagnosis.CASES)):
            scenario = diagnosis.scenario(case, 555)
            self.assertEqual({k: v for k, v in scenario.items() if k != "config_overrides"},
                             {k: v for k, v in original.items() if k != "config_overrides"})
            self.assertEqual(scenario["config_overrides"]["seconds_per_day"], 20)
        for before, after, factor in ((2, 4, "recruit_wait_seconds"),
                                      (5, 6, "recruit_wait_seconds"),
                                      (1, 7, "floral_constancy_on")):
            left, right = [diagnosis.scenario(case, 7)["config_overrides"] for case in (before, after)]
            self.assertEqual({key for key in left if left[key] != right[key]}, {factor})
        for case in (5, 6):
            self.assertTrue(all(diagnosis.scenario(case, 7)["config_overrides"][key] == 1e9
                                for key in diagnosis.NO_MENTORS))

    def test_extraction_requires_a_complete_window_and_labels_sampled_occupancy(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            verdict = {"status": "passed", "outcome": "max_days", "seed": 7}
            summary = {"day": 20, "game_time": 380, "forager_delivery_amount": 220,
                       "forager_deliveries": 4, "recruitment_matches": 0, "scouting_settled": 1}
            rows = [{"type": "snapshot", "population": {"by_role": {"forager": 11},
                    "by_state": {"AT_ENTRANCE_SEEKING": count, "AT_ENTRANCE_MENTORING": 0}}}
                    for count in (1, 2)] + [{"type": "scouting_settled", "game_time": 40}]
            (root / "result.json").write_text(json.dumps(verdict))
            (root / "report.json").write_text(json.dumps({"summary": summary}))
            (root / "session.jsonl").write_text("\n".join(map(json.dumps, rows)))
            result = diagnosis.extract(root)
            self.assertEqual(result["food"], 1.0)
            self.assertEqual(result["seeking_sample_mean"], 1.5)
            self.assertEqual(result["settlement_day"], 3.0)
            summary["day"] = 10
            (root / "report.json").write_text(json.dumps({"summary": summary}))
            with self.assertRaisesRegex(ValueError, "Expected day"):
                diagnosis.extract(root)
            verdict["outcome"] = "queen_died"
            (root / "result.json").write_text(json.dumps(verdict))
            with self.assertRaisesRegex(ValueError, "Incomplete"):
                diagnosis.extract(root)

    def test_paired_changes_use_the_same_seed_and_do_not_invent_zero_baselines(self):
        before = [measurement(v, seed) for v, seed in zip((1, 2, 4, 8, 0), diagnosis.stages.SEEDS)]
        after = [measurement(v, seed) for v, seed in zip((2, 1, 4, 10, 5), diagnosis.stages.SEEDS)]
        changes = diagnosis.paired_changes(before, after)
        self.assertEqual(changes, [100.0, -50.0, 0.0, 25.0, None])
        with self.assertRaises(ValueError):
            diagnosis.paired_changes([measurement()], [measurement()])
        with self.assertRaises(ValueError):
            diagnosis.paired_changes(before, list(reversed(after)))

    def test_report_rejects_a_control_that_received_a_mentor(self):
        values = [[measurement()] * 5 for _ in diagnosis.CASES]
        values[5] = [dict(measurement(), matches=1)] * 5
        with self.assertRaisesRegex(ValueError, "unexpectedly matched"):
            diagnosis.render(values, "identity")

    def test_archived_baseline_requires_matching_simulation_inputs(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            data = {"fingerprint": "old", "settings": diagnosis.tuning.DEFAULTS,
                    "cases": [{"stage": 2, "seed": 7, "directory": "baseline-case"}]}
            (root / "manifest.json").write_text(json.dumps(data))
            with patch.object(diagnosis, "extract", return_value=measurement()) as extract:
                self.assertIsNone(diagnosis.baseline_case(2, 7, "new", root))
                extract.assert_not_called()
                self.assertEqual(diagnosis.baseline_case(2, 7, "old", root), measurement())
                extract.assert_called_once_with(root / "baseline-case")
                self.assertIsNone(diagnosis.baseline_case(4, 7, "old", root))

    def test_failed_runs_are_not_cached_and_successful_runs_can_be_replayed(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with patch.object(diagnosis, "baseline_case", return_value=None), \
                 patch.object(diagnosis.subprocess, "run", return_value=SimpleNamespace(
                     returncode=1, stdout="status=failed", stderr="failure")):
                with self.assertRaises(RuntimeError):
                    diagnosis.run_case(4, 7, "identity", root, root, None)
            self.assertEqual(list(root.rglob("completed.json")), [])
            with patch.object(diagnosis, "baseline_case", return_value=None), \
                 patch.object(diagnosis, "extract", return_value=measurement()), \
                 patch.object(diagnosis.subprocess, "run", return_value=SimpleNamespace(
                     returncode=0, stdout=f"status=passed result={root / 'result.json'}", stderr="")) as run:
                for _ in range(2):
                    self.assertEqual(diagnosis.run_case(4, 7, "identity", root, root, None), measurement())
                self.assertEqual(run.call_count, 1)

    def test_main_collects_all_cases_on_all_five_seeds_and_records_limits(self):
        with tempfile.TemporaryDirectory() as temporary:
            with patch.object(sys, "argv", ["forager_diagnosis.py", "--output", temporary]), \
                 patch.object(diagnosis.tuning, "fingerprint", return_value="identity"), \
                 patch.object(diagnosis, "run_case", side_effect=lambda case, seed, *args: measurement(seed=seed)) as run, \
                 patch("sys.stdout", new_callable=StringIO):
                self.assertEqual(diagnosis.main(), 0)
            self.assertEqual(run.call_count, len(diagnosis.CASES) * 5)
            for case in range(len(diagnosis.CASES)):
                self.assertEqual([call.args[1] for call in run.call_args_list if call.args[0] == case],
                                 list(diagnosis.stages.SEEDS))
            report = (Path(temporary) / "report.md").read_text(encoding="utf-8")
            self.assertIn("not exact dwell time", report)
            self.assertIn("does not isolate", report)
            self.assertIn("not a recommendation", report)


if __name__ == "__main__":
    unittest.main()
