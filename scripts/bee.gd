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

enum Role { FORAGER, NURSERY, BUILDER, EGG_LAYER }
enum State {
	SEEK_FLOWER, TO_FLOWER, COLLECTING, TO_HIVE,           # forager, outdoors
	IN_HIVE_TO_CELL, DEPOSITING, IN_HIVE_TO_EXIT,          # forager, indoors
	MOVE_TO_POINT,                                         # player-commanded
	NURSE_IDLE, TO_EGG, CARRY_EGG, TO_BROOD, TENDING,      # nursery
	BUILD_IDLE, TO_BUILD_SITE, BUILDING,                   # builder
	TO_HAUL_SOURCE, TO_HAUL_TARGET,                        # builder, moving stores
	SEEK_POLLEN, TO_POLLEN_CELL, EATING, LAYING,           # egg layer
}

const Shapes = preload("res://scripts/shapes.gd")
const Egg = preload("res://scripts/egg.gd")

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
var carried_egg: Node2D = null
var target_cell: Node2D = null
var haul_target: Node2D = null
var pollen_eaten: float = 0.0

## Flowers this bee has drained, mapped to the sim-time at which they
## should be back to full. Time-based rather than checking the flower's
## live amount, so a bee commits to staying away for the whole recharge
## rather than darting back the moment a trickle appears.
var flower_cooldowns: Dictionary = {}

var label: Label
var selection_ring: Polygon2D
var body: Polygon2D

func _ready() -> void:
	add_to_group("bees")

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

		# --- nursery ---
		State.NURSE_IDLE:
			_nurse_look_for_work()
		State.TO_EGG:
			_nurse_go_to_egg(delta)
		State.CARRY_EGG:
			_nurse_carry_egg(delta)
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

		# --- egg layer ---
		State.SEEK_POLLEN:
			_queen_seek_pollen()
		State.TO_POLLEN_CELL:
			_queen_go_to_pollen(delta)
		State.EATING:
			_queen_eat(delta)
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

	if age_seconds >= GameConfig.bee_lifespan_days * GameConfig.seconds_per_day:
		_die()
	elif energy <= 0.0:
		_die()

func _works_indoors() -> bool:
	return role == Role.NURSERY or role == Role.BUILDER or role == Role.EGG_LAYER

func _die() -> void:
	if current_flower:
		current_flower.release(self)
	if carried_egg and is_instance_valid(carried_egg):
		carried_egg.claimed_by = null
		carried_egg.visible = true
	if target_cell and is_instance_valid(target_cell):
		target_cell.release_builder(self)
	queue_free()

# --- foraging -----------------------------------------------------

func _max_capacity() -> float:
	return nectar_stomach_capacity if resource_type == "nectar" else pollen_stomach_capacity

func _collection_rate() -> float:
	return nectar_collection_rate if resource_type == "nectar" else pollen_collection_rate

func _seek_flower() -> void:
	var best: Node2D = null
	var best_dist := INF
	for f in get_tree().get_nodes_in_group("flowers"):
		if flower_cooldowns.has(f) and GameConfig.sim_time < flower_cooldowns[f]:
			continue
		if f.occupied_by != null:
			continue
		if f.get_available(resource_type) <= 0.0:
			continue
		var d := position.distance_to(f.position)
		if d < best_dist:
			best_dist = d
			best = f

	if best == null:
		if current_load > 0.0:
			state = State.TO_HIVE
		return   # nothing worth visiting yet -- try again next frame

	best.occupied_by = self
	current_flower = best
	state = State.TO_FLOWER

func _start_collecting() -> void:
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

	var space_left: float = _max_capacity() - current_load
	if space_left <= 0.0:
		_finish_collecting()
		return

	var wanted: float = min(_collection_rate() * delta, space_left)
	var taken: float = current_flower.collect(resource_type, wanted)
	current_load += taken
	if taken > 0.0:
		current_load_type = resource_type

	# flower ran dry, or we're full -- either way this visit is over
	if taken <= 0.0 or current_load >= _max_capacity():
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
		state = _default_state_for_role()

