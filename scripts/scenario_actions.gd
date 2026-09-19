extends RefCounted
## Dev-only headless action driver for --scenario= runs. The headless
## equivalent of clicking, and the contract is
## docs/headless-run-contract.md: a
## scenario's "actions" array gives a run semantic player actions --
## assign a role, designate a cell, queue build/mine work, toggle a
## setting -- gated by day/resource/event triggers and checked with
## assertions. Every verb below calls the same command function the
## click-driven UI already calls (see each verb's comment for which),
## never a reimplementation, so a headless action follows the same rules
## a human action does. Never reachable outside a --scenario= boot -- see
## main.gd::_apply_scenario_boot_arg and its scenario_actions field.
##
## Usage: const ScenarioActions = preload("res://scripts/scenario_actions.gd")
##        ScenarioActions.run_pending(main, main.scenario_actions)
##
## Each action dict is mutated in place with "_resolved": true the tick it
## fires, so a repeat call only evaluates what's still pending -- actions
## are independent of each other (every unresolved one is checked every
## tick, in file order), not a strict sequence, so several can fire on
## the same tick. The one exception is "settle" (see _do_settle): it is a
## barrier, and nothing after it in the file runs until it has counted out
## its ticks.

const Settings = preload("res://scripts/settings_catalogue.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")
const UiLayout = preload("res://scripts/ui_layout.gd")
const Conditions = preload("res://scripts/conditions.gd")

## Fixture-facing `when` names translated to Conditions' shared vocabulary.
## The two threshold directions intentionally share one event_count/disease
## condition; _legacy_when_spec preserves each direction as a separate child.
const LEGACY_WHEN_KEY_MAP := {
	"day_at_least": "day_at_least",
	"population_at_least": "role_count",
	"event_count_at_least": "event_count", "event_count_at_most": "event_count",
	"cells_completed_at_least": "built_cells_at_least",
	"queen_alive": "queen_alive",
	"disease_at_least": "disease", "disease_at_most": "disease",
}

## Called once per _process() tick while main.scenario_active. An "assert"
## that fails ends the run (main._end_scenario_run) and stops evaluating
## the rest of this tick's actions -- everything already resolved stays
## resolved, and log_unresolved (below) records whatever never got there.
static func run_pending(main: Node2D, actions: Array) -> void:
	sample_comb_build_sites(main)
	for action in actions:
		if action.get("_resolved", false):
			continue
		if action.get("do", "") == "settle":
			if not _do_settle(action):
				return
			continue
		if not _when_met(main, action.get("when", {})):
			continue
		action["_resolved"] = true
		if action.get("do", "") == "assert":
			if not _do_assert(main, action):
				return
		else:
			_execute(main, action)


## CB-1: Session.sim_time of the last comb-builder sample.
static var _last_build_sample: float = -1.0e9
const BUILD_SAMPLE_SECONDS := 0.5

## Samples every unfinished cell's own builders and slot_users every 0.5
## simulated seconds and folds them into DiagnosticLog.comb_build_sites as
## running maxima (and one minimum), so a day of sampling allocates nothing
## per tick. Observation only: it changes no simulation state.
static func sample_comb_build_sites(main: Node2D) -> void:
	if Session.sim_time - _last_build_sample < BUILD_SAMPLE_SECONDS:
		return
	_last_build_sample = Session.sim_time
	var stats: Dictionary = DiagnosticLog.comb_build_sites
	if stats.is_empty() or main.hive == null:
		return
	stats["samples"] = int(stats["samples"]) + 1
	for cell in main.hive.cells:
		if not is_instance_valid(cell) or cell.is_built:
			continue
		var building: int = 0
		var without_slot: int = 0
		var holders: int = 0
		var distinct: int = 0
		for holder in cell.slot_users:
			if holder != null and is_instance_valid(holder):
				holders += 1
				distinct += 1
		var stand_points: Array = []
		for bee in cell.builders:
			if not is_instance_valid(bee) or bee.state != bee.State.BUILDING or bee.target_cell != cell:
				continue
			building += 1
			if not cell.slot_users.has(bee):
				without_slot += 1
			stand_points.append(bee.position)
		for i in range(stand_points.size()):
			for j in range(i + 1, stand_points.size()):
				var gap: float = stand_points[i].distance_to(stand_points[j])
				var best: float = float(stats["min_builder_spacing_px"])
				if best < 0.0 or gap < best:
					stats["min_builder_spacing_px"] = gap
		stats["max_builders_per_site"] = maxi(int(stats["max_builders_per_site"]), building)
		stats["max_slots_held"] = maxi(int(stats["max_slots_held"]), holders)
		stats["max_distinct_slots"] = maxi(int(stats["max_distinct_slots"]), distinct)
		stats["building_without_slot"] = maxi(int(stats["building_without_slot"]), without_slot)


## Called from main.gd::_end_scenario_run, before DiagnosticLog closes the
## session file. An action whose "when" never became true is exactly as
## diagnostically interesting as one that fired and was rejected: a run
## must fail loudly if an action cannot be carried out
## (docs/headless-run-contract.md).
static func log_unresolved(actions: Array) -> void:
	for action in actions:
		if action.get("_resolved", false):
			continue
		_log(action.get("do", ""), str(action), "never_fired", "run ended before its 'when' was met")


## {"do": "settle", "ticks": n} -- the one action that is a sequence point,
## and the only one that holds up the actions after it. Godot lays a
## container out on the frame *after* its content changes, so a geometry
## assertion in the same tick as the selection that changed it measures the
## previous frame's rectangle. Every LAY-5/LAY-6 assertion in
## layout_panels.json used to do exactly that and passed on the stale
## number; HC-13 shrank one panel and the stale number stopped agreeing.
## Put a settle between the action and the assertions that measure it.
##
## Returns whether the rest of this tick's actions may run.
static func _do_settle(action: Dictionary) -> bool:
	var remaining: int = int(action.get("ticks", 1))
	if remaining > 0:
		action["ticks"] = remaining - 1
		return false
	action["_resolved"] = true
	_log("settle", str(action), "accepted", "")
	return true

static func _execute(main: Node2D, action: Dictionary) -> void:
	match action.get("do", ""):
		"assign_role":
			_do_assign_role(main, action)
		"designate_cell":
			_do_designate_cell(main, action)
		"queue_build":
			_do_queue_build(main, action)
		"queue_mine":
			_do_queue_mine(main, action)
		"request_placement_tool":
			_do_request_placement_tool(main, action)
		"click_world":
			_do_click_world(main, action)
		"set_config":
			_do_set_config(main, action)
		"hatch_role":
			_do_hatch_role(main, action)
		"set_restock_order":
			_do_set_restock_order(main, action)
		"select_bees":
			_do_select_bees(main, action)
		"select_soil":
			_do_select_soil(main, action)
		"select_cell":
			_do_select_cell(main, action)
		"open_window":
			_do_open_window(main, action)
		"close_window":
			_do_close_window(main, action)
		"viewport_size":
			_do_viewport_size(main, action)
		"show_gallerin_prompt":
			_do_show_gallerin_prompt(main, action)
		"advance_challenge_stage":
			_do_advance_challenge_stage(main, action)
		"retreat_challenge_stage":
			_do_retreat_challenge_stage(main, action)
		var other:
			_log(other, str(action), "rejected", "unknown 'do' value")


