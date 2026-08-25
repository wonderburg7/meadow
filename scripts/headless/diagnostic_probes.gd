## Allowlisted, low-cost snapshot probes for scenario diagnostics.
class_name HeadlessDiagnosticProbes
extends RefCounted

const SNAPSHOT_FIELDS := ["population.total", "resources.food_stores", "environment.winter_here", "role_outcomes.cells_completed_total", "performance.fps", "performance.top_sections_ms"]

static func selected_snapshot(world: Node2D, fields: Array, counters: Dictionary) -> Dictionary:
	var snapshot := {"type": "snapshot", "game_time": Session.sim_time, "day": world.day}
	for field_variant in fields:
		var field: String = str(field_variant)
		match field:
			"population.total": snapshot["population"] = {"total": _live_bee_count(world)}
			"resources.food_stores": snapshot["resources"] = {"food_stores": world.hive.total_honey()}
			"environment.winter_here": snapshot["environment"] = {"winter_here": Session.winter_here}
			"role_outcomes.cells_completed_total": snapshot["role_outcomes"] = {"cells_completed_total": int(counters.get("cells_completed", 0))}
			"performance.fps": snapshot["performance"] = {"fps": Engine.get_frames_per_second()}
			"performance.top_sections_ms":
				var sections: Dictionary = {}
				if Session.perf_enabled:
					for key in Perf.top_sections(8): sections[key] = Perf.averages[key]
				snapshot["performance"] = {"top_sections_ms": sections}
	return snapshot

static func _live_bee_count(world: Node2D) -> int:
	var count := 0
	for bee in world.get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(bee): count += 1
	return count
