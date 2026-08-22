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
## hud.gd's role_requested signal is wired to (main.gd::_ready), so a
## combined key like "forager_nectar" behaves identically to clicking
## that HUD button. Temporarily borrows main.selected_bees since that's
## what the command function reads.
static func _do_assign_role(main: Node2D, action: Dictionary) -> void:
	var bees: Array = _resolve_bees(main, action.get("target", {}))
	var role: String = action.get("role", "")
	if bees.is_empty() or role == "":
		_log("assign_role", str(action), "rejected", "no matching bees or no role given")
		return
	var previous: Array = main.selected_bees
	main.selected_bees = bees
	main.orders_zones._on_role_requested(role)
	main.selected_bees = previous
	_log("assign_role", "%d bees -> %s" % [bees.size(), role], "accepted", "")

## Calls orders_zones._designate_one directly -- the per-cell command
## function _on_cell_designation_requested itself calls once it's worked
## out which cell(s) a click meant.
static func _do_designate_cell(main: Node2D, action: Dictionary) -> void:
	var hex: Array = action.get("hex", [])
	var cell: Node2D = _resolve_cell(main, hex)
	var content: String = action.get("content", "")
	if cell == null:
		_log("designate_cell", str(hex), "rejected", "no cell at that hex")
		return
	main.orders_zones._designate_one(cell, content)
	_log("designate_cell", "%s -> %s" % [hex, content], "accepted", "")

## Calls bee.gd's own build-target functions -- the same ones
## input_selection.gd::_place_build_cell calls once a click resolves to a
## hex. "append": true matches ctrl-click's queue_build_target; the
## default matches a plain click's set_manual_build_target.
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
	_log("queue_build", "%d bees -> %s" % [bees.size(), hex], "accepted", "")

## Same idea as _do_queue_build for miners -- bee.gd's set_mine_target /
## queue_mine_target, the functions input_selection.gd::_place_mine_target
## calls, targeting a block resolved by _resolve_soil_block above.
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
	_log("queue_mine", "%d bees -> %s" % [bees.size(), hex], "accepted", "")

## Calls DebugPanel.setting_set -- the exact function the settings-window
## checkboxes call, already covering both GameConfig and Session keys
## (see debug_panel.gd's SESSION_KEYS split), so this reaches every
## toggle/value the settings window can already reach, nothing wider.
static func _do_set_config(main: Node2D, action: Dictionary) -> void:
	var key: String = action.get("key", "")
	if key == "" or not action.has("value"):
		_log("set_config", str(action), "rejected", "missing key or value")
		return
	main.DebugPanel.setting_set(key, action["value"])
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
