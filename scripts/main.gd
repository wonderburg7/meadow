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
const Roles = preload("res://scripts/roles.gd")
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
const NurseryPanel = preload("res://scripts/nursery_panel.gd")
const DeathMarker = preload("res://scripts/death_marker.gd")
const RainEffect = preload("res://scripts/rain_effect.gd")
const RivalHive = preload("res://scripts/rival_hive.gd")
const SpatialGrid = preload("res://scripts/spatial_grid.gd")
const Season = preload("res://scripts/season.gd")
const WinterPanel = preload("res://scripts/winter_panel.gd")
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
	# An established colony: enough bees and stores that the interesting
	# decisions are about where it goes next rather than whether it
	# survives the first week. `automine` puts the miners straight to
	# work, and `stock` fills some of the comb so the queen can lay from
	# the first moment instead of waiting on the first pollen delivery.
	5: {
		"cells": 12, "nectar_foragers": 16, "pollen_foragers": 6,
		"nurses": 4, "builders": 3, "miners": 3, "automine": true,
		"stock": {"nectar": 4, "pollen": 2},
	},
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
## How far clear of a tree or plateau a flower is planted. This has to
## stay comfortably above Bee.BLOCK_MARGIN, the hard boundary a bee is
## never allowed inside -- a flower any closer than that would sit in
## ground no bee can stand on, and foragers would queue up against the
## edge trying to reach it forever.
const FLOWER_CLEARANCE := 30.0
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
var nursery_panel: CanvasLayer
var winter_panel: CanvasLayer
var rival: Node2D = null
## The year: seasons, disease, winter and gynes leaving.
var season: Node2D = null
var colony_lost: bool = false

## Every bee that has emerged, as {t, key} where key is "role|focus".
## Used for the nursery window's "emerging in the last three minutes"
## figures -- that is the output of the nursery, which is what the zone
## actually controls, rather than what those bees go on to collect.
var emergence_log: Array = []

## Samples of the stores and the population for the colony window's
## history plot.
var history_samples: Array = []
var history_timer: float = 0.0

## Built once when the meadow is laid out. Bees consult this constantly
## for steering, and a scene-tree group query per bee per frame was the
## worst-scaling thing in the simulation. Obstacles never move or appear
## mid-run, so one list serves everybody.
var obstacles: Array = []
## Coarse spatial index over the flowers, so "nearest flower" checks a
## handful of buckets instead of all 250. Rebuilt when the meadow is
## reseeded rather than maintained incrementally -- flowers appear and
## die a few times a minute, not per frame.
var flower_grid = SpatialGrid.new(200.0)
## The same for obstacles. They never move or change during a run, so
## this is built once.
var obstacle_grid = SpatialGrid.new(300.0)
## Mirrors GameConfig.scenery_on, so the toggle is only acted on when it
## actually changes rather than every frame.
var scenery_shown: bool = true

## Weather. Rain waters down open nectar, makes flying heavier, and past
## a point grounds the foragers entirely.
var weather_timer: float = 0.0
var rain_target: float = 0.0
var rain_seconds_left: float = 0.0
var rain_overlay: ColorRect
var rain_effect: Node2D

## Sim time the low-energy warning was last shown, so it can't nag. -INF
## means it hasn't been shown at all yet this run.
var last_energy_warning: float = -INF
var warning_check_timer: float = 5.0
var signal_timer: float = 1.0

var in_hive_view: bool = false
var selected_bees: Array = []
## Comb cells and soil blocks the player has selected. Anything the cell
## or soil popup does applies to the whole list, not just the one clicked.
var selected_cells: Array = []
var selected_blocks: Array = []
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
var awaiting_home_cell: bool = false
var awaiting_mine_home: bool = false
var awaiting_mine_target: bool = false
var awaiting_keep_clear: bool = false
var pending_builder_bees: Array = []
var pending_home_bees: Array = []
var pending_mine_bees: Array = []
var pending_mine_target_bees: Array = []
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

	# The falling streaks themselves, over the colour wash. Screen-space,
	# so they don't slide about when the camera pans.
	rain_effect = RainEffect.new()
	weather_layer.add_child(rain_effect)


	selection_layer = Node2D.new()
	selection_layer.z_index = 100
	selection_layer.draw.connect(_draw_selection_box)
	add_child(selection_layer)

	hud = Hud.new()
	hud.focus_requested.connect(_on_focus_requested)
	hud.role_requested.connect(_on_role_requested)
	hud.view_toggle_requested.connect(_toggle_view)
	hud.colony_panel_requested.connect(func(): _toggle_panel(colony_panel))
	hud.speed_requested.connect(_on_speed_requested)
	hud.cell_designation_requested.connect(_on_cell_designation_requested)
	hud.cell_hatch_role_requested.connect(_on_cell_hatch_role_requested)
	hud.cell_hatch_lock_requested.connect(_on_cell_hatch_lock_requested)
	hud.cell_empty_requested.connect(_on_cell_empty_requested)
	hud.cell_keep_empty_requested.connect(_on_cell_keep_empty_requested)
	hud.cell_gyne_requested.connect(_on_cell_gyne_requested)
	hud.build_cell_requested.connect(_on_build_cell_requested)
	hud.home_cell_requested.connect(_on_home_cell_requested)
	hud.mine_home_requested.connect(_on_mine_home_requested)
	hud.mine_target_requested.connect(_on_mine_target_requested)
	hud.keep_clear_requested.connect(_on_keep_clear_requested)
	hud.restock_targets_requested.connect(_on_restock_targets_requested)
	hud.restock_sources_requested.connect(_on_restock_sources_requested)
	hud.restock_clear_requested.connect(_on_restock_clear_requested)
	hud.soil_mark_requested.connect(_on_soil_mark_requested)
	hud.cell_zone_requested.connect(_on_cell_zone_requested)
	hud.cell_priority_requested.connect(_on_cell_priority_requested)
	hud.cell_close_requested.connect(_on_cell_close_requested)
	hud.cell_fill_close_requested.connect(_on_cell_fill_close_requested)
	hud.nursery_window_requested.connect(_on_nursery_window_requested)
	hud.winter_window_requested.connect(func(): winter_panel.toggle())
	hud.signal_clicked.connect(_on_signal_clicked)
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
	if Session.menu_pending:
		menu.open()

	colony_panel = ColonyPanel.new()
	colony_panel.role_selection_requested.connect(_on_role_selection_requested)
	colony_panel.pinned_changed.connect(func(): hud.pinned_stats_changed())
	add_child(colony_panel)

	nursery_panel = NurseryPanel.new()
	# closing the window has to take the glow off the comb with it,
	# otherwise the hive stays lit up with no panel to explain why
	nursery_panel.closed.connect(_clear_zone_glow)
	nursery_panel.pinned_changed.connect(func(): hud.pinned_stats_changed())
	add_child(nursery_panel)

	winter_panel = WinterPanel.new()
	add_child(winter_panel)

	season = Season.new()
	season.world = self
	season.winter_started.connect(_on_winter_started)
	season.winter_survived.connect(_on_winter_survived)
	season.gyne_released.connect(_on_gyne_released)
	add_child(season)

	game_over = GameOver.new()
	game_over.restart_requested.connect(_on_restart_after_loss)
	game_over.menu_requested.connect(func(): game_over.visible = false; menu.open())
	add_child(game_over)

	hive.storage_changed.connect(func(n, p, h, j): hud.update_storage(n, p, h, j, hive.total_sealed()))
	hud.update_day(day, _season_text())
	hud.update_storage(0, 0, 0, 0)
	hud.update_rates(0.0, 0.0, 0.0)
	hud.set_speed_display(1.0)
	_update_population_readout()
	_apply_view()

	# A pending load is applied last, over the top of a world that has
	# just been built to the saved settings -- see SaveGame's note on why
	# it replays state rather than restoring a scene tree.
	if Session.load_pending:
		Session.load_pending = false
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

	_rebuild_flower_grid()
	obstacle_grid.rebuild(obstacles)

	if GameConfig.rival_hive_on:
		_place_rival_hive()

