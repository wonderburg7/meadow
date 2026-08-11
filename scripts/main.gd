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
const RockBlock = preload("res://scripts/rock_block.gd")
const Hud = preload("res://scripts/hud.gd")
const DebugPanel = preload("res://scripts/debug_panel.gd")
const MainMenu = preload("res://scripts/main_menu.gd")
const GameOver = preload("res://scripts/game_over.gd")
const ColonyPanel = preload("res://scripts/colony_panel.gd")
const SaveGame = preload("res://scripts/save_game.gd")
const Shapes = preload("res://scripts/shapes.gd")

## The fixed starting stages the main menu offers, so a run can begin
## partway in rather than always from a lone queen. `starting_level` of 0
## means "use whatever the tuning numbers say" -- that's the ordinary
## Restart Run behaviour.
const LEVELS := {
	1: {"cells": 0, "nectar_foragers": 0, "pollen_foragers": 0, "nurses": 0, "builders": 0, "miners": 0},
	2: {"cells": 1, "nectar_foragers": 1, "pollen_foragers": 0, "nurses": 0, "builders": 0, "miners": 0},
	3: {"cells": 3, "nectar_foragers": 1, "pollen_foragers": 1, "nurses": 0, "builders": 0, "miners": 0},
	4: {"cells": 15, "nectar_foragers": 8, "pollen_foragers": 3, "nurses": 2, "builders": 2, "miners": 2},
}

const HIVE_WORLD_OFFSET := Vector2(20000, 0)
const HIVE_INTERIOR_CENTRE := Vector2(20400, 280)
## A rectangular field rather than a radial one -- a uniform-angle,
## sqrt-distance scatter (the previous approach) always reads as a disc
## no matter how it's tuned. Rectangular + clustered breaks that up.
const FLOWER_FIELD_HALF_SIZE := Vector2(950.0, 700.0)
const FLOWER_MIN_DISTANCE := 90.0     # keep the ground by the hive clear
const MAX_CLUSTERS_PER_SPECIES := 22
## A few large plateaus rather than many small mounds: raised ground is
## meant to reshape how the colony moves across the meadow, which a
## scattering of little bumps doesn't do.
const RAISED_AREA_COUNT := 4
const RAISED_AREA_RADIUS := Vector2(130.0, 240.0)
const TREE_COUNT := 10
const TREE_RADIUS := Vector2(22.0, 34.0)
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
var game_over: CanvasLayer
var colony_panel: CanvasLayer
var colony_lost: bool = false

## Built once when the meadow is laid out. Bees consult this constantly
## for steering, and a scene-tree group query per bee per frame was the
## worst-scaling thing in the simulation. Obstacles never move or appear
## mid-run, so one list serves everybody.
var obstacles: Array = []

## Weather. Rain waters down open nectar, makes flying heavier, and past
## a point grounds the foragers entirely.
var weather_timer: float = 0.0
var rain_target: float = 0.0
var rain_seconds_left: float = 0.0
var rain_overlay: ColorRect

