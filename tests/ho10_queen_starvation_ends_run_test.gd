extends SceneTree
## HO-10 test: a queen who starves ends the run with "The queen is dead".
##
## Boots the real Main.tscn into Scenario 1 (the queen alone, no comb and
## no stores -- level 7), drains her energy to almost nothing so the
## ordinary starvation check in bee_survival.gd kills her within a few
## frames, then checks that main.gd marks the colony lost and that the
## game-over panel is up with its "The queen is dead" title showing.
##
## Run by tests/test_ho10_queen_starvation_ends_run.py:
##   godot --headless --path <repo> --script res://tests/ho10_queen_starvation_ends_run_test.gd
## Prints "HO10 PASS" and exits 0, or prints each failure and exits 1.

const SCENARIO_ONE_LEVEL := 7   # main_menu.gd: "Scenario 1 Queen alone"
const BOOT_FRAMES := 10         # let Main._ready build the world first
const STARVE_FRAME_LIMIT := 600 # a queen on 0.01 energy dies in a frame or two
const LOSS_FRAME_LIMIT := 60    # frames allowed after her death for the panel

var _main: Node = null
var _queen: Node = null
var _frame := 0
var _phase := "boot"
var _death_frame := -1
var _mode := "starve"   # starve | kill_paused (HO-14) | restore_queenless | restore_queen (HO-13)
var _restore_frame := -1
var _failures: PackedStringArray = PackedStringArray()
var _log: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				if _mode == "starve":
					_starve_queen()
				elif _mode == "kill_paused":
					_kill_queen_paused()
				else:
					_restore_save()
		"restored":
			_watch_restore()
		"starving":
			_watch_starvation()
		"dead":
			_watch_loss()
	if _phase == "done":
		_report()
		return true
	return false


# Autoloads (Session, GameConfig) are in the tree by the first frame, not
# during _initialize; they are reached through the tree rather than by
# name because a --script run compiles this file before they exist.
func _boot() -> void:
	if not root.has_node("Session"):
		_fail("Session autoload is not loaded")
		return
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_mode = args[0]
	var session: Node = root.get_node("Session")
	session.starting_level = SCENARIO_ONE_LEVEL
	session.menu_pending = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _starve_queen() -> void:
	_queen = _main.get("queen")
	if _queen == null or not is_instance_valid(_queen):
		_fail("Scenario 1 has no queen after boot")
		return
	if bool(_queen.get("energy_immune")):
		_fail("the Scenario 1 queen is energy-immune, so she cannot starve")
		return
	_log.append("queen %s, energy %.2f, paused %s" % [_queen.get("bee_name"), float(_queen.get("energy")), paused])
	_queen.set("energy", 0.01)
	_phase = "starving"


# HO-14: the developer "End the run" trigger kills the queen while the
# settings window has the run paused. The panel must open without an
# unpause.
func _kill_queen_paused() -> void:
	_queen = _main.get("queen")
	if _queen == null or not is_instance_valid(_queen):
		_fail("Scenario 1 has no queen after boot")
		return
	paused = true
	load("res://scripts/bee_survival.gd").die(_queen, "debug")
	_death_frame = _frame
	_phase = "dead"


# HO-13: saves the live colony, optionally strips the queen from the file,
# then restores it on a scene that has not yet seen a queen (as on a fresh
# boot), and watches whether the run ends.
func _restore_save() -> void:
	var path := "user://ho13_test_save.json"
	if not _main.SaveGame.save(_main, path):
		_fail("could not write the test save")
		return
	var data: Dictionary = _main.SaveGame.read(path)
	if _mode == "restore_queenless":
		var kept: Array = []
		for entry in data.get("bees", []):
			if not bool(entry.get("queen", false)):
				kept.append(entry)
		data["bees"] = kept
	_main.set("queen_seen_alive", false)
	_main.saving._restore(data)
	_restore_frame = _frame
	_phase = "restored"


func _watch_restore() -> void:
	var lost := bool(_main.get("colony_lost"))
	var game_over: Node = _main.get("game_over")
	if _mode == "restore_queenless":
		if lost and game_over != null and game_over.visible:
			if _find_label(game_over, "The queen is dead") == null:
				_fail("the game-over panel has no \"The queen is dead\" label")
			elif _failures.is_empty():
				_phase = "done"
		elif _frame - _restore_frame > LOSS_FRAME_LIMIT:
			_fail("queenless save restored but the run did not end (colony_lost %s)" % lost)
	else:
		if lost:
			_fail("a save with a queen ended the run after restore")
		elif _frame - _restore_frame > LOSS_FRAME_LIMIT:
			_phase = "done"


func _watch_starvation() -> void:
	if not is_instance_valid(_queen) or bool(_queen.get("is_dying")):
		if is_instance_valid(_queen):
			_log.append("queen dying of %s" % _queen.get("death_cause"))
		_death_frame = _frame
		_phase = "dead"
		return
	if _frame - BOOT_FRAMES > STARVE_FRAME_LIMIT:
		_fail("the queen did not starve within %d frames (energy %.3f, paused %s)" % [
			STARVE_FRAME_LIMIT, float(_queen.get("energy")), paused,
		])


func _watch_loss() -> void:
	var game_over: Node = _main.get("game_over")
	if bool(_main.get("colony_lost")) and game_over != null and game_over.visible:
		_check_panel(game_over)
		return
	if _frame - _death_frame > LOSS_FRAME_LIMIT:
		_fail("%d frames after the queen died: colony_lost %s, game over visible %s, queen still valid %s, main.queen valid %s, main.queen == null %s, paused %s" % [
			LOSS_FRAME_LIMIT,
			_main.get("colony_lost"),
			game_over != null and game_over.visible,
			is_instance_valid(_queen),
			is_instance_valid(_main.get("queen")),
			_main.get("queen") == null,
			paused,
		])


func _check_panel(game_over: Node) -> void:
	var title: Label = _find_label(game_over, "The queen is dead")
	if title == null:
		_fail("the game-over panel has no \"The queen is dead\" label")
	elif not title.is_visible_in_tree():
		_fail("\"The queen is dead\" is not visible")
	if not paused:
		_fail("the run is still running behind the game-over panel")
	if _failures.is_empty():
		_phase = "done"


func _find_label(node: Node, text: String) -> Label:
	if node is Label and (node as Label).text == text:
		return node
	for child in node.get_children():
		var found: Label = _find_label(child, text)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	_failures.append(message)
	_phase = "done"


func _report() -> void:
	for line in _log:
		print("HO10 note: " + line)
	if _failures.is_empty():
		print("HO10 PASS")
		quit(0)
	else:
		for line in _failures:
			print("HO10 FAIL: " + line)
		quit(1)
