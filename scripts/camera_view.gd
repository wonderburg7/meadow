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

## Selects one bee and centres the camera tightly on it, switching view
## if it's on the other side (indoors/outdoors) from wherever the player
## is looking. Used by the colony window's Favourites list -- see
## BEE_INDIVIDUALITY_PLAN.md section 7. Deliberately its own thing
## rather than a call to _zoom_to_fit(): that function's hive-view branch
## frames the whole comb, not one bee in it.
func _focus_on_bee(bee: Node2D) -> void:
	if not is_instance_valid(bee):
		return
	for b in main.selected_bees:
		if is_instance_valid(b):
			b.set_selected(false)
	main.selected_bees.clear()
	bee.set_selected(true)
	main.selected_bees.append(bee)
	main.hud.update_selection(main.selected_bees)

	var bee_indoors: bool = bee.get_parent() == main.hive_root
	if bee_indoors != main.in_hive_view:
		_toggle_view()

	var bounds := Rect2(bee.global_position, Vector2.ZERO).grow(140.0)
	var cam := _active_camera()
	cam.position = bounds.get_center()
	var view: Vector2 = main.get_viewport_rect().size
	var fit: float = min(view.x / bounds.size.x, view.y / bounds.size.y)
	cam.zoom = Vector2(clampf(fit, main.MIN_ZOOM, main.MAX_ZOOM), clampf(fit, main.MIN_ZOOM, main.MAX_ZOOM))

## The command tray's "Follow bee" toggle. `bee` null (or `following`
## false) stops tracking -- hud.gd emits exactly that on every selection
## change, so following never silently outlives the selection it started
## from. Challenge stages use the optional third argument to say their
## follow target may survive a queen-node rebuild; every ordinary player
## toggle clears that permission, including a deliberate mid-stage opt-out.
var _stage_following_queen: bool = false

func _on_follow_bee_toggled(bee: Node2D, following: bool, stage_queen_follow: bool = false) -> void:
	# This is camera_view's only writer for main.following_bee. Stage code
	# must route both camera_follow_queen and camera_follow_off through here.
	_stage_following_queen = following and stage_queen_follow
	main.following_bee = bee if following else null

## Continuous camera tracking, called every frame from main._process
## alongside _handle_pan. Deliberately just re-centres position, not
## zoom -- a player who has zoomed in or out to look at something wants
## to keep that framing while the view follows the bee around in it.
func _handle_follow(_delta: float) -> void:
	if main.following_bee == null:
		return
	if not is_instance_valid(main.following_bee):
		# A checkpoint rebuild can replace the queen node between frames. A
		# stage-owned queen follow tracks the current queen rather than silently
		# ending; ordinary player follows still stop when their bee disappears.
		if _stage_following_queen and is_instance_valid(main.queen):
			_on_follow_bee_toggled(main.queen, true, true)
		else:
			_on_follow_bee_toggled(null, false)
		return
	var bee_indoors: bool = main.following_bee.get_parent() == main.hive_root
	if bee_indoors != main.in_hive_view:
		_toggle_view()
	_active_camera().position = main.following_bee.global_position

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
