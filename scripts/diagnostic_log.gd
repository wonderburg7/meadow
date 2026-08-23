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
## -1.0 means "use the ordinary hourly cadence" (GameConfig.seconds_per_day
## / 24). Set directly by main.gd from a scenario's "snapshot_seconds"
## field -- see tick() -- never through GameConfig, since this describes
## how much diagnostic data a run records rather than anything about how
## the game plays (.claude/rules/simulation.md's GameConfig/Session
## test), and mirrors how "time_scale" is already handled the same way.
var snapshot_interval_override: float = -1.0
## Set by main.gd from a --run-id= boot argument (CHATGPT_INSIGHTS_PLAN.md's
## A1) -- the headless harness's own per-launch identifier, not a scenario
## JSON field, since it names *this process's launch*, not the scenario
## being run. Folded into the session filename so run_scenario.py can pick
## its own file by exact match instead of by newest mtime, which two runs
## started in the same wall-clock second (or a stray manual play session)
## could otherwise race.
var run_id_override: String = ""
## The RNG seed actually in effect for this run (CHATGPT_INSIGHTS_PLAN.md's
## A2). main.gd's own manual-play boot always seeds with
## main.DEFAULT_RANDOM_SEED (12345, duplicated here rather than shared --
## a stable literal, not worth a cross-autoload reference), so this starts
## at that same value and only changes when _apply_scenario_boot_arg
## resolves a scenario's "random_seed" field or run_scenario.py's
## --random-seed= override. Logged in the "config" entry so a headless
## comparison can confirm afterwards which seed each side actually ran
## with, not just which one it asked for.
var scenario_random_seed: int = 12345

var _total_deaths: int = 0
var _deaths_by_cause: Dictionary = {}
var _deaths_by_role: Dictionary = {}
var _crab_spider_events: Dictionary = {}   # "kill"/"escape"/"alarm_flee" -> count
var _recruitment_matches: int = 0
var _scouting_settled: int = 0
var _orientation_flights: int = 0
var _recruitment_followups: int = 0
var _recruit_partner_overlaps: int = 0
var _foragers_settled: int = 0
## Cheap counters, bumped straight from bee_foraging.gd's hot flower-search
## path (nearest_flower's accept closure, once per bee per candidate
## flower) -- no per-call _write() there, that path runs far too often for
## a file write each time. Only the once-an-hour snapshot and the summary
## ever read these.
var _tarsal_marks: int = 0
var _tarsal_rejections: int = 0
var _flower_visits: int = 0
var _flowers_visited_ids: Dictionary = {}   # flower instance id -> true
var _stall_recoveries: int = 0

## Role outcome counters -- see CHATGPT_INSIGHTS_PLAN.md's C5. Cheap
## counters bumped straight from bee_nursery.gd/bee_honey.gd/
## bee_building.gd/bee_mining.gd at the moment each unit of work
## actually completes, so a run's summary states plainly how much real
## work each role got done, not just how many bees held that role.
var _brood_feeds: int = 0
var _brood_hatches: int = 0
var _brood_hatches_by_role_mode: Dictionary = {}
var _jelly_batches: int = 0
var _larval_deaths: int = 0
var _cells_completed: int = 0
var _cells_cleaned: int = 0
var _cells_evicted: int = 0
var _cells_restocked: int = 0
var _blocks_mined: int = 0
var _honey_batches_deposited: int = 0
var _cells_ripened: int = 0


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

	var stamp: String = str(int(Time.get_unix_time_from_system()))
	var suffix: String = ("_%s" % run_id_override) if run_id_override != "" else ""
	var path: String = "%s/session_%s%s.jsonl" % [LOG_DIR, stamp, suffix]
	_file = FileAccess.open(path, FileAccess.WRITE)
	_ended = false
	_hour_accum = 0.0
	_total_deaths = 0
	_deaths_by_cause.clear()
	_deaths_by_role.clear()
	_crab_spider_events.clear()
	_recruitment_matches = 0
	_scouting_settled = 0
	_orientation_flights = 0
	_recruitment_followups = 0
	_recruit_partner_overlaps = 0
	_foragers_settled = 0
	_tarsal_marks = 0
	_tarsal_rejections = 0
	_flower_visits = 0
	_flowers_visited_ids.clear()
	_stall_recoveries = 0
	_brood_feeds = 0
	_brood_hatches = 0
	_brood_hatches_by_role_mode.clear()
	_jelly_batches = 0
	_larval_deaths = 0
	_cells_completed = 0
	_cells_cleaned = 0
	_cells_evicted = 0
	_cells_restocked = 0
	_blocks_mined = 0
	_honey_batches_deposited = 0
	_cells_ripened = 0

	_write({"type": "config", "game_time": Session.sim_time, "random_seed": scenario_random_seed,
			"settings": _config_snapshot()})


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


