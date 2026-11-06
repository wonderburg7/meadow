"""Unit tests for tools/check_scenarios.py."""

from __future__ import annotations

import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.check_scenarios import (
    check_scenario_file,
    check_scenarios,
    derive_execute_arms,
    derive_verbs,
    main,
)


class TestCheckScenarios(unittest.TestCase):
    def test_real_tree_passes(self) -> None:
        count, findings = check_scenarios()
        self.assertGreater(count, 0)
        self.assertEqual(findings, [])

    def test_fixture_with_mine_queue_fails(self) -> None:
        verbs = derive_verbs()
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_file = Path(tmpdir) / "bad_mine_queue.json"
            bad_file.write_text(
                json.dumps({"actions": [{"do": "mine_queue", "target": [0, 0]}]}),
                encoding="utf-8",
            )
            findings = check_scenario_file(bad_file, verbs)
            self.assertTrue(any("unknown 'do' verb: 'mine_queue'" in f for f in findings))
            self.assertTrue(any("action 0" in f for f in findings))

    def test_fixture_with_no_do_fails(self) -> None:
        verbs = derive_verbs()
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_file = Path(tmpdir) / "missing_do.json"
            bad_file.write_text(
                json.dumps({"actions": [{"target": [0, 0]}]}),
                encoding="utf-8",
            )
            findings = check_scenario_file(bad_file, verbs)
            self.assertTrue(any("missing 'do' field" in f for f in findings))
            self.assertTrue(any("action 0" in f for f in findings))

    def test_fixture_with_numeric_do_fails(self) -> None:
        verbs = derive_verbs()
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_file = Path(tmpdir) / "numeric_do.json"
            bad_file.write_text(
                json.dumps({"actions": [{"do": 123}]}),
                encoding="utf-8",
            )
            findings = check_scenario_file(bad_file, verbs)
            self.assertTrue(any("'do' field is not a string" in f for f in findings))
            self.assertTrue(any("action 0" in f for f in findings))

    def test_derived_set_contains_required_verbs(self) -> None:
        verbs = derive_verbs()
        for required in ("assert", "wait", "settle", "set_bee_stats"):
            self.assertIn(required, verbs)

    def test_derived_set_size_equals_execute_arms_plus_three(self) -> None:
        arms = derive_execute_arms()
        verbs = derive_verbs()
        # Computed figure, not a literal
        self.assertEqual(len(verbs), len(arms) + 3)

    def test_cli_list_output(self) -> None:
        verbs = derive_verbs()
        buf = io.StringIO()
        with patch("sys.stdout", buf):
            ret = main(["--list"])
        self.assertEqual(ret, 0)
        lines = [line.strip() for line in buf.getvalue().splitlines() if line.strip()]
        self.assertEqual(sorted(lines), sorted(verbs))


if __name__ == "__main__":
    unittest.main()
