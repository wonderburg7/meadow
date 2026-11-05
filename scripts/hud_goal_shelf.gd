extends RefCounted
## The Goals drop-down (GP-1, GP-2, GP-5, SG-3): the shelf under the top-right
## button row and every line on it. Built by hud.gd, which forwards
## set_challenge_goal and set_colony_goals here. Holds no hud or main reference;
## it reports a star or Dismiss press through its own signals, which hud.gd
## re-emits. Reads only Session and UiTheme.

const UiTheme = preload("res://scripts/ui_theme.gd")

## GP-2: a star on a goal line was pressed.
signal star_toggled(id: String)
## SG-3: Dismiss on a short-term goal's line.
signal dismiss_requested(id: String)

## The Challenge goal shelf (UI_PLAN.md section 5): current goal leads,
## the goal just completed is shown struck through underneath it, and a
## compact progress bar appears only for a goal with a countable target.
## See set_challenge_goal.
var goal_shelf: VBoxContainer
var completed_goal_label: RichTextLabel
var current_goal_label: Label
var goal_progress_row: HBoxContainer
var goal_progress_bar: ProgressBar
var goal_progress_label: Label
## GP-1: the Colony Run's Goals drop-down. The Goals button in the second
## row (built by hud.gd, handed to build) folds the shelf (GP-5);
## `colony_goal_entries` holds what set_colony_goals was last given (each
## with an `id`, so GP-2 can star it). Both stay empty in a Challenge.
var goals_button: Button
var long_term_goal_label: Label
var colony_goal_entries: Array = []
## SG-3: the short-term goals' lines, under the milestone. Rebuilt only when
## their entries change, so a focused Dismiss button is not dropped every second.
var short_term_box: VBoxContainer
var _short_term_sig: String = ""
## GP-2: a star on each line (child of the label) and the box that holds the
## starred lines while the drop-down is collapsed. `goal_star_ids` maps a
## label's star to the goal id its line currently shows.
var goal_stars: Array = []
var goal_star_ids: Dictionary = {}
var favourites_box: VBoxContainer
## Maps a goal line to the star that is its child.
var star_for_label: Dictionary = {}

## The goal shelf (UI_PLAN.md section 5): sits directly under the
## top-right button row, anchored and widened the same way -- see
## set_settings_button_width. Hidden outside a Challenge;
## challenge_runner.gd is the only caller of set_challenge_goal.
func build(parent: Node, goals_button_node: Button, offset_top: float, offset_right: float) -> void:
	goals_button = goals_button_node
	goal_shelf = VBoxContainer.new()
	goal_shelf.theme = UiTheme.build_theme()
	goal_shelf.visible = false
	# The shelf overlaps the second top-bar row while a Challenge is active.
	# It is display-only, so every part must pass pointer input through to
	# the controls underneath instead of leaving only their exposed edge live.
	goal_shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_shelf.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	goal_shelf.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	goal_shelf.offset_right = offset_right
	goal_shelf.offset_top = offset_top
	goal_shelf.custom_minimum_size = Vector2(320, 0)
	goal_shelf.add_theme_constant_override("separation", 1)
	parent.add_child(goal_shelf)

	# GP-2: starred lines, shown while the drop-down is collapsed.
	favourites_box = VBoxContainer.new()
	favourites_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	favourites_box.add_theme_constant_override("separation", 1)
	favourites_box.visible = false
	goal_shelf.add_child(favourites_box)

	# GP-1: the long-term line, above the milestone.
	long_term_goal_label = Label.new()
	long_term_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	long_term_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	long_term_goal_label.custom_minimum_size = Vector2(320, 0)
	long_term_goal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	long_term_goal_label.theme_type_variation = "Body"
	long_term_goal_label.visible = false
	UiTheme.bind_color(long_term_goal_label, "font_color", "text_primary")
	goal_shelf.add_child(long_term_goal_label)
	_add_goal_star(long_term_goal_label)

	# Secondary: the goal just completed, struck through and faded, per
	# section 5. A RichTextLabel rather than a Label since Label has no
	# strikethrough of its own -- BBCode's [s] tag is the plain way to get
	# one without hand-drawing a line.
	completed_goal_label = RichTextLabel.new()
	completed_goal_label.bbcode_enabled = true
	completed_goal_label.fit_content = true
	completed_goal_label.scroll_active = false
	completed_goal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	completed_goal_label.custom_minimum_size = Vector2(320, 0)
	# RichTextLabel has no Label-based theme_type_variation to draw on, so
	# this scales directly rather than joining the Small/Body/Heading set.
	completed_goal_label.add_theme_font_size_override("normal_font_size", UiTheme.font_px(12))
	completed_goal_label.add_theme_color_override("default_color", Color(UiTheme.color("warning"), 0.55))
	completed_goal_label.visible = false
	goal_shelf.add_child(completed_goal_label)
	_add_goal_star(completed_goal_label)

	# Primary: the current goal.
	current_goal_label = Label.new()
	current_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	current_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current_goal_label.custom_minimum_size = Vector2(320, 0)
	current_goal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_goal_label.theme_type_variation = "Body"
	UiTheme.bind_color(current_goal_label, "font_color", "warning")
	goal_shelf.add_child(current_goal_label)
	_add_goal_star(current_goal_label)

	# Tertiary: numeric progress, only for a goal with a countable target.
	goal_progress_row = HBoxContainer.new()
	goal_progress_row.visible = false
	goal_progress_row.alignment = BoxContainer.ALIGNMENT_END
	goal_progress_row.add_theme_constant_override("separation", 6)
	goal_progress_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_shelf.add_child(goal_progress_row)

	goal_progress_bar = ProgressBar.new()
	goal_progress_bar.custom_minimum_size = Vector2(160, 8)
	goal_progress_bar.show_percentage = false
	goal_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_progress_row.add_child(goal_progress_bar)

	goal_progress_label = Label.new()
	goal_progress_label.theme_type_variation = "Small"
	UiTheme.bind_color(goal_progress_label, "font_color", "text_secondary")
	goal_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_progress_row.add_child(goal_progress_label)

	# SG-3: short-term goals, under the milestone.
	short_term_box = VBoxContainer.new()
	short_term_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	short_term_box.add_theme_constant_override("separation", 2)
	short_term_box.visible = false
	goal_shelf.add_child(short_term_box)

