"""Headless regression for SF-1's founding flower-season distribution."""

from __future__ import annotations

import os
import shutil
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import DEFAULT_GODOT_PATH, run_once  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "sf1_founding_flower_mix_test.json"


def _resolve_godot_path() -> str | None:
    return find_godot()


def _out_of_season_share(counts: dict) -> float:
    in_season = int(counts["flowers_in_season"])
    out_of_season = int(counts["flowers_out_of_season"])
    total = in_season + out_of_season
    if total == 0:
        raise AssertionError("flower season counts have no flowers")
    return out_of_season / total


class FoundingFlowerMixTest(unittest.TestCase):
    def test_post_founding_meadow_matches_the_same_phase_next_year_mix(self):
        godot_path = _resolve_godot_path()
        if not godot_path:
            self.skipTest("no Godot executable found -- this test needs a real headless boot")

        for seed in (4242, 17, 89, 2026):
            with self.subTest(seed=seed):
                session_file = run_once(FIXTURE, godot_path, timeout=120, fixed_fps=10, seed_override=seed)
                self.assertIsNotNone(session_file, "scenario run produced no session log")
                entries = load_entries(session_file)
                phase_snapshots = {}
                for entry in entries:
                    if entry.get("type") != "snapshot" or entry.get("day") not in (10, 15):
                        continue
                    environment = entry.get("environment", {})
                    if "flowers_in_season" in environment:
                        phase_snapshots.setdefault(entry["day"], environment)
                self.assertEqual(set(phase_snapshots), {10, 15})
                for environment in phase_snapshots.values():
                    flower_total = environment["flowers_in_season"] + environment["flowers_out_of_season"]
                    self.assertGreaterEqual(flower_total, 700, "meadow drained before the phase comparison")

                initial_share = _out_of_season_share(phase_snapshots[10])
                final_share = _out_of_season_share(phase_snapshots[15])
                self.assertLessEqual(abs(initial_share - final_share), 0.05)


if __name__ == "__main__":
    unittest.main()
