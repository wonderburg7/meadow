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
	if bee.position.distance_to(stand_point) < 12.0:
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
	if bee.position.distance_to(bee.target_cell.position) < 10.0:
		var moving_type: String = bee.target_cell.content_type
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
		if bee.target_cell.evict_mode == "discard":
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
	if bee.restock_sources.is_empty():
		return true
	return bee.restock_sources.has(cell)


## Finds the emptiest target that still has room and a cell to fill it
## from. Emptiest first, so a set of cells fills evenly rather than one
## being topped up repeatedly while another sits empty.
static func find_restock_job(bee: Node2D) -> bool:
	if not has_restock_orders(bee) or bee.hive == null:
		return false

	var neediest: Node2D = null
	var least: float = INF
	for cell in bee.restock_targets:
		if not is_instance_valid(cell) or cell.space_for(bee.restock_resource) <= 0.0:
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
	for cell in bee.hive.cells_holding(bucket):
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
	if bee.position.distance_to(bee.haul_target.position) < 10.0:
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


## Carrying unwanted stores out of the hive to throw away. Same shape as
## a miner hauling spoil: walk to the entrance, step outside, spend a
## moment dumping, then come back in and pick up the next job.
static func builder_go_to_waste_exit(bee: Node2D, delta: float) -> void:
	var exit_point: Vector2 = bee.world.hive_entrance_inside() if bee.world else bee.position
	BeeMovement.move_towards(bee, exit_point, delta)
	if bee.position.distance_to(exit_point) < 8.0:
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
	if bee.world:
		bee.world.move_bee_into_hive(bee)
	bee.target_cell = null
	bee.state = State.BUILD_IDLE

