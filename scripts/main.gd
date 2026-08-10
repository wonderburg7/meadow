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
const SoilBlock = preload("res://scripts/soil_block.gd")
const Obstacle = preload("res://scripts/obstacle.gd")
const Hud = preload("res://scripts/hud.gd")
const DebugPanel = preload("res://scripts/debug_panel.gd")
const Shapes = preload("res://scripts/shapes.gd")

const HIVE_WORLD_OFFSET := Vector2(20000, 0)
const HIVE_INTERIOR_CENTRE := Vector2(20400, 280)
## A rectangular field rather than a radial one -- a uniform-angle,
## sqrt-distance scatter (the previous approach) always reads as a disc
## no matter how it's tuned. Rectangular + clustered breaks that up.
const FLOWER_FIELD_HALF_SIZE := Vector2(950.0, 700.0)
const FLOWER_MIN_DISTANCE := 90.0     # keep the ground by the hive clear
const MAX_CLUSTERS_PER_SPECIES := 22
const OBSTACLE_COUNT := 14
const OBSTACLE_HIVE_CLEARANCE := 220.0
const HIVE_MARKER_POSITION := Vector2(620, 330)

## Muted, slightly grey-green so it reads as grass without glowing.
const MEADOW_COLOR := Color(0.44, 0.56, 0.35)
const FLOOR_COLOR := Color(0.78, 0.60, 0.47)

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

var reseed_timer: float = 0.0
## Rolling window for the top-left rate readout: a sample every 10 sim
## seconds, keeping the last 7 (a 60s span once warmed up). Rate is the
## change across the whole window divided by its length, which is
## steadier than reading the last 10s alone.
var rate_samples: Array = []
var rate_sample_timer: float = 10.0
var cluster_centers: Dictionary = {}   # species name -> Array[Vector2]
var panning: bool = false          # middle mouse button held
var pan_anchor: Vector2 = Vector2.ZERO

## "Click a spot" placement modes, entered from the HUD. While one is
## active the next left click in the relevant view is consumed as the
## placement rather than a normal select/drag.
var awaiting_build_cell: bool = false
var pending_builder_bees: Array = []
var awaiting_forage_start: bool = false
var pending_forage_bees: Array = []
var awaiting_floral_preference: bool = false
var pending_preference_bees: Array = []

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS   # keep input and camera alive while paused
	Engine.time_scale = 1.0
	seed(12345)   # fixed layout while tuning -- delete for a random meadow each run

	meadow_root = Node2D.new()
	# Main is PROCESS_MODE_ALWAYS (so the camera and HUD keep working
	# while paused), and process_mode is inherited by default -- without
	# pinning these back to normal, every bee and flower under them would
	# silently inherit ALWAYS too and just keep simulating through a
	# pause. This is what made Pause not actually stop anything.
	meadow_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(meadow_root)

	hive_root = Node2D.new()
	hive_root.position = HIVE_WORLD_OFFSET
	hive_root.process_mode = Node.PROCESS_MODE_PAUSABLE
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
	hud.cell_hatch_role_requested.connect(_on_cell_hatch_role_requested)
	hud.build_cell_requested.connect(_on_build_cell_requested)
	hud.forage_start_point_requested.connect(_on_forage_start_point_requested)
	hud.secondary_role_requested.connect(_on_secondary_role_requested)
	hud.floral_preference_requested.connect(_on_floral_preference_requested)
	add_child(hud)

	add_child(DebugPanel.new())

	hive.storage_changed.connect(func(n, p): hud.update_storage(n, p))
	hud.update_day(day)
	hud.update_storage(0, 0)
	hud.update_rates(0.0, 0.0, 0.0)
	hud.set_speed_display(1.0)
	_update_population_readout()
	_apply_view()

# --- world building -----------------------------------------------

func _hive_centre_local() -> Vector2:
	return HIVE_INTERIOR_CENTRE - HIVE_WORLD_OFFSET

func _build_meadow() -> void:
	# grass, drawn well beyond the flower area so panning never runs off
	# the edge of it
	var grass := Polygon2D.new()
	grass.polygon = Shapes.square_points(Vector2(4000, 3000))
	grass.position = Vector2(700, 325)
	grass.color = MEADOW_COLOR
	grass.z_index = -10
	meadow_root.add_child(grass)

	hive = Hive.new()
	hive.position = HIVE_MARKER_POSITION
	meadow_root.add_child(hive)

	_scatter_obstacles()

	# Flowers ring the hive in every direction rather than sitting in one
	# block to the side, so which way a forager sets off is a real choice.
	for i in range(int(GameConfig.flower_count)):
		_seed_flower()

