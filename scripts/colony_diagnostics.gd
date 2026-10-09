extends RefCounted
## One pass over the current bees and hive cells, producing the facts the
## problem-strip signals, the Colony/Nursery panels and the winter forecast
## all read -- consolidating what were three separate walks of the same
## state (year_winter.gd's `_refresh_signals`, `_refresh_panels` and
## `_winter_forecast`) into one. See plans/design/colony-diagnostics.md.

const Roles = preload("res://scripts/roles.gd")

static func compute(main: Node2D, bees: Array, counts: Dictionary) -> Dictionary:
	var starving = 0
	var hungry = 0
	for b in bees:
		if b.energy < GameConfig.energy_capacity * 0.15:
			starving += 1
		elif b.energy < GameConfig.energy_capacity * GameConfig.low_energy_warning_level:
			hungry += 1
	var foragers: int = int(counts.get(Roles.count_key(Roles.FORAGER, "nectar"), 0)) + int(counts.get(Roles.count_key(Roles.FORAGER, "pollen"), 0))
	var nurses: int = int(counts.get(Roles.count_key(Roles.NURSE), 0))
	var comb_workers: int = int(counts.get(Roles.count_key(Roles.COMB_WORKER), 0))

	# Reads hive.gd's mutation-owned content buckets rather than walking
	# every cell fresh -- the hive only re-scans its cells when a
	# build/hatch/designation/load actually changed one, not once a second
	# regardless.
	var hungry_brood = 0
	var brood_cells: Array = main.hive.cells_holding("brood")
	for cell in brood_cells:
		if cell.brood_fed_seconds <= 0.0:
			hungry_brood += 1
	var blocked_cells: int = main.hive.cells_holding("corpse").size()
	var free_cells = 0
	for cell in main.hive.cells_holding(""):
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

	return {
		"bees_count": bees.size(),
		"starving": starving,
		"hungry": hungry,
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
