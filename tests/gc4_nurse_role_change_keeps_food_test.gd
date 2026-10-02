extends SceneTree
## GC-4 unit test: a nurse moved to another job puts the brood food she
## carries back into the comb (bee.gd::_return_nurse_food, via _apply_role).
##
## Builds a real hive.gd and real hive_cell.gd cells with room, and a real
## bee.gd nurse carrying known amounts, outside any world. Changes her job
## to Idle straight away (set_role) and, separately, to Forager through a
## queued change (_apply_pending_role, the "finish the job first" path), and
## checks the hive's stored totals rise by exactly what she carried and her
## loads are zero. The queen keeps her old behaviour: she simply stops
## carrying it, and the comb is unchanged.
##
## Run by tests/test_gc4_nurse_role_change_keeps_food.py:
##   godot --headless --path <repo> --script res://tests/gc4_nurse_role_change_keeps_food_test.gd
## Prints "GC4 PASS" and exits 0, or prints each failure and exits 1.

# Loaded in _process, not preloaded: a --script run compiles this file
# before the autoloads these scripts name (GameConfig, Perf) exist.
var Bee: GDScript
var Hive: GDScript
var HiveCell: GDScript

const RESOURCES := ["pollen", "nectar", "honey", "jelly"]

var _failures: PackedStringArray = PackedStringArray()
var _ran := false
var _completed := 0
const TEST_COUNT := 3


func _process(_delta: float) -> bool:
	# Autoloads (GameConfig, Session, DiagnosticLog) are in the tree by the
	# first frame, not during _initialize.
	if _ran:
		return true
	_ran = true
	if not root.has_node("GameConfig"):
		_failures.append("GameConfig autoload is not loaded")
	else:
		Bee = load("res://scripts/bee.gd")
		Hive = load("res://scripts/hive.gd")
		HiveCell = load("res://scripts/hive_cell.gd")
		_test_idle_now()
		_test_forager_queued()
		_test_queen_unchanged()
		# A script error aborts a test function without failing it, so a
		# test that did not reach its end counts as a failure.
		if _completed != TEST_COUNT:
			_failures.append("only %d of %d tests ran to the end" % [_completed, TEST_COUNT])
	if _failures.is_empty():
		print("GC4 PASS")
		quit(0)
	else:
		for line in _failures:
			print("GC4 FAIL: " + line)
		quit(1)
	return true


func _make_hive(cell_count: int) -> Node2D:
	var hive: Node2D = Hive.new()
	root.add_child(hive)
	for i in cell_count:
		var cell: Node2D = HiveCell.new()
		cell.is_built = true
		hive.cells.append(cell)
	return hive


func _make_nurse(hive: Node2D, queen: bool = false) -> Node2D:
	var bee: Node2D = Bee.new()
	bee.is_queen = queen
	bee.hive = hive
	bee.role = Bee.Role.EGG_LAYER if queen else Bee.Role.NURSERY
	# _ready builds the label and markers _apply_role refreshes; nothing
	# else should run, since there is no world around her.
	bee.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(bee)
	return bee


func _totals(hive: Node2D) -> Dictionary:
	# Cells built outside main.gd have no `main` to tell the hive its stock
	# cache is stale, so force the recount.
	hive.invalidate_stock()
	var out := {}
	for key in RESOURCES:
		out[key] = hive.total(key)
	return out


func _expect_totals(label: String, before: Dictionary, after: Dictionary, added: Dictionary) -> void:
	for key in RESOURCES:
		var want: float = before[key] + float(added.get(key, 0.0))
		if absf(after[key] - want) > 0.001:
			_failures.append("%s: hive %s %.3f, expected %.3f" % [label, key, after[key], want])


func _expect_empty_handed(label: String, bee: Node2D) -> void:
	if bee.nurse_pollen != 0.0 or bee.nurse_carb != 0.0 or bee.nurse_jelly != 0.0 or bee.nurse_carb_type != "":
		_failures.append("%s: still carrying pollen %.3f, %s %.3f, jelly %.3f" % [
			label, bee.nurse_pollen, bee.nurse_carb_type, bee.nurse_carb, bee.nurse_jelly])


func _cleanup(nodes: Array) -> void:
	for node in nodes:
		if node is Node2D and node.has_method("add_resource"):
			node.free()
		elif is_instance_valid(node):
			node.queue_free()


func _test_idle_now() -> void:
	var hive := _make_hive(6)
	var bee := _make_nurse(hive)
	bee.nurse_pollen = 6.0
	bee.nurse_carb = 12.0
	bee.nurse_carb_type = "nectar"
	bee.nurse_jelly = 3.0
	var before := _totals(hive)
	bee.set_role(Bee.Role.IDLE)
	if bee.role != Bee.Role.IDLE:
		_failures.append("idle: role did not change")
	_expect_totals("idle", before, _totals(hive), {"pollen": 6.0, "nectar": 12.0, "jelly": 3.0})
	_expect_empty_handed("idle", bee)
	_cleanup(hive.cells + [bee, hive])
	_completed += 1


func _test_forager_queued() -> void:
	var hive := _make_hive(6)
	var bee := _make_nurse(hive)
	bee.nurse_pollen = 4.0
	bee.nurse_carb = 5.0
	bee.nurse_carb_type = "honey"
	var before := _totals(hive)
	bee.pending_role = Bee.Role.FORAGER
	bee._apply_pending_role()
	if bee.role != Bee.Role.FORAGER:
		_failures.append("forager: role did not change")
	_expect_totals("forager", before, _totals(hive), {"pollen": 4.0, "honey": 5.0})
	_expect_empty_handed("forager", bee)
	_cleanup(hive.cells + [bee, hive])
	_completed += 1


func _test_queen_unchanged() -> void:
	var hive := _make_hive(6)
	var queen := _make_nurse(hive, true)
	queen.nurse_pollen = 5.0
	queen.nurse_carb = 10.0
	queen.nurse_carb_type = "nectar"
	var before := _totals(hive)
	queen._apply_role(Bee.Role.IDLE)
	_expect_totals("queen", before, _totals(hive), {})
	_expect_empty_handed("queen", queen)
	_cleanup(hive.cells + [queen, hive])
	_completed += 1
