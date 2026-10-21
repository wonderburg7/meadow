extends SceneTree
## T2-13 test: a bee whose role changes while she carries a body puts it down.
##
## Boots level 3 (a Scenario level: no Challenge branches) and checks, on the
## live world: a Comb worker inside the hive who has lifted a dead bee, then
## is made a Forager, puts that bee back on the floor (one body more) and
## carries nothing dead, so 30 nectar reads as nectar; a Comb worker carrying
## a dead larva, made a Forager, drops the larva (no body is laid) and both
## flags end false.
##
## Run by tests/test_t2_13_carried_body.py:
##   godot --headless --path <repo> --script res://tests/t2_13_carried_body_test.gd
## Prints "T2-13 PASS" and exits 0, or each "T2-13 FAIL" line and exits 1.

const LEVEL := 3
const BOOT_FRAMES := 10

var _main: Node = null
var _frame := 0
var _phase := "boot"
var _failures: PackedStringArray = PackedStringArray()
var _session: Node = null
var _config: Node = null
var BeeBuilding: GDScript = null


func _process(_delta: float) -> bool:
	_frame += 1
	if _phase == "boot":
		_boot()
	elif _phase == "settle" and _frame >= BOOT_FRAMES:
		_run()
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
	_session = root.get_node("Session")
	_config = root.get_node("GameConfig")
	_session.starting_level = LEVEL
	_session.menu_pending = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _run() -> void:
	BeeBuilding = load("res://scripts/bee_building.gd")
	_lifted_bee()
	_dead_larva()


## A Comb worker lifts a dead bee out of the comb, then is made a Forager.
func _lifted_bee() -> void:
	var hive = _main.hive
	hive.clear_bodies()
	var worker: Node2D = _main.world_building._spawn_indoor_bee(_main.Bee.Role.BUILDER)
	worker.architect_mode = "maintain"
	var body: Node2D = hive.add_body(hive.nearest_walkable_point(worker.position + Vector2(40, 0)), 1.0)
	_check(body != null, "could not lay a body to lift")
	if body == null:
		return
	worker.target_body = body
	body.clear_progress = _config.cell_clean_time
	BeeBuilding._lift_body(worker, 0.0)
	_check(worker.carrying_corpse and worker.corpse_is_bee, "lifting a body did not load the Comb worker")
	_check(hive.bodies.is_empty(), "the lifted body is still on the floor")
	var before: int = hive.bodies.size()

	worker._apply_role(_main.Bee.Role.FORAGER)
	_check(not worker.carrying_corpse, "the Forager still has carrying_corpse set")
	_check(not worker.corpse_is_bee, "the Forager still has corpse_is_bee set")
	_check(hive.bodies.size() == before + 1, "the put-down body was not laid: %d bodies, expected %d" % [hive.bodies.size(), before + 1])

	worker.current_load = 30.0
	worker.current_load_type = "nectar"
	var text: String = worker.carrying_text()
	_check(text.find("nectar") >= 0, "the Forager's load does not name the nectar: '%s'" % text)
	_check(text.find("dead") < 0, "the Forager is still told she carries a dead bee: '%s'" % text)
	hive.clear_bodies()


## A Comb worker carrying a dead larva, made a Forager, drops the larva.
func _dead_larva() -> void:
	var hive = _main.hive
	hive.clear_bodies()
	var worker: Node2D = _main.world_building._spawn_indoor_bee(_main.Bee.Role.BUILDER)
	worker.carrying_corpse = true
	worker.corpse_is_bee = false
	worker._apply_role(_main.Bee.Role.FORAGER)
	_check(not worker.carrying_corpse, "a Forager still carries a dead larva")
	_check(not worker.corpse_is_bee, "a Forager still has corpse_is_bee set after a larva")
	_check(hive.bodies.is_empty(), "a dead larva was laid as a body: %d bodies" % hive.bodies.size())


func _report() -> void:
	if _failures.is_empty():
		print("T2-13 PASS")
		quit(0)
	else:
		for line in _failures:
			print("T2-13 FAIL: " + line)
		quit(1)


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_fail(failure)


func _fail(line: String) -> void:
	_failures.append(line)
