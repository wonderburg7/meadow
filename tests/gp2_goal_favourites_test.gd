extends SceneTree
## GP-2 test: favourite goals in the Colony Run's Goals drop-down.
##
## Boots the real Main.tscn into the Colony Run's level row (8) and checks:
## - pressing a line's star stars it (and again unstars it);
## - collapsed, a starred line shows and an unstarred one does not;
## - a met favourite shows struck through, then is dropped and unstarred once
##   the day has changed;
## - the stars come back from the save record after a JSON round trip, a
##   record without them restores none, and unknown ids are dropped.
##
## Run by tests/test_gp2_goal_favourites.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/gp2_goal_favourites_test.gd
## Prints "GP2 PASS" and exits 0, or prints each failure and exits 1.

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
	_session.goals_collapsed = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_booted = true


func _star_for(label: Control) -> Button:
	for star in _main.hud.goal_stars:
		if star.get_parent() == label:
			return star
	return null


func _run() -> void:
	var hud = _main.hud
	var ms = _main.colony_milestones
	_check(ms.applies(), "the Colony Run's rules do not apply")
	ms.favourites.clear()
	ms.show_next()
	_check(hud.favourites_box.get_child_count() == 0, "a line is favourited before any star is pressed")

	# Star the long-term line and the milestone through the real buttons.
	var long_star := _star_for(hud.long_term_goal_label)
	var next_star := _star_for(hud.current_goal_label)
	_check(long_star != null and long_star.visible and long_star.text == "☆", "the long-term star is missing or already on")
	_check(next_star != null and next_star.visible, "the milestone star is missing")
	if long_star == null or next_star == null:
		return
	long_star.pressed.emit()
	_star_for(hud.current_goal_label).pressed.emit()
	_check(ms.favourites == ["long_term", "first_worker"], "favourites are %s" % [ms.favourites])
	_check(_star_for(hud.long_term_goal_label).text == "★", "the long-term star does not show as on")
	_star_for(hud.current_goal_label).pressed.emit()
	_check(ms.favourites == ["long_term"], "pressing again did not unstar: %s" % [ms.favourites])
	_star_for(hud.current_goal_label).pressed.emit()

	# Collapsed: the starred lines show, the ordinary ones do not.
	_session.goals_collapsed = true
	hud._apply_goals_collapsed()
	_check(hud.favourites_box.visible and hud.favourites_box.get_child_count() == 2,
		"collapsed, %d favourite lines show" % hud.favourites_box.get_child_count())
	_check(not hud.long_term_goal_label.visible and not hud.current_goal_label.visible,
		"collapsed, the ordinary lines still show")
	if hud.favourites_box.get_child_count() == 2:
		var milestone_line: String = hud.favourites_box.get_child(1).text
		_check(milestone_line.contains("Raise your first worker"), "the starred milestone line reads '%s'" % milestone_line)
		_check(not milestone_line.contains("[s]"), "an unmet favourite is struck through")

	# Unstarred: nothing shows collapsed.
	ms.toggle_favourite("long_term")
	ms.toggle_favourite("first_worker")
	_check(not hud.favourites_box.visible, "collapsed with no stars, the favourites box shows")
	ms.toggle_favourite("long_term")
	ms.toggle_favourite("first_worker")

	# Met: struck through today, dropped after the day changes.
	ms.met_days["first_worker"] = _main.day
	ms.show_next()
	_check(ms.favourites.has("first_worker"), "a favourite met today was dropped at once")
	var struck := false
	for line in hud.favourites_box.get_children():
		if line.text.contains("[s]") and line.text.contains("Raise your first worker"):
			struck = true
	_check(struck, "a met favourite is not struck through while collapsed")
	_check(hud.favourites_box.get_child_count() == 2, "met today, %d lines show" % hud.favourites_box.get_child_count())
	_main.day += 1
	ms.evaluate()
	_check(not ms.favourites.has("first_worker"), "a met favourite survived the day change")
	_check(ms.favourites == ["long_term"], "favourites after the day change: %s" % [ms.favourites])
	_check(hud.favourites_box.get_child_count() == 1, "after the day change, %d lines show" % hud.favourites_box.get_child_count())

	# Every milestone met: the 'all met' line is not a goal, so it has no star.
	for milestone in ms.MILESTONES:
		ms.met_days[milestone.id] = _main.day
	ms.show_next()
	_check(not _star_for(hud.current_goal_label).visible, "the all-met line shows a star")
	ms.met_days.clear()
	ms.show_next()

	# Save and load.
	ms.favourites = ["long_term", "stable_income"]
	var record: Dictionary = JSON.parse_string(JSON.stringify(ms.save_data()))
	ms.favourites = []
	ms.restore(record)
	_check(ms.favourites == ["long_term", "stable_income"], "stars after a JSON round trip: %s" % [ms.favourites])
	record["favourites"] = ["long_term", "bogus", "stable_income", "long_term"]
	ms.restore(record)
	_check(ms.favourites == ["long_term", "stable_income"], "unknown ids kept: %s" % [ms.favourites])
	var old_record := record.duplicate()
	old_record.erase("favourites")
	ms.restore(old_record)
	_check(ms.favourites.is_empty(), "a record without stars restored %s" % [ms.favourites])
	ms.restore({})
	_check(ms.favourites.is_empty(), "an empty record restored stars")


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("GP2 PASS")
		quit(0)
		return
	for failure in _failures:
		print("GP2 FAIL: " + failure)
	quit(1)
