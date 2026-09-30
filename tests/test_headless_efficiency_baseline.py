"""Executable Slice 0 baselines for the current headless presentation path."""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parent.parent
FIXTURES = Path(__file__).resolve().parent / "fixtures" / "headless"
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

from headless.contracts import (  # noqa: E402
    FAILURE_STDOUT_BUDGET_BYTES,
    SUCCESS_STDOUT_BUDGET_BYTES,
    fits_stdout_budget,
)


def _load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


analyze_session = _load_module("analyze_session", TOOLS / "analyze_session.py")
run_scenario = _load_module("run_scenario", TOOLS / "run_scenario.py")


class HeadlessEfficiencyBaselineTest(unittest.TestCase):
    def analysis_for(self, name: str):
        return analyze_session.analyze(analyze_session.load_entries(FIXTURES / name))

    def test_synthetic_fixtures_cover_terminal_shapes(self):
        self.assertEqual("actions_resolved", self.analysis_for("success.jsonl")["summary"]["outcome"])
        self.assertEqual("rejected", self.analysis_for("action_failure.jsonl")["actions"]["problems"][0]["result"])
        self.assertIsNone(self.analysis_for("missing_summary.jsonl")["summary"])
        self.assertIsNone(self.analysis_for("timeout_failure.jsonl")["summary"])
        self.assertEqual(12, len(self.analysis_for("long_series.jsonl")["population_curve"]))

    def test_current_projection_byte_counts_are_recorded(self):
        success_run = FIXTURES / "success.jsonl"
        entries = analyze_session.load_entries(success_run)
        actual = {}
        for profile in ("brief", "behaviour", "full"):
            stdout = io.StringIO()
            with mock.patch.object(run_scenario, "run_once", return_value=Path("fixture-session.jsonl")), \
                 mock.patch.object(run_scenario, "load_entries", return_value=entries), \
                 contextlib.redirect_stdout(stdout):
                self.assertEqual(0, run_scenario.run_scenario(success_run, "unused", 1, 1, profile))
            actual[profile] = len(stdout.getvalue().encode("utf-8"))
        self.assertEqual({"brief": 396, "behaviour": 522, "full": 884}, actual)

    def test_verdict_output_budgets_are_executable(self):
        self.assertTrue(fits_stdout_budget("status=passed run_id=fixture", failed=False))
        self.assertFalse(fits_stdout_budget(b"x" * (SUCCESS_STDOUT_BUDGET_BYTES + 1), failed=False))
        self.assertTrue(fits_stdout_budget(b"x" * FAILURE_STDOUT_BUDGET_BYTES, failed=True))
        self.assertFalse(fits_stdout_budget(b"x" * (FAILURE_STDOUT_BUDGET_BYTES + 1), failed=True))

    def test_current_aggregate_does_not_make_a_bad_metric_fail(self):
        """Documents the Slice 1 gap: aggregate evidence is informational today."""
        bad_run = FIXTURES / "aggregate_bad_metric.jsonl"
        analysis = self.analysis_for(bad_run.name)
        aggregate = analyze_session.aggregate_runs([analysis, analysis])
        self.assertFalse(aggregate["mechanic_firing"]["predators_on"]["all_fired"])

        stdout = io.StringIO()
        stderr = io.StringIO()
        with mock.patch.object(run_scenario, "run_once", return_value=bad_run), \
             contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            exit_code = run_scenario.run_scenario(bad_run, "unused", 1, 2, "brief")

        self.assertEqual(0, exit_code)
        self.assertIn('"all_fired": false', stdout.getvalue())
        self.assertEqual("", stderr.getvalue())

    def test_existing_cli_flags_remain_available(self):
        result = subprocess.run(
            [sys.executable, str(TOOLS / "run_scenario.py"), "--help"],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(0, result.returncode, result.stderr)
        for flag in ("--timeout", "--godot-path", "--repeat", "--seeds", "--report", "--full", "--fixed-fps",
                     "--route-help"):
            self.assertIn(flag, result.stdout)


if __name__ == "__main__":
    unittest.main()
