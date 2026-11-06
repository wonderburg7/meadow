"""Unit tests for pure and top-level helper functions in tools/worktree.py."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

import worktree  # noqa: E402


class WorktreeHelpersTest(unittest.TestCase):
    def test_row_for(self) -> None:
        row = worktree.row_for("w1", "branch-a", "Review", "Assigned review", "Claude", "plans/review.md")
        expected = "| `.worktrees/w1` (`branch-a`) | Review | Assigned review | Claude | in progress | none | `plans/review.md` |"
        self.assertEqual(row, expected)

    def test_find_row(self) -> None:
        ledger_text = (
            "# Active workstreams\n"
            "\n"
            "| Worktree path (branch) | Lane | Scope | Owner | Status | Depends on | Plan / slice |\n"
            "| --- | --- | --- | --- | --- | --- | --- |\n"
            "| `.worktrees/first` (`claude/first`) | Review | Some scope | Claude | in progress | none | `p1.md` |\n"
            "| `.worktrees/target-tree` (`codex/branch-2`) | Jules | Target scope | Codex | in progress | none | `p2.md` |\n"
            "| `.worktrees/third` (`dave/third`) | Policy | Other | Dave | in progress | none | `p3.md` |\n"
        )
        found = worktree.find_row(ledger_text, "target-tree")
        self.assertIsNotNone(found)
        index, branch = found  # type: ignore[misc]
        self.assertEqual(index, 5)
        self.assertEqual(branch, "codex/branch-2")

        self.assertIsNone(worktree.find_row(ledger_text, "nonexistent"))
        self.assertIsNone(worktree.find_row("", "target-tree"))

    def test_ref_exists(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo = Path(tmpdir)
            subprocess.run(["git", "init", "-q", "-b", "master", str(repo)], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.com"], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.name", "Test"], check=True)

            self.assertFalse(worktree.ref_exists(repo, "refs/heads/master"))

            dummy_file = repo / "README.md"
            dummy_file.write_text("test\n", encoding="utf-8")
            subprocess.run(["git", "-C", str(repo), "add", "README.md"], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-q", "-m", "init"], check=True)

            self.assertTrue(worktree.ref_exists(repo, "refs/heads/master"))
            self.assertTrue(worktree.ref_exists(repo, "HEAD"))
            self.assertFalse(worktree.ref_exists(repo, "refs/heads/nonexistent"))

    def test_check_primary_stop_conditions(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo = Path(tmpdir)
            subprocess.run(["git", "init", "-q", "-b", "master", str(repo)], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.com"], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.name", "Test"], check=True)

            dummy_file = repo / "README.md"
            dummy_file.write_text("test\n", encoding="utf-8")
            subprocess.run(["git", "-C", str(repo), "add", "README.md"], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-q", "-m", "init"], check=True)

            # 1. Switch to a branch other than master
            subprocess.run(["git", "-C", str(repo), "checkout", "-q", "-b", "feature-x"], check=True)
            with self.assertRaises(worktree.Stop) as ctx:
                worktree.check_primary(repo)
            self.assertIn("switch it to master first", str(ctx.exception))

            # Switch back to master
            subprocess.run(["git", "-C", str(repo), "checkout", "-q", "master"], check=True)

            # 2. Dirty plans/workstreams.md
            plans_dir = repo / "plans"
            plans_dir.mkdir()
            ledger_file = plans_dir / "workstreams.md"
            ledger_file.write_text("uncommitted change\n", encoding="utf-8")
            with self.assertRaises(worktree.Stop) as ctx:
                worktree.check_primary(repo)
            self.assertIn("has uncommitted changes", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
