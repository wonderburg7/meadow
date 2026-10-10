"""SP-2: the sprite exporter, the sprite table and the generated catalogue."""
from __future__ import annotations

import shutil
import struct
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import sprites  # noqa: E402

TABLE_HEAD = (
    "| Family | File | Shows | View | Layout | Frames | Levels | Anchor | Variants |\n"
    "| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
)
RED = (255, 0, 0, 255)
BLUE = (0, 0, 255, 255)
CLEAR = (0, 0, 0, 0)


def ase_bytes(width: int, height: int, layers: list[tuple[str, int, int, int, int, list[tuple]]], truncate=True) -> bytes:
    """A minimal RGBA .aseprite: layers are (name, x, y, w, h, pixels)."""
    chunks = b""
    for name, *_ in layers:
        nb = name.encode()
        body = struct.pack("<HHHHHHB3xH", 1, 0, 0, 0, 0, 0, 255, len(nb)) + nb
        chunks += struct.pack("<IH", len(body) + 6, 0x2004) + body
    for index, (_n, x, y, w, h, px) in enumerate(layers):
        raw = b"".join(bytes(p) for p in px)
        comp = zlib.compress(raw)
        if truncate:
            comp = comp[:-4]  # Resprite omits the closing checksum
        body = struct.pack("<HhhBHh5xHH", index, x, y, 255, 2, 0, w, h) + comp
        chunks += struct.pack("<IH", len(body) + 6, 0x2005) + body
    count = len(layers) * 2
    frame = struct.pack("<IHHH2xI", 16 + len(chunks), 0xF1FA, count, 100, 0) + chunks
    header = struct.pack("<IHHHHH", 128 + len(frame), 0xA5E0, 1, width, height, 32).ljust(128, b"\0")
    return header + frame


def solid(w, h, colour):
    return [colour] * (w * h)


