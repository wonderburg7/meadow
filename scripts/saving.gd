extends Node
## Saving and loading a run. Split out of main.gd 14 Aug 2026 -- see
## MAIN_SPLIT_PLAN.md. Holds no state; reads and writes main's fields
## through the `main` reference.
##
## `save_run` is part of main.gd's public surface: debug_panel.gd finds
## main via the "world" group and calls `worlds[0].save_run()` directly,
## so main.gd keeps a one-line wrapper for it.

const SaveSlots = preload("res://scripts/save_slots.gd")

var main: Node2D

## Writes the player's own save to the run's named slot (SV-1). `run_name`
## renames the run first; left empty, the current run's name is used.
func save_run(run_name: String = "") -> void:
	if run_name != "":
		Session.run_name = run_name
	var slug := SaveSlots.slugify(Session.run_name)
	if main.SaveGame.save(main, SaveSlots.slot_path(slug)):
		SaveSlots.record_save(slug, Session.run_name, main.day)
		main.hud.show_warning("Run saved.")
	else:
		main.hud.show_warning("The run could not be saved — check the log for why.")

## Connected to main.gd's day_changed: every
## GameConfig.checkpoint_every_days days, writes the next of the run's three
## rotating checkpoints, never its named save. Runs on the day boundary only
## -- a save walks the whole world, so it must never hang off anything that
## fires more often. Challenges are skipped: tutorial_checkpoint.gd already
## gives them their own rollback, and a Challenge's checkpoints would push
## the player's own run's out of the rotation.
func checkpoint() -> void:
	if Session.starting_level in [1, 2]:
		return
	var every: int = maxi(1, int(GameConfig.checkpoint_every_days))
	if main.day % every != 0:
		return
	_write_checkpoint()

## FC-2: the checkpoint written immediately before the first crisis's
## warning (main.gd::_warn_first_crisis), outside the five-day cadence -- the
## next of the same three rotating files, never the named save. Once a run.
func crisis_checkpoint() -> bool:
	if Session.starting_level in [1, 2]:
		return false
	return _write_checkpoint()

func _write_checkpoint() -> bool:
	var slug := SaveSlots.slugify(Session.run_name)
	if main.SaveGame.save(main, SaveSlots.checkpoint(slug)):
		SaveSlots.record_checkpoint(slug, Session.run_name, main.day)
		return true
	return false

## Replays a saved run over the freshly built world. Order matters: the
## comb has to exist before bees can be pointed at it, and mined-out soil
## has to be removed before routes are rebuilt.
func _restore(data: Dictionary) -> void:
	if data.is_empty():
		main.hud.show_warning("There was no save to load.")
		return

	var clock: Dictionary = data.get("clock", {})
	Session.sim_time = float(clock.get("sim_time", 0.0))
	main.day = int(clock.get("day", 1))
	main.next_bee_id = int(clock.get("next_bee_id", 1))
	main.first_gyne_seen = bool(clock.get("first_gyne_seen", false))

	var weather: Dictionary = data.get("weather", {})
	Session.rain_intensity = float(weather.get("intensity", 0.0))
	main.rain_target = float(weather.get("target", 0.0))
	main.rain_seconds_left = float(weather.get("seconds_left", 0.0))

	var totals: Dictionary = data.get("totals", {})
	main.hive.lifetime_nectar_collected = float(totals.get("nectar", 0.0))
	main.hive.lifetime_pollen_collected = float(totals.get("pollen", 0.0))
	main.hive.lifetime_births = int(totals.get("births", 0))

	var session_state: Dictionary = data.get("session", {})
	Session.winter_coming = bool(session_state.get("winter_coming", false))
	Session.winter_starts_day = float(session_state.get("winter_starts_day", 0.0))
	Session.winter_here = bool(session_state.get("winter_here", false))
	Session.winter_ends_day = float(session_state.get("winter_ends_day", 0.0))
	Session.gynes_released = int(session_state.get("gynes_released", 0))
	Session.crab_spider_preferred_species = str(session_state.get("crab_spider_species", ""))
	if is_instance_valid(main.season):
		main.season.disease = clampf(float(session_state.get("disease", 0.0)), 0.0, 1.0)
	main.hud.set_winter_button_visible(Session.winter_coming)
	# After the winter fields and gynes_released: the season text reads them,
	# and a scene-reload load still holds the previous run's values until here.
	main.hud.update_day(main.day, main.year_winter._season_text())

	_restore_soil(data.get("soil", {}))
	_restore_cells(data.get("cells", []))
	_restore_hive_state(data.get("hive", {}))
	main.flower_grid.rebuild(_restore_flowers(data.get("flowers", [])))
	if is_instance_valid(main.rival) and data.get("rival") is Dictionary:
		main.rival.restore(data["rival"])
	var new_bees := _restore_bees(data.get("bees", []))
	main.fog_of_war.restore(data.get("fog", []))
	# PP-1: here rather than in main.gd, so an in-place checkpoint restore
	# puts the ledger back as exactly as a load does -- PP-4's seed counts
	# and waiting seeds with it.
	main.pollination.restore(data.get("pollination"))
	main.pollination.restore_seed(data.get("seed_bank"))
	# GD-2b: an older save has no guidance block, which intentionally clears
	# the ledger instead of treating a previously shown explanation as new.
	main.gallerin_panel.guidance_policy.restore(data.get("guidance", {}))
	main.SaveGame.restore_skills(data, Session.progression)
	# BS-3 (Dave, 30 Sep 2026): a save holds only the skills it recorded, and
	# one written before BS-1 has none of the run's seeded-role skills. What a
	# run starts owning comes from its definition, not the save, so those are
	# granted again on top -- an old level 4-6 or Challenge 1 save keeps its
	# nurses working without a save-version bump.
	if Session.progression != null:
		for skill_id in main.RunAvailability.starting_skills(main.Levels.get_level(Session.starting_level)):
			Session.progression.grant_temporary(str(skill_id))
		main.Availability.invalidate()

	main.hive.build_navigation()
	main.hive.refresh_edge_flags()
	main.hive.invalidate_index()
	main.hive.invalidate_stock()
	main.hive.announce()
	main._update_population_readout(new_bees)
	# FC-2: after the clock, which decides how a save without the record reads.
	main.restore_first_crisis(data.get("first_crisis"))
	main.hud.show_warning("Run loaded — day %d." % main.day)

