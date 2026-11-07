"""Unit tests for pure helper functions in tools/sprites.py."""
from __future__ import annotations

import struct
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from sprites import (  # noqa: E402
    Built,
    Image,
    Row,
    _gd_canon,
    _res_path,
    catalogue_text,
    read_aseprite,
)


class TestSpritesGdHelpers(unittest.TestCase):
    def test_res_path(self) -> None:
        p = Path("assets/sprites/hive/comb.png")
        self.assertEqual(_res_path(p), "res://assets/sprites/hive/comb.png")


    def test_gd_canon(self) -> None:
        s1 = "const A := [1, 2, ]\nconst B := Vector2(0, 0)\n"
        s2 = "const A := [1, 2]\nconst B := Vector2(0, 0)"
        self.assertEqual(_gd_canon(s1), _gd_canon(s2))


    def test_catalogue_text(self) -> None:
        row = Row(
            family="test_flower",
            file="test_flower.png",
            shows="Test flower sprite",
            view="iso",
            layout="single",
            frames=1,
            levels=[],
            anchor=(8, 8),
            variants={},
        )
        built = Built(
            row=row,
            frame_size=(16, 16),
            hframes=1,
            vframes=1,
            frame_names=["frame"],
            gutter=1,
            sheets={"test_flower_sheet.png": Image.blank(18, 18)},
        )
        sheet_dirs = {"test_flower": Path("assets/sprites/flowers")}
        text = catalogue_text([built], sheet_dirs)
        self.assertIn('const TEST_FLOWER_SHEET := preload("res://assets/sprites/flowers/test_flower_sheet.png")', text)
        self.assertIn("const TEST_FLOWER_FRAME_SIZE := Vector2i(16, 16)", text)
        self.assertIn("const TEST_FLOWER_CELL_GUTTER := 1", text)
        self.assertIn("const TEST_FLOWER_CELL_SIZE := Vector2i(18, 18)", text)
        self.assertIn("const TEST_FLOWER_HFRAMES := 1", text)
        self.assertIn("const TEST_FLOWER_VFRAMES := 1", text)
        self.assertIn('const TEST_FLOWER_FRAMES: Array[String] = ["frame"]', text)
        self.assertIn("const TEST_FLOWER_ANCHOR := Vector2(8.0, 8.0)", text)
        self.assertIn('const TEST_FLOWER_VIEW := "iso"', text)


    def test_catalogue_text_with_variants_and_levels(self) -> None:
        row = Row(
            family="brood",
            file="brood.aseprite",
            shows="Brood cell",
            view="flat",
            layout="layers",
            frames=3,
            levels=[10, 20],
            anchor=None,
            variants={"alt": {}},
        )
        built = Built(
            row=row,
            frame_size=(20, 20),
            hframes=3,
            vframes=1,
            frame_names=["empty", "egg", "larva"],
            gutter=0,
            sheets={
                "brood_sheet.png": Image.blank(60, 20),
                "brood_alt_sheet.png": Image.blank(60, 20),
            },
        )
        sheet_dirs = {"brood": Path("assets/sprites/hive")}
        text = catalogue_text([built], sheet_dirs)
        self.assertIn('const BROOD_SHEET := preload("res://assets/sprites/hive/brood_sheet.png")', text)
        self.assertIn('const BROOD_ALT_SHEET := preload("res://assets/sprites/hive/brood_alt_sheet.png")', text)
        self.assertIn("const BROOD_LEVELS: Array[int] = [10, 20]", text)
        self.assertIn("const BROOD_ANCHOR := Vector2(10.0, 10.0)", text)


    def test_read_aseprite_header_errors(self) -> None:
        with self.assertRaises(ValueError) as ctx:
            read_aseprite(b"short")
        self.assertIn("not an Aseprite file", str(ctx.exception))

        header = bytearray(128)
        struct.pack_into("<H", header, 4, 0xA5E0)
        struct.pack_into("<HHHH", header, 6, 1, 16, 16, 16)  # depth = 16 (unsupported)
        with self.assertRaises(ValueError) as ctx:
            read_aseprite(bytes(header))
        self.assertIn("colour depth 16 is not supported", str(ctx.exception))

        header = bytearray(128)
        struct.pack_into("<H", header, 4, 0xA5E0)
        struct.pack_into("<HHHH", header, 6, 2, 16, 16, 32)  # frames = 2 (unsupported)
        with self.assertRaises(ValueError) as ctx:
            read_aseprite(bytes(header))
        self.assertIn("2 animation frames; the exporter reads one frame", str(ctx.exception))

        header = bytearray(128 + 16)
        struct.pack_into("<H", header, 4, 0xA5E0)
        struct.pack_into("<HHHH", header, 6, 1, 16, 16, 32)  # depth = 32, frames = 1
        struct.pack_into("<IHHH", header, 128, 16, 0x1234, 0, 0)  # bad magic
        with self.assertRaises(ValueError) as ctx:
            read_aseprite(bytes(header))
        self.assertIn("bad frame header", str(ctx.exception))



if __name__ == "__main__":
    unittest.main()
