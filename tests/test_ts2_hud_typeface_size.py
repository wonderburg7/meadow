"""TS-2: the HUD's own size overrides follow the typeface too.

Runs tests/ts2_hud_typeface_size_test.gd in a headless Godot: with OpenDyslexic
at text scale 1, the completed goal line and a favourite goal line carry
UiTheme.font_px of their base sizes, each corner readout carries font_px of its
CORNER_SIZES entry, and switching typeface rebuilds the corner.
Requires a real Godot executable -- skips where none is installed.

Run with: python -m unittest tests.test_ts2_hud_typeface_size
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/ts2_hud_typeface_size_test.gd"
TIMEOUT_SECONDS = 300


class TS2HudTypefaceSizeTest(unittest.TestCase):
    def test_hud_size_overrides_follow_typeface(self):
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
        failures = [line for line in output.splitlines() if line.startswith("TS2 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("TS2 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
