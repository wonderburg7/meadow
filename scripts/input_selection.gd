extends Node
## Mouse and keyboard input, selecting bees/cells/soil, the "click a spot"
## placement modes, and drawing the selection box and a bee's orders.
## Split out of main.gd 14 Aug 2026 -- see MAIN_SPLIT_PLAN.md. Holds no
## state; reads and writes main's fields through the `main` reference.

var main: Node2D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				main.camera_view._toggle_pause()
			KEY_TAB:
				main.camera_view._toggle_view()
			KEY_C:
				main.year_winter._toggle_panel(main.colony_panel)
			KEY_N:
				main.year_winter._toggle_panel(main.nursery_panel)
			KEY_F:
				main.camera_view._zoom_to_fit()
			KEY_O:
				main.orders_zones._cycle_comb_overlay()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
				var slot: int = event.keycode - KEY_0
				if event.ctrl_pressed:
					main.camera_view._save_control_group(slot)
				else:
					main.camera_view._recall_control_group(slot)
			KEY_Z:
				if event.ctrl_pressed:
					main.orders_zones._undo_last_designation()

	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed and not main.camera_view._pointer_over_ui():
					main.camera_view._zoom_by(1.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed and not main.camera_view._pointer_over_ui():
					main.camera_view._zoom_by(1.0 / 1.1)
			MOUSE_BUTTON_LEFT:
				if event.pressed and main.camera_view._pointer_over_ui():
					pass
				elif event.pressed:
					main.dragging = true
					main.drag_start = main.get_global_mouse_position()
					main.drag_current = main.drag_start
				else:
					_finish_drag(event.shift_pressed, event.ctrl_pressed)
			MOUSE_BUTTON_MIDDLE:
				main.panning = event.pressed
				main.pan_anchor = event.position
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					_issue_command(main.get_global_mouse_position())

	elif event is InputEventMouseMotion:
		if main.panning:
			var cam := main.camera_view._active_camera()
			cam.position -= (event.position - main.pan_anchor) / cam.zoom.x
			main.pan_anchor = event.position
		elif main.dragging:
			main.drag_current = main.get_global_mouse_position()

func _finish_drag(additive: bool, add_to_group_selection: bool = false) -> void:
	if not main.dragging:
		return
	main.dragging = false
	main.selection_layer.queue_redraw()

	if main.awaiting_build_cell:
		_place_build_cell(main.drag_start, add_to_group_selection)
		return
	if main.awaiting_mine_target:
		_place_mine_target(main.drag_start, add_to_group_selection)
		return
	if main.awaiting_keep_clear:
		_place_keep_clear(main.drag_start, add_to_group_selection)
		return
	if main.awaiting_home_cell:
		_place_home_cell(main.drag_start)
		return
	if main.awaiting_mine_home:
		_place_mine_home(main.drag_start)
		return
	if main.awaiting_forage_start:
		_place_forage_start(main.drag_start)
		return
	if main.awaiting_floral_preference:
		_place_floral_preference(main.drag_start)
		return

	var box := Rect2(main.drag_start, main.drag_current - main.drag_start).abs()
	var picked: Array = []
	if box.size.length() < 6.0:
		var bee := _bee_at(main.drag_start)
		if bee:
			picked.append(bee)
		elif main.in_hive_view:
			var cell := _cell_at(main.drag_start)
			if cell:
				_select_cells([cell], add_to_group_selection)
				return
			var block := _soil_at(main.drag_start)
			if block:
				_select_blocks([block], add_to_group_selection)
				return
			_clear_cell_selection()
			_clear_block_selection()
		else:
			var flower := main.world_building._flower_at(main.drag_start)
			if flower:
				main.hud.show_flower_popup(flower, main.get_viewport().get_mouse_position())
				return
			var obstacle := main.world_building._obstacle_at(main.drag_start)
			if obstacle:
				main.hud.show_obstacle_popup(obstacle, main.get_viewport().get_mouse_position())
				return
	else:
		for b in _bees_in_current_view():
			if box.has_point(b.global_position):
				picked.append(b)

		if picked.is_empty() and main.in_hive_view:
			var boxed_cells: Array = []
			for c in get_tree().get_nodes_in_group("hive_cells"):
				if is_instance_valid(c) and box.has_point(c.global_position):
					boxed_cells.append(c)
			if not boxed_cells.is_empty():
				_select_cells(boxed_cells, add_to_group_selection)
				return

			var boxed_blocks: Array = []
			for b in get_tree().get_nodes_in_group("soil_blocks"):
				if is_instance_valid(b) and box.has_point(b.global_position):
					boxed_blocks.append(b)
			if not boxed_blocks.is_empty():
				_select_blocks(boxed_blocks, add_to_group_selection)
				return

	if not picked.is_empty():
		_clear_cell_selection()
		_clear_block_selection()

	if not additive:
		for b in main.selected_bees:
			if is_instance_valid(b):
				b.set_selected(false)
		main.selected_bees.clear()

	for b in picked:
		if not main.selected_bees.has(b):
			b.set_selected(true)
			main.selected_bees.append(b)

	main.hud.update_selection(main.selected_bees)

func _select_cells(cells: Array, additive: bool) -> void:
	_clear_block_selection()
	if not additive:
		_clear_cell_selection()
	for cell in cells:
		if not is_instance_valid(cell):
			continue
		if main.selected_cells.has(cell):
			if additive:
				cell.set_selected(false)
				main.selected_cells.erase(cell)
			continue
		cell.set_selected(true)
		main.selected_cells.append(cell)

	if main.selected_cells.is_empty():
		return
	main.hud.show_cell_popup(main.selected_cells[0], main.get_viewport().get_mouse_position(), main.selected_cells.size())

func _clear_cell_selection() -> void:
	for cell in main.selected_cells:
		if is_instance_valid(cell):
			cell.set_selected(false)
	main.selected_cells.clear()

func _select_blocks(blocks: Array, additive: bool) -> void:
	_clear_cell_selection()
	if not additive:
		_clear_block_selection()
	for block in blocks:
		if not is_instance_valid(block):
			continue
		if main.selected_blocks.has(block):
			if additive:
				block.set_selected(false)
				main.selected_blocks.erase(block)
			continue
		block.set_selected(true)
		main.selected_blocks.append(block)

	if main.selected_blocks.is_empty():
		return
	var reachable := 0
	for block in main.selected_blocks:
		if main.hive.mine_stand_hex(block) != null:
			reachable += 1
	main.hud.show_soil_popup(main.selected_blocks.size(), reachable, main.get_viewport().get_mouse_position())

func _clear_block_selection() -> void:
	for block in main.selected_blocks:
		if is_instance_valid(block):
			block.set_selected(false)
	main.selected_blocks.clear()

func _on_soil_mark_requested(mark: bool) -> void:
	for block in main.selected_blocks:
		if is_instance_valid(block):
			block.set_marked(mark)

func _bees_in_current_view() -> Array:
	var root := main.hive_root if main.in_hive_view else main.meadow_root
	return get_tree().get_nodes_in_group("bees").filter(func(b): return b.get_parent() == root)

func _bee_at(point: Vector2) -> Node2D:
	for b in _bees_in_current_view():
		if b.global_position.distance_to(point) <= b.click_radius:
			return b
	return null

func _cell_at(point: Vector2) -> Node2D:
	for c in get_tree().get_nodes_in_group("hive_cells"):
		if is_instance_valid(c) and c.global_position.distance_to(point) <= c.cell_size:
			return c
	return null

func _soil_at(point: Vector2) -> Node2D:
	for b in get_tree().get_nodes_in_group("soil_blocks"):
		if is_instance_valid(b) and b.global_position.distance_to(point) <= b.block_size:
			return b
	return null

func _hex_at(global_point: Vector2) -> Vector2i:
	var local_point: Vector2 = main.hive_root.to_local(global_point)
	return main.Shapes.pixel_to_hex(local_point - main.hive.comb_centre, GameConfig.hive_cell_spacing)

func _place_build_cell(global_point: Vector2, keep_adding: bool) -> void:
	var hex: Vector2i = _hex_at(global_point)
	for b in main.pending_builder_bees:
		if not is_instance_valid(b):
			continue
		if keep_adding:
			b.queue_build_target(hex)
		else:
			b.set_manual_build_target(hex)
	if keep_adding:
		return
	main.awaiting_build_cell = false
	main.pending_builder_bees = []

func _on_build_cell_requested() -> void:
	main.pending_builder_bees = main.selected_bees.filter(func(b): return is_instance_valid(b) and b.role == main.Bee.Role.BUILDER)
	if main.pending_builder_bees.is_empty():
		return
	main.awaiting_build_cell = true
	_ensure_hive_view()

func _place_mine_target(global_point: Vector2, keep_adding: bool) -> void:
	var block := _soil_at(global_point)
	if block != null:
		for b in main.pending_mine_target_bees:
			if not is_instance_valid(b):
				continue
			if keep_adding:
				b.queue_mine_target(block)
			else:
				b.set_mine_target(block)
	if keep_adding:
		return
	main.awaiting_mine_target = false
	main.pending_mine_target_bees = []

func _on_mine_target_requested() -> void:
	main.pending_mine_target_bees = main.selected_bees.filter(func(b): return is_instance_valid(b) and b.role == main.Bee.Role.MINER)
	if main.pending_mine_target_bees.is_empty():
		return
	main.awaiting_mine_target = true
	_ensure_hive_view()

func _place_keep_clear(global_point: Vector2, keep_adding: bool) -> void:
	var hex: Vector2i = _hex_at(global_point)
	if main.hive.tile_is_walkable(hex):
		main.hive.set_keep_clear(hex, not main.hive.is_keep_clear(hex))
	if keep_adding:
		return
	main.awaiting_keep_clear = false

func _on_keep_clear_requested() -> void:
	main.awaiting_keep_clear = true
	_ensure_hive_view()

func _place_home_cell(global_point: Vector2) -> void:
	main.awaiting_home_cell = false
	var local_point: Vector2 = main.hive_root.to_local(global_point)
	var hex: Vector2i = main.Shapes.pixel_to_hex(local_point - main.hive.comb_centre, GameConfig.hive_cell_spacing)
	for b in main.pending_home_bees:
		if is_instance_valid(b):
			b.set_home_hex(hex)
	main.pending_home_bees = []
	main.hud.update_selection(main.selected_bees)

func _on_home_cell_requested() -> void:
	main.pending_home_bees = main.selected_bees.filter(func(b): return is_instance_valid(b) and b.role == main.Bee.Role.BUILDER)
	if main.pending_home_bees.is_empty():
		return
	main.awaiting_home_cell = true
	if not main.in_hive_view:
		main.in_hive_view = true
		main.camera_view._apply_view()

func _place_mine_home(global_point: Vector2) -> void:
	main.awaiting_mine_home = false
	var local_point: Vector2 = main.hive_root.to_local(global_point)
	var hex: Vector2i = main.Shapes.pixel_to_hex(local_point - main.hive.comb_centre, GameConfig.hive_cell_spacing)
	for b in main.pending_mine_bees:
		if is_instance_valid(b):
			b.set_mine_home_hex(hex)
	main.pending_mine_bees = []
	main.hud.update_selection(main.selected_bees)

func _on_mine_home_requested() -> void:
	main.pending_mine_bees = main.selected_bees.filter(func(b): return is_instance_valid(b) and b.role == main.Bee.Role.MINER)
	if main.pending_mine_bees.is_empty():
		return
	main.awaiting_mine_home = true
	if not main.in_hive_view:
		main.in_hive_view = true
		main.camera_view._apply_view()

func _place_forage_start(global_point: Vector2) -> void:
	main.awaiting_forage_start = false
	var meadow_point: Vector2 = main.meadow_root.to_local(global_point)
	for b in main.pending_forage_bees:
		if is_instance_valid(b):
			b.set_forage_start_point(meadow_point)
	main.pending_forage_bees = []

func _place_floral_preference(global_point: Vector2) -> void:
	main.awaiting_floral_preference = false
	var flower := main.world_building._flower_at(global_point)
	if flower:
		for b in main.pending_preference_bees:
			if is_instance_valid(b):
				b.set_preferred_species(flower.species_name)
		main.hud.update_selection(main.selected_bees)
	main.pending_preference_bees = []

func _issue_command(world_point: Vector2) -> void:
	if main.selected_bees.is_empty():
		return
	var flower := main.world_building._flower_at(world_point) if not main.in_hive_view else null
	for b in main.selected_bees:
		if not is_instance_valid(b):
			continue
		if flower:
			b.command_collect_from(flower)
		else:
			b.command_move_to(world_point)

func _on_focus_requested(type: String) -> void:
	for b in main.selected_bees:
		if is_instance_valid(b):
			b.set_focus(type)
	main.hud.update_selection(main.selected_bees)

func _on_role_selection_requested(role: int, focus: String) -> void:
	for b in main.selected_bees:
		if is_instance_valid(b):
			b.set_selected(false)
	main.selected_bees.clear()

	for b in get_tree().get_nodes_in_group("bees"):
		if not is_instance_valid(b) or b.role != role:
			continue
		if focus != "" and b.resource_type != focus:
			continue
		b.set_selected(true)
		main.selected_bees.append(b)

	main.hud.update_selection(main.selected_bees)

func _on_forage_start_point_requested() -> void:
	main.pending_forage_bees = main.selected_bees.filter(func(b): return is_instance_valid(b) and b.role == main.Bee.Role.FORAGER)
	if main.pending_forage_bees.is_empty():
		return
	main.awaiting_forage_start = true
	if main.in_hive_view:
		main.in_hive_view = false
		main.camera_view._apply_view()

func _on_floral_preference_requested() -> void:
	main.pending_preference_bees = main.selected_bees.filter(func(b): return is_instance_valid(b) and b.role == main.Bee.Role.FORAGER)
	if main.pending_preference_bees.is_empty():
		return
	main.awaiting_floral_preference = true
	if main.in_hive_view:
		main.in_hive_view = false
		main.camera_view._apply_view()

func _ensure_hive_view() -> void:
	if not main.in_hive_view:
		main.in_hive_view = true
		main.camera_view._apply_view()

func _draw_selection_box() -> void:
	Perf.begin("draw")
	if main.dragging:
		var box := Rect2(main.drag_start, main.drag_current - main.drag_start).abs()
		main.selection_layer.draw_rect(box, Color(0.2, 1.0, 0.4, 0.15), true)
		main.selection_layer.draw_rect(box, Color(0.2, 1.0, 0.4, 0.9), false, 2.0)

	if not main.in_hive_view:
		for b in main.selected_bees:
			if is_instance_valid(b) and b.role == main.Bee.Role.FORAGER and b.has_forage_start_point():
				_draw_start_point_marker(b.forage_start_point)
		Perf.end("draw")
		return

	_draw_hive_orders()
	Perf.end("draw")

func _draw_hive_orders() -> void:
	var any_architect := false
	for b in main.selected_bees:
		if not is_instance_valid(b):
			continue
		if b.role == main.Bee.Role.BUILDER:
			any_architect = true
			_draw_order_chain(b, _build_queue_points(b), main.BUILD_ORDER_COLOUR)
		elif b.role == main.Bee.Role.MINER:
			_draw_order_chain(b, _mine_queue_points(b), main.MINE_ORDER_COLOUR)

	if any_architect or main.awaiting_keep_clear:
		for hex in main.hive.keep_clear_tiles.keys():
			_draw_tile_outline(_tile_centre(hex), main.KEEP_CLEAR_COLOUR, 2.0, true)

func _build_queue_points(bee: Node2D) -> Array:
	var points: Array = []
	for hex in bee.build_queue:
		points.append(_tile_centre(hex))
	return points

func _mine_queue_points(bee: Node2D) -> Array:
	var points: Array = []
	for block in bee.mine_queue:
		if is_instance_valid(block):
			points.append(main.hive_root.to_global(block.position))
	return points

func _draw_order_chain(bee: Node2D, points: Array, colour: Color) -> void:
	if points.is_empty():
		return
	var previous: Vector2 = bee.global_position
	for i in range(points.size()):
		var point: Vector2 = points[i]
		main.selection_layer.draw_line(previous, point, Color(colour.r, colour.g, colour.b, 0.35), 1.5)
		_draw_tile_outline(point, colour, 2.0, false)
		previous = point

func _draw_tile_outline(centre: Vector2, colour: Color, width: float, dashed: bool) -> void:
	var corners: PackedVector2Array = main.Shapes.hexagon_points(GameConfig.hive_cell_size + 1.0)
	for i in range(6):
		if dashed and i % 2 == 1:
			continue
		main.selection_layer.draw_line(
			centre + corners[i], centre + corners[(i + 1) % 6], colour, width
		)

func _tile_centre(hex: Vector2i) -> Vector2:
	return main.hive_root.to_global(
		main.hive.comb_centre + main.Shapes.hex_to_pixel(hex.x, hex.y, GameConfig.hive_cell_spacing)
	)

func _draw_start_point_marker(point: Vector2) -> void:
	var marker_color := Color(0.2, 1.0, 0.4, 0.95)
	main.selection_layer.draw_circle(point, 9.0, Color(0.2, 1.0, 0.4, 0.2))
	main.selection_layer.draw_arc(point, 9.0, 0.0, TAU, 24, marker_color, 2.5)
	main.selection_layer.draw_line(point + Vector2(-6, 0), point + Vector2(6, 0), marker_color, 2.0)
	main.selection_layer.draw_line(point + Vector2(0, -6), point + Vector2(0, 6), marker_color, 2.0)
