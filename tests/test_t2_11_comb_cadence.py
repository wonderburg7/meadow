"""T2-11 investigation: why comb workers build comb unevenly.

Runs tests/t2_11_comb_cadence_test.gd in a headless Godot at a fixed frame
rate: a Colony Run with two comb workers in Build mode and two miners on Dig
on its own: five game-days with Automation owned, then two without it,
the second with one comb worker selected in the HUD. Prints
every comb-worker idle spell longer than 10 game-seconds with its mode,
idle_reason() and what each catalogue row would have found, plus a line per
game-day. The answer it gave is written in plans/now/tier-two.md, section
T2-11.

A diagnostic: it fails only when the run cannot be set up or the script
errors, never on what the colony did.

Requires a real Godot executable -- skips where none is installed.

Run with: python -m unittest tests.test_t2_11_comb_cadence
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/t2_11_comb_cadence_test.gd"
TIMEOUT_SECONDS = 400


class T211CombCadenceTest(unittest.TestCase):
    def _run(self, user_args: list[str]) -> None:
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        command = [godot, "--headless", "--disable-crash-handler", "--fixed-fps", "60",
                   "--path", str(ROOT), "--script", TEST_SCRIPT]
        if user_args:
            command += ["--"] + user_args
        finished = subprocess.run(
            command, capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=TIMEOUT_SECONDS,
        )
        output = gcc.combined_output(finished)
        report = [line for line in output.splitlines() if line.startswith("T2_11 ")]
        print("\n" + "\n".join(report))
        script_errors = gcc.failing_lines(output)
        failures = [line for line in report if line.startswith("T2_11 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("T2_11 DONE", output, "the run did not finish:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)

    def test_reports_idle_spells_over_five_days_with_automation(self):
        self._run([])

    def test_reports_two_days_without_automation_the_second_with_a_comb_worker_selected(self):
        self._run(["--no-automation", "--days=2", "--select-from-day=2"])


if __name__ == "__main__":
    unittest.main()
