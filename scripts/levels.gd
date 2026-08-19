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
	2: {
		"cells": 1, "nectar_foragers": 1, "pollen_foragers": 0,
		"nurses": 0, "builders": 0, "miners": 0,
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
