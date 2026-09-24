extends RefCounted
## Ordered save-format migrations. Run once by SaveGame.read() before a
## parsed save is handed to saving.gd.
##
## Four real FORMAT_VERSION bumps have happened so far (see save_game.gd's
## own history comment above FORMAT_VERSION): 1->2 for the hex/entrance
## geometry change, 2->3 for fog of war's explored-cells map, 3->4 for
## explicit-versus-automatic cell designations, 4->5 for the eight
## balance fields D1 moved into the save, and 5->6 for the skills a run
## has bought (AP-4). The first two are
## already handled defensively at restore time -- saving.gd::_restore_cells
## evicts whatever a fresh dig placed on a saved cell's tile (the 1->2
## case), and a missing "fog" key already means "nothing explored yet" via
## fog_of_war.restore([]) (the 2->3 case). This file makes both steps
## explicit and testable at the point a save is read, rather than leaving
## them as implicit defaults only discovered at restore time.
##
## Deliberately does NOT touch the several field additions that never
## bumped FORMAT_VERSION at all (search_anchor_x/y, known_patches,
## species_experience/species_confidence) -- those are safe additive
## fields with their own .get() defaults in saving.gd already, unrelated
## to the version number, so folding them in here would just create a
## second, divergent place recording the same default.

## The eight fields D1's second half (plans/design/architecture-review.md)
## reclassified from persist:"none" to persist:"run". An older save has
## none of these in its "settings" dict at all.
const MIGRATED_SETTINGS_V5 := [
	"seasons_on", "season_length_days", "disease_on", "rival_hive_on",
	"fog_of_war_on", "lay_weight_low", "lay_weight_medium", "lay_weight_high",
]

## Applies every known migration step in order until `data`'s version
## reaches `target_version` (SaveGame.FORMAT_VERSION), or there's no step
## for the current version -- nothing more this build knows how to bridge,
## same spirit as SaveGame.read()'s existing "different version, may not
## work" warning. Idempotent: a save already at `target_version` is
## returned unchanged.
static func upgrade(data: Dictionary, target_version: int) -> Dictionary:
	var version := int(data.get("version", 0))
	var out := data
	while version < target_version:
		match version:
			1:
				out = _migrate_1_to_2(out)
				version = 2
			2:
				out = _migrate_2_to_3(out)
				version = 3
			3:
				out = _migrate_3_to_4(out)
				version = 4
			4:
				out = _migrate_4_to_5(out)
				version = 5
			5:
				out = _migrate_5_to_6(out)
				version = 6
			_:
				return out
		out["version"] = version
	return out

## 1->2: hex/entrance geometry change (14 Aug 2026) only -- no field shape
## changed. The defence already lives in saving.gd::_restore_cells (a
## saved cell always evicts whatever the fresh dig put on its tile), so
## there's nothing to transform here; this step exists to keep the version
## ladder complete and documented, not because it does anything.
static func _migrate_1_to_2(data: Dictionary) -> Dictionary:
	return data

## 2->3: added fog of war's explored-cells map (16 Aug 2026). A save from
## before this version simply has no "fog" key; make that explicit here
## rather than relying only on fog_of_war.restore([]) treating a missing
## key as "nothing explored yet".
static func _migrate_2_to_3(data: Dictionary) -> Dictionary:
	data["fog"] = data.get("fog", [])
	return data

## 3->4: distinguish player-made cell designations from automatic first-use
## assignments. Older saves did not retain that distinction, so preserve every
## existing reservation as explicit rather than unexpectedly releasing it.
static func _migrate_3_to_4(data: Dictionary) -> Dictionary:
	for cell in data.get("cells", []):
		cell["designation_explicit"] = str(cell.get("designated", "")) != ""
	return data

## 4->5: seasons_on, season_length_days, disease_on, rival_hive_on,
## fog_of_war_on and the three lay_weight_* fields moved from
## persist:"none" to persist:"run" (D1 second half,
## plans/design/architecture-review.md), so they now live in "settings".
## An older save's "settings" dict simply lacks these keys; default each to
## GameConfig's own value so a save from before this version keeps behaving
## exactly as it did when these fields were shared, not-saved defaults.
static func _migrate_4_to_5(data: Dictionary) -> Dictionary:
	var settings: Dictionary = data.get("settings", {})
	for key in MIGRATED_SETTINGS_V5:
		if not settings.has(key):
			settings[key] = GameConfig.get(key)
	data["settings"] = settings
	return data

## 5->6: a save records the skills bought this run (AP-4). An older save
## was written before skills could be bought, so it owns none -- make that
## explicit rather than leaving it to a missing-key default at restore.
static func _migrate_5_to_6(data: Dictionary) -> Dictionary:
	var skills = data.get("skills", {})
	if typeof(skills) != TYPE_DICTIONARY:
		skills = {}
	if typeof(skills.get("temporary")) != TYPE_ARRAY:
		skills["temporary"] = []
	data["skills"] = skills
	return data
