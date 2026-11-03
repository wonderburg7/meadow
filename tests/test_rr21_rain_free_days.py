"""RR-21: no ordinary random rain in a run's first two game days.

A run at a rain chance high enough to roll rain on every attempt shows no
rain before day 2 by default, rain once the days are past, and rain from the
start when a scenario sets `rain_free_days` to 0. The first crisis is covered
by tests/test_fc2_first_crisis.py. Requires a real Godot for the run tests.
"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once  # noqa: E402

MAIN = ROOT / "scripts" / "main.gd"
SECONDS_PER_DAY = 200.0


def _scenario(free_days: float | None) -> dict:
    actions = [
        {"do": "set_config", "key": "rain_chance_per_day", "value": 6.0},
        {"do": "set_config", "key": "rain_min_seconds", "value": 5.0},
        {"do": "set_config", "key": "rain_max_seconds", "value": 5.0},
    ]
    if free_days is not None:
        actions.append({"do": "set_config", "key": "rain_free_days", "value": free_days})
    return {
        "random_seed": 20261030, "run_type": "colony", "weather": True,
        "winter": False, "disease": False, "time_scale": 8, "cells": 8,
        "nectar_foragers": 0, "pollen_foragers": 0, "nurses": 3,
        "builders": 0, "miners": 0, "honey_makers": 0,
        "queen_laying_backup": "nurse",
        "stop": {"max_days": 4}, "actions": actions,
    }


def _rain_times(test: unittest.TestCase, free_days: float | None) -> list[float]:
    """Game times of the snapshots that show rain falling."""
    godot_path = find_godot()
    if not godot_path:
        test.skipTest("no Godot executable found -- this test needs a real headless boot")
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "rr21.json"
        path.write_text(json.dumps(_scenario(free_days)), encoding="utf-8")
        session_file = run_once(path, godot_path, timeout=600, fixed_fps=30)
    test.assertIsNotNone(session_file, "scenario run produced no session log")
    snaps = [e for e in load_entries(session_file) if e.get("type") == "snapshot"]
    test.assertTrue(snaps, "no snapshots recorded")
    return [float(s["game_time"]) for s in snaps if float(s["environment"]["rain_intensity"]) > 0.01]


class RainFreeDaysRun(unittest.TestCase):
    def test_no_random_rain_in_the_first_two_days_then_it_rolls_again(self):
        times = _rain_times(self, None)
        self.assertTrue(times, "no rain at all in four days at a certain chance")
        self.assertGreaterEqual(min(times), 2 * SECONDS_PER_DAY, "rain fell in the rain-free days: %s" % times[:3])

    def test_a_scenario_can_set_the_free_days_to_zero(self):
        times = _rain_times(self, 0.0)
        self.assertTrue(times and min(times) < 2 * SECONDS_PER_DAY, "no early rain with rain_free_days 0")


class RainWords(unittest.TestCase):
    def test_config_row_and_phrases_exist(self):
        source = MAIN.read_text(encoding="utf-8")
        for phrase in ('"soon"', '"later today"', '"by the end of the day"', '"tomorrow"'):
            self.assertIn(phrase, source)
        self.assertIn("var rain_free_days: float = 2.0", (ROOT / "scripts" / "game_config.gd").read_text(encoding="utf-8"))
        self.assertIn('"key": "rain_free_days"', (ROOT / "scripts" / "settings_catalogue.gd").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