func _restore_soil(soil: Dictionary) -> void:
	var still_there = {}
	for pair in soil.get("present", []):
		still_there[Vector2i(int(pair[0]), int(pair[1]))] = true

	var to_remove: Array = []
	for node in main.hive.occupied_tiles.values():
		if node == null or not is_instance_valid(node) or not node.is_in_group("soil_blocks"):
			continue
		if not still_there.has(node.axial):
			to_remove.append(node)

	var centre_local = main.world_building._hive_centre_local()
	var spacing: float = GameConfig.hive_cell_spacing
	for block in to_remove:
		var hex: Vector2i = block.axial
		main.hive.occupied_tiles.erase(hex)
		block.queue_free()
		main.world_building._add_floor_tile(hex, centre_local, spacing)

	# An in-place restore must also put back soil dug since the checkpoint.
	# _add_soil_block refuses an occupied tile, so a fresh load adds nothing.
	var added := false
	for hex in still_there.keys():
		if main.hive.tile_is_free(hex):
			main.world_building._add_soil_block(hex, centre_local, spacing)
			added = true
	if added:
		main.fog_of_war.notify_hive_open_space_changed()

	for entry in soil.get("marked", []):
		var hex = Vector2i(int(entry.q), int(entry.r))
		var node = main.hive.occupied_tiles.get(hex)
		if node != null and is_instance_valid(node) and node.is_in_group("soil_blocks"):
			node.mine_progress = float(entry.progress)
			node.set_marked(bool(entry.marked))