## Trees and raised ground that foragers steer around (see
## Bee._avoid_obstacles). Kept clear of the hive itself so the entrance
## is never accidentally blocked.
func _scatter_obstacles() -> void:
	var placed: Array = []
	for i in range(OBSTACLE_COUNT):
		var is_tree := randf() < 0.65
		var radius: float = randf_range(22.0, 34.0) if is_tree else randf_range(30.0, 48.0)
		var pos: Vector2
		var attempts := 0
		while attempts < 10:
			pos = hive.position + Vector2(
				randf_range(-FLOWER_FIELD_HALF_SIZE.x, FLOWER_FIELD_HALF_SIZE.x),
				randf_range(-FLOWER_FIELD_HALF_SIZE.y, FLOWER_FIELD_HALF_SIZE.y)
			)
			var clear_of_hive: bool = pos.distance_to(hive.position) > OBSTACLE_HIVE_CLEARANCE
			var clear_of_others := true
			for other in placed:
				if pos.distance_to(other.pos) < radius + other.radius + 40.0:
					clear_of_others = false
					break
			if clear_of_hive and clear_of_others:
				break
			attempts += 1
		if attempts >= 10:
			continue   # couldn't find a clear spot -- skip rather than overlap

		var obstacle := Obstacle.new()
		obstacle.position = pos
		obstacle.z_index = -1   # above the grass, below bees and flowers
		meadow_root.add_child(obstacle)
		obstacle.setup(Obstacle.Kind.TREE if is_tree else Obstacle.Kind.RAISED, radius)
		placed.append({"pos": pos, "radius": radius})

	# Level 1: the queen and nothing else -- no starting foragers.
	if not GameConfig.level1_mode:
		# Always at least one of each, so both resources are coming in
		# from the first moment and the queen isn't stalled on pollen.
		var total_bees: int = maxi(2, int(GameConfig.starting_bees))
		_spawn_bee("nectar")
		_spawn_bee("pollen")
		for i in range(total_bees - 2):
			_spawn_bee("nectar")

## Plants one flower. Most of the time it joins an existing cluster of
## its own species (a tight huddle for Clover, a loose scatter for
## Poppy); the rest of the time it starts a new cluster somewhere in the
## field. Species pick their own patchiness via `cluster_radius` /
## `cluster_chance` in flower.gd -- see the notes on each species there
## for the real-world habit it's approximating.
func _seed_flower() -> void:
	var species_index := Flower.pick_species_index()
	var species: Dictionary = Flower.SPECIES[species_index]
	var species_name: String = species.name
	var cluster_radius: float = species.get("cluster_radius", 70.0)
	var cluster_chance: float = species.get("cluster_chance", 0.6)

	var centers: Array = cluster_centers.get(species_name, [])
	var pos: Vector2

	if not centers.is_empty() and randf() < cluster_chance:
		var center: Vector2 = centers[randi() % centers.size()]
		var angle := randf() * TAU
		var dist := sqrt(randf()) * cluster_radius   # dense towards the centre, thins at the edge
		pos = center + Vector2(cos(angle), sin(angle)) * dist
	else:
		pos = _random_field_point()
		centers.append(pos)
		if centers.size() > MAX_CLUSTERS_PER_SPECIES:
			centers.pop_front()
		cluster_centers[species_name] = centers

	var flower := Flower.new()
	flower.position = pos
	meadow_root.add_child(flower)
	flower.setup(species_index)

## A point somewhere in the rectangular field, kept clear of the ground
## immediately around the hive.
func _random_field_point() -> Vector2:
	var point: Vector2
	for attempt in range(6):
		point = hive.position + Vector2(
			randf_range(-FLOWER_FIELD_HALF_SIZE.x, FLOWER_FIELD_HALF_SIZE.x),
			randf_range(-FLOWER_FIELD_HALF_SIZE.y, FLOWER_FIELD_HALF_SIZE.y)
		)
		if point.distance_to(hive.position) >= FLOWER_MIN_DISTANCE:
			break
	return point

