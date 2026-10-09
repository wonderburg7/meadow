extends RefCounted
## Life support, eating and the stall watchdog, split out of bee.gd --
## see BEE_SPLIT_PLAN.md.
##
## Usage: const BeeSurvival = preload("res://scripts/bee_survival.gd")
##        BeeSurvival.age_and_burn(bee, delta)

const BeeEnums = preload("res://scripts/bee_enums.gd")
const Role = BeeEnums.Role
const State = BeeEnums.State
const BeeMovement = preload("res://scripts/bee_movement.gd")
const BeeForaging = preload("res://scripts/bee_foraging.gd")
const BeeStatus = preload("res://scripts/bee_status.gd")
const ProblemMessages = preload("res://scripts/problem_messages.gd")

static func age_and_burn(bee: Node2D, delta: float) -> void:
	bee.age_seconds += delta

	# Only ever set on the queen during Challenge 1 -- see the field
	# comment on bee.gd. Keeping her topped up here, rather than merely
	# skipping the death check below, means she also never goes sluggish
	# or gets stuck unable to fly while immune.
	if bee.energy_immune:
		bee.energy = GameConfig.energy_capacity
		return

	# A clustered, near-dormant winter colony burns far less than an
	# active one -- this is the number the winter forecast (see
	# year_winter.gd::_winter_forecast) already promises the player, so
	# it has to actually apply here or the forecast is a lie: without
	# it, a colony that met the forecast's stated requirement could
	# still starve for real, at roughly six times the rate it was told
	# to plan for.
	var winter_factor: float = GameConfig.winter_burn_factor if Session.winter_here else 1.0

	# A gyne is a bigger animal and costs more to run, whatever she's
	# doing -- part of why raising one is a real commitment.
	var upkeep: float = GameConfig.energy_burn_rate * winter_factor
	if bee.is_gyne:
		upkeep *= GameConfig.gyne_energy_factor
	bee.energy -= upkeep * delta

	# Flight is paid for separately from simply being alive, so a long
	# trip out to a distant patch actually costs something. Rain makes it
	# worse: a wet bee carries the water as dead weight. Foragers don't
	# fly at all once winter_here is true (see Season.foraging_stopped),
	# so winter_factor is applied here only for symmetry -- a bee still
	# mid-flight the instant winter starts shouldn't be paying the full
	# summer rate for the few remaining seconds of that trip.
	if is_flying(bee):
		var flight: float = GameConfig.flight_energy_burn * winter_factor
		if bee.is_gyne:
			flight *= GameConfig.gyne_energy_factor
		flight *= lerpf(1.0, GameConfig.rain_flight_burn_factor, Session.rain_intensity)
		bee.energy -= flight * delta

	# Building costs extra: bees make wax from the sugar they've eaten,
	# so expansion is paid for in energy rather than a wax stockpile.
	if bee.state == State.BUILDING:
		bee.energy -= GameConfig.build_energy_burn * delta

	sip_from_crop(bee, delta)
	check_critical_recall(bee)

	# Death is checked here, at the end of the one function every bee runs
	# every frame.
	#
	# It used to sit at the bottom of _sip_from_crop, which returns early
	# for any bee that is indoors or not carrying nectar -- so in practice
	# only an outdoor nectar forager could ever die of starvation. Everyone
	# else burned straight past zero into the negative and stayed alive
	# there, and if such a bee later reached the comb it drank the debt
	# back out of the stores. That is the energy leak.
	if bee.energy <= 0.0:
		bee.energy = 0.0
		die(bee, "starvation")
		return

	# The queen doesn't die of old age -- losing her would silently end
	# the colony, and there's no succession yet. She can still starve.
	if not bee.is_queen and bee.age_seconds >= lifespan_seconds(bee):
		die(bee, "old age")


## How long this bee lives. Shortened by disease, which is most of what
## makes pathogen pressure hurt: the colony doesn't visibly sicken, it
## just quietly stops replacing itself fast enough.
static func lifespan_seconds(bee: Node2D) -> float:
	var base: float = GameConfig.bee_lifespan_days * GameConfig.seconds_per_day
	if bee.world != null and is_instance_valid(bee.world) and bee.world.season != null:
		base *= bee.world.season.lifespan_factor()
	return max(GameConfig.seconds_per_day, base)


## Out in the meadow and actually moving under its own power.
static func is_flying(bee: Node2D) -> bool:
	if bee._is_inside_hive():
		return false
	match bee.state:
		State.SEEK_FLOWER, State.TO_FLOWER, State.TO_HIVE, State.MOVE_TO_POINT, State.SEARCHING:
			return true
	return false


