extends CanvasLayer
## The settings window: every tuning control, collapsed behind a cog
## icon in the top-right corner. Was a text button reading "Tuning" --
## renamed and re-iconed 14 Aug 2026, but the file itself keeps its old
## name (debug_panel.gd) since nothing outside this file references the
## class, only the scene tree node it adds itself as.
## Editing a value doesn't change bees/flowers already in the world --
## press "Restart Run" to respawn everything with the new numbers
## (they live in the GameConfig autoload, so they survive the reload).
##
## The settings are grouped into three collapsible collections, each of
## which contains the smaller topic sections. Everything starts closed,
## so opening the panel shows a short menu rather than a wall of numbers.
##
## Every row carries an "i" badge explaining what the number actually
## does, so you can tune without holding the whole model in your head.
## Those badges can be switched off once you know your way around -- see
## the Accessibility section.

# --- preloads -----------------------------------------------------
const UI = preload("res://scripts/ui.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")
const SaveGame = preload("res://scripts/save_game.gd")
const SaveSlots = preload("res://scripts/save_slots.gd")
const Prerequisites = preload("res://scripts/prerequisites.gd")
## The table this window is a view of -- every row's key, label,
## range and tip, plus the read/write and cascade functions.
const Settings = preload("res://scripts/settings_catalogue.gd")
const BeeSurvival = preload("res://scripts/bee_survival.gd")
const Hud = preload("res://scripts/hud.gd")
const Stages = preload("res://scripts/challenge_stages.gd")
const ProblemMessages = preload("res://scripts/problem_messages.gd")
const UiLayout = preload("res://scripts/ui_layout.gd")
const RunAvailabilityPanel = preload("res://scripts/run_availability_panel.gd")

## Text scale re-lays every window, so its -/+ buttons would jump from under
## the pointer on each click; the change applies this long after the last one.
const TEXT_SCALE_APPLY_DELAY := 0.8
## The Challenge stage navigator's goal always takes exactly this many lines.
## It sits above every Game Settings row, and a goal that wrapped to a
## different line count on a stage change moved every row under the pointer
## with no click at all (SC-1, C-72 run 1: + clicks landed on Typeface).
const STAGE_GOAL_LINES := 2

# --- fields -------------------------------------------------------
var _text_scale_timer: Timer
var value_labels: Dictionary = {}
## setting key -> its CheckBox, so the cascade helpers below can refresh
## a row's display when they flip a toggle other than the one clicked.
var toggle_boxes: Dictionary = {}
var panel: PanelContainer
## BS-5: the developer-only rows, rebuilt whenever Developer mode changes,
## and the read-only Run availability table they open (built on first use).
var developer_row: VBoxContainer
## HO-3: the Triggers group, built only while Developer mode is on.
var triggers_box: VBoxContainer
var run_availability_panel: PanelContainer
## Kept so _apply_panel_width() can resize it alongside the panel on
## get_viewport().size_changed, the same pattern gallerin_panel.gd uses.
var panel_scroll: ScrollContainer
var toggle_button: Button
## Greyed out for the length of an active Challenge -- see
## set_save_load_enabled, called by challenge_runner.gd.
var save_btn: Button
var load_btn: Button
## category name -> the VBox holding its rows, so the header button can
## show and hide it
var sections: Dictionary = {}
## category/collection name -> its header Button, so open_to_categories()
## (main_menu.gd's Settings button, UI-M) can expand a section the same
## way a click would, arrow glyph included, without a second copy of the
## open/close logic.
var section_headers: Dictionary = {}
var collection_bodies: Dictionary = {}
var collection_headers: Dictionary = {}
## This row exists only inside the World & start section and is hidden outside
## an active Challenge. Its values remain runner-owned.
var challenge_stage_row: Control
var challenge_stage_label: Label
var challenge_retreat_btn: Button
var challenge_advance_btn: Button
var _challenge_stage_navigation_key: String = ""
## The collapse button promises a two-press sequence; count its presses rather
## than inferring which step it should take from stores the rescue may refill.
var _c2_collapse_presses: int = 0

