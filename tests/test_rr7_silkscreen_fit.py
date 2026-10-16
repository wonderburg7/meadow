"""RR-7: why Silkscreen at text scale 2 still splits a menu hexagon's word.

Runs tests/rr7_silkscreen_fit_test.gd in a headless Godot at a fixed frame
rate and prints its "RR7" figure lines: for the Challenge 1 hexagon's title in
Silkscreen at text scale 2, the available size, the size
MainMenu.hex_fit_size returns, whether hex_text_fits holds at it, and the
line count the Label itself lays out. A diagnostic: it fails only when the
script cannot reach those figures.

Requires a real Godot executable -- skips where none is installed.

Run with: python -m unittest tests.test_rr7_silkscreen_fit
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/rr7_silkscreen_fit_test.gd"
TIMEOUT_SECONDS = 300


class RR7SilkscreenFitTest(unittest.TestCase):
    def test_prints_the_challenge_one_fit_figures_in_silkscreen_at_scale_two(self):
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
        figures = [line for line in output.splitlines() if line.startswith("RR7 ")]
        print("\n" + "\n".join(figures))
        script_errors = gcc.failing_lines(output)
        failures = [line for line in figures if line.startswith("RR7 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("RR7 DONE", output, "the test script did not finish:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
