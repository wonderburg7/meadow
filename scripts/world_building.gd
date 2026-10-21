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

## Clusters can seed a flower up to this far outside the flower field
## rectangle (their anchor is inside it, but the offset from anchor isn't
## clamped) -- the widest species' cluster_radius is 140 (flower_species.gd),
## rounded up with headroom so the grass never shows a flower spilling onto
## grey ground.
const GRASS_MARGIN := 200.0

## Keep hive-floor polygons behind every row-ordered comb cell. -4096 is
## Godot's lowest supported z-index, so even cells above the comb centre
## (whose row key is negative) cannot be hidden by the floor.
const HIVE_FLOOR_Z_INDEX := -4096

func _build_meadow() -> void:
	var grass := Polygon2D.new()
	grass.polygon = main.Shapes.square_points(
		(main.FLOWER_FIELD_HALF_SIZE + Vector2(GRASS_MARGIN, GRASS_MARGIN)) * 2.0
	)
	grass.position = main.HIVE_MARKER_POSITION
	grass.color = main.MEADOW_COLOR
	grass.z_index = -10
	main.meadow_root.add_child(grass)

	main.hive = main.Hive.new()
	main.hive.main = main
	main.hive.position = main.HIVE_MARKER_POSITION
	main.meadow_root.add_child(main.hive)

	_scatter_obstacles()
	_build_microhabitat_zones()

	# Before the founding flowers, whose birth dates read the year's length.
	var level: Dictionary = main.Levels.get_level(Session.starting_level)
	Session.year_has_winter = bool(level.get("winter", true))

	var founding_units := 0
	while founding_units < int(GameConfig.flower_count):
		founding_units += _seed_flower(true, int(GameConfig.flower_count) - founding_units)

	_rebuild_flower_grid()

	if GameConfig.rival_hive_on and level.get("rival_hive", true):
		_place_rival_hive()

func _rebuild_flower_grid() -> void:
	main.flower_grid.rebuild(get_tree().get_nodes_in_group("flowers"))

## Is `node` inside what the camera can currently see, with a margin? Part
## of main.gd's public surface -- bee.gd calls `world.is_on_screen(self)`.
func is_on_screen(node: Node2D) -> bool:
	var root: Node = node.get_parent()
	if root != (main.hive_root if main.in_hive_view else main.meadow_root):
		return false

	var frame := Engine.get_process_frames()
	if _view_frame != frame:
		_view_frame = frame
		var cam: Variant = main.camera_view._active_camera()
		var span: Vector2 = main.get_viewport_rect().size / cam.zoom.x
		_view_rect = Rect2(cam.position - span * 0.5, span).grow(120.0)
	return _view_rect.has_point(node.global_position)

func _place_rival_hive() -> void:
	var spot: Vector2 = main.hive.position
	for attempt: int in range(40):
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
	for i: int in range(count):
		var radius: float = randf_range(radius_range.x, radius_range.y)
		var pos: Vector2
		var attempts := 0
		while attempts < 25:
			pos = main.hive.position + Vector2(
				randf_range(-main.FLOWER_FIELD_HALF_SIZE.x, main.FLOWER_FIELD_HALF_SIZE.x),
				randf_range(-main.FLOWER_FIELD_HALF_SIZE.y, main.FLOWER_FIELD_HALF_SIZE.y)
			)
			var clear_of_hive: bool = pos.distance_to(main.hive.position) > main.OBSTACLE_HIVE_CLEARANCE + radius
			var clear_of_others := true
			for other: Variant in placed:
				if pos.distance_to(other.pos) < radius + other.radius + gap:
					clear_of_others = false
					break
			if clear_of_hive and clear_of_others:
				break
			attempts += 1
		if attempts >= 25:
			continue

		var obstacle: Variant = main.Obstacle.new()
		obstacle.position = pos
		obstacle.z_index = -1
		main.meadow_root.add_child(obstacle)
		obstacle.setup(kind, radius)
		placed.append({"pos": pos, "radius": radius})
		main.obstacles.append(obstacle)

func _spawn_starting_foragers() -> void:
	var level: Dictionary = main.Levels.get_level(Session.starting_level)
	if not level.is_empty():
		for i: int in range(int(level.nectar_foragers)):
			_spawn_bee("nectar", str(level.get("forager_species", "")))
		for i: int in range(int(level.pollen_foragers)):
			_spawn_bee("pollen", str(level.get("forager_species", "")))
		return

	var total_bees: int = maxi(2, int(GameConfig.starting_bees))
	_spawn_bee("nectar")
	_spawn_bee("pollen")
	for i: int in range(total_bees - 2):
		_spawn_bee("nectar")

