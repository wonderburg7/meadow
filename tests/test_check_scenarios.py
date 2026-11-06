"""Unit tests for tools/check_scenarios.py."""

from __future__ import annotations

import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from tools.check_scenarios import (
    ROOT,
    SCENARIO_ACTIONS_PATH,
    check_file,
    derive_verbs,
    extract_execute_arms,
    find_scenario_files,
    main,
    validate_scenario_data,
    walk_actions,
)


class TestCheckScenarios(unittest.TestCase):
    def test_real_tree_passes(self) -> None:
        """The real scenario tree must pass with zero findings."""
        valid_verbs = derive_verbs()
        files = find_scenario_files()
        self.assertGreater(len(files), 100)

        problems: list[str] = []
        for f in files:
            problems.extend(check_file(f, valid_verbs))
        self.assertEqual(problems, [], f"Real tree had unexpected errors: {problems}")

    def test_derived_verbs_contract(self) -> None:
        """The derived set includes assert, wait, settle, set_bee_stats, and matches arms + 3."""
        valid_verbs = derive_verbs()
        self.assertIn("assert", valid_verbs)
        self.assertIn("wait", valid_verbs)
        self.assertIn("settle", valid_verbs)
        self.assertIn("set_bee_stats", valid_verbs)

        source_text = SCENARIO_ACTIONS_PATH.read_text(encoding="utf-8")
        arms = extract_execute_arms(source_text)
        expected_size = len(arms) + 3
        self.assertEqual(len(valid_verbs), expected_size)

    def test_fixture_misspelt_verb_fails(self) -> None:
        """A fixture with misspelt verb 'mine_queue' must fail with file and action index."""
        valid_verbs = derive_verbs()
        with tempfile.TemporaryDirectory() as tmpdir:
            fix_path = Path(tmpdir) / "test_misspelt.json"
            fix_path.write_text(
                json.dumps({
                    "cells": 10,
                    "actions": [
                        {"do": "assign_role", "role": "builder"},
                        {"do": "mine_queue", "target": [0, 0]},
                    ]
                }),
                encoding="utf-8",
            )
            problems = check_file(fix_path, valid_verbs)
            self.assertEqual(len(problems), 1)
            self.assertIn("actions[1]", problems[0])
            self.assertIn("unknown verb 'mine_queue'", problems[0])
            self.assertIn(fix_path.name, problems[0])

    def test_fixture_missing_do_fails(self) -> None:
        """A fixture with missing 'do' field must fail with file and action index."""
        valid_verbs = derive_verbs()
        with tempfile.TemporaryDirectory() as tmpdir:
            fix_path = Path(tmpdir) / "test_missing_do.json"
            fix_path.write_text(
                json.dumps({
                    "actions": [
                        {"when": {"day": 1}, "target": [1, 2]}
                    ]
                }),
                encoding="utf-8",
            )
            problems = check_file(fix_path, valid_verbs)
            self.assertEqual(len(problems), 1)
            self.assertIn("actions[0]", problems[0])
            self.assertIn("missing 'do' field", problems[0])

    def test_fixture_numeric_do_fails(self) -> None:
        """A fixture with numeric 'do' field must fail with file and action index."""
        valid_verbs = derive_verbs()
        with tempfile.TemporaryDirectory() as tmpdir:
            fix_path = Path(tmpdir) / "test_numeric_do.json"
            fix_path.write_text(
                json.dumps({
                    "actions": [
                        {"do": 12345}
                    ]
                }),
                encoding="utf-8",
            )
            problems = check_file(fix_path, valid_verbs)
            self.assertEqual(len(problems), 1)
            self.assertIn("actions[0]", problems[0])
            self.assertIn("'do' field must be a string", problems[0])

    def test_nested_actions_checked(self) -> None:
        """Nested action lists within action dictionaries are recursively checked."""
        valid_verbs = derive_verbs()
        data = {
            "actions": [
                {
                    "do": "assign_role",
                    "actions": [
                        {"do": "invalid_nested_verb"}
                    ]
                }
            ]
        }
        problems = validate_scenario_data(data, "dummy.json", valid_verbs)
        self.assertEqual(len(problems), 1)
        self.assertIn("actions[0].actions[0]", problems[0])
        self.assertIn("unknown verb 'invalid_nested_verb'", problems[0])

    def test_cli_list_option(self) -> None:
        """CLI --list prints derived verbs one per line and returns 0."""
        out = io.StringIO()
        with redirect_stdout(out):
            ret = main(["--list"])
        self.assertEqual(ret, 0)
        lines = [line.strip() for line in out.getvalue().splitlines() if line.strip()]
        self.assertIn("assert", lines)
        self.assertIn("wait", lines)
        self.assertIn("settle", lines)
        self.assertIn("set_bee_stats", lines)
        self.assertEqual(len(lines), len(derive_verbs()))

    def test_cli_execution_success_and_failure(self) -> None:
        """CLI returns 0 on valid scenarios and 1 on errors."""
        with tempfile.TemporaryDirectory() as tmpdir:
            good_file = Path(tmpdir) / "good.json"
            good_file.write_text(json.dumps({"actions": [{"do": "wait", "seconds": 1}]}))
            bad_file = Path(tmpdir) / "bad.json"
            bad_file.write_text(json.dumps({"actions": [{"do": "bad_verb"}]}))

            self.assertEqual(main([str(good_file)]), 0)
            self.assertEqual(main([str(bad_file)]), 1)


if __name__ == "__main__":
    unittest.main()
