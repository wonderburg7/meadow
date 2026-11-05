"""Unit tests for pure helper functions in tools/jules_efficiency.py.

Covers report_path, scope_path, report_focus and next_topic.
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))
import jules_efficiency as efficiency


class JulesEfficiencyHelpersTest(unittest.TestCase):
    def test_report_path_formats_expected_markdown_file_path(self):
        self.assertEqual(efficiency.report_path(2), "docs/jules-efficiency/e-2.md")
        self.assertEqual(efficiency.report_path(10), "docs/jules-efficiency/e-10.md")
        self.assertEqual(efficiency.report_path(100), "docs/jules-efficiency/e-100.md")

    def test_scope_path_accepts_positive_even_e_numbers(self):
        self.assertEqual(efficiency.scope_path("E-2"), "docs/jules-efficiency/e-2.md")
        self.assertEqual(efficiency.scope_path("E-4"), "docs/jules-efficiency/e-4.md")
        self.assertEqual(efficiency.scope_path("E-12"), "docs/jules-efficiency/e-12.md")
        self.assertEqual(efficiency.scope_path("E-100"), "docs/jules-efficiency/e-100.md")

    def test_scope_path_accepts_odd_e_numbers_since_the_kind_word_decides(self):
        # 5 Nov 2026: an efficiency turn is offered when a topic is due, so its number may be odd.
        self.assertEqual(efficiency.scope_path("E-37"), "docs/jules-efficiency/e-37.md")
        self.assertEqual(efficiency.scope_path("E-1"), "docs/jules-efficiency/e-1.md")

    def test_report_focus_reads_the_header_then_falls_back_to_the_old_rotation(self):
        self.assertEqual(efficiency.report_focus("- Focus: code navigation and understanding ownership\n", 37),
                         efficiency.FOCUSES[1])
        self.assertEqual(efficiency.report_focus("Focus: Slice briefs and acceptance criteria  (due: x)\n", 5),
                         efficiency.FOCUSES[0])
        self.assertEqual(efficiency.report_focus("# E-8 -- qualified\n", 8), efficiency.FOCUSES[3])
        self.assertEqual(efficiency.report_focus("# E-14\n", 14), efficiency.FOCUSES[0])
        self.assertIsNone(efficiency.report_focus("# no header\n", 37))

    def test_next_topic_takes_the_oldest_due_topic(self):
        states = [
            (efficiency.FOCUSES[0], "rests", "last run 2026-11-05", "2026-11-05"),
            (efficiency.FOCUSES[1], "due", "30 commits", "2026-10-01"),
            (efficiency.FOCUSES[2], "due", "25 commits", "2026-09-01"),
            (efficiency.FOCUSES[3], "quiet", "3 commits", "2026-09-01"),
        ]
        focus, reason, skipped = efficiency.next_topic(states)
        self.assertEqual((focus, reason), (efficiency.FOCUSES[2], "25 commits"))
        self.assertEqual(len(skipped), 2)
        never = [(efficiency.FOCUSES[4], "due", "first run: no report yet", "")] + states
        self.assertEqual(efficiency.next_topic(never)[0], efficiency.FOCUSES[4])
        self.assertEqual(efficiency.next_topic([states[0], states[3]])[0], None)

    def test_scope_path_rejects_zero_and_leading_zeroes(self):
        self.assertIsNone(efficiency.scope_path("E-0"))
        self.assertIsNone(efficiency.scope_path("E-02"))
        self.assertIsNone(efficiency.scope_path("E-004"))

    def test_scope_path_rejects_negative_and_malformed_identifiers(self):
        self.assertIsNone(efficiency.scope_path("E--2"))
        self.assertIsNone(efficiency.scope_path("E-"))
        self.assertIsNone(efficiency.scope_path("E-two"))
        self.assertIsNone(efficiency.scope_path("e-2"))
        self.assertIsNone(efficiency.scope_path("J-2"))
        self.assertIsNone(efficiency.scope_path("E-2-extra"))
        self.assertIsNone(efficiency.scope_path(""))


if __name__ == "__main__":
    unittest.main()
