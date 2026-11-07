extends SceneTree
## ED-2 test: a run's difficulty is saved and restored. A new run is
## Standard; Easy survives a save and an in-place restore; a save without
## the key, or with an unknown value, loads as Standard.
##
## Run by tests/test_ed2_difficulty_save.py:
##   godot --headless --path <repo> --script res://tests/ed2_difficulty_save_test.gd
## Prints "ED2 PASS" and exits 0, or prints each failure and exits 1.

const LEVEL := 3                    # a Scenario level: no Challenge branches
const BOOT_FRAMES := 10             # let Main._ready build the world first
const SAVE_PATH := "user://ed2_test_save.json"

var _main: Node = null
var _frame := 0
var _phase := "boot"
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	if _phase == "boot":
		_boot()
	elif _phase == "settle" and _frame >= BOOT_FRAMES:
		_run()
		_phase = "done"
	if _phase == "done":
		_report()
		return true
	return false


func _boot() -> void:
	if not root.has_node("Session"):
		_fail("Session autoload is not loaded")
		_phase = "done"
		return
	var session: Node = root.get_node("Session")
	session.starting_level = LEVEL
	session.menu_pending = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _run() -> void:
	var session: Node = root.get_node("Session")
	var save_game: GDScript = _main.SaveGame
	_check(session.difficulty == "standard", "a new run is not Standard")
	var data := _save_and_read(save_game)
	_check(data.get("session", {}).get("difficulty") == "standard", "a Standard run did not save its difficulty")

	# Easy, as a headless scenario would set it, survives save and restore.
	session.difficulty = "easy"
	data = _save_and_read(save_game)
	_check(data.get("session", {}).get("difficulty") == "easy", "the save does not record Easy")
	session.difficulty = "standard"
	_main.saving._restore(data)
	_check(session.difficulty == "easy", "a restore lost Easy")

	# A save without the key, or with an unknown value, loads as Standard.
	var old_save := data.duplicate(true)
	old_save["session"].erase("difficulty")
	_main.saving._restore(old_save)
	_check(session.difficulty == "standard", "a save without the key did not load as Standard")
	session.difficulty = "easy"
	var odd_save := data.duplicate(true)
	odd_save["session"]["difficulty"] = "nightmare"
	_main.saving._restore(odd_save)
	_check(session.difficulty == "standard", "an unknown difficulty did not load as Standard")

	# A new run puts Easy back to Standard.
	session.difficulty = "easy"
	session.reset_run_state()
	_check(session.difficulty == "standard", "a new run kept the last run's Easy")


func _save_and_read(save_game: GDScript) -> Dictionary:
	if not save_game.save(_main, SAVE_PATH):
		_fail("could not write the test save")
		return {}
	return save_game.read(SAVE_PATH)


func _check(ok: bool, message: String) -> void:
	if not ok:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("ED2 PASS")
		quit(0)
		return
	for message in _failures:
		print("ED2 FAIL: " + message)
	quit(1)
