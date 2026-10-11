"""RR-3: a new run from the menu gets its own default name.

Runs a throwaway headless Godot script (written to a temp directory) that
points SaveSlots at its scratch root and checks SaveSlots.fresh_run_name:
no slots gives "My colony"; a recorded "My colony" gives "My colony 2"; both
recorded gives "My colony 3".

Requires a real Godot executable -- skips where none is installed.

Run with: python -m unittest tests.test_rr3_fresh_run_name
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TIMEOUT_SECONDS = 300

SCRIPT = """extends SceneTree

const S = preload("res://scripts/save_slots.gd")

func _process(_delta: float) -> bool:
\tS.use_scratch_root()
\tvar failures := 0
\tvar cases := []
\tcases.append(["no slots", S.fresh_run_name("My colony"), "My colony"])
\tS.record_save(S.slugify("My colony"), "My colony", 1)
\tcases.append(["one slot", S.fresh_run_name("My colony"), "My colony 2"])
\tS.record_save(S.slugify("My colony 2"), "My colony 2", 1)
\tcases.append(["two slots", S.fresh_run_name("My colony"), "My colony 3"])
\tfor c in cases:
\t\tif c[1] != c[2]:
\t\t\tfailures += 1
\t\t\tprint("RR3 FAIL %s: got '%s', wanted '%s'" % [c[0], c[1], c[2]])
\tS.use_scratch_root()
\tif failures == 0:
\t\tprint("RR3 PASS")
\tquit(1 if failures > 0 else 0)
\treturn true
"""


class RR3FreshRunNameTest(unittest.TestCase):
    def test_fresh_run_name_skips_taken_slugs(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        with tempfile.TemporaryDirectory() as tmp:
            script = Path(tmp) / "rr3_probe.gd"
            script.write_text(SCRIPT, encoding="utf-8")
            finished = subprocess.run(
                [godot, "--headless", "--disable-crash-handler", "--fixed-fps", "60",
                 "--path", str(ROOT), "--script", str(script)],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
                timeout=TIMEOUT_SECONDS,
            )
        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("RR3 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("RR3 PASS", output, "the probe did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


if __name__ == "__main__":
    unittest.main()
