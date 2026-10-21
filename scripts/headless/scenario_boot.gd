## Headless --scenario boot and end-of-run, moved out of main.gd (CQ-R1).
## Static functions that take `main`; the scenario_* fields stay on main
## because scenario_actions.gd, diagnostic_log.gd and main's own loop read them.
class_name ScenarioBoot
extends RefCounted

const Levels = preload("res://scripts/levels.gd")
const SaveSlots = preload("res://scripts/save_slots.gd")
const ScenarioActions = preload("res://scripts/scenario_actions.gd")

## Dev-only headless playtest path -- see AI_PLAYTEST_PLAN.md. Never
## reachable from the main menu; only ever set by a --scenario= argument on
## the actual command line the process was launched with. The JSON is
## applied through levels.gd's existing LEVELS shape (via Levels.get_level),
## plus a "config_overrides" block applied to GameConfig -- see
## Levels.apply_config_overrides for the per-field allowlist check -- and an
## optional "time_scale" field (defaults to 30x, see slice 3 below).
static func apply_boot_arg(main: Node2D) -> void:
	var scenario_path: String = ""
	# --run-id=: the headless harness's own per-launch identifier
	# (CHATGPT_INSIGHTS_PLAN.md's A1), not a scenario JSON field -- it names
	# this process's launch, not the scenario. Optional; a manual
	# --scenario= launch with no --run-id still works, same as before.
	var run_id: String = ""
	# --random-seed=: run_scenario.py's own per-launch override
	# (CHATGPT_INSIGHTS_PLAN.md's A2) -- lets it hand each --repeat
	# iteration a fresh seed without editing the scenario file. Wins over
	# the scenario's own "random_seed" field below when both are given.
	var cmdline_seed: String = ""
	# Created only by tools/run_scenario.py. Keeping the output location off
	# scenario JSON makes concurrent runs unambiguous and cannot grant a
	# scenario fixture arbitrary file-write authority.
	var session_output_path: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			scenario_path = arg.substr("--scenario=".length())
		elif arg.begins_with("--run-id="):
			run_id = arg.substr("--run-id=".length())
		elif arg.begins_with("--random-seed="):
			cmdline_seed = arg.substr("--random-seed=".length())
		elif arg.begins_with("--headless-session-path="):
			session_output_path = arg.substr("--headless-session-path=".length())
	if scenario_path.is_empty():
		return

	if not FileAccess.file_exists(scenario_path):
		push_error("--scenario=%s: file not found" % scenario_path)
		return
	var text: String = FileAccess.get_file_as_string(scenario_path)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_error("--scenario=%s: not a JSON object" % scenario_path)
		return

	var level: Dictionary = parsed.duplicate(true)
	var performance_capture: Variant = level.get("performance_capture", null)
	level.erase("performance_capture")
	main.scenario_performance_capture = _parse_performance_capture(performance_capture)
	if performance_capture != null and main.scenario_performance_capture.is_empty():
		main.get_tree().quit(2)
		return
	var scenario_diagnostics: Variant = level.get("diagnostics", null)
	level.erase("diagnostics")
	var stop: Dictionary = level.get("stop", {})
	level.erase("stop")
	var config_overrides: Dictionary = level.get("config_overrides", {})
	level.erase("config_overrides")
	# A Challenge scenario uses the Challenge's ordinary level setup, but keeps
	# the scenario-only controls below (actions, stop conditions, diagnostics)
	# available to the headless runner. Leaving this absent preserves the
	# existing synthetic scenario level exactly.
	var challenge_id: int = int(level.get("challenge", 0))
	level.erase("challenge")
	# Dev-only headless action driver (docs/headless-run-contract.md)
	# -- see scenario_actions.gd. Not a levels.gd field, same
	# reasoning as stop/config_overrides just above.
	var actions: Array = level.get("actions", [])
	level.erase("actions")
	# Dev-only, not a GameConfig field so it doesn't go through the
	# allowlist in Levels.apply_config_overrides -- see AI_PLAYTEST_PLAN.md
	# slice 3. Default of 30x is the ceiling that slice 3 confirmed holds
	# steady (identical total_deaths/deaths_by_cause/deaths_by_role at
	# 8x/16x/30x on a 30-day level-4-shaped run -- no sign of the large-
	# per-frame-delta overshoot the plan's "open risk" worried about,
	# comfortably past the player-facing 8x speed-control cap). A scenario
	# file can still ask for a different value if a future test finds a
	# scenario class where 30x isn't safe.
	var scenario_time_scale: float = float(level.get("time_scale", 30.0))
	level.erase("time_scale")
	# Same reasoning as time_scale just above: dev-only, describes how much
	# diagnostic data this run records rather than anything about how the
	# game plays, so it bypasses GameConfig/the allowlist entirely rather
	# than going through config_overrides. Optional -- omitted means the
	# ordinary hourly cadence. See DiagnosticLog.snapshot_interval_override.
	var scenario_snapshot_seconds: float = float(level.get("snapshot_seconds", -1.0))
	level.erase("snapshot_seconds")
	# PP-1, dev-only like snapshot_seconds: see main.gd scenario_pollination_log.
	main.scenario_pollination_log = bool(level.get("pollination_log", false))
	level.erase("pollination_log")
	# Dev-only, same reasoning as time_scale/snapshot_seconds above. An
	# explicit field instead of always reusing DEFAULT_RANDOM_SEED (the one
	# every manual-play boot also gets) lets a headless comparison declare
	# the same seed on both sides to cancel randomness out, or -- via
	# --random-seed=, which wins if both are present -- let run_scenario.py
	# hand each --repeat iteration its own fresh seed instead of every
	# repeat replaying identically.
	var scenario_random_seed: int = int(level.get("random_seed", main.DEFAULT_RANDOM_SEED))
	if cmdline_seed != "":
		scenario_random_seed = int(cmdline_seed)
	level.erase("random_seed")
	# A UI-only scenario (layout/text assertions) has no colony to describe;
	# cells and forager counts remain direct boot fields, while indoor roles
	# read their optional start_count_key from roles.gd.
	for count_key: String in ["cells", "nectar_foragers", "pollen_foragers"]:
		level[count_key] = level.get(count_key, 0)

	Levels.scenario_override = level
	Levels.apply_config_overrides(config_overrides)
	Session.starting_level = challenge_id if challenge_id in [1, 2] else Levels.SCENARIO_LEVEL_ID
	Session.menu_pending = false
	main.scenario_active = true
	SaveSlots.use_scratch_root()
	main.scenario_actions = actions
	main.scenario_stop_max_days = int(stop.get("max_days", -1))
	main.scenario_stop_when = stop.get("when", {})
	main.scenario_stop_when_actions_resolved = bool(stop.get("when_actions_resolved", false))
	Engine.time_scale = scenario_time_scale
	DiagnosticLog.snapshot_interval_override = scenario_snapshot_seconds
	if not DiagnosticLog.configure_scenario_diagnostics(scenario_diagnostics):
		main.get_tree().quit(2)
		return
	DiagnosticLog.configure_performance_capture(main.scenario_performance_capture)
	DiagnosticLog.run_id_override = run_id
	DiagnosticLog.session_path_override = session_output_path
	seed(scenario_random_seed)
	DiagnosticLog.scenario_random_seed = scenario_random_seed
	# DiagnosticLog only ever opens a session file off Session.run_reset
	# (see diagnostic_log.gd) -- fired at the end of every reset_run_state(),
	# which a normal boot never calls (only Restart/New Run/Load do). A
	# scenario boot needs the same session file every other run gets, so it
	# has to trigger that itself.
	Session.reset_run_state()
	print("AI playtest: loaded scenario %s (stop.max_days=%s, time_scale=%s, random_seed=%s)" % [scenario_path, main.scenario_stop_max_days, scenario_time_scale, scenario_random_seed])