## Flowers are planted and die often enough to matter but rarely enough
## that a full rebuild is the simplest correct answer. Called whenever
## the set changes rather than on a timer.
func _rebuild_flower_grid() -> void:
	flower_grid.rebuild(get_tree().get_nodes_in_group("flowers"))

## Is `node` inside what the camera can currently see, with a margin?
##
## Used to skip presentation work -- labels, colour lerps -- for things
## off screen. Deliberately not used to skip anything the simulation
## depends on: a bee that stopped foraging because you looked away would
## be a much worse bug than a wasted colour assignment.
##
## The visible rectangle is recomputed once a frame rather than per
## caller, since every bee asks.
var _view_rect: Rect2 = Rect2()
var _view_frame: int = -1

func is_on_screen(node: Node2D) -> bool:
	# The wrong world entirely is the cheapest possible answer.
	var root: Node = node.get_parent()
	if root != (hive_root if in_hive_view else meadow_root):
		return false

	var frame := Engine.get_process_frames()
	if _view_frame != frame:
		_view_frame = frame
		var cam := _active_camera()
		var span: Vector2 = get_viewport_rect().size / cam.zoom.x
		_view_rect = Rect2(cam.position - span * 0.5, span).grow(120.0)
	return _view_rect.has_point(node.global_position)

## Puts the rival colony somewhere in the meadow, kept a good distance
## from the player's hive so the two aren't drawing on the same flowers
## from the first minute. They meet in the middle later, as both grow --
## which is the point.
func _place_rival_hive() -> void:
	var spot: Vector2 = hive.position
	for attempt in range(40):
		var candidate: Vector2 = hive.position + Vector2(
			randf_range(-FLOWER_FIELD_HALF_SIZE.x, FLOWER_FIELD_HALF_SIZE.x),
			randf_range(-FLOWER_FIELD_HALF_SIZE.y, FLOWER_FIELD_HALF_SIZE.y)
		)
		if candidate.distance_to(hive.position) < GameConfig.rival_min_distance:
			continue
		if not _is_clear_ground(candidate):
			continue
		spot = candidate
		break
	if spot == hive.position:
		# nowhere far enough inside the field; put it at the far corner
		# rather than on top of the player
		spot = hive.position + Vector2(FLOWER_FIELD_HALF_SIZE.x * 0.9, FLOWER_FIELD_HALF_SIZE.y * 0.6)
		spot = _clear_of_obstacles(spot)

	rival = RivalHive.new()
	rival.position = spot
	rival.world = self
	meadow_root.add_child(rival)

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
	var level: Dictionary = LEVELS.get(Session.starting_level, {})
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
		if point.distance_to(obstacle.position) < obstacle.radius + FLOWER_CLEARANCE:
			return false
	return true

## Pushes `point` out to the boundary of any solid obstacle it lands
## inside, plus a little margin so a bee can actually stand on it.
func _clear_of_obstacles(point: Vector2) -> Vector2:
	var result := point
	for obstacle in obstacles:
		if not is_instance_valid(obstacle) or not obstacle.solid:
			continue
		var edge: float = obstacle.radius + FLOWER_CLEARANCE
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
	var level: Dictionary = LEVELS.get(Session.starting_level, {})
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
	_stock_starting_comb(cells, level)

## Puts something in the comb before the run starts, for stages that
## begin partway in. Filled cells are taken from the outside of the
## spiral inwards, leaving the middle free for the queen to lay in --
## otherwise she has nowhere to start and the stocked hive is worse off
## than an empty one.
func _stock_starting_comb(cells: Array, level: Dictionary) -> void:
	var stock: Dictionary = level.get("stock", {})
	if stock.is_empty() or cells.is_empty():
		return
	var index: int = cells.size() - 1
	for resource in ["nectar", "pollen", "honey"]:
		for i in range(int(stock.get(resource, 0))):
			if index < 0:
				return
			var cell = cells[index]
			cell.add_resource(resource, cell.capacity_for(resource))
			index -= 1

func _spawn_hive_occupants(centre_local: Vector2, interior_rings: int, spacing: float) -> void:
	# the queen is an ordinary bee with is_queen set -- she can be
	# reassigned to forage or build like anyone else
	queen = Bee.new()
	queen.is_queen = true
	queen.position = centre_local + Vector2(0, (interior_rings - 3) * spacing * 1.5)
	hive_root.add_child(queen)
	queen.setup(hive, "pollen", 0, Bee.Role.EGG_LAYER, self)

	var level: Dictionary = LEVELS.get(Session.starting_level, {})
	var nurses: int = int(level.nurses) if not level.is_empty() else int(GameConfig.starting_nurses)
	var builders: int = int(level.builders) if not level.is_empty() else int(GameConfig.starting_builders)
	var miners: int = int(level.miners) if not level.is_empty() else int(GameConfig.starting_miners)
	var honey_makers: int = 0 if not level.is_empty() else int(GameConfig.starting_honey_makers)
	for i in range(nurses):
		_spawn_indoor_bee(Bee.Role.NURSERY)
	for i in range(builders):
		_spawn_indoor_bee(Bee.Role.BUILDER)
	for i in range(miners):
		var miner := _spawn_indoor_bee(Bee.Role.MINER)
		# Later stages start their miners already working, so the hive is
		# visibly opening up rather than waiting to be told to.
		if miner != null and bool(level.get("automine", false)):
			miner.automine = true
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
func _spawn_hatched_bee(role: int, cell: Node2D, as_gyne: bool = false, focus_override: String = "") -> void:
	var bee := Bee.new()
	bee.is_gyne = as_gyne   # must be set before _ready, which sizes the body
	bee.position = cell.position
	hive_root.add_child(bee)
	# The cell carries the sub-mode for the role as well as the role
	# itself, so "raises pollen foragers" or "raises automining miners"
	# comes out right without you having to select the new bee and set it
	# up by hand every time. `focus_override` is what the caller decided,
	# which matters for a cell with no role set: that raises a plain
	# nectar forager rather than inheriting a stale focus from whatever
	# the cell was last configured as.
	var focus: String = focus_override if focus_override != "" else cell.hatch_focus
	if focus == "":
		focus = "nectar"
	# A comb worker's sub-mode travels in the same field as a forager's
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

func _spawn_indoor_bee(role: int) -> Node2D:
	var bee := Bee.new()
	bee.position = _hive_centre_local() + Vector2(randf_range(-50, 50), randf_range(60, 110))
	hive_root.add_child(bee)
	bee.setup(hive, "nectar", next_bee_id, role, self)
	next_bee_id += 1
	return bee

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
	_apply_scenery_setting()

	if not get_tree().paused:
		Session.sim_time += delta
		var new_day: int = 1 + int(Session.sim_time / max(1.0, GameConfig.seconds_per_day))
		if new_day != day:
			day = new_day
			hud.update_day(day, _season_text())
		_hatch_ready_brood()
		_reseed_meadow(delta)
		_advance_weather(delta)
		_check_for_loss()
		_check_colony_energy(delta)
		_refresh_signals(delta)
		_sample_history(delta)
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
		_rebuild_flower_grid()
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
		# A cell with no role named raises an ordinary nectar forager --
		# the safe default, and the thing a colony short of everything
		# else most often needs.
		var role: int = cell.hatch_role if cell.hatch_role >= 0 else Bee.Role.FORAGER
		var focus: String = cell.hatch_focus if cell.hatch_role >= 0 else "nectar"
		var as_gyne: bool = cell.brood_is_gyne
		_record_emergence(role, focus, as_gyne)
		cell.clear_cell()
		_spawn_hatched_bee(role, cell, as_gyne, focus)
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
		Session.rain_intensity = 0.0
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
	Session.rain_intensity = move_toward(Session.rain_intensity, rain_target, delta * 0.25)
	_apply_rain_overlay()

