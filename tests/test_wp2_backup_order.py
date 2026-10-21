"""WP-2: owned, each bee follows an ordered backup list.

Runs tests/wp2_backup_order_test.gd in a headless Godot. That script boots the
real Main.tscn into level 3, stops every bee, empties the comb and, for each
case, spawns one Miner with automine off and nothing marked, so her own role
has no work, then lets her run from her idle state:

- unowned, she falls back on her one backup as today: with Nurse she stays
  idle (even with a list forced onto her), with Forager she forages;
- owned, with the list Nurse then Forager set through orders_zones.gd's
  handler, Nurse has nothing so she takes up foraging; with Nurse alone she
  stays idle;
- a bee living at purchase gets her backup first, then the colony default; a
  bee born after it takes the colony default;
- the lists and the default survive save and restore, and a save without
  them loads the default order and each bee with her backup first.

It stands in for a headless scenario fixture because no scenario action can
set a backup list (scenario_actions.gd is outside this slice). The save goes
to a temporary file, never the player's saves.

Requires a real Godot executable -- skips where none is installed or the
engine cannot initialise headlessly.

Run with: python -m unittest tests.test_wp2_backup_order
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

TEST_SCRIPT = "res://tests/wp2_backup_order_test.gd"
TIMEOUT_SECONDS = 300
CASES = ("unowned, backup Nurse", "unowned, backup Forager",
         "owned, list Nurse then Forager", "owned, list Nurse only")


class BackupOrderTest(unittest.TestCase):
    def test_ordered_backup_list(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")

        with tempfile.TemporaryDirectory() as scratch:
            save_path = Path(scratch) / "wp2_save.json"
            finished = subprocess.run(
                [godot, "--headless", "--disable-crash-handler", "--fixed-fps", "60",
                 "--path", str(ROOT), "--script", TEST_SCRIPT,
                 "--", "--wp2-save=%s" % save_path.as_posix()],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
                timeout=TIMEOUT_SECONDS,
            )
            saved = json.loads(save_path.read_text(encoding="utf-8")) if save_path.exists() else None

        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("WP2 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        for case in CASES:
            self.assertIn("WP2 %s: she" % case, output, "the %s case did not run" % case)
        self.assertIn("WP2 purchase:", output, "the purchase check did not run")
        self.assertIn("WP2 an old save loads", output, "the old-save check did not run")
        self.assertIn("WP2 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)

        self.assertIsNotNone(saved, "the run wrote no save")
        self.assertIn("backup_order_default", saved["session"], "the save holds no colony default")
        self.assertTrue(all("backup_order" in b for b in saved["bees"]), "a bee entry has no backup_order")


if __name__ == "__main__":
    unittest.main()