# --- _ready and construction --------------------------------------
## The five states a plain Godot Button actually looks up -- see
## colony_panel.gd's identical helper.
func _style_button(button: BaseButton) -> BaseButton:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))
	return button

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 10   # draw on top of the world
	# so main_menu.gd's Settings button (UI-M) can reach open_to_categories()
	# without the two needing to know about each other directly -- same
	# pattern as "main_menu" group used the other way by _on_main_menu_pressed().
	add_to_group("debug_panel")
	_text_scale_timer = Timer.new()
	_text_scale_timer.one_shot = true
	_text_scale_timer.wait_time = TEXT_SCALE_APPLY_DELAY
	_text_scale_timer.timeout.connect(func() -> void: UiTheme.refresh_for_setting("text_scale"))
	add_child(_text_scale_timer)
	Session.run_reset.connect(collapse_all)
	Session.run_reset.connect(func() -> void: _c2_collapse_presses = 0)

	# Syncs Godot's own tooltip timer to whatever Session carried in from
	# the last time it was changed -- harmless while Session always
	# starts at the default (0.5s, which matches Godot's own default
	# anyway), and ready for once player_profile.gd persists it.
	ProjectSettings.set("gui/timers/tooltip_delay_sec", Session.tooltip_delay)

	var vp := get_viewport().get_visible_rect().size

	# Anchored to the top-right corner so it tracks window resizing.
	# hud.gd keeps this width clear for us, so the two bars can't overlap.
	toggle_button = Button.new()
	_style_button(toggle_button)
	# A plain cog glyph rather than a loaded texture, consistent with the
	# rest of the game's placeholder-art approach of drawing everything
	# rather than importing assets. Sized up with its own font override
	# since the button itself is now icon-sized rather than text-width.
	toggle_button.text = "⚙"
	toggle_button.theme = UiTheme.build_theme()
	toggle_button.theme_type_variation = "Heading"
	# Match HUD's primary top-right controls so the two anchored groups form
	# one deliberate bar rather than visibly different rows.
	toggle_button.custom_minimum_size = Vector2(Hud.TOP_BAR_BUTTON_WIDTH, Hud.TOP_BAR_CONTROL_HEIGHT)
	toggle_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toggle_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	toggle_button.offset_right = -Hud.TOP_BAR_BUTTON_GAP
	toggle_button.offset_top = 8  # fixed-inset
	toggle_button.tooltip_text = "Open the settings window. Changing a value here affects bees and flowers created from then on -- press Restart Run to rebuild the whole world with the new numbers."
	toggle_button.pressed.connect(_toggle_panel)
	add_child(toggle_button)

	# hud.gd's top-right button row keeps clear of however wide this cog
	# actually is, rather than a fixed reserve -- see hud.gd's
	# set_settings_button_width. `resized` covers every future change
	# (e.g. a font-size setting making the glyph bigger); the deferred
	# call covers the first layout pass, since `resized` only fires on a
	# genuine change and the button's very first size might already be
	# whatever custom_minimum_size says.
	toggle_button.resized.connect(_report_settings_button_width)
	call_deferred("_report_settings_button_width")

	# Built once, here, rather than inside _report_settings_button_width --
	# that function's job is only to tell hud.gd how wide the cog is, and
	# it fires again on every resize. Building the panel there too used to
	# rebuild (and re-add, orphaning the old one) the whole settings window
	# every time the window was resized, on top of using `vp` from outside
	# its own scope, which failed to compile at all.
	panel = PanelContainer.new()
	panel.theme = UiTheme.build_theme()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_right = -Hud.TOP_BAR_BUTTON_GAP
	# Clears the HUD's full two-row button bar (not just this cog's own
	# single-row height) plus a gap the same size as the buttons' own
	# horizontal gap -- previously a flat 40, which only cleared row 1 and
	# left the panel opening underneath row 2 (Dave's 29 Aug report).
	panel.offset_top = 8 + Hud.TOP_BAR_CONTROL_HEIGHT * 2.0 + Hud.TOP_BAR_ROW_SEPARATION + Hud.TOP_BAR_BUTTON_GAP
	# UiLayout.settings_window_width() owns this rectangle's width -- up to
	# a quarter of the viewport, floored at the window's old fixed width
	# (Dave: "up to 25%", UI-X-1). Re-applied on resize by _apply_panel_width.
	var panel_width := UiLayout.settings_window_width(vp.x)
	panel.custom_minimum_size = Vector2(panel_width, 0)
	panel.visible = false
	add_child(panel)

	panel_scroll = ScrollContainer.new()
	panel_scroll.custom_minimum_size = Vector2(panel_width, min(560.0, vp.y - 80.0))
	# A row's info badge (UI.info_badge) is invisible by default
	# (Session.show_info_badges); the panel's width already accounts for
	# its footprint once shown, but disabling horizontal scroll is a cheap
	# second guard so a slightly-too-long label clips rather than
	# stranding a row's toggle off to the right behind a scrollbar
	# (Dave's 29 Aug report on "Show info icons").
	panel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(panel_scroll)

	# The panel's width includes room for optional info badges; keep the
	# rows a deliberate small distance from the scrollbar instead of
	# letting that spare width read as accidental slack when badges are
	# hidden.
	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_right", 6)
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_scroll.add_child(content_margin)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.add_child(column)

	_build_actions(column)

	# Collections and their topic sections both start closed. The first
	# click chooses an area of the game; the second opens the relevant rows.
	for collection in Settings.COLLECTIONS:
		column.add_child(_make_collection(
			collection.name, collection.categories, false
		))
	collapse_all()

	get_viewport().size_changed.connect(_apply_panel_width)

## Keeps the panel at UiLayout.settings_window_width() of whatever the
## viewport resizes to, the same pattern gallerin_panel.gd's _apply_layout
## uses for its own bubble.
func _apply_panel_width() -> void:
	var width := UiLayout.settings_window_width(get_viewport().get_visible_rect().size.x)
	panel.custom_minimum_size.x = width
	panel_scroll.custom_minimum_size.x = width

func _report_settings_button_width() -> void:
	for hud in get_tree().get_nodes_in_group("huds"):
		if is_instance_valid(hud) and hud.has_method("set_settings_button_width"):
			hud.set_settings_button_width(toggle_button.size.x)

# --- collections and sections -------------------------------------
func _rows_in(category: String) -> Array:
	var found: Array = []
	for entry in Settings.TUNABLES:
		if entry.get("category", "") != category:
			continue
		# star rows aren't settings at all -- they toggle whether
		# something appears in the corner, which lives in
		# Session.pinned_stats rather than in GameConfig or Session
		# directly, so the guard below doesn't apply to them
		if entry.get("star", false):
			found.append(entry)
			continue
		# guard against a renamed setting leaving a dead row behind --
		# that used to crash the panel on startup with a confusing error
		if Settings.setting_get(entry.key) == null:
			push_warning("Settings window refers to a missing setting: %s" % entry.key)
			continue
		found.append(entry)
	return found

## The wide first-level dropdown. Its body contains the existing topic
## dropdowns so the player never has to scan all settings at once.
func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 0)

	var body := VBoxContainer.new()
	body.visible = start_open

	var header := Button.new()
	_style_button(header)
	header.text = "%s  %s" % ["▾" if start_open else "▸", collection_name]
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.custom_minimum_size = Vector2(0, 30)
	header.theme_type_variation = "Body"
	header.pressed.connect(func(): _set_open(header, body, collection_name, not body.visible))
	wrapper.add_child(header)
	wrapper.add_child(body)

	collection_bodies[collection_name] = body
	collection_headers[collection_name] = header

	for category in categories:
		var rows := _rows_in(category)
		if rows.is_empty() and category != "Controls":
			continue
		body.add_child(_make_section(category, rows, false))

	return wrapper

## Shared by every collapsible header (collection or section) so a click
## and a programmatic open (open_to_categories()) update the same two
## things -- visibility and the header's arrow glyph -- the same way.
func _set_open(header: Button, body: Control, label: String, open: bool) -> void:
	body.visible = open
	header.text = "%s  %s" % ["▾" if open else "▸", label]