## The hive interior is a hexagonal grid. Open floor in the middle, a
## soil wall of the same tile size around it, and a gap in that wall for
## the entrance. Because soil sits on the same grid as comb, a mined
## block can later be replaced by a cell.
func _build_hive_interior() -> void:
	var centre_local := _hive_centre_local()
	var interior_rings := int(GameConfig.hive_interior_rings)
	var soil_depth := int(GameConfig.hive_soil_depth)
	var spacing: float = GameConfig.hive_cell_spacing

	hive.comb_parent = hive_root
	hive.comb_centre = centre_local

	# The hive is a hollow dug out of solid ground. Everything from the
	# edge of the hollow outwards is soil the bees will eventually mine;
	# the middle is open floor they can move through freely.
	#
	# The edge of the hollow is deliberately ragged: each tile near the
	# boundary is decided individually, so the chamber looks excavated
	# rather than stamped out.
	_dig_out_chamber(centre_local, interior_rings, soil_depth, spacing)
	_add_entrance_marker()
	_build_starting_comb(centre_local, spacing)
	hive.build_navigation()
	hive.refresh_edge_flags()
	_spawn_hive_occupants(centre_local, interior_rings, spacing)

## Lays down every tile: open floor inside the hollow and in the entrance
## tunnel, solid soil everywhere else.
func _dig_out_chamber(centre_local: Vector2, interior_rings: int, soil_depth: int, spacing: float) -> void:
	var entrance_tiles := _entrance_tiles(interior_rings, soil_depth)
	for ring in range(0, interior_rings + soil_depth):
		for hex in Shapes.hex_ring(ring):
			if entrance_tiles.has(hex) or _is_open_tile(hex, ring, interior_rings):
				_add_floor_tile(hex, centre_local, spacing)
			else:
				_add_soil_block(hex, centre_local, spacing)

func _add_entrance_marker() -> void:
	var marker := Polygon2D.new()
	marker.polygon = Shapes.circle_points(7.0, 20)
	marker.position = hive_entrance_inside()
	marker.color = Color(0.05, 0.05, 0.05)
	marker.z_index = 2
	hive_root.add_child(marker)

func _build_starting_comb(centre_local: Vector2, spacing: float) -> void:
	var cells: Array = []
	var starting_count: int = 0 if GameConfig.level1_mode else int(GameConfig.hive_cell_count)
	for i in range(starting_count):
		var cell_hex: Vector2i = Shapes.hex_spiral_at(i)
		var cell := HiveCell.new()
		cell.axial = cell_hex
		cell.position = centre_local + Shapes.hex_to_pixel(cell_hex.x, cell_hex.y, spacing)
		hive_root.add_child(cell)
		cells.append(cell)
		hive.register_tile(cell_hex, cell)
	hive.cells = cells

func _spawn_hive_occupants(centre_local: Vector2, interior_rings: int, spacing: float) -> void:
	# the queen is an ordinary bee with is_queen set -- she can be
	# reassigned to forage or build like anyone else
	queen = Bee.new()
	queen.is_queen = true
	queen.position = centre_local + Vector2(0, (interior_rings - 3) * spacing * 1.5)
	hive_root.add_child(queen)
	queen.setup(hive, "pollen", 0, Bee.Role.EGG_LAYER, self)

	if not GameConfig.level1_mode:
		for i in range(int(GameConfig.starting_nurses)):
			_spawn_indoor_bee(Bee.Role.NURSERY)
		for i in range(int(GameConfig.starting_builders)):
			_spawn_indoor_bee(Bee.Role.BUILDER)

## Tiles well inside the hollow are always open, tiles well outside are
## always soil, and the boundary ring is decided at random so the wall
## has a rough, natural edge.
func _is_open_tile(hex: Vector2i, ring: int, interior_rings: int) -> bool:
	if ring < interior_rings - 1:
		return true
	if ring > interior_rings:
		return false
	# Use the tile's own coordinates as the seed so the shape is stable
	# for a given layout rather than flickering on rebuild.
	var noise: float = abs(sin(float(hex.x) * 12.9898 + float(hex.y) * 78.233))
	return noise > 0.45 if ring == interior_rings - 1 else noise > 0.75

