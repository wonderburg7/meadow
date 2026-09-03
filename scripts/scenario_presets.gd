extends RefCounted
## Difficulty presets for the main menu's Scenario group (Relaxed/
## Standard/Demanding/Custom) -- UI_PLAN.md section 12. Sits on top of a
## Scenario's starting-state preset (levels.gd's LEVELS): a level decides
## the starting colony, a preset decides the difficulty multipliers
## applied over it.
##
## Not to be confused with AI_PLAYTEST_PLAN.md's --scenario= boot-arg
## file (main.gd::_apply_scenario_boot_arg) -- an unrelated, dev-only
## mechanism that happens to share the word "scenario". This file is only
## ever reached from the main menu's Scenario group.
##
## Every preset restates an explicit value for all four fields, including
## "Standard" (its own GameConfig defaults) -- not just a delta from
## whatever was picked last -- so choosing Standard after Relaxed always
## lands back on the baseline rather than leaving Relaxed's numbers
## sitting in GameConfig. Applied via levels.gd's existing
## apply_config_overrides, the same allowlisted-write mechanism the
## headless playtest harness already uses (every key checked against a
## real GameConfig field before it's written) -- reused rather than
## reinvented, and it keeps the actual `GameConfig.set(...)` call inside
## levels.gd, one of the files `.claude/rules/saving.md` allowlists for
## GameConfig writes.

const Levels = preload("res://scripts/levels.gd")

## GameConfig's own defaults for the four fields every preset touches.
## "Standard" is this dictionary, unchanged -- see the note above on why
## that matters.
const BASELINE := {
	"energy_burn_rate": 0.17,
	"nectar_recharge_rate": 0.5,
	"pollen_recharge_rate": 0.1,
	"winter_burn_factor": 0.15,
}

const PRESETS := [
	{
		"key": "relaxed", "label": "Relaxed",
		"overrides": {
			"energy_burn_rate": 0.13, "nectar_recharge_rate": 0.65,
			"pollen_recharge_rate": 0.13, "winter_burn_factor": 0.11,
		},
		"plain_english": [
			"Bees use less energy.",
			"Flowers recover more quickly.",
			"Winter stores last longer.",
		],
	},
	{
		"key": "standard", "label": "Standard",
		"overrides": BASELINE,
		"plain_english": ["The tuning values as they are, unchanged."],
	},
	{
		"key": "demanding", "label": "Demanding",
		"overrides": {
			"energy_burn_rate": 0.21, "nectar_recharge_rate": 0.38,
			"pollen_recharge_rate": 0.075, "winter_burn_factor": 0.19,
		},
		"plain_english": [
			"Bees use more energy.",
			"Flowers recover more slowly.",
			"Winter stores deplete faster.",
		],
	},
	{
		"key": "custom", "label": "Custom",
		"overrides": BASELINE,
		# Curated subset of the GameConfig allowlist a player can hand-tune --
		# the same four fields the other three presets already touch, so
		# Custom is never a way to reach a field this file hasn't already
		# decided is safe to expose here (UI_PLAN.md section 12).
		"customizable_keys": [
			{"key": "energy_burn_rate", "label": "Bee energy use", "step": 0.01, "min": 0.05, "max": 0.4},
			{"key": "nectar_recharge_rate", "label": "Nectar recovery", "step": 0.05, "min": 0.1, "max": 1.0},
			{"key": "pollen_recharge_rate", "label": "Pollen recovery", "step": 0.01, "min": 0.02, "max": 0.3},
			{"key": "winter_burn_factor", "label": "Winter store use", "step": 0.01, "min": 0.05, "max": 0.3},
		],
		"plain_english": ["Set your own values for the settings below."],
	},
]

static func get_preset(key: String) -> Dictionary:
	for preset in PRESETS:
		if preset.key == key:
			return preset
	return PRESETS[1]  # "standard"

## The keys the last apply() call wrote to GameConfig. Presets are applied
## from exactly this one place, so one static is enough to remember what
## the previous run's preset touched (SP-1, settings-persistence.md).
static var _last_applied_keys: Array[String] = []

## Applies a preset's overrides to GameConfig. `custom_values`, only
## meaningful for "custom", replaces the baseline value for whichever of
## its customizable_keys the player actually changed -- any key not
## present keeps the baseline.
static func apply(key: String, custom_values: Dictionary = {}) -> void:
	var preset := get_preset(key)
	var overrides: Dictionary = preset.overrides.duplicate()
	if key == "custom":
		for k in custom_values:
			overrides[k] = custom_values[k]
	_last_applied_keys.assign(overrides.keys())
	Levels.apply_config_overrides(overrides)

## The GameConfig keys a Scenario pick must reset before applying `key` --
## the previous preset's fingerprints plus everything `key` (and, for
## "custom", `custom_overrides`) is about to set. Leaves every other
## GameConfig field exactly as the player left it (SP-1).
static func keys_to_reset(key: String, custom_overrides: Dictionary = {}) -> Array:
	var keys := {}
	for k in _last_applied_keys:
		keys[k] = true
	for k in get_preset(key).overrides:
		keys[k] = true
	if key == "custom":
		for k in custom_overrides:
			keys[k] = true
	return keys.keys()
