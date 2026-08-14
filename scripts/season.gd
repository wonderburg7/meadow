extends Node2D
## The year: seasons, disease pressure, winter, and gynes leaving.
##
## These four are together because they are one idea. A colony's year has
## a shape -- build up, peak, prepare, survive -- and each of these is one
## edge of it. Keeping them in one file makes the shape visible, and
## keeps main.gd from growing another four systems.
##
## The colony's own simulation is untouched by all of it. Winter doesn't
## add a winter state machine to every bee; it stops the foragers going
## out and lets the existing energy rules do the work. Disease doesn't
## add an illness system; it scales two numbers the brood and the bees
## already read. Both are deliberately thin.

signal winter_started()
signal winter_survived(losses: int)
signal gyne_released(total: int)

var world: Node2D = null

## Pathogen pressure, 0 to 1. Rises with dead larvae left in the comb and
## with sheer crowding, falls on its own once the cause is dealt with.
var disease: float = 0.0

## Started at a random point in its second so this tick, the rival
## colony's tick and main.gd's signal refresh don't all land on the same
## frame. Three separate whole-colony sweeps arriving together is a
## visible hitch; spread out, none of them is.
var tick_timer: float = randf()
## Bees alive when winter began, so the loss can be reported at the end.
var bees_at_winter_start: int = 0

func _ready() -> void:
	add_to_group("season")

func _process(delta: float) -> void:
	Perf.begin("season")
	if world == null or not is_instance_valid(world):
		Perf.end("season")
		return
	# Once a second is plenty for all of this -- none of it changes on a
	# timescale a player could see faster than that.
	tick_timer += delta
	if tick_timer < 1.0:
		Perf.end("season")
		return
	var elapsed := tick_timer
	tick_timer = 0.0

	_advance_disease(elapsed)
	_advance_winter()
	_release_ready_gynes()
	Perf.end("season")

# --- disease ------------------------------------------------------
## Pressure builds from two things: bodies left in the comb, and how many
## bees are packed into how much space. Both are things the player
## controls, which is what makes it a decision rather than a tax.
func _advance_disease(elapsed: float) -> void:
	if not GameConfig.disease_on:
		disease = 0.0
		return

	var corpses: int = world.hive.cells_holding("corpse").size()
	var bees: int = world.get_tree().get_nodes_in_group("bees").size()
	var cells: int = max(1, world.hive.cells.size())
	# Crowding is bees per cell, not bees: a big colony in a big hive is
	# fine, a big colony in a small one is not.
	var crowding: float = float(bees) / float(cells)

	var rise: float = (
		corpses * GameConfig.disease_per_corpse
		+ bees * crowding * GameConfig.disease_per_bee
	)
	disease += (rise - GameConfig.disease_recovery) * elapsed
	disease = clampf(disease, 0.0, 1.0)

## How much slower brood develops right now, as a multiplier. Read by
## hive_cell.gd each frame.
func brood_rate() -> float:
	return 1.0 - _severity() * GameConfig.disease_brood_penalty

## How much longer or shorter a bee's lifespan runs right now, as a
## multiplier on the whole. Disease shortens it; winter lengthens it far
## more, on top of whatever disease is doing -- a clustered, dormant
## winter bee simply wears out slower, and the colony is meant to
## overwinter on close to the same bees it went in with rather than
## replacing them mid-winter.
func lifespan_factor() -> float:
	var factor: float = 1.0 - _severity() * GameConfig.disease_lifespan_penalty
	if Session.winter_here:
		factor *= GameConfig.winter_lifespan_factor
	return factor

## Nothing happens below the threshold, then it ramps. A colony that is
## basically clean shouldn't be paying anything at all -- the cost has to
## arrive as a consequence of neglect, not as a constant drag.
func _severity() -> float:
	if disease <= GameConfig.disease_threshold:
		return 0.0
	return (disease - GameConfig.disease_threshold) / max(0.001, 1.0 - GameConfig.disease_threshold)

func disease_text() -> String:
	if not GameConfig.disease_on:
		return ""
	if disease <= GameConfig.disease_threshold:
		return "Hive health: fine (%d%%)" % int(disease * 100.0)
	return "Hive health: pathogens building (%d%%) — brood slowed, bees dying early" % int(disease * 100.0)

# --- winter -------------------------------------------------------
## Winter is not a new set of behaviours. It stops foragers leaving and
## lets the existing energy rules run: bees eat from the comb, the comb
## runs down, and if it runs out they starve. Everything that makes it
## survivable -- honey, sealed cells, a smaller colony -- is already in
## the game. That is the whole argument for doing it this way.
func _advance_winter() -> void:
	if not Session.winter_coming:
		return

	if not Session.winter_here:
		if world.day >= Session.winter_starts_day:
			Session.winter_here = true
			Session.winter_ends_day = world.day + GameConfig.winter_length_days
			bees_at_winter_start = world.get_tree().get_nodes_in_group("bees").size()
			winter_started.emit()
		return

	if world.day < Session.winter_ends_day:
		return

	# Made it. The survivors carry on, and the next winter has to be
	# scheduled again -- one season at a time.
	Session.winter_here = false
	Session.winter_coming = false
	var survivors: int = world.get_tree().get_nodes_in_group("bees").size()
	winter_survived.emit(max(0, bees_at_winter_start - survivors))

## True while foragers should stay in. Read by bee.gd alongside the rain
## check, so there's one place that decides whether it's worth going out.
func foraging_stopped() -> bool:
	return Session.winter_here

# --- gynes leaving ------------------------------------------------
## A mature gyne with enough in her flies off to found a colony of her
## own. She counts once and is removed: the colony has spent everything
## it spent on her, and what it gets back is a number on the scoreboard.
##
## This is the win condition. A run isn't measured by how big the hive
## got -- a huge hive that released nothing has failed at the only thing
## a season is for.
func _release_ready_gynes() -> void:
	if not _gyne_season():
		return
	for bee in world.get_tree().get_nodes_in_group("bees"):
		if not is_instance_valid(bee) or not bee.is_gyne or bee.is_dying:
			continue
		if bee.energy < GameConfig.energy_capacity * GameConfig.gyne_release_energy:
			continue
		bee.leave_to_found_colony()
		Session.gynes_released += 1
		gyne_released.emit(Session.gynes_released)

## Gynes only leave late in the year -- one released in spring would have
## nowhere to overwinter, and letting them go the moment they matured
## would remove the decision about when to start raising them.
func _gyne_season() -> bool:
	if Session.winter_here:
		return false
	if not GameConfig.seasons_on:
		return true
	return Flower.season_fraction() >= GameConfig.gyne_release_day

const Flower = preload("res://scripts/flower.gd")
