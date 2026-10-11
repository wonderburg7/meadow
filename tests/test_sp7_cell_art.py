"""SP-7: Dave's cell and block art -- the exporter layouts it needs, the comb
level rule, and the whole comb drawn from it."""
from __future__ import annotations

import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_sp2_sprites import BLUE, CLEAR, RED, ROOT, RepoFixture, ase_bytes, solid

import sprites  # noqa: E402  (test_sp2_sprites puts tools/ on the path)

CAT = (ROOT / "scripts" / "sprite_catalogue.gd").read_text(encoding="utf-8")
CELL = (ROOT / "scripts" / "hive_cell.gd").read_text(encoding="utf-8")

COMB_FAMILIES = (
    "WAX_CELL_NECTAR", "WAX_CELL_NECTAR_FERMENTED", "WAX_CELL_POLLEN", "WAX_CELL_HONEY",
    "WAX_CELL_ROYAL_JELLY", "WAX_CELL_BEE_BREAD", "WAX_CELL_BEE_BREAD_RIPE",
)


def levels(name: str) -> list[int]:
    m = re.search(name + r"_LEVELS: Array\[int\] = \[([\d, ]+)\]", CAT)
    return [int(x) for x in m.group(1).split(",")]


class NewLayouts(RepoFixture):
    def test_frames_layout_gives_each_layer_alone(self):
        one = ("cap.1", 0, 0, 2, 2, solid(2, 2, RED))
        two = ("cap.2", 2, 2, 2, 2, solid(2, 2, BLUE))
        (self.sprites / "comb" / "thing.aseprite").write_bytes(ase_bytes(4, 4, [one, two]))
        self.write_table("| thing | comb/thing.aseprite | caps | hive | frames | 2 | - | - | - |")
        self.assertEqual(self.run_tool(), 0, self.out)
        sheet = sprites.decode_png((self.sprites / "comb" / "thing_sheet.png").read_bytes())
        self.assertEqual(sheet.get(1, 1), bytes(RED))
        self.assertEqual(sheet.get(3, 3), bytes(CLEAR))         # no base under frame 0
        self.assertEqual(sheet.get(6 + 1, 1), bytes(CLEAR))     # frame 1 has no layer 1
        self.assertEqual(sheet.get(6 + 3, 3), bytes(BLUE))
        cat = (self.tmp / "scripts" / "sprite_catalogue.gd").read_text()
        self.assertIn('const THING_FRAMES: Array[String] = ["1", "2"]', cat)

    def test_single_leaves_hidden_layers_out(self):
        shown = ("block", 0, 0, 4, 4, solid(4, 4, BLUE))
        spare = ("spare", 0, 0, 4, 4, solid(4, 4, RED))
        data = bytearray(ase_bytes(4, 4, [shown, spare]))
        # Clear the second layer chunk's visible flag (the first flags word
        # after its chunk header).
        second = data.find(b"spare") - 18
        data[second] = 0
        (self.sprites / "comb" / "thing.aseprite").write_bytes(bytes(data))
        self.write_table("| thing | comb/thing.aseprite | a block | meadow | single | 1 | - | - | - |")
        self.assertEqual(self.run_tool(), 0, self.out)
        sheet = sprites.decode_png((self.sprites / "comb" / "thing_sheet.png").read_bytes())
        self.assertEqual(sheet.get(2, 2), bytes(BLUE))

    def test_a_cel_hanging_off_the_canvas_is_clipped_when_clear_there(self):
        cel = [CLEAR] * 16
        cel[3 * 4 + 3] = RED  # cel pixel (3, 3) lands on canvas (1, 1)
        base = ("base", 0, 0, 4, 4, solid(4, 4, BLUE))
        state = ("thing.one", -2, -2, 4, 4, cel)
        (self.sprites / "comb" / "thing.aseprite").write_bytes(ase_bytes(4, 4, [base, state]))
        self.write_table(self.ROW)
        self.assertEqual(self.run_tool(), 0, self.out)
        sheet = sprites.decode_png((self.sprites / "comb" / "thing_sheet.png").read_bytes())
        self.assertEqual(sheet.get(6 + 1 + 1, 1 + 1), bytes(RED))

    def test_drawn_pixels_off_the_canvas_still_fail(self):
        cel = [CLEAR] * 16
        cel[0] = RED  # cel pixel (0, 0) lands on canvas (-2, -2)
        base = ("base", 0, 0, 4, 4, solid(4, 4, BLUE))
        state = ("thing.one", -2, -2, 4, 4, cel)
        (self.sprites / "comb" / "thing.aseprite").write_bytes(ase_bytes(4, 4, [base, state]))
        self.write_table(self.ROW)
        self.assertEqual(self.run_tool(), 1)
        self.assertTrue(any("outside the 4x4 canvas" in line for line in self.out), self.out)


class CombLevels(unittest.TestCase):
    def test_top_frame_is_the_full_cell_and_the_rest_share_equally(self):
        for fam in COMB_FAMILIES:
            lv = levels(fam)
            self.assertEqual(lv[-2:], [99, 100], fam)
            steps = [b - a for a, b in zip([0] + lv[:-2], lv[:-2])] + [lv[-2] - lv[-3]]
            self.assertLessEqual(max(steps) - min(steps), 2, (fam, lv))

    def test_larva_stages_share_development_equally(self):
        lv = levels("WAX_CELL_LARVA")
        self.assertEqual(len(lv), 9)
        self.assertEqual(lv[-1], 100)
        for i, bound in enumerate(lv, start=1):
            self.assertAlmostEqual(bound, 100 * i / 9, delta=0.6)


class CombDrawing(unittest.TestCase):
    def test_every_cell_sheet_is_in_the_art_table(self):
        for fam in COMB_FAMILIES + ("WAX_CELL_LARVA",):
            self.assertIn(f"SpriteCatalogue.{fam}_SHEET", CELL)
            self.assertIn(f"SpriteCatalogue.{fam}_LEVELS", CELL)

    def test_each_content_picks_its_sheet(self):
        for sheet in ("jelly", "honey", "larva", "bee_bread", "bee_bread_ripe"):
            self.assertIn(f'art_sheet = "{sheet}"', CELL)

    def test_caps_follow_ripening_and_cover_closed_cells(self):
        self.assertIn("bee_bread_ripen_fraction() * stages", CELL)
        self.assertRegex(CELL, r"if is_closed:\s+cap_stage = SpriteCatalogue\.WAX_CELL_SEALED_HFRAMES")
        self.assertIn("not cap_sprite.visible", CELL)

    def test_the_old_recolour_variant_is_gone(self):
        table = (ROOT / "assets" / "sprites" / "SPRITES.md").read_text(encoding="utf-8")
        self.assertNotIn("fermented: 487908", table)
        self.assertTrue((ROOT / "assets/sprites/comb/wax_cell_nectar_fermented.aseprite").exists())


if __name__ == "__main__":
    unittest.main()
