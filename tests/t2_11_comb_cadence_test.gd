extends SceneTree
## T2-11 investigation: why comb workers build comb unevenly.
##
## A Colony Run (level 8) as the main menu starts it, with Automation and
## the Comb worker and Miner skills owned from the start, two comb workers
## in Build mode and two miners on Dig on its own, run for five game-days
## at the game's fastest speed (or without Automation, see _automation
## below). Every bee here is held fed (energy_immune)
## and young: a Colony Run's lone queen has no stores, and feeding trips or
## old age are not the question. The queen still builds as her backup.
##
## For each comb worker, every spell in BUILD_IDLE longer than 10
## game-seconds is reported once it ends: the mode, idle_reason(), whether
## hive.create_next_cell_site would have returned a site (probed without
## side effects, by walking the same spiral over hive.can_build_on), and
## what each Comb worker catalogue row would have found. idle_reason() is
## called once per spell, at the 10-second mark, and is flagged when that
## call itself started a site (T2-11's finding). It also reports
## stretches with no building at all (BUILDING not entered) longer than
## 10 game-seconds, which catch a bee looping BUILD_IDLE -> TO_BUILD_SITE
## -> released without ever sitting idle long, and a per-day line.
##
## Diagnostic, not a pass/fail gate: prints "T2_11 ..." lines, then
## "T2_11 DONE" and exits 0; exits 1 with "T2_11 FAIL" only when the run
## itself could not be set up.
## Run by tests/test_t2_11_comb_cadence.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/t2_11_comb_cadence_test.gd

const LEVEL := 8             # the Colony Run's level row
const BOOT_FRAMES := 10
const SPEED := 8.0           # the game's own fastest speed
## `-- --no-automation` after the command runs the same colony without
## Automation (hypothesis a); `-- --days=N` shortens the run. The unittest
## runs both: five days with Automation, two without.
var _automation := not ("--no-automation" in OS.get_cmdline_user_args())
var _days := _days_arg(5)
const IDLE_SPELL := 10.0     # game-seconds
const AUTOMATION := "skill.hive_mind.automation"
const Shapes = preload("res://scripts/shapes.gd")

var _main: Node = null
var _session: Node = null
var _config: Node = null
var _frame := 0
var _phase := "boot"
var _failures: PackedStringArray = PackedStringArray()
var _start_time := 0.0
var _last_day := 0
var _workers: Array = []      # comb workers under watch
var _miners: Array = []
var _track: Dictionary = {}   # bee_id -> per-bee bookkeeping
var _spells_found := 0
var _spells_with_site := 0
var _quiet_found := 0


static func _days_arg(fallback: int) -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--days="):
			return maxi(1, int(arg.trim_prefix("--days=")))
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
	var progression = _session.progression
	if progression == null:
		_failures.append("the run has no progression")
		_phase = "done"
		return
	var roles: GDScript = load("res://scripts/roles.gd")
	var Bee = _main.Bee
	for r in [Bee.Role.MINER, Bee.Role.BUILDER]:
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

	for i in 2:
		var builder: Node2D = _main.world_building._spawn_indoor_bee(Bee.Role.BUILDER)
		builder.architect_mode = "build"
		builder.state = Bee.State.BUILD_IDLE
		_workers.append(builder)
	for i in 2:
		var miner: Node2D = _main.world_building._spawn_indoor_bee(Bee.Role.MINER)
		miner.automine = true
		miner.mine_queue.clear()
		miner.state = Bee.State.MINE_IDLE
		_miners.append(miner)
	var everyone: Array = _workers + _miners
	if _main.queen != null and is_instance_valid(_main.queen):
		everyone.append(_main.queen)
	for b in everyone:
		b.energy_immune = true
		b.age_seconds = 0.0
	for b in _workers:
		_track[b.bee_id] = {
			"idle_since": -1.0, "idle_snapshot": {},
			"last_built": float(_session.sim_time), "quiet_states": {},
			"aborted": 0, "prev_state": b.state, "idle_total": 0.0,
		}
	if paused:
		paused = false
	_start_time = float(_session.sim_time)
	_last_day = 0
	print("T2_11 setup: level %d, %d game-days, %d comb workers (Build), %d miners (Dig on its own), Automation %s, open floor sites %s" % [
		LEVEL, _days, _workers.size(), _miners.size(),
		"available" if _workers[0]._action_available("comb_build_outward") else "NOT available",
		_site_available(Vector2i.ZERO)])
	Engine.time_scale = SPEED
	_phase = "run"


func _step() -> void:
	var now: float = float(_session.sim_time)
	var elapsed: float = now - _start_time
	var Bee = _main.Bee
	for b in _workers:
		if not is_instance_valid(b) or b.is_dying:
			continue
		var t: Dictionary = _track[b.bee_id]
		var s: int = b.state
		# Aborted approach: left TO_BUILD_SITE for BUILD_IDLE without building.
		if t.prev_state == Bee.State.TO_BUILD_SITE and s == Bee.State.BUILD_IDLE:
			t.aborted += 1
		t.prev_state = s
		# BUILD_IDLE spells.
		if s == Bee.State.BUILD_IDLE:
			if t.idle_since < 0.0:
				t.idle_since = now
			elif t.idle_snapshot.is_empty() and now - t.idle_since > IDLE_SPELL:
				t.idle_snapshot = _snapshot(b)
		elif t.idle_since >= 0.0:
			_close_idle(b, t, now)
		# Stretches with no building at all (time by state: _count_quiet_time).
		if s == Bee.State.BUILDING:
			_close_quiet(b, t, now)
	_count_quiet_time()
	if int(elapsed / float(_config.seconds_per_day)) > _last_day:
		_last_day = int(elapsed / float(_config.seconds_per_day))
		_day_line(_last_day)
	if elapsed >= float(_days) * float(_config.seconds_per_day):
		for b in _workers:
			if is_instance_valid(b):
				var t: Dictionary = _track[b.bee_id]
				if t.idle_since >= 0.0:
					_close_idle(b, t, now)
				_close_quiet(b, t, now)
		Engine.time_scale = 1.0
		_phase = "done"