# --- triggers -----------------------------------------------------

## Shared by "when" (gates an action) and "assert" (checks one without
## gating anything) -- same shape either way. Scenario fixtures retain their
## established vocabulary here, translated into Conditions' shared vocabulary
## before evaluation. Two legacy predicates remain local compatibility checks:
## food_stores_at_least deliberately means *ripe* honey (not all honey), and
## a population query without a role means every cached role bucket combined.
## An empty dict is always met, so an action with no "when" fires the very
## first tick it's checked.
static func _when_met(main: Node2D, when: Dictionary) -> bool:
	if when.is_empty():
		return true
	var spec := _legacy_when_spec(main, when)
	if spec.is_empty() and not when.is_empty():
		return false
	if when.has("challenge_stage_id"):
		if main.challenge_runner.current_stage_id() != str(when["challenge_stage_id"]):
			return false
	if when.has("selected_mine_queue_at_least"):
		if main.selected_bees.is_empty() or not is_instance_valid(main.selected_bees[0]):
			return false
		if main.selected_bees[0].mine_queue.size() < int(when["selected_mine_queue_at_least"]):
			return false
	return Conditions.met(main, spec)


## Returns Conditions' vocabulary for a legacy scenario `when` dictionary.
## `{}` means a compatibility condition failed, never a valid empty spec:
## _when_met has already handled an actually empty `when` before reaching here.
static func _legacy_when_spec(main: Node2D, when: Dictionary) -> Dictionary:
	# Keep a true evaluator condition even for a legacy `when` containing
	# only a compatibility predicate (or challenge_stage_id below).
	var spec := {"all_of": []}
	if when.has("day_at_least"):
		spec[LEGACY_WHEN_KEY_MAP["day_at_least"]] = when["day_at_least"]
	if when.has("food_stores_at_least"):
		# total("honey") includes wet mix; the old trigger, and its fixtures,
		# intentionally count only ripe honey through total_honey().
		if main.hive.total_honey() < float(when["food_stores_at_least"]):
			return {}
	if when.has("population_at_least"):
		var population: Dictionary = when["population_at_least"]
		var role_key: String = str(population.get("role", ""))
		if role_key == "":
			var total := 0
			for count in main._role_counts().values():
				total += int(count)
			if total < int(population.get("count", 0)):
				return {}
		else:
			spec[LEGACY_WHEN_KEY_MAP["population_at_least"]] = {"role": role_key, "at_least": int(population.get("count", 0))}
	if when.has("event_count_at_least") or when.has("event_count_at_most"):
		var event_conditions: Array = spec["all_of"]
		if when.has("event_count_at_least"):
			var at_least: Dictionary = when["event_count_at_least"]
			event_conditions.append({LEGACY_WHEN_KEY_MAP["event_count_at_least"]: {
				"type": at_least.get("type", ""), "subtype": at_least.get("subtype", ""),
				"at_least": int(at_least.get("count", 0)),
			}})
		if when.has("event_count_at_most"):
			var at_most: Dictionary = when["event_count_at_most"]
			event_conditions.append({LEGACY_WHEN_KEY_MAP["event_count_at_most"]: {
				"type": at_most.get("type", ""), "subtype": at_most.get("subtype", ""),
				"at_most": int(at_most.get("count", 0)),
			}})
		spec["all_of"] = event_conditions
	if when.has("cells_completed_at_least"):
		spec[LEGACY_WHEN_KEY_MAP["cells_completed_at_least"]] = when["cells_completed_at_least"]
	if when.has("queen_alive"):
		spec[LEGACY_WHEN_KEY_MAP["queen_alive"]] = when["queen_alive"]
	if when.has("disease_at_least") or when.has("disease_at_most"):
		var disease_spec := {}
		if when.has("disease_at_least"):
			disease_spec["at_least"] = when["disease_at_least"]
		if when.has("disease_at_most"):
			disease_spec["at_most"] = when["disease_at_most"]
		spec[LEGACY_WHEN_KEY_MAP["disease_at_least"]] = disease_spec
	return spec


# --- selectors ------------------------------------------------------

## Bees matching {"bee_ids": [...]} or {"current_role": key, "count": N},
## in stable bee_id order so the same selector always picks the same bees.
static func _resolve_bees(main: Node2D, target: Dictionary) -> Array:
	var bees: Array = main.get_tree().get_nodes_in_group("bees").filter(
		func(b): return is_instance_valid(b)
	)
	bees.sort_custom(func(a, b): return a.bee_id < b.bee_id)

	if target.has("any_of"):
		var picked: Array = []
		for part in target["any_of"]:
			for b in _resolve_bees(main, part):
				if not picked.has(b):
					picked.append(b)
		return picked

	if target.has("bee_ids"):
		var ids: Array = target["bee_ids"]
		return bees.filter(func(b): return ids.has(b.bee_id))

	if target.has("current_role"):
		var role_id: int = main.Roles.id_for_key(target["current_role"])
		var matches: Array = bees.filter(func(b): return b.role == role_id)
		var count: int = int(target.get("count", matches.size()))
		return matches.slice(0, count)

	return []

static func _resolve_cell(main: Node2D, hex: Array) -> Node2D:
	if hex.size() != 2:
		return null
	return main.hive.cell_at_tile(Vector2i(int(hex[0]), int(hex[1])))

## No axial lookup exists for soil blocks -- input_selection.gd::_soil_at
## finds one by click distance, which a headless action has no click to
## give it. Mirrors hive.gd::cell_at_tile's job against the "soil_blocks"
## group instead of hive.gd's occupied_tiles dictionary, since soil
## blocks aren't registered there.
static func _resolve_soil_block(main: Node2D, hex: Array) -> Node2D:
	if hex.size() != 2:
		return null
	var target := Vector2i(int(hex[0]), int(hex[1]))
	for b in main.get_tree().get_nodes_in_group("soil_blocks"):
		if is_instance_valid(b) and b.axial == target:
			return b
	return null


# --- verbs ------------------------------------------------------------

