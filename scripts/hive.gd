extends Polygon2D
## The hive's meadow-side marker (the brown square foragers fly home to)
## and the accountant for everything stored in the comb.
##
## Storage physically lives in the hexagonal cells over in the hive
## view; this script routes deposits and withdrawals to them and hands
## out jobs to builders, so the meadow never needs to know how the comb
## is laid out.

signal storage_changed(nectar: float, pollen: float, honey: float)

const Shapes = preload("res://scripts/shapes.gd")
const HiveCell = preload("res://scripts/hive_cell.gd")

var cells: Array = []            # populated by main.gd once the comb is built
var comb_parent: Node2D = null   # the hive-view root new cells get added to
var comb_centre: Vector2 = Vector2.ZERO

## Rotation pointer for find_empty_cell's brood-cell sequence.
var _brood_pointer: int = 0

## Running totals, never reset, for the top-left rate readout (see
## main.gd's rate-sampling). Counted at the moment of harvest/birth
## rather than derived from the current stock, since stock also goes
## down from being eaten/used -- these only ever go up.
var lifetime_nectar_collected: float = 0.0
var lifetime_pollen_collected: float = 0.0
var lifetime_births: int = 0

func record_collection(resource_type: String, amount: float) -> void:
	if resource_type == "nectar":
		lifetime_nectar_collected += amount
	else:
		lifetime_pollen_collected += amount

func record_birth() -> void:
	lifetime_births += 1

## Which hex tiles are taken, so comb and soil never overlap.
## Keys are axial Vector2i, values are the node sitting there.
var occupied_tiles: Dictionary = {}

func register_tile(hex: Vector2i, node: Node2D) -> void:
	occupied_tiles[hex] = node

func tile_is_free(hex: Vector2i) -> bool:
	return not occupied_tiles.has(hex)

## Is this tile inside the open part of the hive (not soil, not beyond
## the wall)? Comb can only be drawn on free interior tiles.
func tile_is_interior(hex: Vector2i) -> bool:
	return Shapes.hex_ring_index(hex) < int(GameConfig.hive_interior_rings)

## The comb cell sitting on a tile, if any. Used to work out whether a
## bee is walking over comb and should be slowed down.
func cell_at_tile(hex: Vector2i) -> Node2D:
	var node = occupied_tiles.get(hex)
	if node != null and is_instance_valid(node) and node.has_method("is_nursery_cell"):
		return node
	return null

func _ready() -> void:
	polygon = Shapes.square_points(Vector2(60, 60))
	color = Color(0.55, 0.35, 0.15)  # placeholder art: brown square

## Spreads `amount` across any cells that will take it. Returns how
## much actually fitted -- anything left over is lost, which is the
## signal that the hive needs more comb.
##
## Foragers no longer use this (they walk to a specific cell instead);
## it's kept for the no-world fallback path in bee.gd.
func deposit(resource_type: String, amount: float) -> float:
	if resource_type == "" or amount <= 0.0:
		return 0.0
	var remaining := amount
	# top up part-filled cells of this type first, then start new ones
	for cell in cells:
		if remaining <= 0.0:
			break
		if cell.content_type == resource_type:
			remaining -= cell.add_resource(resource_type, remaining)
	for cell in cells:
		if remaining <= 0.0:
			break
		if cell.is_empty():
			remaining -= cell.add_resource(resource_type, remaining)
	announce()
	return amount - remaining

## Pulls up to `amount` of a resource back out of the comb.
func take(resource_type: String, amount: float) -> float:
	var still_needed := amount
	for cell in cells:
		if still_needed <= 0.0:
			break
		if resource_type == "honey" and not cell.is_ripe_honey():
			continue   # wet mix isn't food yet
		still_needed -= cell.take_resource(resource_type, still_needed)
	announce()
	return amount - still_needed

