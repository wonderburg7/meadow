extends RefCounted
## The settings-window toggle prerequisite tree: which toggle each one
## depends on, plus the two lookups debug_panel.gd's cascade walks need.
## Extracted out of debug_panel.gd so the rule is data any script can
## query, not something only reachable through a checkbox widget --
## DESIGN_BACKLOG.md's section 13, slice 3 (the only slice in that
## section that touches code). See GAME_MODEL.md's
## Availability/prerequisites card for the full read.
##
## debug_panel.gd still owns turning toggles on/off and syncing their
## checkboxes -- that's presentation. This file only answers "what does
## X depend on" and "what depends on X", so a future non-UI caller could
## ask the same question without going through the settings window.
##
## Usage: const Prerequisites = preload("res://scripts/prerequisites.gd")
##        Prerequisites.is_gated(key)

## key -> the one toggle it depends on. Empty/absent means no
## prerequisite. Mirrors the intended research order for a future skills
## tree, not built yet (see docs/archive/SCOUTING_TOGGLE_PLAN.md).
const TOGGLE_PREREQUISITE := {
	"scouting_on": "orientation_flight_on",
	"floral_constancy_on": "scouting_on",
	"auto_recruitment_on": "scouting_on",
	"crab_spider_recruit_suppression_on": "predators_on",
	"alarm_pheromone_on": "predators_on",
}

## True if `key` takes part in the tree at all, either as something with
## a prerequisite or as something else's prerequisite.
static func is_gated(key: String) -> bool:
	return TOGGLE_PREREQUISITE.has(key) or TOGGLE_PREREQUISITE.values().has(key)

## The one toggle `key` directly depends on, or "" if none.
static func direct_parent(key: String) -> String:
	return TOGGLE_PREREQUISITE.get(key, "")

## Every toggle that directly depends on `key`.
static func direct_dependents(key: String) -> Array[String]:
	var found: Array[String] = []
	for child in TOGGLE_PREREQUISITE:
		if TOGGLE_PREREQUISITE[child] == key:
			found.append(child)
	return found