class RepoFixture(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        (self.tmp / "assets" / "sprites" / "comb").mkdir(parents=True)
        (self.tmp / "scripts").mkdir()
        self.sprites = self.tmp / "assets" / "sprites"
        self.out: list[str] = []

    def write_table(self, *rows: str):
        (self.sprites / "SPRITES.md").write_text(TABLE_HEAD + "\n".join(rows) + "\n", encoding="utf-8")

    def write_cell(self, state_pixels=None, name="thing"):
        base = ("base", 0, 0, 4, 4, solid(4, 4, BLUE))
        state = ("thing.one", 1, 1, 2, 2, state_pixels or solid(2, 2, RED))
        (self.sprites / "comb" / f"{name}.aseprite").write_bytes(ase_bytes(4, 4, [base, state]))

    def run_tool(self, check=False):
        return sprites.run(self.tmp, check, out=self.out.append)

    ROW = "| thing | comb/thing.aseprite | a thing | hive | layers | 2 | 100 | 2,2 | - |"


class ExporterTests(RepoFixture):
    def test_layers_flatten_with_a_gutter_and_write_the_catalogue(self):
        self.write_cell()
        self.write_table(self.ROW)
        self.assertEqual(self.run_tool(), 0, self.out)
        sheet = sprites.decode_png((self.sprites / "comb" / "thing_sheet.png").read_bytes())
        self.assertEqual((sheet.width, sheet.height), (2 * 6, 6))
        self.assertEqual(sheet.get(0, 0), bytes(CLEAR))      # gutter
        self.assertEqual(sheet.get(1, 1), bytes(BLUE))       # frame 0: base only
        self.assertEqual(sheet.get(2, 2), bytes(BLUE))
        self.assertEqual(sheet.get(6 + 2, 2), bytes(RED))    # frame 1: base plus state
        self.assertEqual(sheet.get(6 + 1, 1), bytes(BLUE))
        cat = (self.tmp / "scripts" / "sprite_catalogue.gd").read_text()
        for line in (
            'const THING_SHEET := preload("res://assets/sprites/comb/thing_sheet.png")',
            "const THING_FRAME_SIZE := Vector2i(4, 4)",
            "const THING_HFRAMES := 2",
            'const THING_FRAMES: Array[String] = ["base", "one"]',
            "const THING_ANCHOR := Vector2(2.0, 2.0)",
            "const THING_LEVELS: Array[int] = [100]",
        ):
            self.assertIn(line, cat)

    def test_check_is_clean_after_a_run_and_fails_on_stale_output(self):
        self.write_cell()
        self.write_table(self.ROW)
        self.assertEqual(self.run_tool(), 0)
        self.assertEqual(self.run_tool(check=True), 0, self.out)
        self.write_cell(solid(2, 2, (0, 255, 0, 255)))
        self.out.clear()
        self.assertEqual(self.run_tool(check=True), 1)
        self.assertTrue(any("stale" in line for line in self.out), self.out)
        (self.tmp / "scripts" / "sprite_catalogue.gd").write_text("# edited\n")
        self.write_cell()
        self.assertEqual(self.run_tool(check=True), 1)

    def test_a_recolour_variant_adds_a_swapped_sheet(self):
        self.write_cell()
        self.write_table(self.ROW.replace("| - |", "| sour: 0000FF>00FF00 |"))
        self.assertEqual(self.run_tool(), 0, self.out)
        sheet = sprites.decode_png((self.sprites / "comb" / "thing_sour_sheet.png").read_bytes())
        self.assertEqual(sheet.get(1, 1), bytes((0, 255, 0, 255)))
        self.assertEqual(sheet.get(6 + 2, 2), bytes(RED))
        self.assertIn("THING_SOUR_SHEET", (self.tmp / "scripts" / "sprite_catalogue.gd").read_text())

    def test_a_variant_naming_an_unused_colour_fails(self):
        self.write_cell()
        self.write_table(self.ROW.replace("| - |", "| sour: 123456>00FF00 |"))
        self.assertEqual(self.run_tool(), 1)
        self.assertTrue(any("not use" in line for line in self.out), self.out)

    def test_part_transparent_pixels_fail(self):
        self.write_cell(solid(2, 2, (255, 0, 0, 128)))
        self.write_table(self.ROW)
        self.assertEqual(self.run_tool(), 1)
        self.assertTrue(any("part-transparent" in line for line in self.out), self.out)

    def test_frame_count_must_match_the_table(self):
        self.write_cell()
        self.write_table(self.ROW.replace("| 2 |", "| 3 |"))
        self.assertEqual(self.run_tool(), 1)
        self.assertTrue(any("table says 3" in line for line in self.out), self.out)

    def test_an_art_file_without_a_row_fails(self):
        self.write_cell()
        self.write_cell(name="orphan")
        self.write_table(self.ROW)
        self.assertEqual(self.run_tool(), 1)
        self.assertTrue(any("orphan.aseprite: no row" in line for line in self.out), self.out)

    def test_guide_layers_are_ignored(self):
        base = ("base", 0, 0, 4, 4, solid(4, 4, BLUE))
        guide = ("_guide", 0, 0, 4, 4, solid(4, 4, (1, 2, 3, 255)))
        state = ("thing.one", 1, 1, 2, 2, solid(2, 2, RED))
        (self.sprites / "comb" / "thing.aseprite").write_bytes(ase_bytes(4, 4, [base, guide, state]))
        self.write_table(self.ROW)
        self.assertEqual(self.run_tool(), 0, self.out)

    def test_grid_art_must_leave_the_cell_edge_clear(self):
        sheet = [CLEAR] * 64  # 8x8 canvas, two 4x4 frames side by side
        for x in range(4, 8):
            for y in range(4):
                sheet[y * 8 + x] = RED
        layer = ("sheet", 0, 0, 8, 8, sheet)
        (self.sprites / "comb" / "thing.aseprite").write_bytes(ase_bytes(8, 8, [layer]))
        self.write_table("| thing | comb/thing.aseprite | x | meadow | grid 4x4 rows=a,b | 4 | - | - | - |")
        self.assertEqual(self.run_tool(), 1)
        self.assertTrue(any("edge of its grid cell" in line for line in self.out), self.out)

    def test_unexported_rows_build_nothing(self):
        (self.sprites / "comb" / "thing.aseprite").write_bytes(b"not parsed")
        self.write_table("| thing | comb/thing.aseprite | x | meadow | unexported | 32 | - | - | - |")
        self.assertEqual(self.run_tool(check=True), 1)  # only the empty catalogue is stale
        self.assertEqual(self.run_tool(), 0)
        self.assertFalse((self.sprites / "comb" / "thing_sheet.png").exists())

    def test_png_round_trip(self):
        img = sprites.Image(2, 1, bytearray(RED + CLEAR))
        back = sprites.decode_png(sprites.encode_png(img))
        self.assertEqual(back.pixels, img.pixels)


class RepoTests(unittest.TestCase):
    def test_the_repo_sprites_are_current(self):
        out: list[str] = []
        self.assertEqual(sprites.run(ROOT, True, out=out.append), 0, out)

    def test_the_cell_sheets_hold_the_plan_levels(self):
        cat = (ROOT / "scripts" / "sprite_catalogue.gd").read_text(encoding="utf-8")
        self.assertIn("const WAX_CELL_NECTAR_LEVELS: Array[int] = [10, 25, 40, 55, 70, 85, 100]", cat)
        self.assertIn("const WAX_CELL_POLLEN_LEVELS: Array[int] = [30, 60, 90, 100]", cat)
        self.assertIn("const WAX_CELL_NECTAR_HFRAMES := 8", cat)

    def test_the_empty_cup_is_the_retired_pngs_pixels(self):
        sheet = sprites.decode_png((ROOT / "assets/sprites/comb/wax_cell_nectar_sheet.png").read_bytes())
        cup = sheet.crop(1, 1, 32, 32)
        self.assertEqual(sum(1 for i in range(3, len(cup.pixels), 4) if cup.pixels[i]), 720)

    def test_hive_cell_reads_the_catalogue(self):
        src = (ROOT / "scripts" / "hive_cell.gd").read_text(encoding="utf-8")
        self.assertIn("const EMPTY_TEXTURE := SpriteCatalogue.WAX_CELL_NECTAR_SHEET", src)
        self.assertNotIn("wax.cell.empty", src)
        self.assertNotIn("EMPTY_TEXTURE_BASE", src)

    def test_the_old_environment_art_has_retired(self):
        env = ROOT / "assets" / "sprites" / "environment"
        self.assertEqual([p.name for p in env.glob("wax.cell.empty*")] if env.exists() else [], [])


if __name__ == "__main__":
    unittest.main()