## How far a bushy species' extra flower units land from the bush's
## anchor point -- tight enough that their individual backdrop shapes
## (flower.gd's ~25-41px jittered radius) overlap into one bush outline,
## rather than reading as separate plants.
const BUSH_UNIT_SPREAD := Vector2(8.0, 24.0)

## One or two soft zones per microhabitat string on the species table,
## scattered across the field and built once per run (before any flower is
## seeded, so it stays reproducible off the run's seed). `_seed_flower`
## biases a species' *first* cluster anchor toward a matching zone --
## existing clusters (main.cluster_centers) are untouched by this.
const MICROHABITAT_ZONE_RADIUS := Vector2(300.0, 450.0)
const MICROHABITAT_ZONE_CHANCE := 0.75

func _build_microhabitat_zones() -> void:
	main.microhabitat_zones.clear()
	var microhabitats: Array = []
	for species: Variant in main.FlowerSpecies.SPECIES:
		var habitat: String = species.get("microhabitat", "")
		if habitat != "" and not microhabitats.has(habitat):
			microhabitats.append(habitat)

	for habitat: Variant in microhabitats:
		var zone_count := randi_range(1, 2)
		var zones: Array = []
		for i: int in range(zone_count):
			var radius: float = randf_range(MICROHABITAT_ZONE_RADIUS.x, MICROHABITAT_ZONE_RADIUS.y)
			zones.append({
				"centre": _random_zone_centre(radius),
				"radius": radius,
			})
		main.microhabitat_zones[habitat] = zones

## A random point inside one of `habitat`'s zones, or an empty Vector2 flag
## (via the returned bool) if that habitat has no zones -- callers fall
## back to `_random_field_point()` in that case.
func _random_point_in_zone(habitat: String) -> Vector2:
	var zones: Array = main.microhabitat_zones.get(habitat, [])
	var zone: Dictionary = zones[randi() % zones.size()]
	var centre: Vector2 = zone.centre
	var radius: float = zone.radius
	var angle := randf() * TAU
	var dist := sqrt(randf()) * radius
	return centre + Vector2(cos(angle), sin(angle)) * dist

const SEED_DISTANCE := Vector2(20.0, 60.0)  # PP-4: a seed from its parent, in px

