"""Contracts for the FR-1 foraging-stage evidence campaign."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from io import StringIO
from pathlib import Path
from unittest.mock import patch

from tools import forager_stages
from tools.godot_compile_check import find_godot
from tools.scenario_sweep import short_scenarios


class ForagerStagesTests(unittest.TestCase):
    def test_fixture_is_the_settled_colony_and_window(self) -> None:
        fixture = json.loads(forager_stages.SCENARIO.read_text(encoding="utf-8"))
        self.assertEqual((fixture["cells"], fixture["nectar_foragers"], fixture["pollen_foragers"]), (15, 8, 3))
        self.assertEqual(fixture["stop"], {"max_days": 20})
        self.assertEqual(fixture["skill_grants"], ["skill.foraging.associative_learning"])
        overrides = fixture["config_overrides"]
        self.assertTrue(overrides["tarsal_markers_on"])
        self.assertTrue(overrides["adaptive_constancy_on"])

    def test_every_stage_explicitly_owns_the_four_toggles(self) -> None:
        expected = {"orientation_flight_on", "scouting_on", "auto_recruitment_on", "floral_constancy_on"}
        self.assertEqual(len(forager_stages.STAGES), 4)
        self.assertTrue(all(set(toggles) == expected for _, toggles in forager_stages.STAGES))

    def test_figure_and_stage_ratios(self) -> None:
        self.assertEqual(forager_stages.delivery_per_forager_day({"forager_delivery_amount": 220}), 1.0)
        self.assertEqual(forager_stages.stage_rows([[1, 3, 2], [2, 8, 4]]), [(2, "--"), (4, "2.00x")])

    def test_campaign_fixture_is_not_part_of_the_short_sweep(self) -> None:
        self.assertNotIn(Path("test_scenarios/fr1_forager_stages_test.json"),
                         [path.relative_to(forager_stages.ROOT) for path in short_scenarios("")])

    def test_main_passes_the_optional_godot_path_to_each_run(self) -> None:
        with patch.object(forager_stages, "_run_one", return_value=1.0) as run_one, \
             patch.object(sys, "argv", ["forager_stages.py", "--godot-path", "Godot.exe"]), \
             patch("sys.stdout", new_callable=StringIO):
            self.assertEqual(forager_stages.main(), 0)
        self.assertEqual(run_one.call_count, 20)
        self.assertTrue(all(call.args[-1] == "Godot.exe" for call in run_one.call_args_list))

    def test_auto_recruitment_stage_completes_without_stale_mentor_errors(self) -> None:
        if not find_godot():
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        name, toggles = forager_stages.STAGES[2]
        with tempfile.TemporaryDirectory(prefix="meadow-fr1-test-") as temporary:
            value = forager_stages._run_one(
                name.replace(" ", "_"), toggles, forager_stages.SEEDS[0], Path(temporary), None)
        self.assertGreater(value, 0.0)


if __name__ == "__main__":
    unittest.main()
