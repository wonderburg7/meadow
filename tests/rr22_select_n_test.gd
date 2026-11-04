extends SceneTree
## RR-22 test: n is clamped to 1..the selection size, the step buttons move
## it by 1 and 5, Select keeps the n bees nearest the centre, and youngest /
## oldest keep the one bee with the least or greatest age.

const LEVEL := 12
const BOOT_FRAMES := 10

var _main: Node = null
var _frame := 0
var _done := false
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	if _done:
		return false
	if _frame == 1:
		var session: Node = root.get_node("Session")
		session.starting_level = LEVEL
		session.menu_pending = false
		var scene: PackedScene = load("res://scenes/Main.tscn")
		_main = scene.instantiate()
		root.add_child(_main)
		current_scene = _main
	elif _frame >= BOOT_FRAMES:
		_run()
		_done = true
		_report()
	return false


func _crowd(count: int) -> Array:
	var bees: Array = get_nodes_in_group("bees").filter(func(b: Variant) -> bool: return not b.is_queen)
	return bees.slice(0, count)


func _select(bees: Array) -> void:
	for b: Variant in _main.selected_bees:
		if is_instance_valid(b):
			b.set_selected(false)
	_main.selected_bees = bees.duplicate()
	for b: Variant in bees:
		b.set_selected(true)
	_main.hud.update_selection(_main.selected_bees)


func _run() -> void:
	var hud: Variant = _main.hud
	var bees: Array = _crowd(12)
	_check(bees.size() >= 4, "fewer than 4 bees to select (%d)" % bees.size())
	if bees.size() < 4:
		return
	# A single selection shows no row.
	_select(bees.slice(0, 1))
	_check(not hud.select_n_row.visible, "the row shows for one bee")
	# Distinct ages and positions: bee i is i seconds old and sits i*10 along x.
	var total: int = bees.size()
	for i: int in total:
		bees[i].age_seconds = 100.0 + float((i * 7) % total) * 3.0
		bees[i].global_position = Vector2(float(i) * 10.0, 0.0)
	_select(bees)
	_check(hud.select_n_row.visible, "the row is hidden for a crowd")
	_check(hud.select_n == 1, "n did not start at 1 (%d)" % hud.select_n)
	hud.step_select_n(-1)
	hud.step_select_n(-5)
	_check(hud.select_n == 1, "n went below 1 (%d)" % hud.select_n)
	hud.step_select_n(5)
	_check(hud.select_n == mini(6, total), ">> did not step by 5, clamped (%d)" % hud.select_n)
	hud.step_select_n(-5)
	_check(hud.select_n == 1, "<< did not step back to 1 (%d)" % hud.select_n)
	hud.step_select_n(1)
	_check(hud.select_n == 2, "> did not step by 1 (%d)" % hud.select_n)
	hud.step_select_n(1)
	hud.step_select_n(-1)
	_check(hud.select_n == 2, "< did not step by 1 (%d)" % hud.select_n)
	hud.step_select_n(5)
	hud.step_select_n(5)
	_check(hud.select_n == total, "n passed the selection size (%d of %d)" % [hud.select_n, total])
	# Select 2 keeps the 2 nearest the centre, deselects the rest.
	hud.step_select_n(-total)
	hud.step_select_n(1)
	_check(hud.select_n == 2, "n was %d, wanted 2" % hud.select_n)
	var centre := Vector2.ZERO
	for b: Variant in bees:
		centre += b.global_position
	centre /= total
	hud.select_n_confirmed()
	_check(_main.selected_bees.size() == 2, "Select kept %d bees, wanted 2" % _main.selected_bees.size())
	var kept_far: float = 0.0
	for b: Variant in _main.selected_bees:
		kept_far = maxf(kept_far, b.global_position.distance_to(centre))
	for b: Variant in bees:
		if not _main.selected_bees.has(b):
			_check(b.global_position.distance_to(centre) >= kept_far - 0.001, "a nearer bee was dropped")
	_check(hud.select_n <= 2, "n is not clamped after narrowing (%d)" % hud.select_n)
	# Youngest and oldest.
	var youngest: Variant = bees[0]
	var oldest: Variant = bees[0]
	for b: Variant in bees:
		if b.age_seconds < youngest.age_seconds:
			youngest = b
		if b.age_seconds > oldest.age_seconds:
			oldest = b
	_select(bees)
	hud.select_youngest()
	_check(_main.selected_bees.size() == 1 and _main.selected_bees[0] == youngest, "youngest was not kept alone")
	_check(not hud.select_n_row.visible, "the row stays after narrowing to one")
	_select(bees)
	hud.select_oldest()
	_check(_main.selected_bees.size() == 1 and _main.selected_bees[0] == oldest, "oldest was not kept alone")


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)


func _report() -> void:
	if _failures.is_empty():
		print("RR22 PASS")
		quit(0)
		return
	for line: String in _failures:
		print("RR22 FAIL: ", line)
	quit(1)
