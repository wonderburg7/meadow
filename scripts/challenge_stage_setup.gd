extends RefCounted
## Applies the world a Challenge 1 stage declares it starts from (its
## `"setup"` record in challenge_stages.gd). Only the debug arrows use this:
## natural stage advance never rebuilds the world, it just checks it.
##
## Every key is optional; an absent key leaves that part of the world alone.
## Keys apply in the order KEYS lists them, then navigation, edge flags and
## the storage readout are refreshed once. See plans/now/c1-followups.md
## (C1F-1) for why each stage's record is written the way it is.
class_name ChallengeStageSetup

const Bee = preload("res://scripts/bee.gd")
const Shapes = preload("res://scripts/shapes.gd")
const Stages = preload("res://scripts/challenge_stages.gd")

## The whole vocabulary, in application order. tests/source_checks.py reads
## this to reject a stage record that names a key nothing applies.
const KEYS := [
	"tunnel_open", "queen_at", "built_cells", "cell_stores", "pollen_cell",
	"queen_role", "queen_focus", "queen_load", "brood_cells", "new_worker",
	"runner", "selection",
]

static func apply(runner: Node, main: Node2D, setup: Dictionary) -> void:
	if setup.is_empty() or not is_instance_valid(main.queen):
		return
	_release_queen(main)
	if setup.has("tunnel_open"):
		_apply_tunnel(runner, main, bool(setup.tunnel_open))
	if setup.has("queen_at"):
		_place_queen(main, str(setup.queen_at))
	if setup.has("built_cells"):
		_set_built_cells(main, int(setup.built_cells))
	if setup.has("cell_stores"):
		_set_cell_stores(main, setup.cell_stores)
	if setup.has("pollen_cell"):
		_set_pollen_cell(main, int(setup.pollen_cell))
	_apply_queen(main, setup)
	if setup.has("brood_cells"):
		_set_brood_cells(main, int(setup.brood_cells))
	if setup.has("new_worker"):
		_set_new_worker(runner, main, bool(setup.new_worker))
	if setup.has("runner"):
		for counter in setup.runner:
			runner.set("_" + str(counter), setup.runner[counter])
	if setup.has("selection"):
		_set_selection(runner, main, str(setup.selection))
	# Role changes and the tunnel can leave her mid-errand; park her again.
	_release_queen(main)
	if setup.get("tunnel_open", true) == false:
		runner._drive_opening_mine()
	main.hive.build_navigation()
	main.hive.refresh_edge_flags()
	main.hive.announce()
	main.fog_of_war.notify_hive_open_space_changed()

## Same release freeze_bee:queen performs, so no errand survives a jump, plus
## dropping an armed "Build cell" tool so the next click cannot place a cell.
static func _release_queen(main: Node2D) -> void:
	var queen: Node2D = main.queen
	queen._release_everything()
	queen.clear_navigation_state()
	queen.current_flower = null
	queen.target_cell = null
	queen.target_block = null
	queen.state = Bee.State.IDLING
	if main.active_placement_tool != "":
		main.input_selection.clear_placement_tool()

# --- tunnel and queen position -------------------------------------

static func _apply_tunnel(runner: Node, main: Node2D, open: bool) -> void:
	# Any survivors go first; _setup_opening_tunnel adds a fresh set.
	for block in main.get_tree().get_nodes_in_group("soil_blocks"):
		if is_instance_valid(block) and not block.is_queued_for_deletion() and block in runner._opening_blocks:
			main.world_building.finish_mining(block)
	runner._opening_blocks.clear()
	runner._opening_started = false
	if not open:
		runner._setup_opening_tunnel()

## Where _setup_opening_tunnel puts the queen: just outside the sealed part.
static func tunnel_queen_position(main: Node2D) -> Vector2:
	var interior_rings: int = int(GameConfig.hive_interior_rings)
	var tunnel_depth: int = int(GameConfig.hive_soil_depth + GameConfig.hive_rock_rings)
	var entrance_tiles: Dictionary = main.world_building._entrance_tiles(interior_rings, tunnel_depth)
	var blocked_count: int = maxi(1, ceili(float(entrance_tiles.size()) / 3.0) - 1)
	var queen_ring: int = interior_rings + blocked_count + 1
	return main.world_building._hive_centre_local() + Shapes.hex_to_pixel(
		0, -queen_ring, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid
	)

static func _place_queen(main: Node2D, place: String) -> void:
	var queen: Node2D = main.queen
	match place:
		"meadow_door":
			main.world_building.move_bee_out_of_hive(queen)
		"hive_floor":
			main.world_building.move_bee_into_hive(queen)
			queen.position = main.hive_entrance_inside()
		"cavity":
			main.world_building.move_bee_into_hive(queen)
			queen.position = main.world_building._hive_centre_local()
		"tunnel":
			main.world_building.move_bee_into_hive(queen)
			queen.position = tunnel_queen_position(main)
		_:
			push_error("challenge_stage_setup: unknown queen_at '%s'" % place)
	queen.clear_navigation_state()

# --- comb ------------------------------------------------------------

static func _built_cells(main: Node2D) -> Array:
	return main.hive.cells.filter(func(c): return is_instance_valid(c) and c.is_built)

