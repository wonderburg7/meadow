extends SceneTree
## GP-1 test: the Colony Run's Goals drop-down and the long-term line.
##
## Boots the real Main.tscn into the Colony Run's level row (8) and checks:
## - the shelf shows the long-term line and the next milestone, and the
##   Goals button in the second row folds and unfolds them;
## - the long-term line follows the run's phase (before the countdown, the
##   countdown, winter, after winter in and out of the mating window, won);
## - evaluate() refreshes that line on a day change with no milestone newly
##   met;
## - collapsed, only the Goals button shows, and expanded and collapsed the shelf
##   stays inside the viewport at ui_layout.gd's MIN_SUPPORTED_WIDTH;
## - the collapsed state is a profile preference and comes back from a
##   profile's data;
## - a Challenge's shelf (set_challenge_goal) has no Goals button or long-term line.
##
## Run by tests/test_gp1_goals_dropdown.py (with APPDATA pointed at a temp
## folder, so the toggle's save_preferences never touches a real profile):
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/gp1_goals_dropdown_test.gd
## Prints "GP1 PASS" and exits 0, or prints each failure and exits 1.

const COLONY_RUN_LEVEL := 8
const BOOT_FRAMES := 10
const LAYOUT_FRAMES := 4

var _main: Node = null
var _session: Node = null
var _frame := 0
var _phase := "boot"
var _phase_frame := 0
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				_check_content()
				_start_layout("expanded")
		"expanded":
			if _frame - _phase_frame >= LAYOUT_FRAMES:
				_check_inside("expanded")
				_main.hud.goals_button.pressed.emit()
				_start_layout("collapsed")
		"collapsed":
			if _frame - _phase_frame >= LAYOUT_FRAMES:
				_check_collapsed()
				_check_inside("collapsed")
				_check_profile_and_challenge()
				_phase = "done"
	if _phase == "done":
		_report()
		return true
	return false


func _boot() -> void:
	if not root.has_node("Session"):
		_fail("the Session autoload is not loaded")
		return
	_session = root.get_node("Session")
	_session.starting_level = COLONY_RUN_LEVEL
	_session.menu_pending = false
	_session.goals_collapsed = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _check_content() -> void:
	var hud: CanvasLayer = _main.hud
	var ms: RefCounted = _main.colony_milestones
	_check(ms.applies(), "the Colony Run's rules do not apply on level %d" % COLONY_RUN_LEVEL)
	ms.show_next()
	_check(hud.goals_button.visible, "no Goals button in a Colony Run")
	_check(hud.goals_button.text == "Goals", "the button reads '%s'" % hud.goals_button.text)
	_check(hud.goals_button.button_pressed, "expanded, the Goals button is not pressed")
	_check(hud.long_term_goal_label.visible and not hud.long_term_goal_label.text.is_empty(),
		"the long-term line is not showing")
	_check(hud.current_goal_label.visible and hud.current_goal_label.text == "Build your first cell",
		"the next milestone is '%s'" % hud.current_goal_label.text)
	var ids: Array = []
	for entry: Variant in hud.colony_goal_entries:
		ids.append(str(entry.id))
	_check(ids == ["long_term", "first_cell"], "entries carry ids %s" % [ids])

	# SG-4: the opening walk. Each step shows alone until it is met, in order.
	var walk := [
		["first_cell", "Build your first cell"],
		["first_stores", "Bring in nectar and pollen"],
		["first_egg", "Let the queen lay an egg"],
	]
	for i: int in walk.size():
		_check(hud.current_goal_label.text == walk[i][1], "step %d reads '%s'" % [i, hud.current_goal_label.text])
		ms.met_days[walk[i][0]] = _main.day
		ms.show_next()
	_check(hud.current_goal_label.text == "Raise your first worker",
		"after the opening the line is '%s'" % hud.current_goal_label.text)
	for step: Array in walk:
		ms.met_days.erase(step[0])
	ms.show_next()

	# SG-4: an old save with first_worker met but no opening ids. The steps
	# are backfilled met, the shelf shows the real next goal, and the last-met
	# line is still first_worker.
	ms.restore({"first_worker": 5})
	ms.show_next()
	_check(ms.day_met("first_cell") == 5 and ms.day_met("first_egg") == 5, "the opening steps were not backfilled")
	_check(hud.current_goal_label.text == "Unlock your first automation",
		"an old save shows '%s' as next" % hud.current_goal_label.text)
	var done_texts: Array = []
	for entry: Variant in hud.colony_goal_entries:
		if entry.done:
			done_texts.append(str(entry.text))
	_check(done_texts == ["Raise your first worker"], "an old save's last-met line is %s" % [done_texts])

	# A save with none of the milestones: the opening steps stay unmet.
	ms.restore({})
	ms.show_next()
	_check(ms.day_met("first_cell") == -1, "a fresh save backfilled the opening steps")
	_check(hud.current_goal_label.text == "Build your first cell",
		"a fresh save shows '%s' as next" % hud.current_goal_label.text)


	# The long-term line, phase by phase.
	_session.winter_coming = false
	_session.winter_here = false
	_session.winter_ends_day = 0.0
	_expect_line(ms, "Survive the first winter, then send out a gyne", "before the countdown")
	_session.winter_coming = true
	_session.winter_starts_day = 12.0
	_expect_line(ms, "Survive winter -- it arrives on day 12", "countdown")
	_session.winter_here = true
	_session.winter_ends_day = float(_main.day) + 5.0
	_expect_line(ms, "Survive winter -- 5 days left", "winter")
	_session.winter_here = false
	var line: String = ms.long_term_line()
	_check(line.begins_with("Send out a gyne"), "after winter the line is '%s'" % line)
	ms.met_days[ms.VICTORY] = _main.day
	_expect_line(ms, "Your colony has made it -- keep it thriving", "after victory")
	ms.met_days.erase(ms.VICTORY)

	# A day change alone, with no milestone newly met, refreshes the line.
	_session.winter_here = true
	_session.winter_ends_day = float(_main.day) + 5.0
	ms.evaluate()
	_check(hud.long_term_goal_label.text == "Survive winter -- 5 days left", "evaluate left '%s'" % hud.long_term_goal_label.text)
	_main.day += 1
	ms.evaluate()
	_check(hud.long_term_goal_label.text == "Survive winter -- 4 days left",
		"a day later the line is '%s'" % hud.long_term_goal_label.text)
	_session.winter_here = false
	_session.winter_coming = false
	_session.winter_ends_day = 0.0
	ms.evaluate()


