"""Verify Dr Gallerin explains hungry brood and starving bees."""

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
	var hungry_only = policy_script.new()
	hungry_only.update_facts({"hungry_brood": 3})
	assert(hungry_only.eligible_id() == "hungry_brood")
	var brood: Dictionary = catalogue.explanation(hungry_only.eligible_id(), hungry_only.facts)
	assert(brood.evidence.contains("3 brood cells unfed"))
	assert(brood.text.contains("If food and a nurse") and brood.text.contains("If workers or stores"))

	var starving_only = policy_script.new()
	starving_only.update_facts({"starving": 2})
	assert(starving_only.eligible_id() == "starving")
	var bees: Dictionary = catalogue.explanation(starving_only.eligible_id(), starving_only.facts)
	assert(bees.evidence.contains("2 bees"))
	assert(bees.text.contains("If forage or stored food") and bees.text.contains("If food is not ready"))

	var workforce_first = policy_script.new()
	workforce_first.update_facts({
		"missing_nurse_workforce": 1, "brood_cells": 3, "nurses": 0,
		"hungry_brood": 3, "starving": 2,
	})
	assert(workforce_first.eligible_id() == "missing_nurse_workforce")

	var policy = policy_script.new()
	policy.update_facts({"hungry_brood": 3, "starving": 2})
	policy.mark_rendered(catalogue.explanation(policy.eligible_id(), policy.facts))
	policy.mark_rendered(catalogue.explanation(policy.eligible_id(), policy.facts))
	policy.update_facts({"hungry_brood": 0, "starving": 0})
	assert(policy.shown_entries().size() == 2)
	assert(policy.shown_entries()[0].evidence == brood.evidence)
	assert(policy.shown_entries()[1].evidence == bees.evidence)
	assert(catalogue.current_state(brood.id, policy.facts).contains("cleared"))
	assert(catalogue.current_state(bees.id, policy.facts).contains("cleared"))
	print("GD3 PASS")
	quit()
'''


class GuidanceHungerTest(unittest.TestCase):
    def test_hunger_explanations_and_history(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("Godot cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot))
        with tempfile.TemporaryDirectory(dir=ROOT / "tests") as directory:
            script = Path(directory) / "gd3_test.gd"
            script.write_text(SCRIPT, encoding="utf-8")
            finished = subprocess.run(
                [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
                 "--script", str(script)],
                capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=30,
            )
        output = gcc.combined_output(finished)
        self.assertEqual(gcc.failing_lines(output), [], output[-4000:])
        self.assertEqual(finished.returncode, 0, output[-4000:])
        self.assertIn("GD3 PASS", output)


if __name__ == "__main__":
    unittest.main()
