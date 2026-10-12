extends SceneTree
## RR-5 test: hexagon names re-fit when the typeface changes.
##
## Boots the real Main.tscn, opens the main menu, sets text scale 2 and
## Munro, and waits until every hexagon name has fitted under Munro. Then it
## switches to OpenDyslexic through the Typeface setting's own apply path
## (settings_catalogue.gd's ui_typeface row), waits until the labels draw in
## OpenDyslexic and have refitted, and checks each hexagon label's font size
## against what the menu's hex_fit_size gives for OpenDyslexic at that box.
##
## Before the fix the fit cache key used font.get_rid().get_id(), which is 0
## for every FontFile, so the switch kept Munro's fitted size.
##
## Run by tests/test_rr5_hex_refit.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/rr5_hex_refit_test.gd
## Prints "RR5 PASS" and exits 0, or prints each failure and exits 1.

## The scripts are loaded at run time, not preloaded: they reach the Session
## and GameConfig autoloads, which a --script run has not registered when it
## compiles this file.
const LEVEL := 3            # a Scenario level with comb, as the COL-7 test uses
const BOOT_FRAMES := 10     # let Main._ready build the world and the menu first
const SETTLE_FRAMES := 2    # frames to draw once a face is in place
const SETTLE_CAP := 600     # frames to wait for a refit before calling it a failure
const TEXT_SCALE := 2.0
const MUNRO := "res://assets/fonts/munro.ttf"
const OPENDYSLEXIC := "res://assets/fonts/OpenDyslexic-Regular.otf"

var _main: Node = null
var _menu: Node = null
var _frame := 0
var _phase := "boot"
var _phase_frame := 0
var _hex_labels: Array = []
var _munro: Font = null
var _opendyslexic: Font = null
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				_start_munro()
		"munro":
			_wait_for_fit(_munro, "under Munro", _switch_to_opendyslexic)
		"opendyslexic":
			_wait_for_fit(_opendyslexic, "after the switch to OpenDyslexic", _check_hex_labels)
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
	var session: Node = root.get_node("Session")
	session.starting_level = LEVEL
	session.menu_pending = true
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _start_munro() -> void:
	var menus := get_nodes_in_group("main_menu")
	if menus.is_empty():
		_fail("no main menu was built")
		return
	_menu = menus[0]
	_menu.open()
	_munro = load(MUNRO)
	_opendyslexic = load(OPENDYSLEXIC)
	root.get_node("Session").text_scale = TEXT_SCALE
	_settings().apply_setting("ui_typeface", "munro")
	_ui_theme().refresh_for_setting("text_scale")
	_ui_theme().refresh_for_setting("ui_typeface")
	_hex_labels = _find_hex_labels(_menu)
	_check(_hex_labels.size() > 0, "no hexagon name labels were found in the main menu")
	_phase = "munro"
	_phase_frame = _frame


func _switch_to_opendyslexic() -> void:
	_settings().apply_setting("ui_typeface", "opendyslexic")
	_ui_theme().refresh_for_setting("ui_typeface")
	_phase = "opendyslexic"
	_phase_frame = _frame


## Waits until every hexagon name draws in `face` at the size the fit gives
## for it, then SETTLE_FRAMES more frames. Gives up after SETTLE_CAP frames
## and fails: a Munro fit that never settles is the stale-key fault itself,
## and a pass that starts from a stale fit proves nothing.
func _wait_for_fit(face: Font, when: String, next: Callable) -> void:
	if _all_fitted(face):
		if _frame - _phase_frame >= SETTLE_FRAMES:
			next.call()
		return
	if _frame - _phase_frame >= SETTLE_CAP:
		_fail("the hexagon names never settled %s (%d frames)" % [when, _frame - _phase_frame])


func _all_fitted(face: Font) -> bool:
	for label in _hex_labels:
		if not is_instance_valid(label) or label.get_theme_font("font").get_instance_id() != face.get_instance_id():
			return false
		if label.get_theme_font_size("font_size") != _expected_size(label, face):
			return false
	return true


func _expected_size(label: Label, face: Font) -> int:
	var avail: Vector2 = label.size - label.get_theme_stylebox("normal").get_minimum_size()
	var base := int(round(_ui_theme().TYPE_SIZES["Tiny"] * TEXT_SCALE))
	return _menu_script().hex_fit_size(face, label.text, avail, base, label.get_theme_constant("line_spacing"))


func _check_hex_labels() -> void:
	var differs := false
	for label in _hex_labels:
		if not is_instance_valid(label):
			_check(false, "a hexagon name label was freed before the check")
			continue
		var expected := _expected_size(label, _opendyslexic)
		var actual: int = label.get_theme_font_size("font_size")
		_check(actual == expected,
			"'%s' is at font size %d after the switch to OpenDyslexic, expected %d" % [label.text, actual, expected])
		if _expected_size(label, _munro) != expected:
			differs = true
	# If Munro and OpenDyslexic fit every name the same, a stale size passes
	# too, and this check proves nothing.
	_check(differs, "Munro and OpenDyslexic fit every hexagon name to the same size, so this check cannot tell a refit from none")
	_phase = "done"


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


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)


func _fail(line: String) -> void:
	_failures.append(line)
	_phase = "done"


func _report() -> void:
	if _failures.is_empty():
		print("RR5 PASS")
		quit(0)
	else:
		for line in _failures:
			print("RR5 FAIL: " + line)
		quit(1)
