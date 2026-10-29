"""Unit tests for tools/sprites.py's table and layout parsing functions."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from sprites import SpriteError, _hex_colour, _parse_grid, _state_name, parse_table  # noqa: E402


class SpritesHelpersTests(unittest.TestCase):
    def test_hex_colour(self):
        self.assertEqual(_hex_colour("#ff8000", "test"), (255, 128, 0))
        self.assertEqual(_hex_colour("FF8000", "test"), (255, 128, 0))
        with self.assertRaises(SpriteError) as ctx:
            _hex_colour("#ff800", "test")
        self.assertIn("not RRGGBB", str(ctx.exception))

    def test_parse_table(self):
        text = (
            "# Ignore pre-header comments or docs\n"
            "Some documentation before the table.\n\n"
            "| family | file | shows | view | layout | frames | levels | anchor | variants |\n"
            "| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
            "| simple | simple.png | simple sprite | hive | single | 1 | - | - | - |\n"
            "| complex | complex.aseprite | complex sprite | meadow | layers | 3 | 2/5 | 3,4 | dark: ff0000>800000, 00ff00>008000; pale: ff0000>ffcccc |\n"
        )
        rows = parse_table(text)
        self.assertEqual(len(rows), 2)

        r0 = rows[0]
        self.assertEqual(r0.family, "simple")
        self.assertEqual(r0.file, "simple.png")
        self.assertEqual(r0.shows, "simple sprite")
        self.assertEqual(r0.view, "hive")
        self.assertEqual(r0.layout, "single")
        self.assertEqual(r0.frames, 1)
        self.assertEqual(r0.levels, [])
        self.assertIsNone(r0.anchor)
        self.assertEqual(r0.variants, {})

        r1 = rows[1]
        self.assertEqual(r1.family, "complex")
        self.assertEqual(r1.file, "complex.aseprite")
        self.assertEqual(r1.shows, "complex sprite")
        self.assertEqual(r1.view, "meadow")
        self.assertEqual(r1.layout, "layers")
        self.assertEqual(r1.frames, 3)
        self.assertEqual(r1.levels, [2, 5])
        self.assertEqual(r1.anchor, (3, 4))
        expected_variants = {
            "dark": {
                (255, 0, 0): (128, 0, 0),
                (0, 255, 0): (0, 128, 0),
            },
            "pale": {
                (255, 0, 0): (255, 204, 204),
            },
        }
        self.assertEqual(r1.variants, expected_variants)

    def test_parse_table_errors(self):
        # Row with eight cells
        eight_cells = (
            "| family | file | shows | view | layout | frames | levels | anchor | variants |\n"
            "| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
            "| f | f.png | s | hive | single | 1 | - | - |\n"
        )
        with self.assertRaises(SpriteError) as ctx:
            parse_table(eight_cells)
        self.assertIn("has 8 cells, expected 9", str(ctx.exception))

        # View not in VIEWS
        invalid_view = (
            "| family | file | shows | view | layout | frames | levels | anchor | variants |\n"
            "| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
            "| f | f.png | s | invalid_view | single | 1 | - | - | - |\n"
        )
        with self.assertRaises(SpriteError) as ctx:
            parse_table(invalid_view)
        self.assertIn("view 'invalid_view' is not one of", str(ctx.exception))

        # Frames not a whole number
        invalid_frames = (
            "| family | file | shows | view | layout | frames | levels | anchor | variants |\n"
            "| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
            "| f | f.png | s | hive | single | abc | - | - | - |\n"
        )
        with self.assertRaises(SpriteError) as ctx:
            parse_table(invalid_frames)
        self.assertIn("frames 'abc' is not a whole number", str(ctx.exception))

        # Variant with no '>' pair
        invalid_variant = (
            "| family | file | shows | view | layout | frames | levels | anchor | variants |\n"
            "| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
            "| f | f.png | s | hive | single | 1 | - | - | dark: ff0000 |\n"
        )
        with self.assertRaises(SpriteError):
            parse_table(invalid_variant)

        # Text with no header row
        no_header = "| simple | simple.png | simple sprite | hive | single | 1 | - | - | - |\n"
        with self.assertRaises(SpriteError) as ctx:
            parse_table(no_header)
        self.assertIn("has no table with the header", str(ctx.exception))

    def test_parse_grid(self):
        fw, fh, names = _parse_grid("grid 16x24 rows=left,right", "test_family")
        self.assertEqual((fw, fh, names), (16, 24, ["left", "right"]))

        with self.assertRaises(SpriteError) as ctx:
            _parse_grid("grid 16 rows=a", "test_family")
        self.assertIn("layout must read 'grid WxH rows=name,name,...'", str(ctx.exception))

        with self.assertRaises(SpriteError) as ctx:
            _parse_grid("grid 16x16", "test_family")
        self.assertIn("layout must read 'grid WxH rows=name,name,...'", str(ctx.exception))

    def test_state_name(self):
        self.assertEqual(_state_name("base.substate.active"), "active")
        self.assertEqual(_state_name("simple_state"), "simple_state")


if __name__ == "__main__":
    unittest.main()
