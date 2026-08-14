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

## Role and State (and ROLE_PERF_SECTIONS) live in bee_enums.gd, a leaf
## file with no dependencies, so every other bee_*.gd file can use them
## without a circular preload of bee.gd itself. Aliased straight back
## here so every existing `Bee.Role.X` / `Bee.State.X` reference in
## hud.gd, main.gd, world_building.gd, input_selection.gd,
## orders_zones.gd and year_winter.gd keeps working unchanged.
const BeeEnums = preload("res://scripts/bee_enums.gd")
const Role = BeeEnums.Role
const State = BeeEnums.State
const ROLE_PERF_SECTIONS = BeeEnums.ROLE_PERF_SECTIONS

const Shapes = preload("res://scripts/shapes.gd")
const Roles = preload("res://scripts/roles.gd")
const BeeMovement = preload("res://scripts/bee_movement.gd")
const BeeStatus = preload("res://scripts/bee_status.gd")
const BeeSurvival = preload("res://scripts/bee_survival.gd")
const BeeForaging = preload("res://scripts/bee_foraging.gd")
const BeeNursery = preload("res://scripts/bee_nursery.gd")
const BeeBuilding = preload("res://scripts/bee_building.gd")
const BeeMining = preload("res://scripts/bee_mining.gd")
const BeeHoney = preload("res://scripts/bee_honey.gd")
const BeeEggLaying = preload("res://scripts/bee_egg_laying.gd")

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
	BeeSurvival.age_and_burn(self, delta)
	Perf.end("bee_burn")
	if not is_inside_tree():
		Perf.end("bees")
		return   # died during ageing

	if thinking:
		Perf.begin("bee_think")
		BeeSurvival.watch_for_stalls(self, think_delta)

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
		if BeeSurvival.should_go_and_eat(self):
			BeeSurvival.begin_feeding_self(self)
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
			BeeForaging.seek_flower(self)
			Perf.end("bee_seek_flower")
		State.TO_FLOWER:
			Perf.begin("bee_to_flower")
			if current_flower == null:
				state = State.SEEK_FLOWER
			else:
				BeeMovement.move_towards(self, current_flower.position, delta)
				if position.distance_to(current_flower.position) < arrive_distance:
					BeeForaging.start_inspecting(self)
			Perf.end("bee_to_flower")
		State.INSPECTING:
			Perf.begin("bee_inspecting")
			BeeForaging.inspect(self, delta)
			Perf.end("bee_inspecting")
		State.COLLECTING:
			Perf.begin("bee_collecting")
			BeeForaging.collect(self, delta)
			Perf.end("bee_collecting")
		State.DRINKING:
			BeeForaging.drink_at_flower(self, delta)
		State.TO_HIVE:
			Perf.begin("bee_to_hive")
			BeeMovement.move_towards(self, hive.position, delta)
			if position.distance_to(hive.position) < arrive_distance:
				BeeForaging.enter_hive(self)
			Perf.end("bee_to_hive")
		State.SHELTERING:
			BeeForaging.shelter(self, delta)

		# --- nursery, making royal jelly ---
		State.MAKING_JELLY:
			BeeNursery.nurse_make_jelly(self, delta)
		State.TO_JELLY_CELL:
			BeeNursery.nurse_go_to_jelly_cell(self, delta)
		State.DEPOSITING_JELLY:
			BeeNursery.nurse_deposit_jelly(self, delta)

		# --- forager, indoors ---
		State.IN_HIVE_TO_CELL:
			Perf.begin("bee_to_cell")
			BeeForaging.go_to_deposit_cell(self, delta)
			Perf.end("bee_to_cell")
		State.DEPOSITING:
			timer -= delta
			if timer <= 0.0:
				BeeForaging.finish_depositing(self)
		State.IN_HIVE_TO_EXIT:
			Perf.begin("bee_to_exit")
			BeeForaging.go_to_exit(self, delta)
			Perf.end("bee_to_exit")

		State.MOVE_TO_POINT:
			BeeMovement.move_towards(self, move_target, delta)
			if position.distance_to(move_target) < arrive_distance:
				state = _default_state_for_role()
		State.IDLING:
			pass   # waits for orders and nothing else

		# --- nursery ---
		State.NURSE_IDLE:
			_idle_dispatch()
		State.TO_BROOD:
			BeeNursery.nurse_go_to_brood(self, delta)
		State.TENDING:
			BeeNursery.nurse_tend(self, delta)
		State.TO_FOOD_CELL:
			BeeNursery.nurse_go_to_food(self, delta)
		State.LOADING_FOOD:
			BeeNursery.nurse_load_food(self, delta)

		# --- eating (any role) ---
		State.TO_FEED_CELL:
			BeeSurvival.go_to_feed_cell(self, delta)
		State.FEEDING:
			BeeSurvival.feed_self(self, delta)

		# --- builder ---
		State.BUILD_IDLE:
			_idle_dispatch()
		State.TO_BUILD_SITE:
			BeeBuilding.builder_go_to_site(self, delta)
		State.BUILDING:
			BeeBuilding.builder_build(self, delta)
		State.TO_RESTOCK_SOURCE:
			BeeBuilding.restock_go_to_source(self, delta)
		State.TO_RESTOCK_TARGET:
			BeeBuilding.restock_go_to_target(self, delta)
		State.TO_HAUL_SOURCE:
			BeeBuilding.builder_go_to_haul_source(self, delta)
		State.TO_HAUL_TARGET:
			BeeBuilding.builder_go_to_haul_target(self, delta)
		State.TO_WASTE_EXIT:
			BeeBuilding.builder_go_to_waste_exit(self, delta)
		State.DUMPING_WASTE:
			BeeBuilding.builder_dump_waste(self, delta)
		State.TO_CLEAN_CELL:
			BeeBuilding.architect_go_to_clean(self, delta)
		State.CLEANING:
			BeeBuilding.architect_clean(self, delta)

		# --- miner ---
		State.MINE_IDLE:
			_idle_dispatch()
		State.TO_MINE_SITE:
			BeeMining.miner_go_to_site(self, delta)
		State.MINING:
			BeeMining.miner_dig(self, delta)
		State.TO_MINE_EXIT:
			BeeMining.miner_go_to_exit(self, delta)
		State.DUMPING_DIRT:
			BeeMining.miner_dump(self, delta)

		# --- honey maker ---
		State.HONEY_IDLE:
			_idle_dispatch()
		State.TO_NECTAR_CELL:
			BeeHoney.honey_go_to_nectar(self, delta)
		State.CHEWING:
			BeeHoney.honey_chew(self, delta)
		State.TO_HONEY_CELL:
			BeeHoney.honey_go_to_pot(self, delta)
		State.DEPOSITING_HONEY:
			BeeHoney.honey_deposit(self, delta)
		State.FANNING:
			BeeHoney.honey_fan(self, delta)

		# --- egg layer ---
		State.SEEK_POLLEN:
			BeeEggLaying.queen_seek_pollen(self)
		State.TO_POLLEN_CELL:
			BeeEggLaying.queen_go_to_pollen(self, delta)
		State.EATING:
			BeeEggLaying.queen_eat(self, delta)
		State.TO_CELL_TO_LAY:
			BeeEggLaying.queen_go_to_lay(self, delta)
		State.LAYING:
			BeeEggLaying.queen_lay(self, delta)
	Perf.end(role_section)
	Perf.end("bee_state")

	Perf.begin("bee_label")
	_update_label()
	Perf.end("bee_label")
	Perf.end("bees")