## Sim time the low-energy warning was last shown, so it can't nag. -INF
## means it hasn't been shown at all yet this run.
var last_energy_warning: float = -INF
var warning_check_timer: float = 5.0
var signal_timer: float = 1.0

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
	add_to_group("world")   # so the tuning panel can find us to save
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

	# A wash of grey-blue over the meadow while it's raining. Drawn on its
	# own layer beneath the HUD so it tints the world, not the panels.
	var weather_layer := CanvasLayer.new()
	weather_layer.layer = 5
	add_child(weather_layer)
	rain_overlay = ColorRect.new()
	rain_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	rain_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rain_overlay.color = Color(0.35, 0.45, 0.62, 0.0)
	rain_overlay.visible = false
	weather_layer.add_child(rain_overlay)

	selection_layer = Node2D.new()
	selection_layer.z_index = 100
	selection_layer.draw.connect(_draw_selection_box)
	add_child(selection_layer)

	hud = Hud.new()
	hud.focus_requested.connect(_on_focus_requested)
	hud.role_requested.connect(_on_role_requested)
	hud.view_toggle_requested.connect(_toggle_view)
	hud.colony_panel_requested.connect(func(): colony_panel.toggle())
	hud.speed_requested.connect(_on_speed_requested)
	hud.cell_designation_requested.connect(_on_cell_designation_requested)
	hud.cell_hatch_role_requested.connect(_on_cell_hatch_role_requested)
	hud.cell_hatch_lock_requested.connect(_on_cell_hatch_lock_requested)
	hud.cell_empty_requested.connect(_on_cell_empty_requested)
	hud.cell_keep_empty_requested.connect(_on_cell_keep_empty_requested)
	hud.cell_gyne_requested.connect(_on_cell_gyne_requested)
	hud.build_cell_requested.connect(_on_build_cell_requested)
	hud.forage_start_point_requested.connect(_on_forage_start_point_requested)
	hud.secondary_role_requested.connect(_on_secondary_role_requested)
	hud.finish_first_requested.connect(_on_finish_first_requested)
	hud.floral_preference_requested.connect(_on_floral_preference_requested)
	add_child(hud)

	add_child(DebugPanel.new())

	# The main menu sits above everything and pauses the run behind it.
	# It opens by itself the first time the game is launched, and after
	# that only when the player asks for it from the tuning panel.
	var menu := MainMenu.new()
	menu.level_chosen.connect(_on_level_chosen)
	add_child(menu)
	if GameConfig.menu_pending:
		menu.open()

	colony_panel = ColonyPanel.new()
	colony_panel.role_selection_requested.connect(_on_role_selection_requested)
	add_child(colony_panel)

	game_over = GameOver.new()
	game_over.restart_requested.connect(_on_restart_after_loss)
	game_over.menu_requested.connect(func(): game_over.visible = false; menu.open())
	add_child(game_over)

	hive.storage_changed.connect(func(n, p, h, j): hud.update_storage(n, p, h, j))
	hud.update_day(day)
	hud.update_storage(0, 0, 0, 0)
	hud.update_rates(0.0, 0.0, 0.0)
	hud.set_speed_display(1.0)
	_update_population_readout()
	_apply_view()

	# A pending load is applied last, over the top of a world that has
	# just been built to the saved settings -- see SaveGame's note on why
	# it replays state rather than restoring a scene tree.
	if GameConfig.load_pending:
		GameConfig.load_pending = false
		_restore(SaveGame.read())

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
## Raised areas go down first and are given a wide berth, because they
## are whole regions of the map rather than single props -- a few big
## plateaus the colony has to route around, each with its own unreachable
## trees and flowers on top. Scattered trees fill in around them.
func _scatter_obstacles() -> void:
	var placed: Array = []
	_place_obstacles(placed, RAISED_AREA_COUNT, Obstacle.Kind.RAISED, RAISED_AREA_RADIUS, 120.0)
	_place_obstacles(placed, TREE_COUNT, Obstacle.Kind.TREE, TREE_RADIUS, 40.0)
	_spawn_starting_foragers()

func _place_obstacles(placed: Array, count: int, kind: int, radius_range: Vector2, gap: float) -> void:
	for i in range(count):
		var radius: float = randf_range(radius_range.x, radius_range.y)
		var pos: Vector2
		var attempts := 0
		while attempts < 25:
			pos = hive.position + Vector2(
				randf_range(-FLOWER_FIELD_HALF_SIZE.x, FLOWER_FIELD_HALF_SIZE.x),
				randf_range(-FLOWER_FIELD_HALF_SIZE.y, FLOWER_FIELD_HALF_SIZE.y)
			)
			# The hive doorway has to stay open, so nothing is allowed
			# near it -- a plateau across the entrance would wall the
			# colony in.
			var clear_of_hive: bool = pos.distance_to(hive.position) > OBSTACLE_HIVE_CLEARANCE + radius
			var clear_of_others := true
			for other in placed:
				if pos.distance_to(other.pos) < radius + other.radius + gap:
					clear_of_others = false
					break
			if clear_of_hive and clear_of_others:
				break
			attempts += 1
		if attempts >= 25:
			continue   # nowhere it fits -- skip rather than overlap

		var obstacle := Obstacle.new()
		obstacle.position = pos
		obstacle.z_index = -1   # above the grass, below bees and flowers
		meadow_root.add_child(obstacle)
		obstacle.setup(kind, radius)
		placed.append({"pos": pos, "radius": radius})
		obstacles.append(obstacle)

## How many foragers a run opens with, and which resource each is on.
## A chosen stage says exactly; otherwise the tuning number applies, with
## at least one of each resource so both are coming in from the first
## moment and the queen isn't stalled waiting for pollen.
func _spawn_starting_foragers() -> void:
	var level: Dictionary = LEVELS.get(GameConfig.starting_level, {})
	if not level.is_empty():
		for i in range(int(level.nectar_foragers)):
			_spawn_bee("nectar")
		for i in range(int(level.pollen_foragers)):
			_spawn_bee("pollen")
		return

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

	# Raised ground and tree trunks are solid, so a flower planted on one
	# would be unreachable -- a forager would walk to the edge and stall.
	# Try elsewhere first; pushing it clear is the last resort, because
	# doing that for every attempt would ring each plateau with a
	# suspiciously neat hedge of flowers.
	for retry in range(8):
		if _is_clear_ground(pos):
			break
		pos = _random_field_point()
	pos = _clear_of_obstacles(pos)

	var flower := Flower.new()
	flower.position = pos
	meadow_root.add_child(flower)
	flower.setup(species_index)

