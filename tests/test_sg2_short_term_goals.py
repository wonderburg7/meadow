"""SG-2: short-term goals offered, finished and paid by the game, and saved.

Runs tests/sg2_short_term_goals_test.gd in a real headless Godot. It builds
the Colony Run of test_scenarios/sg2_short_term_goals.json, paused, moves the
day on by hand (the stores, the lifetime counters, then main.gd's day-boundary
sample) and runs year_winter.gd's one-second refresh, which offers, advances
and pays the goals. It shows: no goal before a day's income is known; the
pollen goal offered with no pollen income and paying a quarter of the day's
gross income into the stores after a whole day of surplus; "Lay in honey for
winter" finishing five days before winter while the CR-2 milestone waits for
the last day; offered and finished goals through a save and an in-place
restore, and a save without them restoring none. Challenges 1 and 2, with the
same pollen shortfall, offer nothing.

Run with: python -m unittest tests.test_sg2_short_term_goals
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


class ShortTermGoalsInPlayTest(unittest.TestCase):
    def test_goals_offered_paid_and_saved(self):
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
                 "--script", "res://tests/sg2_short_term_goals_test.gd"],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
                timeout=180, env=env,
            )
        output = gcc.combined_output(finished)
        self.assertEqual(gcc.failing_lines(output), [], output[-3000:])
        self.assertNotIn("SG2 FAIL", output, output[-3000:])
        self.assertIn("SG2 PASS", output, output[-3000:])
        self.assertEqual(finished.returncode, 0, output[-3000:])


if __name__ == "__main__":
    unittest.main()