## How bees eat. `energy_wanted` is in energy units; honey is drawn on
## first because it is `honey_energy_factor` times as dense as the nectar
## it was made from, so a hive with honey in it feeds far more bees from
## the same comb. Returns the energy actually delivered.
func take_energy(energy_wanted: float) -> float:
	if energy_wanted <= 0.0:
		return 0.0
	var delivered := 0.0

	var honey_units_wanted: float = energy_wanted / max(0.001, GameConfig.honey_energy_factor)
	var honey_taken: float = take("honey", honey_units_wanted)
	delivered += honey_taken * GameConfig.honey_energy_factor

	if delivered < energy_wanted:
		delivered += take("nectar", energy_wanted - delivered)
	return delivered

func total(resource_type: String) -> float:
	var sum := 0.0
	for cell in cells:
		if cell.content_type == resource_type:
			sum += cell.amount
	return sum

## Ripe honey only -- wet mix still drying isn't a store yet.
func total_honey() -> float:
	var sum := 0.0
	for cell in cells:
		if cell.is_ripe_honey():
			sum += cell.amount
	return sum

# --- finding cells ------------------------------------------------

## The cell a bee carrying `resource_type` should walk to: a part-filled
## cell of the same resource if there is one (so stores stay tidy and
## cells fill up rather than spreading thin), otherwise a free cell.
## Cells designated to this resource are preferred over undesignated
## ones. `except` lets a hauling builder avoid its own source cell.
## A cell counted as "practically full" is skipped in favour of starting
## a fresh one, rather than only ever being topped up. Without this, a
## cell that bees are constantly sipping from (foragers refuelling,
## nurses feeding) never quite hits exactly `capacity`, so a second pot
## never got used even once builders had made one -- the trickle of
## withdrawals always left just enough room to look "not full yet".
func find_cell_for(resource_type: String, except: Node2D = null) -> Node2D:
	var best_empty: Node2D = null
	var almost_full: Node2D = null
	for cell in cells:
		if cell == except or not is_instance_valid(cell):
			continue
		if cell.space_for(resource_type) <= 0.0:
			continue
		if cell.content_type == resource_type:
			if cell.amount < cell.capacity * GameConfig.cell_full_threshold:
				return cell   # genuine room -- use it immediately, as before
			elif almost_full == null:
				almost_full = cell   # fallback only, if nothing better turns up
			continue
		if best_empty == null:
			best_empty = cell
		elif cell.designated_type == resource_type and best_empty.designated_type == "":
			best_empty = cell   # prefer a cell the player pinned to this
	return best_empty if best_empty != null else almost_full

## Where the queen should lay her next egg. Cells you've reserved for
## brood come first -- and if there are several, she works through them
## in a fixed rotation (see `_brood_pointer`) rather than always filling
## the first one in the list while it happens to be free. Only once no
## reserved cell is available does she fall back to a spare undesignated
## cell, then finally any empty cell at all.
func find_empty_cell() -> Node2D:
	var brood_cells: Array = cells.filter(func(c): return is_instance_valid(c) and c.is_nursery_cell())
	if not brood_cells.is_empty():
		_brood_pointer = _brood_pointer % brood_cells.size()
		for step in range(brood_cells.size()):
			var idx: int = (_brood_pointer + step) % brood_cells.size()
			var cell = brood_cells[idx]
			if cell.is_empty():
				# next call starts past this one, so a run of eggs spreads
				# across the reserved cells instead of camping the first
				_brood_pointer = (idx + 1) % brood_cells.size()
				return cell

	for cell in cells:
		if cell.is_empty() and cell.designated_type == "":
			return cell
	for cell in cells:
		if cell.is_empty():
			return cell
	return null

func has_room_for_egg() -> bool:
	return find_empty_cell() != null

func find_cell_with(resource_type: String) -> Node2D:
	for cell in cells:
		if cell.content_type == resource_type and cell.amount > 0.0:
			if resource_type == "honey" and not cell.is_ripe_honey():
				continue
			return cell
	return null