func _add_floor_tile(hex: Vector2i, centre_local: Vector2, spacing: float) -> void:
	var tile := Polygon2D.new()
	tile.polygon = Shapes.hexagon_points(GameConfig.hive_cell_size * 1.08)
	tile.position = centre_local + Shapes.hex_to_pixel(hex.x, hex.y, spacing)
	tile.color = FLOOR_COLOR
	hive_root.add_child(tile)

func _add_soil_block(hex: Vector2i, centre_local: Vector2, spacing: float) -> void:
	if not hive.tile_is_free(hex):
		return
	var block := SoilBlock.new()
	block.position = centre_local + Shapes.hex_to_pixel(hex.x, hex.y, spacing)
	hive_root.add_child(block)
	block.setup(hex)
	hive.register_tile(hex, block)

## The tunnel bees walk in through: a narrow channel of open tiles cut
## straight up from the hollow through the soil above it.
func _entrance_tiles(interior_rings: int, soil_depth: int) -> Dictionary:
	var tiles: Dictionary = {}
	var half: float = GameConfig.hive_entrance_width * GameConfig.hive_cell_spacing
	for ring in range(interior_rings - 1, interior_rings + soil_depth):
		for hex in Shapes.hex_ring(ring):
			var pixel := Shapes.hex_to_pixel(hex.x, hex.y, GameConfig.hive_cell_spacing)
			# upwards on screen is negative y
			if pixel.y < 0.0 and abs(pixel.x) <= half:
				tiles[hex] = true
	return tiles

## The mouth of the tunnel at the outer surface, where bees actually
## enter and leave. They then walk the whole tunnel down into the hollow,
## so arriving and departing reads as a journey rather than a teleport.
func hive_entrance_inside() -> Vector2:
	var rings: float = GameConfig.hive_interior_rings + GameConfig.hive_soil_depth - 1.0
	return _hive_centre_local() + Vector2(0, -rings * GameConfig.hive_cell_spacing * 1.5)

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

## A bee that's just hatched -- unlike the starting roster, it needs to
## visibly emerge from the actual cell it developed in rather than
## appearing near the hive centre (indoor roles) or straight out in the
## meadow (forager, which used to skip the hive entirely). It's spawned
## inside the hive at the cell's position; a forager then walks itself
## out through the entrance exactly like any other exiting bee.
func _spawn_hatched_bee(role: int, cell: Node2D) -> void:
	var bee := Bee.new()
	bee.position = cell.position
	hive_root.add_child(bee)
	bee.setup(hive, "nectar", next_bee_id, role, self)
	next_bee_id += 1
	if role == Bee.Role.FORAGER:
		bee.state = Bee.State.IN_HIVE_TO_EXIT
	# other roles: setup() already left it in the right indoor idle state

func _spawn_indoor_bee(role: int) -> void:
	var bee := Bee.new()
	bee.position = _hive_centre_local() + Vector2(randf_range(-50, 50), randf_range(60, 110))
	hive_root.add_child(bee)
	bee.setup(hive, "nectar", next_bee_id, role, self)
	next_bee_id += 1

# --- moving bees between the meadow and the hive ------------------


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
	selection_layer.queue_redraw()

	if not get_tree().paused:
		GameConfig.sim_time += delta
		var new_day: int = 1 + int(GameConfig.sim_time / max(1.0, GameConfig.seconds_per_day))
		if new_day != day:
			day = new_day
			hud.update_day(day)
		_hatch_ready_brood()
		_reseed_meadow(delta)
		rate_sample_timer -= delta
		if rate_sample_timer <= 0.0:
			rate_sample_timer = 10.0
			_sample_rates()

	_prune_selection()

## Flowers wither on their own; this quietly seeds replacements so the
## meadow stays about as full as `flower_count` without every gap
## refilling instantly.
func _reseed_meadow(delta: float) -> void:
	reseed_timer -= delta
	if reseed_timer > 0.0:
		return
	reseed_timer = GameConfig.flower_regrow_seconds
	if get_tree().get_nodes_in_group("flowers").size() < int(GameConfig.flower_count):
		_seed_flower()
	if dragging:
		selection_layer.queue_redraw()

## A finished brood cell releases a new bee. The cell decides what that
## bee becomes: whatever role you set on it, or a nectar forager by
## default. Because the role lives on the cell, every future egg raised
## there comes out the same way without you touching it again.
func _hatch_ready_brood() -> void:
	for cell in hive.cells:
		if not cell.brood_ready():
			continue
		var role: int = cell.hatch_role if cell.hatch_role >= 0 else Bee.Role.FORAGER
		cell.clear_cell()
		_spawn_hatched_bee(role, cell)
		hive.record_birth()
		_update_population_readout()

