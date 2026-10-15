"""tools/run_tests.py: the order it runs tests in, and when verify's unit
stage may leave out the modules that boot Godot."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import run_tests  # noqa: E402


class SlowestFirstTest(unittest.TestCase):
    def test_unknown_ids_lead_then_the_slowest(self):
        timings = {"tests.fast": 1.0, "tests.slow": 30.0}
        ordered = run_tests.slowest_first(["tests.fast", "tests.new", "tests.slow"], timings)
        self.assertEqual(["tests.new", "tests.slow", "tests.fast"], ordered)


class SplitGameClassesTest(unittest.TestCase):
    def test_only_a_game_module_with_several_classes_is_split(self):
        ids = run_tests.split_game_classes([
            "tests.test_bb4_challenge_pacing", "tests.test_ho10_queen_starvation_ends_run", "tests.test_run_tests",
        ])
        self.assertEqual([
            "tests.test_bb4_challenge_pacing.ChallengeOneRouteTest",
            "tests.test_bb4_challenge_pacing.ChallengeTwoRouteTest",
            "tests.test_ho10_queen_starvation_ends_run",
            "tests.test_run_tests",
        ], ids)


class GameTestReachTest(unittest.TestCase):
    GAME = ["tests.test_bb1_bee_bread"]

    def test_a_godot_module_is_a_game_test_and_a_tooling_one_is_not(self):
        self.assertTrue(run_tests.is_game_test("tests.test_bb1_bee_bread"))
        self.assertFalse(run_tests.is_game_test("tests.test_run_tests"))

    def test_the_tools_a_game_test_imports_reach_it_transitively(self):
        files = run_tests.game_test_files(self.GAME)
        self.assertIn("tests/test_bb1_bee_bread.py", files)
        self.assertIn("tools/run_scenario.py", files)
        # run_scenario imports godot_cache: one import further down.
        self.assertIn("tools/godot_cache.py", files)
        self.assertNotIn("tools/slice.ps1", files)

    def test_only_documents_and_unimported_tooling_stay_clear_of_the_game(self):
        files = run_tests.game_test_files(self.GAME)
        for path in ("plans/now/x.md", "README.md", "docs/a.txt", "tools/slice.ps1",
                     "tools/run_tests.py", "tests/test_slice_lifecycle.py"):
            self.assertFalse(run_tests.reaches_game(path, files), path)
        for path in ("scripts/main.gd", "scenes/main.tscn", "project.godot", "test_scenarios/a.json",
                     "tests/ho10_script.gd", "tools/run_scenario.py", "tests/test_bb1_bee_bread.py"):
            self.assertTrue(run_tests.reaches_game(path, files), path)

    def test_game_tests_run_when_nothing_or_anything_game_side_changed(self):
        with mock.patch.object(run_tests, "changed_files", return_value=[]):
            self.assertTrue(run_tests.game_tests_reached("master", self.GAME)[0])
        with mock.patch.object(run_tests, "changed_files", return_value=None):
            self.assertTrue(run_tests.game_tests_reached("master", self.GAME)[0])
        with mock.patch.object(run_tests, "changed_files", return_value=["tools/slice.ps1", "scripts/hud.gd"]):
            self.assertEqual((True, "reached by scripts/hud.gd"), run_tests.game_tests_reached("master", self.GAME))
        with mock.patch.object(run_tests, "changed_files", return_value=["tools/slice.ps1", "plans/a.md"]):
            self.assertFalse(run_tests.game_tests_reached("master", self.GAME)[0])


if __name__ == "__main__":
    unittest.main()