## Is this spot out in the open, clear of every solid obstacle?
func _is_clear_ground(point: Vector2) -> bool:
	for obstacle in obstacles:
		if not is_instance_valid(obstacle) or not obstacle.solid:
			continue
		if point.distance_to(obstacle.position) < obstacle.radius + 24.0:
			return false
	return true

## Pushes `point` out to the boundary of any solid obstacle it lands
## inside, plus a little margin so a bee can actually stand on it.
func _clear_of_obstacles(point: Vector2) -> Vector2:
	var result := point
	for obstacle in obstacles:
		if not is_instance_valid(obstacle) or not obstacle.solid:
			continue
		var edge: float = obstacle.radius + 24.0
		var offset: Vector2 = result - obstacle.position
		if offset.length() >= edge:
			continue
		if offset.length() < 0.01:
			offset = Vector2.RIGHT
		result = obstacle.position + offset.normalized() * edge
	return result

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
	var rock_rings := int(GameConfig.hive_rock_rings)
	var entrance_tiles := _entrance_tiles(interior_rings, soil_depth + rock_rings)
	for ring in range(0, interior_rings + soil_depth):
		for hex in Shapes.hex_ring(ring):
			if entrance_tiles.has(hex) or _is_open_tile(hex, ring, interior_rings):
				_add_floor_tile(hex, centre_local, spacing)
			else:
				_add_soil_block(hex, centre_local, spacing)

	# Bedrock wraps the whole thing. Beyond this the colony cannot dig,
	# move or build -- it's the hard edge of the world -- so the soil in
	# between is a finite resource rather than an endless outward sprawl.
	# The entrance tunnel is carved through it, otherwise the doorway
	# would be sealed off by the very wall meant to bound the map.
	for ring in range(interior_rings + soil_depth, interior_rings + soil_depth + rock_rings):
		for hex in Shapes.hex_ring(ring):
			if entrance_tiles.has(hex):
				_add_floor_tile(hex, centre_local, spacing)
			else:
				_add_rock_block(hex, centre_local, spacing)

func _add_entrance_marker() -> void:
	var marker := Polygon2D.new()
	marker.polygon = Shapes.circle_points(7.0, 20)
	marker.position = hive_entrance_inside()
	marker.color = Color(0.05, 0.05, 0.05)
	marker.z_index = 2
	hive_root.add_child(marker)

func _build_starting_comb(centre_local: Vector2, spacing: float) -> void:
	var cells: Array = []
	var level: Dictionary = LEVELS.get(GameConfig.starting_level, {})
	var starting_count: int = int(level.cells) if not level.is_empty() else int(GameConfig.hive_cell_count)
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

	var level: Dictionary = LEVELS.get(GameConfig.starting_level, {})
	var nurses: int = int(level.nurses) if not level.is_empty() else int(GameConfig.starting_nurses)
	var builders: int = int(level.builders) if not level.is_empty() else int(GameConfig.starting_builders)
	var miners: int = int(level.miners) if not level.is_empty() else int(GameConfig.starting_miners)
	var honey_makers: int = 0 if not level.is_empty() else int(GameConfig.starting_honey_makers)
	for i in range(nurses):
		_spawn_indoor_bee(Bee.Role.NURSERY)
	for i in range(builders):
		_spawn_indoor_bee(Bee.Role.BUILDER)
	for i in range(miners):
		_spawn_indoor_bee(Bee.Role.MINER)
	for i in range(honey_makers):
		_spawn_indoor_bee(Bee.Role.HONEY_MAKER)

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

## Open ground. Drawn oversized and with no outline so neighbouring tiles
## fuse into one continuous floor -- the hive interior should read as an
## excavated space, not a grid of separately bordered hexagons.
func _add_floor_tile(hex: Vector2i, centre_local: Vector2, spacing: float) -> void:
	var tile := Polygon2D.new()
	tile.polygon = Shapes.hexagon_points(GameConfig.hive_cell_size * 1.15)
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

