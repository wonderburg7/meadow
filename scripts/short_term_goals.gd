extends RefCounted
## SG-1: the short-term catalogue and its rules. The caller supplies a plain
## ColonyDiagnostics snapshot plus daily income, built cells and winter facts.
## No scene, save or balance singleton is read here.

const CATALOGUE := [
	{"id": "pollen_surplus", "label": "Build a pollen surplus", "resource": "pollen"},
	{"id": "clear_blocked_work", "label": "Clear blocked work", "resource": "honey"},
	{"id": "make_room", "label": "Make room", "resource": "nectar"},
	{"id": "feed_every_larva", "label": "Feed every larva", "resource": "pollen"},
	{"id": "put_waiting_bees_to_work", "label": "Put waiting bees to work", "resource": "nectar"},
	{"id": "honey_for_winter", "label": "Lay in honey for winter", "resource": "honey"},
]


## Return offers for the vacant slots. Record each with accept() when shown.
## Facts: net_daily_income and gross_daily_income map resource to amount;
## built_cells, winter_coming and winter_ready supplement diagnostics.compute.
## Thresholds: few_free_cells, many_waiting_bees and few_waiting_bees.
## SG-2: a resource missing from an income map is unknown, not zero -- its
## one-day window has not filled since the run began or was loaded. No goal is
## offered while its own resource's gross income is unknown, since the reward
## is fixed at offer and would pay nothing.
static func available(facts: Dictionary, state: Dictionary, day: int, thresholds: Dictionary, reward_fraction: float) -> Array:
	var offered: Dictionary = state.get("offered", {})
	var dismissed: Dictionary = state.get("dismissed", {})
	var finished: Dictionary = state.get("finished", {})
	# Dismiss leaves its slot empty until tomorrow, even if another trigger
	# holds. This prevents an immediate replacement under the player's hand.
	var dismissed_today: int = 0
	for dismissed_day in dismissed.values():
		if int(dismissed_day) == day:
			dismissed_today += 1
	var vacant: int = maxi(0, 2 - offered.size() - dismissed_today)
	var result: Array = []
	for goal in CATALOGUE:
		if result.size() >= vacant:
			break
		var id: String = goal.id
		if offered.has(id) or int(dismissed.get(id, -1)) == day or int(finished.get(id, -1)) == day:
			continue
		if not facts.get("gross_daily_income", {}).has(goal.resource):
			continue
		if not _trigger(id, facts, thresholds):
			continue
		var entry: Dictionary = goal.duplicate()
		entry["offered_day"] = day
		entry["reward"] = maxf(0.0, reward_fraction) * maxf(0.0, float(facts.get("gross_daily_income", {}).get(goal.resource, 0.0)))
		if id == "make_room":
			entry["built_cells_target"] = int(facts.get("built_cells", 0)) + maxi(1, int(thresholds.get("few_free_cells", 1)))
		result.append(entry)
	return result


static func accept(state: Dictionary, entry: Dictionary) -> void:
	var offered: Dictionary = state.get("offered", {})
	if offered.size() >= 2 or offered.has(str(entry.get("id", ""))):
		return
	offered[str(entry.id)] = entry.duplicate(true)
	state["offered"] = offered


static func dismiss(state: Dictionary, id: String, day: int) -> void:
	var offered: Dictionary = state.get("offered", {})
	if not offered.has(id):
		return
	offered.erase(id)
	state["offered"] = offered
	var dismissed: Dictionary = state.get("dismissed", {})
	dismissed[id] = day
	state["dismissed"] = dismissed
	var held_since: Dictionary = state.get("held_since", {})
	held_since.erase(id)
	state["held_since"] = held_since


static func finish(state: Dictionary, id: String, day: int) -> float:
	var offered: Dictionary = state.get("offered", {})
	if not offered.has(id):
		return 0.0
	var reward: float = float(offered[id].get("reward", 0.0))
	offered.erase(id)
	state["offered"] = offered
	var finished: Dictionary = state.get("finished", {})
	finished[id] = day
	state["finished"] = finished
	var held_since: Dictionary = state.get("held_since", {})
	held_since.erase(id)
	state["held_since"] = held_since
	return reward


## Called on the one-second refresh. at_day_change is true only for the
## refresh at a day boundary. A whole-day clock starts at such a boundary
## while the condition holds; any observed interruption clears it.
static func progress(entry: Dictionary, facts: Dictionary, state: Dictionary, day: int, thresholds: Dictionary, at_day_change: bool = false) -> Dictionary:
	var id: String = str(entry.get("id", ""))
	var current: float = 0.0
	var target: float = 1.0
	var condition: bool = false
	match id:
		"pollen_surplus":
			# SG-2: an unknown rate neither advances nor interrupts the day.
			if not facts.get("net_daily_income", {}).has("pollen"):
				var known_since: Dictionary = state.get("held_since", {})
				var so_far: int = maxi(0, day - int(known_since.get(id, day)))
				return {"current": so_far, "target": 1, "done": false}
			current = float(facts.get("net_daily_income", {}).get("pollen", 0.0))
			condition = current > 0.0
			# A positive rate is the condition; the full day is the progress.
		"clear_blocked_work":
			current = float(int(facts.get("blocked_cells", 0)) + int(facts.get("blocked_work", 0)))
			condition = current <= 0.0
		"make_room":
			current = float(facts.get("built_cells", 0))
			target = float(entry.get("built_cells_target", 1))
			condition = current >= target
		"feed_every_larva":
			current = float(facts.get("hungry_brood", 0))
			condition = current <= 0.0
		"put_waiting_bees_to_work":
			current = float(facts.get("waiting_for_work", 0))
			target = float(thresholds.get("few_waiting_bees", 0))
			condition = current <= target
		"honey_for_winter":
			current = float(int(bool(facts.get("winter_ready", false))))
			condition = current >= 1.0
	var whole_day: bool = id == "pollen_surplus" or id == "feed_every_larva"
	if not whole_day:
		return {"current": current, "target": target, "done": condition}
	var held_since: Dictionary = state.get("held_since", {})
	if not condition:
		held_since.erase(id)
	elif at_day_change and not held_since.has(id):
		held_since[id] = day
	state["held_since"] = held_since
	var elapsed: int = maxi(0, day - int(held_since.get(id, day))) if condition and held_since.has(id) else 0
	return {"current": elapsed, "target": 1, "done": condition and elapsed >= 1}


static func _trigger(id: String, facts: Dictionary, thresholds: Dictionary) -> bool:
	match id:
		"pollen_surplus":
			var net: Dictionary = facts.get("net_daily_income", {})
			return net.has("pollen") and float(net.pollen) <= 0.0
		"clear_blocked_work":
			return int(facts.get("blocked_cells", 0)) > 0 or int(facts.get("blocked_work", 0)) > 0
		"make_room":
			return int(facts.get("free_cells", 0)) <= int(thresholds.get("few_free_cells", 0))
		"feed_every_larva":
			return int(facts.get("hungry_brood", 0)) > 0
		"put_waiting_bees_to_work":
			return int(facts.get("waiting_for_work", 0)) >= int(thresholds.get("many_waiting_bees", 1))
		"honey_for_winter":
			return bool(facts.get("winter_coming", false)) and not bool(facts.get("winter_ready", false))
	return false
