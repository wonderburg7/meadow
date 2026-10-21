extends RefCounted
## Stable, entity-aware copy for the at-a-glance problem strip.
##
## This formatter receives facts already established by year_winter.gd; it
## never decides whether a problem exists. Choosing the lowest bee id keeps a
## condition's protagonist stable across the strip's one-second refreshes, and
## the fallbacks keep every warning honest when no relevant individual exists.
## One row is the exception: T2-8a's winter_unclustered asks season.gd itself
## (whether Shiver Cluster is owned, whether the countdown is in its last
## days), so year_winter.gd's state stays as it was.

const Season = preload("res://scripts/season.gd")

## The problem strip is an ordered catalogue, rather than a second set of
## decisions living in year_winter.gd. `condition` deliberately uses the
## shared condition vocabulary's `custom` leaf: these facts are already
## computed by ColonyDiagnostics, and the signal-specific comparisons do not
## belong in that general-purpose evaluator. A null action/category becomes "" in
## the line, which keeps every line the same five-element shape.
const SIGNALS := [
	{"id": "starving", "condition": {"custom": "starving"}, "severity": 2, "action": "starving", "category": null, "message": "signal_starving"},
	{"id": "hungry_brood", "condition": {"custom": "hungry_brood"}, "severity": 2, "action": "hungry_brood", "category": "brood", "message": "signal_hungry_brood"},
	{"id": "dead_cells", "condition": {"custom": "dead_cells"}, "severity": 2, "action": "dead_cells", "category": "brood", "message": "signal_dead_cells"},
	{"id": "low_pollen", "condition": {"custom": "low_pollen"}, "severity": 2, "action": "", "category": "brood", "message": "signal_low_pollen"},
	{"id": "low_food", "condition": {"custom": "low_food"}, "severity": 2, "action": null, "category": null, "message": "signal_low_food"},
	{"id": "no_nurses", "condition": {"custom": "no_nurses"}, "severity": 2, "action": "", "category": "brood", "message": "signal_no_nurses"},
	{"id": "winter_unclustered", "condition": {"custom": "winter_unclustered"}, "severity": 2, "action": null, "category": null, "message": "signal_winter_unclustered"},
	{"id": "no_free_cells", "condition": {"custom": "no_free_cells"}, "severity": 1, "action": null, "category": null, "message": "signal_no_free_cells"},
	{"id": "hungry", "condition": {"custom": "hungry"}, "severity": 1, "action": "hungry", "category": null, "message": "signal_hungry"},
	{"id": "no_foragers", "condition": {"custom": "no_foragers"}, "severity": 1, "action": "", "category": null, "message": "signal_no_foragers"},
	{"id": "no_comb_workers", "condition": {"custom": "no_comb_workers"}, "severity": 1, "action": "dead_cells", "category": "brood", "message": "signal_no_comb_workers"},
	{"id": "hard_rain", "condition": {"custom": "hard_rain"}, "severity": 1, "action": null, "category": null, "message": "signal_hard_rain"},
	{"id": "rain", "condition": {"custom": "rain"}, "severity": 0, "action": null, "category": null, "message": "signal_rain"},
]


static func signal_lines(state: Dictionary) -> Array:
	var lines: Array = []
	for entry in SIGNALS:
		if not _matches(state, entry.condition):
			continue
		# Fixed shape [text, severity, action, category, id]: action and
		# category are "" when the row has none, so readers can index
		# [2], [3] and [4] without a size check (GP-4 added the id).
		var action: String = "" if entry.action == null else str(entry.action)
		var category: String = "" if entry.category == null else str(entry.category)
		lines.append([_dispatch(str(entry.message), state), int(entry.severity), action, category, str(entry.id)])
	return lines


## SIGNALS names each row's message function by its string identifier
## rather than a Callable, since a static function cannot bind `self` to
## address its own script for dynamic dispatch (there is no instance, and
## this file preloading itself back is not allowed). One `match` covering
## the same identifiers `SIGNALS` already lists keeps both in one place.
static func _dispatch(message: String, state: Dictionary) -> String:
	match message:
		"signal_starving": return signal_starving(state)
		"signal_hungry_brood": return signal_hungry_brood(state)
		"signal_dead_cells": return signal_dead_cells(state)
		"signal_low_pollen": return signal_low_pollen(state)
		"signal_low_food": return signal_low_food(state)
		"signal_no_nurses": return signal_no_nurses(state)
		"signal_winter_unclustered": return signal_winter_unclustered(state)
		"signal_no_free_cells": return signal_no_free_cells(state)
		"signal_hungry": return signal_hungry(state)
		"signal_no_foragers": return signal_no_foragers(state)
		"signal_no_comb_workers": return signal_no_comb_workers(state)
		"signal_hard_rain": return signal_hard_rain(state)
		"signal_rain": return signal_rain(state)
	return ""


