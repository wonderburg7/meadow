"""SP-12: compare outlines with the rendered cup rim in a scenario."""
import sys
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from analyze_session import load_entries
import godot_compile_check as gcc
from run_scenario import run_once


class OutlineRimScenario(unittest.TestCase):
    def test_rim_assertions_and_actions(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("Godot is required")
        log = run_once(ROOT / "test_scenarios" / "sp_outline_rim.json", godot, timeout=600, fixed_fps=30)
        self.assertIsNotNone(log, "scenario produced no session log")
        actions = [entry for entry in load_entries(log) if entry.get("type") == "action"]
        self.assertEqual([a.get("result") for a in actions if a.get("do") == "assert"], ["accepted", "accepted"])
        self.assertFalse([a for a in actions if a.get("result") in ("rejected", "never_fired")], actions)

    def test_displaced_outline_is_rejected(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("Godot is required")
        gcc.ensure_writable_user_dir()
        self.assertTrue(gcc.prepare_cache(godot))
        result = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
             "--script", "res://tests/sp11_cell_rim_test.gd"],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180,
        )
        output = gcc.combined_output(result)
        self.assertEqual(gcc.failing_lines(output), [], output)
        self.assertIn("SP11 PASS", output)
        self.assertEqual(result.returncode, 0, output)
