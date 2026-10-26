extends RefCounted
## CR-2 (plans/now/colony-run.md decision 4): the Colony Run's milestones,
## from plans/design/product-scope.md §7, and the day each was first met.
##
## Each milestone is data -- an id, a label and a conditions.gd condition --
## so the evaluator is one loop rather than six bespoke checks, and the
## Challenge stage runner stays Challenge-only. Nothing here gates play: the
## recorded days are facts for CR-3's readout and victory screen to show.
##
## It runs only in a run whose level row carries `"run_type": "colony"`, and
## only from main.gd's existing hooks -- day change and population change --
## never per frame. A milestone, once met, is recorded with that day and never
## checked again, so a met milestone can't be un-met by a bad week.
##
## The recorded days go in the save as an additive field
## (save_game.gd's "colony_milestones"); a save without it reads as nothing
## met, which is how every save from before this file loads.
##
## COL-7 (decision 10): the run's genetic points live here too, counted when
## season.gd::send_gyne sends a gyne inside the mating window and saved in
## the same record under GENETIC_POINTS, so save_game.gd needs no new field.
## A record without them restores 0. They are counted and saved now and
## spent later (plans/design/progression.md).

const Conditions = preload("res://scripts/conditions.gd")
const Levels = preload("res://scripts/levels.gd")

## skills.gd's AUTOMATION id, spelled out because only progression.gd may read
## the skill catalogue (source_checks.py), as challenge_stages.gd does for
## NURSES; tests/test_conditions.py fails if the two drift apart.
const AUTOMATION_SKILL := "skill.hive_mind.automation"

## The nine milestones, in the order a colony usually meets them. The label is
## for CR-3's readout; the goal is COL-1's short player-facing line for the
## goal shelf.
const MILESTONES := [
	# SG-4: the opening, one step at a time. Each is shown alone until met.
	{
		"id": "first_cell", "label": "First cell",
		"goal": "Build your first cell",
		"condition": {"built_cells_at_least": 1},
	},
	{
		"id": "first_stores", "label": "First stores",
		"goal": "Bring in nectar and pollen",
		# The stores the first egg was laid on, rounded down in the closeout.
		"condition": {"all_of": [
			{"hive_total": {"resource": "nectar", "at_least": 245}},
			{"hive_total": {"resource": "pollen", "at_least": 155}},
		]},
	},
	{
		"id": "first_egg", "label": "First egg",
		"goal": "Let the queen lay an egg",
		"condition": {"brood_stage": {"stage": "egg", "at_least": 1}},
	},
	{
		"id": "first_worker", "label": "First worker",
		"goal": "Raise your first worker",
		# Any adult other than the queen. The run starts with her alone.
		"condition": {"non_queen_adults_at_least": 1},
	},
	{
		"id": "first_automation", "label": "First automation",
		"goal": "Unlock your first automation",
		"condition": {"skill_owned": AUTOMATION_SKILL},
	},
	{
		"id": "stable_income", "label": "Stable resource income",
		"goal": "Keep nectar and pollen coming in",
		# Nectar and pollen both came in, and neither store fell, across the
		# last three whole days (main.gd's day_store_totals).
		"condition": {"all_of": [
			{"net_income": {"resource": "nectar", "days": 3, "at_least": 0.0}},
			{"net_income": {"resource": "pollen", "days": 3, "at_least": 0.0}},
		]},
	},
	{
		"id": "winter_ready", "label": "Ready for winter",
		"goal": "Get the colony ready for winter",
		# The winter window's own verdict ("On track"), judged on the
		# countdown's last day, on the colony that meets winter.
		"condition": {"winter_ready": true},
	},
	{
		"id": "winter_recovery", "label": "Recovered after winter",
		"goal": "Bring the colony through winter",
		# Winter is over, the queen came through it, and she is laying again:
		# brood in its egg stage is in the comb.
		"condition": {"all_of": [
			{"winter_over": true},
			{"queen_alive": true},
			{"brood_stage": {"stage": "egg", "at_least": 1}},
		]},
	},
	{
		"id": "first_gyne", "label": "First gyne away",
		"goal": "Send out a gyne",
		"condition": {"gynes_released_at_least": 1},
	},
]

