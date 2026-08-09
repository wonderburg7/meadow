extends Node2D
## Builds and runs the prototype: a meadow of flowers and foragers, and
## a walled hive interior with a hexagonal comb, the queen, nursery
## workers and builders.
##
## Both places simulate all the time. Switching view just moves the
## camera -- nothing pauses when you look away. The two worlds sit far
## apart in the same coordinate space (see HIVE_WORLD_OFFSET) so each
## camera can frame one without seeing the other.
##
## Foragers move between the two: they fly to the hive marker in the
## meadow, then get reparented into the hive view and walk in through
## the entrance to reach a cell. main.gd owns that handover because it
## owns both roots and the entrance geometry (see move_bee_into_hive).
##
## Controls
##   Tab            switch between meadow and hive
##   Space          pause
##   Arrow keys     pan the camera
##   Mouse wheel    zoom
##   Left click     select a bee (Shift to add), or a comb cell -- or drag a box
##   Right click    on a flower: go collect there. on ground: move there

const Bee = preload("res://scripts/bee.gd")
const Hive = preload("res://scripts/hive.gd")
const Flower = preload("res://scripts/flower.gd")
const HiveCell = preload("res://scripts/hive_cell.gd")
const Hud = preload("res://scripts/hud.gd")
const DebugPanel = preload("res://scripts/debug_panel.gd")
const Shapes = preload("res://scripts/shapes.gd")

const HIVE_WORLD_OFFSET := Vector2(20000, 0)
const HIVE_INTERIOR_CENTRE := Vector2(20400, 280)
const FLOWER_AREA_MIN := Vector2(300, 90)
const FLOWER_AREA_MAX := Vector2(1100, 560)
const HIVE_MARKER_POSITION := Vector2(140, 320)

## The hive wall is a near-complete ring with a gap left at the bottom
## for bees to walk through. Angles are in degrees, y-down, so 90 is
## straight down the screen.
const ENTRANCE_HALF_WIDTH_DEGREES := 14.0

const PAN_SPEED := 420.0
const MIN_ZOOM := 0.4
const MAX_ZOOM := 3.0

var meadow_root: Node2D
var hive_root: Node2D
var meadow_camera: Camera2D
var hive_camera: Camera2D
var selection_layer: Node2D

var hive: Node2D
var hud: CanvasLayer
var queen: Node2D

var in_hive_view: bool = false
var selected_bees: Array = []
var next_bee_id: int = 1
var day: int = 1
var current_speed: float = 1.0

var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_current: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS   # keep input and camera alive while paused
	Engine.time_scale = 1.0
	seed(12345)   # fixed layout while tuning -- delete for a random meadow each run

	meadow_root = Node2D.new()
	add_child(meadow_root)

	hive_root = Node2D.new()
	hive_root.position = HIVE_WORLD_OFFSET
	add_child(hive_root)

	_build_meadow()
	_build_hive_interior()
	_build_cameras()

	selection_layer = Node2D.new()
	selection_layer.z_index = 100
	selection_layer.draw.connect(_draw_selection_box)
	add_child(selection_layer)

	hud = Hud.new()
	hud.focus_requested.connect(_on_focus_requested)
	hud.role_requested.connect(_on_role_requested)
	hud.view_toggle_requested.connect(_toggle_view)
	hud.speed_requested.connect(_on_speed_requested)
	hud.cell_designation_requested.connect(_on_cell_designation_requested)
	add_child(hud)

	add_child(DebugPanel.new())

	hive.storage_changed.connect(func(n, p): hud.update_storage(n, p))
	hud.update_day(day)
	hud.update_storage(0, 0)
	hud.set_speed_display(1.0)
	_update_population_readout()
	_apply_view()

# --- world building -----------------------------------------------

func _hive_centre_local() -> Vector2:
	return HIVE_INTERIOR_CENTRE - HIVE_WORLD_OFFSET

func _build_meadow() -> void:
	hive = Hive.new()
	hive.position = HIVE_MARKER_POSITION
	meadow_root.add_child(hive)

	for i in range(int(GameConfig.flower_count)):
		var flower := Flower.new()
		flower.position = Vector2(
			randf_range(FLOWER_AREA_MIN.x, FLOWER_AREA_MAX.x),
			randf_range(FLOWER_AREA_MIN.y, FLOWER_AREA_MAX.y)
		)
		meadow_root.add_child(flower)
		flower.setup(i % Flower.SPECIES.size())

	for i in range(int(GameConfig.starting_bees)):
		_spawn_bee("nectar" if i % 2 == 0 else "pollen")

