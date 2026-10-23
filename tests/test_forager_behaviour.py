"""FR-1d: causal checks against the real foraging exit and mentor-match paths."""

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import godot_compile_check as gcc


class ForagerBehaviourTests(unittest.TestCase):
    def test_scout_wait_requires_a_matching_mentor(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
             "--script", "res://tests/fr1d_forager_behaviour_test.gd"],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120,
        )
        output = gcc.combined_output(finished)
        print(output)
        self.assertEqual(gcc.failing_lines(output), [], output[-5000:])
        self.assertEqual(finished.returncode, 0, output[-5000:])
        self.assertIn("FR1D PASS", output)


if __name__ == "__main__":
    unittest.main()
