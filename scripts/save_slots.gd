extends RefCounted
## Which save files exist, what they are called and which checkpoint comes
## next (plans/now/named-saves.md, SV-1). Pure path-and-index work: it never
## opens a save's contents and holds no reference to main, so it can be
## exercised without a world. save_game.gd still writes one run to one path;
## this file only decides which path.
##
## Layout, all under `root`:
##   <slug>.json                the player's own named save
##   <slug>.checkpoint<N>.json  one of three rotating checkpoints, N = 1..3
##   index.json                 per slug: display name, last-saved day and
##                              time, and the next checkpoint number
## A slug holds only a-z, 0-9 and hyphens, so no slug can spell
## "<other>.checkpoint1" -- a checkpoint can never land on a named save.
##
## A missing, empty or corrupt index reads as "no saves", never as an error
## that stops the game -- the same defensive shape as SaveGame.read().
## tutorial_checkpoint.gd's file lives outside `root` and is never listed.
##
## Usage: const SaveSlots = preload("res://scripts/save_slots.gd")

const ROOT := "user://saves/"
## Headless --scenario= runs write here instead (main.gd), so a test run
## never rotates the player's checkpoints or adds a slot to their list.
const SCRATCH_ROOT := "user://scenario_saves/"
const INDEX_FILE := "index.json"
const CHECKPOINTS := 3
## save_game.gd's SAVE_PATH, the only save there was before SV-1. Adopted
## (copied, never moved or read) as the slot below the first time the
## catalogue is touched, so an existing colony is not lost to the move.
const LEGACY_PATH := "user://meadow_save.json"
const LEGACY_NAME := "My colony"
const DEFAULT_SLUG := "colony"

static var root: String = ROOT
## The root that has been created and had the legacy save adopted into it
## this session, so that work is done once rather than on every call.
static var _prepared_root: String = ""

# --- paths ---------------------------------------------------------

## The player's run name reduced to lowercase letters, digits and hyphens.
static func slugify(display_name: String) -> String:
	var slug := ""
	for ch: String in display_name.strip_edges().to_lower():
		var code: int = ch.unicode_at(0)
		var keep: bool = (code >= 97 and code <= 122) or (code >= 48 and code <= 57)
		if keep:
			slug += ch
		elif not slug.ends_with("-"):
			slug += "-"
	slug = slug.trim_prefix("-").trim_suffix("-")
	return slug if slug != "" else DEFAULT_SLUG

static func slot_path(slug: String) -> String:
	_prepare()
	return root + slug + ".json"

static func checkpoint_path(slug: String, number: int) -> String:
	_prepare()
	return root + "%s.checkpoint%d.json" % [slug, number]

## The path the next checkpoint for `slug` should be written to. The
## rotation runs 1 -> 2 -> 3 -> 1, so the one overwritten is always the
## oldest; it lives in the index rather than a scan of the directory, and
## only record_checkpoint() moves it on, so a failed write leaves it put.
static func checkpoint(slug: String) -> String:
	var entry: Dictionary = _read_index()["slots"].get(slug, {})
	return checkpoint_path(slug, _next_checkpoint(entry))

## The most recently saved run that has a named save on disk, as a
## list_slots() entry, or {} if there is none -- what the Load button reads
## until the Saves window (SV-2) lets the player choose.
static func latest_named() -> Dictionary:
	for entry: Dictionary in list_slots():
		if int(entry.get("saved_at", 0)) > 0 and FileAccess.file_exists(slot_path(entry["slug"])):
			return entry
	return {}

# --- the index -----------------------------------------------------

## Every slot, newest first by whichever of its named save or checkpoints
## was written last. Each entry is the index record plus "slug" and
## "last_saved". Reads the index file only; call it when something is about
## to display the list, not per frame.
static func list_slots() -> Array:
	var slots: Dictionary = _read_index()["slots"]
	var result: Array = []
	for slug: String in slots:
		var entry: Dictionary = slots[slug].duplicate(true)
		entry["slug"] = slug
		var last := int(entry.get("saved_at", 0))
		for number: String in entry.get("checkpoints", {}):
			last = maxi(last, int(entry["checkpoints"][number].get("saved_at", 0)))
		entry["last_saved"] = last
		result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["last_saved"]) > int(b["last_saved"]))
	return result

## Names this launch has already handed out (RR-6). A run that never saves
## writes no slot, so without this the next run would be offered the same
## name. Static, so it lasts until the game is relaunched; nothing is written.
static var _issued_run_slugs: Dictionary = {}

## A default run name that no listed slot and no name issued this launch
## uses yet: `base`, else `base 2`, `base 3`... for the lowest number whose
## slug is free (RR-3, RR-6). Reads the index file only; call it when a new
## run starts, not per frame.
static func fresh_run_name(base: String) -> String:
	var taken := _issued_run_slugs.duplicate()
	for slot: Dictionary in list_slots():
		taken[slot["slug"]] = true
	var run_name := base
	var n := 2
	while taken.has(slugify(run_name)):
		run_name = "%s %d" % [base, n]
		n += 1
	_issued_run_slugs[slugify(run_name)] = true
	return run_name

