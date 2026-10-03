extends SceneTree
## HO-15 test: a menu hex shrinks its name until every word and every line
## fits, for six typefaces at text scale 1 and 2.
##
## Run by tests/test_ho15_menu_hex_fit.py:
##   godot --headless --path <repo> --script res://tests/ho15_menu_hex_fit_test.gd
## Prints "HO15 PASS" and exits 0, or prints each failure and exits 1.

const TYPEFACES := ["sans", "atkinson", "opendyslexic", "opensans", "munro", "silkscreen"]
const TINY_SIZE := 11

var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_run()
	_report()
	return true


func _run() -> void:
	var menu: GDScript = load("res://scripts/main_menu.gd")
	var ui_theme: GDScript = load("res://scripts/ui_theme.gd")
	var consts: Dictionary = menu.get_script_constant_map()
	var hex_size: float = consts["HEX_SIZE"]
	var box := Vector2(hex_size * 2.0 - 44.0, hex_size * sqrt(3.0) - 16.0)
	var spacing: int = ThemeDB.get_default_theme().get_constant("line_spacing", "Label")
	for typeface in TYPEFACES:
		var font: Font = ui_theme._typeface_font(typeface)
		if font == null:
			font = ThemeDB.fallback_font
		for scale in [1.0, 2.0]:
			var base := int(round(TINY_SIZE * scale))
			for stage in consts["STAGES"]:
				var title: String = stage.title
				var size: int = menu.hex_fit_size(font, title, box, base, spacing)
				if not menu.hex_text_fits(font, title, box, size, spacing):
					_fail("%s scale %.0f \"%s\": size %d does not fit" % [typeface, scale, title, size])
				elif size != base and menu.hex_text_fits(font, title, box, size + 1, spacing):
					_fail("%s scale %.0f \"%s\": size %d is not the largest that fits" % [typeface, scale, title, size])


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("HO15 PASS")
		quit(0)
	else:
		for line in _failures:
			print("HO15 FAIL: " + line)
		quit(1)
