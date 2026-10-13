"""Run the SG-1 catalogue and rule fixtures in a real headless Godot."""

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import godot_compile_check as gcc  # noqa: E402


class ShortTermGoalsTest(unittest.TestCase):
    def test_catalogue_offer_progress_and_reward(self):
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
                 "--script", "res://tests/sg1_short_term_goals_test.gd"],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
                timeout=60, env=env,
            )
        output = gcc.combined_output(finished)
        self.assertEqual(gcc.failing_lines(output), [], output[-3000:])
        self.assertNotIn("SG1 FAIL", output, output[-3000:])
        self.assertIn("SG1 PASS", output, output[-3000:])
        self.assertEqual(finished.returncode, 0, output[-3000:])


if __name__ == "__main__":
    unittest.main()
