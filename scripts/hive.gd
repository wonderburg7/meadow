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
const Resources = preload("res://scripts/resources.gd")
const Roles = preload("res://scripts/roles.gd")

var cells: Array = []            # populated by main.gd once the comb is built
var comb_parent: Node2D = null   # the hive-view root new cells get added to
var comb_centre: Vector2 = Vector2.ZERO

## Set once by world_building.gd right after this Hive is created. Handed
## on to every cell it builds so a cell can reach main.season without a
## per-frame get_nodes_in_group lookup -- see HiveCell._health_factor.
var main: Node2D = null

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

## Foragers currently waiting at the entrance willing to pass on their
## start point (and species, under floral_constancy_on) to a seeker of
## the same resource type (see GameConfig.auto_recruitment_on). A seeker
## doesn't claim one -- any number can read the same mentor's info, so
## this is just "who's currently offering", not a queue.
var entrance_mentors: Array = []

func add_entrance_mentor(bee: Node2D) -> void:
	if not entrance_mentors.has(bee):
		entrance_mentors.append(bee)

func remove_entrance_mentor(bee: Node2D) -> void:
	entrance_mentors.erase(bee)

## Slice 9 (proximity recruitment, GameConfig.proximity_recruitment_on):
## the indoor-dwell counterpart of entrance_mentors above -- a forager
## becomes eligible as soon as her trip is scored (see
## BeeForaging._score_trip/_update_dance_eligibility) and stays eligible
## through the rest of her indoor dwell, not just for one instant at the
## door. Same "who's currently offering/looking" shape as entrance_mentors,
## not a queue. Populated/pruned by BeeForaging wherever eligibility is
## decided, and at move_bee_into_hive/move_bee_out_of_hive
## (world_building.gd). A mentor who already used her one recruit this
## hive visit (bee.has_danced_this_visit) is never added -- see
## add_dance_eligible_mentor.
var dance_eligible_mentors: Array = []
var dance_eligible_seekers: Array = []

func add_dance_eligible_mentor(bee: Node2D) -> void:
	if not bee.has_danced_this_visit and not dance_eligible_mentors.has(bee):
		dance_eligible_mentors.append(bee)

func remove_dance_eligible_mentor(bee: Node2D) -> void:
	dance_eligible_mentors.erase(bee)

func add_dance_eligible_seeker(bee: Node2D) -> void:
	if not dance_eligible_seekers.has(bee):
		dance_eligible_seekers.append(bee)

func remove_dance_eligible_seeker(bee: Node2D) -> void:
	dance_eligible_seekers.erase(bee)

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
## is bucketed by what each cell holds, and the find_* functions read
## the buckets instead. One pass for the colony rather than one pass per
## bee per question.
##
## The buckets used to be rebuilt once per frame regardless of whether
## anything had changed; they're now rebuilt only when a cell mutation
## says they might be stale, same shape as `mining_work_epoch` below.
## `index_epoch` is bumped by `invalidate_index()`, called from every
## cell mutator that can change a cell's content_type/is_built bucket
## (hive_cell.gd) and from the load-restore path (saving.gd), which
## writes those fields directly.

var _index: Dictionary = {}      # content type -> Array of cells
var index_epoch: int = 0
var _index_built_epoch: int = -1

func _content_index() -> Dictionary:
	if _index_built_epoch == index_epoch:
		return _index
	Perf.begin("hive_index_rebuild")

	var buckets := {}
	for key in Resources.content_keys():
		buckets[key] = []
	# Derived buckets: not content kinds, so not in Resources.content_keys().
	buckets["unbuilt"] = []
	buckets["ripe_honey"] = []
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
	_index_built_epoch = index_epoch
	Perf.end("hive_index_rebuild")
	return _index

## The single invalidation source for the content buckets: any mutation
## that changes a cell's content_type, is_built or ripeness calls this
## so the next read rebuilds rather than trusting a stale bucket.
##
## This is Slice 5's `CellChanged` event boundary (CHATGPT_EFFICIENCY_
## IMPLEMENTATION_PLAN.md) -- deliberately not a separate Godot `signal`.
## Every cell mutator and the load-restore path already call this on every
## change, several times per frame at real colony sizes, so a real signal
## here would add per-mutation emit overhead with no consumer: Slice 1/2
## already chose epoch-based polling (index_epoch, corner_signature) over
## push notification for exactly this reason. `index_epoch` bumping is the
## event; a future consumer should compare epochs, not connect a signal.
func invalidate_index() -> void:
	index_epoch += 1

func cells_holding(content: String) -> Array:
	return _content_index().get(content, [])

