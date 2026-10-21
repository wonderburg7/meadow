extends SceneTree
## TS-2 test: the HUD's own size overrides follow the typeface too.
##
## At text scale 1 with OpenDyslexic selected, the completed goal line and a
## favourite goal line carry UiTheme.font_px of their base sizes (12 and 14),
## and each corner readout carries UiTheme.font_px of its CORNER_SIZES entry.
## Switching typeface rebuilds the corner, so its labels are new nodes at the
## new size. Run by tests/test_ts2_hud_typeface_size.py:
##   godot --headless --path <repo> --script res://tests/ts2_hud_typeface_size_test.gd
## Prints "TS2 PASS" and exits 0, or each "TS2 FAIL" line and exits 1.

const FACE := "opendyslexic"
const GOAL_BASE := 12
const FAVOURITE_BASE := 14
const CORNER_KEY := "day"


func _initialize() -> void:
	var hud_script: GDScript = load("res://scripts/hud.gd")
	var theme_script: GDScript = load("res://scripts/ui_theme.gd")
	var session: Node = root.get_node("Session")
	var failures := PackedStringArray()

	var saved_pins: Array = session.pinned_stats.duplicate()
	session.text_scale = 1.0
	session.ui_typeface = FACE
	session.pinned_stats = [CORNER_KEY]
	if theme_script.typeface_size_factor(FACE) == 1.0:
		failures.append("%s has no size factor, so this check cannot tell a match from none" % FACE)

	var hud = hud_script.new()
	# Built directly rather than through add_child: _ready needs the main
	# scene (saves panel, main.add_child). The goal shelf and corner only need
	# their own members, which the test supplies as bare controls.
	hud.top_right_bar = VBoxContainer.new()
	hud._build_goal_shelf()
	hud.corner_column = VBoxContainer.new()
	hud.pause_label = Label.new()
	hud.corner_column.add_child(hud.pause_label)
	hud.perf_plot = Control.new()
	hud.corner_column.add_child(hud.perf_plot)
	hud.perf_breakdown = Label.new()
	hud.corner_column.add_child(hud.perf_breakdown)
	hud._rebuild_favourites([{"starred": true, "text": "Test goal", "done": false}])
	hud.corner_texts[CORNER_KEY] = "Day 3"
	hud._refresh_corner()

	var goal_size: int = hud.completed_goal_label.get_theme_font_size("normal_font_size")
	_expect(failures, goal_size == theme_script.font_px(GOAL_BASE),
		"completed goal line is %d px, want font_px(%d) = %d" % [goal_size, GOAL_BASE, theme_script.font_px(GOAL_BASE)])

	var favourite_line: Control = hud.favourites_box.get_child(0) if hud.favourites_box.get_child_count() > 0 else null
	if favourite_line == null:
		failures.append("the favourites box built no goal line")
	else:
		var fav_size: int = favourite_line.get_theme_font_size("normal_font_size")
		_expect(failures, fav_size == theme_script.font_px(FAVOURITE_BASE),
			"favourite goal line is %d px, want font_px(%d) = %d" % [fav_size, FAVOURITE_BASE, theme_script.font_px(FAVOURITE_BASE)])

	var corner_label: Label = _corner_label(hud)
	if corner_label == null:
		failures.append("the corner built no %s readout" % CORNER_KEY)
	else:
		var corner_size: int = corner_label.get_theme_font_size("font_size")
		var corner_base: int = hud_script.CORNER_SIZES[CORNER_KEY]
		_expect(failures, corner_size == theme_script.font_px(corner_base),
			"corner readout is %d px, want font_px(%d) = %d" % [corner_size, corner_base, theme_script.font_px(corner_base)])
		var old_id: int = corner_label.get_instance_id()
		session.ui_typeface = "sans"
		hud._refresh_corner()
		var sans_label: Label = _corner_label(hud)
		_expect(failures, sans_label != null and sans_label.get_instance_id() != old_id,
			"switching typeface did not rebuild the corner")
		if sans_label != null:
			var sans_size: int = sans_label.get_theme_font_size("font_size")
			_expect(failures, sans_size == theme_script.font_px(corner_base) and sans_size != corner_size,
				"corner readout after switching to Standard is %d px, was %d px under %s" % [sans_size, corner_size, FACE])

	hud.free()
	session.ui_typeface = "sans"
	session.text_scale = 1.0
	session.pinned_stats = saved_pins

	if failures.is_empty():
		print("TS2 PASS")
		quit(0)
	else:
		for f in failures:
			print("TS2 FAIL: " + f)
		quit(1)


func _corner_label(hud) -> Label:
	for child in hud.corner_column.get_children():
		# A rebuild queue_frees the old labels, so skip any still waiting to go.
		if child is Label and child != hud.pause_label and not child.is_queued_for_deletion() and (child as Label).text != "":
			return child as Label
	return null


func _expect(failures: PackedStringArray, ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)
