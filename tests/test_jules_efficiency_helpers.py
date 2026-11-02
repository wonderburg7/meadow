"""Unit tests for pure helper functions in tools/jules_efficiency.py.

Covers report_path and scope_path.
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

    def test_scope_path_rejects_odd_e_numbers(self):
        self.assertIsNone(efficiency.scope_path("E-1"))
        self.assertIsNone(efficiency.scope_path("E-3"))
        self.assertIsNone(efficiency.scope_path("E-11"))

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
