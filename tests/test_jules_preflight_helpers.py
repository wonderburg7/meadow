"""Unit tests for tools/jules_preflight.py helper functions.

Covers pure top-level helper functions:
- is_pattern
- unprocessed
- review_block
- matches_base
- has_done_line
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


class JulesPreflightHelpersTest(unittest.TestCase):
    def test_is_pattern(self):
        self.assertTrue(preflight.is_pattern("docs/*.md"))
        self.assertTrue(preflight.is_pattern("scripts/?oo.gd"))
        self.assertTrue(preflight.is_pattern("tests/[a-z]*.py"))
        self.assertFalse(preflight.is_pattern("docs/known-pitfalls.md"))
        self.assertFalse(preflight.is_pattern("scripts/main.gd"))

    def test_unprocessed(self):
        ledger = {
            "jules/j-1-test": preflight.LedgerRow(
                item="J-1",
                branch="jules/j-1-test",
                state="closed",
                date="2026-10-25",
                by="Dave",
                outcome="closed",
            )
        }
        self.assertFalse(preflight.unprocessed("origin/jules/j-1-test", ledger))
        self.assertFalse(preflight.unprocessed("jules/j-1-test", ledger))
        self.assertTrue(preflight.unprocessed("origin/jules/j-2-test", ledger))
        self.assertTrue(preflight.unprocessed("jules/j-2-test", ledger))

    def test_review_block(self):
        review = preflight.Review(
            id="R-gameplay",
            key="gameplay",
            title="Gameplay mechanics and loops",
            path="docs/reviews/gameplay.md",
            priority=1,
            every_days=14,
            min_commits=30,
            watches=["scripts/gameplay/"],
        )
        lines = preflight.review_block(review, "due after 30 commits", ["Note 1", "Note 2"])
        text = "\n".join(lines)
        self.assertIn("next  R-gameplay -- Gameplay mechanics and loops", text)
        self.assertIn("branch: jules/r-gameplay-<topic>", text)
        self.assertIn("why now: due after 30 commits", text)
        self.assertIn("Note 1", text)
        self.assertIn("Note 2", text)


class JulesPreflightGitHelpersTest(unittest.TestCase):
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

    def test_matches_base_when_no_files_changed_or_content_identical(self):
        subprocess.run(["git", "-C", str(self.root), "checkout", "-b", "feature"], check=True, capture_output=True)
        self.assertTrue(preflight.matches_base(self.root, "feature", "master"))

        (self.root / "feature.txt").write_text("Feature\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(self.root), "add", "feature.txt"], check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.root), "commit", "-m", "Add feature"], check=True, capture_output=True)
        self.assertFalse(preflight.matches_base(self.root, "feature", "master"))

        subprocess.run(["git", "-C", str(self.root), "checkout", "master"], check=True, capture_output=True)
        (self.root / "feature.txt").write_text("Feature\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(self.root), "add", "feature.txt"], check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.root), "commit", "-m", "Port feature to master"], check=True, capture_output=True)
        self.assertTrue(preflight.matches_base(self.root, "feature", "master"))

    def test_has_done_line(self):
        self.assertFalse(preflight.has_done_line(self.root, "J-50", "master"))

        (self.root / "note.txt").write_text("Done J-50\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(self.root), "add", "note.txt"], check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.root), "commit", "-m", "J-50: implement feature"], check=True, capture_output=True)
        self.assertTrue(preflight.has_done_line(self.root, "J-50", "master"))

        subprocess.run(["git", "-C", str(self.root), "revert", "HEAD", "--no-edit"], check=True, capture_output=True)
        self.assertFalse(preflight.has_done_line(self.root, "J-50", "master"))


if __name__ == "__main__":
    unittest.main()
