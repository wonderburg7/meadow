extends SceneTree
## GP-4 test: the corner problem strip.
##
## Boots the real Main.tscn and feeds hud.update_signals() lines, then checks:
## - a line's button is only as wide as its text (not the column);
## - at most SIGNAL_LINE_CAP lines show, then a "+N more" label;
## - no severity-0 line shows;
## - in a Colony Run (level 8) red lines show with the strip unstarred, yellow
##   ones do not; outside it nothing shows unstarred;
## - a removed line (the x button) stays away until a refresh stops reporting
##   it, then returns when it is reported again.
##
## Run by tests/test_gp4_problem_strip.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/gp4_problem_strip_test.gd
## Prints "GP4 PASS" and exits 0, or prints each failure and exits 1.

const COLONY_RUN_LEVEL := 8
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
		_run()
		_report()
		return true
	return false


func _boot() -> void:
	_session = root.get_node("Session")
	_session.starting_level = COLONY_RUN_LEVEL
	_session.menu_pending = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_booted = true


func _line(text: String, severity: int, id: String) -> Array:
	return [text, severity, "", "", id]


## The strip's rows: HBoxContainers holding the text button and the x.
func _rows() -> Array:
	var rows: Array = []
	for child in _main.hud.corner_column.get_children():
		if child is HBoxContainer and not child.is_queued_for_deletion():
			rows.append(child)
	return rows


func _more_labels() -> Array:
	var found: Array = []
	for child in _main.hud.corner_column.get_children():
		if child is Label and not child.is_queued_for_deletion() and str(child.text).contains("more"):
			found.append(child)
	return found


func _texts() -> Array:
	var texts: Array = []
	for row in _rows():
		texts.append(str(row.get_child(0).text))
	return texts


func _run() -> void:
	var hud = _main.hud
	_check(_main.colony_milestones.applies(), "the Colony Run's rules do not apply")
	_check(hud.SIGNAL_LINE_CAP == 4, "the cap is %d" % hud.SIGNAL_LINE_CAP)

	# Width: a short line's button is its text's width, far below the column cap.
	_session.pinned_stats = ["day", "stores", "signals"]
	hud.update_signals([_line("Short", 1, "a")])
	var row: Control = _rows()[0] if not _rows().is_empty() else null
	_check(row != null, "a starred yellow line does not show")
	if row != null:
		var button: Button = row.get_child(0)
		_check(button.size_flags_horizontal == Control.SIZE_SHRINK_BEGIN, "the line button fills the column")
		_check(row.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the row catches clicks")
		var natural: float = button.get_minimum_size().x
		_check(natural < hud._corner_line_width() * 0.5, "the test line is not short")

	# Cap and "+N more".
	var many: Array = []
	for i in range(6):
		many.append(_line("Problem %d" % i, 2, "p%d" % i))
	hud.update_signals(many)
	_check(_rows().size() == 4, "%d lines show, not 4" % _rows().size())
	var more := _more_labels()
	_check(more.size() == 1 and str(more[0].text).contains("+2 more"), "the +2 more line is missing")
	if not more.is_empty():
		_check(more[0].mouse_filter == Control.MOUSE_FILTER_IGNORE, "the +N more line is interactive")
	hud.update_signals(many.slice(0, 4))
	_check(_more_labels().is_empty(), "+N more shows with exactly four lines")

	# Severity 0 never shows.
	hud.update_signals([_line("Drizzle", 0, "rain"), _line("Low", 1, "b")])
	_check(_texts() == ["• Low"], "severity-0 line shown: %s" % [_texts()])

	# Colony Run, strip unstarred: red shows, yellow does not.
	_session.pinned_stats = ["day", "stores"]
	hud.update_signals([_line("Yellow", 1, "y"), _line("Red", 2, "r")])
	_check(_texts() == ["• Red"], "unstarred Colony Run strip shows %s" % [_texts()])
	# Outside a Colony Run, unstarred shows nothing.
	_session.starting_level = 1
	hud.update_signals([_line("Yellow", 1, "y"), _line("Red", 2, "r")])
	_check(_texts().is_empty(), "unstarred strip outside a Colony Run shows %s" % [_texts()])
	_session.starting_level = COLONY_RUN_LEVEL

	# Removal: stays away while reported, returns once cleared and reported again.
	_session.pinned_stats = ["day", "stores", "signals"]
	hud.update_signals([_line("One", 2, "one"), _line("Two", 2, "two")])
	var remove: Button = _rows()[0].get_child(1)
	_check(remove.text == "×", "the first row has no x button")
	remove.pressed.emit()
	_check(_texts() == ["• Two"], "after removing One: %s" % [_texts()])
	hud.update_signals([_line("One", 2, "one"), _line("Two", 2, "two")])
	_check(_texts() == ["• Two"], "One came back while its problem persisted: %s" % [_texts()])
	hud.update_signals([_line("Two", 2, "two")])
	hud.update_signals([_line("One", 2, "one"), _line("Two", 2, "two")])
	_check(_texts() == ["• One", "• Two"], "One did not return after clearing: %s" % [_texts()])


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("GP4 PASS")
		quit(0)
		return
	for failure in _failures:
		print("GP4 FAIL: " + failure)
	quit(1)
