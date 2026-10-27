extends SceneTree
## RR-11 test: nectar between the pre-ferment fraction and the fermenting time
## shows the warning colour but is still ordinary, usable nectar.

const LEVEL := 3
const BOOT_FRAMES := 10

var _main: Node = null
var _frame := 0
var _done := false
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	if _done:
		return false
	if _frame == 1:
		var session: Node = root.get_node("Session")
		session.starting_level = LEVEL
		session.menu_pending = false
		var scene: PackedScene = load("res://scenes/Main.tscn")
		_main = scene.instantiate()
		root.add_child(_main)
		current_scene = _main
	elif _frame >= BOOT_FRAMES:
		_run()
		_done = true
		_report()
	return false


func _run() -> void:
	var session: Node = root.get_node("Session")
	var config: Node = root.get_node("GameConfig")
	var cells: Array = _main.hive.cells.filter(func(cell: Polygon2D) -> bool: return cell.content_type == "")
	_check(not cells.is_empty(), "level %d has no empty cell" % LEVEL)
	if cells.is_empty():
		return
	var cell: Variant = cells[0]
	var hour: float = config.seconds_per_day / 24.0
	var span: float = config.nectar_ferment_hours * hour
	cell.add_resource("nectar", 5.0)
	var stamp: float = session.sim_time
	session.use_cell_sprites = false
	var expected: Array = [[0.6, false, false], [0.65, true, false], [1.1, false, true]]
	for row: Array in expected:
		session.sim_time = stamp + span * float(row[0])
		_check(cell.is_pre_fermented() == row[1], "at %.1f pre_fermented was %s" % [row[0], cell.is_pre_fermented()])
		_check(cell.is_fermented() == row[2], "at %.1f fermented was %s" % [row[0], cell.is_fermented()])
	session.sim_time = stamp + span * 0.8
	cell._refresh()
	_check(cell.fill_shape.color.is_equal_approx(cell.PRE_FERMENTED_NECTAR_COLOR), "flat colour at 0.8 was %s" % cell.fill_shape.color)
	_check(_main.hive.find_honey_source(cell.global_position) == cell, "find_honey_source skipped the pre-fermented cell")
	var taken: float = _main.hive.take("nectar", 1.0)
	_check(is_equal_approx(taken, 1.0), "take(nectar, 1.0) took %f" % taken)


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)


func _report() -> void:
	if _failures.is_empty():
		print("RR11 PASS")
		quit(0)
		return
	for line: String in _failures:
		print("RR11 FAIL: ", line)
	quit(1)