## Calls orders_zones._on_role_requested -- the exact function
## hud.gd's role_requested signal is wired to (main.gd::_ready). A plain
## key ("forager") behaves identically to clicking the Job row. A
## combined key ("forager_nectar") only ever reaches _on_role_requested
## from the real UI once a bee is already on that role -- the Doing row
## only appears for the selection's current common role (hud.gd's
## _build_doing_row) -- so clicking it in one step is a two-click human
## action (Job row, then Doing row). CHATGPT_INSIGHTS_PLAN.md's B2: a
## scenario author writing a combined key in one action expects both
## steps, so this splits it into the same two calls a human would make,
## then checks the bees actually ended up on both the role and the mode
## before logging "accepted" -- the old version logged "accepted" for a
## combined key on non-matching bees while silently changing nothing,
## since _apply_mode's role-specific setters (e.g. set_focus) no-op on a
## bee not already on that role.
static func _do_assign_role(main: Node2D, action: Dictionary) -> void:
	var bees: Array = _resolve_bees(main, action.get("target", {}))
	var role: String = action.get("role", "")
	if bees.is_empty() or role == "":
		_log("assign_role", str(action), "rejected", "no matching bees or no role given")
		return

	var role_id: int = main.Roles.id_for_key(role)
	var base_key: String = role
	var mode_key: String = ""
	if role_id == -1:
		for r in main.Roles.ROLES:
			var prefix: String = r.key + "_"
			if role.begins_with(prefix):
				role_id = r.id
				base_key = r.key
				mode_key = role.substr(prefix.length())
				break
	if role_id == -1:
		_log("assign_role", str(action), "rejected", "unknown role")
		return
	if mode_key != "":
		var mode_known := false
		for mode in main.Roles.modes_for(role_id):
			if mode.key == mode_key:
				mode_known = true
				break
		if not mode_known:
			_log("assign_role", str(action), "rejected", "unknown mode for role")
			return

	var previous: Array = main.selected_bees
	main.selected_bees = bees
	main.orders_zones._on_role_requested(base_key)
	if mode_key != "":
		main.orders_zones._on_role_requested(role)
	main.selected_bees = previous

	var bad: Array = bees.filter(func(b):
		if not is_instance_valid(b) or b.role != role_id:
			return true
		return mode_key != "" and not main.hud._mode_is_active(role_id, b, mode_key)
	)
	if not bad.is_empty():
		_log("assign_role", "%d bees -> %s" % [bees.size(), role], "rejected",
			"%d bee(s) did not end up with role/mode %s" % [bad.size(), role])
		return
	_log("assign_role", "%d bees -> %s" % [bees.size(), role], "accepted", "")

## Calls orders_zones._designate_one directly -- the per-cell command
## function _on_cell_designation_requested itself calls once it's worked
## out which cell(s) a click meant. CHATGPT_INSIGHTS_PLAN.md's B3: checks
## the cell's own designated_type afterwards, since _designate_one can
## silently no-op (a conflicting occupant with Session.warn_on_discard on
## just shows a dialog headlessly can't answer, and leaves the cell as it
## was) -- the old version logged "accepted" regardless.
static func _do_designate_cell(main: Node2D, action: Dictionary) -> void:
	var hex: Array = action.get("hex", [])
	var cell: Node2D = _resolve_cell(main, hex)
	var content: String = action.get("content", "")
	if cell == null:
		_log("designate_cell", str(hex), "rejected", "no cell at that hex")
		return
	main.orders_zones._designate_one(cell, content)
	if cell.designated_type != content:
		_log("designate_cell", "%s -> %s" % [hex, content], "rejected",
			"cell ended up designated '%s'" % cell.designated_type)
		return
	_log("designate_cell", "%s -> %s" % [hex, content], "accepted", "")

## Calls bee.gd's own build-target functions -- the same ones
## input_selection.gd::_place_build_cell calls once a click resolves to a
## hex. "append": true matches ctrl-click's queue_build_target; the
## default matches a plain click's set_manual_build_target.
## CHATGPT_INSIGHTS_PLAN.md's B3: checks each bee's own build_queue
## afterwards, so a hex that can't actually be built on (already filled,
## dug away) shows up as a rejection instead of a false "accepted" --
## set_manual_build_target/queue_build_target both queue unconditionally,
## the check only happens later when the bee actually tries to take the
## target (_take_next_build_target).
static func _do_queue_build(main: Node2D, action: Dictionary) -> void:
	var bees: Array = _resolve_bees(main, action.get("target", {}))
	var hex_arr: Array = action.get("hex", [])
	if bees.is_empty() or hex_arr.size() != 2:
		_log("queue_build", str(action), "rejected", "no matching bees or bad hex")
		return
	var hex := Vector2i(int(hex_arr[0]), int(hex_arr[1]))
	var append: bool = action.get("append", false)
	for b in bees:
		if append:
			b.queue_build_target(hex)
		else:
			b.set_manual_build_target(hex)
	var bad: Array = bees.filter(func(b):
		return not is_instance_valid(b) or not b.build_queue.has(hex)
	)
	if not bad.is_empty():
		_log("queue_build", "%d bees -> %s" % [bees.size(), hex], "rejected",
			"%d bee(s) didn't end up with that tile queued" % bad.size())
		return
	_log("queue_build", "%d bees -> %s" % [bees.size(), hex], "accepted", "")

## Same idea as _do_queue_build for miners -- bee.gd's set_mine_target /
## queue_mine_target, the functions input_selection.gd::_place_mine_target
## calls, targeting a block resolved by _resolve_soil_block above.
## CHATGPT_INSIGHTS_PLAN.md's B3: checks each bee's own mine_queue.
static func _do_queue_mine(main: Node2D, action: Dictionary) -> void:
	var bees: Array = _resolve_bees(main, action.get("target", {}))
	var hex: Array = action.get("hex", [])
	var block: Node2D = _resolve_soil_block(main, hex)
	if bees.is_empty() or block == null:
		_log("queue_mine", str(action), "rejected", "no matching bees or no soil block at that hex")
		return
	var append: bool = action.get("append", false)
	for b in bees:
		if append:
			b.queue_mine_target(block)
		else:
			b.set_mine_target(block)
	var bad: Array = bees.filter(func(b):
		return not is_instance_valid(b) or not b.mine_queue.has(block)
	)
	if not bad.is_empty():
		_log("queue_mine", "%d bees -> %s" % [bees.size(), hex], "rejected",
			"%d bee(s) didn't end up with that block queued" % bad.size())
		return
	_log("queue_mine", "%d bees -> %s" % [bees.size(), hex], "accepted", "")

## Arms a placement tool through input_selection.request_placement_tool, the
## function hud.gd's placement_tool_requested signal is wired to. `tool` is a
## PLACEMENT_TOOLS id. Rejected when the tool is unknown or nothing ends up armed.
static func _do_request_placement_tool(main: Node2D, action: Dictionary) -> void:
	var tool_id: String = str(action.get("tool", ""))
	main.input_selection.request_placement_tool(tool_id)
	if main.active_placement_tool != tool_id:
		_log("request_placement_tool", tool_id, "rejected", "tool unknown or no eligible bees selected")
		return
	_log("request_placement_tool", tool_id, "accepted", "")

