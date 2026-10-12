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

## Emitted once per point earned, with the flower that earned it, for PP-2's
## rising "+1". Presentation listens; nothing in the simulation does.
signal points_earned(flower: Node2D)

## skills.gd's Pollinator points effect key (an enable_behaviour effect).
const BEHAVIOUR := "pollinator_points_on"
const POINTS := "points"
const CONTRIBUTION := "contribution"

var main: Node2D
var points: int = 0
var contribution: int = 0

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
