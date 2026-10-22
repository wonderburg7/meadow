extends SceneTree
## CQ-S0 (plans/now/code-health.md): every golden save in
## tests/fixtures/saves/ comes back out of a load exactly as it went in.
##
## Each golden is replayed onto a freshly built world and saved again in the
## same frame, with the tree paused so nothing simulates in between, by up to
## two routes:
##   load      -- the Saves window's reload (saves_panel.gd::reload_from):
##                apply the saved settings, level and skill policy, then build
##                the world with Session.load_pending set, so main.gd::_ready
##                replays the save;
##   in_place  -- saving.gd::_restore, the function the Challenge rollback and
##                restore_slot call, over a freshly built world of the same run
##                that has sat paused for BOOT_FRAMES frames. It does not cover
##                restoring over a world that has been running.
## The re-saved file is compared with the golden as canonical JSON, keys
## sorted. A list whose order is only the order something was walked in is
## compared by key: bees by id, cells and marked soil by q/r, flowers by place
## and species; soil `present`, hive `keep_clear` and `fog` as sets. Every
## other list keeps its order -- bodies among them, which the save promises
## oldest first.
##
## The world each golden belongs to is rebuilt from its capture scenario
## (test_scenarios/cq_s0_<name>_capture.json), the way
## headless/scenario_boot.gd builds it: the save records level 999, which
## means nothing without that scenario's level row.
##
## Older saves (tests/fixtures/save_v1.json, save_v2.json, and a v6 save made
## from the early golden by taking away what version 7 added) are loaded,
## re-saved and recorded: the first re-save is printed as a RECORD line, and
## must itself survive a second load unchanged. The v6 save's re-save must
## also equal the early golden it was made from.
##
## A difference matched by KNOWN_DIFFERENCES is reported as KNOWN, not a
## failure; an entry there that no longer matches anything fails as STALE, so
## the list cannot outlive the fault it names.
##
## Scratch files carry this process's id, so runs side by side (verify.ps1's
## parallel modules, two worktrees) never write or delete each other's.

const GOLDEN_DIR := "res://tests/fixtures/saves/"
const CAPTURE_DIR := "res://test_scenarios/"
const BOOT_FRAMES := 10
const MAX_LINES_PER_CASE := 40
## Godot's JSON writes a float to 15 significant digits, so a value derived
## from a saved one (a bee's stats from her trait percentage) can come back
## a unit out in that last digit. Relative to the value, far below anything
## the simulation could tell apart, and far above that rounding.
const FLOAT_TOLERANCE := 1.0e-12
## roles.gd FORAGER. Not loaded from roles.gd: it is only a number here.
const ROLE_FORAGER := 0

## Which routes each golden takes. A Challenge save cannot be loaded the
## ordinary way (debug_panel.gd::set_save_load_enabled), so Challenge 2's
## checkpoint is restored in place only.
const GOLDENS := [
	{"name": "early", "routes": ["load", "in_place"]},
	{"name": "mid", "routes": ["load", "in_place"]},
	{"name": "winter", "routes": ["load", "in_place"]},
	{"name": "challenge2", "routes": ["in_place"]},
	{"name": "orientation", "routes": ["load", "in_place"]},
]

## "<case>" -> what that route is known to change today, each entry
## {"bees": <which bees, see _eligible_bees>, "gains": [fields]}: only those
## bees, and only fields the re-save has and the golden lacks. Any other bee
## gaining them, or any bee losing or changing them, still fails. Each is
## escalated to Dave rather than fixed here: making a route idempotent
## changes what a loaded run does.
##
## Orientation flight (CQ-S0, 22 Oct 2026): a bee switched into Forager after
## she was made has no start point until her first trip (bee.gd::setup takes
## an orientation flight only for a bee created as a Forager). Saved before
## that trip, she has none; but the replay builds her through setup() as a
## Forager, so with orientation flight on she takes a flight to a new random
## point, and the re-save gains start_x/start_y and the search anchor that
## follows them. Both routes, since both go through _restore_bees.
## Kept as a known difference (Dave, 22 Oct 2026). The intended fix, for a
## later slice: saving.gd tells setup() not to start an orientation flight for
## a restored bee, so she keeps no start point until her first trip, as saved.
## Once it lands this entry fails as STALE, and the fix slice removes it.
const ORIENTATION_GAINS_START := {
	"bees": "forager_without_start_point",
	"gains": ["search_anchor_x", "search_anchor_y", "start_x", "start_y"],
}
const KNOWN_DIFFERENCES := {
	"orientation:load": [ORIENTATION_GAINS_START],
	"orientation:in_place": [ORIENTATION_GAINS_START],
}

