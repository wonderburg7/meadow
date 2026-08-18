extends Node
## World building: laying out the meadow and the hive interior, spawning
## bees, and the handful of things bees themselves call on `main` at
## runtime (moving between meadow and hive, dying, finishing a dig).
##
## Split out of main.gd 14 Aug 2026 -- see MAIN_SPLIT_PLAN.md. Holds no
## state of its own beyond `_view_rect`/`_view_frame`, which are private to
## `is_on_screen`. Everything else lives on `main` and is reached through
## the `main` reference set when this node is created.
##
## bee.gd, debug_panel.gd and others hold a reference to `main` (as
## `world`) and call several of these methods directly by name --
## `is_on_screen`, `hive_entrance_inside`, `move_bee_into_hive`,
## `move_bee_out_of_hive`, `mark_death`, `finish_mining`. main.gd keeps a
## one-line wrapper for each of those so nothing outside this split had to
## change. Everything else here is reached from other files only via
## `main.world_building.<name>()`.

var main: Node2D

## Used by is_on_screen. Recomputed once a frame rather than per caller.
var _view_rect: Rect2 = Rect2()
var _view_frame: int = -1

func _build_meadow() -> void:
	var grass = Polygon2D.new()
	grass.polygon = main.Shapes.square_points(Vector2(4000, 3000))
	grass.position = Vector2(700, 325)
	grass.color = main.MEADOW_COLOR
	grass.z_index = -10
	main.meadow_root.add_child(grass)

	main.hive = main.Hive.new()
	main.hive.position = main.HIVE_MARKER_POSITION
	main.meadow_root.add_child(main.hive)

	_scatter_obstacles()

	for i in range(int(GameConfig.flower_count)):
		_seed_flower()

	_rebuild_flower_grid()

	if GameConfig.rival_hive_on:
		_place_rival_hive()

func _rebuild_flower_grid() -> void:
	main.flower_grid.rebuild(get_tree().get_nodes_in_group("flowers"))

## Is `node` inside what the camera can currently see, with a margin? Part
## of main.gd's public surface -- bee.gd calls `world.is_on_screen(self)`.
func is_on_screen(node: Node2D) -> bool:
	var root: Node = node.get_parent()
	if root != (main.hive_root if main.in_hive_view else main.meadow_root):
		return false

	var frame = Engine.get_process_frames()
	if _view_frame != frame:
		_view_frame = frame
		var cam = main.camera_view._active_camera()
		var span: Vector2 = main.get_viewport_rect().size / cam.zoom.x
		_view_rect = Rect2(cam.position - span * 0.5, span).grow(120.0)
	return _view_rect.has_point(node.global_position)

func _place_rival_hive() -> void:
	var spot: Vector2 = main.hive.position
	for attempt in range(40):
		var candidate: Vector2 = main.hive.position + Vector2(
			randf_range(-main.FLOWER_FIELD_HALF_SIZE.x, main.FLOWER_FIELD_HALF_SIZE.x),
			randf_range(-main.FLOWER_FIELD_HALF_SIZE.y, main.FLOWER_FIELD_HALF_SIZE.y)
		)
		if candidate.distance_to(main.hive.position) < GameConfig.rival_min_distance:
			continue
		if not _is_clear_ground(candidate):
			continue
		spot = candidate
		break
	if spot == main.hive.position:
		spot = main.hive.position + Vector2(main.FLOWER_FIELD_HALF_SIZE.x * 0.9, main.FLOWER_FIELD_HALF_SIZE.y * 0.6)
		spot = _clear_of_obstacles(spot)

	main.rival = main.RivalHive.new()
	main.rival.position = spot
	main.rival.world = main
	main.meadow_root.add_child(main.rival)

func _scatter_obstacles() -> void:
	var placed: Array = []
	_place_obstacles(placed, main.RAISED_AREA_COUNT, main.Obstacle.Kind.RAISED, main.RAISED_AREA_RADIUS, 120.0)
	_place_obstacles(placed, main.TREE_COUNT, main.Obstacle.Kind.TREE, main.TREE_RADIUS, 40.0)
	_spawn_starting_foragers()

