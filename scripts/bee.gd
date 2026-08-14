extends Node2D
## Bee -- v1 prototype, slice 8.
##
## A bee has a ROLE, and (if foraging) a FOCUS resource:
##   Forager    -- flies out to flowers, brings nectar or pollen home
##   Nursery    -- stays in the hive, carries eggs to cells, tends brood
##   Builder    -- draws new comb cells, and hauls resources between cells
##   Egg layer  -- queen only: eats pollen, lays eggs on the hive floor
##
## Foraging loop: pick an unoccupied flower with spare focus resource
## that isn't on this bee's "recently drained" list, fly there, collect,
## repeat until the stomach is full, then fly home, walk in through the
## hive entrance, deposit into a cell, and walk back out.
##
## Every bee burns energy constantly and dies if it hits zero, and dies
## of old age at `bee_lifespan_days`. Foragers refuel from the comb when
## they deposit; in-hive bees sip from the comb as they go.
##
## The queen is an ordinary bee with `is_queen` set: she moves slower,
## and she alone can take the Egg layer role. She can be reassigned to
## forage or build like anyone else.

## HONEY_MAKER is appended rather than slotted in alphabetically because
## hive_cell.hatch_role and hud.gd's HATCH_ROLES store these as plain
## ints -- renumbering the existing ones would silently change what
## every already-earmarked cell raises.
enum Role { FORAGER, NURSERY, BUILDER, EGG_LAYER, IDLE, MINER, HONEY_MAKER }

## Perf section per role, indexed by the Role enum above -- an Array
## lookup rather than building a string every frame, so asking "which
## role is it" in the breakdown costs almost nothing extra.
const ROLE_PERF_SECTIONS := [
	"bee_state_forager", "bee_state_nurse", "bee_state_builder",
	"bee_state_queen", "bee_state_idle", "bee_state_miner", "bee_state_honey",
]
enum State {
	SEEK_FLOWER, TO_FLOWER, INSPECTING, COLLECTING, TO_HIVE,   # forager, outdoors
	DRINKING, SHELTERING,                                  # forager, refuelling / rained off
	MAKING_JELLY, TO_JELLY_CELL, DEPOSITING_JELLY,         # nursery, royal jelly
	IN_HIVE_TO_CELL, DEPOSITING, IN_HIVE_TO_EXIT,          # forager, indoors
	MOVE_TO_POINT, IDLING,                                 # player-commanded
	NURSE_IDLE, TO_BROOD, TENDING,                         # nursery
	TO_FOOD_CELL, LOADING_FOOD,                            # nursery, fetching a meal
	TO_FEED_CELL, FEEDING,                                 # any bee, eating
	BUILD_IDLE, TO_BUILD_SITE, BUILDING,                   # builder
	TO_HAUL_SOURCE, TO_HAUL_TARGET,                        # builder, moving stores
	TO_RESTOCK_SOURCE, TO_RESTOCK_TARGET,                  # builder, keeping cells topped up
	TO_WASTE_EXIT, DUMPING_WASTE,                          # builder, throwing it out
	TO_CLEAN_CELL, CLEANING,                               # comb worker, clearing a dead larva
	MINE_IDLE, TO_MINE_SITE, MINING,                       # miner
	TO_MINE_EXIT, DUMPING_DIRT,                            # miner, full of spoil
	SEEK_POLLEN, TO_POLLEN_CELL, EATING,                   # egg layer
	TO_CELL_TO_LAY, LAYING,
	HONEY_IDLE, TO_NECTAR_CELL, CHEWING,                   # honey maker
	TO_HONEY_CELL, DEPOSITING_HONEY, FANNING,
}

const Shapes = preload("res://scripts/shapes.gd")
const Roles = preload("res://scripts/roles.gd")

var speed: float = 110.0
var flower_handling_time: float = 2.0
var nectar_collection_rate: float = 5.0
var pollen_collection_rate: float = 2.0
var deposit_time: float = 2.5
var nectar_stomach_capacity: float = 50.0
var pollen_stomach_capacity: float = 25.0
var arrive_distance: float = 4.0
var click_radius: float = 14.0

var role: int = Role.FORAGER
var state: int = State.SEEK_FLOWER
var timer: float = 0.0
var is_queen: bool = false

## A gyne: a future queen, raised on royal jelly and several times more
## expensive than a worker. She can do any worker job while she is here,
## but she is bigger, slower and hungrier than one.
var is_gyne: bool = false

## Nursery sub-mode: "feed" tends and feeds brood, "jelly" makes royal
## jelly for gyne larvae, "both" does either as it comes up.
var nurse_mode: String = "feed"
## Royal jelly this nurse is carrying, both to feed gyne larvae with and
## to deposit into a jelly cell after making a batch.
var nurse_jelly: float = 0.0

var hive: Node2D          # the meadow-side marker / storage accountant
var world: Node2D         # main.gd -- owns the geometry and the two roots
var resource_type: String = "nectar"    # this bee's focus, when foraging
var current_load: float = 0.0
var current_load_type: String = ""
var current_flower: Node2D = null
var bee_id: int = 0

var energy: float = 100.0
var age_seconds: float = 0.0
var selected: bool = false
## queue_free only takes effect at the end of the frame, so without this
## a dying bee can be processed again and die twice.
var is_dying: bool = false

var move_target: Vector2 = Vector2.ZERO   # for player-commanded movement
var target_cell: Node2D = null
var haul_target: Node2D = null
var target_block: Node2D = null
var automine: bool = false

## What a comb worker (the Builder role) actually does: "build" draws new
## comb, "maintain" clears dead larvae and shifts stores out of cells the
## player has re-designated, "both" does either as it comes up.
var architect_mode: String = "both"
## True while carrying a dead larva out of the hive to throw away.
var carrying_corpse: bool = false

## Whether a change of job waits for the current one to finish. Off means
## the bee drops what it's doing the instant you reassign it; on means it
## sees the job through first -- a forager, for instance, delivers its
## load before it takes up the new role. `pending_role` holds the change
## until then.
var finish_task_first: bool = false
var pending_role: int = -1
var dirt_load: float = 0.0
var pollen_eaten: float = 0.0

## Honey making. `honey_load` is chewed nectar-and-enzyme mix on its way
## to a cell; `fan_target` is the cell currently being dried out.
var honey_load: float = 0.0
var fan_target: Node2D = null

## The wall of `target_cell` this bee has claimed while loading or
## unloading. -1 means it doesn't hold one. Only six bees can work a cell
## at a time, one per wall, so they never stand on top of each other.
var cell_slot: int = -1
var slot_cell: Node2D = null

## What a nurse is physically carrying. Brood is fed from this, not from
## the comb directly, so a nurse has to go and load up first -- see
## _nurse_restock_errand. `nurse_carb` is either nectar or honey; which
## one is in `nurse_carb_type`, because honey feeds a larva for longer.
var nurse_pollen: float = 0.0
var nurse_carb: float = 0.0
var nurse_carb_type: String = ""
var nurse_fetching: String = ""      # what this trip to a cell is for

## Stall watchdog. A bee that hasn't moved for a few seconds while it is
## supposed to be travelling has got itself pinned on something; rather
## than hovering there until the player notices, it gives up on the
## current errand. See _watch_for_stalls.
var stall_best_distance: float = INF
var stall_timer: float = 0.0
const STALL_SECONDS := 4.0
## How close to an obstacle a bee has to be for the escape hatch to treat
## it as the thing it is caught on.
const ESCAPE_RANGE := 60.0

## A role to fall back to whenever this bee's primary role has genuinely
## nothing for it to do right now -- a non-automine miner with no block
## marked, a nurse with no brood to tend, a builder with nowhere left to
## build. -1 means none set. The bee's own `role` never changes because
## of this; it just borrows another role's behaviour between primary
## tasks and drops it the instant primary work turns up again.
var secondary_role: int = -1

## Floral constancy (see GameConfig.floral_constancy_on): "" means no
## preference. Once set, this bee only ever selects flowers of this
## species, regardless of the toggle -- turning constancy off in tuning
## just stops new preferences being offered, it doesn't clear ones a
## bee already has.
var preferred_species: String = ""

## Player-set point (meadow/global space) a forager heads to first on
## every trip out, before hunting for a flower. Lets the player split
## foragers across different parts of the meadow instead of them all
## drifting to whatever's nearest the entrance. INF means "not set".
var forage_start_point: Vector2 = Vector2(INF, INF)

## A player-placed manual cell site a builder should try first, before
## falling back to its usual pick-a-site logic. Consumed (cleared) the
## moment it's acted on, successfully or not, so a bad click can't loop.
var manual_build_hex: Vector2i = Vector2i.ZERO
var has_manual_build_target: bool = false
## Tiles this comb worker has been told to build on, in the order they were
## clicked. Only this bee works its own queue; other comb workers pick
## their own sites as before.
var build_queue: Array = []
## The same for a miner: blocks it has been told to dig, in order.
var mine_queue: Array = []

## A comb worker's own centre of operations. Left to pick its own sites it
## fills the space around this tile outwards in a honeycomb spiral,
## rather than always adding to the middle of the comb -- so two
## comb workers with different home cells grow the hive in two places.
var home_hex: Vector2i = Vector2i.ZERO
var has_home_hex: bool = false
## The same idea for miners: the tile a miner works outward from when
## choosing which soil to dig next.
var mine_home_hex: Vector2i = Vector2i.ZERO
var has_mine_home: bool = false

## Flowers this bee has drained, mapped to the sim-time at which they
## should be back to full. Time-based rather than checking the flower's
## live amount, so a bee commits to staying away for the whole recharge
## rather than darting back the moment a trickle appears.
var flower_cooldowns: Dictionary = {}

## Cached route while walking inside the hive -- see _move_towards.
var path_points: PackedVector2Array = PackedVector2Array()
var path_index: int = 0
var path_goal: Vector2 = Vector2(INF, INF)

var label: Label
var selection_ring: Polygon2D
var body: Polygon2D

func _ready() -> void:
	add_to_group("bees")
	# Newly built cells and freshly-mined floor tiles get added to
	# hive_root's child list after bees that already exist, which made
	# them draw on top -- Godot draws same-z siblings in child order, and
	# reparenting/adding doesn't reshuffle existing children. Giving bees
	# a fixed z_index above the static furniture (floor, soil, cells, all
	# left at the default 0) means draw order no longer depends on when
	# each node happened to be added.
	z_index = 5

	speed = GameConfig.bee_speed
	flower_handling_time = GameConfig.flower_handling_time
	nectar_collection_rate = GameConfig.nectar_collection_rate
	pollen_collection_rate = GameConfig.pollen_collection_rate
	deposit_time = GameConfig.deposit_time
	nectar_stomach_capacity = GameConfig.nectar_stomach_capacity
	pollen_stomach_capacity = GameConfig.pollen_stomach_capacity
	energy = GameConfig.energy_capacity

	# A gyne sits visibly between a worker and the queen, so you can pick
	# one out of a crowd without selecting it.
	var size_factor: float = 1.0
	if is_queen:
		size_factor = 1.55
	elif is_gyne:
		size_factor = GameConfig.gyne_size_factor
	var body_radius: float = 6.5 * size_factor
	var outline_radius: float = 9.0 * size_factor
	click_radius = outline_radius + 5.0

	selection_ring = Polygon2D.new()
	selection_ring.polygon = Shapes.circle_points(outline_radius + 4.0)
	selection_ring.color = Color(0.2, 1.0, 0.4, 0.85)
	selection_ring.visible = false
	add_child(selection_ring)

	var outline := Polygon2D.new()
	outline.polygon = Shapes.circle_points(outline_radius)
	outline.color = Color(0.05, 0.05, 0.05)   # black outline
	add_child(outline)

	body = Polygon2D.new()
	body.polygon = Shapes.circle_points(body_radius)
	body.color = _base_colour()
	add_child(body)

	label = Label.new()
	label.position = Vector2(-16, -32 if not is_queen else -40)
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)

func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void:
	hive = hive_node
	world = world_node
	resource_type = type
	bee_id = id
	role = bee_role
	if is_gyne:
		speed = GameConfig.bee_speed * GameConfig.gyne_speed_factor
	if is_queen:
		speed = GameConfig.bee_speed * GameConfig.queen_speed_factor
		# The queen's day used to be eat, lay, wait, eat, lay. Nursing is
		# her natural second job -- she is in the brood nest anyway -- so
		# she picks it up automatically whenever laying is blocked. The
		# player can change it like any other bee's backup role.
		if secondary_role == -1:
			secondary_role = Role.NURSERY
	state = _default_state_for_role()
	_update_label()

func _default_state_for_role() -> int:
	match role:
		Role.NURSERY:
			return State.NURSE_IDLE
		Role.BUILDER:
			return State.BUILD_IDLE
		Role.EGG_LAYER:
			# Deliberately an idle state rather than SEEK_POLLEN: it sends
			# the queen through _idle_dispatch, which checks the brood
			# before it checks laying. Going straight to SEEK_POLLEN would
			# have her start on the next egg without ever looking at the
			# larvae she already has.
			return State.NURSE_IDLE
		Role.IDLE:
			return State.IDLING
		Role.MINER:
			return State.MINE_IDLE
		Role.HONEY_MAKER:
			return State.HONEY_IDLE
		_:
			return State.SEEK_FLOWER

func _base_colour() -> Color:
	if is_queen:
		return Color(0.95, 0.45, 0.75)
	if is_gyne:
		return Color(1.0, 0.62, 0.35)   # between a worker's yellow and the queen's pink
	return Color(1.0, 0.85, 0.1)

# --- how often a bee thinks ---------------------------------------
## Movement has to happen every frame or bees stutter. *Deciding* things
## does not: a bee choosing a flower, checking whether it is hungry, or
## looking for work is making a judgement on a scale of seconds, and
## asking sixty times a second is sixty times more often than the answer
## can change.
##
## So the state machine runs every frame (it is mostly movement) but the
## expensive judgements behind it -- searching the comb for work, picking
## a flower, scanning for a stall -- run on a slower tick. At 8 a second
## no behaviour is visibly different and the per-bee cost of the parts
## that scale badly drops by roughly seven eighths.
##
## Each bee's tick is offset by its own id, so they don't all think on
## the same frame and produce a spike. This is the single biggest thing
## standing between the current colony size and a much larger one.
const THINKS_PER_SECOND := 8.0
var think_timer: float = 0.0
## Real time since this bee last thought, so anything measured in
## seconds (the stall watchdog) counts wall time rather than ticks.
var since_last_think: float = 0.0
## True on the frames where the slow work is allowed to happen.
var thinking: bool = false

