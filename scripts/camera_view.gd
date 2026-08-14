extends Node
## Cameras, pan/zoom, the meadow/hive view toggle, control groups and the
## speed controls. Split out of main.gd 14 Aug 2026 -- see
## MAIN_SPLIT_PLAN.md. Holds no state; reads and writes main's fields
## through the `main` reference.

var main: Node2D

func _active_camera() -> Camera2D:
	return main.hive_camera if main.in_hive_view else main.meadow_camera

func _handle_pan(delta: float) -> void:
	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if direction != Vector2.ZERO:
		var cam = _active_camera()
		cam.position += direction.normalized() * main.PAN_SPEED * delta / cam.zoom.x

func _pointer_over_ui() -> bool:
	return main.get_viewport().gui_get_hovered_control() != null

func _save_control_group(slot: int) -> void:
	var ids: Array = []
	for b in main.selected_bees:
		if is_instance_valid(b):
			ids.append(b.bee_id)
	if ids.is_empty():
		Session.control_groups.erase(slot)
		main.hud.show_warning("Group %d cleared." % slot)
		return
	Session.control_groups[slot] = ids
	main.hud.show_warning("Group %d saved — %d bees. Press %d to select them again." % [slot, ids.size(), slot])

func _recall_control_group(slot: int) -> void:
	var ids: Array = Session.control_groups.get(slot, [])
	if ids.is_empty():
		return
	for b in main.selected_bees:
		if is_instance_valid(b):
			b.set_selected(false)
	main.selected_bees.clear()
	for b in get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(b) and ids.has(b.bee_id):
			b.set_selected(true)
			main.selected_bees.append(b)
	main.hud.update_selection(main.selected_bees)
	if main.selected_bees.is_empty():
		main.hud.show_warning("Every bee in group %d has died." % slot)

func _zoom_to_fit() -> void:
	var points: Array = []
	if main.in_hive_view:
		for cell in main.hive.cells:
			if is_instance_valid(cell):
				points.append(cell.global_position)
	else:
		points.append(main.meadow_root.to_global(main.hive.position))
		for b in main.input_selection._bees_in_current_view():
			points.append(b.global_position)
	if points.size() < 2:
		return

	var bounds = Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	bounds = bounds.grow(120.0)

	var cam = _active_camera()
	cam.position = bounds.get_center()
	var view: Vector2 = main.get_viewport_rect().size
	var fit: float = min(view.x / max(1.0, bounds.size.x), view.y / max(1.0, bounds.size.y))
	cam.zoom = Vector2(clampf(fit, main.MIN_ZOOM, main.MAX_ZOOM), clampf(fit, main.MIN_ZOOM, main.MAX_ZOOM))

func _zoom_by(factor: float) -> void:
	var cam = _active_camera()
	var z: float = clamp(cam.zoom.x * factor, main.MIN_ZOOM, main.MAX_ZOOM)
	cam.zoom = Vector2(z, z)

func _toggle_view() -> void:
	main.in_hive_view = not main.in_hive_view
	_apply_view()

func _apply_view() -> void:
	_active_camera().make_current()
	main.meadow_root.visible = not main.in_hive_view
	main.hive_root.visible = main.in_hive_view
	main.hud.set_view_label(main.in_hive_view)
	if main.nursery_panel != null:
		main.orders_zones._apply_zone_glow()
	main._apply_rain_overlay()

func _on_speed_requested(speed_scale: float) -> void:
	if speed_scale <= 0.0:
		get_tree().paused = true
	else:
		get_tree().paused = false
		main.current_speed = speed_scale
		Engine.time_scale = speed_scale
	_refresh_speed_display()

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	_refresh_speed_display()

func _refresh_speed_display() -> void:
	main.hud.pause_label.visible = get_tree().paused
	main.hud.set_speed_display(0.0 if get_tree().paused else main.current_speed)
