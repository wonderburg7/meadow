"""Unit tests for tools/create_grass_sprite.py.

Tests cover:
- top_bounds and on_top helper logic.
- draw_sprite output file generation, RGBA format, 32x32 dimensions.
- Every pixel is transparent or one of the module's named colours (the
  no-filtering, no-antialiasing promise).

Both tests skip when Pillow is missing, since the tool imports it at load.
"""

import sys
from pathlib import Path
import tempfile
import unittest

try:
    from PIL import Image
except ImportError:
    Image = None

# tools/create_grass_sprite.py imports PIL unconditionally, so only import it
# when Pillow is present.
if Image is not None:
    from tools import create_grass_sprite
else:
    create_grass_sprite = None


class TestCreateGrassSpriteTool(unittest.TestCase):
    @unittest.skipIf(Image is None, "Pillow is not installed")
    def test_top_bounds_and_on_top(self) -> None:
        self.assertIsNone(create_grass_sprite.top_bounds(-1))
        self.assertIsNone(create_grass_sprite.top_bounds(26))

        # Test boundary rows
        self.assertEqual(create_grass_sprite.top_bounds(0), (8, 23))
        self.assertEqual(create_grass_sprite.top_bounds(7), (1, 30))
        self.assertEqual(create_grass_sprite.top_bounds(8), (0, 31))
        self.assertEqual(create_grass_sprite.top_bounds(17), (0, 31))
        self.assertEqual(create_grass_sprite.top_bounds(25), (8, 23))

        # Test on_top helper
        self.assertTrue(create_grass_sprite.on_top(8, 0))
        self.assertTrue(create_grass_sprite.on_top(23, 0))
        self.assertFalse(create_grass_sprite.on_top(7, 0))
        self.assertFalse(create_grass_sprite.on_top(24, 0))
        self.assertFalse(create_grass_sprite.on_top(10, -1))

    @unittest.skipIf(Image is None, "Pillow is not installed")
    def test_draw_sprite(self) -> None:
        allowed_colors = {
            create_grass_sprite.TRANSPARENT,
            create_grass_sprite.SOIL_DARK,
            create_grass_sprite.SOIL_MID,
            create_grass_sprite.SOIL_LIGHT,
            create_grass_sprite.GRASS_SHADE,
            create_grass_sprite.GRASS_BASE,
            create_grass_sprite.GRASS_LIGHT,
            create_grass_sprite.GRASS_SUN,
        }

        with tempfile.TemporaryDirectory() as tmp_dir:
            out_path = Path(tmp_dir) / "sub" / "grass_test.png"
            create_grass_sprite.draw_sprite(out_path)

            self.assertTrue(out_path.exists())

            with Image.open(out_path) as img:
                self.assertEqual(img.size, (32, 32))
                self.assertEqual(img.mode, "RGBA")

                # Verify every pixel is in allowed_colors (no anti-aliasing / filtering)
                pixels = img.load()
                for y in range(32):
                    for x in range(32):
                        px = pixels[x, y]
                        self.assertIn(
                            px,
                            allowed_colors,
                            f"Pixel at ({x}, {y}) has unexpected color {px}",
                        )


if __name__ == "__main__":
    unittest.main()
