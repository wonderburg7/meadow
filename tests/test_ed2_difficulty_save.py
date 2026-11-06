"""ED-2: a run's difficulty, saved.

Runs tests/ed2_difficulty_save_test.gd in a headless Godot. That script checks
a new run is Standard, Easy (set directly, as a headless run would) survives
save and restore, and a save without the key, or with an unknown value, loads
as Standard. The save goes to a temporary file, never the player's saves.

Requires a real Godot executable -- skips where none is installed or the
engine cannot initialise headlessly.

Run with: python -m unittest tests.test_ed2_difficulty_save
"""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/ed2_difficulty_save_test.gd"
TIMEOUT_SECONDS = 300


class DifficultySaveTest(unittest.TestCase):
    def test_difficulty_round_trip(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")

        with tempfile.TemporaryDirectory() as scratch:
            save_path = Path(scratch) / "ed2_save.json"
            finished = subprocess.run(
                [godot, "--headless", "--disable-crash-handler", "--fixed-fps", "60",
                 "--path", str(ROOT), "--script", TEST_SCRIPT,
                 "--", "--ed2-save=%s" % save_path.as_posix()],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
                timeout=TIMEOUT_SECONDS,
            )
            saved = json.loads(save_path.read_text(encoding="utf-8")) if save_path.exists() else None

        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("ED2 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        for line in ("ED2 a new run is Standard", "ED2 Easy survives save and restore",
                     "ED2 an old save loads as Standard", "ED2 an unknown difficulty loads as Standard"):
            self.assertIn(line, output, "a check did not run: " + line)
        self.assertIn("ED2 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)
        self.assertIsNotNone(saved, "the run wrote no save")
        self.assertEqual(saved["session"].get("difficulty"), "easy", "the save does not hold Easy")


if __name__ == "__main__":
    unittest.main()
