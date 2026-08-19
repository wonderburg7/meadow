extends Node
## Autoload. Writes one `user://logs/session_<unix_time>.jsonl` file per
## run -- config once at the start, a death line whenever a bee dies, an
## hourly (in-game) snapshot, and a summary at the end -- so a run can be
## looked back over without having watched it happen. See
## DIAGNOSTIC_LOGGING_PLAN.md for the design and the reasoning behind
## each field.
##
## Session boundary: `start_session()` runs off `Session.run_reset`,
## which fires at the end of every `reset_run_state()` call (Restart Run,
## New Run, Load -- see session.gd) rather than main.gd calling this
## directly at each site. `start_session()` itself calls `end_session`
## first, so a run that's abandoned mid-play (not a queen death) still
## gets a "quit" summary before the next file opens -- this also means a
## future reset_run_state() call site is covered automatically, without
## needing to be found and wired up here.

const BeeEnums = preload("res://scripts/bee_enums.gd")
const Flower = preload("res://scripts/flower.gd")

const LOG_DIR := "user://logs"
const MAX_SESSION_FILES := 5

var _file: FileAccess = null
## True whenever there is no open session to close -- starts true so the
## very first start_session() of a boot doesn't try to summarise a
## session that never existed.
var _ended: bool = true
var _hour_accum: float = 0.0

var _total_deaths: int = 0
var _deaths_by_cause: Dictionary = {}
var _deaths_by_role: Dictionary = {}


func _ready() -> void:
	Session.run_reset.connect(start_session)


## The OS-level "close the window" request. Godot still quits normally
## after this (auto_accept_quit defaults on) -- this just gets the
## summary line written and the file flushed first, so a window close
## mid-run doesn't lose whatever was only in memory.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		end_session("quit")


func start_session() -> void:
	end_session("quit")   # no-op if nothing was open, or already ended by a collapse

	DirAccess.make_dir_recursive_absolute(LOG_DIR)
	_prune_old_sessions()

	var path: String = "%s/session_%d.jsonl" % [LOG_DIR, int(Time.get_unix_time_from_system())]
	_file = FileAccess.open(path, FileAccess.WRITE)
	_ended = false
	_hour_accum = 0.0
	_total_deaths = 0
	_deaths_by_cause.clear()
	_deaths_by_role.clear()

	_write({"type": "config", "game_time": Session.sim_time, "settings": _config_snapshot()})


func log_death(bee: Node2D) -> void:
	if _file == null:
		return
	var role_name: String = BeeEnums.Role.keys()[bee.role]
	_write({
		"type": "death",
		"game_time": Session.sim_time,
		"bee_id": bee.bee_id,
		"role": role_name,
		"is_queen": bee.is_queen,
		"is_gyne": bee.is_gyne,
		"state": BeeEnums.State.keys()[bee.state],
		"in_hive": bee._is_inside_hive(),
		"location": [bee.position.x, bee.position.y],
		"cause": bee.death_cause,
		"stats": {"energy": bee.energy, "age_seconds": bee.age_seconds},
	})
	_total_deaths += 1
	_deaths_by_cause[bee.death_cause] = int(_deaths_by_cause.get(bee.death_cause, 0)) + 1
	_deaths_by_role[role_name] = int(_deaths_by_role.get(role_name, 0)) + 1


## Called from main.gd's own per-frame block (only while unpaused, same
## as the rest of its housekeeping) -- see main.gd::_process. Only does
## real work once a full in-game hour has passed, same pattern as
## season.gd's own once-a-second accumulator.
func tick(delta: float, world: Node2D) -> void:
	if _file == null:
		return
	_hour_accum += delta
	var hour_seconds: float = GameConfig.seconds_per_day / 24.0
	if _hour_accum < hour_seconds:
		return
	_hour_accum = 0.0
	_write(_snapshot(world))


func end_session(outcome: String) -> void:
	if _ended or _file == null:
		_ended = true
		return
	_write({
		"type": "summary",
		"game_time": Session.sim_time,
		"day": _current_day(),
		"outcome": outcome,
		"total_deaths": _total_deaths,
		"deaths_by_cause": _deaths_by_cause,
		"deaths_by_role": _deaths_by_role,
		"gynes_released": Session.gynes_released,
	})
	_file.close()
	_file = null
	_ended = true