## Shown under the top-right button row for the length of a Challenge --
## see TUTORIAL_PLAN.md and UI_PLAN.md section 5. `text` is the current
## goal (empty hides the whole shelf). `completed_text`, when given,
## shows the goal just finished, struck through and faded, underneath
## it. `progress_current`/`progress_target` add a compact bar and count,
## shown only when `progress_target` is a real target -- both default to
## -1.0 ("no countable target") rather than 0.0, since 0 is itself a
## valid amount of progress.
func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void:
	# A Challenge's shelf has no header and no long-term line (GP-1).
	colony_goal_entries = []
	goals_button.visible = false
	long_term_goal_label.visible = false
	favourites_box.visible = false
	short_term_box.visible = false
	_short_term_sig = ""
	for star: Variant in goal_stars:
		star.visible = false
	current_goal_label.visible = true
	goal_shelf.visible = not text.is_empty()
	current_goal_label.text = text

	completed_goal_label.visible = not completed_text.is_empty()
	if not completed_text.is_empty():
		completed_goal_label.text = "[s]%s[/s]" % completed_text

	var has_progress: bool = progress_target > 0.0
	goal_progress_row.visible = has_progress
	if has_progress:
		goal_progress_bar.max_value = progress_target
		goal_progress_bar.value = clampf(progress_current, 0.0, progress_target)
		goal_progress_label.text = "%d / %d" % [int(round(progress_current)), int(round(progress_target))]

## GP-1: the Colony Run's Goals drop-down. `entries` are dictionaries of
## `id` ("long_term" or a milestone id), `text`, and `done` (true for the
## last goal met, drawn struck through). Called by colony_milestones.gd
## only; a Challenge keeps set_challenge_goal. Which lines show follows
## Session.goals_collapsed: collapsed leaves the header alone.
func set_colony_goals(entries: Array) -> void:
	colony_goal_entries = entries.duplicate(true)
	var long_text := ""
	var next_text := ""
	var done_text := ""
	var long_id := ""
	var next_id := ""
	var done_id := ""
	for entry: Variant in entries:
		if bool(entry.get("extra", false)) or bool(entry.get("short_term", false)):
			continue
		if str(entry.id) == "long_term":
			long_text = str(entry.text)
			long_id = "long_term"
		elif bool(entry.get("done", false)):
			done_text = str(entry.text)
			done_id = str(entry.id)
		else:
			next_text = str(entry.text)
			next_id = str(entry.id)
	_set_goal_star(long_term_goal_label, long_id, entries)
	_set_goal_star(current_goal_label, next_id, entries)
	_set_goal_star(completed_goal_label, done_id, entries)
	rebuild_favourites(entries)
	long_term_goal_label.text = long_text
	current_goal_label.text = next_text
	completed_goal_label.text = "[s]%s[/s]" % done_text if not done_text.is_empty() else ""
	goal_progress_row.visible = false
	_rebuild_short_term(entries)
	# No entries (a Scenario with no short-term goal on offer): no shelf.
	goals_button.visible = not entries.is_empty()
	goal_shelf.visible = not entries.is_empty()
	apply_collapsed()

func apply_collapsed() -> void:
	if not goals_button.visible:
		return
	goals_button.button_pressed = not Session.goals_collapsed
	var open: bool = not Session.goals_collapsed
	long_term_goal_label.visible = open and not long_term_goal_label.text.is_empty()
	current_goal_label.visible = open and not current_goal_label.text.is_empty()
	completed_goal_label.visible = open and not completed_goal_label.text.is_empty()
	favourites_box.visible = not open and favourites_box.get_child_count() > 0
	short_term_box.visible = open and short_term_box.get_child_count() > 0

