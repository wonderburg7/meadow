"""The skill tree shows what is held but not spendable beside the spendable figure.

Source-level: the spendable snapshot (_stores) is unchanged, while the stores
text and a blocked skill's cost line name the sealed or unripe remainder,
measured against the same hive totals the HUD stores line uses.

Run with: python -m unittest tests.test_skill_tree_unspendable_note
"""

from __future__ import annotations

import unittest
from pathlib import Path

SRC = (Path(__file__).resolve().parent.parent / "scripts" / "skill_tree_panel.gd").read_text(encoding="utf-8")


class UnspendableNote(unittest.TestCase):
    def test_stores_text_names_the_remainder(self) -> None:
        self.assertIn("sealed or unripe)", SRC)
        self.assertIn("main.hive.total_honey()", SRC)
        self.assertIn("main.hive.total(STORE_CONTENT[key])", SRC)

    def test_blocked_tooltip_and_detail_carry_it(self) -> None:
        self.assertIn("_unspendable_note(skill) if state == STATE_BLOCKED", SRC)
        self.assertIn("if tile.state == STATE_BLOCKED:", SRC)

    def test_spendable_rule_untouched(self) -> None:
        self.assertIn("not cell.can_withdraw()", SRC)


if __name__ == "__main__":
    unittest.main()
