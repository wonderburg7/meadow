"""T2-10: a miner on Dig on its own wakes when Automation is bought.

Runs tests/t2_10_automine_wake_test.gd headlessly. Requires a real Godot.
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402


class AutomineWakeTest(unittest.TestCase):
    def test_source_guard(self):
        text = (ROOT / "scripts" / "bee.gd").read_text(encoding="utf-8")
        self.assertIn("_mining_no_work_gate_epoch == Availability.gate_epoch", text)

    def test_miner_wakes_and_idle_reasons_name_automation(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
             "--script", "res://tests/t2_10_automine_wake_test.gd"],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180,
        )
        output = gcc.combined_output(finished)
        failures = [l for l in output.splitlines() if l.startswith("T2_10 FAIL")]
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("T2_10 PASS", output, output[-1500:])


if __name__ == "__main__":
    unittest.main()