func _restore_cells(cells: Array) -> void:
	for cell in main.hive.cells:
		if is_instance_valid(cell):
			main.hive.occupied_tiles.erase(cell.axial)
			cell.queue_free()
	main.hive.cells = []

	var centre_local = main.world_building._hive_centre_local()
	var spacing: float = GameConfig.hive_cell_spacing
	for entry in cells:
		var hex = Vector2i(int(entry.q), int(entry.r))
		# A save's cell always wins the tile it says it's on, even if the
		# freshly built hive put soil or bedrock there instead -- which can
		# happen if the dig pattern has changed since the save was made
		# (see the hex-orientation/entrance change, 14 Aug 2026). Without
		# this, the old block's node keeps existing and drawing, just
		# untracked, which is a silent doubled-up tile rather than a crash.
		var occupant = main.hive.occupied_tiles.get(hex)
		if occupant != null and is_instance_valid(occupant):
			occupant.queue_free()
		main.hive.occupied_tiles.erase(hex)

		var cell = main.HiveCell.new()
		cell.axial = hex
		cell.main = main
		cell.position = centre_local + main.Shapes.hex_to_pixel(hex.x, hex.y, spacing, Session.use_sprite_hex_grid)
		main.hive_root.add_child(cell)

		cell.content_type = str(entry.get("content", ""))
		cell.amount = float(entry.get("amount", 0.0))
		cell.designated_type = str(entry.get("designated", ""))
		cell.designation_is_explicit = bool(entry.get("designation_explicit", false))
		cell.keep_empty = bool(entry.get("keep_empty", false))
		cell.evict_requested = bool(entry.get("evict", false))
		cell.evict_mode = str(entry.get("evict_mode", "move"))
		cell.is_built = bool(entry.get("built", true))
		cell.build_progress = float(entry.get("build_progress", 0.0))
		cell.brood_progress = float(entry.get("brood_progress", 0.0))
		cell.brood_fed_seconds = float(entry.get("brood_fed", 0.0))
		cell.unfed_seconds = float(entry.get("unfed", 0.0))
		cell.brood_is_gyne = bool(entry.get("gyne", false))
		# COL-9, additive: a save from before drones has none, and a cell
		# is never both.
		cell.brood_is_drone = bool(entry.get("drone", false)) and not cell.brood_is_gyne
		# BB-2, additive: a larva in a save from before BB-2 has been fed
		# pollen so far, and follows the rule from here on.
		cell.brood_food = ""
		if cell.content_type == "brood":
			cell.brood_food = str(entry.get("brood_food", "pollen"))
		cell.clean_progress = float(entry.get("clean", 0.0))
		cell.ripen_progress = float(entry.get("ripen", 0.0))
		# NF-2, additive: Session.sim_time is restored above, so a save from
		# before NF-2 gives its nectar a fresh stamp at the restore time.
		cell.nectar_since = -1.0
		if cell.content_type == "nectar":
			cell.nectar_since = float(entry.get("nectar_since", Session.sim_time))
		# BB-1, additive: a save from before BB-1 holds no bee bread, so it
		# has no stamp to restore.
		cell.bee_bread_sealed_at = -1.0
		if cell.content_type == "bee_bread":
			cell.bee_bread_sealed_at = float(entry.get("bee_bread_sealed_at", -1.0))
			cell.restore_bee_bread_seal()
		cell.hatch_role = int(entry.get("hatch_role", -1))
		cell.hatch_focus = str(entry.get("hatch_focus", "nectar"))
		cell.hatch_automine = bool(entry.get("hatch_automine", false))
		cell.hatch_role_locked = bool(entry.get("hatch_locked", false))
		cell.hatch_gyne = bool(entry.get("hatch_gyne", false))
		# PP-5, additive: a save from before PP-5 marks no cell.
		cell.priority_cell = bool(entry.get("priority_cell", false))
		cell.nursery_priority = int(entry.get("priority", 1))
		cell.is_closed = bool(entry.get("closed", false))
		cell.fill_then_close = bool(entry.get("fill_close", false))

		main.hive.cells.append(cell)
		main.hive.register_tile(hex, cell)

	# Every field above was written straight onto the cell rather than
	# through its mutator methods, so none of the invalidate_index() /
	# invalidate_stock() calls those methods make ran during restore --
	# the content buckets and stock totals both need one explicit bump
	# once the whole cell list is back, not per cell.
	main.hive.invalidate_index()
	main.hive.invalidate_stock()

func _restore_hive_state(state: Dictionary) -> void:
	main.hive.keep_clear_tiles.clear()
	for pair in state.get("keep_clear", []):
		main.hive.keep_clear_tiles[Vector2i(int(pair[0]), int(pair[1]))] = true
	var credit: Array = state.get("tier_credit", [])
	if credit.size() == 3:
		main.hive._tier_credit = [float(credit[0]), float(credit[1]), float(credit[2])]
	main.hive._brood_pointer = int(state.get("brood_pointer", 0))
	# T2-4b: the saved bodies replace the live ones, never add to them, so an
	# in-place checkpoint restore leaves exactly the saved count. An older
	# save has no "bodies" and loads with none.
	main.hive.clear_bodies()
	for entry in state.get("bodies", []):
		if entry is Dictionary:
			var body = main.hive.add_body(
				Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0))),
				float(entry.get("died_at", 0.0)))
			if body != null:
				body.clear_progress = float(entry.get("clear", 0.0))

func _cells_at(refs: Array) -> Array:
	var out: Array = []
	for pair in refs:
		var node = main.hive.occupied_tiles.get(Vector2i(int(pair[0]), int(pair[1])))
		if node != null and is_instance_valid(node) and node.is_in_group("hive_cells"):
			out.append(node)
	return out

