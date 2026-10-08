"""SI-1: a real Godot boot saves and reloads visible run state."""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/si1_run_state_test.gd"


class SI1RunStateTest(unittest.TestCase):
    def test_disease_species_and_rival_survive_a_load(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT), "--script", TEST_SCRIPT],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180,
        )
        output = gcc.combined_output(finished)
        self.assertEqual(gcc.failing_lines(output), [], "script errors:\n" + output[-3000:])
        self.assertFalse(any(line.startswith("SI1 FAIL") for line in output.splitlines()), output[-3000:])
        self.assertIn("SI1 PASS", output, "the test script did not report a pass:\n" + output[-3000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
