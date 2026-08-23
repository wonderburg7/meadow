extends RefCounted
## Saving and loading a run.
##
## The save is a plain JSON dictionary written to `user://`, which Godot
## maps to a per-user application folder, so saves survive the project
## being moved or rebuilt.
##
## The approach is deliberately "record the dynamic state, replay it onto
## a freshly built world" rather than trying to serialise the scene tree.
## main.gd already knows how to build a hive, a meadow and a bee from
## numbers; loading just builds one and then overwrites what it made with
## what was recorded. That keeps the save format independent of node
## structure, so rearranging scenes doesn't invalidate saved games.
##
## What is *not* saved: the exact layout of soil that has never been
## touched, and cosmetic scenery. Those are regenerated from the same
## fixed seed, so they come back identical anyway.

const SAVE_PATH := "user://meadow_save.json"
## Bumped 16 Aug 2026: added fog of war's explored-cells map. A save from
## before this version simply has no "fog" key, and read() below already
## warns rather than refusing outright -- _restore_fog treats a missing
## key as "nothing explored yet" rather than erroring, so an old save
## still loads, just re-fogged.
##
## Previously bumped 14 Aug 2026: the hive geometry changed (flat-top
## hexes, corner entrance) so a save from before that version was dug and
## tunnelled differently. _restore_cells defends against a save's cell
## landing on what the fresh dig now considers soil.
const FORMAT_VERSION := 3