## Delivers a plain left click at a world point: sets the drag start and end
## there and calls input_selection._finish_drag(false), the function a real
## mouse release reaches. `x`, `y` are local to the `view` root ("hive" or
## "meadow"); `soil_hex` [q, r] instead clicks the centre of that soil block.
static func _do_click_world(main: Node2D, action: Dictionary) -> void:
	var point: Vector2
	if action.has("soil_hex"):
		var block: Node2D = _resolve_soil_block(main, action["soil_hex"])
		if block == null:
			_log("click_world", str(action), "rejected", "no soil block at that hex")
			return
		point = block.global_position
	else:
		var root: Node2D = main.hive_root if str(action.get("view", "hive")) == "hive" else main.meadow_root
		point = root.to_global(Vector2(float(action.get("x", 0.0)), float(action.get("y", 0.0))))
	main.dragging = true
	main.drag_start = point
	main.drag_current = point
	main.input_selection._finish_drag(false)
	_log("click_world", str(action), "accepted", "")

## Calls the settings catalogue's apply_setting -- the same
## setting-plus-cascade function the settings-window checkbox handler
## calls (CHATGPT_INSIGHTS_PLAN.md B1), already covering both
## GameConfig and Session keys (see settings_catalogue.gd's
## SESSION_KEYS split) and the Prerequisites cascade, so this reaches
## every toggle/value the settings window can already reach, behaving
## exactly the same way, nothing wider. Reached directly rather than
## through main.DebugPanel: a headless run has no reason to load a
## CanvasLayer to set a number.
static func _do_set_config(_main: Node2D, action: Dictionary) -> void:
	var key: String = action.get("key", "")
	if key == "" or not action.has("value"):
		_log("set_config", str(action), "rejected", "missing key or value")
		return
	Settings.apply_setting(key, action["value"])
	UiTheme.refresh_for_setting(key)
	_log("set_config", "%s = %s" % [key, action["value"]], "accepted", "")

## Calls orders_zones._on_cell_hatch_role_requested -- the same function
## nursery_panel.gd's role buttons call once a cell is selected. Added for
## CHATGPT_INSIGHTS_PLAN.md's C4 hatch test (no way to configure a hatch
## role headlessly before this), same "call the real command function"
## pattern as every other verb here.
static func _do_hatch_role(main: Node2D, action: Dictionary) -> void:
	var hex: Array = action.get("hex", [])
	var cell: Node2D = _resolve_cell(main, hex)
	var role_key: String = action.get("role", "")
	if cell == null or role_key == "":
		_log("hatch_role", str(action), "rejected", "no cell at that hex or no role given")
		return
	var role_id: int = main.Roles.id_for_key(role_key)
	var focus: String = action.get("focus", "")
	var automine: bool = action.get("automine", false)
	main.orders_zones._on_cell_hatch_role_requested(cell, role_id, focus, automine)
	_log("hatch_role", "%s -> %s/%s" % [hex, role_key, focus], "accepted", "")

## Calls the same two restock command functions as the comb-worker panel:
## first choose the destination/resource, then the explicitly allowed source.
## The temporary selections are the headless equivalent of the player's two
## selection-and-button steps and are restored before the action is reported.
static func _do_set_restock_order(main: Node2D, action: Dictionary) -> void:
	var bees: Array = _resolve_bees(main, action.get("target", {}))
	var target_hex: Array = action.get("target_hex", [])
	var source_hex: Array = action.get("source_hex", [])
	var target_cell: Node2D = _resolve_cell(main, target_hex)
	var source_cell: Node2D = _resolve_cell(main, source_hex)
	var resource: String = action.get("resource", "")
	if bees.is_empty() or target_cell == null or source_cell == null or resource == "":
		_log("set_restock_order", str(action), "rejected", "no matching bees, named cell or resource")
		return

	var previous_bees: Array = main.selected_bees
	var previous_cells: Array = main.selected_cells
	main.selected_bees = bees
	main.selected_cells = [target_cell]
	main.orders_zones._on_restock_targets_requested(resource)
	main.selected_cells = [source_cell]
	main.orders_zones._on_restock_sources_requested(true)
	main.selected_bees = previous_bees
	main.selected_cells = previous_cells
	for cell in previous_cells:
		if is_instance_valid(cell):
			cell.set_selected(true)
	main.hud.update_selection(previous_bees)

	var bad: Array = bees.filter(func(b):
		return (
			not is_instance_valid(b)
			or b.architect_mode != "restock"
			or b.restock_resource != resource
			or not b.restock_targets.has(target_cell)
			or not b.restock_sources.has(source_cell)
		)
	)
	if not bad.is_empty() or target_cell.designated_type != resource:
		_log("set_restock_order", "%d bees: %s -> %s" % [bees.size(), source_hex, target_hex], "rejected",
			"restock target, source, resource or designation did not stick")
		return
	_log("set_restock_order", "%d bees: %s -> %s (%s)" % [bees.size(), source_hex, target_hex, resource], "accepted", "")

## Selects bees the same way a single non-additive click does --
## input_selection.gd::_finish_drag's terminal branch: clear whatever else
## was selected, mark the picked bees selected and call hud.update_selection,
## the exact call a click's selection ends on. Left selected afterwards
## (unlike _do_assign_role's temporary swap-and-restore), because LAY-5/LAY-6
## fixtures need the selection panels it opens to stay up for later asserts.
static func _do_select_bees(main: Node2D, action: Dictionary) -> void:
	var bees: Array = _resolve_bees(main, action.get("target", {}))
	if bees.is_empty():
		_log("select_bees", str(action), "rejected", "no matching bees")
		return
	main.input_selection._clear_world_object_selection()
	main.input_selection._clear_cell_selection()
	main.input_selection._clear_block_selection()
	for b in main.selected_bees:
		if is_instance_valid(b):
			b.set_selected(false)
	main.selected_bees.clear()
	for b in bees:
		if not main.selected_bees.has(b):
			b.set_selected(true)
			main.selected_bees.append(b)
	main.hud.update_selection(main.selected_bees)
	var bad: Array = bees.filter(func(b): return not is_instance_valid(b) or not main.selected_bees.has(b))
	if not bad.is_empty():
		_log("select_bees", "%d bees" % bees.size(), "rejected",
			"%d bee(s) did not end up selected" % bad.size())
		return
	_log("select_bees", "%d bees" % bees.size(), "accepted", "")

## Selects soil blocks the same way a single non-additive click does --
## input_selection.gd::_select_blocks, the function a click on a soil block
## resolves to once _finish_drag has found it. "hexes" names blocks by axial
## coordinate like queue_mine's target; omit it to pick whichever block the
## "soil_blocks" group returns first, so a fixture doesn't need to know a
## procedurally-generated map's exact layout just to reach the soil summary
## LAY-6's control_rect checks (soil_mark_btn/soil_clear_btn) need visible.
static func _do_select_soil(main: Node2D, action: Dictionary) -> void:
	var hexes: Array = action.get("hexes", [])
	var blocks: Array = []
	if hexes.is_empty():
		var all_blocks: Array = main.get_tree().get_nodes_in_group("soil_blocks").filter(
			func(b): return is_instance_valid(b)
		)
		if not all_blocks.is_empty():
			blocks.append(all_blocks[0])
	else:
		for hex in hexes:
			var block: Node2D = _resolve_soil_block(main, hex)
			if block != null:
				blocks.append(block)
	if blocks.is_empty():
		_log("select_soil", str(action), "rejected", "no soil block found")
		return
	main.input_selection._select_blocks(blocks, false)
	_log("select_soil", "%d blocks" % blocks.size(), "accepted", "")

