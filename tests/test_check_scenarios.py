"""Unit tests for tools/check_scenarios.py."""

from __future__ import annotations

import io
import json
import re
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import check_scenarios  # noqa: E402


class TestCheckScenarios(unittest.TestCase):
    def test_real_tree_passes(self):
        """The real tree of scenarios must pass with zero findings."""
        files = check_scenarios.find_scenario_files(ROOT)
        self.assertGreater(len(files), 0, "Expected scenario files in test_scenarios/")
        verbs = check_scenarios.derive_recognised_verbs()
        errors = check_scenarios.check_all_scenarios(files, verbs)
        self.assertEqual(errors, [], f"Unexpected errors on real scenarios: {errors}")

    def test_main_cli_passes_on_repo(self):
        """tools/check_scenarios.py exits 0 when run on the repo."""
        code = check_scenarios.main([])
        self.assertEqual(code, 0)

    def test_derived_verbs_contain_required_members(self):
        """The derived set must include assert, wait, settle, and set_bee_stats."""
        verbs = check_scenarios.derive_recognised_verbs()
        for v in ("assert", "wait", "settle", "set_bee_stats"):
            self.assertIn(v, verbs)

    def test_derived_set_size_equals_execute_arms_plus_three(self):
        """The derived set size equals the _execute arm count plus three, computed dynamically."""
        harness_text = (ROOT / "scripts" / "scenario_actions.gd").read_text(encoding="utf-8")
        arms = check_scenarios.extract_execute_arms(harness_text)
        expected_size = len(arms) + 3
        verbs = check_scenarios.derive_recognised_verbs()
        self.assertEqual(len(verbs), expected_size)

    def test_cli_list_option(self):
        """Running with --list outputs derived verbs, one per line."""
        out = io.StringIO()
        with redirect_stdout(out):
            code = check_scenarios.main(["--list"])
        self.assertEqual(code, 0)
        output_verbs = set(out.getvalue().splitlines())
        expected_verbs = check_scenarios.derive_recognised_verbs()
        self.assertEqual(output_verbs, expected_verbs)

    def test_fixture_with_unknown_verb_fails(self):
        """A scenario fixture with unknown verb 'mine_queue' fails reporting file and action index."""
        bad_scenario = {
            "actions": [
                {"do": "assign_role", "role": "builder"},
                {"do": "mine_queue", "target": [1, 2]},
            ]
        }
        with tempfile.TemporaryDirectory() as tmpdir:
            f = Path(tmpdir) / "bad_verb.json"
            f.write_text(json.dumps(bad_scenario), encoding="utf-8")
            verbs = check_scenarios.derive_recognised_verbs()
            errors = check_scenarios.check_scenario_file(f, verbs)
            self.assertEqual(len(errors), 1)
            self.assertIn(f"{f}:1: unknown verb 'mine_queue'", errors[0])

    def test_fixture_with_missing_do_fails(self):
        """A scenario fixture with missing 'do' verb fails reporting file and action index."""
        bad_scenario = {
            "actions": [
                {"when": {"day_at_least": 1}},
            ]
        }
        with tempfile.TemporaryDirectory() as tmpdir:
            f = Path(tmpdir) / "missing_do.json"
            f.write_text(json.dumps(bad_scenario), encoding="utf-8")
            verbs = check_scenarios.derive_recognised_verbs()
            errors = check_scenarios.check_scenario_file(f, verbs)
            self.assertEqual(len(errors), 1)
            self.assertIn(f"{f}:0: missing 'do' verb", errors[0])

    def test_fixture_with_numeric_do_fails(self):
        """A scenario fixture with a numeric 'do' verb fails reporting file and action index."""
        bad_scenario = {
            "actions": [
                {"do": 123},
            ]
        }
        with tempfile.TemporaryDirectory() as tmpdir:
            f = Path(tmpdir) / "numeric_do.json"
            f.write_text(json.dumps(bad_scenario), encoding="utf-8")
            verbs = check_scenarios.derive_recognised_verbs()
            errors = check_scenarios.check_scenario_file(f, verbs)
            self.assertEqual(len(errors), 1)
            self.assertIn(f"{f}:0: non-string 'do' verb", errors[0])

    def test_nested_actions_checked(self):
        """Actions nested inside inner objects are also checked and report their index."""
        nested = {
            "sub": {
                "actions": [
                    {"do": "invalid_nested_verb"}
                ]
            }
        }
        with tempfile.TemporaryDirectory() as tmpdir:
            f = Path(tmpdir) / "nested.json"
            f.write_text(json.dumps(nested), encoding="utf-8")
            verbs = check_scenarios.derive_recognised_verbs()
            errors = check_scenarios.check_scenario_file(f, verbs)
            self.assertEqual(len(errors), 1)
            self.assertIn(f"{f}:0: unknown verb 'invalid_nested_verb'", errors[0])


if __name__ == "__main__":
    unittest.main()
