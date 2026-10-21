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
const Availability = preload("res://scripts/availability.gd")
const SaveSlots = preload("res://scripts/save_slots.gd")

const SAVE_PATH := "user://meadow_save.json"
## Bumped 24 Sep 2026 (AP-4, plans/now/alpha-progression-spine.md): a save
## records the skills bought this run, under "skills". An older save has no
## such block; save_migrations.gd's _migrate_5_to_6 reads it as owning
## nothing, which is exactly what a save from before skills could be bought
## means.
##
## Previously bumped 1 Sep 2026: distinguish explicit cell designations from automatic
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
##
## Bumped 12 Sep 2026 (D1, plans/design/architecture-review.md): the eight
## balance fields named in save_migrations.gd's _migrate_4_to_5 moved from
## persist:"none" to persist:"run", so they now go in the save. An older
## save simply has none of them in its "settings" dict; the migration
## defaults each to GameConfig's own value rather than leaving that to be
## discovered as a missing-key default at restore time.
##
## Bumped 17 Oct 2026 (FC-2, Dave's decision): the first crisis's four
## GameConfig values (save_migrations.gd's MIGRATED_SETTINGS_V7) are saved
## with the run. An older save has none of them; _migrate_6_to_7 fills in
## GameConfig's defaults, which is how every older run behaved.
const FORMAT_VERSION := 7

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
		"starting_level": Session.starting_level,
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
		# FC-2: the first crisis's state (pending, warned, active or spent)
		# and the times that schedule it, so a load neither repeats nor skips
		# it. Additive: main.gd::restore_first_crisis reads a save without it.
		"first_crisis": world.first_crisis.duplicate(true),
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
			# T2-4b: dead bees on the floor, oldest first. Additive: an
			# older save has none and loads with none.
			"bodies": _bodies_data(world),
		},
		"session": {
			"winter_coming": Session.winter_coming,
			"winter_starts_day": Session.winter_starts_day,
			"winter_here": Session.winter_here,
			"winter_ends_day": Session.winter_ends_day,
			"gynes_released": Session.gynes_released,
			"crab_spider_species": Session.crab_spider_preferred_species,
			# WP-2, additive: the colony's default backup order. An older
			# save has none and loads Session.DEFAULT_BACKUP_ORDER.
			"backup_order_default": Session.backup_order_default.duplicate(),
		},
		"cells": _cells_data(world),
		"soil": _soil_data(world),
		"bees": _bees_data(world),
		"flowers": _flowers_data(world),
		"fog": world.fog_of_war.explored_list(),
		# GD-2b: diagnostic facts are recomputed after loading, but rendered
		# explanations must remain consumed and available through Why.
		"guidance": world.gallerin_panel.guidance_policy.save_data(),
		"skills": _skills_data(),
		"colony_milestones": world.colony_milestones.save_data(),
		# PP-1: Pollinator Points and Contribution. Additive: an older save
		# has none and restores both at zero (pollination.gd::restore).
		"pollination": world.pollination.save_data(),
		# PP-4: the year's seed counts, the counts this spring reads and the
		# seeds waiting to be planted. Additive: an older save has none and
		# restores none (pollination.gd::restore_seed).
		"seed_bank": world.pollination.seed_save_data(),
		# BS-14: the grants and bans this run's availability sheet was built
		# from, so a load does not re-read today's developer edits.
		"skill_policy": {
			"grants": Session.run_skill_grants.duplicate(),
			"bans": Session.run_skill_bans.duplicate(),
		},
	}
	if is_instance_valid(world.season):
		data["session"]["disease"] = world.season.disease
	if is_instance_valid(world.rival):
		data["rival"] = world.rival.save_data()
	# BS-14: says, at the top of the file, that developer edits changed this
	# run's level policy at its start. Absent otherwise.
	if Session.run_developer_changes:
		data["developer_changes"] = true

	# SI-3: all-or-nothing -- a failed write leaves the old save in place.
	return SaveSlots.write_atomic(path, JSON.stringify(data))