func _process(delta: float) -> void:
	Perf.begin("bees")
	if hive == null or is_dying:
		Perf.end("bees")
		return

	# Staggered by a random jitter so the colony's thinking is spread
	# across frames rather than landing on one.
	think_timer -= delta
	since_last_think += delta
	thinking = think_timer <= 0.0
	var think_delta: float = since_last_think
	if thinking:
		think_timer = (1.0 / THINKS_PER_SECOND) * randf_range(0.85, 1.15)
		since_last_think = 0.0

	Perf.begin("bee_burn")
	_age_and_burn(delta)
	Perf.end("bee_burn")
	if not is_inside_tree():
		Perf.end("bees")
		return   # died during ageing

	if thinking:
		Perf.begin("bee_think")
		_watch_for_stalls(think_delta)

		# A queued role change lands the moment the bee is free. Checked
		# here rather than only in the idle states because not every job
		# ends in one -- a forager that finishes a walk-to-point drops
		# straight into looking for a flower, and would otherwise never
		# pick the change up.
		if pending_role != -1 and not _is_busy():
			_apply_pending_role()

		# Eating is an errand now, not a number that quietly appears. A
		# bee that has run low breaks off whatever it was doing, walks to
		# a cell with food in it and feeds there. Checked before the
		# state machine so it can interrupt anything.
		if _should_go_and_eat():
			_begin_feeding_self()
		Perf.end("bee_think")

	# Runs every frame, not just on a think tick -- unlike the block
	# above, so this is where a per-state handler that does real search
	# or scan work (rather than just walking) would show up as costing
	# far more than THINKS_PER_SECOND would suggest.
	Perf.begin("bee_state")
	# Nested under a second, role-specific section so the breakdown can
	# answer "is it every bee, or one role" without needing a second
	# playtest -- both cover exactly the same code, so bee_state stays
	# the total and the per-role ones are how it's split.
	var role_section: String = ROLE_PERF_SECTIONS[role] if role >= 0 and role < ROLE_PERF_SECTIONS.size() else "bee_state"
	Perf.begin(role_section)
	match state:
		# --- forager, outdoors ---
		# Individually timed rather than lumped into bee_state_forager:
		# Dave's colony is 25/33 foragers cycling through here, and this
		# is where the plan's suspect list runs out -- bee_move and
		# bee_path both read 0ms, so whatever it is has to be one of
		# these specific branches rather than the moving between them.
		State.SEEK_FLOWER:
			Perf.begin("bee_seek_flower")
			_seek_flower()
			Perf.end("bee_seek_flower")
		State.TO_FLOWER:
			Perf.begin("bee_to_flower")
			if current_flower == null:
				state = State.SEEK_FLOWER
			else:
				_move_towards(current_flower.position, delta)
				if position.distance_to(current_flower.position) < arrive_distance:
					_start_inspecting()
			Perf.end("bee_to_flower")
		State.INSPECTING:
			Perf.begin("bee_inspecting")
			_inspect(delta)
			Perf.end("bee_inspecting")
		State.COLLECTING:
			Perf.begin("bee_collecting")
			_collect(delta)
			Perf.end("bee_collecting")
		State.DRINKING:
			_drink_at_flower(delta)
		State.TO_HIVE:
			Perf.begin("bee_to_hive")
			_move_towards(hive.position, delta)
			if position.distance_to(hive.position) < arrive_distance:
				_enter_hive()
			Perf.end("bee_to_hive")
		State.SHELTERING:
			_shelter(delta)

		# --- nursery, making royal jelly ---
		State.MAKING_JELLY:
			_nurse_make_jelly(delta)
		State.TO_JELLY_CELL:
			_nurse_go_to_jelly_cell(delta)
		State.DEPOSITING_JELLY:
			_nurse_deposit_jelly(delta)

		# --- forager, indoors ---
		State.IN_HIVE_TO_CELL:
			Perf.begin("bee_to_cell")
			_go_to_deposit_cell(delta)
			Perf.end("bee_to_cell")
		State.DEPOSITING:
			timer -= delta
			if timer <= 0.0:
				_finish_depositing()
		State.IN_HIVE_TO_EXIT:
			Perf.begin("bee_to_exit")
			_go_to_exit(delta)
			Perf.end("bee_to_exit")

		State.MOVE_TO_POINT:
			_move_towards(move_target, delta)
			if position.distance_to(move_target) < arrive_distance:
				state = _default_state_for_role()
		State.IDLING:
			pass   # waits for orders and nothing else

		# --- nursery ---
		State.NURSE_IDLE:
			_idle_dispatch()
		State.TO_BROOD:
			_nurse_go_to_brood(delta)
		State.TENDING:
			_nurse_tend(delta)
		State.TO_FOOD_CELL:
			_nurse_go_to_food(delta)
		State.LOADING_FOOD:
			_nurse_load_food(delta)

		# --- eating (any role) ---
		State.TO_FEED_CELL:
			_go_to_feed_cell(delta)
		State.FEEDING:
			_feed_self(delta)

		# --- builder ---
		State.BUILD_IDLE:
			_idle_dispatch()
		State.TO_BUILD_SITE:
			_builder_go_to_site(delta)
		State.BUILDING:
			_builder_build(delta)
		State.TO_RESTOCK_SOURCE:
			_restock_go_to_source(delta)
		State.TO_RESTOCK_TARGET:
			_restock_go_to_target(delta)
		State.TO_HAUL_SOURCE:
			_builder_go_to_haul_source(delta)
		State.TO_HAUL_TARGET:
			_builder_go_to_haul_target(delta)
		State.TO_WASTE_EXIT:
			_builder_go_to_waste_exit(delta)
		State.DUMPING_WASTE:
			_builder_dump_waste(delta)
		State.TO_CLEAN_CELL:
			_architect_go_to_clean(delta)
		State.CLEANING:
			_architect_clean(delta)

		# --- miner ---
		State.MINE_IDLE:
			_idle_dispatch()
		State.TO_MINE_SITE:
			_miner_go_to_site(delta)
		State.MINING:
			_miner_dig(delta)
		State.TO_MINE_EXIT:
			_miner_go_to_exit(delta)
		State.DUMPING_DIRT:
			_miner_dump(delta)

		# --- honey maker ---
		State.HONEY_IDLE:
			_idle_dispatch()
		State.TO_NECTAR_CELL:
			_honey_go_to_nectar(delta)
		State.CHEWING:
			_honey_chew(delta)
		State.TO_HONEY_CELL:
			_honey_go_to_pot(delta)
		State.DEPOSITING_HONEY:
			_honey_deposit(delta)
		State.FANNING:
			_honey_fan(delta)

		# --- egg layer ---
		State.SEEK_POLLEN:
			_queen_seek_pollen()
		State.TO_POLLEN_CELL:
			_queen_go_to_pollen(delta)
		State.EATING:
			_queen_eat(delta)
		State.TO_CELL_TO_LAY:
			_queen_go_to_lay(delta)
		State.LAYING:
			_queen_lay(delta)
	Perf.end(role_section)
	Perf.end("bee_state")

	Perf.begin("bee_label")
	_update_label()
	Perf.end("bee_label")
	Perf.end("bees")

# --- life support -------------------------------------------------

func _age_and_burn(delta: float) -> void:
	age_seconds += delta

	# A gyne is a bigger animal and costs more to run, whatever she's
	# doing -- part of why raising one is a real commitment.
	var upkeep: float = GameConfig.energy_burn_rate
	if is_gyne:
		upkeep *= GameConfig.gyne_energy_factor
	energy -= upkeep * delta

	# Flight is paid for separately from simply being alive, so a long
	# trip out to a distant patch actually costs something. Rain makes it
	# worse: a wet bee carries the water as dead weight.
	if _is_flying():
		var flight: float = GameConfig.flight_energy_burn
		if is_gyne:
			flight *= GameConfig.gyne_energy_factor
		flight *= lerpf(1.0, GameConfig.rain_flight_burn_factor, Session.rain_intensity)
		energy -= flight * delta

	# Building costs extra: bees make wax from the sugar they've eaten,
	# so expansion is paid for in energy rather than a wax stockpile.
	if state == State.BUILDING:
		energy -= GameConfig.build_energy_burn * delta

	_sip_from_crop(delta)

	# Death is checked here, at the end of the one function every bee runs
	# every frame.
	#
	# It used to sit at the bottom of _sip_from_crop, which returns early
	# for any bee that is indoors or not carrying nectar -- so in practice
	# only an outdoor nectar forager could ever die of starvation. Everyone
	# else burned straight past zero into the negative and stayed alive
	# there, and if such a bee later reached the comb it drank the debt
	# back out of the stores. That is the energy leak.
	if energy <= 0.0:
		energy = 0.0
		_die()
		return

	# The queen doesn't die of old age -- losing her would silently end
	# the colony, and there's no succession yet. She can still starve.
	if not is_queen and age_seconds >= _lifespan_seconds():
		_die()

## How long this bee lives. Shortened by disease, which is most of what
## makes pathogen pressure hurt: the colony doesn't visibly sicken, it
## just quietly stops replacing itself fast enough.
func _lifespan_seconds() -> float:
	var base: float = GameConfig.bee_lifespan_days * GameConfig.seconds_per_day
	if world != null and is_instance_valid(world) and world.season != null:
		base *= world.season.lifespan_factor()
	return max(GameConfig.seconds_per_day, base)

## Should a forager stay in? Rain and winter both stop trips, and having
## one function decide means a bee can never be caught out by one of them
## while checking only the other.
##
## Fixed 14 Aug 2026: this called itself here instead of checking rain,
## almost certainly lost in a refactor -- unconditional recursion until
## GDScript's call stack errors out, which is where the whole 4fps
## drop came from. `_seek_flower` and `_go_to_exit` both call this as
## their first line, which is exactly the two states the perf overlay
## named as the cost.
func _grounded() -> bool:
	if Session.rain_intensity > GameConfig.rain_forage_limit:
		return true
	if world != null and is_instance_valid(world) and world.season != null:
		return world.season.foraging_stopped()
	return false

## Out in the meadow and actually moving under its own power.
func _is_flying() -> bool:
	if _is_inside_hive():
		return false
	match state:
		State.SEEK_FLOWER, State.TO_FLOWER, State.TO_HIVE, State.MOVE_TO_POINT:
			return true
	return false

## A nectar forager doesn't have to land to refuel: it can metabolise
## what's already in its crop. That comes straight off the delivery,
## though, so a bee doing this often is one that's ranging too far for
## what the patch is paying.
func _sip_from_crop(delta: float) -> void:
	if _is_inside_hive() or current_load_type != "nectar" or current_load <= 0.0:
		return
	if energy > GameConfig.energy_capacity * GameConfig.crop_drink_threshold:
		return
	var wanted: float = min(GameConfig.nectar_drink_rate * delta, GameConfig.energy_capacity - energy)
	var taken: float = min(wanted, current_load)
	current_load -= taken
	energy += taken
	if current_load <= 0.001:
		current_load = 0.0
		current_load_type = ""

	# Bees used to top themselves up invisibly from wherever they stood,
	# which made a forager's deposit look far smaller than the load it
	# carried in -- it was quietly eating most of it straight back out of
	# the cell it had just filled. Eating is now a real trip to a real
	# cell; see _should_go_and_eat and _feed_self.

func _works_indoors() -> bool:
	return (
		role == Role.NURSERY
		or role == Role.BUILDER
		or role == Role.EGG_LAYER
		or role == Role.MINER
		or role == Role.HONEY_MAKER
	)

# --- eating -------------------------------------------------------

## True when this bee should break off and go and eat. Only inside the
## hive: there is nothing to eat out in the meadow, which is why a
## forager that keeps coming home empty still eventually starves.
func _should_go_and_eat() -> bool:
	if state == State.TO_FEED_CELL or state == State.FEEDING:
		return false
	# Don't break off partway through a short action where the bee is
	# holding something not yet committed anywhere -- a mouthful of
	# nectar being chewed into honey, or a load of brood food being
	# picked up. It would simply be lost.
	if state == State.CHEWING or state == State.LOADING_FOOD or state == State.MAKING_JELLY:
		return false
	if not _is_inside_hive():
		return false
	if energy > GameConfig.energy_capacity * GameConfig.hunger_threshold:
		return false
	return hive.find_food_cell() != null

func _begin_feeding_self() -> void:
	_release_cell_slot()
	target_cell = hive.find_food_cell()
	state = State.TO_FEED_CELL

