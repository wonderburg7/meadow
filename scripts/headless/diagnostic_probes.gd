## Allowlisted, low-cost snapshot probes for scenario diagnostics.
class_name HeadlessDiagnosticProbes
extends RefCounted

const SNAPSHOT_FIELDS := ["population.total", "resources.food_stores", "resources.stored_nectar", "resources.stored_pollen", "environment.winter_here", "environment.flowers_by_species", "environment.flowers_in_season", "environment.flowers_out_of_season", "role_outcomes.cells_completed_total", "performance.fps", "performance.top_sections_ms", "colony.milestone_days", "resources.first_tier2_affordable", "resources.gyne_rearing_affordable"]

static func selected_snapshot(world: Node2D, fields: Array, counters: Dictionary) -> Dictionary:
	var snapshot := {"type": "snapshot", "game_time": Session.sim_time, "day": world.day}
	for field_variant: Variant in fields:
		var field: String = str(field_variant)
		match field:
			"population.total": _merge_field(snapshot, "population", "total", _live_bee_count(world))
			"resources.food_stores": _merge_field(snapshot, "resources", "food_stores", world.hive.total_honey())
			"resources.stored_nectar": _merge_field(snapshot, "resources", "stored_nectar", world.hive.total("nectar"))
			"resources.stored_pollen": _merge_field(snapshot, "resources", "stored_pollen", world.hive.total("pollen"))
			"resources.first_tier2_affordable": _merge_field(snapshot, "resources", "first_tier2_affordable", first_tier2_affordable(world.hive))
			"resources.gyne_rearing_affordable": _merge_field(snapshot, "resources", "gyne_rearing_affordable", gyne_rearing_affordable(world))
			"environment.winter_here": _merge_field(snapshot, "environment", "winter_here", Session.winter_here)
			"environment.flowers_by_species": _merge_field(snapshot, "environment", "flowers_by_species", flower_season_counts(world).by_species)
			"environment.flowers_in_season": _merge_field(snapshot, "environment", "flowers_in_season", flower_season_counts(world).in_season)
			"environment.flowers_out_of_season": _merge_field(snapshot, "environment", "flowers_out_of_season", flower_season_counts(world).out_of_season)
			"role_outcomes.cells_completed_total": _merge_field(snapshot, "role_outcomes", "cells_completed_total", int(counters.get("cells_completed", 0)))
			"performance.fps": _merge_field(snapshot, "performance", "fps", Engine.get_frames_per_second())
			"performance.top_sections_ms": _merge_field(snapshot, "performance", "top_sections_ms", top_sections_ms(8))
			"colony.milestone_days":
				var milestone_days: Dictionary = {}
				if is_instance_valid(world.colony_milestones) and world.colony_milestones.applies():
					milestone_days = world.colony_milestones.met_days.duplicate()
				_merge_field(snapshot, "colony", "milestone_days", milestone_days)
	return snapshot

## Adds one field into the snapshot's group dictionary, creating the group on
## first use, so two fields from the same group don't overwrite each other.
static func _merge_field(snapshot: Dictionary, group: String, key: String, value: Variant) -> void:
	if not snapshot.has(group):
		snapshot[group] = {}
	snapshot[group][key] = value

static func _live_bee_count(world: Node2D) -> int:
	var count := 0
	for bee: Variant in world.get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(bee): count += 1
	return count

static func flower_season_counts(world: Node2D) -> Dictionary:
	var in_season := 0
	var out_of_season := 0
	var by_species: Dictionary = {}
	for flower: Variant in world.get_tree().get_nodes_in_group("flowers"):
		if not is_instance_valid(flower):
			continue
		by_species[flower.species_name] = int(by_species.get(flower.species_name, 0)) + 1
		if flower.in_season():
			in_season += 1
		else:
			out_of_season += 1
	return {"in_season": in_season, "out_of_season": out_of_season, "by_species": by_species}


static func first_tier2_affordable(hive: Object) -> bool:
	if Session.progression == null:
		return false
	var stores := {"honey": hive.total_honey(), "nectar": hive.total("nectar"), "pollen": hive.total("pollen")}
	return Session.progression.first_tier2_path_covered(stores)


## PP-6: the stores, bee bread, jelly and Pollinator points cover Gyne rearing's
## whole path from zero (progression.gd::gyne_rearing_path_covered).
static func gyne_rearing_affordable(world: Node2D) -> bool:
	if Session.progression == null:
		return false
	var points := 0.0
	if world.pollination != null:
		points = float(world.pollination.points)
	var stores := {"honey": world.hive.total_honey(), "nectar": world.hive.total("nectar"),
		"pollen": world.hive.total("pollen"), "bee_bread": world.hive.total("bee_bread"),
		"royal_jelly": world.hive.total("jelly"), "pollinator_points": points}
	return Session.progression.gyne_rearing_path_covered(stores)


static func top_sections_ms(count: int) -> Dictionary:
	var sections: Dictionary = {}
	if Session.perf_enabled:
		for key: String in Perf.top_sections(count):
			sections[key] = Perf.averages[key]
	return sections
