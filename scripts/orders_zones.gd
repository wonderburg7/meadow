extends Node
## The nursery zone, comb overlays, cell designation and restocking
## orders, role/mode assignment, and one step of undo for designation.
## Split out of main.gd 14 Aug 2026 -- see MAIN_SPLIT_PLAN.md. Holds no
## state beyond `_designation_undo`, which nothing outside this file
## touches; reads and writes main's fields through the `main` reference.

var main: Node2D

## One step of undo for cell designation. Records what each cell was
## before the change.
var _designation_undo: Array = []

func _apply_zone_glow() -> void:
	var showing: bool = main.nursery_panel.is_open() and main.in_hive_view
	if not showing:
		_clear_zone_glow()
		return
	for cell in main.hive.cells:
		if not is_instance_valid(cell):
			continue
		if cell.is_nursery_cell():
			cell.set_zone_glow(
				true,
				main.NurseryPanel.colour_for(cell.hatch_role, cell.hatch_focus, cell.hatch_gyne),
				main.NurseryPanel.tag_for(cell.hatch_role, cell.hatch_focus, cell.hatch_gyne)
			)
		else:
			cell.set_zone_glow(false)

func _cycle_comb_overlay() -> void:
	if not main.in_hive_view:
		main.in_hive_view = true
		main.camera_view._apply_view()
	var index: int = main.COMB_OVERLAYS.find(Session.comb_overlay)
	Session.comb_overlay = main.COMB_OVERLAYS[(index + 1) % main.COMB_OVERLAYS.size()]
	_apply_comb_overlay()
	main.hud.show_warning("Comb overlay: %s. Press O again to cycle." % main.OVERLAY_NAMES[Session.comb_overlay])

func _apply_comb_overlay() -> void:
	for cell in main.hive.cells:
		if is_instance_valid(cell):
			cell.set_overlay(Session.comb_overlay)

func _remember_designations(cells: Array) -> void:
	_designation_undo = []
	for cell in cells:
		if is_instance_valid(cell):
			_designation_undo.append({
				"cell": cell,
				"designated": cell.designated_type,
				"designation_explicit": cell.designation_is_explicit,
				"keep_empty": cell.keep_empty,
				"priority": cell.nursery_priority,
			})

func _undo_last_designation() -> void:
	if _designation_undo.is_empty():
		main.hud.show_warning("Nothing to undo.")
		return
	var restored = 0
	for entry in _designation_undo:
		var cell = entry.cell
		if not is_instance_valid(cell):
			continue
		cell.set_designation(entry.designated, bool(entry.designation_explicit))
		cell.keep_empty = entry.keep_empty
		cell.nursery_priority = entry.priority
		cell.bump_display_epoch()
		restored += 1
	_designation_undo = []
	main.hud.show_warning("Undone — %d cells put back." % restored)

func _clear_zone_glow() -> void:
	for cell in main.hive.cells:
		if is_instance_valid(cell):
			cell.set_zone_glow(false)

func _on_cell_priority_requested(anchor: Node2D, tier: int) -> void:
	for cell in _cells_to_act_on(anchor):
		cell.nursery_priority = clampi(tier, 0, 2)
		cell.bump_display_epoch()
		if not cell.is_nursery_cell():
			_designate_one(cell, "brood")

func _on_cell_close_requested(anchor: Node2D, closed: bool) -> void:
	for cell in _cells_to_act_on(anchor):
		cell.set_closed(closed)

func _on_cell_fill_close_requested(anchor: Node2D) -> void:
	for cell in _cells_to_act_on(anchor):
		cell.set_fill_then_close(true)

func _restock_comb_workers() -> Array:
	return main.selected_bees.filter(func(b):
		return is_instance_valid(b) and b.role == main.Bee.Role.BUILDER
	)

func _on_restock_targets_requested(resource: String) -> void:
	var cells: Array = main.selected_cells.filter(func(c): return is_instance_valid(c))
	if cells.is_empty():
		main.hud.show_warning("Select the comb you want kept full first, then press the resource.")
		return
	for b in _restock_comb_workers():
		b.set_restock_targets(cells, resource)
		b.architect_mode = "restock"
	for cell in cells:
		_designate_one(cell, resource)
	main.input_selection._clear_cell_selection()
	main.hud.update_selection(main.selected_bees)

func _on_restock_sources_requested(allowed: bool) -> void:
	var cells: Array = main.selected_cells.filter(func(c): return is_instance_valid(c))
	if cells.is_empty():
		main.hud.show_warning("Select the comb you mean first, then press the button.")
		return
	for b in _restock_comb_workers():
		b.set_restock_sources(cells, allowed)
	main.input_selection._clear_cell_selection()
	main.hud.update_selection(main.selected_bees)

func _on_restock_clear_requested() -> void:
	for b in _restock_comb_workers():
		b.clear_restock()
	main.hud.update_selection(main.selected_bees)

func _on_role_requested(role_name: String) -> void:
	var role_id: int = main.Roles.id_for_key(role_name)
	if role_id != -1:
		_assign_role(role_id)
		return

	for role in main.Roles.ROLES:
		var prefix: String = role.key + "_"
		if not role_name.begins_with(prefix):
			continue
		_apply_mode(role.id, role_name.substr(prefix.length()))
		return