## Selects a built comb cell the same way a single non-additive click does --
## input_selection.gd::_select_cells, the function _cell_at's result resolves
## to once a click lands on a cell. "built_index" orders the "hive_cells"
## group's built members by axial tile (q then r), so a fixture doesn't need
## to know which tile a Challenge happens to have built by the stage it's
## testing.
static func _do_select_cell(main: Node2D, action: Dictionary) -> void:
	var built_index: int = int(action.get("built_index", 0))
	var built_cells: Array = main.get_tree().get_nodes_in_group("hive_cells").filter(
		func(c): return is_instance_valid(c) and c.is_built
	)
	built_cells.sort_custom(func(a, b):
		if a.axial.x != b.axial.x:
			return a.axial.x < b.axial.x
		return a.axial.y < b.axial.y
	)
	if built_index < 0 or built_index >= built_cells.size():
		_log("select_cell", str(action), "rejected",
			"no built cell at index %d (%d built)" % [built_index, built_cells.size()])
		return
	main.input_selection._select_cells([built_cells[built_index]], false)
	_log("select_cell", "built_index %d" % built_index, "accepted", "")

## Opens one of the left-side windows or the command tray's "More…" panel,
## through the same functions their buttons call
## (main.gd wires colony_button/foraging_button to year_winter._toggle_panel,
## input_selection.gd's 'N' key does the same for nursery). "More…" has no
## extracted function -- hud.gd's more_button.pressed lambda is inlined --
## so this replicates that lambda's body against the same public fields.
static func _do_open_window(main: Node2D, action: Dictionary) -> void:
	var window_key: String = action.get("window", "")
	if window_key == "command_tray_more":
		main.hud.more_panel_open = true
		if main.hud.more_button != null:
			main.hud.more_button.set_pressed_no_signal(true)
		if main.hud.more_panel != null:
			main.hud.more_panel.visible = true
		main.hud._resize_command_tray()
		if main.hud.more_panel != null and main.hud.more_panel.visible:
			_log("open_window", window_key, "accepted", "")
		else:
			_log("open_window", window_key, "rejected", "tray 'More…' panel did not open")
		return

	if window_key == "settings":
		# The settings window is not a year_winter toggle panel. "sections"
		# names the category sections to expand, e.g. ["World & start"].
		main.debug_panel.open_to_categories(action.get("sections", []))
		if main.debug_panel.panel.visible:
			_log("open_window", window_key, "accepted", "")
		else:
			_log("open_window", window_key, "rejected", "settings window did not open")
		return

	var panel: CanvasLayer = null
	match window_key:
		"colony":
			panel = main.colony_panel
		"foraging":
			panel = main.foraging_panel
		"nursery":
			panel = main.nursery_panel
		_:
			pass
	if panel == null:
		_log("open_window", str(action), "rejected", "unknown window")
		return
	if not panel.is_open():
		main.year_winter._toggle_panel(panel)
	if not panel.is_open():
		_log("open_window", window_key, "rejected", "panel did not open")
		return
	_log("open_window", window_key, "accepted", "")

## {"do": "close_window", "window": "settings"} -- panel.visible = false
## directly, the same thing debug_panel.gd's own "Return to Main Menu"
## handler does (_on_main_menu_pressed()). Only "settings" is needed so
## far -- UI-X-4's fixture checks the bubble's ceiling grows back once the
## settings window stops sharing its column.
static func _do_close_window(main: Node2D, action: Dictionary) -> void:
	var window_key: String = action.get("window", "")
	if window_key == "settings":
		main.debug_panel.panel.visible = false
		_log("close_window", window_key, "accepted", "")
		return
	_log("close_window", str(action), "rejected", "unknown window")

## Sets the root window's size directly rather than relying on Godot's
## --resolution command-line flag, whose behaviour --headless doesn't
## guarantee. LAY-5: lets a fixture cover the three supported sizes
## (1920x1080, 1280x720, 800x600 -- UiLayout.MIN_SUPPORTED_WIDTH's floor)
## without three separate Godot boots.
static func _do_viewport_size(main: Node2D, action: Dictionary) -> void:
	var w: int = int(action.get("w", 0))
	var h: int = int(action.get("h", 0))
	if w <= 0 or h <= 0:
		_log("viewport_size", str(action), "rejected", "w and h must both be positive")
		return
	main.get_window().size = Vector2i(w, h)
	_log("viewport_size", "%dx%d" % [w, h], "accepted", "")

## {"do": "show_gallerin_prompt", "text": "..."} -- the developer trigger
## HC-14's panel_rect gap assertions need: Dr Gallerin's bubble (and its
## Dismiss/Turn-off button row) only exists on screen while a prompt is
## showing, and nothing else in a scenario fixture puts one there.
static func _do_show_gallerin_prompt(main: Node2D, action: Dictionary) -> void:
	var text: String = action.get("text", "Test prompt.")
	Session.gallerin_enabled = true
	main.gallerin_panel.visible = true
	main.gallerin_panel.show_now({"id": "scenario_prompt", "text": text, "repeatable": true})
	if main.gallerin_panel.bubble != null and main.gallerin_panel.bubble.visible:
		_log("show_gallerin_prompt", text, "accepted", "")
	else:
		_log("show_gallerin_prompt", text, "rejected", "bubble did not open")

## Advances through the Challenge's existing debug seam until its named stage
## is current. That seam calls _advance(), so every normal boundary effect,
## checkpoint, prompt, gate and marker still runs; this action never assigns
## the runner's private stage index directly.
## Mirror of _do_advance_challenge_stage: steps back through the debug
## retreat seam, so the destination stage's setup is applied at each step.
static func _do_retreat_challenge_stage(main: Node2D, action: Dictionary) -> void:
	var target_id: String = str(action.get("stage_id", ""))
	if target_id.is_empty():
		_log("retreat_challenge_stage", str(action), "rejected", "missing stage_id")
		return
	if not main.challenge_runner.active:
		_log("retreat_challenge_stage", target_id, "rejected", "no active Challenge")
		return
	var guard := 0
	while main.challenge_runner.can_debug_retreat_stage() and main.challenge_runner.current_stage_id() != target_id:
		main.challenge_runner.debug_retreat_stage()
		guard += 1
		if guard > 100:
			break
	if main.challenge_runner.current_stage_id() == target_id:
		_log("retreat_challenge_stage", target_id, "accepted", "")
	else:
		_log("retreat_challenge_stage", target_id, "rejected", "stage was not found")

