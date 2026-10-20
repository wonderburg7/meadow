extends SceneTree
## T2-10 test: a miner on Dig on its own starts as soon as Automation is
## bought, and an idle miner or comb worker says it needs Automation.
## Run by tests/test_t2_10_automine_wake.py:
##   godot --headless --path <repo> --script res://tests/t2_10_automine_wake_test.gd
## Prints "T2_10 PASS" and exits 0, or each "T2_10 FAIL" line and exits 1.

const LEVEL := 3
const BOOT_FRAMES := 10
const AUTOMATION := "skill.hive_mind.automation"

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
			print("T2_10 PASS")
			quit(0)
		else:
			for f: String in _failures:
				print("T2_10 FAIL ", f)
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
	var roles: GDScript = load("res://scripts/roles.gd")
	var Bee: GDScript = _main.Bee
	var hive: Polygon2D = _main.hive
	for r: int in [Bee.Role.MINER, Bee.Role.BUILDER]:
		var skill: String = roles.skill_for(r)
		if skill != "":
			progression.grant_temporary(skill)
	progression._mastered.erase(AUTOMATION)
	progression._temporary.erase(AUTOMATION)
	progression._behaviour_cache.clear()
	_main.Availability.invalidate()

	var miner: Node2D = _main.world_building._spawn_indoor_bee(Bee.Role.MINER)
	miner.automine = true
	miner.mine_queue.clear()
	miner.state = Bee.State.MINE_IDLE
	_expect(not miner._try_role_work(Bee.Role.MINER), "the miner found work without Automation")
	_expect("Automation" in miner.idle_reason(), "the miner's idle reason does not name Automation: %s" % miner.idle_reason())

	var epoch: int = hive.mining_work_epoch
	progression.grant_temporary(AUTOMATION)
	progression._behaviour_cache.clear()
	_main.Availability.invalidate()
	_expect(hive.mining_work_epoch == epoch, "buying Automation moved the mining epoch")
	_expect(miner._try_role_work(Bee.Role.MINER), "the miner stayed idle after Automation was granted")

	progression._temporary.erase(AUTOMATION)
	progression._mastered.erase(AUTOMATION)
	progression._behaviour_cache.clear()
	_main.Availability.invalidate()
	var builder: Node2D = _main.world_building._spawn_indoor_bee(Bee.Role.BUILDER)
	builder.architect_mode = "build"
	builder.state = Bee.State.BUILD_IDLE
	if hive.create_next_cell_site(Vector2i.ZERO) == null:
		_failures.append("the test hive has no room to build")
	else:
		_expect("Automation" in builder.idle_reason(), "the comb worker's idle reason does not name Automation: %s" % builder.idle_reason())


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)
