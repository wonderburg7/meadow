"""ED-1: every bee has health (plans/now/difficulty.md, "ED-1 -- every bee has health").

Runs tests/ed1_health_test.gd in a headless Godot at a fixed frame rate, once
per mode:

- starve: a queen out of energy with nothing to eat does not die on the spot;
  she loses health and dies of starvation about half a game-day later.
- recover: a forager out of energy in the meadow heads home at 25% of her
  speed, eats, rests inside while her health or energy is under the rest
  thresholds, and leaves only once both clear them.
- ambush: a crab-spider ambush still kills a bee at full health outright.

The static half checks the new GameConfig values each have a settings row.

Requires a real Godot executable for the run half -- skips where none is
installed.

Run with: python -m unittest tests.test_ed1_health
"""

from __future__ import annotations

import re
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/ed1_health_test.gd"
TIMEOUT_SECONDS = 300
NEW_VALUES = (
    "health_capacity", "exhaustion_health_drain", "health_regen_rate",
    "spent_speed_factor", "rest_leave_health", "rest_leave_energy",
)


class ED1HealthStaticTest(unittest.TestCase):
    def test_every_new_value_is_a_config_field_with_a_settings_row(self):
        config = (ROOT / "scripts" / "game_config.gd").read_text(encoding="utf-8")
        catalogue = (ROOT / "scripts" / "settings_catalogue.gd").read_text(encoding="utf-8")
        for key in NEW_VALUES:
            self.assertRegex(config, r"(?m)^var %s: float = " % key)
            row = re.search(r'"persist":\s*"(\w+)",\s*"key":\s*"%s"' % key, catalogue)
            self.assertIsNotNone(row, "%s has no settings row" % key)
            self.assertEqual(row.group(1), "none", "%s must not go in the save before ED-1c" % key)

    def test_the_drain_is_set_to_half_a_day(self):
        config = (ROOT / "scripts" / "game_config.gd").read_text(encoding="utf-8")

        def value(key):
            return float(re.search(r"(?m)^var %s: float = ([0-9.]+)" % key, config).group(1))

        lasts = value("health_capacity") / value("exhaustion_health_drain")
        self.assertAlmostEqual(lasts / value("seconds_per_day"), 0.5, places=2)


class ED1HealthRunTest(unittest.TestCase):
    def test_an_exhausted_bee_with_nothing_to_eat_dies_after_half_a_day(self):
        self._run_mode("starve")

    def test_a_spent_forager_crawls_home_eats_rests_and_leaves_past_the_thresholds(self):
        self._run_mode("recover")

    def test_an_ambush_still_kills_outright(self):
        self._run_mode("ambush")

    def _run_mode(self, mode):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--fixed-fps", "60",
             "--path", str(ROOT), "--script", TEST_SCRIPT, "--", mode],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=TIMEOUT_SECONDS,
        )
        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("ED1 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("ED1 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