## Called from crab_spider.gd for all three outcomes an attack/alarm can
## have -- "kill", "escape", "alarm_flee" -- so the log has direct
## evidence the mechanic is firing at all (CRAB_SPIDER_PLAN.md is off by
## default; a run with predators_on but zero of these lines means the
## toggle, the spawn roll, or the hook into start_collecting()/inspect()
## isn't actually wired up, not just that nobody got unlucky) and so the
## observed kill/escape ratio can be checked against
## crab_spider_attack_success_chance directly, rather than only inferred
## from the death log's "crab spider ambush" cause.
func log_crab_spider_event(bee: Node2D, flower: Node2D, outcome: String) -> void:
	if _file == null:
		return
	_write({
		"type": "crab_spider_event",
		"game_time": Session.sim_time,
		"bee_id": bee.bee_id,
		"role": BeeEnums.Role.keys()[bee.role],
		"species": flower.species_name,
		"outcome": outcome,
		"location": [flower.position.x, flower.position.y],
	})
	_crab_spider_events[outcome] = int(_crab_spider_events.get(outcome, 0)) + 1


## Called from bee_foraging.gd::wait_at_entrance() the moment a seeker is
## handed a mentor's patch -- direct evidence auto-recruitment is
## actually matching bees up, not just that the entrance-wait states are
## being entered. Carries both bees' avg_collection_rate at the moment of
## the match, so the recruit_lower/upper_threshold_nectar/pollen numbers
## in game_config.gd can be checked against what real trips were actually
## delivering rather than trusted on the strength of the starting guess
## alone. seeker_rate_before is also the baseline log_recruitment_followup
## compares this bee's next few trips on the new patch against.
func log_recruitment_match(seeker: Node2D, mentor: Node2D) -> void:
	if _file == null:
		return
	_write({
		"type": "recruitment_match",
		"game_time": Session.sim_time,
		"seeker_id": seeker.bee_id,
		"mentor_id": mentor.bee_id,
		"resource_type": seeker.resource_type,
		"start_point": [mentor.forage_start_point.x, mentor.forage_start_point.y],
		"species": mentor.preferred_species,
		"seeker_rate_before": seeker.avg_collection_rate,
		"seeker_trips_scored": seeker.trips_scored,
		"mentor_rate": mentor.avg_collection_rate,
		"mentor_trips_scored": mentor.trips_scored,
	})
	_recruitment_matches += 1


## Called from bee_foraging.gd::_score_trip() for each of a recruited
## bee's (and her mentor's -- see recruit_role) first RECRUIT_FOLLOWUP_TRIPS
## trips after a match -- the direct answer to "does resource collection
## improve for recruited bees, over more than just the first noisy trip",
## and, since the mentor is tracked too, "does having someone follow you
## onto your own patch cost you anything". trip_rate is that one trip's
## raw rate; rate_before is the fixed baseline both bees had *before* the
## match, repeated on every row so each trip can be compared against it
## without joining back to the recruitment_match line.
func log_recruitment_followup(bee: Node2D, trip_index: int, trip_rate: float) -> void:
	if _file == null:
		return
	_write({
		"type": "recruitment_followup",
		"game_time": Session.sim_time,
		"bee_id": bee.bee_id,
		"partner_id": bee.recruit_partner.bee_id if bee.recruit_partner != null and is_instance_valid(bee.recruit_partner) else -1,
		"recruit_role": bee.recruit_role,
		"resource_type": bee.resource_type,
		"trip_index": trip_index,
		"rate_before": bee.recruit_rate_before,
		"trip_rate": trip_rate,
	})
	_recruitment_followups += 1


## Called from bee_foraging.gd::start_collecting() when a bee mid-followup
## lands on a flower her recruit partner (mentor or seeker, whichever she
## is) marked most recently -- direct evidence for or against the
## hypothesis that sharing a start point means trailing the other bee
## onto flowers she only just drained, rather than genuinely fresh ones.
func count_recruit_partner_overlap() -> void:
	_recruit_partner_overlaps += 1


