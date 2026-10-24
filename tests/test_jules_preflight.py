"""tools/jules_preflight.py: Google Jules's ownership check and task picker,
run against a throwaway repository with its own `origin`."""

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
sys.modules["jules_preflight"] = preflight  # dataclasses look the module up while building Task
SPEC.loader.exec_module(preflight)

TASKS = (
    "# Jules\n\n## Tasks\n\n"
    "### J-1 -- first\n\n- Files: `tools/one.py`, tests/test_one.py (new)\n- After: none\n\n"
    "### J-2 -- second\n\n- Files: `tools/two.py`\n\n"
    "### J-3 -- third\n\n- Files: `tools/three.py`\n- After: J-1\n\n"
    "### J-4 -- fourth\n\n- Files: `tools/four.py`\n- After: J-9\n- Do: change four.\n\n"
    "## Standing tasks\n\n- Files: `tools/not_a_task.py`\n"
)


class JulesPreflightTest(unittest.TestCase):
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
        self.write("NEXTSTEPS.md", "### Claude lane\n\n- Files: `tools/queued.py`\n")
        self.write("plans/now/sample.md", "A later slice edits `tools/planned.py`: it does.\n")
        self.write("plans/reference/jules.md", TASKS)
        for name in ("one", "two", "three", "four", "free", "branched"):
            self.write(f"tools/{name}.py", "# placeholder\n")
        self.commit("seed")
        self.git("push", "-q", "origin", "master")

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args: str) -> str:
        return preflight.git(self.root, *args)

    def write(self, path: str, text: str) -> None:
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8")

    def commit(self, message: str) -> None:
        self.git("add", "-A")
        self.git("commit", "-q", "-m", message)

    def push_branch(self, name: str, path: str, merge: bool = False, message: str = "edit") -> None:
        self.git("checkout", "-q", "-b", name, "master")
        self.write(path, f"# {name}\n")
        self.commit(message)
        self.git("push", "-q", "origin", name)
        self.git("checkout", "-q", "master")
        if merge:
            self.git("merge", "-q", "--no-ff", "-m", f"Merge pull request #1 from owner/{name}\n\n{message}", name)
            self.git("push", "-q", "origin", "master")
        self.git("fetch", "-q", "origin")

    def test_parse_tasks_reads_files_and_after(self):
        tasks = preflight.parse_tasks(TASKS)
        self.assertEqual([task.id for task in tasks], ["J-1", "J-2", "J-3", "J-4"])
        self.assertEqual(tasks[0].files, ["tools/one.py", "tests/test_one.py"])
        self.assertEqual(tasks[0].after, [])
        self.assertEqual(tasks[2].after, ["J-1"])

    def test_a_task_block_ends_at_the_next_section(self):
        tasks = preflight.parse_tasks(TASKS)
        self.assertEqual(tasks[3].files, ["tools/four.py"])
        self.assertIn("- Do: change four.", tasks[3].body)
        self.assertNotIn("tools/not_a_task.py", "\n".join(tasks[3].body))

    def test_queue_counts_free_tasks_and_names_each_state(self):
        self.push_branch("jules/j-1-first", "tools/one.py", merge=True, message="J-1: first")
        self.push_branch("jules/j-2-second", "tools/two.py")
        states = [(task.id, state) for task, state, _ in preflight.classify(self.root, preflight.parse_tasks(TASKS))]
        self.assertEqual(states, [("J-1", "done"), ("J-2", "taken"), ("J-3", "free"), ("J-4", "waits")])

    def test_task_for_ref_reads_the_task_from_the_branch_name(self):
        self.assertEqual(preflight.task_for_ref(self.root, "origin/jules/j-12-typed-array-9796301"), "J-12")
        self.assertIsNone(preflight.task_for_ref(self.root, "origin/claude/other"))
        self.git("checkout", "-q", "-b", "jules/j-3-third")
        self.assertEqual(preflight.task_for_ref(self.root, "HEAD"), "J-3")
        self.git("checkout", "-q", "master")

    def test_scope_flags_a_stale_snapshot_as_off_task_files(self):
        """A commit whose tree predates master reverts files the task never named."""
        task = preflight.parse_tasks(TASKS)[0]  # J-1: tools/one.py, tests/test_one.py
        self.git("checkout", "-q", "-b", "jules/j-1-first", "master")
        self.write("tools/one.py", "# jules\n")
        self.write("tools/added.py", "# stray\n")
        (self.root / "plans/now/sample.md").unlink()
        self.commit("J-1: first")
        report = preflight.scope_report(self.root, task, "HEAD", base="master")
        self.assertIn("ok    M tools/one.py", report)
        self.assertTrue(any(line.startswith("off   A tools/added.py") and "git rm -f tools/added.py" in line for line in report))
        self.assertTrue(
            any(line.startswith("off   D plans/now/sample.md") and "git checkout master -- plans/now/sample.md" in line for line in report)
        )
        self.assertIn("note  tests/test_one.py -- named in Files but unchanged", report)
        self.git("checkout", "-q", "master")

    def test_scope_is_clean_when_only_the_named_files_change(self):
        task = preflight.parse_tasks(TASKS)[1]
        self.git("checkout", "-q", "-b", "jules/j-2-second", "master")
        self.write("tools/two.py", "# jules\n")
        self.commit("J-2: second")
        report = preflight.scope_report(self.root, task, "HEAD", base="master")
        self.assertEqual(report, ["ok    M tools/two.py"])
        self.git("checkout", "-q", "master")

    def test_queued_planned_and_branched_paths_are_owned(self):
        self.push_branch("codex/other", "tools/branched.py")
        found = preflight.owners(self.root, ["tools/queued.py", "tools/planned.py", "tools/branched.py", "tools/free.py"])
        self.assertIn("named in NEXTSTEPS.md:3", found["tools/queued.py"])
        self.assertIn("named in plans/now/sample.md:1", found["tools/planned.py"])
        self.assertEqual(found["tools/branched.py"], ["changed on unmerged origin/codex/other"])
        self.assertEqual(found["tools/free.py"], [])

    def test_a_merged_branch_owns_nothing(self):
        self.push_branch("claude/done", "tools/branched.py", merge=True)
        self.assertEqual(preflight.owners(self.root, ["tools/branched.py"])["tools/branched.py"], [])

    def test_next_skips_done_taken_and_blocked_tasks(self):
        self.push_branch("jules/j-1-first", "tools/one.py", merge=True, message="J-1: first")
        self.push_branch("jules/j-2-second", "tools/two.py")
        task, skipped = preflight.next_task(self.root, preflight.parse_tasks(TASKS))
        self.assertEqual(task.id, "J-3")
        self.assertEqual(skipped, ["J-1: done", "J-2: taken by an open jules/j-2-* branch"])

    def test_next_passes_over_a_task_whose_file_another_branch_changes(self):
        self.push_branch("codex/busy", "tools/two.py")
        task, skipped = preflight.next_task(self.root, preflight.parse_tasks(TASKS))
        self.assertEqual(task.id, "J-1")
        self.git("checkout", "-q", "-b", "claude/busy-one", "master")
        self.write("tools/one.py", "# busy\n")
        self.commit("edit one")
        self.git("push", "-q", "origin", "claude/busy-one")
        self.git("checkout", "-q", "master")
        self.git("fetch", "-q", "origin")
        task, skipped = preflight.next_task(self.root, preflight.parse_tasks(TASKS))
        self.assertIsNone(task)
        self.assertEqual(skipped[0], "J-1: tools/one.py changed on unmerged origin/claude/busy-one")
        self.assertEqual(skipped[2], "J-3: waits for J-1")
        self.assertEqual(skipped[3], "J-4: waits for J-9")


if __name__ == "__main__":
    unittest.main()