func _add_rock_block(hex: Vector2i, centre_local: Vector2, spacing: float) -> void:
	if not hive.tile_is_free(hex):
		return
	var block := RockBlock.new()
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
	var rings: float = (
		GameConfig.hive_interior_rings
		+ GameConfig.hive_soil_depth
		+ GameConfig.hive_rock_rings
		- 1.0
	)
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
func _spawn_hatched_bee(role: int, cell: Node2D, as_gyne: bool = false) -> void:
	var bee := Bee.new()
	bee.is_gyne = as_gyne   # must be set before _ready, which sizes the body
	bee.position = cell.position
	hive_root.add_child(bee)
	# The cell carries the sub-mode for the role as well as the role
	# itself, so "raises pollen foragers" or "raises automining miners"
	# comes out right without you having to select the new bee and set it
	# up by hand every time.
	var focus: String = cell.hatch_focus if cell.hatch_focus != "" else "nectar"
	# An architect's sub-mode travels in the same field as a forager's
	# resource, so hand it to the right property.
	if role == Bee.Role.BUILDER:
		bee.architect_mode = focus if focus in ["build", "maintain", "both"] else "both"
		bee.setup(hive, "nectar", next_bee_id, role, self)
	else:
		bee.setup(hive, focus, next_bee_id, role, self)
	if role == Bee.Role.MINER:
		bee.automine = cell.hatch_automine
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
		_advance_weather(delta)
		_check_for_loss()
		_check_colony_energy(delta)
		_refresh_signals(delta)
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
		var as_gyne: bool = cell.brood_is_gyne
		cell.clear_cell()
		_spawn_hatched_bee(role, cell, as_gyne)
		# Unless the player pinned it, a role set on a cell applies to that
		# one bee and then clears, so a one-off choice doesn't quietly
		# govern everything the cell ever raises. "Keep for every bee" in
		# the cell popup is what locks it in.
		if not cell.hatch_role_locked:
			cell.hatch_role = -1
		hive.record_birth()
		_update_population_readout()

## Weather. Rain arrives, builds, sits, and eases off again, so the
## colony gets a warning rather than being switched off mid-flight. The
## intensity is what every other system reads: it waters down the nectar
## standing in open flowers, adds the weight of water to every wingbeat,
## and past `rain_forage_limit` makes a trip cost more than it returns,
## at which point foragers stay in.
func _advance_weather(delta: float) -> void:
	if not GameConfig.weather_on:
		GameConfig.rain_intensity = 0.0
		_apply_rain_overlay()
		return

	if rain_seconds_left > 0.0:
		rain_seconds_left -= delta
		if rain_seconds_left <= 0.0:
			rain_target = 0.0
	else:
		# one roll per in-game day, spread evenly over it
		weather_timer -= delta
		if weather_timer <= 0.0:
			weather_timer = max(10.0, GameConfig.seconds_per_day / 6.0)
			if randf() < GameConfig.rain_chance_per_day / 6.0:
				rain_target = randf_range(0.35, 1.0)
				rain_seconds_left = randf_range(GameConfig.rain_min_seconds, GameConfig.rain_max_seconds)
				hud.show_warning(
					"Rain is coming in. Nectar in the open flowers is being watered down, wet wings cost more to fly on, and if it gets heavy enough your foragers will stay at the hive."
				)

	# eased rather than switched, so bees aren't grounded from one frame
	# to the next
	GameConfig.rain_intensity = move_toward(GameConfig.rain_intensity, rain_target, delta * 0.25)
	_apply_rain_overlay()

func _apply_rain_overlay() -> void:
	if rain_overlay == null:
		return
	rain_overlay.color = Color(0.35, 0.45, 0.62, GameConfig.rain_intensity * 0.35)
	rain_overlay.visible = GameConfig.rain_intensity > 0.01 and not in_hive_view

## The queen is the only bee that can lay and there is no succession, so
## losing her ends the run. Checked here rather than from the bee itself
## because a dying bee frees itself, and main.gd is what holds the
## reference worth watching.
func _check_for_loss() -> void:
	if colony_lost or queen == null:
		return
	if is_instance_valid(queen):
		return
	colony_lost = true
	game_over.open(
		day,
		get_tree().get_nodes_in_group("bees").size(),
		hive.total("nectar"),
		hive.total_honey(),
	)

## Warns when the colony as a whole is running on empty. Deliberately
## doesn't pause: it's information, and stopping the game every time
## things got tight would be worse than the problem. It also won't repeat
## for `low_energy_gap` seconds, so a colony that stays hungry gets told
## once and then left alone to be dealt with.
func _check_colony_energy(delta: float) -> void:
	warning_check_timer -= delta
	if warning_check_timer > 0.0:
		return
	warning_check_timer = 5.0

	if GameConfig.sim_time - last_energy_warning < GameConfig.low_energy_gap:
		return

	var bees: Array = get_tree().get_nodes_in_group("bees")
	if bees.size() < 3:
		return   # too small a colony for a proportion to mean anything

	var hungry := 0
	for b in bees:
		if b.energy < GameConfig.energy_capacity * GameConfig.low_energy_warning_level:
			hungry += 1
	var share: float = float(hungry) / float(bees.size())
	if share < GameConfig.low_energy_warning_fraction:
		return

	last_energy_warning = GameConfig.sim_time
	hud.show_warning(
		"%d of your %d bees (%d%%) are below %d%% energy. The colony is burning nectar faster than it is bringing it in — put more bees on nectar foraging, or they will start to starve."
		% [hungry, bees.size(), int(share * 100.0), int(GameConfig.low_energy_warning_level * 100.0)]
	)

