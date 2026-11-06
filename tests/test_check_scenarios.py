"""Unit tests for tools/check_scenarios.py."""

from __future__ import annotations

import io
import json
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

import check_scenarios  # noqa: E402


class CheckScenariosTest(unittest.TestCase):
    def test_derived_verbs_contract(self) -> None:
        """The derived verb set matches computed size and expected verbs."""
        text = check_scenarios.SCENARIO_ACTIONS_PATH.read_text(encoding="utf-8")
        arms = check_scenarios.extract_execute_arms(text)
        verbs = check_scenarios.derive_verbs(check_scenarios.SCENARIO_ACTIONS_PATH)

        # Derived set includes assert, wait, settle, set_bee_stats
        self.assertIn("assert", verbs)
        self.assertIn("wait", verbs)
        self.assertIn("settle", verbs)
        self.assertIn("set_bee_stats", verbs)

        # Derived set's size equals _execute arm count plus three, as a computed figure
        self.assertEqual(len(verbs), len(arms) + 3)

    def test_real_tree_passes(self) -> None:
        """The real repository scenario tree passes with zero findings."""
        buf_out, buf_err = io.StringIO(), io.StringIO()
        with redirect_stdout(buf_out), redirect_stderr(buf_err):
            ret = check_scenarios.main([])
        self.assertEqual(ret, 0, f"STDOUT: {buf_out.getvalue()}\nSTDERR: {buf_err.getvalue()}")
        self.assertIn("all action verbs valid", buf_out.getvalue())

    def test_cli_list_flag(self) -> None:
        """Passing --list outputs the derived verbs, one per line."""
        buf = io.StringIO()
        with redirect_stdout(buf):
            ret = check_scenarios.main(["--list"])
        self.assertEqual(ret, 0)
        lines = [line.strip() for line in buf.getvalue().splitlines() if line.strip()]
        verbs = check_scenarios.derive_verbs(check_scenarios.SCENARIO_ACTIONS_PATH)
        self.assertEqual(set(lines), verbs)

    def test_negative_fixture_unknown_verb(self) -> None:
        """A fixture with an unknown verb like 'mine_queue' fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_path = Path(tmpdir) / "bad_verb.json"
            temp_path.write_text(
                json.dumps({"actions": [{"do": "mine_queue"}]}), encoding="utf-8"
            )
            verbs = check_scenarios.derive_verbs(check_scenarios.SCENARIO_ACTIONS_PATH)
            problems = check_scenarios.check_scenario_file(temp_path, verbs, root=Path(tmpdir))
            self.assertTrue(any("unknown 'do' verb 'mine_queue'" in p for p in problems))

    def test_negative_fixture_missing_do(self) -> None:
        """A fixture with an action missing the 'do' field fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_path = Path(tmpdir) / "missing_do.json"
            temp_path.write_text(
                json.dumps({"actions": [{"target": "honey"}]}), encoding="utf-8"
            )
            verbs = check_scenarios.derive_verbs(check_scenarios.SCENARIO_ACTIONS_PATH)
            problems = check_scenarios.check_scenario_file(temp_path, verbs, root=Path(tmpdir))
            self.assertTrue(any("missing required 'do' field" in p for p in problems))

    def test_negative_fixture_numeric_do(self) -> None:
        """A fixture with a numeric 'do' field fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_path = Path(tmpdir) / "numeric_do.json"
            temp_path.write_text(
                json.dumps({"actions": [{"do": 42}]}), encoding="utf-8"
            )
            verbs = check_scenarios.derive_verbs(check_scenarios.SCENARIO_ACTIONS_PATH)
            problems = check_scenarios.check_scenario_file(temp_path, verbs, root=Path(tmpdir))
            self.assertTrue(any("has non-string 'do' verb 42" in p for p in problems))


if __name__ == "__main__":
    unittest.main()
