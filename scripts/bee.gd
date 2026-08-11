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
enum State {
	SEEK_FLOWER, TO_FLOWER, INSPECTING, COLLECTING, TO_HIVE,   # forager, outdoors
	IN_HIVE_TO_CELL, DEPOSITING, IN_HIVE_TO_EXIT,          # forager, indoors
	MOVE_TO_POINT, IDLING,                                 # player-commanded
	NURSE_IDLE, TO_BROOD, TENDING,                         # nursery
	BUILD_IDLE, TO_BUILD_SITE, BUILDING,                   # builder
	TO_HAUL_SOURCE, TO_HAUL_TARGET,                        # builder, moving stores
	MINE_IDLE, TO_MINE_SITE, MINING,                       # miner
	TO_MINE_EXIT, DUMPING_DIRT,                            # miner, full of spoil
	SEEK_POLLEN, TO_POLLEN_CELL, EATING,                   # egg layer
	TO_CELL_TO_LAY, LAYING,
	HONEY_IDLE, TO_NECTAR_CELL, CHEWING,                   # honey maker
	TO_HONEY_CELL, DEPOSITING_HONEY, FANNING,
}

const Shapes = preload("res://scripts/shapes.gd")

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

var move_target: Vector2 = Vector2.ZERO   # for player-commanded movement
var target_cell: Node2D = null
var haul_target: Node2D = null
var target_block: Node2D = null
var automine: bool = false
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

	var body_radius: float = 10.0 if is_queen else 6.5
	var outline_radius: float = 13.5 if is_queen else 9.0
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
			return State.SEEK_POLLEN
		Role.IDLE:
			return State.IDLING
		Role.MINER:
			return State.MINE_IDLE
		Role.HONEY_MAKER:
			return State.HONEY_IDLE
		_:
			return State.SEEK_FLOWER

func _base_colour() -> Color:
	return Color(0.95, 0.45, 0.75) if is_queen else Color(1.0, 0.85, 0.1)

func _process(delta: float) -> void:
	if hive == null:
		return

	_age_and_burn(delta)
	if not is_inside_tree():
		return   # died during ageing

	match state:
		# --- forager, outdoors ---
		State.SEEK_FLOWER:
			_seek_flower()
		State.TO_FLOWER:
			if current_flower == null:
				state = State.SEEK_FLOWER
			else:
				_move_towards(current_flower.position, delta)
				if position.distance_to(current_flower.position) < arrive_distance:
					_start_inspecting()
		State.INSPECTING:
			_inspect(delta)
		State.COLLECTING:
			_collect(delta)
		State.TO_HIVE:
			_move_towards(hive.position, delta)
			if position.distance_to(hive.position) < arrive_distance:
				_enter_hive()

		# --- forager, indoors ---
		State.IN_HIVE_TO_CELL:
			_go_to_deposit_cell(delta)
		State.DEPOSITING:
			timer -= delta
			if timer <= 0.0:
				_finish_depositing()
		State.IN_HIVE_TO_EXIT:
			_go_to_exit(delta)

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

		# --- builder ---
		State.BUILD_IDLE:
			_idle_dispatch()
		State.TO_BUILD_SITE:
			_builder_go_to_site(delta)
		State.BUILDING:
			_builder_build(delta)
		State.TO_HAUL_SOURCE:
			_builder_go_to_haul_source(delta)
		State.TO_HAUL_TARGET:
			_builder_go_to_haul_target(delta)

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

	_update_label()

# --- life support -------------------------------------------------

