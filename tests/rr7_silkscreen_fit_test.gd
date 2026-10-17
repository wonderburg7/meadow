extends SceneTree
## RR-7 investigation: why Silkscreen at text scale 2 still splits a menu
## hexagon's word (C-99, 15 Oct 2026: "CHALLENG" / "E 1").
##
## Boots the real Main.tscn, opens the main menu, sets text scale 2 and
## Silkscreen through the settings' own apply path, waits until the Challenge 1
## hexagon's name has fitted, then prints the figures the plan asks for: the
## label's available size, the size hex_fit_size returns, whether
## hex_text_fits holds at it, and the line count the Label itself lays out.
## It also prints each candidate size from base down to the floor, each word's
## width at the returned size, and the lines a TextParagraph shaped the way a
## word-smart Label shapes breaks the title into.
##
## A regression guard (RR-8): after each step of the walk it fails when the
## last painted size differs from hex_fit_size's, or the painted lines split a
## word, as well as when it cannot reach the figures. Run by tests/test_rr7_silkscreen_fit.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/rr7_silkscreen_fit_test.gd
## Prints "RR7 ..." figure lines, then "RR7 DONE" and exits 0, or "RR7 FAIL" lines and exits 1.

## The scripts are loaded at run time, not preloaded: they reach the Session
## and GameConfig autoloads, which a --script run has not registered when it
## compiles this file.
const LEVEL := 3
const BOOT_FRAMES := 10
const SETTLE_FRAMES := 2
const SETTLE_CAP := 600
const TEXT_SCALE := 2.0
const SILKSCREEN := "res://assets/fonts/slkscr.ttf"
const TITLE_PREFIX := "Challenge 1 "

var _menu: Node = null
var _frame := 0
var _phase := "boot"
var _phase_frame := 0
var _label: Label = null
var _face: Font = null
var _failures: PackedStringArray = PackedStringArray()
var _steps: Array = []
var _step := 0
const WALK_FRAMES := 20
var _painted_size := 0
var _painted_face := ""
var _draws := 0


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				_start()
		"fit":
			_wait_for_fit()
		"walk":
			_walk()
	if _phase == "done":
		_report()
		return true
	return false


func _boot() -> void:
	if not root.has_node("Session") or not root.has_node("GameConfig"):
		_fail("the Session or GameConfig autoload is not loaded")
		return
	var session: Node = root.get_node("Session")
	session.starting_level = LEVEL
	session.menu_pending = true
	var main: Node = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	_phase = "settle"


func _start() -> void:
	var menus := get_nodes_in_group("main_menu")
	if menus.is_empty():
		_fail("no main menu was built")
		return
	_menu = menus[0]
	_menu.open()
	_face = load(SILKSCREEN)
	root.get_node("Session").text_scale = TEXT_SCALE
	_settings().apply_setting("ui_typeface", "silkscreen")
	_ui_theme().refresh_for_setting("text_scale")
	_ui_theme().refresh_for_setting("ui_typeface")
	for label in _find_hex_labels(_menu):
		if label.text.begins_with(TITLE_PREFIX):
			_label = label
	if _label == null:
		_fail("no hexagon name starting '%s' was found" % TITLE_PREFIX)
		return
	_probe_paint()
	_phase = "fit"
	_phase_frame = _frame


## The Label paints its text on NOTIFICATION_DRAW, before its `draw` signal
## fires, so the font size in effect when the signal starts is the size it
## just painted. The menu's own fit handler is moved behind this probe so the
## probe reads that size before the fit changes it.
func _probe_paint() -> void:
	var fits: Array = []
	for connection in _label.get_signal_connection_list("draw"):
		fits.append(connection["callable"])
		_label.draw.disconnect(connection["callable"])
	_label.draw.connect(_on_label_draw)
	for fit in fits:
		_label.draw.connect(fit)


func _on_label_draw() -> void:
	_painted_size = _label.get_theme_font_size("font_size")
	_painted_face = _label.get_theme_font("font").resource_path.get_file()
	_draws += 1


func _wait_for_fit() -> void:
	if _fitted():
		if _frame - _phase_frame >= SETTLE_FRAMES:
			_print_figures()
			_steps = _walk_steps()
			_phase = "walk"
			_phase_frame = _frame
		return
	if _frame - _phase_frame >= SETTLE_CAP:
		_fail("the Challenge 1 name never fitted under Silkscreen (%d frames)" % (_frame - _phase_frame))


func _fitted() -> bool:
	if not is_instance_valid(_label):
		return false
	if _label.get_theme_font("font").get_instance_id() != _face.get_instance_id():
		return false
	return _label.get_theme_font_size("font_size") == _fit_size()


func _avail() -> Vector2:
	return _label.size - _label.get_theme_stylebox("normal").get_minimum_size()


func _base() -> int:
	return int(round(_ui_theme().TYPE_SIZES["Tiny"] * TEXT_SCALE))


func _spacing() -> int:
	return _label.get_theme_constant("line_spacing")


func _fit_size() -> int:
	return _menu_script().hex_fit_size(_face, _label.text, _avail(), _base(), _spacing())


