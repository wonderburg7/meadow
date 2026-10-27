"""RR-1: the queen can build a cell in every run.

Runs test_scenarios/rr1_queen_builds_test.json in a headless Godot: a colony
with no cells and no workers, so the queen is alone as in a Colony Run, outside
any Challenge. She must be offered Build cell, and after the Build cell tool
and a click on the hive floor she builds one cell within two game days. Also
checks the source: orders_zones.gd owns the general build. Requires a real
Godot for the scenario test.
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import subprocess  # noqa: E402

import godot_compile_check as gcc  # noqa: E402
from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "rr1_queen_builds_test.json"
RESUME_SCRIPT = "res://tests/rr16_queen_resume_test.gd"
RESUME_TIMEOUT_SECONDS = 300


class QueenBuildsTest(unittest.TestCase):
    def test_lone_queen_is_offered_build_cell_and_builds_one(self):
        godot_path = find_godot()
        if not godot_path:
            self.skipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(FIXTURE, godot_path, timeout=240, fixed_fps=30)
        self.assertIsNotNone(session_file, "scenario run produced no session log")
        actions = [e for e in load_entries(session_file) if e.get("type") == "action"]
        bad = [e for e in actions if e.get("result") != "accepted"]
        self.assertEqual(bad, [], "actions not accepted: %s" % bad)
        done = [e for e in actions if e.get("do") == "assert" and "built_cells_at_least" in str(e.get("target"))]
        self.assertTrue(done, "the built-cell assertion never ran")

    def test_queen_resumes_a_part_built_site(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
             "--script", RESUME_SCRIPT],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=RESUME_TIMEOUT_SECONDS,
        )
        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("RR16 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("RR16 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)

    def test_orders_zones_owns_the_general_build(self):
        source = (ROOT / "scripts" / "orders_zones.gd").read_text(encoding="utf-8")
        self.assertIn("func queen_build_at(", source)
        runner = (ROOT / "scripts" / "challenge_runner.gd").read_text(encoding="utf-8")
        self.assertIn("orders_zones.queen_build_at(", runner)


if __name__ == "__main__":
    unittest.main()
