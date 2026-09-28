extends RefCounted
## Read-only evaluator shared by Challenge goals, scenario triggers and future
## level conditions. Nothing calls it yet: C2 and C3 adopt it separately.
##
## The evaluator deliberately reads main's cached role counts and hive's cached
## totals/content buckets. It never reaches into a scene group or writes state.

const Roles = preload("res://scripts/roles.gd")
const Resources = preload("res://scripts/resources.gd")


static func met(main, spec: Dictionary) -> bool:
	for key in spec:
		if not _met_key(main, str(key), spec[key]):
			return false
	return true


static func progress(main, spec: Dictionary) -> Dictionary:
	for key in spec:
		var result := _progress_key(main, str(key), spec[key])
		if not result.is_empty():
			return result
	return {}


static func _met_key(main, key: String, value) -> bool:
	match key:
		"day_at_least":
			return main.day >= int(value)
		"role_count":
			var role_spec: Dictionary = value
			return _role_count(main, role_spec) >= int(role_spec.get("at_least", 0))
		"hive_total":
			var total_spec: Dictionary = value
			return main.hive.total(str(total_spec.get("resource", ""))) >= float(total_spec.get("at_least", 0))
		"cell_count":
			var cell_spec: Dictionary = value
			return _cell_count(main, cell_spec) >= int(cell_spec.get("at_least", 0))
		"built_cells_at_least":
			return _built_cell_count(main) >= int(value)
		"brood_cells_at_least":
			return main.hive.cells_holding("brood").size() >= int(value)
		"queen_alive":
			var alive: bool = main.queen != null and is_instance_valid(main.queen) and not main.colony_lost
			return alive == bool(value)
		"skill_owned":
			return _skill_owned(str(value))
		"event_count":
			var event_spec: Dictionary = value
			var count := DiagnosticLog.event_count(str(event_spec.get("type", "")), str(event_spec.get("subtype", "")))
			return count >= int(event_spec.get("at_least", -2147483648)) and count <= int(event_spec.get("at_most", 2147483647))
		"disease":
			var disease_spec: Dictionary = value
			var disease := _disease(main)
			return disease >= float(disease_spec.get("at_least", -INF)) and disease <= float(disease_spec.get("at_most", INF))
		"all_of":
			for child in value:
				if not met(main, child):
					return false
			return true
		"any_of":
			for child in value:
				if met(main, child):
					return true
			return false
		"custom":
			var method := str(value)
			if main.has_method(method):
				return bool(main.call(method))
			push_error("Conditions custom method is unavailable: %s" % method)
			return false
		_:
			push_error("Conditions does not support key: %s" % key)
			return false


static func _progress_key(main, key: String, value) -> Dictionary:
	match key:
		"day_at_least":
			return {"current": main.day, "target": int(value)}
		"role_count":
			var role_spec: Dictionary = value
			return {"current": _role_count(main, role_spec), "target": int(role_spec.get("at_least", 0))}
		"hive_total":
			var total_spec: Dictionary = value
			return {"current": main.hive.total(str(total_spec.get("resource", ""))), "target": float(total_spec.get("at_least", 0))}
		"cell_count":
			var cell_spec: Dictionary = value
			return {"current": _cell_count(main, cell_spec), "target": int(cell_spec.get("at_least", 0))}
		"built_cells_at_least":
			return {"current": _built_cell_count(main), "target": int(value)}
		"brood_cells_at_least":
			return {"current": main.hive.cells_holding("brood").size(), "target": int(value)}
		"skill_owned":
			return {"current": 1 if _skill_owned(str(value)) else 0, "target": 1}
		"event_count":
			var event_spec: Dictionary = value
			if event_spec.has("at_least"):
				return {"current": DiagnosticLog.event_count(str(event_spec.get("type", "")), str(event_spec.get("subtype", ""))), "target": int(event_spec["at_least"])}
			if event_spec.has("at_most"):
				return {"current": DiagnosticLog.event_count(str(event_spec.get("type", "")), str(event_spec.get("subtype", ""))), "target": int(event_spec["at_most"])}
		"disease":
			var disease_spec: Dictionary = value
			if disease_spec.has("at_least"):
				return {"current": _disease(main), "target": float(disease_spec["at_least"])}
			if disease_spec.has("at_most"):
				return {"current": _disease(main), "target": float(disease_spec["at_most"])}
		"all_of", "any_of":
			for child in value:
				var result := progress(main, child)
				if not result.is_empty():
					return result
	return {}


static func _role_count(main, spec: Dictionary) -> int:
	var role_id := Roles.id_for_key(str(spec.get("role", "")))
	if role_id < 0:
		return 0
	var counts: Dictionary = main._role_counts()
	if role_id != Roles.FORAGER or spec.has("focus"):
		return int(counts.get(Roles.count_key(role_id, str(spec.get("focus", ""))), 0))
	var total := 0
	for focus in Roles.modes_for(role_id):
		total += int(counts.get(Roles.count_key(role_id, str(focus.key)), 0))
	return total


static func _cached_cells(main) -> Array:
	var cells: Array = []
	for content in Resources.content_keys():
		cells.append_array(main.hive.cells_holding(content))
	return cells


static func _cell_count(main, spec: Dictionary) -> int:
	var cells: Array = main.hive.cells_holding(str(spec.get("content", ""))) if spec.has("content") else _cached_cells(main)
	var count := 0
	for cell in cells:
		if spec.has("designated") and cell.designated_type != str(spec["designated"]):
			continue
		if spec.has("explicit") and cell.designation_is_explicit != bool(spec["explicit"]):
			continue
		count += 1
	return count


static func _built_cell_count(main) -> int:
	return _cached_cells(main).size()


## BS-1: `{"skill_owned": "<skill id>"}`, for a stage goal that asks the
## player to buy a skill. The run's resolver is the only answer to "is this
## owned"; no resolver means nothing is.
static func _skill_owned(skill_id: String) -> bool:
	return Session.progression != null and Session.progression.is_owned(skill_id)


static func _disease(main) -> float:
	if main.season == null or not is_instance_valid(main.season):
		return 0.0
	return main.season.disease
