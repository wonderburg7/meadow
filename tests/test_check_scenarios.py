"""Unit tests for tools/check_scenarios.py.

Verifies:
- The real scenario tree passes with zero findings.
- Temporary fixtures with misspelt verb ('mine_queue'), missing 'do', and numeric 'do' each fail.
- The derived set includes 'assert', 'wait', 'settle' and 'set_bee_stats'.
- The derived set's size equals the _execute arm count plus three, as a computed figure, not a literal.
- CLI flags such as --list print derived verbs.
"""

from __future__ import annotations

import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from tools.check_scenarios import (
    check_scenario_file,
    derive_recognised_verbs,
    extract_execute_arms,
)


class TestCheckScenarios(unittest.TestCase):
    def test_derived_verbs_contain_required_verbs(self) -> None:
        verbs = derive_recognised_verbs("scripts/scenario_actions.gd")
        for expected in ("assert", "wait", "settle", "set_bee_stats"):
            self.assertIn(expected, verbs, f"Expected {expected} in derived verbs")

    def test_derived_set_size_equals_execute_arms_plus_three(self) -> None:
        text = Path("scripts/scenario_actions.gd").read_text(encoding="utf-8")
        arms = extract_execute_arms(text)
        expected_size = len(set(arms)) + 3  # computed figure, not a literal
        verbs = derive_recognised_verbs("scripts/scenario_actions.gd")
        self.assertEqual(len(verbs), expected_size)

    def test_real_tree_passes_with_zero_findings(self) -> None:
        verbs = derive_recognised_verbs("scripts/scenario_actions.gd")
        all_errors: list[str] = []
        scenario_files = sorted(Path("test_scenarios").rglob("*.json"))
        self.assertGreater(len(scenario_files), 0, "Expected scenario files in test_scenarios/")
        for scenario_file in scenario_files:
            errs = check_scenario_file(scenario_file, verbs)
            all_errors.extend(errs)
        self.assertEqual(all_errors, [], f"Expected zero findings in real tree, found: {all_errors}")

    def test_temporary_fixture_misspelt_verb_fails(self) -> None:
        verbs = derive_recognised_verbs("scripts/scenario_actions.gd")
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_file = Path(tmpdir) / "misspelt.json"
            bad_file.write_text(
                json.dumps({"actions": [{"do": "mine_queue"}]}),
                encoding="utf-8",
            )
            errs = check_scenario_file(bad_file, verbs)
            self.assertTrue(any("unknown verb 'mine_queue'" in e for e in errs), f"Expected unknown verb error: {errs}")

    def test_temporary_fixture_missing_do_fails(self) -> None:
        verbs = derive_recognised_verbs("scripts/scenario_actions.gd")
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_file = Path(tmpdir) / "missing_do.json"
            bad_file.write_text(
                json.dumps({"actions": [{"target": "bee_1"}]}),
                encoding="utf-8",
            )
            errs = check_scenario_file(bad_file, verbs)
            self.assertTrue(any("missing 'do' verb" in e for e in errs), f"Expected missing 'do' error: {errs}")

    def test_temporary_fixture_numeric_do_fails(self) -> None:
        verbs = derive_recognised_verbs("scripts/scenario_actions.gd")
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_file = Path(tmpdir) / "numeric_do.json"
            bad_file.write_text(
                json.dumps({"actions": [{"do": 123}]}),
                encoding="utf-8",
            )
            errs = check_scenario_file(bad_file, verbs)
            self.assertTrue(any("'do' verb is not a string" in e for e in errs), f"Expected non-string error: {errs}")

    def test_cli_list_flag(self) -> None:
        proc = subprocess.run(
            [sys.executable, "tools/check_scenarios.py", "--list"],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(proc.returncode, 0)
        lines = [line.strip() for line in proc.stdout.splitlines() if line.strip()]
        verbs = derive_recognised_verbs("scripts/scenario_actions.gd")
        self.assertEqual(sorted(lines), sorted(verbs))

    def test_cli_fails_on_bad_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_file = Path(tmpdir) / "bad.json"
            bad_file.write_text(
                json.dumps({"actions": [{"do": "mine_queue"}]}),
                encoding="utf-8",
            )
            proc = subprocess.run(
                [sys.executable, "tools/check_scenarios.py", str(bad_file)],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(proc.returncode, 1)
            self.assertIn("mine_queue", proc.stderr)


if __name__ == "__main__":
    unittest.main()