## Founders are sampled as though they were born earlier in this same year,
## rather than all being born in today's season. Replacements retain the
## current-season selection used before SF-1. PP-4: oldest gap first (pollination.gd).
func _seed_flower(founding: bool = false, max_units: int = 4) -> int:
	var ledger: Variant = main.pollination if not founding else null
	var counts: Dictionary = ledger.regrowth_counts(main.Flower.regrowth_factor < 1.0) if ledger != null else {}
	var gap: Array = ledger.take_gap() if ledger != null else []
	if ledger != null and ledger.seed_in_season(gap):
		return _plant_seed(ledger, gap)
	var excluded_species: Array = ["Poppy"] if Session.starting_level == 1 else []
	var starting_age := -1.0
	var birth_fraction := -1.0
	if founding:
		# Draw this before species so a founder's birth date, not the season
		# at the instant the world appears, chooses its species. The age uses
		# the nominal lifetime; setup still gives every flower its normal
		# independently varied lifespan.
		starting_age = randf() * GameConfig.flower_lifespan_days * GameConfig.seconds_per_day
		var season_days: float = maxf(1.0, GameConfig.season_length_days)
		var year_days: float = Session.year_days()
		var birth_day: float = 1.0 + (Session.sim_time - starting_age) / maxf(1.0, GameConfig.seconds_per_day)
		var day_in_year: float = fposmod(birth_day - 1.0, year_days) + 1.0
		birth_fraction = clampf((day_in_year - 1.0) / season_days, 0.0, 1.0)
	var weights: Array = main.FlowerSpecies.species_weights(excluded_species, birth_fraction, counts)
	var species_index: int = main.FlowerSpecies.pick_from_weights(weights, excluded_species)
	var species: Dictionary = main.FlowerSpecies.SPECIES[species_index]
	var species_name: String = species.name
	var cluster_radius: float = species.get("cluster_radius", 70.0)
	var cluster_chance: float = species.get("cluster_chance", 0.6)

	var centers: Array = main.cluster_centers.get(species_name, [])
	var anchor: Vector2

	if not centers.is_empty() and randf() < cluster_chance:
		var center: Vector2 = centers[randi() % centers.size()]
		var angle: float = randf() * TAU
		var dist: float = sqrt(randf()) * cluster_radius
		anchor = center + Vector2(cos(angle), sin(angle)) * dist
	else:
		var habitat: String = species.get("microhabitat", "")
		var zones: Array = main.microhabitat_zones.get(habitat, [])
		if not zones.is_empty() and randf() < MICROHABITAT_ZONE_CHANCE:
			anchor = _random_point_in_zone(habitat)
			for retry: int in range(6):
				if anchor.distance_to(main.hive.position) >= main.FLOWER_MIN_DISTANCE:
					break
				anchor = _random_point_in_zone(habitat)
		else:
			anchor = _random_field_point()
		centers.append(anchor)
		if centers.size() > main.MAX_CLUSTERS_PER_SPECIES:
			centers.pop_front()
		main.cluster_centers[species_name] = centers

	# A bushy species (Bramble) plants several flower units together as
	# one bush, rather than leaving it to chance whether a later re-seed
	# lands close enough to read as the same plant.
	var unit_count := 1
	if species.get("bushy", false):
		unit_count = randi_range(
			species.get("bush_min_units", 2), species.get("bush_max_units", 4))
	unit_count = mini(unit_count, max_units)
	var dropped: int = ledger.drop_empty_gaps(unit_count - 1) if ledger != null else 0

	for unit: int in range(unit_count):
		var pos: Vector2 = anchor
		if unit > 0:
			var a := randf() * TAU
			var d := randf_range(BUSH_UNIT_SPREAD.x, BUSH_UNIT_SPREAD.y)
			pos = anchor + Vector2(cos(a), sin(a)) * d
		for retry: int in range(8):
			if _is_clear_ground(pos):
				break
			if unit == 0:
				pos = _random_field_point()
			else:
				var a2 := randf() * TAU
				var d2 := randf_range(BUSH_UNIT_SPREAD.x, BUSH_UNIT_SPREAD.y)
				pos = anchor + Vector2(cos(a2), sin(a2)) * d2
		var flower: Node2D = _add_flower(pos, species_index, starting_age)
		if ledger != null:
			ledger.log_replant("seasonal", flower, weights, counts, unit == 0, gap, dropped)
	return unit_count

## Every replacement and founder goes in here: clear of obstacles, then set up.
func _add_flower(pos: Vector2, species_index: int, starting_age: float = -1.0) -> Node2D:
	var flower: Variant = main.Flower.new()
	flower.position = _clear_of_obstacles(pos)
	main.meadow_root.add_child(flower)
	flower.setup(species_index, starting_age)
	main.CrabSpider.maybe_spawn(flower)
	return flower

## PP-4: one unit (bushy too) of `entry`'s species near where it stood.
func _plant_seed(ledger: Variant, entry: Array) -> int:
	var parent := Vector2(float(entry[1]), float(entry[2]))
	var pos := parent
	for attempt: int in range(9):
		var angle := randf() * TAU
		pos = _in_field(parent + Vector2(cos(angle), sin(angle)) * randf_range(SEED_DISTANCE.x, SEED_DISTANCE.y))
		if _is_clear_ground(pos):
			break
	ledger.log_replant("seed", _add_flower(pos, int(entry[0])), [], {}, true, entry, 0)
	return 1

## `point` kept in the field and FLOWER_MIN_DISTANCE off the hive (_random_field_point's rules).
func _in_field(point: Vector2) -> Vector2:
	var centre: Vector2 = main.hive.position
	var off: Vector2 = point.clamp(centre - main.FLOWER_FIELD_HALF_SIZE, centre + main.FLOWER_FIELD_HALF_SIZE) - centre
	var reach: float = maxf(off.length(), main.FLOWER_MIN_DISTANCE)
	return centre + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * reach

func _is_clear_ground(point: Vector2) -> bool:
	for obstacle: Variant in main.obstacles:
		if not is_instance_valid(obstacle) or not obstacle.solid:
			continue
		if point.distance_to(obstacle.position) < obstacle.radius + main.FLOWER_CLEARANCE:
			return false
	return true

