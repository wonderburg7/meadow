"""PP-5: Priority cells -- marked brood cells are fed first.

Runs tests/pp5_priority_cells_test.gd in a headless Godot. That script boots
the real Main.tscn, stops every bee but one nurse, empties the comb and gives
two built cells a hungry larva each, with the nurse carrying food for exactly
one. It marks the larva today's order would pass over through the handler
the cell popup's "Feed first" box reaches, and lets the nurse work:

- unowned, the row is hidden, the mark cannot be set, and she feeds the larva
  today's order picks, even with a mark forced on the other cell;
- owned, she feeds the marked larva first on pollen and nectar, pollen and
  honey, bee bread and nectar, and royal jelly (two gyne larvae);
- the mark survives save and restore, and a save without it loads unmarked.

It stands in for a headless scenario fixture because no scenario action can
mark a cell (scenario_actions.gd is Codex-owned, as GC-4's test notes), so
test_scenarios/pp5_priority_cells.json was not written. The save goes to a
temporary file, never the player's saves.

Requires a real Godot executable -- skips where none is installed or the
engine cannot initialise headlessly.

Run with: python -m unittest tests.test_pp5_priority_cells
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

TEST_SCRIPT = "res://tests/pp5_priority_cells_test.gd"
TIMEOUT_SECONDS = 300
CASES = ("unowned", "pollen and nectar", "pollen and honey", "bee bread and nectar", "royal jelly for gynes")


class PriorityCellsTest(unittest.TestCase):
    def test_marked_larvae_are_fed_first(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")

        with tempfile.TemporaryDirectory() as scratch:
            save_path = Path(scratch) / "pp5_save.json"
            finished = subprocess.run(
                [godot, "--headless", "--disable-crash-handler", "--fixed-fps", "60",
                 "--path", str(ROOT), "--script", TEST_SCRIPT,
                 "--", "--pp5-save=%s" % save_path.as_posix()],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
                timeout=TIMEOUT_SECONDS,
            )
            saved = json.loads(save_path.read_text(encoding="utf-8")) if save_path.exists() else None

        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("PP5 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        for case in CASES:
            self.assertIn("PP5 %s: the nurse fed the" % case, output, "the %s case did not run" % case)
        self.assertIn("PP5 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)

        self.assertIsNotNone(saved, "the run wrote no save")
        marks = [c for c in saved["cells"] if c.get("priority_cell")]
        self.assertEqual(len(marks), 1, "the save should hold exactly one marked cell")
        self.assertTrue(all("priority_cell" in c for c in saved["cells"]), "a cell entry has no priority_cell")


if __name__ == "__main__":
    unittest.main()
