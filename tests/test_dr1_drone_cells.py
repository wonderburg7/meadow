"""DR-1: a mated queen lays drones in cells marked for them.

Runs tests/dr1_drone_cells_test.gd in a headless Godot: a mated queen lays a
drone in a cell marked for one and a worker in an unmarked cell; the gyne and
drone marks clear each other; an unmated queen still lays a drone in a
gyne-marked cell; the mark survives a save and load.

Requires a real Godot executable -- skips where none is installed.

Run with: python -m unittest tests.test_dr1_drone_cells
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/dr1_drone_cells_test.gd"
TIMEOUT_SECONDS = 180


class DR1DroneCellsTest(unittest.TestCase):
    def test_a_mated_queen_lays_drones_in_marked_cells_and_the_mark_is_saved(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT), "--script", TEST_SCRIPT],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=TIMEOUT_SECONDS,
        )
        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("DR1 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("DR1 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
