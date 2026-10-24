"""Unit tests for tools/foraging_evidence_report.py.

Tests cover:
- CLI usage and invalid arguments exit status
- Helper functions (_mean, _metrics, _handling)
- Full experiment report generation with METRICS processing, case grouping,
  and not_exercised conditions (recruitment, senescence, handling experience).
"""

import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools import foraging_evidence_report


class TestForagingEvidenceReportHelpers(unittest.TestCase):
    def test_mean(self) -> None:
        self.assertEqual(foraging_evidence_report._mean([]), 0.0)
        self.assertEqual(foraging_evidence_report._mean([1.0, 2.0, 3.0]), 2.0)
        self.assertEqual(foraging_evidence_report._mean([1.0, 2.0]), 1.5)
        self.assertEqual(foraging_evidence_report._mean([1.0, 2.0, 3.0, 4.0]), 2.5)

    def test_metrics(self) -> None:
        rows = [
            {
                "flower_visits": 10,
                "recruitment_matches": 2,
                "deaths_by_cause": {"starvation": 1},
            },
            {
                "flower_visits": 20,
                "recruitment_matches": 4,
                "deaths_by_cause": {"starvation": 3},
            },
        ]
        res = foraging_evidence_report._metrics(rows)
        self.assertEqual(res["flower_visits"], {"mean": 15.0, "min": 10.0, "max": 20.0})
        self.assertEqual(res["recruitment_matches"], {"mean": 3.0, "min": 2.0, "max": 4.0})
        self.assertEqual(res["starvation_deaths"], {"mean": 2.0, "min": 1.0, "max": 3.0})
        # Default zero for unspecified metric in rows
        self.assertEqual(res["orientation_flights"], {"mean": 0.0, "min": 0.0, "max": 0.0})

    def test_handling(self) -> None:
        rows = [
            {
                "handling_by_experience": {
                    "novice": {"visits": 2, "seconds": 10.0},
                    "expert": {"visits": 5, "seconds": 15.0},
                }
            },
            {
                "handling_by_experience": {
                    "novice": {"visits": 3, "seconds": 20.0},
                }
            },
        ]
        res = foraging_evidence_report._handling(rows)
        self.assertIn("novice", res)
        self.assertEqual(res["novice"]["visits"], 5)
        self.assertEqual(res["novice"]["average_seconds"], 6.0)
        self.assertIn("expert", res)
        self.assertEqual(res["expert"]["visits"], 5)
        self.assertEqual(res["expert"]["average_seconds"], 3.0)


class TestForagingEvidenceReportCLI(unittest.TestCase):
    def test_usage_error(self) -> None:
        with patch("sys.stderr", new_callable=io.StringIO) as mock_stderr:
            ret = foraging_evidence_report.main(["foraging_evidence_report.py"])
            self.assertEqual(ret, 2)
            self.assertIn("usage:", mock_stderr.getvalue())

    def test_missing_file_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            missing = Path(tmp_dir) / "nonexistent.json"
            with self.assertRaises((FileNotFoundError, OSError)):
                foraging_evidence_report.main(["foraging_evidence_report.py", str(missing)])

    def test_full_report_generation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            run1_dir = tmp_path / "case1" / "run1"
            run1_dir.mkdir(parents=True)
            result1_path = run1_dir / "result.json"
            result1_path.write_text(json.dumps({"process": {"wall_seconds": 5.0}}), encoding="utf-8")
            report1_path = run1_dir / "report.json"
            report1_path.write_text(
                json.dumps({
                    "summary": {
                        "flower_visits": 10,
                        "unique_flowers_visited": 5,
                        "orientation_flights": 1,
                        "scouting_settled": 2,
                        "recruitment_matches": 0,
                        "forager_deliveries": 3,
                        "forager_delivery_amount": 15.0,
                        "stall_recoveries": 0,
                        "flowers_senesced": 0,
                        "senescence_nectar_lost": 0.0,
                        "senescence_pollen_lost": 0.0,
                        "deaths_by_cause": {"starvation": 0},
                        "handling_by_experience": {},
                    }
                }),
                encoding="utf-8",
            )

            exp_json = tmp_path / "experiment.json"
            experiment_data = {
                "name": "test_exp",
                "status": "completed",
                "seeds": [123],
                "cases": {
                    "entrance": [
                        {"status": "passed", "result": "case1/run1/result.json"},
                        {"status": "failed", "result": "case1/run1/result.json"},
                    ],
                    "senescence_on": [
                        {"status": "passed", "result": "case1/run1/result.json"},
                    ],
                    "handling_experience": [
                        {"status": "passed", "result": "case1/run1/result.json"},
                    ],
                },
            }
            exp_json.write_text(json.dumps(experiment_data), encoding="utf-8")

            with patch("sys.stdout", new_callable=io.StringIO) as mock_stdout:
                ret = foraging_evidence_report.main(["foraging_evidence_report.py", str(exp_json)])
                self.assertEqual(ret, 0)
                self.assertIn("status=completed", mock_stdout.getvalue())

            verdict_path = tmp_path / "foraging-evidence-verdict.json"
            self.assertTrue(verdict_path.exists())
            verdict = json.loads(verdict_path.read_text(encoding="utf-8"))

            self.assertEqual(verdict["schema_version"], 1)
            self.assertEqual(verdict["experiment"], "test_exp")
            self.assertEqual(verdict["status"], "completed")
            self.assertEqual(verdict["seeds"], [123])
            self.assertIn("entrance", verdict["cases"])
            self.assertEqual(verdict["cases"]["entrance"]["runs"], 1)

            # Check not_exercised conditions triggered by mock data
            not_exercised = verdict["not_exercised"]
            self.assertIn("entrance recruitment", not_exercised)
            self.assertIn("senescence recharge effect", not_exercised)
            self.assertIn("handling experience", not_exercised)

    def test_every_metric_averaged_across_passed_runs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            runs = []
            for index, scale in enumerate((1.0, 3.0)):
                run_dir = tmp_path / ("run%d" % index)
                run_dir.mkdir()
                (run_dir / "result.json").write_text(
                    json.dumps({"process": {"wall_seconds": 10.0 * scale}}), encoding="utf-8")
                summary = {metric: scale for metric in foraging_evidence_report.METRICS if metric != "runtime_seconds"}
                (run_dir / "report.json").write_text(json.dumps({"summary": summary}), encoding="utf-8")
                runs.append({"status": "passed", "result": "run%d/result.json" % index})
            exp_json = tmp_path / "experiment.json"
            exp_json.write_text(json.dumps({"name": "grouped", "status": "completed", "seeds": [1, 2],
                                            "cases": {"entrance": runs}}), encoding="utf-8")

            with patch("sys.stdout", new_callable=io.StringIO):
                self.assertEqual(foraging_evidence_report.main(["foraging_evidence_report.py", str(exp_json)]), 0)
            verdict = json.loads((tmp_path / "foraging-evidence-verdict.json").read_text(encoding="utf-8"))

            case = verdict["cases"]["entrance"]
            self.assertEqual(case["runs"], 2)
            for metric in foraging_evidence_report.METRICS:
                expected = {"mean": 20.0, "min": 10.0, "max": 30.0} if metric == "runtime_seconds" else {"mean": 2.0, "min": 1.0, "max": 3.0}
                self.assertEqual(case["metrics"][metric], expected, metric)
            self.assertEqual(verdict["not_exercised"], [])

    def test_unreadable_file_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            with self.assertRaises(OSError):
                foraging_evidence_report.main(["foraging_evidence_report.py", tmp_dir])


if __name__ == "__main__":
    unittest.main()
