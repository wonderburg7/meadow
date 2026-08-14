extends RefCounted
## Foraging, plus entering and leaving the hive, split out of bee.gd --
## see BEE_SPLIT_PLAN.md.
##
## Usage: const BeeForaging = preload("res://scripts/bee_foraging.gd")
##        BeeForaging.seek_flower(bee)

const BeeEnums = preload("res://scripts/bee_enums.gd")
const Role = BeeEnums.Role
const State = BeeEnums.State
const BeeMovement = preload("res://scripts/bee_movement.gd")
const BeeStatus = preload("res://scripts/bee_status.gd")

static func max_capacity(bee: Node2D) -> float:
	return bee.nectar_stomach_capacity if bee.resource_type == "nectar" else bee.pollen_stomach_capacity


static func collection_rate(bee: Node2D) -> float:
	return bee.nectar_collection_rate if bee.resource_type == "nectar" else bee.pollen_collection_rate


static func seek_flower(bee: Node2D) -> void:
	# Heavy rain: a trip costs more in wet-wing flight than the watered
	# down nectar brings back, so there is no point going out. Wait it out
	# at the hive instead.
	if BeeStatus.grounded(bee):
		bee.state = State.TO_HIVE
		return

	# First pass respects this bee's own memory of what it has drained,
	# and (if the marker option is on) other bees' scent marks too.
	var best := nearest_flower(bee, true)
	if best == null:
		# Nothing passes the filters. Rather than hovering over a spent
		# flower, relax the memory and take the best of what's left.
		best = nearest_flower(bee, false)

	if best == null:
		# Genuinely nothing to visit -- go home rather than sitting on an
		# empty flower, which looked like the bee was stuck.
		bee.state = State.TO_HIVE
		return

	best.occupied_by = bee
	bee.current_flower = best
	bee.state = State.TO_FLOWER


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
static func nearest_flower(bee: Node2D, strict: bool) -> Node2D:
	var accept := func(f) -> bool:
		if f.occupied_by != null:
			return false
		if f.get_available(bee.resource_type) <= 0.0:
			return false
		if bee.preferred_species != "" and f.species_name != bee.preferred_species:
			return false
		if strict:
			if bee.flower_cooldowns.has(f) and Session.sim_time < bee.flower_cooldowns[f]:
				return false
			# Tarsal secretion: bees leave a scent mark on flowers they
			# land on, and other bees avoid a recently marked flower
			# rather than wasting a trip on one already stripped.
			if GameConfig.tarsal_markers_on and f.is_marked(bee):
				return false
		return true

	var grid = flower_grid(bee)
	if grid != null:
		var found = grid.nearest(bee.position, GameConfig.forage_search_radius, accept)
		if found != null:
			return found

	# Nothing close enough, or no grid yet. Fall back to the honest scan.
	var best: Node2D = null
	var best_dist := INF
	for f in bee.get_tree().get_nodes_in_group("flowers"):
		if not is_instance_valid(f) or not accept.call(f):
			continue
		var d := bee.position.distance_to(f.position)
		if d < best_dist:
			best_dist = d
			best = f
	return best


static func flower_grid(bee: Node2D):
	if bee.world != null and is_instance_valid(bee.world):
		return bee.world.flower_grid
	return null

## Landing on a flower doesn't commit a bee to feeding from it. A short
## inspection comes first -- long enough to notice things like a fresh
## tarsal mark from another bee, or that it's nearly empty -- and only
## then does the bee decide whether to actually feed or move on. This
## also catches a flower that got marked by someone else mid-flight,
## after this bee had already committed to it.
const INSPECTION_TIME := 1.5
const REJECTED_AVOID_SECONDS := 15.0


static func start_inspecting(bee: Node2D) -> void:
	bee.timer = INSPECTION_TIME
	bee.state = State.INSPECTING


static func inspect(bee: Node2D, delta: float) -> void:
	if bee.current_flower == null or not is_instance_valid(bee.current_flower):
		bee.current_flower = null
		bee.state = State.SEEK_FLOWER
		return
	bee.timer -= delta
	if bee.timer > 0.0:
		return
	# Refuel before working. Every forager drinks nectar, whatever it came
	# for -- a pollen forager still needs the sugar, it just isn't what
	# it's carrying home.
	if needs_a_drink(bee) and bee.current_flower.get_available("nectar") > GameConfig.min_worthwhile_amount:
		bee.state = State.DRINKING
		return

	if worth_feeding(bee, bee.current_flower):
		start_collecting(bee)
	else:
		reject_flower(bee)


static func needs_a_drink(bee: Node2D) -> bool:
	return bee.energy < GameConfig.energy_capacity * GameConfig.forager_drink_threshold