## BS-3: a role, a backup role or a cell's Raises choice is set only while
## Availability.role_query allows it. The stage part is left out here: which
## controls a Challenge shows is the HUD's lesson plan, while owning a role's
## skill is a rule of the run that holds for every caller.
func _role_permitted(role_id: int, bee = null) -> bool:
	return main.Availability.role_query(role_id, null, Session.progression, bee).available

func _assign_role(role_id: int) -> void:
	for b in main.selected_bees:
		if is_instance_valid(b) and _role_permitted(role_id, b):
			b.set_role(role_id)
	main._update_population_readout()
	main.hud.update_selection(main.selected_bees)

func _apply_mode(role_id: int, mode_key: String) -> void:
	for b in main.selected_bees:
		if not is_instance_valid(b):
			continue
		match role_id:
			main.Roles.FORAGER:
				b.set_focus(mode_key)
			main.Roles.NURSE:
				b.nurse_mode = mode_key
			main.Roles.COMB_WORKER:
				b.architect_mode = mode_key
			main.Roles.MINER:
				b.automine = not b.automine
			main.Roles.HONEY:
				b.fermenting = not b.fermenting
	main.hud.update_selection(main.selected_bees)

func _on_finish_first_requested(value: bool) -> void:
	for b in main.selected_bees:
		if is_instance_valid(b):
			b.finish_task_first = value
	main.hud.update_selection(main.selected_bees)

## Only ever offered for a single selected bee -- see hud.gd's
## _build_favourite_star.
func _on_favourite_requested(value: bool) -> void:
	for b in main.selected_bees:
		if is_instance_valid(b):
			b.is_favourite = value
	main.hud.update_selection(main.selected_bees)

func _on_secondary_role_requested(role_name: String) -> void:
	var target_role: int = main.Roles.id_for_key(role_name)
	for b in main.selected_bees:
		if is_instance_valid(b) and (target_role < 0 or _role_permitted(target_role, b)):
			b.set_secondary_role(target_role)
	main.hud.update_selection(main.selected_bees)

func _cells_to_act_on(cell: Node2D) -> Array:
	if not main.selected_cells.is_empty():
		return main.selected_cells.filter(func(c): return is_instance_valid(c))
	return [cell] if is_instance_valid(cell) else []

func _on_cell_designation_requested(anchor: Node2D, type: String) -> void:
	_remember_designations(_cells_to_act_on(anchor))
	for cell in _cells_to_act_on(anchor):
		_designate_one(cell, type)

func _designate_one(cell: Node2D, type: String) -> void:
	if not is_instance_valid(cell):
		return
	if type == "":
		cell.set_designation("")
		return

	var conflicting: bool = (
		cell.content_type != ""
		and cell.content_type != "brood"
		and cell.content_type != type
		and cell.amount > 0.0
	)
	if not conflicting:
		cell.set_designation(type)
		return

	if main.hive.has_room_elsewhere(cell.content_type, cell) 			or bool(main.Levels.get_level(Session.starting_level).get("designation_keeps_stores", false)):
		cell.set_designation(type)
	elif Session.warn_on_discard:
		main.hud.show_discard_warning(cell, type, cell.content_type, cell.amount)
	else:
		cell.clear_cell()
		cell.set_designation(type)

func _on_cell_hatch_role_requested(anchor: Node2D, role: int, focus: String, use_automine: bool) -> void:
	if role >= 0 and not _role_permitted(role):
		return
	for cell in _cells_to_act_on(anchor):
		cell.hatch_role = role
		cell.hatch_focus = focus
		cell.hatch_automine = use_automine
		cell.bump_display_epoch()
		if role >= 0 and cell.designated_type != "brood":
			_designate_one(cell, "brood")

func _on_cell_hatch_lock_requested(anchor: Node2D, locked: bool) -> void:
	for cell in _cells_to_act_on(anchor):
		cell.hatch_role_locked = locked
		cell.bump_display_epoch()

func _on_cell_empty_requested(anchor: Node2D, method: String, keep_empty: bool) -> void:
	for cell in _cells_to_act_on(anchor):
		_empty_one(cell, method, keep_empty)

func _empty_one(cell: Node2D, method: String, keep_empty: bool) -> void:
	if not is_instance_valid(cell):
		return
	_set_keep_empty(cell, keep_empty)

	if cell.content_type == "" or cell.content_type == "brood":
		return

	cell.evict_mode = "discard" if method == "discard" else "move"
	cell.evict_requested = true
	cell.bump_display_epoch()

func _on_cell_gyne_requested(anchor: Node2D, as_gyne: bool) -> void:
	for cell in _cells_to_act_on(anchor):
		cell.hatch_gyne = as_gyne
		cell.bump_display_epoch()
		if as_gyne and cell.designated_type != "brood":
			_designate_one(cell, "brood")

func _on_cell_keep_empty_requested(anchor: Node2D, keep_empty: bool) -> void:
	for cell in _cells_to_act_on(anchor):
		_set_keep_empty(cell, keep_empty)

func _set_keep_empty(cell: Node2D, keep_empty: bool) -> void:
	if not is_instance_valid(cell):
		return
	if keep_empty:
		cell.set_designation("")
	cell.keep_empty = keep_empty
	cell.bump_display_epoch()