func _place_obstacles(placed: Array, count: int, kind: int, radius_range: Vector2, gap: float) -> void:
	for i in range(count):
		var radius: float = randf_range(radius_range.x, radius_range.y)
		var pos: Vector2
		var attempts = 0
		while attempts < 25:
			pos = main.hive.position + Vector2(
				randf_range(-main.FLOWER_FIELD_HALF_SIZE.x, main.FLOWER_FIELD_HALF_SIZE.x),
				randf_range(-main.FLOWER_FIELD_HALF_SIZE.y, main.FLOWER_FIELD_HALF_SIZE.y)
			)
			var clear_of_hive: bool = pos.distance_to(main.hive.position) > main.OBSTACLE_HIVE_CLEARANCE + radius
			var clear_of_others = true
			for other in placed:
				if pos.distance_to(other.pos) < radius + other.radius + gap:
					clear_of_others = false
					break
			if clear_of_hive and clear_of_others:
				break
			attempts += 1
		if attempts >= 25:
			continue

		var obstacle = main.Obstacle.new()
		obstacle.position = pos
		obstacle.z_index = -1
		main.meadow_root.add_child(obstacle)
		obstacle.setup(kind, radius)
		placed.append({"pos": pos, "radius": radius})
		main.obstacles.append(obstacle)

func _spawn_starting_foragers() -> void:
	var level: Dictionary = main.Levels.LEVELS.get(Session.starting_level, {})
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

func _seed_flower() -> void:
	var species_index = main.Flower.pick_species_index()
	var species: Dictionary = main.Flower.SPECIES[species_index]
	var species_name: String = species.name
	var cluster_radius: float = species.get("cluster_radius", 70.0)
	var cluster_chance: float = species.get("cluster_chance", 0.6)

	var centers: Array = main.cluster_centers.get(species_name, [])
	var pos: Vector2

	if not centers.is_empty() and randf() < cluster_chance:
		var center: Vector2 = centers[randi() % centers.size()]
		var angle = randf() * TAU
		var dist = sqrt(randf()) * cluster_radius
		pos = center + Vector2(cos(angle), sin(angle)) * dist
	else:
		pos = _random_field_point()
		centers.append(pos)
		if centers.size() > main.MAX_CLUSTERS_PER_SPECIES:
			centers.pop_front()
		main.cluster_centers[species_name] = centers

	for retry in range(8):
		if _is_clear_ground(pos):
			break
		pos = _random_field_point()
	pos = _clear_of_obstacles(pos)

	var flower = main.Flower.new()
	flower.position = pos
	main.meadow_root.add_child(flower)
	flower.setup(species_index)

func _is_clear_ground(point: Vector2) -> bool:
	for obstacle in main.obstacles:
		if not is_instance_valid(obstacle) or not obstacle.solid:
			continue
		if point.distance_to(obstacle.position) < obstacle.radius + main.FLOWER_CLEARANCE:
			return false
	return true

func _clear_of_obstacles(point: Vector2) -> Vector2:
	var result = point
	for obstacle in main.obstacles:
		if not is_instance_valid(obstacle) or not obstacle.solid:
			continue
		var edge: float = obstacle.radius + main.FLOWER_CLEARANCE
		var offset: Vector2 = result - obstacle.position
		if offset.length() >= edge:
			continue
		if offset.length() < 0.01:
			offset = Vector2.RIGHT
		result = obstacle.position + offset.normalized() * edge
	return result

func _random_field_point() -> Vector2:
	var point: Vector2
	for attempt in range(6):
		point = main.hive.position + Vector2(
			randf_range(-main.FLOWER_FIELD_HALF_SIZE.x, main.FLOWER_FIELD_HALF_SIZE.x),
			randf_range(-main.FLOWER_FIELD_HALF_SIZE.y, main.FLOWER_FIELD_HALF_SIZE.y)
		)
		if point.distance_to(main.hive.position) >= main.FLOWER_MIN_DISTANCE:
			break
	return point

func _hive_centre_local() -> Vector2:
	return main.HIVE_INTERIOR_CENTRE - main.HIVE_WORLD_OFFSET

