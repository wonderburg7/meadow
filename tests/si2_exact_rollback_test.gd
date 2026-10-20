extends SceneTree
## SI-2 test: an in-place checkpoint restore puts back soil dug since the
## checkpoint (Challenge 2's rollback keeps every block dug otherwise).
##
## Boots level 3, writes a TutorialCheckpoint, mines one soil block beside
## open floor, restores, and checks the soil count and the mined hex.
##
## Run by tests/test_si2_exact_rollback.py:
##   godot --headless --path <repo> --script res://tests/si2_exact_rollback_test.gd
## Prints "SI2 PASS" and exits 0, or prints each failure and exits 1.

const LEVEL := 3                    # a Scenario level: no Challenge branches
const BOOT_FRAMES := 10             # let Main._ready build the world first

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
	var hive: Polygon2D = _main.hive
	var before := _soil_count(hive)
	_check(before > 0, "the level has no soil blocks")
	var target: Node2D = null
	for node: Variant in hive.occupied_tiles.values():
		if node == null or not is_instance_valid(node) or not node.is_in_group("soil_blocks"):
			continue
		for step: Variant in hive.NEIGHBOUR_STEPS:
			if hive.tile_is_walkable(node.axial + step):
				target = node
				break
		if target != null:
			break
	if target == null:
		_fail("no soil block sits next to open floor")
		return
	var hex: Vector2i = target.axial
	_check(_main.TutorialCheckpoint.save(_main), "the checkpoint did not save")
	_main.world_building.finish_mining(target)
	_check(_soil_count(hive) == before - 1, "mining did not remove exactly one block")
	_check(_main.TutorialCheckpoint.restore(_main), "the checkpoint did not restore")
	_check(_soil_count(hive) == before, "the restore left %d soil blocks, expected %d" % [_soil_count(hive), before])
	var node: Variant = hive.occupied_tiles.get(hex)
	_check(node != null and is_instance_valid(node) and node.is_in_group("soil_blocks"), "the mined hex holds no soil block after the restore")
	_main.TutorialCheckpoint.clear()


func _soil_count(hive: Polygon2D) -> int:
	var n := 0
	for node: Variant in hive.occupied_tiles.values():
		if node != null and is_instance_valid(node) and node.is_in_group("soil_blocks"):
			n += 1
	return n


func _cleanup() -> void:
	_main.TutorialCheckpoint.clear()


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_fail(failure)


func _fail(line: String) -> void:
	_failures.append(line)


func _report() -> void:
	if _failures.is_empty():
		print("SI2 PASS")
		quit(0)
	else:
		for line: String in _failures:
			print("SI2 FAIL: " + line)
		quit(1)
