"""Unit tests for tools/check_scenarios.py."""

from __future__ import annotations

import io
import json
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import check_scenarios  # noqa: E402


class CheckScenariosTests(unittest.TestCase):
    def test_real_tree_passes_with_zero_findings(self) -> None:
        """The real tree of scenarios passes with zero findings."""
        findings = check_scenarios.check_all_scenarios(ROOT / "test_scenarios")
        self.assertEqual([], findings, f"Unexpected findings on repo scenarios: {findings}")

    def test_fixture_with_unknown_verb_mine_queue_fails(self) -> None:
        """A scenario fixture with unknown verb 'mine_queue' fails with file and index."""
        with tempfile.TemporaryDirectory() as tmpdir:
            file_path = Path(tmpdir) / "bad_mine_queue.json"
            content = {
                "actions": [
                    {"do": "settle", "ticks": 2},
                    {"do": "mine_queue", "target": [0, 0]},
                ]
            }
            file_path.write_text(json.dumps(content), encoding="utf-8")
            verbs = check_scenarios.derive_recognised_verbs()
            findings = check_scenarios.check_scenario_file(file_path, verbs)
            self.assertEqual(1, len(findings))
            self.assertIn("bad_mine_queue.json", findings[0])
            self.assertIn("action [1]", findings[0])
            self.assertIn("unknown 'do' verb: 'mine_queue'", findings[0])

    def test_fixture_with_missing_do_fails(self) -> None:
        """A scenario fixture missing the 'do' verb fails with file and index."""
        with tempfile.TemporaryDirectory() as tmpdir:
            file_path = Path(tmpdir) / "missing_do.json"
            content = {
                "actions": [
                    {"target": "hive"},
                ]
            }
            file_path.write_text(json.dumps(content), encoding="utf-8")
            verbs = check_scenarios.derive_recognised_verbs()
            findings = check_scenarios.check_scenario_file(file_path, verbs)
            self.assertEqual(1, len(findings))
            self.assertIn("missing_do.json", findings[0])
            self.assertIn("action [0]", findings[0])
            self.assertIn("missing 'do' verb", findings[0])

    def test_fixture_with_numeric_do_fails(self) -> None:
        """A scenario fixture with numeric 'do' fails with file and index."""
        with tempfile.TemporaryDirectory() as tmpdir:
            file_path = Path(tmpdir) / "numeric_do.json"
            content = {
                "actions": [
                    {"do": 12345},
                ]
            }
            file_path.write_text(json.dumps(content), encoding="utf-8")
            verbs = check_scenarios.derive_recognised_verbs()
            findings = check_scenarios.check_scenario_file(file_path, verbs)
            self.assertEqual(1, len(findings))
            self.assertIn("numeric_do.json", findings[0])
            self.assertIn("action [0]", findings[0])
            self.assertIn("not a string", findings[0])

    def test_derived_verbs_include_required_verbs(self) -> None:
        """The derived verb set includes assert, wait, settle, and set_bee_stats."""
        verbs = check_scenarios.derive_recognised_verbs()
        self.assertIn("assert", verbs)
        self.assertIn("wait", verbs)
        self.assertIn("settle", verbs)
        self.assertIn("set_bee_stats", verbs)

    def test_derived_set_size_equals_execute_arms_plus_three(self) -> None:
        """The derived set's size equals _execute arm count plus three, as a computed figure."""
        source = (ROOT / "scripts" / "scenario_actions.gd").read_text(encoding="utf-8")
        arms = check_scenarios.extract_execute_arms(source)
        verbs = check_scenarios.derive_recognised_verbs()
        self.assertEqual(len(verbs), len(arms) + 3)

    def test_cli_list_flag_prints_verbs(self) -> None:
        """Running with --list prints derived verbs, one per line, and exits 0."""
        buf = io.StringIO()
        with redirect_stdout(buf):
            code = check_scenarios.main(["--list"])
        self.assertEqual(0, code)
        output = buf.getvalue().splitlines()
        verbs = check_scenarios.derive_recognised_verbs()
        self.assertEqual(sorted(verbs), output)

    def test_cli_exits_nonzero_on_findings(self) -> None:
        """CLI returns non-zero when finding violations."""
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_json = Path(tmpdir) / "test.json"
            bad_json.write_text(json.dumps({"actions": [{"do": "unknown_verb"}]}), encoding="utf-8")
            err_buf = io.StringIO()
            with redirect_stderr(err_buf):
                code = check_scenarios.main([tmpdir])
            self.assertEqual(1, code)
            self.assertIn("unknown 'do' verb", err_buf.getvalue())


if __name__ == "__main__":
    unittest.main()