func _apply_rain_overlay() -> void:
	if rain_overlay == null:
		return
	rain_overlay.color = Color(0.35, 0.45, 0.62, Session.rain_intensity * 0.35)
	var showing: bool = Session.rain_intensity > 0.01 and not in_hive_view
	rain_overlay.visible = showing
	# Rain is only visible from outside. Inside the hive you find out
	# about it the way the colony does -- the foragers stop coming back.
	if rain_effect != null:
		rain_effect.visible = showing

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

	if Session.sim_time - last_energy_warning < GameConfig.low_energy_gap:
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

	last_energy_warning = Session.sim_time
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
	var comb_workers := 0
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
				comb_workers += 1

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
		lines.append(["%d bees are about to starve" % starving, 2, "starving"])
	if hungry_brood > 0:
		lines.append(["%d larvae are going hungry" % hungry_brood, 2, "hungry_brood"])
	if dead_cells > 0:
		lines.append(["%d cells blocked by dead larvae" % dead_cells, 2, "dead_cells"])
	# Suppressed for the first week: a colony this young genuinely has no
	# pollen and there is nothing useful to do about it, so saying so from
	# the first minute is noise that teaches you to ignore the strip.
	if day >= int(GameConfig.pollen_warning_first_day) and hive.total("pollen") < GameConfig.egg_pollen_cost * 0.5:
		lines.append(["Almost no pollen — the queen cannot lay", 2])
	if hive.total("nectar") < 40.0 and hive.total_honey() < 10.0:
		lines.append(["Food is running out", 2])
	if nurses == 0 and hive.cells_holding("brood").size() > 0:
		lines.append(["No nurses — brood will not develop at all", 2, ""])
	if free_cells == 0:
		lines.append(["No free cells — nowhere to store or lay", 1])
	if hungry > 0:
		lines.append(["%d bees running low on energy" % hungry, 1, "hungry"])
	if foragers == 0:
		lines.append(["No foragers — nothing is coming in", 1, ""])
	if comb_workers == 0 and dead_cells > 0:
		lines.append(["No comb workers to clear the blocked cells", 1, "dead_cells"])
	if Session.rain_intensity > GameConfig.rain_forage_limit:
		lines.append(["Raining hard — foragers are grounded", 1])
	elif Session.rain_intensity > 0.05:
		lines.append(["Raining — nectar is watered down and flying costs more", 0])

	hud.update_signals(lines)
	_refresh_panels(bees)

## Feeds the colony overview and the nursery window. The population and
## comb figures are computed once here and shared between the corner
## readouts and both panels, so they can never disagree.
func _refresh_panels(bees: Array) -> void:
	var counts := _role_counts()
	# The mean of each bee's own percentage, clamped per bee, rather than
	# the total divided by the total capacity. The two only agree while
	# every bee is within range, and one bee sitting on a large negative
	# energy used to drag the whole figure down -- which is what made this
	# read far lower than any bee you could actually click on.
	var energy_share := 0.0
	for b in bees:
		energy_share += clampf(b.energy / max(0.001, GameConfig.energy_capacity), 0.0, 1.0)

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

	var mean_energy: float = energy_share / max(1, bees.size())
	var comb_text := "Comb — %d cells, %d free · brood %d (%d gynes), %d hungry" % [
		hive.cells.size(), free_cells, brood_count, gyne_count, hungry_brood,
	]
	if season != null:
		var health: String = season.disease_text()
		if health != "":
			comb_text += "\n%s" % health
	hud.update_comb(comb_text)
	hud.update_energy(mean_energy)

	if colony_panel.is_open():
		colony_panel.refresh(counts, hud.corner_texts, history_samples)

	# The nursery figures are computed whenever the window is open *or*
	# one of them is starred into the corner. Otherwise starring a
	# nursery readout and closing the window would freeze it at whatever
	# it last said, which is worse than not showing it at all.
	if nursery_panel.is_open() or _nursery_stat_pinned():
		nursery_panel.refresh(
			hive.zone_summary(), counts, _emergence_counts(), GameConfig.emergence_window_seconds
		)
		for key in nursery_panel.corner_texts.keys():
			hud.corner_texts[key] = nursery_panel.corner_texts[key]
		hud.refresh_corner()
	_apply_zone_glow()
	_refresh_winter()

# --- winter -------------------------------------------------------

## What the colony will need to get through the winter, and what it has.
##
## Worked out from the colony's own size rather than a fixed target, so
## it moves as the colony does. That is the whole tension of the run-up:
## every bee you add is another mouth to feed through the winter, so
## growing now is directly at odds with surviving later. A fixed target
## wouldn't create that at all.
##
## Honey counts at `honey_energy_factor` because that is genuinely what
## it is worth -- which is also the argument for the honey-maker role,
## made in numbers the player can see.
func _winter_forecast() -> Dictionary:
	var bees: int = get_tree().get_nodes_in_group("bees").size()
	var seconds_of_winter: float = GameConfig.winter_length_days * GameConfig.seconds_per_day
	var required: float = (
		bees * GameConfig.energy_burn_rate * GameConfig.winter_burn_factor * seconds_of_winter
	)
	var held: float = (
		hive.total("nectar") + hive.total_honey() * GameConfig.honey_energy_factor
	)
	var days_left: float = max(0.0, Session.winter_starts_day - day)
	return {
		"bees": bees,
		"required_energy": required,
		"held_energy": held,
		"days_left": days_left,
	}

## Starts the countdown. Called from the tuning panel.
func begin_winter_countdown() -> void:
	Session.winter_coming = true
	Session.winter_starts_day = day + GameConfig.winter_countdown_days
	winter_panel.open()
	hud.set_winter_button_visible(true)
	hud.show_warning(
		"Winter will arrive on day %d. The forecast in the top right shows what the colony will need to last it out, and how far short it is. Every bee you add between now and then is another mouth to feed through it."
		% int(Session.winter_starts_day)
	)

func _refresh_winter() -> void:
	if not Session.winter_coming:
		return
	var forecast := _winter_forecast()
	winter_panel.refresh(forecast)
	hud.corner_texts["winter"] = winter_panel.corner_text
	hud.refresh_corner()

# --- the year -----------------------------------------------------

## The line beside the day counter: where in the year the colony is, and
## how many gynes it has got away. The score belongs next to the clock
## because the two together are the run -- how far through, and how much
## to show for it.
func _season_text() -> String:
	var parts: Array = []
	if Session.winter_here:
		parts.append("Winter, %d days left" % int(max(0.0, Session.winter_ends_day - day)))
	elif GameConfig.seasons_on:
		var through: float = Flower.season_fraction()
		var name: String = "Early season"
		if through > 0.66:
			name = "Late season"
		elif through > 0.33:
			name = "Midsummer"
		parts.append(name)
	if Session.gynes_released > 0:
		parts.append("%d gynes away" % Session.gynes_released)
	return "  ".join(parts)

func _on_winter_started() -> void:
	hud.show_warning(
		"Winter has arrived. The foragers are staying in, nothing more is coming from the meadow, and the colony is living on what is in the comb. It lasts %d days."
		% int(GameConfig.winter_length_days)
	)

