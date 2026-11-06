#!/usr/bin/env python3
"""Unit tests for tools/check_scenarios.py."""

from __future__ import annotations

import io
import json
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

from tools.check_scenarios import (
    ROOT,
    check_all_scenarios,
    check_scenario_file,
    derive_verbs,
    main,
    parse_execute_arms,
)


class TestCheckScenarios(unittest.TestCase):
    def test_real_tree_passes(self) -> None:
        """The real repo test scenarios pass cleanly with zero findings."""
        problems = check_all_scenarios(ROOT)
        self.assertEqual(problems, [])

    def test_derived_verbs_contain_required_set(self) -> None:
        """The derived set includes assert, wait, settle, and set_bee_stats."""
        verbs = derive_verbs(ROOT)
        self.assertIn("assert", verbs)
        self.assertIn("wait", verbs)
        self.assertIn("settle", verbs)
        self.assertIn("set_bee_stats", verbs)

    def test_derived_verbs_count_matches_arms_plus_three(self) -> None:
        """The derived set size equals the _execute arm count plus three, computed not literal."""
        script_text = (ROOT / "scripts" / "scenario_actions.gd").read_text(encoding="utf-8")
        arms = parse_execute_arms(script_text)
        verbs = derive_verbs(ROOT)
        expected_size = len(set(arms)) + 3
        self.assertEqual(len(verbs), expected_size)

    def test_fixture_misspelt_verb_fails(self) -> None:
        """A temporary fixture with misspelt verb 'mine_queue' fails with file and action index."""
        verbs = derive_verbs(ROOT)
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir) / "test_misspelt.json"
            data = {
                "name": "misspelt_scenario",
                "actions": [
                    {"do": "wait", "seconds": 1.0},
                    {"do": "mine_queue", "target": "soil"},
                ],
            }
            tmp_path.write_text(json.dumps(data), encoding="utf-8")
            problems = check_scenario_file(tmp_path, verbs)
            self.assertEqual(len(problems), 1)
            self.assertIn("action 1", problems[0])
            self.assertIn("unknown 'do' verb 'mine_queue'", problems[0])
            self.assertIn(str(tmp_path), problems[0])

    def test_fixture_missing_do_fails(self) -> None:
        """A temporary fixture with an action missing 'do' fails with file and action index."""
        verbs = derive_verbs(ROOT)
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir) / "test_missing_do.json"
            data = {
                "name": "missing_do_scenario",
                "actions": [
                    {"seconds": 2.0},
                ],
            }
            tmp_path.write_text(json.dumps(data), encoding="utf-8")
            problems = check_scenario_file(tmp_path, verbs)
            self.assertEqual(len(problems), 1)
            self.assertIn("action 0", problems[0])
            self.assertIn("missing 'do' verb", problems[0])
            self.assertIn(str(tmp_path), problems[0])

    def test_fixture_numeric_do_fails(self) -> None:
        """A temporary fixture with a numeric 'do' fails with file and action index."""
        verbs = derive_verbs(ROOT)
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir) / "test_numeric_do.json"
            data = {
                "name": "numeric_do_scenario",
                "actions": [
                    {"do": 1234},
                ],
            }
            tmp_path.write_text(json.dumps(data), encoding="utf-8")
            problems = check_scenario_file(tmp_path, verbs)
            self.assertEqual(len(problems), 1)
            self.assertIn("action 0", problems[0])
            self.assertIn("'do' verb is not a string", problems[0])
            self.assertIn(str(tmp_path), problems[0])

    def test_cli_list_option(self) -> None:
        """CLI --list prints derived verbs, one per line."""
        out = io.StringIO()
        err = io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = main(["--list"])
        self.assertEqual(code, 0)
        lines = [line.strip() for line in out.getvalue().splitlines() if line.strip()]
        verbs = derive_verbs(ROOT)
        self.assertEqual(set(lines), verbs)
        self.assertEqual(lines, sorted(verbs))

    def test_cli_runs_cleanly(self) -> None:
        """CLI main() runs cleanly on repo root."""
        out = io.StringIO()
        err = io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = main([])
        self.assertEqual(code, 0)
        self.assertIn("all action verbs recognised", out.getvalue())


if __name__ == "__main__":
    unittest.main()
