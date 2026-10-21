extends RefCounted
## Read-only evaluator shared by Challenge stage goals (challenge_runner.gd),
## Colony Run milestones (colony_milestones.gd) and scenario triggers
## (scenario_actions.gd). A new rule about the colony's state is a leaf here,
## not a second evaluator: short-term goals take their income, built-cell and
## winter facts from these leaves (plans/now/short-term-goals.md, SG-2).
##
## The evaluator deliberately reads main's cached role counts and hive's cached
## totals/content buckets. It never reaches into a scene group or writes state.

const Roles = preload("res://scripts/roles.gd")
const Resources = preload("res://scripts/resources.gd")


static func met(main: Node2D, spec: Dictionary) -> bool:
	for key: Variant in spec:
		if not _met_key(main, str(key), spec[key]):
			return false
	return true


static func progress(main: Node2D, spec: Dictionary) -> Dictionary:
	for key: Variant in spec:
		var result := _progress_key(main, str(key), spec[key])
		if not result.is_empty():
			return result
	return {}


static func _met_key(main: Node2D, key: String, value: Variant) -> bool:
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
		"net_income":
			var income_spec: Dictionary = value
			var income := _net_income(main, income_spec)
			return not income.is_empty() and float(income.collected) > 0.0 and float(income.net) >= float(income_spec.get("at_least", 0.0))
		"non_queen_adults_at_least":
			return _non_queen_adults(main) >= int(value)
		"winter_ready":
			return _winter_ready(main) == bool(value)
		"winter_over":
			return _winter_over() == bool(value)
		"brood_stage":
			var stage_spec: Dictionary = value
			return _brood_stage(main, stage_spec) >= int(stage_spec.get("at_least", 0))
		"gynes_released_at_least":
			return Session.gynes_released >= int(value)
		"all_of":
			for child: Variant in value:
				if not met(main, child):
					return false
			return true
		"any_of":
			for child: Variant in value:
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


static func _progress_key(main: Node2D, key: String, value: Variant) -> Dictionary:
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
		"net_income":
			var income_spec: Dictionary = value
			var income := _net_income(main, income_spec)
			return {"current": float(income.get("net", 0.0)), "target": float(income_spec.get("at_least", 0.0))}
		"non_queen_adults_at_least":
			return {"current": _non_queen_adults(main), "target": int(value)}
		"brood_stage":
			var stage_spec: Dictionary = value
			return {"current": _brood_stage(main, stage_spec), "target": int(stage_spec.get("at_least", 0))}
		"gynes_released_at_least":
			return {"current": Session.gynes_released, "target": int(value)}
		"all_of", "any_of":
			for child: Variant in value:
				var result := progress(main, child)
				if not result.is_empty():
					return result
	return {}


static func _role_count(main: Node2D, spec: Dictionary) -> int:
	var role_id := Roles.id_for_key(str(spec.get("role", "")))
	if role_id < 0:
		return 0
	var counts: Dictionary = main._role_counts()
	if role_id != Roles.FORAGER or spec.has("focus"):
		return int(counts.get(Roles.count_key(role_id, str(spec.get("focus", ""))), 0))
	var total := 0
	for focus: Variant in Roles.modes_for(role_id):
		total += int(counts.get(Roles.count_key(role_id, str(focus.key)), 0))
	return total


static func _cached_cells(main: Node2D) -> Array:
	var cells: Array = []
	for content: String in Resources.content_keys():
		cells.append_array(main.hive.cells_holding(content))
	return cells


static func _cell_count(main: Node2D, spec: Dictionary) -> int:
	var cells: Array = main.hive.cells_holding(str(spec.get("content", ""))) if spec.has("content") else _cached_cells(main)
	var count := 0
	for cell: Variant in cells:
		if spec.has("designated") and cell.designated_type != str(spec["designated"]):
			continue
		if spec.has("explicit") and cell.designation_is_explicit != bool(spec["explicit"]):
			continue
		count += 1
	return count


static func _built_cell_count(main: Node2D) -> int:
	return _cached_cells(main).size()


## BS-1: `{"skill_owned": "<skill id>"}`, for a stage goal that asks the
## player to buy a skill. The run's resolver is the only answer to "is this
## owned"; no resolver means nothing is.
static func _skill_owned(skill_id: String) -> bool:
	return Session.progression != null and Session.progression.is_owned(skill_id)


static func _disease(main: Node2D) -> float:
	if main.season == null or not is_instance_valid(main.season):
		return 0.0
	return main.season.disease


## CR-2: `{"net_income": {"resource": "nectar", "days": 3, "at_least": 0.0}}`,
## a rate of income over the last `days` whole days. Read from main.gd's
## day_store_totals (one sample per day boundary), never from a live total,
## so a check on day change and one later the same day give the same answer.
## `net` is how far the store moved across the window; `collected` is how
## much came in from the meadow over it. The leaf asks for both: income means
## something arrived, so a store that sat at zero is not a stable income.
## An empty result means the window is not full yet -- a new run, or the
## first days after a load, since the samples are not saved.
static func _net_income(main: Node2D, spec: Dictionary) -> Dictionary:
	var samples: Array = main.day_store_totals
	var days: int = maxi(1, int(spec.get("days", 1)))
	if samples.size() <= days:
		return {}
	var resource := str(spec.get("resource", ""))
	var newest: Dictionary = samples[samples.size() - 1]
	var oldest: Dictionary = samples[samples.size() - 1 - days]
	return {
		"net": float(newest.get(resource, 0.0)) - float(oldest.get(resource, 0.0)),
		"collected": float(newest.get(resource + "_collected", 0.0)) - float(oldest.get(resource + "_collected", 0.0)),
	}


## CR-2: every adult other than the queen, gynes included, from main's cached
## role counts (which count every bee, the queen among them).
static func _non_queen_adults(main: Node2D) -> int:
	var total := 0
	for count: Variant in main._role_counts().values():
		total += int(count)
	if main.queen != null and is_instance_valid(main.queen):
		total -= 1
	return maxi(0, total)


## CR-2: the winter window's own verdict -- year_winter.gd's forecast, read
## the way winter_panel.gd::refresh reads it ("On track" when the comb holds
## at least what winter needs) -- judged on the colony that meets winter: only
## on the countdown's last day (the forecast's days_left at most 1), up to the
## day boundary winter arrives on. main.gd emits day_changed before season.gd's
## once-a-second tick sets winter_here, so that boundary is still checked. An
## earlier verdict says nothing about the colony winter finds, and a met
## milestone is never re-checked. The bee count is the whole population, queen
## included, as main's panel refresh passes it.
static func _winter_ready(main: Node2D) -> bool:
	if not Session.winter_coming or Session.winter_here:
		return false
	var bees := 0
	for count: Variant in main._role_counts().values():
		bees += int(count)
	var forecast: Dictionary = main.year_winter._winter_forecast(bees)
	if float(forecast.get("days_left", INF)) > 1.0:
		return false
	return float(forecast.get("held_energy", 0.0)) >= float(forecast.get("required_energy", 0.0))


## CR-2: a winter has come and gone. season.gd sets winter_ends_day when winter
## arrives and clears winter_here when it ends; a run opens one countdown.
static func _winter_over() -> bool:
	return Session.winter_ends_day > 0.0 and not Session.winter_here


## CR-2: `{"brood_stage": {"stage": "egg", "at_least": 1}}`, brood cells in one
## stage of hive.gd's own egg/larva/capped split.
static func _brood_stage(main: Node2D, spec: Dictionary) -> int:
	return int(main.hive.brood_stage_counts().get(str(spec.get("stage", "")), 0))
