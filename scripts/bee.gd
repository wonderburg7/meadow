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

enum Role { FORAGER, NURSERY, BUILDER, EGG_LAYER, IDLE, MINER }
enum State {
	SEEK_FLOWER, TO_FLOWER, COLLECTING, TO_HIVE,           # forager, outdoors
	IN_HIVE_TO_CELL, DEPOSITING, IN_HIVE_TO_EXIT,          # forager, indoors
	MOVE_TO_POINT, IDLING,                                 # player-commanded
	NURSE_IDLE, TO_BROOD, TENDING,                         # nursery
	BUILD_IDLE, TO_BUILD_SITE, BUILDING,                   # builder
	TO_HAUL_SOURCE, TO_HAUL_TARGET,                        # builder, moving stores
	MINE_IDLE, TO_MINE_SITE, MINING,                       # miner
	TO_MINE_EXIT, DUMPING_DIRT,                            # miner, full of spoil
	SEEK_POLLEN, TO_POLLEN_CELL, EATING,                   # egg layer
	TO_CELL_TO_LAY, LAYING,
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
					_start_collecting()
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
			_nurse_look_for_work()
		State.TO_BROOD:
			_nurse_go_to_brood(delta)
		State.TENDING:
			_nurse_tend(delta)

		# --- builder ---
		State.BUILD_IDLE:
			_builder_look_for_work()
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
			_miner_look_for_work()
		State.TO_MINE_SITE:
			_miner_go_to_site(delta)
		State.MINING:
			_miner_dig(delta)
		State.TO_MINE_EXIT:
			_miner_go_to_exit(delta)
		State.DUMPING_DIRT:
			_miner_dump(delta)

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

	# bees working inside sip from the comb as they go
	if _works_indoors() and energy < GameConfig.energy_capacity * 0.6:
		energy += hive.take("nectar", GameConfig.energy_capacity * 0.25)

	# The queen doesn't die of old age -- losing her would silently end
	# the colony, and there's no succession yet. She can still starve.
	if not is_queen and age_seconds >= GameConfig.bee_lifespan_days * GameConfig.seconds_per_day:
		_die()
	elif energy <= 0.0:
		_die()

func _works_indoors() -> bool:
	return role == Role.NURSERY or role == Role.BUILDER or role == Role.EGG_LAYER or role == Role.MINER

func _die() -> void:
	if current_flower:
		current_flower.release(self)
	if target_cell and is_instance_valid(target_cell):
		target_cell.release_builder(self)
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
	state = State.IN_HIVE_TO_CELL

func _go_to_deposit_cell(delta: float) -> void:
	if current_load <= 0.0:
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

	_move_towards(target_cell.position, delta)
	if position.distance_to(target_cell.position) < 8.0:
		timer = deposit_time
		state = State.DEPOSITING

func _finish_depositing() -> void:
	if target_cell and is_instance_valid(target_cell):
		var placed: float = target_cell.add_resource(current_load_type, current_load)
		current_load -= placed
		hive.announce()
	target_cell = null

