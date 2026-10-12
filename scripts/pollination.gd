extends RefCounted
## PP-1 (plans/now/pollination.md): the colony's pollination ledger, from
## plans/design/product-scope.md §10 and its 10 Oct 2026 decisions.
##
## Two counters, and this file is the only writer of either:
##
## - `points`: spendable Pollinator Points. A bee earns one when she finishes
##   a flower straight after a *different* flower of the same species on the
##   same foraging trip, but only while the colony owns the Pollinator points
##   skill, and only once per flower until that flower has refilled (its
##   `award_ready_at`). PP-2: skill_tree_panel.gd spends them through
##   spend(), and pollination_pop.gd shows the "+1".
## - `contribution`: Pollination Contribution, never spent. It rises on every
##   compatible delivery whether or not the skill is owned, because
##   pollination itself happens either way. Nothing reads it yet beyond the
##   developer panel.
##
## Flowers own their own pollen counts (flower.gd's compatible_visits and
## incompatible_visits); bees own only their trip's last flower
## (bee.gd::trip_last_flower), which only this file sets.
## bee_foraging.gd::finish_collecting calls record_visit once per finished
## visit, and bee.gd calls groom as she enters the hive -- never per frame.
##
## main.gd creates it, as it does colony_milestones.gd; save_game.gd writes
## save_data() under "pollination" and saving.gd::_restore hands it back, so
## a load and an in-place checkpoint restore both put the counters back. A
## save without the record restores zero.
##
## PP-4: seed set, only in a run whose level row sets "seed_set" (the Colony
## Run and Scenarios; never a Challenge -- levels.gd::seed_set_enabled). A
## flower sets seed (flower.gd::sets_seed) when it had at least one
## compatible delivery and more compatible than incompatible ones. When one
## dies of age, flower.gd hands it to flower_withered here, which:
##
## - counts it in `seed_counts` under its species, the meadow's memory of
##   which species the colony pollinated this year, and
## - queues a seed where it stood (`pending_seeds`), which
##   world_building.gd::_seed_flower plants as the next replacement, of the
##   same species, close by. A flower that did not set seed queues nothing,
##   so its gap is filled by today's seasonal draw, the background floor.
##
## After winter, while COL-8's regrowth is under way (Flower.regrowth_factor
## below 1), the seasonal draw is weighted by the counts the year gathered
## (regrowth_counts, read through flower_species.gd::species_weights). On
## the first draw after a winter the counts move to `spring_counts` and
## `seed_counts` starts again from zero, so each winter remembers one year.
## save_game.gd writes them, with the seeds waiting, under "seed_bank"
## (seed_save_data), beside the "pollination" record rather than in it, and
## saving.gd::_restore hands them back through restore_seed.

## Emitted once per point earned, with the flower that earned it, for PP-2's
## rising "+1". Presentation listens; nothing in the simulation does.
signal points_earned(flower: Node2D)

## skills.gd's Pollinator points effect key (an enable_behaviour effect).
const BEHAVIOUR := "pollinator_points_on"
const POINTS := "points"
const CONTRIBUTION := "contribution"
const SEED_COUNTS := "seed_counts"
const SPRING_COUNTS := "spring_counts"
const SPRING_OF := "spring_of"
const PENDING_SEEDS := "pending_seeds"

const Levels = preload("res://scripts/levels.gd")

var main: Node2D
var points: int = 0
var contribution: int = 0
## PP-4: seed-setting deaths this year, species name -> count.
var seed_counts: Dictionary = {}
## PP-4: the counts this spring's regrowth reads, moved out of seed_counts
## on the first draw after the winter that ended on day `spring_of`.
var spring_counts: Dictionary = {}
var spring_of: float = 0.0
## PP-4: seeds waiting to be planted, oldest first, each
## [species_index, x, y] of the flower that set it.
var pending_seeds: Array = []

## Whether the colony owns Pollinator points, in bee_foraging.gd's
## tarsal_markers_on() pattern. There is no GameConfig toggle behind it: the
## skill is the only way to switch points on.
static func pollinator_points_on() -> bool:
	return Session.progression != null and Session.progression.is_behaviour_enabled(BEHAVIOUR)

