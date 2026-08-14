extends Polygon2D
## The hive's meadow-side marker (the brown square foragers fly home to)
## and the accountant for everything stored in the comb.
##
## Storage physically lives in the hexagonal cells over in the hive
## view; this script routes deposits and withdrawals to them and hands
## out jobs to builders, so the meadow never needs to know how the comb
## is laid out.

signal storage_changed(nectar: float, pollen: float, honey: float, jelly: float)

const Shapes = preload("res://scripts/shapes.gd")
const HiveCell = preload("res://scripts/hive_cell.gd")

var cells: Array = []            # populated by main.gd once the comb is built
var comb_parent: Node2D = null   # the hive-view root new cells get added to
var comb_centre: Vector2 = Vector2.ZERO

## Rotation pointer for find_empty_cell's brood-cell sequence, used to
## spread a run of eggs across the cells within one priority tier rather
## than camping the first free one.
var _brood_pointer: int = 0

## Running credit per priority tier (low, medium, high) for the weighted
## share-out in `find_empty_cell`. See the note there.
var _tier_credit: Array = [0.0, 0.0, 0.0]

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

# --- cell index ---------------------------------------------------
## Every bee used to walk the whole cell list several times a frame
## looking for work -- fine at twenty bees, not at two hundred. The list
## is now bucketed by what each cell holds, once per frame, and the
## find_* functions read the buckets instead. One pass for the colony
## rather than one pass per bee per question.

var _index: Dictionary = {}      # content type -> Array of cells
var _index_frame: int = -1

func _content_index() -> Dictionary:
	var frame := Engine.get_process_frames()
	if _index_frame == frame:
		return _index
	_index_frame = frame

	var buckets := {
		"": [], "nectar": [], "pollen": [], "honey": [], "jelly": [],
		"brood": [], "corpse": [], "unbuilt": [], "ripe_honey": [],
	}
	for cell in cells:
		if not is_instance_valid(cell):
			continue
		if not cell.is_built:
			buckets["unbuilt"].append(cell)
			continue
		buckets[cell.content_type].append(cell)
		if cell.is_ripe_honey():
			buckets["ripe_honey"].append(cell)
	_index = buckets
	return _index

## Drops the cached buckets, for the rare case where a caller changes
## cells and needs the next read in the same frame to see it.
func invalidate_index() -> void:
	_index_frame = -1

func cells_holding(content: String) -> Array:
	return _content_index().get(content, [])

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

## How much of the stores is sealed away in closed cells. Counted in the
## totals (it is still the colony's) but worth showing separately, since
## none of it can be eaten until you open the cells again.
func total_sealed() -> float:
	var sum := 0.0
	for cell in cells:
		if is_instance_valid(cell) and not cell.can_withdraw():
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

## Where the queen should lay her next egg.
##
## The order is: configured nursery cells, shared out between the three
## priority tiers; then nursery cells with no role set; then, if the
## player allows it, any spare undesignated comb.
##
## The tier share-out is a deficit-weighted round robin -- the same idea
## a network router uses to divide bandwidth fairly between connections
## of different priority. Each tier accumulates credit equal to its
## weight on every lay; whichever tier has the most credit *and* somewhere
## to put an egg gets it, and pays the total weight back out of its
## credit.
##
## The reason for doing it this way rather than "high priority first" is
## certainty: over any stretch of time the tiers get eggs in exactly the
## ratio of their weights, and they come out interleaved (high, medium,
## high, low, ...) rather than in streaks. So a 1:2:3 zone really does
## produce a 1:2:3 mix, and it does so steadily enough to see.
func find_empty_cell() -> Node2D:
	var configured: Array = []
	var unset: Array = []
	for cell in cells:
		if not is_instance_valid(cell) or not cell.is_nursery_cell():
			continue
		if cell.hatch_role >= 0 or cell.hatch_gyne:
			configured.append(cell)
		else:
			unset.append(cell)

	var chosen := _lay_by_priority(configured)
	if chosen != null:
		return chosen

	# Zone cells with no role named are the fallback within the zone: an
	# egg goes here only when every configured cell is busy, and the bee
	# that emerges is an ordinary nectar forager. That way an unset cell
	# is never wasted, but it also never outbids a cell you set up.
	chosen = _lay_by_priority(unset)
	if chosen != null:
		return chosen

	# Plain spare comb, last of all, and only if the player has left the
	# queen free to use it. There used to be a pass here that took any
	# empty cell at all, which meant she would lay into a cell reserved
	# for pollen or honey -- the one thing a reservation should prevent.
	if not GameConfig.queen_lays_in_any_cell:
		return null
	for cell in cells:
		if not is_instance_valid(cell):
			continue
		if cell.is_empty() and cell.designated_type == "" and not cell.keep_empty and not cell.is_closed:
			return cell
	return null