	# refuel from the comb while we're home
	energy += hive.take("nectar", GameConfig.energy_capacity - energy)

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
	energy += hive.take("nectar", GameConfig.energy_capacity - energy)
	state = State.SEEK_FLOWER

# --- nursery work -------------------------------------------------

## The queen lays directly into a cell now (see _queen_lay), so there's
## never a loose egg on the floor for a nurse to fetch. A nurse's only
## job is tending brood that's already in a cell.
func _nurse_look_for_work() -> void:
	var brood = hive.find_brood_cell()
	if brood:
		target_cell = brood
		state = State.TO_BROOD

func _nurse_go_to_brood(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or target_cell.content_type != "brood":
		state = State.NURSE_IDLE
		return
	_move_towards(target_cell.position, delta)
	if position.distance_to(target_cell.position) < 10.0:
		state = State.TENDING

func _nurse_tend(_delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or target_cell.content_type != "brood":
		state = State.NURSE_IDLE
		return
	target_cell.being_tended = true   # cell reads this each frame to speed development

# --- building -----------------------------------------------------

## Builders have two jobs, in priority order: shift resources out of
## cells the player has re-designated, then draw new comb.
func _builder_look_for_work() -> void:
	var source = hive.find_cell_needing_eviction()
	if source:
		target_cell = source
		state = State.TO_HAUL_SOURCE
		return

	var site: Node2D = null
	if has_manual_build_target:
		# Consumed either way -- if the tile turns out to be occupied or
		# solid, falling through to automatic placement is better than
		# retrying the same bad hex forever.
		site = hive.create_cell_site_at(manual_build_hex)
		has_manual_build_target = false

	if site == null:
		site = hive.find_unfinished_cell()
	if site == null:
		site = hive.create_next_cell_site()   # nothing under way -- start one
	if site:
		target_cell = site
		state = State.TO_BUILD_SITE

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

## Miners dig out blocks you've marked. With automine on they don't wait
## to be told: they take the edge block nearest the middle of the comb,
## so the hive opens up around itself rather than at the far rim.
func _miner_look_for_work() -> void:
	var block = hive.find_marked_block()
	if block == null and automine:
		block = hive.find_nearest_edge_block()
		if block != null:
			block.set_marked(true)
	if block != null:
		target_block = block
		state = State.TO_MINE_SITE

func _miner_go_to_site(delta: float) -> void:
	if target_block == null or not is_instance_valid(target_block) or not target_block.marked_for_mining:
		target_block = null
		state = State.MINE_IDLE
		return
	# stand next to the block rather than inside it -- it's solid
	_move_towards(target_block.position, delta)
	if position.distance_to(target_block.position) < GameConfig.hive_cell_spacing * 1.6:
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

# --- egg laying (queen only) --------------------------------------

func _queen_seek_pollen() -> void:
	# no point eating for an egg she'll have nowhere to put
	if not hive.has_room_for_egg():
		return
	target_cell = hive.find_cell_with("pollen")
	if target_cell:
		state = State.TO_POLLEN_CELL

func _queen_go_to_pollen(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or target_cell.content_type != "pollen":
		state = State.SEEK_POLLEN
		return
	_move_towards(target_cell.position, delta)
	if position.distance_to(target_cell.position) < 8.0:
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
		target_cell = hive.find_empty_cell()
		if target_cell == null:
			return   # nowhere to lay; wait until a cell frees up
		state = State.TO_CELL_TO_LAY

func _queen_go_to_lay(delta: float) -> void:
	if target_cell == null or not is_instance_valid(target_cell) or not target_cell.is_empty():
		target_cell = hive.find_empty_cell()
		if target_cell == null:
			state = State.SEEK_POLLEN
			return
	_move_towards(target_cell.position, delta)
	if position.distance_to(target_cell.position) < 8.0:
		timer = 1.5
		state = State.LAYING

func _queen_lay(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		if target_cell != null and is_instance_valid(target_cell) and target_cell.is_empty():
			target_cell.start_brood()
			pollen_eaten -= GameConfig.egg_pollen_cost
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
	move_target = parent.to_local(world_point) if parent else world_point
	_release_everything()
	state = State.MOVE_TO_POINT

## `meadow_point` is global/meadow-space (meadow_root sits at the origin,
## so global and local-to-meadow coincide -- see the note on
## command_move_to for why that distinction matters elsewhere).
func set_forage_start_point(meadow_point: Vector2) -> void:
	forage_start_point = meadow_point

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

func can_take_role(new_role: int) -> bool:
	return is_queen if new_role == Role.EGG_LAYER else true

func set_role(new_role: int) -> void:
	if new_role == role or not can_take_role(new_role):
		return
	_release_everything()

	var was_indoors := _works_indoors()
	role = new_role
	visible = true
	var now_indoors := _works_indoors()

	if world:
		if now_indoors and not was_indoors:
			world.move_bee_into_hive(self)
		elif was_indoors and not now_indoors:
			world.move_bee_out_of_hive(self)

	state = _default_state_for_role()
	_update_label()

func _release_everything() -> void:
	if current_flower:
		current_flower.release(self)
		current_flower = null
	if target_cell and is_instance_valid(target_cell):
		target_cell.release_builder(self)
	if target_block and is_instance_valid(target_block):
		target_block.release_miner(self)
	target_cell = null
	target_block = null
	haul_target = null

## Called by a flower that's about to wither with this bee on it.
func release_flower_reference(flower: Node2D) -> void:
	if current_flower == flower:
		current_flower = null
		if state == State.TO_FLOWER or state == State.COLLECTING:
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
			return "looking for a block to dig" if automine else "waiting for a block to be marked"
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
			return "looking for brood work"
		State.TO_BROOD:
			return "going to tend the brood"
		State.TENDING:
			return "tending a developing bee"
		State.BUILD_IDLE:
			return "looking for building work"
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

func role_name_text() -> String:
	match role:
		Role.NURSERY:
			return "Nursery"
		Role.BUILDER:
			return "Builder"
		Role.EGG_LAYER:
			return "Egg layer"
		Role.IDLE:
			return "Idle"
		Role.MINER:
			return "Miner (automine on)" if automine else "Miner"
		_:
			return "Forager (%s)" % resource_type

## What this bee is carrying, for the info panel.
func carrying_text() -> String:
	if role == Role.MINER:
		return "Carrying: %d dirt (of %d)" % [int(dirt_load), int(GameConfig.miner_dirt_capacity)]
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

## Outdoors a bee flies straight. Inside the hive it walks a route over
## open tiles, because soil is solid. The route is recalculated only
## when the destination changes, not every frame.
func _move_towards(target: Vector2, delta: float) -> void:
	var step: float = speed * _terrain_speed_factor() * delta

	if not _is_inside_hive():
		position = position.move_toward(_avoid_obstacles(target), step)
		return

	if target.distance_to(path_goal) > 6.0 or path_points.is_empty():
		path_goal = target
		path_points = hive.path_between(position, target)
		path_index = 0

	if path_points.is_empty():
		position = position.move_toward(target, step)   # no route -- go direct
		return

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