func _on_winter_survived(losses: int) -> void:
	if losses > 0:
		hud.show_warning(
			"Spring. The colony came through the winter, %d bees lighter. Foraging can start again."
			% losses
		)
	else:
		hud.show_warning("Spring, and not a bee lost. Foraging can start again.")

## A gyne got away. This is the score, so it is worth saying out loud
## rather than only appearing in a readout.
func _on_gyne_released(total: int) -> void:
	hud.show_warning(
		"A gyne has left to found a colony of her own. That is %d away this run — the only thing a season is really measured in."
		% total
	)
	_update_population_readout()

## Clicking a line in the problem strip selects whatever it is about, or
## takes you to it. Being told there are hungry larvae and then having to
## hunt for them yourself is most of the work of acting on the warning.
func _on_signal_clicked(action: String) -> void:
	match action:
		"starving":
			_select_bees_where(func(b): return b.energy < GameConfig.energy_capacity * 0.15)
		"hungry":
			_select_bees_where(func(b): return b.energy < GameConfig.energy_capacity * GameConfig.low_energy_warning_level)
		"hungry_brood":
			_focus_cells(func(c): return c.content_type == "brood" and c.brood_fed_seconds <= 0.0)
		"dead_cells":
			_focus_cells(func(c): return c.needs_cleaning())

func _select_bees_where(test: Callable) -> void:
	for b in selected_bees:
		if is_instance_valid(b):
			b.set_selected(false)
	selected_bees.clear()
	for b in get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(b) and test.call(b):
			b.set_selected(true)
			selected_bees.append(b)
	hud.update_selection(selected_bees)
	if not selected_bees.is_empty():
		_active_camera().position = selected_bees[0].global_position

## Selects the cells concerned and points the camera at them, switching
## to the hive view since that is where they are.
func _focus_cells(test: Callable) -> void:
	var found: Array = []
	for cell in hive.cells:
		if is_instance_valid(cell) and test.call(cell):
			found.append(cell)
	if found.is_empty():
		return
	if not in_hive_view:
		in_hive_view = true
		_apply_view()
	_select_cells(found, false)
	_active_camera().position = found[0].global_position

func _nursery_stat_pinned() -> bool:
	for key in Session.pinned_stats:
		if str(key).begins_with("nursery_"):
			return true
	return false

## A sample of the things worth watching over time. Taken on the sim
## clock rather than the wall clock, so fast-forwarding compresses the
## plot the same way it compresses everything else.
func _sample_history(delta: float) -> void:
	history_timer -= delta
	if history_timer > 0.0:
		return
	history_timer = max(1.0, GameConfig.history_sample_seconds)
	# Trim the emergence log here as well as when it's read: otherwise a
	# long run with the nursery window closed would keep every birth it
	# ever had.
	_trim_emergence_log()
	history_samples.append({
		"t": Session.sim_time,
		"bees": get_tree().get_nodes_in_group("bees").size(),
		"nectar": hive.total("nectar"),
		"pollen": hive.total("pollen"),
		"honey": hive.total_honey(),
	})
	while history_samples.size() > int(GameConfig.history_points):
		history_samples.pop_front()

## Bees that have emerged inside the window, counted by what they came
## out as. Old entries are dropped here rather than on a timer, so the
## list can't grow without bound over a long run.
func _emergence_counts() -> Dictionary:
	_trim_emergence_log()
	var counts := {}
	for entry in emergence_log:
		counts[entry.key] = int(counts.get(entry.key, 0)) + 1
	return counts

func _trim_emergence_log() -> void:
	var cutoff: float = Session.sim_time - GameConfig.emergence_window_seconds
	while not emergence_log.is_empty() and float(emergence_log[0].t) < cutoff:
		emergence_log.pop_front()

## Lights up every nursery-zone cell in the colour of the role it raises
## while the nursery window is open.
##
## The comb itself is no longer dimmed. Dimming was meant to make the
## zone stand out, but the thing you most want to read while the window
## is open is the comb -- what is in each cell, how full it is, which are
## free -- and washing it out made that harder, not easier. A bright
## border round the zone cells does the job on its own.
func _apply_zone_glow() -> void:
	var showing: bool = nursery_panel.is_open() and in_hive_view
	if not showing:
		_clear_zone_glow()
		return
	for cell in hive.cells:
		if not is_instance_valid(cell):
			continue
		if cell.is_nursery_cell():
			cell.set_zone_glow(true, NurseryPanel.colour_for(cell.hatch_role, cell.hatch_focus, cell.hatch_gyne))
		else:
			cell.set_zone_glow(false)

## The colony and nursery windows both live down the left-hand side and
## would sit on top of each other, so opening one closes the other. They
## also answer different questions, so wanting both at once is unlikely
## enough that overlapping panels would be the more annoying outcome.
func _toggle_panel(panel: CanvasLayer) -> void:
	if panel == nursery_panel:
		_on_nursery_window_requested()
		return
	if nursery_panel.is_open():
		nursery_panel.close()
	panel.toggle()

## Opening the nursery window lights the comb up straight away rather
## than at the next refresh, which matters because the refresh is paused
## with the game and looking at the zone while paused is reasonable.
func _on_nursery_window_requested() -> void:
	if nursery_panel.is_open():
		nursery_panel.close()
		return
	if colony_panel.is_open():
		colony_panel.toggle()
	nursery_panel.open()
	if not in_hive_view:
		in_hive_view = true
	_apply_view()
	nursery_panel.refresh(
		hive.zone_summary(),
		_role_counts(),
		_emergence_counts(),
		GameConfig.emergence_window_seconds
	)

## The live population, keyed by job. Shared by the colony window, the
## nursery ring and the corner readouts so they can't drift apart.
func _role_counts() -> Dictionary:
	var counts := {}
	for b in get_tree().get_nodes_in_group("bees"):
		if not is_instance_valid(b):
			continue
		var key: String = "%d|" % b.role
		if b.role == Bee.Role.FORAGER:
			key = "%d|%s" % [b.role, b.resource_type]
		counts[key] = int(counts.get(key, 0)) + 1
	return counts

# --- comb overlays ------------------------------------------------
## Colour the whole comb by one property at a time, so a question about
## the hive can be answered by looking at it rather than by clicking
## thirty cells. The nursery zone glow proved the pattern works; this
## generalises it.
##
## Cycled with O rather than buried in a menu, because the useful thing
## is flicking between them.
const COMB_OVERLAYS := ["", "contents", "fill", "role", "reserved"]
const OVERLAY_NAMES := {
	"": "off",
	"contents": "what each cell holds",
	"fill": "how full each cell is",
	"role": "what each nursery cell raises",
	"reserved": "what each cell is reserved for",
}

func _cycle_comb_overlay() -> void:
	if not in_hive_view:
		in_hive_view = true
		_apply_view()
	var index: int = COMB_OVERLAYS.find(Session.comb_overlay)
	Session.comb_overlay = COMB_OVERLAYS[(index + 1) % COMB_OVERLAYS.size()]
	_apply_comb_overlay()
	hud.show_warning("Comb overlay: %s. Press O again to cycle." % OVERLAY_NAMES[Session.comb_overlay])

func _apply_comb_overlay() -> void:
	for cell in hive.cells:
		if is_instance_valid(cell):
			cell.set_overlay(Session.comb_overlay)

# --- undo ---------------------------------------------------------
## One step of undo for cell designation, which is the action most often
## done to a lot of cells at once and so the one most worth being able to
## take back. Records what each cell was before the change.
var _designation_undo: Array = []

func _remember_designations(cells: Array) -> void:
	_designation_undo = []
	for cell in cells:
		if is_instance_valid(cell):
			_designation_undo.append({
				"cell": cell,
				"designated": cell.designated_type,
				"keep_empty": cell.keep_empty,
				"priority": cell.nursery_priority,
			})

