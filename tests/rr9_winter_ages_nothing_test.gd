extends SceneTree
## RR-9 test: winter advances the calendar, not nectar or sealed bee bread.

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
	var cells: Array = _main.hive.cells.filter(func(cell): return cell.content_type == "")
	_check(cells.size() >= 2, "level %d has fewer than two empty cells" % LEVEL)
	if cells.size() < 2:
		return
	var nectar = cells[0]
	var bee_bread = cells[1]
	var seconds_per_day: float = config.seconds_per_day
	session.sim_time -= seconds_per_day
	nectar.add_resource("nectar", nectar.capacity_for("nectar"))
	bee_bread.add_resource("bee_bread", bee_bread.capacity_for("bee_bread"))
	session.sim_time += seconds_per_day
	var nectar_age_before: float = nectar.nectar_age()
	var bee_bread_fraction_before: float = bee_bread.bee_bread_ripen_fraction()
	var time_before: float = session.sim_time
	_main.season._resolve_winter(config.winter_length_days)

	_check(is_equal_approx(nectar.nectar_age(), nectar_age_before), "nectar aged from %f to %f" % [nectar_age_before, nectar.nectar_age()])
	_check(is_equal_approx(bee_bread.bee_bread_ripen_fraction(), bee_bread_fraction_before), "bee bread ripened from %f to %f" % [bee_bread_fraction_before, bee_bread.bee_bread_ripen_fraction()])
	_check(not nectar.is_fermented(), "nectar fermented during winter")
	_check(is_equal_approx(session.sim_time, time_before + config.winter_length_days * seconds_per_day), "sim time did not advance by winter's length")


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)


func _report() -> void:
	if _failures.is_empty():
		print("RR9 PASS")
		quit(0)
		return
	for line in _failures:
		print("RR9 FAIL: ", line)
	quit(1)