func _build_hive_interior() -> void:
	var centre_local := _hive_centre_local()
	var radius: float = GameConfig.hive_wall_radius

	# floor
	var floor_disc := Polygon2D.new()
	floor_disc.polygon = Shapes.circle_points(radius, 48)
	floor_disc.position = centre_local
	floor_disc.color = Color(0.22, 0.17, 0.08)
	hive_root.add_child(floor_disc)

	# wall: a ring with a gap at the bottom for the entrance. Later,
	# wall-mining bees will widen this to make room for more comb.
	var wall := Line2D.new()
	wall.position = centre_local
	wall.points = Shapes.arc_points(
		radius,
		90.0 + ENTRANCE_HALF_WIDTH_DEGREES,
		90.0 + 360.0 - ENTRANCE_HALF_WIDTH_DEGREES,
		96
	)
	wall.width = 14.0
	wall.default_color = Color(0.42, 0.32, 0.12)
	hive_root.add_child(wall)

	# a lighter pad on the floor marking where bees come and go
	var pad := Polygon2D.new()
	pad.polygon = Shapes.square_points(Vector2(70, 18))
	pad.position = centre_local + Vector2(0, radius - 4)
	pad.color = Color(0.55, 0.45, 0.2)
	hive_root.add_child(pad)

	var entrance_label := Label.new()
	entrance_label.position = centre_local + Vector2(-28, radius + 8)
	entrance_label.add_theme_font_size_override("font_size", 12)
	entrance_label.text = "entrance"
	hive_root.add_child(entrance_label)

	# comb
	var cells: Array = []
	for axial in Shapes.hex_spiral(int(GameConfig.hive_cell_count)):
		var cell := HiveCell.new()
		cell.position = centre_local + Shapes.hex_to_pixel(axial.x, axial.y, GameConfig.hive_cell_spacing)
		hive_root.add_child(cell)
		cells.append(cell)
	hive.cells = cells
	hive.comb_parent = hive_root
	hive.comb_centre = centre_local

	# the queen is an ordinary bee with is_queen set -- she can be
	# reassigned to forage or build like anyone else
	queen = Bee.new()
	queen.is_queen = true
	queen.position = centre_local + Vector2(0, 120)
	hive_root.add_child(queen)
	queen.setup(hive, "pollen", 0, Bee.Role.EGG_LAYER, self)

	# start with at least one nurse, otherwise the queen's eggs would
	# sit on the floor forever with nobody to carry them to a cell
	for i in range(int(GameConfig.starting_nurses)):
		_spawn_indoor_bee(Bee.Role.NURSERY)
	for i in range(int(GameConfig.starting_builders)):
		_spawn_indoor_bee(Bee.Role.BUILDER)

func _build_cameras() -> void:
	meadow_camera = Camera2D.new()
	meadow_camera.position = Vector2(640, 320)
	add_child(meadow_camera)

	hive_camera = Camera2D.new()
	hive_camera.position = HIVE_INTERIOR_CENTRE
	add_child(hive_camera)

func _spawn_bee(focus: String) -> void:
	var bee := Bee.new()
	bee.position = hive.position
	meadow_root.add_child(bee)
	bee.setup(hive, focus, next_bee_id, Bee.Role.FORAGER, self)
	next_bee_id += 1

func _spawn_indoor_bee(role: int) -> void:
	var bee := Bee.new()
	bee.position = _hive_centre_local() + Vector2(randf_range(-50, 50), randf_range(60, 110))
	hive_root.add_child(bee)
	bee.setup(hive, "nectar", next_bee_id, role, self)
	next_bee_id += 1

# --- moving bees between the meadow and the hive ------------------

## Where a bee stands once it is inside, just past the entrance gap.
func hive_entrance_inside() -> Vector2:
	return _hive_centre_local() + Vector2(0, GameConfig.hive_wall_radius - 26.0)

func move_bee_into_hive(bee: Node2D) -> void:
	if bee.get_parent() == hive_root:
		return
	bee.reparent(hive_root)
	bee.position = hive_entrance_inside()
	bee.visible = true
	_update_population_readout()

func move_bee_out_of_hive(bee: Node2D) -> void:
	if bee.get_parent() == meadow_root:
		return
	bee.reparent(meadow_root)
	bee.position = hive.position
	bee.visible = true
	_update_population_readout()

# --- per-frame ----------------------------------------------------

func _process(delta: float) -> void:
	_handle_pan(delta)

	if not get_tree().paused:
		GameConfig.sim_time += delta
		var new_day: int = 1 + int(GameConfig.sim_time / max(1.0, GameConfig.seconds_per_day))
		if new_day != day:
			day = new_day
			hud.update_day(day)
		_hatch_ready_brood()

	_prune_selection()
	if dragging:
		selection_layer.queue_redraw()

## A finished brood cell releases a new forager into the meadow.
func _hatch_ready_brood() -> void:
	for cell in hive.cells:
		if cell.brood_ready():
			cell.clear_cell()
			_spawn_bee("nectar")
			_update_population_readout()

func _update_population_readout() -> void:
	var foragers := 0
	var nurses := 0
	var builders := 0
	for b in get_tree().get_nodes_in_group("bees"):
		match b.role:
			Bee.Role.NURSERY:
				nurses += 1
			Bee.Role.BUILDER:
				builders += 1
			Bee.Role.FORAGER:
				foragers += 1
	hud.update_population(foragers, nurses, builders)

func _prune_selection() -> void:
	var before := selected_bees.size()
	selected_bees = selected_bees.filter(func(b): return is_instance_valid(b))
	if selected_bees.size() != before:
		hud.update_selection(selected_bees)
		_update_population_readout()

