"""Tests for routable_docs, queue_declared_files, and check_backticked_paths in tools/check_docs.py (standing task S-1)."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from check_docs import (
    check_backticked_paths,
    git_ignores,
    queue_declared_files,
    routable_docs,
)


class TestCheckDocsBacktickedPathsHelpers(unittest.TestCase):
    def test_routable_docs_collects_expected_paths_without_duplicates(self) -> None:
        docs = routable_docs()
        self.assertIsInstance(docs, list)
        self.assertTrue(len(docs) > 0)
        # Verify no duplicate entries are returned
        self.assertEqual(len(docs), len(set(docs)))
        # Verify all returned files exist and have .md suffix
        for doc in docs:
            self.assertTrue(doc.is_file(), f"{doc} should be an existing file")
            self.assertEqual(doc.suffix, ".md")

    def test_queue_declared_files_returns_empty_when_nextsteps_missing(self) -> None:
        with patch.object(Path, "is_file", return_value=False):
            declared = queue_declared_files()
            self.assertEqual(declared, set())

    def test_queue_declared_files_parses_declared_files_from_queue_and_backlog(self) -> None:
        sample_queue = (
            "## Next up\n\n"
            "### Claude lane\n\n"
            "1. **[Claude] S-1 -- Sample item**\n"
            "   - Plan: `plans/test.md`\n"
            "   - Files: `scripts/new_file.gd`, `tests/test_new_file.py`\n"
            "   - Check: `python tests/source_checks.py`\n"
            "   - Proof: `present: scripts/new_file.gd :: extends Node`\n"
        )
        fake_entry = MagicMock()
        fake_entry.body = "- Files: `scripts/backlog_entry.gd`\n"

        with patch.object(Path, "is_file", return_value=True), \
             patch.object(Path, "read_text", return_value=sample_queue), \
             patch("check_docs.plan_queue_blocks", return_value=[fake_entry]):
            declared = queue_declared_files()
            self.assertIn("scripts/new_file.gd", declared)
            self.assertIn("tests/test_new_file.py", declared)
            self.assertIn("scripts/backlog_entry.gd", declared)

    def test_check_backticked_paths_passes_for_existing_repo_files(self) -> None:
        errors: list[str] = []
        doc_content = (
            "# Documentation\n\n"
            "See `scripts/main.gd` and `project.godot` for setup.\n"
            "Also check `res://scripts/main.gd::some_func` or `scripts/main.gd#section`.\n"
            "Non-routable references: `not_a_path`, `foo bar/baz.gd`, `https://example.com/file.md`.\n"
        )
        fake_doc = Path("docs/sample.md")
        with patch("check_docs.routable_docs", return_value=[fake_doc]), \
             patch.object(Path, "read_text", return_value=doc_content), \
             patch("check_docs.queue_declared_files", return_value=set()):
            check_backticked_paths(errors)
            self.assertEqual(errors, [])

    def test_check_backticked_paths_ignores_declared_queue_files_and_gitignored_files(self) -> None:
        errors: list[str] = []
        doc_content = (
            "# References\n\n"
            "Upcoming file `scripts/future_feature.gd` and ignored `.claude/settings.local.json`.\n"
        )
        fake_doc = Path("docs/sample.md")
        declared = {"scripts/future_feature.gd"}
        with patch("check_docs.routable_docs", return_value=[fake_doc]), \
             patch.object(Path, "read_text", return_value=doc_content), \
             patch("check_docs.queue_declared_files", return_value=declared), \
             patch("check_docs.git_ignores", side_effect=lambda rel: rel == ".claude/settings.local.json"):
            check_backticked_paths(errors)
            self.assertEqual(errors, [])

    def test_check_backticked_paths_reports_nonexistent_paths(self) -> None:
        errors: list[str] = []
        doc_content = (
            "# Broken Doc\n\n"
            "See `scripts/nonexistent_script.gd` and `plans/missing_plan.md`.\n"
            "Wildcards like `scripts/**/*.gd` are skipped.\n"
        )
        fake_doc = ROOT / "docs" / "broken.md"
        with patch("check_docs.routable_docs", return_value=[fake_doc]), \
             patch.object(Path, "read_text", return_value=doc_content), \
             patch("check_docs.queue_declared_files", return_value=set()), \
             patch("check_docs.git_ignores", return_value=False):
            check_backticked_paths(errors)
            self.assertEqual(len(errors), 2)
            self.assertIn("docs/broken.md: backticked path does not exist: scripts/nonexistent_script.gd", errors[0])
            self.assertIn("docs/broken.md: backticked path does not exist: plans/missing_plan.md", errors[1])


if __name__ == "__main__":
    unittest.main()
