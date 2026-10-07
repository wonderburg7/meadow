extends Node2D
## The year: seasons, disease pressure, winter, and gynes leaving.
##
## These four are together because they are one idea. A colony's year has
## a shape -- build up, peak, prepare, survive -- and each of these is one
## edge of it. Keeping them in one file makes the shape visible, and
## keeps main.gd from growing another four systems.
##
## The colony's own simulation is untouched by all of it. Winter isn't
## played at all (COL-6): the day it arrives the colony pays one bill out
## of the comb and the run moves on to spring. Disease doesn't add an
## illness system; it scales two numbers the brood and the bees already
## read. Both are deliberately thin.

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
	var level: Dictionary = Levels.get_level(Session.starting_level)
	if not GameConfig.disease_on or not level.get("disease", true):
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
## Winter is skipped and resolved in one step (COL-6, decision 11 of
## plans/now/colony-run.md). The day it arrives the colony pays, at once,
## what a played winter would have burned -- winter_bill, the figure the
## winter window forecasts -- out of the comb's stores, and the next tick is
## the first day of spring. Nobody ages, eats or forages through the skipped
## days. Everything that makes winter survivable -- honey, sealed cells, a
## smaller colony -- still is: they are what the bill is paid from.
func _advance_winter() -> void:
	if not Session.winter_coming:
		# The countdown opens before every winter, relative to this year's
		# playable season. Its dates stay in Session so a save made during the
		# countdown carries that particular winter through unchanged.
		if world.day >= _winter_countdown_day():
			world.begin_winter_countdown()
		return

	if not Session.winter_here:
		if world.day >= Session.winter_starts_day:
			Session.winter_here = true
			Session.winter_ends_day = world.day + GameConfig.winter_length_days
			winter_started.emit()
			_resolve_winter(GameConfig.winter_length_days)
		return

	# Only a save made during a played winter, before COL-6, reaches here:
	# it loads with winter_here set. The skip finishes that winter now,
	# billing only the days it had left.
	_resolve_winter(maxf(0.0, Session.winter_ends_day - world.day))

## Pays `days` of winter in one go and moves the clock on to spring. The
## bill comes out of the stores; if they fall short, the bees the stores
## cannot carry die now, as they would have starved through it. Then the
## day counter jumps by those days -- main.gd derives the day from sim_time
## -- and winter ends exactly as a winter that was played through ended:
## winter_here and winter_coming clear (so the next countdown is scheduled
## a year on), winter_ends_day stays set (conditions.gd's winter_over reads
## it), and winter_survived fires once with the bees the bill took.
func _resolve_winter(days: float) -> void:
	var bees: Array = []
	for bee in world.get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(bee) and not bee.is_dying:
			bees.append(bee)
	var held: float = winter_stores()
	var lost: Array = _winter_losses(bees, held, days)
	_pay_from_stores(minf(held, winter_bill(bees.size() - lost.size(), days)))
	# The queen dies through the ordinary path: main.gd's _check_for_loss sees
	# her gone, a gyne succeeds her (COL-10) or the run ends with the
	# checkpoint offer (COL-3).
	for bee in lost:
		BeeSurvival.die(bee, "starvation")
	Session.sim_time += days * GameConfig.seconds_per_day
	Session.winter_here = false
	Session.winter_coming = false
	winter_survived.emit(lost.size())

## What `bees` bees burn through `days` of winter, in energy units:
## bees x energy_burn_rate x winter_burn_factor x winter's seconds
## (decision 11). The one copy of the formula: year_winter.gd's forecast
## reads it, so the forecast and the charge can never disagree. `days`
## defaults to a whole winter.
func winter_bill(bees: int, days: float = -1.0) -> float:
	if days < 0.0:
		days = GameConfig.winter_length_days
	return (
		bees * GameConfig.energy_burn_rate * GameConfig.winter_burn_factor
		* days * GameConfig.seconds_per_day
	)

## What the comb holds against the bill, in the same energy units: nectar
## plus ripe honey at honey_energy_factor, sealed cells included. Read by the
## forecast too.
func winter_stores() -> float:
	return world.hive.total("nectar") + world.hive.total_honey() * GameConfig.honey_energy_factor

