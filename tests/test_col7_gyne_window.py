"""COL-7: the player sends a gyne, and the mating window decides her worth.

Runs tests/col7_gyne_window_test.gd in a headless Godot at a fixed frame
rate: a ready gyne stays put across many season ticks; one short of energy
can't be sent and her readout says why; sent through her panel in early
spring she is lost (gyne_lost, no release, no points, no win); sent in mid
summer she counts (gyne_released, the release count, 10 genetic points and
the Colony Run's win); the points survive save_data/restore, and a record
without them restores 0.

Requires a real Godot executable -- skips where none is installed.

Run with: python -m unittest tests.test_col7_gyne_window
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/col7_gyne_window_test.gd"
TIMEOUT_SECONDS = 300


class COL7GyneWindowTest(unittest.TestCase):
    def test_a_sent_gyne_counts_inside_the_mating_window_and_is_lost_outside_it(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--fixed-fps", "60",
             "--path", str(ROOT), "--script", TEST_SCRIPT],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=TIMEOUT_SECONDS,
        )
        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("COL7 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("COL7 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
