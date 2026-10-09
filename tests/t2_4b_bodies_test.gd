extends SceneTree
## T2-4b test: bees that die in the hive leave bodies.
##
## Boots level 3 (a Scenario level: no Challenge branches) and checks, on the
## live world: an in-hive death leaves one body and a meadow death none;
## bodies raise disease as dead larvae do; a Comb worker with Cleaning
## carries one out through the waste exit and one without leaves it, with
## dead larvae still first; the cap drops the oldest; and bodies survive a
## save and load, an in-place checkpoint restore leaves the saved count,
## and an old save loads with none. Last, a winter the stores cannot pay
## leaves a body for every bee it takes, inside and out.
##
## Run by tests/test_t2_4b_bodies.py:
##   godot --headless --path <repo> --script res://tests/t2_4b_bodies_test.gd
## Prints "T2-4B PASS" and exits 0, or each "T2-4B FAIL" line and exits 1.

const LEVEL := 3
const BOOT_FRAMES := 10
const CLEANING := "skill.hive_mind.cleaning"
const SAVE_PATH := "user://t2_4b_bodies_test_save.json"
const STEP := 0.1            # seconds per driven step of the Comb worker
const MAX_STEPS := 6000

var _main: Node = null
var _frame := 0
var _phase := "boot"
var _failures: PackedStringArray = PackedStringArray()
var _config: Node = null
var _session: Node = null
var BeeSurvival: GDScript = null
var BeeBuilding: GDScript = null


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
	BeeSurvival = load("res://scripts/bee_survival.gd")
	BeeBuilding = load("res://scripts/bee_building.gd")
	var hive = _main.hive
	hive.clear_bodies()
	_deaths(hive)
	_disease(hive)
	_cleaning(hive)
	_cap(hive)
	_saving(hive)
	_winter(hive)   # last: it takes every bee, the queen too


# --- where a bee dies ---------------------------------------------
func _deaths(hive) -> void:
	var inside: Node2D = _main.world_building._spawn_indoor_bee(_main.Bee.Role.FORAGER)
	var fell_at: Vector2 = inside.position
	BeeSurvival.die(inside, "test")
	_check(hive.bodies.size() == 1, "an in-hive death left %d bodies, expected 1" % hive.bodies.size())
	if hive.bodies.size() == 1:
		var body: Node2D = hive.bodies[0]
		_check(body.position == fell_at, "the body lies at %s, not where she fell (%s)" % [body.position, fell_at])
		_check(body.get_parent() == _main.hive_root, "the body is not in the hive view")
	_main.world_building._spawn_bee("nectar")
	var outside: Node2D = _last_bee()
	_check(outside != null and not outside._is_inside_hive(), "the meadow bee is not in the meadow")
	if outside != null:
		BeeSurvival.die(outside, "test")
	_check(hive.bodies.size() == 1, "a meadow death changed the body count to %d" % hive.bodies.size())
	hive.clear_bodies()


# --- disease ------------------------------------------------------
func _disease(hive) -> void:
	var season = _main.season
	var old_on: bool = _config.disease_on
	_config.disease_on = true
	var base: float = _disease_rise(season)
	hive.add_body(hive.nearest_walkable_point(_main.hive_entrance_inside()), 0.0)
	var with_body: float = _disease_rise(season)
	hive.clear_bodies()
	var cell: Node2D = _empty_built_cell(hive)
	_check(cell != null, "no empty built cell to kill a larva in")
	if cell != null:
		cell._larva_dies()
		hive.invalidate_index()
		var with_larva: float = _disease_rise(season)
		cell.clear_cell()
		hive.invalidate_index()
		_check(absf((with_body - base) - _config.disease_per_corpse) < 0.000001,
			"one body raised disease by %f, not disease_per_corpse (%f)" % [with_body - base, _config.disease_per_corpse])
		_check(absf((with_body - base) - (with_larva - base)) < 0.000001,
			"a body (%f) and a dead larva (%f) raise disease differently" % [with_body - base, with_larva - base])
	_config.disease_on = old_on


## One second of the disease tick from a fixed mid-scale start, so the
## clamp at zero cannot hide a difference.
func _disease_rise(season) -> float:
	season.disease = 0.5
	season._advance_disease(1.0)
	var out: float = season.disease
	season.disease = 0.0
	return out