## Called from bee_foraging.gd::_score_trip() the first time a forager's
## trips_scored reaches recruit_grace_trips -- fires once per bee, so a
## run's own log always carries a real settled-rate sample for nectar and
## pollen without needing a one-off debug print added back in to get one
## (see recruit_lower/upper_threshold_nectar/pollen's derivation comment
## in game_config.gd).
func log_forager_settled(bee: Node2D) -> void:
	if _file == null:
		return
	_write({
		"type": "forager_settled",
		"game_time": Session.sim_time,
		"bee_id": bee.bee_id,
		"resource_type": bee.resource_type,
		"rate": bee.avg_collection_rate,
	})
	_foragers_settled += 1


## Called from bee_foraging.gd::take_orientation_flight() -- direct
## evidence orientation flight is actually running (fires for every new
## forager whenever orientation_flight_on is on, indoor- or
## outdoor-spawned), rather than only inferable from forage_start_point
## being set.
func log_orientation_flight(bee: Node2D) -> void:
	if _file == null:
		return
	_write({
		"type": "orientation_flight",
		"game_time": Session.sim_time,
		"bee_id": bee.bee_id,
		"role": BeeEnums.Role.keys()[bee.role],
		"point": [bee.forage_start_point.x, bee.forage_start_point.y],
	})
	_orientation_flights += 1


## Bumped from bee_foraging.gd::start_collecting() -- a real feeding visit,
## whatever the toggles. Cheap counters only (no per-call _write, see the
## field comments above); rolled into the hourly snapshot and the summary.
func count_flower_visit(flower: Node2D) -> void:
	_flower_visits += 1
	if flower != null and is_instance_valid(flower):
		_flowers_visited_ids[flower.get_instance_id()] = true


func count_tarsal_mark() -> void:
	_tarsal_marks += 1


## Bumped from bee_foraging.gd::nearest_flower()'s accept closure -- a
## candidate flower turned down specifically because another bee marked it
## recently. Direct evidence tarsal marking is actually steering bees away
## from stripped flowers, not just that the toggle is on and marks are
## being left.
func count_tarsal_rejection() -> void:
	_tarsal_rejections += 1


## Called from bee_survival.gd::watch_for_stalls() the moment it judges a
## bee stuck (STALL_SECONDS of no real progress towards `goal`) and is
## about to take recovery action -- not gated to a toggle, since a stall
## can happen to any moving bee, but written for every scouting-collapse
## investigation this diagnostic pass was built for: whether the backstop
## is firing constantly (a real dead end in the steering) or barely at
## all (the bees piling up aren't even reaching this check).
func log_stall_recovery(bee: Node2D, goal: Vector2) -> void:
	if _file == null:
		return
	_write({
		"type": "stall_recovery",
		"game_time": Session.sim_time,
		"bee_id": bee.bee_id,
		"role": BeeEnums.Role.keys()[bee.role],
		"state": BeeEnums.State.keys()[bee.state],
		"position": [bee.position.x, bee.position.y],
		"goal": [goal.x, goal.y],
	})
	_stall_recoveries += 1


## Called from bee_foraging.gd::_score_trip() when a scouting bee's three
## bouts are all in and she commits (or fails to). `found_patch: false`
## with scouting otherwise looking healthy in the snapshot counts is the
## tell for "scouting runs but never actually finds anywhere worth
## settling", which reads identically to "scouting isn't wired up" from
## the population numbers alone.
func log_scouting_settled(bee: Node2D) -> void:
	if _file == null:
		return
	_write({
		"type": "scouting_settled",
		"game_time": Session.sim_time,
		"bee_id": bee.bee_id,
		"found_patch": bee.scout_best_rate > 0.0,
		"best_rate": bee.scout_best_rate,
		"start_point": [bee.forage_start_point.x, bee.forage_start_point.y],
		"species": bee.preferred_species,
	})
	_scouting_settled += 1


## Called from bee_nursery.gd::feed_brood() -- one real meal delivered to
## a larva, whatever its type.
func count_brood_feed() -> void:
	_brood_feeds += 1


