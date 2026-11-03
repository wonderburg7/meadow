"""Tests for helper functions in tools/check_docs.py (standing task S-1)."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.check_docs import (
    _block_shape,
    _disposition_errors,
    _is_repository_relative_file,
    _table_cells,
    _unquote,
    rule_front_matter_globs,
)


class TestCheckDocsHelpers(unittest.TestCase):
    def test_table_cells(self) -> None:
        row = "| col1 | col2 \\| escaped | col3 |"
        cells = _table_cells(row)
        self.assertEqual(cells, ["col1", "col2 / escaped", "col3"])

        no_outer_pipes = "first | second | third"
        self.assertEqual(_table_cells(no_outer_pipes), ["first", "second", "third"])

    def test_unquote(self) -> None:
        self.assertEqual(_unquote('"hello"'), "hello")
        self.assertEqual(_unquote("'world'"), "world")
        self.assertEqual(_unquote("  'spaced'  "), "spaced")
        self.assertEqual(_unquote("unquoted"), "unquoted")

    def test_block_shape(self) -> None:
        body = "   1. Item one\n   - Files: `scripts/bee.gd`\n   - Proof: `ok`\n"
        shape = _block_shape(body)
        self.assertEqual(shape, "1. Item one\n- Files: `scripts/bee.gd`\n- Proof: `ok`")

    def test_is_repository_relative_file(self) -> None:
        self.assertTrue(_is_repository_relative_file("scripts/bee.gd"))
        self.assertTrue(_is_repository_relative_file("docs/known-pitfalls.md"))
        self.assertFalse(_is_repository_relative_file("/etc/passwd"))
        self.assertFalse(_is_repository_relative_file("C:\\Windows\\system32"))
        self.assertFalse(_is_repository_relative_file("https://example.com/file.md"))
        self.assertFalse(_is_repository_relative_file("../parent/file.txt"))
        self.assertFalse(_is_repository_relative_file("scripts/"))
        self.assertFalse(_is_repository_relative_file(""))

    def test_rule_front_matter_globs(self) -> None:
        # Block list style
        text_block = """---
paths:
  - "scripts/**/*.gd"
  - 'tests/*.py'
---
# Some rule
"""
        self.assertEqual(rule_front_matter_globs(text_block), ["scripts/**/*.gd", "tests/*.py"])

        # Inline list style
        text_inline_list = """---
paths: ["scripts/**/*.gd", "tests/*.py"]
---
"""
        self.assertEqual(rule_front_matter_globs(text_inline_list), ["scripts/**/*.gd", "tests/*.py"])

        # Inline scalar style
        text_scalar = """---
paths: "scripts/**/*.gd"
---
"""
        self.assertEqual(rule_front_matter_globs(text_scalar), ["scripts/**/*.gd"])

        # No front matter or unclosed
        self.assertIsNone(rule_front_matter_globs("# Just markdown\n"))
        self.assertIsNone(rule_front_matter_globs("---\npaths: 'test'\n"))

    def test_disposition_errors(self) -> None:
        allowed = ("queued", "deferred", "wontfix")

        # Empty body with none
        self.assertEqual(_disposition_errors("doc.md", "Section", "None.", allowed), [])

        # Missing table and no none
        errors_no_table = _disposition_errors("doc.md", "Section", "Some text without table", allowed)
        self.assertEqual(len(errors_no_table), 1)
        self.assertIn("has no table", errors_no_table[0])

        # Missing Disposition column
        body_no_disp = """| Issue | Impact |
| --- | --- |
| bug | high |
"""
        errors_no_col = _disposition_errors("doc.md", "Section", body_no_disp, allowed)
        self.assertEqual(len(errors_no_col), 1)
        self.assertIn("table has no Disposition column", errors_no_col[0])

        # Valid rows
        body_valid = """| Issue | Disposition |
| --- | --- |
| Bug 1 | Queued in plans/now/code-health.md (CH-1) |
| Bug 2 | Deferred until next release cycle |
| Bug 3 | Wontfix deliberate architectural trade-off |
"""
        self.assertEqual(_disposition_errors("doc.md", "Section", body_valid, allowed), [])

        # Invalid disposition word
        body_invalid_word = """| Issue | Disposition |
| --- | --- |
| Bug 1 | Pending review soon |
"""
        errors_word = _disposition_errors("doc.md", "Section", body_invalid_word, allowed)
        self.assertEqual(len(errors_word), 1)
        self.assertIn("has no disposition", errors_word[0])

        # Missing detail
        body_no_detail = """| Issue | Disposition |
| --- | --- |
| Bug 1 | Queued |
"""
        errors_detail = _disposition_errors("doc.md", "Section", body_no_detail, allowed)
        self.assertEqual(len(errors_detail), 1)
        self.assertIn("says Queued but not how, where or why", errors_detail[0])

        # Queued without plan or slice id
        body_no_plan = """| Issue | Disposition |
| --- | --- |
| Bug 1 | Queued later in backlog |
"""
        errors_plan = _disposition_errors("doc.md", "Section", body_no_plan, allowed)
        self.assertEqual(len(errors_plan), 1)
        self.assertIn("without naming the slice id or plan", errors_plan[0])


if __name__ == "__main__":
    unittest.main()