## `total`, `total_sealed` and `total_honey` (below) are read several times
## a frame -- Challenge goal checks, the problem strip, the winter forecast,
## corner readouts -- and each used to walk every cell on every call.
## `stock_epoch` is a **separate** counter from `index_epoch` above: an
## ordinary deposit or withdrawal changes `amount` without touching
## content_type/is_built/ripeness, so it would never move `index_epoch`,
## and a cache keyed on that would serve a stale total. Every mutator that
## changes `amount`, `is_closed`, `fill_then_close` or `ripen_progress`
## (hive_cell.gd) bumps this instead, and the restore path (saving.gd)
## bumps it too, same shape as `index_epoch`'s own restore bump.
var stock_epoch: int = 0
var _stock_built_epoch: int = -1
var _stock_totals: Dictionary = {}

func invalidate_stock() -> void:
	stock_epoch += 1

func _stock() -> Dictionary:
	if _stock_built_epoch == stock_epoch:
		return _stock_totals
	Perf.begin("hive_stock_rebuild")

	var by_type := {}
	var sealed := 0.0
	var honey := 0.0
	for cell in cells:
		if not is_instance_valid(cell):
			continue
		by_type[cell.content_type] = by_type.get(cell.content_type, 0.0) + cell.amount
		if not cell.can_withdraw():
			sealed += cell.amount
		if cell.is_ripe_honey():
			honey += cell.amount
	_stock_totals = {"by_type": by_type, "sealed": sealed, "honey": honey}
	_stock_built_epoch = stock_epoch
	Perf.end("hive_stock_rebuild")
	return _stock_totals

## Which hex tiles are taken, so comb and soil never overlap.
## Keys are axial Vector2i, values are the node sitting there.
var occupied_tiles: Dictionary = {}

## The single invalidation source for miners waiting for work.  A miner may
## remember a failed search only while this value is unchanged; mutations that
## can make a job appear, disappear or become reachable advance it.
var mining_work_epoch: int = 0

func register_tile(hex: Vector2i, node: Node2D) -> void:
	occupied_tiles[hex] = node
	if node.has_signal("mining_work_changed"):
		node.connect("mining_work_changed", _advance_mining_work_epoch)


func invalidate_mining_work() -> void:
	_advance_mining_work_epoch()


func _advance_mining_work_epoch() -> void:
	mining_work_epoch += 1

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

	for key in Resources.energy_keys_by_priority():
		if delivered >= energy_wanted:
			break
		var factor: float = max(0.001, Resources.energy_factor_for(key))
		var units_wanted: float = (energy_wanted - delivered) / factor
		delivered += take(key, units_wanted) * factor
	return delivered

func total(resource_type: String) -> float:
	return _stock().get("by_type", {}).get(resource_type, 0.0)

## How much of the stores is sealed away in closed cells. Counted in the
## totals (it is still the colony's) but worth showing separately, since
## none of it can be eaten until you open the cells again.
func total_sealed() -> float:
	return _stock().get("sealed", 0.0)

## Ripe honey only -- wet mix still drying isn't a store yet.
func total_honey() -> float:
	return _stock().get("honey", 0.0)

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

## As find_cell_for, but only ever returns a cell the player has
## explicitly pinned to `resource_type` -- no fallback to ordinary empty
## comb. Used where that fallback would let a resource spill into cells
## nobody designated for it (see the jelly-storage bug this fixed).
func find_designated_cell_for(resource_type: String, except: Node2D = null) -> Node2D:
	var best_empty: Node2D = null
	var almost_full: Node2D = null
	for cell in cells:
		if cell == except or not is_instance_valid(cell):
			continue
		if cell.designated_type != resource_type:
			continue
		if cell.space_for(resource_type) <= 0.0:
			continue
		if cell.content_type == resource_type:
			if cell.amount < cell.capacity * GameConfig.cell_full_threshold:
				return cell
			elif almost_full == null:
				almost_full = cell
			continue
		if best_empty == null:
			best_empty = cell
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
	var weight_sum: float = weights[0] + weights[1] + weights[2]
	if weight_sum <= 0.0:
		weight_sum = 1.0
	for tier in range(3):
		_tier_credit[tier] += weights[tier]
	_tier_credit[clampi(cell.nursery_priority, 0, 2)] -= weight_sum
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
			key = Roles.count_key(cell.hatch_role, cell.hatch_focus)
		elif cell.hatch_role > 0:
			key = Roles.count_key(cell.hatch_role, cell.hatch_focus)
		by_role[key] = int(by_role.get(key, 0)) + 1
	return {"counts": counts, "free": free, "by_role": by_role}

