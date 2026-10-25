extends SceneTree
## DR-1 test: a mated queen lays drones in cells marked for them.
##
## Boots the real Main.tscn into level 3 and checks, in one frame:
## - a mated queen lays a drone, at a worker egg's cost, into a cell marked
##   for a drone, and a worker into an unmarked one; the queen looks to a
##   marked cell before an unset one, and the nursery readout keys it "drone";
## - marking a gyne cell for a drone clears its gyne mark, and the reverse;
## - an unmated queen still lays a drone into a gyne-marked cell;
## - the mark survives a save and load, and a save without the key loads
##   no cell marked.
##
## Run by tests/test_dr1_drone_cells.py:
##   godot --headless --path <repo> --script res://tests/dr1_drone_cells_test.gd
## Prints "DR1 PASS" and exits 0, or prints each failure and exits 1.

const LEVEL := 3          # a Scenario level with comb: no Challenge branches
const BOOT_FRAMES := 10   # let Main._ready build the world first
const SAVE_PATH := "user://dr1_test_save.json"

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
	var hive: Node2D = _main.hive
	var orders: Node = _main.orders_zones
	var queen: Node2D = _main.queen
	if queen == null or not is_instance_valid(queen):
		_fail("level %d has no queen after boot" % LEVEL)
		return
	if not queen.is_mated:
		_fail("the founding queen is not mated")
		return
	_main.selected_cells.clear()

	# 1. A mated queen lays a drone in a marked cell, a worker in an unmarked one.
	var drone_cell: Node2D = _free_cell(hive, [])
	var worker_cell: Node2D = _free_cell(hive, [drone_cell])
	if drone_cell == null or worker_cell == null:
		_fail("level %d has fewer than two empty cells to lay into" % LEVEL)
		return
	orders._on_cell_drone_requested(drone_cell, true)
	_check(drone_cell.hatch_drone, "the drone request did not mark the cell")
	_check(drone_cell.designated_type == "brood", "a drone cell is reserved for '%s', not brood" % drone_cell.designated_type)
	_check(int(hive.zone_summary()["by_role"].get("drone", 0)) == 1, "the nursery readout does not key the drone cell \"drone\"")
	if not _other_configured_cell(hive, drone_cell):
		_check(hive.find_empty_cell() == drone_cell, "the queen does not look to the drone cell before an unset one")
	queen.pollen_eaten = game_config.gyne_egg_pollen_cost
	if _lay(egg_laying, queen, drone_cell) == null:
		return
	_check(drone_cell.brood_is_drone and not drone_cell.brood_is_gyne, "a mated queen laid no drone into the drone cell")
	_check(is_equal_approx(queen.pollen_eaten, game_config.gyne_egg_pollen_cost - game_config.egg_pollen_cost),
		"a drone egg did not cost a worker egg's pollen (%.1f left)" % queen.pollen_eaten)
	_check(drone_cell.hatch_drone, "the drone mark did not outlast the egg")
	if _lay(egg_laying, queen, worker_cell) == null:
		return
	_check(not worker_cell.brood_is_drone and not worker_cell.brood_is_gyne, "a mated queen laid no worker into an unmarked cell")

	# 2. The gyne and drone marks clear each other.
	var mark_cell: Node2D = _free_cell(hive, [])
	if mark_cell == null:
		_fail("no third empty cell to mark")
		return
	mark_cell.hatch_gyne = true
	orders._on_cell_drone_requested(mark_cell, true)
	_check(mark_cell.hatch_drone and not mark_cell.hatch_gyne, "marking a gyne cell for a drone left its gyne mark")
	if hive.find_empty_cell() == mark_cell:
		_check(is_equal_approx(egg_laying.pollen_needed_for_next_egg(queen), game_config.egg_pollen_cost),
			"a mated queen waits for a gyne egg's pollen for a drone cell")
	mark_cell.hatch_gyne = true
	_check(mark_cell.hatch_gyne and not mark_cell.hatch_drone, "marking a drone cell for a gyne left its drone mark")

	# 3. An unmated queen still lays a drone into a gyne-marked cell.
	queen.is_mated = false
	if _lay(egg_laying, queen, mark_cell) == null:
		return
	_check(mark_cell.brood_is_drone and not mark_cell.brood_is_gyne, "an unmated queen laid no drone into a gyne cell")
	queen.is_mated = true

	# 4. The mark survives a save and load.
	var drone_hex: Vector2i = drone_cell.axial
	var save_game: GDScript = _main.SaveGame
	if not save_game.save(_main, SAVE_PATH):
		_fail("could not write the test save")
		return
	var data: Dictionary = save_game.read(SAVE_PATH)
	_main.saving._restore(data.duplicate(true))
	var restored: Node2D = _cell_at(drone_hex)
	_check(restored != null and restored.hatch_drone and not restored.hatch_gyne, "the restored cell lost its drone mark")
	_check(restored != null and restored.content_type == "brood" and restored.brood_is_drone, "the restored cell lost its drone larva")
	_check(_marked_count() == 1, "the save restored %d drone-marked cells, not 1" % _marked_count())

	# A save without the key marks no cell.
	var old_save: Dictionary = data.duplicate(true)
	for entry in old_save.get("cells", []):
		entry.erase("hatch_drone")
	_main.saving._restore(old_save)
	_check(_marked_count() == 0, "a save without the key loads %d drone-marked cells" % _marked_count())
	_completed = true


## The queen lays straight into `cell` without the walk there: the same call
## her LAYING state makes when its timer runs out.
func _lay(egg_laying: GDScript, queen: Node2D, cell: Node2D) -> Node2D:
	queen.target_cell = cell
	queen.timer = 0.0
	egg_laying.queen_lay(queen, 0.1)
	if cell.content_type != "brood":
		_fail("queen_lay laid nothing into the cell at %s" % cell.axial)
		return null
	return cell


## An empty, built cell with no mark, other than those in `exclude`.
func _free_cell(hive: Node2D, exclude: Array) -> Node2D:
	for cell in hive.cells:
		if not is_instance_valid(cell) or exclude.has(cell) or not cell.is_empty():
			continue
		if cell.hatch_gyne or cell.hatch_drone or cell.hatch_role >= 0:
			continue
		return cell
	return null


## Whether any nursery cell but `except` has a role or mark set, which would
## share the queen's lays with it.
func _other_configured_cell(hive: Node2D, except: Node2D) -> bool:
	for cell in hive.cells:
		if cell == except or not is_instance_valid(cell) or not cell.is_nursery_cell():
			continue
		if cell.hatch_role >= 0 or cell.hatch_gyne or cell.hatch_drone:
			return true
	return false


func _cell_at(hex: Vector2i) -> Node2D:
	for cell in _main.hive.cells:
		if is_instance_valid(cell) and cell.axial == hex:
			return cell
	return null


func _marked_count() -> int:
	var count := 0
	for cell in _main.hive.cells:
		if is_instance_valid(cell) and cell.hatch_drone:
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
		print("DR1 PASS")
		quit(0)
	else:
		for line in _failures:
			print("DR1 FAIL: " + line)
		quit(1)
