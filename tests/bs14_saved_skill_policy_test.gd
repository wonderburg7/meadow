extends SceneTree
## BS-14 test: a save keeps its run's skill grants and bans, and says when
## developer edits made them.
##
## Boots the real Main.tscn into level 3, then drives main.gd's
## run_definition with a test overrides file (a headless boot never reads
## the real one): a run started under a developer ban is saved, the
## overrides file changes, and the save's load steps (the ones
## saves_panel.gd and debug_panel.gd take before the reload) put the saved
## ban back rather than the file's new edit. Also checks the tag survives a
## re-save, the next new run reads the file again, a save without the field
## loads as before, and a Challenge save never hands its policy to another
## level.
##
## Run by tests/test_bs14_saved_skill_policy.py:
##   godot --headless --path <repo> --script res://tests/bs14_saved_skill_policy_test.gd
## Prints "BS14 PASS" and exits 0, or prints each failure and exits 1.

const LEVEL := 3                    # a Scenario level: no Challenge branches
const BOOT_FRAMES := 10             # let Main._ready build the world first
const SAVED_BAN := "skill.brood.gyne_rearing"
const LATER_BAN := "skill.brood.drones"
const OVERRIDES_PATH := "user://bs14_test_overrides.json"
const SAVE_PATH := "user://bs14_test_save.json"

var _main: Node = null
# Loaded once at run time: a preload cannot see the autoloads at parse time.
var _overrides: GDScript = null
var _frame := 0
var _phase := "boot"
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	if _phase == "boot":
		_boot()
	elif _phase == "settle" and _frame >= BOOT_FRAMES:
		_run()
		_cleanup()
		_phase = "done"
	if _phase == "done":
		_report()
		return true
	return false


# Autoloads are reached through the tree: a --script run compiles this file
# before they exist.
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
	var main_script: GDScript = _main.get_script()
	_overrides = load("res://scripts/developer_overrides.gd")
	var overrides: GDScript = _overrides
	var save_game: GDScript = _main.SaveGame
	overrides.reset(OVERRIDES_PATH)

	# A headless boot builds the level as levels.gd has it, untagged.
	_check(not session.run_developer_changes, "a headless boot is tagged as developer-edited")

	# A run started under a developer ban.
	overrides.set_edit(LEVEL, SAVED_BAN, overrides.EDIT_BAN, OVERRIDES_PATH)
	var level: Dictionary = main_script.run_definition(LEVEL, true, OVERRIDES_PATH)
	_check(level.get("skill_bans", []).has(SAVED_BAN), "the developer ban did not reach the run start")
	_check(session.run_developer_changes, "a run started under a developer ban is not tagged")
	var data := _save_and_read(save_game)
	_check(_tagged(data), "the save of a developer-edited run carries no developer_changes")
	_check(_saved_bans(data).has(SAVED_BAN), "the save does not record the run's ban")

	# The overrides file changes before the load.
	overrides.set_edit(LEVEL, SAVED_BAN, overrides.EDIT_NONE, OVERRIDES_PATH)
	overrides.set_edit(LEVEL, LATER_BAN, overrides.EDIT_BAN, OVERRIDES_PATH)

	# The load: the steps saves_panel.gd takes before the reload, then the
	# reloaded scene's run start.
	save_game.apply_starting_level(data)
	save_game.apply_skill_policy(data)
	level = main_script.run_definition(session.starting_level, true, OVERRIDES_PATH)
	var bans: Array = level.get("skill_bans", [])
	_check(bans.has(SAVED_BAN), "the load dropped the saved ban")
	_check(not bans.has(LATER_BAN), "the load took the overrides file's later ban")
	_check(session.run_developer_changes, "the loaded run lost its developer_changes tag")
	_check(session.pending_skill_policy.is_empty(), "the run start left the saved policy pending")

	# A re-save of the loaded run keeps the tag and the saved ban.
	data = _save_and_read(save_game)
	_check(_tagged(data), "a re-save of the loaded run dropped developer_changes")
	_check(_saved_bans(data).has(SAVED_BAN), "a re-save of the loaded run dropped the saved ban")

	# The next new run reads the overrides file again.
	level = main_script.run_definition(LEVEL, true, OVERRIDES_PATH)
	bans = level.get("skill_bans", [])
	_check(bans.has(LATER_BAN) and not bans.has(SAVED_BAN), "the next new run did not read the overrides file again")

	# A save without the field loads as before: the overrides file decides.
	var old_save := data.duplicate(true)
	old_save.erase("skill_policy")
	old_save.erase("developer_changes")
	save_game.apply_starting_level(old_save)
	save_game.apply_skill_policy(old_save)
	_check(session.pending_skill_policy.is_empty(), "a save without the field left a policy pending")
	level = main_script.run_definition(LEVEL, true, OVERRIDES_PATH)
	_check(level.get("skill_bans", []).has(LATER_BAN), "a save without the field did not read the overrides file")

	# A Challenge save keeps the current level, and its policy stays out of it.
	var challenge_save := data.duplicate(true)
	challenge_save["starting_level"] = 1
	save_game.apply_starting_level(challenge_save)
	save_game.apply_skill_policy(challenge_save)
	_check(session.starting_level == LEVEL, "a Challenge save changed the current level")
	level = main_script.run_definition(session.starting_level, true, OVERRIDES_PATH)
	bans = level.get("skill_bans", [])
	_check(bans.has(LATER_BAN) and not bans.has(SAVED_BAN), "a Challenge save's policy reached another level")
	_check(session.pending_skill_policy.is_empty(), "a mismatched policy was left pending")

	# With no developer edits a run is untagged, and so is its save.
	overrides.reset(OVERRIDES_PATH)
	level = main_script.run_definition(LEVEL, true, OVERRIDES_PATH)
	_check(not session.run_developer_changes, "a run with no developer edits is tagged")
	data = _save_and_read(save_game)
	_check(not data.has("developer_changes"), "the save of an unedited run carries developer_changes")
	_check(typeof(data.get("skill_policy")) == TYPE_DICTIONARY, "the save has no skill_policy field")


func _save_and_read(save_game: GDScript) -> Dictionary:
	if not save_game.save(_main, SAVE_PATH):
		_fail("could not write the test save")
		return {}
	return save_game.read(SAVE_PATH)


func _tagged(data: Dictionary) -> bool:
	var tag: Variant = data.get("developer_changes")
	return typeof(tag) == TYPE_BOOL and tag


func _saved_bans(data: Dictionary) -> Array:
	var policy: Variant = data.get("skill_policy")
	if typeof(policy) != TYPE_DICTIONARY:
		return []
	return policy.get("bans", [])


func _cleanup() -> void:
	_overrides.reset(OVERRIDES_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_fail(failure)


func _fail(line: String) -> void:
	_failures.append(line)


func _report() -> void:
	if _failures.is_empty():
		print("BS14 PASS")
		quit(0)
	else:
		for line: String in _failures:
			print("BS14 FAIL: " + line)
		quit(1)