func _blocks_at(refs: Array) -> Array:
	var out: Array = []
	for pair in refs:
		var node = main.hive.occupied_tiles.get(Vector2i(int(pair[0]), int(pair[1])))
		if node != null and is_instance_valid(node) and node.is_in_group("soil_blocks"):
			out.append(node)
	return out

## A bare `queue_free()` leaves a node visible to `get_nodes_in_group()`
## until the end of the frame -- fine for SpatialGrid (it already guards
## with `is_instance_valid`), but anything that counts or iterates a group
## mid-restore would catch the about-to-be-freed node alongside its
## replacement. Restore paths use this instead so the old node is gone
## from the group the instant it's called, not at end of frame.
func _retire_node(node: Node, group_name: String) -> void:
	node.remove_from_group(group_name)
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.queue_free()

## Returns the flowers it just created, so `_restore()` can hand them
## straight to `flower_grid.rebuild()` instead of re-querying the
## "flowers" group afterwards.
func _restore_flowers(flowers: Array) -> Array:
	for f in get_tree().get_nodes_in_group("flowers"):
		if is_instance_valid(f):
			_retire_node(f, "flowers")

	var created: Array = []
	for entry in flowers:
		var flower = main.Flower.new()
		flower.position = Vector2(float(entry.x), float(entry.y))
		main.meadow_root.add_child(flower)
		flower.setup(int(entry.species))
		flower.nectar_amount = float(entry.get("nectar", 0.0))
		flower.pollen_amount = float(entry.get("pollen", 0.0))
		flower.age_seconds = float(entry.get("age", 0.0))
		# PP-4, additive: a save from before it keeps setup()'s re-roll.
		if entry.has("lifespan"):
			flower.lifespan_seconds = maxf(1.0, float(entry.lifespan))
		# PP-1, additive: a save from before them loads zero.
		flower.compatible_visits = maxi(0, int(entry.get("compatible", 0)))
		flower.incompatible_visits = maxi(0, int(entry.get("incompatible", 0)))
		flower.award_ready_at = float(entry.get("award_ready_at", 0.0))
		created.append(flower)
	return created

