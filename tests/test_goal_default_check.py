"""Tests for tools/goal_default_check.py."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools import goal_default_check

ROOT = Path(__file__).resolve().parent.parent


class TestGoalDefaultCheck(unittest.TestCase):
    def test_repo_challenge_stages_pass(self) -> None:
        """The real repo challenge_stages.gd must have explicit: true on designation conditions."""
        problems = goal_default_check.check_file(ROOT / "scripts" / "challenge_stages.gd")
        self.assertEqual(problems, [], f"Unexpected problems in repo: {problems}")

    def test_cli_main_passes_on_repo(self) -> None:
        """main() returns 0 when run on the default repository files."""
        self.assertEqual(goal_default_check.main([]), 0)

    def test_missing_file_reports_error(self) -> None:
        """Nonexistent file passed to check_file returns problem line."""
        problems = goal_default_check.check_file(Path("scripts/nonexistent_stages_file.gd"))
        self.assertTrue(any("does not exist" in p for p in problems))

    def test_cell_count_without_designated_is_allowed(self) -> None:
        """A cell_count condition that only checks count or content without designation is fine."""
        content = (
            'const STAGES := [{\n'
            '    "id": "1.5",\n'
            '    "condition": {"cell_count": {"at_least": 1}}\n'
            '}]\n'
        )
        problems = goal_default_check.check_content(content, "test.gd")
        self.assertEqual(problems, [])

    def test_cell_count_with_designated_and_explicit_passes(self) -> None:
        """A cell_count condition with designated and 'explicit: true' passes."""
        content = (
            'const STAGES := [{\n'
            '    "id": "1.13",\n'
            '    "condition": {"cell_count": {"designated": "pollen", "explicit": true, "at_least": 1}}\n'
            '}]\n'
        )
        problems = goal_default_check.check_content(content, "test.gd")
        self.assertEqual(problems, [])

    def test_mutation_omitting_explicit_fails(self) -> None:
        """A cell_count condition with designated but lacking 'explicit: true' is flagged."""
        # Mutation: like stage 1.13 before the fix
        content = (
            'const STAGES := [{\n'
            '    "id": "1.13",\n'
            '    "condition": {"cell_count": {"designated": "pollen", "at_least": 1}}\n'
            '}]\n'
        )
        problems = goal_default_check.check_content(content, "test.gd")
        self.assertEqual(len(problems), 1)
        self.assertIn("cell_count specifies 'designated' without '\"explicit\": true'", problems[0])
        self.assertIn("test.gd:3", problems[0])

    def test_mutation_explicit_false_fails(self) -> None:
        """Setting 'explicit: false' when matching designated is also flagged."""
        content = (
            'const STAGES := [{\n'
            '    "id": "1.13",\n'
            '    "condition": {"cell_count": {"designated": "pollen", "explicit": false, "at_least": 1}}\n'
            '}]\n'
        )
        problems = goal_default_check.check_content(content, "test.gd")
        self.assertEqual(len(problems), 1)
        self.assertIn("cell_count specifies 'designated' without '\"explicit\": true'", problems[0])

    def test_comments_and_strings_ignored(self) -> None:
        """Comments mentioning unguarded patterns are ignored."""
        content = (
            '# Note: "cell_count": {"designated": "pollen"}\n'
            'const STAGES := [{\n'
            '    "id": "1.13",\n'
            '    "condition": {"cell_count": {"designated": "pollen", "explicit": true, "at_least": 1}}\n'
            '}]\n'
        )
        problems = goal_default_check.check_content(content, "test.gd")
        self.assertEqual(problems, [])

    def test_cli_on_temporary_file(self) -> None:
        """CLI main() fails with exit code 1 when bad file is passed."""
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_file = Path(tmpdir) / "bad_stages.gd"
            bad_file.write_text(
                'const S = [{"condition": {"cell_count": {"designated": "nectar"}}}]',
                encoding="utf-8",
            )
            self.assertEqual(goal_default_check.main([str(bad_file)]), 1)


if __name__ == "__main__":
    unittest.main()
