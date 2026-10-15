"""SP-10: hive soil and rock blocks draw in screen order, like comb cells.

Static checks on the scripts that set z_index, then runs
tests/sp10_soil_depth_test.gd in a headless Godot.

Requires a real Godot executable -- the headless run skips where none is installed.

Run with: python -m unittest tests.test_sp10_soil_depth
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/sp10_soil_depth_test.gd"
TIMEOUT_SECONDS = 180


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


class SoilDepthStatic(unittest.TestCase):
    def test_shared_depth_is_two_rows_plus_column(self):
        shapes = read("scripts/shapes.gd")
        self.assertIn("static func hex_draw_depth(hex: Vector2i) -> int:", shapes)
        self.assertIn("return 2 * hex.y + hex.x", shapes)

    def test_comb_cell_uses_the_shared_depth(self):
        cell = read("scripts/hive_cell.gd")
        self.assertIn("z_index = Shapes.hex_draw_depth(axial)", cell)
        self.assertNotIn("2 * axial.y + axial.x", cell)

    def test_soil_block_sets_depth_in_setup(self):
        soil = read("scripts/soil_block.gd")
        setup = soil[soil.index("func setup(hex: Vector2i)"):]
        setup = setup[:setup.index("\n\n")]
        self.assertIn("z_index = Shapes.hex_draw_depth(hex)", setup)

    def test_rock_block_sets_depth_in_setup(self):
        rock = read("scripts/rock_block.gd")
        setup = rock[rock.index("func setup(hex: Vector2i)"):]
        self.assertIn("z_index = Shapes.hex_draw_depth(hex)", setup)

    def test_no_other_block_or_cell_sets_its_own_depth(self):
        for rel in ("scripts/soil_block.gd", "scripts/rock_block.gd", "scripts/hive_cell.gd"):
            self.assertNotIn("2 * axial.y", read(rel), rel)


class SoilDepthHeadless(unittest.TestCase):
    def test_blocks_and_cells_draw_in_screen_order(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT), "--script", TEST_SCRIPT],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=TIMEOUT_SECONDS,
        )
        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("SP10 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("SP10 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
