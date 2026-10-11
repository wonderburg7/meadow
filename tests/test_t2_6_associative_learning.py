"""T2-6: associative learning in a headless Godot run."""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402


class AssociativeLearningTest(unittest.TestCase):
    def test_skill_entry_enables_behaviour(self):
        text = (ROOT / "scripts" / "skills.gd").read_text(encoding="utf-8")
        start = text.index('"id": ASSOCIATIVE_LEARNING, "name":')
        entry = text[start:text.index("\n\t},", start)]
        self.assertIn('"status": "existing"', entry)
        self.assertIn('{"type": "enable_behaviour", "key": "handling_experience_on"}', entry)

    def test_direct_reads_use_helper(self):
        text = (ROOT / "scripts" / "bee_foraging.gd").read_text(encoding="utf-8")
        self.assertNotIn("if GameConfig.handling_experience_on:", text)

    def test_learning_builds_and_fades(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
             "--script", "res://tests/t2_6_associative_learning_test.gd"],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120,
        )
        output = gcc.combined_output(finished)
        failures = [line for line in output.splitlines() if line.startswith("T2_6 FAIL")]
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("T2_6 PASS", output, output[-1500:])


if __name__ == "__main__":
    unittest.main()
