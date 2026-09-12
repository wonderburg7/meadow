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

const SaveMigrations = preload("res://scripts/save_migrations.gd")
const SettingsCatalogue = preload("res://scripts/settings_catalogue.gd")

const SAVE_PATH := "user://meadow_save.json"
## Bumped 1 Sep 2026: distinguish explicit cell designations from automatic
## first-use assignments, so an automatically assigned cell returns to the
## neutral pool when fully emptied.
##
## Previously bumped 16 Aug 2026: added fog of war's explored-cells map. A save from
## before this version simply has no "fog" key, and read() below already
## warns rather than refusing outright -- _restore_fog treats a missing
## key as "nothing explored yet" rather than erroring, so an old save
## still loads, just re-fogged.
##
## Previously bumped 14 Aug 2026: the hive geometry changed (flat-top
## hexes, corner entrance) so a save from before that version was dug and
## tunnelled differently. _restore_cells defends against a save's cell
## landing on what the fresh dig now considers soil.
const FORMAT_VERSION := 4

## Every GameConfig field worth carrying across, derived from
## settings_catalogue.gd's TUNABLES rather than hand-maintained here --
## see each row's "persist" field ("run" goes in the save, "player" is a
## Session preference that never does, "none" is neither). This function's
## result is byte-identical to the literal list it replaced (D1,
## plans/design/architecture-review.md); a mismatch between a row's
## "persist" tag and what a save actually needs is now a single place to
## fix, checked in tests/source_checks.py, rather than three.
##
## The player's interface preferences (starred readouts, info badges,
## colour-blind mode) deliberately stay out of the save: they belong to
## the player, not the run, and loading someone else's save should not
## rearrange your screen. Those live in Session, tagged "player".
static func saved_settings() -> Array:
	var keys: Array = []
	for entry in SettingsCatalogue.TUNABLES:
		if entry.get("persist", "none") == "run":
			keys.append(entry.key)
	return keys

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
	for key in saved_settings():
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
			"designation_explicit": cell.designation_is_explicit,
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
		var entry := {
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
			# Slice 6 patch memory: array of [x, y] pairs, most recent
			# last, same order as bee.known_patches and the same [x, y]
			# shape _hex_list already uses below.
			"known_patches": _point_list(b.known_patches),
			# Slice 7: plain String->number dictionaries, already
			# JSON-safe as-is -- no [x,y]-pair helper needed like the
			# points above.
			"species_experience": b.species_experience,
			"species_confidence": b.species_confidence,
			# Forager-history save design (28 Aug 2026): recruitment's
			# rolling collection-rate history. Additive, same pattern as
			# the Slice 6/7 fields above -- no FORMAT_VERSION bump.
			"avg_collection_rate": b.avg_collection_rate,
			"grace_rate_sum": b.grace_rate_sum,
			"trips_scored": b.trips_scored,
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
		}
		# Unset until a bee's first forage bout, both default to
		# Vector2(INF, INF) (bee.gd) -- omit rather than write a value that
		# only round-trips via JSON's exponent-clamped 1e99999 encoding of
		# an unrepresentable double, which floods the console with
		# "Exponent too high" on every load. Read side (saving.gd) already
		# treats a missing key as unset via entry.get(key, INF).
		if b.forage_start_point.x != INF:
			entry["start_x"] = b.forage_start_point.x
			entry["start_y"] = b.forage_start_point.y
		if b.local_search_anchor.x != INF:
			entry["search_anchor_x"] = b.local_search_anchor.x
			entry["search_anchor_y"] = b.local_search_anchor.y
		out.append(entry)
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
	# Bridges any known older format up to FORMAT_VERSION before saving.gd
	# ever sees it -- a no-op for a save that's already current (Slice 5,
	# CHATGPT_EFFICIENCY_IMPLEMENTATION_PLAN.md).
	return SaveMigrations.upgrade(parsed, FORMAT_VERSION)

## Puts the saved tuning values back before anything is built, so the
## world comes out the same shape it was saved in.
static func apply_settings(data: Dictionary) -> void:
	var settings: Dictionary = data.get("settings", {})
	for key in settings.keys():
		if GameConfig.get(key) != null or typeof(settings[key]) == TYPE_BOOL:
			GameConfig.set(key, settings[key])