## Every GameConfig field worth carrying across.
##
## Balance numbers only. The player's interface preferences (starred
## readouts, info badges, colour-blind mode) deliberately stay out of the
## save: they belong to the player, not the run, and loading someone
## else's save should not rearrange your screen. Those live in Session.
const SAVED_SETTINGS := [
	"flower_count", "hive_cell_count", "starting_bees", "starting_nurses",
	"starting_builders", "starting_miners", "starting_honey_makers",
	"seconds_per_day", "nectar_recharge_rate", "pollen_recharge_rate",
	"tarsal_markers_on", "tarsal_marker_seconds", "floral_constancy_on",
	# Orientation flight/scouting/auto-recruitment were missing from this
	# list entirely -- same gap as the winter numbers below: tuning any of
	# them in the panel didn't survive a save/load, and a scenario's
	# config_overrides (checked against this same list -- see
	# Levels.apply_config_overrides) couldn't turn them on either.
	"orientation_flight_on", "scouting_on", "auto_recruitment_on",
	"forage_start_radius", "forage_search_radius",
	"recruit_lower_threshold_nectar", "recruit_upper_threshold_nectar",
	"recruit_lower_threshold_pollen", "recruit_upper_threshold_pollen",
	"recruit_wait_seconds", "recruit_grace_trips", "recruit_start_point_jitter",
	"bee_speed", "flower_handling_time", "nectar_collection_rate",
	"pollen_collection_rate", "deposit_time", "nectar_stomach_capacity",
	"pollen_stomach_capacity", "cell_capacity", "cell_full_threshold",
	"egg_pollen_cost", "queen_eat_rate", "queen_speed_factor",
	"brood_develop_time", "tending_speed_bonus", "brood_feed_seconds",
	"brood_feed_seconds_honey", "brood_feed_pollen", "brood_feed_nectar",
	"brood_feed_honey", "brood_feed_threshold", "larva_death_seconds",
	"cell_clean_time", "nurse_carry_feeds", "nurse_load_time",
	"hunger_threshold", "bee_eat_rate", "flight_energy_burn",
	"forager_drink_threshold", "nectar_drink_rate", "crop_drink_threshold",
	"gyne_size_factor", "gyne_speed_factor", "gyne_energy_factor",
	"gyne_egg_pollen_cost", "gyne_develop_multiplier", "brood_feed_jelly",
	"brood_feed_seconds_gyne", "jelly_pollen_cost", "jelly_honey_cost",
	"jelly_make_time", "jelly_per_batch", "jelly_cell_capacity",
	"weather_on", "rain_chance_per_day", "rain_min_seconds",
	"rain_max_seconds", "rain_nectar_dilution", "rain_flight_burn_factor",
	"rain_forage_limit", "honey_cell_capacity", "honey_energy_factor",
	"nectar_per_honey", "honey_chew_time", "honey_ripen_time",
	"honey_rewet_factor", "block_mine_time", "miner_dirt_capacity",
	"dirt_fill_rate", "dirt_dump_time", "cell_build_time",
	"build_energy_burn", "hive_interior_rings", "hive_soil_depth",
	"hive_rock_rings", "hive_entrance_width", "hive_cell_size",
	"hive_cell_spacing", "cell_slow_factor", "bee_lifespan_days",
	"energy_capacity", "energy_burn_rate",
	"low_energy_warning_fraction", "low_energy_warning_level",
	"low_energy_gap",
	# The winter numbers were missing from this list entirely -- tuning
	# any of them in the panel didn't survive a save/load. Added together
	# rather than just the new one, since the gap applied to all four.
	"winter_countdown_days", "winter_length_days",
	"winter_burn_factor", "winter_lifespan_factor",
	# Bee individuality.
	"trait_positive_chance", "trait_magnitude_bands",
	"fact_trait_matched_chance", "fact_general_chance", "fact_templated_chance",
	"visual_size_jitter_range", "visual_tint_jitter_range",
	"milestone_interval", "epitaph_min_gap",
	# Crab spiders. Added so a --scenario= file can turn predators on
	# via config_overrides (AI_PLAYTEST_PLAN.md slice 6) -- overrides
	# are checked against this same list, so it doubles as making
	# predators_on/attack chance survive an ordinary save/load too,
	# which they didn't before.
	"predators_on", "crab_spider_attack_success_chance",
	# Slices 5/6 (local search, probabilistic choice/patch memory) were
	# missing from this list entirely, same gap as orientation/scouting
	# and the winter numbers above -- discovered while adding Slice 7's
	# own new keys below. Added together so tuning any of these in the
	# panel, or turning them on via a scenario's config_overrides, now
	# actually survives a save/load.
	"forage_perception_radius", "local_search_drift_rate",
	"forage_search_spiral_step", "forage_search_angle_step",
	"probabilistic_choice_on", "probabilistic_choice_heading_weight",
	"known_patches_max", "known_patch_min_spacing",
	# Slice 7 (handling experience, adaptive constancy).
	"handling_experience_on", "handling_experience_floor",
	"handling_experience_visits_to_floor",
	"adaptive_constancy_on", "adaptive_constancy_gain",
	"adaptive_constancy_decay", "adaptive_constancy_weight",
]

static func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)

# --- writing -------------------------------------------------------

## `path` defaults to the player's own save slot. tutorial_checkpoint.gd
## passes its own path so a Challenge's automatic checkpoints never touch
## the player's save.
static func save(world, path: String = SAVE_PATH) -> bool:
	var data := {
		"version": FORMAT_VERSION,
		"settings": _settings_dict(),
		"clock": {
			"sim_time": Session.sim_time,
			"day": world.day,
			"next_bee_id": world.next_bee_id,
			"first_gyne_seen": world.first_gyne_seen,
		},
		"weather": {
			"intensity": Session.rain_intensity,
			"target": world.rain_target,
			"seconds_left": world.rain_seconds_left,
		},
		"totals": {
			"nectar": world.hive.lifetime_nectar_collected,
			"pollen": world.hive.lifetime_pollen_collected,
			"births": world.hive.lifetime_births,
		},
		"hive": {
			# Reserved open ground and the queen's laying credit. Neither
			# was saved before, so a loaded run quietly forgot which
			# tiles were meant to stay clear and restarted the priority
			# share-out from zero.
			"keep_clear": _hex_list(world.hive.keep_clear_tiles.keys()),
			"tier_credit": world.hive._tier_credit,
			"brood_pointer": world.hive._brood_pointer,
		},
		"session": {
			"winter_coming": Session.winter_coming,
			"winter_starts_day": Session.winter_starts_day,
			"winter_here": Session.winter_here,
			"winter_ends_day": Session.winter_ends_day,
			"gynes_released": Session.gynes_released,
		},
		"cells": _cells_data(world),
		"soil": _soil_data(world),
		"bees": _bees_data(world),
		"flowers": _flowers_data(world),
		"fog": world.fog_of_war.explored_list(),
	}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open the save file for writing: %s" % path)
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true

