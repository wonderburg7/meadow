"""Pure-Python tests for H3's behaviour-equivalence diff, without launching Godot."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path


TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

from equivalence import DEFAULT_FIELDS, diff_results  # noqa: E402


def _result(**overrides):
    base = {
        "schema_version": 1,
        "status": "passed",
        "run_id": "aaaaaaaaaaaa",
        "scenario": {"path": "test_scenarios/example.json", "sha256": "deadbeef"},
        "seed": 4242,
        "diagnostics": {"profile": "verdict", "version": 1},
        "outcome": "actions_resolved",
        "simulated": {"seconds": 12.5, "day": 1},
        "actions": {"rejected": 0, "failed": 0, "unresolved": 0},
        "expectations": {"passed": ["queen_alive"], "failed": []},
        "process": {"exit_code": 0, "pid": 123, "execution": "completed", "wall_seconds": 1.23},
        "artefacts": {"session": "session.jsonl", "process_log": "process.log"},
    }
    for key, value in overrides.items():
        base[key] = value
    return base


class EquivalenceDiffTest(unittest.TestCase):
    def test_identical_results_have_no_differences(self):
        left = _result()
        right = _result()
        self.assertEqual([], diff_results(left, right, DEFAULT_FIELDS))

    def test_identity_only_fields_are_ignored_by_default(self):
        left = _result(run_id="one", process={"exit_code": 0, "pid": 1, "execution": "completed",
                                               "wall_seconds": 0.5})
        right = _result(run_id="two", process={"exit_code": 0, "pid": 2, "execution": "completed",
                                                "wall_seconds": 9.9})
        left["scenario"] = {"path": "/tmp/a/example.json", "sha256": "one"}
        right["scenario"] = {"path": "/tmp/b/example.json", "sha256": "two"}
        left["artefacts"] = {"session": "a.jsonl"}
        right["artefacts"] = {"session": "b.jsonl"}
        self.assertEqual([], diff_results(left, right, DEFAULT_FIELDS))

    def test_a_moved_balance_field_is_reported_and_named(self):
        left = _result()
        right = _result(outcome="queen_dead",
                         expectations={"passed": [], "failed": ["queen_alive"]})
        differences = diff_results(left, right, DEFAULT_FIELDS)
        fields = {field for field, _, _ in differences}
        self.assertIn("outcome", fields)
        self.assertIn("expectations.failed", fields)
        self.assertIn("expectations.passed", fields)
        for field, ref_value, working_value in differences:
            if field == "outcome":
                self.assertEqual("actions_resolved", ref_value)
                self.assertEqual("queen_dead", working_value)

    def test_fields_option_narrows_the_comparison(self):
        left = _result()
        # A4-shaped case: a legitimate cadence change moves timing, an
        # outcome regression moves outcome. A slice that only claims to
        # preserve "outcome" should not see the timing move it never
        # promised to preserve, but must still catch the outcome regression.
        right = _result(outcome="queen_dead", simulated={"seconds": 99.0, "day": 3})

        narrowed = diff_results(left, right, ["outcome"])
        self.assertEqual([("outcome", "actions_resolved", "queen_dead")], narrowed)

        full = diff_results(left, right, DEFAULT_FIELDS)
        self.assertIn("simulated.seconds", {field for field, _, _ in full})

    def test_missing_field_is_reported_rather_than_silently_equal(self):
        left = _result()
        right = dict(left)
        del right["diagnostics"]
        differences = diff_results(left, right, ["diagnostics.profile"])
        self.assertEqual(1, len(differences))
        field, ref_value, working_value = differences[0]
        self.assertEqual("diagnostics.profile", field)
        self.assertEqual("verdict", ref_value)
        self.assertIsNot(ref_value, working_value)


if __name__ == "__main__":
    unittest.main()