func _build_hive_interior() -> void:
	var centre_local = _hive_centre_local()
	var interior_rings = int(GameConfig.hive_interior_rings)
	var soil_depth = int(GameConfig.hive_soil_depth)
	var spacing: float = GameConfig.hive_cell_spacing

	main.hive.comb_parent = main.hive_root
	main.hive.comb_centre = centre_local

	_dig_out_chamber(centre_local, interior_rings, soil_depth, spacing)
	_add_entrance_marker()
	_build_starting_comb(centre_local, spacing)
	main.hive.build_navigation()
	main.hive.refresh_edge_flags()
	_spawn_hive_occupants(centre_local, interior_rings, spacing)

func _dig_out_chamber(centre_local: Vector2, interior_rings: int, soil_depth: int, spacing: float) -> void:
	var rock_rings = int(GameConfig.hive_rock_rings)
	var entrance_tiles = _entrance_tiles(interior_rings, soil_depth + rock_rings)
	for ring in range(0, interior_rings + soil_depth):
		for hex in main.Shapes.hex_ring(ring):
			if entrance_tiles.has(hex) or _is_open_tile(hex, ring, interior_rings):
				_add_floor_tile(hex, centre_local, spacing)
			else:
				_add_soil_block(hex, centre_local, spacing)

	for ring in range(interior_rings + soil_depth, interior_rings + soil_depth + rock_rings):
		for hex in main.Shapes.hex_ring(ring):
			if entrance_tiles.has(hex):
				_add_floor_tile(hex, centre_local, spacing)
			else:
				_add_rock_block(hex, centre_local, spacing)

func _add_entrance_marker() -> void:
	var marker = Polygon2D.new()
	marker.polygon = main.Shapes.circle_points(7.0, 20)
	marker.position = hive_entrance_inside()
	marker.color = Color(0.05, 0.05, 0.05)
	marker.z_index = 2
	main.hive_root.add_child(marker)

func _build_starting_comb(centre_local: Vector2, spacing: float) -> void:
	var cells: Array = []
	var level: Dictionary = main.Levels.LEVELS.get(Session.starting_level, {})
	var starting_count: int = int(level.cells) if not level.is_empty() else int(GameConfig.hive_cell_count)
	for i in range(starting_count):
		var cell_hex: Vector2i = main.Shapes.hex_spiral_at(i)
		var cell = main.HiveCell.new()
		cell.axial = cell_hex
		cell.position = centre_local + main.Shapes.hex_to_pixel(cell_hex.x, cell_hex.y, spacing)
		main.hive_root.add_child(cell)
		cells.append(cell)
		main.hive.register_tile(cell_hex, cell)
	main.hive.cells = cells
	_stock_starting_comb(cells, level)

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
	main.queen = main.Bee.new()
	main.queen.is_queen = true
	main.queen.position = centre_local + Vector2(0, (interior_rings - 3) * spacing * 1.5)
	main.hive_root.add_child(main.queen)
	# "nectar" here is only ever read if she's later switched to Forager
	# (nothing else looks at a Laying bee's resource_type) -- matches
	# every other bee's default so a queen turned forager starts on
	# nectar like anyone else, rather than keeping this leftover value.
	main.queen.setup(main.hive, "nectar", 0, main.Bee.Role.EGG_LAYER, main)

	var level: Dictionary = main.Levels.LEVELS.get(Session.starting_level, {})
	var nurses: int = int(level.nurses) if not level.is_empty() else int(GameConfig.starting_nurses)
	var builders: int = int(level.builders) if not level.is_empty() else int(GameConfig.starting_builders)
	var miners: int = int(level.miners) if not level.is_empty() else int(GameConfig.starting_miners)
	var honey_makers: int = 0 if not level.is_empty() else int(GameConfig.starting_honey_makers)
	for i in range(nurses):
		_spawn_indoor_bee(main.Bee.Role.NURSERY)
	for i in range(builders):
		_spawn_indoor_bee(main.Bee.Role.BUILDER)
	for i in range(miners):
		var miner = _spawn_indoor_bee(main.Bee.Role.MINER)
		if miner != null and bool(level.get("automine", false)):
			miner.automine = true
	for i in range(honey_makers):
		_spawn_indoor_bee(main.Bee.Role.HONEY_MAKER)