# --- Clearing carries bodies out ----------------------------------
func _cleaning(hive) -> void:
	var progression = _session.progression
	_check(progression != null, "the run has no progression")
	if progression == null:
		return
	var had_mastered: bool = progression._mastered.has(CLEANING)
	var had_temporary: bool = progression._temporary.has(CLEANING)
	progression._mastered.erase(CLEANING)
	progression._temporary.erase(CLEANING)
	# The Comb worker role itself is owned in both halves, so only Cleaning
	# differs between them.
	var comb_skill: String = load("res://scripts/roles.gd").skill_for(_main.Bee.Role.BUILDER)
	var had_comb: bool = comb_skill == "" or progression._temporary.has(comb_skill)
	if comb_skill != "":
		progression.grant_temporary(comb_skill)
	progression._behaviour_cache.clear()
	_main.Availability.invalidate()

	var worker: Node2D = _main.world_building._spawn_indoor_bee(_main.Bee.Role.BUILDER)
	worker.architect_mode = "maintain"
	worker.state = _main.Bee.State.BUILD_IDLE
	var body: Node2D = hive.add_body(hive.nearest_walkable_point(worker.position + Vector2(40, 0)), 1.0)

	_check(not worker._try_role_work(_main.Bee.Role.BUILDER) or worker.target_body == null,
		"a Comb worker without Cleaning went for the body")
	_check(hive.bodies.size() == 1, "without Cleaning the body did not stay")

	progression.grant_temporary(CLEANING)
	_main.Availability.invalidate()

	# A dead larva comes before a body.
	var cell: Node2D = _empty_built_cell(hive)
	if cell != null:
		cell._larva_dies()
		hive.invalidate_index()
		worker.state = _main.Bee.State.BUILD_IDLE
		worker.target_cell = null
		_check(worker._try_role_work(_main.Bee.Role.BUILDER), "with Cleaning a Comb worker found no work")
		_check(worker.target_cell == cell and worker.target_body == null, "a body was picked over a dead larva")
		BeeBuilding.architect_go_to_clean(worker, 0.0)
		worker.target_cell = null
		cell.clear_cell()
		hive.invalidate_index()

	worker.state = _main.Bee.State.BUILD_IDLE
	_check(worker._try_role_work(_main.Bee.Role.BUILDER), "with Cleaning a Comb worker found no body to clear")
	_check(worker.target_body == body, "the Comb worker did not take the body")
	_check(body.is_claimed(), "the body is not claimed by the Comb worker")
	var saw_outside_with_body := false
	var steps := 0
	while steps < MAX_STEPS:
		steps += 1
		var state: int = worker.state
		if state == _main.Bee.State.TO_CLEAN_CELL:
			BeeBuilding.architect_go_to_clean(worker, STEP)
		elif state == _main.Bee.State.CLEANING:
			BeeBuilding.architect_clean(worker, STEP)
		elif state == _main.Bee.State.TO_WASTE_EXIT:
			BeeBuilding.builder_go_to_waste_exit(worker, STEP)
		elif state == _main.Bee.State.DUMPING_WASTE:
			if worker.carrying_corpse and worker.corpse_is_bee and not worker._is_inside_hive():
				saw_outside_with_body = true
			BeeBuilding.builder_dump_waste(worker, STEP)
		else:
			break
	_check(saw_outside_with_body, "the Comb worker never carried the body outside (stopped in state %d after %d steps)" % [worker.state, steps])
	_check(hive.bodies.is_empty(), "the carried body is still on the floor")
	_check(worker._is_inside_hive() and worker.state == _main.Bee.State.BUILD_IDLE, "the Comb worker did not come back in to idle")
	_check(not worker.carrying_corpse and not worker.corpse_is_bee, "the Comb worker still carries a body")

	progression._temporary.erase(CLEANING)
	if not had_comb:
		progression._temporary.erase(comb_skill)
	if had_mastered:
		progression._mastered[CLEANING] = true
	if had_temporary:
		progression._temporary[CLEANING] = true
	progression._behaviour_cache.clear()
	_main.Availability.invalidate()
	hive.clear_bodies()


# --- the cap ------------------------------------------------------
func _cap(hive) -> void:
	var old_cap: float = _config.max_hive_bodies
	_config.max_hive_bodies = 3.0
	var point: Vector2 = hive.nearest_walkable_point(_main.hive_entrance_inside())
	for i in range(4):
		hive.add_body(point, float(i + 1))
	_check(hive.bodies.size() == 3, "the cap of 3 held %d bodies" % hive.bodies.size())
	if hive.bodies.size() == 3:
		_check(hive.bodies[0].died_at == 2.0 and hive.bodies[2].died_at == 4.0, "the cap did not drop the oldest body")
	_config.max_hive_bodies = old_cap
	hive.clear_bodies()


