"""HO-10: a queen who starves ends the run with "The queen is dead".

Runs tests/ho10_queen_starvation_ends_run_test.gd in a headless Godot. That
script boots the real Main.tscn into Scenario 1 (the queen alone, no comb and
no stores), drains her energy so the ordinary starvation check kills her, and
checks main.gd sets colony_lost and the game-over panel shows "The queen is
dead". It stands in for a headless scenario fixture because a scenario run
ends "collapsed" instead of opening the panel, and scenario_actions.gd is
Codex-owned (plans/now/hands-on-findings.md, HO-10).

Requires a real Godot executable, like test_gc4_nurse_role_change_keeps_food.py
-- skips where none is installed or the engine cannot initialise headlessly.

Run with: python tests/test_ho10_queen_starvation_ends_run.py
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/ho10_queen_starvation_ends_run_test.gd"
TIMEOUT_SECONDS = 180


class HO10QueenStarvationEndsRunTest(unittest.TestCase):
    def test_starved_queen_opens_the_queen_is_dead(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        self._run_mode(godot, "starve")

    def test_queenless_save_restored_on_fresh_scene_ends_run(self):
        self._boot_and_run("restore_queenless")

    def test_save_with_a_queen_plays_on(self):
        self._boot_and_run("restore_queen")

    def _boot_and_run(self, mode):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        self._run_mode(godot, mode)

    def _run_mode(self, godot, mode):
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT), "--script", TEST_SCRIPT, "--", mode],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=TIMEOUT_SECONDS,
        )
        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("HO10 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("HO10 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
