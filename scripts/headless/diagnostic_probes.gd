## Allowlisted, low-cost snapshot probes for scenario diagnostics.
class_name HeadlessDiagnosticProbes
extends RefCounted

const SNAPSHOT_FIELDS := ["population.total", "resources.food_stores", "resources.stored_nectar", "resources.stored_pollen", "environment.winter_here", "environment.flowers_by_species", "environment.flowers_in_season", "environment.flowers_out_of_season", "role_outcomes.cells_completed_total", "performance.fps", "performance.top_sections_ms", "colony.milestone_days", "resources.first_tier2_affordable"]

static func selected_snapshot(world: Node2D, fields: Array, counters: Dictionary) -> Dictionary:
	var snapshot := {"type": "snapshot", "game_time": Session.sim_time, "day": world.day}
	for field_variant: Variant in fields:
		var field: String = str(field_variant)
		match field:
			"population.total": _merge_field(snapshot, "population", "total", _live_bee_count(world))
			"resources.food_stores": _merge_field(snapshot, "resources", "food_stores", world.hive.total_honey())
			"resources.stored_nectar": _merge_field(snapshot, "resources", "stored_nectar", world.hive.total("nectar"))
			"resources.stored_pollen": _merge_field(snapshot, "resources", "stored_pollen", world.hive.total("pollen"))
			"resources.first_tier2_affordable":
				var tier2_stores := {"honey": world.hive.total_honey(), "nectar": world.hive.total("nectar"), "pollen": world.hive.total("pollen")}
				_merge_field(snapshot, "resources", "first_tier2_affordable",
					Session.progression != null and Session.progression.first_tier2_path_covered(tier2_stores))
			"environment.winter_here": _merge_field(snapshot, "environment", "winter_here", Session.winter_here)
			"environment.flowers_by_species": _merge_field(snapshot, "environment", "flowers_by_species", _flowers_by_species(world))
			"environment.flowers_in_season": _merge_field(snapshot, "environment", "flowers_in_season", _flower_season_counts(world).in_season)
			"environment.flowers_out_of_season": _merge_field(snapshot, "environment", "flowers_out_of_season", _flower_season_counts(world).out_of_season)
			"role_outcomes.cells_completed_total": _merge_field(snapshot, "role_outcomes", "cells_completed_total", int(counters.get("cells_completed", 0)))
			"performance.fps": _merge_field(snapshot, "performance", "fps", Engine.get_frames_per_second())
			"performance.top_sections_ms":
				var sections: Dictionary = {}
				if Session.perf_enabled:
					for key: String in Perf.top_sections(8): sections[key] = Perf.averages[key]
				_merge_field(snapshot, "performance", "top_sections_ms", sections)
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

static func _flowers_by_species(world: Node2D) -> Dictionary:
	var counts: Dictionary = {}
	for f: Variant in world.get_tree().get_nodes_in_group("flowers"):
		if is_instance_valid(f):
			counts[f.species_name] = int(counts.get(f.species_name, 0)) + 1
	return counts


static func _flower_season_counts(world: Node2D) -> Dictionary:
	var in_season := 0
	var out_of_season := 0
	for flower: Variant in world.get_tree().get_nodes_in_group("flowers"):
		if not is_instance_valid(flower):
			continue
		if flower.in_season():
			in_season += 1
		else:
			out_of_season += 1
	return {"in_season": in_season, "out_of_season": out_of_season}