## SG-4: the three opening milestones. main.gd checks them once a second
## while one is unmet (opening_pending), so a finished cell or a laid egg
## shows within a second.
const OPENING := ["first_cell", "first_stores", "first_egg"]
## COL-2: the key under which the win is recorded in met_days, beside the
## milestone ids, so the saved record needs no new field.
const VICTORY := "victory"
## COL-7: the key the genetic points are saved under, beside the days.
const GENETIC_POINTS := "genetic_points"
## GP-2: the key the starred goal ids are saved under, in the same record.
const FAVOURITES := "favourites"
## The long-term line's id in a favourites list and in the HUD's entries.
const LONG_TERM := "long_term"

var main: Node2D
## Milestone id -> the day it was first met. A milestone absent here is not
## met yet.
var met_days: Dictionary = {}
## COL-7: the genetic points this run has earned from gynes sent inside the
## mating window. Colony Run only.
var genetic_points: int = 0
## GP-2: the goal ids the player has starred (LONG_TERM or a milestone id).
## A starred line stays on screen while the Goals drop-down is collapsed.
var favourites: Array = []


## True in a Colony Run only. Read from the level row each time, so a load
## that switches level (CR-1's starting_level) is followed without a reset.
func applies() -> bool:
	var level: Dictionary = Levels.get_level(Session.starting_level)
	return str(level.get("run_type", "")) == "colony"


## SG-4: true in a Colony Run while an opening step is still unmet. main.gd's
## one-second check asks this first, so the run does nothing once they are met.
func opening_pending() -> bool:
	if not applies():
		return false
	for id: Variant in OPENING:
		if not met_days.has(id):
			return true
	return false


## Called from main.gd on day change and on population change. Checks only
## the milestones not yet met, and records today's day for any that now are.
func evaluate() -> void:
	if main == null or not applies():
		return
	for milestone: Dictionary in MILESTONES:
		var id: String = milestone.id
		if met_days.has(id):
			continue
		if Conditions.met(main, milestone.condition):
			met_days[id] = main.day
	# GP-1: the Goals drop-down's long-term line follows the day, so it
	# refreshes on every call (day change, death, gyne), not only a new milestone.
	show_next()


## The day `id` was first met, or -1 if it hasn't been.
func day_met(id: String) -> int:
	return int(met_days.get(id, -1))


## COL-7: adds what a gyne sent today earned (season.gd::send_gyne). Only a
## Colony Run counts them.
func add_genetic_points(points: int) -> void:
	if not applies():
		return
	genetic_points += maxi(0, points)


## What save_game.gd writes: a copy, so the save never aliases live state,
## with the genetic points beside the days.
func save_data() -> Dictionary:
	var data: Dictionary = met_days.duplicate()
	data[GENETIC_POINTS] = genetic_points
	data[FAVOURITES] = favourites.duplicate()
	return data


## Puts back what a save recorded, replacing whatever this run holds.
## Unknown ids are dropped, and JSON's floats come back as whole days. An
## empty dictionary -- a save from before CR-2 -- means nothing met.
func restore(data: Dictionary) -> void:
	met_days.clear()
	for milestone: Dictionary in MILESTONES:
		var id: String = milestone.id
		var day: Variant = data.get(id)
		if typeof(day) == TYPE_INT or typeof(day) == TYPE_FLOAT:
			met_days[id] = int(day)
	var won: Variant = data.get(VICTORY)
	if typeof(won) == TYPE_INT or typeof(won) == TYPE_FLOAT:
		met_days[VICTORY] = int(won)
	# COL-7: a record from before the points restores 0.
	genetic_points = 0
	var points: Variant = data.get(GENETIC_POINTS)
	if typeof(points) == TYPE_INT or typeof(points) == TYPE_FLOAT:
		genetic_points = maxi(0, int(points))
	# GP-2: keep only ids this file knows; a record without the key has none.
	favourites.clear()
	var starred: Variant = data.get(FAVOURITES)
	if typeof(starred) == TYPE_ARRAY:
		for id: Variant in starred:
			if _is_goal_id(str(id)) and not favourites.has(str(id)):
				favourites.append(str(id))


## GP-2: true for an id a favourite may carry. SG-3 adds the short-term ids.
func _is_goal_id(id: String) -> bool:
	if id == LONG_TERM:
		return true
	for milestone: Dictionary in MILESTONES:
		if milestone.id == id:
			return true
	return false


## GP-2: the star on a Goals line. Unknown ids are ignored.
func toggle_favourite(id: String) -> void:
	if not _is_goal_id(id):
		return
	if favourites.has(id):
		favourites.erase(id)
	else:
		favourites.append(id)
	show_next()


