"""Unit tests for pure helper functions in tools/check_docs.py."""

from __future__ import annotations

import unittest

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



if __name__ == "__main__":
    unittest.main()
