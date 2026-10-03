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

const Conditions = preload("res://scripts/conditions.gd")
const Levels = preload("res://scripts/levels.gd")

## skills.gd's AUTOMATION id, spelled out because only progression.gd may read
## the skill catalogue (source_checks.py), as challenge_stages.gd does for
## NURSES; tests/test_conditions.py fails if the two drift apart.
const AUTOMATION_SKILL := "skill.hive_mind.automation"

## The six milestones, in the order a colony usually meets them. The label is
## for CR-3's readout; the goal is COL-1's short player-facing line for the
## goal shelf.
const MILESTONES := [
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

## COL-2: the key under which the win is recorded in met_days, beside the
## milestone ids, so the saved record needs no new field.
const VICTORY := "victory"

var main: Node2D
## Milestone id -> the day it was first met. A milestone absent here is not
## met yet.
var met_days: Dictionary = {}


## True in a Colony Run only. Read from the level row each time, so a load
## that switches level (CR-1's starting_level) is followed without a reset.
func applies() -> bool:
	var level: Dictionary = Levels.get_level(Session.starting_level)
	return str(level.get("run_type", "")) == "colony"


## Called from main.gd on day change and on population change. Checks only
## the milestones not yet met, and records today's day for any that now are.
func evaluate() -> void:
	if main == null or not applies():
		return
	var changed := false
	for milestone in MILESTONES:
		var id: String = milestone.id
		if met_days.has(id):
			continue
		if Conditions.met(main, milestone.condition):
			met_days[id] = main.day
			changed = true
	if changed:
		show_next()


## The day `id` was first met, or -1 if it hasn't been.
func day_met(id: String) -> int:
	return int(met_days.get(id, -1))


## What save_game.gd writes: a copy, so the save never aliases live state.
func save_data() -> Dictionary:
	return met_days.duplicate()


## Puts back what a save recorded, replacing whatever this run holds.
## Unknown ids are dropped, and JSON's floats come back as whole days. An
## empty dictionary -- a save from before CR-2 -- means nothing met.
func restore(data: Dictionary) -> void:
	met_days.clear()
	for milestone in MILESTONES:
		var id: String = milestone.id
		var day = data.get(id)
		if typeof(day) == TYPE_INT or typeof(day) == TYPE_FLOAT:
			met_days[id] = int(day)
	var won = data.get(VICTORY)
	if typeof(won) == TYPE_INT or typeof(won) == TYPE_FLOAT:
		met_days[VICTORY] = int(won)


## COL-2 (decision 3): the Colony Run is won the first time a gyne leaves
## after the first winter has ended with the queen alive. Called from
## season.gd's gyne_released only, so a gyne from before winter never counts
## and a later day change cannot win on an old release. The win is recorded
## in met_days, so a load never shows the screen twice.
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
	for milestone in MILESTONES:
		var id: String = milestone.id
		if met_days.has(id):
			if int(met_days[id]) >= done_day:
				done_day = int(met_days[id])
				done_goal = milestone.goal
		elif next_goal.is_empty():
			next_goal = milestone.goal
	if next_goal.is_empty():
		next_goal = "Every milestone met -- your colony has made it"
	main.hud.set_challenge_goal(next_goal, done_goal)