## Lists compared as sets: their order is whatever order a dictionary or the
## fog grid happened to be walked in, and a member has nothing but itself.
const SET_PATHS := [["soil", "present"], ["hive", "keep_clear"], ["fog"]]
## Lists compared member by member under a key made of these fields, for the
## same reason: bees come from a node group, marked soil from a dictionary.
const KEYED_PATHS := [
	{"path": ["bees"], "key": ["id"]},
	{"path": ["cells"], "key": ["q", "r"]},
	{"path": ["soil", "marked"], "key": ["q", "r"]},
	{"path": ["flowers"], "key": ["x", "y", "species"]},
]

## Loaded on the first frame: each names the GameConfig or Session autoload,
## which a --script SceneTree cannot compile against before they exist.
var SaveGame: GDScript
var Levels: GDScript
var SaveMigrations: GDScript
var _main: Node
var _jobs: Array = []
var _job: Dictionary = {}
var _phase := "boot"
var _frame := 0
var _config_snapshot: Dictionary = {}
var _old_level := 0
var _failures: PackedStringArray = PackedStringArray()
var _scratch_prefix := ""
var _out_path := ""
var _scratch_files: Array = []
var _compared := 0

## Autoloads are read on the first frame, as si1_run_state_test.gd does.
func _build_jobs() -> void:
	SaveGame = load("res://scripts/save_game.gd")
	Levels = load("res://scripts/levels.gd")
	SaveMigrations = load("res://scripts/save_migrations.gd")
	_scratch_prefix = "user://cq_s0_%d_" % OS.get_process_id()
	_out_path = _scratch_prefix + "resaved.json"
	_scratch_files.append(_out_path)
	for key: String in SaveGame.saved_settings():
		_config_snapshot[key] = root.get_node("GameConfig").get(key)
	_old_level = root.get_node("Session").starting_level
	for golden: Dictionary in GOLDENS:
		var path: String = GOLDEN_DIR + "cq_s0_%s.json" % golden.name
		for route: String in golden.routes:
			_jobs.append({
				"case": "%s:%s" % [golden.name, route], "source": path,
				"route": route, "capture": golden.name, "compare_to": path,
			})
	_jobs.append(_old_job("v1", "res://tests/fixtures/save_v1.json", ""))
	_jobs.append(_old_job("v2", "res://tests/fixtures/save_v2.json", ""))
	_jobs.append(_old_job("v6", _write_v6(), GOLDEN_DIR + "cq_s0_early.json"))

## An older save: loaded and re-saved, then the re-save loaded once more.
func _old_job(label: String, path: String, compare_to: String) -> Dictionary:
	return {
		"case": "%s:load" % label, "source": path, "route": "load",
		"capture": "early", "compare_to": compare_to, "old": label,
	}

## The early golden as version 6 wrote it: the same run without the four
## settings version 7 added (save_migrations.gd::MIGRATED_SETTINGS_V7).
func _write_v6() -> String:
	var data: Dictionary = _parse(GOLDEN_DIR + "cq_s0_early.json")
	data["version"] = 6
	for key: String in SaveMigrations.MIGRATED_SETTINGS_V7:
		data["settings"].erase(key)
	var path := _scratch_prefix + "v6.json"
	_write(path, JSON.stringify(data))
	return path

func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_build_jobs()
			_phase = "next"
		"next":
			if _jobs.is_empty():
				_finish()
				return true
			_job = _jobs.pop_front()
			_start(_job)
		"settle":
			if _frame >= BOOT_FRAMES:
				var data: Dictionary = SaveGame.read(_job.source)
				_main.saving._restore(data)
				_resave_and_compare()
	return false

# --- one case -------------------------------------------------------

func _start(job: Dictionary) -> void:
	var session: Node = root.get_node("Session")
	var config: Node = root.get_node("GameConfig")
	for key: String in _config_snapshot:
		config.set(key, _config_snapshot[key])
	var capture: Dictionary = _capture_level(job.capture)
	Levels.scenario_override = capture.level
	session.starting_level = 2 if capture.challenge == 2 else Levels.SCENARIO_LEVEL_ID
	var data: Dictionary = SaveGame.read(job.source)
	if data.is_empty():
		_failures.append("%s: %s could not be read" % [job.case, job.source])
		_phase = "next"
		return
	# saves_panel.gd::reload_from's order, for both routes: the world is
	# built to the saved settings, level and skill policy.
	SaveGame.apply_settings(data)
	SaveGame.apply_starting_level(data)
	SaveGame.apply_skill_policy(data)
	session.menu_pending = false
	if job.route == "load":
		session.load_path = job.source
		session.load_pending = true
	_create_world()
	if job.route == "load":
		_resave_and_compare()
	else:
		_phase = "settle"

