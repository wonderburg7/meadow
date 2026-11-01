extends SceneTree
## SG-3 (plans/now/short-term-goals.md): the short-term goals in the Goals
## drop-down, with progress, reward, star and Dismiss.
##
## Each case builds the real Main scene, paused, and moves the day on by hand
## the way sg2_short_term_goals_test.gd does; year_winter.gd's one-second
## refresh then offers, advances and pays the goals and calls main.gd's hook,
## which redraws the drop-down.
##
## colony   -- the Colony Run: an offered goal sits under the milestone with
##             its progress and reward; its star keeps it when the drop-down
##             is collapsed; Dismiss removes it and nothing replaces it until
##             the next day; finishing one shows the completion note and
##             Dr Gallerin's line, the line only once.
## scenario -- the same level row without "run_type": the drop-down holds the
##             short-term goal alone, with no milestone or long-term line.
## challenge1 -- a Challenge keeps its own shelf: no short-term line.

const BOOT_FRAMES := 10
const SCENARIO := "res://test_scenarios/sg3_goal_shelf.json"

var Levels: GDScript
var _cases: Array = ["colony", "scenario", "challenge1"]
var _case := ""
var _main: Node
var _phase := "boot"
var _frame := 0
var _old_level := 0
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			Levels = load("res://scripts/levels.gd")
			_old_level = root.get_node("Session").starting_level
			_phase = "next"
		"next":
			if _cases.is_empty():
				_finish()
				return true
			_case = _cases.pop_front()
			_start(_case)
		"settle":
			if _frame >= BOOT_FRAMES:
				match _case:
					"challenge1":
						_challenge_case()
					_:
						_run_case()
				_free_world()
				_phase = "next"
	return false


func _start(case_name: String) -> void:
	var session: Node = root.get_node("Session")
	session.menu_pending = false
	session.load_pending = false
	session.goals_collapsed = false
	session.winter_coming = false
	session.winter_here = false
	session.winter_starts_day = 0.0
	session.winter_ends_day = 0.0
	if case_name == "challenge1":
		Levels.scenario_override = {}
		session.starting_level = 1
	else:
		var level: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SCENARIO))
		level.erase("random_seed")
		if case_name == "scenario":
			level.erase("run_type")
		Levels.scenario_override = level
		session.starting_level = Levels.SCENARIO_LEVEL_ID
	paused = true
	_main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(_main)
	current_scene = _main
	_frame = 0
	_phase = "settle"


func _free_world() -> void:
	if is_instance_valid(_main):
		_main.queue_free()
	_main = null
	current_scene = null


func _next_day(pollen_in: float, pollen_kept: float) -> void:
	_main.hive.record_collection("pollen", pollen_in)
	if pollen_kept > 0.0:
		_main.hive.deposit("pollen", pollen_kept)
	_main.day += 1
	_main._sample_day_stores()


func _refresh() -> void:
	_main.signal_timer = 0.0
	_main.year_winter._refresh_signals(0.01)


func _offered() -> Dictionary:
	return _main.short_term_goals.get("offered", {})


func _row(id: String) -> Node:
	return _main.hud.short_term_box.get_node_or_null("short_term_" + id)


func _row_text(id: String) -> String:
	var row := _row(id)
	return str(row.get_node("text").text) if row != null else ""