func _age_and_burn(delta: float) -> void:
	age_seconds += delta
	energy -= GameConfig.energy_burn_rate * delta
	# Building costs extra: bees make wax from the sugar they've eaten,
	# so expansion is paid for in energy rather than a wax stockpile.
	if state == State.BUILDING:
		energy -= GameConfig.build_energy_burn * delta

	# Bees working inside sip from the comb as they go. They eat honey
	# first where there is any -- it's several times as energy-dense as
	# the nectar it was made from, so a hive with honey in it supports far
	# more bees off the same comb.
	if _works_indoors() and energy < GameConfig.energy_capacity * 0.6:
		energy += hive.take_energy(GameConfig.energy_capacity * 0.25)

	# The queen doesn't die of old age -- losing her would silently end
	# the colony, and there's no succession yet. She can still starve.
	if not is_queen and age_seconds >= GameConfig.bee_lifespan_days * GameConfig.seconds_per_day:
		_die()
	elif energy <= 0.0:
		_die()

func _works_indoors() -> bool:
	return (
		role == Role.NURSERY
		or role == Role.BUILDER
		or role == Role.EGG_LAYER
		or role == Role.MINER
		or role == Role.HONEY_MAKER
	)

func _die() -> void:
	if current_flower:
		current_flower.release(self)
	if target_cell and is_instance_valid(target_cell):
		target_cell.release_builder(self)
	_release_cell_slot()
	queue_free()

# --- foraging -----------------------------------------------------

func _max_capacity() -> float:
	return nectar_stomach_capacity if resource_type == "nectar" else pollen_stomach_capacity

func _collection_rate() -> float:
	return nectar_collection_rate if resource_type == "nectar" else pollen_collection_rate

func _seek_flower() -> void:
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
func _nearest_flower(strict: bool) -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for f in get_tree().get_nodes_in_group("flowers"):
		if f.occupied_by != null:
			continue
		if f.get_available(resource_type) <= 0.0:
			continue
		if preferred_species != "" and f.species_name != preferred_species:
			continue
		if strict:
			if flower_cooldowns.has(f) and GameConfig.sim_time < flower_cooldowns[f]:
				continue
			# Tarsal secretion: bees leave a scent mark on flowers they
			# land on, and other bees avoid a recently marked flower
			# rather than wasting a trip on one already stripped.
			if GameConfig.tarsal_markers_on and f.is_marked(self):
				continue
		var d := position.distance_to(f.position)
		if d < best_dist:
			best_dist = d
			best = f
	return best

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
	if _worth_feeding(current_flower):
		_start_collecting()
	else:
		_reject_flower()

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
		flower_cooldowns[current_flower] = GameConfig.sim_time + REJECTED_AVOID_SECONDS
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
	current_load += taken
	if taken > 0.0:
		current_load_type = resource_type
		hive.record_collection(resource_type, taken)

	if current_load >= _max_capacity():
		_finish_collecting()

func _finish_collecting() -> void:
	if current_flower and is_instance_valid(current_flower):
		# stay away until it's had time to fully recharge
		flower_cooldowns[current_flower] = GameConfig.sim_time + current_flower.seconds_until_full(resource_type)
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
		# A forager only ever refuelled here, after a *successful*
		# deposit -- one that came home empty (nothing worth collecting
		# outside, or the comb was full) walked straight back out again
		# without ever eating. Over enough empty trips that starved it
		# to death. Refuel on every visit home, loaded or not.
		energy += hive.take_energy(GameConfig.energy_capacity - energy)
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

	# refuel from the comb while we're home
	energy += hive.take_energy(GameConfig.energy_capacity - energy)

	if current_load > 0.0:
		state = State.IN_HIVE_TO_CELL   # still carrying -- find another cell
	else:
		current_load_type = ""
		state = State.IN_HIVE_TO_EXIT

func _go_to_exit(delta: float) -> void:
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
		_feed_brood(target_cell)
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
func _feed_brood(cell: Node2D) -> void:
	# Check the comb has both halves of the meal before taking either.
	# Taking the pollen first and then finding no carbohydrate would throw
	# scarce pollen away for nothing.
	if hive.total("pollen") < GameConfig.brood_feed_pollen:
		return

	var use_honey: bool = hive.total_honey() >= GameConfig.brood_feed_honey
	if not use_honey and hive.total("nectar") < GameConfig.brood_feed_nectar:
		return

	hive.take("pollen", GameConfig.brood_feed_pollen)
	if use_honey:
		hive.take("honey", GameConfig.brood_feed_honey)
		cell.feed_brood(GameConfig.brood_feed_seconds_honey, true)
	else:
		hive.take("nectar", GameConfig.brood_feed_nectar)
		cell.feed_brood(GameConfig.brood_feed_seconds, false)
	hive.announce()