func _sample_rates() -> void:
	rate_samples.append({
		"t": GameConfig.sim_time,
		"nectar": hive.lifetime_nectar_collected,
		"pollen": hive.lifetime_pollen_collected,
		"births": hive.lifetime_births,
	})
	while rate_samples.size() > 7:
		rate_samples.pop_front()
	if rate_samples.size() < 2:
		return
	var oldest: Dictionary = rate_samples[0]
	var newest: Dictionary = rate_samples[rate_samples.size() - 1]
	var span: float = newest.t - oldest.t
	if span <= 0.0:
		return
	hud.update_rates(
		(newest.nectar - oldest.nectar) / span,
		(newest.pollen - oldest.pollen) / span,
		(newest.births - oldest.births) / span,
	)

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
			MOUSE_BUTTON_MIDDLE:
				# hold the scroll wheel down and drag to pan the view
				panning = event.pressed
				pan_anchor = event.position
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					_issue_command(get_global_mouse_position())

	elif event is InputEventMouseMotion:
		if panning:
			# move the camera opposite to the drag, so the world follows
			# the cursor the way it does in a map application
			var cam := _active_camera()
			cam.position -= (event.position - pan_anchor) / cam.zoom.x
			pan_anchor = event.position
		elif dragging:
			drag_current = get_global_mouse_position()

func _finish_drag(additive: bool) -> void:
	if not dragging:
		return
	dragging = false
	selection_layer.queue_redraw()

	if awaiting_build_cell:
		_place_build_cell(drag_start)
		return
	if awaiting_forage_start:
		_place_forage_start(drag_start)
		return
	if awaiting_floral_preference:
		_place_floral_preference(drag_start)
		return

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
			# clicking an exposed soil block flags it for digging
			var block := _soil_at(drag_start)
			if block and block.is_edge:
				block.set_marked(not block.marked_for_mining)
				return
		else:
			var flower := _flower_at(drag_start)
			if flower:
				hud.show_flower_popup(flower, get_viewport().get_mouse_position())
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

func _soil_at(point: Vector2) -> Node2D:
	for b in get_tree().get_nodes_in_group("soil_blocks"):
		if is_instance_valid(b) and b.global_position.distance_to(point) <= b.block_size:
			return b
	return null

## A miner has finished a block: it becomes open floor, and the routes
## through the hive are rebuilt so bees can use the new space.
func finish_mining(block: Node2D) -> void:
	var centre_local := _hive_centre_local()
	var spacing: float = GameConfig.hive_cell_spacing
	hive.remove_block(block, func(hex: Vector2i): _add_floor_tile(hex, centre_local, spacing))

func _flower_at(point: Vector2) -> Node2D:
	for f in get_tree().get_nodes_in_group("flowers"):
		if f.global_position.distance_to(point) <= 20.0:
			return f
	return null

## Consumes the click that follows a "Build Cell" request: works out
## which hex it landed on and hands it to each pending builder. A miss
## (soil, already-occupied tile, outside the hollow) is silently ignored
## rather than nagging the player -- the builder just falls back to
## automatic placement, same as any other failed manual target.
func _place_build_cell(global_point: Vector2) -> void:
	awaiting_build_cell = false
	var local_point: Vector2 = hive_root.to_local(global_point)
	var hex: Vector2i = Shapes.pixel_to_hex(local_point - hive.comb_centre, GameConfig.hive_cell_spacing)
	for b in pending_builder_bees:
		if is_instance_valid(b):
			b.set_manual_build_target(hex)
	pending_builder_bees = []

## Consumes the click that follows a "Set start point" request.
func _place_forage_start(global_point: Vector2) -> void:
	awaiting_forage_start = false
	var meadow_point: Vector2 = meadow_root.to_local(global_point)
	for b in pending_forage_bees:
		if is_instance_valid(b):
			b.set_forage_start_point(meadow_point)
	pending_forage_bees = []