func _run_case() -> void:
	var hud: CanvasLayer = _main.hud
	var ms: RefCounted = _main.colony_milestones
	var colony: bool = _case == "colony"
	_check(ms.applies() == colony, "%s: the Colony Run's milestone rules apply only in the colony case" % _case)
	_main.day_store_totals.clear()
	_main.short_term_goals = {}
	_main._sample_day_stores()
	_next_day(40.0, 0.0)
	_refresh()
	_check(_offered().has("pollen_surplus"), "%s: the pollen goal is offered (offered: %s)" % [_case, _offered().keys()])
	if not _offered().has("pollen_surplus"):
		return

	# 1. Under the milestone, with its reward.
	var text := _row_text("pollen_surplus")
	_check(text.contains("Build a pollen surplus") and text.contains("pays 10 pollen"),
		"%s: the goal's line names the outcome and the reward (%s)" % [_case, text])
	_check(hud.goal_shelf.visible and hud.short_term_box.visible, "%s: the goal shows in the open drop-down" % _case)
	if colony:
		_check(not hud.current_goal_label.text.is_empty() and hud.current_goal_label.visible, "colony: the milestone still shows")
		_check(hud.short_term_box.get_index() > hud.current_goal_label.get_index(), "colony: the goal sits under the milestone")
	else:
		_check(hud.current_goal_label.text.is_empty() and hud.long_term_goal_label.text.is_empty(),
			"scenario: the drop-down holds the short-term goal alone")

	# 2. Progress, once the next refresh has worked it out.
	_next_day(40.0, 30.0)
	_refresh()
	text = _row_text("pollen_surplus")
	_check(text.contains("of 1 day"), "%s: the line shows progress (%s)" % [_case, text])

	# 3. Star it; collapsed, the starred goal stays and the open list goes.
	var session: Node = root.get_node("Session")
	_check(_row("pollen_surplus").get_node("star").text == "☆", "%s: the goal's star starts off" % _case)
	_row("pollen_surplus").get_node("star").pressed.emit()
	_check(ms.favourites.has("pollen_surplus"), "%s: pressing the star favourites the goal (%s)" % [_case, ms.favourites])
	_check(_row("pollen_surplus").get_node("star").text == "★", "%s: the star shows as on" % _case)
	session.goals_collapsed = true
	hud._apply_goals_collapsed()
	var kept := false
	for line: Node in hud.favourites_box.get_children():
		kept = kept or str(line.text).contains("Build a pollen surplus")
	_check(kept and hud.favourites_box.visible and not hud.short_term_box.visible,
		"%s: collapsed, the starred goal stays and the list is folded" % _case)
	session.goals_collapsed = false
	hud._apply_goals_collapsed()

	# 4. Dismiss: gone, and nothing replaces it today; back tomorrow.
	var before: int = _offered().size()
	var dismiss: Button = _row("pollen_surplus").get_node("dismiss")
	_check(dismiss.focus_mode == Control.FOCUS_ALL, "%s: Dismiss can be focused from the keyboard" % _case)
	dismiss.pressed.emit()
	_check(not _offered().has("pollen_surplus") and _row("pollen_surplus") == null,
		"%s: Dismiss removes the goal and its line" % _case)
	if _offered().is_empty() and not colony:
		_check(not hud.goal_shelf.visible, "scenario: dismissing the last goal clears the shelf")
	_check(not ms.favourites.has("pollen_surplus"), "%s: a dismissed goal is unstarred" % _case)
	_refresh()
	_check(not _offered().has("pollen_surplus") and _offered().size() == before - 1,
		"%s: nothing replaces it the same day (offered %d -> %d)" % [_case, before, _offered().size()])
	_next_day(40.0, 0.0)
	_refresh()
	_check(_offered().has("pollen_surplus"), "%s: the goal can be offered again the next day" % _case)

	# 5. Finishing: the note, then Dr Gallerin's line, once.
	_next_day(40.0, 30.0)
	_refresh()
	_next_day(40.0, 30.0)
	_refresh()
	_check(_main.short_term_goals.get("finished", {}).has("pollen_surplus"), "%s: a whole day of surplus finishes the goal" % _case)
	text = _row_text("pollen_surplus")
	_check(text.contains("done") and _row("pollen_surplus") != null and _row("pollen_surplus").get_node_or_null("dismiss") == null,
		"%s: the completion note replaces the goal's line (%s)" % [_case, text])
	var panel: CanvasLayer = _main.gallerin_panel
	var line: String = load("res://scripts/guidance_catalogue.gd").goal_completion_line("pollen_surplus")
	_check(not line.is_empty() and panel._last_message == line, "%s: Dr Gallerin said the completion line (%s)" % [_case, panel._last_message])
	panel._last_message = ""
	_main.on_short_term_goals_refreshed([{"id": "pollen_surplus", "label": "Build a pollen surplus", "resource": "pollen", "reward": 10.0}])
	_check(panel._last_message == "", "%s: the line is said once per goal per run" % _case)
	# The note lasts the day it was earned.
	_next_day(0.0, 0.0)
	_main.on_short_term_goals_refreshed([])
	_check(_row("pollen_surplus") == null or not _row_text("pollen_surplus").contains("done"), "%s: the note goes with the day" % _case)


func _challenge_case() -> void:
	_check(_main.challenge_runner.active, "challenge1 is running")
	_main.day_store_totals.clear()
	_main._sample_day_stores()
	_next_day(40.0, 0.0)
	_refresh()
	_check(not _main.hud.short_term_box.visible and _main.hud.short_term_box.get_child_count() == 0,
		"a Challenge's shelf shows no short-term line")
	# Even with a goal in the state, a Challenge's own shelf is left alone.
	_main.short_term_goals = {"offered": {"pollen_surplus": {"id": "pollen_surplus", "label": "Build a pollen surplus",
		"resource": "pollen", "reward": 10.0}}}
	_main.colony_milestones.show_next()
	_check(not _main.hud.goals_button.visible and _main.hud.short_term_box.get_child_count() == 0,
		"a Challenge's shelf is not overwritten by a short-term goal")


func _check(ok: bool, label: String) -> void:
	if ok:
		print("SG3 OK " + label)
	else:
		_failures.append(label)


func _finish() -> void:
	Levels.scenario_override = {}
	root.get_node("Session").starting_level = _old_level
	paused = false
	if _failures.is_empty():
		print("SG3 PASS")
		quit(0)
	else:
		for failure: String in _failures:
			print("SG3 FAIL " + failure)
		quit(1)