## Colony-wide brood counts by developmental stage, for the nursery
## drawer's "brood stages" row (UI_PLAN.md section 15, slice 4). Each
## cell only ever tracks one continuous brood_progress/develop_time()
## fraction (rule 3, CLAUDE.md) -- this buckets that same fraction into
## three roughly equal thirds for display, adding nothing new to what a
## cell tracks, only summing it up.
func brood_stage_counts() -> Dictionary:
	var counts := {"egg": 0, "larva": 0, "capped": 0}
	for cell in cells_holding("brood"):
		var fraction: float = cell.development_percent() / 100.0
		if fraction < 1.0 / 3.0:
			counts["egg"] += 1
		elif fraction < 2.0 / 3.0:
			counts["larva"] += 1
		else:
			counts["capped"] += 1
	return counts

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
		if not cell.is_built and cell.has_free_slot():
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
## Set to the current frame when a full spiral walk has just found
## nothing to build on, so that frame's other idle comb workers get the
## same answer for free rather than each repeating the whole walk.
## Scoped to one frame, not cached until something changes, because
## mining can free a tile at any moment and the very next frame has to
## see it -- unlike `_index_frame` above this never needs an explicit
## invalidate, the timeout is one frame.
##
## Added 16 Aug 2026: with the comb full, every idle comb worker was
## repeating this same few-hundred-tile walk every single frame -- the
## corner readout showed it as 480ms of a frame's budget with a few dozen
## of them idle at once. Exactly the "every bee walks the whole list"
## shape of bug `_content_index()` above already fixed once for the
## cell-content searches; this is the same fix for the comb-growing one.
var _no_room_frame: int = -1

func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D:
	if comb_parent == null:
		return null
	if _no_room_frame == Engine.get_process_frames():
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
		_no_room_frame = Engine.get_process_frames()
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
	cell.main = main
	cell.position = comb_centre + Shapes.hex_to_pixel(hex.x, hex.y, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid)
	comb_parent.add_child(cell)
	cell.start_as_site()
	cells.append(cell)
	register_tile(hex, cell)
	# A new cell changes this tile's travel cost (see _tile_cost). Update
	# the one A* point rather than rebuilding the whole graph, and drop the
	# cached routes, which were smoothed against the old costs.
	if _tile_ids.has(hex):
		_astar.set_point_weight_scale(_tile_ids[hex], _tile_cost(hex))
		_path_cache.clear()
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
	# Every tile that isn't soil or bedrock is walkable -- but only up to
	# `reach - 1`, the outermost ring world_building.gd actually dug or
	# walled (see its _dig_out_chamber loops, which stop one short of
	# `reach` too). Ring `reach` itself was never given a floor, a soil
	# block or a rock block -- nothing registers a node there -- so
	# _is_solid(hex) below reported it as open floor by default and this
	# used to scan one ring past the real structure, adding a phantom
	# walkable ring in the empty space just outside the rock wall. A bee
	# routed anywhere near the entrance could path onto that ring and
	# wander the outer perimeter instead of reaching the actual doorway.
	for ring in range(0, reach):
		for hex in Shapes.hex_ring(ring):
			if _is_solid(hex):
				continue
			_tile_ids[hex] = next_id
			var world_point: Vector2 = comb_centre + Shapes.hex_to_pixel(hex.x, hex.y, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid)
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
## route found" fallback in BeeMovement.move_towards walked it there in a
## straight line -- straight through the wall. Snapping the target to
## whichever walkable tile is actually closest fixes both ends of that.
func nearest_walkable_point(point: Vector2) -> Vector2:
	var hex: Vector2i = Shapes.pixel_to_hex(point - comb_centre, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid)
	if _tile_ids.has(hex):
		return point
	var best_hex: Vector2i = hex
	var best_dist := INF
	for h in _tile_ids.keys():
		var d: float = Vector2(h.x - hex.x, h.y - hex.y).length_squared()
		if d < best_dist:
			best_dist = d
			best_hex = h
	return comb_centre + Shapes.hex_to_pixel(best_hex.x, best_hex.y, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid)

## A list of world points from `from_point` to `to_point` that stays out
## of the soil. Returns an empty array if either end is unreachable, in
## which case the caller should just move straight and hope.
## Routes are cached by the pair of tiles they run between, because bees
## ask for the same handful of journeys over and over -- entrance to
## comb, comb to stores, stores to brood. Mining and comb construction both
## clear the cache when they change the route costs, so a cached route can
## never be stale.
##
## Keyed on tiles rather than exact positions: two bees standing anywhere
## on the same tile want the same route.
var _path_cache: Dictionary = {}
const PATH_CACHE_LIMIT := 2000

