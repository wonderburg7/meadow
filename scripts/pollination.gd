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
## - queues the gap it leaves (`gaps`, oldest first): a seed of its species
##   where it stood if it set seed, an empty gap if not.
##
## world_building.gd::_seed_flower fills the oldest gap first. A seed of a
## species in flower now comes up close by; an empty gap, or a seed whose
## species is out of season, takes today's seasonal draw, the background
## floor. Queuing both kinds keeps the order the flowers died in, so seeds
## waiting never crowd the seasonal draw out.
##
## After winter, while COL-8's regrowth is under way (Flower.regrowth_factor
## below 1), the seasonal draw is weighted by the counts the year gathered
## (regrowth_counts, read through flower_species.gd::species_weights). The
## first death or replacement after a winter moves the counts to
## `spring_counts` and starts `seed_counts` again from zero (_roll_spring),
## so each winter remembers one year.
## save_game.gd writes them, with the gaps, under "seed_bank"
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
const GAPS := "gaps"

const Levels = preload("res://scripts/levels.gd")
const FlowerSpecies = preload("res://scripts/flower_species.gd")

var main: Node2D
var points: int = 0
var contribution: int = 0
## PP-4: seed-setting deaths this year, species name -> count.
var seed_counts: Dictionary = {}
## PP-4: the counts this spring's regrowth reads, moved out of seed_counts
## by _roll_spring after the winter that ended on day `spring_of`.
var spring_counts: Dictionary = {}
var spring_of: float = 0.0
## PP-4: gaps waiting to be filled, oldest first, each [species_index, x, y]
## of the flower that left it; species_index is EMPTY_GAP when it set no seed.
var gaps: Array = []
const EMPTY_GAP := -1

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
	var last: Variant = bee.trip_last_flower
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
	var last: Variant = bee.trip_last_flower
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
## itself. With seed set on, counts the flower if it set seed and queues its
## gap; logs every death in a "pollination_log" scenario.
func flower_withered(flower: Node2D) -> void:
	var on := seed_set_on()
	var sets: bool = flower.sets_seed()
	if on:
		_roll_spring()
		if sets:
			seed_counts[flower.species_name] = int(seed_counts.get(flower.species_name, 0)) + 1
		gaps.append([flower.species_index if sets else EMPTY_GAP, flower.position.x, flower.position.y])
		# Never more waiting than the meadow holds.
		while gaps.size() > maxi(1, int(GameConfig.flower_count)):
			gaps.pop_front()
	if _logging():
		DiagnosticLog.log_action("pollination_withered", flower.species_name, "recorded", JSON.stringify({
			"flower": [flower.position.x, flower.position.y],
			"species_index": flower.species_index,
			"compatible_visits": flower.compatible_visits,
			"incompatible_visits": flower.incompatible_visits,
			"seed_set_on": on,
			"sets_seed": sets,
			"seed_counts": seed_counts,
			"gaps": gaps.size(),
		}))

## The oldest gap waiting, removed from the queue, or an empty array when
## none is. Only world_building.gd::_seed_flower takes them.
func take_gap() -> Array:
	if gaps.is_empty():
		return []
	return gaps.pop_front()

## Whether `gap` holds a seed that can come up now: one was set, and its
## species is in flower today. Out of season, the gap takes the seasonal draw.
static func seed_in_season(gap: Array) -> bool:
	return not gap.is_empty() and int(gap[0]) >= 0 \
		and FlowerSpecies.in_season(FlowerSpecies.SPECIES[int(gap[0]) % FlowerSpecies.SPECIES.size()])

## A bushy seasonal draw fills more than its one gap: it also takes up to
## `count` empty gaps waiting at the front, so the queue keeps pace with the
## room in the meadow. Never skips past a seed. Returns how many it took.
func drop_empty_gaps(count: int) -> int:
	var dropped := 0
	while dropped < count and not gaps.is_empty() and int(gaps[0][0]) == EMPTY_GAP:
		gaps.pop_front()
		dropped += 1
	return dropped

