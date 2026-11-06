extends SceneTree
## ED-2 test: a run's difficulty is reset with the run, saved and restored.
##
## Boots the real Main.tscn into level 3 and checks:
## - a new run is Standard (reset_run_state sets it);
## - Easy, set here as a headless run would set it, survives SaveGame.save,
##   SaveGame.read and saving.gd::_restore;
## - a save without the key, or with an unknown value, loads as Standard.
##
## Run by tests/test_ed2_difficulty_save.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/ed2_difficulty_save_test.gd -- --ed2-save=<file>
## Prints "ED2 PASS" and exits 0, or prints each failure and exits 1.

const LEVEL := 3
const BOOT_FRAMES := 10

var _main: Node = null
var _session: Node = null
var _frame := 0
var _phase := "boot"
var _save_path := ""
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				_run_checks()
				_phase = "done"
	if _phase == "done":
		_report()
		return true
	return false


# Autoloads are reached through the tree: a --script run compiles this file
# before they exist.
func _boot() -> void:
	if not root.has_node("Session"):
		_fail("the Session autoload is not loaded")
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--ed2-save="):
			_save_path = arg.trim_prefix("--ed2-save=")
	if _save_path == "":
		_fail("no --ed2-save=<file> given")
		return
	_session = root.get_node("Session")
	# A stale value from an earlier run must not survive a new one.
	_session.difficulty = _session.DIFFICULTY_EASY
	_session.reset_run_state()
	_check(_session.difficulty == _session.DIFFICULTY_STANDARD,
		"a new run is %s, not standard" % _session.difficulty)
	print("ED2 a new run is Standard")
	_session.starting_level = LEVEL
	_session.menu_pending = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _run_checks() -> void:
	_check(_session.difficulty == _session.DIFFICULTY_STANDARD,
		"the booted run is %s, not standard" % _session.difficulty)
	_session.difficulty = _session.DIFFICULTY_EASY
	if not _main.SaveGame.save(_main, _save_path):
		_fail("SaveGame.save failed")
		return
	var data: Dictionary = _main.SaveGame.read(_save_path)
	if data.is_empty():
		_fail("SaveGame.read could not read the save back")
		return
	_check(str(data.get("session", {}).get("difficulty", "")) == _session.DIFFICULTY_EASY,
		"the save holds difficulty %s, not easy" % data.get("session", {}).get("difficulty", "<none>"))

	_session.difficulty = _session.DIFFICULTY_STANDARD
	_main.saving._restore(data.duplicate(true))
	_check(_session.difficulty == _session.DIFFICULTY_EASY,
		"Easy restored as %s" % _session.difficulty)
	print("ED2 Easy survives save and restore")

	var old: Dictionary = data.duplicate(true)
	old.get("session", {}).erase("difficulty")
	_main.saving._restore(old)
	_check(_session.difficulty == _session.DIFFICULTY_STANDARD,
		"a save without a difficulty loaded as %s" % _session.difficulty)
	print("ED2 an old save loads as Standard")

	var odd: Dictionary = data.duplicate(true)
	odd["session"]["difficulty"] = "nightmare"
	_main.saving._restore(odd)
	_check(_session.difficulty == _session.DIFFICULTY_STANDARD,
		"an unknown difficulty loaded as %s" % _session.difficulty)
	print("ED2 an unknown difficulty loads as Standard")


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)


func _fail(line: String) -> void:
	_failures.append(line)
	_phase = "done"


func _report() -> void:
	if _failures.is_empty():
		print("ED2 PASS")
		quit(0)
	else:
		for line: String in _failures:
			print("ED2 FAIL: " + line)
		quit(1)