## Picks a cell out of `pool` according to the priority weights. Returns
## null when nothing in the pool is free.
##
## Deliberately free of side effects. find_empty_cell is a question the
## queen asks constantly -- "is there anywhere to lay?", "how much pollen
## does the next egg need?" -- and only occasionally acts on. If asking
## moved the credit along, the tiers would be shared out in proportion to
## how often the question was asked rather than how many eggs were laid,
## which is not the same thing at all. The credit only moves in
## `record_lay`, called at the moment an egg actually goes in.
func _lay_by_priority(pool: Array) -> Node2D:
	if pool.is_empty():
		return null

	var weights := _tier_weights()

	# Sort the free cells into their tiers first, so a tier with nowhere
	# to lay is skipped rather than being handed an egg it can't take.
	var by_tier := [[], [], []]
	for cell in pool:
		if cell.is_empty():
			by_tier[clampi(cell.nursery_priority, 0, 2)].append(cell)

	var best := -1
	var best_credit := -INF
	for tier in range(3):
		if by_tier[tier].is_empty():
			continue
		# what this tier's credit *would* be on the next lay
		var projected: float = _tier_credit[tier] + weights[tier]
		if projected > best_credit:
			best_credit = projected
			best = tier
	if best == -1:
		return null

	# Within the tier, keep the old rotation so a run of eggs spreads
	# across its cells rather than filling one at a time.
	var tier_cells: Array = by_tier[best]
	return tier_cells[_brood_pointer % tier_cells.size()]

func _tier_weights() -> Array:
	return [
		max(0.0, GameConfig.lay_weight_low),
		max(0.0, GameConfig.lay_weight_medium),
		max(0.0, GameConfig.lay_weight_high),
	]

## Called by the queen the instant an egg goes into `cell`. This is where
## the priority credit actually moves: every tier earns its weight, and
## the tier that got the egg pays the total back. A tier whose cells are
## all occupied keeps banking credit and so gets first refusal the moment
## one frees up -- nothing is lost by being busy.
##
## Eggs laid in plain undesignated comb don't touch the credit, since
## they were never part of the zone's share-out.
func record_lay(cell: Node2D) -> void:
	if not is_instance_valid(cell) or not cell.is_nursery_cell():
		return
	var weights := _tier_weights()
	var total: float = weights[0] + weights[1] + weights[2]
	if total <= 0.0:
		total = 1.0
	for tier in range(3):
		_tier_credit[tier] += weights[tier]
	_tier_credit[clampi(cell.nursery_priority, 0, 2)] -= total
	_brood_pointer += 1

## How many zone cells sit in each tier, and how many of those are free,
## for the nursery window's readout.
func zone_summary() -> Dictionary:
	var counts := [0, 0, 0]
	var free := [0, 0, 0]
	var by_role := {}
	for cell in cells:
		if not is_instance_valid(cell) or not cell.is_nursery_cell():
			continue
		var tier: int = clampi(cell.nursery_priority, 0, 2)
		counts[tier] += 1
		if cell.is_empty():
			free[tier] += 1
		# Keyed the same way the live population counts are, so the two
		# read against each other row for row: the focus only forms part
		# of the key for foragers, since it means nothing for anyone else.
		var key: String = "unset"
		if cell.hatch_gyne:
			key = "gyne"
		elif cell.hatch_role == 0:
			key = "0|%s" % cell.hatch_focus
		elif cell.hatch_role > 0:
			key = "%d|" % cell.hatch_role
		by_role[key] = int(by_role.get(key, 0)) + 1
	return {"counts": counts, "free": free, "by_role": by_role}

