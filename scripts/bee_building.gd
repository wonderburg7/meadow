extends RefCounted
## Building and restocking, split out of bee.gd -- see BEE_SPLIT_PLAN.md.
##
## set_restock_targets/set_restock_sources/clear_restock/has_restock_orders
## stay as one-line wrappers on bee.gd, same pattern as
## clear_navigation_state after the bee_movement.gd split, because
## orders_zones.gd and hud.gd call them directly on a bee.
##
## Usage: const BeeBuilding = preload("res://scripts/bee_building.gd")
##        BeeBuilding.builder_build(bee, delta)

const BeeEnums = preload("res://scripts/bee_enums.gd")
const Role = BeeEnums.Role
const State = BeeEnums.State
const BeeMovement = preload("res://scripts/bee_movement.gd")
const BeeForaging = preload("res://scripts/bee_foraging.gd")

## Arrival distances for the builder's walks. Same values as before.
const STAND_REACH := 2.0
const CELL_REACH := 10.0
const HAUL_REACH := 10.0
const BODY_REACH := 8.0

## Catalogue finders all take one bee and return whether they started work.
## The cleaning row (actions.gd `comb_clean_cell`, gated on Cleaning) clears
## dead larvae first and, with none waiting, carries out the oldest body no
## other Comb worker is on (T2-4b). Both walk out the same waste exit.
static func find_cell_needing_cleaning(bee: Node2D) -> bool:
	var dead: Variant = bee.hive.find_cell_needing_cleaning()
	if dead != null:
		bee.target_body = null
		bee.target_cell = dead
		bee.state = State.TO_CLEAN_CELL
		return true
	var body: Node2D = bee.hive.find_body_to_clear()
	if body == null:
		return false
	bee.target_body = body
	body.claimant = bee
	bee.state = State.TO_CLEAN_CELL
	return true


static func find_cell_needing_eviction(bee: Node2D) -> bool:
	if bee.current_load > 0.0:
		return false   # still holding a load (GC-2): never lift over it
	var source: Variant = bee.hive.find_cell_needing_eviction()
	if source == null:
		return false
	bee.target_cell = source
	bee.state = State.TO_HAUL_SOURCE
	return true


static func create_cell_site_at(bee: Node2D) -> bool:
	var site: Node2D = null
	while site == null and bee._take_next_build_target():
		site = bee.hive.create_cell_site_at(bee.manual_build_hex)
		bee.has_manual_build_target = false
	if site == null:
		site = bee.hive.find_unfinished_cell()
	if site == null:
		return false
	return _start_building(bee, site)

## T2-2: the outward half -- starts a new site on the spiral. Gated by
## Automation in actions.gd; the marked half above never makes one.
static func create_next_cell_site_outward(bee: Node2D) -> bool:
	var site: Node2D = bee.hive.create_next_cell_site(bee.home_hex if bee.has_home_hex else Vector2i.ZERO)
	if site == null:
		return false
	return _start_building(bee, site)

static func _start_building(bee: Node2D, site: Node2D) -> bool:
	bee.target_cell = site
	bee.state = State.TO_BUILD_SITE
	DiagnosticLog.log_build_target(bee, site, "assigned", "build_work_selected", "pending", "not_checked")
	return true

