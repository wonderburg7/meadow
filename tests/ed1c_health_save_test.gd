extends SceneTree
## ED-1c test: a bee's health is saved and restored; a save without the key
## loads every bee at full health.
##
## Boots the real Main.tscn into level 3, lowers two bees' health, saves,
## then restores that save in place (saving.gd::_restore) and checks each bee
## came back with the health she was saved with. The same save with every
## "health" key erased restores every bee at GameConfig.health_capacity.
##
## Run by tests/test_ed1c_health_save.py:
##   godot --headless --path <repo> --script res://tests/ed1c_health_save_test.gd
## Prints "ED1C PASS" and exits 0, or prints each failure and exits 1.

const LEVEL := 3
const BOOT_FRAMES := 10
const SAVE_PATH := "user://ed1c_test_save.json"

var _main: Node = null
var _frame := 0
var _phase := "boot"
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	if _phase == "boot":
		var session: Node = root.get_node("Session")
		session.starting_level = LEVEL
		session.menu_pending = false
		var scene: PackedScene = load("res://scenes/Main.tscn")
		_main = scene.instantiate()
		root.add_child(_main)
		current_scene = _main
		_phase = "settle"
	elif _phase == "settle" and _frame >= BOOT_FRAMES:
		_run()
		_phase = "done"
	if _phase == "done":
		_report()
		return true
	return false


func _run() -> void:
	var save_game: GDScript = _main.SaveGame
	var capacity: float = root.get_node("GameConfig").health_capacity
	var bees: Array = _main.get_tree().get_nodes_in_group("bees")
	if bees.size() < 2:
		_fail("the level has fewer than two bees")
		return
	var wanted := {}
	for i in range(2):
		var bee: Node = bees[i]
		bee.health = capacity * (0.25 + 0.25 * i)
		wanted[bee.bee_id] = bee.health
	if not save_game.save(_main, SAVE_PATH):
		_fail("could not write the test save")
		return
	var data: Dictionary = save_game.read(SAVE_PATH)
	for entry: Dictionary in data.get("bees", []):
		if wanted.has(int(entry.get("id", -1))):
			if not is_equal_approx(float(entry.get("health", -1.0)), wanted[int(entry["id"])]):
				_fail("the save did not record bee %d's health" % int(entry["id"]))

	# Restore with the health in place: each bee keeps what she was saved with.
	# Raise the live bees first so the restore has to bring the value back.
	for bee: Node in bees:
		bee.health = capacity
	_main.saving._restore(data)
	var restored := _health_by_id()
	for id: int in wanted:
		if not restored.has(id):
			_fail("bee %d did not come back from the restore" % id)
		elif not is_equal_approx(restored[id], wanted[id]):
			_fail("bee %d came back with health %.2f, saved %.2f" % [id, restored[id], wanted[id]])

	# An old save has no key: every bee loads at full health.
	var old_save := data.duplicate(true)
	for entry: Dictionary in old_save.get("bees", []):
		entry.erase("health")
	_main.saving._restore(old_save)
	restored = _health_by_id()
	if restored.is_empty():
		_fail("no bees after restoring the old save")
	for id: int in restored:
		if not is_equal_approx(restored[id], capacity):
			_fail("bee %d of a save without health loaded at %.2f, not full" % [id, restored[id]])
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _health_by_id() -> Dictionary:
	var out := {}
	for node: Node in _main.get_tree().get_nodes_in_group("bees"):
		if not node.is_queued_for_deletion():
			out[node.bee_id] = node.health
	return out


func _fail(line: String) -> void:
	_failures.append(line)


func _report() -> void:
	if _failures.is_empty():
		print("ED1C PASS")
		quit(0)
	else:
		for line: String in _failures:
			print("ED1C FAIL: " + line)
		quit(1)
