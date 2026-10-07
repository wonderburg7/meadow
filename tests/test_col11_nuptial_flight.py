"""COL-11: an unmated queen's nuptial flights.

Runs tests/col11_nuptial_flight_test.gd in a headless Godot at a fixed frame
rate: season.gd's mating curve is 0 in early spring and 1 at mid summer; an
unmated queen sent on flights through the succession window leaves the hive,
lays nothing while she is out, and comes home unmated where the curve is 0;
the selected-bee panel's Mating row switches her mode both ways;
she flies once a day; in mid summer she comes home mated and then lays
worker brood.

Requires a real Godot executable -- skips where none is installed.

Run with: python -m unittest tests.test_col11_nuptial_flight
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/col11_nuptial_flight_test.gd"
TIMEOUT_SECONDS = 300


class COL11NuptialFlightTest(unittest.TestCase):
    def test_an_unmated_queen_mates_on_a_mid_summer_flight_and_not_in_spring(self):
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
        failures = [line for line in output.splitlines() if line.startswith("COL11 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("COL11 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
