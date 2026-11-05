"""Drones have no "Change to..." menu, Doing row or "If idle" row.

Static part: _rebuild_role_controls guards the three builders behind the
all-drones check. Run part: tests/drone_command_rows_test.gd in a headless
Godot checks the all-drones rule on constructed selections.
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/drone_command_rows_test.gd"


class DroneRowsStaticTest(unittest.TestCase):
    def test_job_doing_and_idle_rows_skip_drones(self):
        text = (ROOT / "scripts" / "hud_command_rows.gd").read_text(encoding="utf-8")
        body = text.split("func _rebuild_role_controls(", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("var all_drones: bool = _all_drones(bees)", body)
        self.assertIn("if not all_drones:\n\t\t_build_doing_row(", body)
        self.assertIn("if not all_drones:\n\t\t_build_job_row(", body)
        self.assertIn("\t\t_build_fallback_row(", body)


    def test_assigning_a_job_skips_drones_in_a_mixed_selection(self):
        text = (ROOT / "scripts" / "orders_zones.gd").read_text(encoding="utf-8")
        body = text.split("func _assign_role(", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("_role_permitted(role_id, b) and not b.is_drone", body)


class DroneRowsRunTest(unittest.TestCase):
    def test_all_drones_rule(self):
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
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120,
        )
        output = gcc.combined_output(finished)
        failures = [line for line in output.splitlines() if line.startswith("DRONE_ROWS FAIL")]
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("DRONE_ROWS PASS", output, output[-1500:])


if __name__ == "__main__":
    unittest.main()
