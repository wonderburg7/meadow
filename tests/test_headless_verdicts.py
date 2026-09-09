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
from run_scenario import _suppress_windows_crash_dialogs, run_once, run_verdict_scenario  # noqa: E402


ANALYSIS = {
    "summary": {
        "outcome": "actions_resolved", "game_time": 12.5, "day": 1,
        "total_deaths": 0, "queen_alive": True, "gynes_released": 0,
    },
    "actions": {"total": 1, "problems": []},
}


class HeadlessVerdictTest(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