## Called after the player's own save has been written.
static func record_save(slug: String, display_name: String, day: int) -> void:
	var index := _read_index()
	var entry := _entry(index, slug, display_name)
	entry["day"] = day
	entry["saved_at"] = int(Time.get_unix_time_from_system())
	_write_index(index)

## Called after a checkpoint has been written to checkpoint(slug); moves
## the rotation on to the next number.
static func record_checkpoint(slug: String, display_name: String, day: int) -> void:
	var index := _read_index()
	var entry := _entry(index, slug, display_name)
	var number := _next_checkpoint(entry)
	entry["checkpoints"][str(number)] = {"day": day, "saved_at": int(Time.get_unix_time_from_system())}
	entry["next_checkpoint"] = number % CHECKPOINTS + 1
	_write_index(index)

## Removes a run's named save, its checkpoints and its index entry.
static func delete(slug: String) -> void:
	var paths := [slot_path(slug)]
	for number: int in range(1, CHECKPOINTS + 1):
		paths.append(checkpoint_path(slug, number))
	for path: String in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	var index := _read_index()
	index["slots"].erase(slug)
	_write_index(index)

## Headless scenario runs: points the catalogue at SCRATCH_ROOT and empties
## it, so each run starts from no saves and never touches the player's.
## tools/run_scenario.py launches every run with a user:// of its own
## (private_user_env), so this never empties a run going on alongside.
static func use_scratch_root() -> void:
	root = SCRATCH_ROOT
	_prepared_root = ""
	if DirAccess.dir_exists_absolute(SCRATCH_ROOT):
		for file_name: String in DirAccess.get_files_at(SCRATCH_ROOT):
			DirAccess.remove_absolute(SCRATCH_ROOT + file_name)

# --- internals -----------------------------------------------------

static func _next_checkpoint(entry: Dictionary) -> int:
	return clampi(int(entry.get("next_checkpoint", 1)), 1, CHECKPOINTS)

static func _entry(index: Dictionary, slug: String, display_name: String) -> Dictionary:
	var slots: Dictionary = index["slots"]
	if not slots.has(slug):
		slots[slug] = {"name": display_name, "day": -1, "saved_at": 0, "next_checkpoint": 1, "checkpoints": {}}
	var entry: Dictionary = slots[slug]
	entry["name"] = display_name
	if typeof(entry.get("checkpoints")) != TYPE_DICTIONARY:
		entry["checkpoints"] = {}
	return entry

static func _empty_index() -> Dictionary:
	return {"version": 1, "legacy_adopted": false, "slots": {}}

static func _read_index() -> Dictionary:
	_prepare()
	return _load_index_file()

static func _load_index_file() -> Dictionary:
	var path := root + INDEX_FILE
	if not FileAccess.file_exists(path):
		# SI-3: a crash between the replace's remove and rename leaves only .tmp.
		if not FileAccess.file_exists(path + ".tmp"):
			return _empty_index()
		path = path + ".tmp"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _empty_index()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("slots")) != TYPE_DICTIONARY:
		push_warning("The save index is unreadable; treating it as no saves.")
		return _empty_index()
	return parsed

static func _write_index(index: Dictionary) -> void:
	write_atomic(root + INDEX_FILE, JSON.stringify(index, "\t"))

## SI-3: writes `text` to `path + ".tmp"` and renames it over `path`, so a
## crash or full disk never leaves a half file. Returns false if the open,
## the store or the rename fails (a failed store removes the .tmp; a failed
## rename keeps it).
static func write_atomic(path: String, text: String) -> bool:
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("Could not open the file for writing: %s" % tmp)
		return false
	var stored := file.store_string(text)
	file.close()
	if not stored:
		push_error("Could not write the file: %s" % tmp)
		DirAccess.remove_absolute(tmp)
		return false
	if DirAccess.rename_absolute(tmp, path) != OK:
		# Keep the .tmp: the rename may have removed the target first, and
		# read() falls back to the .tmp.
		push_error("Could not replace the file: %s" % path)
		return false
	return true

## Creates `root` and, for the player's own catalogue, adopts the legacy
## save once. Copies the file byte for byte without opening it, and never
## over a slot that already exists (a corrupt index re-runs this).
static func _prepare() -> void:
	if _prepared_root == root:
		return
	_prepared_root = root
	DirAccess.make_dir_recursive_absolute(root)
	if root != ROOT:
		return
	var index := _load_index_file()
	if bool(index.get("legacy_adopted", false)):
		return
	if FileAccess.file_exists(LEGACY_PATH):
		var slug := slugify(LEGACY_NAME)
		var dest := root + slug + ".json"
		if not FileAccess.file_exists(dest):
			DirAccess.copy_absolute(LEGACY_PATH, dest)
		if not index["slots"].has(slug):
			var entry := _entry(index, slug, LEGACY_NAME)
			entry["saved_at"] = int(FileAccess.get_modified_time(LEGACY_PATH))
	index["legacy_adopted"] = true
	_write_index(index)
