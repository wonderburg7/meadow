extends RefCounted
## Mining, split out of bee.gd -- see BEE_SPLIT_PLAN.md.
##
## Usage: const BeeMining = preload("res://scripts/bee_mining.gd")
##        BeeMining.miner_dig(bee, delta)

const BeeEnums = preload("res://scripts/bee_enums.gd")
const Role = BeeEnums.Role
const State = BeeEnums.State
const BeeMovement = preload("res://scripts/bee_movement.gd")

## Catalogue finders all take one bee and return whether they started work.
static func _start_mining(bee: Node2D, block: Node2D, mark: bool = false) -> bool:
	if block == null:
		return false
	if mark:
		block.set_marked(true)
	bee._mining_no_work_epoch = -1
	bee.target_block = block
	bee.state = State.TO_MINE_SITE
	return true


static func _next_queued_block(bee: Node2D) -> bool:
	var block: Node2D = bee._next_queued_block()
	if block != null and bee.hive.mine_stand_hex(block) == null:
		block = null
	return _start_mining(bee, block)


static func find_marked_block(bee: Node2D) -> bool:
	return _start_mining(bee, bee.hive.find_marked_block(bee._mine_reference_point()))


static func find_nearest_edge_block(bee: Node2D) -> bool:
	var from_point: Vector2 = bee._mine_reference_point() if bee.has_mine_home else Vector2(INF, INF)
	return _start_mining(bee, bee.hive.find_nearest_edge_block(from_point), true)

## Miners used to be walked at the block's own centre. Soil is solid, so
## routing found no path to it at all and _move_towards's "no safe route,
## stay put" branch left the bee standing still forever -- which is why
## marked blocks never got dug. It now walks to the open tile beside the
## block instead, which is a real destination the router can reach.
static func miner_go_to_site(bee: Node2D, delta: float) -> void:
	if bee.target_block == null or not is_instance_valid(bee.target_block) or not bee.target_block.marked_for_mining:
		bee.target_block = null
		bee.state = State.MINE_IDLE
		return

	var stand_point: Vector2 = bee.hive.mine_stand_point(bee.target_block, bee.position)
	if stand_point.x == INF:
		# nothing open touches this block, so nobody can reach it -- drop
		# it and let the idle dispatch find another job
		bee.target_block = null
		bee.state = State.MINE_IDLE
		return

	BeeMovement.move_towards(bee, stand_point, delta)
	if bee.position.distance_to(stand_point) < 8.0:
		bee.target_block.claim_miner(bee)
		bee.state = State.MINING


static func miner_dig(bee: Node2D, delta: float) -> void:
	if bee.target_block == null or not is_instance_valid(bee.target_block) or not bee.target_block.marked_for_mining:
		bee.target_block = null
		bee.state = State.MINE_IDLE
		return
	bee.energy -= GameConfig.build_energy_burn * delta   # digging is hard work

	bee.dirt_load += GameConfig.dirt_fill_rate * delta
	if bee.dirt_load >= GameConfig.miner_dirt_capacity:
		# full up -- down tools and carry it outside. The block keeps
		# whatever progress it has, same as an abandoned build site, so
		# picking this bee (or another miner) up again just resumes it.
		bee.target_block.release_miner(bee)
		bee.state = State.TO_MINE_EXIT
		return

	if bee.target_block.add_mine_progress(delta):
		bee.target_block.release_miner(bee)
		DiagnosticLog.count_block_mined()
		if bee.world:
			bee.world.finish_mining(bee.target_block)
		bee.target_block = null
		bee.state = State.MINE_IDLE


static func miner_go_to_exit(bee: Node2D, delta: float) -> void:
	var exit_point: Vector2 = bee.world.hive_entrance_inside() if bee.world else bee.position
	BeeMovement.move_towards(bee, exit_point, delta)
	if bee.position.distance_to(exit_point) < 8.0:
		if bee.world:
			bee.world.move_bee_out_of_hive(bee)
		bee.timer = GameConfig.dirt_dump_time
		bee.state = State.DUMPING_DIRT


static func miner_dump(bee: Node2D, delta: float) -> void:
	bee.timer -= delta
	if bee.timer <= 0.0:
		bee.dirt_load = 0.0
		if bee.world:
			bee.world.move_bee_into_hive(bee)
		# target_block is still marked, still holding its progress -- go
		# straight back to it rather than re-rolling automine's choice
		bee.state = State.TO_MINE_SITE if (bee.target_block and is_instance_valid(bee.target_block) and bee.target_block.marked_for_mining) else State.MINE_IDLE