## Expands the named collection(s) and, within them, the named category
## section(s) -- e.g. ["Accessibility", "Appearance"] -- and shows the
## panel. Lets main_menu.gd's Settings button (UI-M) reuse this panel's
## existing Accessibility/Appearance rows instead of duplicating them.
func open_to_categories(categories: Array) -> void:
	_apply_layer_for_context()
	panel.visible = true
	for collection in Settings.COLLECTIONS:
		var categories_here: Array = collection.categories
		var contains_target := false
		for cat in categories:
			if categories_here.has(cat):
				contains_target = true
				break
		if contains_target and collection_headers.has(collection.name):
			_set_open(collection_headers[collection.name], collection_bodies[collection.name], collection.name, true)
	for cat in categories:
		if section_headers.has(cat):
			_set_open(section_headers[cat], sections[cat], cat, true)

## Closes every collection and every topic section, returning the window
## to its built state. Called when a run starts, so an expansion left over
## from the pre-run menu's Settings button (open_to_categories) does not
## follow the player into the game (Dave, 8 Sep 2026).
func collapse_all() -> void:
	for key in collection_headers:
		_set_open(collection_headers[key], collection_bodies[key], key, false)
	for key in section_headers:
		_set_open(section_headers[key], sections[key], key, false)

## A clickable heading with its rows underneath, hidden until the heading
## is clicked.
func _make_section(category: String, entries: Array, start_open: bool) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 0)

	var body := VBoxContainer.new()
	body.visible = start_open

	var header := Button.new()
	_style_button(header)
	header.text = "%s  %s" % ["▾" if start_open else "▸", category]
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.custom_minimum_size = Vector2(0, 24)
	header.theme_type_variation = "Small"
	header.pressed.connect(func(): _set_open(header, body, category, not body.visible))
	wrapper.add_child(header)
	wrapper.add_child(body)
	section_headers[category] = header

	var ordered_entries := []
	# Preserve the authored order inside each group while putting the most
	# frequently changed on/off controls first and passive readout stars last.
	for entry in entries:
		if entry.get("toggle", false):
			ordered_entries.append(entry)
	for entry in entries:
		if not entry.get("toggle", false) and not entry.get("star", false):
			ordered_entries.append(entry)
	for entry in entries:
		if entry.get("star", false):
			ordered_entries.append(entry)
	for entry in ordered_entries:
		if entry.get("star", false):
			body.add_child(_make_star_row(entry))
		elif entry.get("toggle", false):
			body.add_child(_make_toggle_row(entry))
		elif entry.has("options"):
			body.add_child(_make_options_row(entry))
		else:
			body.add_child(_make_row(entry))
	if category == "World & start":
		body.add_child(_make_challenge_stage_navigation())

	# The controls used to be printed permanently in the top-left corner.
	# They are now a real topic rather than an appendix to Appearance.
	if category == "Controls":
		body.add_child(_make_controls_help())

	# Keep this action beside the seasonal settings instead of floating
	# above all three collections.
	if category == "Seasons & health":
		body.add_child(HSeparator.new())
		body.add_child(_make_winter_action())

	sections[category] = body
	return wrapper

# --- the Challenge stage navigator --------------------------------
## Developer-only navigation for a live Challenge. The runner exposes only
## read methods and transition methods, so this view cannot mutate stage
## state directly. It stays in this section rather than the general Triggers
## group because it describes the active world's current Challenge state.
func _make_challenge_stage_navigation() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	# Both this row and the with_info() wrapper below must expand, as in
	# _add_action_row(). Without it the row sits at its minimum width, the
	# autowrap label's minimum is about zero, and the stage name wrapped one
	# letter per line between two stretched arrows (C-49, 12 and 17 Sep
	# 2026). scenario_actions.gd's no_collapsed_controls now fails on it.
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	challenge_retreat_btn = Button.new()
	_style_button(challenge_retreat_btn)
	challenge_retreat_btn.text = "◀"
	challenge_retreat_btn.custom_minimum_size = Vector2(28, 24)
	challenge_retreat_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	challenge_retreat_btn.pressed.connect(_on_challenge_retreat_pressed)
	row.add_child(challenge_retreat_btn)

	challenge_stage_label = Label.new()
	challenge_stage_label.theme_type_variation = "Small"
	challenge_stage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	challenge_stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# A fixed height whatever the goal says (STAGE_GOAL_LINES): a longer goal
	# ends in an ellipsis and the full text is in the tooltip. The reserve is
	# recomputed on every theme change because text scale and typeface
	# change the line height in place; the inequality guard keeps a
	# same-size refresh from re-laying the window.
	challenge_stage_label.max_lines_visible = STAGE_GOAL_LINES
	challenge_stage_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	challenge_stage_label.mouse_filter = Control.MOUSE_FILTER_PASS
	var reserve_goal_lines := func() -> void:
		var label := challenge_stage_label
		var font_size := label.get_theme_font_size("font_size")
		var line_height := label.get_theme_font("font").get_height(font_size)
		var height: float = ceil(line_height * STAGE_GOAL_LINES
			+ label.get_theme_constant("line_spacing") * (STAGE_GOAL_LINES - 1)
			+ label.get_theme_stylebox("normal").get_minimum_size().y)
		if label.custom_minimum_size.y != height:
			label.custom_minimum_size.y = height
	challenge_stage_label.ready.connect(reserve_goal_lines)
	challenge_stage_label.theme_changed.connect(reserve_goal_lines)
	row.add_child(challenge_stage_label)

	challenge_advance_btn = Button.new()
	_style_button(challenge_advance_btn)
	challenge_advance_btn.text = "▶"
	challenge_advance_btn.custom_minimum_size = Vector2(28, 24)
	challenge_advance_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	challenge_advance_btn.pressed.connect(_on_challenge_advance_pressed)
	row.add_child(challenge_advance_btn)

	var wrapped_row := UI.with_info(row, "Debug only: step through an active Challenge's stages. Going back rebuilds the stage's gates, prompts and marker, but does not undo the hive, cells or bees; a goal already satisfied may advance again immediately.")
	wrapped_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapped_row.visible = false
	challenge_stage_row = wrapped_row
	return wrapped_row

