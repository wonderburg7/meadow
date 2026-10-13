"""GP-2: favourite goals stay on screen when the Goals drop-down is collapsed.

Runs tests/gp2_goal_favourites_test.gd in a headless Godot: a starred line
shows while collapsed; a met favourite shows struck through until the next
day change, then drops and unstars; stars survive a save record's round trip
through JSON; a record without them loads with none.

APPDATA is pointed at a temp folder so no real profile is written.

Requires a real Godot executable -- skips where none is installed.

Run with: python -m unittest tests.test_gp2_goal_favourites
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/gp2_goal_favourites_test.gd"
TIMEOUT_SECONDS = 300


class GP2GoalFavouritesTest(unittest.TestCase):
    def test_favourites_show_collapsed_strike_when_met_and_save(self):
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
                [godot, "--headless", "--disable-crash-handler", "--fixed-fps", "60",
                 "--path", str(ROOT), "--script", TEST_SCRIPT],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
                timeout=TIMEOUT_SECONDS, env=env,
            )
        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("GP2 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("GP2 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