## The at-a-glance strip: a short list of what is currently wrong, in
## rough order of how quickly it will hurt. Deliberately phrased as
## symptoms rather than instructions -- it tells you what is happening,
## and leaves what to do about it to you.
##
## Recomputed once a second for the whole colony rather than per bee, so
## it costs effectively nothing.
func _refresh_signals(delta: float) -> void:
	signal_timer -= delta
	if signal_timer > 0.0:
		return
	signal_timer = 1.0

	var lines: Array = []
	var bees: Array = get_tree().get_nodes_in_group("bees")

	var starving := 0
	var hungry := 0
	var foragers := 0
	var nurses := 0
	var architects := 0
	for b in bees:
		if b.energy < GameConfig.energy_capacity * 0.15:
			starving += 1
		elif b.energy < GameConfig.energy_capacity * GameConfig.low_energy_warning_level:
			hungry += 1
		match b.role:
			Bee.Role.FORAGER:
				foragers += 1
			Bee.Role.NURSERY:
				nurses += 1
			Bee.Role.BUILDER:
				architects += 1

	var hungry_brood := 0
	var dead_cells := 0
	var free_cells := 0
	for cell in hive.cells:
		if not is_instance_valid(cell):
			continue
		if cell.needs_cleaning():
			dead_cells += 1
		elif cell.content_type == "brood" and cell.brood_fed_seconds <= 0.0:
			hungry_brood += 1
		elif cell.is_empty() and not cell.keep_empty:
			free_cells += 1

	if starving > 0:
		lines.append(["%d bees are about to starve" % starving, 2])
	if hungry_brood > 0:
		lines.append(["%d larvae are going hungry" % hungry_brood, 2])
	if dead_cells > 0:
		lines.append(["%d cells blocked by dead larvae" % dead_cells, 2])
	if hive.total("pollen") < GameConfig.egg_pollen_cost * 0.5:
		lines.append(["Almost no pollen — the queen cannot lay", 2])
	if hive.total("nectar") < 40.0 and hive.total_honey() < 10.0:
		lines.append(["Almost no nectar or honey — nothing to eat", 2])
	if nurses == 0 and hive.cells_holding("brood").size() > 0:
		lines.append(["No nurses — brood will not develop at all", 2])
	if free_cells == 0:
		lines.append(["No free cells — nowhere to store or lay", 1])
	if hungry > 0:
		lines.append(["%d bees running low on energy" % hungry, 1])
	if foragers == 0:
		lines.append(["No foragers — nothing is coming in", 1])
	if architects == 0 and dead_cells > 0:
		lines.append(["No architects to clear the blocked cells", 1])
	if GameConfig.rain_intensity > GameConfig.rain_forage_limit:
		lines.append(["Raining hard — foragers are grounded", 1])
	elif GameConfig.rain_intensity > 0.05:
		lines.append(["Raining — nectar is watered down and flying costs more", 0])

	hud.update_signals(lines)
	_refresh_colony_panel(bees)

## Feeds the colony overview. Only computed while the panel is actually
## open, since nothing else reads these numbers.
func _refresh_colony_panel(bees: Array) -> void:
	if not colony_panel.is_open():
		return

	var counts := {}
	var total_energy := 0.0
	for b in bees:
		var key: String = "%d|" % b.role
		if b.role == Bee.Role.FORAGER:
			key = "%d|%s" % [b.role, b.resource_type]
		counts[key] = int(counts.get(key, 0)) + 1
		total_energy += b.energy

	var brood_count := 0
	var gyne_count := 0
	var hungry_brood := 0
	var free_cells := 0
	for cell in hive.cells:
		if not is_instance_valid(cell):
			continue
		if cell.content_type == "brood":
			brood_count += 1
			if cell.brood_is_gyne:
				gyne_count += 1
			if cell.brood_fed_seconds <= 0.0:
				hungry_brood += 1
		elif cell.is_empty() and not cell.keep_empty:
			free_cells += 1

	colony_panel.refresh(
		counts,
		{
			"nectar": hive.total("nectar"),
			"pollen": hive.total("pollen"),
			"honey": hive.total_honey(),
			"jelly": hive.total("jelly"),
		},
		{
			"cells": hive.cells.size(), "free": free_cells,
			"brood": brood_count, "gynes": gyne_count, "hungry": hungry_brood,
		},
		(total_energy / max(1, bees.size())) / max(0.001, GameConfig.energy_capacity)
	)