func _process(_delta: float) -> void:
	_refresh_challenge_stage_navigation()

func _refresh_challenge_stage_navigation() -> void:
	if challenge_stage_row == null:
		return
	var worlds := get_tree().get_nodes_in_group("world")
	var runner = null if worlds.is_empty() else worlds[0].challenge_runner
	var active: bool = runner != null and runner.active
	var stage_id: String = runner.current_stage_id() if active else ""
	var stage_goal: String = runner.current_stage_goal_text() if active else ""
	var key: String = "%s|%s|%s|%s" % [active, stage_id, stage_goal, runner.can_debug_retreat_stage() if active else false]
	if key == _challenge_stage_navigation_key:
		return
	_challenge_stage_navigation_key = key
	challenge_stage_row.visible = active
	if not active:
		return
	challenge_stage_label.text = "%s — %s" % [stage_id, stage_goal]
	challenge_stage_label.tooltip_text = challenge_stage_label.text
	challenge_retreat_btn.disabled = not runner.can_debug_retreat_stage()
	challenge_advance_btn.disabled = not runner.can_debug_advance_stage()

# --- the controls help --------------------------------------------
## The controls used to be printed permanently in the top-left corner, and
## the text carried its own "Controls" heading and blank lines between
## groups. The section header above it already says Controls, and the blank
## lines left the list looking gappy rather than grouped (Dave, 12 Sep
## 2026), so this is one unbroken list in reading order.
func _make_controls_help() -> Control:
	var help := Label.new()
	help.name = "ControlsHelp"
	help.theme_type_variation = "Small"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The list's pitch is its font size plus 2px (C-53). Munro's line height
	# is ~1.2x its size (24px at 20px, text scale 1.5), and Godot's default
	# Label line_spacing adds 3px more, which read as a gap between every
	# item. UI-X-1 measured this once at ready; the spacing then went stale
	# whenever text scale changed, because UiTheme.refresh() resizes the
	# font in place (23px apart at 1.5, measured headlessly 19 Sep 2026).
	# So it is recomputed on every theme change, from the font Label will
	# actually draw with. The inequality guard matters: setting an override
	# is itself a theme change, and would otherwise recurse.
	var tighten := func() -> void:
		var font_size := help.get_theme_font_size("font_size")
		var height := int(help.get_theme_font("font").get_height(font_size))
		var spacing := font_size + 2 - height
		if not help.has_theme_constant_override("line_spacing") or help.get_theme_constant("line_spacing") != spacing:
			help.add_theme_constant_override("line_spacing", spacing)
	help.ready.connect(tighten)
	help.theme_changed.connect(tighten)
	help.text = """Arrow keys — pan the view
Mouse wheel — zoom in and out
Middle mouse drag — pan the view
Tab — switch between meadow and hive
Space — pause
C — colony window
N — nursery window
G — foraging window
O — cycle the comb overlay
F — frame everything in view
Ctrl+1..9 — save the selection as a group
1..9 — select that group again
Ctrl+Z — undo the last cell reservation
Left click or drag — select bees
Ctrl+click — add comb or soil to a selection
Left click a flower, tree or raised area — see what it is
Left click a comb cell — inspect and set it
Left click exposed soil — mark it for digging
Right click a flower — send the selection to collect there
Right click the ground — move the selection there
Click a warning in the corner to select what it is about.
Escape — close the skill tree"""
	return help

# --- the action buttons -------------------------------------------
## Restart, save/load and the main menu, kept at the top of the panel so
## they don't drift below a growing list of settings, with the developer
## Triggers group underneath them.
##
## Every long-labelled button gets its own full-width row. A button's
## minimum width is its text width, and the ScrollContainer above has
## horizontal scrolling disabled, so three long trigger buttons sharing one
## HBoxContainer used to set the whole window's minimum width -- the panel
## opened about 915px wide on a 1920px screen instead of the panel's own width
## (Dave, 12 Sep 2026). One button per row keeps the widest label, not the
## sum of three, as the constraint.
func _build_actions(column: VBoxContainer) -> void:
	var restart_btn := Button.new()
	_style_button(restart_btn)
	restart_btn.text = "Restart Run"
	restart_btn.pressed.connect(_on_restart_pressed)
	_add_action_row(column, restart_btn, "Rebuild the meadow and hive from scratch using the current values above, at whichever starting stage you last chose. Everything in progress is lost; the tuning numbers themselves are kept.")

	var menu_btn := Button.new()
	_style_button(menu_btn)
	menu_btn.text = "Return to Main Menu"
	menu_btn.pressed.connect(_on_main_menu_pressed)
	_add_action_row(column, menu_btn, "Pause and go back to the main menu, where you can start a Challenge or a Scenario. You can also close the menu again and carry on with the run you have.")

	# Save and Load keep their shared row: both labels are short enough that
	# the pair still fits inside the panel's width.
	var save_row := HBoxContainer.new()
	save_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(save_row)

	save_btn = Button.new()
	_style_button(save_btn)
	save_btn.text = "Save run"
	save_btn.pressed.connect(_on_save_pressed)
	save_row.add_child(UI.with_info(save_btn, "Write the current run to disk: the comb and everything in it, every bee and what it is doing, the meadow, the weather and the clock. There is one save slot, so saving again overwrites it."))

	load_btn = Button.new()
	_style_button(load_btn)
	load_btn.text = "Saves…"
	load_btn.pressed.connect(_on_load_pressed)
	save_row.add_child(UI.with_info(load_btn, "Open the Saves window: save this run by name, load a save or one of its checkpoints, or delete one."))

	developer_row = VBoxContainer.new()
	developer_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(developer_row)

	# One labelled home for buttons that force a state the simulation
	# reaches only rarely on its own. HO-3: built only with Developer mode on
	# (_refresh_developer_row fills and empties it).
	triggers_box = VBoxContainer.new()
	triggers_box.add_theme_constant_override("separation", 0)
	triggers_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(triggers_box)
	_refresh_developer_row()

	column.add_child(HSeparator.new())

