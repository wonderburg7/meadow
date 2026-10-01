"""Pure-Python tests for Slice 1's typed expectation contract."""

from __future__ import annotations

import sys
import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

from headless.verdicts import ContractError, evaluate_expectations, validate_expectations  # noqa: E402
from headless.jobs import HeadlessRunOutcome  # noqa: E402
from analyze_session import analyze  # noqa: E402
from run_scenario import _suppress_windows_crash_dialogs, run_once, run_verdict_scenario  # noqa: E402


ANALYSIS = {
    "summary": {
        "outcome": "actions_resolved", "game_time": 12.5, "day": 1,
        "total_deaths": 0, "queen_alive": True, "gynes_released": 0,
    },
    "actions": {"total": 1, "problems": []},
}


class HeadlessVerdictTest(unittest.TestCase):
    def test_analysis_derives_each_milestone_in_one_day_series(self):
        settings = {
            "energy_burn_rate": 1.0,
            "winter_burn_factor": 1.0,
            "winter_length_days": 1.5,
            "seconds_per_day": 2.0,
            "honey_energy_factor": 2.0,
        }
        entries = [
            {"type": "config", "settings": settings},
            {"type": "snapshot", "day": 1, "game_time": 2.0, "population": {"total": 1},
             "resources": {"food_stores": 1}, "environment": {"winter_here": False}},
            {"type": "snapshot", "day": 2, "game_time": 3.0, "population": {"total": 2},
             "resources": {"food_stores": 3}, "environment": {"winter_here": True}},
            {"type": "snapshot", "day": 3, "game_time": 6.0, "population": {"total": 2},
             "resources": {"food_stores": 4}, "environment": {"winter_here": False}},
        ]

        self.assertEqual({
            "first_worker_day": 2,
            "winter_entered_day": 2,
            "winter_survived_day": 3,
            "food_secure_day": 2,
        }, analyze(entries)["milestones"])
        self.assertEqual({
            "first_worker_day": 1.5,
            "winter_entered_day": 1.5,
            "winter_survived_day": 3.0,
            "food_secure_day": 1.5,
        }, analyze(entries)["milestone_times"])

    def test_milestone_times_use_the_first_qualifying_snapshot_within_a_day(self):
        settings = {"energy_burn_rate": 1.0, "winter_burn_factor": 1.0,
                    "winter_length_days": 1.0, "seconds_per_day": 200.0,
                    "honey_energy_factor": 1.0}
        entries = [
            {"type": "config", "settings": settings},
            {"type": "snapshot", "day": 2, "game_time": 300.0,
             "population": {"total": 1}, "resources": {"food_stores": 0},
             "environment": {"winter_here": False}},
            {"type": "snapshot", "day": 2, "game_time": 350.0,
             "population": {"total": 2}, "resources": {"food_stores": 400},
             "environment": {"winter_here": False}},
            {"type": "snapshot", "day": 2, "game_time": 390.0,
             "population": {"total": 2}, "resources": {"food_stores": 400},
             "environment": {"winter_here": False}},
        ]
        analysis = analyze(entries)
        self.assertEqual({"first_worker_day": 2, "food_secure_day": 2},
                         analysis["milestones"])
        self.assertEqual({"first_worker_day": 1.75, "food_secure_day": 1.75},
                         analysis["milestone_times"])

    def test_zero_population_is_neither_food_secure_nor_winter_survived(self):
        settings = {"energy_burn_rate": 1.0, "winter_burn_factor": 1.0,
                    "winter_length_days": 1.0, "seconds_per_day": 1.0,
                    "honey_energy_factor": 1.0}
        entries = [
            {"type": "config", "settings": settings},
            {"type": "snapshot", "day": 1, "game_time": 1.0,
             "population": {"total": 0}, "resources": {"food_stores": 0},
             "environment": {"winter_here": True}},
            {"type": "snapshot", "day": 2, "game_time": 2.0,
             "population": {"total": 0}, "resources": {"food_stores": 0},
             "environment": {"winter_here": False}},
        ]
        analysis = analyze(entries)
        self.assertEqual({"winter_entered_day": 1}, analysis["milestones"])
        self.assertEqual({"winter_entered_day": 1.0}, analysis["milestone_times"])

    def test_analysis_without_snapshots_has_no_milestones(self):
        analysis = analyze([{"type": "config", "settings": {}}])
        self.assertEqual({}, analysis["milestones"])
        self.assertEqual({}, analysis["milestone_times"])

    def test_missing_milestone_has_consistent_expectation_results(self):
        analysis = dict(ANALYSIS, milestones={})
        expectations = validate_expectations([
            {"id": "eq", "metric": "milestones.winter_survived_day", "op": "eq", "value": 4},
            {"id": "ne", "metric": "milestones.winter_survived_day", "op": "ne", "value": 4},
            {"id": "lt", "metric": "milestones.winter_survived_day", "op": "lt", "value": 4},
            {"id": "lte", "metric": "milestones.winter_survived_day", "op": "lte", "value": 4},
            {"id": "gt", "metric": "milestones.winter_survived_day", "op": "gt", "value": 4},
            {"id": "gte", "metric": "milestones.winter_survived_day", "op": "gte", "value": 4},
            {"id": "between", "metric": "milestones.winter_survived_day", "op": "between", "min": 1, "max": 4},
            {"id": "exists", "metric": "milestones.winter_survived_day", "op": "exists"},
            {"id": "empty", "metric": "milestones.winter_survived_day", "op": "empty"},
            {"id": "not_empty", "metric": "milestones.winter_survived_day", "op": "not_empty"},
        ])

        results = {result.identifier: result for result in evaluate_expectations(analysis, expectations)}
        self.assertIsNone(results["eq"].actual)
        self.assertFalse(results["eq"].passed)
        self.assertTrue(results["ne"].passed)
        for identifier in ("lt", "lte", "gt", "gte", "between", "exists", "not_empty"):
            self.assertFalse(results[identifier].passed)
        self.assertTrue(results["empty"].passed)

    def test_legacy_runner_disables_godot_crash_handler(self):
        scenario = Path("scenario.json")
        session = Path("session.jsonl")

        def fake_godot(command, **_kwargs):
            self.assertIn("--disable-crash-handler", command)
            return mock.Mock(returncode=0, stdout="", stderr="")

        with mock.patch("run_scenario.subprocess.run", side_effect=fake_godot), \
             mock.patch.dict(run_once.__globals__, {"session_file_for_run_id": lambda _run_id: session}), \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(session, run_once(scenario, "unused", 1))

    def test_windows_error_mode_is_applied_only_while_spawning(self):
        kernel32 = mock.Mock()
        kernel32.GetErrorMode.return_value = 0x10
        fake_windll = SimpleNamespace(kernel32=kernel32)

        with mock.patch("run_scenario.os.name", "nt"), \
             mock.patch("run_scenario.ctypes.windll", fake_windll, create=True):
            with _suppress_windows_crash_dialogs():
                self.assertEqual([mock.call(0x13)], kernel32.SetErrorMode.call_args_list)

        self.assertEqual([mock.call(0x13), mock.call(0x10)], kernel32.SetErrorMode.call_args_list)

    def test_typed_expectations_pass_and_name_their_results(self):
        expect = validate_expectations([
            {"id": "queen", "metric": "summary.queen_alive", "op": "eq", "value": True},
            {"id": "clean", "metric": "actions.problems", "op": "empty"},
            {"id": "day", "metric": "summary.day", "op": "between", "min": 1, "max": 2},
        ])
        results = evaluate_expectations(ANALYSIS, expect)
        self.assertEqual(["queen", "clean", "day"], [result.identifier for result in results])
        self.assertTrue(all(result.passed for result in results))

    def test_failed_expectation_is_a_game_failure_not_a_contract_error(self):
        expect = validate_expectations([
            {"id": "no_deaths", "metric": "summary.total_deaths", "op": "eq", "value": 1},
        ])
        result = evaluate_expectations(ANALYSIS, expect)[0]
        self.assertFalse(result.passed)
        self.assertEqual(1, result.expected)
        self.assertEqual(0, result.actual)

    def test_unknown_metrics_and_type_errors_are_contract_errors(self):
        with self.assertRaisesRegex(ContractError, "unknown expectation metric"):
            validate_expectations([{"metric": "summary.typo", "op": "eq", "value": 1}])
        with self.assertRaisesRegex(ContractError, "numeric bounds"):
            validate_expectations([{"metric": "summary.day", "op": "between", "min": "1", "max": 2}])
        with self.assertRaisesRegex(ContractError, "requires numeric"):
            evaluate_expectations(ANALYSIS, validate_expectations([
                {"metric": "summary.day", "op": "gte", "value": "tomorrow"},
            ]))

    def test_runner_writes_an_isolated_failure_verdict(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scenario = root / "scenario.json"
            scenario.write_text(json.dumps({
                "random_seed": 4242,
                "expect": [{"id": "wrong_deaths", "metric": "summary.total_deaths", "op": "eq", "value": 1}],
            }), encoding="utf-8")
            fixture = (Path(__file__).resolve().parent / "fixtures" / "headless" / "success.jsonl").read_text(
                encoding="utf-8"
            )

            def fake_godot(command, _timeout):
                self.assertIn("--disable-crash-handler", command)
                session_arg = next(item for item in command if item.startswith("--headless-session-path="))
                session = Path(session_arg.split("=", 1)[1])
                session.write_text(fixture, encoding="utf-8")
                return HeadlessRunOutcome("completed", 123, 0,
                                          "MEADOW_RESULT_PATH=%s\n" % session, "", 0.1)

            stdout = io.StringIO()
            with mock.patch("run_scenario.run_headless_process", side_effect=fake_godot), \
                 contextlib.redirect_stdout(stdout):
                self.assertEqual(1, run_verdict_scenario(scenario, "unused", 1, 30, root / "results"))

            line = stdout.getvalue().strip()
            self.assertTrue(line.startswith("status=failed "))
            result_path = Path(line.rsplit("result=", 1)[1])
            result = json.loads(result_path.read_text(encoding="utf-8"))
            failure = json.loads((result_path.parent / "failure.json").read_text(encoding="utf-8"))
            self.assertEqual("failed", result["status"])
            self.assertEqual("product_failure", result["classification"])
            self.assertEqual(["wrong_deaths"], result["expectations"]["failed"])
            self.assertEqual({"kind": "expectation", "id": "wrong_deaths", "expected": 1, "actual": 0},
                             failure["reason"])

    def test_invalid_diagnostics_are_rejected_before_launch(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scenario = root / "scenario.json"
            scenario.write_text(json.dumps({"diagnostics": {"profile": "typo"}}), encoding="utf-8")
            with mock.patch("run_scenario.subprocess.run") as launch, contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(1, run_verdict_scenario(scenario, "unused", 1, 30, root / "results"))
            launch.assert_not_called()

    def test_script_error_is_a_compile_failure_before_zero_session_analysis(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scenario = root / "scenario.json"
            scenario.write_text(json.dumps({"random_seed": 4242}), encoding="utf-8")
            zero_session = '{"type":"summary","outcome":"actions_resolved","game_time":0,"day":0}\n'
            script_error = "SCRIPT ERROR: Parse Error: Could not resolve class \\\"Broken\\\"."
            script_path = "res://scripts/broken.gd"

            def fake_godot(command, _timeout):
                session_arg = next(item for item in command if item.startswith("--headless-session-path="))
                session = Path(session_arg.split("=", 1)[1])
                session.write_text(zero_session, encoding="utf-8")
                return HeadlessRunOutcome("completed", 123, 0,
                                          "MEADOW_RESULT_PATH=%s\n" % session,
                                          "%s\n          at: GDScript::reload (%s:1)\n" % (script_error, script_path), 0.1)

            stdout = io.StringIO()
            stderr = io.StringIO()
            with mock.patch("run_scenario.run_headless_process", side_effect=fake_godot), \
                 contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                self.assertEqual(1, run_verdict_scenario(scenario, "unused", 1, 30, root / "results"))

            result_path = Path(stdout.getvalue().strip().rsplit("result=", 1)[1])
            result = json.loads(result_path.read_text(encoding="utf-8"))
            failure = json.loads((result_path.parent / "failure.json").read_text(encoding="utf-8"))
            self.assertEqual("compile_error", result["status"])
            self.assertEqual("compile_failure", result["classification"])
            self.assertIsNone(result["outcome"])
            self.assertEqual({"kind": "compile", "message": script_error, "script": script_path}, failure["reason"])
            self.assertIn(script_error, stderr.getvalue())
            self.assertIn(script_path, stderr.getvalue())
            self.assertIn(str(result_path.parent / "process.log"), stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