func _go_to_feed_cell(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or not _is_edible(target_cell):
		target_cell = hive.find_food_cell()
		if target_cell == null:
			_after_feeding()
		return

	var approach := _approach_cell(target_cell, delta)
	if approach < 0:
		# all six walls in use -- eat somewhere else rather than queueing
		target_cell = hive.find_food_cell(target_cell)
		if target_cell == null:
			_after_feeding()
		return
	if approach == 1:
		state = State.FEEDING

func _is_edible(cell: Node2D) -> bool:
	if cell.amount <= 0.0:
		return false
	if cell.content_type == "nectar":
		return true
	return cell.is_ripe_honey()

## Feeding drains the cell gradually, so you can watch a bee empty it.
## Honey gives `honey_energy_factor` times the energy per unit, so a bee
## eating honey takes far less out of the comb for the same refill.
func _feed_self(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or not _is_edible(target_cell):
		target_cell = hive.find_food_cell()
		state = State.TO_FEED_CELL if target_cell != null else state
		if target_cell == null:
			_after_feeding()
		return

	var room: float = GameConfig.energy_capacity - energy
	if room <= 0.5:
		_after_feeding()
		return

	var per_unit: float = GameConfig.honey_energy_factor if target_cell.content_type == "honey" else 1.0
	var energy_wanted: float = min(GameConfig.bee_eat_rate * delta, room)
	var taken: float = target_cell.take_resource(target_cell.content_type, energy_wanted / per_unit)
	energy += taken * per_unit
	hive.announce()
	if taken <= 0.0:
		_after_feeding()

## Back to work. A forager still carrying a load finishes delivering it;
## one that has already unloaded heads back out; indoor bees pick their
## own job up again.
func _after_feeding() -> void:
	_release_cell_slot()
	target_cell = null
	if _works_indoors():
		# indoor roles pick their own job back up; sending one down the
		# forager's deposit path would have it filing away whatever it
		# was carrying for its own work
		state = _default_state_for_role()
	elif current_load > 0.0:
		state = State.IN_HIVE_TO_CELL
	else:
		state = State.IN_HIVE_TO_EXIT

# --- stall watchdog -----------------------------------------------

## A backstop, not the fix. Steering round obstacles is handled properly
## in _avoid_obstacles; this catches anything that still manages to pin a
## bee -- an unreachable flower, a corner it cannot steer out of -- and
## abandons the errand rather than leaving it hovering until the player
## notices and moves it by hand.
func _watch_for_stalls(delta: float) -> void:
	if _is_inside_hive() or _current_goal().x == INF:
		_reset_stall_watch()
		return

	# Measured as distance still to go rather than distance moved, so it
	# catches a bee shuffling back and forth between two obstacles as
	# well as one standing perfectly still. Either way it isn't getting
	# any closer, which is the thing that matters.
	var goal: Vector2 = _current_goal()
	if goal.x == INF:
		_reset_stall_watch()
		return
	var remaining: float = position.distance_to(goal)
	if stall_best_distance == INF or remaining < stall_best_distance - 2.0:
		stall_best_distance = remaining
		stall_timer = 0.0
		return

	stall_timer += delta
	if stall_timer < STALL_SECONDS:
		return
	_reset_stall_watch()

	# The guarantee the steering doesn't have to provide: a bee that isn't
	# getting closer to where it is going gets moved, so no geometry bug
	# can pin one indefinitely.
	#
	# If it was going round something, try the other way rather than
	# forgetting the obstacle entirely -- the usual reason a detour stops
	# paying is that it committed to the long way round a wall. Flipping
	# keeps the commitment (so it doesn't dither) but reverses it.
	if skirt_obstacle != null and is_instance_valid(skirt_obstacle):
		skirt_turn = -skirt_turn
	else:
		skirt_obstacle = null
	_escape_nearest_obstacle()

	if state == State.TO_FLOWER:
		_reject_flower()          # give up on this one and pick another
	elif state == State.MOVE_TO_POINT:
		state = _default_state_for_role()

## Pushes this bee clear of whatever solid thing it is closest to. A last
## resort, used only when the steering has demonstrably failed.
func _escape_nearest_obstacle() -> void:
	var nearest: Node2D = null
	var nearest_gap := INF
	for obstacle in _obstacles():
		if not is_instance_valid(obstacle) or not obstacle.solid:
			continue
		var gap: float = position.distance_to(obstacle.position) - obstacle.radius
		# Only things the bee is actually up against. Without this it
		# could pick a huge plateau on the far side of the meadow -- its
		# radius makes the gap small even at a distance -- and fling the
		# bee across the map to "escape" something it was nowhere near.
		if gap > ESCAPE_RANGE:
			continue
		if gap < nearest_gap:
			nearest_gap = gap
			nearest = obstacle

	if nearest == null:
		# Not caught on anything: the hold-up is elsewhere. A short hop is
		# enough to break any symmetry that might be causing it.
		position += Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0))
		return

	var outward: Vector2 = position - nearest.position
	if outward.length() < 0.01:
		outward = Vector2.RIGHT
	position = nearest.position + outward.normalized() * (nearest.radius + 40.0)

## Where the bee is currently trying to get to, in its own parent's
## coordinates. INF means "not travelling anywhere in particular".
func _current_goal() -> Vector2:
	match state:
		State.TO_FLOWER:
			return current_flower.position if (current_flower and is_instance_valid(current_flower)) else Vector2(INF, INF)
		State.TO_HIVE:
			return hive.position
		State.MOVE_TO_POINT:
			return move_target
	return Vector2(INF, INF)

func _reset_stall_watch() -> void:
	stall_best_distance = INF
	stall_timer = 0.0

func _die() -> void:
	if is_dying:
		return          # queue_free is deferred, so guard against a second pass
	is_dying = true
	if current_flower:
		current_flower.release(self)
	if target_cell and is_instance_valid(target_cell):
		target_cell.release_builder(self)
	if target_block and is_instance_valid(target_block):
		target_block.release_miner(self)
	_release_cell_slot()
	# A mark is left where it fell, so losses show up in the place they
	# happened rather than only as a number going down.
	if world != null and is_instance_valid(world):
		world.mark_death(self)
	queue_free()

# --- foraging -----------------------------------------------------

func _max_capacity() -> float:
	return nectar_stomach_capacity if resource_type == "nectar" else pollen_stomach_capacity

func _collection_rate() -> float:
	return nectar_collection_rate if resource_type == "nectar" else pollen_collection_rate

func _seek_flower() -> void:
	# Heavy rain: a trip costs more in wet-wing flight than the watered
	# down nectar brings back, so there is no point going out. Wait it out
	# at the hive instead.
	if _grounded():
		state = State.TO_HIVE
		return

	# First pass respects this bee's own memory of what it has drained,
	# and (if the marker option is on) other bees' scent marks too.
	var best := _nearest_flower(true)
	if best == null:
		# Nothing passes the filters. Rather than hovering over a spent
		# flower, relax the memory and take the best of what's left.
		best = _nearest_flower(false)

	if best == null:
		# Genuinely nothing to visit -- go home rather than sitting on an
		# empty flower, which looked like the bee was stuck.
		state = State.TO_HIVE
		return

	best.occupied_by = self
	current_flower = best
	state = State.TO_FLOWER

## `strict` applies the avoidance rules; without it only the hard
## constraints (occupied, empty) are checked.
## Searched through main.gd's spatial grid rather than by walking every
## flower in the meadow. This was a scan of 250 nodes per bee per
## decision; with the grid it looks at the handful in the buckets
## nearest the bee and widens only if it finds nothing.
##
## The fallback to a full scan matters: a bee whose preferred species has
## nothing in range should still find one eventually rather than deciding
## the meadow is empty and going home.
func _nearest_flower(strict: bool) -> Node2D:
	var accept := func(f) -> bool:
		if f.occupied_by != null:
			return false
		if f.get_available(resource_type) <= 0.0:
			return false
		if preferred_species != "" and f.species_name != preferred_species:
			return false
		if strict:
			if flower_cooldowns.has(f) and Session.sim_time < flower_cooldowns[f]:
				return false
			# Tarsal secretion: bees leave a scent mark on flowers they
			# land on, and other bees avoid a recently marked flower
			# rather than wasting a trip on one already stripped.
			if GameConfig.tarsal_markers_on and f.is_marked(self):
				return false
		return true

	var grid = _flower_grid()
	if grid != null:
		var found = grid.nearest(position, GameConfig.forage_search_radius, accept)
		if found != null:
			return found

	# Nothing close enough, or no grid yet. Fall back to the honest scan.
	var best: Node2D = null
	var best_dist := INF
	for f in get_tree().get_nodes_in_group("flowers"):
		if not is_instance_valid(f) or not accept.call(f):
			continue
		var d := position.distance_to(f.position)
		if d < best_dist:
			best_dist = d
			best = f
	return best

func _flower_grid():
	if world != null and is_instance_valid(world):
		return world.flower_grid
	return null

## Landing on a flower doesn't commit a bee to feeding from it. A short
## inspection comes first -- long enough to notice things like a fresh
## tarsal mark from another bee, or that it's nearly empty -- and only
## then does the bee decide whether to actually feed or move on. This
## also catches a flower that got marked by someone else mid-flight,
## after this bee had already committed to it.
const INSPECTION_TIME := 1.5
const REJECTED_AVOID_SECONDS := 15.0

func _start_inspecting() -> void:
	timer = INSPECTION_TIME
	state = State.INSPECTING

func _inspect(delta: float) -> void:
	if current_flower == null or not is_instance_valid(current_flower):
		current_flower = null
		state = State.SEEK_FLOWER
		return
	timer -= delta
	if timer > 0.0:
		return
	# Refuel before working. Every forager drinks nectar, whatever it came
	# for -- a pollen forager still needs the sugar, it just isn't what
	# it's carrying home.
	if _needs_a_drink() and current_flower.get_available("nectar") > GameConfig.min_worthwhile_amount:
		state = State.DRINKING
		return

	if _worth_feeding(current_flower):
		_start_collecting()
	else:
		_reject_flower()

func _needs_a_drink() -> bool:
	return energy < GameConfig.energy_capacity * GameConfig.forager_drink_threshold

## Drinking straight from the flower, into the bee rather than into its
## load. This is what gives a forager range: it doesn't have to fly home
## to eat, so how far it can work depends on what's flowering out there
## rather than on the distance back to the comb.
func _drink_at_flower(delta: float) -> void:
	if current_flower == null or not is_instance_valid(current_flower):
		current_flower = null
		state = State.SEEK_FLOWER
		return

	var room: float = GameConfig.energy_capacity - energy
	var wanted: float = min(GameConfig.nectar_drink_rate * delta, room)
	var drunk: float = current_flower.collect("nectar", wanted)
	# Rain waters the nectar down, so a wet flower gives back less than
	# the same volume would on a dry day.
	energy += drunk * _nectar_strength()

	if room <= 0.5 or drunk <= 0.0 or current_flower.get_available("nectar") < GameConfig.min_worthwhile_amount:
		# topped up (or the flower is dry) -- get on with the job
		if _worth_feeding(current_flower):
			_start_collecting()
		else:
			_reject_flower()

## How much a unit of nectar is actually worth right now. Rain dilutes
## what's standing in an open flower.
func _nectar_strength() -> float:
	return lerpf(1.0, 1.0 - GameConfig.rain_nectar_dilution, Session.rain_intensity)

## Rained off. Waiting it out *inside* the hive rather than at the door:
## a bee sheltering out in the meadow couldn't reach the comb to eat, and
## would have walked itself in and straight back out again every few
## seconds as the exit and the rain check argued with each other.
func _shelter(_delta: float) -> void:
	if not _grounded():
		state = State.IN_HIVE_TO_EXIT if _is_inside_hive() else State.SEEK_FLOWER

func _worth_feeding(f: Node2D) -> bool:
	if f.get_available(resource_type) < GameConfig.min_worthwhile_amount:
		return false
	if GameConfig.tarsal_markers_on and f.is_marked(self):
		return false
	return true

## Doesn't set a full recharge-length cooldown -- this bee didn't drain
## anything, so there's no reason to wait for a refill. A short "don't
## bother rechecking immediately" pause is enough.
func _reject_flower() -> void:
	if current_flower and is_instance_valid(current_flower):
		flower_cooldowns[current_flower] = Session.sim_time + REJECTED_AVOID_SECONDS
		current_flower.release(self)
	current_flower = null
	state = State.SEEK_FLOWER

func _start_collecting() -> void:
	current_flower.leave_marker(self)
	# `timer` now counts down the handling phase only -- finding the
	# nectary after landing. Gathering itself happens gradually, in
	# _collect(), so the flower's readout ticks down while you watch.
	timer = flower_handling_time
	state = State.COLLECTING

## Draws resource out of the flower a little each frame. Previously the
## whole load was removed in one lump when the timer expired, which made
## the flower's numbers look frozen until the bee left.
func _collect(delta: float) -> void:
	if current_flower == null or not is_instance_valid(current_flower):
		current_flower = null
		state = State.SEEK_FLOWER
		return

	if timer > 0.0:
		timer -= delta
		return   # still handling the flower, nothing gathered yet

	# A bee carries one resource at a time. If it still has a part-load of
	# something else after a focus change, it delivers that first rather
	# than mixing the two in its stomach.
	if current_load > 0.0 and current_load_type != "" and current_load_type != resource_type:
		_finish_collecting()
		state = State.TO_HIVE
		return

	var space_left: float = _max_capacity() - current_load
	if space_left <= 0.0:
		_finish_collecting()
		return

	# A drained flower still trickles back a little every frame as it
	# recharges. Waiting for the take to hit exactly zero therefore never
	# happened -- the bee sat there sipping the trickle forever. Instead
	# it leaves as soon as there isn't a worthwhile amount left.
	if current_flower.get_available(resource_type) < GameConfig.min_worthwhile_amount:
		_finish_collecting()
		return

	var wanted: float = min(_collection_rate() * delta, space_left)
	var taken: float = current_flower.collect(resource_type, wanted)
	# Nectar standing in an open flower is watered down by rain, so a wet
	# day's foraging brings home less than the same volume would dry.
	if resource_type == "nectar":
		taken *= _nectar_strength()
	current_load += taken
	if taken > 0.0:
		current_load_type = resource_type
		hive.record_collection(resource_type, taken)

	if current_load >= _max_capacity():
		_finish_collecting()

func _finish_collecting() -> void:
	if current_flower and is_instance_valid(current_flower):
		# stay away until it's had time to fully recharge
		flower_cooldowns[current_flower] = Session.sim_time + current_flower.seconds_until_full(resource_type)
		current_flower.release(self)
	current_flower = null
	state = State.TO_HIVE if current_load >= _max_capacity() else State.SEEK_FLOWER

# --- entering and leaving the hive --------------------------------

## Foragers now physically walk into the hive view to deposit, rather
## than vanishing at the meadow marker. main.gd owns the reparenting
## because it owns both world roots and the entrance geometry.
func _enter_hive() -> void:
	if world == null:
		# no world wired up (shouldn't happen) -- fall back to the old
		# behaviour so a bee never gets stuck at the door
		_deposit_everything_remotely()
		return
	world.move_bee_into_hive(self)
	target_cell = null
	# A bee that came home because its job is now indoors (see set_role)
	# starts that job at the door rather than running the forager's
	# deposit-and-leave sequence.
	state = _default_state_for_role() if _works_indoors() else State.IN_HIVE_TO_CELL

## Walks to one of the six wall positions on `cell`, claiming it first,
## so no more than six bees ever work the same cell at once and none of
## them stand on top of each other. Returns:
##    1  arrived and in position
##    0  still on the way
##   -1  every wall is taken -- the caller should look for another cell
func _approach_cell(cell: Node2D, delta: float) -> int:
	if cell == null or not is_instance_valid(cell):
		return -1
	if slot_cell != cell:
		_release_cell_slot()
		var index: int = cell.claim_slot(self)
		if index < 0:
			return -1
		cell_slot = index
		slot_cell = cell
	var stand_point: Vector2 = cell.slot_position(cell_slot)
	_move_towards(stand_point, delta)
	return 1 if position.distance_to(stand_point) < 6.0 else 0

func _release_cell_slot() -> void:
	if slot_cell != null and is_instance_valid(slot_cell):
		slot_cell.release_slot(self)
	slot_cell = null
	cell_slot = -1

func _go_to_deposit_cell(delta: float) -> void:
	if current_load <= 0.0:
		# Nothing to deliver. Eating is handled separately now -- the
		# hunger check in _process will already have sent this bee to a
		# food cell if it needed one, and it runs whether the trip home
		# was a productive one or not.
		state = State.IN_HIVE_TO_EXIT
		return

	if target_cell == null or not is_instance_valid(target_cell) or target_cell.space_for(current_load_type) <= 0.0:
		target_cell = hive.find_cell_for(current_load_type)
		if target_cell == null:
			# comb is full -- the load is lost, which is the signal that
			# the hive needs more cells built
			current_load = 0.0
			current_load_type = ""
			state = State.IN_HIVE_TO_EXIT
			return

	var approach := _approach_cell(target_cell, delta)
	if approach < 0:
		# all six walls busy -- try somewhere else rather than queueing
		target_cell = hive.find_cell_for(current_load_type, target_cell)
		return
	if approach == 1:
		timer = deposit_time
		state = State.DEPOSITING