## One action button on its own row, filling the window's width with its
## info badge pinned to the right. The button expands rather than sitting at
## its text width so a row of one does not read as a stray short button.
## HO-3: the Triggers group exists only with Developer mode on.
func _rebuild_triggers() -> void:
	for child in triggers_box.get_children():
		triggers_box.remove_child(child)
		child.queue_free()
	if not Session.developer_mode:
		return
	var triggers_header := Label.new()
	triggers_header.text = "Triggers"
	triggers_header.theme_type_variation = "Small"
	triggers_box.add_child(UI.with_info(triggers_header, "Debug only: every button in this group forces a simulation state the world otherwise reaches rarely or not at all, so a behaviour that depends on it can be watched on demand instead of waited for."))

	var stage_trigger_btn := Button.new()
	_style_button(stage_trigger_btn)
	stage_trigger_btn.text = "Advance Challenge stage"
	stage_trigger_btn.pressed.connect(_on_challenge_advance_pressed)
	_add_action_row(triggers_box, stage_trigger_btn, "Debug only: advance an active Challenge through its ordinary stage-transition path, even when the current goal's mechanic is still a placeholder.")

	var fire_warnings_btn := Button.new()
	_style_button(fire_warnings_btn)
	fire_warnings_btn.text = "Fire test warnings"
	fire_warnings_btn.pressed.connect(_on_fire_test_warnings_pressed)
	_add_action_row(triggers_box, fire_warnings_btn, "Debug only: fires an epitaph, a crab-spider-escape warning eight seconds later and a save-style confirmation two seconds after that, so the warning banner's arbitration between producers can be watched without waiting for the simulation to collide them on its own.")

	var c2_collapse_btn := Button.new()
	_style_button(c2_collapse_btn)
	c2_collapse_btn.text = "Force Challenge 2 collapse"
	c2_collapse_btn.pressed.connect(_on_force_c2_collapse_pressed)
	_add_action_row(triggers_box, c2_collapse_btn, "Debug only, and only during an active Challenge 2 run: withdraws nectar from the hive. One press drops the stores just below the rescue threshold; a second press drops them below the failure floor, so both the one-time rescue and the checkpoint restore in challenge_runner.gd::_check_c2_failure() can be reached from one run.")

	var end_run_btn := Button.new()
	_style_button(end_run_btn)
	end_run_btn.text = "End the run"
	end_run_btn.pressed.connect(_on_end_run_pressed)
	_add_action_row(triggers_box, end_run_btn, "Debug only: kills the queen, so the run ends at \"The queen is dead\" exactly as a real death does. Does nothing in a scenario run.")

func _on_end_run_pressed() -> void:
	var worlds := get_tree().get_nodes_in_group("world")
	if worlds.is_empty():
		return
	var world = worlds[0]
	if world.scenario_active or not is_instance_valid(world.queen):
		return
	BeeSurvival.die(world.queen, "debug")

## BS-5: the Developer mode rows. With it off the row is empty -- the
## button is absent, not disabled -- and an open table closes.
func _refresh_developer_row() -> void:
	if triggers_box != null:
		_rebuild_triggers()
	for child in developer_row.get_children():
		developer_row.remove_child(child)
		child.queue_free()
	var button := _make_run_availability_button()
	if button != null:
		_add_action_row(developer_row, button, "Developer mode: a read-only table of this run's skills, the roles they unlock and the features they need -- which the run starts owning, leaves to the skill tree or does not offer, and why.")
	elif run_availability_panel != null:
		run_availability_panel.hide()

## Null unless Developer mode is on; tests/source_checks.py fails this if
## the guard goes.
func _make_run_availability_button() -> Button:
	if not Session.developer_mode:
		return null
	var button := Button.new()
	_style_button(button)
	button.text = "Run availability"
	button.pressed.connect(_on_run_availability_pressed)
	return button

func _on_run_availability_pressed() -> void:
	if run_availability_panel == null:
		run_availability_panel = RunAvailabilityPanel.new()
		add_child(run_availability_panel)
		# It belongs to the settings window: closing that closes it too.
		panel.visibility_changed.connect(func():
			if not panel.visible:
				run_availability_panel.hide())
	run_availability_panel.open()

func _add_action_row(parent: Control, button: Button, tip: String) -> void:
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UI.with_info(button, tip)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)

func _make_winter_action() -> Control:
	var row := HBoxContainer.new()
	var winter_btn := Button.new()
	_style_button(winter_btn)
	winter_btn.text = "Bring on winter"
	winter_btn.pressed.connect(_on_winter_pressed)
	row.add_child(UI.with_info(winter_btn, "Schedule a winter for a set number of days from now (see \"Winter in days\" in the Winter section). A forecast opens in the Winter window on the left showing what the colony will need to last it out and how far short it currently is. The figure moves as the colony grows, which is the point: every bee you add is another mouth to feed through it."))
	return row

## Starts the countdown on the running world. Winter is scheduled
## relative to the current day rather than a fixed date, so pressing this
## on day 40 gives the same run-up as pressing it on day 4.
func _on_winter_pressed() -> void:
	var worlds := get_tree().get_nodes_in_group("world")
	if worlds.is_empty():
		return
	worlds[0].begin_winter_countdown()

func _on_challenge_advance_pressed() -> void:
	var worlds := get_tree().get_nodes_in_group("world")
	if worlds.is_empty():
		return
	worlds[0].challenge_runner.debug_advance_stage()
	_refresh_challenge_stage_navigation()

func _on_challenge_retreat_pressed() -> void:
	var worlds := get_tree().get_nodes_in_group("world")
	if worlds.is_empty():
		return
	worlds[0].challenge_runner.debug_retreat_stage()
	_refresh_challenge_stage_navigation()

