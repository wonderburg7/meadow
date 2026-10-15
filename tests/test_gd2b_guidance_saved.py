"""Verify guidance's rendered ledger persists with a run save."""

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import godot_compile_check as gcc  # noqa: E402


SCRIPT = r'''extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var policy_script: GDScript = load("res://scripts/guidance_policy.gd")
	var catalogue: GDScript = load("res://scripts/guidance_catalogue.gd")
	var before = policy_script.new()
	before.update_facts({"missing_nurse_workforce": 1, "brood_cells": 2, "nurses": 0})
	var entry: Dictionary = catalogue.explanation(before.eligible_id(), before.facts)
	before.mark_rendered(entry)
	var saved: Dictionary = before.save_data()

	var after = policy_script.new()
	after.restore(saved)
	after.update_facts({"missing_nurse_workforce": 1, "brood_cells": 2, "nurses": 0})
	assert(after.eligible_id() == "")
	assert(after.shown_entries().size() == 1)
	assert(after.shown_entries()[0].evidence == entry.evidence)

	var older_save = policy_script.new()
	older_save.restore({})
	older_save.update_facts({"missing_nurse_workforce": 1, "brood_cells": 2, "nurses": 0})
	assert(older_save.eligible_id() == "missing_nurse_workforce")
	assert(older_save.shown_entries().is_empty())
	print("GD2B PASS")
	quit()
'''


class GuidanceSavedTest(unittest.TestCase):
    def test_rendered_guidance_survives_a_save(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("Godot cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot))
        with tempfile.TemporaryDirectory(dir=ROOT / "tests") as directory:
            script = Path(directory) / "gd2b_test.gd"
            script.write_text(SCRIPT, encoding="utf-8")
            finished = subprocess.run(
                [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
                 "--script", str(script)],
                capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=30,
            )
        output = gcc.combined_output(finished)
        self.assertEqual(gcc.failing_lines(output), [], output[-4000:])
        self.assertEqual(finished.returncode, 0, output[-4000:])
        self.assertIn("GD2B PASS", output)

    def test_run_save_and_restore_wire_guidance(self):
        save = (ROOT / "scripts" / "save_game.gd").read_text(encoding="utf-8")
        restore = (ROOT / "scripts" / "saving.gd").read_text(encoding="utf-8")
        self.assertIn('"guidance": world.gallerin_panel.guidance_policy.save_data()', save)
        self.assertIn('guidance_policy.restore(data.get("guidance", {}))', restore)


if __name__ == "__main__":
    unittest.main()