static func builder_go_to_site(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.is_built:
		DiagnosticLog.log_build_target(bee, bee.target_cell, "released", "target_invalid_or_already_built", "not_attempted", "not_checked")
		if bee.target_cell != null and is_instance_valid(bee.target_cell):
			bee.target_cell.release_builder(bee)
		bee.target_cell = null
		bee.state = State.BUILD_IDLE
		return
	# Stands at one of the cell's six walls rather than its centre, so a
	# builder (the queen included, in Challenge 1) doesn't sit on top of
	# the comb she's forming and hide it from view while it's drawn.
	# The claimed wall remains stable for the whole approach: picking a
	# nearest wall every frame could flip between two equidistant walls and
	# make the bee waver. Builders now share the six-slot system with the
	# deposit/feed queues, which deliberately caps a build site at one bee
	# per wall.
	var slot_index: int = bee.target_cell.claim_slot(bee)
	if slot_index < 0:
		DiagnosticLog.log_build_target(bee, bee.target_cell, "released", "no_free_build_wall", "not_attempted", "not_checked")
		bee.target_cell.release_builder(bee)
		bee.target_cell = null
		bee.state = State.BUILD_IDLE
		return
	var stand_point: Vector2 = bee.target_cell.slot_position(slot_index)
	BeeMovement.move_towards(bee, stand_point, delta)
	if bee.path_points.is_empty():
		DiagnosticLog.log_build_target(bee, bee.target_cell, "released", "no_route_to_build_approach", "unreachable", "no_route")
		bee.target_cell.release_builder(bee)
		bee.target_cell = null
		bee.state = State.BUILD_IDLE
		return
	if bee.position.distance_to(stand_point) < STAND_REACH:
		bee.target_cell.claim_builder(bee)
		DiagnosticLog.log_build_target(bee, bee.target_cell, "claimed", "arrived_at_build_approach", "arrived", "route_ok")
		bee.state = State.BUILDING


## Each builder contributes its own `delta` to the cell every frame, so
## two builders on one cell finish it in half the wall-clock time. The
## cell keeps its progress if everyone wanders off, so building can be
## abandoned and picked up again later.
static func builder_build(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell):
		bee.state = bee._default_state_for_role()
		return
	# Another builder can finish the shared site earlier in this frame. This
	# bee still owns a wall until it releases it, even though there is no more
	# building work to do.
	if bee.target_cell.is_built:
		bee.target_cell.release_builder(bee)
		bee.target_cell = null
		bee.state = bee._default_state_for_role()
		return
	bee.target_cell.add_build_progress(delta)
	if bee.target_cell.is_built:
		DiagnosticLog.log_build_target(bee, bee.target_cell, "completed", "build_progress_finished", "arrived", "route_ok")
		bee.target_cell.release_builder(bee)
		bee.target_cell = null
		bee.state = bee._default_state_for_role()


static func builder_go_to_haul_source(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or not bee.target_cell.needs_eviction():
		bee.target_cell = null
		bee.state = State.BUILD_IDLE
		return
	BeeMovement.move_towards(bee, bee.target_cell.position, delta)
	if bee.position.distance_to(bee.target_cell.position) < CELL_REACH:
		var moving_type: String = bee.target_cell.content_type
		# NF-5: checked before the take, since a take that empties the
		# cell clears its stamp. Fermented nectar is never moved to
		# another cell, which would stamp it fresh.
		var was_fermented: bool = bee.target_cell.is_fermented()
		var lifted: float = bee.target_cell.take_resource(moving_type, bee.nectar_stomach_capacity)
		if lifted <= 0.0:
			bee.target_cell = null
			bee.state = State.BUILD_IDLE
			return
		bee.current_load = lifted
		bee.current_load_type = moving_type
		bee.hive.announce()

		# The player asked for this cell's contents to be thrown out, so
		# the builder carries them out through the entrance and dumps
		# them. Discarding used to happen the instant the button was
		# pressed, with the resource simply vanishing and no bee doing
		# any of the work.
		if bee.target_cell.evict_mode == "discard" or was_fermented:
			BeeForaging.release_cell_slot(bee)
			bee.state = State.TO_WASTE_EXIT
			return

		bee.haul_target = bee.hive.find_cell_for(moving_type, bee.target_cell)
		if bee.haul_target == null:
			# nowhere to put it -- it has to go outside after all, which
			# is what the player was warned about when they asked for the
			# cell to be emptied
			BeeForaging.release_cell_slot(bee)
			bee.state = State.TO_WASTE_EXIT
			return
		bee.state = State.TO_HAUL_TARGET



static func set_restock_targets(bee: Node2D, cells: Array, resource: String) -> void:
	bee.restock_targets = cells.duplicate()
	bee.restock_resource = resource


static func set_restock_sources(bee: Node2D, cells: Array, allowed: bool) -> void:
	if allowed:
		bee.restock_sources = cells.duplicate()
	else:
		bee.restock_blocked = cells.duplicate()


static func clear_restock(bee: Node2D) -> void:
	bee.restock_targets.clear()
	bee.restock_sources.clear()
	bee.restock_blocked.clear()
	bee.restock_resource = ""


## T3-2. Has the colony bought Restocking? Stocking orders, the Stocking mode
## and the restock job are all refused without it. True with no progression,
## as in a bare test hive (the convention Availability.mode_query keeps).
static func restocking_owned() -> bool:
	return Session.progression == null or Session.progression.is_owned("skill.colony.restocking")

static func has_restock_orders(bee: Node2D) -> bool:
	return not bee.restock_targets.is_empty() and bee.restock_resource != ""


## May this comb worker take `cell`'s contents to fill one of its targets?
static func may_draw_from(bee: Node2D, cell: Node2D) -> bool:
	if not is_instance_valid(cell) or bee.restock_targets.has(cell):
		return false          # never rob one target to fill another
	if not cell.can_withdraw():
		return false          # sealed
	if bee.restock_blocked.has(cell):
		return false
	# NF-4: with fermentation sense, fermented nectar stays where it is
	# (Dave, 9 Oct 2026); without it, a restock order still takes it.
	if bee.hive.avoids_as_sour(cell):
		return false
	if bee.restock_sources.is_empty():
		return true
	return bee.restock_sources.has(cell)


## Finds the emptiest target that still has room and a cell to fill it
## from. Emptiest first, so a set of cells fills evenly rather than one
## being topped up repeatedly while another sits empty.
static func find_restock_job(bee: Node2D) -> bool:
	if bee.current_load > 0.0:
		return false   # still holding a load (GC-2): never lift over it
	if not has_restock_orders(bee) or bee.hive == null:
		return false
	# T3-2: unowned, no comb worker stocks in any mode, Anything included.
	if not restocking_owned():
		return false

	var neediest: Node2D = null
	var least: float = INF
	for cell: Variant in bee.restock_targets:
		if not is_instance_valid(cell) or cell.space_for(bee.restock_resource) <= 0.0:
			continue
		# NF-4: with the sense, fresh nectar is never poured into a sour
		# target, where it would keep the old stamp and be sour at once.
		if bee.hive.avoids_as_sour(cell):
			continue
		var held: float = cell.amount if cell.content_type == bee.restock_resource else 0.0
		if held < least:
			least = held
			neediest = cell
	if neediest == null:
		return false

	var source: Node2D = null
	var most := 0.0
	var bucket: String = "ripe_honey" if bee.restock_resource == "honey" else bee.restock_resource
	for cell: Variant in bee.hive.cells_holding(bucket):
		if not may_draw_from(bee, cell) or cell.amount <= 0.0:
			continue
		# fullest first: emptying one cell completely beats leaving a
		# trail of nearly empty ones behind
		if cell.amount > most:
			most = cell.amount
			source = cell
	if source == null:
		return false

	bee.target_cell = source
	bee.haul_target = neediest
	bee.state = State.TO_RESTOCK_SOURCE
	return true


static func restock_go_to_source(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.content_type != bee.restock_resource:
		bee.target_cell = null
		bee.state = State.BUILD_IDLE
		return
	if bee.haul_target == null or not is_instance_valid(bee.haul_target):
		bee.target_cell = null
		bee.state = State.BUILD_IDLE
		return

	# NF-4: a source that fermented while she walked over is no longer one.
	if bee.hive.avoids_as_sour(bee.target_cell):
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = null
		bee.state = State.BUILD_IDLE
		return

	var approach := BeeForaging.approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		bee.target_cell = null
		bee.state = State.BUILD_IDLE
		return
	if approach != 1:
		return

	# Never lift more than the destination can hold, so nothing is left
	# stranded in the bee's crop with nowhere to put it.
	var room: float = bee.haul_target.space_for(bee.restock_resource)
	var wanted: float = min(bee.nectar_stomach_capacity, room)
	var lifted: float = bee.target_cell.take_resource(bee.restock_resource, wanted)
	BeeForaging.release_cell_slot(bee)
	if lifted <= 0.0:
		bee.target_cell = null
		bee.state = State.BUILD_IDLE
		return
	bee.current_load = lifted
	bee.current_load_type = bee.restock_resource
	bee.hive.announce()
	bee.target_cell = null
	bee.state = State.TO_RESTOCK_TARGET


static func restock_go_to_target(bee: Node2D, delta: float) -> void:
	if bee.haul_target == null or not is_instance_valid(bee.haul_target):
		# The destination has gone. Put the load somewhere sensible
		# rather than losing it.
		bee.haul_target = bee.hive.find_cell_for(bee.current_load_type)
		if bee.haul_target == null:
			bee.current_load = 0.0
			bee.current_load_type = ""
			bee.state = State.BUILD_IDLE
			return

	var approach := BeeForaging.approach_cell(bee, bee.haul_target, delta)
	if approach < 0:
		bee.haul_target = null
		bee.state = State.BUILD_IDLE
		return
	if approach != 1:
		return

	var placed: float = bee.haul_target.add_resource(bee.current_load_type, bee.current_load)
	bee.current_load -= placed
	bee.hive.announce()
	DiagnosticLog.count_cell_restocked()
	BeeForaging.release_cell_slot(bee)
	bee.haul_target = null
	if bee.current_load <= 0.001:
		bee.current_load = 0.0
		bee.current_load_type = ""
	bee.state = State.BUILD_IDLE


static func builder_go_to_haul_target(bee: Node2D, delta: float) -> void:
	if bee.haul_target == null or not is_instance_valid(bee.haul_target):
		bee.haul_target = bee.hive.find_cell_for(bee.current_load_type)
		if bee.haul_target == null:
			bee.current_load = 0.0
			bee.current_load_type = ""
			bee.state = State.BUILD_IDLE
			return
	BeeMovement.move_towards(bee, bee.haul_target.position, delta)
	if bee.position.distance_to(bee.haul_target.position) < HAUL_REACH:
		var placed: float = bee.haul_target.add_resource(bee.current_load_type, bee.current_load)
		bee.current_load -= placed
		bee.hive.announce()
		bee.haul_target = null
		if bee.current_load <= 0.0:
			bee.current_load_type = ""
			bee.target_cell = null
			bee.state = State.BUILD_IDLE


## Clearing a dead larva. The body blocks the cell completely -- nothing
## can be stored there and no egg can be laid in it -- so this is the
## first thing a comb worker on maintenance picks up.
static func architect_go_to_clean(bee: Node2D, delta: float) -> void:
	if bee.target_body != null:
		_go_to_body(bee, delta)
		return
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or not bee.target_cell.needs_cleaning():
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = null
		bee.state = State.BUILD_IDLE
		return

	var approach := BeeForaging.approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		bee.target_cell = null
		bee.state = State.BUILD_IDLE
		return
	if approach == 1:
		bee.state = State.CLEANING


static func architect_clean(bee: Node2D, delta: float) -> void:
	if bee.target_body != null:
		_lift_body(bee, delta)
		return
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or not bee.target_cell.needs_cleaning():
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = null
		bee.state = State.BUILD_IDLE
		return

	if bee.target_cell.add_clean_progress(delta):
		bee.target_cell.clear_cell()
		bee.hive.announce()
		DiagnosticLog.count_cell_cleaned()
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = null
		# the body goes out of the hive rather than back into the comb
		bee.carrying_corpse = true
		bee.state = State.TO_WASTE_EXIT


## T2-4b: a body on the floor. Walk to it; lifting it takes as long as
## clearing a dead larva (cell_clean_time); then it goes out the waste exit
## like one. A body that has gone (the cap, a restore) ends the job.
## Checked before anything holds the body in a typed variable: one the cap
## or a restore has freed must not be assigned to one.
static func _body_present(bee: Node2D) -> bool:
	return is_instance_valid(bee.target_body) and bee.target_body.is_inside_tree()


static func _drop_body_job(bee: Node2D) -> void:
	bee.target_body = null
	bee.state = State.BUILD_IDLE


static func _go_to_body(bee: Node2D, delta: float) -> void:
	if not _body_present(bee):
		_drop_body_job(bee)
		return
	BeeMovement.move_towards(bee, bee.target_body.position, delta)
	if bee.position.distance_to(bee.target_body.position) < BODY_REACH:
		bee.state = State.CLEANING


static func _lift_body(bee: Node2D, delta: float) -> void:
	if not _body_present(bee):
		_drop_body_job(bee)
		return
	var body: Node2D = bee.target_body
	body.clear_progress += delta
	if body.clear_progress < GameConfig.cell_clean_time:
		return
	bee.hive.remove_body(body)
	bee.target_body = null
	bee.carrying_corpse = true
	bee.corpse_is_bee = true
	bee.state = State.TO_WASTE_EXIT


## Carrying unwanted stores out of the hive to throw away. Same shape as
## a miner hauling spoil: walk to the entrance, step outside, spend a
## moment dumping, then come back in and pick up the next job.
static func builder_go_to_waste_exit(bee: Node2D, delta: float) -> void:
	if BeeMovement.walk_to_hive_exit(bee, delta):
		if bee.world:
			bee.world.move_bee_out_of_hive(bee)
		bee.timer = GameConfig.dirt_dump_time
		bee.state = State.DUMPING_WASTE


static func builder_dump_waste(bee: Node2D, delta: float) -> void:
	bee.timer -= delta
	if bee.timer > 0.0:
		return
	bee.current_load = 0.0
	bee.current_load_type = ""
	bee.carrying_corpse = false
	bee.corpse_is_bee = false
	if bee.world:
		bee.world.move_bee_into_hive(bee)
	# An "Empty this cell" order ends when the cell is empty, not after one
	# stomachful. A builder would find the cell again through
	# find_cell_needing_eviction, but a bee whose own role never looks for
	# eviction work -- Challenge 1's Forager queen (C-31) -- dropped the
	# order after the first trip. target_cell is still the source here:
	# only a cleaned corpse arrives with it cleared.
	var source: Node2D = bee.target_cell
	if source != null and is_instance_valid(source) and source.needs_eviction():
		bee.state = State.TO_HAUL_SOURCE
		return
	bee.target_cell = null
	bee.state = State.BUILD_IDLE

