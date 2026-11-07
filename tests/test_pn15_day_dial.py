"""PN-15: the day dial follows simulation time."""

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import godot_compile_check as gcc


class DayDialTest(unittest.TestCase):
    def test_corner_signature_excludes_sim_time(self):
        hud = (ROOT / "scripts/hud.gd").read_text(encoding="utf-8")
        signature = hud.split("func _corner_signature(", 1)[1].split("\nfunc ", 1)[0]
        self.assertNotIn("sim_time", signature)
        self.assertNotIn("day_fraction", signature)

    def test_day_fraction(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("Godot cannot initialise headlessly")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--fixed-fps", "60",
             "--path", str(ROOT), "--script", "res://tests/pn15_day_dial_test.gd"],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=300,
        )
        output = gcc.combined_output(finished)
        self.assertEqual(gcc.failing_lines(output), [], output)
        self.assertNotIn("PN15 FAIL", output, output)
        self.assertIn("PN15 PASS", output, output)
        self.assertEqual(finished.returncode, 0, output)


if __name__ == "__main__":
    unittest.main()
