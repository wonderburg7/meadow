"""Pure-Python contract and runner tests for headless experiment manifests."""

from __future__ import annotations

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

from headless.experiments import (  # noqa: E402
    aggregate_case_metrics,
    compose_case_scenario,
    evaluate_aggregate_expectations,
    required_metrics,
    validate_manifest,
)
from headless.verdicts import ContractError  # noqa: E402
from run_scenario import run_experiment_manifest  # noqa: E402


MANIFEST = {
    "name": "matched deaths",
    "base_scenario": "base.json",
    "seeds": [101, 202],
    "cases": {
        "on": {"config_overrides": {"predators_on": True}},
        "off": {"config_overrides": {"predators_on": False}},
    },
    "expect": [{"id": "on_not_lower", "left": "on.total_deaths.mean", "op": "gte",
                "right": "off.total_deaths.mean"}],
    "report": {"mode": "table", "metrics": ["total_deaths"]},
}


class HeadlessExperimentTest(unittest.TestCase):
    def test_manifest_allows_only_config_overlays_and_preserves_base_setup(self):
        manifest = validate_manifest(MANIFEST)
        base = {"cells": 12, "actions": [{"do": "assert"}], "config_overrides": {"old": 1}}
        composed = compose_case_scenario(base, manifest.cases["on"])
        self.assertEqual(12, composed["cells"])
        self.assertEqual(base["actions"], composed["actions"])
        self.assertEqual({"old": 1, "predators_on": True}, composed["config_overrides"])
        with self.assertRaisesRegex(ContractError, "starting-state fields"):
            validate_manifest(dict(MANIFEST, cases={"bad": {"cells": 1}}))

    def test_aggregate_expectations_use_matched_case_statistics(self):
        manifest = validate_manifest(MANIFEST)
        aggregate = aggregate_case_metrics({
            "on": [{"total_deaths": 3}, {"total_deaths": 1}],
            "off": [{"total_deaths": 0}, {"total_deaths": 1}],
        }, required_metrics(manifest))
        self.assertEqual(2.0, aggregate["on"]["total_deaths"]["mean"])
        result = evaluate_aggregate_expectations(aggregate, manifest.expectations)[0]
        self.assertTrue(result["passed"])
        self.assertEqual(2.0, result["actual"])
        self.assertEqual(0.5, result["expected"])

    def test_unknown_aggregate_paths_fail_before_launch(self):
        bad = dict(MANIFEST, expect=[{
            "id": "bad", "left": "missing.total_deaths.mean", "op": "gt", "value": 0,
        }])
        with self.assertRaisesRegex(ContractError, "case.summary_field"):
            validate_manifest(bad)

    def test_runner_keeps_per_case_seed_artefacts_and_prints_one_aggregate_result(self):
        fixture = (Path(__file__).resolve().parent / "fixtures" / "headless" / "success.jsonl").read_text(
            encoding="utf-8"
        )
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "base.json").write_text(json.dumps({"cells": 1}), encoding="utf-8")
            manifest_path = root / "experiment.json"
            manifest_path.write_text(json.dumps(MANIFEST), encoding="utf-8")
            commands: list[list[str]] = []

            def fake_godot(command, **_kwargs):
                commands.append(command)
                session_arg = next(item for item in command if item.startswith("--headless-session-path="))
                session = Path(session_arg.split("=", 1)[1])
                session.write_text(fixture, encoding="utf-8")
                return mock.Mock(returncode=0, stdout="MEADOW_RESULT_PATH=%s\n" % session, stderr="")

            stdout = io.StringIO()
            with mock.patch("run_scenario.subprocess.run", side_effect=fake_godot), \
                 contextlib.redirect_stdout(stdout):
                self.assertEqual(0, run_experiment_manifest(manifest_path, "unused", 1, 30, root / "results"))

            lines = stdout.getvalue().splitlines()
            self.assertEqual(2, len(lines))  # One terminal verdict and one requested table.
            self.assertTrue(lines[0].startswith("status=passed experiment=matched deaths "))
            result_path = Path(lines[0].rsplit("result=", 1)[1])
            result = json.loads(result_path.read_text(encoding="utf-8"))
            self.assertEqual([101, 202], [item["seed"] for item in result["cases"]["on"]])
            self.assertEqual([101, 202], [item["seed"] for item in result["cases"]["off"]])
            self.assertEqual(4, len(commands))
            self.assertEqual([101, 202, 101, 202], [
                int(next(item.split("=", 1)[1] for item in command if item.startswith("--random-seed=")))
                for command in commands
            ])
            for case in ("on", "off"):
                for run in result["cases"][case]:
                    self.assertTrue((result_path.parent / run["result"]).is_file())

    def test_invalid_manifest_does_not_launch_godot(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = root / "invalid.json"
            manifest.write_text(json.dumps({"name": "bad"}), encoding="utf-8")
            with mock.patch("run_scenario.subprocess.run") as launch, contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(1, run_experiment_manifest(manifest, "unused", 1, 30, root / "results"))
            launch.assert_not_called()

    def test_aggregate_expectation_failure_returns_nonzero(self):
        fixture = (Path(__file__).resolve().parent / "fixtures" / "headless" / "success.jsonl").read_text(
            encoding="utf-8"
        )
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "base.json").write_text(json.dumps({"cells": 1}), encoding="utf-8")
            failing = dict(MANIFEST, expect=[{
                "id": "impossible", "left": "on.total_deaths.mean", "op": "gt", "value": 0,
            }])
            manifest_path = root / "experiment.json"
            manifest_path.write_text(json.dumps(failing), encoding="utf-8")

            def fake_godot(command, **_kwargs):
                session_arg = next(item for item in command if item.startswith("--headless-session-path="))
                session = Path(session_arg.split("=", 1)[1])
                session.write_text(fixture, encoding="utf-8")
                return mock.Mock(returncode=0, stdout="MEADOW_RESULT_PATH=%s\n" % session, stderr="")

            stdout = io.StringIO()
            with mock.patch("run_scenario.subprocess.run", side_effect=fake_godot), \
                 contextlib.redirect_stdout(stdout):
                self.assertEqual(1, run_experiment_manifest(manifest_path, "unused", 1, 30, root / "results"))
            self.assertTrue(stdout.getvalue().splitlines()[0].startswith(
                "status=failed experiment=matched deaths reason=expectation "
            ))


if __name__ == "__main__":
    unittest.main()
