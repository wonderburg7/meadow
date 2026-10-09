extends SceneTree
## SP-1 test: an empty HiveCell's sprite carries PixelSprite's shared
## material, linear filtering and the hive pixel scale.
##
## Run by tests/test_sp1_pixel_sprite.py:
##   godot --headless --path <repo> --script res://tests/sp1_pixel_sprite_test.gd
## Prints "SP1 PASS" and exits 0, or prints each failure and exits 1.

var _failures: PackedStringArray = PackedStringArray()
var _ran := false


func _process(_delta: float) -> bool:
	# Autoloads are in the tree by the first frame, not during _initialize.
	if _ran:
		return true
	_ran = true
	_run()
	if _failures.is_empty():
		print("SP1 PASS")
		quit(0)
	else:
		for line in _failures:
			print("SP1 FAIL: " + line)
		quit(1)
	return true


func _run() -> void:
	var pixel_sprite: GDScript = load("res://scripts/pixel_sprite.gd")
	var hive_cell: GDScript = load("res://scripts/hive_cell.gd")
	var cell: Node2D = hive_cell.new()
	root.add_child(cell)
	var sprite: Sprite2D = cell.empty_sprite
	if sprite == null:
		_failures.append("the cell has no empty_sprite")
		return
	if sprite.material == null or sprite.material != pixel_sprite.shared_material():
		_failures.append("the sprite does not carry PixelSprite's shared material")
	if not (sprite.material is ShaderMaterial) or (sprite.material as ShaderMaterial).shader == null:
		_failures.append("the shared material has no shader")
	if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR:
		_failures.append("texture filter is %d, expected linear" % sprite.texture_filter)
	var expected: float = pixel_sprite.hive_scale()
	if absf(expected - 1.1875) > 0.0001:
		_failures.append("hive scale is %f, expected 1.1875" % expected)
	if not sprite.scale.is_equal_approx(Vector2.ONE * expected):
		_failures.append("sprite scale is %s, expected %f" % [sprite.scale, expected])
	var other: Node2D = hive_cell.new()
	root.add_child(other)
	if other.empty_sprite.material != sprite.material:
		_failures.append("two cells do not share one material")