## Fires the same three warning-banner shapes the simulation only produces
## by chance, so the throttle in hud.gd::show_warning can be watched
## arbitrating between two keyed producers and letting an unkeyed
## confirmation through unaffected. One SceneTreeTimer chain, not a
## per-frame state machine: the epitaph fires immediately, the escape
## chains eight seconds later, and the confirmation chains a further two
## seconds after that (t=0, t=+8s, t=+10s).
func _on_fire_test_warnings_pressed() -> void:
	var worlds := get_tree().get_nodes_in_group("world")
	if worlds.is_empty():
		return
	var hud = worlds[0].hud
	var bees := get_tree().get_nodes_in_group("bees")
	if bees.is_empty():
		return
	var bee: Node2D = bees[0]

	hud.show_warning(
		ProblemMessages.epitaph(bee.bee_name, "starvation", bee.bee_fact),
		"epitaph", GameConfig.epitaph_min_gap
	)
	get_tree().create_timer(8.0).timeout.connect(func() -> void:
		if not is_instance_valid(hud):
			return
		hud.show_warning(
			ProblemMessages.crab_spider_escape(bee.bee_name),
			"crab_spider_escape", GameConfig.crab_spider_escape_min_gap
		)
		get_tree().create_timer(2.0).timeout.connect(func() -> void:
			if is_instance_valid(hud):
				hud.show_warning("Run saved.")
		)
	)

## Withdraws nectar via the hive's own take() API (never writes cell
## amounts directly) so challenge_runner.gd::_check_c2_failure(), which
## polls main.hive.total("nectar") every frame, sees the drop and fires
## on its own. The first press aims for the rescue threshold; every later
## press aims for the failure floor, so the button's two-press tooltip remains
## true even though the rescue refills the stores after the first press.
func _on_force_c2_collapse_pressed() -> void:
	var worlds := get_tree().get_nodes_in_group("world")
	if worlds.is_empty():
		return
	var world = worlds[0]
	if Session.starting_level != 2 or not world.challenge_runner.active:
		return
	var hive = world.hive
	var nectar: float = hive.total("nectar")
	_c2_collapse_presses += 1
	var target: float = Stages.C2_RESCUE_THRESHOLD - 1.0 if _c2_collapse_presses == 1 else Stages.C2_FAILURE_FLOOR - 1.0
	if nectar > target:
		hive.take("nectar", nectar - target)

# --- save and load ------------------------------------------------
## Ordinary player save/load doesn't record Challenge stage/gate/prompt
## state (see challenge_runner.gd), so it's disabled for the length of an
## active Challenge -- tutorial_checkpoint.gd covers Challenge-internal
## rollback instead. Godot doesn't fire `pressed` on a disabled button, so
## the handlers below don't need their own guard on top of this.
func set_save_load_enabled(enabled: bool) -> void:
	save_btn.disabled = not enabled
	load_btn.disabled = not enabled

## Lets another panel (hud.gd's queen panel) change a settings-window
## toggle without writing GameConfig/Session itself -- keeps the write
## inside this allowlisted file and keeps the settings window's own
## checkbox in sync if it's currently open.
func set_toggle(key: String, value: bool) -> void:
	Settings.setting_set(key, value)
	if toggle_boxes.has(key):
		toggle_boxes[key].set_pressed_no_signal(value)

func _on_save_pressed() -> void:
	var worlds := get_tree().get_nodes_in_group("world")
	if worlds.is_empty():
		push_warning("No world to save")
		return
	worlds[0].save_run()

## Loading goes through a scene reload rather than trying to mutate the
## running world in place: the saved tuning values decide the shape of
## the hive, so the world has to be built with them from the start. The
## flag tells the fresh scene to replay the save over itself.
func _on_load_pressed() -> void:
	# SV-3, SA-1: the Saves window (SV-2) is where a save is chosen, so
	# "Saves…" opens it -- in a sandbox run and on the main menu, where the
	# window raises itself above the menu (saves_panel.gd::open). Only a
	# Challenge in progress keeps the older behaviour below, loading the
	# most recently saved named slot: a Challenge keeps its own checkpoints.
	var worlds := get_tree().get_nodes_in_group("world")
	var menus := get_tree().get_nodes_in_group("main_menu")
	var menu_visible: bool = not menus.is_empty() and menus[0].visible
	if not worlds.is_empty() and (menu_visible or not (Session.starting_level in [1, 2])):
		var saves_panel = worlds[0].hud.saves_panel
		if saves_panel != null:
			panel.visible = false
			if not saves_panel.is_open():
				worlds[0].year_winter._toggle_panel(saves_panel)
			return
	var slot := SaveSlots.latest_named()
	var path := SaveSlots.slot_path(slot["slug"]) if not slot.is_empty() else ""
	var data := SaveGame.read(path) if path != "" else {}
	if data.is_empty():
		push_warning("There is no save to load")
		return
	SaveGame.apply_settings(data)
	Session.run_name = str(slot["name"])
	Session.load_path = path
	Session.load_pending = true
	Session.menu_pending = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

# --- showing and hiding the panel ---------------------------------
func _toggle_panel() -> void:
	_apply_layer_for_context()
	panel.visible = not panel.visible
	# The cog itself doesn't change state -- the panel opening or closing
	# is feedback enough, the way it wasn't when this button was just a
	# label reading "Tuning".

## Normally draws just above the HUD (layer 10, below gallerin/main_menu/
## game_over) -- but main_menu.gd's own Settings button (UI-M) opens this
## same panel while the menu itself is visible, and the menu's CanvasLayer
## (20) sits above this one, so the panel used to open invisibly behind
## the menu's own background (Dave's 29 Aug report). Raised above the menu
## only while it is actually visible, so the normal in-run ordering is
## unaffected.
func _apply_layer_for_context() -> void:
	var menus := get_tree().get_nodes_in_group("main_menu")
	var menu_visible: bool = not menus.is_empty() and menus[0].visible
	layer = 21 if menu_visible else 10

