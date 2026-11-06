"""Unit tests for pure helper functions in tools/worktree.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import worktree  # noqa: E402


class WorktreeHelpersTest(unittest.TestCase):
    def test_row_for_formats_table_row_correctly(self):
        row = worktree.row_for(
            name="task-1",
            branch="jules/task-1",
            lane="Jules",
            scope="Add helpers test",
            owner="Claude",
            plan="plans/reference/jules.md",
        )
        expected = (
            "| `.worktrees/task-1` (`jules/task-1`) | Jules | Add helpers test | Claude"
            " | in progress | none | `plans/reference/jules.md` |"
        )
        self.assertEqual(row, expected)

    def test_find_row_locates_matching_worktree_entry(self):
        ledger_text = (
            "# Header\n"
            "| Column 1 | Column 2 |\n"
            "| `.worktrees/review-wt` (`claude/review-1`) | Review | Scope A | Claude | in progress | none | `p.md` |\n"
            "| `.worktrees/jules-wt` (`jules/s-1-test`) | Jules | Scope B | Dave | in progress | none | `plans/j.md` |\n"
        )
        res = worktree.find_row(ledger_text, "review-wt")
        self.assertIsNotNone(res)
        self.assertEqual(res, (2, "claude/review-1"))

        res2 = worktree.find_row(ledger_text, "jules-wt")
        self.assertIsNotNone(res2)
        self.assertEqual(res2, (3, "jules/s-1-test"))

    def test_find_row_returns_none_when_not_found(self):
        ledger_text = (
            "# Header\n"
            "| `.worktrees/other-wt` (`branch-1`) | Review | Scope | Claude | in progress | none | `p.md` |\n"
        )
        self.assertIsNone(worktree.find_row(ledger_text, "missing-wt"))
        self.assertIsNone(worktree.find_row("", "any-wt"))

    def test_find_row_avoids_prefix_and_partial_matches(self):
        ledger_text = (
            "| `.worktrees/prefix-name-extra` (`branch-extra`) | Review | Scope | Claude | in progress | none | `p.md` |\n"
        )
        self.assertIsNone(worktree.find_row(ledger_text, "prefix-name"))


if __name__ == "__main__":
    unittest.main()