## T2-4b: each body's place (hive-view coordinates), time of death and how
## far a Comb worker has lifted it ("clear", as a cell saves "clean").
static func _bodies_data(world) -> Array:
	var out: Array = []
	for body in world.hive.bodies:
		if is_instance_valid(body):
			out.append({
				"x": body.position.x, "y": body.position.y,
				"died_at": body.died_at, "clear": body.clear_progress,
			})
	return out

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
			"drone": cell.brood_is_drone,
			# BB-2, additive: what the larva has been raised on so far.
			"brood_food": cell.brood_food if cell.content_type == "brood" else "",
			"clean": cell.clean_progress,
			"ripen": cell.ripen_progress,
			# NF-2: saving.gd reads it back for nectar cells only.
			"nectar_since": cell.nectar_since if cell.content_type == "nectar" else -1.0,
			# BB-1, additive: when a bee bread cell sealed (-1 while filling).
			"bee_bread_sealed_at": cell.bee_bread_sealed_at if cell.content_type == "bee_bread" else -1.0,
			"hatch_role": cell.hatch_role,
			"hatch_focus": cell.hatch_focus,
			"hatch_automine": cell.hatch_automine,
			"hatch_locked": cell.hatch_role_locked,
			"hatch_gyne": cell.hatch_gyne,
			# PP-5, additive: the "Feed first" mark.
			"priority_cell": cell.priority_cell,
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
		var at: Vector2 = b.saved_position()   # NF-3: the task's spot, mid-wander
		var entry := {
			"id": b.bee_id,
			"queen": b.is_queen,
			"gyne": b.is_gyne,
			"drone": b.is_drone,
			"mated": b.is_mated,
			"indoors": b.get_parent() == world.hive_root,
			"x": at.x, "y": at.y,
			"role": b.role,
			"state": b.saved_state(),
			"resource": b.resource_type,
			"energy": b.energy,
			"age": b.age_seconds,
			# NF-3, additive: seconds of tipsiness left. An older save has
			# none, and saving.gd loads that bee sober.
			"tipsy": b.tipsy_time_left,
			"load": b.current_load,
			"load_type": b.current_load_type,
			"honey_load": b.honey_load,
			# BB-1, additive: the Fermenting mode and any bee bread carried.
			"fermenting": b.fermenting,
			"bee_bread_load": b.bee_bread_load,
			"dirt": b.dirt_load,
			"pollen_eaten": b.pollen_eaten,
			"nurse_pollen": b.nurse_pollen,
			"nurse_carb": b.nurse_carb,
			"nurse_carb_type": b.nurse_carb_type,
			"nurse_jelly": b.nurse_jelly,
			# BB-2, additive: ripe bee bread a nurse carries.
			"nurse_bee_bread": b.nurse_bee_bread,
			"nurse_mode": b.nurse_mode,
			"architect_mode": b.architect_mode,
			"automine": b.automine,
			"secondary": b.secondary_role,
			# WP-2, additive: the bee's ordered backup jobs (empty until the
			# colony owns Work priorities). An older save has none, and the
			# bee's backup goes first, then the colony default.
			"backup_order": b.backup_order.duplicate(),
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
			# BB-2: the stats her trait and outcome give her. A readout for
			# diagnostics and tests only -- never read back, since
			# _apply_stats re-derives them on restore.
			"stats": {
				"speed": b.speed,
				"nectar_capacity": b.nectar_stomach_capacity,
				"pollen_capacity": b.pollen_stomach_capacity,
				"lifespan_days": b.BeeSurvival.lifespan_seconds(b) / GameConfig.seconds_per_day,
			},
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
		# BB-2, additive: written only for a worker raised since BB-2. A bee
		# with no outcome is saved exactly as a pre-BB-2 save holds her, so
		# every load of one goes through saving.gd's old-save default.
		if b.brood_outcome != "":
			entry["brood_outcome"] = b.brood_outcome
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
			# PP-4, additive: without it a load re-rolls the lifespan, and a
			# flower already older than its new one dies (and replants) at
			# once. An older save keeps that re-roll.
			"lifespan": f.lifespan_seconds,
			# PP-1, additive: an older save loads both counts at zero and
			# the pollination window open.
			"compatible": f.compatible_visits,
			"incompatible": f.incompatible_visits,
			"award_ready_at": f.award_ready_at,
		})
	return out

# --- reading -------------------------------------------------------

## Returns the parsed save, or an empty dictionary if there isn't one or
## it can't be read. main.gd stashes this and applies it after it has
## rebuilt the world, because the settings have to be in place *before*
## the hive geometry is laid out. `path` defaults to the player's own
## save slot, same as save() above.
static func read(path: String = SAVE_PATH) -> Dictionary:
	# SI-3: a crash between the replace's remove and rename leaves only .tmp.
	if not has_save(path):
		if not FileAccess.file_exists(path + ".tmp"):
			return {}
		path = path + ".tmp"
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

