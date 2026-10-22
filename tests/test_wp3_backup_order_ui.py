"""WP-3: the ordered backup list in the selection panel and the colony default.

Writes a small test script to a temporary folder and runs it in a headless
Godot against the real Main.tscn (level 3):

- unowned, the selection panel shows no ordered list, and the single Backup
  choice still sets the backup;
- owned, pressing the real up, down and remove buttons in the selection panel
  reorders the list of every selected bee at once, and a mixed selection
  shows the first bee's list and says so;
- the Colony window's "New bees fall back on" list changes the colony
  default, and a bee emerging afterwards takes it while living bees keep
  their own lists.

No scenario action can press a button, hence the script; test_scenarios/
wp3_backup_order_ui.json covers the layout side (the panel boots with the
skill owned and stays inside the screen).

Requires a real Godot executable -- skips where none is installed or the
engine cannot initialise headlessly.

Run with: python -m unittest tests.test_wp3_backup_order_ui
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
from analyze_session import load_entries  # noqa: E402
from run_scenario import run_once  # noqa: E402

TIMEOUT_SECONDS = 300
FIXTURE = ROOT / "test_scenarios" / "wp3_backup_order_ui.json"
SCRIPT = r'''extends SceneTree
# WP3 headless check, written to a temporary file by tests/test_wp3_backup_order_ui.py.
const WORK_PRIORITIES := "skill.hive_mind.work_priorities"
var Roles: GDScript
var _main: Node = null
var _session: Node = null
var _frame := 0
var _phase := "boot"
var _phase_frame := 0
var _a: Node2D = null
var _b: Node2D = null
var _failures: PackedStringArray = PackedStringArray()

func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_session = root.get_node("Session")
			Roles = load("res://scripts/roles.gd")
			_session.starting_level = 3
			_session.menu_pending = false
			_main = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
			root.add_child(_main)
			current_scene = _main
			_phase = "settle"
		"settle":
			if _frame >= 10:
				_unowned()
		"seeding":
			if _frame - _phase_frame >= 3:
				_owned()
	if _phase == "done":
		if _failures.is_empty():
			print("WP3 PASS")
			quit(0)
		else:
			for line: String in _failures:
				print("WP3 FAIL: " + line)
			quit(1)
		return true
	return false

func _check(ok: bool, failure: String) -> void:
	if not ok:
		_failures.append(failure)

func _spawn(backup_key: String) -> Node2D:
	var bee: Node2D = _main.world_building._spawn_indoor_bee(_main.Bee.Role.MINER)
	bee.process_mode = Node.PROCESS_MODE_DISABLED
	bee.set_secondary_role(Roles.id_for_key(backup_key))
	return bee

func _press(path_name: String, under: Node) -> bool:
	var button: Node = under.find_child(path_name, true, false)
	if button == null or not (button is BaseButton) or button.disabled:
		return false
	button.pressed.emit()
	return true

func _unowned() -> void:
	for bee: Node in _main.get_tree().get_nodes_in_group("bees"):
		bee.process_mode = Node.PROCESS_MODE_DISABLED
	for role_id: int in [Roles.MINER, Roles.NURSE, Roles.FORAGER]:
		var skill: String = Roles.skill_for(role_id)
		if skill != "" and not _session.progression.is_owned(skill):
			_session.progression.grant_temporary(skill)
	_main.Availability.invalidate()
	_a = _spawn("nurse")
	_b = _spawn("nurse")
	_main.selected_bees = [_a, _b]
	_main.hud.update_selection(_main.selected_bees)
	_check(not _main.Bee.work_priorities_owned(), "Work priorities is owned at the start of level 3")
	_check(_main.hud.find_child("backup_order_list", true, false) == null, "unowned: the ordered list is shown")
	_check(_main.hud.find_child("backup_order_column", true, false) == null, "unowned: the list column is shown")
	_check(_main.hud.find_child("backup_up_0", true, false) == null, "unowned: an up button is shown")
	_main.hud.secondary_role_requested.emit("forager")
	_check(_a.secondary_role == Roles.FORAGER and _b.secondary_role == Roles.FORAGER, "unowned: the single Backup choice no longer works")
	_check(not _a.backup_order_set, "unowned: choosing a backup set a list")
	print("WP3 unowned: the single Backup choice is unchanged, no list")
	_session.progression.grant_temporary(WORK_PRIORITIES)
	_main.Availability.invalidate()
	_phase = "seeding"
	_phase_frame = _frame

func _ids(keys: Array) -> Array:
	return keys.map(func(k: Variant) -> int: return Roles.id_for_key(str(k)))

func _owned() -> void:
	_check(_main.Bee.work_priorities_owned(), "Work priorities is not owned after the grant")
	var base: Array = [Roles.NURSE, Roles.FORAGER, Roles.MINER]
	_main.selected_bees = [_a, _b]
	_main.orders_zones._on_backup_order_requested(["nurse", "forager", "miner"])
	_check(_a.backup_order == base and _b.backup_order == base, "could not set the base list")
	_main.hud.update_selection(_main.selected_bees)
	_check(_main.hud.find_child("backup_order_list", true, false) != null, "owned: no ordered list is shown")
	_check(_main.hud.find_child("backup_up_0", true, false) != null, "owned: no up button")
	_check(_main.hud.find_child("backup_down_0", true, false) != null, "owned: no down button")
	# Move the second job up with the real button.
	_check(_press("backup_up_1", _main.hud), "owned: the up button for the second job could not be pressed")
	var moved: Array = [Roles.FORAGER, Roles.NURSE, Roles.MINER]
	_check(_a.backup_order == moved, "bee A's list after moving up is %s" % [_a.backup_order])
	_check(_b.backup_order == moved, "bee B's list after moving up is %s" % [_b.backup_order])
	print("WP3 owned: moving a job up reordered both selected bees: %s" % [_b.backup_order])
	_check(_press("backup_down_0", _main.hud), "owned: the down button could not be pressed")
	_check(_a.backup_order == base and _b.backup_order == base, "moving down did not undo it: %s" % [_a.backup_order])
	_check(_press("backup_remove_2", _main.hud), "owned: the remove button could not be pressed")
	_check(_a.backup_order == [Roles.NURSE, Roles.FORAGER] and _b.backup_order == [Roles.NURSE, Roles.FORAGER], "remove did not apply to both bees")
	_check(_main.hud.find_child("backup_add", true, false) != null, "owned: no Add a job menu")
	_check(_main.hud.find_child("backup_up_1", true, false) != null and _main.hud.find_child("backup_up_2", true, false) == null, "list has the wrong length after a removal")
	# Mixed selection says so, showing the first bee's list.
	_b.set_backup_order([Roles.MINER])
	_main.hud.update_selection(_main.selected_bees)
	var found_note := false
	for label: Node in _main.hud.find_children("*", "Label", true, false):
		if "Mixed selection" in label.text:
			found_note = true
	_check(found_note, "a mixed selection does not say so")
	_check(_main.hud.find_child("backup_up_1", true, false) != null, "a mixed selection does not show the first bee's list")
	_main.selected_bees = [_a]
	_main.hud.update_selection(_main.selected_bees)
	for label: Node in _main.hud.find_children("*", "Label", true, false):
		_check(not ("Mixed selection" in label.text), "an agreeing selection claims to be mixed")
	print("WP3 owned: a mixed selection shows the first bee's order and says so")
	# The Colony window default.
	var panel: Node = _main.colony_panel
	panel._rebuild_default_order()
	var column: Node = panel.default_order_column
	_check(column.find_child("backup_order_list", true, false) != null, "the Colony window shows no list")
	var before: Array = _session.backup_order_default.duplicate()
	_check(before.size() > 1, "the colony default is too short to test")
	_check(_press("backup_down_0", column), "Colony window: the down button could not be pressed")
	var after: Array = _session.backup_order_default
	_check(after.size() == before.size() and after[0] == before[1] and after[1] == before[0], "the colony default did not change: %s from %s" % [after, before])
	var newborn: Node2D = _main.world_building._spawn_indoor_bee(_main.Bee.Role.FORAGER)
	newborn.process_mode = Node.PROCESS_MODE_DISABLED
	_check(newborn.backup_list() == after, "a newly emerged bee took %s, not the colony default %s" % [newborn.backup_list(), after])
	_check(_a.backup_order == [Roles.NURSE, Roles.FORAGER], "changing the default touched a living bee")
	print("WP3 colony: the default list changed what a newly emerged bee takes: %s" % [newborn.backup_order])
	_phase = "done"
'''


class BackupOrderUiTest(unittest.TestCase):
    def test_backup_order_ui(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")

        with tempfile.TemporaryDirectory() as scratch:
            script = Path(scratch) / "wp3_backup_order_ui_run.gd"
            script.write_text(SCRIPT, encoding="utf-8", newline="\n")
            finished = subprocess.run(
                [godot, "--headless", "--disable-crash-handler", "--fixed-fps", "60",
                 "--path", str(ROOT), "--script", script.as_posix()],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
                timeout=TIMEOUT_SECONDS,
            )

        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("WP3 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        for marker in ("WP3 unowned:", "WP3 owned: moving a job up", "WP3 owned: a mixed selection",
                       "WP3 colony:"):
            self.assertIn(marker, output, "the %r check did not run" % marker)
        self.assertIn("WP3 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)

    def test_owned_panel_fits_the_tray(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        session_file = run_once(FIXTURE, godot, timeout=TIMEOUT_SECONDS, fixed_fps=30)
        self.assertIsNotNone(session_file, "scenario run produced no session log")
        entries = load_entries(session_file)
        actions = [e for e in entries if e.get("type") == "action"]
        self.assertEqual([e for e in actions if e.get("result") == "rejected"], [], "an action or assertion was rejected")
        self.assertGreaterEqual(len([e for e in actions if e.get("do") == "assert" or e.get("action") == "assert"]), 3, "the assertions did not run")


if __name__ == "__main__":
    unittest.main()