## Returns the bees it just created, same reasoning as `_restore_flowers`
## above -- `_restore()` hands this straight to the population readout.
func _restore_bees(bees: Array) -> Array:
	for b in get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(b):
			_retire_node(b, "bees")
	main.queen = null
	main.selected_bees.clear()

	var created: Array = []
	for entry in bees:
		var bee = main.Bee.new()
		bee.is_queen = bool(entry.get("queen", false))
		bee.is_gyne = bool(entry.get("gyne", false))
		# COL-9, additive: a save from before them loads every queen mated
		# and nothing a drone. Set before the bee enters the tree, so
		# _ready() draws a drone at his own size.
		bee.is_drone = bool(entry.get("drone", false))
		bee.is_mated = bool(entry.get("mated", true))
		bee.position = Vector2(float(entry.x), float(entry.y))
		if bool(entry.get("indoors", false)):
			main.hive_root.add_child(bee)
		else:
			main.meadow_root.add_child(bee)

		bee.setup(main.hive, str(entry.get("resource", "nectar")), int(entry.get("id", 0)), int(entry.get("role", 0)), main)

		# Bee individuality -- restore the actual rolled identity rather
		# than the fresh random one _ready()/setup() just rolled for this
		# new node. _apply_stats() re-derives speed/collection rates/etc
		# from the restored trait so a reload lands on the same numbers,
		# not a compounded or re-rolled trait. See BEE_INDIVIDUALITY_PLAN.md.
		bee.bee_name = str(entry.get("name", bee.bee_name))
		bee.trait_stat = str(entry.get("trait_stat", bee.trait_stat))
		bee.trait_percent = float(entry.get("trait_pct", bee.trait_percent))
		# BB-2, additive: a bee from a save made before BB-2 has no outcome,
		# so she lives out her life as today's worker (25 days, 100%).
		# set_brood_outcome runs _apply_stats.
		bee.set_brood_outcome(str(entry.get("brood_outcome", "")))
		bee.bee_fact = str(entry.get("fact", bee.bee_fact))
		bee.is_favourite = bool(entry.get("favourite", false))

		bee.state = int(entry.get("state", bee.state))
		bee.energy = float(entry.get("energy", GameConfig.energy_capacity))
		bee.age_seconds = float(entry.get("age", 0.0))
		# NF-3, additive: a save from before tipsiness loads every bee sober.
		bee.tipsy_time_left = maxf(0.0, float(entry.get("tipsy", 0.0)))
		bee.current_load = float(entry.get("load", 0.0))
		bee.current_load_type = str(entry.get("load_type", ""))
		bee.honey_load = float(entry.get("honey_load", 0.0))
		# BB-1, additive: a save from before BB-1 has no Fermenting bees.
		bee.fermenting = bool(entry.get("fermenting", false))
		bee.bee_bread_load = float(entry.get("bee_bread_load", 0.0))
		bee.dirt_load = float(entry.get("dirt", 0.0))
		bee.pollen_eaten = float(entry.get("pollen_eaten", 0.0))
		bee.nurse_pollen = float(entry.get("nurse_pollen", 0.0))
		bee.nurse_carb = float(entry.get("nurse_carb", 0.0))
		bee.nurse_carb_type = str(entry.get("nurse_carb_type", ""))
		bee.nurse_jelly = float(entry.get("nurse_jelly", 0.0))
		bee.nurse_bee_bread = float(entry.get("nurse_bee_bread", 0.0))
		bee.nurse_mode = str(entry.get("nurse_mode", "feed"))
		bee.architect_mode = str(entry.get("architect_mode", "both"))
		bee.automine = bool(entry.get("automine", false))
		bee.secondary_role = int(entry.get("secondary", -1))
		bee.finish_task_first = bool(entry.get("finish_first", false))
		bee.pending_role = int(entry.get("pending_role", -1))
		bee.preferred_species = str(entry.get("preferred", ""))
		var restored_start := Vector2(float(entry.get("start_x", INF)), float(entry.get("start_y", INF)))
		if restored_start.x != INF:
			bee.set_forage_start_point(restored_start, "save_restore")
		# Older saves have no search_anchor_x/y -- fall back to the
		# start point just restored above rather than INF, so a save made
		# before Slice 5 doesn't silently lose her anchor on first load.
		bee.local_search_anchor = Vector2(
			float(entry.get("search_anchor_x", bee.forage_start_point.x)),
			float(entry.get("search_anchor_y", bee.forage_start_point.y)))
		# Older saves (pre-Slice-6) have no known_patches at all -- an
		# empty array is the correct fallback, not an error, same as a
		# freshly spawned bee who hasn't fed anywhere yet.
		# known_patches is bee.gd's only Array[Vector2]-typed save field; a
		# bare `[]` literal assigned through this dynamically-typed `bee`
		# reference doesn't coerce to that type at runtime and throws, so
		# build the typed array locally and assign it once instead.
		var patches: Array[Vector2] = []
		for pair in entry.get("known_patches", []):
			if pair.size() == 2:
				patches.append(Vector2(float(pair[0]), float(pair[1])))
		bee.known_patches = patches
		# Older saves (pre-Slice-7) have neither key at all -- an empty
		# dictionary is correct, same as a bee who hasn't earned any
		# experience/confidence yet.
		bee.species_experience = entry.get("species_experience", {})
		bee.species_confidence = entry.get("species_confidence", {})
		# Forager-history save design (28 Aug 2026): older saves have
		# none of these three keys -- 0.0/0.0/0 is exactly a fresh bee's
		# starting value (see bee.gd), so falling back to it on an old
		# save is correct, not a loss.
		bee.avg_collection_rate = float(entry.get("avg_collection_rate", 0.0))
		bee.grace_rate_sum = float(entry.get("grace_rate_sum", 0.0))
		bee.trips_scored = int(entry.get("trips_scored", 0))

		bee.build_queue = []
		for pair in entry.get("build_queue", []):
			bee.build_queue.append(Vector2i(int(pair[0]), int(pair[1])))
		bee.has_manual_build_target = not bee.build_queue.is_empty()
		if bee.has_manual_build_target:
			bee.manual_build_hex = bee.build_queue[0]
		bee.mine_queue = _blocks_at(entry.get("mine_queue", []))

		var home: Array = entry.get("home_hex", [])
		if home.size() == 2:
			bee.set_home_hex(Vector2i(int(home[0]), int(home[1])))
		var mine_home: Array = entry.get("mine_home", [])
		if mine_home.size() == 2:
			bee.set_mine_home_hex(Vector2i(int(mine_home[0]), int(mine_home[1])))

		bee.restock_resource = str(entry.get("restock_resource", ""))
		bee.restock_targets = _cells_at(entry.get("restock_targets", []))
		bee.restock_sources = _cells_at(entry.get("restock_sources", []))
		bee.restock_blocked = _cells_at(entry.get("restock_blocked", []))

		if bee.is_queen:
			main.queen = bee

		created.append(bee)

	main.colony_lost = false
	# HO-13: a restored colony counts as having lived, so a save holding no
	# queen ends at once (HO-10 rule) wherever it was loaded from.
	main.queen_seen_alive = true
	return created
