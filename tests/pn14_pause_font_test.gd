extends SceneTree
## PN-14: Space leaves the HUD readout font sizes unchanged across a pause.

var _main: Node
var _frame := 0
var _before := {}
var _failures := PackedStringArray()

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		var session: Node = root.get_node("Session")
		session.starting_level = 8
		session.menu_pending = false
		session.pinned_stats = ["day", "stores", "fps"]
		_main = load("res://scenes/Main.tscn").instantiate()
		root.add_child(_main)
		current_scene = _main
	elif _frame == 15:
		_main.hud.update_fps(60, 16.0, 20.0, 1.0)
		_before = _sizes()
		_check(_before.size() == 3, "expected the day, stores and fps readouts")
		_press_space()
		_check(paused, "Space did not pause the game")
	elif _frame == 20:
		_main.hud.update_fps(60, 16.0, 20.0, 0.0)
		_press_space()
		_check(not paused, "Space did not resume the game")
	elif _frame == 30:
		_main.hud.update_fps(60, 16.0, 20.0, 1.0)
		var after := _sizes()
		_check(after == _before, "readout font sizes changed: %s -> %s" % [_before, after])
		if _failures.is_empty():
			print("PN14 PASS")
			quit(0)
		else:
			for failure in _failures:
				print("PN14 FAIL: " + failure)
			quit(1)
		return true
	return false

func _press_space() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	_main.input_selection._unhandled_input(event)

func _sizes() -> Dictionary:
	var result := {}
	for child in _main.hud.corner_column.get_children():
		if child is Label and child != _main.hud.pause_label and child != _main.hud.perf_breakdown and not child.is_queued_for_deletion() and child.text != "":
			result[child.text] = child.get_theme_font_size("font_size")
	return result

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