# --- saving -------------------------------------------------------
func _saving(hive) -> void:
	var a: Vector2 = hive.nearest_walkable_point(_main.hive_entrance_inside())
	var b: Vector2 = hive.nearest_walkable_point(_main.hive.comb_centre)
	hive.add_body(a, 11.0)
	hive.add_body(b, 12.0)

	_check(_main.SaveGame.save(_main, SAVE_PATH), "the save did not write")
	hive.clear_bodies()
	var data: Dictionary = _main.SaveGame.read(SAVE_PATH)
	_check(not data.is_empty(), "the save did not read back")
	_main.saving._restore(data)
	_check(hive.bodies.size() == 2, "a load restored %d bodies, expected 2" % hive.bodies.size())
	if hive.bodies.size() == 2:
		_check(hive.bodies[0].position.distance_to(a) < 0.01 and hive.bodies[0].died_at == 11.0, "the first body did not come back where and when it was")
		_check(hive.bodies[1].position.distance_to(b) < 0.01 and hive.bodies[1].died_at == 12.0, "the second body did not come back where and when it was")

	_check(_main.TutorialCheckpoint.save(_main), "the checkpoint did not save")
	for i in range(3):
		hive.add_body(a, 20.0 + i)
	_check(_main.TutorialCheckpoint.restore(_main), "the checkpoint did not restore")
	_check(hive.bodies.size() == 2, "an in-place checkpoint restore left %d bodies, expected the saved 2" % hive.bodies.size())
	_check(_count_bodies_in_view() == 2, "the hive view holds %d body nodes after the restore, expected 2" % _count_bodies_in_view())

	var old_save: Dictionary = _main.SaveGame.read(SAVE_PATH)
	old_save["hive"].erase("bodies")
	_main.saving._restore(old_save)
	_check(hive.bodies.is_empty(), "an old save loaded with %d bodies, expected none" % hive.bodies.size())


# --- winter's dead -------------------------------------------------
## Empty comb, so the bill takes everyone: each leaves a body, and the one
## caught in the meadow lies inside the entrance at spring.
func _winter(hive) -> void:
	var old_cap: float = _config.max_hive_bodies
	_config.max_hive_bodies = 100000.0
	hive.clear_bodies()
	_main.world_building._spawn_bee("nectar")
	var outside: Node2D = _last_bee()
	_check(outside != null and not outside._is_inside_hive(), "no bee in the meadow before winter")
	for cell in hive.cells:
		if is_instance_valid(cell) and cell.is_built:
			cell.clear_cell()
	hive.invalidate_index()
	hive.invalidate_stock()
	var living := 0
	for bee in _main.get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(bee) and not bee.is_dying:
			living += 1
	_check(_main.season.winter_stores() <= 0.0, "the comb still holds stores for winter")
	var entrance: Vector2 = hive.nearest_walkable_point(_main.hive_entrance_inside())
	_main.season._resolve_winter(_config.winter_length_days)
	_check(hive.bodies.size() == living, "winter took %d bees but left %d bodies" % [living, hive.bodies.size()])
	var at_entrance := 0
	for body in hive.bodies:
		if body.position.distance_to(entrance) < 0.01:
			at_entrance += 1
	_check(at_entrance >= 1, "the bee caught outside was not laid inside the entrance")
	_config.max_hive_bodies = old_cap


func _count_bodies_in_view() -> int:
	var n := 0
	for child in _main.hive_root.get_children():
		if child.get_script() == preload("res://scripts/hive_body.gd") and not child.is_queued_for_deletion():
			n += 1
	return n


func _empty_built_cell(hive) -> Node2D:
	for cell in hive.cells:
		if is_instance_valid(cell) and cell.is_built and cell.content_type == "":
			return cell
	return null


func _last_bee() -> Node2D:
	var best: Node2D = null
	for bee in _main.get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(bee) and not bee.is_dying and (best == null or bee.bee_id > best.bee_id):
			best = bee
	return best


func _cleanup() -> void:
	_main.TutorialCheckpoint.clear()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_fail(failure)


func _fail(line: String) -> void:
	_failures.append(line)


func _report() -> void:
	if _failures.is_empty():
		print("T2-4B PASS")
		quit(0)
	else:
		for line in _failures:
			print("T2-4B FAIL: " + line)
		quit(1)
