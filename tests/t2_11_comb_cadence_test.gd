extends SceneTree
## T2-11 investigation: why comb workers build comb unevenly.
##
## A Colony Run (level 8) as the main menu starts it, with Automation and
## the Comb worker and Miner skills owned from the start, two comb workers
## in Build mode and two miners on Dig on its own, run for five game-days
## at the game's fastest speed. Every bee here is held fed (energy_immune)
## and young: a Colony Run's lone queen has no stores, and feeding trips or
## old age are not the question. The queen still builds as her backup.
##
## Options after `--`: `--no-automation` runs the same colony without
## Automation (hypothesis a); `--days=N` sets the run's length;
## `--select-from-day=N` selects the first comb worker in the HUD from the
## start of day N, as a player clicking on her would. The unittest runs
## five days with Automation, then two days without it with the selection
## from day 2.
##
## The measurement never changes the colony. bee.gd::idle_reason() calls
## hive.create_next_cell_site, which starts a site whenever one is free
## (T2-11's finding), so the test calls idle_reason() only when no site is
## free (then it has no side effect); otherwise it prints the branch
## idle_reason would reach, from the same conditions read directly.
##
## For each comb worker, every spell in BUILD_IDLE longer than 10
## game-seconds is reported: the mode, the idle reason, whether
## hive.create_next_cell_site would have returned a site, and what each
## Comb worker catalogue row would have found, all read on a frame inside
## the spell. Stretches with no building at all longer than 10 game-seconds
## are reported too, with the time by state and how many approaches to a
## site ended without building. Each game-day gets a line with the cells
## built and the sites started that day.
##
## Diagnostic, not a pass/fail gate: prints "T2_11 ..." lines, then
## "T2_11 DONE" and exits 0; exits 1 with "T2_11 FAIL" only when the run
## itself could not be set up.
## Run by tests/test_t2_11_comb_cadence.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/t2_11_comb_cadence_test.gd [-- options]

const LEVEL := 8             # the Colony Run's level row
const BOOT_FRAMES := 10
const SPEED := 8.0           # the game's own fastest speed
const IDLE_SPELL := 10.0     # game-seconds
const AUTOMATION := "skill.hive_mind.automation"
const Shapes = preload("res://scripts/shapes.gd")

var _automation := not ("--no-automation" in OS.get_cmdline_user_args())
var _days := _int_arg("--days=", 5)
var _select_from_day := _int_arg("--select-from-day=", 0)

var _main: Node = null
var _session: Node = null
var _config: Node = null
var _frame := 0
var _phase := "boot"
var _failures: PackedStringArray = PackedStringArray()
var _start_time := 0.0
var _last_now := -1.0
var _last_day := 0
var _cells_at_day_start := 0
var _built_at_day_start := 0
var _selected: Node2D = null
var _workers: Array = []      # comb workers under watch
var _miners: Array = []
var _track: Dictionary = {}   # bee_id -> per-bee bookkeeping
var _spells_found := 0
var _spells_with_site := 0
var _quiet_found := 0


static func _int_arg(prefix: String, fallback: int) -> int:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return maxi(0, int(arg.trim_prefix(prefix)))
	return fallback


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				_setup()
		"run":
			_step()
	if _phase == "done":
		_report()
		return true
	return false


func _boot() -> void:
	if not root.has_node("Session") or not root.has_node("GameConfig"):
		_failures.append("the Session or GameConfig autoload is not loaded")
		_phase = "done"
		return
	_session = root.get_node("Session")
	_config = root.get_node("GameConfig")
	_session.starting_level = LEVEL
	_session.menu_pending = false
	_main = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _setup() -> void:
	var progression: Object = _session.progression
	if progression == null:
		_failures.append("the run has no progression")
		_phase = "done"
		return
	var roles: GDScript = load("res://scripts/roles.gd")
	var Bee: GDScript = _main.Bee
	for r: int in [Bee.Role.MINER, Bee.Role.BUILDER]:
		var skill: String = roles.skill_for(r)
		if skill != "":
			progression.grant_temporary(skill)
	if _automation:
		progression.grant_temporary(AUTOMATION)
	else:
		progression._mastered.erase(AUTOMATION)
		progression._temporary.erase(AUTOMATION)
	progression._behaviour_cache.clear()
	_main.Availability.invalidate()

	for i: int in 2:
		var builder: Node2D = _main.world_building._spawn_indoor_bee(Bee.Role.BUILDER)
		builder.architect_mode = "build"
		builder.state = Bee.State.BUILD_IDLE
		_workers.append(builder)
	for i: int in 2:
		var miner: Node2D = _main.world_building._spawn_indoor_bee(Bee.Role.MINER)
		miner.automine = true
		miner.mine_queue.clear()
		miner.state = Bee.State.MINE_IDLE
		_miners.append(miner)
	var everyone: Array = _workers + _miners
	if _main.queen != null and is_instance_valid(_main.queen):
		everyone.append(_main.queen)
	for b: Variant in everyone:
		b.energy_immune = true
		b.age_seconds = 0.0
	for b: Variant in _workers:
		_track[b.bee_id] = {
			"idle_since": -1.0, "idle_last": -1.0, "idle_snapshot": {},
			"last_built": float(_session.sim_time), "quiet_states": {},
			"approach_ends": {}, "prev_state": b.state, "idle_total": 0.0,
		}
	if paused:
		paused = false
	_start_time = float(_session.sim_time)
	_last_day = 0
	_cells_at_day_start = _main.hive.cells.size()
	_built_at_day_start = _built_count()
	print("T2_11 setup: level %d, %d game-days, %d comb workers (Build), %d miners (Dig on its own), Automation %s, a free site %s, HUD selection from day %s" % [
		LEVEL, _days, _workers.size(), _miners.size(),
		"available" if _workers[0]._action_available("comb_build_outward") else "NOT available",
		_site_available(Vector2i.ZERO), str(_select_from_day) if _select_from_day > 0 else "never"])
	if _select_from_day == 1:
		_select(_workers[0])
	Engine.time_scale = SPEED
	_phase = "run"