# --- life support -------------------------------------------------
## Moved to bee_survival.gd -- see BEE_SPLIT_PLAN.md.
# --- eating -------------------------------------------------------
## Moved to bee_survival.gd -- see BEE_SPLIT_PLAN.md.
# --- stall watchdog -----------------------------------------------
## Moved to bee_survival.gd -- see BEE_SPLIT_PLAN.md. reset_stall_watch
## stays here: bee_movement.gd's clear_navigation_state() (already
## split out) calls it directly, and moving it would make
## bee_movement.gd and bee_survival.gd preload each other.

func _reset_stall_watch() -> void:
	stall_best_distance = INF
	stall_timer = 0.0
# --- foraging -----------------------------------------------------
## Moved to bee_foraging.gd -- see BEE_SPLIT_PLAN.md.
# --- entering and leaving the hive --------------------------------
## Moved to bee_foraging.gd -- see BEE_SPLIT_PLAN.md.
# --- nursery work -------------------------------------------------
## Moved to bee_nursery.gd -- see BEE_SPLIT_PLAN.md.
# --- royal jelly ---------------------------------------------------
## Moved to bee_nursery.gd -- see BEE_SPLIT_PLAN.md.
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
				if BeeNursery.can_make_jelly(self):
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
			if brood.needs_feeding() and not BeeNursery.can_feed(self, brood):
				if BeeNursery.nurse_restock_errand(self, brood.brood_is_gyne):
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
				if BeeBuilding.find_restock_job(self):
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
## Moved to bee_building.gd -- see BEE_SPLIT_PLAN.md.
# --- keeping cells topped up ---------------------------------------
## Moved to bee_building.gd -- see BEE_SPLIT_PLAN.md. The four
## methods below stay as one-line wrappers because orders_zones.gd
## and hud.gd call them directly on a bee.
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