func _undo_last_designation() -> void:
	if _designation_undo.is_empty():
		hud.show_warning("Nothing to undo.")
		return
	var restored := 0
	for entry in _designation_undo:
		var cell = entry.cell
		if not is_instance_valid(cell):
			continue
		cell.set_designation(entry.designated)
		cell.keep_empty = entry.keep_empty
		cell.nursery_priority = entry.priority
		restored += 1
	_designation_undo = []
	hud.show_warning("Undone — %d cells put back." % restored)

func _clear_zone_glow() -> void:
	for cell in hive.cells:
		if is_instance_valid(cell):
			cell.set_zone_glow(false)

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
	Session.sim_time = float(clock.get("sim_time", 0.0))
	day = int(clock.get("day", 1))
	next_bee_id = int(clock.get("next_bee_id", 1))
	hud.update_day(day, _season_text())

	var weather: Dictionary = data.get("weather", {})
	Session.rain_intensity = float(weather.get("intensity", 0.0))
	rain_target = float(weather.get("target", 0.0))
	rain_seconds_left = float(weather.get("seconds_left", 0.0))

	var totals: Dictionary = data.get("totals", {})
	hive.lifetime_nectar_collected = float(totals.get("nectar", 0.0))
	hive.lifetime_pollen_collected = float(totals.get("pollen", 0.0))
	hive.lifetime_births = int(totals.get("births", 0))

	var session_state: Dictionary = data.get("session", {})
	Session.winter_coming = bool(session_state.get("winter_coming", false))
	Session.winter_starts_day = float(session_state.get("winter_starts_day", 0.0))
	Session.winter_here = bool(session_state.get("winter_here", false))
	Session.winter_ends_day = float(session_state.get("winter_ends_day", 0.0))
	Session.gynes_released = int(session_state.get("gynes_released", 0))
	hud.set_winter_button_visible(Session.winter_coming)

	_restore_soil(data.get("soil", {}))
	_restore_cells(data.get("cells", []))
	_restore_hive_state(data.get("hive", {}))
	_restore_flowers(data.get("flowers", []))
	_rebuild_flower_grid()
	# Bees last: their orders point at cells, so the comb has to exist
	# before those references can be resolved.
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
		cell.nursery_priority = int(entry.get("priority", 1))
		cell.is_closed = bool(entry.get("closed", false))
		cell.fill_then_close = bool(entry.get("fill_close", false))

		hive.cells.append(cell)
		hive.register_tile(hex, cell)

## Hive-level state that isn't a cell: reserved open ground, and the
## queen's priority credit. Restoring the credit matters more than it
## looks -- starting it from zero would give whichever tier happened to
## come first an extra egg on every load.
func _restore_hive_state(state: Dictionary) -> void:
	hive.keep_clear_tiles.clear()
	for pair in state.get("keep_clear", []):
		hive.keep_clear_tiles[Vector2i(int(pair[0]), int(pair[1]))] = true
	var credit: Array = state.get("tier_credit", [])
	if credit.size() == 3:
		hive._tier_credit = [float(credit[0]), float(credit[1]), float(credit[2])]
	hive._brood_pointer = int(state.get("brood_pointer", 0))

## Turns saved tile references back into the cells now sitting on those
## tiles. Anything whose tile no longer holds a cell is dropped.
func _cells_at(refs: Array) -> Array:
	var out: Array = []
	for pair in refs:
		var node = hive.occupied_tiles.get(Vector2i(int(pair[0]), int(pair[1])))
		if node != null and is_instance_valid(node) and node.is_in_group("hive_cells"):
			out.append(node)
	return out

func _blocks_at(refs: Array) -> Array:
	var out: Array = []
	for pair in refs:
		var node = hive.occupied_tiles.get(Vector2i(int(pair[0]), int(pair[1])))
		if node != null and is_instance_valid(node) and node.is_in_group("soil_blocks"):
			out.append(node)
	return out

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

		# The bee's own orders. Tile references rather than nodes, since
		# every cell and block was rebuilt a moment ago.
		bee.build_queue = []
		for pair in entry.get("build_queue", []):
			bee.build_queue.append(Vector2i(int(pair[0]), int(pair[1])))
		bee.has_manual_build_target = not bee.build_queue.is_empty()
		if bee.has_manual_build_target:
			bee.manual_build_hex = bee.build_queue[0]
		bee.mine_queue = _blocks_at(entry.get("mine_queue", []))

		var home: Array = entry.get("home_hex", [])
		if home.size() == 2:
			bee.set_home_hex(Vector2i(int(home[0]), int(home[1])))
		var mine_home: Array = entry.get("mine_home", [])
		if mine_home.size() == 2:
			bee.set_mine_home_hex(Vector2i(int(mine_home[0]), int(mine_home[1])))

		bee.restock_resource = str(entry.get("restock_resource", ""))
		bee.restock_targets = _cells_at(entry.get("restock_targets", []))
		bee.restock_sources = _cells_at(entry.get("restock_sources", []))
		bee.restock_blocked = _cells_at(entry.get("restock_blocked", []))

		if bee.is_queen:
			queen = bee

	# a saved run whose queen was already gone would otherwise reopen the
	# game over screen the moment it loads, which is fair enough
	colony_lost = false