## The brood a nurse should go to: the hungriest larva first, so feeding
## keeps up with the whole nursery rather than one favoured cell. Falls
## back to any brood at all, since standing over a fed larva still speeds
## it up.
func find_brood_cell() -> Node2D:
	var hungriest: Node2D = null
	var any_brood: Node2D = null
	for cell in cells:
		if cell.content_type != "brood":
			continue
		if any_brood == null:
			any_brood = cell
		if not cell.needs_feeding():
			continue
		if hungriest == null or cell.brood_fed_seconds < hungriest.brood_fed_seconds:
			hungriest = cell
	return hungriest if hungriest != null else any_brood

## A cell of wet mix that still needs fanning out. Honey makers do this
## between trips, and it's the last step before the cell counts as a
## store the colony can actually eat.
func find_cell_needing_fanning() -> Node2D:
	for cell in cells:
		if cell.needs_fanning():
			return cell
	return null

## Where a honey maker puts its chewed mix: a honey cell with room, or
## failing that any spare cell it can start as a honey pot.
func find_honey_target() -> Node2D:
	return find_cell_for("honey")

func find_unfinished_cell() -> Node2D:
	for cell in cells:
		if not cell.is_built:
			return cell
	return null

func find_cell_needing_eviction() -> Node2D:
	for cell in cells:
		if cell.needs_eviction():
			return cell
	return null

## Is there anywhere else `resource_type` could go? Used to decide
## whether re-designating a cell would destroy its contents.
func has_room_elsewhere(resource_type: String, except: Node2D) -> bool:
	return find_cell_for(resource_type, except) != null

# --- growing the comb ---------------------------------------------

## Adds the next cell in the outward hex spiral as an unfinished site
## for builders to work on. Returns null when the comb has grown as far
## as the hive wall allows -- later, wall-mining bees will lift that.
## Walks outward along the hex spiral looking for the first free
## interior tile, and starts an unfinished cell there for builders to
## work on. Returns null when the open floor is full -- at that point
## the hive can only grow by mining soil, which is the miner role's job.
func create_next_cell_site() -> Node2D:
	if comb_parent == null:
		return null

	var index := 0
	var hex := Vector2i(0, 0)
	var found := false
	# a generous ceiling: every tile the interior could possibly hold
	var limit := 1 + 3 * int(GameConfig.hive_interior_rings) * (int(GameConfig.hive_interior_rings) + 1)
	while index < limit:
		hex = Shapes.hex_spiral_at(index)
		if tile_is_interior(hex) and tile_is_free(hex):
			found = true
			break
		index += 1
	if not found:
		return null

	var cell := HiveCell.new()
	cell.axial = hex
	cell.position = comb_centre + Shapes.hex_to_pixel(hex.x, hex.y, GameConfig.hive_cell_spacing)
	comb_parent.add_child(cell)
	cell.start_as_site()
	cells.append(cell)
	register_tile(hex, cell)
	return cell

## As above, but at a player-chosen tile rather than the next spiral
## slot -- see the "Build cell" placement mode in hud.gd/main.gd. Returns
## null (without side effects) if the tile isn't free open interior
## floor, so the caller can fall back to automatic placement.
func create_cell_site_at(hex: Vector2i) -> Node2D:
	if comb_parent == null:
		return null
	if not tile_is_interior(hex) or not tile_is_free(hex):
		return null

	var cell := HiveCell.new()
	cell.axial = hex
	cell.position = comb_centre + Shapes.hex_to_pixel(hex.x, hex.y, GameConfig.hive_cell_spacing)
	comb_parent.add_child(cell)
	cell.start_as_site()
	cells.append(cell)
	register_tile(hex, cell)
	return cell

# --- navigation ---------------------------------------------------
## Bees can't walk through soil, so movement inside the hive follows a
## route over open tiles. Comb tiles are passable but cost more, which
## reproduces the "slower over cells" rule as a routing preference too:
## a bee will go round the comb if that's genuinely quicker.

const COMB_TRAVEL_COST := 2.0

var _astar := AStar2D.new()
var _tile_ids: Dictionary = {}   # axial -> AStar point id

