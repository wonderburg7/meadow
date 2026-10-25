"""Unit tests for pure helpers and id/text functions in tools/new_check.py."""

from datetime import date
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

from tools import new_check


class TestNewCheckHelpers(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp_dir, ignore_errors=True)

    def test_used_ids_and_next_free_id_when_none_used(self):
        ready_dir = self.tmp_dir / "ready"
        ready_dir.mkdir()
        blocked_file = self.tmp_dir / "blocked.md"
        archive_file = self.tmp_dir / "HANDS_ON_CHECKS_ARCHIVE.md"
        blocked_file.write_text("", encoding="utf-8")
        archive_file.write_text("", encoding="utf-8")

        fake_sources = (ready_dir, blocked_file, archive_file)
        with patch.object(new_check, "ID_SOURCES", fake_sources):
            self.assertEqual(new_check.used_ids(), set())
            self.assertEqual(new_check.next_free_id(), 1)

    def test_used_ids_and_next_free_id_with_gaps(self):
        ready_dir = self.tmp_dir / "ready"
        ready_dir.mkdir()
        (ready_dir / "C-1.md").write_text("# C-1 -- Test", encoding="utf-8")
        (ready_dir / "C-5.md").write_text("# C-5 -- Test", encoding="utf-8")

        blocked_file = self.tmp_dir / "blocked.md"
        blocked_file.write_text("Blocked C-3 and C-2", encoding="utf-8")

        archive_file = self.tmp_dir / "HANDS_ON_CHECKS_ARCHIVE.md"
        archive_file.write_text("Archived C-10", encoding="utf-8")

        fake_sources = (ready_dir, blocked_file, archive_file)
        with patch.object(new_check, "ID_SOURCES", fake_sources):
            self.assertEqual(new_check.used_ids(), {1, 2, 3, 5, 10})
            self.assertEqual(new_check.next_free_id(), 11)

    def test_record_text_formatting(self):
        text = new_check.record_text(42, "Check Title", "plans/now/ui.md", "dave")
        self.assertTrue(text.startswith("# C-42 -- Check Title\n"))
        self.assertIn("PASS: <the single condition, on this one line>", text)
        self.assertIn("If it fails, <what a failure would change", text)
        self.assertIn("Runner: dave", text)
        self.assertIn("Owner: `plans/now/ui.md`", text)

    def test_day_label_and_pass_heading(self):
        d = date(2026, 10, 25)
        self.assertEqual(new_check.day_label(d), "25 Oct 2026")
        self.assertEqual(new_check.pass_heading(d), "## 25 Oct 2026 -- Dave's hands-on pass")

    def test_insert_entries_new_heading(self):
        archive_text = (
            "# Hands-on check archive\n"
            "\n"
            "Preamble text\n"
            "\n"
            "## 10 Oct 2026 -- Dave's hands-on pass\n"
            "\n"
            "### C-1 -- old check\n"
        )
        heading = "## 25 Oct 2026 -- Dave's hands-on pass"
        block = "### C-2 -- new check\n\nPASS: ok"
        res = new_check.insert_entries(archive_text, heading, block)

        expected = (
            "# Hands-on check archive\n"
            "\n"
            "Preamble text\n"
            "\n"
            "## 25 Oct 2026 -- Dave's hands-on pass\n"
            "\n"
            "### C-2 -- new check\n"
            "\n"
            "PASS: ok\n"
            "\n"
            "## 10 Oct 2026 -- Dave's hands-on pass\n"
            "\n"
            "### C-1 -- old check\n"
        )
        self.assertEqual(res, expected)

    def test_insert_entries_existing_heading(self):
        archive_text = (
            "# Hands-on check archive\n"
            "\n"
            "Preamble text\n"
            "\n"
            "## 25 Oct 2026 -- Dave's hands-on pass\n"
            "\n"
            "### C-1 -- first check\n"
        )
        heading = "## 25 Oct 2026 -- Dave's hands-on pass"
        block = "### C-2 -- second check\n\nPASS: ok"
        res = new_check.insert_entries(archive_text, heading, block)

        expected = (
            "# Hands-on check archive\n"
            "\n"
            "Preamble text\n"
            "\n"
            "## 25 Oct 2026 -- Dave's hands-on pass\n"
            "\n"
            "### C-1 -- first check\n"
            "\n"
            "### C-2 -- second check\n"
            "\n"
            "PASS: ok\n"
        )
        self.assertEqual(res, expected)


if __name__ == "__main__":
    unittest.main()
