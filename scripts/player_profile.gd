extends RefCounted
## Persists across every run, save/load and app restart -- separate from
## save_game.gd's per-colony `user://meadow_save.json`. Two kinds of data
## live here: the player's interface preferences (a durable mirror of
## Session's own "interface preferences" block) and completion tracking
## for Challenges and Scenario presets. See UI_PLAN.md section 12.
##
## `Session` stays the thing every existing call site reads and writes
## (`Session.show_info_badges` and the rest, unchanged across `hud.gd`,
## `ui.gd`, `debug_panel.gd` and everywhere else) -- this file is only
## ever touched at boot (`session.gd`'s `_ready` loads from it) and
## whenever a preference actually changes (`Session.save_preferences()`,
## called from `debug_panel.gd::setting_set` -- the one choke point every
## settings-window change already passes through -- plus the handful of
## preferences a player can change from outside the settings window: the
## pinned-stat stars in `colony_panel.gd`/`nursery_panel.gd`/
## `debug_panel.gd`, the selection-tray field cog in `hud.gd`, and the
## discard-warning "don't show again" checkbox, also in `hud.gd`).
##
## Same defensive shape as `save_game.gd`: a missing or corrupt file
## means "start with Session's own hard-coded defaults", never a blocked
## boot.

const PROFILE_PATH := "user://meadow_profile.json"
const FORMAT_VERSION := 1

## Every Session field this file is the durable home for.
## `control_groups` and `comb_overlay` are deliberately absent -- they
## describe the *current run's* display state, not a durable player
## preference (UI_PLAN.md section 12's "worth a second look" note,
## resolved: they stay Session-only).
const PREFERENCE_KEYS := [
	"pinned_stats", "perf_enabled", "show_info_badges", "colour_blind_mode",
	"warn_on_discard", "gallerin_enabled", "show_flower_amounts",
	"show_cell_contents_text", "show_forager_labels", "show_speed_8x",
	"show_selection_identity", "show_selection_energy",
	"show_selection_activity", "show_selection_trait",
	"ui_theme", "ui_typeface", "text_scale", "reduced_motion",
	"screen_shake", "tooltip_delay", "show_interface_labels",
]

static func has_profile(path: String = PROFILE_PATH) -> bool:
	return FileAccess.file_exists(path)

## Returns the parsed profile, or an empty dictionary if there isn't one
## or it can't be read -- same shape as SaveGame.read(), so a missing or
## corrupt profile falls back to defaults rather than blocking startup.
static func read(path: String = PROFILE_PATH) -> Dictionary:
	if not has_profile(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("The player profile file is not readable; starting with defaults.")
		return {}
	return parsed

## Called once at boot (session.gd's _ready) to set every preference
## field to whatever was last saved. A key absent from the file (a fresh
## profile, or one saved before a new preference existed) leaves
## whichever default Session already declared for it untouched -- same
## "missing key means default" shape save_game.gd's apply_settings() uses.
static func apply_to_session(data: Dictionary) -> void:
	var prefs: Dictionary = data.get("preferences", {})
	for key in PREFERENCE_KEYS:
		if prefs.has(key):
			Session.set(key, prefs[key])

## Whichever Challenge levels (1, 2, ...) have been completed at least
## once.
static func completed_challenges(data: Dictionary) -> Array:
	return data.get("completed_challenges", [])

## "<level>_<preset>" -> true for every Scenario+preset combination that
## has actually been started. Scenarios (the main menu's "starter" group)
## have no win condition, so there is nothing to "complete" in the
## Challenge sense -- this tracks "played" instead, which is what the
## honeycomb's completion ticks actually show for that group. A
## judgement call, not pinned down by UI_PLAN.md itself; see
## NEXTSTEPS.md.
static func played_scenarios(data: Dictionary) -> Dictionary:
	return data.get("played_scenarios", {})

## Re-reads the file, overwrites just the "preferences" block with
## Session's current values, and writes it back -- so completion data
## already on disk is always preserved.
static func save_preferences() -> void:
	var data := read()
	data["version"] = FORMAT_VERSION
	var prefs := {}
	for key in PREFERENCE_KEYS:
		prefs[key] = Session.get(key)
	data["preferences"] = prefs
	_write(data)

static func mark_challenge_complete(level: int) -> void:
	var data := read()
	var completed: Array = data.get("completed_challenges", [])
	if not completed.has(level):
		completed.append(level)
	data["completed_challenges"] = completed
	data["version"] = FORMAT_VERSION
	_write(data)

static func mark_scenario_played(level: int, preset_key: String) -> void:
	var data := read()
	var played: Dictionary = data.get("played_scenarios", {})
	played["%d_%s" % [level, preset_key]] = true
	data["played_scenarios"] = played
	data["version"] = FORMAT_VERSION
	_write(data)

static func _write(data: Dictionary, path: String = PROFILE_PATH) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open the player profile file for writing: %s" % path)
		return
	file.store_string(JSON.stringify(data))
	file.close()
