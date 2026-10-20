extends SceneTree
## PP-5 test: with Priority cells owned, a nurse feeds a larva in a cell
## marked "Feed first" before any unmarked one, for every food a larva takes.
##
## Boots the real Main.tscn into level 3, a Scenario level with comb, where
## Priority cells is not owned at the start. Every bee but one test nurse is
## stopped, the comb is emptied, and two built cells each get a hungry larva.
## The nurse carries food for exactly one larva and the comb holds none, so
## whichever larva she feeds first is the only one fed. Each case marks the
## larva today's order (hive.gd::find_brood_cell) would NOT pick, through the
## handler the cell popup's box reaches, then lets the nurse run in the world.
##
## - Unowned: the "Feed first" row is hidden, the handler refuses the mark,
##   and the nurse feeds the larva today's order picks -- even with a mark
##   forced onto the other cell, as an old save could carry.
## - Owned (granted as the scenario action grant_skill does): the row shows,
##   the mark is set, and the nurse feeds the marked larva first, on pollen
##   and nectar, pollen and honey, bee bread and nectar, and royal jelly with
##   pollen and honey for two gyne larvae.
## - A marked gyne larva she can do nothing for (no royal jelly anywhere, and
##   she is on feeding only) does not hold her: she feeds the unmarked worker
##   larva today's order picks.
## - The mark survives SaveGame.save, SaveGame.read and saving.gd::_restore,
##   and a save entry with no priority_cell key restores unmarked.
##
## Run by tests/test_pp5_priority_cells.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/pp5_priority_cells_test.gd -- --pp5-save=<file>
## Prints "PP5 PASS" and exits 0, or prints each failure and exits 1.

const LEVEL := 3              # a Scenario level with comb: no Challenge branches
const BOOT_FRAMES := 10       # let Main._ready build the world first
const SPEED := 8.0
const MAX_WATCH_FRAMES := 1800
const PRIORITY_CELLS := "skill.brood.priority_cells"

const CASES := [
	{"name": "unowned", "owned": false, "load": "pollen_nectar"},
	{"name": "pollen and nectar", "owned": true, "load": "pollen_nectar"},
	{"name": "pollen and honey", "owned": true, "load": "pollen_honey"},
	{"name": "bee bread and nectar", "owned": true, "load": "bee_bread_nectar"},
	{"name": "a marked gyne with no jelly", "owned": true, "load": "pollen_nectar", "unservable_gyne": true},
	{"name": "royal jelly for gynes", "owned": true, "load": "gyne"},
]

var BeeNursery: GDScript
var BeeForaging: GDScript
var _main: Node = null
var _session: Node = null
var _config: Node = null
var _frame := 0
var _phase := "boot"
var _phase_frame := 0
var _case := -1
var _nurse: Node2D = null
var _cells: Array = []
var _expected: Node2D = null
var _other: Node2D = null
var _save_path := ""
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				_set_up()
		"watch":
			_watch()
	if _phase == "done":
		_report()
		return true
	return false


# Autoloads are reached through the tree: a --script run compiles this file
# before they exist.
func _boot() -> void:
	if not root.has_node("Session") or not root.has_node("GameConfig"):
		_fail("the Session or GameConfig autoload is not loaded")
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--pp5-save="):
			_save_path = arg.trim_prefix("--pp5-save=")
	if _save_path == "":
		_fail("no --pp5-save=<file> given")
		return
	_session = root.get_node("Session")
	_config = root.get_node("GameConfig")
	BeeNursery = load("res://scripts/bee_nursery.gd")
	BeeForaging = load("res://scripts/bee_foraging.gd")
	_session.starting_level = LEVEL
	_session.menu_pending = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _set_up() -> void:
	if _session.progression == null:
		_fail("level %d has no progression" % LEVEL)
		return
	if _session.progression.is_owned(PRIORITY_CELLS):
		_fail("Priority cells is owned at the start of level %d" % LEVEL)
		return
	# Only the test nurse moves: the queen lays no eggs and backs nobody up.
	for bee: Node in _main.get_tree().get_nodes_in_group("bees"):
		bee.process_mode = Node.PROCESS_MODE_DISABLED
	_nurse = _main.world_building._spawn_indoor_bee(_main.Bee.Role.NURSERY)
	_nurse.energy_immune = true
	_nurse.nurse_mode = "feed"
	var built: Array = _main.hive.cells.filter(func(c: Variant) -> bool: return is_instance_valid(c) and c.is_built and not c.is_closed)
	built.sort_custom(func(a: Variant, b: Variant) -> bool:
		if a.axial.x != b.axial.x:
			return a.axial.x < b.axial.x
		return a.axial.y < b.axial.y
	)
	if built.size() < 2:
		_fail("level %d has fewer than two built cells" % LEVEL)
		return
	_cells = [built[0], built[1]]
	for cell: Variant in _cells:
		_main.orders_zones._designate_one(cell, "brood")
	Engine.time_scale = SPEED
	_next_case()


