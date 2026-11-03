"""ED-1b: an ambush takes health and the selection panel shows it
(plans/now/difficulty.md, "ED-1b").

Runs tests/ed1b_health_panel_test.gd in a headless Godot: a crab-spider ambush
takes all of a worker's health and kills her with cause "crab spider ambush",
and the selection panel of a half-health bee shows "Health 50%" beside her
energy. Skips where no Godot executable is installed.

Run with: python -m unittest tests.test_ed1b_health_panel
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/ed1b_health_panel_test.gd"
TIMEOUT_SECONDS = 300


class ED1bHealthPanelTest(unittest.TestCase):
    def test_an_ambush_takes_all_health_and_the_panel_shows_health(self):
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
        failures = [line for line in output.splitlines() if line.startswith("ED1B FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("ED1B PASS", output, "no pass reported:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