func _expect_line(ms: RefCounted, expected: String, phase: String) -> void:
	var line: String = ms.long_term_line()
	_check(line == expected, "%s: the line is '%s', not '%s'" % [phase, line, expected])


func _start_layout(name: String) -> void:
	root.size = Vector2i(int(load("res://scripts/ui_layout.gd").MIN_SUPPORTED_WIDTH), 600)
	_phase = name
	_phase_frame = _frame


func _check_inside(label: String) -> void:
	var rect: Rect2 = _main.hud.goal_shelf.get_global_rect()
	var view := Rect2(Vector2.ZERO, Vector2(root.size))
	print("GP1 %s shelf %s in viewport %s" % [label, rect, view])
	_check(view.encloses(rect), "%s: the shelf %s leaves the viewport %s" % [label, rect, view])


func _check_collapsed() -> void:
	var hud: CanvasLayer = _main.hud
	_check(_session.goals_collapsed, "the button press did not collapse the drop-down")
	_check(hud.goals_button.visible and not hud.goals_button.button_pressed,
		"collapsed, the Goals button is missing or still pressed")
	_check(not hud.long_term_goal_label.visible and not hud.current_goal_label.visible
		and not hud.completed_goal_label.visible, "collapsed, goal lines still show")


func _check_profile_and_challenge() -> void:
	var hud: CanvasLayer = _main.hud
	var profile: GDScript = load("res://scripts/player_profile.gd")
	_check(profile.PREFERENCE_KEYS.has("goals_collapsed"), "goals_collapsed is not a profile preference")
	_session.goals_collapsed = false
	profile.apply_to_session({"preferences": {"goals_collapsed": true}})
	_check(_session.goals_collapsed, "a profile with goals_collapsed true did not restore it")
	_session.goals_collapsed = true
	profile.apply_to_session({"preferences": {}})
	_check(_session.goals_collapsed, "a profile without the key changed the state")
	hud.goals_button.pressed.emit()
	_check(not _session.goals_collapsed and hud.long_term_goal_label.visible, "pressing again did not expand")

	hud.set_challenge_goal("Do the thing", "Did the other thing")
	_check(not hud.goals_button.visible and not hud.long_term_goal_label.visible,
		"a Challenge's shelf shows the Goals button or long-term line")
	_check(hud.current_goal_label.visible and hud.current_goal_label.text == "Do the thing"
		and hud.completed_goal_label.visible, "a Challenge's shelf lines changed")
	_session.goals_collapsed = true
	hud.set_challenge_goal("Do the thing")
	_check(hud.current_goal_label.visible, "collapsing the Colony Run's drop-down hid a Challenge's goal")


func _check(ok: bool, message: String) -> void:
	if not ok:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("GP1 PASS")
		quit(0)
		return
	for failure: String in _failures:
		print("GP1 FAIL: " + failure)
	quit(1)
