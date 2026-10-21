extends SceneTree
## T2-14 test: a comb worker's idle reason asks whether there is room to build
## without starting a site.
##
## Boots level 3 (a Scenario level: no Challenge branches) with Automation not
## owned, puts a comb worker in Build mode in BUILD_IDLE, and checks: the idle
## reason names Automation and 20 calls to idle_reason() leave hive.cells the
## same size; hive.has_room_to_build() agrees with create_next_cell_site() both
## where there is room and where there is none (comb_parent cleared).
##
## Run by tests/test_t2_14_idle_reason_pure.py:
##   godot --headless --path <repo> --script res://tests/t2_14_idle_reason_pure_test.gd
## Prints "T2_14 PASS" and exits 0, or each "T2_14 FAIL" line and exits 1.

const LEVEL := 3
const BOOT_FRAMES := 10
const AUTOMATION := "skill.hive_mind.automation"
const IDLE_CALLS := 20

var _main: Node = null
var _session: Node = null
var _frame := 0
var _phase := "boot"
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	if _phase == "boot":
		_boot()
	elif _phase == "settle" and _frame >= BOOT_FRAMES:
		_run()
		_phase = "done"
	if _phase == "done":
		if _failures.is_empty():
			print("T2_14 PASS")
			quit(0)
		else:
			for f: String in _failures:
				print("T2_14 FAIL ", f)
			quit(1)
		return true
	return false


func _boot() -> void:
	if not root.has_node("Session"):
		_failures.append("Session autoload is not loaded")
		_phase = "done"
		return
	_session = root.get_node("Session")
	_session.starting_level = LEVEL
	_session.menu_pending = false
	_main = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _run() -> void:
	var progression: Object = _session.progression
	if progression == null:
		_failures.append("the run has no progression")
		return
	var Bee: GDScript = _main.Bee
	var hive = _main.hive
	progression._mastered.erase(AUTOMATION)
	progression._temporary.erase(AUTOMATION)
	progression._behaviour_cache.clear()
	_main.Availability.invalidate()

	var builder: Node2D = _main.world_building._spawn_indoor_bee(Bee.Role.BUILDER)
	builder.architect_mode = "build"
	builder.state = Bee.State.BUILD_IDLE
	_expect(not builder._action_available("comb_build_outward"), "Automation is still available to the comb worker")

	var room: bool = hive.has_room_to_build(Vector2i.ZERO)
	_expect(room, "the test hive has no room to build")

	var cells_before: int = hive.cells.size()
	var reason := ""
	for i: int in IDLE_CALLS:
		reason = builder.idle_reason()
	_expect(hive.cells.size() == cells_before, "idle_reason() started sites: %d cells before, %d after" % [cells_before, hive.cells.size()])
	_expect("Automation" in reason, "the comb worker's idle reason does not name Automation: %s" % reason)

	var site = hive.create_next_cell_site(Vector2i.ZERO)
	_expect((site != null) == room, "has_room_to_build() said %s but create_next_cell_site() returned %s" % [room, site])

	var saved_parent = hive.comb_parent
	hive.comb_parent = null
	var no_room: bool = hive.has_room_to_build(Vector2i.ZERO)
	var no_site = hive.create_next_cell_site(Vector2i.ZERO)
	hive.comb_parent = saved_parent
	_expect(not no_room, "has_room_to_build() said there was room with no comb to build in")
	_expect(no_site == null, "create_next_cell_site() started a site with no comb to build in")


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)