## AP-4: the skills bought this run. Only temporary ownership is saved --
## branch-tier progress is worked out from what is owned, and mastered
## ownership, adaptations, milestones and familiarity are later steps'
## (progression.md section 11), so nothing is written for them.
static func _skills_data() -> Dictionary:
	var bought: Array = []
	var progression = Session.progression
	if progression != null:
		for skill_id in progression.owned_ids():
			if progression.is_temporary(skill_id):
				bought.append(skill_id)
	return {"temporary": bought}

## Called by saving.gd::_restore once the world is rebuilt: the run owns
## exactly what the save says it bought, no more. end_run() drops whatever
## this run held before the replay, which is what a Challenge rollback
## wants too. Availability's cached action answers are asked again after.
static func restore_skills(data: Dictionary, progression) -> void:
	if progression == null:
		return
	progression.end_run()
	for skill_id in data.get("skills", {}).get("temporary", []):
		progression.grant_temporary(str(skill_id))
	Availability.invalidate()

## CR-2 (plans/now/colony-run.md): the day each Colony Run milestone was first
## met, as main.gd hands it to colony_milestones.gd::restore after the world is
## replayed. An additive field, with no FORMAT_VERSION bump and no migration,
## like CR-1's starting_level: a save without it -- or with something other
## than a dictionary there -- reads as nothing met.
static func milestone_days(data: Dictionary) -> Dictionary:
	var days = data.get("colony_milestones")
	if typeof(days) != TYPE_DICTIONARY:
		return {}
	return days

## Puts the saved tuning values back before anything is built, so the
## world comes out the same shape it was saved in.
static func apply_settings(data: Dictionary) -> void:
	var settings: Dictionary = data.get("settings", {})
	for key in settings.keys():
		if GameConfig.get(key) != null or typeof(settings[key]) == TYPE_BOOL:
			GameConfig.set(key, settings[key])

## CR-1 (plans/now/colony-run.md decision 1): puts back which run the save
## belongs to before the world is rebuilt, so a Colony Run save reloads as a
## Colony Run rather than inside whatever level is current. An additive field,
## with no FORMAT_VERSION bump and no migration: a save without it leaves
## Session.starting_level as it is, which is how every save loaded before the
## field existed. JSON hands numbers back as floats, hence the int().
##
## A save made in Challenge 1 or 2 keeps the current level instead, exactly
## as before this field: main.gd::_ready never starts the stage runner on a
## load, so restoring level 1 or 2 would switch on the Challenge-only
## branches (no checkpoints, and the rest of `starting_level in [1, 2]`)
## with no Challenge running. Challenges roll back through their own
## tutorial_checkpoint.gd, which never comes through here.
const CHALLENGE_LEVELS := [1, 2]

static func apply_starting_level(data: Dictionary) -> void:
	var saved = data.get("starting_level")
	if typeof(saved) != TYPE_INT and typeof(saved) != TYPE_FLOAT:
		return
	if int(saved) in CHALLENGE_LEVELS:
		return
	Session.starting_level = int(saved)

## BS-14 (plans/now/brood-spine.md): puts back the skill grants and bans the
## saved run's availability sheet was built from, and whether developer edits
## made them, for main.gd's run_definition to use instead of the overrides
## file as it stands at load time. Called next to apply_starting_level,
## before the world is rebuilt. An additive field, with no FORMAT_VERSION bump
## and no migration, like CR-1's starting_level: a save without it -- or with
## something other than a dictionary there -- leaves nothing pending, so the
## run starts exactly as before the field. The saved level rides along, so a
## Challenge save, which keeps the current level, never hands its policy to
## a different level.
static func apply_skill_policy(data: Dictionary) -> void:
	Session.pending_skill_policy = {}
	var policy = data.get("skill_policy")
	var saved_level = data.get("starting_level")
	if typeof(policy) != TYPE_DICTIONARY:
		return
	if typeof(saved_level) != TYPE_INT and typeof(saved_level) != TYPE_FLOAT:
		return
	var changes = data.get("developer_changes")
	Session.pending_skill_policy = {
		"level": int(saved_level),
		"grants": _skill_ids(policy.get("grants")),
		"bans": _skill_ids(policy.get("bans")),
		"developer_changes": typeof(changes) == TYPE_BOOL and changes,
	}

## Skill id strings out of whatever a save's list held.
static func _skill_ids(value) -> Array:
	var ids: Array = []
	if typeof(value) != TYPE_ARRAY:
		return ids
	for item in value:
		if typeof(item) == TYPE_STRING and not ids.has(item):
			ids.append(item)
	return ids