static func _do_advance_challenge_stage(main: Node2D, action: Dictionary) -> void:
	var target_id: String = str(action.get("stage_id", ""))
	if target_id.is_empty():
		_log("advance_challenge_stage", str(action), "rejected", "missing stage_id")
		return
	if not main.challenge_runner.active:
		_log("advance_challenge_stage", target_id, "rejected", "no active Challenge")
		return
	var guard := 0
	while main.challenge_runner.active and main.challenge_runner.current_stage_id() != target_id:
		main.challenge_runner.debug_advance_stage()
		guard += 1
		if guard > 100:
			_log("advance_challenge_stage", target_id, "rejected", "stage was not found")
			return
	if main.challenge_runner.current_stage_id() == target_id:
		_log("advance_challenge_stage", target_id, "accepted", "")
	else:
		_log("advance_challenge_stage", target_id, "rejected", "Challenge completed before stage was reached")


# --- assertion checks -------------------------------------------------

## Not gated -- checked once, the tick its own "when" (if any) is met.
## Returns whether the run should keep going, so run_pending can stop
## evaluating the rest of this tick's actions on failure. Dispatches on
## which key the condition dict carries: "panel"/"control"/"container"/
## "root"/"no_empty_labels" each name one of the LAY-5/LAY-6 rectangle
## assertions below;
## anything else falls back to the plain trigger checks _when_met already
## covers (day_at_least and friends), unchanged.
static func _do_assert(main: Node2D, action: Dictionary) -> bool:
	var condition: Dictionary = action.get("condition", {})
	var result: Dictionary = _evaluate_assert_condition(main, condition)
	if result.get("ok", false):
		_log("assert", str(condition), "accepted", "")
		return true
	_log("assert", str(condition), "rejected", String(result.get("reason", "condition not met")))
	main._end_scenario_run("assert_failed")
	return false

static func _evaluate_assert_condition(main: Node2D, condition: Dictionary) -> Dictionary:
	if condition.has("panel"):
		return _check_panel_rect(main, condition)
	if condition.has("control"):
		return _check_control_rect(main, condition)
	if condition.has("container"):
		return _check_even_columns(main, condition)
	if condition.has("root"):
		return _check_no_collapsed_controls(main, condition)
	if condition.has("no_empty_labels"):
		return _check_no_empty_labels(main, condition)
	if _when_met(main, condition):
		return {"ok": true, "reason": ""}
	return {"ok": false, "reason": "condition not met"}

## LAY-5's panel-level check: {"panel": name, "inside_viewport": true,
## "gap_below": px, "after_panel": name, "gap": px}. `name` is one of the
## panels LAY-5/HC-14 name, each resolved to the Control whose
## get_global_rect() is the thing a player actually sees -- command_tray/
## summary are hud.gd fields, the three windows keep their PanelContainer
## behind a CanvasLayer (colony_panel.gd, foraging_panel.gd, nursery_panel.gd
## all name it "panel"), and "gallerin" is gallerin_panel.gd's speech
## bubble. An invisible panel is never asserted on by a fixture -- LAY-5
## only calls this once the panel has just been opened -- so no
## invisible-pass rule is needed here the way LAY-6's control_rect needs one.
##
## "after_panel"/"gap" (HC-14) is how two panels' shared clearance is
## proven equal without a fixture repeating the same pixel literal twice
## and trusting it stays in sync: both the summary-to-tray gap and the
## tray-to-bubble gap assert against the same PANEL_GAP value, so either
## one drifting from the other fails here rather than needing an eye.
static func _check_panel_rect(main: Node2D, condition: Dictionary) -> Dictionary:
	var name: String = condition.get("panel", "")
	var panel: Control = _resolve_named_panel(main, name)
	if panel == null:
		return {"ok": false, "reason": "unknown panel '%s'" % name}
	if not panel.visible:
		return {"ok": false, "reason": "panel '%s' is not visible" % name}
	var rect: Rect2 = panel.get_global_rect()
	var viewport_rect: Rect2 = main.get_viewport().get_visible_rect()
	if not viewport_rect.encloses(rect):
		return {"ok": false, "reason": "panel '%s' rect %s is not inside viewport %s" % [name, rect, viewport_rect]}
	if condition.has("gap_below"):
		var expected_gap: float = float(condition["gap_below"])
		var actual_gap: float = (viewport_rect.position.y + viewport_rect.size.y) - (rect.position.y + rect.size.y)
		if absf(actual_gap - expected_gap) > 1.0:
			return {"ok": false, "reason": "panel '%s' gap_below is %.1fpx, expected %.1fpx (rect %s, viewport %s)" % [name, actual_gap, expected_gap, rect, viewport_rect]}
	if condition.has("after_panel"):
		var after_name: String = condition["after_panel"]
		var after_panel: Control = _resolve_named_panel(main, after_name)
		if after_panel == null:
			return {"ok": false, "reason": "unknown panel '%s'" % after_name}
		if not after_panel.visible:
			return {"ok": false, "reason": "panel '%s' is not visible" % after_name}
		var after_rect: Rect2 = after_panel.get_global_rect()
		var expected_after_gap: float = float(condition.get("gap", 0))
		var actual_after_gap: float = rect.position.x - (after_rect.position.x + after_rect.size.x)
		if absf(actual_after_gap - expected_after_gap) > 1.0:
			return {"ok": false, "reason": "panel '%s' gap after '%s' is %.1fpx, expected %.1fpx (rect %s, after %s)" % [name, after_name, actual_after_gap, expected_after_gap, rect, after_rect]}
	## HC-8 -- "command_tray" is the one panel_rect caller whose content
	## control is reachable by a stable field (hud.command_content); this is
	## the one place that comparison is made, rather than a second height
	## helper alongside panel_rect.
	if condition.has("matches_content"):
		if name != "command_tray":
			return {"ok": false, "reason": "matches_content only supports panel 'command_tray'"}
		var content: Control = main.hud.command_content
		var expected_height: float = content.get_combined_minimum_size().y + UiLayout.panel_chrome().y
		var tolerance: float = float(condition.get("tolerance", 1.0))
		if absf(rect.size.y - expected_height) > tolerance:
			return {"ok": false, "reason": "panel '%s' height is %.1fpx, content wants %.1fpx (tolerance %.1fpx, rect %s)" % [name, rect.size.y, expected_height, tolerance, rect]}
	## UI-X-4: {"panel": name, "height": px, "tolerance": px} checks the
	## rendered height directly, for panels (like gallerin) whose height
	## comes from a fraction/ceiling rule rather than matching its content.
	if condition.has("height"):
		var expected_height2: float = float(condition["height"])
		var tolerance2: float = float(condition.get("tolerance", 1.0))
		if absf(rect.size.y - expected_height2) > tolerance2:
			return {"ok": false, "reason": "panel '%s' height is %.1fpx, expected %.1fpx (tolerance %.1fpx, rect %s)" % [name, rect.size.y, expected_height2, tolerance2, rect]}
	## UI-X-4: {"panel": name, "below_panel": other_name, "gap": px} --
	## the vertical counterpart of "after_panel"/"gap" above, for the bubble
	## clearing the settings window's bottom edge rather than two panels
	## sharing a row (Dave, 17 Sep 2026: "unless the settings window is in
	## the way ... shorten").
	if condition.has("below_panel"):
		var below_name: String = condition["below_panel"]
		var below_panel: Control = _resolve_named_panel(main, below_name)
		if below_panel == null:
			return {"ok": false, "reason": "unknown panel '%s'" % below_name}
		if not below_panel.visible:
			return {"ok": false, "reason": "panel '%s' is not visible" % below_name}
		var below_rect: Rect2 = below_panel.get_global_rect()
		var expected_below_gap: float = float(condition.get("gap", 0))
		var actual_below_gap: float = rect.position.y - (below_rect.position.y + below_rect.size.y)
		if actual_below_gap < expected_below_gap - 1.0:
			return {"ok": false, "reason": "panel '%s' gap below '%s' is %.1fpx, expected at least %.1fpx (rect %s, below %s)" % [name, below_name, actual_below_gap, expected_below_gap, rect, below_rect]}
	## UI-X-4: {"panel": name, "min_height": px} / {"max_height": px} -- a
	## one-sided bound, for acceptance criteria phrased as "taller than" or
	## "at most" rather than a single expected number.
	if condition.has("min_height"):
		var min_height: float = float(condition["min_height"])
		if rect.size.y < min_height:
			return {"ok": false, "reason": "panel '%s' height is %.1fpx, expected at least %.1fpx (rect %s)" % [name, rect.size.y, min_height, rect]}
	if condition.has("max_height"):
		var max_height: float = float(condition["max_height"])
		if rect.size.y > max_height:
			return {"ok": false, "reason": "panel '%s' height is %.1fpx, expected at most %.1fpx (rect %s)" % [name, rect.size.y, max_height, rect]}
	## UI-X-4: {"panel": "gallerin", "scroll_active": true} -- whether the
	## bubble's content is taller than the visible area it was given, i.e.
	## the ceiling actually clipped it rather than the panel hugging shorter
	## content (see ui_panel_layout.gd::apply()'s comment on that split).
	if condition.has("scroll_active"):
		if name != "gallerin":
			return {"ok": false, "reason": "scroll_active only supports panel 'gallerin'"}
		var expected_scroll: bool = bool(condition["scroll_active"])
		var scroll: ScrollContainer = main.gallerin_panel._bubble_scroll
		var content: Control = scroll.get_child(0) as Control
		var actual_scroll: bool = content != null and content.get_combined_minimum_size().y > scroll.size.y + 0.5
		if actual_scroll != expected_scroll:
			return {"ok": false, "reason": "panel 'gallerin' scroll_active is %s, expected %s" % [actual_scroll, expected_scroll]}
	return {"ok": true, "reason": ""}