## One-line wrappers -- orders_zones.gd and hud.gd call these directly on
## a bee, so the public API didn't move even though the logic did.
func set_restock_targets(cells: Array, resource: String) -> void:
	BeeBuilding.set_restock_targets(self, cells, resource)

func set_restock_sources(cells: Array, allowed: bool) -> void:
	BeeBuilding.set_restock_sources(self, cells, allowed)

func clear_restock() -> void:
	BeeBuilding.clear_restock(self)

func has_restock_orders() -> bool:
	return BeeBuilding.has_restock_orders(self)
# --- mining -------------------------------------------------------
## Moved to bee_mining.gd -- see BEE_SPLIT_PLAN.md.
# --- honey making -------------------------------------------------
## Moved to bee_honey.gd -- see BEE_SPLIT_PLAN.md.
# --- egg laying (queen only) --------------------------------------
## Moved to bee_egg_laying.gd -- see BEE_SPLIT_PLAN.md.
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
		target = BeeMovement.block_obstacles(self, target)
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
	var now_indoors := BeeStatus.works_indoors(self)

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
	BeeForaging.release_cell_slot(self)
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
				if not BeeBuilding.has_restock_orders(self):
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
			if BeeStatus.grounded(self):
				if Session.winter_here:
					return "Winter. Nothing is out, so the foragers are staying in."
				return "Raining too hard to fly. They'll go out when it eases."
			if BeeForaging.nearest_flower(self, false) == null:
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
			int(nurse_pollen), int(nurse_carb), carb_name, int(BeeNursery.feeds_carried(self)),
		]
		if nurse_jelly > 0.0:
			carried += ", plus %d royal jelly" % int(nurse_jelly)
		return carried
	if current_load <= 0.0 or current_load_type == "":
		return "Carrying: nothing"
	return "Carrying: %d %s (of %d)" % [int(current_load), current_load_type, int(BeeForaging.max_capacity(self))]

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
	BeeForaging.release_cell_slot(self)
	queue_free()

func days_remaining() -> float:
	return max(0.0, BeeSurvival.lifespan_seconds(self) / max(1.0, GameConfig.seconds_per_day) - age_days())

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
## Obstacle avoidance and steering moved to bee_movement.gd -- see
## BEE_SPLIT_PLAN.md. These three vars stay here (all vars stay on
## bee.gd) because bee_movement.gd's static functions read and write
## them directly as bee.skirt_obstacle etc.

## Which obstacle the bee is currently going round, and which way. Held
## until the bee is genuinely past it -- picking a side afresh each frame
## flips at the halfway angle and shuffles the bee on the spot.
var skirt_obstacle: Node2D = null
var skirt_turn: float = 1.0

## How many consecutive clear frames before the bee forgets what it was
## going round. See bee_movement.gd's SKIRT_FORGET_FRAMES for why one
## clear frame isn't enough.
var skirt_clear_frames: int = 0

## Kept as a one-line wrapper so world_building.gd's call to
## `b.clear_navigation_state()` didn't have to change -- same pattern as
## main.gd's wrappers after the main.gd split.
func clear_navigation_state() -> void:
	BeeMovement.clear_navigation_state(self)