## SG-3: one row for each short-term entry -- the outcome with its progress
## and reward, a Dismiss button (an open goal only) and a star. Focusable
## buttons, so the keyboard reaches Dismiss.
func _rebuild_short_term(entries: Array) -> void:
	var lines: Array = []
	for entry: Variant in entries:
		if bool(entry.get("short_term", false)):
			lines.append(entry)
	var sig: String = JSON.stringify(lines)
	if sig == _short_term_sig:
		return
	_short_term_sig = sig
	for child: Variant in short_term_box.get_children():
		short_term_box.remove_child(child)
		child.queue_free()
	for entry: Variant in lines:
		var id: String = str(entry.id)
		var done: bool = bool(entry.get("done", false))
		var row := HBoxContainer.new()
		row.name = "short_term_" + id
		row.alignment = BoxContainer.ALIGNMENT_END
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 4)
		var line := Label.new()
		line.name = "text"
		line.text = str(entry.text)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(190, 0)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.theme_type_variation = "Body"
		UiTheme.bind_color(line, "font_color", "text_secondary" if done else "warning")
		row.add_child(line)
		if not done:
			var dismiss := Button.new()
			dismiss.name = "dismiss"
			dismiss.text = "Dismiss"
			dismiss.theme_type_variation = "Small"
			dismiss.tooltip_text = "Drop this goal. No other is offered until tomorrow."
			dismiss.pressed.connect(func() -> void: dismiss_requested.emit(id))
			row.add_child(dismiss)
		var star := Button.new()
		star.name = "star"
		star.flat = true
		star.text = "★" if bool(entry.get("starred", false)) else "☆"
		star.theme_type_variation = "Small"
		star.custom_minimum_size = Vector2(26, 20)
		star.tooltip_text = "Keep this goal on screen when the Goals list is collapsed."
		star.pressed.connect(func() -> void: star_toggled.emit(id))
		row.add_child(star)
		short_term_box.add_child(row)

## GP-2: a small star as a child of a goal line. Its look and its goal id are
## set by set_colony_goals; pressing it only reports the id.
func _add_goal_star(label: Control) -> void:
	var star := Button.new()
	star.flat = true
	star.text = "☆"
	star.visible = false
	star.focus_mode = Control.FOCUS_NONE
	star.theme_type_variation = "Small"
	star.custom_minimum_size = Vector2(26, 20)
	star.tooltip_text = "Keep this goal on screen when the Goals list is collapsed."
	star.mouse_filter = Control.MOUSE_FILTER_STOP
	star.pressed.connect(func() -> void: _on_goal_star_pressed(star))
	# On the right, where the right-aligned line ends (Dave, 24 Oct 2026),
	# with the line's text kept clear of it by a right margin.
	star.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	star.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var room := StyleBoxEmpty.new()
	room.content_margin_right = star.custom_minimum_size.x
	label.add_theme_stylebox_override("normal", room)
	label.add_child(star)
	goal_stars.append(star)
	goal_star_ids[star] = ""
	star_for_label[label] = star

func _set_goal_star(label: Control, id: String, entries: Array) -> void:
	var star: Button = star_for_label.get(label)
	if star == null:
		return
	goal_star_ids[star] = id
	var starred := false
	for entry: Variant in entries:
		if str(entry.id) == id and bool(entry.get("starred", false)):
			starred = true
	star.text = "★" if starred else "☆"
	star.visible = not id.is_empty() and id != "all_met"

func _on_goal_star_pressed(star: Button) -> void:
	var id: String = str(goal_star_ids.get(star, ""))
	if not id.is_empty():
		star_toggled.emit(id)

## GP-2: the collapsed view -- one line for each starred goal, a met one
## struck through. Rebuilt whenever the entries are, never per frame.
func rebuild_favourites(entries: Array) -> void:
	for child: Variant in favourites_box.get_children():
		favourites_box.remove_child(child)
		child.queue_free()
	for entry: Variant in entries:
		if not bool(entry.get("starred", false)):
			continue
		var line := RichTextLabel.new()
		line.bbcode_enabled = true
		line.fit_content = true
		line.scroll_active = false
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.custom_minimum_size = Vector2(320, 0)
		line.add_theme_font_size_override("normal_font_size", UiTheme.font_px(14))
		var done: bool = bool(entry.get("done", false))
		line.add_theme_color_override("default_color", Color(UiTheme.color("warning"), 0.55 if done else 1.0))
		var text: String = str(entry.text).replace("[", "[lb]")
		line.text = "[right]%s[/right]" % ("[s]%s[/s]" % text if done else text)
		favourites_box.add_child(line)

func toggle_collapsed() -> void:
	Session.goals_collapsed = not Session.goals_collapsed
	Session.save_preferences()
	apply_collapsed()
