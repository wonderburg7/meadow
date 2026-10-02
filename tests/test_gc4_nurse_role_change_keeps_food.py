"""GC-4: a nurse moved to another job puts her brood food back in the comb.

Runs tests/gc4_nurse_role_change_keeps_food_test.gd in a headless Godot. That
script builds a real hive, real cells and a real nurse outside any world,
changes her job to Idle and (queued) to Forager, and checks the hive's stored
totals rise by exactly what she carried; the queen keeps her old behaviour.
It stands in for a headless scenario fixture because no scenario action can
load a nurse with brood food (scenario_actions.gd is Codex-owned; Dave,
2 Oct 2026).

Requires a real Godot executable, like test_hc16_tray_reselect.py -- skips
where none is installed or the engine cannot initialise headlessly.

Run with: python tests/test_gc4_nurse_role_change_keeps_food.py
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/gc4_nurse_role_change_keeps_food_test.gd"
TIMEOUT_SECONDS = 120


class GC4NurseRoleChangeKeepsFoodTest(unittest.TestCase):
    def test_nurse_food_goes_back_to_the_comb(self):
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
        failures = [line for line in output.splitlines() if line.startswith("GC4 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("GC4 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