## Clicking a role tally in the colony panel selects every bee in it, so
## you can retask a whole job at once instead of hunting for them.
func _on_role_selection_requested(role: int, focus: String) -> void:
	for b in selected_bees:
		if is_instance_valid(b):
			b.set_selected(false)
	selected_bees.clear()

	for b in get_tree().get_nodes_in_group("bees"):
		if not is_instance_valid(b) or b.role != role:
			continue
		if focus != "" and b.resource_type != focus:
			continue
		b.set_selected(true)
		selected_bees.append(b)

	hud.update_selection(selected_bees)

# --- saving and loading -------------------------------------------

func save_run() -> void:
	if SaveGame.save(self):
		hud.show_warning("Run saved.")
	else:
		hud.show_warning("The run could not be saved — check the log for why.")

## Replays a saved run over the freshly built world. Order matters: the
## comb has to exist before bees can be pointed at it, and mined-out soil
## has to be removed before routes are rebuilt.
func _restore(data: Dictionary) -> void:
	if data.is_empty():
		hud.show_warning("There was no save to load.")
		return

	var clock: Dictionary = data.get("clock", {})
	GameConfig.sim_time = float(clock.get("sim_time", 0.0))
	day = int(clock.get("day", 1))
	next_bee_id = int(clock.get("next_bee_id", 1))
	hud.update_day(day)

	var weather: Dictionary = data.get("weather", {})
	GameConfig.rain_intensity = float(weather.get("intensity", 0.0))
	rain_target = float(weather.get("target", 0.0))
	rain_seconds_left = float(weather.get("seconds_left", 0.0))

	var totals: Dictionary = data.get("totals", {})
	hive.lifetime_nectar_collected = float(totals.get("nectar", 0.0))
	hive.lifetime_pollen_collected = float(totals.get("pollen", 0.0))
	hive.lifetime_births = int(totals.get("births", 0))

	_restore_soil(data.get("soil", {}))
	_restore_cells(data.get("cells", []))
	_restore_flowers(data.get("flowers", []))
	_restore_bees(data.get("bees", []))

	hive.build_navigation()
	hive.refresh_edge_flags()
	hive.invalidate_index()
	hive.announce()
	_update_population_readout()
	hud.show_warning("Run loaded — day %d." % day)

## Any soil block the save doesn't list has been dug out, so it becomes
## open floor. Blocks that are listed get their marking and progress back.
func _restore_soil(soil: Dictionary) -> void:
	var still_there := {}
	for pair in soil.get("present", []):
		still_there[Vector2i(int(pair[0]), int(pair[1]))] = true

	var to_remove: Array = []
	for node in hive.occupied_tiles.values():
		if node == null or not is_instance_valid(node) or not node.is_in_group("soil_blocks"):
			continue
		if not still_there.has(node.axial):
			to_remove.append(node)

	var centre_local := _hive_centre_local()
	var spacing: float = GameConfig.hive_cell_spacing
	for block in to_remove:
		var hex: Vector2i = block.axial
		hive.occupied_tiles.erase(hex)
		block.queue_free()
		_add_floor_tile(hex, centre_local, spacing)

	for entry in soil.get("marked", []):
		var hex := Vector2i(int(entry.q), int(entry.r))
		var node = hive.occupied_tiles.get(hex)
		if node != null and is_instance_valid(node) and node.is_in_group("soil_blocks"):
			node.mine_progress = float(entry.progress)
			node.set_marked(bool(entry.marked))

## The comb is rebuilt from the save wholesale: whatever the starting
## layout gave us is discarded, because a loaded run's comb has grown,
## been re-designated and been dug into since.
func _restore_cells(cells: Array) -> void:
	for cell in hive.cells:
		if is_instance_valid(cell):
			hive.occupied_tiles.erase(cell.axial)
			cell.queue_free()
	hive.cells = []

	var centre_local := _hive_centre_local()
	var spacing: float = GameConfig.hive_cell_spacing
	for entry in cells:
		var hex := Vector2i(int(entry.q), int(entry.r))
		var cell := HiveCell.new()
		cell.axial = hex
		cell.position = centre_local + Shapes.hex_to_pixel(hex.x, hex.y, spacing)
		hive_root.add_child(cell)

		cell.content_type = str(entry.get("content", ""))
		cell.amount = float(entry.get("amount", 0.0))
		cell.designated_type = str(entry.get("designated", ""))
		cell.keep_empty = bool(entry.get("keep_empty", false))
		cell.evict_requested = bool(entry.get("evict", false))
		cell.evict_mode = str(entry.get("evict_mode", "move"))
		cell.is_built = bool(entry.get("built", true))
		cell.build_progress = float(entry.get("build_progress", 0.0))
		cell.brood_progress = float(entry.get("brood_progress", 0.0))
		cell.brood_fed_seconds = float(entry.get("brood_fed", 0.0))
		cell.unfed_seconds = float(entry.get("unfed", 0.0))
		cell.brood_is_gyne = bool(entry.get("gyne", false))
		cell.clean_progress = float(entry.get("clean", 0.0))
		cell.ripen_progress = float(entry.get("ripen", 0.0))
		cell.hatch_role = int(entry.get("hatch_role", -1))
		cell.hatch_focus = str(entry.get("hatch_focus", "nectar"))
		cell.hatch_automine = bool(entry.get("hatch_automine", false))
		cell.hatch_role_locked = bool(entry.get("hatch_locked", false))
		cell.hatch_gyne = bool(entry.get("hatch_gyne", false))

		hive.cells.append(cell)
		hive.register_tile(hex, cell)

