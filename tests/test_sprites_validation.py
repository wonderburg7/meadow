"""Isolated unit tests for tools/sprites.py sprite table validation."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from sprites import SpriteError, parse_table  # noqa: E402


class SpritesTableValidationTests(unittest.TestCase):
    HEADER = (
        "| family | file | shows | view | layout | frames | levels | anchor | variants |\n"
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
    )

    def test_valid_multi_level_signed_anchor_row(self):
        table = (
            self.HEADER
            + "| queen | queen.aseprite | Queen bee | hive | layers | 4 | -1/0/1/2 | -5,10 | dark: ff0000>800000 |\n"
        )
        rows = parse_table(table)
        self.assertEqual(len(rows), 1)
        row = rows[0]
        self.assertEqual(row.family, "queen")
        self.assertEqual(row.file, "queen.aseprite")
        self.assertEqual(row.shows, "Queen bee")
        self.assertEqual(row.view, "hive")
        self.assertEqual(row.layout, "layers")
        self.assertEqual(row.frames, 4)
        self.assertEqual(row.levels, [-1, 0, 1, 2])
        self.assertEqual(row.anchor, (-5, 10))
        self.assertEqual(
            row.variants,
            {"dark": {(255, 0, 0): (128, 0, 0)}},
        )

    def test_reject_empty_variant_name(self):
        table = (
            self.HEADER
            + "| bee | bee.png | Bee | hive | single | 1 | - | - | : ff0000>800000 |\n"
        )
        with self.assertRaises(SpriteError) as ctx:
            parse_table(table)
        self.assertIn("variant ': ff0000>800000' needs name: RRGGBB>RRGGBB", str(ctx.exception))

    def test_reject_invalid_hex_digits(self):
        table = (
            self.HEADER
            + "| bee | bee.png | Bee | hive | single | 1 | - | - | dark: fg0000>800000 |\n"
        )
        with self.assertRaises(ValueError) as ctx:
            parse_table(table)
        self.assertIn("invalid literal for int() with base 16", str(ctx.exception))

    def test_malformed_levels_raise_value_error(self):
        table = (
            self.HEADER
            + "| bee | bee.png | Bee | hive | single | 1 | 1/abc | - | - |\n"
        )
        with self.assertRaises(ValueError) as ctx:
            parse_table(table)
        self.assertIn("invalid literal for int() with base 10", str(ctx.exception))

    def test_malformed_anchor_raises_value_error(self):
        # Non-numeric component
        table_abc = (
            self.HEADER
            + "| bee | bee.png | Bee | hive | single | 1 | - | 10,abc | - |\n"
        )
        with self.assertRaises(ValueError):
            parse_table(table_abc)

        # Three components
        table_three = (
            self.HEADER
            + "| bee | bee.png | Bee | hive | single | 1 | - | 10,20,30 | - |\n"
        )
        with self.assertRaises(ValueError):
            parse_table(table_three)

        # Single component with no comma
        table_one = (
            self.HEADER
            + "| bee | bee.png | Bee | hive | single | 1 | - | 10 | - |\n"
        )
        with self.assertRaises(ValueError):
            parse_table(table_one)


if __name__ == "__main__":
    unittest.main()