# --- idle work dispatch --------------------------------------------

## Called every frame a bee is sitting in one of the three "waiting for
## work" states (NURSE_IDLE, BUILD_IDLE, MINE_IDLE -- interchangeable
## now, since this is the only thing any of them do). Tries the bee's
## real role first; only if that genuinely has nothing on offer does it
## try the secondary role instead. Because the fallback states above all
## route failures back to one of these same three idle states, a bee
## doing secondary work re-checks its primary role again the moment that
## task ends -- it never gets stuck permanently "being" its secondary.
func _idle_dispatch() -> void:
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
			target_cell = brood
			state = State.TO_BROOD
			return true

		Role.BUILDER:
			# Builders have two jobs, in priority order: shift resources
			# out of cells the player has re-designated, then draw new
			# comb -- a manually placed site first, if one's pending.
			var source = hive.find_cell_needing_eviction()
			if source:
				target_cell = source
				state = State.TO_HAUL_SOURCE
				return true

			var site: Node2D = null
			if has_manual_build_target:
				# Consumed either way -- if the tile turns out to be
				# occupied or solid, falling through to automatic
				# placement beats retrying the same bad hex forever.
				site = hive.create_cell_site_at(manual_build_hex)
				has_manual_build_target = false
			if site == null:
				site = hive.find_unfinished_cell()
			if site == null:
				site = hive.create_next_cell_site()
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
			var block = hive.find_marked_block(position)
			if block == null and automine:
				block = hive.find_nearest_edge_block()
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
		haul_target = hive.find_cell_for(moving_type, target_cell)
		if haul_target == null:
			# nowhere to put it -- it's discarded. The player was warned
			# about this when they re-designated the cell.
			current_load = 0.0
			current_load_type = ""
			hive.announce()
			state = State.BUILD_IDLE
			return
		state = State.TO_HAUL_TARGET

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
	if pollen_eaten >= GameConfig.egg_pollen_cost:
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
			target_cell.start_brood()
			pollen_eaten -= GameConfig.egg_pollen_cost
		_release_cell_slot()
		target_cell = null
		state = State.SEEK_POLLEN

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
func set_manual_build_target(hex: Vector2i) -> void:
	manual_build_hex = hex
	has_manual_build_target = true

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
	_release_everything()

	role = new_role
	visible = true
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
	match role:
		Role.NURSERY:
			return "U"
		Role.BUILDER:
			return "B"
		Role.EGG_LAYER:
			return "E"
		Role.IDLE:
			return "-"
		Role.MINER:
			return "M"
		Role.HONEY_MAKER:
			return "H"
		_:
			return "N" if resource_type == "nectar" else "P"

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
		State.TO_HAUL_SOURCE:
			return "going to clear a reassigned cell"
		State.TO_HAUL_TARGET:
			return "moving %s to another cell" % current_load_type
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
		return " (backup role %s also has nothing right now)" % _role_short_name(secondary_role)
	return ""

func role_name_text() -> String:
	var base: String
	match role:
		Role.NURSERY:
			base = "Nursery"
		Role.BUILDER:
			base = "Builder"
		Role.EGG_LAYER:
			base = "Egg layer"
		Role.IDLE:
			base = "Idle"
		Role.MINER:
			base = "Miner (automine on)" if automine else "Miner"
		Role.HONEY_MAKER:
			base = "Honey maker"
		_:
			base = "Forager (%s)" % resource_type
			if preferred_species != "":
				base += " -- %s only" % preferred_species
	if secondary_role != -1 and secondary_role != role:
		base += " -- backup: %s" % _role_short_name(secondary_role)
	return base