func _clear_of_obstacles(point: Vector2) -> Vector2:
	var result: Variant = point
	for obstacle: Variant in main.obstacles:
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

## Like `_random_field_point()`, but keeps the whole zone circle inside the
## field rectangle rather than just its centre -- otherwise a zone rolled
## near the field edge lets `_random_point_in_zone` place flowers past the
## grass, up to `radius` (300-450px) outside the boundary.
func _random_zone_centre(radius: float) -> Vector2:
	var half: Vector2 = (main.FLOWER_FIELD_HALF_SIZE - Vector2(radius, radius)).max(Vector2.ZERO)
	return main.hive.position + Vector2(
		randf_range(-half.x, half.x),
		randf_range(-half.y, half.y)
	)

func _random_field_point() -> Vector2:
	var point: Vector2
	for attempt: int in range(6):
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
	var centre_local := _hive_centre_local()
	var interior_rings := int(GameConfig.hive_interior_rings)
	var soil_depth := int(GameConfig.hive_soil_depth)
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
	var rock_rings := int(GameConfig.hive_rock_rings)
	var entrance_tiles: Dictionary = _entrance_tiles(interior_rings, soil_depth + rock_rings)
	for ring: int in range(0, interior_rings + soil_depth):
		for hex: Vector2i in main.Shapes.hex_ring(ring):
			if entrance_tiles.has(hex) or _is_open_tile(hex, ring, interior_rings):
				_add_floor_tile(hex, centre_local, spacing)
			else:
				_add_soil_block(hex, centre_local, spacing)

	for ring: int in range(interior_rings + soil_depth, interior_rings + soil_depth + rock_rings):
		for hex: Vector2i in main.Shapes.hex_ring(ring):
			if entrance_tiles.has(hex):
				_add_floor_tile(hex, centre_local, spacing)
			else:
				_add_rock_block(hex, centre_local, spacing)

func _add_entrance_marker() -> void:
	var marker := Polygon2D.new()
	marker.polygon = main.Shapes.circle_points(7.0, 20)
	marker.position = hive_entrance_inside()
	marker.color = Color(0.05, 0.05, 0.05)
	marker.z_index = 2
	main.hive_root.add_child(marker)

func _build_starting_comb(centre_local: Vector2, spacing: float) -> void:
	var cells: Array = []
	var level: Dictionary = main.Levels.get_level(Session.starting_level)
	var starting_count: int = int(level.cells) if not level.is_empty() else int(GameConfig.hive_cell_count)
	for i: int in range(starting_count):
		var cell_hex: Vector2i = main.Shapes.hex_spiral_at(i)
		var cell: Variant = main.HiveCell.new()
		cell.axial = cell_hex
		cell.main = main
		cell.position = centre_local + main.Shapes.hex_to_pixel(cell_hex.x, cell_hex.y, spacing, Session.use_sprite_hex_grid)
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
	for resource: String in ["nectar", "pollen", "honey"]:
		for i: int in range(int(stock.get(resource, 0))):
			if index < 0:
				return
			var cell: Variant = cells[index]
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

	var level: Dictionary = main.Levels.get_level(Session.starting_level)
	for role: Dictionary in main.Roles.ROLES:
		if role.start_count_key == "":
			continue
		var count: int = int(level.get(role.start_count_key, 0)) if not level.is_empty() else int(GameConfig.get(role.start_config))
		for i: int in range(count):
			var bee: Node2D = _spawn_indoor_bee(role.id)
			if role.id == main.Roles.MINER and bee != null and bool(level.get("automine", false)):
				bee.automine = true

func _is_open_tile(hex: Vector2i, ring: int, interior_rings: int) -> bool:
	if ring < interior_rings - 1:
		return true
	if ring > interior_rings:
		return false
	var noise: float = abs(sin(float(hex.x) * 12.9898 + float(hex.y) * 78.233))
	return noise > 0.45 if ring == interior_rings - 1 else noise > 0.75