## Called from world_building.gd::_spawn_hatched_bee() after the new bee's
## role-specific mode has been applied. This is the concise headless proof
## that fed brood completed development and emerged as the requested job.
func count_brood_hatch(role: int, mode: String) -> void:
	_brood_hatches += 1
	var key: String = "%s/%s" % [BeeEnums.Role.keys()[role], mode]
	_brood_hatches_by_role_mode[key] = int(_brood_hatches_by_role_mode.get(key, 0)) + 1


## Called from bee_nursery.gd::nurse_make_jelly() when a batch finishes.
func count_jelly_batch() -> void:
	_jelly_batches += 1


## Called from hive_cell.gd::_larva_dies().
func count_larval_death() -> void:
	_larval_deaths += 1


## Called from hive_cell.gd::add_build_progress() the moment a cell
## finishes building.
func count_cell_completed() -> void:
	_cells_completed += 1


## Read by the dev-only smoke scenario's early-success condition.
func cell_completed_count() -> int:
	return _cells_completed


## Called from bee_building.gd::architect_clean() once a dead larva is
## fully cleared out.
func count_cell_cleaned() -> void:
	_cells_cleaned += 1


## Called from hive_cell.gd::take_resource() when an eviction-requested
## cell is fully emptied -- covers both "discard" and "move" evict modes,
## since both drain the source cell through take_resource.
func count_cell_evicted() -> void:
	_cells_evicted += 1


## Called from bee_building.gd::restock_go_to_target() each time a
## restock delivery is placed in its destination cell.
func count_cell_restocked() -> void:
	_cells_restocked += 1


## Called from bee_mining.gd::miner_dig() the moment a soil block
## finishes mining.
func count_block_mined() -> void:
	_blocks_mined += 1


## Called from bee_honey.gd::honey_deposit() when a honey maker fully
## empties her load into a cell.
func count_honey_batch_deposited() -> void:
	_honey_batches_deposited += 1


## Called from hive_cell.gd::add_fanning_progress() the moment a cell
## crosses honey_ripen_time and becomes ripe.
func count_cell_ripened() -> void:
	_cells_ripened += 1


## Called from scenario_actions.gd for every headless scenario action
## attempted -- see AI_PLAYTEST_PLAN.md's action-driver extension and
## insights_from_ChatGPT.md's 22 Aug 2026 entry. One line per action,
## whatever the result, so a run states plainly what it tried to do and
## whether it worked, not just what happened to the bees afterwards.
func log_action(do: String, target_desc: String, result: String, reason: String) -> void:
	if _file == null:
		return
	_write({
		"type": "action",
		"game_time": Session.sim_time,
		"do": do,
		"target": target_desc,
		"result": result,
		"reason": reason,
	})


## Read-side counterpart to the counters this file already keeps for its
## own summary line -- lets a scenario's "when"/"assert" conditions ask
## "has this actually happened N times yet" without scenario_actions.gd
## reaching into this file's private counters. subtype only matters for
## crab_spider_event ("kill"/"escape"/"alarm_flee"); the flat counters
## ignore it.
func event_count(type: String, subtype: String = "") -> int:
	match type:
		"brood_feed":
			return _brood_feeds
		"brood_hatch":
			if subtype != "":
				return int(_brood_hatches_by_role_mode.get(subtype, 0))
			return _brood_hatches
		"jelly_batches":
			return _jelly_batches
		"honey_batches_deposited":
			return _honey_batches_deposited
		"cells_ripened":
			return _cells_ripened
		"cells_restocked":
			return _cells_restocked
		"death":
			if subtype != "":
				return int(_deaths_by_cause.get(subtype, 0))
			return _total_deaths
		"flower_visit":
			return _flower_visits
		"recruitment_match":
			return _recruitment_matches
		"scouting_settled":
			return _scouting_settled
		"crab_spider_event":
			if subtype == "":
				var total := 0
				for count in _crab_spider_events.values():
					total += int(count)
				return total
			return int(_crab_spider_events.get(subtype, 0))
		"orientation_flight":
			return _orientation_flights
		"forager_settled":
			return _foragers_settled
		_:
			return 0


