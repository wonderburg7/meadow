"""Run the shipping guidance policy and Dr Gallerin view in Godot."""

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
	var policy = policy_script.new()
	policy.update_facts({"missing_nurse_workforce": 1, "brood_cells": 2, "nurses": 0})
	assert(policy.eligible_id() == "missing_nurse_workforce")
	var nurse: Dictionary = catalogue.explanation(policy.eligible_id(), policy.facts)
	assert(nurse.evidence.contains("2 brood cells"))
	assert(nurse.text.contains("If a worker") and nurse.text.contains("If workers"))
	# Detection and an unseen line do not consume the first encounter.
	assert(policy.eligible_id() == "missing_nurse_workforce")
	policy.mark_rendered(nurse)
	assert(policy.eligible_id() == "")
	policy.update_facts({"missing_nurse_workforce": 0, "brood_cells": 0, "nurses": 1})
	assert(policy.shown_entries().size() == 1)
	assert(policy.shown_entries()[0].evidence == nurse.evidence)
	assert(catalogue.current_state(nurse.id, policy.facts).contains("cleared"))
	policy.update_facts({"warning": 1})
	assert(policy.eligible_id() == "")

	var panel_script: GDScript = load("res://scripts/gallerin_panel.gd")
	var panel = panel_script.new()
	root.add_child(panel)
	panel.visible = true
	panel.update_guidance_facts({"missing_comb_workforce": 1, "blocked_cells": 3, "comb_workers": 0})
	# A due authored prompt wins; the explanation remains eligible.
	panel.queue_prompts([{"id": "challenge", "text": "Challenge first", "delay": 0.0}])
	panel._process(0.1)
	assert(panel._last_message == "Challenge first")
	assert(panel.guidance_policy.eligible_id() == "missing_comb_workforce")
	panel.clear_queue()
	panel.bubble.visible = false
	panel._process(0.1)
	assert(panel.guidance_policy.eligible_id() == "")
	assert(panel.guidance_policy.shown_entries().size() == 1)
	panel.update_guidance_facts({"missing_comb_workforce": 0, "blocked_cells": 0, "comb_workers": 1})
	panel._on_why_pressed()
	assert(panel._why_entries.size() == 1)
	panel._on_why_selected(0)
	assert(panel._why_detail.text.contains("3 cells blocked"))
	assert(panel._why_detail.text.contains("cleared"))
	panel._on_disable_pressed()
	assert(not panel._why_popup.visible)
	print("GD2A PASS")
	quit()
'''


class GuidanceTest(unittest.TestCase):
    def test_policy_and_panel_with_challenge_priority(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("Godot cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot))
        with tempfile.TemporaryDirectory(dir=ROOT / "tests") as directory:
            script = Path(directory) / "gd2a_test.gd"
            script.write_text(SCRIPT, encoding="utf-8")
            finished = subprocess.run(
                [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
                 "--script", str(script)],
                capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=30,
            )
        output = gcc.combined_output(finished)
        self.assertEqual(gcc.failing_lines(output), [], output[-4000:])
        self.assertEqual(finished.returncode, 0, output[-4000:])
        self.assertIn("GD2A PASS", output)

    def test_existing_snapshot_is_passed_before_challenge_return(self):
        source = (ROOT / "scripts" / "year_winter.gd").read_text(encoding="utf-8")
        refresh = source.split("func _refresh_signals(", 1)[1].split("func _refresh_panels(", 1)[0]
        self.assertLess(refresh.index("ColonyDiagnostics.compute"),
                        refresh.index("update_guidance_facts(facts)"))
        self.assertLess(refresh.index("update_guidance_facts(facts)"),
                        refresh.index("if main.challenge_runner.active:"))


if __name__ == "__main__":
    unittest.main()
