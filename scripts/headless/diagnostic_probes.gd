## Allowlisted, low-cost snapshot probes for scenario diagnostics.
class_name HeadlessDiagnosticProbes
extends RefCounted

const SNAPSHOT_FIELDS := ["population.total", "resources.food_stores", "resources.stored_nectar", "resources.stored_pollen", "environment.winter_here", "environment.flowers_by_species", "role_outcomes.cells_completed_total", "performance.fps", "performance.top_sections_ms"]

static func selected_snapshot(world: Node2D, fields: Array, counters: Dictionary) -> Dictionary:
	var snapshot := {"type": "snapshot", "game_time": Session.sim_time, "day": world.day}
	for field_variant in fields:
		var field: String = str(field_variant)
		match field:
			"population.total": _merge_field(snapshot, "population", "total", _live_bee_count(world))
			"resources.food_stores": _merge_field(snapshot, "resources", "food_stores", world.hive.total_honey())
			"resources.stored_nectar": _merge_field(snapshot, "resources", "stored_nectar", world.hive.total("nectar"))
			"resources.stored_pollen": _merge_field(snapshot, "resources", "stored_pollen", world.hive.total("pollen"))
			"environment.winter_here": _merge_field(snapshot, "environment", "winter_here", Session.winter_here)
			"environment.flowers_by_species": _merge_field(snapshot, "environment", "flowers_by_species", _flowers_by_species(world))
			"role_outcomes.cells_completed_total": _merge_field(snapshot, "role_outcomes", "cells_completed_total", int(counters.get("cells_completed", 0)))
			"performance.fps": _merge_field(snapshot, "performance", "fps", Engine.get_frames_per_second())
			"performance.top_sections_ms":
				var sections: Dictionary = {}
				if Session.perf_enabled:
					for key in Perf.top_sections(8): sections[key] = Perf.averages[key]
				_merge_field(snapshot, "performance", "top_sections_ms", sections)
	return snapshot

## Adds one field into the snapshot's group dictionary, creating the group on
## first use, so two fields from the same group don't overwrite each other.
static func _merge_field(snapshot: Dictionary, group: String, key: String, value) -> void:
	if not snapshot.has(group):
		snapshot[group] = {}
	snapshot[group][key] = value

static func _live_bee_count(world: Node2D) -> int:
	var count := 0
	for bee in world.get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(bee): count += 1
	return count

static func _flowers_by_species(world: Node2D) -> Dictionary:
	var counts: Dictionary = {}
	for f in world.get_tree().get_nodes_in_group("flowers"):
		if is_instance_valid(f):
			counts[f.species_name] = int(counts.get(f.species_name, 0)) + 1
	return counts
