"""RR-5: hexagon names re-fit when the typeface changes.

Runs tests/rr5_hex_refit_test.gd in a headless Godot at a fixed frame rate:
with text scale 2 and Munro, then OpenDyslexic switched through the Typeface
setting's own apply path, every hexagon name's font size equals what
MainMenu.hex_fit_size gives for OpenDyslexic.

Requires a real Godot executable -- skips where none is installed.

Run with: python -m unittest tests.test_rr5_hex_refit
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/rr5_hex_refit_test.gd"
TIMEOUT_SECONDS = 300


class RR5HexRefitTest(unittest.TestCase):
    def test_switching_typeface_at_scale_two_refits_every_hexagon_name(self):
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
        failures = [line for line in output.splitlines() if line.startswith("RR5 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("RR5 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
