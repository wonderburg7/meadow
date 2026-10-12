"""SP-4: nectar and pollen fill levels are drawn from the cell sprites."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CELL = (ROOT / "scripts" / "hive_cell.gd").read_text(encoding="utf-8")
CAT = (ROOT / "scripts" / "sprite_catalogue.gd").read_text(encoding="utf-8")
SETTINGS = (ROOT / "scripts" / "settings_catalogue.gd").read_text(encoding="utf-8")


def levels(name):
    m = re.search(name + r"_LEVELS: Array\[int\] = \[([\d, ]+)\]", CAT)
    return [int(x) for x in m.group(1).split(",")]


def fill_frame(lv, fraction):
    """Mirror of HiveCell.fill_frame."""
    if fraction <= 0.0:
        return 0
    pct = fraction * 100.0
    for i, bound in enumerate(lv):
        if pct <= bound + 0.0001:
            return i + 1
    return len(lv)


class FillSprites(unittest.TestCase):
    def test_levels_come_from_the_catalogue(self):
        self.assertIn("SpriteCatalogue.WAX_CELL_NECTAR_LEVELS", CELL)
        self.assertIn("SpriteCatalogue.WAX_CELL_POLLEN_LEVELS", CELL)
        self.assertNotRegex(CELL, r"\[10, 25, 40")

    def test_frame_choice(self):
        nectar = levels("WAX_CELL_NECTAR")
        self.assertEqual(fill_frame(nectar, 0.0), 0)
        self.assertEqual(fill_frame(nectar, 0.01), 1)
        self.assertEqual(fill_frame(nectar, 0.17), 1)
        self.assertEqual(fill_frame(nectar, 0.18), 2)
        self.assertEqual(fill_frame(nectar, 0.99), len(nectar) - 1)
        self.assertEqual(fill_frame(nectar, 1.0), len(nectar))
        pollen = levels("WAX_CELL_POLLEN")
        self.assertEqual(fill_frame(pollen, 0.5), 2)
        self.assertEqual(fill_frame(pollen, 0.51), 3)
        self.assertEqual(fill_frame(pollen, 1.0), 5)

    def test_gdscript_matches_the_rule(self):
        self.assertIn("percent <= float(levels[i])", CELL)
        self.assertIn("if fraction <= 0.0:\r\n\t\treturn 0" if "\r\n" in CELL else "if fraction <= 0.0:\n\t\treturn 0", CELL)

    def test_fermented_art_and_no_flat_body(self):
        self.assertIn("WAX_CELL_NECTAR_FERMENTED_SHEET", CAT)
        self.assertIn('art_sheet = "fermented"', CELL)
        self.assertTrue((ROOT / "assets/sprites/comb/wax_cell_nectar_fermented_sheet.png").exists())
        self.assertIn("_show_fill_art(art_sheet, art_frame)", CELL)
        self.assertRegex(CELL, r"color = Color\(color\.r, color\.g, color\.b, 0\.0\)")

    def test_frame_set_only_on_change(self):
        self.assertRegex(CELL, r"if key == _art_key:\s+return")

    def test_tip_names_filled_cells(self):
        self.assertIn("how full each store is", SETTINGS)


if __name__ == "__main__":
    unittest.main()
