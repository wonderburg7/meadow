extends SceneTree
## SP-10 test: hive soil and rock blocks draw in the same order as comb cells.
##
## Boots level 3 (a Scenario level: no Challenge branches) and checks, on the
## fresh live hive: every soil and rock block has
## z_index == Shapes.hex_draw_depth(axial); a block lower on screen than
## another has the higher z_index; and a comb cell and a block on neighbouring
## hexes order the same way round as they sit on screen.
##
## Run by tests/test_sp10_soil_depth.py:
##   godot --headless --path <repo> --script res://tests/sp10_soil_depth_test.gd
## Prints "SP10 PASS" and exits 0, or each "SP10 FAIL" line and exits 1.

const Shapes = preload("res://scripts/shapes.gd")

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
	var blocks: Array = []
	for child in _main.hive_root.get_children():
		if is_instance_of(child, _main.SoilBlock) or is_instance_of(child, _main.RockBlock):
			blocks.append(child)
	_check(blocks.size() > 0, "a fresh hive has no soil or rock blocks")
	# A fresh comb may touch no block at all, so build one cell beside the
	# first block to test the cell-and-block order against.
	if blocks.size() > 0:
		_add_cell_beside(blocks[0])
	var cells: Array = []
	for child in _main.hive_root.get_children():
		if is_instance_of(child, _main.HiveCell):
			cells.append(child)
	_check(cells.size() > 0, "a fresh hive has no comb cells")

	for block in blocks:
		var want: int = Shapes.hex_draw_depth(block.axial)
		if block.z_index != want:
			_fail("block at %s has z_index %d, not hex_draw_depth %d" % [block.axial, block.z_index, want])

	# Screen order: whatever sits lower on screen must draw over whatever
	# sits higher, for every pair of blocks.
	for a in blocks:
		for b in blocks:
			if b.position.y > a.position.y and not b.z_index > a.z_index:
				_fail("block at %s is lower on screen than %s but z_index %d is not above %d"
					% [b.axial, a.axial, b.z_index, a.z_index])

	# A comb cell and a block on neighbouring hexes order the same way.
	var neighbours := 0
	for cell in cells:
		for block in blocks:
			if Shapes.hex_distance(cell.axial, block.axial) != 1:
				continue
			neighbours += 1
			if cell.position.y > block.position.y and not cell.z_index > block.z_index:
				_fail("cell at %s is lower than block at %s but does not draw over it" % [cell.axial, block.axial])
			if block.position.y > cell.position.y and not block.z_index > cell.z_index:
				_fail("block at %s is lower than cell at %s but does not draw over it" % [block.axial, cell.axial])
	_check(neighbours > 0, "no comb cell sits next to a block, so the cell-and-block order was not tested")


## The six steps from one hex to its neighbours, in axial (q, r).
const NEIGHBOUR_STEPS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1),
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 1),
]


## A comb cell on a free hex beside the block, placed the way world_building
## places one: the block's position plus the hex step on the same grid. Its
## _ready sets the z_index under test, exactly as for a comb cell.
func _add_cell_beside(block) -> void:
	# Autoloads are reached through the tree, as in _boot.
	var spacing: float = root.get_node("GameConfig").hive_cell_spacing
	var squashed: bool = _session.use_sprite_hex_grid
	for step in NEIGHBOUR_STEPS:
		var hex: Vector2i = block.axial + step
		if _hex_has_block_or_cell(hex):
			continue
		var cell = _main.HiveCell.new()
		cell.axial = hex
		cell.main = _main
		cell.position = block.position + Shapes.hex_to_pixel(step.x, step.y, spacing, squashed)
		_main.hive_root.add_child(cell)
		return
	_fail("no free hex beside the block at %s to test a cell against" % block.axial)


func _hex_has_block_or_cell(hex: Vector2i) -> bool:
	for child in _main.hive_root.get_children():
		if child.get("axial") == hex:
			return true
	return false


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_fail(failure)


func _fail(line: String) -> void:
	_failures.append(line)


func _report() -> void:
	if _failures.is_empty():
		print("SP10 PASS")
		quit(0)
	else:
		for line in _failures:
			print("SP10 FAIL: " + line)
		quit(1)