static func _settings_dict() -> Dictionary:
	var out := {}
	for key in SAVED_SETTINGS:
		out[key] = GameConfig.get(key)
	return out

static func _cells_data(world) -> Array:
	var out: Array = []
	for cell in world.hive.cells:
		if not is_instance_valid(cell):
			continue
		out.append({
			"q": cell.axial.x, "r": cell.axial.y,
			"content": cell.content_type,
			"amount": cell.amount,
			"designated": cell.designated_type,
			"keep_empty": cell.keep_empty,
			"evict": cell.evict_requested,
			"evict_mode": cell.evict_mode,
			"built": cell.is_built,
			"build_progress": cell.build_progress,
			"brood_progress": cell.brood_progress,
			"brood_fed": cell.brood_fed_seconds,
			"unfed": cell.unfed_seconds,
			"gyne": cell.brood_is_gyne,
			"clean": cell.clean_progress,
			"ripen": cell.ripen_progress,
			"hatch_role": cell.hatch_role,
			"hatch_focus": cell.hatch_focus,
			"hatch_automine": cell.hatch_automine,
			"hatch_locked": cell.hatch_role_locked,
			"hatch_gyne": cell.hatch_gyne,
			"priority": cell.nursery_priority,
			"closed": cell.is_closed,
			"fill_close": cell.fill_then_close,
		})
	return out

## Only blocks that differ from a fresh layout need recording: which have
## been dug out entirely, and which are marked or part-dug.
static func _soil_data(world) -> Dictionary:
	var marked: Array = []
	var present: Array = []
	for node in world.hive.occupied_tiles.values():
		if node == null or not is_instance_valid(node) or not node.is_in_group("soil_blocks"):
			continue
		present.append([node.axial.x, node.axial.y])
		if node.marked_for_mining or node.mine_progress > 0.0:
			marked.append({
				"q": node.axial.x, "r": node.axial.y,
				"marked": node.marked_for_mining,
				"progress": node.mine_progress,
			})
	return {"present": present, "marked": marked}

static func _bees_data(world) -> Array:
	var out: Array = []
	for b in world.get_tree().get_nodes_in_group("bees"):
		if not is_instance_valid(b):
			continue
		out.append({
			"id": b.bee_id,
			"queen": b.is_queen,
			"gyne": b.is_gyne,
			"indoors": b.get_parent() == world.hive_root,
			"x": b.position.x, "y": b.position.y,
			"role": b.role,
			"state": b.state,
			"resource": b.resource_type,
			"energy": b.energy,
			"age": b.age_seconds,
			"load": b.current_load,
			"load_type": b.current_load_type,
			"honey_load": b.honey_load,
			"dirt": b.dirt_load,
			"pollen_eaten": b.pollen_eaten,
			"nurse_pollen": b.nurse_pollen,
			"nurse_carb": b.nurse_carb,
			"nurse_carb_type": b.nurse_carb_type,
			"nurse_jelly": b.nurse_jelly,
			"nurse_mode": b.nurse_mode,
			"architect_mode": b.architect_mode,
			"automine": b.automine,
			"secondary": b.secondary_role,
			"finish_first": b.finish_task_first,
			"pending_role": b.pending_role,
			"preferred": b.preferred_species,
			"start_x": b.forage_start_point.x,
			"start_y": b.forage_start_point.y,
			"search_anchor_x": b.local_search_anchor.x,
			"search_anchor_y": b.local_search_anchor.y,
			# Slice 6 patch memory: array of [x, y] pairs, most recent
			# last, same order as bee.known_patches and the same [x, y]
			# shape _hex_list already uses below.
			"known_patches": _point_list(b.known_patches),
			# Slice 7: plain String->number dictionaries, already
			# JSON-safe as-is -- no [x,y]-pair helper needed like the
			# points above.
			"species_experience": b.species_experience,
			"species_confidence": b.species_confidence,
			# Bee individuality -- see BEE_INDIVIDUALITY_PLAN.md. Without
			# these, reloading a save would silently re-roll every bee's
			# name, fact and trait, which breaks the whole point.
			"name": b.bee_name,
			"fact": b.bee_fact,
			"trait_stat": b.trait_stat,
			"trait_pct": b.trait_percent,
			"favourite": b.is_favourite,
			# A bee's own orders. These were being lost on save, so a
			# player who had spent time laying out a build order or a
			# restocking plan reloaded to find it gone -- silent data
			# loss, which is the worst kind.
			"build_queue": _hex_list(b.build_queue),
			"mine_queue": _cell_refs(b.mine_queue),
			"home_hex": [b.home_hex.x, b.home_hex.y] if b.has_home_hex else [],
			"mine_home": [b.mine_home_hex.x, b.mine_home_hex.y] if b.has_mine_home else [],
			"restock_resource": b.restock_resource,
			"restock_targets": _cell_refs(b.restock_targets),
			"restock_sources": _cell_refs(b.restock_sources),
			"restock_blocked": _cell_refs(b.restock_blocked),
		})
	return out