## Fallback only -- deposits without the walk-in animation.
func _deposit_everything_remotely() -> void:
	hive.deposit(current_load_type, current_load)
	current_load = 0.0
	current_load_type = ""
	energy += hive.take("nectar", GameConfig.energy_capacity - energy)
	state = State.SEEK_FLOWER

# --- nursery work -------------------------------------------------

func _nurse_look_for_work() -> void:
	for e in get_tree().get_nodes_in_group("loose_eggs"):
		if e.claimed_by == null:
			e.claimed_by = self
			carried_egg = e
			state = State.TO_EGG
			return
	var brood = hive.find_brood_cell()
	if brood:
		target_cell = brood
		state = State.TO_BROOD

func _nurse_go_to_egg(delta: float) -> void:
	if carried_egg == null or not is_instance_valid(carried_egg):
		carried_egg = null
		state = State.NURSE_IDLE
		return
	_move_towards(carried_egg.position, delta)
	if position.distance_to(carried_egg.position) < 8.0:
		target_cell = hive.find_empty_cell()
		if target_cell == null:
			# nowhere to put it -- drop the claim and do something else
			carried_egg.claimed_by = null
			carried_egg = null
			state = State.NURSE_IDLE
			return
		carried_egg.visible = false   # tucked under the bee while carried
		state = State.CARRY_EGG

func _nurse_carry_egg(delta: float) -> void:
	if target_cell == null or carried_egg == null or not is_instance_valid(carried_egg):
		state = State.NURSE_IDLE
		return
	if not target_cell.is_empty():
		target_cell = hive.find_empty_cell()
		if target_cell == null:
			return
	_move_towards(target_cell.position, delta)
	carried_egg.position = position
	if position.distance_to(target_cell.position) < 8.0:
		target_cell.start_brood()
		carried_egg.queue_free()
		carried_egg = null
		state = State.NURSE_IDLE

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

	var site = hive.find_unfinished_cell()
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

# --- egg laying (queen only) --------------------------------------

func _queen_seek_pollen() -> void:
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
		timer = 1.5
		state = State.LAYING

func _queen_lay(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		var egg := Egg.new()
		# drop it just beside her so a nursery worker can come and collect
		egg.position = position + Vector2(randf_range(-30, 30), randf_range(20, 45))
		get_parent().add_child(egg)
		pollen_eaten -= GameConfig.egg_pollen_cost
		state = State.SEEK_POLLEN

# --- player commands ----------------------------------------------

func command_move_to(point: Vector2) -> void:
	move_target = point
	_release_everything()
	state = State.MOVE_TO_POINT

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
	# carrying the old resource? take it home before switching over
	state = State.TO_HIVE if (current_load > 0.0 and current_load_type != resource_type) else State.SEEK_FLOWER
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
	if carried_egg and is_instance_valid(carried_egg):
		carried_egg.claimed_by = null
		carried_egg.visible = true
		carried_egg = null
	if target_cell and is_instance_valid(target_cell):
		target_cell.release_builder(self)
	target_cell = null
	haul_target = null

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
		_:
			return "N" if resource_type == "nectar" else "P"

func role_name_text() -> String:
	match role:
		Role.NURSERY:
			return "Nursery"
		Role.BUILDER:
			return "Builder"
		Role.EGG_LAYER:
			return "Egg layer"
		_:
			return "Forager (%s)" % resource_type

func _update_label() -> void:
	var days_left: float = GameConfig.bee_lifespan_days - age_seconds / max(0.001, GameConfig.seconds_per_day)
	var prefix := "Q" if is_queen else str(bee_id)
	label.text = "%s%s  %dd" % [prefix, role_letter(), int(max(0.0, days_left))]
	# body dims as energy runs low, so a starving bee is visible at a glance
	var energy_fraction: float = clamp(energy / max(0.001, GameConfig.energy_capacity), 0.0, 1.0)
	body.color = _base_colour().lerp(Color(0.45, 0.35, 0.3), 1.0 - energy_fraction)

func _move_towards(target: Vector2, delta: float) -> void:
	position = position.move_toward(target, speed * delta)
