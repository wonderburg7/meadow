extends RefCounted
## Honey making, split out of bee.gd -- see BEE_SPLIT_PLAN.md.
##
## Usage: const BeeHoney = preload("res://scripts/bee_honey.gd")
##        BeeHoney.honey_chew(bee, delta)

const BeeEnums = preload("res://scripts/bee_enums.gd")
const Role = BeeEnums.Role
const State = BeeEnums.State
const BeeForaging = preload("res://scripts/bee_foraging.gd")

## Catalogue finders all take one bee and return whether they started work.

## BB-1. Any honey maker holding bee bread takes it to a cell with room.
## With none, it waits in HONEY_IDLE holding the load: the honey rows below
## refuse a bee carrying bee bread, so it never takes nectar on top of it.
static func find_bee_bread_target(bee: Node2D) -> bool:
	if bee.bee_bread_load <= 0.0:
		return false
	var cell: Variant = bee.hive.find_bee_bread_target()
	if cell == null:
		return false
	bee.target_cell = cell
	bee.state = State.TO_BEE_BREAD_CELL
	return true

## BB-1. A Fermenting honey maker with empty hands takes the pollen and ripe
## honey for one load from the comb and sets off with it as bee bread. It
## starts only when both are there and a cell has room, so nothing is taken
## that cannot be stored; otherwise the honey rows run as before.
static func find_bee_bread_ingredients(bee: Node2D) -> bool:
	if bee.bee_bread_load > 0.0 or bee.honey_load > 0.0 or bee.current_load > 0.0:
		return false
	var pollen_needed: float = GameConfig.bee_bread_pollen_per_load
	var honey_needed: float = GameConfig.bee_bread_honey_per_load
	if not bee.hive.can_take("pollen", pollen_needed) or not bee.hive.can_take("honey", honey_needed):
		return false
	var cell: Variant = bee.hive.find_bee_bread_target()
	if cell == null:
		return false
	bee.hive.take("pollen", pollen_needed)
	bee.hive.take("honey", honey_needed)
	bee.bee_bread_load = GameConfig.bee_bread_per_load
	bee.target_cell = cell
	bee.state = State.TO_BEE_BREAD_CELL
	return true

static func find_honey_target(bee: Node2D) -> bool:
	if bee.honey_load <= 0.0:
		return false
	var pot: Variant = bee.hive.find_honey_target()
	if pot == null:
		return false
	bee.target_cell = pot
	bee.state = State.TO_HONEY_CELL
	return true


static func find_cell_needing_fanning(bee: Node2D) -> bool:
	if bee.honey_load > 0.0 or bee.bee_bread_load > 0.0:
		return false
	var drying: Variant = bee.hive.find_cell_needing_fanning()
	if drying == null:
		return false
	bee.fan_target = drying
	bee.state = State.FANNING
	return true


static func find_cell_with(bee: Node2D) -> bool:
	if bee.current_load > 0.0:
		return false   # still holding a load (GC-2): never lift over it
	if bee.honey_load > 0.0 or bee.bee_bread_load > 0.0:
		return false   # BB-1: holding bee bread, it waits for a cell instead
	# NF-2: never fermented nectar. NF-4: closest to her, or oldest with the sense.
	var nectar_cell: Variant = bee.hive.find_honey_source(bee.global_position)
	if nectar_cell == null or bee.hive.find_honey_target() == null:
		return false
	bee.target_cell = nectar_cell
	bee.state = State.TO_NECTAR_CELL
	return true

## Nectar is mostly water and ferments; honey keeps, and packs several
## times the energy into the same cell. A honey maker takes nectar back
## out of the comb, chews enzymes into it, spits the mix into a cell of
## its own, and then fans its wings over that cell until the water has
## evaporated off. Only then is it honey the colony can eat.

