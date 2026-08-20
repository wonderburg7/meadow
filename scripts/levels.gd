extends RefCounted
## Level presets: the fixed starting stages the main menu offers, so a run
## can begin partway in rather than always from a lone queen. Level id 0
## means "use whatever the tuning numbers say" -- world_building.gd falls
## back to GameConfig whenever LEVELS.get() returns an empty dictionary,
## which is the ordinary Restart Run behaviour.
##
## Extracted out of main.gd's old LEVELS constant (agreed direction in
## DESIGN_BACKLOG.md §1) as the first step toward the Challenges/starter-
## modes split in TUTORIAL_PLAN.md. Each entry now carries empty
## `unlocks` and `win_conditions` arrays alongside the starting-state
## fields that were already here, so Challenge 1 and 2 can fill those in
## without a second restructure. Levels 1 and 2 are the ones TUTORIAL_PLAN.md
## says will eventually be superseded by full Challenge definitions;
## levels 3-5 stay as plain starter-mode presets.
##
## `weather`, `disease`, `rival_hive` and `winter` are read directly by
## the systems they gate (main.gd::_advance_weather, season.gd::
## _advance_disease, world_building.gd::_build_meadow,
## year_winter.gd::begin_winter_countdown) alongside each system's own
## GameConfig toggle -- `.get(key, true)` so every level except 1 and 2
## behaves exactly as before. Deliberately *not* a GameConfig write: per
## .claude/rules/saving.md, a Challenge-local override belongs on the
## thing it affects, not the shared autoload -- writing e.g.
## GameConfig.weather_on = false here would leak into every later run
## the same way an early attempt at cell_build_time did (see
## challenge_runner.gd's FAST_BUILD_TIME comment).

const LEVELS := {
	1: {
		"cells": 0, "nectar_foragers": 0, "pollen_foragers": 0,
		"nurses": 0, "builders": 0, "miners": 0,
		"weather": false, "disease": false, "rival_hive": false, "winter": false,
		"unlocks": [], "win_conditions": [],
	},
	# Challenge 2: Brood, Roles and Expansion (TUTORIAL_PLAN.md). 5 cells,
	# stocked from the last-built backward (see world_building.gd::
	# _stock_starting_comb) -- 2 nectar-full, 1 pollen-full, 2 left empty
	# for the queen to lay into at stage 2.1. No worker bees; the queen is
	# the only one, role EGG_LAYER (challenge_runner.gd resets this
	# explicitly at start() too, since Challenge 1 may have left her as a
	# Forager).
	2: {
		"cells": 5, "nectar_foragers": 0, "pollen_foragers": 0,
		"nurses": 0, "builders": 0, "miners": 0,
		"stock": {"nectar": 2, "pollen": 1},
		"weather": false, "disease": false, "rival_hive": false, "winter": false,
		"unlocks": [], "win_conditions": [],
	},
	3: {
		"cells": 3, "nectar_foragers": 1, "pollen_foragers": 1,
		"nurses": 0, "builders": 0, "miners": 0,
		"unlocks": [], "win_conditions": [],
	},
	4: {
		"cells": 15, "nectar_foragers": 8, "pollen_foragers": 3,
		"nurses": 2, "builders": 2, "miners": 2,
		"unlocks": [], "win_conditions": [],
	},
	# An established colony: enough bees and stores that the interesting
	# decisions are about where it goes next rather than whether it
	# survives the first week. `automine` puts the miners straight to
	# work, and `stock` fills some of the comb so the queen can lay from
	# the first moment instead of waiting on the first pollen delivery.
	5: {
		"cells": 12, "nectar_foragers": 16, "pollen_foragers": 6,
		"nurses": 2, "builders": 3, "miners": 3, "automine": true,
		"stock": {"nectar": 4, "pollen": 2},
		"unlocks": [], "win_conditions": [],
	},
}

## Dev-only headless playtest path (AI_PLAYTEST_PLAN.md). main.gd's
## --scenario= boot arg parses a JSON file into this instead of adding a
## sixth entry to the const LEVELS above, and points Session.starting_level
## at SCENARIO_LEVEL_ID -- every existing `LEVELS.get(Session.starting_level,
## {})`-shaped call site becomes get_level(...) below, so a scenario run
## reuses the same lookup instead of a parallel one. Empty except during a
## --scenario= boot; never touched from the main menu.
const SCENARIO_LEVEL_ID := 999
static var scenario_override: Dictionary = {}

static func get_level(id: int) -> Dictionary:
	if id == SCENARIO_LEVEL_ID and not scenario_override.is_empty():
		return scenario_override
	return LEVELS.get(id, {})
