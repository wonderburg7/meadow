extends SceneTree
## SP-6 test: an outdoor worker is drawn from the meadow forager sheet.
## Heading picks the row (eight octants), the shared wing clock picks the
## frame, and the body circles are hidden outdoors and back indoors.
##
## Run by tests/test_sp6_forager_sprite.py:
##   godot --headless --path <repo> --script res://tests/sp6_forager_sprite_test.gd
## Prints "SP6 PASS" and exits 0, or prints each failure and exits 1.

const SpriteCatalogue = preload("res://scripts/sprite_catalogue.gd")
const FAKE_WORLD := "extends Node2D\nvar hive_root: Node2D\nvar pollination = null\nfunc is_on_screen(_b) -> bool:\n\treturn true\nfunc invalidate_population() -> void:\n\tpass\n"
const OCTANTS: Array[String] = ["right", "down_right", "down", "down_left", "left", "up_left", "up", "up_right"]

var _failures: PackedStringArray = PackedStringArray()
var _ran := false
var _bee_script: GDScript
var _session: Node


func _process(_delta: float) -> bool:
	if _ran:
		return true
	_ran = true
	_session = root.get_node("Session")
	_bee_script = load("res://scripts/bee.gd")
	_run()
	if _failures.is_empty():
		print("SP6 PASS")
		quit(0)
	else:
		for line in _failures:
			print("SP6 FAIL: " + line)
		quit(1)
	return true


func _make_bee(world: Node2D = null) -> Node2D:
	var bee: Node2D = _bee_script.new()
	bee.role = _bee_script.Role.FORAGER
	bee.process_mode = Node.PROCESS_MODE_DISABLED
	bee.world = world
	root.add_child(bee)
	return bee


func _row_of(frame: int) -> int:
	return frame / SpriteCatalogue.FORAGERS_MEADOW_VIEW_HFRAMES


func _run() -> void:
	var fake_script := GDScript.new()
	fake_script.source_code = FAKE_WORLD
	fake_script.reload()
	var world: Node2D = fake_script.new()
	world.hive_root = Node2D.new()
	root.add_child(world)
	root.add_child(world.hive_root)

	var bee: Node2D = _make_bee(world)
	root.remove_child(bee)
	world.add_child(bee)   # in the meadow: parent is not hive_root
	if bee.meadow_sprite == null:
		_failures.append("the bee has no meadow sprite")
		return

	# Rows: each octant shows the row named for that direction.
	bee.wander_phase = 0.0
	for k: int in range(8):
		bee.heading = Vector2.RIGHT.rotated(k * PI / 4.0 + 0.1)   # inside the octant
		bee._update_meadow_sprite()
		var want: int = SpriteCatalogue.FORAGERS_MEADOW_VIEW_FRAMES.find(OCTANTS[k] + ".0") / 6
		var got: int = _row_of(bee.meadow_sprite.frame)
		if got != want:
			_failures.append("octant %d (%s): row %d, expected %d" % [k, OCTANTS[k], got, want])
	if not bee.meadow_sprite.visible:
		_failures.append("the sprite is hidden outdoors")
	if bee.body.visible or bee.outline_disc.visible:
		_failures.append("body circles still show outdoors")
	if not bee.centre_dot.visible:
		_failures.append("the load dot is hidden outdoors")

	# Wing clock: the column advances with sim_time and is offset by wander_phase.
	bee.heading = Vector2.RIGHT
	_session.sim_time = 10.0
	bee._update_meadow_sprite()
	var first: int = bee.meadow_sprite.frame % 6
	_session.sim_time = 10.0 + 1.0 / bee.WING_FRAMES_PER_SECOND
	bee._update_meadow_sprite()
	var second: int = bee.meadow_sprite.frame % 6
	if second != (first + 1) % 6:
		_failures.append("wing column went %d -> %d, expected the next frame" % [first, second])
	var seen := {}
	for i: int in range(12):
		_session.sim_time = 20.0 + i / bee.WING_FRAMES_PER_SECOND
		bee._update_meadow_sprite()
		seen[bee.meadow_sprite.frame % 6] = true
	if seen.size() != 6:
		_failures.append("the wing clock showed %d of 6 frames" % seen.size())
	_session.sim_time = 30.0
	bee.wander_phase = 0.0
	bee._update_meadow_sprite()
	var base: int = bee.meadow_sprite.frame % 6
	bee.wander_phase = TAU / 6.0 * 2.0 + 0.01
	bee._update_meadow_sprite()
	if bee.meadow_sprite.frame % 6 != (base + 2) % 6:
		_failures.append("wander_phase did not offset the wing clock")

	# Indoors the circles return and the sprite goes.
	world.remove_child(bee)
	world.hive_root.add_child(bee)
	bee._update_meadow_sprite()
	if bee.meadow_sprite.visible:
		_failures.append("the sprite still shows indoors")
	if not bee.body.visible or not bee.outline_disc.visible:
		_failures.append("body circles are not back indoors")

	# And outdoors again.
	world.hive_root.remove_child(bee)
	world.add_child(bee)
	bee._update_meadow_sprite()
	if not bee.meadow_sprite.visible or bee.body.visible:
		_failures.append("going back outdoors did not restore the sprite")

	# A drone keeps its circles outdoors.
	var drone: Node2D = _make_bee(world)
	root.remove_child(drone)
	world.add_child(drone)
	drone.become_drone()
	drone._update_meadow_sprite()
	if drone.meadow_sprite.visible or not drone.body.visible:
		_failures.append("a drone is drawn from the forager sheet")

	_profile(world)


## Cost of the new display step per bee, printed for the plan's record.
func _profile(world: Node2D) -> void:
	var bees: Array = []
	for i: int in range(300):
		var b: Node2D = _make_bee(world)
		root.remove_child(b)
		world.add_child(b)
		b.heading = Vector2.RIGHT.rotated(i * 0.37)
		bees.append(b)
	var rounds := 200
	var t0 := Time.get_ticks_usec()
	for r: int in range(rounds):
		_session.sim_time = r * 0.016
		for b: Node2D in bees:
			b._update_heading_marker()
			b._update_search_ring()
	var before := Time.get_ticks_usec() - t0
	t0 = Time.get_ticks_usec()
	for r: int in range(rounds):
		_session.sim_time = r * 0.016
		for b: Node2D in bees:
			b._update_heading_marker()
			b._update_search_ring()
			b._update_meadow_sprite()
	var after := Time.get_ticks_usec() - t0
	print("SP6 PROFILE: display step per bee per frame, 300 bees x %d frames: without sprite %.3f us, with sprite %.3f us" % [
		rounds, float(before) / (300.0 * rounds), float(after) / (300.0 * rounds)])