func _print_figures() -> void:
	var menu: Script = _menu_script()
	var avail := _avail()
	var size := _fit_size()
	var fits: bool = menu.hex_text_fits(_face, _label.text, avail, size, _spacing())
	print("RR7 title: '%s'" % _label.text)
	print("RR7 label size: %s  stylebox minimum: %s  available: %s" % [
		str(_label.size), str(_label.get_theme_stylebox("normal").get_minimum_size()), str(avail)])
	print("RR7 base size: %d  floor: %d  line_spacing: %d" % [_base(), menu.HEX_MIN_FONT_SIZE, _spacing()])
	print("RR7 hex_fit_size returns: %d  hex_text_fits at it: %s  label font_size now: %d" % [
		size, str(fits), _label.get_theme_font_size("font_size")])
	print("RR7 Label line count: %d  visible lines: %d  minimum size: %s" % [
		_label.get_line_count(), _label.get_visible_line_count(), str(_label.get_minimum_size())])
	print("RR7 last paint: size %d  face %s  draws so far %d  lines at the painted size %s" % [
		_painted_size, _painted_face, _draws, str(_paragraph_lines(_painted_size, avail.x))])
	for candidate in range(_base(), menu.HEX_MIN_FONT_SIZE - 1, -1):
		print("RR7 candidate %d: hex_text_fits %s  widest word %.1f  height %.1f  paragraph lines %s" % [
			candidate, str(menu.hex_text_fits(_face, _label.text, avail, candidate, _spacing())),
			_widest_word(candidate), _face.get_height(candidate), str(_paragraph_lines(candidate, avail.x))])
	for word in _label.text.split(" ", false):
		print("RR7 word '%s' at %d: get_string_size %.2f  TextLine %.2f  (available %.1f)" % [
			word, size, _face.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x,
			_text_line_width(word, size), avail.x])


## C-99's own route: text scale 1, then 2, each through the settings path the
## Appearance row uses, and at each every typeface in the list in order. Each
## step waits WALK_FRAMES, then prints the Challenge 1 name's drawn face and
## size and whether the lines it lays out at that size split a word.
func _walk_steps() -> Array:
	var steps: Array = []
	for scale in [1.0, 2.0]:
		steps.append(["text_scale", scale])
		for face in _typefaces():
			steps.append(["ui_typeface", face])
	return steps


func _typefaces() -> Array:
	for row in _settings().TUNABLES:
		if row.get("key", "") == "ui_typeface":
			return row["options"]
	return []


func _walk() -> void:
	if _frame - _phase_frame < WALK_FRAMES:
		return
	if _step > 0:
		_print_step(_steps[_step - 1])
	if _step >= _steps.size():
		_phase = "done"
		return
	var step: Array = _steps[_step]
	_settings().apply_setting(step[0], step[1])
	_ui_theme().refresh_for_setting(step[0])
	_step += 1
	_phase_frame = _frame


func _print_step(step: Array) -> void:
	if not is_instance_valid(_label):
		_fail("the Challenge 1 name label was freed during the walk")
		return
	var font: Font = _label.get_theme_font("font")
	var drawn: int = _label.get_theme_font_size("font_size")
	var avail := _avail()
	var base := int(round(_ui_theme().TYPE_SIZES["Tiny"] * root.get_node("Session").text_scale))
	var fit: int = _menu_script().hex_fit_size(font, _label.text, avail, base, _spacing())
	var lines := _paragraph_lines_in(font, _painted_size, avail.x)
	var step_name := "%s=%s" % [step[0], str(step[1])]
	if _painted_size != fit:
		_failures.append("RR7 walk %s: painted size %d, fit %d (%s)" % [step_name, _painted_size, fit, font.resource_path.get_file()])
	if _splits_a_word(lines):
		_failures.append("RR7 walk %s: painted lines split a word %s" % [step_name, str(lines)])
	print("RR7 walk %s=%s: face %s  scale %s  override %d  fit %d  painted %d (%s, draw %d)  painted split %s  %s" % [
		step[0], str(step[1]), font.resource_path.get_file(), str(root.get_node("Session").text_scale),
		drawn, fit, _painted_size, _painted_face, _draws, str(_splits_a_word(lines)), str(lines)])


func _splits_a_word(lines: PackedStringArray) -> bool:
	for i in range(lines.size() - 1):
		if not lines[i].ends_with(" ") and not lines[i + 1].begins_with(" "):
			return true
	return false


func _widest_word(size: int) -> float:
	var widest := 0.0
	for word in _label.text.split(" ", false):
		widest = maxf(widest, _face.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
	return widest


func _text_line_width(text: String, size: int) -> float:
	var line := TextLine.new()
	line.add_string(text, _face, size)
	return line.get_size().x


## The lines a word-smart Label breaks the title into at `size`, shaped as a
## TextParagraph with the Label's own break flags.
func _paragraph_lines(size: int, width: float) -> PackedStringArray:
	return _paragraph_lines_in(_face, size, width)


func _paragraph_lines_in(font: Font, size: int, width: float) -> PackedStringArray:
	var para := TextParagraph.new()
	para.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	para.width = width
	para.add_string(_label.text, font, size)
	var lines := PackedStringArray()
	for i in para.get_line_count():
		var span := para.get_line_range(i)
		lines.append(_label.text.substr(span.x, span.y - span.x))
	return lines


func _settings() -> Script:
	return load("res://scripts/settings_catalogue.gd")


func _ui_theme() -> Script:
	return load("res://scripts/ui_theme.gd")


func _menu_script() -> Script:
	return load("res://scripts/main_menu.gd")


func _find_hex_labels(node: Node) -> Array:
	var found: Array = []
	if node is Label and node.has_meta("hex_fit_key"):
		found.append(node)
	for child in node.get_children():
		found.append_array(_find_hex_labels(child))
	return found


func _fail(line: String) -> void:
	_failures.append(line)
	_phase = "done"


func _report() -> void:
	if _failures.is_empty():
		print("RR7 DONE")
		quit(0)
	else:
		for line in _failures:
			print("RR7 FAIL: " + line)
		quit(1)
