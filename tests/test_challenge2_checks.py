"""HO-16: Challenge 2's Nurse gating, stage dwell and the skill tree's Escape.

Runs tests/challenge2_checks_test.gd in a headless Godot, once per mode. That
script boots the real Main.tscn into Challenge 2 and checks:
  nurse_gating (C-81): Nurse is not offered before 2.5 or before Nurses is
                       bought, and is offered the frame after it is.
  dwell (C-94):        stages 2.3 and 2.4 each stay up for MIN_STAGE_DWELL
                       when one hatch and a full comb meet them together.
  escape (C-100):      Space leaves the skill tree open; Escape closes it and
                       unpauses the run.

Requires a real Godot executable, like test_ho10_queen_starvation_ends_run.py
-- skips where none is installed or the engine cannot initialise headlessly.

Run with: python tests/test_challenge2_checks.py
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/challenge2_checks_test.gd"
TIMEOUT_SECONDS = 180


class Challenge2ChecksTest(unittest.TestCase):
    def test_nurse_gating(self):
        self._boot_and_run("nurse_gating")

    def test_dwell(self):
        self._boot_and_run("dwell")

    def test_escape(self):
        self._boot_and_run("escape")

    def _boot_and_run(self, mode):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
             "--fixed-fps", "60", "--script", TEST_SCRIPT, "--", mode],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=TIMEOUT_SECONDS,
        )
        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("C2CHECKS FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("C2CHECKS PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
