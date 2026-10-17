extends SceneTree
## SP-11 test: with Cell art on, every ring on a comb cell traces the cup's
## rim (EMPTY_RIM) -- six points, each through _silhouette_point_to_local and
## scaled about the rim's centre; with Cell art off every ring is the hexagon.
##
## Run by tests/test_sp11_cell_rim.py:
##   godot --headless --path <repo> --script res://tests/sp11_cell_rim_test.gd
## Prints "SP11 PASS" and exits 0, or each "SP11 FAIL" line and exits 1.

const LEVEL := 3
const BOOT_FRAMES := 10

var _main: Node = null
var _frame := 0
var _phase := "boot"
var _failures: PackedStringArray = PackedStringArray()
var _session: Node = null


func _process(_delta: float) -> bool:
	_frame += 1
	if _phase == "boot":
		_boot()
	elif _phase == "settle" and _frame >= BOOT_FRAMES:
		_run()
		_phase = "done"
	if _phase == "done":
		_report()
		return true
	return false


# Autoloads are reached through the tree: a --script run compiles this file
# before they exist.
func _boot() -> void:
	if not root.has_node("Session"):
		_fail("Session autoload is not loaded")
		_phase = "done"
		return
	_session = root.get_node("Session")
	_session.starting_level = LEVEL
	_session.menu_pending = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _run() -> void:
	var cell = _make_cell(true)
	_check(cell.EMPTY_RIM.size() == 6, "EMPTY_RIM has %d points, not six" % cell.EMPTY_RIM.size())
	var rings := {
		"selection_ring": cell.cell_size + 2.0,
		"designation_ring": cell.cell_size - 3.0,
		"zone_halo": cell.cell_size + 6.0,
		"zone_glow": cell.cell_size + 4.0,
		"outline": cell.cell_size,
	}
	for ring_name in rings:
		_check_cup_ring(cell, ring_name, cell.get(ring_name), rings[ring_name])
	cell.queue_free()

	var flat = _make_cell(false)
	for ring_name in rings:
		var line: Line2D = flat.get(ring_name)
		_check(line != null and line.points.size() == 7,
			"Cell art off: %s is not the hexagon" % ring_name)
		if line != null and line.points.size() == 7:
			var hex: PackedVector2Array = flat.Shapes.hexagon_points(rings[ring_name], flat.squashed)
			for i in 6:
				if not line.points[i].is_equal_approx(hex[i]):
					_fail("Cell art off: %s point %d is not the hexagon corner" % [ring_name, i])
	flat.queue_free()
	_session.use_cell_sprites = true


func _make_cell(cell_art: bool):
	_session.use_cell_sprites = cell_art
	var cell = _main.HiveCell.new()
	cell.axial = Vector2i(40, 40)
	cell.main = _main
	_main.hive_root.add_child(cell)
	return cell


func _check_cup_ring(cell, ring_name: String, line: Line2D, size: float) -> void:
	if line == null:
		_fail("%s is missing" % ring_name)
		return
	var pts: PackedVector2Array = line.points
	if pts.size() != 7:
		_fail("%s has %d points, not the rim's six plus the closing point" % [ring_name, pts.size()])
		return
	var local: Array = []
	var centre := Vector2.ZERO
	for p in cell.EMPTY_RIM:
		var q: Vector2 = cell._silhouette_point_to_local(p)
		local.append(q)
		centre += q
	centre /= 6.0
	var k: float = size / cell.cell_size
	for i in 6:
		var want: Vector2 = centre + (local[i] - centre) * k
		if not pts[i].is_equal_approx(want):
			_fail("%s point %d is %s, not %s" % [ring_name, i, pts[i], want])
	if not pts[6].is_equal_approx(pts[0]):
		_fail("%s does not close its loop" % ring_name)


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_fail(failure)


func _fail(line: String) -> void:
	_failures.append(line)


func _report() -> void:
	if _failures.is_empty():
		print("SP11 PASS")
		quit(0)
	else:
		for line in _failures:
			print("SP11 FAIL: " + line)
		quit(1)
