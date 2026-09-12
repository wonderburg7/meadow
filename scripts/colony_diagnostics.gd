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
	for cell in main.hive.cells_holding("brood"):
		if cell.brood_fed_seconds <= 0.0:
			hungry_brood += 1
	var free_cells = 0
	for cell in main.hive.cells_holding(""):
		if not cell.keep_empty:
			free_cells += 1

	return {
		"bees_count": bees.size(),
		"starving": starving,
		"hungry": hungry,
		"foragers": foragers,
		"nurses": nurses,
		"comb_workers": comb_workers,
		"hungry_brood": hungry_brood,
		"free_cells": free_cells,
	}
