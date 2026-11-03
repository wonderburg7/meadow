"""SG-3: short-term goals in the Goals drop-down, with progress, reward, star and Dismiss.

Runs tests/sg3_goal_shelf_test.gd in a real headless Godot. It builds the
Colony Run of test_scenarios/sg3_goal_shelf.json (and the same row as a
Scenario, without run_type), paused, moves the day on by hand and runs
year_winter.gd's one-second refresh. It shows: an offered goal in the drop-down
under the milestone with its progress and reward; a starred goal staying when
the drop-down is collapsed; Dismiss removing it with nothing replacing it until
the next day; finishing one showing the completion note and Dr Gallerin's line
once; a Challenge's shelf untouched.

Run with: python -m unittest tests.test_sg3_goal_shelf
"""

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import godot_compile_check as gcc  # noqa: E402


class GoalShelfInPlayTest(unittest.TestCase):
    def test_goals_shown_starred_dismissed_and_finished(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        with tempfile.TemporaryDirectory() as appdata:
            env = dict(os.environ, APPDATA=appdata)
            finished = subprocess.run(
                [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
                 "--script", "res://tests/sg3_goal_shelf_test.gd"],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
                timeout=180, env=env,
            )
        output = gcc.combined_output(finished)
        self.assertEqual(gcc.failing_lines(output), [], output[-3000:])
        self.assertNotIn("SG3 FAIL", output, output[-3000:])
        self.assertIn("SG3 PASS", output, output[-3000:])
        self.assertEqual(finished.returncode, 0, output[-3000:])


if __name__ == "__main__":
    unittest.main()
