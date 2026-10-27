"""SP-3: cell-content colours match the new sprites and stay distinct."""
import itertools
import math
import re
import unittest
from pathlib import Path

SRC = (Path(__file__).resolve().parent.parent / "scripts" / "hive_cell.gd").read_text(encoding="utf-8")
NAMES = ["EMPTY", "NECTAR", "FERMENTED_NECTAR", "POLLEN", "HONEY_WET", "HONEY", "BROOD",
         "JELLY", "GYNE_BROOD", "CORPSE", "SITE", "BEE_BREAD", "BEE_BREAD_SEALED", "BEE_BREAD_RIPE",
         "PRE_FERMENTED_NECTAR"]


def colour(name):
    m = re.search(r"const " + name + r"_COLOR := Color\(([\d.]+), ([\d.]+), ([\d.]+)\)", SRC)
    assert m, name
    return tuple(float(x) for x in m.groups())


def oklab(rgb):
    r, g, b = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in rgb]
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


class ContentColours(unittest.TestCase):
    def test_sprite_fills(self):
        for name, rgb in (("NECTAR", (187, 248, 36)), ("POLLEN", (255, 123, 0))):
            for got, want in zip(colour(name), rgb):
                self.assertAlmostEqual(got * 255, want, delta=0.05)

    def test_pairs_are_distinct(self):
        bad = []
        for a, b in itertools.combinations(NAMES, 2):
            d = math.dist(oklab(colour(a)), oklab(colour(b)))
            if d < 0.10:
                bad.append((a, b, round(d, 3)))
        self.assertEqual(bad, [])

    def test_load_dot_uses_sprite_colours(self):
        bee = (Path(__file__).resolve().parent.parent / "scripts" / "bee.gd").read_text(encoding="utf-8")
        self.assertIn("Color(1.0, 0.48235, 0.0) if resource_type", bee)
        self.assertIn("Color(0.73333, 0.97255, 0.14118)", bee)


if __name__ == "__main__":
    unittest.main()
