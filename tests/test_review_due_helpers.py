"""Unit tests for pure helper functions in tools/review_due.py.

Covers parse_jules, parse_prompt, latest_record, reviewed_commit,
missing_watches, load_prompts, summary, detail, and main.
"""

from __future__ import annotations

import importlib.util
import io
import shutil
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS_DIR))

REVIEW_DUE_SPEC = importlib.util.spec_from_file_location(
    "review_due", TOOLS_DIR / "review_due.py"
)
review_due = importlib.util.module_from_spec(REVIEW_DUE_SPEC)
sys.modules["review_due"] = review_due
REVIEW_DUE_SPEC.loader.exec_module(review_due)


class TestReviewDueHelpers(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.temp_dir, ignore_errors=True)

    def test_parse_jules_valid(self) -> None:
        rota, note = review_due.parse_jules("R-save | priority 1 | every 14 days | min 20 commits")
        self.assertIsNotNone(rota)
        assert rota is not None
        self.assertEqual(rota.id, "R-save")
        self.assertEqual(rota.priority, 1)
        self.assertEqual(rota.every_days, 14)
        self.assertEqual(rota.min_commits, 20)
        self.assertEqual(note, "")

    def test_parse_jules_singular_units(self) -> None:
        rota, note = review_due.parse_jules("R-test | priority 2 | every 1 day | min 1 commit")
        self.assertIsNotNone(rota)
        assert rota is not None
        self.assertEqual(rota.id, "R-test")
        self.assertEqual(rota.priority, 2)
        self.assertEqual(rota.every_days, 1)
        self.assertEqual(rota.min_commits, 1)
        self.assertEqual(note, "")

    def test_parse_jules_no(self) -> None:
        rota, note = review_due.parse_jules("no -- manual review only")
        self.assertIsNone(rota)
        self.assertEqual(note, "no -- manual review only")

        rota2, note2 = review_due.parse_jules("No")
        self.assertIsNone(rota2)
        self.assertEqual(note2, "No")

    def test_parse_jules_unreadable(self) -> None:
        rota, note = review_due.parse_jules("something invalid")
        self.assertIsNone(rota)
        self.assertEqual(note, "unreadable Jules line: something invalid")

    def test_parse_prompt(self) -> None:
        text = """Record key: `demo`
Watches: file1.txt file2.txt
Reasoning: core
Jules: R-demo | priority 3 | every 7 days | min 10 commits
Ignored line
"""
        prompt = review_due.parse_prompt(Path("plans/reference/reviews/demo.md"), text)
        self.assertEqual(prompt.path, Path("plans/reference/reviews/demo.md"))
        self.assertEqual(prompt.key, "demo")
        self.assertEqual(prompt.watches, ["file1.txt", "file2.txt"])
        self.assertEqual(prompt.reasoning, "core")
        self.assertIsNotNone(prompt.jules)
        assert prompt.jules is not None
        self.assertEqual(prompt.jules.id, "R-demo")
        self.assertEqual(prompt.jules_note, "")

    def test_parse_prompt_empty_and_none_key(self) -> None:
        text = """Record key: none
Watches:
Reasoning:
"""
        prompt = review_due.parse_prompt(Path("reviews/empty.md"), text)
        self.assertIsNone(prompt.key)
        self.assertEqual(prompt.watches, [])
        self.assertEqual(prompt.reasoning, "unstated")
        self.assertIsNone(prompt.jules)
        self.assertEqual(prompt.jules_note, "no Jules line")

        text_empty = "Record key: \n"
        prompt_empty = review_due.parse_prompt(Path("reviews/empty2.md"), text_empty)
        self.assertIsNone(prompt_empty.key)

    def test_latest_record(self) -> None:
        tracked = [
            "docs/gameplay-2026-10-01.md",
            "docs/gameplay-2026-10-30.md",
            "plans/archive/gameplay_2026-11-04.md",
            "docs/other-2026-11-05.md",
            "docs/unrelated.txt",
        ]
        best = review_due.latest_record("gameplay", tracked)
        self.assertEqual(best, ("plans/archive/gameplay_2026-11-04.md", "2026-11-04"))

        none_found = review_due.latest_record("nonexistent", tracked)
        self.assertIsNone(none_found)

    def test_reviewed_commit(self) -> None:
        text_with_reviewed = """# Report

Reviewed: 8dc78d3
Some other details...
"""
        self.assertEqual(review_due.reviewed_commit(text_with_reviewed), "8dc78d3")

        text_without = "# Report\nNo commit here\n"
        self.assertIsNone(review_due.reviewed_commit(text_without))

    def test_missing_watches(self) -> None:
        existing = self.temp_dir / "exists.txt"
        existing.write_text("hello", encoding="utf-8")

        prompt = review_due.Prompt(
            path=Path("plans/reference/reviews/demo.md"),
            key="demo",
            watches=["exists.txt", "missing.txt"],
        )
        problems = review_due.missing_watches([prompt], root=self.temp_dir)
        self.assertEqual(len(problems), 1)
        self.assertIn("watches a path that does not exist: missing.txt", problems[0])

    def test_load_prompts(self) -> None:
        prompts_dir = self.temp_dir / review_due.PROMPTS_DIR
        prompts_dir.mkdir(parents=True, exist_ok=True)
        readme = prompts_dir / "README.md"
        readme.write_text("Instructions", encoding="utf-8")

        sample = prompts_dir / "sample.md"
        sample.write_text("Record key: `sample`\nWatches: sample.txt\n", encoding="utf-8")

        loaded = review_due.load_prompts(root=self.temp_dir)
        self.assertEqual(len(loaded), 1)
        self.assertEqual(loaded[0].key, "sample")
        self.assertEqual(loaded[0].path, Path("plans/reference/reviews/sample.md"))

    def test_detail_unknown_key(self) -> None:
        prompts_dir = self.temp_dir / review_due.PROMPTS_DIR
        prompts_dir.mkdir(parents=True, exist_ok=True)
        sample = prompts_dir / "sample.md"
        sample.write_text("Record key: `sample`\nWatches: sample.txt\n", encoding="utf-8")

        out = io.StringIO()
        with redirect_stdout(out):
            code = review_due.detail("nonexistent", root=self.temp_dir)
        self.assertEqual(code, 2)
        self.assertIn("unknown review key 'nonexistent'", out.getvalue())

    def test_main_help_and_invalid_args(self) -> None:
        out = io.StringIO()
        with redirect_stdout(out):
            code_help = review_due.main(["--help"])
        self.assertEqual(code_help, 0)
        self.assertIn("Which of Dave's reviews has something to review", out.getvalue())

        out_err = io.StringIO()
        with redirect_stdout(out_err):
            code_extra = review_due.main(["arg1", "arg2"])
        self.assertEqual(code_extra, 2)


if __name__ == "__main__":
    unittest.main()
