"""T2-14: a comb worker's idle reason asks whether there is room to build.

Runs tests/t2_14_idle_reason_pure_test.gd headlessly. The source guard checks
that idle_reason() no longer starts a site; the headless run checks the
behaviour. Requires a real Godot for the run; skips where none is installed.

Run with: python -m unittest tests.test_t2_14_idle_reason_pure
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/t2_14_idle_reason_pure_test.gd"
TIMEOUT_SECONDS = 180


class T214IdleReasonPureTest(unittest.TestCase):
    def test_idle_reason_asks_for_room_and_starts_no_site(self):
        text = (ROOT / "scripts" / "bee.gd").read_text(encoding="utf-8")
        start = text.index("func idle_reason(")
        body = text[start:text.index("\nfunc ", start + 1)]
        self.assertIn("hive.has_room_to_build(", body)
        self.assertNotIn("create_next_cell_site(", body)

    def test_room_to_build_in_a_headless_run(self):
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
        failures = [line for line in output.splitlines() if line.startswith("T2_14 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("T2_14 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
