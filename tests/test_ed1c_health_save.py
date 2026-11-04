"""ED-1c: health is saved per bee (plans/now/difficulty.md).

Runs tests/ed1c_health_save_test.gd in a headless Godot: a bee's lowered
health survives save and in-place restore, and a save without the key loads
every bee at full health. The static half checks both save files carry the
key.

Run with: python -m unittest tests.test_ed1c_health_save
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/ed1c_health_save_test.gd"
TIMEOUT_SECONDS = 300


class ED1cStaticTest(unittest.TestCase):
    def test_the_save_writes_and_reads_health_with_a_full_health_default(self):
        writer = (ROOT / "scripts" / "save_game.gd").read_text(encoding="utf-8")
        reader = (ROOT / "scripts" / "saving.gd").read_text(encoding="utf-8")
        self.assertIn('"health": b.health', writer)
        self.assertIn('entry.get("health", GameConfig.health_capacity)', reader)


class ED1cRunTest(unittest.TestCase):
    def test_health_survives_a_save_and_an_old_save_loads_full(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
             "--script", TEST_SCRIPT],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=TIMEOUT_SECONDS,
        )
        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("ED1C FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("ED1C PASS", output, "no pass reported:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0)


if __name__ == "__main__":
    unittest.main()
