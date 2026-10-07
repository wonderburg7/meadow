"""T2-2: Automation gates automine and outward comb building.

Runs tests/t2_2_automation_gate_test.gd headlessly (both halves refused
unowned, allowed owned, marked work unaffected) and checks Challenge 2's stage
2.8 data frees Backup roles and Automation. Requires a real Godot for the
first test.
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402


def _stage_block(text: str, stage_id: str) -> str:
    start = text.index('"id": "%s"' % stage_id)
    end = text.index("\n\t},", start)
    return text[start:end]


class AutomationGateTest(unittest.TestCase):
    def test_stage_2_8_frees_backup_roles_and_automation(self):
        text = (ROOT / "scripts" / "challenge_stages.gd").read_text(encoding="utf-8")
        self.assertIn('const BACKUP_ROLES_SKILL := "skill.hive_mind.backup_roles"', text)
        self.assertIn('const AUTOMATION_SKILL := "skill.hive_mind.automation"', text)
        free, keys = _stage_block(text, "2.8").split('"unlocked_keys"')
        for name in ("BACKUP_ROLES_SKILL", "AUTOMATION_SKILL"):
            self.assertIn(name, free)
            self.assertIn(name, keys)
        self.assertNotIn("AUTOMATION_SKILL", _stage_block(text, "2.7"))

    def test_gate_data(self):
        actions = (ROOT / "scripts" / "actions.gd").read_text(encoding="utf-8")
        self.assertEqual(actions.count('"skill": "skill.hive_mind.automation"'), 2)
        roles = (ROOT / "scripts" / "roles.gd").read_text(encoding="utf-8")
        self.assertIn('"key": "automine", "skill": "skill.hive_mind.automation"', roles)

    def test_gates_refuse_unowned_and_allow_owned(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
             "--script", "res://tests/t2_2_automation_gate_test.gd"],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120,
        )
        output = gcc.combined_output(finished)
        failures = [l for l in output.splitlines() if l.startswith("T2_2 FAIL")]
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("T2_2 PASS", output, output[-1500:])


if __name__ == "__main__":
    unittest.main()
