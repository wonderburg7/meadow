extends RefCounted
## One pass over the current bees and hive cells, producing the facts the
## problem-strip signals, the Colony/Nursery panels and the winter forecast
## all read -- consolidating what were three separate walks of the same
## state (year_winter.gd's `_refresh_signals`, `_refresh_panels` and
## `_winter_forecast`) into one. See plans/design/colony-diagnostics.md.

const Roles = preload("res://scripts/roles.gd")

static func compute(main: Node2D, bees: Array, counts: Dictionary) -> Dictionary:
	var starving: int = 0
	var hungry: int = 0
	var waiting_for_work: int = 0
	var travelling_for_work: int = 0
	var no_available_work: int = 0
	for b: Variant in bees:
		if b.energy < GameConfig.energy_capacity * 0.15:
			starving += 1
		elif b.energy < GameConfig.energy_capacity * GameConfig.low_energy_warning_level:
			hungry += 1
		# Bee records the result at its real dispatch search. Re-running that
		# mutable search here could disagree with the work it has just claimed.
		if b.is_waiting_for_work():
			waiting_for_work += 1
		if b.is_travelling_for_work():
			travelling_for_work += 1
		if b.has_no_available_work():
			no_available_work += 1
	var foragers: int = int(counts.get(Roles.count_key(Roles.FORAGER, "nectar"), 0)) + int(counts.get(Roles.count_key(Roles.FORAGER, "pollen"), 0))
	var nurses: int = int(counts.get(Roles.count_key(Roles.NURSE), 0))
	var comb_workers: int = int(counts.get(Roles.count_key(Roles.COMB_WORKER), 0))

	# Reads hive.gd's mutation-owned content buckets rather than walking
	# every cell fresh -- the hive only re-scans its cells when a
	# build/hatch/designation/load actually changed one, not once a second
	# regardless.
	var hungry_brood: int = 0
	var brood_cells: Array = main.hive.cells_holding("brood")
	for cell: Variant in brood_cells:
		if cell.brood_fed_seconds <= 0.0:
			hungry_brood += 1
	var blocked_cells: int = main.hive.cells_holding("corpse").size()
	var free_cells: int = 0
	for cell: Variant in main.hive.cells_holding(""):
		if not cell.keep_empty:
			free_cells += 1

	# A missing workforce is one required role with demand but no assigned
	# worker. Blocked work counts affected cells, not bees: every brood cell
	# stalls without a nurse, and every corpse cell needs a comb worker.
	# These are observations only; they do not change role assignment or the
	# existing warning policy (including the queen's nursing fallback).
	var missing_nurse_workforce: int = int(brood_cells.size() > 0 and nurses == 0)
	var missing_comb_workforce: int = int(blocked_cells > 0 and comb_workers == 0)
	var blocked_work: int = brood_cells.size() * missing_nurse_workforce + blocked_cells * missing_comb_workforce

	# FC-2: while the first crisis's rain falls, the facts its "Why is this
	# happening?" entry states -- how hard it rains, which foragers the rain
	# keeps in and which cannot fly for another reason, and how long the
	# stores last. Read only while it is active, so the walk is bounded.
	var crisis_rain := 0
	var rain_grounded_foragers := 0
	var rain_unable_foragers := 0
	var food_cover_minutes := 0
	var crisis: Variant = main.get("first_crisis")
	if typeof(crisis) == TYPE_DICTIONARY and str(crisis.get("state", "")) == "active":
		var readiness: Dictionary = crisis_readiness(main, bees, false, GameConfig.rain_max_seconds)
		crisis_rain = 1
		rain_grounded_foragers = int(readiness.able_foragers)
		rain_unable_foragers = int(readiness.unable_foragers)
		food_cover_minutes = int(float(readiness.food_cover_seconds) / 60.0)

	return {
		"first_crisis_rain": crisis_rain,
		"rain_percent": int(round(Session.rain_intensity * 100.0)),
		"rain_grounded_foragers": rain_grounded_foragers,
		"rain_unable_foragers": rain_unable_foragers,
		"food_cover_minutes": food_cover_minutes,
		"bees_count": bees.size(),
		"starving": starving,
		"hungry": hungry,
		"waiting_for_work": waiting_for_work,
		"travelling_for_work": travelling_for_work,
		"no_available_work": no_available_work,
		"foragers": foragers,
		"nurses": nurses,
		"comb_workers": comb_workers,
		"hungry_brood": hungry_brood,
		"brood_cells": brood_cells.size(),
		"free_cells": free_cells,
		"blocked_cells": blocked_cells,
		"missing_nurse_workforce": missing_nurse_workforce,
		"missing_comb_workforce": missing_comb_workforce,
		"missing_required_workforce": missing_nurse_workforce + missing_comb_workforce,
		"blocked_work": blocked_work,
	}


## FC-2 (plans/now/crisis-readiness.md): the first crisis's readiness inputs,
## from FC-1's contract. A working forager is a living worker -- not the
## queen, a drone or a gyne -- assigned to foraging and able to fly now. One
## below the starving line is counted apart as unable (too low on energy), so
## the explanation can tell her from a bee the rain keeps in; one the season
## holds in is counted apart again, as season-held. Food cover is the comb's adult food (nectar plus ripe honey at
## honey_energy_factor, the same units as season.gd's winter_stores) over what
## every adult burns at energy_burn_rate, in seconds. The episode needs
## `rain_seconds` of cover. main.gd calls this on its bounded crisis tick (once
## a second inside the window) and for the crisis trace, never per bee frame.
## `skill_owned` says whether the early automation milestone is reached; the
## caller asks progression, the only reader of the skill catalogue.
static func crisis_readiness(main: Node2D, bees: Array, skill_owned: bool, rain_seconds: float) -> Dictionary:
	var able_foragers := 0
	var unable_foragers := 0
	var season_held_foragers := 0
	var foragers_outside := 0
	var bee_energy := 0.0
	var season_stopped: bool = main.season != null and is_instance_valid(main.season) and main.season.foraging_stopped()
	for b: Variant in bees:
		bee_energy += b.energy
		if b.is_queen or b.is_drone or b.is_gyne or b.role != Roles.FORAGER:
			continue
		if not b._is_inside_hive():
			foragers_outside += 1
		if b.energy < GameConfig.energy_capacity * 0.15:
			unable_foragers += 1
		elif season_stopped:
			season_held_foragers += 1
		else:
			able_foragers += 1
	var nectar: float = main.hive.total("nectar")
	var honey: float = main.hive.total_honey()
	var food: float = nectar + honey * GameConfig.honey_energy_factor
	var consumption: float = float(bees.size()) * GameConfig.energy_burn_rate
	var cover: float = food / maxf(consumption, 0.001)
	var food_ready: bool = cover >= rain_seconds
	return {
		"automation": skill_owned,
		"able_foragers": able_foragers,
		"unable_foragers": unable_foragers,
		"season_held_foragers": season_held_foragers,
		"foragers_outside": foragers_outside,
		"food_stores": food,
		"stored_nectar": nectar,
		"stored_honey": honey,
		"stored_pollen": main.hive.total("pollen"),
		"consumption_per_second": consumption,
		# What the bees carry in their own reserves, so a trace can follow
		# the colony's whole food (comb plus bodies) through the rain.
		"bee_energy": bee_energy,
		"food_cover_seconds": cover,
		"food_cover_needed": rain_seconds,
		"food_ready": food_ready,
		"ready": skill_owned and able_foragers > 0 and food_ready,
	}