## One finished visit by `bee` to `flower`, taking `resource_type`. Compares
## the flower with the trip's last one, then makes this flower the last one.
## A trip's first flower, or the same flower twice running, delivers nothing.
func record_visit(bee: Node2D, flower: Node2D, resource_type: String) -> void:
	# Checked untyped first: the last flower may have died of age since,
	# and a freed instance cannot be assigned to a typed variable. A dead
	# flower's pollen is no previous flower at all.
	var last = bee.trip_last_flower
	var previous: Node2D = last if is_instance_valid(last) else null
	bee.trip_last_flower = flower
	if previous == null or previous == flower:
		_log_visit(bee, flower, previous, "first", false)
		return
	if previous.species_name != flower.species_name:
		flower.receive_pollen(false)
		_log_visit(bee, flower, previous, "incompatible", false)
		return
	flower.receive_pollen(true)
	contribution += 1
	var awarded := false
	if pollinator_points_on() and flower.take_award(resource_type):
		points += 1
		awarded = true
	_log_visit(bee, flower, previous, "compatible", awarded)
	if awarded:
		points_earned.emit(flower)

## A bee entering the hive grooms her pollen off, so her next trip's first
## flower delivers nothing. bee.gd calls this whenever the bee is parented
## under the hive root, which every way into the hive does
## (world_building.gd::move_bee_into_hive reparents her).
func groom(bee: Node2D) -> void:
	# Untyped, for the same reason as record_visit: it may have died.
	var last = bee.trip_last_flower
	if last == null:
		return
	bee.trip_last_flower = null
	if _logging():
		DiagnosticLog.log_action("pollination_groomed", "bee %d" % int(bee.bee_id), "recorded", "")

## PP-2: a skill purchase spends points. skill_tree_panel.gd::buy_skill calls
## it with exactly what Progression.purchase deducted from its snapshot, so
## the ledger loses the recipe's points and nothing else. Returns what was
## taken; asking for more than is held takes what there is.
func spend(amount: int) -> int:
	var before := points
	var taken := clampi(amount, 0, points)
	points -= taken
	if _logging():
		DiagnosticLog.log_action("pollination_spent", str(amount), "recorded",
			JSON.stringify({"before": before, "spent": taken, "after": points}))
	return taken

# --- seed set (PP-4) ------------------------------------------------
## Whether this run's level row asks for seed set. A Challenge's does not,
## so Challenges 1 and 2 replant as they always have.
static func seed_set_on() -> bool:
	return Levels.seed_set_enabled(Session.starting_level)

## flower.gd calls this once as a flower dies of age, before it frees
## itself. Counts and queues a seed only when the run has seed set and the
## flower set seed; logs every death in a "pollination_log" scenario.
func flower_withered(flower: Node2D) -> void:
	var on := seed_set_on()
	var sets: bool = flower.sets_seed()
	if on and sets:
		seed_counts[flower.species_name] = int(seed_counts.get(flower.species_name, 0)) + 1
		pending_seeds.append([flower.species_index, flower.position.x, flower.position.y])
		# Never more waiting than the meadow holds: each seed fills one gap.
		while pending_seeds.size() > maxi(1, int(GameConfig.flower_count)):
			pending_seeds.pop_front()
	if _logging():
		DiagnosticLog.log_action("pollination_withered", flower.species_name, "recorded", JSON.stringify({
			"flower": [flower.position.x, flower.position.y],
			"species_index": flower.species_index,
			"compatible_visits": flower.compatible_visits,
			"incompatible_visits": flower.incompatible_visits,
			"seed_set_on": on,
			"sets_seed": sets,
			"seed_counts": seed_counts,
			"pending": pending_seeds.size(),
		}))

## The oldest seed waiting to be planted, removed from the queue, or an
## empty array when none is. Only world_building.gd::_seed_flower takes them.
func take_pending_seed() -> Array:
	if pending_seeds.is_empty():
		return []
	return pending_seeds.pop_front()

## The seed counts the seasonal draw is weighted by now, or an empty
## dictionary for an ordinary draw. `regrowing` is whether COL-8's spring
## regrowth is still under way (world_building.gd reads
## Flower.regrowth_factor). The first call after a winter moves the year's
## counts into spring_counts and starts seed_counts again, whether or not
## the regrowth is still running.
func regrowth_counts(regrowing: bool) -> Dictionary:
	if not seed_set_on() or Session.winter_ends_day <= 0.0 or Session.winter_here:
		return {}
	if spring_of != Session.winter_ends_day:
		spring_counts = seed_counts
		seed_counts = {}
		spring_of = Session.winter_ends_day
		if _logging():
			DiagnosticLog.log_action("pollination_spring", str(spring_of), "recorded",
				JSON.stringify({"spring_counts": spring_counts}))
	return spring_counts if regrowing else {}