## A nectar forager doesn't have to land to refuel: it can metabolise
## what's already in its crop. That comes straight off the delivery,
## though, so a bee doing this often is one that's ranging too far for
## what the patch is paying.
static func sip_from_crop(bee: Node2D, delta: float) -> void:
	if bee._is_inside_hive() or bee.current_load_type != "nectar" or bee.current_load <= 0.0:
		return
	if bee.energy > GameConfig.energy_capacity * GameConfig.crop_drink_threshold:
		return
	var wanted: float = min(GameConfig.nectar_drink_rate * delta, GameConfig.energy_capacity - bee.energy)
	var taken: float = min(wanted, bee.current_load)
	bee.current_load -= taken
	bee.energy += taken
	if bee.current_load <= 0.001:
		bee.current_load = 0.0
		bee.current_load_type = ""

	# Bees used to top themselves up invisibly from wherever they stood,
	# which made a forager's deposit look far smaller than the load it
	# carried in -- it was quietly eating most of it straight back out of
	# the cell it had just filled. Eating is now a real trip to a real
	# cell; see _should_go_and_eat and _feed_self.


## A bee still out hunting (nothing found yet, or flying to a candidate
## she hasn't reached) has no other self-rescue: sip_from_crop only helps
## once she is carrying nectar, and drink_at_flower only helps once she
## has actually reached one. When the calculated return reserve is no longer
## available, give up the search and fly home instead -- the same "go home
## empty" transition search_for_flower already uses when it runs out of
## meadow to check.
static func check_critical_recall(bee: Node2D) -> void:
	if bee._is_inside_hive() or bee.role != Role.FORAGER:
		return
	if bee.current_load_type == "nectar" and bee.current_load > 0.0:
		return          # sip_from_crop is already keeping her topped up
	if not (bee.state in [State.SEEK_FLOWER, State.SEARCHING, State.TO_FLOWER, State.MOVE_TO_POINT]):
		return
	var required: float = estimated_return_energy(bee)
	if bee.energy > required:
		return
	if bee.state == State.TO_FLOWER and bee.current_flower and is_instance_valid(bee.current_flower):
		bee.current_flower.release(bee)
		bee.current_flower = null
	bee.emergency_return_reason = "reserve_below_estimated_return"
	DiagnosticLog.log_forager_return(bee, "started", required)
	bee.state = State.TO_HIVE


## Conservative, monotonic reserve: straight-line distance is inflated for
## obstacle detours, then paid at the actual flight/upkeep rate plus a
## config-owned safety margin.  Carrying nectar remains handled by the crop
## sip above, so an already-fuelled bee is not needlessly recalled.
static func estimated_return_energy(bee: Node2D) -> float:
	var distance: float = bee.position.distance_to(bee.hive.position) * GameConfig.forager_return_route_factor
	var seconds: float = distance / max(1.0, bee.speed)
	var flight: float = GameConfig.flight_energy_burn * lerpf(1.0, GameConfig.rain_flight_burn_factor, Session.rain_intensity)
	if bee.is_gyne:
		flight *= GameConfig.gyne_energy_factor
	var upkeep: float = GameConfig.energy_burn_rate * (GameConfig.gyne_energy_factor if bee.is_gyne else 1.0)
	return seconds * (flight + upkeep) + GameConfig.energy_capacity * GameConfig.forager_return_safety_margin


## True when this bee should break off and go and eat. Only inside the
## hive: there is nothing to eat out in the meadow, which is why a
## forager that keeps coming home empty still eventually starves.
static func should_go_and_eat(bee: Node2D) -> bool:
	if bee.state == State.TO_FEED_CELL or bee.state == State.FEEDING:
		return false
	# Don't break off partway through a short action where the bee is
	# holding something not yet committed anywhere -- a mouthful of
	# nectar being chewed into honey, or a load of brood food being
	# picked up. It would simply be lost.
	if bee.state == State.CHEWING or bee.state == State.LOADING_FOOD or bee.state == State.MAKING_JELLY:
		return false
	if not bee._is_inside_hive():
		return false
	if bee.energy > GameConfig.energy_capacity * GameConfig.hunger_threshold:
		return false
	return bee.hive.find_food_cell() != null


static func begin_feeding_self(bee: Node2D) -> void:
	BeeForaging.release_cell_slot(bee)
	bee.target_cell = bee.hive.find_food_cell()
	bee.state = State.TO_FEED_CELL


