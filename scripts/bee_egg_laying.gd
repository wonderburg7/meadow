extends RefCounted
## Queen egg laying, split out of bee.gd -- see BEE_SPLIT_PLAN.md.
##
## Usage: const BeeEggLaying = preload("res://scripts/bee_egg_laying.gd")
##        BeeEggLaying.queen_lay(bee, delta)

const BeeEnums = preload("res://scripts/bee_enums.gd")
const Role = BeeEnums.Role
const State = BeeEnums.State
const BeeForaging = preload("res://scripts/bee_foraging.gd")

## Catalogue finder: all rows take one bee and report whether work started.
static func has_room_for_egg(bee: Node2D) -> bool:
	if not bee.is_queen or bee.laying_paused:
		return false
	if not bee.hive.has_room_for_egg() or bee.hive.find_cell_with("pollen") == null:
		return false
	bee.state = State.SEEK_POLLEN
	return true

## A gyne egg is a far bigger investment than a worker one, so the queen
## has to eat considerably more before she can lay it. She looks at what
## the colony has actually asked for: if any free cell is set aside to
## raise a gyne, that's the next egg. An unmated queen lays only drones,
## at a worker egg's cost, whatever the cell asks for (COL-9).
static func pollen_needed_for_next_egg(bee: Node2D) -> float:
	var next: Variant = bee.hive.find_empty_cell()
	if bee.is_mated and next != null and is_instance_valid(next) and next.hatch_gyne:
		return GameConfig.gyne_egg_pollen_cost
	return GameConfig.egg_pollen_cost


static func queen_seek_pollen(bee: Node2D) -> void:
	# Nothing to lay into, or nothing to eat: rather than hovering doing
	# nothing, hand over to the idle dispatch, which re-checks laying
	# first and otherwise puts her on her backup role (nursing, unless
	# the player has changed it). She picks laying straight back up the
	# moment a cell frees up -- see _try_role_work's EGG_LAYER case.
	if not bee.hive.has_room_for_egg():
		bee.state = State.NURSE_IDLE
		return
	bee.target_cell = bee.hive.find_cell_with("pollen")
	if bee.target_cell:
		bee.state = State.TO_POLLEN_CELL
	else:
		bee.state = State.NURSE_IDLE


static func queen_go_to_pollen(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.content_type != "pollen":
		BeeForaging.release_cell_slot(bee)
		bee.state = State.SEEK_POLLEN
		return
	var approach := BeeForaging.approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		bee.target_cell = null
		bee.state = State.SEEK_POLLEN
		return
	if approach == 1:
		bee.state = State.EATING


static func queen_eat(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.content_type != "pollen":
		bee.state = State.SEEK_POLLEN
		return
	bee.pollen_eaten += bee.target_cell.take_resource("pollen", GameConfig.queen_eat_rate * delta)
	bee.hive.announce()
	if bee.pollen_eaten >= pollen_needed_for_next_egg(bee):
		# walk to a free cell and lay into it directly. She no longer
		# drops eggs on the floor for a nurse to pick up -- that's what
		# left white eggs scattered around the hive.
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = bee.hive.find_empty_cell()
		if bee.target_cell == null:
			return   # nowhere to lay; wait until a cell frees up
		bee.state = State.TO_CELL_TO_LAY


static func queen_go_to_lay(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or not bee.target_cell.is_empty():
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = bee.hive.find_empty_cell()
		if bee.target_cell == null:
			bee.state = State.SEEK_POLLEN
			return
	var approach := BeeForaging.approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		bee.target_cell = null
		bee.state = State.SEEK_POLLEN
		return
	if approach == 1:
		bee.timer = 1.5
		bee.state = State.LAYING


static func queen_lay(bee: Node2D, delta: float) -> void:
	bee.timer -= delta
	if bee.timer <= 0.0:
		if bee.target_cell != null and is_instance_valid(bee.target_cell) and bee.target_cell.is_empty():
			# COL-9: an unmated queen's eggs are unfertilised, so they become
			# drones -- never a worker, never a gyne, whatever the cell asks.
			var as_drone: bool = not bee.is_mated
			var as_gyne: bool = bee.target_cell.hatch_gyne and not as_drone
			bee.target_cell.start_brood(as_gyne, as_drone)
			# Only now does the priority share-out move on. Everything up to
			# this point was the queen asking where she *could* lay.
			bee.hive.record_lay(bee.target_cell)
			bee.pollen_eaten -= GameConfig.gyne_egg_pollen_cost if as_gyne else GameConfig.egg_pollen_cost
			bee.pollen_eaten = max(0.0, bee.pollen_eaten)
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = null
		# back through the dispatch, so the brood gets looked at before
		# she starts on the next egg
		bee.state = State.NURSE_IDLE

