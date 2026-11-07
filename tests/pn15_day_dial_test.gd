extends SceneTree

func _initialize() -> void:
	call_deferred("_check_dial")

func _check_dial() -> void:
	var session = root.get_node("Session")
	var config = root.get_node("GameConfig")
	var dial = load("res://scripts/hud_day_dial.gd").new()
	root.add_child(dial)
	for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
		session.sim_time = config.seconds_per_day * fraction
		if not is_equal_approx(dial.day_fraction(), fposmod(fraction, 1.0)):
			push_error("PN15 FAIL: fraction %s gave %s" % [fraction, dial.day_fraction()])
			quit(1)
			return
	session.pinned_stats = ["day"]
	session.starting_level = 8
	session.menu_pending = false
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	var hud = main.hud
	hud.update_day(1)
	var found = false
	for child in hud.corner_column.get_children():
		if child is Label:
			for nested in child.get_children():
				if nested.get_script() == dial.get_script():
					found = true
	if not found:
		push_error("PN15 FAIL: no dial beside the day label")
		quit(1)
		return
	print("PN15 PASS")
	quit(0)