static func honey_go_to_nectar(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.content_type != "nectar":
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = null
		bee.state = State.HONEY_IDLE
		return

	var approach := BeeForaging.approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		bee.target_cell = null
		bee.state = State.HONEY_IDLE
		return
	if approach < 1:
		return

	var wanted: float = bee.nectar_stomach_capacity
	var lifted: float = bee.target_cell.take_resource("nectar", wanted)
	BeeForaging.release_cell_slot(bee)
	bee.target_cell = null
	bee.hive.announce()
	if lifted <= 0.0:
		bee.state = State.HONEY_IDLE
		return
	bee.current_load = lifted
	bee.current_load_type = "nectar"
	bee.timer = GameConfig.honey_chew_time
	bee.state = State.CHEWING


## Standing still working the nectar over in its crop, adding the
## enzymes that break the sugars down. `nectar_per_honey` is where the
## concentration happens: several units of thin nectar become one of mix.
static func honey_chew(bee: Node2D, delta: float) -> void:
	bee.timer -= delta
	if bee.timer > 0.0:
		return
	bee.honey_load = bee.current_load / max(0.1, GameConfig.nectar_per_honey)
	bee.current_load = 0.0
	bee.current_load_type = ""
	bee.target_cell = bee.hive.find_honey_target()
	if bee.target_cell == null:
		# nowhere to put it -- hold onto it and wait for a cell to free up
		bee.state = State.HONEY_IDLE
		return
	bee.state = State.TO_HONEY_CELL


static func honey_go_to_pot(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.space_for("honey") <= 0.0:
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = bee.hive.find_honey_target()
		if bee.target_cell == null:
			bee.state = State.HONEY_IDLE
		return

	var approach := BeeForaging.approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		bee.target_cell = bee.hive.find_cell_for("honey", bee.target_cell)
		return
	if approach == 1:
		bee.timer = bee.deposit_time
		bee.state = State.DEPOSITING_HONEY


static func honey_deposit(bee: Node2D, delta: float) -> void:
	bee.timer -= delta
	if bee.timer > 0.0:
		return
	if bee.target_cell != null and is_instance_valid(bee.target_cell):
		bee.honey_load -= bee.target_cell.add_resource("honey", bee.honey_load)
		bee.hive.announce()
		bee.fan_target = bee.target_cell
	BeeForaging.release_cell_slot(bee)
	bee.target_cell = null
	if bee.honey_load > 0.001:
		bee.state = State.HONEY_IDLE   # still carrying -- find another pot
	else:
		bee.honey_load = 0.0
		DiagnosticLog.count_honey_batch_deposited()
		bee.state = State.FANNING if bee.fan_target != null else State.HONEY_IDLE


## BB-1. Carrying bee bread to its cell. A cell that filled up or sealed on
## the way is swapped for the next one with room; with none, the bee waits in
## HONEY_IDLE, still holding the load, until the deposit row finds one.
static func bee_bread_go_to_cell(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.space_for("bee_bread") <= 0.0:
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = bee.hive.find_bee_bread_target()
		if bee.target_cell == null:
			bee.state = State.HONEY_IDLE
		return

	var approach := BeeForaging.approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		bee.target_cell = bee.hive.find_bee_bread_target(bee.target_cell)
		return
	if approach == 1:
		bee.timer = bee.deposit_time
		bee.state = State.DEPOSITING_BEE_BREAD


static func bee_bread_deposit(bee: Node2D, delta: float) -> void:
	bee.timer -= delta
	if bee.timer > 0.0:
		return
	if bee.target_cell != null and is_instance_valid(bee.target_cell):
		bee.bee_bread_load -= bee.target_cell.add_resource("bee_bread", bee.bee_bread_load)
		bee.hive.announce()
	BeeForaging.release_cell_slot(bee)
	bee.target_cell = null
	if bee.bee_bread_load <= 0.001:
		bee.bee_bread_load = 0.0
	# Still carrying some: the deposit row finds it another cell.
	bee.state = State.HONEY_IDLE


## Beating its wings over the open cell to drive a breeze across it. Each
## fanning bee contributes its own frame time, so several working the
## same cell dry it out proportionally faster.
static func honey_fan(bee: Node2D, delta: float) -> void:
	if bee.fan_target == null or not is_instance_valid(bee.fan_target) or not bee.fan_target.needs_fanning():
		BeeForaging.release_cell_slot(bee)
		bee.fan_target = null
		bee.state = State.HONEY_IDLE
		return

	var approach := BeeForaging.approach_cell(bee, bee.fan_target, delta)
	if approach < 0:
		bee.fan_target = null
		bee.state = State.HONEY_IDLE
		return
	if approach == 1:
		bee.fan_target.add_fanning_progress(delta)