# --- building a settings row --------------------------------------
func _make_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var lbl := Label.new()
	lbl.theme_type_variation = "Small"
	lbl.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0)
	lbl.text = "%s: %s" % [entry.label, _format_value(Settings.setting_get(entry.key))]
	value_labels[entry.key] = lbl
	row.add_child(lbl)

	row.add_child(UI.info_badge(entry.tip))
	row.add_spacer(false)

	var controls := _make_control_slot()
	row.add_child(controls)

	var minus := Button.new()
	_style_button(minus)
	minus.text = "-"
	minus.custom_minimum_size = Vector2(26, 24)
	_wire_repeat_button(minus, entry, -1.0)
	controls.add_child(minus)

	var plus := Button.new()
	_style_button(plus)
	plus.text = "+"
	plus.custom_minimum_size = Vector2(26, 24)
	_wire_repeat_button(plus, entry, 1.0)
	controls.add_child(plus)

	return row

## Repeat tuning for held -/+ buttons: how long to wait before the first
## repeat, the fastest interval it accelerates to, and how long it takes
## to get there. Lets a large-range setting (Flowers, Cell capacity...)
## be held down rather than clicked dozens of times.
const REPEAT_INITIAL_DELAY := 0.4
const REPEAT_MIN_INTERVAL := 0.03
const REPEAT_ACCEL_SECONDS := 2.0
const ROW_LABEL_WIDTH := 140.0
const ROW_CONTROL_WIDTH := 55.0

func _make_control_slot() -> HBoxContainer:
	var controls := HBoxContainer.new()
	controls.custom_minimum_size = Vector2(ROW_CONTROL_WIDTH, 0)
	controls.alignment = BoxContainer.ALIGNMENT_END
	controls.add_theme_constant_override("separation", 3)
	return controls

## Wires a +/- button so a single click steps once as before, but holding
## it down repeats the step, speeding up the longer it's held.
func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	button.add_child(timer)
	# Boxed in a single-element array rather than a plain var: lambdas
	# capture by value, so a bare `var start_ms` reassigned inside the
	# button_down lambda below would never be seen by schedule_next's own
	# copy -- the repeat would always compute held_seconds from a stale
	# start time. An array's contents are shared across every lambda that
	# captures it, so mutating start_ms[0] is visible to all of them.
	var start_ms := [0]

	var schedule_next := func():
		var held_seconds: float = (Time.get_ticks_msec() - start_ms[0]) / 1000.0
		var t: float = clamp(held_seconds / REPEAT_ACCEL_SECONDS, 0.0, 1.0)
		timer.start(lerp(REPEAT_INITIAL_DELAY, REPEAT_MIN_INTERVAL, t))

	timer.timeout.connect(func():
		_adjust(entry, direction * entry.step)
		schedule_next.call()
	)
	button.pressed.connect(func(): _adjust(entry, direction * entry.step))
	button.button_down.connect(func():
		start_ms[0] = Time.get_ticks_msec()
		timer.start(REPEAT_INITIAL_DELAY)
	)
	button.button_up.connect(func(): timer.stop())

## An on/off setting rather than a number, shown as a checkbox. Takes
## effect immediately -- no Restart Run needed.
func _make_toggle_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var label := Label.new()
	label.text = entry.label
	label.theme_type_variation = "Small"
	label.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0)
	row.add_child(label)
	row.add_child(UI.info_badge(entry.tip))
	row.add_spacer(false)

	var controls := _make_control_slot()
	row.add_child(controls)

	var box := CheckBox.new()
	_style_button(box)
	box.button_pressed = Settings.setting_get(entry.key)
	var key: String = entry.key
	toggle_boxes[key] = box
	box.toggled.connect(func(pressed: bool):
		Settings.setting_set(key, pressed)
		if key == "show_info_badges":
			# applies to every badge already on screen, not just new ones
			UI.refresh_badge_visibility(self)
		elif key == "developer_mode":
			_refresh_developer_row()
		elif key == "colour_blind_mode":
			# every cell relabels itself on its next frame; the panels are
			# told so they can redraw their keys straight away
			for listener in get_tree().get_nodes_in_group("colour_blind_listeners"):
				if is_instance_valid(listener) and listener.has_method("colour_blind_changed"):
					listener.colour_blind_changed()
		elif key == "use_cell_sprites":
			# cells otherwise only redraw themselves on their own staggered
			# timer (see hive_cell.gd's display cadence note) -- force it so
			# the swap is visible straight away rather than up to 1/6s late
			for cell in get_tree().get_nodes_in_group("hive_cells"):
				if is_instance_valid(cell):
					cell._refresh()
		elif key == "gallerin_enabled":
			# gallerin_panel.gd only reads this once, in its own _ready() --
			# toggling it here has to reach the live node directly, same
			# idea as the colour-blind broadcast above.
			for gallerin_panel in get_tree().get_nodes_in_group("gallerin"):
				if is_instance_valid(gallerin_panel):
					gallerin_panel.visible = pressed
		elif key == "show_speed_8x":
			# the button only exists once in the top-right bar per hud --
			# same "huds" group dispatch set_settings_button_width uses.
			for hud in get_tree().get_nodes_in_group("huds"):
				if is_instance_valid(hud) and hud.has_method("refresh_speed_visibility"):
					hud.refresh_speed_visibility()
		elif key == "show_interface_labels":
			# same "huds" group dispatch as show_speed_8x above.
			for hud in get_tree().get_nodes_in_group("huds"):
				if is_instance_valid(hud) and hud.has_method("_apply_interface_label_visibility"):
					hud._apply_interface_label_visibility()
		elif Prerequisites.is_gated(key):
			if pressed:
				_cascade_mutual_exclusion(key)
				_cascade_prerequisites_on(key)
			else:
				_cascade_dependents_off(key)
	)
	controls.add_child(box)
	return row

