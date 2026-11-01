"""HS-2: hard soil fills the outer half of the hive's soil.

Run part (test_scenarios/hs2_hard_soil.json): a soft block is accepted as a
dig order, a hard block is refused before Mighty Mandible and accepted after.
The scenario's one rejection is expected, so the run itself reports "failed"
on its action problems; this test reads the action log instead.
Static part: the colour distances and the rough halfway edge.
"""

from __future__ import annotations

import math
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "hs2_hard_soil.json"
INTERIOR = 6
DEPTH = 12


def _colour(rel: str, name: str):
    text = (ROOT / rel).read_text(encoding="utf-8")
    m = re.search(r"const " + name + r" := Color\(([\d.]+), ([\d.]+), ([\d.]+)\)", text)
    assert m, name
    return tuple(float(x) for x in m.groups())


def _oklab(rgb):
    r, g, b = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in rgb]
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


def _roundi(x: float) -> int:
    """GDScript roundi: halves round away from zero."""
    return int(math.floor(x + 0.5)) if x >= 0 else -int(math.floor(-x + 0.5))


def _ring(q: int, r: int) -> int:
    return max(abs(q), abs(r), abs(q + r))


def hard_soil_start_ring(q: int, r: int, fraction: float = 0.5) -> int:
    """Mirror of SoilBlock.hard_soil_start_ring in scripts/soil_block.gd."""
    base = INTERIOR + _roundi(DEPTH * fraction)
    bearing = math.atan2(r * 0.866, q + r * 0.5)
    wobble = DEPTH * 0.15 * (0.6 * math.sin(5.0 * bearing + 1.3) + 0.4 * math.sin(11.0 * bearing + 0.4))
    notch = 1 if abs(math.sin(q * 12.9898 + r * 78.233)) > 0.85 else 0
    return max(INTERIOR + 2, min(INTERIOR + DEPTH, base + _roundi(wobble) + notch))


class StaticTest(unittest.TestCase):
    def test_colour_distances(self):
        hard = _oklab(_colour("scripts/soil_block.gd", "HARD_SOIL_COLOR"))
        soil = _oklab(_colour("scripts/soil_block.gd", "SOIL_COLOR"))
        rock = _oklab(_colour("scripts/rock_block.gd", "ROCK_COLOR"))
        self.assertGreaterEqual(math.dist(hard, soil), 0.06)
        self.assertGreaterEqual(math.dist(hard, rock), 0.05)

    def test_edge_is_rough_and_roughly_halfway(self):
        rings = set()
        for q in range(-20, 21):
            for r in range(-20, 21):
                if INTERIOR + 1 <= _ring(q, r) < INTERIOR + DEPTH:
                    start = hard_soil_start_ring(q, r)
                    rings.add(start)
                    self.assertTrue(8 <= start <= 18, (q, r, start))
        self.assertGreaterEqual(len(rings), 3)

    def test_ring_nine_never_hard_and_eighteen_always_hard(self):
        for q in range(-20, 21):
            for r in range(-20, 21):
                ring = _ring(q, r)
                if ring == 18:
                    self.assertGreaterEqual(ring, hard_soil_start_ring(q, r))
                if ring == 9:
                    self.assertLess(ring, hard_soil_start_ring(q, r), (q, r))


class HardSoilRunTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(FIXTURE, godot_path, timeout=600, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        cls.orders = [e for e in load_entries(session_file)
                      if e.get("type") == "action" and e.get("do") == "queue_mine"]

    def test_hard_block_refused_then_accepted(self):
        self.assertEqual([a.get("result") for a in self.orders], ["accepted", "rejected", "accepted"])


if __name__ == "__main__":
    unittest.main()
