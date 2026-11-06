"""Unit tests for tools/check_scenarios.py."""

from __future__ import annotations

import io
import json
import re
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import check_scenarios  # noqa: E402


class TestCheckScenarios(unittest.TestCase):
    """Test suite for check_scenarios.py tool."""

    def test_real_repo_scenarios_pass(self) -> None:
        """The real tree on origin/master passes check_scenarios cleanly."""
        recognised_verbs, problems = check_scenarios.check_repo(ROOT)
        self.assertGreater(len(recognised_verbs), 0)
        self.assertEqual(problems, [], f"Unexpected scenario problems found: {problems}")

    def test_main_cli_success(self) -> None:
        """Invoking main() with default args succeeds with code 0."""
        out = io.StringIO()
        with redirect_stdout(out):
            code = check_scenarios.main([])
        self.assertEqual(code, 0)
        self.assertIn("clean", out.getvalue())

    def test_main_cli_list(self) -> None:
        """Invoking main(['--list']) prints all derived verbs one per line."""
        out = io.StringIO()
        with redirect_stdout(out):
            code = check_scenarios.main(["--list"])
        self.assertEqual(code, 0)
        lines = [line.strip() for line in out.getvalue().splitlines() if line.strip()]
        for expected in ("assert", "wait", "settle", "set_bee_stats", "queue_mine"):
            self.assertIn(expected, lines)

    def test_derived_verbs_contain_required_verbs(self) -> None:
        """The derived verb set contains assert, wait, settle, and set_bee_stats."""
        actions_script = ROOT / "scripts" / "scenario_actions.gd"
        verbs = check_scenarios.derive_recognised_verbs(actions_script)
        for req in ("assert", "wait", "settle", "set_bee_stats"):
            self.assertIn(req, verbs)

    def test_derived_verbs_size_equals_execute_arms_plus_three(self) -> None:
        """The derived verb set's size equals _execute arm count plus 3 computed, not literal."""
        actions_script = ROOT / "scripts" / "scenario_actions.gd"
        content = actions_script.read_text(encoding="utf-8")
        execute_arms = check_scenarios.extract_execute_verbs(content)
        verbs = check_scenarios.derive_recognised_verbs(actions_script)
        # Sequence verbs: assert, wait, settle (3)
        self.assertEqual(len(verbs), len(execute_arms) + 3)

    def test_fixture_unknown_verb_fails(self) -> None:
        """A fixture with an unknown verb (such as 'mine_queue') fails with file and action index."""
        recognised_verbs = {"assert", "wait", "settle", "queue_mine"}
        with tempfile.TemporaryDirectory() as tmpdir:
            file_path = Path(tmpdir) / "test_unknown.json"
            bad_data = {
                "name": "Bad Verb Scenario",
                "actions": [
                    {"do": "wait", "seconds": 1.0},
                    {"do": "mine_queue", "target": "comb"},
                ],
            }
            file_path.write_text(json.dumps(bad_data), encoding="utf-8")

            problems = check_scenarios.check_scenario_file(file_path, recognised_verbs)
            self.assertEqual(len(problems), 1)
            self.assertIn(str(file_path), problems[0])
            self.assertIn("actions[1]", problems[0])
            self.assertIn("unknown 'do' verb 'mine_queue'", problems[0])

    def test_fixture_missing_do_fails(self) -> None:
        """A fixture with an action missing 'do' fails with file and action index."""
        recognised_verbs = {"assert", "wait", "settle", "queue_mine"}
        with tempfile.TemporaryDirectory() as tmpdir:
            file_path = Path(tmpdir) / "test_no_do.json"
            bad_data = {
                "name": "No Do Scenario",
                "actions": [
                    {"not_a_do": "wait", "seconds": 1.0},
                ],
            }
            file_path.write_text(json.dumps(bad_data), encoding="utf-8")

            problems = check_scenarios.check_scenario_file(file_path, recognised_verbs)
            self.assertEqual(len(problems), 1)
            self.assertIn(str(file_path), problems[0])
            self.assertIn("actions[0]", problems[0])
            self.assertIn("missing 'do' field", problems[0])

    def test_fixture_numeric_do_fails(self) -> None:
        """A fixture with a numeric 'do' fails with file and action index."""
        recognised_verbs = {"assert", "wait", "settle", "queue_mine"}
        with tempfile.TemporaryDirectory() as tmpdir:
            file_path = Path(tmpdir) / "test_numeric_do.json"
            bad_data = {
                "name": "Numeric Do Scenario",
                "actions": [
                    {"do": 12345},
                ],
            }
            file_path.write_text(json.dumps(bad_data), encoding="utf-8")

            problems = check_scenarios.check_scenario_file(file_path, recognised_verbs)
            self.assertEqual(len(problems), 1)
            self.assertIn(str(file_path), problems[0])
            self.assertIn("actions[0]", problems[0])
            self.assertIn("non-string 'do' value", problems[0])

    def test_nested_action_failures_reported_with_index(self) -> None:
        """Nested actions (e.g. inside a sub-structure) are walked and reported."""
        recognised_verbs = {"assert", "wait", "settle"}
        with tempfile.TemporaryDirectory() as tmpdir:
            file_path = Path(tmpdir) / "test_nested.json"
            nested_data = {
                "sequence": {
                    "actions": [
                        {"do": "wait"},
                        {"do": "invalid_nested_verb"},
                    ]
                }
            }
            file_path.write_text(json.dumps(nested_data), encoding="utf-8")

            problems = check_scenarios.check_scenario_file(file_path, recognised_verbs)
            self.assertEqual(len(problems), 1)
            self.assertIn("sequence.actions[1]", problems[0])
            self.assertIn("invalid_nested_verb", problems[0])

    def test_non_dict_action_element_reported(self) -> None:
        """An action element that is not a dictionary is reported with index."""
        recognised_verbs = {"assert"}
        with tempfile.TemporaryDirectory() as tmpdir:
            file_path = Path(tmpdir) / "test_bad_type.json"
            bad_data = {
                "actions": [
                    "string_action_not_dict",
                ]
            }
            file_path.write_text(json.dumps(bad_data), encoding="utf-8")

            problems = check_scenarios.check_scenario_file(file_path, recognised_verbs)
            self.assertEqual(len(problems), 1)
            self.assertIn("actions[0]", problems[0])
            self.assertIn("action is not a dictionary", problems[0])


if __name__ == "__main__":
    unittest.main()