func build_navigation() -> void:
	_astar.clear()
	_tile_ids.clear()

	var reach := int(GameConfig.hive_interior_rings + GameConfig.hive_soil_depth + GameConfig.hive_rock_rings)
	var next_id := 0
	# every tile that isn't soil or bedrock is walkable
	for ring in range(0, reach + 1):
		for hex in Shapes.hex_ring(ring):
			if _is_solid(hex):
				continue
			_tile_ids[hex] = next_id
			var world_point: Vector2 = comb_centre + Shapes.hex_to_pixel(hex.x, hex.y, GameConfig.hive_cell_spacing)
			_astar.add_point(next_id, world_point, _tile_cost(hex))
			next_id += 1

	var neighbours := [
		Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1),
	]
	for hex in _tile_ids.keys():
		for step in neighbours:
			var other: Vector2i = hex + step
			if _tile_ids.has(other):
				_astar.connect_points(_tile_ids[hex], _tile_ids[other], true)

## Soil can eventually be dug out; bedrock never can. Either way nothing
## walks through it, so routing treats them the same.
func _is_solid(hex: Vector2i) -> bool:
	var node = occupied_tiles.get(hex)
	if node == null or not is_instance_valid(node):
		return false
	return node.is_in_group("soil_blocks") or node.is_in_group("rock_blocks")

func _tile_cost(hex: Vector2i) -> float:
	return COMB_TRAVEL_COST if cell_at_tile(hex) != null else 1.0

func tile_is_walkable(hex: Vector2i) -> bool:
	return _tile_ids.has(hex)

## Used to sanitise a player-commanded destination before a bee is sent
## there: right-clicking on a soil block (solid, no route through it)
## used to leave the bee's target sitting inside the wall, and the "no
## route found" fallback in Bee._move_towards walked it there in a
## straight line -- straight through the wall. Snapping the target to
## whichever walkable tile is actually closest fixes both ends of that.
func nearest_walkable_point(point: Vector2) -> Vector2:
	var hex: Vector2i = Shapes.pixel_to_hex(point - comb_centre, GameConfig.hive_cell_spacing)
	if _tile_ids.has(hex):
		return point
	var best_hex: Vector2i = hex
	var best_dist := INF
	for h in _tile_ids.keys():
		var d: float = Vector2(h.x - hex.x, h.y - hex.y).length_squared()
		if d < best_dist:
			best_dist = d
			best_hex = h
	return comb_centre + Shapes.hex_to_pixel(best_hex.x, best_hex.y, GameConfig.hive_cell_spacing)

## A list of world points from `from_point` to `to_point` that stays out
## of the soil. Returns an empty array if either end is unreachable, in
## which case the caller should just move straight and hope.
func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array:
	var from_hex := Shapes.pixel_to_hex(from_point - comb_centre, GameConfig.hive_cell_spacing)
	var to_hex := Shapes.pixel_to_hex(to_point - comb_centre, GameConfig.hive_cell_spacing)
	if not _tile_ids.has(from_hex) or not _tile_ids.has(to_hex):
		return PackedVector2Array()
	var raw := _astar.get_point_path(_tile_ids[from_hex], _tile_ids[to_hex])
	return _smooth_path(from_point, raw)

## A* returns a route along hex centres, which makes bees walk in a
## zigzag down the six grid directions. This pulls the string tight:
## any waypoint that can be skipped without crossing soil is dropped, so
## bees move in straight lines while still going round walls.
##
## Cheapness still comes from A*, which already prefers open floor to
## comb -- smoothing only removes corners from the route it chose, so
## a bee won't shortcut straight across comb it deliberately avoided.
func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array:
	if raw.size() <= 2:
		return raw
	var result := PackedVector2Array()
	var anchor := from_point
	var i := 1
	while i < raw.size() - 1:
		# look as far ahead as we can still see in a straight line
		var furthest := i
		for j in range(i, raw.size()):
			if _line_is_clear(anchor, raw[j]):
				furthest = j
			else:
				break
		if furthest >= raw.size() - 1:
			break
		result.append(raw[furthest])
		anchor = raw[furthest]
		i = furthest + 1
	result.append(raw[raw.size() - 1])
	return result