## Drinking straight from the flower, into the bee rather than into its
## load. This is what gives a forager range: it doesn't have to fly home
## to eat, so how far it can work depends on what's flowering out there
## rather than on the distance back to the comb.
static func drink_at_flower(bee: Node2D, delta: float) -> void:
	if bee.current_flower == null or not is_instance_valid(bee.current_flower):
		bee.current_flower = null
		bee.state = State.SEEK_FLOWER
		return

	var room: float = GameConfig.energy_capacity - bee.energy
	var wanted: float = min(GameConfig.nectar_drink_rate * delta, room)
	var drunk: float = bee.current_flower.collect("nectar", wanted)
	# Rain waters the nectar down, so a wet flower gives back less than
	# the same volume would on a dry day.
	bee.energy += drunk * nectar_strength(bee)

	if room <= 0.5 or drunk <= 0.0 or bee.current_flower.get_available("nectar") < GameConfig.min_worthwhile_amount:
		# topped up (or the flower is dry) -- get on with the job
		if worth_feeding(bee, bee.current_flower):
			start_collecting(bee)
		else:
			reject_flower(bee)


## How much a unit of nectar is actually worth right now. Rain dilutes
## what's standing in an open flower.
static func nectar_strength(bee: Node2D) -> float:
	return lerpf(1.0, 1.0 - GameConfig.rain_nectar_dilution, Session.rain_intensity)


## Rained off. Waiting it out *inside* the hive rather than at the door:
## a bee sheltering out in the meadow couldn't reach the comb to eat, and
## would have walked itself in and straight back out again every few
## seconds as the exit and the rain check argued with each other.
static func shelter(bee: Node2D, _delta: float) -> void:
	if not BeeStatus.grounded(bee):
		bee.state = State.IN_HIVE_TO_EXIT if bee._is_inside_hive() else State.SEEK_FLOWER


static func worth_feeding(bee: Node2D, f: Node2D) -> bool:
	if f.get_available(bee.resource_type) < GameConfig.min_worthwhile_amount:
		return false
	if GameConfig.tarsal_markers_on and f.is_marked(bee):
		return false
	return true


## Doesn't set a full recharge-length cooldown -- this bee didn't drain
## anything, so there's no reason to wait for a refill. A short "don't
## bother rechecking immediately" pause is enough.
static func reject_flower(bee: Node2D) -> void:
	if bee.current_flower and is_instance_valid(bee.current_flower):
		bee.flower_cooldowns[bee.current_flower] = Session.sim_time + REJECTED_AVOID_SECONDS
		bee.current_flower.release(bee)
	bee.current_flower = null
	bee.state = State.SEEK_FLOWER


static func start_collecting(bee: Node2D) -> void:
	bee.current_flower.leave_marker(bee)
	# `timer` now counts down the handling phase only -- finding the
	# nectary after landing. Gathering itself happens gradually, in
	# _collect(), so the flower's readout ticks down while you watch.
	bee.timer = bee.flower_handling_time
	bee.state = State.COLLECTING


## Draws resource out of the flower a little each frame. Previously the
## whole load was removed in one lump when the timer expired, which made
## the flower's numbers look frozen until the bee left.
static func collect(bee: Node2D, delta: float) -> void:
	if bee.current_flower == null or not is_instance_valid(bee.current_flower):
		bee.current_flower = null
		bee.state = State.SEEK_FLOWER
		return

	if bee.timer > 0.0:
		bee.timer -= delta
		return   # still handling the flower, nothing gathered yet

	# A bee carries one resource at a time. If it still has a part-load of
	# something else after a focus change, it delivers that first rather
	# than mixing the two in its stomach.
	if bee.current_load > 0.0 and bee.current_load_type != "" and bee.current_load_type != bee.resource_type:
		finish_collecting(bee)
		bee.state = State.TO_HIVE
		return

	var space_left: float = max_capacity(bee) - bee.current_load
	if space_left <= 0.0:
		finish_collecting(bee)
		return

	# A drained flower still trickles back a little every frame as it
	# recharges. Waiting for the take to hit exactly zero therefore never
	# happened -- the bee sat there sipping the trickle forever. Instead
	# it leaves as soon as there isn't a worthwhile amount left.
	if bee.current_flower.get_available(bee.resource_type) < GameConfig.min_worthwhile_amount:
		finish_collecting(bee)
		return

	var wanted: float = min(collection_rate(bee) * delta, space_left)
	var taken: float = bee.current_flower.collect(bee.resource_type, wanted)
	# Nectar standing in an open flower is watered down by rain, so a wet
	# day's foraging brings home less than the same volume would dry.
	if bee.resource_type == "nectar":
		taken *= nectar_strength(bee)
	bee.current_load += taken
	if taken > 0.0:
		bee.current_load_type = bee.resource_type
		bee.hive.record_collection(bee.resource_type, taken)

	if bee.current_load >= max_capacity(bee):
		finish_collecting(bee)


static func finish_collecting(bee: Node2D) -> void:
	if bee.current_flower and is_instance_valid(bee.current_flower):
		# stay away until it's had time to fully recharge
		bee.flower_cooldowns[bee.current_flower] = Session.sim_time + bee.current_flower.seconds_until_full(bee.resource_type)
		bee.current_flower.release(bee)
	bee.current_flower = null
	bee.state = State.TO_HIVE if bee.current_load >= max_capacity(bee) else State.SEEK_FLOWER



