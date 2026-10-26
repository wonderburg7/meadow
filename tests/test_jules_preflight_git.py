"""Unit tests for tools/jules_preflight.py's git helpers."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOL = Path(__file__).resolve().parent.parent / "tools" / "jules_preflight.py"
SPEC = importlib.util.spec_from_file_location("jules_preflight", TOOL)
preflight = importlib.util.module_from_spec(SPEC)
sys.modules["jules_preflight"] = preflight
SPEC.loader.exec_module(preflight)


class TestJulesPreflightGitHelpers(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        base = Path(self.temp.name)
        self.origin = base / "origin.git"
        self.root = base / "clone"

        # Make a bare repository and a clone of it
        subprocess.run(["git", "init", "-q", "--bare", "-b", "master", str(self.origin)], check=True)
        subprocess.run(["git", "clone", "-q", str(self.origin), str(self.root)], check=True)

        # Configure git identity in clone
        self.git("config", "user.email", "test@example.com")
        self.git("config", "user.name", "Test")
        self.git("checkout", "-q", "-b", "master")

        # Initial commit on master
        self.write_file("README.md", "# Test Repo\n")
        self.git("add", "README.md")
        self.git("commit", "-q", "-m", "initial commit")
        self.git("push", "-q", "origin", "master")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def git(self, *args: str) -> str:
        return preflight.git(self.root, *args)

    def write_file(self, rel_path: str, content: str) -> None:
        p = self.root / rel_path
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content, encoding="utf-8")

    def test_git_helpers(self) -> None:
        # On master, commit once with a subject starting J-2:
        self.write_file("J2.txt", "J-2 done\n")
        self.git("add", "J2.txt")
        self.git("commit", "-q", "-m", "J-2: complete task 2")
        self.git("push", "-q", "origin", "master")

        # Push a jules/j-1-x branch that adds one file
        self.git("checkout", "-q", "-b", "jules/j-1-x", "master")
        self.write_file("added_by_j1.txt", "j1 file\n")
        self.git("add", "added_by_j1.txt")
        self.git("commit", "-q", "-m", "add file for J-1")
        self.git("push", "-q", "origin", "jules/j-1-x")

        # A J-20 branch must not make J-2 look taken (the stem's trailing hyphen)
        self.git("checkout", "-q", "-b", "jules/j-20-y", "master")
        self.write_file("added_by_j20.txt", "j20 file\n")
        self.git("add", "added_by_j20.txt")
        self.git("commit", "-q", "-m", "add file for J-20")
        self.git("push", "-q", "origin", "jules/j-20-y")

        # Switch back to master and fetch remote branches so origin/jules/j-1-x exists
        self.git("checkout", "-q", "master")
        self.git("fetch", "-q", "origin")

        base = "origin/master"

        # Build each Task with parse_tasks from a two-task string
        two_tasks_str = (
            "### J-1 -- Task One\n"
            "- Files: `added_by_j1.txt`\n"
            "- After: none\n\n"
            "### J-2 -- Task Two\n"
            "- Files: `J2.txt`\n"
            "- After: none\n"
        )
        tasks = preflight.parse_tasks(two_tasks_str)
        self.assertEqual(len(tasks), 2)
        task_j1, task_j2 = tasks[0], tasks[1]

        # Check open_branches sees the branch
        branches = preflight.open_branches(self.root, base=base)
        self.assertIn("origin/jules/j-1-x", branches)

        # Check branch_files sees the file added in the branch
        b_files = preflight.branch_files(self.root, "origin/jules/j-1-x", base=base)
        self.assertEqual(b_files, {"added_by_j1.txt"})

        # Check is_taken is True for J-1 and False for J-2
        self.assertTrue(preflight.is_taken(self.root, task_j1, base=base))
        self.assertFalse(preflight.is_taken(self.root, task_j2, base=base))

        # Check is_done is True for J-2 and False for J-1
        self.assertTrue(preflight.is_done(self.root, task_j2, base=base))
        self.assertFalse(preflight.is_done(self.root, task_j1, base=base))

    def test_planned_mentions(self) -> None:
        self.write_file("NEXTSTEPS.md", "### Queue\n- Edit `tools/sample.py` here.\n")
        self.write_file("plans/now/active.md", "This also touches `tools/sample.py`.\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "add queue and plan")
        self.git("push", "-q", "origin", "master")

        mentions = preflight.planned_mentions(self.root, "tools/sample.py", base="origin/master")
        self.assertIn("NEXTSTEPS.md:2", mentions)
        self.assertIn("plans/now/active.md:1", mentions)


if __name__ == "__main__":
    unittest.main()
