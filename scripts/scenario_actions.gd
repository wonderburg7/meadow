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
## the same tick.

const Settings = preload("res://scripts/settings_catalogue.gd")

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
## diagnostically interesting as one that fired and was rejected: a run
## must fail loudly if an action cannot be carried out
## (docs/headless-run-contract.md).
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
		"set_restock_order":
			_do_set_restock_order(main, action)
		"select_bees":
			_do_select_bees(main, action)
		"select_soil":
			_do_select_soil(main, action)
		"open_window":
			_do_open_window(main, action)
		"viewport_size":
			_do_viewport_size(main, action)
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
	if when.has("event_count_at_most"):
		var spec: Dictionary = when["event_count_at_most"]
		if DiagnosticLog.event_count(spec.get("type", ""), spec.get("subtype", "")) > int(spec.get("count", 0)):
			return false
	if when.has("cells_completed_at_least") and DiagnosticLog.cell_completed_count() < int(when["cells_completed_at_least"]):
		return false
	if when.has("queen_alive"):
		var queen_alive: bool = main.queen != null and is_instance_valid(main.queen) and not main.colony_lost
		if queen_alive != bool(when["queen_alive"]):
			return false
	if when.has("disease_at_least"):
		if main.season == null or not is_instance_valid(main.season) or main.season.disease < float(when["disease_at_least"]):
			return false
	if when.has("disease_at_most"):
		if main.season == null or not is_instance_valid(main.season) or main.season.disease > float(when["disease_at_most"]):
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


# --- assertion checks -------------------------------------------------

## Not gated -- checked once, the tick its own "when" (if any) is met.
## Returns whether the run should keep going, so run_pending can stop
## evaluating the rest of this tick's actions on failure. Dispatches on
## which key the condition dict carries: "panel"/"control"/"container"/
## "root" each name one of the LAY-5/LAY-6 rectangle assertions below;
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
	if _when_met(main, condition):
		return {"ok": true, "reason": ""}
	return {"ok": false, "reason": "condition not met"}

## LAY-5's panel-level check: {"panel": name, "inside_viewport": true,
## "gap_below": px}. `name` is one of the five panels LAY-5 names, each
## resolved to the Control whose get_global_rect() is the thing a player
## actually sees -- command_tray/summary are hud.gd fields, the three
## windows keep their PanelContainer behind a CanvasLayer (colony_panel.gd,
## foraging_panel.gd, nursery_panel.gd all name it "panel"). An invisible
## panel is never asserted on by a fixture -- LAY-5 only calls this once
## the panel has just been opened -- so no invisible-pass rule is needed
## here the way LAY-6's control_rect needs one.
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
		_:
			return null

## LAY-6 change 1: {"control": "<path>", "min_size": [w, h], "inside":
## "<path>"}. An invisible control passes silently -- see the plan's own
## reasoning: visibility is what _rebuild_role_controls legitimately
## toggles, so asserting on a hidden control would make every fixture a
## list of which columns happen to be shown this tick.
static func _check_control_rect(main: Node2D, condition: Dictionary) -> Dictionary:
	var path: String = condition.get("control", "")
	var node: Node = _resolve_scoped_path(main, path)
	if node == null or not (node is Control):
		return {"ok": false, "reason": "control '%s' not found" % path}
	var control: Control = node as Control
	if not control.is_visible_in_tree():
		return {"ok": true, "reason": ""}
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
	return {"ok": true, "reason": ""}

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

static func _collect_collapsed_controls(node: Node, out: Array) -> void:
	for child in node.get_children():
		if (child is Button or child is MenuButton) and (child as Control).is_visible_in_tree():
			var rect: Rect2 = (child as Control).get_global_rect()
			if rect.size.x < 8.0 or rect.size.y < 8.0:
				out.append("%s (%s)" % [child.get_path(), rect])
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
		_:
			return null
	if root == null or segments.size() == 1:
		return root
	return root.get_node_or_null("/".join(segments.slice(1)))

static func _log(do: String, target_desc: String, result: String, reason: String) -> void:
	DiagnosticLog.log_action(do, target_desc, result, reason)