func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array:
	Perf.begin("bee_path")
	var from_hex := Shapes.pixel_to_hex(from_point - comb_centre, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid)
	var to_hex := Shapes.pixel_to_hex(to_point - comb_centre, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid)
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
	var from_centre: Vector2 = comb_centre + Shapes.hex_to_pixel(from_hex.x, from_hex.y, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid)
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
	# Sampled in true (unsquashed) hex space -- the squashed pixel span
	# under-counts steps on a near-vertical line, which could skip a
	# solid tile the straight-line walk actually crosses.
	var squashed: bool = Session.use_sprite_hex_grid
	var span := Shapes.unsquash_point(from_point, squashed).distance_to(Shapes.unsquash_point(to_point, squashed))
	var steps := int(span / (GameConfig.hive_cell_size * 0.6)) + 1
	for s in range(steps + 1):
		var point: Vector2 = from_point.lerp(to_point, float(s) / float(steps))
		var hex := Shapes.pixel_to_hex(point - comb_centre, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid)
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
	var topology_changed := false
	for node in occupied_tiles.values():
		if node == null or not is_instance_valid(node) or not node.is_in_group("soil_blocks"):
			continue
		var edge := false
		for step in NEIGHBOUR_STEPS:
			if tile_is_walkable(node.axial + step):
				edge = true
				break
		if node.is_edge != edge:
			node.is_edge = edge
			topology_changed = true
	if topology_changed:
		_advance_mining_work_epoch()

## A block the player has flagged for digging. Blocks the player marked
## always come first, whether or not the miner is on automine -- an
## explicit instruction outranks the automatic choice. `from_point` (the
## miner's own position, in hive-local space) breaks ties, so a miner
## goes to the nearest job rather than whichever happened to be first in
## the dictionary.
func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D:
	var squashed: bool = Session.use_sprite_hex_grid
	var true_from: Vector2 = Shapes.unsquash_point(from_point, squashed)
	var best: Node2D = null
	var best_distance := INF
	for node in occupied_tiles.values():
		if not _is_markable_block(node) or not node.marked_for_mining:
			continue
		# a block with no open tile beside it can't be reached, so it's no
		# use as a job even though it's marked
		if mine_stand_hex(node) == null:
			continue
		# Unsquashed so a miner's "nearest" pick is the same regardless of
		# which of the six directions the block happens to sit in -- the
		# squashed grid's compressed y axis would otherwise favour blocks
		# above/below over ones the same hex-distance to the side.
		var d: float = 0.0 if from_point.x == INF else true_from.distance_to(Shapes.unsquash_point(node.position, squashed))
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
	var squashed: bool = Session.use_sprite_hex_grid
	var true_from: Vector2 = Shapes.unsquash_point(from_point, squashed)
	var best: Node2D = null
	var best_distance := INF
	for node in occupied_tiles.values():
		if not _is_markable_block(node) or not node.is_edge:
			continue
		if mine_stand_hex(node) == null:
			continue
		# Both branches are hex-space distances now (see find_marked_block):
		# hex ring index is the step distance from (0,0) -- the middle of
		# the comb, where the first cell is drawn -- and the unsquashed
		# from_point case matches it so a miner's own home cell spirals
		# outward the same way the from-centre fallback does.
		var d: float = (
			true_from.distance_to(Shapes.unsquash_point(node.position, squashed)) if from_point.x != INF
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
	var squashed: bool = Session.use_sprite_hex_grid
	var true_from: Vector2 = Shapes.unsquash_point(from_point, squashed)
	var best := Vector2(INF, INF)
	var best_distance := INF
	for step in NEIGHBOUR_STEPS:
		var neighbour: Vector2i = block.axial + step
		if not tile_is_walkable(neighbour):
			continue
		var point: Vector2 = comb_centre + Shapes.hex_to_pixel(neighbour.x, neighbour.y, GameConfig.hive_cell_spacing, squashed)
		# Unsquashed distance -- see find_marked_block -- so the six faces
		# of a block are judged by true hex-distance, not squashed pixels.
		var d: float = true_from.distance_to(Shapes.unsquash_point(point, squashed))
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
	_advance_mining_work_epoch()
	block.queue_free()
	floor_maker.call(hex)
	build_navigation()
	refresh_edge_flags()

func announce() -> void:
	storage_changed.emit(total("nectar"), total("pollen"), total_honey(), total("jelly"))
