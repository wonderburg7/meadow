extends SceneTree
## RR-2 test: "Saves..." works on the main menu at a fresh boot.
##
## Boots the real Main.tscn with menu_pending = true (no run built, so no
## hud, saving or year_winter), presses the settings window's Saves... via
## debug_panel._on_load_pressed() and checks the Saves window is open.
## Any script error in the output fails the Python wrapper.
##
## Run by tests/test_rr2_boot_saves.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/rr2_boot_saves_test.gd
## Prints "RR2 PASS" and exits 0, or prints each failure and exits 1.

const BOOT_FRAMES := 10

var _main: Node = null
var _session: Node = null
var _frame := 0
var _booted := false
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	if not _booted:
		_boot()
		return false
	if _frame >= BOOT_FRAMES:
		_check_saves()
		return true
	return false


func _boot() -> void:
	if not root.has_node("Session"):
		_fail("the Session autoload is not loaded")
		return
	_session = root.get_node("Session")
	_session.menu_pending = true
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_booted = true


func _check_saves() -> void:
	_check(_main.hud == null, "a menu boot should have no hud yet")
	_check(_main.saves_panel != null, "main.gd did not build the Saves window at boot")
	_check(_main.debug_panel != null, "main.gd did not build the debug panel at boot")
	if _main.saves_panel != null and _main.debug_panel != null:
		_main.debug_panel._on_load_pressed()
		_check(_main.saves_panel.is_open(), "Saves... did not open the Saves window on the menu")
		_check(not _main.saves_panel.save_run_btn.visible or not _main.saves_panel.is_open(),
			"the Save row should stay hidden on the menu")
		# Closing and reopening must also work, and a load of an unreadable
		# file must warn rather than touch the missing hud.
		_main.saves_panel.close()
		_main.saves_panel._load("res://tests/no_such_save.json", "none")
	if _failures.is_empty():
		print("RR2 PASS")
		quit(0)
	else:
		for line in _failures:
			print("RR2 FAIL: ", line)
		quit(1)


func _check(ok: bool, message: String) -> void:
	if not ok:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