func _add_floor_tile(hex: Vector2i, centre_local: Vector2, spacing: float) -> void:
	var tile := Polygon2D.new()
	tile.polygon = main.Shapes.hexagon_points(GameConfig.hive_cell_size * 1.15, Session.use_sprite_hex_grid)
	tile.position = centre_local + main.Shapes.hex_to_pixel(hex.x, hex.y, spacing, Session.use_sprite_hex_grid)
	tile.color = main.FLOOR_COLOR
	# Cell z-index follows its screen row (2r + q), which is negative above
	# the comb centre. Keep the opaque floor below that whole ordering rather
	# than allowing those cells to be hidden behind this default-z polygon.
	tile.z_index = HIVE_FLOOR_Z_INDEX
	main.hive_root.add_child(tile)

func _add_soil_block(hex: Vector2i, centre_local: Vector2, spacing: float) -> void:
	if not main.hive.tile_is_free(hex):
		return
	var block: Variant = main.SoilBlock.new()
	block.position = centre_local + main.Shapes.hex_to_pixel(hex.x, hex.y, spacing, Session.use_sprite_hex_grid)
	main.hive_root.add_child(block)
	block.setup(hex)
	main.hive.register_tile(hex, block)

func _add_rock_block(hex: Vector2i, centre_local: Vector2, spacing: float) -> void:
	if not main.hive.tile_is_free(hex):
		return
	var block: Variant = main.RockBlock.new()
	block.position = centre_local + main.Shapes.hex_to_pixel(hex.x, hex.y, spacing, Session.use_sprite_hex_grid)
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
	for ring: int in range(interior_rings - 1, interior_rings + soil_depth):
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
	return _hive_centre_local() + main.Shapes.hex_to_pixel(0, -rings, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid)

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
	var base: Vector2 = _hive_centre_local() + main.Shapes.hex_to_pixel(0, row, spacing, Session.use_sprite_hex_grid)
	return base + Vector2(sign(side) * spacing * 1.4, 0.0)

func _build_cameras() -> void:
	main.meadow_camera = Camera2D.new()
	main.meadow_camera.position = Vector2(640, 320)
	main.add_child(main.meadow_camera)

	main.hive_camera = Camera2D.new()
	main.hive_camera.position = main.HIVE_INTERIOR_CENTRE
	main.add_child(main.hive_camera)

func _spawn_bee(focus: String, preferred_species: String = "") -> void:
	var bee: Variant = main.Bee.new()
	bee.position = main.hive.position
	main.meadow_root.add_child(bee)
	bee.setup(main.hive, focus, main.next_bee_id, main.Bee.Role.FORAGER, main)
	if preferred_species != "":
		bee.set_preferred_species(preferred_species)
	_stagger_starter_age(bee)
	main.next_bee_id += 1

func _spawn_hatched_bee(role: int, cell: Node2D, as_gyne: bool = false, focus_override: String = "") -> Node2D:
	var bee: Variant = main.Bee.new()
	bee.is_gyne = as_gyne
	bee.position = cell.position
	main.hive_root.add_child(bee)
	var focus: String = focus_override if focus_override != "" else cell.hatch_focus
	if focus == "":
		focus = "nectar"
	if role == main.Bee.Role.BUILDER:
		bee.architect_mode = focus if focus in ["build", "maintain", "both", "restock"] else "both"
		bee.setup(main.hive, "nectar", main.next_bee_id, role, main)
	else:
		bee.setup(main.hive, focus, main.next_bee_id, role, main)
	if role == main.Bee.Role.MINER:
		bee.automine = cell.hatch_automine
	# BB-2: a worker's outcome is fixed here, from what her cell fed her
	# (main.gd's hatch has already cleared the cell, which leaves brood_food
	# alone), and saved with her; the cell then forgets it. A gyne has none;
	# main.gd's become_drone clears a drone's. A cell still holding a live
	# larva is not the one she hatched from (challenge_stage_setup's new
	# worker is handed the first built cell), so its larva keeps its food and
	# she gets no outcome.
	if cell.content_type != "brood":
		if not as_gyne:
			bee.set_brood_outcome(cell.brood_food)
		cell.brood_food = ""
	var hatch_mode: String = bee.architect_mode if role == main.Bee.Role.BUILDER else focus
	DiagnosticLog.count_brood_hatch(role, hatch_mode)
	main.next_bee_id += 1
	if role == main.Bee.Role.FORAGER:
		bee.state = main.Bee.State.IN_HIVE_TO_EXIT
	return bee