## What a hungry bee walks to when it needs feeding. Ripe honey first --
## it carries several times the energy per unit, so a bee spends less
## time at the cell and the same comb feeds far more of them.
func find_food_cell(except: Node2D = null) -> Node2D:
	for cell in cells:
		if cell == except or not is_instance_valid(cell) or not cell.can_withdraw():
			continue
		if cell.is_ripe_honey() and cell.amount > 0.0:
			return cell
	for cell in cells:
		if cell == except or not is_instance_valid(cell) or not cell.can_withdraw():
			continue
		if cell.content_type == "nectar" and cell.amount > 0.0:
			return cell
	return null

func has_room_for_egg() -> bool:
	return find_empty_cell() != null

func find_cell_with(resource_type: String) -> Node2D:
	var bucket: String = "ripe_honey" if resource_type == "honey" else resource_type
	for cell in cells_holding(bucket):
		# a sealed cell is out of circulation -- sending a bee to one just
		# has it walk over, get nothing, and ask again
		if cell.amount > 0.0 and cell.can_withdraw():
			return cell
	return null

## The brood a nurse should go to: the hungriest larva first, so feeding
## keeps up with the whole nursery rather than one favoured cell. Falls
## back to any brood at all, since standing over a fed larva still speeds
## it up.
func find_brood_cell() -> Node2D:
	var hungriest: Node2D = null
	var any_brood: Node2D = null
	for cell in cells_holding("brood"):
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

## A cell blocked by a dead larva. Nothing can be stored there and no egg
## can be laid in it until a comb worker clears it, so this outranks every
## other maintenance job.
func find_cell_needing_cleaning() -> Node2D:
	var corpses := cells_holding("corpse")
	return corpses[0] if not corpses.is_empty() else null

func find_cell_needing_eviction() -> Node2D:
	for cell in cells:
		if is_instance_valid(cell) and cell.needs_eviction():
			return cell
	return null

## A gyne larva waiting on royal jelly, so nurses know whether it's worth
## anyone making any.
func has_gyne_brood() -> bool:
	for cell in cells_holding("brood"):
		if cell.brood_is_gyne:
			return true
	return false

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
## `around` is the tile the spiral grows out from -- a comb worker's own
## home cell if it has been given one, otherwise the middle of the comb.
## Two comb workers with different home cells will grow the hive in two
## places at once instead of both queueing at the same edge.
##
## Comb can now go on any open tile, not just the original interior
## rings: ground the miners have opened up is exactly the space the comb
## is supposed to expand into, and refusing to build there made mining
## pointless.
func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D:
	if comb_parent == null:
		return null

	var hex := Vector2i(0, 0)
	var found := false
	# generous ceiling: everything out to the far edge of the dug ground
	var reach := int(GameConfig.hive_interior_rings + GameConfig.hive_soil_depth)
	var limit := 1 + 3 * reach * (reach + 1)
	var index := 0
	while index < limit:
		hex = around + Shapes.hex_spiral_at(index)
		if _can_build_on(hex):
			found = true
			break
		index += 1
	if not found:
		return null

	return _start_site_at(hex)

## Tiles the player has asked to be left as open floor. Comb workers skip
## these when picking a site, so you can keep a corridor through the
## middle of the comb or leave a landing area by the entrance rather than
## having the hive slowly fill in solid.
##
## Colony-wide rather than per-bee: "don't build here" is a fact about
## the hive, and having each comb worker hold its own copy would mean the
## rule quietly stopped applying as bees died and were replaced.
var keep_clear_tiles: Dictionary = {}

func set_keep_clear(hex: Vector2i, value: bool) -> void:
	if value:
		keep_clear_tiles[hex] = true
	else:
		keep_clear_tiles.erase(hex)

func is_keep_clear(hex: Vector2i) -> bool:
	return keep_clear_tiles.has(hex)

## Buildable means open, walkable ground with nothing already on it that
## the player hasn't reserved as open space.
## `tile_is_walkable` is the honest test: it's true for exactly the tiles
## a bee can stand on, which is the same set comb can be drawn on.
func can_build_on(hex: Vector2i) -> bool:
	return tile_is_free(hex) and tile_is_walkable(hex) and not is_keep_clear(hex)

func _can_build_on(hex: Vector2i) -> bool:
	return can_build_on(hex)

func _start_site_at(hex: Vector2i) -> Node2D:
	var cell := HiveCell.new()
	cell.axial = hex
	cell.position = comb_centre + Shapes.hex_to_pixel(hex.x, hex.y, GameConfig.hive_cell_spacing)
	comb_parent.add_child(cell)
	cell.start_as_site()
	cells.append(cell)
	register_tile(hex, cell)
	invalidate_index()
	return cell