## Who the stores cannot carry through `days` of winter. While the
## survivors' bill is more than is held, bees go in this order (Dave's
## decision, 7 Oct 2026): drones, then workers, then gynes, the oldest first
## (by age_seconds) within each group. The queen goes last, and only if the
## stores cannot cover even her own share. Brood is a cell, not a bee, so it
## stays outside the bill. Reads only is_queen, is_gyne, is_drone and
## age_seconds, so tests/test_col6_winter_skip.py can hand it stand-ins.
func _winter_losses(bees: Array, held: float, days: float) -> Array:
	var lost: Array = []
	if held >= winter_bill(bees.size(), days):
		return lost
	var drones: Array = bees.filter(func(bee): return bee.is_drone and not bee.is_queen)
	var workers: Array = bees.filter(func(bee): return not bee.is_drone and not bee.is_gyne and not bee.is_queen)
	var gynes: Array = bees.filter(func(bee): return bee.is_gyne and not bee.is_queen)
	var survivors: int = bees.size()
	for group in [drones, workers, gynes]:
		group.sort_custom(func(a, b): return a.age_seconds > b.age_seconds)
		for bee in group:
			if held >= winter_bill(survivors, days):
				return lost
			lost.append(bee)
			survivors -= 1
	if held < winter_bill(1, days):
		for bee in bees:
			if bee.is_queen:
				lost.append(bee)
	return lost

## Takes `energy` out of the comb. The open cells pay first, through the
## hive's own take_energy (honey before nectar). Sealed cells count in what
## the forecast says the comb holds, and a winter is what they were sealed
## for, so what the open cells could not pay comes out of them, in the same
## order. A sealed cell left with something in it is closed again; one
## emptied stays open.
func _pay_from_stores(energy: float) -> void:
	if energy <= 0.0:
		return
	var owed: float = energy - world.hive.take_energy(energy)
	for key in Resources.energy_keys_by_priority():
		var factor: float = maxf(0.001, Resources.energy_factor_for(key))
		for cell in world.hive.cells:
			if owed <= 0.0:
				break
			if not is_instance_valid(cell) or cell.can_withdraw() or cell.content_type != key:
				continue
			if key == "honey" and not cell.is_ripe_honey():
				continue
			var was_closed: bool = cell.is_closed
			cell.set_closed(false)
			owed -= cell.take_resource(key, owed / factor) * factor
			if cell.amount > 0.0:
				if was_closed:
					cell.set_closed(true)
				else:
					cell.set_fill_then_close(true)
	world.hive.announce()

## The first day on which this year's countdown may open. A short playable
## season opens immediately when its configured notice would otherwise reach
## into the previous winter; that keeps the countdown inside its own year.
func _winter_countdown_day() -> float:
	var season_days: float = maxf(1.0, GameConfig.season_length_days)
	var year_days: float = Session.year_days()
	var year_start: float = floor((world.day - 1.0) / year_days) * year_days + 1.0
	return year_start + maxf(0.0, season_days - GameConfig.winter_countdown_days)

## True while foragers should stay in. Read by bee.gd alongside the rain
## check, so there's one place that decides whether it's worth going out.
func foraging_stopped() -> bool:
	return Session.winter_here

# --- the mating curve ---------------------------------------------
## Decision 7 of plans/now/colony-run.md: mating follows one curve through
## the year -- nothing outside late spring to early autumn, rising to 1 at
## mid summer. This is that curve, the only one: COL-11's nuptial flights
## read it through nuptial_mating_chance, and COL-7's genetic credit reads
## mating_curve itself rather than keeping a second.
##
## Measured on the playable season's fraction (Flower.season_fraction), in
## the thirds year_winter.gd names: spring to 0.33, summer to 0.66, autumn
## to 1. The window opens in the last part of spring and closes early in
## autumn, and peaks halfway through, in mid summer.
const MATING_WINDOW_START := 0.2
const MATING_WINDOW_END := 0.8

## Today's place on the curve, 0 to 1: 0 outside the window and through
## winter, a smooth arch inside it, 1 at mid summer. With seasons off the
## year holds at mid season (season_fraction is 0.5), so the curve is 1.
func mating_curve() -> float:
	if Session.winter_here:
		return 0.0
	var through_year: float = Flower.season_fraction()
	if through_year <= MATING_WINDOW_START or through_year >= MATING_WINDOW_END:
		return 0.0
	var through_window: float = (through_year - MATING_WINDOW_START) / (MATING_WINDOW_END - MATING_WINDOW_START)
	return sin(PI * through_window)

## The chance an unmated queen coming home from a nuptial flight today has
## mated: GameConfig.nuptial_flight_peak_chance at mid summer, scaled by
## the curve everywhere else. bee.gd::_end_nuptial_flight rolls against it.
func nuptial_mating_chance() -> float:
	return clampf(GameConfig.nuptial_flight_peak_chance * mating_curve(), 0.0, 1.0)

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
const Levels = preload("res://scripts/levels.gd")
const Resources = preload("res://scripts/resources.gd")
const BeeSurvival = preload("res://scripts/bee_survival.gd")
