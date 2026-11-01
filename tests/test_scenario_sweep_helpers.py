"""Unit tests for tools/scenario_sweep.py helper functions and runner."""

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from tools import scenario_sweep


class TestScenarioSweepHelpers(unittest.TestCase):
    def test_short_scenarios_excludes_long_running_patterns(self):
        """Scenarios matching LONG_RUNNING prefixes or patterns must be omitted."""
        scenarios = scenario_sweep.short_scenarios("")
        names = [path.name for path in scenarios]
        for pattern in scenario_sweep.LONG_RUNNING:
            for name in names:
                self.assertNotRegex(
                    name,
                    pattern,
                    f"Scenario {name} should have been excluded by pattern {pattern}",
                )

    def test_short_scenarios_applies_only_filter(self):
        """Passing an 'only' token limits results to files containing that substring."""
        scenarios = scenario_sweep.short_scenarios("a5_")
        self.assertGreater(len(scenarios), 0)
        self.assertTrue(all("a5_" in path.name for path in scenarios))

    def test_short_scenarios_returns_sorted_list(self):
        """Scenarios returned are sorted by file path."""
        scenarios = scenario_sweep.short_scenarios("")
        self.assertEqual(scenarios, sorted(scenarios))

    def test_short_scenarios_synthetic_filtering(self):
        """Verify pattern exclusion and substring filtering on synthetic paths."""
        synthetic_paths = [
            Path("/fake/test_scenarios/alpha_arc_test.json"),
            Path("/fake/test_scenarios/foraging_features_1_test.json"),
            Path("/fake/test_scenarios/h5_harvest_test.json"),
            Path("/fake/test_scenarios/h6_dance_test.json"),
            Path("/fake/test_scenarios/evidence_baseline_test.json"),
        ]
        with patch.object(Path, "glob", return_value=synthetic_paths):
            self.assertEqual(
                scenario_sweep.short_scenarios(""),
                [
                    Path("/fake/test_scenarios/h5_harvest_test.json"),
                    Path("/fake/test_scenarios/h6_dance_test.json"),
                ],
            )
            self.assertEqual(
                scenario_sweep.short_scenarios("h5"),
                [Path("/fake/test_scenarios/h5_harvest_test.json")],
            )

    def test_main_returns_2_when_no_godot(self):
        """Exit code is 2 when find_godot returns None."""
        with patch.object(scenario_sweep, "find_godot", return_value=None), \
             patch("sys.argv", ["scenario_sweep.py"]):
            code = scenario_sweep.main()
            self.assertEqual(code, 2)

    def test_main_returns_0_when_all_scenarios_pass(self):
        """Exit code is 0 when all selected scenarios report status=passed."""
        dummy_scenarios = [Path("/fake/h5_test.json"), Path("/fake/h6_test.json")]
        mock_result = MagicMock(stdout="status=passed run_id=123 result=ok\n")
        with patch.object(scenario_sweep, "find_godot", return_value="/fake/godot"), \
             patch.object(scenario_sweep, "short_scenarios", return_value=dummy_scenarios), \
             patch("subprocess.run", return_value=mock_result), \
             patch("sys.argv", ["scenario_sweep.py"]):
            code = scenario_sweep.main()
            self.assertEqual(code, 0)

    def test_main_returns_1_when_scenario_fails(self):
        """Exit code is 1 when at least one scenario does not pass."""
        dummy_scenarios = [Path("/fake/h5_test.json"), Path("/fake/h6_test.json")]
        pass_res = MagicMock(stdout="status=passed\n")
        fail_res = MagicMock(stdout="status=failed assertion_failed\n")
        with patch.object(scenario_sweep, "find_godot", return_value="/fake/godot"), \
             patch.object(scenario_sweep, "short_scenarios", return_value=dummy_scenarios), \
             patch("subprocess.run", side_effect=[pass_res, fail_res]), \
             patch("sys.argv", ["scenario_sweep.py"]):
            code = scenario_sweep.main()
            self.assertEqual(code, 1)

    def test_main_returns_1_when_scenario_times_out(self):
        """Exit code is 1 when a scenario times out."""
        dummy_scenarios = [Path("/fake/timeout_test.json")]
        with patch.object(scenario_sweep, "find_godot", return_value="/fake/godot"), \
             patch.object(scenario_sweep, "short_scenarios", return_value=dummy_scenarios), \
             patch("subprocess.run", side_effect=subprocess.TimeoutExpired(["cmd"], 10)), \
             patch("sys.argv", ["scenario_sweep.py"]):
            code = scenario_sweep.main()
            self.assertEqual(code, 1)


if __name__ == "__main__":
    unittest.main()