## Called from main.gd's own per-frame block (only while unpaused, same
## as the rest of its housekeeping) -- see main.gd::_process. Only does
## real work once a full in-game hour has passed, same pattern as
## season.gd's own once-a-second accumulator.
func tick(delta: float, world: Node2D) -> void:
	if _file == null:
		return
	_hour_accum += delta
	# snapshot_interval_override lets a --scenario= run pick a fixed
	# sim-second cadence instead -- see main.gd::_apply_scenario_boot_arg
	# and its "snapshot_seconds" field, same pattern as "time_scale".
	# Ordinary play is untouched: an hour is exactly what the day-length
	# setting says it is. A compressed test day (seconds_per_day pushed
	# down to keep a headless run's real-world time short) otherwise means
	# an "hour" is a fraction of a sim-second, so a 60-day run logs a
	# snapshot every frame or two -- the AI-playtest-harness session's
	# 60-day/20s-per-day runs were writing 1000+ snapshot lines each
	# (2MB+ files) for data that a coarser cadence captures just as well:
	# population and rates barely move between one snapshot and the next
	# at that resolution, so nothing analyze_session.py or a human
	# actually reads was lost by spacing them out.
	var interval: float = snapshot_interval_override if snapshot_interval_override > 0.0 else GameConfig.seconds_per_day / 24.0
	if _hour_accum < interval:
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
		"crab_spider_events": _crab_spider_events,
		"recruitment_matches": _recruitment_matches,
		"scouting_settled": _scouting_settled,
		"orientation_flights": _orientation_flights,
		"recruitment_followups": _recruitment_followups,
		"recruit_partner_overlaps": _recruit_partner_overlaps,
		"foragers_settled": _foragers_settled,
		"tarsal_marks": _tarsal_marks,
		"tarsal_rejections": _tarsal_rejections,
		"flower_visits": _flower_visits,
		"unique_flowers_visited": _flowers_visited_ids.size(),
		"stall_recoveries": _stall_recoveries,
		"brood_feeds": _brood_feeds,
		"brood_hatches": _brood_hatches,
		"brood_hatches_by_role_mode": _brood_hatches_by_role_mode,
		"jelly_batches": _jelly_batches,
		"larval_deaths": _larval_deaths,
		"cells_completed": _cells_completed,
		"cells_cleaned": _cells_cleaned,
		"cells_evicted": _cells_evicted,
		"cells_restocked": _cells_restocked,
		"blocks_mined": _blocks_mined,
		"honey_batches_deposited": _honey_batches_deposited,
		"cells_ripened": _cells_ripened,
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

	# Live counts, not just deltas since the last event -- these are what
	# let a snapshot answer "is floral constancy/recruitment/scouting
	# actually doing anything right now" on its own, without having to
	# cross-reference the discrete event lines above.
	var scouting_now := 0
	var by_preferred_species: Dictionary = {}
	# Settled foragers (not mid-scout) split by whether they've got a
	# floral-constancy preference, so a snapshot can answer "are the bees
	# with a preferred species actually collecting faster" directly,
	# without needing to cross-reference individual bees by hand.
	var rate_with_preference_sum := 0.0
	var rate_with_preference_n := 0
	var rate_without_preference_sum := 0.0
	var rate_without_preference_n := 0
	for b in bees:
		if not is_instance_valid(b):
			continue
		if b.is_scouting:
			scouting_now += 1
		if b.preferred_species != "":
			by_preferred_species[b.preferred_species] = int(by_preferred_species.get(b.preferred_species, 0)) + 1
		if b.role == BeeEnums.Role.FORAGER and not b.is_scouting:
			if b.preferred_species != "":
				rate_with_preference_sum += b.avg_collection_rate
				rate_with_preference_n += 1
			else:
				rate_without_preference_sum += b.avg_collection_rate
				rate_without_preference_n += 1

	var active_spiders := 0
	if GameConfig.predators_on:
		for f in world.get_tree().get_nodes_in_group("flowers"):
			if is_instance_valid(f) and f.has_crab_spider:
				active_spiders += 1

	var hive: Node2D = world.hive
	var by_contents: Dictionary = {}
	for content_type in ["", "nectar", "pollen", "honey", "jelly", "brood", "corpse"]:
		by_contents[content_type] = hive.cells_holding(content_type).size()
	var sealed := 0
	for cell in hive.cells:
		if is_instance_valid(cell) and cell.is_built and cell.is_closed:
			sealed += 1

	# Live, not cumulative -- how much diggable soil is left, split by
	# whether a miner could reach it at all (is_edge) versus what the
	# player has actually queued (marked_for_mining). blocks_mined below
	# is the cumulative counterpart: how much has already come out.
	var exposed_blocks := 0
	var marked_blocks := 0
	for block in world.get_tree().get_nodes_in_group("soil_blocks"):
		if not is_instance_valid(block):
			continue
		if block.is_edge:
			exposed_blocks += 1
		if block.marked_for_mining:
			marked_blocks += 1

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
		"foraging_behaviour": {
			"orientation_flight_on": GameConfig.orientation_flight_on,
			"floral_constancy_on": GameConfig.floral_constancy_on,
			"scouting_on": GameConfig.scouting_on,
			"auto_recruitment_on": GameConfig.auto_recruitment_on,
			"tarsal_markers_on": GameConfig.tarsal_markers_on,
			"probabilistic_choice_on": GameConfig.probabilistic_choice_on,
			"handling_experience_on": GameConfig.handling_experience_on,
			"adaptive_constancy_on": GameConfig.adaptive_constancy_on,
			"scouting_now": scouting_now,
			"with_preferred_species": by_preferred_species,
			"avg_rate_with_preferred_species": rate_with_preference_sum / rate_with_preference_n if rate_with_preference_n > 0 else 0.0,
			"avg_rate_without_preferred_species": rate_without_preference_sum / rate_without_preference_n if rate_without_preference_n > 0 else 0.0,
			"entrance_mentors_waiting": hive.entrance_mentors.size(),
			"orientation_flights_total": _orientation_flights,
			"tarsal_marks_total": _tarsal_marks,
			"tarsal_rejections_total": _tarsal_rejections,
			"flower_visits_total": _flower_visits,
			"unique_flowers_visited": _flowers_visited_ids.size(),
			"recruitment_followups_total": _recruitment_followups,
			"recruit_partner_overlaps_total": _recruit_partner_overlaps,
			"foragers_settled_total": _foragers_settled,
		},
		"crab_spiders": {
			"predators_on": GameConfig.predators_on,
			"alarm_pheromone_on": GameConfig.alarm_pheromone_on,
			"recruit_suppression_on": GameConfig.crab_spider_recruit_suppression_on,
			"preferred_species": Session.crab_spider_preferred_species,
			"active_spiders": active_spiders,
		},
		"performance": _performance_snapshot(world),
		"role_outcomes": {
			"brood_feeds_total": _brood_feeds,
			"brood_hatches_total": _brood_hatches,
			"brood_hatches_by_role_mode": _brood_hatches_by_role_mode,
			"jelly_batches_total": _jelly_batches,
			"larval_deaths_total": _larval_deaths,
			"cells_completed_total": _cells_completed,
			"cells_cleaned_total": _cells_cleaned,
			"cells_evicted_total": _cells_evicted,
			"cells_restocked_total": _cells_restocked,
			"blocks_mined_total": _blocks_mined,
			"honey_batches_deposited_total": _honey_batches_deposited,
			"cells_ripened_total": _cells_ripened,
			"exposed_soil_blocks": exposed_blocks,
			"marked_soil_blocks": marked_blocks,
		},
	}


