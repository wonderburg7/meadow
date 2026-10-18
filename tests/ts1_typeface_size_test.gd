extends SceneTree
## TS-1 test: every typeface draws at the same width as Standard.
##
## For text scale 1 and 2 and every typeface in the Typeface setting, measures
## UiTheme.REFERENCE_TEXT at UiTheme.font_px(TYPE_SIZES["Body"]) in that face
## and compares it with Standard at the same scale. Passes within 8 %.
##
## Run by tests/test_ts1_typeface_size.py:
##   godot --headless --path <repo> --script res://tests/ts1_typeface_size_test.gd
## Prints "TS1 PASS" and exits 0, or prints each failure and exits 1.

const TOLERANCE := 0.08
const TYPEFACES := ["sans", "atkinson", "opensans", "opendyslexic", "munro", "silkscreen"]
const SCALES := [1.0, 2.0]

var _frame := 0


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false
	_run()
	return true


# Autoloads are reached through the tree: a --script run compiles this file
# before they exist.
func _run() -> void:
	var failures := PackedStringArray()
	if not root.has_node("Session"):
		print("TS1 FAIL: the Session autoload is not loaded")
		quit(1)
		return
	var session: Node = root.get_node("Session")
	var theme_script: Script = load("res://scripts/ui_theme.gd")
	var settings: Script = load("res://scripts/settings_catalogue.gd")
	var body: float = theme_script.TYPE_SIZES["Body"]
	var seen_different := false
	for scale in SCALES:
		session.text_scale = scale
		session.ui_typeface = "sans"
		var standard := _width(theme_script, ThemeDB.fallback_font, body)
		for face_name in TYPEFACES:
			session.ui_typeface = face_name
			var font: Font = theme_script._typeface_font(face_name)
			if font == null:
				font = ThemeDB.fallback_font
			var width := _width(theme_script, font, body)
			var ratio: float = width / standard
			if absf(ratio - 1.0) > TOLERANCE:
				failures.append("%s at scale %.1f is %.1f %% of Standard's width (px %d)" % [
					face_name, scale, ratio * 100.0, theme_script.font_px(body)])
			if face_name != "sans" and theme_script.typeface_size_factor(face_name) != 1.0:
				seen_different = true
	if not seen_different:
		failures.append("no typeface needed a size factor, so this check cannot tell a match from none")
	session.ui_typeface = "sans"
	session.text_scale = 1.0
	if settings == null:
		failures.append("settings_catalogue.gd did not load")
	if failures.is_empty():
		print("TS1 PASS")
		quit(0)
	else:
		for line in failures:
			print("TS1 FAIL: " + line)
		quit(1)


func _width(theme_script: Script, font: Font, body: float) -> float:
	return font.get_string_size(theme_script.REFERENCE_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, theme_script.font_px(body)).x