func _role_short_name(r: int) -> String:
	match r:
		Role.NURSERY:
			return "Nursery"
		Role.BUILDER:
			return "Builder"
		Role.MINER:
			return "Miner"
		Role.HONEY_MAKER:
			return "Honey maker"
		Role.EGG_LAYER:
			return "Egg layer"
		Role.IDLE:
			return "Idle"
		_:
			return "Forager"

## What this bee is carrying, for the info panel.
func carrying_text() -> String:
	if role == Role.MINER:
		return "Carrying: %d dirt (of %d)" % [int(dirt_load), int(GameConfig.miner_dirt_capacity)]
	if honey_load > 0.0:
		return "Carrying: %d units of honey mix" % int(ceil(honey_load))
	if current_load <= 0.0 or current_load_type == "":
		return "Carrying: nothing"
	return "Carrying: %d %s (of %d)" % [int(current_load), current_load_type, int(_max_capacity())]

## Age and remaining life now live in the selection panel rather than
## floating over every bee, which was a lot of numbers to read at once.
func age_days() -> float:
	return age_seconds / max(0.001, GameConfig.seconds_per_day)

func days_remaining() -> float:
	return max(0.0, GameConfig.bee_lifespan_days - age_days())

func _update_label() -> void:
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

## The meadow has no real pathfinding -- trees and raised areas are rare
## enough that a full navmesh would be overkill. Instead: if the straight
## line to `target` would pass too close to an obstacle, aim at a point
## that clears it by a bee-width margin instead. Recomputed fresh every
## frame from the bee's current position, so as it curves round the
## obstacle the aim point slides along with it, and once the line is
## clear it heads straight at the real target again.
func _avoid_obstacles(target: Vector2) -> Vector2:
	var to_target: Vector2 = target - position
	var span: float = to_target.length()
	if span < 1.0:
		return target
	var direction: Vector2 = to_target / span

	for obstacle in get_tree().get_nodes_in_group("obstacles"):
		if not is_instance_valid(obstacle):
			continue
		var to_obstacle: Vector2 = obstacle.position - position
		var along: float = clamp(to_obstacle.dot(direction), 0.0, span)
		var closest_point: Vector2 = position + direction * along
		var clearance: float = obstacle.radius + 16.0
		if closest_point.distance_to(obstacle.position) >= clearance:
			continue
		# which side to swing round -- whichever side of the line the
		# obstacle centre is already on, so the bee doesn't cut across it
		var side_sign: float = signf(direction.cross(to_obstacle))
		var perpendicular: Vector2 = direction.rotated(PI / 2.0)
		return obstacle.position - perpendicular * clearance * (1.0 if side_sign >= 0.0 else -1.0)

	return target

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
	for obstacle in get_tree().get_nodes_in_group("obstacles"):
		if not is_instance_valid(obstacle) or not obstacle.solid:
			continue
		var edge: float = obstacle.radius + 8.0
		var offset: Vector2 = result - obstacle.position
		var distance: float = offset.length()
		if distance >= edge:
			continue
		if distance < 0.01:
			# exactly on the centre (shouldn't happen) -- shove it out in
			# an arbitrary but consistent direction rather than dividing
			# by zero
			offset = Vector2.RIGHT
			distance = 1.0
		result = obstacle.position + offset / distance * edge
	return result

## Outdoors a bee flies straight. Inside the hive it walks a route over
## open tiles, because soil is solid. The route is recalculated only
## when the destination changes, not every frame.
func _move_towards(target: Vector2, delta: float) -> void:
	var step: float = speed * _terrain_speed_factor() * delta

	if not _is_inside_hive():
		var wanted: Vector2 = position.move_toward(_avoid_obstacles(target), step)
		position = _block_obstacles(wanted)
		return

	if target.distance_to(path_goal) > 6.0 or path_points.is_empty():
		path_goal = target
		path_points = hive.path_between(position, target)
		path_index = 0

	if path_points.is_empty():
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