func _restore_flowers(flowers: Array) -> void:
	for f in get_tree().get_nodes_in_group("flowers"):
		if is_instance_valid(f):
			f.queue_free()

	for entry in flowers:
		var flower := Flower.new()
		flower.position = Vector2(float(entry.x), float(entry.y))
		meadow_root.add_child(flower)
		flower.setup(int(entry.species))
		flower.nectar_amount = float(entry.get("nectar", 0.0))
		flower.pollen_amount = float(entry.get("pollen", 0.0))
		flower.age_seconds = float(entry.get("age", 0.0))

func _restore_bees(bees: Array) -> void:
	for b in get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(b):
			b.queue_free()
	queen = null
	selected_bees.clear()

	for entry in bees:
		var bee := Bee.new()
		bee.is_queen = bool(entry.get("queen", false))
		bee.is_gyne = bool(entry.get("gyne", false))
		bee.position = Vector2(float(entry.x), float(entry.y))
		if bool(entry.get("indoors", false)):
			hive_root.add_child(bee)
		else:
			meadow_root.add_child(bee)

		bee.setup(hive, str(entry.get("resource", "nectar")), int(entry.get("id", 0)), int(entry.get("role", 0)), self)
		bee.state = int(entry.get("state", bee.state))
		bee.energy = float(entry.get("energy", GameConfig.energy_capacity))
		bee.age_seconds = float(entry.get("age", 0.0))
		bee.current_load = float(entry.get("load", 0.0))
		bee.current_load_type = str(entry.get("load_type", ""))
		bee.honey_load = float(entry.get("honey_load", 0.0))
		bee.dirt_load = float(entry.get("dirt", 0.0))
		bee.pollen_eaten = float(entry.get("pollen_eaten", 0.0))
		bee.nurse_pollen = float(entry.get("nurse_pollen", 0.0))
		bee.nurse_carb = float(entry.get("nurse_carb", 0.0))
		bee.nurse_carb_type = str(entry.get("nurse_carb_type", ""))
		bee.nurse_jelly = float(entry.get("nurse_jelly", 0.0))
		bee.nurse_mode = str(entry.get("nurse_mode", "feed"))
		bee.architect_mode = str(entry.get("architect_mode", "both"))
		bee.automine = bool(entry.get("automine", false))
		bee.secondary_role = int(entry.get("secondary", -1))
		bee.finish_task_first = bool(entry.get("finish_first", false))
		bee.pending_role = int(entry.get("pending_role", -1))
		bee.preferred_species = str(entry.get("preferred", ""))
		bee.forage_start_point = Vector2(float(entry.get("start_x", INF)), float(entry.get("start_y", INF)))

		if bee.is_queen:
			queen = bee

	# a saved run whose queen was already gone would otherwise reopen the
	# game over screen the moment it loads, which is fair enough
	colony_lost = false

func _on_restart_after_loss() -> void:
	GameConfig.sim_time = 0.0
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

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
	var honey_makers := 0
	for b in get_tree().get_nodes_in_group("bees"):
		match b.role:
			Bee.Role.NURSERY:
				nurses += 1
			Bee.Role.BUILDER:
				builders += 1   # architects
			Bee.Role.FORAGER:
				foragers += 1
			Bee.Role.HONEY_MAKER:
				honey_makers += 1
	hud.update_population(foragers, nurses, builders, honey_makers)

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