## GP-2: the day a favourite was met, or -1. The long-term goal is met by the
## win; a milestone by its recorded day.
func _favourite_met_day(id: String) -> int:
	if id == LONG_TERM:
		return day_met(VICTORY)
	return day_met(id)


## GP-2: a met favourite stays, struck through, for the rest of the day it was
## met; once the day has changed it is removed and unstarred. Derived from the
## saved days, so a load mid-day keeps it and a load after it drops it.
func _drop_stale_favourites() -> void:
	for id: Variant in favourites.duplicate():
		var met: int = _favourite_met_day(str(id))
		if met >= 0 and main.day > met:
			favourites.erase(id)


## COL-2 (decision 3): the Colony Run is won the first time a gyne leaves
## after the first winter has ended with the queen alive. Called from
## season.gd's gyne_released only, so a gyne from before winter never counts
## and a later day change cannot win on an old release. Since COL-7 that
## signal fires only for a gyne the player sent inside the mating window, so
## one sent outside it, lost, cannot win. The win is recorded in met_days,
## so a load never shows the screen twice.
func check_victory() -> void:
	if main == null or not applies() or met_days.has(VICTORY):
		return
	if not Conditions.met(main, {"all_of": [{"winter_over": true}, {"queen_alive": true}]}):
		return
	met_days[VICTORY] = main.day
	var bees: int = main.get_tree().get_nodes_in_group("bees").size()
	main.challenge_complete.open(
		"Colony Run won: your colony came through its first winter and sent out a gyne.",
		"A new queen leaves to found a colony of her own. Keep playing to see this one thrive, or head back to the menu.",
		main.day, bees, main.hive.total("nectar"), main.hive.total("pollen"), true,
	)


## COL-1: the goal shelf shows the first milestone not yet met, with the one
## most recently met struck through beneath it. Called when a milestone is
## newly met, at the start of the run and after a load -- never per frame.
## No bar: a milestone has no single number. Does nothing outside a Colony Run.
func show_next() -> void:
	if main == null or main.hud == null or not applies():
		return
	var next_goal := ""
	var done_goal := ""
	var done_day := -1
	var next_id := ""
	var done_id := ""
	for milestone: Dictionary in MILESTONES:
		var id: String = milestone.id
		if met_days.has(id):
			if int(met_days[id]) >= done_day:
				done_day = int(met_days[id])
				done_goal = milestone.goal
				done_id = id
		elif next_goal.is_empty():
			next_goal = milestone.goal
			next_id = id
	if next_goal.is_empty():
		next_goal = "Every milestone met -- your colony has made it"
		next_id = "all_met"
	_drop_stale_favourites()
	var entries: Array = [{
		"id": LONG_TERM, "text": long_term_line(), "done": met_days.has(VICTORY),
		"starred": favourites.has(LONG_TERM),
	}]
	entries.append({"id": next_id, "text": next_goal, "done": false, "starred": favourites.has(next_id)})
	if not done_goal.is_empty():
		entries.append({"id": done_id, "text": done_goal, "done": true, "starred": favourites.has(done_id)})
	# A starred milestone that is met but no longer the newest met one has no
	# line of its own in the drop-down; it still shows while collapsed.
	for milestone: Dictionary in MILESTONES:
		var id: String = milestone.id
		if favourites.has(id) and met_days.has(id) and id != done_id:
			entries.append({"id": id, "text": milestone.goal, "done": true, "starred": true, "extra": true})
	if not main.hud.goal_star_toggled.is_connected(toggle_favourite):
		main.hud.goal_star_toggled.connect(toggle_favourite)
	main.hud.set_colony_goals(entries)


## GP-1 (plans/now/goal-presentation.md decision 3): the long-term goal as
## the run's phase puts it. Read from the winter facts and the mating
## curve, so it is a line of text and changes no outcome.
func long_term_line() -> String:
	if met_days.has(VICTORY):
		return "Your colony has made it -- keep it thriving"
	if Session.winter_here:
		var left: int = maxi(0, int(ceil(Session.winter_ends_day - main.day)))
		return "Survive winter -- %d day%s left" % [left, "" if left == 1 else "s"]
	if Session.winter_ends_day > 0.0:
		if main.season.mating_curve() > 0.0:
			return "Send out a gyne -- the mating window is open"
		return "Send out a gyne -- when the mating window opens"
	if Session.winter_coming:
		return "Survive winter -- it arrives on day %d" % int(Session.winter_starts_day)
	return "Survive the first winter, then send out a gyne"