## Foragers now physically walk into the hive view to deposit, rather
## than vanishing at the meadow marker. main.gd owns the reparenting
## because it owns both world roots and the entrance geometry.
static func enter_hive(bee: Node2D) -> void:
	if bee.world == null:
		# no world wired up (shouldn't happen) -- fall back to the old
		# behaviour so a bee never gets stuck at the door
		deposit_everything_remotely(bee)
		return
	bee.world.move_bee_into_hive(bee)
	bee.target_cell = null
	# A bee that came home because its job is now indoors (see set_role)
	# starts that job at the door rather than running the forager's
	# deposit-and-leave sequence.
	bee.state = bee._default_state_for_role() if BeeStatus.works_indoors(bee) else State.IN_HIVE_TO_CELL


## Walks to one of the six wall positions on `cell`, claiming it first,
## so no more than six bees ever work the same cell at once and none of
## them stand on top of each other. Returns:
##    1  arrived and in position
##    0  still on the way
##   -1  every wall is taken -- the caller should look for another cell
static func approach_cell(bee: Node2D, cell: Node2D, delta: float) -> int:
	if cell == null or not is_instance_valid(cell):
		return -1
	if bee.slot_cell != cell:
		release_cell_slot(bee)
		var index: int = cell.claim_slot(bee)
		if index < 0:
			return -1
		bee.cell_slot = index
		bee.slot_cell = cell
	var stand_point: Vector2 = cell.slot_position(bee.cell_slot)
	BeeMovement.move_towards(bee, stand_point, delta)
	return 1 if bee.position.distance_to(stand_point) < 6.0 else 0


static func release_cell_slot(bee: Node2D) -> void:
	if bee.slot_cell != null and is_instance_valid(bee.slot_cell):
		bee.slot_cell.release_slot(bee)
	bee.slot_cell = null
	bee.cell_slot = -1


static func go_to_deposit_cell(bee: Node2D, delta: float) -> void:
	if bee.current_load <= 0.0:
		# Nothing to deliver. Eating is handled separately now -- the
		# hunger check in _process will already have sent this bee to a
		# food cell if it needed one, and it runs whether the trip home
		# was a productive one or not.
		bee.state = State.IN_HIVE_TO_EXIT
		return

	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.space_for(bee.current_load_type) <= 0.0:
		bee.target_cell = bee.hive.find_cell_for(bee.current_load_type)
		if bee.target_cell == null:
			# comb is full -- the load is lost, which is the signal that
			# the hive needs more cells built
			bee.current_load = 0.0
			bee.current_load_type = ""
			bee.state = State.IN_HIVE_TO_EXIT
			return

	var approach := approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		# all six walls busy -- try somewhere else rather than queueing
		bee.target_cell = bee.hive.find_cell_for(bee.current_load_type, bee.target_cell)
		return
	if approach == 1:
		bee.timer = bee.deposit_time
		bee.state = State.DEPOSITING


static func finish_depositing(bee: Node2D) -> void:
	if bee.target_cell and is_instance_valid(bee.target_cell):
		var placed: float = bee.target_cell.add_resource(bee.current_load_type, bee.current_load)
		bee.current_load -= placed
		bee.hive.announce()
	release_cell_slot(bee)
	bee.target_cell = null

	# No refuelling here any more. A forager used to eat its fill the
	# instant it unloaded, taking most of the delivery straight back out
	# of the very cell it had just filled -- which is why a bee carrying
	# 50 nectar appeared to deposit a fraction of it. If it is hungry the
	# check in _process sends it to eat as a separate, visible trip.

	if bee.current_load > 0.0:
		bee.state = State.IN_HIVE_TO_CELL   # still carrying -- find another cell
		return

	bee.current_load_type = ""
	# The load is delivered, so a queued role change takes effect now --
	# this is the "finish depositing first" case.
	if bee._apply_pending_role():
		return
	bee.state = State.IN_HIVE_TO_EXIT


static func go_to_exit(bee: Node2D, delta: float) -> void:
	# No point walking out into weather that costs more to fly in than the
	# trip would bring back. Wait inside, where the food is.
	if bee.role == Role.FORAGER and BeeStatus.grounded(bee):
		bee.state = State.SHELTERING
		return

	var exit_point: Vector2 = bee.world.hive_entrance_inside() if bee.world else bee.position
	BeeMovement.move_towards(bee, exit_point, delta)
	if bee.position.distance_to(exit_point) < 8.0:
		if bee.world:
			bee.world.move_bee_out_of_hive(bee)
		# A forager with a start point set heads there first, every trip,
		# rather than just once -- that's what keeps it working the same
		# patch instead of drifting back to whatever's nearest the door.
		if bee.role == Role.FORAGER and bee.forage_start_point.x != INF:
			bee.move_target = bee.forage_start_point
			bee.state = State.MOVE_TO_POINT
		else:
			bee.state = bee._default_state_for_role()


## Fallback only -- deposits without the walk-in animation.
static func deposit_everything_remotely(bee: Node2D) -> void:
	bee.hive.deposit(bee.current_load_type, bee.current_load)
	bee.current_load = 0.0
	bee.current_load_type = ""
	bee.energy += bee.hive.take_energy(GameConfig.energy_capacity - bee.energy)
	bee.state = State.SEEK_FLOWER