static func go_to_feed_cell(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or not is_edible(bee, bee.target_cell):
		bee.target_cell = bee.hive.find_food_cell()
		if bee.target_cell == null:
			after_feeding(bee)
		return

	var approach := BeeForaging.approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		# all six walls in use -- eat somewhere else rather than queueing
		bee.target_cell = bee.hive.find_food_cell(bee.target_cell)
		if bee.target_cell == null:
			after_feeding(bee)
		return
	if approach == 1:
		bee.state = State.FEEDING


static func is_edible(_bee: Node2D, cell: Node2D) -> bool:
	if cell.amount <= 0.0:
		return false
	if cell.content_type == "nectar":
		return true
	return cell.is_ripe_honey()


## Feeding drains the cell gradually, so you can watch a bee empty it.
## Honey gives `honey_energy_factor` times the energy per unit, so a bee
## eating honey takes far less out of the comb for the same refill.
static func feed_self(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or not is_edible(bee, bee.target_cell):
		bee.target_cell = bee.hive.find_food_cell()
		bee.state = State.TO_FEED_CELL if bee.target_cell != null else bee.state
		if bee.target_cell == null:
			after_feeding(bee)
		return

	var room: float = GameConfig.energy_capacity - bee.energy
	if room <= 0.5:
		after_feeding(bee)
		return

	var per_unit: float = GameConfig.honey_energy_factor if bee.target_cell.content_type == "honey" else 1.0
	var energy_wanted: float = min(GameConfig.bee_eat_rate * delta, room)
	var taken: float = bee.target_cell.take_resource(bee.target_cell.content_type, energy_wanted / per_unit)
	bee.energy += taken * per_unit
	bee.hive.announce()
	if taken <= 0.0:
		after_feeding(bee)


## Back to work. A forager still carrying a load finishes delivering it;
## one that has already unloaded heads back out; indoor bees pick their
## own job up again.
static func after_feeding(bee: Node2D) -> void:
	BeeForaging.release_cell_slot(bee)
	bee.target_cell = null
	if BeeStatus.works_indoors(bee) or bee.role == Role.IDLE:
		# indoor roles pick their own job back up; sending one down the
		# forager's deposit path would have it filing away whatever it
		# was carrying for its own work. An Idle bee goes back to idling
		# where she ate rather than walking out to starve
		bee.state = bee._default_state_for_role()
	elif bee.current_load > 0.0:
		bee.state = State.IN_HIVE_TO_CELL
	else:
		bee.state = State.IN_HIVE_TO_EXIT



## A backstop, not the fix. Steering round obstacles is handled properly
## in _avoid_obstacles; this catches anything that still manages to pin a
## bee -- an unreachable flower, a corner it cannot steer out of -- and
## abandons the errand rather than leaving it hovering until the player
## notices and moves it by hand.
static func watch_for_stalls(bee: Node2D, delta: float) -> void:
	var goal: Vector2 = current_goal(bee)
	if (bee._is_inside_hive() and bee.state != State.TO_BUILD_SITE) or goal.x == INF:
		bee._reset_stall_watch()
		return

	# Measured as distance still to go rather than distance moved, so it
	# catches a bee shuffling back and forth between two obstacles as
	# well as one standing perfectly still. Either way it isn't getting
	# any closer, which is the thing that matters.
	var remaining: float = bee.position.distance_to(goal)
	if bee.stall_best_distance == INF or remaining < bee.stall_best_distance - 2.0:
		bee.stall_best_distance = remaining
		bee.stall_timer = 0.0
		return

	bee.stall_timer += delta
	if bee.stall_timer < bee.STALL_SECONDS:
		return
	if bee.state == State.TO_BUILD_SITE:
		# A build site is normally created only on walkable ground. If a
		# topology/path defect nevertheless leaves it unreachable, make the
		# abandonment explicit and return this worker to selection instead of
		# shoving it to a random point or allowing it to wait forever.
		DiagnosticLog.log_build_target(bee, bee.target_cell, "released", "no_progress_to_build_approach", "stalled", "stalled")
		if bee.target_cell != null and is_instance_valid(bee.target_cell):
			bee.target_cell.release_builder(bee)
		bee.target_cell = null
		bee.state = State.BUILD_IDLE
		bee._reset_stall_watch()
		return
	# Logged before recovery touches anything -- position/goal/state at the
	# exact moment the watchdog judged this bee stuck, so a run where
	# scouting collapses (see foraging_features_on_test.json) can show
	# whether the backstop is firing a lot (a real steering dead end) or
	# not at all (the bee isn't actually reaching this check).
	DiagnosticLog.log_stall_recovery(bee, goal)
	bee._reset_stall_watch()

	# The guarantee the steering doesn't have to provide: a bee that isn't
	# getting closer to where it is going gets moved, so no geometry bug
	# can pin one indefinitely.
	#
	# If it was going round something, try the other way rather than
	# forgetting the obstacle entirely -- the usual reason a detour stops
	# paying is that it committed to the long way round a wall. Flipping
	# keeps the commitment (so it doesn't dither) but reverses it.
	if bee.skirt_obstacle != null and is_instance_valid(bee.skirt_obstacle):
		bee.skirt_turn = -bee.skirt_turn
	else:
		bee.skirt_obstacle = null
	escape_nearest_obstacle(bee)

	if bee.state == State.TO_FLOWER:
		BeeForaging.reject_flower(bee)          # give up on this one and pick another
	elif bee.state == State.MOVE_TO_POINT:
		bee.state = bee._default_state_for_role()
	elif bee.state == State.SEARCHING:
		# Same reasoning as TO_FLOWER's reject_flower above: a waypoint the
		# escape shove couldn't clear is abandoned, not retried forever.
		BeeForaging.advance_search_waypoint(bee)


## Pushes this bee clear of whatever solid thing it is closest to. A last
## resort, used only when the steering has demonstrably failed.
static func escape_nearest_obstacle(bee: Node2D) -> void:
	var nearest: Node2D = null
	var nearest_gap := INF
	for obstacle in BeeMovement.obstacles(bee):
		if not is_instance_valid(obstacle) or not obstacle.solid:
			continue
		var gap: float = bee.position.distance_to(obstacle.position) - obstacle.radius
		# Only things the bee is actually up against. Without this it
		# could pick a huge plateau on the far side of the meadow -- its
		# radius makes the gap small even at a distance -- and fling the
		# bee across the map to "escape" something it was nowhere near.
		if gap > bee.ESCAPE_RANGE:
			continue
		if gap < nearest_gap:
			nearest_gap = gap
			nearest = obstacle

	if nearest == null:
		# Not caught on anything: the hold-up is elsewhere. A short hop is
		# enough to break any symmetry that might be causing it.
		bee.position += Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0))
		return

	var outward: Vector2 = bee.position - nearest.position
	if outward.length() < 0.01:
		outward = Vector2.RIGHT
	bee.position = nearest.position + outward.normalized() * (nearest.radius + 40.0)


