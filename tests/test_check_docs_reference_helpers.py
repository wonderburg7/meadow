"""Unit tests for pure helper functions in tools/check_docs.py."""

from __future__ import annotations

import unittest
from pathlib import Path
from unittest.mock import patch

from tools import check_docs


class TestCheckDocsReferenceHelpers(unittest.TestCase):
    def test_item_files_extracts_backticked_paths(self) -> None:
        """_item_files parses backticked paths from an item body's - Files: line."""
        body = (
            "- Task: Foo\n"
            "- Files: `scripts/bee.gd`, `tools/run_tests.py` and `tests/test_bee.py`\n"
            "- Do: something"
        )
        self.assertEqual(
            check_docs._item_files(body),
            {"scripts/bee.gd", "tools/run_tests.py", "tests/test_bee.py"},
        )

    def test_item_files_missing_or_empty_files_line(self) -> None:
        """_item_files returns an empty set when no - Files: line is present or no paths backticked."""
        self.assertEqual(check_docs._item_files("- Task: Foo\n- Do: something"), set())
        self.assertEqual(check_docs._item_files("- Files:\n- Do: something"), set())
        self.assertEqual(check_docs._item_files("- Files: none\n- Do: something"), set())

    def test_active_slice_ids_extracts_leaf_names(self) -> None:
        """_active_slice_ids extracts normalised leaf slice IDs from worktree ledger rows."""
        fake_rows = [
            ("worktrees/slice-a", Path("/repo/worktrees/slice-a")),
            ("worktrees/nested/slice-b/", Path("/repo/worktrees/nested/slice-b")),
            ("worktrees\\windows\\slice-c", Path("/repo/worktrees/windows/slice-c")),
        ]
        with patch.object(check_docs, "ledger_worktree_rows", return_value=fake_rows):
            self.assertEqual(check_docs._active_slice_ids(), {"slice-a", "slice-b", "slice-c"})

    def test_owner_plan_markdown_link(self) -> None:
        """_owner_plan extracts relative plan path from Markdown links, stripping anchors."""
        line = "Owner: [Combat plan](plans/combat.md#slice-1)"
        self.assertEqual(check_docs._owner_plan(line), "plans/combat.md")

    def test_owner_plan_backticks(self) -> None:
        """_owner_plan extracts relative plan path from backticks, stripping anchors."""
        line = "Owner: `plans/combat.md#anchor`"
        self.assertEqual(check_docs._owner_plan(line), "plans/combat.md")

    def test_owner_plan_no_plan_target(self) -> None:
        """_owner_plan returns None when no token with a slash is present."""
        self.assertIsNone(check_docs._owner_plan("Owner: Dave"))
        self.assertIsNone(check_docs._owner_plan("Owner: `standalone`"))

    def test_routable_docs_collects_unique_paths(self) -> None:
        """routable_docs globs DOC_GLOBS from ROOT, returning sorted unique paths."""
        p1 = Path("docs/a.md")
        p2 = Path("plans/b.md")
        fake_globs = {
            "*.md": [p1],
            "docs/*.md": [p1, p2],
        }

        def mock_glob(self: Path, pattern: str) -> list[Path]:
            return fake_globs.get(pattern, [])

        with patch.object(check_docs, "DOC_GLOBS", ("*.md", "docs/*.md")), \
             patch.object(Path, "glob", mock_glob):
            docs = check_docs.routable_docs()
            self.assertEqual(docs, [p1, p2])


if __name__ == "__main__":
    unittest.main()