# --- building entries -----------------------------------------------

## Every GameConfig tunable, read via reflection rather than hand-copied,
## so this never drifts from what game_config.gd actually declares.
func _config_snapshot() -> Dictionary:
	var settings := {}
	for prop in GameConfig.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			settings[prop.name] = GameConfig.get(prop.name)
	return settings


func _snapshot(world: Node2D) -> Dictionary:
	var bees: Array = world.get_tree().get_nodes_in_group("bees")

	var by_role: Dictionary = {}
	for role_key in BeeEnums.Role.keys():
		by_role[role_key.to_lower()] = 0
	by_role["gyne"] = 0
	var by_state: Dictionary = {}
	for state_key in BeeEnums.State.keys():
		by_state[state_key] = 0
	for b in bees:
		if not is_instance_valid(b):
			continue
		var role_bucket: String = "gyne" if b.is_gyne else BeeEnums.Role.keys()[b.role].to_lower()
		by_role[role_bucket] = int(by_role[role_bucket]) + 1
		var state_bucket: String = BeeEnums.State.keys()[b.state]
		by_state[state_bucket] = int(by_state[state_bucket]) + 1

	var hive: Node2D = world.hive
	var by_contents: Dictionary = {}
	for content_type in ["", "nectar", "pollen", "honey", "jelly", "brood", "corpse"]:
		by_contents[content_type] = hive.cells_holding(content_type).size()
	var sealed := 0
	for cell in hive.cells:
		if is_instance_valid(cell) and cell.is_built and cell.is_closed:
			sealed += 1

	return {
		"type": "snapshot",
		"game_time": Session.sim_time,
		"day": world.day,
		"population": {
			"total": bees.size(),
			"by_role": by_role,
			"by_state": by_state,
		},
		"resources": {
			"pollen_rate_avg": _rate(world, "pollen"),
			"nectar_rate_avg": _rate(world, "nectar"),
			"food_stores": hive.total_honey(),
		},
		"cells": {
			"total": hive.cells.size(),
			"by_contents": by_contents,
			"sealed": sealed,
			"unbuilt": hive.cells_holding("unbuilt").size(),
		},
		"environment": {
			"rain_intensity": Session.rain_intensity,
			"season_fraction": Flower.season_fraction(),
			"disease": world.season.disease if world.season != null and is_instance_valid(world.season) else 0.0,
			"winter_here": Session.winter_here,
		},
	}


## Reuses main.gd's own rate-sampling window (rate_samples: a "t" plus
## cumulative-lifetime totals, refreshed every 10 sim seconds -- see
## year_winter.gd::_sample_rates) rather than keeping a second average of
## its own, so this can never disagree with what the colony panel shows.
func _rate(world: Node2D, key: String) -> float:
	var samples: Array = world.rate_samples
	if samples.size() < 2:
		return 0.0
	var oldest: Dictionary = samples[0]
	var newest: Dictionary = samples[samples.size() - 1]
	var span: float = newest.t - oldest.t
	if span <= 0.0:
		return 0.0
	return (newest[key] - oldest[key]) / span


## Matches main.gd's own day formula (main.gd::_process) so a summary
## written from outside a per-frame context (a window close, an
## abandoned-run "quit") reports the same day main.gd would.
func _current_day() -> int:
	return 1 + int(Session.sim_time / max(1.0, GameConfig.seconds_per_day))


func _prune_old_sessions() -> void:
	var dir := DirAccess.open(LOG_DIR)
	if dir == null:
		return
	var files: Array = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.begins_with("session_") and fname.ends_with(".jsonl"):
			files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	files.sort()   # unix-time filenames sort chronologically as plain strings
	while files.size() >= MAX_SESSION_FILES:
		dir.remove(files[0])
		files.remove_at(0)


func _write(entry: Dictionary) -> void:
	if _file == null:
		return
	_file.store_line(JSON.stringify(entry))
	_file.flush()