## The re-save, taken in the same frame as the replay.
func _resave_and_compare() -> void:
	var saved: bool = SaveGame.save(_main, _out_path)
	_free_world()
	_phase = "next"
	if not saved:
		_failures.append("%s: the re-save failed" % _job.case)
		return
	var resaved: Dictionary = _parse(_out_path)
	if _job.has("old"):
		_record_old(resaved)
	if _job.compare_to != "":
		_compare(_job.case, _parse(_job.compare_to), resaved)

## An older save's first re-save is printed, then queued to go round once
## more against itself.
func _record_old(resaved: Dictionary) -> void:
	var source: Dictionary = _parse(_job.source)
	var added: Array = []
	for key: String in resaved.keys():
		if not source.has(key):
			added.append(key)
	added.sort()
	print("CQS0 RECORD %s: version %d loaded and re-saved as version %d, %d bees, %d cells; keys the load added: %s" % [
		_job.old, int(source.get("version", 0)), int(resaved.get("version", 0)),
		resaved.get("bees", []).size(), resaved.get("cells", []).size(), ", ".join(added)])
	var first := _scratch_prefix + "%s_resaved.json" % _job.old
	_write(first, JSON.stringify(resaved))
	_jobs.push_front({
		"case": "%s:resaved" % _job.old, "source": first, "route": "load",
		"capture": "early", "compare_to": first,
	})

func _create_world() -> void:
	paused = true
	_main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(_main)
	current_scene = _main
	_frame = 0

func _free_world() -> void:
	if is_instance_valid(_main):
		_main.queue_free()
	_main = null
	current_scene = null

## The level row headless/scenario_boot.gd would make of the capture.
func _capture_level(capture_name: String) -> Dictionary:
	var parsed: Dictionary = _parse(CAPTURE_DIR + "cq_s0_%s_capture.json" % capture_name)
	var challenge := int(parsed.get("challenge", 0))
	for key: String in ["performance_capture", "diagnostics", "stop", "config_overrides",
			"challenge", "actions", "time_scale", "snapshot_seconds", "pollination_log", "random_seed"]:
		parsed.erase(key)
	for key: String in ["cells", "nectar_foragers", "pollen_foragers"]:
		parsed[key] = parsed.get(key, 0)
	return {"level": parsed, "challenge": challenge}

# --- comparing ------------------------------------------------------

func _compare(case_name: String, golden: Dictionary, resaved: Dictionary) -> void:
	_compared += 1
	var diffs: Array = []
	_diff(_canonical(golden), _canonical(resaved), "", diffs)
	var known: Array = KNOWN_DIFFERENCES.get(case_name, [])
	var matched: Dictionary = {}
	var unexpected: Array = []
	for entry: Dictionary in diffs:
		var index := _known_index(known, golden, entry)
		if index >= 0:
			matched[index] = true
			print("CQS0 KNOWN %s: %s" % [case_name, entry.text])
		else:
			unexpected.append(entry.text)
	for i: int in known.size():
		if not matched.has(i):
			_failures.append("%s: STALE known difference %s no longer happens" % [case_name, JSON.stringify(known[i])])
	if unexpected.is_empty():
		print("CQS0 OK %s" % case_name)
		return
	_failures.append("%s: %d difference(s)" % [case_name, unexpected.size()])
	for i: int in mini(unexpected.size(), MAX_LINES_PER_CASE):
		print("CQS0 DIFF %s: %s" % [case_name, unexpected[i]])

## Which entry of `known` a difference is, or -1: a field the re-save gained
## on one of the bees the entry names, as she is in the golden.
func _known_index(known: Array, golden: Dictionary, entry: Dictionary) -> int:
	if entry.kind != "added":
		return -1
	for i: int in known.size():
		for bee_key: String in _eligible_bees(golden, known[i].bees):
			for field: String in known[i].gains:
				if entry.path == "bees.%s.%s" % [bee_key, field]:
					return i
	return -1

## The keys (as KEYED_PATHS makes them) of the golden's bees a known
## difference may touch.
func _eligible_bees(golden: Dictionary, which: String) -> Array:
	var keys: Array = []
	for bee: Variant in golden.get("bees", []):
		if not (bee is Dictionary):
			continue
		match which:
			"forager_without_start_point":
				if int(bee.get("role", -1)) == ROLE_FORAGER and not bool(bee.get("queen", false)) \
						and not bee.has("start_x"):
					keys.append(_key_part(bee.get("id")))
	return keys

