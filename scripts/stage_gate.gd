extends Node
## Stage-gated UI visibility: the general mechanism both Challenges lean
## on to hide whole panels/buttons until a sub-stage unlocks them, rather
## than showing them disabled (see TUTORIAL_PLAN.md's "UI unlock rules").
## Nothing in the codebase gated UI before this file; it's new,
## general-purpose plumbing with no consumers yet -- Challenge 1's own
## sub-stages are what will actually call unlock()/lock() as the player
## progresses.
##
## One instance lives at main.stage_gate, following the fog_of_war
## pattern: a plain Node sibling of world_building etc. that holds real
## state of its own rather than just a `main` pointer back to main.gd.
##
## Outside a Challenge run (`active == false`, the default), every key
## reads as unlocked -- starter modes, open world and a plain Restart Run
## never gate anything, so UI code can call is_unlocked() unconditionally
## without a separate "am I in a Challenge" check at every call site.
##
## Hard exemption (TUTORIAL_PLAN.md, "UI unlock rules"): accessibility
## toggles are never inside the hide/reveal list at all, not "unlocked
## early" -- out of this system's scope entirely. ACCESSIBILITY_KEYS below
## makes that a refusal in code rather than a rule someone could forget
## while wiring up a new sub-stage.

signal unlocked_changed(key: String)

const ACCESSIBILITY_KEYS := [
	"colour_blind_mode",
	"settings_cog",
	"ui_theme",
	"text_scale",
	"ui_typeface",
	"reduced_motion",
	"screen_shake",
	"tooltip_delay",
	"show_info_badges",
]

var main: Node2D
var active: bool = false
var _unlocked: Dictionary = {}   # key -> true

## Called when a Challenge run starts. `initial_unlocks` is whatever the
## first sub-stage already shows (Challenge 1's 1.1 starts with hive
## view, queen selection, settings cog and so on already visible).
func start(initial_unlocks: Array = []) -> void:
	active = true
	_unlocked.clear()
	for key in initial_unlocks:
		unlock(key)

## Called when a Challenge run ends -- completed, abandoned to the main
## menu, or superseded by a plain restart -- so a later starter-mode or
## open-world run never inherits a stale unlocked set.
func stop() -> void:
	active = false
	_unlocked.clear()

## True whenever `key`'s UI should be shown. Always true outside a
## Challenge run, and always true for an accessibility key regardless.
func is_unlocked(key: String) -> bool:
	if not active or key in ACCESSIBILITY_KEYS:
		return true
	return _unlocked.has(key)

func unlock(key: String) -> void:
	if key in ACCESSIBILITY_KEYS:
		push_error("stage_gate: '%s' is an accessibility key and must never be gated." % key)
		return
	if _unlocked.has(key):
		return
	_unlocked[key] = true
	unlocked_changed.emit(key)

func lock(key: String) -> void:
	_unlocked.erase(key)

## The current unlocked set, for the checkpoint system to save alongside
## the rest of a sub-stage's state -- rolling a Challenge run back to an
## earlier checkpoint must hide whatever that earlier sub-stage hadn't
## unlocked yet, not just reset the simulated colony.
func unlocked_keys() -> Array:
	return _unlocked.keys()

## Replaces the unlocked set wholesale, e.g. when a checkpoint restores
## an earlier sub-stage.
func set_unlocked_keys(keys: Array) -> void:
	_unlocked.clear()
	for key in keys:
		unlock(key)