func _step() -> void:
	var now: float = float(_session.sim_time)
	var dt: float = 0.0 if _last_now < 0.0 else now - _last_now
	_last_now = now
	var elapsed: float = now - _start_time
	var Bee: GDScript = _main.Bee
	for b: Variant in _workers:
		if not is_instance_valid(b) or b.is_dying:
			continue
		var t: Dictionary = _track[b.bee_id]
		var s: int = b.state
		# An approach to a site that ended anywhere but BUILDING, tallied by
		# the state it went to.
		if t.prev_state == Bee.State.TO_BUILD_SITE and s != Bee.State.TO_BUILD_SITE and s != Bee.State.BUILDING:
			var to: String = _state_name(s)
			t.approach_ends[to] = int(t.approach_ends.get(to, 0)) + 1
		t.prev_state = s
		# BUILD_IDLE spells. A spell's length runs to its last BUILD_IDLE
		# frame, so a spell long enough to report always has a snapshot
		# taken inside it.
		if s == Bee.State.BUILD_IDLE:
			t.idle_total += dt
			if t.idle_since < 0.0:
				t.idle_since = now
			t.idle_last = now
			if t.idle_snapshot.is_empty() and now - t.idle_since > IDLE_SPELL:
				t.idle_snapshot = _snapshot(b)
		elif t.idle_since >= 0.0:
			_close_idle(b, t)
		# Stretches with no building at all.
		if s == Bee.State.BUILDING:
			_close_quiet(b, t, now)
		else:
			var key: String = _state_name(s)
			t.quiet_states[key] = float(t.quiet_states.get(key, 0.0)) + dt
	var day_index: int = int(elapsed / float(_config.seconds_per_day))
	if day_index > _last_day:
		_last_day = day_index
		_day_line(_last_day)
		if _select_from_day > 0 and _last_day + 1 == _select_from_day and _last_day < _days:
			_select(_workers[0])
	if elapsed >= float(_days) * float(_config.seconds_per_day):
		for b: Variant in _workers:
			if is_instance_valid(b):
				var t: Dictionary = _track[b.bee_id]
				if t.idle_since >= 0.0:
					_close_idle(b, t)
				_close_quiet(b, t, now)
		Engine.time_scale = 1.0
		_phase = "done"


## Selects one bee as a click on her does (challenge_stage_setup.gd's
## _set_selection): the HUD's selection panel then refreshes on its own
## cadence, reading her idle_reason().
func _select(b: Node2D) -> void:
	for other: Variant in _main.selected_bees:
		if is_instance_valid(other):
			other.set_selected(false)
	_main.selected_bees.clear()
	b.set_selected(true)
	_main.selected_bees.append(b)
	_main.hud.update_selection(_main.selected_bees)
	_selected = b
	print("T2_11 SELECT bee %d in the HUD from day %d: selection panel visible %s" % [
		b.bee_id, _last_day + 1, _main.hud.selection_panel.visible])


func _close_idle(b: Node2D, t: Dictionary) -> void:
	var length: float = float(t.idle_last) - float(t.idle_since)
	if length > IDLE_SPELL:
		_spells_found += 1
		var snap: Dictionary = t.idle_snapshot
		if snap.is_empty():
			print("T2_11 IDLE bee %d day %.2f for %.1f s | snapshot missing" % [b.bee_id, _day_of(float(t.idle_since)), length])
		else:
			if snap.site_available:
				_spells_with_site += 1
			print("T2_11 IDLE bee %d day %.2f for %.1f s | mode=%s | selected=%s | site_available=%s | idle_reason=%s | finders: %s" % [
				b.bee_id, _day_of(float(t.idle_since)), length,
				snap.mode, b == _selected, snap.site_available, snap.reason, snap.finders])
	t.idle_since = -1.0
	t.idle_last = -1.0
	t.idle_snapshot = {}


func _close_quiet(b: Node2D, t: Dictionary, now: float) -> void:
	var length: float = now - float(t.last_built)
	if length > IDLE_SPELL:
		_quiet_found += 1
		print("T2_11 NO-BUILD bee %d day %.2f for %.1f s | approaches that ended without building, by where they went: %s | time by state: %s" % [
			b.bee_id, _day_of(float(t.last_built)), length,
			_tally(t.approach_ends, "%s %d"), _tally(t.quiet_states, "%s %.1f s")])
	t.quiet_states = {}
	t.approach_ends = {}
	t.last_built = now