func _canonical(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	for keys: Array in SET_PATHS:
		var holder: Variant = _holder(out, keys)
		if holder is Dictionary and holder.get(keys[-1]) is Array:
			var members := {}
			for item: Variant in holder[keys[-1]]:
				members[JSON.stringify(item)] = true
			holder[keys[-1]] = members
	for rule: Dictionary in KEYED_PATHS:
		var keys: Array = rule.path
		var holder: Variant = _holder(out, keys)
		if holder is Dictionary and holder.get(keys[-1]) is Array:
			holder[keys[-1]] = _keyed(holder[keys[-1]], rule.key)
	return out

## The dictionary that holds the last key of `keys`, or null.
func _holder(data: Dictionary, keys: Array) -> Variant:
	var holder: Variant = data
	for i: int in keys.size() - 1:
		holder = holder.get(keys[i], {}) if holder is Dictionary else null
	return holder

## A list as a dictionary under each member's key fields. A key two members
## share gets " #2", " #3"... in list order, so neither is lost.
func _keyed(items: Array, fields: Array) -> Dictionary:
	var out := {}
	for item: Variant in items:
		var parts: PackedStringArray = PackedStringArray()
		for field: String in fields:
			parts.append(_key_part(item.get(field) if item is Dictionary else null))
		var key := ",".join(parts)
		var unique := key
		var n := 2
		while out.has(unique):
			unique = "%s #%d" % [key, n]
			n += 1
		out[unique] = item
	return out

## JSON numbers are floats; a whole one is written as an integer so a bee's
## key reads "5", not "5.0".
func _key_part(value: Variant) -> String:
	if value is float and value == roundf(value) and absf(value) < 1.0e15:
		return str(int(value))
	return str(value)

## Every place `a` (the golden) and `b` (the re-save) disagree, as
## {"text": readable line, "path": where, "kind": added|removed|changed|size}.
func _diff(a: Variant, b: Variant, path: String, out: Array) -> void:
	if a is Dictionary and b is Dictionary:
		var keys: Array = a.keys()
		for key: Variant in b.keys():
			if not keys.has(key):
				keys.append(key)
		keys.sort()
		for key: Variant in keys:
			var child := "%s.%s" % [path, key] if path != "" else str(key)
			if not a.has(key):
				_note(out, child, "added", "only in the re-save: %s" % _short(b[key]))
			elif not b.has(key):
				_note(out, child, "removed", "only in the golden: %s" % _short(a[key]))
			else:
				_diff(a[key], b[key], child, out)
		return
	if a is Array and b is Array:
		if a.size() != b.size():
			_note(out, path + ".size()", "size", "golden %d, re-save %d" % [a.size(), b.size()])
		for i: int in mini(a.size(), b.size()):
			_diff(a[i], b[i], "%s[%d]" % [path, i], out)
		return
	if typeof(a) == TYPE_FLOAT and typeof(b) == TYPE_FLOAT:
		if absf(a - b) > FLOAT_TOLERANCE * maxf(1.0, maxf(absf(a), absf(b))):
			_note(out, path, "changed", "golden %s, re-save %s" % [_short(a), _short(b)])
		return
	if typeof(a) != typeof(b) or a != b:
		_note(out, path, "changed", "golden %s, re-save %s" % [_short(a), _short(b)])

func _note(out: Array, path: String, kind: String, what: String) -> void:
	out.append({"text": "%s -- %s" % [path, what], "path": path, "kind": kind})

func _short(value: Variant) -> String:
	var text := JSON.stringify(value)
	return text if text.length() <= 120 else text.substr(0, 117) + "..."

# --- files and the end ----------------------------------------------

func _parse(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write %s" % path)
		return
	file.store_string(text)
	file.close()
	if not _scratch_files.has(path):
		_scratch_files.append(path)

## Deletes only this run's scratch files (each named with its process id).
func _finish() -> void:
	var config: Node = root.get_node("GameConfig")
	for key: String in _config_snapshot:
		config.set(key, _config_snapshot[key])
	Levels.scenario_override = {}
	root.get_node("Session").starting_level = _old_level
	paused = false
	for path: String in _scratch_files:
		for each: String in [path, path + ".tmp"]:
			if FileAccess.file_exists(each):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(each))
	if _compared == 0:
		_failures.append("no save was compared")
	if _failures.is_empty():
		print("CQS0 PASS")
		quit(0)
	else:
		for failure: String in _failures:
			print("CQS0 FAIL: " + failure)
		quit(1)
