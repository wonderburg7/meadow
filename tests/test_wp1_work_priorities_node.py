"""WP-1: Work priorities is a Hive Mind tier-3 node behind Backup roles.

Read straight from the shipping skills.gd by a real Godot boot.
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
	var row: Dictionary = Skills.entry("skill.hive_mind.work_priorities")
	print("WP1 ROW %s|%d|%s|%s" % [row.sector, row.tier, row.axial, row.all_of])
	print("WP1 NAME %s" % row.name)
	print("WP1 BUILT %s" % Skills.is_built("skill.hive_mind.work_priorities"))
	print("WP1 CUT %s" % Skills.is_cut("skill.hive_mind.work_priorities"))
	print("WP1 OLD %s" % Skills.entry("skill.hive_mind.extended_backup_roles").size())
	var old_cut: bool = Skills.CUT_FROM_ALPHA.has("skill.hive_mind.extended_backup_roles")
	print("WP1 OLDCUT %s" % old_cut)
	var cp: Dictionary = Skills.entry("skill.colony.cell_priority")
	print("WP1 CELL %s|%s|%d" % [cp.name, cp.baseline, cp.tier])
	print("WP1 OLDCOLONY %d" % Skills.entry("skill.colony.work_priorities").size())
"""


class WorkPrioritiesNodeTest(unittest.TestCase):
    def test_the_node(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot))
        with tempfile.TemporaryDirectory() as folder:
            script = Path(folder) / "wp1.gd"
            script.write_text(SCRIPT, encoding="utf-8")
            finished = subprocess.run(
                [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
                 "--script", str(script)],
                capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180)
        output = gcc.combined_output(finished)
        seen = {}
        for line in output.splitlines():
            if line.startswith("WP1 "):
                key, _, value = line[4:].partition(" ")
                seen[key] = value.strip()
        self.assertEqual(seen.get("ROW"), "hive_mind|3|(-6, -1)|[\"skill.hive_mind.backup_roles\"]", output[-2000:])
        self.assertEqual(seen.get("NAME"), "Work priorities")
        self.assertEqual(seen.get("BUILT"), "true")
        self.assertEqual(seen.get("CUT"), "false")
        self.assertEqual(seen.get("OLD"), "0")
        self.assertEqual(seen.get("OLDCUT"), "false")
        self.assertEqual(seen.get("CELL"), "Cell priority|true|0")
        self.assertEqual(seen.get("OLDCOLONY"), "0")


if __name__ == "__main__":
    unittest.main()