func _tally(d: Dictionary, fmt: String) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for k: Variant in d:
		if float(d[k]) >= 0.5:
			parts.append(fmt % [k, d[k]])
	return ", ".join(parts) if not parts.is_empty() else "none"


## What the bee's catalogue would find right now, read without starting work.
## Rebuilt by hand from actions.gd's Comb worker rows and their bee_building.gd
## finders, so it can drift from them: re-read both if either changes.
func _snapshot(b: Node2D) -> Dictionary:
	var hive: Polygon2D = _main.hive
	var around: Vector2i = b.home_hex if b.has_home_hex else Vector2i.ZERO
	var site := _site_available(around)
	var outward_open: bool = b._action_available("comb_build_outward")
	var finders: PackedStringArray = PackedStringArray()
	var mode: String = b._action_mode_for_role(b.role)
	for action: Variant in _main.Bee._actions_by_role.get(b.role, []):
		var id: String = action.id
		if not action.modes.is_empty() and not mode in action.modes:
			continue
		if action.gated and not b._action_available(id):
			finders.append("%s=gated off" % id)
			continue
		var found := ""
		match String(action.find):
			"find_cell_needing_cleaning":
				found = "dead larva" if hive.find_cell_needing_cleaning() != null else ("body" if hive.find_body_to_clear() != null else "")
			"find_cell_needing_eviction":
				found = "cell to evict" if b.current_load <= 0.0 and hive.find_cell_needing_eviction() != null else ""
			"find_restock_job":
				found = "?"   # not probed: no restock orders in this run
			"create_cell_site_at":
				var marked := false
				for hex: Variant in b.build_queue:
					if hive.can_build_on(hex):
						marked = true
				var unfinished: Variant = hive.find_unfinished_cell()
				if marked:
					found = "marked tile"
				elif unfinished != null:
					found = "unfinished cell %s" % [unfinished.axial]
			"create_next_cell_site_outward":
				found = "spiral site" if site else ""
		finders.append("%s=%s" % [id, found if found != "" else "nothing"])
	# idle_reason() starts a site when one is free, so it is called only
	# when none is; otherwise the branch it would reach is named.
	var reason: String
	if not site or b.architect_mode in ["restock", "maintain"]:
		reason = "\"%s\"" % b.idle_reason()
	elif not outward_open:
		reason = "(not called: it would start a site) the Automation branch, \"Nothing marked to build...\""
	else:
		reason = "(not called: it would start a site) the busy branch, \"\""
	return {"mode": b.architect_mode, "site_available": site, "reason": reason, "finders": ", ".join(finders)}


## hive.create_next_cell_site's spiral walk, without starting the site. A copy
## of that loop, so it can drift from it: re-read it if that function changes.
func _site_available(around: Vector2i) -> bool:
	var hive: Polygon2D = _main.hive
	var reach := int(_config.hive_interior_rings + _config.hive_soil_depth)
	var limit := 1 + 3 * reach * (reach + 1)
	for index: int in limit:
		if hive.can_build_on(around + Shapes.hex_spiral_at(index)):
			return true
	return false


func _built_count() -> int:
	var built := 0
	for c: Variant in _main.hive.cells:
		if c.is_built:
			built += 1
	return built


func _day_line(day: int) -> void:
	var hive: Polygon2D = _main.hive
	var built := _built_count()
	var cells: int = hive.cells.size()
	var idle_parts: PackedStringArray = PackedStringArray()
	for b: Variant in _workers:
		if is_instance_valid(b):
			idle_parts.append("bee %d idle %.0f s in total" % [b.bee_id, float(_track[b.bee_id].idle_total)])
	print("T2_11 DAY %d: %d cells built that day (%d in all), %d sites started that day, %d unfinished, %d soil blocks left, a free site %s, a comb worker selected %s | %s" % [
		day, built - _built_at_day_start, built, cells - _cells_at_day_start, cells - built,
		get_nodes_in_group("soil_blocks").size(), _site_available(Vector2i.ZERO),
		_selected != null, "; ".join(idle_parts)])
	_built_at_day_start = built
	_cells_at_day_start = cells


func _day_of(time: float) -> float:
	return (time - _start_time) / float(_config.seconds_per_day) + 1.0


func _state_name(s: int) -> String:
	var names: Array = _main.Bee.State.keys()
	return names[s] if s >= 0 and s < names.size() else str(s)


func _report() -> void:
	if not _failures.is_empty():
		for f: String in _failures:
			print("T2_11 FAIL ", f)
		quit(1)
		return
	print("T2_11 SUMMARY: %d idle spells over %.0f s, %d of them while a spiral site was free; %d no-build stretches over %.0f s" % [
		_spells_found, IDLE_SPELL, _spells_with_site, _quiet_found, IDLE_SPELL])
	print("T2_11 DONE")
	quit(0)