## A setting whose value is one of a small fixed set of strings (e.g.
## Session.ui_theme's "dark"/"light"/"high_contrast"), shown as a label
## plus "‹"/"›" buttons that step through entry.options -- the same shape
## as the numeric row's -/+ buttons, but stepping through a list instead
## of by an amount.
func _make_options_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var lbl := Label.new()
	lbl.theme_type_variation = "Small"
	lbl.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0)
	lbl.text = "%s: %s" % [entry.label, _option_display(entry, Settings.setting_get(entry.key))]
	value_labels[entry.key] = lbl
	row.add_child(lbl)

	row.add_child(UI.info_badge(entry.tip))
	row.add_spacer(false)

	var controls := _make_control_slot()
	row.add_child(controls)

	var prev := Button.new()
	_style_button(prev)
	prev.text = "‹"
	prev.custom_minimum_size = Vector2(26, 24)
	prev.pressed.connect(func(): _cycle_option(entry, -1))
	controls.add_child(prev)

	var next := Button.new()
	_style_button(next)
	next.text = "›"
	next.custom_minimum_size = Vector2(26, 24)
	next.pressed.connect(func(): _cycle_option(entry, 1))
	controls.add_child(next)

	return row

func _option_display(entry: Dictionary, value) -> String:
	var labels: Dictionary = entry.get("option_labels", {})
	return labels.get(value, value)

func _cycle_option(entry: Dictionary, direction: int) -> void:
	var options: Array = entry.options
	var idx: int = options.find(Settings.setting_get(entry.key))
	if idx == -1:
		idx = 0
	idx = (idx + direction + options.size()) % options.size()
	var new_value: String = options[idx]
	Settings.setting_set(entry.key, new_value)
	UiTheme.refresh_for_setting(entry.key)
	value_labels[entry.key].text = "%s: %s" % [entry.label, _option_display(entry, new_value)]

# --- prerequisite cascades ----------------------------------------
## UI-syncing wrapper over the catalogue's
## `_cascade_prerequisites_on_static` -- ticks the checkbox for every
## key the cascade actually changed.
func _cascade_prerequisites_on(key: String) -> void:
	for changed in Settings._cascade_prerequisites_on_static(key):
		if toggle_boxes.has(changed):
			toggle_boxes[changed].button_pressed = true
	# An ancestor switched on above may have turned off its mutually
	# exclusive sibling. Refresh every such pair from the authoritative
	# setting so their checkboxes do not retain the old pressed state.
	for mutually_exclusive in Prerequisites.MUTUALLY_EXCLUSIVE:
		if toggle_boxes.has(mutually_exclusive):
			toggle_boxes[mutually_exclusive].button_pressed = Settings.setting_get(mutually_exclusive)

## UI-syncing wrapper over the catalogue's
## `_cascade_dependents_off_static` -- unticks the checkbox for every
## key the cascade actually changed.
func _cascade_dependents_off(key: String) -> void:
	for changed in Settings._cascade_dependents_off_static(key):
		if toggle_boxes.has(changed):
			toggle_boxes[changed].button_pressed = false

## UI-syncing wrapper over the catalogue's
## `_cascade_mutual_exclusion_static` -- unticks the checkbox for
## whatever it turned off.
func _cascade_mutual_exclusion(key: String) -> void:
	for changed in Settings._cascade_mutual_exclusion_static(key):
		if toggle_boxes.has(changed):
			toggle_boxes[changed].button_pressed = false

# --- star rows and value editing ----------------------------------
## A row whose control is the same ★ / ☆ toggle the colony window uses,
## pinning something into the corner readout rather than changing a
## number. Kept identical to that one on purpose: a star means the same
## thing wherever the player meets it.
func _make_star_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var label := Label.new()
	label.text = entry.label
	label.theme_type_variation = "Small"
	label.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0)
	row.add_child(label)
	row.add_child(UI.info_badge(entry.tip))
	row.add_spacer(false)

	var controls := _make_control_slot()
	row.add_child(controls)

	var key: String = entry.key
	var star := Button.new()
	_style_button(star)
	star.toggle_mode = true
	star.flat = true
	star.focus_mode = Control.FOCUS_NONE
	star.button_pressed = Session.pinned_stats.has(key)
	star.text = "★" if star.button_pressed else "☆"
	star.theme_type_variation = "Body"
	star.tooltip_text = "Show this in the top-right corner."
	star.toggled.connect(func(pressed: bool):
		if pressed and not Session.pinned_stats.has(key):
			Session.pinned_stats.append(key)
		elif not pressed:
			Session.pinned_stats.erase(key)
		star.text = "★" if pressed else "☆"
		Session.save_preferences()
		# The corner has to be told: no number changed, so nothing else
		# would prompt it to redraw.
		for hud in get_tree().get_nodes_in_group("huds"):
			if is_instance_valid(hud) and hud.has_method("pinned_stats_changed"):
				hud.pinned_stats_changed()
	)
	controls.add_child(star)
	return row

func _adjust(entry: Dictionary, delta: float) -> void:
	var new_value: float = Settings.setting_get(entry.key) + delta
	new_value = max(new_value, entry.min)
	if entry.has("max"):
		new_value = min(new_value, entry.max)
	Settings.setting_set(entry.key, new_value)
	if entry.key == "text_scale":
		_text_scale_timer.start()
	else:
		UiTheme.refresh_for_setting(entry.key)
	value_labels[entry.key].text = "%s: %s" % [entry.label, _format_value(new_value)]
	if entry.key == "tooltip_delay":
		# Godot's own project-wide tooltip timer, rather than something
		# every tooltip_text assignment would otherwise need to read
		# individually -- see UI_PLAN.md section 7.
		ProjectSettings.set("gui/timers/tooltip_delay_sec", new_value)

func _format_value(v) -> String:
	if v is bool:
		return "on" if v else "off"
	if v == int(v):
		return str(int(v))
	return "%.2f" % v

# --- restart and main menu ----------------------------------------
func _on_restart_pressed() -> void:
	_restart()

## main.gd adds the menu to the "main_menu" group, so the panel can reach
## it without the two needing to know about each other directly.
func _on_main_menu_pressed() -> void:
	var menus := get_tree().get_nodes_in_group("main_menu")
	if menus.is_empty():
		push_warning("No main menu in the scene to return to")
		return
	panel.visible = false
	menus[0].open()

func _restart() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	Session.reset_run_state()
	get_tree().reload_current_scene()