static func _set_built_cells(main: Node2D, count: int) -> void:
	var built: Array = _built_cells(main)
	# Half-built sites count for nothing: remove them, then trim or grow.
	for cell in main.hive.cells.duplicate():
		if is_instance_valid(cell) and not cell.is_built:
			_remove_cell(main, cell)
	while built.size() > count:
		_remove_cell(main, built.pop_back())
	while built.size() < count:
		var site: Node2D = main.hive.create_next_cell_site()
		if site == null:
			push_error("challenge_stage_setup: no room for cell %d" % built.size())
			return
		site.nectar_capacity_override = Stages.C1_NECTAR_CELL_CAPACITY
		site.build_time_override = Stages.FAST_BUILD_TIME
		site.add_build_progress(Stages.FAST_BUILD_TIME)
		built.append(site)

## Releases every bee's hold on the cell before it goes, so nothing keeps
## walking to a freed node.
static func _remove_cell(main: Node2D, cell: Node2D) -> void:
	for bee in main.get_tree().get_nodes_in_group("bees"):
		if not is_instance_valid(bee):
			continue
		cell.release_slot(bee)
		cell.release_builder(bee)
		if bee.target_cell == cell:
			bee.target_cell = null
			if bee.state != Bee.State.IDLING:
				bee.clear_navigation_state()
	main.selected_cells.erase(cell)
	main.hive.cells.erase(cell)
	main.hive.occupied_tiles.erase(cell.axial)
	main.hive.invalidate_index()
	cell.queue_free()

static func _set_cell_stores(main: Node2D, stores: Array) -> void:
	var built: Array = _built_cells(main)
	for i in range(built.size()):
		var cell: Node2D = built[i]
		cell.clear_cell()
		if i < stores.size():
			var type: String = str(stores[i].type)
			if not cell.designation_is_explicit:
				cell.set_designation(type, false)
			cell.add_resource(type, float(stores[i].amount))
		elif not cell.designation_is_explicit:
			cell.set_designation("", false)

static func _set_pollen_cell(main: Node2D, index: int) -> void:
	var built: Array = _built_cells(main)
	for i in range(built.size()):
		if i == index:
			built[i].set_designation("pollen", true)
		else:
			built[i].set_designation("", false)

static func _set_brood_cells(main: Node2D, count: int) -> void:
	var brooded: Array = []
	for cell in _built_cells(main):
		if cell.content_type == "brood":
			brooded.append(cell)
	while brooded.size() > count:
		brooded.pop_back().clear_cell()
	while brooded.size() < count:
		var free_cell: Node2D = null
		for cell in _built_cells(main):
			if cell.content_type == "" and cell.amount <= 0.0:
				free_cell = cell
				break
		if free_cell == null:
			push_error("challenge_stage_setup: no empty cell for an egg")
			return
		free_cell.start_brood(false)
		brooded.append(free_cell)

# --- queen and new worker -------------------------------------------

static func _apply_queen(main: Node2D, setup: Dictionary) -> void:
	var queen: Node2D = main.queen
	if setup.has("queen_role"):
		var role: int = Bee.Role.FORAGER if str(setup.queen_role) == "forager" else Bee.Role.EGG_LAYER
		if queen.role != role:
			queen._apply_role(role)
	if setup.has("queen_focus"):
		queen.resource_type = str(setup.queen_focus)
		queen.flower_cooldowns.clear()
	if setup.has("queen_load"):
		var amount: float = float(setup.queen_load.get("amount", 0.0))
		queen.current_load = amount
		queen.current_load_type = str(setup.queen_load.get("type", "")) if amount > 0.0 else ""
	queen._update_label()
	queen._update_role_marker()

static func _set_new_worker(runner: Node, main: Node2D, wanted: bool) -> void:
	var existing: Node2D = runner._new_worker
	if not wanted:
		if is_instance_valid(existing):
			existing._release_everything()
			main.selected_bees.erase(existing)
			# queue_free is deferred; leaving the group now stops the next
			# role count (and so 1.17's goal) still seeing her this frame.
			existing.remove_from_group("bees")
			existing.queue_free()
		runner._new_worker = null
		runner._greeting_active = false
		main.invalidate_population()
		return
	if is_instance_valid(existing):
		# Back into the hive if she was sent out and the arrow rewound her.
		main.world_building.move_bee_into_hive(existing)
		existing.state = Bee.State.IDLING
		return
	var built: Array = _built_cells(main)
	if built.is_empty():
		push_error("challenge_stage_setup: a new worker needs a cell to hatch from")
		return
	var bee: Node2D = main.world_building._spawn_hatched_bee(Bee.Role.FORAGER, built[0], false, "nectar")
	bee.position = main.queen.position + Stages.GREETING_REST_OFFSET
	bee.state = Bee.State.IDLING
	runner._new_worker = bee
	# The egg has hatched: leaving it would spawn a second worker later.
	_set_brood_cells(main, 0)
	main.invalidate_population()

static func _set_selection(runner: Node, main: Node2D, who: String) -> void:
	for bee in main.selected_bees:
		if is_instance_valid(bee):
			bee.set_selected(false)
	main.selected_bees.clear()
	var chosen: Node2D = null
	if who == "queen":
		chosen = main.queen
	elif who == "new_worker" and is_instance_valid(runner._new_worker):
		chosen = runner._new_worker
	if chosen != null:
		chosen.set_selected(true)
		main.selected_bees.append(chosen)
	main.hud.update_selection(main.selected_bees)