func _next_case() -> void:
	_case += 1
	if _case >= CASES.size():
		Engine.time_scale = 1.0
		_check_save_and_restore()
		_phase = "done"
		return
	var spec: Dictionary = CASES[_case]
	if spec.owned and not _session.progression.is_owned(PRIORITY_CELLS):
		_session.progression.grant_temporary(PRIORITY_CELLS)
		_check(_session.progression.is_owned(PRIORITY_CELLS), "granting Priority cells did not own it")
	_check(BeeNursery.priority_cells_owned() == spec.owned,
		"%s: priority_cells_owned() is %s" % [spec.name, BeeNursery.priority_cells_owned()])

	# An empty comb, so the nurse cannot restock, and two hungry larvae.
	for cell: Variant in _main.hive.cells:
		if is_instance_valid(cell) and cell.content_type != "":
			cell.clear_cell()
	var as_gyne: bool = spec.load == "gyne"
	for cell: Variant in _cells:
		cell.priority_cell = false
		cell.start_brood(as_gyne)
	_main.selected_cells.clear()

	# Today's pick, without any mark: the other cell is the one to mark.
	var today: Node2D = _main.hive.find_brood_cell()
	if not _cells.has(today):
		_fail("%s: today's order picked neither test larva" % spec.name)
		return
	var marked: Node2D = _cells[1] if today == _cells[0] else _cells[0]
	if spec.get("unservable_gyne", false):
		# The cell to mark raises a gyne, and nothing she carries or could
		# fetch will feed one. Today's order must still pick the worker.
		marked.start_brood(true)
		today = _main.hive.find_brood_cell()
		if today == marked:
			_fail("%s: today's order picked the gyne larva, so the case shows nothing" % spec.name)
			return
	_main.orders_zones._on_cell_feed_first_requested(marked, true)
	_main.hud._apply_cell_popup_gating()
	_check(_main.hud.feed_first_row.visible == spec.owned,
		"%s: the Feed first row is %s" % [spec.name, "shown" if _main.hud.feed_first_row.visible else "hidden"])
	if spec.get("unservable_gyne", false):
		_check(marked.priority_cell, "%s: the handler did not set the mark" % spec.name)
		_expected = today
		_other = marked
	elif spec.owned:
		_check(marked.priority_cell, "%s: the handler did not set the mark" % spec.name)
		_expected = marked
		_other = today
	else:
		_check(not marked.priority_cell, "unowned: the handler set the mark")
		# A mark from elsewhere (an old save) still changes nothing.
		marked.priority_cell = true
		_expected = today
		_other = marked

	_load_nurse(spec.load)
	_phase = "watch"
	_phase_frame = _frame


func _load_nurse(kind: String) -> void:
	BeeForaging.release_cell_slot(_nurse)
	_nurse.target_cell = null
	_nurse.nurse_fetching = ""
	_nurse.nurse_pollen = 0.0
	_nurse.nurse_bee_bread = 0.0
	_nurse.nurse_jelly = 0.0
	_nurse.nurse_carb = 0.0
	_nurse.nurse_carb_type = ""
	match kind:
		"pollen_nectar":
			_nurse.nurse_pollen = float(_config.brood_feed_pollen)
			_nurse.nurse_carb = float(_config.brood_feed_nectar)
			_nurse.nurse_carb_type = "nectar"
		"pollen_honey":
			_nurse.nurse_pollen = float(_config.brood_feed_pollen)
			_nurse.nurse_carb = float(_config.brood_feed_honey)
			_nurse.nurse_carb_type = "honey"
		"bee_bread_nectar":
			_nurse.nurse_bee_bread = float(_config.brood_feed_bee_bread)
			_nurse.nurse_carb = float(_config.brood_feed_nectar)
			_nurse.nurse_carb_type = "nectar"
		"gyne":
			_nurse.nurse_pollen = float(_config.brood_feed_pollen)
			_nurse.nurse_jelly = float(_config.brood_feed_jelly)
			_nurse.nurse_carb = float(_config.brood_feed_honey)
			_nurse.nurse_carb_type = "honey"
	_nurse.state = _main.Bee.State.NURSE_IDLE