## Consumes the click that follows a "Set preference" request. A miss
## (no flower under the click) is ignored rather than nagging -- nothing
## changes and the player can just click again.
func _place_floral_preference(global_point: Vector2) -> void:
	awaiting_floral_preference = false
	var flower := _flower_at(global_point)
	if flower:
		for b in pending_preference_bees:
			if is_instance_valid(b):
				b.set_preferred_species(flower.species_name)
		hud.update_selection(selected_bees)
	pending_preference_bees = []

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
	# automine isn't a role, it's a switch on the miners already selected
	if role_name == "automine":
		for b in selected_bees:
			if is_instance_valid(b):
				b.automine = not b.automine
		hud.update_selection(selected_bees)
		return

	var target_role: int = Bee.Role.FORAGER
	match role_name:
		"nursery":
			target_role = Bee.Role.NURSERY
		"builder":
			target_role = Bee.Role.BUILDER
		"egg_layer":
			target_role = Bee.Role.EGG_LAYER
		"idle":
			target_role = Bee.Role.IDLE
		"miner":
			target_role = Bee.Role.MINER
	for b in selected_bees:
		if is_instance_valid(b):
			b.set_role(target_role)
	_update_population_readout()
	hud.update_selection(selected_bees)

func _on_secondary_role_requested(role_name: String) -> void:
	var target_role: int = -1
	match role_name:
		"forager":
			target_role = Bee.Role.FORAGER
		"nursery":
			target_role = Bee.Role.NURSERY
		"builder":
			target_role = Bee.Role.BUILDER
		"miner":
			target_role = Bee.Role.MINER
		# "none" (or anything else) leaves target_role at -1, clearing it
	for b in selected_bees:
		if is_instance_valid(b):
			b.set_secondary_role(target_role)
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

func _on_cell_hatch_role_requested(cell: Node2D, role: int) -> void:
	if is_instance_valid(cell):
		cell.hatch_role = role

## Enters "click a hive tile" mode for the selected builders. Switches to
## the hive view automatically, since that's where the click has to land.
func _on_build_cell_requested() -> void:
	pending_builder_bees = selected_bees.filter(func(b): return is_instance_valid(b) and b.role == Bee.Role.BUILDER)
	if pending_builder_bees.is_empty():
		return
	awaiting_build_cell = true
	if not in_hive_view:
		in_hive_view = true
		_apply_view()

## Enters "click a meadow spot" mode for the selected foragers. Switches
## to the meadow view automatically, for the same reason.
func _on_forage_start_point_requested() -> void:
	pending_forage_bees = selected_bees.filter(func(b): return is_instance_valid(b) and b.role == Bee.Role.FORAGER)
	if pending_forage_bees.is_empty():
		return
	awaiting_forage_start = true
	if in_hive_view:
		in_hive_view = false
		_apply_view()

## Enters "click a flower" mode for the selected foragers.
func _on_floral_preference_requested() -> void:
	pending_preference_bees = selected_bees.filter(func(b): return is_instance_valid(b) and b.role == Bee.Role.FORAGER)
	if pending_preference_bees.is_empty():
		return
	awaiting_floral_preference = true
	if in_hive_view:
		in_hive_view = false
		_apply_view()

func _draw_selection_box() -> void:
	if dragging:
		var box := Rect2(drag_start, drag_current - drag_start).abs()
		selection_layer.draw_rect(box, Color(0.2, 1.0, 0.4, 0.15), true)
		selection_layer.draw_rect(box, Color(0.2, 1.0, 0.4, 0.9), false, 2.0)

	# A selected forager with a start point set gets a marker at that
	# spot, so it's obvious at a glance where it'll head on its next
	# trip out rather than that only living in the selection panel text.
	if not in_hive_view:
		for b in selected_bees:
			if is_instance_valid(b) and b.role == Bee.Role.FORAGER and b.has_forage_start_point():
				_draw_start_point_marker(b.forage_start_point)

func _draw_start_point_marker(point: Vector2) -> void:
	var marker_color := Color(0.2, 1.0, 0.4, 0.95)
	selection_layer.draw_circle(point, 9.0, Color(0.2, 1.0, 0.4, 0.2))
	selection_layer.draw_arc(point, 9.0, 0.0, TAU, 24, marker_color, 2.5)
	selection_layer.draw_line(point + Vector2(-6, 0), point + Vector2(6, 0), marker_color, 2.0)
	selection_layer.draw_line(point + Vector2(0, -6), point + Vector2(0, 6), marker_color, 2.0)