func _finish_depositing() -> void:
	if target_cell and is_instance_valid(target_cell):
		var placed: float = target_cell.add_resource(current_load_type, current_load)
		current_load -= placed
		hive.announce()
	_release_cell_slot()
	target_cell = null

	# No refuelling here any more. A forager used to eat its fill the
	# instant it unloaded, taking most of the delivery straight back out
	# of the very cell it had just filled -- which is why a bee carrying
	# 50 nectar appeared to deposit a fraction of it. If it is hungry the
	# check in _process sends it to eat as a separate, visible trip.

	if current_load > 0.0:
		state = State.IN_HIVE_TO_CELL   # still carrying -- find another cell
		return

	current_load_type = ""
	# The load is delivered, so a queued role change takes effect now --
	# this is the "finish depositing first" case.
	if _apply_pending_role():
		return
	state = State.IN_HIVE_TO_EXIT

func _go_to_exit(delta: float) -> void:
	# No point walking out into weather that costs more to fly in than the
	# trip would bring back. Wait inside, where the food is.
	if role == Role.FORAGER and _grounded():
		state = State.SHELTERING
		return

	var exit_point: Vector2 = world.hive_entrance_inside() if world else position
	_move_towards(exit_point, delta)
	if position.distance_to(exit_point) < 8.0:
		if world:
			world.move_bee_out_of_hive(self)
		# A forager with a start point set heads there first, every trip,
		# rather than just once -- that's what keeps it working the same
		# patch instead of drifting back to whatever's nearest the door.
		if role == Role.FORAGER and forage_start_point.x != INF:
			move_target = forage_start_point
			state = State.MOVE_TO_POINT
		else:
			state = _default_state_for_role()

## Fallback only -- deposits without the walk-in animation.
func _deposit_everything_remotely() -> void:
	hive.deposit(current_load_type, current_load)
	current_load = 0.0
	current_load_type = ""
	energy += hive.take_energy(GameConfig.energy_capacity - energy)
	state = State.SEEK_FLOWER

# --- nursery work -------------------------------------------------

