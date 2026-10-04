extends RefCounted
## Developer edits to what a run starts with (plans/now/brood-spine.md BS-6,
## decision 6 option (a)): one small JSON file on this machine, never a
## fixture, never shipped data.
##
## Usage: const DeveloperOverrides = preload("res://scripts/developer_overrides.gd")
##        var level := DeveloperOverrides.apply(Session.starting_level, Levels.get_level(Session.starting_level))
##
## The file maps a level id (as a string, the way JSON keys are) to
## {"grants": [...], "bans": [...]}: skill ids added to that level's own
## `skill_grants` and `skill_bans`, the two keys RunAvailability.sheet_for
## already honours. Nothing here edits a starting count -- "seeding implies
## owning" derives from counts -- so an override can only grant a skill from
## the start or ban it, and a ban still wins over a grant, as in
## run_availability.gd.
##
## Only main.gd's run start (outside scenario and headless runs) and the
## developer table (run_availability_panel.gd) read this; only the table
## writes it. A missing or unparseable file reads as no overrides.

const PATH := "user://developer_start_overrides.json"

## What a row's edit can be: none (the game's own data), grant from the
## start, or ban.
const EDIT_NONE := ""
const EDIT_GRANT := "grant"
const EDIT_BAN := "ban"


## Every level's overrides, or an empty dictionary.
static func read_all(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	# An instance parse, not JSON.parse_string, so a hand-mangled file reads
	# as no overrides without an engine error at every run start.
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data


## One level's overrides as {"grants": [...], "bans": [...]}, both lists of
## skill id strings, empty when the level has none.
static func for_level(level_id: int, path: String = PATH) -> Dictionary:
	var entry = read_all(path).get(str(level_id), {})
	if typeof(entry) != TYPE_DICTIONARY:
		entry = {}
	return {"grants": _ids(entry.get("grants", [])), "bans": _ids(entry.get("bans", []))}


## A copy of the run definition with this level's override lists merged into
## its skill_grants and skill_bans. A skill banned by either drops out of the
## merged grants, so a ban wins. With no overrides the copy is unchanged.
static func apply(level_id: int, definition: Dictionary, path: String = PATH) -> Dictionary:
	var result := definition.duplicate(true)
	var edits := for_level(level_id, path)
	if edits.grants.is_empty() and edits.bans.is_empty():
		return result
	var bans: Array = _ids(definition.get("skill_bans", []))
	for skill_id in edits.bans:
		if not bans.has(skill_id):
			bans.append(skill_id)
	var grants: Array = []
	for skill_id in _ids(definition.get("skill_grants", [])) + edits.grants:
		if not bans.has(skill_id) and not grants.has(skill_id):
			grants.append(skill_id)
	result["skill_grants"] = grants
	result["skill_bans"] = bans
	return result


## The edit this level's overrides make to one skill: EDIT_BAN, EDIT_GRANT
## or EDIT_NONE.
static func edit_for(level_id: int, skill_id: String, path: String = PATH) -> String:
	var edits := for_level(level_id, path)
	if edits.bans.has(skill_id):
		return EDIT_BAN
	if edits.grants.has(skill_id):
		return EDIT_GRANT
	return EDIT_NONE


## Sets one skill's edit for one level and writes the file. EDIT_NONE removes
## it; a level left with no edits is dropped from the file.
static func set_edit(level_id: int, skill_id: String, edit: String, path: String = PATH) -> void:
	var all := read_all(path)
	var edits := for_level(level_id, path)
	edits.grants.erase(skill_id)
	edits.bans.erase(skill_id)
	if edit == EDIT_GRANT:
		edits.grants.append(skill_id)
	elif edit == EDIT_BAN:
		edits.bans.append(skill_id)
	if edits.grants.is_empty() and edits.bans.is_empty():
		all.erase(str(level_id))
	else:
		all[str(level_id)] = edits
	if all.is_empty():
		reset(path)
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open the developer start overrides for writing: %s" % path)
		return
	file.store_string(JSON.stringify(all, "\t"))
	file.close()


## Deletes the file: every level starts from the game's own data again.
static func reset(path: String = PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Skill id strings out of whatever JSON or a level definition held.
static func _ids(value) -> Array:
	var ids: Array = []
	if typeof(value) != TYPE_ARRAY:
		return ids
	for item in value:
		if typeof(item) == TYPE_STRING and not ids.has(item):
			ids.append(item)
	return ids
