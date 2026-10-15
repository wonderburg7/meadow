"""SP-11: every ring on a cell traces the cup's rim.

Static checks on scripts/hive_cell.gd, then runs tests/sp11_cell_rim_test.gd
in a headless Godot.

Requires a real Godot executable -- the headless run skips where none is installed.

Run with: python -m unittest tests.test_sp11_cell_rim
"""

from __future__ import annotations

import re
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/sp11_cell_rim_test.gd"
TIMEOUT_SECONDS = 180


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


class CellRimStatic(unittest.TestCase):
    def test_rim_is_six_points(self):
        cell = read("scripts/hive_cell.gd")
        match = re.search(r"const EMPTY_RIM: Array = \[(.*?)\n\]", cell, re.S)
        self.assertIsNotNone(match, "EMPTY_RIM is not declared")
        self.assertEqual(len(re.findall(r"Vector2\(", match.group(1))), 6)

    def test_old_silhouette_and_nudge_are_gone(self):
        cell = read("scripts/hive_cell.gd")
        self.assertNotIn("EMPTY_SILHOUETTE", cell)
        self.assertNotIn("RING_Y_NUDGE", cell)

    def test_cup_rings_walk_the_rim(self):
        cell = read("scripts/hive_cell.gd")
        body = cell[cell.index("func _set_outline_points_cup"):]
        body = body[:body.index("\n\n")]
        self.assertIn("for p in EMPTY_RIM:", body)
        self.assertIn("_silhouette_point_to_local(p)", body)


class CellRimHeadless(unittest.TestCase):
    def test_every_ring_traces_the_rim(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT), "--script", TEST_SCRIPT],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=TIMEOUT_SECONDS,
        )
        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("SP11 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("SP11 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
