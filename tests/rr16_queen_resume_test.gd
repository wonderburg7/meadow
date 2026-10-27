extends SceneTree
## RR-16 test: the queen resumes a part-built site, a finished cell gives
## null, and an empty tile still makes a site.

const Shapes = preload("res://scripts/shapes.gd")
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
	var hive: Variant = _main.hive
	var queen: Variant = _main.queen
	var orders: Variant = _main.orders_zones
	_check(is_instance_valid(queen), "no queen on level %d" % LEVEL)
	if not is_instance_valid(queen):
		return
	var hex: Variant = _free_hex(hive)
	_check(hex != null, "no buildable tile found")
	if hex == null:
		return
	# An empty tile still makes a site, as before.
	var made: Variant = orders.queen_build_at(hex)
	_check(made != null, "an empty tile made no site")
	if made == null:
		return
	_check(made.get("is_built") == false, "the new site is not unbuilt")
	_check(hive.site_at_tile(hex) == made, "site_at_tile did not find the new site")
	# A part-built site is resumed: returned, targeted and the state set.
	queen.target_cell = null
	queen.state = _main.Bee.State.TO_FOOD_CELL
	var resumed: Variant = orders.queen_build_at(hex)
	_check(resumed == made, "a part-built site was not returned")
	_check(queen.target_cell == made, "the queen's target is not the part-built site")
	_check(queen.state == _main.Bee.State.TO_BUILD_SITE, "queen state was %s" % queen.state)
	# A finished cell gives null.
	made.is_built = true
	_check(orders.queen_build_at(hex) == null, "a finished cell did not return null")


## The first tile around the comb centre the hive would accept for a cell.
func _free_hex(hive: Variant) -> Variant:
	for index: int in range(1, 400):
		var hex: Vector2i = Shapes.hex_spiral_at(index)
		if hive.can_build_on(hex):
			return hex
	return null


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)


func _report() -> void:
	if _failures.is_empty():
		print("RR16 PASS")
		quit(0)
		return
	for line: String in _failures:
		print("RR16 FAIL: ", line)
	quit(1)
