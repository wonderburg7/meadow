"""Alternation survives pending PRs, corrections and checkout integration.

Runs against private Git refs; never fetches or changes the real repository.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))
import jules_efficiency as efficiency
import jules_preflight as preflight


class EfficiencyTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.git("init", "-q", "-b", "master")
        self.git("config", "user.email", "test@example.com")
        self.git("config", "user.name", "Test")
        self.write("plans/reference/jules.md", "# Jules\n\n### J-1 -- ordinary\n\n- Files: tools/one.py\n")
        self.write("tools/one.py", "# seed\n")
        self.commit("seed")
        self.git("update-ref", "refs/remotes/origin/master", "HEAD")

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.root), *args], check=True,
                              capture_output=True, text=True).stdout.strip()

    def write(self, path, text):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8")

    def commit(self, message):
        self.git("add", ".")
        self.git("commit", "-q", "--allow-empty", "-m", message)
        return self.git("rev-parse", "HEAD")

    def publish(self, number, kind, branch):
        commit = self.commit(f"task\n\nJules-Sequence: {number} {kind}")
        self.git("update-ref", "refs/remotes/origin/" + branch, commit)
        return commit

    def cli(self, *args):
        script = (
            "import sys; from pathlib import Path; "
            "sys.path.insert(0, sys.argv[1]); import jules_preflight as p; "
            "p.ROOT = Path(sys.argv[2]); raise SystemExit(p.main(sys.argv[3:]))"
        )
        return subprocess.run([sys.executable, "-c", script, str(TOOLS), str(self.root),
                               "--no-fetch", *args], capture_output=True, text=True)

    def test_first_turn_is_ordinary_and_selects_numbered_task(self):
        self.assertEqual(efficiency.next_turn(self.root), (1, ""))
        result = self.cli("--next")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Jules-Sequence: 1 ordinary", result.stdout)
        self.assertIn("next  J-1 -- ordinary", result.stdout)

    def test_pending_ordinary_pr_forces_efficiency_even_with_free_task(self):
        previous = self.publish(1, "ordinary", "jules/j-99-pending")
        result = self.cli("--next")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Jules-Sequence: 2 efficiency", result.stdout)
        self.assertIn("next  E-2 -- Token efficiency: slice briefs", result.stdout)
        self.assertIn(previous, result.stdout)
        self.assertNotIn("next  J-1", result.stdout)

    def test_pending_efficiency_pr_restores_ordinary_turn(self):
        self.publish(1, "ordinary", "jules/j-99-pending")
        self.publish(2, "efficiency", "jules/e-2-briefs")
        result = self.cli("--next")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Jules-Sequence: 3 ordinary", result.stdout)
        self.assertIn("next  J-1", result.stdout)

    def test_correction_does_not_consume_another_turn(self):
        self.publish(1, "ordinary", "jules/j-99-pending")
        correction = self.publish(1, "ordinary", "jules/j-99-corrected")
        self.assertEqual(efficiency.next_turn(self.root)[0], 2)
        self.assertIn(efficiency.next_turn(self.root)[1],
                      [correction, self.git("rev-parse", "origin/jules/j-99-pending")])

    def test_checkout_integration_and_deleted_pr_refs_keep_sequence(self):
        self.publish(1, "ordinary", "jules/j-99-pending")
        self.publish(2, "efficiency", "jules/e-2-briefs")
        self.git("reset", "--hard", "origin/master")
        integrated = self.commit("batch\n\nJules-Sequence: 1 ordinary\nJules-Sequence: 2 efficiency")
        self.git("update-ref", "refs/remotes/origin/master", integrated)
        for branch in ("j-99-pending", "e-2-briefs"):
            self.git("update-ref", "-d", "refs/remotes/origin/jules/" + branch)
        self.assertEqual(efficiency.next_turn(self.root), (3, integrated))

    def test_local_and_non_jules_refs_do_not_advance_sequence(self):
        self.publish(21, "ordinary", "codex/experiment")
        self.commit("local\n\nJules-Sequence: 23 ordinary")
        self.assertEqual(efficiency.next_turn(self.root), (1, ""))

    def test_invalid_parity_stops_instead_of_skipping_efficiency(self):
        self.publish(2, "ordinary", "jules/j-99-invalid")
        with self.assertRaisesRegex(ValueError, "invalid Jules-Sequence"):
            efficiency.next_turn(self.root)
        result = self.cli("--next")
        self.assertEqual(result.returncode, 1)
        self.assertIn("stop  cannot determine Jules sequence", result.stdout)
        self.assertNotIn("Traceback", result.stderr)

    def test_efficiency_scope_rejects_code_and_other_reports(self):
        task = preflight.scope_task(self.root, "E-2")
        self.assertEqual(task.files, ["docs/jules-efficiency/e-2.md"])
        for invalid in ("E-1", "E-0", "E-02", "E-nope"):
            self.assertIsNone(preflight.scope_task(self.root, invalid))
        self.git("switch", "-q", "-c", "jules/e-2-briefs")
        self.write("docs/jules-efficiency/e-2.md", "# report\n")
        self.write("docs/jules-efficiency/e-4.md", "# other task\n")
        self.write("tools/one.py", "# unasked fix\n")
        self.commit("E-2: report")
        result = self.cli("--scope")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("ok    A docs/jules-efficiency/e-2.md", result.stdout)
        self.assertIn("off   A docs/jules-efficiency/e-4.md", result.stdout)
        self.assertIn("off   M tools/one.py", result.stdout)

    def test_focus_rotates_through_development_work_and_wraps(self):
        for index, focus in enumerate(efficiency.FOCUSES):
            output = "\n".join(efficiency.task_block(2 * (index + 1), "abc"))
            self.assertIn("Focus: " + focus, output)
        self.assertIn("Focus: " + efficiency.FOCUSES[0],
                      "\n".join(efficiency.task_block(14, "abc")))


if __name__ == "__main__":
    unittest.main()
