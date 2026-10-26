"""CT-1: a sealed cell takes a faint tone of what it holds.

Static part: the two presentation constants, and the strength formula
mirrored here, give the values the scenario asserts: quarter-full honey
between 0.10 and 0.13, full honey and full pollen at 0.28, an empty cell at 0.
Run part (test_scenarios/ct1_cell_tones.json): five built cells are stocked,
four are closed, and the scenario's own asserts read each cell's
tone_strength in the running game. Every stocking, closing and assert action
must be accepted, and no action may be left unresolved, so a failed assert
fails here.
"""

from __future__ import annotations

import math
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "ct1_cell_tones.json"
SRC = (ROOT / "scripts" / "hive_cell.gd").read_text(encoding="utf-8")
TONE_MIN = 0.06
TONE_MAX = 0.28


def tone_strength(fraction: float) -> float:
    """Mirror of hive_cell.gd::content_tone_strength."""
    if fraction <= 0.0:
        return 0.0
    step = math.ceil(min(max(fraction, 0.0), 1.0) * 8.0) / 8.0
    return TONE_MIN + (TONE_MAX - TONE_MIN) * step


class ToneFormulaTest(unittest.TestCase):
    def test_named_constants_in_the_cell_script(self):
        self.assertIn("const CONTENT_TONE_MIN := 0.06", SRC)
        self.assertIn("const CONTENT_TONE_MAX := 0.28", SRC)

    def test_tone_is_applied_to_art_and_cap(self):
        self.assertIn("static func content_tone(base: Color, strength: float) -> Color:", SRC)
        self.assertIn("empty_sprite.modulate = art_tint * tone", SRC)
        self.assertIn("cap_sprite.modulate = tone", SRC)

    def test_quarter_full_honey_is_faint_but_visible(self):
        self.assertTrue(0.10 <= tone_strength(50.0 / 200.0) <= 0.13)

    def test_full_honey_and_pollen_are_full_strength(self):
        self.assertAlmostEqual(tone_strength(200.0 / 200.0), 0.28)

    def test_empty_cell_has_no_tone(self):
        self.assertEqual(tone_strength(0.0), 0.0)

    def test_scenario_asserts_the_expected_values(self):
        text = FIXTURE.read_text(encoding="utf-8")
        self.assertIn('"min": 0.10, "max": 0.13', text)
        self.assertIn('"min": 0.0, "max": 0.0', text)


class CellToneRunTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(FIXTURE, godot_path, timeout=600, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        cls.actions = [e for e in load_entries(session_file) if e.get("type") == "action"]

    def _rows(self, verb: str) -> list:
        return [a.get("result") for a in self.actions if a.get("do") == verb]

    def test_five_cells_stocked(self):
        self.assertEqual(self._rows("set_cell_contents"), ["accepted"] * 5)

    def test_four_cells_closed(self):
        self.assertEqual(self._rows("close_cell"), ["accepted"] * 4)

    def test_all_six_tone_asserts_hold(self):
        self.assertEqual(self._rows("assert"), ["accepted"] * 6)

    def test_nothing_left_unresolved(self):
        self.assertNotIn("never_fired", [a.get("result") for a in self.actions])


if __name__ == "__main__":
    unittest.main()
