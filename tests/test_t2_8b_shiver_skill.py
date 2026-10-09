"""T2-8b: Shiver Cluster is a Hive Mind tier-2 node behind Backup roles.

The catalogue row is read straight from the shipping skills.gd and the starting
rule from run_availability.gd. The behaviour (a Colony Run pays the multiplied
bill until it buys the node, other runs own it) is run in
tests/test_t2_8a_shiver_bill.py, which this module's check is paired with.
Requires a real Godot for the sheet test.
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

SCRIPT = """extends SceneTree
var _frame := 0

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		_check()
	return _frame >= 4

func _check() -> void:
	var Skills = load("res://scripts/skills.gd")
	var RunAvailability = load("res://scripts/run_availability.gd")
	var id: String = Skills.SHIVER_CLUSTER
	var row: Dictionary = Skills.entry(id)
	print("T2_8B ROW %s|%d|%s" % [row.sector, row.tier, row.cost.has(Skills.HONEY)])
	print("T2_8B BACKUP %s" % Skills.has(Skills.BACKUP_ROLES))
	var colony: Dictionary = RunAvailability.sheet_for({"run_type": "colony"})
	var scenario: Dictionary = RunAvailability.sheet_for({"name": "x"})
	var banned: Dictionary = RunAvailability.sheet_for({"skill_bans": [id]})
	print("T2_8B COLONY %s" % colony.starting.has(id))
	print("T2_8B OTHER %s" % scenario.starting.has(id))
	print("T2_8B BANNED %s|%s" % [banned.starting.has(id), banned.skills[id].source])
"""


class ShiverSkillTest(unittest.TestCase):
    def test_the_node_and_its_starting_rule(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot))
        with tempfile.TemporaryDirectory() as folder:
            script = Path(folder) / "t2_8b.gd"
            script.write_text(SCRIPT, encoding="utf-8")
            finished = subprocess.run(
                [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
                 "--script", str(script)],
                capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180)
        output = gcc.combined_output(finished)
        self.assertEqual(gcc.failing_lines(output), [], output[-2000:])
        seen = {}
        for line in output.splitlines():
            if line.startswith("T2_8B "):
                key, _, value = line[6:].partition(" ")
                seen[key] = value.strip()
        self.assertEqual(seen.get("ROW"), "hive_mind|2|true")
        self.assertEqual(seen.get("COLONY"), "false")
        self.assertEqual(seen.get("OTHER"), "true")
        self.assertEqual(seen.get("BANNED"), "false|unavailable")

    def test_it_sits_behind_backup_roles_in_the_catalogue(self):
        text = (ROOT / "scripts" / "skills.gd").read_text(encoding="utf-8").replace("\r\n", "\n")
        block = text.split('"id": SHIVER_CLUSTER', 1)[1].split("\n\t},", 1)[0]
        self.assertIn('"requires_previous_tier": true', block)
        self.assertIn('"all_of": []', block)  # tier gating reaches Backup roles


if __name__ == "__main__":
    unittest.main()