## The seed counts the seasonal draw is weighted by now, or an empty
## dictionary for an ordinary draw. `regrowing` is whether COL-8's spring
## regrowth is still under way (world_building.gd reads
## Flower.regrowth_factor).
func regrowth_counts(regrowing: bool) -> Dictionary:
	if not seed_set_on():
		return {}
	_roll_spring()
	if Session.winter_ends_day <= 0.0 or Session.winter_here:
		return {}
	return spring_counts if regrowing else {}

## Once per winter, on the first death or replacement after it: the year's
## counts become spring's, and the new year's start from zero.
func _roll_spring() -> void:
	if Session.winter_ends_day <= 0.0 or Session.winter_here or spring_of == Session.winter_ends_day:
		return
	spring_counts = seed_counts
	seed_counts = {}
	spring_of = Session.winter_ends_day
	if _logging():
		DiagnosticLog.log_action("pollination_spring", str(spring_of), "recorded",
			JSON.stringify({"spring_counts": spring_counts}))

## One line per flower planted as a replacement in a "pollination_log"
## scenario: `kind` is "seed" (from the seed in `gap`) or "seasonal" (today's
## draw, with the weights it was drawn from and the counts that weighted
## them). A replacement's first flower also carries the gap it filled (empty
## when none was waiting) and how many empty gaps a bush took with it.
func log_replant(kind: String, flower: Node2D, weights: Array, counts: Dictionary, first: bool, gap: Array, dropped: int) -> void:
	if not _logging():
		return
	var detail := {
		"flower": [flower.position.x, flower.position.y],
		"species": flower.species_name,
		"species_index": flower.species_index,
		"weights": weights,
		"counts": counts,
	}
	if first:
		detail["gap"] = gap
		detail["dropped"] = dropped
	DiagnosticLog.log_action("pollination_replant", kind, "recorded", JSON.stringify(detail))

func _logging() -> bool:
	return main != null and main.scenario_active and main.scenario_pollination_log

func save_data() -> Dictionary:
	return {POINTS: points, CONTRIBUTION: contribution}

## A record that is missing, or not a dictionary, restores zero -- how every
## save from before PP-1 loads.
func restore(data: Variant) -> void:
	points = 0
	contribution = 0
	if typeof(data) != TYPE_DICTIONARY:
		return
	points = maxi(0, int(data.get(POINTS, 0)))
	contribution = maxi(0, int(data.get(CONTRIBUTION, 0)))

## PP-4: the seed counts and the gaps waiting, save_game.gd's "seed_bank".
func seed_save_data() -> Dictionary:
	return {
		SEED_COUNTS: seed_counts.duplicate(),
		SPRING_COUNTS: spring_counts.duplicate(),
		SPRING_OF: spring_of,
		GAPS: gaps.duplicate(true),
	}

## A record that is missing, or not a dictionary -- every save from before
## PP-4 -- restores no seed counts and no gaps waiting.
func restore_seed(data: Variant) -> void:
	seed_counts = {}
	spring_counts = {}
	spring_of = 0.0
	gaps = []
	if typeof(data) != TYPE_DICTIONARY:
		return
	seed_counts = _restore_counts(data.get(SEED_COUNTS))
	spring_counts = _restore_counts(data.get(SPRING_COUNTS))
	spring_of = maxf(0.0, float(data.get(SPRING_OF, 0.0)))
	var saved: Variant = data.get(GAPS)
	if typeof(saved) == TYPE_ARRAY:
		for entry: Variant in saved:
			if typeof(entry) == TYPE_ARRAY and entry.size() == 3:
				gaps.append([maxi(EMPTY_GAP, int(entry[0])), float(entry[1]), float(entry[2])])

## JSON reads every number back as a float; the counts are whole.
static func _restore_counts(data: Variant) -> Dictionary:
	var out: Dictionary = {}
	if typeof(data) != TYPE_DICTIONARY:
		return out
	for species: Variant in data:
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