## Is the cursor over a panel or control rather than the world?
##
## A scroll wheel event inside the tuning panel is consumed by its
## scroll container -- but only while there is somewhere left to scroll.
## Once it hits the top or bottom the event falls through to here, and
## carrying on scrolling zoomed the whole game in and out from under the
## panel. Checking what the cursor is actually over stops that, and stops
## clicks on a panel starting a selection drag in the world behind it.
func _pointer_over_ui() -> bool:
	return get_viewport().gui_get_hovered_control() != null

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
			KEY_C:
				colony_panel.toggle()

	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed and not _pointer_over_ui():
					_zoom_by(1.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed and not _pointer_over_ui():
					_zoom_by(1.0 / 1.1)
			MOUSE_BUTTON_LEFT:
				if event.pressed and _pointer_over_ui():
					pass   # a click on a panel belongs to the panel
				elif event.pressed:
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
			# clicking a tree or a bank of raised ground says what it is
			var obstacle := _obstacle_at(drag_start)
			if obstacle:
				hud.show_obstacle_popup(obstacle, get_viewport().get_mouse_position())
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

func _obstacle_at(point: Vector2) -> Node2D:
	for o in obstacles:
		if is_instance_valid(o) and o.global_position.distance_to(point) <= o.radius:
			return o
	return null

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

	# nor is an architect's mode -- it says which jobs one will take
	if role_name.begins_with("architect_"):
		var mode: String = role_name.substr("architect_".length())
		for b in selected_bees:
			if is_instance_valid(b):
				b.architect_mode = mode
		hud.update_selection(selected_bees)
		return

	# nor is a nurse's: feeding brood, making royal jelly, or both
	if role_name.begins_with("nurse_"):
		var nurse_mode: String = role_name.substr("nurse_".length())
		for b in selected_bees:
			if is_instance_valid(b):
				b.nurse_mode = nurse_mode
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
		"honey_maker":
			target_role = Bee.Role.HONEY_MAKER
	for b in selected_bees:
		if is_instance_valid(b):
			b.set_role(target_role)
	_update_population_readout()
	hud.update_selection(selected_bees)


func _on_finish_first_requested(value: bool) -> void:
	for b in selected_bees:
		if is_instance_valid(b):
			b.finish_task_first = value
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
		"honey_maker":
			target_role = Bee.Role.HONEY_MAKER
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

func _on_cell_hatch_role_requested(cell: Node2D, role: int, focus: String, use_automine: bool) -> void:
	if not is_instance_valid(cell):
		return
	cell.hatch_role = role
	cell.hatch_focus = focus
	cell.hatch_automine = use_automine
	# Earmarking a cell to raise a particular kind of bee only means
	# anything if eggs actually end up in it, so choosing a role also
	# reserves the cell for brood. Without this, foragers carried on
	# filling it with nectar and the role never came into play.
	if role >= 0 and cell.designated_type != "brood":
		_on_cell_designation_requested(cell, "brood")

## Pins the cell's hatch role so every future bee raised there inherits
## it, rather than the role applying to the next one only.
func _on_cell_hatch_lock_requested(cell: Node2D, locked: bool) -> void:
	if is_instance_valid(cell):
		cell.hatch_role_locked = locked

## Clearing a cell out. "move" hands it to a builder to carry into
## another cell; "discard" throws it out of the hive there and then.
## `keep_empty` is what stops foragers immediately refilling it, which is
## the real problem this solves -- with a lot of foragers running, every
## spare cell fills with nectar and nothing is left for pollen or brood.
func _on_cell_empty_requested(cell: Node2D, method: String, keep_empty: bool) -> void:
	if not is_instance_valid(cell):
		return
	_on_cell_keep_empty_requested(cell, keep_empty)

	if cell.content_type == "" or cell.content_type == "brood":
		return   # nothing to shift, and brood isn't cargo

	# Either way a builder does the work: it walks to the cell, lifts the
	# contents, and then carries them to another cell or out through the
	# entrance to throw away. Discarding used to happen instantly with
	# the resource simply vanishing and no bee involved at all.
	cell.evict_mode = "discard" if method == "discard" else "move"
	cell.evict_requested = true

## Ticking "keep this cell empty" takes effect straight away, whether or
## not the cell is being emptied at the same time.
## Earmarking a cell for a gyne also reserves it for brood, for the same
## reason as setting a hatch role does: an egg has to end up in it.
func _on_cell_gyne_requested(cell: Node2D, as_gyne: bool) -> void:
	if not is_instance_valid(cell):
		return
	cell.hatch_gyne = as_gyne
	if as_gyne and cell.designated_type != "brood":
		_on_cell_designation_requested(cell, "brood")

func _on_cell_keep_empty_requested(cell: Node2D, keep_empty: bool) -> void:
	if not is_instance_valid(cell):
		return
	if keep_empty:
		# "keep this one clear" and "reserve it for X" are contradictory;
		# designating it later clears keep_empty again
		cell.set_designation("")
	cell.keep_empty = keep_empty

func _on_level_chosen(level: int) -> void:
	GameConfig.starting_level = level
	GameConfig.menu_pending = false
	GameConfig.sim_time = 0.0
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

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