static func _matches(state: Dictionary, condition: Dictionary) -> bool:
	# SIGNALS only needs C1's `custom` vocabulary leaf. Keeping the dispatch
	# here makes each predicate testable against a constructed colony state,
	# while Conditions remains a read-only evaluator of live main state.
	match str(condition.get("custom", "")):
		"starving": return int(state.starving) > 0
		"hungry_brood": return int(state.hungry_brood) > 0
		"dead_cells": return int(state.dead_cells) > 0
		"low_pollen": return int(state.day) >= int(GameConfig.pollen_warning_first_day) and float(state.pollen) < GameConfig.egg_pollen_cost * GameConfig.pollen_warning_stock_multiplier
		"low_food": return float(state.nectar) < GameConfig.nectar_warning_total and float(state.honey) < GameConfig.honey_warning_total
		"no_nurses": return int(state.nurses) == 0 and int(state.brood_cells) > 0
		"winter_unclustered": return Season.unclustered_warning_due(float(state.day))
		"no_free_cells": return int(state.free_cells) == 0
		"hungry": return int(state.hungry) > 0
		"no_foragers": return int(state.foragers) == 0
		"no_comb_workers": return int(state.comb_workers) == 0 and int(state.dead_cells) > 0
		"hard_rain": return float(state.rain_intensity) > GameConfig.rain_forage_limit
		"rain": return float(state.rain_intensity) > 0.05 and float(state.rain_intensity) <= GameConfig.rain_forage_limit
	return false


static func signal_starving(state: Dictionary) -> String:
	return starving(state.bees, int(state.starving))


static func signal_hungry_brood(state: Dictionary) -> String:
	return "%d larvae are going hungry" % int(state.hungry_brood)


static func signal_dead_cells(state: Dictionary) -> String:
	return "%d cells blocked by dead larvae" % int(state.dead_cells)


static func signal_low_pollen(_state: Dictionary) -> String:
	return "Almost no pollen — the queen cannot lay"


static func signal_low_food(_state: Dictionary) -> String:
	return "Food is running out"


static func signal_no_nurses(_state: Dictionary) -> String:
	return "No nurses — brood will not develop at all"


static func signal_winter_unclustered(state: Dictionary) -> String:
	var days_left: int = int(ceil(maxf(0.0, Session.winter_starts_day - float(state.day))))
	return "Winter in %d day%s, and without Shiver Cluster the colony burns %s times its stores through it" % [
		days_left, "" if days_left == 1 else "s", String.num(GameConfig.winter_unclustered_multiplier, 2).trim_suffix(".0"),
	]


static func signal_no_free_cells(state: Dictionary) -> String:
	return no_free_cells(state.bees, state.queen)


static func signal_hungry(state: Dictionary) -> String:
	return hungry(state.bees, int(state.hungry))


static func signal_no_foragers(state: Dictionary) -> String:
	return no_foragers(state.queen)


static func signal_no_comb_workers(_state: Dictionary) -> String:
	return "No comb workers to clear the blocked cells"


static func signal_hard_rain(_state: Dictionary) -> String:
	return "Raining hard — foragers are grounded"


static func signal_rain(_state: Dictionary) -> String:
	return "Raining — nectar is watered down and flying costs more"

static func starving(bees: Array, count: int) -> String:
	var bee := _first_bee(bees, func(candidate):
		return candidate.energy < GameConfig.energy_capacity * GameConfig.starving_energy_level
	)
	if bee != null:
		return "%s is almost out of energy and would like the nectar department to treat this as urgent." % bee.bee_name
	return "%d bees are about to starve" % count

static func hungry(bees: Array, count: int) -> String:
	var bee := _first_bee(bees, func(candidate):
		return candidate.energy >= GameConfig.energy_capacity * GameConfig.starving_energy_level \
			and candidate.energy < GameConfig.energy_capacity * GameConfig.low_energy_warning_level
	)
	if bee != null:
		return "%s is running low on energy — she is trying to work, but the pantry is not helping." % bee.bee_name
	return "%d bees are running low on energy" % count

static func no_free_cells(bees: Array, queen) -> String:
	var loaded := _first_bee(bees, func(candidate):
		return candidate.current_load > 0.0 and candidate.current_load_type in ["nectar", "pollen"]
	)
	if loaded != null:
		return "%s is annoyed that there is nowhere to put the %s she gathered — how can she work under these conditions?" % [loaded.bee_name, loaded.current_load_type]
	if is_instance_valid(queen):
		return "%s has inspected the comb and found no free cell for stores or eggs. She is not impressed." % queen.bee_name
	return "No free cells — nowhere to store food or lay eggs"

static func no_foragers(queen) -> String:
	if is_instance_valid(queen):
		return "%s has noticed that nobody is bringing food home. She is trying not to take it personally." % queen.bee_name
	return "No foragers — nothing is coming in"

## The two warning-banner copy owners that used to live on the simulation
## side (BeeSurvival._announce_death, CrabSpider._announce_escape) -- see
## UI-Q-2 in plans/now/ui.md. The simulation states the fact (a bee died,
## a bee escaped) and calls these to choose the words.
static func epitaph(bee_name: String, death_cause: String, bee_fact: String) -> String:
	return "%s has died of %s. %s" % [bee_name, death_cause, bee_fact]

static func crab_spider_escape(bee_name: String) -> String:
	return "%s narrowly escaped a crab spider." % bee_name

static func _first_bee(bees: Array, test: Callable) -> Node2D:
	var found: Node2D = null
	for bee in bees:
		if not is_instance_valid(bee) or not test.call(bee):
			continue
		if found == null or int(bee.bee_id) < int(found.bee_id):
			found = bee
	return found