## Hexes as flat pairs, which is all JSON can carry.
static func _hex_list(hexes: Array) -> Array:
	var out: Array = []
	for hex in hexes:
		out.append([hex.x, hex.y])
	return out

## Same [x, y]-pairs shape as _hex_list above, for a plain Array[Vector2]
## rather than hex coordinates -- see bee.known_patches (Slice 6).
static func _point_list(points: Array) -> Array:
	var out: Array = []
	for p in points:
		out.append([p.x, p.y])
	return out

## Cells are referred to by their tile, not by node, since the nodes are
## rebuilt from scratch on load.
static func _cell_refs(cells: Array) -> Array:
	var out: Array = []
	for cell in cells:
		if is_instance_valid(cell):
			out.append([cell.axial.x, cell.axial.y])
	return out

static func _flowers_data(world) -> Array:
	var out: Array = []
	for f in world.get_tree().get_nodes_in_group("flowers"):
		if not is_instance_valid(f):
			continue
		out.append({
			"x": f.position.x, "y": f.position.y,
			"species": f.species_index,
			"nectar": f.nectar_amount,
			"pollen": f.pollen_amount,
			"age": f.age_seconds,
		})
	return out

# --- reading -------------------------------------------------------

## Returns the parsed save, or an empty dictionary if there isn't one or
## it can't be read. main.gd stashes this and applies it after it has
## rebuilt the world, because the settings have to be in place *before*
## the hive geometry is laid out. `path` defaults to the player's own
## save slot, same as save() above.
static func read(path: String = SAVE_PATH) -> Dictionary:
	if not has_save(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("The save file is not readable.")
		return {}
	var save_version := int(parsed.get("version", 0))
	if save_version > FORMAT_VERSION:
		# A save from a newer build may use fields this version doesn't
		# know to restore -- rather than silently dropping them, refuse
		# the load outright and leave the current world untouched.
		push_error("Save file is from a newer version of the game (%d, this build reads %d) and cannot be loaded." % [save_version, FORMAT_VERSION])
		return {}
	if save_version != FORMAT_VERSION:
		push_warning("Save file is from a different version of the game; loading it may not work.")
	return parsed

## Puts the saved tuning values back before anything is built, so the
## world comes out the same shape it was saved in.
static func apply_settings(data: Dictionary) -> void:
	var settings: Dictionary = data.get("settings", {})
	for key in settings.keys():
		if GameConfig.get(key) != null or typeof(settings[key]) == TYPE_BOOL:
			GameConfig.set(key, settings[key])