static func _resolve_named_panel(main: Node2D, name: String) -> Control:
	match name:
		"command_tray":
			return main.hud.command_tray
		"summary":
			return main.hud.selection_panel
		"colony":
			return main.colony_panel.panel
		"foraging":
			return main.foraging_panel.panel
		"nursery":
			return main.nursery_panel.panel
		"gallerin":
			return main.gallerin_panel.bubble
		"settings":
			return main.debug_panel.panel
		_:
			return null

## LAY-6 change 1: {"control": "<path>", "min_size": [w, h], "inside":
## "<path>", "same_height_as": "<path>"}. An invisible control passes
## silently -- see the plan's own reasoning: visibility is what
## _rebuild_role_controls legitimately toggles, so asserting on a hidden
## control would make every fixture a list of which columns happen to be
## shown this tick. UI-X-2: {"visible": true} opts a fixture out of that
## silent pass, for the cases where a control being hidden at all -- not
## just its rect -- is the bug under test.
##
## "same_height_as" (HC-13) is the one thing a per-control minimum cannot
## say: that two neighbouring controls are the same height as each other.
## The summary panel's star and cog each took the height its own glyph's
## font metrics asked for, which no absolute pixel expectation would catch
## without also breaking every time the theme's font changed.
static func _check_control_rect(main: Node2D, condition: Dictionary) -> Dictionary:
	var path: String = condition.get("control", "")
	var node: Node = _resolve_scoped_path(main, path)
	if node == null or not (node is Control):
		return {"ok": false, "reason": "control '%s' not found" % path}
	var control: Control = node as Control
	if not control.is_visible_in_tree():
		if condition.get("visible", false):
			return {"ok": false, "reason": "control '%s' is not visible" % path}
		return {"ok": true, "reason": ""}
	if condition.has("max_leading"):
		var leading: Dictionary = _label_leading(control)
		if leading.is_empty():
			return {"ok": false, "reason": "control '%s' is not a Label" % path}
		if leading.leading > float(condition["max_leading"]):
			return {"ok": false, "reason": "control '%s' lines are %dpx apart for a %dpx font: %dpx leading, at most %s allowed" % [path, leading.pitch, leading.font_size, leading.leading, condition["max_leading"]]}
	var rect: Rect2 = control.get_global_rect()
	var min_size_arr: Array = condition.get("min_size", [0, 0])
	var expected := Vector2(float(min_size_arr[0]), float(min_size_arr[1]))
	if rect.size.x < expected.x or rect.size.y < expected.y:
		return {"ok": false, "reason": "control '%s' rect %s is smaller than minimum %s" % [path, rect, expected]}
	if condition.has("inside"):
		var inside_path: String = condition["inside"]
		var inside_node: Node = _resolve_scoped_path(main, inside_path)
		if inside_node == null or not (inside_node is Control):
			return {"ok": false, "reason": "control '%s' inside-ancestor '%s' not found" % [path, inside_path]}
		var ancestor_rect: Rect2 = (inside_node as Control).get_global_rect()
		if not ancestor_rect.encloses(rect):
			return {"ok": false, "reason": "control '%s' rect %s is not inside '%s' rect %s" % [path, rect, inside_path, ancestor_rect]}
	if condition.has("same_height_as"):
		var peer_path: String = condition["same_height_as"]
		var peer_node: Node = _resolve_scoped_path(main, peer_path)
		if peer_node == null or not (peer_node is Control):
			return {"ok": false, "reason": "control '%s' height-peer '%s' not found" % [path, peer_path]}
		var peer: Control = peer_node as Control
		if not peer.is_visible_in_tree():
			return {"ok": false, "reason": "control '%s' height-peer '%s' is not visible" % [path, peer_path]}
		var peer_height: float = peer.get_global_rect().size.y
		if absf(rect.size.y - peer_height) > 1.0:
			return {"ok": false, "reason": "control '%s' is %.1fpx tall but '%s' is %.1fpx" % [path, rect.size.y, peer_path, peer_height]}
	return {"ok": true, "reason": ""}

