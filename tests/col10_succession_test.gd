extends SceneTree
## COL-10 test: a gyne takes over from a dead queen.
##
## Boots the real Main.tscn into level 3, raises three adult gynes -- the
## oldest leaving to found a colony, then an older and a younger one -- and
## kills the queen. Checks that:
## - the older staying gyne becomes the queen: is_queen set, is_gyne
##   cleared, unmated, on Egg layer, main.queen pointing at her, her
##   readout saying "Unmated: lays drones";
## - the run is not lost and the game-over panel never shows;
## - the succession window opened once and stays at one;
## - she lays drone brood;
## then, with no gyne left, kills her and checks the run ends as before:
## colony_lost set and the game-over panel up.
##
## Run by tests/test_col10_succession.py:
##   godot --headless --path <repo> --script res://tests/col10_succession_test.gd
## Prints "COL10 PASS" and exits 0, or prints each failure and exits 1.

const LEVEL := 3            # a Scenario level with comb: no Challenge branches
const BOOT_FRAMES := 10     # let Main._ready build the world first
const WAIT_FRAMES := 60     # frames allowed for a death to be noticed
const SETTLE_FRAMES := 30   # frames watched after the takeover

var _main: Node = null
var _frame := 0
var _phase := "boot"
var _phase_frame := 0
var _old_queen: Node2D = null
var _heir: Node2D = null
var _younger: Node2D = null
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				_kill_queen_with_gynes()
		"first_death":
			_watch_takeover()
		"after_takeover":
			_watch_settled()
		"second_death":
			_watch_loss()
	if _phase == "done":
		_report()
		return true
	return false


# Autoloads are reached through the tree: a --script run compiles this file
# before they exist.
func _boot() -> void:
	if not root.has_node("Session"):
		_fail("Session autoload is not loaded")
		return
	var session: Node = root.get_node("Session")
	session.starting_level = LEVEL
	session.menu_pending = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _kill_queen_with_gynes() -> void:
	_old_queen = _main.queen
	if _old_queen == null or not is_instance_valid(_old_queen):
		_fail("level %d has no queen after boot" % LEVEL)
		return
	# Only the gynes raised here count.
	for b in _main.get_tree().get_nodes_in_group("bees"):
		b.is_gyne = false
	var leaving: Node2D = _spawn_gyne(3.0)
	_heir = _spawn_gyne(2.0)
	_younger = _spawn_gyne(1.0)
	if leaving == null or _heir == null or _younger == null:
		return
	# The oldest flies off this frame: still a valid node until it ends.
	leaving.leave_to_found_colony()
	load("res://scripts/bee_survival.gd").die(_old_queen, "debug")
	_phase = "first_death"
	_phase_frame = _frame


func _spawn_gyne(age_days: float) -> Node2D:
	var cell: Node2D = _main.hive.find_empty_cell()
	if cell == null:
		_fail("no empty cell to hatch a gyne at")
		return null
	var gyne: Node2D = _main.world_building._spawn_hatched_bee(_main.Bee.Role.NURSERY, cell, true, "feed")
	gyne.age_seconds = age_days * float(root.get_node("GameConfig").seconds_per_day)
	return gyne


func _watch_takeover() -> void:
	if bool(_main.colony_lost):
		_fail("the run was lost although a gyne was alive")
		return
	# Asked before a typed assignment: a freed queen cannot be assigned to one.
	if not is_instance_valid(_main.queen) or _main.queen == _old_queen:
		if _frame - _phase_frame > WAIT_FRAMES:
			_fail("%d frames after the queen died no gyne had taken over" % WAIT_FRAMES)
		return
	var current: Node2D = _main.queen
	_check(current == _heir, "the queen is bee %d, not the oldest staying gyne" % current.bee_id)
	_check(current.is_queen, "the new queen's is_queen is not set")
	_check(not current.is_gyne, "the new queen is still a gyne")
	_check(not current.is_mated, "the new queen is mated")
	_check(current.role == _main.Bee.Role.EGG_LAYER, "the new queen is role %d, not Egg layer" % current.role)
	_check(current.role_name_text().contains("Unmated: lays drones"),
		"the new queen's readout is \"%s\"" % current.role_name_text())
	_check(is_instance_valid(_younger) and _younger.is_gyne and not _younger.is_queen,
		"the younger gyne did not stay a gyne")
	_check(not _main.game_over.visible, "the game-over panel opened")
	_check(_main.succession_panel.is_open(), "the succession window is not open")
	_check(_main.succession_panel.takeovers_shown == 1,
		"the succession window opened %d times" % _main.succession_panel.takeovers_shown)
	_check_lays_drones(current)
	_phase = "after_takeover"
	_phase_frame = _frame


## She lays straight into an empty cell, the call her LAYING state makes.
func _check_lays_drones(current: Node2D) -> void:
	var cell: Node2D = _main.hive.find_empty_cell()
	if cell == null:
		_fail("no empty cell for the new queen to lay into")
		return
	current.target_cell = cell
	current.timer = 0.0
	load("res://scripts/bee_egg_laying.gd").queen_lay(current, 0.1)
	_check(cell.content_type == "brood", "the new queen laid nothing")
	_check(cell.brood_is_drone, "the new queen's egg is not drone brood")


func _watch_settled() -> void:
	if _frame - _phase_frame < SETTLE_FRAMES:
		return
	_check(not bool(_main.colony_lost), "the run was lost after the takeover")
	_check(not _main.game_over.visible, "the game-over panel opened after the takeover")
	_check(_main.succession_panel.takeovers_shown == 1,
		"the succession window reopened (%d times)" % _main.succession_panel.takeovers_shown)
	if not _failures.is_empty():
		_phase = "done"
		return
	# No gyne left: her death ends the run as before.
	_younger.is_gyne = false
	_old_queen = _main.queen
	load("res://scripts/bee_survival.gd").die(_old_queen, "debug")
	_phase = "second_death"
	_phase_frame = _frame


func _watch_loss() -> void:
	if bool(_main.colony_lost) and _main.game_over.visible:
		_check(_main.succession_panel.takeovers_shown == 1,
			"the succession window opened with no gyne to promote")
		_phase = "done"
		return
	if _frame - _phase_frame > WAIT_FRAMES:
		_fail("%d frames after the gyneless queen died: colony_lost %s, game over visible %s" % [
			WAIT_FRAMES, _main.colony_lost, _main.game_over.visible,
		])


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)


func _fail(line: String) -> void:
	_failures.append(line)
	_phase = "done"


func _report() -> void:
	if _failures.is_empty():
		print("COL10 PASS")
		quit(0)
	else:
		for line in _failures:
			print("COL10 FAIL: " + line)
		quit(1)
