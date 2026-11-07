"""PN-12: developer mode buys any skill, free; off, every gate behaves as before."""

from __future__ import annotations

import re
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent.parent / "scripts"
PANEL = (SCRIPTS / "skill_tree_panel.gd").read_text(encoding="utf-8")
CATALOGUE = (SCRIPTS / "settings_catalogue.gd").read_text(encoding="utf-8")


class DeveloperSkillsTest(unittest.TestCase):
    def test_waiver_needs_developer_mode_and_only_cost_or_prerequisites(self):
        body = re.search(r"func _developer_waives.*?(?=\n\n)", PANEL, re.S).group(0)
        self.assertIn("Session.developer_mode", body)
        self.assertIn("Progression.BLOCK_COST", body)
        self.assertIn("Progression.BLOCK_PREREQUISITES", body)
        self.assertNotIn("BLOCK_ALREADY_OWNED", body)

    def test_panel_and_buy_use_waiver_and_grant_without_spending(self):
        self.assertEqual(PANEL.count("_developer_waives("), 3)  # def + _rebuild + buy_skill
        buy = re.search(r"func buy_skill.*", PANEL, re.S).group(0)
        waived = buy.split("if not progression.purchase(")[0]
        self.assertIn("grant_temporary(skill_id)", waived)
        self.assertNotIn("hive.take", waived)

    def test_tip_no_longer_claims_to_change_nothing(self):
        tip = re.search(r'"key": "developer_mode".*?"tip": "([^"]*)"', CATALOGUE, re.S).group(1)
        self.assertNotIn("Changes nothing about how a run plays", tip)
        self.assertIn("skill", tip)


if __name__ == "__main__":
    unittest.main()