func _spawn_indoor_bee(role: int) -> Node2D:
	var bee: Variant = main.Bee.new()
	# Indoor roles begin on the walkable navigation graph. The former random
	# point could land in a soil tile, leaving a builder unable to route to
	# any comb site (and therefore permanently idle) from its first tick.
	var spawn_point := _hive_centre_local() + Vector2(randf_range(-50, 50), randf_range(60, 110))
	bee.position = main.hive.nearest_walkable_point(spawn_point)
	main.hive_root.add_child(bee)
	bee.setup(main.hive, "nectar", main.next_bee_id, role, main)
	_stagger_starter_age(bee)
	main.next_bee_id += 1
	return bee

## Founders only: a hatched bee is newborn by definition. Seeded from the
## bee id rather than the global stream, so this does not reshuffle the
## meadow layout or any scenario that follows the fixed seed.
func _stagger_starter_age(bee: Node2D) -> void:
	var spread: float = clampf(GameConfig.starter_age_spread, 0.0, 0.9)
	if spread <= 0.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("starter_age_%d" % bee.bee_id)
	bee.age_seconds = rng.randf() * spread * bee.BeeSurvival.lifespan_seconds(bee)

## Part of main.gd's public surface -- bee.gd calls `world.move_bee_into_hive(self)`.
func move_bee_into_hive(bee: Node2D) -> void:
	Perf.begin("hive_transition")
	if bee.get_parent() == main.hive_root:
		Perf.end("hive_transition")
		return
	bee.reparent(main.hive_root)
	bee.position = hive_entrance_inside()
	bee.visible = true
	# Slice 9 (proximity recruitment): a fresh hive visit gets a fresh shot
	# at recruiting -- see hive.gd's add_dance_eligible_mentor.
	bee.has_danced_this_visit = false
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
	# Slice 9 (proximity recruitment): she's leaving, so she's no longer a
	# candidate for either side of the indoor dance.
	if bee.hive != null and is_instance_valid(bee.hive):
		bee.hive.remove_dance_eligible_mentor(bee)
		bee.hive.remove_dance_eligible_seeker(bee)
	main._update_population_readout()
	Perf.end("hive_transition")

## Part of main.gd's public surface -- bee.gd calls `world.mark_death(self)`.
## Called from BeeSurvival.die() before queue_free() actually removes the
## bee, so death_info is snapshotted from a still-valid node -- see
## death_marker.gd's own header comment for why that matters.
func mark_death(bee: Node2D) -> void:
	var marker: Variant = main.DeathMarker.new()
	marker.position = bee.position
	marker.death_info = {
		"bee_id": bee.bee_id,
		"bee_name": bee.bee_name,
		"is_favourite": bee.is_favourite,
		"is_queen": bee.is_queen,
		"is_gyne": bee.is_gyne,
		"role_text": bee.role_name_text(),
		"trait_text": bee.trait_text(),
		"bee_fact": bee.bee_fact,
		"age_days": bee.age_days(),
		"cause": bee.death_cause,
		"preferred_species": bee.preferred_species,
	}
	var parent: Node = bee.get_parent()
	if parent == null or not is_instance_valid(parent):
		parent = main.meadow_root
	parent.add_child(marker)

func _apply_scenery_setting() -> void:
	if main.scenery_shown == GameConfig.scenery_on:
		return
	main.scenery_shown = GameConfig.scenery_on
	for obstacle: Variant in main.obstacles:
		if is_instance_valid(obstacle):
			obstacle.visible = main.scenery_shown
			obstacle.solid = main.scenery_shown

	for b: Variant in get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(b):
			b.clear_navigation_state()

## Part of main.gd's public surface -- bee.gd calls `world.finish_mining(target_block)`.
func finish_mining(block: Node2D) -> void:
	var centre_local := _hive_centre_local()
	var spacing: float = GameConfig.hive_cell_spacing
	main.hive.remove_block(block, func(hex: Vector2i) -> void: _add_floor_tile(hex, centre_local, spacing))
	main.fog_of_war.notify_hive_open_space_changed()

func _obstacle_at(point: Vector2) -> Node2D:
	for o: Variant in main.obstacles:
		if is_instance_valid(o) and o.global_position.distance_to(point) <= o.radius:
			return o
	return null

func _flower_at(point: Vector2) -> Node2D:
	for f: Variant in get_tree().get_nodes_in_group("flowers"):
		if f.global_position.distance_to(point) <= 20.0:
			return f
	return null
