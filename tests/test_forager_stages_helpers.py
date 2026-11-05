"""Unit tests for pure helpers and execution contracts in tools/forager_stages.py.

Tests cover:
- delivery_per_forager_day calculation with various values and zero divisor handling.
- stage_rows median calculation, ratio rendering, and single/multi-stage sequences.
- _scenario JSON construction, config overrides merging, and random seed setting.
- _run_one failure conditions: subprocess failure, non-zero returncode, missing
  passed status, orientation flight leaks, and scouting settled leaks.
- main CLI formatting and stage table rendering.
"""

from __future__ import annotations

import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from tools import forager_stages


class TestForagerStagesHelpers(unittest.TestCase):
    def test_delivery_per_forager_day_values(self) -> None:
        """Verify delivery per forager day computes forager_delivery_amount / (DAYS * FORAGERS)."""
        summary = {"forager_delivery_amount": 220}
        expected = 220.0 / (forager_stages.DAYS * forager_stages.FORAGERS)
        self.assertEqual(forager_stages.delivery_per_forager_day(summary), expected)

        summary_zero = {"forager_delivery_amount": 0}
        self.assertEqual(forager_stages.delivery_per_forager_day(summary_zero), 0.0)

        summary_float = {"forager_delivery_amount": 440.0}
        self.assertEqual(forager_stages.delivery_per_forager_day(summary_float), 2.0)

    def test_stage_rows_single_and_multiple(self) -> None:
        """Verify stage_rows computes medians and ratio against preceding stage."""
        # Single stage has no previous stage, so ratio is '--'
        single = [[2.0, 4.0, 6.0]]
        self.assertEqual(forager_stages.stage_rows(single), [(4.0, "--")])

        # Multiple stages
        multi = [
            [1.0, 2.0, 3.0],      # median 2.0
            [3.0, 4.0, 5.0],      # median 4.0 -> ratio 2.00x
            [1.0, 2.0, 3.0],      # median 2.0 -> ratio 0.50x
        ]
        rows = forager_stages.stage_rows(multi)
        self.assertEqual(rows, [(2.0, "--"), (4.0, "2.00x"), (2.0, "0.50x")])

    def test_scenario_generation(self) -> None:
        """Verify _scenario loads template, applies overrides, and sets random_seed."""
        toggles = {"orientation_flight_on": True, "custom_toggle": False}
        seed = 4242
        scen = forager_stages._scenario(toggles, seed)
        self.assertEqual(scen["random_seed"], seed)
        self.assertTrue(scen["config_overrides"]["orientation_flight_on"])
        self.assertFalse(scen["config_overrides"]["custom_toggle"])

    def test_run_one_subprocess_failure_raises(self) -> None:
        """Verify _run_one raises RuntimeError on subprocess failure or non-zero exit."""
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            with patch.object(subprocess, "run") as mock_run:
                mock_run.return_value = SimpleNamespace(
                    returncode=1,
                    stdout="some output",
                    stderr="an error occurred",
                )
                with self.assertRaisesRegex(RuntimeError, "failed"):
                    forager_stages._run_one("test_stage", {"orientation_flight_on": True}, 7, tmp, None)

    def test_run_one_missing_status_or_result_pattern_raises(self) -> None:
        """Verify _run_one raises RuntimeError if status=passed or result= is missing in stdout."""
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            with patch.object(subprocess, "run") as mock_run:
                # Missing result=
                mock_run.return_value = SimpleNamespace(
                    returncode=0,
                    stdout="status=passed but no path",
                    stderr="",
                )
                with self.assertRaisesRegex(RuntimeError, "failed"):
                    forager_stages._run_one("test_stage", {"orientation_flight_on": True}, 7, tmp, None)

                # Missing status=passed
                mock_run.return_value = SimpleNamespace(
                    returncode=0,
                    stdout="status=failed result=/tmp/res.json",
                    stderr="",
                )
                with self.assertRaisesRegex(RuntimeError, "failed"):
                    forager_stages._run_one("test_stage", {"orientation_flight_on": True}, 7, tmp, None)

    def test_run_one_leak_checks_raise(self) -> None:
        """Verify _run_one enforces disabled feature leak checks."""
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            res_file = tmp / "results" / "run" / "result.json"
            res_file.parent.mkdir(parents=True, exist_ok=True)
            res_file.write_text("{}", encoding="utf-8")

            report_file = tmp / "results" / "run" / "report.json"

            # 1. Orientation flights leaked while disabled
            report_file.write_text(json.dumps({
                "summary": {
                    "forager_delivery_amount": 100,
                    "orientation_flights": 3,
                    "scouting_settled": 0,
                }
            }), encoding="utf-8")

            with patch.object(subprocess, "run") as mock_run:
                mock_run.return_value = SimpleNamespace(
                    returncode=0,
                    stdout=f"status=passed result={res_file}",
                    stderr="",
                )
                with self.assertRaisesRegex(RuntimeError, "orientation flights leaked while disabled"):
                    forager_stages._run_one(
                        "stage_a",
                        {"orientation_flight_on": False, "scouting_on": True},
                        7,
                        tmp,
                        None,
                    )

            # 2. Scouting settled leaked while disabled
            report_file.write_text(json.dumps({
                "summary": {
                    "forager_delivery_amount": 100,
                    "orientation_flights": 0,
                    "scouting_settled": 2,
                }
            }), encoding="utf-8")

            with patch.object(subprocess, "run") as mock_run:
                mock_run.return_value = SimpleNamespace(
                    returncode=0,
                    stdout=f"status=passed result={res_file}",
                    stderr="",
                )
                with self.assertRaisesRegex(RuntimeError, "scouting settled while disabled"):
                    forager_stages._run_one(
                        "stage_b",
                        {"orientation_flight_on": True, "scouting_on": False},
                        7,
                        tmp,
                        None,
                    )

    def test_run_one_success(self) -> None:
        """Verify _run_one parses report summary and returns delivery_per_forager_day on success."""
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            res_file = tmp / "results" / "run" / "result.json"
            res_file.parent.mkdir(parents=True, exist_ok=True)
            res_file.write_text("{}", encoding="utf-8")

            report_file = tmp / "results" / "run" / "report.json"
            report_file.write_text(json.dumps({
                "summary": {
                    "forager_delivery_amount": 220,
                    "orientation_flights": 0,
                    "scouting_settled": 0,
                }
            }), encoding="utf-8")

            with patch.object(subprocess, "run") as mock_run:
                mock_run.return_value = SimpleNamespace(
                    returncode=0,
                    stdout=f"status=passed result={res_file}",
                    stderr="",
                )
                val = forager_stages._run_one(
                    "stage_c",
                    {"orientation_flight_on": False, "scouting_on": False},
                    7,
                    tmp,
                    "godot_bin",
                )
                self.assertEqual(val, 1.0)
                # Check godot-path was passed
                cmd = mock_run.call_args[0][0]
                self.assertIn("--godot-path", cmd)
                self.assertIn("godot_bin", cmd)

    def test_main_cli_table_rendering(self) -> None:
        """Verify main output formatting matches expected markdown table structure."""
        with patch.object(forager_stages, "_run_one", side_effect=lambda name, toggles, seed, root, godot: 1.5):
            with patch("sys.argv", ["tools/forager_stages.py"]), \
                 patch("sys.stdout", new_callable=io.StringIO) as mock_stdout:
                code = forager_stages.main()
                self.assertEqual(code, 0)
                output = mock_stdout.getvalue()
                self.assertIn("Window: days 1--20; divisor: 20 days x 11 starting foragers.", output)
                self.assertIn("| Stage | Food per forager per day (median; five seeds) | vs stage before |", output)
                self.assertIn("| Orientation flight | 1.5000 (1.5000, 1.5000, 1.5000, 1.5000, 1.5000) | -- |", output)
                self.assertIn("| Auto scouting | 1.5000 (1.5000, 1.5000, 1.5000, 1.5000, 1.5000) | 1.00x |", output)


if __name__ == "__main__":
    unittest.main()
