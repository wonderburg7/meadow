extends SceneTree
## COL-9 test: an unmated queen's eggs become drones.
##
## Boots the real Main.tscn into level 3 and checks, in one frame:
## - the founding queen is mated;
## - an unmated queen lays drone brood, even into a cell set to raise a
##   gyne, and the cell's label reads "drone";
## - that brood hatches through main.gd's emergence loop as an Idle drone,
##   bigger than a worker and smaller than a gyne, in his own colour, who
##   refuses every other job (set_role and set_secondary_role);
## - a save round-trips is_mated, is_drone and brood_is_drone;
## - a save without those fields loads every queen mated and nothing a drone.
##
## Run by tests/test_col9_drones.py:
##   godot --headless --path <repo> --script res://tests/col9_drones_test.gd
## Prints "COL9 PASS" and exits 0, or prints each failure and exits 1.

const LEVEL := 3          # a Scenario level with comb: no Challenge branches
const BOOT_FRAMES := 10   # let Main._ready build the world first
const SAVE_PATH := "user://col9_test_save.json"

var _main: Node = null
var _frame := 0
var _phase := "boot"
var _failures: PackedStringArray = PackedStringArray()
var _completed := false


func _process(_delta: float) -> bool:
	_frame += 1
	if _phase == "boot":
		_boot()
	elif _phase == "settle" and _frame >= BOOT_FRAMES:
		_run()
		# A script error aborts _run without failing it.
		if not _completed:
			_fail("the test did not run to the end")
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
	var game_config: Node = root.get_node("GameConfig")
	var egg_laying: GDScript = load("res://scripts/bee_egg_laying.gd")
	var bee_script: GDScript = _main.Bee
	var idle: int = bee_script.Role.IDLE
	var hive: Node2D = _main.hive
	var queen: Node2D = _main.queen
	if queen == null or not is_instance_valid(queen):
		_fail("level %d has no queen after boot" % LEVEL)
		return
	_check(queen.is_mated, "the founding queen is not mated")

	# A mated queen still lays a worker egg; then make her unmated.
	var worker_cell: Node2D = _lay(egg_laying, queen, hive)
	if worker_cell == null:
		return
	_check(not worker_cell.brood_is_drone and not worker_cell.brood_is_gyne, "a mated queen did not lay worker brood")
	queen.is_mated = false

	# An unmated queen lays drone brood, even into a cell set for a gyne.
	var hatch_cell: Node2D = hive.find_empty_cell()
	if hatch_cell == null:
		_fail("no second empty cell to lay into")
		return
	hatch_cell.hatch_gyne = true
	_check(is_equal_approx(egg_laying.pollen_needed_for_next_egg(queen), game_config.egg_pollen_cost),
		"an unmated queen waits for a gyne egg's pollen")
	if _lay(egg_laying, queen, hive, hatch_cell) == null:
		return
	_check(hatch_cell.content_type == "brood", "the unmated queen laid nothing")
	_check(hatch_cell.brood_is_drone, "an unmated queen's egg is not drone brood")
	_check(not hatch_cell.brood_is_gyne, "a drone cell is also a gyne cell")
	_check(is_equal_approx(hatch_cell.develop_time(), game_config.brood_develop_time),
		"drone brood does not develop like worker brood")
	hatch_cell._refresh()
	_check(hatch_cell.info_label.text.begins_with("drone"), "the drone brood label reads \"%s\"" % hatch_cell.info_label.text)
	hatch_cell.hatch_gyne = false

	# A second drone cell stays brood for the save.
	var kept_cell: Node2D = _lay(egg_laying, queen, hive)
	if kept_cell == null:
		return
	_check(kept_cell.brood_is_drone, "the second unmated egg is not drone brood")

	# Hatch the first through main.gd's emergence loop.
	var drone_id: int = _main.next_bee_id
	hatch_cell.hatch_role = bee_script.Role.NURSERY
	hatch_cell.brood_progress = hatch_cell.develop_time()
	_main._hatch_ready_brood()
	var drone: Node2D = _bee_with_id(drone_id)
	if drone == null:
		_fail("drone brood hatched no bee")
		return
	_check(drone.is_drone, "the bee hatched from drone brood is not a drone")
	_check(drone.role == idle, "the drone hatched as role %d, not Idle" % drone.role)
	_check(not drone.is_gyne, "the drone is also a gyne")
	_check(not hatch_cell.brood_is_drone, "the emptied cell still says drone")
	var size: float = drone._caste_size_factor()
	_check(size > 1.0 and size < game_config.gyne_size_factor, "a drone is drawn at %.2f, not between a worker and a gyne" % size)
	var worker_colour: Color = Color(1.0, 0.85, 0.1)
	_check(drone._base_colour() != worker_colour, "a drone is the worker's colour")

	# He refuses every other job, now and as a backup.
	for role in [bee_script.Role.FORAGER, bee_script.Role.NURSERY, bee_script.Role.BUILDER,
			bee_script.Role.MINER, bee_script.Role.HONEY_MAKER, bee_script.Role.EGG_LAYER]:
		_check(not drone.can_take_role(role), "a drone may take role %d" % role)
		drone.set_role(role)
		_check(drone.role == idle and drone.pending_role == -1, "set_role moved the drone to role %d" % role)
		drone.set_secondary_role(role)
		_check(drone.secondary_role == -1, "the drone took role %d as a backup" % role)

	# A save round-trips all three fields.
	var save_game: GDScript = _main.SaveGame
	if not save_game.save(_main, SAVE_PATH):
		_fail("could not write the test save")
		return
	var data: Dictionary = save_game.read(SAVE_PATH)
	_main.saving._restore(data.duplicate(true))
	var restored_queen: Node2D = _main.queen
	_check(restored_queen != null and not restored_queen.is_mated, "the restored queen is mated again")
	var restored_drone: Node2D = _bee_with_id(drone_id)
	_check(restored_drone != null and restored_drone.is_drone and restored_drone.role == idle,
		"the restored drone is not an Idle drone")
	if restored_drone != null:
		_check(is_equal_approx(restored_drone._caste_size_factor(), size), "the restored drone is drawn at a worker's size")
	_check(_drone_brood_count(hive) == 1, "the save kept %d drone brood cells, not 1" % _drone_brood_count(hive))

	# A save without the fields loads every queen mated and nothing a drone.
	var old_save: Dictionary = data.duplicate(true)
	for entry in old_save.get("bees", []):
		entry.erase("drone")
		entry.erase("mated")
	for entry in old_save.get("cells", []):
		entry.erase("drone")
	_main.saving._restore(old_save)
	_check(_main.queen != null and _main.queen.is_mated, "a save without the field loads the queen unmated")
	for b in _main.get_tree().get_nodes_in_group("bees"):
		_check(not b.is_drone, "a save without the field loads bee %d as a drone" % b.bee_id)
	_check(_drone_brood_count(hive) == 0, "a save without the field loads drone brood")
	_completed = true


## The queen lays straight into `cell` (or the next empty one) without the
## walk there: the same call her LAYING state makes when its timer runs out.
func _lay(egg_laying: GDScript, queen: Node2D, hive: Node2D, cell: Node2D = null) -> Node2D:
	if cell == null:
		cell = hive.find_empty_cell()
	if cell == null:
		_fail("no empty cell to lay into")
		return null
	queen.target_cell = cell
	queen.timer = 0.0
	egg_laying.queen_lay(queen, 0.1)
	if cell.content_type != "brood":
		_fail("queen_lay laid nothing into the cell")
		return null
	return cell


func _bee_with_id(id: int) -> Node2D:
	for b in _main.get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(b) and b.bee_id == id:
			return b
	return null


func _drone_brood_count(hive: Node2D) -> int:
	var count := 0
	for cell in _main.hive.cells:
		if is_instance_valid(cell) and cell.content_type == "brood" and cell.brood_is_drone:
			count += 1
	return count


func _cleanup() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_fail(failure)


func _fail(line: String) -> void:
	_failures.append(line)


func _report() -> void:
	if _failures.is_empty():
		print("COL9 PASS")
		quit(0)
	else:
		for line in _failures:
			print("COL9 FAIL: " + line)
		quit(1)