func _on_restart_after_loss() -> void:
	Session.reset_run_state()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _sample_rates() -> void:
	rate_samples.append({
		"t": Session.sim_time,
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
				builders += 1   # comb workers
			Bee.Role.FORAGER:
				foragers += 1
			Bee.Role.HONEY_MAKER:
				honey_makers += 1
	hud.update_population(foragers, nurses, builders, honey_makers)

func _prune_selection() -> void:
	# cells and blocks can be freed under us -- a mined block, a cell
	# rebuilt on load -- so drop the dead references before anything acts
	# on them
	selected_cells = selected_cells.filter(func(c): return is_instance_valid(c))
	selected_blocks = selected_blocks.filter(func(b): return is_instance_valid(b))

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

# --- control groups -----------------------------------------------
## Saved by bee id rather than by node, so a group survives its members
## dying: recalling it simply picks up whoever is still alive.

func _save_control_group(slot: int) -> void:
	var ids: Array = []
	for b in selected_bees:
		if is_instance_valid(b):
			ids.append(b.bee_id)
	if ids.is_empty():
		Session.control_groups.erase(slot)
		hud.show_warning("Group %d cleared." % slot)
		return
	Session.control_groups[slot] = ids
	hud.show_warning("Group %d saved — %d bees. Press %d to select them again." % [slot, ids.size(), slot])

func _recall_control_group(slot: int) -> void:
	var ids: Array = Session.control_groups.get(slot, [])
	if ids.is_empty():
		return
	for b in selected_bees:
		if is_instance_valid(b):
			b.set_selected(false)
	selected_bees.clear()
	for b in get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(b) and ids.has(b.bee_id):
			b.set_selected(true)
			selected_bees.append(b)
	hud.update_selection(selected_bees)
	if selected_bees.is_empty():
		hud.show_warning("Every bee in group %d has died." % slot)

## Frames whatever matters in the current view: the comb in the hive, or
## the colony's bees and the hive marker in the meadow.
func _zoom_to_fit() -> void:
	var points: Array = []
	if in_hive_view:
		for cell in hive.cells:
			if is_instance_valid(cell):
				points.append(cell.global_position)
	else:
		points.append(meadow_root.to_global(hive.position))
		for b in _bees_in_current_view():
			points.append(b.global_position)
	if points.size() < 2:
		return

	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	bounds = bounds.grow(120.0)

	var cam := _active_camera()
	cam.position = bounds.get_center()
	var view: Vector2 = get_viewport_rect().size
	var fit: float = min(view.x / max(1.0, bounds.size.x), view.y / max(1.0, bounds.size.y))
	cam.zoom = Vector2(clampf(fit, MIN_ZOOM, MAX_ZOOM), clampf(fit, MIN_ZOOM, MAX_ZOOM))

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
	# the zone glow only makes sense over the comb, and the rain only
	# outside it, so both follow the view rather than waiting for the
	# next refresh -- which matters because that refresh is paused with
	# the game
	if nursery_panel != null:
		_apply_zone_glow()
	_apply_rain_overlay()

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
				_toggle_panel(colony_panel)
			KEY_N:
				_toggle_panel(nursery_panel)
			KEY_F:
				_zoom_to_fit()
			KEY_O:
				_cycle_comb_overlay()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
				# Ctrl+number saves the selection, plain number recalls it.
				# The usual convention, and worth having the moment a
				# colony is big enough that finding your foragers is a job.
				var slot: int = event.keycode - KEY_0
				if event.ctrl_pressed:
					_save_control_group(slot)
				else:
					_recall_control_group(slot)
			KEY_Z:
				if event.ctrl_pressed:
					_undo_last_designation()

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
					# shift adds bees to a selection; ctrl adds comb cells
					# and soil blocks to theirs
					_finish_drag(event.shift_pressed, event.ctrl_pressed)
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

func _finish_drag(additive: bool, add_to_group_selection: bool = false) -> void:
	if not dragging:
		return
	dragging = false
	selection_layer.queue_redraw()

	# Placement modes consume the click. Ctrl held means "and another",
	# so the mode stays on and the target is added to the end of the
	# order rather than replacing it.
	if awaiting_build_cell:
		_place_build_cell(drag_start, add_to_group_selection)
		return
	if awaiting_mine_target:
		_place_mine_target(drag_start, add_to_group_selection)
		return
	if awaiting_keep_clear:
		_place_keep_clear(drag_start, add_to_group_selection)
		return
	if awaiting_home_cell:
		_place_home_cell(drag_start)
		return
	if awaiting_mine_home:
		_place_mine_home(drag_start)
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
				_select_cells([cell], add_to_group_selection)
				return
			# soil: any block can be flagged, not just an exposed one --
			# marking a whole seam and letting miners work inward as each
			# layer opens up is a reasonable thing to want to do
			var block := _soil_at(drag_start)
			if block:
				_select_blocks([block], add_to_group_selection)
				return
			_clear_cell_selection()
			_clear_block_selection()
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

		# A box in the hive view can cover bees, comb and soil at once.
		# Bees win, because moving and retasking them is the more common
		# thing to want; comb comes next, and soil only if the box caught
		# neither. Without a fixed order a drag near the wall would do
		# something different depending on exactly where it started.
		if picked.is_empty() and in_hive_view:
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

	# Selecting bees drops any comb or soil selection, so the highlight
	# rings never outlive the popup that acts on them.
	if not picked.is_empty():
		_clear_cell_selection()
		_clear_block_selection()

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

# --- selecting comb and soil --------------------------------------
## Comb cells and soil blocks are selected the same way bees are: click
## one, ctrl-click to add, or drag a box. Everything the popup then does
## applies to the whole selection, so re-designating twenty cells is one
## action rather than twenty.

func _select_cells(cells: Array, additive: bool) -> void:
	_clear_block_selection()
	if not additive:
		_clear_cell_selection()
	for cell in cells:
		if not is_instance_valid(cell):
			continue
		if selected_cells.has(cell):
			if additive:
				# ctrl-clicking one that's already in takes it out again
				cell.set_selected(false)
				selected_cells.erase(cell)
			continue
		cell.set_selected(true)
		selected_cells.append(cell)

	if selected_cells.is_empty():
		return
	hud.show_cell_popup(selected_cells[0], get_viewport().get_mouse_position(), selected_cells.size())

func _clear_cell_selection() -> void:
	for cell in selected_cells:
		if is_instance_valid(cell):
			cell.set_selected(false)
	selected_cells.clear()

func _select_blocks(blocks: Array, additive: bool) -> void:
	_clear_cell_selection()
	if not additive:
		_clear_block_selection()
	for block in blocks:
		if not is_instance_valid(block):
			continue
		if selected_blocks.has(block):
			if additive:
				block.set_selected(false)
				selected_blocks.erase(block)
			continue
		block.set_selected(true)
		selected_blocks.append(block)

	if selected_blocks.is_empty():
		return
	var reachable := 0
	for block in selected_blocks:
		if hive.mine_stand_hex(block) != null:
			reachable += 1
	hud.show_soil_popup(selected_blocks.size(), reachable, get_viewport().get_mouse_position())

func _clear_block_selection() -> void:
	for block in selected_blocks:
		if is_instance_valid(block):
			block.set_selected(false)
	selected_blocks.clear()

## Marking or unmarking every selected block at once. Blocks buried
## behind other soil can be marked perfectly well -- miners simply can't
## reach them until the ones in front are gone, so a marked seam digs
## itself inward layer by layer.
func _on_soil_mark_requested(mark: bool) -> void:
	for block in selected_blocks:
		if is_instance_valid(block):
			block.set_marked(mark)

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

## Drops a fading mark where a bee died. Added to whichever world the
## bee was in, so a forager that ran out of energy behind a plateau
## leaves its mark out there where you can see the pattern.
func mark_death(bee: Node2D) -> void:
	var marker := DeathMarker.new()
	marker.position = bee.position
	var parent: Node = bee.get_parent()
	if parent == null or not is_instance_valid(parent):
		parent = meadow_root
	parent.add_child(marker)

## Trees and raised ground can be switched off from the tuning panel.
## They are hidden *and* made non-solid, so bees route straight through
## where they were rather than round invisible walls.
func _apply_scenery_setting() -> void:
	if scenery_shown == GameConfig.scenery_on:
		return
	scenery_shown = GameConfig.scenery_on
	for obstacle in obstacles:
		if is_instance_valid(obstacle):
			obstacle.visible = scenery_shown
			obstacle.solid = scenery_shown

	# Every bee forgets whatever it was steering round, and its stall
	# watch is reset. Without this a bee mid-detour kept its commitment to
	# an obstacle that no longer exists, so switching the scenery off
	# didn't free the ones already caught -- which is exactly what you'd
	# reach for the toggle to do.
	for b in get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(b):
			b.clear_navigation_state()

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
func _place_build_cell(global_point: Vector2, keep_adding: bool) -> void:
	var hex: Vector2i = _hex_at(global_point)
	for b in pending_builder_bees:
		if not is_instance_valid(b):
			continue
		if keep_adding:
			b.queue_build_target(hex)
		else:
			b.set_manual_build_target(hex)
	# Ctrl keeps the mode live so a run of tiles can be clicked in the
	# order they should be built, without going back to the button.
	if keep_adding:
		return
	awaiting_build_cell = false
	pending_builder_bees = []

## Consumes the click after "Mine": adds a block to the selected miners'
## own dig order.
func _place_mine_target(global_point: Vector2, keep_adding: bool) -> void:
	var block := _soil_at(global_point)
	if block != null:
		for b in pending_mine_target_bees:
			if not is_instance_valid(b):
				continue
			if keep_adding:
				b.queue_mine_target(block)
			else:
				b.set_mine_target(block)
	if keep_adding:
		return
	awaiting_mine_target = false
	pending_mine_target_bees = []

## Consumes the click after "Keep clear": flags a tile as one no
## comb worker will build on. Clicking a flagged tile again clears it, so
## the one button both sets and unsets.
func _place_keep_clear(global_point: Vector2, keep_adding: bool) -> void:
	var hex: Vector2i = _hex_at(global_point)
	if hive.tile_is_walkable(hex):
		hive.set_keep_clear(hex, not hive.is_keep_clear(hex))
	if keep_adding:
		return
	awaiting_keep_clear = false

## The hex tile under a global (screen-derived) point, in the hive view.
func _hex_at(global_point: Vector2) -> Vector2i:
	var local_point: Vector2 = hive_root.to_local(global_point)
	return Shapes.pixel_to_hex(local_point - hive.comb_centre, GameConfig.hive_cell_spacing)

## Consumes the click that follows a "Work from here" request: the tile an
## comb worker will fill outwards from when picking its own sites.
func _place_home_cell(global_point: Vector2) -> void:
	awaiting_home_cell = false
	var local_point: Vector2 = hive_root.to_local(global_point)
	var hex: Vector2i = Shapes.pixel_to_hex(local_point - hive.comb_centre, GameConfig.hive_cell_spacing)
	for b in pending_home_bees:
		if is_instance_valid(b):
			b.set_home_hex(hex)
	pending_home_bees = []
	hud.update_selection(selected_bees)

func _on_home_cell_requested() -> void:
	pending_home_bees = selected_bees.filter(func(b): return is_instance_valid(b) and b.role == Bee.Role.BUILDER)
	if pending_home_bees.is_empty():
		return
	awaiting_home_cell = true
	if not in_hive_view:
		in_hive_view = true
		_apply_view()

## Consumes the click that follows a "Set dig centre" request: the tile
## the selected miners judge distance from when choosing their next block.
func _place_mine_home(global_point: Vector2) -> void:
	awaiting_mine_home = false
	var local_point: Vector2 = hive_root.to_local(global_point)
	var hex: Vector2i = Shapes.pixel_to_hex(local_point - hive.comb_centre, GameConfig.hive_cell_spacing)
	for b in pending_mine_bees:
		if is_instance_valid(b):
			b.set_mine_home_hex(hex)
	pending_mine_bees = []
	hud.update_selection(selected_bees)

func _on_mine_home_requested() -> void:
	pending_mine_bees = selected_bees.filter(func(b): return is_instance_valid(b) and b.role == Bee.Role.MINER)
	if pending_mine_bees.is_empty():
		return
	awaiting_mine_home = true
	if not in_hive_view:
		in_hive_view = true
		_apply_view()

## Records what just came out of the comb, for the nursery window's
## emergence rates. Keyed the same way the population counts are, so the
## two line up row for row.
func _record_emergence(role: int, focus: String, as_gyne: bool) -> void:
	var key: String = "gyne"
	if not as_gyne:
		key = "%d|%s" % [role, focus] if role == Bee.Role.FORAGER else "%d|" % role
	emergence_log.append({"t": Session.sim_time, "key": key})

# --- the nursery zone ---------------------------------------------

## Putting cells into the zone is the same thing as reserving them for
## brood -- the zone *is* the set of brood cells, rather than a second
## flag that has to be kept in step with the designation. One piece of
## state, so the two can never disagree.
func _on_cell_zone_requested(anchor: Node2D, in_zone: bool) -> void:
	_remember_designations(_cells_to_act_on(anchor))
	for cell in _cells_to_act_on(anchor):
		if in_zone:
			_designate_one(cell, "brood")
		elif cell.is_nursery_cell():
			cell.set_designation("")

func _on_cell_priority_requested(anchor: Node2D, tier: int) -> void:
	for cell in _cells_to_act_on(anchor):
		cell.nursery_priority = clampi(tier, 0, 2)
		# Setting a priority on a cell that isn't in the zone is a clear
		# statement of intent, so put it in rather than silently doing
		# nothing.
		if not cell.is_nursery_cell():
			_designate_one(cell, "brood")

func _on_cell_close_requested(anchor: Node2D, closed: bool) -> void:
	for cell in _cells_to_act_on(anchor):
		cell.set_closed(closed)

func _on_cell_fill_close_requested(anchor: Node2D) -> void:
	for cell in _cells_to_act_on(anchor):
		cell.set_fill_then_close(true)

## Consumes the click that follows a "Start here" request.
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

## A request from the selection panel. `role_name` is either a role key
## ("forager", "comb_worker") or a role key and a sub-mode joined by an
## underscore ("comb_worker_build", "nurse_jelly", "miner_automine").
##
## Both forms are built from the role table in roles.gd, so this handles
## whatever that table contains rather than a hand-written list that has
## to be kept in step with it.
func _on_role_requested(role_name: String) -> void:
	var role_id: int = Roles.id_for_key(role_name)
	if role_id != -1:
		_assign_role(role_id)
		return

	# Not a bare role, so it must be a sub-mode. Find which role it
	# belongs to by matching the longest key that prefixes it -- longest
	# because "miner" would otherwise also match "miner_automine".
	for role in Roles.ROLES:
		var prefix: String = role.key + "_"
		if not role_name.begins_with(prefix):
			continue
		_apply_mode(role.id, role_name.substr(prefix.length()))
		return

func _assign_role(role_id: int) -> void:
	for b in selected_bees:
		if is_instance_valid(b):
			b.set_role(role_id)
	_update_population_readout()
	hud.update_selection(selected_bees)

## Sub-modes live on different fields per role, which is why this can't
## be one assignment. A miner's is a toggle rather than a choice, since
## it only has the one.
func _apply_mode(role_id: int, mode_key: String) -> void:
	for b in selected_bees:
		if not is_instance_valid(b):
			continue
		match role_id:
			Roles.FORAGER:
				b.set_focus(mode_key)
			Roles.NURSE:
				b.nurse_mode = mode_key
			Roles.COMB_WORKER:
				b.architect_mode = mode_key
			Roles.MINER:
				b.automine = not b.automine
	hud.update_selection(selected_bees)


func _on_finish_first_requested(value: bool) -> void:
	for b in selected_bees:
		if is_instance_valid(b):
			b.finish_task_first = value
	hud.update_selection(selected_bees)

func _on_secondary_role_requested(role_name: String) -> void:
	# "none" (and anything unrecognised) clears it
	var target_role: int = Roles.id_for_key(role_name)
	for b in selected_bees:
		if is_instance_valid(b):
			b.set_secondary_role(target_role)
	hud.update_selection(selected_bees)

## Reserving a cell for one resource when it already holds another means
## the contents have to go somewhere. If any other cell has room, a
## builder will haul it across. If nothing has room, the player is
## warned before anything is thrown away.
## Everything the cell popup does acts on the whole selection. The cell
## it was opened on is only the anchor; if the player has ten selected,
## the button applies to all ten.
func _cells_to_act_on(cell: Node2D) -> Array:
	if not selected_cells.is_empty():
		return selected_cells.filter(func(c): return is_instance_valid(c))
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

	if hive.has_room_elsewhere(cell.content_type, cell):
		cell.set_designation(type)   # a builder will come and shift it
	elif Session.warn_on_discard:
		hud.show_discard_warning(cell, type, cell.content_type, cell.amount)
	else:
		cell.clear_cell()
		cell.set_designation(type)

func _on_cell_hatch_role_requested(anchor: Node2D, role: int, focus: String, use_automine: bool) -> void:
	for cell in _cells_to_act_on(anchor):
		cell.hatch_role = role
		cell.hatch_focus = focus
		cell.hatch_automine = use_automine
		# Earmarking a cell to raise a particular kind of bee only means
		# anything if eggs actually end up in it, so choosing a role also
		# reserves the cell for brood. Without this, foragers carried on
		# filling it with nectar and the role never came into play.
		if role >= 0 and cell.designated_type != "brood":
			_designate_one(cell, "brood")

## Pins the cell's hatch role so every future bee raised there inherits
## it, rather than the role applying to the next one only.
func _on_cell_hatch_lock_requested(anchor: Node2D, locked: bool) -> void:
	for cell in _cells_to_act_on(anchor):
		cell.hatch_role_locked = locked

## Clearing a cell out. "move" hands it to a builder to carry into
## another cell; "discard" throws it out of the hive there and then.
## `keep_empty` is what stops foragers immediately refilling it, which is
## the real problem this solves -- with a lot of foragers running, every
## spare cell fills with nectar and nothing is left for pollen or brood.
func _on_cell_empty_requested(anchor: Node2D, method: String, keep_empty: bool) -> void:
	for cell in _cells_to_act_on(anchor):
		_empty_one(cell, method, keep_empty)

func _empty_one(cell: Node2D, method: String, keep_empty: bool) -> void:
	if not is_instance_valid(cell):
		return
	_set_keep_empty(cell, keep_empty)

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
func _on_cell_gyne_requested(anchor: Node2D, as_gyne: bool) -> void:
	for cell in _cells_to_act_on(anchor):
		cell.hatch_gyne = as_gyne
		if as_gyne and cell.designated_type != "brood":
			_designate_one(cell, "brood")

func _on_cell_keep_empty_requested(anchor: Node2D, keep_empty: bool) -> void:
	for cell in _cells_to_act_on(anchor):
		_set_keep_empty(cell, keep_empty)

func _set_keep_empty(cell: Node2D, keep_empty: bool) -> void:
	if not is_instance_valid(cell):
		return
	if keep_empty:
		# "keep this one clear" and "reserve it for X" are contradictory;
		# designating it later clears keep_empty again
		cell.set_designation("")
	cell.keep_empty = keep_empty

func _on_level_chosen(level: int) -> void:
	Session.starting_level = level
	Session.menu_pending = false
	Session.reset_run_state()
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
	_ensure_hive_view()

## "Mine": the next click (or run of ctrl-clicks) sets this miner's own
## dig order.
func _on_mine_target_requested() -> void:
	pending_mine_target_bees = selected_bees.filter(func(b): return is_instance_valid(b) and b.role == Bee.Role.MINER)
	if pending_mine_target_bees.is_empty():
		return
	awaiting_mine_target = true
	_ensure_hive_view()

## "Keep clear": the next click flags a tile no comb worker will build on.
## Colony-wide, so it doesn't matter which comb worker was selected.
func _on_keep_clear_requested() -> void:
	awaiting_keep_clear = true
	_ensure_hive_view()

# --- restocking orders --------------------------------------------
## These act on the current comb selection rather than entering a
## click-a-spot mode: you pick the cells the ordinary way, then say what
## they are for. Selecting comb is something the player already does
## constantly, so reusing it beats inventing a fourth placement mode.

func _restock_comb_workers() -> Array:
	return selected_bees.filter(func(b):
		return is_instance_valid(b) and b.role == Bee.Role.BUILDER
	)

func _on_restock_targets_requested(resource: String) -> void:
	var cells: Array = selected_cells.filter(func(c): return is_instance_valid(c))
	if cells.is_empty():
		hud.show_warning("Select the comb you want kept full first, then press the resource.")
		return
	for b in _restock_comb_workers():
		b.set_restock_targets(cells, resource)
		b.architect_mode = "restock"
	# The cells have to be reserved for the resource, or foragers will
	# keep filling them with whatever arrives and the comb worker will
	# spend its life undoing that.
	for cell in cells:
		_designate_one(cell, resource)
	_clear_cell_selection()
	hud.update_selection(selected_bees)

func _on_restock_sources_requested(allowed: bool) -> void:
	var cells: Array = selected_cells.filter(func(c): return is_instance_valid(c))
	if cells.is_empty():
		hud.show_warning("Select the comb you mean first, then press the button.")
		return
	for b in _restock_comb_workers():
		b.set_restock_sources(cells, allowed)
	_clear_cell_selection()
	hud.update_selection(selected_bees)

func _on_restock_clear_requested() -> void:
	for b in _restock_comb_workers():
		b.clear_restock()
	hud.update_selection(selected_bees)

func _ensure_hive_view() -> void:
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
		return

	_draw_hive_orders()

# --- showing a bee's orders ---------------------------------------
## Everything here is drawn only while the bee holding the order is
## selected, so the comb isn't permanently covered in other bees'
## plans. The keep-clear tiles are the exception: they belong to the
## colony, not to a bee, so they show for any selected comb worker.

const BUILD_ORDER_COLOUR := Color(0.45, 0.85, 1.0)
const MINE_ORDER_COLOUR := Color(1.0, 0.72, 0.30)
const KEEP_CLEAR_COLOUR := Color(0.95, 0.45, 0.45)

func _draw_hive_orders() -> void:
	var any_architect := false
	for b in selected_bees:
		if not is_instance_valid(b):
			continue
		if b.role == Bee.Role.BUILDER:
			any_architect = true
			_draw_order_chain(b, _build_queue_points(b), BUILD_ORDER_COLOUR)
		elif b.role == Bee.Role.MINER:
			_draw_order_chain(b, _mine_queue_points(b), MINE_ORDER_COLOUR)

	# Reserved open space, for any comb worker. Also shown while placing
	# one, so you can see what's already flagged as you click.
	if any_architect or awaiting_keep_clear:
		for hex in hive.keep_clear_tiles.keys():
			_draw_tile_outline(_tile_centre(hex), KEEP_CLEAR_COLOUR, 2.0, true)

func _build_queue_points(bee: Node2D) -> Array:
	var points: Array = []
	for hex in bee.build_queue:
		points.append(_tile_centre(hex))
	return points

func _mine_queue_points(bee: Node2D) -> Array:
	var points: Array = []
	for block in bee.mine_queue:
		if is_instance_valid(block):
			points.append(hive_root.to_global(block.position))
	return points

## A faint line from the bee through each of its targets in order, with
## the tile outlined and numbered. The line is what turns a set of marks
## into a plan you can read: it says which one is first.
func _draw_order_chain(bee: Node2D, points: Array, colour: Color) -> void:
	if points.is_empty():
		return
	var previous: Vector2 = bee.global_position
	for i in range(points.size()):
		var point: Vector2 = points[i]
		selection_layer.draw_line(previous, point, Color(colour.r, colour.g, colour.b, 0.35), 1.5)
		_draw_tile_outline(point, colour, 2.0, false)
		previous = point

## One hexagon outline at a world point, sized to a comb tile. `dashed`
## draws every other edge, which reads as "reserved" rather than "here is
## a thing".
func _draw_tile_outline(centre: Vector2, colour: Color, width: float, dashed: bool) -> void:
	var corners: PackedVector2Array = Shapes.hexagon_points(GameConfig.hive_cell_size + 1.0)
	for i in range(6):
		if dashed and i % 2 == 1:
			continue
		selection_layer.draw_line(
			centre + corners[i], centre + corners[(i + 1) % 6], colour, width
		)

func _tile_centre(hex: Vector2i) -> Vector2:
	return hive_root.to_global(
		hive.comb_centre + Shapes.hex_to_pixel(hex.x, hex.y, GameConfig.hive_cell_spacing)
	)

func _draw_start_point_marker(point: Vector2) -> void:
	var marker_color := Color(0.2, 1.0, 0.4, 0.95)
	selection_layer.draw_circle(point, 9.0, Color(0.2, 1.0, 0.4, 0.2))
	selection_layer.draw_arc(point, 9.0, 0.0, TAU, 24, marker_color, 2.5)
	selection_layer.draw_line(point + Vector2(-6, 0), point + Vector2(6, 0), marker_color, 2.0)
	selection_layer.draw_line(point + Vector2(0, -6), point + Vector2(0, 6), marker_color, 2.0)