## "max_leading" (C-53): how far apart a Label draws consecutive list items,
## less its font size. The pitch is the font's line height plus the label's
## line_spacing and, since each new line starts a paragraph, paragraph_spacing --
## the numbers Label itself draws with, read after any theme change, so a
## spacing measured once and left stale by a text-scale change fails here.
static func _label_leading(control: Control) -> Dictionary:
	if not (control is Label):
		return {}
	var label := control as Label
	var font_size: int = label.get_theme_font_size("font_size")
	var pitch: int = (int(label.get_theme_font("font").get_height(font_size))
		+ label.get_theme_constant("line_spacing") + label.get_theme_constant("paragraph_spacing"))
	return {"font_size": font_size, "pitch": pitch, "leading": pitch - font_size}

## LAY-6 change 2: {"container": "<path>", "children": n, "tolerance": px}.
## Fails when the first n visible children's widths, or the gaps between
## them, are not equal within tolerance -- the one assertion no per-control
## minimum can express, and the one HC-1 (the tray's three columns bunched
## against its left edge) needs.
static func _check_even_columns(main: Node2D, condition: Dictionary) -> Dictionary:
	var path: String = condition.get("container", "")
	var node: Node = _resolve_scoped_path(main, path)
	if node == null or not (node is Control):
		return {"ok": false, "reason": "container '%s' not found" % path}
	var container: Control = node as Control
	var visible_children: Array = container.get_children().filter(
		func(c): return c is Control and c.is_visible_in_tree()
	)
	var n: int = int(condition.get("children", 0))
	if visible_children.size() < n:
		return {"ok": false, "reason": "container '%s' has %d visible children, expected at least %d" % [path, visible_children.size(), n]}
	var selected: Array = visible_children.slice(0, n)
	var tolerance: float = float(condition.get("tolerance", 0))

	var widths: Array = selected.map(func(c): return (c as Control).get_global_rect().size.x)
	var reference_width: float = widths[0]
	for w in widths:
		if absf(w - reference_width) > tolerance:
			return {"ok": false, "reason": "container '%s' columns have uneven widths %s (tolerance %.1fpx)" % [path, widths, tolerance]}

	if n >= 2:
		var gaps: Array = []
		for i in range(n - 1):
			var left_rect: Rect2 = (selected[i] as Control).get_global_rect()
			var right_rect: Rect2 = (selected[i + 1] as Control).get_global_rect()
			gaps.append(right_rect.position.x - (left_rect.position.x + left_rect.size.x))
		var reference_gap: float = gaps[0]
		for g in gaps:
			if absf(g - reference_gap) > tolerance:
				return {"ok": false, "reason": "container '%s' columns have uneven gaps %s (tolerance %.1fpx)" % [path, gaps, tolerance]}

	return {"ok": true, "reason": ""}

## LAY-6 change 4: {"root": "<path>"}. Walks every visible Button/MenuButton
## under root and fails on any under 8x8px -- the sweep that catches the
## next collapsed control nobody named an assertion for, on top of the
## named control_rect checks above. Geometry only, never colour/font/
## stylebox -- HC-3's flat "Change to…" button is a drawing defect this
## sweep does not and cannot see; leave that one to a screenshot.
static func _check_no_collapsed_controls(main: Node2D, condition: Dictionary) -> Dictionary:
	var path: String = condition.get("root", "")
	var node: Node = _resolve_scoped_path(main, path)
	if node == null:
		return {"ok": false, "reason": "root '%s' not found" % path}
	var collapsed: Array = []
	_collect_collapsed_controls(node, collapsed)
	if not collapsed.is_empty():
		return {"ok": false, "reason": "collapsed controls under '%s': %s" % [path, collapsed]}
	return {"ok": true, "reason": ""}

## HC-13: {"no_empty_labels": "<path>"}. Fails on any visible Label under
## root whose text is empty. An empty Godot Label still reports a full line
## of font height as its minimum, so three of them are a band of dead space
## the player sees and no rectangle assertion names -- and stating the
## defect directly beats an absolute panel height that would have to be
## re-measured every time the theme's font changed.
static func _check_no_empty_labels(main: Node2D, condition: Dictionary) -> Dictionary:
	var path: String = condition.get("no_empty_labels", "")
	var node: Node = _resolve_scoped_path(main, path)
	if node == null:
		return {"ok": false, "reason": "no_empty_labels root '%s' not found" % path}
	var empties: Array = []
	_collect_empty_labels(node, empties)
	if not empties.is_empty():
		return {"ok": false, "reason": "visible labels with no text under '%s': %s" % [path, empties]}
	return {"ok": true, "reason": ""}

static func _collect_empty_labels(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is Label and (child as Control).is_visible_in_tree() and (child as Label).text.strip_edges() == "":
			out.append(String(child.get_path()))
		_collect_empty_labels(child, out)

static func _collect_collapsed_controls(node: Node, out: Array) -> void:
	for child in node.get_children():
		if (child is Button or child is MenuButton) and (child as Control).is_visible_in_tree():
			var rect: Rect2 = (child as Control).get_global_rect()
			if rect.size.x < 8.0 or rect.size.y < 8.0:
				out.append("%s (%s)" % [child.get_path(), rect])
		# A wrapping label squeezed to a glyph's width reads one letter per
		# line: its minimum width is about zero, so a container without an
		# expand flag gives it nothing (C-49; docs/known-pitfalls.md).
		elif child is Label and (child as Label).is_visible_in_tree() 				and (child as Label).autowrap_mode != TextServer.AUTOWRAP_OFF 				and (child as Label).text != "":
			var label_rect: Rect2 = (child as Label).get_global_rect()
			if label_rect.size.x < 24.0:
				out.append("%s (%s, wrapping label)" % [child.get_path(), label_rect])
		_collect_collapsed_controls(child, out)

## Resolves a control_rect/even_columns/no_collapsed_controls path against a
## small allowlist of named roots, so a fixture can only reach the parts of
## the scene tree LAY-6 was written to check, never an arbitrary node.
## "<root>" alone returns the root; "<root>/<rest>" resolves <rest> under it
## with the ordinary get_node_or_null.
static func _resolve_scoped_path(main: Node2D, path: String) -> Node:
	if path == "":
		return null
	var segments: Array = path.split("/")
	var root_name: String = segments[0]
	var root: Node = null
	match root_name:
		"hud":
			root = main.hud
		"selection_panel":
			root = main.hud.selection_panel
		"command_tray":
			root = main.hud.command_tray
		"gallerin_panel":
			root = main.gallerin_panel
		"settings":
			root = main.debug_panel.panel
		_:
			return null
	if root == null or segments.size() == 1:
		return root
	# "settings/**/ControlsHelp": a named control anywhere under the root, for
	# panels built from nested containers whose own names are incidental.
	if segments.size() == 3 and segments[1] == "**":
		return root.find_child(segments[2], true, false)
	return root.get_node_or_null("/".join(segments.slice(1)))

static func _log(do: String, target_desc: String, result: String, reason: String) -> void:
	DiagnosticLog.log_action(do, target_desc, result, reason)