## One line per replacement in a "pollination_log" scenario: `kind` is
## "seed" (planted from a pending seed at `parent`) or "seasonal" (today's
## draw, with the weights it was drawn from and the counts that weighted it).
func log_replant(kind: String, flower: Node2D, parent: Array, weights: Array, counts: Dictionary) -> void:
	if not _logging():
		return
	DiagnosticLog.log_action("pollination_replant", kind, "recorded", JSON.stringify({
		"flower": [flower.position.x, flower.position.y],
		"species": flower.species_name,
		"species_index": flower.species_index,
		"parent": parent,
		"weights": weights,
		"counts": counts,
	}))

func _logging() -> bool:
	return main != null and main.scenario_active and main.scenario_pollination_log

func save_data() -> Dictionary:
	return {POINTS: points, CONTRIBUTION: contribution}

## A record that is missing, or not a dictionary, restores zero -- how every
## save from before PP-1 loads.
func restore(data) -> void:
	points = 0
	contribution = 0
	if typeof(data) != TYPE_DICTIONARY:
		return
	points = maxi(0, int(data.get(POINTS, 0)))
	contribution = maxi(0, int(data.get(CONTRIBUTION, 0)))

## PP-4: the seed counts and the seeds waiting, save_game.gd's "seed_bank".
func seed_save_data() -> Dictionary:
	return {
		SEED_COUNTS: seed_counts.duplicate(),
		SPRING_COUNTS: spring_counts.duplicate(),
		SPRING_OF: spring_of,
		PENDING_SEEDS: pending_seeds.duplicate(true),
	}

## A record that is missing, or not a dictionary -- every save from before
## PP-4 -- restores no seed counts and no seeds waiting.
func restore_seed(data) -> void:
	seed_counts = {}
	spring_counts = {}
	spring_of = 0.0
	pending_seeds = []
	if typeof(data) != TYPE_DICTIONARY:
		return
	seed_counts = _restore_counts(data.get(SEED_COUNTS))
	spring_counts = _restore_counts(data.get(SPRING_COUNTS))
	spring_of = maxf(0.0, float(data.get(SPRING_OF, 0.0)))
	var seeds = data.get(PENDING_SEEDS)
	if typeof(seeds) == TYPE_ARRAY:
		for entry in seeds:
			if typeof(entry) == TYPE_ARRAY and entry.size() == 3:
				pending_seeds.append([int(entry[0]), float(entry[1]), float(entry[2])])

## JSON reads every number back as a float; the counts are whole.
static func _restore_counts(data) -> Dictionary:
	var out: Dictionary = {}
	if typeof(data) != TYPE_DICTIONARY:
		return out
	for species in data:
		var count := int(data[species])
		if count > 0:
			out[str(species)] = count
	return out

## Only in a headless scenario that sets "pollination_log": true
## (main.gd's scenario_pollination_log): one session-log line per finished
## visit, so tests/test_pp1_pollination_ledger.py can watch each delivery
## and award happen rather than infer them from the totals. Ordinary play,
## and every other scenario, writes nothing here.
func _log_visit(bee: Node2D, flower: Node2D, previous: Node2D, kind: String, awarded: bool) -> void:
	if not _logging():
		return
	# Only a delivery has a flower it came from; "first" may hold a freed one.
	var delivered := kind != "first"
	var detail := {
		"bee": int(bee.bee_id),
		"flower": [flower.position.x, flower.position.y],
		"species": flower.species_name,
		"from": [previous.position.x, previous.position.y] if delivered else [],
		"from_species": previous.species_name if delivered else "",
		"owned": pollinator_points_on(),
		"awarded": awarded,
		"award_ready_at": flower.award_ready_at,
		"compatible_visits": flower.compatible_visits,
		"incompatible_visits": flower.incompatible_visits,
		"points": points,
		"contribution": contribution,
	}
	DiagnosticLog.log_action("pollination_visit", kind, "recorded", JSON.stringify(detail))