func _is_open_tile(hex: Vector2i, ring: int, interior_rings: int) -> bool:
	if ring < interior_rings - 1:
		return true
	if ring > interior_rings:
		return false
	var noise: float = abs(sin(float(hex.x) * 12.9898 + float(hex.y) * 78.233))
	return noise > 0.45 if ring == interior_rings - 1 else noise > 0.75

func _add_floor_tile(hex: Vector2i, centre_local: Vector2, spacing: float) -> void:
	var tile = Polygon2D.new()
	tile.polygon = main.Shapes.hexagon_points(GameConfig.hive_cell_size * 1.15)
	tile.position = centre_local + main.Shapes.hex_to_pixel(hex.x, hex.y, spacing)
	tile.color = main.FLOOR_COLOR
	main.hive_root.add_child(tile)

func _add_soil_block(hex: Vector2i, centre_local: Vector2, spacing: float) -> void:
	if not main.hive.tile_is_free(hex):
		return
	var block = main.SoilBlock.new()
	block.position = centre_local + main.Shapes.hex_to_pixel(hex.x, hex.y, spacing)
	main.hive_root.add_child(block)
	block.setup(hex)
	main.hive.register_tile(hex, block)

func _add_rock_block(hex: Vector2i, centre_local: Vector2, spacing: float) -> void:
	if not main.hive.tile_is_free(hex):
		return
	var block = main.RockBlock.new()
	block.position = centre_local + main.Shapes.hex_to_pixel(hex.x, hex.y, spacing)
	main.hive_root.add_child(block)
	block.setup(hex)
	main.hive.register_tile(hex, block)

## The dug-out hive is itself a big hexagon (a stack of hex_ring shells),
## which gives it six corners. Under the flat-top projection, axial
## `(0, -ring)` is the unique topmost one at every ring -- so walking that
## single column from the surface down to the interior carves a corner
## entrance at the top with a tunnel exactly one tile wide, rather than
## the old pixel-distance test, which alternated between one and two
## tiles wide depending on the ring's parity. `hive_entrance_width` is no
## longer read here; a single-file tunnel was the point of this change.
func _entrance_tiles(interior_rings: int, soil_depth: int) -> Dictionary:
	var tiles: Dictionary = {}
	for ring in range(interior_rings - 1, interior_rings + soil_depth):
		tiles[Vector2i(0, -ring)] = true
	return tiles

## Part of main.gd's public surface -- bee.gd calls `world.hive_entrance_inside()`.
func hive_entrance_inside() -> Vector2:
	var rings: int = int(
		GameConfig.hive_interior_rings
		+ GameConfig.hive_soil_depth
		+ GameConfig.hive_rock_rings
		- 1.0
	)
	# Same corner hex _entrance_tiles walks to, found the one way this
	# file trusts for turning an axial coordinate into a world position --
	# not hand-derived, so a future geometry change doesn't have to find
	# this a second time.
	return _hive_centre_local() + main.Shapes.hex_to_pixel(0, -rings, GameConfig.hive_cell_spacing)

## Where a recruit (seeker, `side` -1) or recruiter (mentor, `side` 1)
## forager stands while waiting at the door for a match. Deliberately
## *not* hive_entrance_inside() -- that's the outer mouth of the
## single-file entrance tunnel, walled in on both sides the whole way
## down, so there's no "left" or "right" to stand in down there. The
## point where the tunnel actually opens out into the interior room is
## axial (0, -(interior_rings - 1)) -- see _entrance_tiles -- so this
## starts there and steps two rows further into the open room, clear of
## the doorway, before offsetting sideways.
func entrance_wait_point(side: int) -> Vector2:
	var interior_rings: int = int(GameConfig.hive_interior_rings)
	var spacing: float = GameConfig.hive_cell_spacing
	var row: int = -(interior_rings - 1) + 2
	var base: Vector2 = _hive_centre_local() + main.Shapes.hex_to_pixel(0, row, spacing)
	return base + Vector2(sign(side) * spacing * 1.4, 0.0)

func _build_cameras() -> void:
	main.meadow_camera = Camera2D.new()
	main.meadow_camera.position = Vector2(640, 320)
	main.add_child(main.meadow_camera)

	main.hive_camera = Camera2D.new()
	main.hive_camera.position = main.HIVE_INTERIOR_CENTRE
	main.add_child(main.hive_camera)