## Adds this frame's game time to the state the bee is in during a no-building
## stretch. sim_time moves by the frame's delta, so the difference is exact.
var _last_now := -1.0
func _count_quiet_time() -> void:
	var now: float = float(_session.sim_time)
	if _last_now < 0.0:
		_last_now = now
		return
	var dt: float = now - _last_now
	_last_now = now
	var Bee = _main.Bee
	for b in _workers:
		if not is_instance_valid(b):
			continue
		var t: Dictionary = _track[b.bee_id]
		if b.state == Bee.State.BUILD_IDLE:
			t.idle_total += dt
		if b.state != Bee.State.BUILDING:
			var key: String = _state_name(b.state)
			t.quiet_states[key] = float(t.quiet_states.get(key, 0.0)) + dt


func _close_idle(b: Node2D, t: Dictionary, now: float) -> void:
	var length: float = now - float(t.idle_since)
	if length > IDLE_SPELL:
		_spells_found += 1
		var snap: Dictionary = t.idle_snapshot if not t.idle_snapshot.is_empty() else _snapshot(b)
		if snap.site_available:
			_spells_with_site += 1
		print("T2_11 IDLE bee %d day %.2f for %.1f s | mode=%s | site_available=%s | idle_reason=\"%s\" | finders: %s" % [
			b.bee_id, (float(t.idle_since) - _start_time) / float(_config.seconds_per_day) + 1.0, length,
			snap.mode, snap.site_available, snap.reason, snap.finders])
	t.idle_since = -1.0
	t.idle_snapshot = {}


func _close_quiet(b: Node2D, t: Dictionary, now: float) -> void:
	var length: float = now - float(t.last_built)
	if length > IDLE_SPELL:
		_quiet_found += 1
		var parts: PackedStringArray = PackedStringArray()
		for k in t.quiet_states:
			if float(t.quiet_states[k]) >= 0.5:
				parts.append("%s %.1f s" % [k, float(t.quiet_states[k])])
		print("T2_11 NO-BUILD bee %d day %.2f for %.1f s | aborted approaches so far %d | time by state: %s" % [
			b.bee_id, (float(t.last_built) - _start_time) / float(_config.seconds_per_day) + 1.0, length,
			int(t.aborted), ", ".join(parts)])
	t.quiet_states = {}
	t.last_built = now


## What the bee's catalogue would find right now, read without starting work.
## Probes before idle_reason(), which calls hive.create_next_cell_site and so
## can itself start a site.
func _snapshot(b: Node2D) -> Dictionary:
	var hive = _main.hive
	var around: Vector2i = b.home_hex if b.has_home_hex else Vector2i.ZERO
	var site := _site_available(around)
	var finders: PackedStringArray = PackedStringArray()
	var mode: String = b._action_mode_for_role(b.role)
	for action in _main.Bee._actions_by_role.get(b.role, []):
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
				for hex in b.build_queue:
					if hive.can_build_on(hex):
						marked = true
				var unfinished = hive.find_unfinished_cell()
				if marked:
					found = "marked tile"
				elif unfinished != null:
					found = "unfinished cell %s" % [unfinished.axial]
			"create_next_cell_site_outward":
				found = "spiral site" if site else ""
		finders.append("%s=%s" % [id, found if found != "" else "nothing"])
	var cells_before: int = hive.cells.size()
	var reason: String = b.idle_reason()
	if hive.cells.size() != cells_before:
		reason += " [idle_reason() started a site]"
	return {"mode": b.architect_mode, "site_available": site, "reason": reason, "finders": ", ".join(finders)}


## hive.create_next_cell_site's spiral walk, without starting the site.
func _site_available(around: Vector2i) -> bool:
	var hive = _main.hive
	var reach := int(_config.hive_interior_rings + _config.hive_soil_depth)
	var limit := 1 + 3 * reach * (reach + 1)
	for index in limit:
		if hive.can_build_on(around + Shapes.hex_spiral_at(index)):
			return true
	return false


func _day_line(day: int) -> void:
	var hive = _main.hive
	var built := 0
	var sites := 0
	for c in hive.cells:
		if c.is_built:
			built += 1
		else:
			sites += 1
	var idle_parts: PackedStringArray = PackedStringArray()
	for b in _workers:
		if is_instance_valid(b):
			idle_parts.append("bee %d idle %.0f s, aborted %d" % [b.bee_id, float(_track[b.bee_id].idle_total), int(_track[b.bee_id].aborted)])
	print("T2_11 DAY %d: %d cells built, %d sites, %d soil blocks left, open site %s | %s" % [
		day, built, sites, get_nodes_in_group("soil_blocks").size(), _site_available(Vector2i.ZERO), "; ".join(idle_parts)])


func _state_name(s: int) -> String:
	var names: Array = _main.Bee.State.keys()
	return names[s] if s >= 0 and s < names.size() else str(s)


func _report() -> void:
	if not _failures.is_empty():
		for f in _failures:
			print("T2_11 FAIL ", f)
		quit(1)
		return
	print("T2_11 SUMMARY: %d idle spells over %.0f s, %d of them while a spiral site was free; %d no-build stretches over %.0f s" % [
		_spells_found, IDLE_SPELL, _spells_with_site, _quiet_found, IDLE_SPELL])
	print("T2_11 DONE")
	quit(0)