## fps and game_speed are free reads (Engine.get_frames_per_second(),
## world.current_speed) that cost nothing beyond what main.gd already
## tracks for its own HUD readout -- included on every snapshot,
## whatever the "fps" star is set to, since neither needs Perf running.
## The per-section breakdown only gets added on top when Session.perf_enabled
## is already true: perf.gd keeps those averages every frame regardless,
## so this is a dictionary read, not new measurement, and only fires when
## someone was already paying that cost for the HUD. Together this turns
## the once-an-hour snapshot into the low-cost way to see a run's
## performance pattern over its whole length, not just a single instant
## a human happened to be looking at the "fps" star.
const PERFORMANCE_SNAPSHOT_SECTIONS := 8

func _performance_snapshot(world: Node2D) -> Dictionary:
	var perf: Dictionary = {
		"fps": Engine.get_frames_per_second(),
		"game_speed": world.current_speed,
		"paused": world.get_tree().paused,
	}
	if Session.perf_enabled:
		perf["worst_frame_ms"] = Perf.last_worst_ms
		perf["p95_worst_frame_ms"] = Perf.percentile_ms(0.95)
		var sections: Dictionary = {}
		for key in Perf.top_sections(PERFORMANCE_SNAPSHOT_SECTIONS):
			sections[key] = Perf.averages[key]
		perf["top_sections_ms"] = sections
	return perf


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