func _spawn_bee(focus: String) -> void:
	var bee = main.Bee.new()
	bee.position = main.hive.position
	main.meadow_root.add_child(bee)
	bee.setup(main.hive, focus, main.next_bee_id, main.Bee.Role.FORAGER, main)
	main.next_bee_id += 1

func _spawn_hatched_bee(role: int, cell: Node2D, as_gyne: bool = false, focus_override: String = "") -> void:
	var bee = main.Bee.new()
	bee.is_gyne = as_gyne
	bee.position = cell.position
	main.hive_root.add_child(bee)
	var focus: String = focus_override if focus_override != "" else cell.hatch_focus
	if focus == "":
		focus = "nectar"
	if role == main.Bee.Role.BUILDER:
		bee.architect_mode = focus if focus in ["build", "maintain", "both"] else "both"
		bee.setup(main.hive, "nectar", main.next_bee_id, role, main)
	else:
		bee.setup(main.hive, focus, main.next_bee_id, role, main)
	if role == main.Bee.Role.MINER:
		bee.automine = cell.hatch_automine
	main.next_bee_id += 1
	if role == main.Bee.Role.FORAGER:
		bee.state = main.Bee.State.IN_HIVE_TO_EXIT

func _spawn_indoor_bee(role: int) -> Node2D:
	var bee = main.Bee.new()
	bee.position = _hive_centre_local() + Vector2(randf_range(-50, 50), randf_range(60, 110))
	main.hive_root.add_child(bee)
	bee.setup(main.hive, "nectar", main.next_bee_id, role, main)
	main.next_bee_id += 1
	return bee

## Part of main.gd's public surface -- bee.gd calls `world.move_bee_into_hive(self)`.
func move_bee_into_hive(bee: Node2D) -> void:
	Perf.begin("hive_transition")
	if bee.get_parent() == main.hive_root:
		Perf.end("hive_transition")
		return
	bee.reparent(main.hive_root)
	bee.position = hive_entrance_inside()
	bee.visible = true
	main._update_population_readout()
	Perf.end("hive_transition")

## Part of main.gd's public surface -- bee.gd calls `world.move_bee_out_of_hive(self)`.
func move_bee_out_of_hive(bee: Node2D) -> void:
	Perf.begin("hive_transition")
	if bee.get_parent() == main.meadow_root:
		Perf.end("hive_transition")
		return
	bee.reparent(main.meadow_root)
	bee.position = main.hive.position
	bee.visible = true
	main._update_population_readout()
	Perf.end("hive_transition")

## Part of main.gd's public surface -- bee.gd calls `world.mark_death(self)`.
func mark_death(bee: Node2D) -> void:
	var marker = main.DeathMarker.new()
	marker.position = bee.position
	var parent: Node = bee.get_parent()
	if parent == null or not is_instance_valid(parent):
		parent = main.meadow_root
	parent.add_child(marker)

func _apply_scenery_setting() -> void:
	if main.scenery_shown == GameConfig.scenery_on:
		return
	main.scenery_shown = GameConfig.scenery_on
	for obstacle in main.obstacles:
		if is_instance_valid(obstacle):
			obstacle.visible = main.scenery_shown
			obstacle.solid = main.scenery_shown

	for b in get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(b):
			b.clear_navigation_state()

## Part of main.gd's public surface -- bee.gd calls `world.finish_mining(target_block)`.
func finish_mining(block: Node2D) -> void:
	var centre_local = _hive_centre_local()
	var spacing: float = GameConfig.hive_cell_spacing
	main.hive.remove_block(block, func(hex: Vector2i): _add_floor_tile(hex, centre_local, spacing))

func _obstacle_at(point: Vector2) -> Node2D:
	for o in main.obstacles:
		if is_instance_valid(o) and o.global_position.distance_to(point) <= o.radius:
			return o
	return null

func _flower_at(point: Vector2) -> Node2D:
	for f in get_tree().get_nodes_in_group("flowers"):
		if f.global_position.distance_to(point) <= 20.0:
			return f
	return null
