extends RefCounted
## The one place a *feature* is described -- a whole system that a run
## either has or hasn't, as opposed to a skill the colony buys.
##
## Usage: const Features = preload("res://scripts/features.gd")
##        Features.is_available(Features.PREDATORS)
##
## Scope (progression.md section 3, Phase A step 1): catalogue data only.
## Nothing reads this file yet -- the thin resolver (Phase A step 2) is
## what will answer "is this skill's feature dependency valid in this
## run?" by asking here. Adding the data first keeps that slice to
## wiring rather than wiring plus authoring.
##
## Most features are already a GameConfig toggle, so `config_flag` names
## the var that decides availability today and `is_available()` reads it.
## The exceptions carry `config_flag: ""` and `built: false`: drought has
## no state, no effect and no UI anywhere in the codebase (section 5.5),
## so a skill depending on it can never be valid until a drought feature
## slice lands. That is the point of recording it rather than leaving it
## out -- Weather sensing's drought half has somewhere to point.

const PREDATORS := "feature.predators"
const WEATHER := "feature.weather"
const SEASONS := "feature.seasons"
const FOG_OF_WAR := "feature.fog_of_war"
const DISEASE := "feature.disease"
const DROUGHT := "feature.drought"

const FEATURES := [
	{
		"id": PREDATORS, "label": "Predators",
		"description": "Ambush predators in the meadow, and everything cascaded under them: threat memory, recruitment suppression and alarm marks.",
		"config_flag": "predators_on", "built": true, "requires": [],
	},
	{
		"id": WEATHER, "label": "Weather",
		"description": "Rain: diluted nectar, costlier flight and a limit above which foragers stay home.",
		"config_flag": "weather_on", "built": true, "requires": [],
	},
	{
		"id": SEASONS, "label": "Seasons",
		"description": "A turning year, so a species' flowering window opens and closes rather than running flat.",
		"config_flag": "seasons_on", "built": true, "requires": [],
	},
	{
		"id": FOG_OF_WAR, "label": "Fog of war",
		"description": "The meadow is uncertain until explored, and dims back towards uncertain unless something keeps it remembered.",
		"config_flag": "fog_of_war_on", "built": true, "requires": [],
	},
	{
		"id": DISEASE, "label": "Disease",
		"description": "Crowding and corpses raise a disease load that slows brood development and shortens lives.",
		"config_flag": "disease_on", "built": true, "requires": [],
	},
	{
		# Nothing drought-related exists: no state, no flower effect, no
		# UI (progression.md section 5.5). Listed so the half of Weather
		# sensing that needs it has an ID to depend on, and so validation
		# can say plainly why that half cannot ship yet.
		"id": DROUGHT, "label": "Drought",
		"description": "A dry spell that hurts flowering and forage value. Not built -- needs its own feature slice before any skill can read it.",
		"config_flag": "", "built": false, "requires": [WEATHER],
	},
]

# --- lookups ------------------------------------------------------

static func entry(feature_id: String) -> Dictionary:
	for feature: Dictionary in FEATURES:
		if feature.id == feature_id:
			return feature
	return {}

static func has(feature_id: String) -> bool:
	return not entry(feature_id).is_empty()

static func ids() -> Array:
	return FEATURES.map(func(f: Dictionary) -> Variant: return f.id)

static func label_for(feature_id: String) -> String:
	return entry(feature_id).get("label", feature_id)

static func is_built(feature_id: String) -> bool:
	return entry(feature_id).get("built", false)

## Whether this run actually has the feature. An unbuilt feature is never
## available however the config is set; a built one follows its toggle.
## `config` is GameConfig -- passed in rather than reached for, so this
## file stays a catalogue and the resolver stays the only thing wiring
## progression to the running game.
static func is_available(feature_id: String, config: Object) -> bool:
	var feature := entry(feature_id)
	if feature.is_empty() or not feature.get("built", false):
		return false
	var flag: String = feature.get("config_flag", "")
	if flag == "":
		return true
	return bool(config.get(flag))
