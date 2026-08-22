extends RefCounted
## Dev-only headless action driver for --scenario= runs. Extends
## AI_PLAYTEST_PLAN.md's harness with the piece insights_from_ChatGPT.md's
## 22 Aug 2026 "headless equivalent of clicking" entry recommended: a
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
## the same tick.

## Called once per _process() tick while main.scenario_active. An "assert"
## that fails ends the run (main._end_scenario_run) and stops evaluating
## the rest of this tick's actions -- everything already resolved stays
## resolved, and log_unresolved (below) records whatever never got there.
static func run_pending(main: Node2D, actions: Array) -> void:
	for action in actions:
		if action.get("_resolved", false):
			continue
		if not _when_met(main, action.get("when", {})):
			continue
		action["_resolved"] = true
		if action.get("do", "") == "assert":
			if not _do_assert(main, action):
				return
		else:
			_execute(main, action)


## Called from main.gd::_end_scenario_run, before DiagnosticLog closes the
## session file. An action whose "when" never became true is exactly as
## diagnostically interesting as one that fired and was rejected --
## insights_from_ChatGPT.md's recommendation #4/#5 ("a run should fail
## loudly if an action cannot be carried out").
static func log_unresolved(actions: Array) -> void:
	for action in actions:
		if action.get("_resolved", false):
			continue
		_log(action.get("do", ""), str(action), "never_fired", "run ended before its 'when' was met")


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
		"set_config":
			_do_set_config(main, action)
		"hatch_role":
			_do_hatch_role(main, action)
		var other:
			_log(other, str(action), "rejected", "unknown 'do' value")


# --- triggers -----------------------------------------------------

## Shared by "when" (gates an action) and "assert" (checks one without
## gating anything) -- same shape either way. An empty dict is always met,
## so an action with no "when" fires the very first tick it's checked.
static func _when_met(main: Node2D, when: Dictionary) -> bool:
	if when.is_empty():
		return true
	if when.has("day_at_least") and main.day < int(when["day_at_least"]):
		return false
	if when.has("food_stores_at_least") and main.hive.total_honey() < float(when["food_stores_at_least"]):
		return false
	if when.has("population_at_least"):
		var spec: Dictionary = when["population_at_least"]
		if _population(main, spec.get("role", "")) < int(spec.get("count", 0)):
			return false
	if when.has("event_count_at_least"):
		var spec: Dictionary = when["event_count_at_least"]
		if DiagnosticLog.event_count(spec.get("type", ""), spec.get("subtype", "")) < int(spec.get("count", 0)):
			return false
	if when.has("cells_completed_at_least") and DiagnosticLog.cell_completed_count() < int(when["cells_completed_at_least"]):
		return false
	if when.has("queen_alive"):
		var queen_alive: bool = main.queen != null and is_instance_valid(main.queen) and not main.colony_lost
		if queen_alive != bool(when["queen_alive"]):
			return false
	return true

static func _population(main: Node2D, role_key: String) -> int:
	var bees: Array = main.get_tree().get_nodes_in_group("bees")
	if role_key == "":
		return bees.size()
	var role_id: int = main.Roles.id_for_key(role_key)
	var count := 0
	for b in bees:
		if is_instance_valid(b) and b.role == role_id:
			count += 1
	return count


# --- selectors ------------------------------------------------------

## Bees matching {"bee_ids": [...]} or {"current_role": key, "count": N},
## in stable bee_id order so the same selector always picks the same bees.
static func _resolve_bees(main: Node2D, target: Dictionary) -> Array:
	var bees: Array = main.get_tree().get_nodes_in_group("bees").filter(
		func(b): return is_instance_valid(b)
	)
	bees.sort_custom(func(a, b): return a.bee_id < b.bee_id)

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

## Calls DebugPanel.apply_setting -- the same setting-plus-cascade function
## the settings-window checkbox handler calls (CHATGPT_INSIGHTS_PLAN.md
## B1), already covering both GameConfig and Session keys (see
## debug_panel.gd's SESSION_KEYS split) and the Prerequisites cascade, so
## this reaches every toggle/value the settings window can already reach,
## behaving exactly the same way, nothing wider.
static func _do_set_config(main: Node2D, action: Dictionary) -> void:
	var key: String = action.get("key", "")
	if key == "" or not action.has("value"):
		_log("set_config", str(action), "rejected", "missing key or value")
		return
	main.DebugPanel.apply_setting(key, action["value"])
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

## Not gated -- checked once, the tick its own "when" (if any) is met.
## Returns whether the run should keep going, so run_pending can stop
## evaluating the rest of this tick's actions on failure.
static func _do_assert(main: Node2D, action: Dictionary) -> bool:
	var condition: Dictionary = action.get("condition", {})
	if _when_met(main, condition):
		_log("assert", str(condition), "accepted", "")
		return true
	_log("assert", str(condition), "rejected", "condition not met")
	main._end_scenario_run("assert_failed")
	return false

static func _log(do: String, target_desc: String, result: String, reason: String) -> void:
	DiagnosticLog.log_action(do, target_desc, result, reason)
