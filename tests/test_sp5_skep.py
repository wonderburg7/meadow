"""SP-5: the skep is drawn in the meadow, the rival hive is a darker recolour."""
import unittest
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # Pillow is missing (a Linux agent's VM, say): skip, don't error
    Image = None

ROOT = Path(__file__).resolve().parent.parent
HIVE = (ROOT / "scripts" / "hive.gd").read_text(encoding="utf-8")
RIVAL = (ROOT / "scripts" / "rival_hive.gd").read_text(encoding="utf-8")
CAT = (ROOT / "scripts" / "sprite_catalogue.gd").read_text(encoding="utf-8")
MEADOW = ROOT / "assets" / "sprites" / "meadow"


def luma(p):
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


class SkepSprites(unittest.TestCase):
    def test_hive_draws_the_skep_and_keeps_a_transparent_hit_square(self):
        self.assertIn("SpriteCatalogue.HIVE_SKEP_SHEET", HIVE)
        self.assertIn("PixelSprite.apply(skep, PixelSprite.MEADOW_SCALE)", HIVE)
        self.assertIn("Shapes.square_points(Vector2(60, 60))", HIVE)
        self.assertRegex(HIVE, r"color = Color\(0\.55, 0\.35, 0\.15, 0\.0\)")

    def test_skep_footprint_is_centred(self):
        # Frame 54x41 with anchor 27,20.5: the middle of the art.
        self.assertIn("HIVE_SKEP_ANCHOR := Vector2(27.0, 20.5)", CAT)
        self.assertIn("-SpriteCatalogue.HIVE_SKEP_ANCHOR * PixelSprite.MEADOW_SCALE", HIVE)

    def test_rival_uses_the_recolour_and_a_transparent_hit_square(self):
        self.assertIn("SpriteCatalogue.HIVE_SKEP_RIVAL_SHEET", RIVAL)
        self.assertRegex(RIVAL, r"body\.color = Color\(0\.42, 0\.24, 0\.30, 0\.0\)")
        self.assertIn("skep.modulate = RUIN_TINT", RIVAL)
        self.assertIn("skep.modulate = Color.WHITE", RIVAL)

    @unittest.skipIf(Image is None, "Pillow is not installed")
    def test_rival_sheet_is_darker_and_same_shape(self):
        a = Image.open(MEADOW / "hive_skep_sheet.png").convert("RGBA")
        b = Image.open(MEADOW / "hive_skep_rival_sheet.png").convert("RGBA")
        self.assertEqual(a.size, b.size)
        pa, pb = list(a.getdata()), list(b.getdata())
        self.assertEqual([p[3] for p in pa], [p[3] for p in pb])
        solid = [(x, y) for x, y in zip(pa, pb) if x[3] == 255]
        self.assertTrue(solid)
        self.assertTrue(all(luma(y) < luma(x) for x, y in solid))


if __name__ == "__main__":
    unittest.main()