## Where the bee is currently trying to get to, in its own parent's
## coordinates. INF means "not travelling anywhere in particular".
static func current_goal(bee: Node2D) -> Vector2:
	match bee.state:
		State.TO_FLOWER:
			return bee.current_flower.position if (bee.current_flower and is_instance_valid(bee.current_flower)) else Vector2(INF, INF)
		State.TO_HIVE:
			return bee.hive.position
		State.MOVE_TO_POINT:
			return bee.move_target
		State.TO_BUILD_SITE:
			if bee.target_cell != null and is_instance_valid(bee.target_cell):
				return bee.target_cell.slot_position(0)
			return Vector2(INF, INF)
		State.SEARCHING:
			return bee.search_waypoint
	return Vector2(INF, INF)


static func die(bee: Node2D, cause: String) -> void:
	if bee.is_dying:
		return          # queue_free is deferred, so guard against a second pass
	bee.is_dying = true
	bee.death_cause = cause
	if bee.current_flower:
		bee.current_flower.release(bee)
	if bee.target_cell and is_instance_valid(bee.target_cell):
		bee.target_cell.release_builder(bee)
	if bee.target_block and is_instance_valid(bee.target_block):
		bee.target_block.release_miner(bee)
	BeeForaging.release_cell_slot(bee)
	DiagnosticLog.log_death(bee)
	# T2-4b: a bee who dies inside the hive leaves her body where she fell;
	# one who dies in the meadow leaves none. Winter's dead who were outside
	# are laid inside by season.gd before they reach here.
	if bee.hive != null and is_instance_valid(bee.hive) and bee._is_inside_hive():
		bee.hive.add_body(bee.position, Session.sim_time)
	# A mark is left where it fell, so losses show up in the place they
	# happened rather than only as a number going down.
	if bee.world != null and is_instance_valid(bee.world):
		# bee_died's one listener (main.gd::_on_bee_died) does mark_death()
		# and invalidate_population() -- see that function's own comment for
		# why the order between them doesn't matter (queue_free() below is
		# deferred, so this bee is still in the "bees" group for the rest of
		# this frame; harmless, since the population cache is only read
		# later, on year_winter.gd's 1-second tick). Epitaph announcement
		# stays a direct call: it's bee-domain logic (throttled by
		# GameConfig.epitaph_min_gap), not a cross-system reach-through.
		bee.world.bee_died.emit(bee)
		_announce_death(bee)
	bee.queue_free()


## A one-line epitaph via the same toast channel as any other warning,
## throttled by GameConfig.epitaph_min_gap (arbitrated at the channel, see
## UI-Q-1 in plans/now/ui.md) so a bad night in winter, or a mass
## starvation event, can't fire a dozen of these back to back -- see
## BEE_INDIVIDUALITY_PLAN.md section 6. If more bees die within the gap,
## their epitaphs are skipped rather than queued: the moment matters more
## than completeness.
static func _announce_death(bee: Node2D) -> void:
	bee.world.hud.show_warning(
		ProblemMessages.epitaph(bee.bee_name, bee.death_cause, bee.bee_fact),
		"epitaph", GameConfig.epitaph_min_gap, bee.world.hud.SEVERITY_DANGER
	)
