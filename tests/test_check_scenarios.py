"""Unit tests for tools/check_scenarios.py.

Verifies:
- The real scenario tree passes with zero findings.
- Temporary fixtures with misspelt verb ('mine_queue'), missing 'do', and numeric 'do' each fail.
- The derived set includes 'assert', 'wait', 'settle' and 'set_bee_stats'.
- The derived set's size equals the _execute arm count plus three, as a computed figure, not a literal.
- CLI flags such as --list print derived verbs.
- The derived set follows source changes (renamed, added and removed verbs),
  ignores comments and formatting, and nested bad actions fail without bypass.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from tools.check_scenarios import (
    check_scenario_file,
    derive_recognised_verbs,
    extract_execute_arms,
    extract_sequence_verbs,
)

ACTIONS_GD = Path("scripts/scenario_actions.gd")


def _derived(text: str) -> set[str]:
    return set(extract_execute_arms(text)) | set(extract_sequence_verbs(text))


class TestCheckScenarios(unittest.TestCase):
    def test_derived_verbs_contain_required_verbs(self) -> None:
        verbs = derive_recognised_verbs("scripts/scenario_actions.gd")
        for expected in ("assert", "wait", "settle", "set_bee_stats"):
            self.assertIn(expected, verbs, f"Expected {expected} in derived verbs")

    def test_derived_set_size_equals_execute_arms_plus_three(self) -> None:
        """Counted by a separate, cruder reading of the source than the extractor's."""
        text = ACTIONS_GD.read_text(encoding="utf-8")
        execute = text.split("static func _execute(", 1)[1].split("\nstatic func ", 1)[0]
        arm_count = len(set(re.findall(r'^\t\t"(\w+)":$', execute, re.MULTILINE)))
        pending = text.split("static func run_pending(", 1)[1].split("\nstatic func ", 1)[0]
        sequence = set(re.findall(r'get\("do", ""\) == "(\w+)"', pending))
        self.assertEqual(sequence, {"assert", "wait", "settle"})
        verbs = derive_recognised_verbs(ACTIONS_GD)
        self.assertEqual(len(verbs), arm_count + len(sequence))

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

    # --- source mutations (jules-review-2026-11-07 F2) ---

    def _source(self) -> str:
        return ACTIONS_GD.read_text(encoding="utf-8")

    def _mutate(self, old: str, new: str) -> str:
        text = self._source()
        self.assertIn(old, text, "mutation target missing from the real source")
        return text.replace(old, new, 1)

    def test_renamed_sequence_verb_follows_the_source(self) -> None:
        verbs = _derived(self._source().replace('"settle"', '"rest"'))
        self.assertIn("rest", verbs)
        self.assertNotIn("settle", verbs)

    def test_new_sequence_comparison_is_recognised(self) -> None:
        verbs = _derived(self._mutate(
            '\t\tif action.get("do", "") == "wait":',
            '\t\tif "pause" == action.get("do", ""):\n\t\t\tcontinue\n'
            '\t\tif action.get("do", "") == "wait":',
        ))
        self.assertIn("pause", verbs)

    def test_removed_arm_is_no_longer_recognised(self) -> None:
        verbs = _derived(self._mutate(
            '\t\t"queue_mine":\n\t\t\t_do_queue_mine(main, action)\n', ""
        ))
        self.assertNotIn("queue_mine", verbs)
        with tempfile.TemporaryDirectory() as tmpdir:
            fixture = Path(tmpdir) / "uses_removed.json"
            fixture.write_text(json.dumps({"actions": [{"do": "queue_mine"}]}), encoding="utf-8")
            errs = check_scenario_file(fixture, verbs)
        self.assertTrue(any("unknown verb 'queue_mine'" in e for e in errs), errs)

    def test_multi_pattern_and_guarded_arms(self) -> None:
        verbs = _derived(self._mutate(
            '\t\t"keep_role":',
            '\t\t"alpha", "beta":\n\t\t\tpass\n'
            '\t\t"gamma" when action.has("x"):\n\t\t\tpass\n'
            '\t\t"keep_role":',
        ))
        self.assertLessEqual({"alpha", "beta", "gamma", "keep_role"}, verbs)

    def test_formatting_does_not_change_the_derived_set(self) -> None:
        baseline = _derived(self._source())
        blank = self._mutate(
            '\tmatch action.get("do", ""):\n', '\tmatch action.get("do", ""):\n\n'
        )
        self.assertEqual(_derived(blank), baseline)
        commented = self._mutate(
            '\t\t"keep_role":', '# column-zero comment\n\n\t\t"keep_role":'
        ).replace(
            '\t\tif action.get("do", "") == "assert":',
            '# column-zero comment\n\t\tif action.get("do", "") == "assert":',
            1,
        )
        self.assertEqual(_derived(commented), baseline)

    def test_commented_out_verbs_are_not_recognised(self) -> None:
        text = self._mutate(
            '\t\t"keep_role":',
            '\t\t#"ghost_arm":\n# "ghost_col0":\n\t\t"keep_role":',
        ).replace(
            '\t\tif action.get("do", "") == "wait":',
            '\t\t# if action.get("do", "") == "ghost_seq":\n'
            '\t\tif action.get("do", "") == "wait":',
            1,
        )
        verbs = _derived(text)
        self.assertEqual(verbs & {"ghost_arm", "ghost_col0", "ghost_seq"}, set())
        self.assertEqual(verbs, _derived(self._source()))

    def test_nested_bad_actions_fail_without_bypass(self) -> None:
        verbs = derive_recognised_verbs(ACTIONS_GD)
        data = {
            "actions": [{"do": "wait", "days": 1}],
            "cases": [{"actions": [
                {"do": "settle"},
                {"do": "mine_queue", "disabled": True},
                {"do": 7, "mock": True},
                {"_comment": "no verb"},
            ]}],
        }
        with tempfile.TemporaryDirectory() as tmpdir:
            fixture = Path(tmpdir) / "nested.json"
            fixture.write_text(json.dumps(data), encoding="utf-8")
            errs = check_scenario_file(fixture, verbs)
        self.assertEqual(len(errs), 3, errs)
        self.assertTrue(any("cases[0].actions[1]" in e and "mine_queue" in e for e in errs), errs)
        self.assertTrue(any("cases[0].actions[2]" in e and "not a string" in e for e in errs), errs)
        self.assertTrue(any("cases[0].actions[3]" in e and "missing 'do'" in e for e in errs), errs)


if __name__ == "__main__":
    unittest.main()
