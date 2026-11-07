"""Unit tests for tools/jules_preflight.py extra helper functions.

Covers the pure off_line formatter; git-backed reviewed_state tests are excluded.
"""

from __future__ import annotations

import unittest

from tools import jules_preflight as preflight


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



if __name__ == "__main__":
    unittest.main()
