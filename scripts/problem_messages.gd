extends RefCounted
## Stable, entity-aware copy for the at-a-glance problem strip.
##
## This formatter receives facts already established by year_winter.gd; it
## never decides whether a problem exists. Choosing the lowest bee id keeps a
## condition's protagonist stable across the strip's one-second refreshes, and
## the fallbacks keep every warning honest when no relevant individual exists.

static func starving(bees: Array, count: int) -> String:
	var bee := _first_bee(bees, func(candidate):
		return candidate.energy < GameConfig.energy_capacity * 0.15
	)
	if bee != null:
		return "%s is almost out of energy and would like the nectar department to treat this as urgent." % bee.bee_name
	return "%d bees are about to starve" % count

static func hungry(bees: Array, count: int) -> String:
	var bee := _first_bee(bees, func(candidate):
		return candidate.energy >= GameConfig.energy_capacity * 0.15 \
			and candidate.energy < GameConfig.energy_capacity * GameConfig.low_energy_warning_level
	)
	if bee != null:
		return "%s is running low on energy — she is trying to work, but the pantry is not helping." % bee.bee_name
	return "%d bees are running low on energy" % count

static func no_free_cells(bees: Array, queen: Node2D) -> String:
	var loaded := _first_bee(bees, func(candidate):
		return candidate.current_load > 0.0 and candidate.current_load_type in ["nectar", "pollen"]
	)
	if loaded != null:
		return "%s is annoyed that there is nowhere to put the %s she gathered — how can she work under these conditions?" % [loaded.bee_name, loaded.current_load_type]
	if is_instance_valid(queen):
		return "%s has inspected the comb and found no free cell for stores or eggs. She is not impressed." % queen.bee_name
	return "No free cells — nowhere to store food or lay eggs"

static func no_foragers(queen: Node2D) -> String:
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