# --- camera -------------------------------------------------------

func _active_camera() -> Camera2D:
	return hive_camera if in_hive_view else meadow_camera

func _handle_pan(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if direction != Vector2.ZERO:
		var cam := _active_camera()
		cam.position += direction.normalized() * PAN_SPEED * delta / cam.zoom.x

func _zoom_by(factor: float) -> void:
	var cam := _active_camera()
	var z: float = clamp(cam.zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
	cam.zoom = Vector2(z, z)

func _toggle_view() -> void:
	in_hive_view = not in_hive_view
	_apply_view()

func _apply_view() -> void:
	_active_camera().make_current()
	meadow_root.visible = not in_hive_view
	hive_root.visible = in_hive_view
	hud.set_view_label(in_hive_view)

# --- speed --------------------------------------------------------

func _on_speed_requested(speed_scale: float) -> void:
	if speed_scale <= 0.0:
		get_tree().paused = true
	else:
		get_tree().paused = false
		current_speed = speed_scale
		Engine.time_scale = speed_scale
	_refresh_speed_display()

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	_refresh_speed_display()

func _refresh_speed_display() -> void:
	hud.pause_label.visible = get_tree().paused
	hud.set_speed_display(0.0 if get_tree().paused else current_speed)

# --- input --------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_toggle_pause()
			KEY_TAB:
				_toggle_view()

	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom_by(1.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_by(1.0 / 1.1)
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					dragging = true
					drag_start = get_global_mouse_position()
					drag_current = drag_start
				else:
					_finish_drag(event.shift_pressed)
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					_issue_command(get_global_mouse_position())

	elif event is InputEventMouseMotion and dragging:
		drag_current = get_global_mouse_position()

func _finish_drag(additive: bool) -> void:
	if not dragging:
		return
	dragging = false
	selection_layer.queue_redraw()

	var box := Rect2(drag_start, drag_current - drag_start).abs()
	var picked: Array = []
	if box.size.length() < 6.0:
		# treated as a click rather than a drag
		var bee := _bee_at(drag_start)
		if bee:
			picked.append(bee)
		elif in_hive_view:
			var cell := _cell_at(drag_start)
			if cell:
				hud.show_cell_popup(cell, get_viewport().get_mouse_position())
				return
	else:
		for b in _bees_in_current_view():
			if box.has_point(b.global_position):
				picked.append(b)

	if not additive:
		for b in selected_bees:
			if is_instance_valid(b):
				b.set_selected(false)
		selected_bees.clear()

	for b in picked:
		if not selected_bees.has(b):
			b.set_selected(true)
			selected_bees.append(b)

	hud.update_selection(selected_bees)

func _bees_in_current_view() -> Array:
	var root := hive_root if in_hive_view else meadow_root
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

func _flower_at(point: Vector2) -> Node2D:
	for f in get_tree().get_nodes_in_group("flowers"):
		if f.global_position.distance_to(point) <= 20.0:
			return f
	return null

## Right-click: send the selection to a flower if there's one under the
## cursor, otherwise just walk them to that spot.
func _issue_command(world_point: Vector2) -> void:
	if selected_bees.is_empty():
		return
	var flower := _flower_at(world_point) if not in_hive_view else null
	for b in selected_bees:
		if not is_instance_valid(b):
			continue
		if flower:
			b.command_collect_from(flower)
		else:
			b.command_move_to(world_point)

func _on_focus_requested(type: String) -> void:
	for b in selected_bees:
		if is_instance_valid(b):
			b.set_focus(type)
	hud.update_selection(selected_bees)

func _on_role_requested(role_name: String) -> void:
	var target_role: int = Bee.Role.FORAGER
	match role_name:
		"nursery":
			target_role = Bee.Role.NURSERY
		"builder":
			target_role = Bee.Role.BUILDER
		"egg_layer":
			target_role = Bee.Role.EGG_LAYER
	for b in selected_bees:
		if is_instance_valid(b):
			b.set_role(target_role)
	_update_population_readout()
	hud.update_selection(selected_bees)

## Reserving a cell for one resource when it already holds another means
## the contents have to go somewhere. If any other cell has room, a
## builder will haul it across. If nothing has room, the player is
## warned before anything is thrown away.
func _on_cell_designation_requested(cell: Node2D, type: String) -> void:
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

	if hive.has_room_elsewhere(cell.content_type, cell):
		cell.set_designation(type)   # a builder will come and shift it
	elif GameConfig.warn_on_discard:
		hud.show_discard_warning(cell, type, cell.content_type, cell.amount)
	else:
		cell.clear_cell()
		cell.set_designation(type)

func _draw_selection_box() -> void:
	if not dragging:
		return
	var box := Rect2(drag_start, drag_current - drag_start).abs()
	selection_layer.draw_rect(box, Color(0.2, 1.0, 0.4, 0.15), true)
	selection_layer.draw_rect(box, Color(0.2, 1.0, 0.4, 0.9), false, 2.0)
