"""tools/worktree.py: open/close an ad-hoc worktree with its plans/workstreams.md row,
run against a throwaway repository with its own `origin`."""

from __future__ import annotations

import contextlib
import io
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

import worktree  # noqa: E402

LEDGER_TEXT = (
    "# Active workstreams\n\n"
    "| Worktree path (branch) | Lane | Scope | Owner | Status | Depends on | Plan / slice |\n"
    "| --- | --- | --- | --- | --- | --- | --- |\n"
)
SLICE_PS1 = (
    "function Get-LaneTrailer {\n"
    "    param([string]$Lane)\n"
    '    if ($Lane -eq "Codex") {\n'
    '        return "Co-Authored-By: Codex Test <codex@example.com>"\n'
    "    }\n"
    '    return "Co-Authored-By: Claude Test <claude@example.com>"\n'
    "}\n"
)


class WorktreeToolTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        base = Path(self.temp.name)
        self.origin = base / "origin.git"
        self.root = base / "work"
        subprocess.run(["git", "init", "-q", "--bare", "-b", "master", str(self.origin)], check=True)
        subprocess.run(["git", "clone", "-q", str(self.origin), str(self.root)], check=True, capture_output=True)
        self.git("config", "user.email", "test@example.com")
        self.git("config", "user.name", "Test")
        self.git("checkout", "-q", "-b", "master")
        (self.root / "plans").mkdir()
        (self.root / "tools").mkdir()
        (self.root / "plans/workstreams.md").write_text(LEDGER_TEXT, encoding="utf-8")
        (self.root / "tools/slice.ps1").write_text(SLICE_PS1, encoding="utf-8")
        (self.root / ".gitignore").write_text(".worktrees/\n", encoding="utf-8")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "seed")
        self.git("push", "-q", "-u", "origin", "master")

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args: str) -> str:
        return subprocess.run(["git", "-C", str(self.root), *args], check=True, capture_output=True, text=True).stdout

    def run_tool(self, *argv: str, root: Path | None = None) -> tuple[int, str]:
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = worktree.main(list(argv), root=root or self.root)
        return code, out.getvalue() + err.getvalue()

    def open_review(self, name: str = "review-1", branch: str = "claude/review-1", owner: str = "Claude") -> tuple[int, str]:
        return self.run_tool("open", "--name", name, "--branch", branch, "--lane", "Review",
                             "--scope", "Assigned review; report only", "--owner", owner,
                             "--plan", "plans/reference/review.md")

    def ledger(self) -> str:
        return (self.root / "plans/workstreams.md").read_text(encoding="utf-8")

    def remote_ledger(self) -> str:
        return self.git("show", "origin/master:plans/workstreams.md") if self.git("fetch", "-q", "origin") == "" else ""

    def test_open_registers_commits_and_pushes_in_one_step(self):
        code, output = self.open_review()
        self.assertEqual(code, 0, output)
        row = ("| `.worktrees/review-1` (`claude/review-1`) | Review | Assigned review; report only | Claude"
               " | in progress | none | `plans/reference/review.md` |")
        self.assertIn(row, self.ledger())
        self.assertIn(row, self.remote_ledger())
        self.assertTrue((self.root / ".worktrees/review-1").is_dir())
        self.assertIn((self.root / ".worktrees/review-1").resolve().as_posix(), self.git("worktree", "list"))
        message = self.git("log", "-1", "--format=%B")
        self.assertTrue(message.startswith("Register the review-1 worktree in the ledger"))
        self.assertIn("Co-Authored-By: Claude Test <claude@example.com>", message)
        # The branch starts at origin/master, before the row commit.
        self.assertEqual(self.git("rev-parse", "claude/review-1"), self.git("rev-parse", "HEAD~1"))

    def test_codex_owner_takes_the_codex_trailer(self):
        self.assertEqual(self.open_review(owner="Codex")[0], 0)
        self.assertIn("Co-Authored-By: Codex Test <codex@example.com>", self.git("log", "-1", "--format=%B"))

    def test_open_refuses_existing_names_branches_and_worktrees(self):
        self.assertEqual(self.open_review()[0], 0)
        code, output = self.open_review()
        self.assertEqual(code, 1)
        self.assertIn("already exists or has a row", output)
        code, output = self.open_review(name="review-2")
        self.assertEqual(code, 1)
        self.assertIn("branch claude/review-1 already exists", output)
        code, output = self.run_tool("open", "--name", "x", "--branch", "b", "--lane", "Review", "--scope", "s",
                                     "--owner", "Claude", "--plan", "p.md", root=self.root / ".worktrees/review-1")
        self.assertEqual(code, 1)
        self.assertIn("primary checkout", output)

    def test_open_refuses_off_master_and_a_dirty_ledger(self):
        (self.root / "plans/workstreams.md").write_text(LEDGER_TEXT + "edit\n", encoding="utf-8")
        code, output = self.open_review()
        self.assertEqual((code, "uncommitted changes" in output), (1, True))
        self.git("checkout", "-q", "--", "plans/workstreams.md")
        self.git("checkout", "-q", "-b", "side")
        code, output = self.open_review()
        self.assertEqual((code, "switch it to master" in output), (1, True))
        self.assertFalse((self.root / ".worktrees").exists())

    def test_close_refuses_unmerged_work_unless_abandoned(self):
        self.assertEqual(self.open_review()[0], 0)
        tree = self.root / ".worktrees/review-1"
        (tree / "report.md").write_text("# report\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(tree), "add", "-A"], check=True)
        subprocess.run(["git", "-C", str(tree), "commit", "-q", "-m", "report"], check=True)
        code, output = self.run_tool("close", "--name", "review-1")
        self.assertEqual(code, 1)
        self.assertIn("not merged into origin/master", output)
        self.assertTrue(tree.is_dir())
        code, output = self.run_tool("close", "--name", "review-1", "--abandon")
        self.assertEqual(code, 0, output)
        self.assertFalse(tree.exists())
        self.assertNotIn("review-1", self.ledger())
        self.assertNotIn("review-1", self.remote_ledger())
        self.assertTrue(self.git("log", "-1", "--format=%s").startswith("Abandon the review-1 worktree"))

    def test_close_removes_a_merged_worktree_branch_and_row(self):
        self.assertEqual(self.open_review()[0], 0)
        tree = self.root / ".worktrees/review-1"
        (tree / "report.md").write_text("# report\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(tree), "add", "-A"], check=True)
        subprocess.run(["git", "-C", str(tree), "commit", "-q", "-m", "report"], check=True)
        self.git("merge", "-q", "--no-edit", "claude/review-1")
        self.git("push", "-q", "origin", "master")
        code, output = self.run_tool("close", "--name", "review-1")
        self.assertEqual(code, 0, output)
        self.assertFalse(tree.exists())
        self.assertEqual(self.git("branch", "--list", "claude/review-1"), "")
        self.assertEqual(self.ledger(), LEDGER_TEXT)
        self.assertEqual(self.remote_ledger(), LEDGER_TEXT)
        self.assertIn("Close the review-1 worktree in the ledger", self.git("log", "-1", "--format=%B"))

    def test_close_needs_a_row(self):
        code, output = self.run_tool("close", "--name", "nothing")
        self.assertEqual((code, "no row for .worktrees/nothing" in output), (1, True))

    def test_the_real_slice_script_still_has_both_trailers(self):
        root = TOOLS.parent
        self.assertTrue(worktree.lane_trailer(root, "Codex").startswith("Co-Authored-By: "))
        self.assertNotEqual(worktree.lane_trailer(root, "Codex"), worktree.lane_trailer(root, "Claude"))


if __name__ == "__main__":
    unittest.main()