func _watch() -> void:
	var spec: Dictionary = CASES[_case]
	for cell: Variant in _cells:
		cell.unfed_seconds = 0.0   # neither starves while she walks
	var fed: Array = _cells.filter(func(c: Polygon2D) -> bool: return c.brood_fed_seconds > 0.0)
	if fed.is_empty():
		if _frame - _phase_frame >= MAX_WATCH_FRAMES:
			_fail("%s: the nurse fed neither larva in %d frames (state %d)" % [spec.name, MAX_WATCH_FRAMES, _nurse.state])
		return
	_check(fed.has(_expected), "%s: the nurse fed the wrong larva first" % spec.name)
	_check(not fed.has(_other), "%s: the other larva was fed too" % spec.name)
	match spec.load:
		"pollen_honey":
			_check(_expected.fed_on_honey, "%s: the larva was not fed on honey" % spec.name)
		"bee_bread_nectar":
			_check(_expected.brood_food == "bee_bread", "%s: the larva was not fed bee bread" % spec.name)
		"gyne":
			_check(_expected.brood_is_gyne, "%s: the fed larva is not a gyne" % spec.name)
	print("PP5 %s: the nurse fed the %s larva first" % [spec.name, "marked" if fed[0].priority_cell else "unmarked"])
	_next_case()


## The last case left one cell marked and one not.
func _check_save_and_restore() -> void:
	var marked_hex: Vector2i = _expected.axial
	var other_hex: Vector2i = _other.axial
	_check(_expected.priority_cell and not _other.priority_cell, "before saving, the marks are not as the last case left them")
	if not _main.SaveGame.save(_main, _save_path):
		_fail("SaveGame.save failed")
		return
	var data: Dictionary = _main.SaveGame.read(_save_path)
	if data.is_empty():
		_fail("SaveGame.read could not read the save back")
		return
	var entries := {}
	for entry: Variant in data.get("cells", []):
		entries[Vector2i(int(entry.q), int(entry.r))] = entry
	_check(entries.has(marked_hex) and bool(entries[marked_hex].get("priority_cell", false)),
		"the save does not record the marked cell")
	_check(entries.has(other_hex) and not bool(entries[other_hex].get("priority_cell", true)),
		"the save does not record the unmarked cell as unmarked")

	_main.saving._restore(data.duplicate(true))
	_check(_cell_at(marked_hex) != null and _cell_at(marked_hex).priority_cell, "the mark did not survive restore")
	_check(_cell_at(other_hex) != null and not _cell_at(other_hex).priority_cell, "restore marked the unmarked cell")

	# A save from before PP-5 has no key at all: every cell loads unmarked.
	var old: Dictionary = data.duplicate(true)
	for entry: Variant in old.get("cells", []):
		entry.erase("priority_cell")
	_main.saving._restore(old)
	_check(_cell_at(marked_hex) != null and not _cell_at(marked_hex).priority_cell,
		"a save with no priority_cell key restored a mark")
	print("PP5 the mark survives save and restore; an older save restores unmarked")


func _cell_at(hex: Vector2i) -> Node2D:
	for cell: Variant in _main.hive.cells:
		if is_instance_valid(cell) and not cell.is_queued_for_deletion() and cell.axial == hex:
			return cell
	return null


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)


func _fail(line: String) -> void:
	_failures.append(line)
	_phase = "done"


func _report() -> void:
	Engine.time_scale = 1.0
	if _failures.is_empty():
		print("PP5 PASS")
		quit(0)
	else:
		for line: String in _failures:
			print("PP5 FAIL: " + line)
		quit(1)
