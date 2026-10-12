"""SP-9: hive soil blocks drawn from Dave's soil_block art, crumbling as mined.

Static checks on scripts/soil_block.gd against the generated catalogue, plus
the quarter-to-frame rule replayed in Python from the constants it reads."""
from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOIL = (ROOT / "scripts" / "soil_block.gd").read_text(encoding="utf-8")
CAT = (ROOT / "scripts" / "sprite_catalogue.gd").read_text(encoding="utf-8")


def catalogue_frames() -> list[str]:
    m = re.search(r"SOIL_BLOCK_FRAMES: Array\[String\] = \[([^\]]+)\]", CAT)
    return re.findall(r'"([^"]+)"', m.group(1))


def stage_frames() -> list[str]:
    m = re.search(r"STAGE_FRAMES: Array\[String\] = \[([^\]]+)\]", SOIL)
    return re.findall(r'"([^"]+)"', m.group(1))


def frame_for(fraction: float) -> int:
    quarter = max(0, min(3, int(fraction * 4.0)))
    return catalogue_frames().index(stage_frames()[quarter])


class SoilArt(unittest.TestCase):
    def test_uses_the_catalogue_soil_sheet(self):
        self.assertIn("SpriteCatalogue.SOIL_BLOCK_SHEET", SOIL)
        self.assertIn("SpriteCatalogue.SOIL_BLOCK_HFRAMES", SOIL)

    def test_stages_are_5_then_4_2_1(self):
        self.assertEqual(stage_frames(), ["5", "4", "2", "1"])
        self.assertEqual(catalogue_frames(), ["1", "2", "4", "5"])

    def test_each_quarter_maps_to_its_frame(self):
        names = catalogue_frames()
        for fraction, want in ((0.0, "5"), (0.24, "5"), (0.25, "4"), (0.49, "4"),
                               (0.5, "2"), (0.74, "2"), (0.75, "1"), (0.99, "1")):
            self.assertEqual(names[frame_for(fraction)], want, fraction)

    def test_footprint_is_the_anchor_plus_the_side_height(self):
        self.assertIn("SIDE_HEIGHT_PX := 14.0", SOIL)
        self.assertIn("SOIL_BLOCK_ANCHOR.y + SIDE_HEIGHT_PX", SOIL)
        self.assertIn("SOIL_BLOCK_ANCHOR := Vector2(16.0, 9.0)", CAT)

    def test_cell_art_off_keeps_the_flat_mass(self):
        self.assertIn("if not Session.use_cell_sprites:", SOIL)
        self.assertIn("SOIL_COLOR.lerp(", SOIL)

    def test_frame_is_set_only_when_it_changes(self):
        self.assertRegex(SOIL, r"if frame == _art_frame:\s+return")

    def test_marker_ring_and_label_remain(self):
        for name in ("marker", "selection_ring", "progress_label"):
            self.assertIn(name, SOIL)


if __name__ == "__main__":
    unittest.main()