## Walks the straight line in small steps and checks nothing solid sits
## on it. Step size is under one tile so a block can't be jumped over.
func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool:
	var span := from_point.distance_to(to_point)
	var steps := int(span / (GameConfig.hive_cell_size * 0.6)) + 1
	for s in range(steps + 1):
		var point: Vector2 = from_point.lerp(to_point, float(s) / float(steps))
		var hex := Shapes.pixel_to_hex(point - comb_centre, GameConfig.hive_cell_spacing)
		if not tile_is_walkable(hex):
			return false
	return true

# --- mining -------------------------------------------------------

const NEIGHBOUR_STEPS := [
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1),
]

## A soil block is on the edge if any neighbouring tile is walkable --
## otherwise no bee could ever stand next to it to dig.
func refresh_edge_flags() -> void:
	for node in occupied_tiles.values():
		if node == null or not is_instance_valid(node) or not node.is_in_group("soil_blocks"):
			continue
		var edge := false
		for step in NEIGHBOUR_STEPS:
			if tile_is_walkable(node.axial + step):
				edge = true
				break
		node.is_edge = edge

## A block the player has flagged for digging. Blocks the player marked
## always come first, whether or not the miner is on automine -- an
## explicit instruction outranks the automatic choice. `from_point` (the
## miner's own position, in hive-local space) breaks ties, so a miner
## goes to the nearest job rather than whichever happened to be first in
## the dictionary.
func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for node in occupied_tiles.values():
		if not _is_markable_block(node) or not node.marked_for_mining:
			continue
		# a block with no open tile beside it can't be reached, so it's no
		# use as a job even though it's marked
		if mine_stand_hex(node) == null:
			continue
		var d: float = 0.0 if from_point.x == INF else from_point.distance_to(node.position)
		if best == null or d < best_distance:
			best_distance = d
			best = node
		if from_point.x == INF:
			return best
	return best

## For automining: the edge block nearest the central wax cell, so
## digging opens up space next to the comb rather than out at the rim.
func find_nearest_edge_block() -> Node2D:
	var best: Node2D = null
	var best_distance := 1 << 30
	for node in occupied_tiles.values():
		if not _is_markable_block(node) or not node.is_edge:
			continue
		if mine_stand_hex(node) == null:
			continue
		# hex ring index is the step distance from (0,0) -- the middle of
		# the comb, where the first cell is drawn
		var d := Shapes.hex_ring_index(node.axial)
		if d < best_distance:
			best_distance = d
			best = node
	return best

func _is_markable_block(node) -> bool:
	return node != null and is_instance_valid(node) and node.is_in_group("soil_blocks")

## The open tile a miner should stand on to dig `block`. Soil is solid,
## so routing a bee at the block's own centre finds no path at all and it
## just stands there -- which is what stopped miners ever reaching a
## marked block. Returns null when nothing open touches it.
func mine_stand_hex(block: Node2D):
	if not is_instance_valid(block):
		return null
	for step in NEIGHBOUR_STEPS:
		var neighbour: Vector2i = block.axial + step
		if tile_is_walkable(neighbour):
			return neighbour
	return null

## As above, as a position in hive-local space, ready to walk to.
## Prefers whichever open neighbour is closest to `from_point`.
func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2:
	var best := Vector2(INF, INF)
	var best_distance := INF
	for step in NEIGHBOUR_STEPS:
		var neighbour: Vector2i = block.axial + step
		if not tile_is_walkable(neighbour):
			continue
		var point: Vector2 = comb_centre + Shapes.hex_to_pixel(neighbour.x, neighbour.y, GameConfig.hive_cell_spacing)
		var d: float = from_point.distance_to(point)
		if d < best_distance:
			best_distance = d
			best = point
	return best

## Turns a finished block back into open floor and reopens the routes
## through it.
func remove_block(block: Node2D, floor_maker: Callable) -> void:
	if not is_instance_valid(block):
		return
	var hex: Vector2i = block.axial
	occupied_tiles.erase(hex)
	block.queue_free()
	floor_maker.call(hex)
	build_navigation()
	refresh_edge_flags()

func announce() -> void:
	storage_changed.emit(total("nectar"), total("pollen"), total_honey())