## As above, but at a player-chosen tile rather than the next spiral
## slot -- see the "Build cell" placement mode in hud.gd/main.gd. Returns
## null (without side effects) if the tile isn't free open interior
## floor, so the caller can fall back to automatic placement.
func create_cell_site_at(hex: Vector2i) -> Node2D:
	if comb_parent == null or not _can_build_on(hex):
		return null
	return _start_site_at(hex)

# --- navigation ---------------------------------------------------
## Bees can't walk through soil, so movement inside the hive follows a
## route over open tiles. Comb tiles are passable but cost more, which
## reproduces the "slower over cells" rule as a routing preference too:
## a bee will go round the comb if that's genuinely quicker.

const COMB_TRAVEL_COST := 2.0

var _astar := AStar2D.new()
var _tile_ids: Dictionary = {}   # axial -> AStar point id

func build_navigation() -> void:
	Perf.begin("nav_rebuild")
	_astar.clear()
	_tile_ids.clear()
	# the layout has changed, so every cached route is suspect
	_path_cache.clear()

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
	Perf.end("nav_rebuild")

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
## Routes are cached by the pair of tiles they run between, because bees
## ask for the same handful of journeys over and over -- entrance to
## comb, comb to stores, stores to brood. The hive layout only changes
## when a block is mined out, and build_navigation clears the cache when
## that happens, so a cached route can never be stale.
##
## Keyed on tiles rather than exact positions: two bees standing anywhere
## on the same tile want the same route.
var _path_cache: Dictionary = {}
const PATH_CACHE_LIMIT := 2000

func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array:
	Perf.begin("bee_path")
	var from_hex := Shapes.pixel_to_hex(from_point - comb_centre, GameConfig.hive_cell_spacing)
	var to_hex := Shapes.pixel_to_hex(to_point - comb_centre, GameConfig.hive_cell_spacing)
	if not _tile_ids.has(from_hex) or not _tile_ids.has(to_hex):
		Perf.end("bee_path")
		return PackedVector2Array()

	var key := Vector4i(from_hex.x, from_hex.y, to_hex.x, to_hex.y)
	if _path_cache.has(key):
		Perf.end("bee_path")
		return _path_cache[key]

	var raw := _astar.get_point_path(_tile_ids[from_hex], _tile_ids[to_hex])
	# Smoothed from the tile centre rather than the bee's exact position,
	# so the result is the same for everyone on that tile and can be
	# shared. The bee walks to the first waypoint from wherever it is.
	var from_centre: Vector2 = comb_centre + Shapes.hex_to_pixel(from_hex.x, from_hex.y, GameConfig.hive_cell_spacing)
	var smoothed := _smooth_path(from_centre, raw)

	if _path_cache.size() >= PATH_CACHE_LIMIT:
		_path_cache.clear()   # simplest eviction: start again rather than track ages
	_path_cache[key] = smoothed
	Perf.end("bee_path")
	return smoothed

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
## `from_point` overrides that with a miner's own home cell, in which
## case digging opens up around there instead.
func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for node in occupied_tiles.values():
		if not _is_markable_block(node) or not node.is_edge:
			continue
		if mine_stand_hex(node) == null:
			continue
		# hex ring index is the step distance from (0,0) -- the middle of
		# the comb, where the first cell is drawn
		var d: float = (
			from_point.distance_to(node.position) if from_point.x != INF
			else float(Shapes.hex_ring_index(node.axial))
		)
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
##
## The miner doesn't stand on the centre of that tile but part of the way
## across it towards the soil, so it is visibly working the face of the
## block rather than standing a whole tile back from it.
##
## It has to stay under 0.5: at exactly half way it is on the boundary
## between the two tiles, and any further puts the destination inside the
## soil block itself -- which is not walkable, so path_between would find
## no route and the miner would stand still forever. That is the bug that
## stopped marked blocks ever being dug in the first place.
const MINER_FACE_APPROACH := 0.35

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
	if best.x == INF:
		return best
	return best.lerp(block.position, MINER_FACE_APPROACH)

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
	storage_changed.emit(total("nectar"), total("pollen"), total_honey(), total("jelly"))
