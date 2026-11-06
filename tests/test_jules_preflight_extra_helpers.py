"""Unit tests for tools/jules_preflight.py extra helper functions.

Covers pure and git helper functions:
- off_line
- reviewed_state
"""

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


class JulesPreflightExtraHelpersTest(unittest.TestCase):
    def test_off_line(self):
        line_a = preflight.off_line("A", "docs/new.md", "unexpected added file", base="origin/master")
        self.assertEqual(
            line_a,
            "off   A docs/new.md -- unexpected added file; delete it: git rm -f docs/new.md",
        )

        line_m = preflight.off_line("M", "scripts/main.gd", "unauthorized edit", base="origin/master")
        self.assertEqual(
            line_m,
            "off   M scripts/main.gd -- unauthorized edit; restore it: git checkout origin/master -- scripts/main.gd",
        )


class JulesPreflightReviewedStateTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        subprocess.run(["git", "-C", str(self.root), "init", "-b", "master"], check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.root), "config", "user.name", "Tester"], check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.root), "config", "user.email", "test@example.com"], check=True, capture_output=True)

        (self.root / "README.md").write_text("Hello\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(self.root), "add", "README.md"], check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.root), "commit", "-m", "Initial commit"], check=True, capture_output=True)

    def tearDown(self):
        self.temp.cleanup()

    def test_reviewed_state_no_sha(self):
        row_no_sha = preflight.LedgerRow(
            item="J-10",
            branch="jules/j-10-feature",
            state="reviewed",
            date="2026-11-01",
            by="Claude",
            outcome="looks good but no tip recorded",
        )
        state, detail = preflight.reviewed_state(self.root, "master", row_no_sha, base="master")
        self.assertEqual(state, "moved")
        self.assertIn("no 'at <40-char SHA>:' at the start of the Outcome", detail)

    def test_reviewed_state_mismatched_sha(self):
        tip_master = subprocess.run(
            ["git", "-C", str(self.root), "rev-parse", "master"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        fake_sha = "0" * 40
        row_mismatched_sha = preflight.LedgerRow(
            item="J-10",
            branch="jules/j-10-feature",
            state="reviewed",
            date="2026-11-01",
            by="Claude",
            outcome=f"at {fake_sha}: approved",
        )
        state, detail = preflight.reviewed_state(self.root, "master", row_mismatched_sha, base="master")
        self.assertEqual(state, "moved")
        self.assertIn(f"tip is now {tip_master[:12]}: review the new commits", detail)

    def test_reviewed_state_active_branch(self):
        subprocess.run(["git", "-C", str(self.root), "checkout", "-b", "feature-branch"], check=True, capture_output=True)
        (self.root / "work.txt").write_text("Work\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(self.root), "add", "work.txt"], check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.root), "commit", "-m", "Work commit"], check=True, capture_output=True)
        tip_feature = subprocess.run(
            ["git", "-C", str(self.root), "rev-parse", "feature-branch"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()

        row_reviewed = preflight.LedgerRow(
            item="J-10",
            branch="jules/j-10-feature",
            state="reviewed",
            date="2026-11-01",
            by="Claude",
            outcome=f"at {tip_feature}: verified and approved",
        )
        state, detail = preflight.reviewed_state(self.root, "feature-branch", row_reviewed, base="master")
        self.assertEqual(state, "reviewed")
        self.assertEqual(detail, f"J-10, 2026-11-01 by Claude: at {tip_feature}: verified and approved")

    def test_reviewed_state_stale(self):
        tip_master = subprocess.run(
            ["git", "-C", str(self.root), "rev-parse", "master"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        row_stale = preflight.LedgerRow(
            item="J-10",
            branch="jules/j-10-feature",
            state="reviewed",
            date="2026-11-01",
            by="Claude",
            outcome=f"at {tip_master}: verified and approved",
        )
        state, detail = preflight.reviewed_state(self.root, "master", row_stale, base="master")
        self.assertEqual(state, "stale")
        self.assertIn("already on master: flip the row to merged", detail)


if __name__ == "__main__":
    unittest.main()