static func _parse_performance_capture(raw: Variant) -> Dictionary:
	if raw == null:
		return {}
	if not (raw is Dictionary):
		push_error("scenario performance_capture must be an object")
		return {}
	var allowed := ["warmup_frames", "measurement_frames", "sections", "include_fog"]
	for key: Variant in raw:
		if not key in allowed:
			push_error("scenario performance_capture has unknown key: %s" % key)
			return {}
	for required: String in ["warmup_frames", "measurement_frames", "sections"]:
		if not raw.has(required):
			push_error("scenario performance_capture missing %s" % required)
			return {}
	var warmup: Variant = raw.warmup_frames
	var measurement: Variant = raw.measurement_frames
	if not _is_whole_number(warmup) or warmup < 0:
		push_error("scenario performance_capture.warmup_frames must be a non-negative integer")
		return {}
	if not _is_whole_number(measurement) or measurement <= 0:
		push_error("scenario performance_capture.measurement_frames must be a positive integer")
		return {}
	if not (raw.sections is Array) or raw.sections.is_empty():
		push_error("scenario performance_capture.sections must be a non-empty array")
		return {}
	var sections: Array = []
	for section: Variant in raw.sections:
		if not (section is String) or section.is_empty() or section in sections:
			push_error("scenario performance_capture.sections must contain unique non-empty strings")
			return {}
		sections.append(section)
	var include_fog: Variant = raw.get("include_fog", false)
	if not (include_fog is bool):
		push_error("scenario performance_capture.include_fog must be boolean")
		return {}
	return {"warmup_frames": warmup, "measurement_frames": measurement,
		"sections": sections, "include_fog": include_fog}


static func _is_whole_number(value: Variant) -> bool:
	return (value is int) or (value is float and is_equal_approx(value, round(value)))


## Ends a headless scenario run the same way a normal loss does --
## DiagnosticLog gets its summary line either way -- but quits the process
## afterwards instead of showing game_over's UI, since nothing is watching
## it. `outcome` matches DiagnosticLog.end_session's existing vocabulary
## ("collapsed" is already used by _check_for_loss; "max_days" and
## "assert_failed" were added for the headless action driver, the latter
## from a failed scenario_actions.gd "assert"; "stop_condition_met" and
## "actions_resolved" are CHATGPT_INSIGHTS_PLAN.md's A5 early-success
## stops). Any action left unresolved (its "when" never met) is logged
## before the summary line, same reasoning as a failed assert: a run
## should say plainly what it couldn't do, not just what it did.
static func end_run(main: Node2D, outcome: String) -> void:
	ScenarioActions.log_unresolved(main.scenario_actions)
	DiagnosticLog.set_queen_alive(is_instance_valid(main.queen))
	DiagnosticLog.end_session(outcome)
	if DiagnosticLog.session_path_override != "":
		print("MEADOW_RESULT_PATH=%s" % DiagnosticLog.session_path())
	print("AI playtest: scenario ended (%s) at day %d" % [outcome, main.day])
	main.get_tree().quit()