func _nurse_go_to_brood(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or target_cell.content_type != "brood":
		_release_cell_slot()
		state = State.NURSE_IDLE
		return
	var approach := _approach_cell(target_cell, delta)
	if approach < 0:
		target_cell = null
		state = State.NURSE_IDLE
		return
	if approach == 1:
		state = State.TENDING

func _nurse_tend(_delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or target_cell.content_type != "brood":
		_release_cell_slot()
		state = State.NURSE_IDLE
		return
	target_cell.being_tended = true   # cell reads this each frame to speed development

	if target_cell.needs_feeding():
		if _can_feed(target_cell):
			_feed_brood(target_cell)
			return
		# Out of one or both halves of the meal. Go and restock, but only
		# if there is actually something in the comb to fetch -- otherwise
		# stay put, since standing over the larva at least speeds up
		# whatever food it has left.
		if _restock_possible():
			_release_cell_slot()
			target_cell = null
			state = State.NURSE_IDLE
		return

	# This larva has food in it for now.
	#
	# A bee nursing as a backup job (the queen, unless you change it)
	# hands back and re-checks its real role. A dedicated nurse moves on
	# to whichever larva is hungriest if there is one -- otherwise a
	# single nurse would camp the first cell it found while every other
	# larva in the nest starved -- and only stays put when there is
	# nothing more urgent, since standing over brood speeds it up.
	if role != Role.NURSERY:
		_release_cell_slot()
		target_cell = null
		state = State.NURSE_IDLE
		return

	var other = hive.find_brood_cell()
	if other != null and other != target_cell and other.needs_feeding():
		_release_cell_slot()
		target_cell = other
		state = State.TO_BROOD

## Drops a meal into the cell. Larvae don't develop at all on their own
## any more (see HiveCell._develop_brood): each feed buys a fixed stretch
## of development and then it stalls until someone comes back.
##
## Pollen is the protein and is required either way. The carbohydrate is
## honey if the colony has any, because it's denser and lasts the larva
## longer -- which is the main reason a colony bothers making honey at
## all -- and nectar otherwise.
## How much carbohydrate one feed takes out of what the nurse is
## carrying. Honey goes further, which is the whole point of it.
func _carb_per_feed() -> float:
	return GameConfig.brood_feed_honey if nurse_carb_type == "honey" else GameConfig.brood_feed_nectar

## Can this nurse feed that particular larva right now, from what she is
## carrying? A gyne is fussier: royal jelly and honey specifically, where
## a worker larva will take nectar.
func _can_feed(cell: Node2D) -> bool:
	if nurse_pollen < GameConfig.brood_feed_pollen:
		return false
	if cell != null and is_instance_valid(cell) and cell.brood_is_gyne:
		if nurse_jelly < GameConfig.brood_feed_jelly:
			return false
		return nurse_carb_type == "honey" and nurse_carb >= GameConfig.brood_feed_honey
	return nurse_carb >= _carb_per_feed()

func _can_feed_brood() -> bool:
	return nurse_pollen >= GameConfig.brood_feed_pollen and nurse_carb >= _carb_per_feed()

## How many complete meals this nurse is carrying, for the info panel --
## whichever half runs out first is the limit.
func _feeds_carried() -> float:
	var from_pollen: float = nurse_pollen / max(0.001, GameConfig.brood_feed_pollen)
	var from_carb: float = nurse_carb / max(0.001, _carb_per_feed())
	return floor(min(from_pollen, from_carb))

## Could a trip to the stores actually improve what this nurse is
## carrying? Deliberately mirrors _nurse_restock_errand's conditions: if
## the two disagreed, a nurse short of pollen with none in the comb would
## bounce between the brood nest and her idle state every frame, being
## told to restock and finding nothing to restock with.
func _restock_possible() -> bool:
	if nurse_pollen < GameConfig.brood_feed_pollen and hive.find_cell_with("pollen") != null:
		return true
	if nurse_carb < _carb_per_feed():
		if hive.find_cell_with("honey") != null or hive.find_cell_with("nectar") != null:
			return true
	if nurse_jelly < GameConfig.brood_feed_jelly and hive.find_cell_with("jelly") != null:
		return true
	return false

## Feeds from what this nurse is physically carrying. She had to walk to
## a pollen cell and a nectar or honey cell to get it (see
## _nurse_restock_errand) -- food no longer appears in the larva out of
## the colony's totals with no bee going anywhere.
func _feed_brood(cell: Node2D) -> void:
	if not _can_feed(cell):
		return

	if cell.brood_is_gyne:
		# A gyne is raised on royal jelly. Nothing else will do, and it
		# has to come with honey rather than nectar.
		nurse_pollen -= GameConfig.brood_feed_pollen
		nurse_jelly -= GameConfig.brood_feed_jelly
		nurse_carb -= GameConfig.brood_feed_honey
		if nurse_carb <= 0.001:
			nurse_carb = 0.0
			nurse_carb_type = ""
		cell.feed_brood(GameConfig.brood_feed_seconds_gyne, true)
		return

	var on_honey: bool = nurse_carb_type == "honey"
	nurse_pollen -= GameConfig.brood_feed_pollen
	nurse_carb -= _carb_per_feed()
	if nurse_carb <= 0.001:
		nurse_carb = 0.0
		nurse_carb_type = ""
	cell.feed_brood(
		GameConfig.brood_feed_seconds_honey if on_honey else GameConfig.brood_feed_seconds,
		on_honey
	)

# --- royal jelly ---------------------------------------------------
## Only gyne larvae eat royal jelly, and only nurses set to make it
## produce any. A nurse eats pollen and honey and works them into jelly
## in her head glands, then either carries it straight to a gyne larva or
## stores it in a cell set aside for it.

func _can_make_jelly() -> bool:
	# no point making it if nothing needs it and there's nowhere to put it
	if not hive.has_gyne_brood() and hive.find_cell_for("jelly") == null:
		return false
	if hive.total("pollen") < GameConfig.jelly_pollen_cost:
		return false
	return hive.total_honey() >= GameConfig.jelly_honey_cost

## Standing still while her glands do the work. The pollen and honey are
## taken at the start, so a batch that is interrupted still costs.
func _nurse_make_jelly(delta: float) -> void:
	if timer == GameConfig.jelly_make_time:
		if not _can_make_jelly():
			state = State.NURSE_IDLE
			return
		hive.take("pollen", GameConfig.jelly_pollen_cost)
		hive.take("honey", GameConfig.jelly_honey_cost)
		hive.announce()

	timer -= delta
	if timer > 0.0:
		return
	nurse_jelly += GameConfig.jelly_per_batch
	state = State.NURSE_IDLE

func _nurse_go_to_jelly_cell(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or target_cell.space_for("jelly") <= 0.0:
		_release_cell_slot()
		target_cell = hive.find_cell_for("jelly")
		if target_cell == null:
			state = State.NURSE_IDLE
		return

	var approach := _approach_cell(target_cell, delta)
	if approach < 0:
		target_cell = hive.find_cell_for("jelly", target_cell)
		return
	if approach == 1:
		timer = GameConfig.nurse_load_time
		state = State.DEPOSITING_JELLY

func _nurse_deposit_jelly(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return
	if target_cell != null and is_instance_valid(target_cell):
		# She keeps one feed's worth on her, so she isn't storing jelly
		# and then immediately fetching it back out again.
		var keep: float = GameConfig.brood_feed_jelly if hive.has_gyne_brood() else 0.0
		var spare: float = max(0.0, nurse_jelly - keep)
		nurse_jelly -= target_cell.add_resource("jelly", spare)
		hive.announce()
	_release_cell_slot()
	target_cell = null
	state = State.NURSE_IDLE

## Sends this nurse off to load up if she is short of either half of a
## meal. Returns true when an errand was started. Honey is preferred over
## nectar because a honey feed carries a larva further.
func _nurse_restock_errand(for_gyne: bool = false) -> bool:
	if nurse_pollen < GameConfig.brood_feed_pollen:
		var pollen_cell = hive.find_cell_with("pollen")
		if pollen_cell != null:
			_start_food_errand(pollen_cell, "pollen")
			return true

	# A gyne larva takes honey and nothing else, so there's no falling
	# back on nectar for one.
	var carb_needed: float = GameConfig.brood_feed_honey if for_gyne else _carb_per_feed()
	var carb_short: bool = nurse_carb < carb_needed or (for_gyne and nurse_carb_type != "honey")
	if carb_short:
		var carb_type := "honey"
		var carb_cell = hive.find_cell_with("honey")
		if carb_cell == null and not for_gyne:
			carb_type = "nectar"
			carb_cell = hive.find_cell_with("nectar")
		if carb_cell != null:
			_start_food_errand(carb_cell, carb_type)
			return true

	if for_gyne and nurse_jelly < GameConfig.brood_feed_jelly:
		var jelly_cell = hive.find_cell_with("jelly")
		if jelly_cell != null:
			_start_food_errand(jelly_cell, "jelly")
			return true
		# nobody has made any -- make it here if this nurse is set to
		if nurse_mode != "feed" and _can_make_jelly():
			timer = GameConfig.jelly_make_time
			state = State.MAKING_JELLY
			return true

	return false

func _start_food_errand(cell: Node2D, what: String) -> void:
	_release_cell_slot()
	target_cell = cell
	nurse_fetching = what
	state = State.TO_FOOD_CELL

func _nurse_go_to_food(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or target_cell.content_type != nurse_fetching or target_cell.amount <= 0.0:
		_abandon_food_errand()
		return
	if nurse_fetching == "honey" and not target_cell.is_ripe_honey():
		_abandon_food_errand()
		return

	var approach := _approach_cell(target_cell, delta)
	if approach < 0:
		_abandon_food_errand()
		return
	if approach == 1:
		timer = GameConfig.nurse_load_time
		state = State.LOADING_FOOD

## Filling up. She takes several feeds' worth in one visit, so she isn't
## walking back to the stores for every single larva.
func _nurse_load_food(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return

	if target_cell != null and is_instance_valid(target_cell):
		var feeds: float = max(1.0, GameConfig.nurse_carry_feeds)
		if nurse_fetching == "pollen":
			nurse_pollen += target_cell.take_resource("pollen", GameConfig.brood_feed_pollen * feeds)
		elif nurse_fetching == "jelly":
			nurse_jelly += target_cell.take_resource("jelly", GameConfig.brood_feed_jelly * feeds)
		else:
			var per_feed: float = GameConfig.brood_feed_honey if nurse_fetching == "honey" else GameConfig.brood_feed_nectar
			var got: float = target_cell.take_resource(nurse_fetching, per_feed * feeds)
			if got > 0.0:
				# a nurse carries one kind of carbohydrate at a time
				if nurse_carb_type != nurse_fetching:
					nurse_carb = 0.0
				nurse_carb += got
				nurse_carb_type = nurse_fetching
		hive.announce()

	_abandon_food_errand()

func _abandon_food_errand() -> void:
	_release_cell_slot()
	target_cell = null
	nurse_fetching = ""
	state = State.NURSE_IDLE

# --- idle work dispatch --------------------------------------------

## Called every frame a bee is sitting in one of the three "waiting for
## work" states (NURSE_IDLE, BUILD_IDLE, MINE_IDLE -- interchangeable
## now, since this is the only thing any of them do). Tries the bee's
## real role first; only if that genuinely has nothing on offer does it
## try the secondary role instead. Because the fallback states above all
## route failures back to one of these same three idle states, a bee
## doing secondary work re-checks its primary role again the moment that
## task ends -- it never gets stuck permanently "being" its secondary.
## Idle states are exactly the moments a bee has finished something and
## has nothing in hand, so a queued role change is applied here. Foragers
## also apply theirs the moment they finish unloading, since standing in
## the hive holding nothing is not a state they pass through.
func _apply_pending_role() -> bool:
	if pending_role == -1:
		return false
	var wanted: int = pending_role
	pending_role = -1
	if wanted != role:
		_apply_role(wanted)
		return true
	return false

## Is this bee partway through something worth finishing? Everything
## except the "waiting for work" states and standing idle.
func _is_busy() -> bool:
	match state:
		State.IDLING, State.NURSE_IDLE, State.BUILD_IDLE, State.MINE_IDLE, State.HONEY_IDLE, State.SEEK_FLOWER:
			return false
	return true

func _idle_dispatch() -> void:
	if _apply_pending_role():
		return

	# The queen is the exception to "own role first". A hungry larva stops
	# developing altogether and can be lost, whereas a delayed egg costs
	# only time -- so she feeds the brood she already has before making
	# more. Any other bee, and a queen whose backup the player has
	# changed, still works its own role first.
	if is_queen and role == Role.EGG_LAYER and secondary_role != -1:
		if _try_role_work(secondary_role):
			return

	if _try_role_work(role):
		return
	if secondary_role != -1 and secondary_role != role:
		_try_role_work(secondary_role)

## Attempts to find and start one unit of work for role `r`. Returns
## true if it found something (and has already changed state), false if
## there was genuinely nothing to do.
func _try_role_work(r: int) -> bool:
	match r:
		Role.NURSERY:
			# Royal jelly first, for a nurse set to make it. It's the one
			# thing a gyne larva cannot do without, and only nurses on
			# this sub-mode produce any.
			if nurse_mode != "feed":
				if nurse_jelly > 0.0 and hive.find_cell_for("jelly") != null:
					state = State.TO_JELLY_CELL
					return true
				if _can_make_jelly():
					timer = GameConfig.jelly_make_time
					state = State.MAKING_JELLY
					return true
				if nurse_mode == "jelly":
					return false

			# The queen lays directly into a cell (see _queen_lay), so
			# there's never a loose egg on the floor to fetch -- a
			# nurse's job is feeding brood already in a cell.
			var brood = hive.find_brood_cell()
			if brood == null:
				return false
			# A bee nursing only as a backup (the queen, by default)
			# takes the job when a larva is actually waiting to be fed.
			# A dedicated nurse also stands over already-fed brood,
			# because that speeds up the time the larva has food for.
			# Without this distinction the queen would ping-pong
			# between the brood nest and her own idle state forever.
			if r != role and not brood.needs_feeding():
				return false
			# Load up before walking over. A nurse feeds from what she is
			# carrying, so an empty-handed one goes to the stores first.
			if brood.needs_feeding() and not _can_feed(brood):
				if _nurse_restock_errand(brood.brood_is_gyne):
					return true
			target_cell = brood
			state = State.TO_BROOD
			return true

		Role.BUILDER:
			# Comb workers do two kinds of work, and which of them this one
			# is willing to take depends on its mode.
			#
			# Maintenance, in priority order: clear dead larvae out of
			# cells (a body blocks the cell entirely, so this is urgent),
			# then shift stores out of cells the player has re-designated
			# or asked to be emptied.
			if architect_mode != "build":
				var dead = hive.find_cell_needing_cleaning()
				if dead:
					target_cell = dead
					state = State.TO_CLEAN_CELL
					return true

				var source = hive.find_cell_needing_eviction()
				if source:
					target_cell = source
					state = State.TO_HAUL_SOURCE
					return true

			# Keeping chosen cells topped up. Ranked with maintenance
			# rather than building, because it's the same kind of job --
			# moving what the colony already has to where it's wanted --
			# and because a half-built cell can wait while the winter
			# store runs dry.
			if architect_mode == "restock" or architect_mode == "both":
				if _find_restock_job():
					return true

			if architect_mode == "maintain" or architect_mode == "restock":
				return false

			var site: Node2D = null
			# The player's own order comes first, worked front to back.
			# Entries that have become unbuildable are skipped inside
			# _take_next_build_target rather than stalling the queue.
			while site == null and _take_next_build_target():
				site = hive.create_cell_site_at(manual_build_hex)
				has_manual_build_target = false
			if site == null:
				site = hive.find_unfinished_cell()
			if site == null:
				# grows outward from this comb worker's own home cell if it
				# has been given one, otherwise from the middle of the comb
				site = hive.create_next_cell_site(home_hex if has_home_hex else Vector2i.ZERO)
			if site:
				target_cell = site
				state = State.TO_BUILD_SITE
				return true
			return false

		Role.MINER:
			# Blocks the player marked always come first, automine or
			# not -- an explicit instruction outranks the automatic
			# choice, so switching automine on doesn't make a miner
			# ignore the blocks you flagged. Only once every marked
			# block is dealt with does an automining bee pick its own:
			# the exposed block nearest the central wax cell, so the
			# hive opens up around itself rather than at the rim.
			# This miner's own order first, in the order it was given.
			var block = _next_queued_block()
			if block != null and hive.mine_stand_hex(block) == null:
				block = null   # still buried; take another job meanwhile
			if block == null:
				block = hive.find_marked_block(_mine_reference_point())
			if block == null and automine:
				block = hive.find_nearest_edge_block(_mine_reference_point() if has_mine_home else Vector2(INF, INF))
				if block != null:
					block.set_marked(true)
			if block != null:
				target_block = block
				state = State.TO_MINE_SITE
				return true
			return false

		Role.HONEY_MAKER:
			# Still holding mix from a previous trip -- put that down
			# before doing anything else, or fetching a fresh load of
			# nectar would overwrite it and the work would be lost.
			if honey_load > 0.0:
				var pot = hive.find_honey_target()
				if pot != null:
					target_cell = pot
					state = State.TO_HONEY_CELL
					return true
				return false

			# Drying cells already spat into come next: wet mix isn't
			# a store until the water is fanned off it, so leaving it
			# to fetch more nectar just piles up unusable cells.
			var drying = hive.find_cell_needing_fanning()
			if drying != null:
				fan_target = drying
				state = State.FANNING
				return true
			var nectar_cell = hive.find_cell_with("nectar")
			if nectar_cell != null and hive.find_honey_target() != null:
				target_cell = nectar_cell
				state = State.TO_NECTAR_CELL
				return true
			return false

		Role.EGG_LAYER:
			# Only the queen ever has this role. She goes back to laying
			# the moment there's both pollen to eat and somewhere to put
			# an egg; the rest of the time her backup role (nursing, by
			# default) picks up the slack.
			if not is_queen:
				return false
			if hive.has_room_for_egg() and hive.find_cell_with("pollen") != null:
				state = State.SEEK_POLLEN
				return true
			return false

		Role.FORAGER:
			# No cheap way to know in advance whether a flower's worth
			# visiting -- _seek_flower already handles "nothing out
			# there" gracefully by heading home, so just hand off to it.
			state = State.SEEK_FLOWER
			return true

		_:
			return false

# --- building -----------------------------------------------------

func _builder_go_to_site(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or target_cell.is_built:
		target_cell = null
		state = State.BUILD_IDLE
		return
	_move_towards(target_cell.position, delta)
	if position.distance_to(target_cell.position) < 12.0:
		target_cell.claim_builder(self)
		state = State.BUILDING

## Each builder contributes its own `delta` to the cell every frame, so
## two builders on one cell finish it in half the wall-clock time. The
## cell keeps its progress if everyone wanders off, so building can be
## abandoned and picked up again later.
func _builder_build(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell):
		state = State.BUILD_IDLE
		return
	target_cell.add_build_progress(delta)
	if target_cell.is_built:
		target_cell.release_builder(self)
		target_cell = null
		state = State.BUILD_IDLE

func _builder_go_to_haul_source(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or not target_cell.needs_eviction():
		target_cell = null
		state = State.BUILD_IDLE
		return
	_move_towards(target_cell.position, delta)
	if position.distance_to(target_cell.position) < 10.0:
		var moving_type: String = target_cell.content_type
		var lifted: float = target_cell.take_resource(moving_type, nectar_stomach_capacity)
		if lifted <= 0.0:
			target_cell = null
			state = State.BUILD_IDLE
			return
		current_load = lifted
		current_load_type = moving_type
		hive.announce()

		# The player asked for this cell's contents to be thrown out, so
		# the builder carries them out through the entrance and dumps
		# them. Discarding used to happen the instant the button was
		# pressed, with the resource simply vanishing and no bee doing
		# any of the work.
		if target_cell.evict_mode == "discard":
			_release_cell_slot()
			state = State.TO_WASTE_EXIT
			return

		haul_target = hive.find_cell_for(moving_type, target_cell)
		if haul_target == null:
			# nowhere to put it -- it has to go outside after all, which
			# is what the player was warned about when they asked for the
			# cell to be emptied
			_release_cell_slot()
			state = State.TO_WASTE_EXIT
			return
		state = State.TO_HAUL_TARGET

# --- keeping cells topped up ---------------------------------------
## A comb worker on the restock sub-mode has a list of cells it keeps full
## of one resource, drawing on the rest of the comb to do it.
##
## The point of it is placement. The colony's stores end up wherever the
## foragers happened to put them, which is fine until something needs to
## be *somewhere* -- honey next to the brood before winter, pollen within
## reach of the nursery, a reserve by the entrance. Rather than adding a
## new kind of bee, this is a job a comb worker can be given: it is already
## the caste that moves things between cells.
##
## The source list is what stops it undoing your own arrangements. With
## nothing chosen it takes from anywhere; name some cells and it takes
## only from those; block some and it leaves them alone. That is what
## lets you say "fill these from the outer comb, but never touch the
## winter store".

## Cells this comb worker keeps full, and of what.
var restock_targets: Array = []
var restock_resource: String = ""
## Cells it may draw on. Empty means anywhere that isn't blocked.
var restock_sources: Array = []
var restock_blocked: Array = []

func set_restock_targets(cells: Array, resource: String) -> void:
	restock_targets = cells.duplicate()
	restock_resource = resource

func set_restock_sources(cells: Array, allowed: bool) -> void:
	if allowed:
		restock_sources = cells.duplicate()
	else:
		restock_blocked = cells.duplicate()

func clear_restock() -> void:
	restock_targets.clear()
	restock_sources.clear()
	restock_blocked.clear()
	restock_resource = ""

func has_restock_orders() -> bool:
	return not restock_targets.is_empty() and restock_resource != ""

## May this comb worker take `cell`'s contents to fill one of its targets?
func _may_draw_from(cell: Node2D) -> bool:
	if not is_instance_valid(cell) or restock_targets.has(cell):
		return false          # never rob one target to fill another
	if not cell.can_withdraw():
		return false          # sealed
	if restock_blocked.has(cell):
		return false
	if restock_sources.is_empty():
		return true
	return restock_sources.has(cell)

## Finds the emptiest target that still has room and a cell to fill it
## from. Emptiest first, so a set of cells fills evenly rather than one
## being topped up repeatedly while another sits empty.
func _find_restock_job() -> bool:
	if not has_restock_orders() or hive == null:
		return false

	var neediest: Node2D = null
	var least: float = INF
	for cell in restock_targets:
		if not is_instance_valid(cell) or cell.space_for(restock_resource) <= 0.0:
			continue
		var held: float = cell.amount if cell.content_type == restock_resource else 0.0
		if held < least:
			least = held
			neediest = cell
	if neediest == null:
		return false

	var source: Node2D = null
	var most := 0.0
	var bucket: String = "ripe_honey" if restock_resource == "honey" else restock_resource
	for cell in hive.cells_holding(bucket):
		if not _may_draw_from(cell) or cell.amount <= 0.0:
			continue
		# fullest first: emptying one cell completely beats leaving a
		# trail of nearly empty ones behind
		if cell.amount > most:
			most = cell.amount
			source = cell
	if source == null:
		return false

	target_cell = source
	haul_target = neediest
	state = State.TO_RESTOCK_SOURCE
	return true

func _restock_go_to_source(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or target_cell.content_type != restock_resource:
		target_cell = null
		state = State.BUILD_IDLE
		return
	if haul_target == null or not is_instance_valid(haul_target):
		target_cell = null
		state = State.BUILD_IDLE
		return

	var approach := _approach_cell(target_cell, delta)
	if approach < 0:
		target_cell = null
		state = State.BUILD_IDLE
		return
	if approach != 1:
		return

	# Never lift more than the destination can hold, so nothing is left
	# stranded in the bee's crop with nowhere to put it.
	var room: float = haul_target.space_for(restock_resource)
	var wanted: float = min(nectar_stomach_capacity, room)
	var lifted: float = target_cell.take_resource(restock_resource, wanted)
	_release_cell_slot()
	if lifted <= 0.0:
		target_cell = null
		state = State.BUILD_IDLE
		return
	current_load = lifted
	current_load_type = restock_resource
	hive.announce()
	target_cell = null
	state = State.TO_RESTOCK_TARGET

func _restock_go_to_target(delta: float) -> void:
	if haul_target == null or not is_instance_valid(haul_target):
		# The destination has gone. Put the load somewhere sensible
		# rather than losing it.
		haul_target = hive.find_cell_for(current_load_type)
		if haul_target == null:
			current_load = 0.0
			current_load_type = ""
			state = State.BUILD_IDLE
			return

	var approach := _approach_cell(haul_target, delta)
	if approach < 0:
		haul_target = null
		state = State.BUILD_IDLE
		return
	if approach != 1:
		return

	var placed: float = haul_target.add_resource(current_load_type, current_load)
	current_load -= placed
	hive.announce()
	_release_cell_slot()
	haul_target = null
	if current_load <= 0.001:
		current_load = 0.0
		current_load_type = ""
	state = State.BUILD_IDLE

func _builder_go_to_haul_target(delta: float) -> void:
	if haul_target == null or not is_instance_valid(haul_target):
		haul_target = hive.find_cell_for(current_load_type)
		if haul_target == null:
			current_load = 0.0
			current_load_type = ""
			state = State.BUILD_IDLE
			return
	_move_towards(haul_target.position, delta)
	if position.distance_to(haul_target.position) < 10.0:
		var placed: float = haul_target.add_resource(current_load_type, current_load)
		current_load -= placed
		hive.announce()
		haul_target = null
		if current_load <= 0.0:
			current_load_type = ""
			target_cell = null
			state = State.BUILD_IDLE

## Clearing a dead larva. The body blocks the cell completely -- nothing
## can be stored there and no egg can be laid in it -- so this is the
## first thing a comb worker on maintenance picks up.
func _architect_go_to_clean(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or not target_cell.needs_cleaning():
		_release_cell_slot()
		target_cell = null
		state = State.BUILD_IDLE
		return

	var approach := _approach_cell(target_cell, delta)
	if approach < 0:
		target_cell = null
		state = State.BUILD_IDLE
		return
	if approach == 1:
		state = State.CLEANING

func _architect_clean(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or not target_cell.needs_cleaning():
		_release_cell_slot()
		target_cell = null
		state = State.BUILD_IDLE
		return

	if target_cell.add_clean_progress(delta):
		target_cell.clear_cell()
		hive.announce()
		_release_cell_slot()
		target_cell = null
		# the body goes out of the hive rather than back into the comb
		carrying_corpse = true
		state = State.TO_WASTE_EXIT

## Carrying unwanted stores out of the hive to throw away. Same shape as
## a miner hauling spoil: walk to the entrance, step outside, spend a
## moment dumping, then come back in and pick up the next job.
func _builder_go_to_waste_exit(delta: float) -> void:
	var exit_point: Vector2 = world.hive_entrance_inside() if world else position
	_move_towards(exit_point, delta)
	if position.distance_to(exit_point) < 8.0:
		if world:
			world.move_bee_out_of_hive(self)
		timer = GameConfig.dirt_dump_time
		state = State.DUMPING_WASTE

func _builder_dump_waste(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return
	current_load = 0.0
	current_load_type = ""
	carrying_corpse = false
	if world:
		world.move_bee_into_hive(self)
	target_cell = null
	state = State.BUILD_IDLE

# --- mining -------------------------------------------------------

## Miners used to be walked at the block's own centre. Soil is solid, so
## routing found no path to it at all and _move_towards's "no safe route,
## stay put" branch left the bee standing still forever -- which is why
## marked blocks never got dug. It now walks to the open tile beside the
## block instead, which is a real destination the router can reach.
func _miner_go_to_site(delta: float) -> void:
	if target_block == null or not is_instance_valid(target_block) or not target_block.marked_for_mining:
		target_block = null
		state = State.MINE_IDLE
		return

	var stand_point: Vector2 = hive.mine_stand_point(target_block, position)
	if stand_point.x == INF:
		# nothing open touches this block, so nobody can reach it -- drop
		# it and let the idle dispatch find another job
		target_block = null
		state = State.MINE_IDLE
		return

	_move_towards(stand_point, delta)
	if position.distance_to(stand_point) < 8.0:
		target_block.claim_miner(self)
		state = State.MINING

func _miner_dig(delta: float) -> void:
	if target_block == null or not is_instance_valid(target_block) or not target_block.marked_for_mining:
		target_block = null
		state = State.MINE_IDLE
		return
	energy -= GameConfig.build_energy_burn * delta   # digging is hard work

	dirt_load += GameConfig.dirt_fill_rate * delta
	if dirt_load >= GameConfig.miner_dirt_capacity:
		# full up -- down tools and carry it outside. The block keeps
		# whatever progress it has, same as an abandoned build site, so
		# picking this bee (or another miner) up again just resumes it.
		target_block.release_miner(self)
		state = State.TO_MINE_EXIT
		return

	if target_block.add_mine_progress(delta):
		target_block.release_miner(self)
		if world:
			world.finish_mining(target_block)
		target_block = null
		state = State.MINE_IDLE

func _miner_go_to_exit(delta: float) -> void:
	var exit_point: Vector2 = world.hive_entrance_inside() if world else position
	_move_towards(exit_point, delta)
	if position.distance_to(exit_point) < 8.0:
		if world:
			world.move_bee_out_of_hive(self)
		timer = GameConfig.dirt_dump_time
		state = State.DUMPING_DIRT

func _miner_dump(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		dirt_load = 0.0
		if world:
			world.move_bee_into_hive(self)
		# target_block is still marked, still holding its progress -- go
		# straight back to it rather than re-rolling automine's choice
		state = State.TO_MINE_SITE if (target_block and is_instance_valid(target_block) and target_block.marked_for_mining) else State.MINE_IDLE

# --- honey making -------------------------------------------------
## Nectar is mostly water and ferments; honey keeps, and packs several
## times the energy into the same cell. A honey maker takes nectar back
## out of the comb, chews enzymes into it, spits the mix into a cell of
## its own, and then fans its wings over that cell until the water has
## evaporated off. Only then is it honey the colony can eat.

func _honey_go_to_nectar(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or target_cell.content_type != "nectar":
		_release_cell_slot()
		target_cell = null
		state = State.HONEY_IDLE
		return

	var approach := _approach_cell(target_cell, delta)
	if approach < 0:
		target_cell = null
		state = State.HONEY_IDLE
		return
	if approach < 1:
		return

	var wanted: float = nectar_stomach_capacity
	var lifted: float = target_cell.take_resource("nectar", wanted)
	_release_cell_slot()
	target_cell = null
	hive.announce()
	if lifted <= 0.0:
		state = State.HONEY_IDLE
		return
	current_load = lifted
	current_load_type = "nectar"
	timer = GameConfig.honey_chew_time
	state = State.CHEWING

## Standing still working the nectar over in its crop, adding the
## enzymes that break the sugars down. `nectar_per_honey` is where the
## concentration happens: several units of thin nectar become one of mix.
func _honey_chew(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return
	honey_load = current_load / max(0.1, GameConfig.nectar_per_honey)
	current_load = 0.0
	current_load_type = ""
	target_cell = hive.find_honey_target()
	if target_cell == null:
		# nowhere to put it -- hold onto it and wait for a cell to free up
		state = State.HONEY_IDLE
		return
	state = State.TO_HONEY_CELL

func _honey_go_to_pot(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or target_cell.space_for("honey") <= 0.0:
		_release_cell_slot()
		target_cell = hive.find_honey_target()
		if target_cell == null:
			state = State.HONEY_IDLE
		return

	var approach := _approach_cell(target_cell, delta)
	if approach < 0:
		target_cell = hive.find_cell_for("honey", target_cell)
		return
	if approach == 1:
		timer = deposit_time
		state = State.DEPOSITING_HONEY

func _honey_deposit(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return
	if target_cell != null and is_instance_valid(target_cell):
		honey_load -= target_cell.add_resource("honey", honey_load)
		hive.announce()
		fan_target = target_cell
	_release_cell_slot()
	target_cell = null
	if honey_load > 0.001:
		state = State.HONEY_IDLE   # still carrying -- find another pot
	else:
		honey_load = 0.0
		state = State.FANNING if fan_target != null else State.HONEY_IDLE

## Beating its wings over the open cell to drive a breeze across it. Each
## fanning bee contributes its own frame time, so several working the
## same cell dry it out proportionally faster.
func _honey_fan(delta: float) -> void:
	if fan_target == null or not is_instance_valid(fan_target) or not fan_target.needs_fanning():
		_release_cell_slot()
		fan_target = null
		state = State.HONEY_IDLE
		return

	var approach := _approach_cell(fan_target, delta)
	if approach < 0:
		fan_target = null
		state = State.HONEY_IDLE
		return
	if approach == 1:
		fan_target.being_fanned = true   # cell reads this each frame

# --- egg laying (queen only) --------------------------------------

## A gyne egg is a far bigger investment than a worker one, so the queen
## has to eat considerably more before she can lay it. She looks at what
## the colony has actually asked for: if any free cell is set aside to
## raise a gyne, that's the next egg.
func _pollen_needed_for_next_egg() -> float:
	var next = hive.find_empty_cell()
	if next != null and is_instance_valid(next) and next.hatch_gyne:
		return GameConfig.gyne_egg_pollen_cost
	return GameConfig.egg_pollen_cost

func _queen_seek_pollen() -> void:
	# Nothing to lay into, or nothing to eat: rather than hovering doing
	# nothing, hand over to the idle dispatch, which re-checks laying
	# first and otherwise puts her on her backup role (nursing, unless
	# the player has changed it). She picks laying straight back up the
	# moment a cell frees up -- see _try_role_work's EGG_LAYER case.
	if not hive.has_room_for_egg():
		state = State.NURSE_IDLE
		return
	target_cell = hive.find_cell_with("pollen")
	if target_cell:
		state = State.TO_POLLEN_CELL
	else:
		state = State.NURSE_IDLE

func _queen_go_to_pollen(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or target_cell.content_type != "pollen":
		_release_cell_slot()
		state = State.SEEK_POLLEN
		return
	var approach := _approach_cell(target_cell, delta)
	if approach < 0:
		target_cell = null
		state = State.SEEK_POLLEN
		return
	if approach == 1:
		state = State.EATING

func _queen_eat(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or target_cell.content_type != "pollen":
		state = State.SEEK_POLLEN
		return
	pollen_eaten += target_cell.take_resource("pollen", GameConfig.queen_eat_rate * delta)
	hive.announce()
	if pollen_eaten >= _pollen_needed_for_next_egg():
		# walk to a free cell and lay into it directly. She no longer
		# drops eggs on the floor for a nurse to pick up -- that's what
		# left white eggs scattered around the hive.
		_release_cell_slot()
		target_cell = hive.find_empty_cell()
		if target_cell == null:
			return   # nowhere to lay; wait until a cell frees up
		state = State.TO_CELL_TO_LAY

func _queen_go_to_lay(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or not target_cell.is_empty():
		_release_cell_slot()
		target_cell = hive.find_empty_cell()
		if target_cell == null:
			state = State.SEEK_POLLEN
			return
	var approach := _approach_cell(target_cell, delta)
	if approach < 0:
		target_cell = null
		state = State.SEEK_POLLEN
		return
	if approach == 1:
		timer = 1.5
		state = State.LAYING

func _queen_lay(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		if target_cell != null and is_instance_valid(target_cell) and target_cell.is_empty():
			var as_gyne: bool = target_cell.hatch_gyne
			target_cell.start_brood(as_gyne)
			# Only now does the priority share-out move on. Everything up to
			# this point was the queen asking where she *could* lay.
			hive.record_lay(target_cell)
			pollen_eaten -= GameConfig.gyne_egg_pollen_cost if as_gyne else GameConfig.egg_pollen_cost
			pollen_eaten = max(0.0, pollen_eaten)
		_release_cell_slot()
		target_cell = null
		# back through the dispatch, so the brood gets looked at before
		# she starts on the next egg
		state = State.NURSE_IDLE

# --- player commands ----------------------------------------------

## `world_point` is a true global (screen-space-derived) position. Bee
## movement always works in local-to-parent coordinates -- `position` is
## a Node2D's local offset, not a global one -- so this converts once,
## here, rather than leaving every caller to remember to. Getting this
## wrong is exactly what sent bees drifting off to one side inside the
## hive: a global point was being compared directly against a local
## position, which only matches by coincidence in the meadow (where
## meadow_root sits at the origin).
func command_move_to(world_point: Vector2) -> void:
	var parent := get_parent()
	var target: Vector2 = parent.to_local(world_point) if parent else world_point
	# Inside the hive, a click can land on solid soil -- snap it to the
	# nearest open tile rather than sending the bee at a point it can
	# only reach by cutting straight through the wall.
	if _is_inside_hive() and hive and hive.has_method("nearest_walkable_point"):
		target = hive.nearest_walkable_point(target)
	else:
		# Out in the meadow the equivalent hazard is a click on a tree or
		# a raised area. The bee can't stand there, so it would creep up
		# to the boundary and never register as having arrived. Nudging
		# the destination out to the edge means it completes the order.
		target = _block_obstacles(target)
	move_target = target
	_release_everything()
	state = State.MOVE_TO_POINT

## `meadow_point` is global/meadow-space (meadow_root sits at the origin,
## so global and local-to-meadow coincide -- see the note on
## command_move_to for why that distinction matters elsewhere).
func set_forage_start_point(meadow_point: Vector2) -> void:
	forage_start_point = meadow_point

func has_forage_start_point() -> bool:
	return forage_start_point.x != INF

func set_preferred_species(species: String) -> void:
	preferred_species = species
	flower_cooldowns.clear()   # a change of preference is worth a fresh look

## `hex` is an axial coordinate relative to the comb centre, matching
## what hive.gd already uses for cells and soil blocks.
##
## Replaces whatever was queued. Ctrl-clicking uses queue_build_target
## instead, which adds to the end.
func set_manual_build_target(hex: Vector2i) -> void:
	build_queue = [hex]
	manual_build_hex = hex
	has_manual_build_target = true

## Adds a tile to the end of this comb worker's build order. The queue is
## worked front to back, so the order you click is the order the comb
## gets drawn -- which matters when you're extending towards something.
func queue_build_target(hex: Vector2i) -> void:
	if build_queue.has(hex):
		return
	build_queue.append(hex)
	manual_build_hex = build_queue[0]
	has_manual_build_target = true

func clear_build_queue() -> void:
	build_queue.clear()
	has_manual_build_target = false

## Takes the next tile off the front of the queue, or returns false when
## there is nothing queued.
func _take_next_build_target() -> bool:
	while not build_queue.is_empty():
		var hex: Vector2i = build_queue.pop_front()
		if hive != null and hive.can_build_on(hex):
			manual_build_hex = hex
			has_manual_build_target = true
			return true
		# tile has been filled or dug away since it was queued -- skip it
		# rather than stalling the whole order on one stale entry
	has_manual_build_target = false
	return false

## Same idea for miners: an ordered list of blocks this bee will dig.
func set_mine_target(block: Node2D) -> void:
	mine_queue = [block] if is_instance_valid(block) else []
	if is_instance_valid(block):
		block.set_marked(true)

func queue_mine_target(block: Node2D) -> void:
	if not is_instance_valid(block) or mine_queue.has(block):
		return
	mine_queue.append(block)
	block.set_marked(true)

func clear_mine_queue() -> void:
	mine_queue.clear()

## The next block this miner should dig from its own order, skipping any
## that have been dug out or unmarked since.
func _next_queued_block() -> Node2D:
	while not mine_queue.is_empty():
		var block = mine_queue[0]
		if is_instance_valid(block) and block.marked_for_mining:
			return block
		mine_queue.pop_front()
	return null

func set_home_hex(hex: Vector2i) -> void:
	home_hex = hex
	has_home_hex = true

## A miner's own centre of operations. It picks the soil nearest to this
## rather than nearest to itself, so a seam gets worked through from one
## end instead of the miner drifting to whatever happens to be closest
## after each block. Two miners with different home cells open the hive
## up in two places at once.
func set_mine_home_hex(hex: Vector2i) -> void:
	mine_home_hex = hex
	has_mine_home = true

## Where the miner should judge distance from: its home cell if it has
## one, otherwise wherever it is standing.
func _mine_reference_point() -> Vector2:
	if has_mine_home and hive != null:
		return hive.comb_centre + Shapes.hex_to_pixel(mine_home_hex.x, mine_home_hex.y, GameConfig.hive_cell_spacing)
	return position

## Sent to a specific flower by right-click: ignore the cooldown list
## for this one trip and go straight there.
func command_collect_from(flower: Node2D) -> void:
	if role != Role.FORAGER:
		return
	if flower.occupied_by != null and flower.occupied_by != self:
		return
	if current_flower and current_flower != flower:
		current_flower.release(self)
	flower_cooldowns.erase(flower)
	flower.occupied_by = self
	current_flower = flower
	state = State.TO_FLOWER

func set_focus(type: String) -> void:
	if type == resource_type or role != Role.FORAGER:
		return
	resource_type = type
	flower_cooldowns.clear()
	if current_flower:
		current_flower.release(self)
		current_flower = null

	# A bee mid-errand inside the hive (carrying to a cell, depositing,
	# walking out) is still physically parented under hive_root. Forcing
	# it into SEEK_FLOWER here would send it hunting for a flower whose
	# position is in meadow coordinates while the bee itself is reading
	# that as a local-to-hive offset -- it ends up drifting to a fixed,
	# meaningless spot in the hive. Instead, let it finish walking out
	# normally; _go_to_exit already calls _default_state_for_role() once
	# it's back in the meadow, which will pick up the new resource type.
	if not _is_inside_hive():
		# Already out foraging -- no need to fly home first.
		state = State.SEEK_FLOWER
	_update_label()

## `new_role` of -1 clears it. A bee can't take itself as its own
## backup, and only Miner, Nursery and Builder ever actually check
## theirs (see _idle_dispatch) -- the hud only offers the control for
## bees currently doing one of those.
func set_secondary_role(new_role: int) -> void:
	secondary_role = -1 if new_role == role else new_role

func can_take_role(new_role: int) -> bool:
	return is_queen if new_role == Role.EGG_LAYER else true

## Changing a bee's job used to reparent it between the meadow and the
## hive on the spot. That teleported it: assign the queen to forage and
## she vanished from the hive floor and reappeared at the meadow marker,
## or the reverse. She now travels there like any other bee -- if she's
## outside she flies home and walks in through the entrance; if she's
## inside she walks out through it. The role changes immediately; only
## the journey takes time.
func set_role(new_role: int) -> void:
	if new_role == role or not can_take_role(new_role):
		return

	# With "finish current task" ticked, the change is queued rather than
	# applied: the bee sees the job through -- a forager delivers the
	# load it is carrying, a comb worker finishes the cell it is on -- and
	# picks the new role up the moment it is next free. Unticked, it
	# drops everything immediately, which is the old behaviour.
	if finish_task_first and _is_busy():
		pending_role = new_role
		return

	pending_role = -1
	_apply_role(new_role)

## Applied straight away, with no regard for what the bee was doing.
func _apply_role(new_role: int) -> void:
	_release_everything()

	role = new_role
	visible = true
	# brood food a nurse was carrying isn't any use in another job
	nurse_pollen = 0.0
	nurse_carb = 0.0
	nurse_carb_type = ""
	nurse_fetching = ""
	nurse_jelly = 0.0
	var now_indoors := _works_indoors()

	if _is_inside_hive():
		# already in the hive: either start the new indoor job here, or
		# walk out through the entrance the normal way
		state = _default_state_for_role() if now_indoors else State.IN_HIVE_TO_EXIT
	else:
		# out in the meadow: fly to the hive and walk in, or just get on
		# with the new outdoor job from where it stands
		state = State.TO_HIVE if now_indoors else _default_state_for_role()

	_update_label()

func _release_everything() -> void:
	if current_flower:
		current_flower.release(self)
		current_flower = null
	if target_cell and is_instance_valid(target_cell):
		target_cell.release_builder(self)
	if target_block and is_instance_valid(target_block):
		target_block.release_miner(self)
	_release_cell_slot()
	target_cell = null
	target_block = null
	haul_target = null
	fan_target = null

## Called by a flower that's about to wither with this bee on it.
func release_flower_reference(flower: Node2D) -> void:
	if current_flower == flower:
		current_flower = null
		if state == State.TO_FLOWER or state == State.INSPECTING or state == State.COLLECTING:
			state = State.SEEK_FLOWER

func set_selected(value: bool) -> void:
	selected = value
	selection_ring.visible = value

# --- display ------------------------------------------------------

func role_letter() -> String:
	# Foragers are the one role whose letter depends on what it's doing,
	# since which resource a bee is on is the thing you most want to read
	# off a crowd of them at a glance.
	if role == Role.FORAGER:
		return "N" if resource_type == "nectar" else "P"
	return Roles.letter_for(role)

## Why isn't this bee doing anything?
##
## "Nothing is happening and I can't tell why" is the worst state to
## leave a player in, and it is easy to reach: a nurse with no brood, a
## miner with nothing marked and automine off, a comb worker with
## nowhere left to build all look identical from outside -- a bee
## standing still.
##
## Each role knows what it was looking for, so each can say what it
## didn't find. Returns "" when the bee is genuinely busy.
func idle_reason() -> String:
	if hive == null:
		return ""
	match state:
		State.NURSE_IDLE:
			if role == Role.EGG_LAYER:
				if hive.find_cell_with("pollen") == null:
					return "No pollen in the comb — she can't eat, so she can't lay."
				if not hive.has_room_for_egg():
					return "Nowhere to lay. Every nursery cell is occupied and there is no spare comb — reserve more cells for eggs, or build some."
				return ""
			if hive.cells_holding("brood").is_empty():
				return "No brood to look after. Nothing has been laid, or it has all emerged."
			return ""
		State.BUILD_IDLE:
			if architect_mode == "restock":
				if not has_restock_orders():
					return "No restocking orders. Select some comb and choose a resource to keep it full of."
				return "Nowhere to draw from. Every cell holding %s is either sealed, blocked, or one of the cells being filled." % restock_resource
			if architect_mode == "maintain":
				return "Nothing to clear. No dead larvae and no cells waiting to be emptied."
			if hive.create_next_cell_site(home_hex if has_home_hex else Vector2i.ZERO) == null:
				return "Nowhere left to build. The open floor is full — put miners on the soil to make more room, or clear a keep-clear tile."
			return ""
		State.MINE_IDLE:
			if not mine_queue.is_empty():
				return "The blocks you marked are still buried. They will be dug once the soil in front of them is gone."
			if automine:
				return "No soil left within reach. Everything diggable has been dug, or what's left is behind bedrock."
			return "Nothing marked to dig, and this miner isn't digging on its own. Use Mine to give it a block, or turn on \"Dig on its own\"."
		State.HONEY_IDLE:
			if hive.find_cell_with("nectar") == null:
				return "No nectar to work with. Honey is made from stored nectar, so the foragers have to bring some in first."
			if hive.find_honey_target() == null:
				return "Nowhere to put the mix. Every cell is full or reserved for something else — free one up, or build more comb."
			return ""
		State.SEEK_FLOWER:
			if _grounded():
				if Session.winter_here:
					return "Winter. Nothing is out, so the foragers are staying in."
				return "Raining too hard to fly. They'll go out when it eases."
			if _nearest_flower(false) == null:
				return "Nothing worth visiting. Every flower nearby is empty, out of season, or already taken."
			return ""
		State.IDLING:
			return "Set to idle. It will stay put until you give it a job."
	return ""

## A plain-language description of what this bee is doing right now,
## shown in the selection panel. Deliberately concrete ("returning
## pollen to the hive") rather than naming internal states.
func task_description() -> String:
	match state:
		State.SEEK_FLOWER:
			return "looking for a %s flower" % resource_type
		State.TO_FLOWER:
			return "flying to a flower for %s" % resource_type
		State.INSPECTING:
			return "inspecting a flower before deciding whether to feed"
		State.COLLECTING:
			if timer > 0.0:
				return "landing on a flower"
			return "collecting %s (%d carried)" % [resource_type, int(current_load)]
		State.TO_HIVE:
			return "returning %s to the hive (%d carried)" % [current_load_type, int(current_load)]
		State.IN_HIVE_TO_CELL:
			return "carrying %s to a cell" % current_load_type
		State.DEPOSITING:
			return "unloading %s into a cell" % current_load_type
		State.IN_HIVE_TO_EXIT:
			return "heading back out of the hive"
		State.MOVE_TO_POINT:
			return "moving where you sent it"
		State.IDLING:
			return "idle -- waiting for orders"
		State.MINE_IDLE:
			var base_mine := "looking for a block to dig" if automine else "waiting for a block to be marked"
			return base_mine + _idle_backup_note()
		State.TO_MINE_SITE:
			return "walking to a marked soil block"
		State.MINING:
			var dug := 0
			if target_block and is_instance_valid(target_block):
				dug = int(target_block.mine_fraction() * 100.0)
			return "digging out soil (%d%%, carrying %d/%d dirt)" % [dug, int(dirt_load), int(GameConfig.miner_dirt_capacity)]
		State.TO_MINE_EXIT:
			return "carrying spoil out to dump it"
		State.DUMPING_DIRT:
			return "emptying out a load of dirt"
		State.NURSE_IDLE:
			return "looking for brood work" + _idle_backup_note()
		State.TO_BROOD:
			return "going to tend the brood"
		State.TENDING:
			if target_cell and is_instance_valid(target_cell) and target_cell.content_type == "brood":
				if target_cell.brood_fed_seconds > 0.0:
					return "feeding a larva (%ds of development left in it)" % int(target_cell.brood_fed_seconds)
				return "tending a larva -- no pollen in the comb to feed it"
			return "tending a developing bee"
		State.DRINKING:
			return "drinking nectar from the flower to refuel (energy %d%%)" % int(100.0 * energy / max(0.001, GameConfig.energy_capacity))
		State.SHELTERING:
			return "sheltering at the hive -- too wet to forage"
		State.MAKING_JELLY:
			return "working pollen and honey into royal jelly (%ds)" % int(max(0.0, timer))
		State.TO_JELLY_CELL:
			return "carrying royal jelly to a cell"
		State.DEPOSITING_JELLY:
			return "storing royal jelly"
		State.TO_FOOD_CELL:
			return "going to collect %s for the brood" % nurse_fetching
		State.LOADING_FOOD:
			return "loading up with %s to feed the brood" % nurse_fetching
		State.TO_FEED_CELL:
			return "hungry -- heading to a cell to eat"
		State.FEEDING:
			var eating := "nectar"
			if target_cell and is_instance_valid(target_cell):
				eating = target_cell.content_type
			return "eating %s (energy %d%%)" % [
				eating, int(100.0 * energy / max(0.001, GameConfig.energy_capacity)),
			]
		State.HONEY_IDLE:
			return "looking for nectar to turn into honey" + _idle_backup_note()
		State.TO_NECTAR_CELL:
			return "going to a nectar cell to fill up"
		State.CHEWING:
			return "chewing enzymes into nectar (%ds left)" % int(max(0.0, timer))
		State.TO_HONEY_CELL:
			return "carrying the honey mix to a cell"
		State.DEPOSITING_HONEY:
			return "spitting the mix into a honey cell"
		State.FANNING:
			var dried := 0
			if fan_target and is_instance_valid(fan_target):
				dried = int(fan_target.ripen_fraction() * 100.0)
			return "fanning a honey cell dry (%d%%)" % dried
		State.BUILD_IDLE:
			return "looking for building work" + _idle_backup_note()
		State.TO_BUILD_SITE:
			return "walking to a cell under construction"
		State.BUILDING:
			var pct := 0
			if target_cell and is_instance_valid(target_cell):
				pct = int(target_cell.build_fraction() * 100.0)
			return "building a new cell (%d%%)" % pct
		State.TO_RESTOCK_SOURCE:
			return "fetching %s to top up a cell it keeps full" % restock_resource
		State.TO_RESTOCK_TARGET:
			return "carrying %s to a cell it keeps full" % current_load_type
		State.TO_HAUL_SOURCE:
			return "going to clear a reassigned cell"
		State.TO_HAUL_TARGET:
			return "moving %s to another cell" % current_load_type
		State.TO_CLEAN_CELL:
			return "going to clear a dead larva out of a cell"
		State.CLEANING:
			var cleaned := 0
			if target_cell and is_instance_valid(target_cell):
				cleaned = int(target_cell.clean_fraction() * 100.0)
			return "clearing a dead larva out of a cell (%d%%)" % cleaned
		State.TO_WASTE_EXIT:
			if carrying_corpse:
				return "carrying a dead larva out of the hive"
			return "carrying %s out of the hive to dump it" % current_load_type
		State.DUMPING_WASTE:
			return "disposing of a dead larva" if carrying_corpse else "throwing out unwanted stores"
		State.SEEK_POLLEN:
			if not hive.has_room_for_egg():
				return "waiting -- no free cell to lay in"
			return "looking for pollen to eat"
		State.TO_POLLEN_CELL:
			return "walking to a pollen cell"
		State.EATING:
			return "feeding on pollen (%d of %d for an egg)" % [int(pollen_eaten), int(GameConfig.egg_pollen_cost)]
		State.TO_CELL_TO_LAY:
			return "carrying an egg to a free cell"
		State.LAYING:
			return "laying an egg into a cell"
	return "idle"

## Only ever reached from task_description() while sitting in an idle
## state, which means _idle_dispatch already tried the secondary role
## this frame too and it also came up empty.
func _idle_backup_note() -> String:
	if secondary_role != -1 and secondary_role != role:
		return " (backup role %s also has nothing right now)" % Roles.label_for(secondary_role)
	return ""

func role_name_text() -> String:
	var base: String = Roles.label_for(role)
	match role:
		Role.NURSERY:
			base += " (%s)" % Roles.mode_label(Roles.NURSE, nurse_mode).to_lower()
		Role.BUILDER:
			base += " (%s)" % architect_mode_name()
		Role.MINER:
			if automine:
				base += " (digging on its own)"
		Role.FORAGER:
			base += " (%s)" % resource_type
			if preferred_species != "":
				base += " -- %s only" % preferred_species
	if secondary_role != -1 and secondary_role != role:
		base += " -- when idle: %s" % Roles.label_for(secondary_role)
	return base

func nurse_mode_name() -> String:
	match nurse_mode:
		"jelly":
			return "royal jelly"
		"both":
			return "feeding and royal jelly"
		_:
			return "feeding brood"

func architect_mode_name() -> String:
	var label: String = Roles.mode_label(Roles.COMB_WORKER, architect_mode).to_lower()
	if architect_mode == "restock":
		label += " %s" % (restock_resource if restock_resource != "" else "-- nothing set")
	return label

func carrying_text() -> String:
	if carrying_corpse:
		return "Carrying: a dead larva, for disposal outside"
	if role == Role.MINER:
		return "Carrying: %d dirt (of %d)" % [int(dirt_load), int(GameConfig.miner_dirt_capacity)]
	if honey_load > 0.0:
		return "Carrying: %d units of honey mix" % int(ceil(honey_load))
	if nurse_pollen > 0.0 or nurse_carb > 0.0 or nurse_jelly > 0.0:
		var carb_name: String = nurse_carb_type if nurse_carb_type != "" else "nectar"
		var carried := "Carrying: %d pollen and %d %s for the brood (%d feeds)" % [
			int(nurse_pollen), int(nurse_carb), carb_name, int(_feeds_carried()),
		]
		if nurse_jelly > 0.0:
			carried += ", plus %d royal jelly" % int(nurse_jelly)
		return carried
	if current_load <= 0.0 or current_load_type == "":
		return "Carrying: nothing"
	return "Carrying: %d %s (of %d)" % [int(current_load), current_load_type, int(_max_capacity())]

## Age and remaining life now live in the selection panel rather than
## floating over every bee, which was a lot of numbers to read at once.
func age_days() -> float:
	return age_seconds / max(0.001, GameConfig.seconds_per_day)

## A gyne mature enough and fed enough to go. She simply leaves: the
## colony has already spent everything it will spend on her, and what it
## gets back is a number on the scoreboard rather than a bee.
##
## Not a death -- no marker, no corpse. She flew off and it worked.
func leave_to_found_colony() -> void:
	if is_dying:
		return
	is_dying = true
	if current_flower:
		current_flower.release(self)
	if target_cell and is_instance_valid(target_cell):
		target_cell.release_builder(self)
	if target_block and is_instance_valid(target_block):
		target_block.release_miner(self)
	_release_cell_slot()
	queue_free()

func days_remaining() -> float:
	return max(0.0, _lifespan_seconds() / max(1.0, GameConfig.seconds_per_day) - age_days())

## Skipped entirely for bees the camera can't see. Setting a label's text
## and a polygon's colour are each cheap; doing both for every bee every
## frame when most of them are off screen is not, and nobody can tell.
func _update_label() -> void:
	if world != null and is_instance_valid(world) and not world.is_on_screen(self):
		return
	var prefix := "Q" if is_queen else str(bee_id)
	label.text = "%s%s" % [prefix, role_letter()]
	# body dims as energy runs low, so a starving bee is visible at a glance
	var energy_fraction: float = clamp(energy / max(0.001, GameConfig.energy_capacity), 0.0, 1.0)
	body.color = _base_colour().lerp(Color(0.45, 0.35, 0.3), 1.0 - energy_fraction)

## Bees inside the hive pick their way over the comb rather than flying
## straight, so standing on a cell slows them down. Out in the meadow
## there's no terrain, so this is a no-op.
func _terrain_speed_factor() -> float:
	if not _is_inside_hive():
		return 1.0
	if hive == null or not hive.has_method("cell_at_tile"):
		return 1.0
	var local: Vector2 = position - hive.comb_centre
	var hex: Vector2i = Shapes.pixel_to_hex(local, GameConfig.hive_cell_spacing)
	return GameConfig.cell_slow_factor if hive.cell_at_tile(hex) != null else 1.0

func _is_inside_hive() -> bool:
	return world != null and get_parent() == world.hive_root

# --- getting round things in the meadow ---------------------------
##
## This was rewritten after three failed patches, because the approach
## itself was wrong rather than the details.
##
## The old scheme aimed at a point on a circle of radius
## `max(clearance, current distance from the centre)`. That number is the
## bee's *own* distance from the obstacle, so the aim point sat on the
## circle the bee was already standing on. Moving towards it produced
## tangential motion and no radial motion at all -- the bee orbited the
## obstacle at a fixed distance forever, unable to get closer or further
## away. That is exactly the behaviour on screen. Every patch since then
## adjusted which way round the orbit went, which was never the problem.
##
## The rewrite steers at the *tangent point*: the place on the inflated
## circle where a straight line from the bee just grazes the obstacle.
## Three things follow from that, and they are what make it work:
##
##   1. The tangent point is never on the bee's current circle, so the
##      motion always has a radial component. No orbit is possible.
##   2. Walking a tangent line is the shortest way past a circle, so the
##      bee visibly makes for the edge and rounds it.
##   3. Once the bee passes the tangent point the obstacle is behind it
##      and the straight line to the target is clear, so the detour ends
##      by itself rather than needing to be detected.
##
## Underneath it all is a hard guarantee that does not depend on any of
## the geometry being right: `_watch_for_stalls` measures whether the bee
## is actually getting closer to where it is going, and if it isn't, moves
## it clear. A steering bug should cost a bee a few seconds, never the run.

## Room left round an obstacle when steering, and the hard boundary
## _block_obstacles enforces. These two numbers have to satisfy two
## constraints, and getting them the wrong way round is what caused the
## orbiting in the first place:
##
##   BLOCK_MARGIN >= OBSTACLE_MARGIN
##     A bee pressed against the hard boundary must not be considered to
##     be inside the steering margin. When it was (block 8, steering 16),
##     a bee at the boundary counted as blocked by the very obstacle it
##     was touching -- in every direction, including directly away from
##     it. It could never report "the way is clear", so it circled at the
##     boundary forever. That is the orbit at fixed distance.
##
##   BLOCK_MARGIN < the clearance flowers are planted at
##     Otherwise a flower near a plateau sits inside the boundary and no
##     bee can ever physically reach it.
##
## 18 and 18 satisfy both, against a flower clearance of 30.
const OBSTACLE_MARGIN := 18.0
const BLOCK_MARGIN := 18.0

## How far round the rim to aim when the bee is already at the boundary.
const SWEEP_STEP := 0.6

## Which obstacle the bee is currently going round, and which way. Held
## until the bee is genuinely past it -- picking a side afresh each frame
## flips at the halfway angle and shuffles the bee on the spot.
var skirt_obstacle: Node2D = null
var skirt_turn: float = 1.0

## How many consecutive clear frames before the bee forgets what it was
## going round.
##
## One clear frame used to be enough, and that was too eager. The
## blocker test can momentarily report the way clear part-way past an
## obstacle -- it is a line-of-sight check against a set that changes as
## the bee moves -- and dropping the commitment on that one frame lets
## the side be chosen afresh from an angle that has already swung past
## halfway. Which is precisely the shuffle the commitment exists to
## stop. Holding it for a few frames costs nothing: the turn is only
## ever read on a frame where there *is* a blocker.
const SKIRT_FORGET_FRAMES := 3
var skirt_clear_frames: int = 0

## Returns where the bee should actually head this frame: the target
## itself when the way is clear, or a tangent point past whatever is in
## the way.
func _avoid_obstacles(target: Vector2) -> Vector2:
	var blocker := _first_blocker(target)
	if blocker == null:
		# Clear for now, but not necessarily past it. See
		# SKIRT_FORGET_FRAMES.
		skirt_clear_frames += 1
		if skirt_clear_frames >= SKIRT_FORGET_FRAMES:
			skirt_obstacle = null
			skirt_clear_frames = 0
		return target
	skirt_clear_frames = 0
	return _tangent_past(blocker, target)

## The nearest solid obstacle the straight line to `target` runs into,
## or null if the way is clear.
##
## `solid` is checked here as well as in _block_obstacles. Without it,
## switching the scenery off left bees still steering round trees they
## could now walk straight through -- which is why turning the scenery
## off didn't free the stuck ones.
func _first_blocker(target: Vector2) -> Node2D:
	var to_target: Vector2 = target - position
	var span: float = to_target.length()
	if span < 1.0:
		return null
	var direction: Vector2 = to_target / span

	var nearest: Node2D = null
	var nearest_along := INF
	for obstacle in _obstacles_towards(target):
		if not is_instance_valid(obstacle) or not obstacle.solid:
			continue
		var reach: float = obstacle.radius + OBSTACLE_MARGIN

		# Something the bee is standing next to but heading away from is
		# not in the way. Without this test a bee at the boundary of a
		# plateau reports itself blocked by that plateau whichever way it
		# faces, and can never decide it is past it.
		var to_obstacle: Vector2 = obstacle.position - position
		var along: float = clamp(to_obstacle.dot(direction), 0.0, span)
		if along <= 0.5:
			continue

		# An obstacle whose margin contains the destination can't be
		# steered around and still arrived at -- a flower planted close to
		# a plateau, say. Ignore it and let the hard boundary slide the
		# bee round the edge instead, which does get there.
		if target.distance_to(obstacle.position) < reach:
			continue

		var closest_point: Vector2 = position + direction * along
		if closest_point.distance_to(obstacle.position) >= reach:
			continue
		if along < nearest_along:
			nearest_along = along
			nearest = obstacle
	return nearest

## Where to aim in order to get past `obstacle`.
##
## The aim point always sits on the circle of radius R = obstacle radius
## plus the margin. That fixed R is the whole fix. The old code used
## `max(R, the bee's own distance from the centre)`, which put the aim
## point on whatever circle the bee happened to be standing on -- so the
## bee moved along that circle and never off it. Pure orbit.
##
## How far round the circle to aim depends on where the bee is:
##
##   Far out: aim at the silhouette edge, acos(R/d) round from the bee's
##   own bearing. That is the point where a straight line from the bee
##   just grazes the obstacle, so this is the shortest way past it.
##
##   At the boundary: acos(R/d) collapses to nothing, so step a fixed
##   SWEEP_STEP round instead. The bee walks round the edge until the
##   way ahead opens up.
##
## Both cases put the aim point somewhere the bee is not, and both pull
## it towards R rather than holding it wherever it started, so there is
## always motion both around and across.
func _tangent_past(obstacle: Node2D, target: Vector2) -> Vector2:
	var rim: float = obstacle.radius + OBSTACLE_MARGIN
	var from_centre: Vector2 = position - obstacle.position
	var distance: float = from_centre.length()
	if distance < 0.01:
		from_centre = Vector2.RIGHT
		distance = 0.01

	var turn: float = _committed_turn(obstacle, target)
	var silhouette: float = acos(clamp(rim / distance, -1.0, 1.0)) if distance > rim else 0.0
	var offset: float = max(silhouette, SWEEP_STEP)
	var heading: float = from_centre.angle() + turn * offset
	return obstacle.position + Vector2(cos(heading), sin(heading)) * rim

	# Deliberately no recursion for the case where the way past one
	# obstacle points into its neighbour. `_first_blocker` always returns
	# the *nearest* thing in the way, so as the bee advances the
	# neighbour becomes the nearest blocker and is routed round in its
	# turn, one obstacle at a time. Trying to solve the whole chain in
	# one frame is how the old code produced aim points that satisfied
	# neither obstacle.

## Which way round. Chosen once per obstacle and then held, because a
## choice remade every frame from an angle that changes as you act on it
## will flip back and forth at the halfway point -- that is the
## side-to-side shuffle. Committing to the longer way round is always
## better than oscillating.
func _committed_turn(obstacle: Node2D, target: Vector2) -> float:
	if skirt_obstacle == obstacle and is_instance_valid(skirt_obstacle):
		return skirt_turn
	var here: float = (position - obstacle.position).angle()
	var there: float = (target - obstacle.position).angle()
	var shorter_way: float = wrapf(there - here, -PI, PI)
	skirt_obstacle = obstacle
	skirt_turn = 1.0 if shorter_way >= 0.0 else -1.0
	return skirt_turn

## Called when the world changes underneath a bee -- the scenery being
## toggled, or a bee being given a new order -- so no stale commitment to
## an obstacle that may no longer be solid survives into the next frame.
func clear_navigation_state() -> void:
	skirt_obstacle = null
	skirt_clear_frames = 0
	_reset_stall_watch()

## The obstacle list, from main.gd's cache rather than a group query.
## Every bee asks about obstacles several times a frame; scanning the
## scene tree for them each time was one of the few things in here that
## scales badly with colony size. The meadow's obstacles never change
## during a run, so main.gd builds the list once.
func _obstacles() -> Array:
	if world != null and is_instance_valid(world):
		return world.obstacles
	return get_tree().get_nodes_in_group("obstacles")

## Which obstacles could matter for a move from here to `target`.
##
## The honest answer is "all fourteen of them", and that is what this
## returns. It briefly went through the spatial grid, which was a
## mistake worth writing down: the grid is a clear win for flowers, and
## a loss here, because the two questions are not the same shape.
##
## The flower search asks about 250 objects, eight times a second. The
## obstacle search asks about 14, sixty times a second, for every bee.
## Against 14 items in an array main.gd already holds, the grid query
## was slower than the scan it replaced -- 25 to 121 bucket lookups
## depending on how far the bee was flying, plus a fresh Array allocated
## every frame per bee. At sixty bees that is thousands of allocations a
## second, and allocation churn shows up as *uneven* frame times rather
## than a lower average. Since movement is speed * delta, uneven frames
## are visible directly as bees moving in little lurches.
##
## It also fed a set that changed as the bee moved into _committed_turn,
## which is meant to be sticky. See SKIRT_FORGET_FRAMES.
##
## Kept as its own function rather than inlined: if the meadow ever
## holds hundreds of obstacles this is the one place that has to change,
## and the right fix then is to cache per journey, not per frame.
func _obstacles_towards(_target: Vector2) -> Array:
	return _obstacles()

## The hard half of obstacle handling. _avoid_obstacles steers, which is
## enough most of the time but not a guarantee: a bee right-clicked onto
## a mound, or squeezed between two obstacles, could still end up on top
## of one. This refuses the move outright -- if the position a bee is
## about to take is inside a solid obstacle it gets pushed back out to
## the edge and slid along it, so it walks round the boundary instead of
## over it. Raised ground stays impassable until a movement upgrade
## clears `solid` on it.
func _block_obstacles(wanted: Vector2) -> Vector2:
	var result := wanted
	# Settle over a few rounds. Pushing clear of one obstacle can land a
	# bee inside the next one where two sit close together, and a single
	# pass would leave it there.
	for round_number in range(3):
		var moved := false
		for obstacle in _obstacles():
			if not is_instance_valid(obstacle) or not obstacle.solid:
				continue
			var edge: float = obstacle.radius + BLOCK_MARGIN
			var offset: Vector2 = result - obstacle.position
			var distance: float = offset.length()
			if distance >= edge:
				continue
			if distance < 0.01:
				# exactly on the centre (shouldn't happen) -- shove it out
				# in an arbitrary but consistent direction rather than
				# dividing by zero
				offset = Vector2.RIGHT
				distance = 1.0
			result = obstacle.position + offset / distance * edge
			moved = true
		if not moved:
			break
	return result

## Outdoors a bee flies straight. Inside the hive it walks a route over
## open tiles, because soil is solid. The route is recalculated only
## when the destination changes, not every frame.
func _move_towards(target: Vector2, delta: float) -> void:
	Perf.begin("bee_move")
	var step: float = speed * _terrain_speed_factor() * delta

	if not _is_inside_hive():
		var wanted: Vector2 = position.move_toward(_avoid_obstacles(target), step)
		position = _block_obstacles(wanted)
		Perf.end("bee_move")
		return

	if target.distance_to(path_goal) > 6.0 or path_points.is_empty():
		path_goal = target
		# Timed inside path_between itself (hive.gd), which is the
		# suspect the perf plan names first: an A* search over the whole
		# hive grid, potentially every frame per bee.
		path_points = hive.path_between(position, target)
		path_index = 0

	if path_points.is_empty():
		Perf.end("bee_move")
		return   # no safe route -- stay put rather than cutting through soil

	# walk the waypoints, spending any leftover movement on the next one
	while step > 0.0 and path_index < path_points.size():
		var waypoint: Vector2 = path_points[path_index]
		var gap: float = position.distance_to(waypoint)
		if gap <= step:
			position = waypoint
			step -= gap
			path_index += 1
		else:
			position = position.move_toward(waypoint, step)
			step = 0.0
	if path_index >= path_points.size():
		position = position.move_toward(target, step)
	Perf.end("bee_move")
