extends CanvasLayer
## The main menu: a full-screen overlay that pauses the run behind it and
## offers a choice of starting stage, laid out as a fixed honeycomb of
## hex-shaped tiles per UI_PLAN.md section 12.
##
## It opens by itself the first time the game is launched, and after that
## only when the player picks "Return to Main Menu" in the settings window.
## Choosing a Challenge emits level_chosen (unchanged); choosing a
## Scenario also carries which difficulty preset was picked, via
## scenario_chosen. Either way main.gd sets Session.starting_level and
## reloads the scene, so every stage is built by the same world-building
## code rather than a separate path that could drift out of step.

const UI = preload("res://scripts/ui.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")
const Shapes = preload("res://scripts/shapes.gd")
const PlayerProfile = preload("res://scripts/player_profile.gd")
const ScenarioPresets = preload("res://scripts/scenario_presets.gd")

## Challenges carry no preset -- main.gd's existing wiring stays as it was.
signal level_chosen(level: int)
## Scenarios carry a preset key (see scenario_presets.gd) and, for
## "custom", whichever of its fields the player actually changed.
signal scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary)

## Kept in the same order they're shown. `level` matches the keys of
## levels.gd's LEVELS dictionary, which is what actually decides what gets
## spawned -- these are the words for it.
##
## Split into two groups per TUTORIAL_PLAN.md's "Terminology" section:
## **Challenges** (`group: "challenge"`) are staged, scripted entries with
## a win condition and Dr Gallerin guiding you through it. **Scenarios**
## (`group: "starter"` -- the internal key stays as it was; only the
## player-facing heading changed, UI_PLAN.md section 12) are the plain
## starting-point presets this menu always had -- no sub-stages, no win
## condition, no Dr Gallerin, just a different-sized colony to begin from,
## now with a difficulty preset layered on top (scenario_presets.gd).
## Internal level ids stay exactly as they were (1-5) so existing saves
## and the LEVELS dictionary don't need to change shape; only the menu's
## grouping and labels do.
const STAGES := [
	{
		"level": 1,
		"group": "challenge",
		"title": "Challenge 1: First Stores",
		"blurb": "Found the beginnings of a colony. Build your first cell, gather nectar, and learn how a tiny hive starts to sustain itself.",
	},
	{
		"level": 2,
		"group": "challenge",
		"title": "Challenge 2: Brood, Roles and Expansion",
		"blurb": "Grow the colony from stored food into a working hive. Lay eggs, raise specialist bees, keep nectar flowing, and expand the hive enough to support a balanced workforce.",
	},
	{
		"level": 3,
		"group": "starter",
		"title": "Scenario 1 — A working colony",
		"blurb": "The queen, three cells, and two foragers — one on nectar, one on pollen. Both resources are coming in from the first moment.",
	},
	{
		"level": 4,
		"group": "starter",
		"title": "Scenario 2 — Established nest",
		"blurb": "Fifteen cells and a full crew: eleven foragers (eight on nectar, three on pollen), two nurses, two comb workers on both jobs, and two miners. Enough colony that keeping it fed is the challenge, not starting it.",
	},
	{
		"level": 5,
		"group": "starter",
		"title": "Scenario 3 — In full swing",
		"blurb": "Twenty-two foragers (sixteen on nectar, six on pollen), four nurses, three comb workers and three miners already digging. Twelve cells, four of them full of nectar and two of pollen, so the queen can lay from the first second. A colony big enough that what to do with it is the question.",
	},
	{
		"level": 6,
		"group": "starter",
		"title": "Scenario 4 — Thirty strong",
		"blurb": "Thirty bees: twenty foragers (fourteen on nectar, six on pollen), three nurses, three comb workers, two miners and two honey makers. Eighteen cells in three ring-layers around the centre, half of them already stocked with nectar, pollen and honey.",
	},
]

## Shown above each group of STAGES rows, in the same order the groups
## should appear. Dave's exact descriptor text, 21 Aug 2026 (UI_PLAN.md
## section 12) -- the "starter" key itself is internal-only and unchanged.
const GROUPS := [
	{"key": "challenge", "heading": "Challenges", "note": "Unlock new features through overcoming challenges to the hive."},
	{"key": "starter", "heading": "Scenarios", "note": "Low stakes scenarios as starting points for your colony."},
]

## Centre-to-corner distance of one hex tile.
const HEX_SIZE := 56.0
## Horizontal air between two tiles' bounding boxes, so neighbouring
## tiles' click areas never overlap -- see NEXTSTEPS.md for why this is a
## row of separated hexes rather than true edge-to-edge tessellation.
const HEX_GAP := 14.0
## Purely cosmetic vertical zigzag between alternating tiles in a row, so
## a row of two or three still reads as "honeycomb" rather than a plain
## strip of rounded buttons.
const HEX_STAGGER := 18.0

var panel: PanelContainer
var backdrop: ColorRect
var _detail_column: VBoxContainer
## level -> {"border": Polygon2D, "fill": Polygon2D, "tick": Label}
var _hex_nodes: Dictionary = {}
var _selected_level: int = -1
var _selected_preset_key: String = "standard"
## Only ever holds keys from the "custom" preset's customizable_keys.
var _custom_values: Dictionary = {}
var _profile_data: Dictionary = {}

# --- lifecycle -------------------------------------------------------

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS   # the menu still works while paused
	layer = 20                           # above the HUD and the settings window
	visible = false
	# so the settings window's "Return to Main Menu" button can find us
	# without main.gd having to wire the two together
	add_to_group("main_menu")

	_profile_data = PlayerProfile.read()

	backdrop = ColorRect.new()
	backdrop.color = Color(0.05, 0.07, 0.05, 0.88)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP   # swallow clicks on the world behind
	add_child(backdrop)

	panel = PanelContainer.new()
	panel.theme = UiTheme.build_theme()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(640, 0)
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 600)
	panel.add_child(scroll)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)

	var title := Label.new()
	title.text = "Meadow"
	title.theme_type_variation = "Heading"
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose where to start. Everything else uses your current tuning values."
	subtitle.theme_type_variation = "Small"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size = Vector2(600, 0)
	column.add_child(subtitle)

	for group in GROUPS:
		var heading := Label.new()
		heading.text = group.heading
		heading.theme_type_variation = "Heading"
		column.add_child(heading)

		var note := Label.new()
		note.text = group.note
		note.theme_type_variation = "Small"
		note.add_theme_color_override("font_color", UiTheme.color("text_secondary"))
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(600, 0)
		column.add_child(note)

		column.add_child(_make_honeycomb_strip(group.key))
		column.add_child(HSeparator.new())

	var detail_placeholder := Label.new()
	detail_placeholder.text = "Choose a Challenge or Scenario above."
	detail_placeholder.theme_type_variation = "Body"
	detail_placeholder.add_theme_color_override("font_color", UiTheme.color("text_secondary"))

	_detail_column = VBoxContainer.new()
	_detail_column.add_theme_constant_override("separation", 6)
	_detail_column.add_child(detail_placeholder)
	column.add_child(_detail_column)

	column.add_child(HSeparator.new())

	var close_btn := Button.new()
	close_btn.text = "Back to the run"
	close_btn.custom_minimum_size = Vector2(0, 30)
	_style_button(close_btn)
	close_btn.pressed.connect(close)
	column.add_child(UI.with_info(close_btn, "Close the menu and carry on with the colony you already have. Nothing is restarted."))

func open() -> void:
	# Re-read rather than trust whatever was loaded at _ready() -- a
	# Challenge can be completed, or a preference changed, without the
	# scene reloading (completing a Challenge doesn't reload; only
	# choosing a new stage or restarting does), so the ticks below could
	# otherwise go stale for the rest of the session.
	_profile_data = PlayerProfile.read()
	_refresh_ticks()
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false
	Session.menu_pending = false

# --- the honeycomb ------------------------------------------------------

func _make_honeycomb_strip(group_key: String) -> Control:
	var stages_in_group: Array = []
	for stage in STAGES:
		if stage.group == group_key:
			stages_in_group.append(stage)

	var bbox := Vector2(HEX_SIZE * 2.0, HEX_SIZE * sqrt(3.0))
	var step_x: float = HEX_SIZE * 2.0 + HEX_GAP
	var strip := Control.new()
	strip.custom_minimum_size = Vector2(
		float(stages_in_group.size() - 1) * step_x + bbox.x,
		bbox.y + HEX_STAGGER
	)
	strip.size = strip.custom_minimum_size

	for i in range(stages_in_group.size()):
		var tile := _make_hex_tile(stages_in_group[i])
		tile.position = Vector2(float(i) * step_x, HEX_STAGGER if i % 2 == 1 else 0.0)
		strip.add_child(tile)

	return strip

func _make_hex_tile(stage: Dictionary) -> Control:
	var bbox := Vector2(HEX_SIZE * 2.0, HEX_SIZE * sqrt(3.0))
	var tile := Control.new()
	tile.custom_minimum_size = bbox
	tile.size = bbox

	# Border hex slightly larger than the fill hex, layered underneath --
	# the cheapest way to fake a stroke on a non-rectangular shape without
	# a StyleBox, matching the rest of the game's "flat Polygon2D shapes,
	# no imported art" placeholder approach (see gallerin_panel.gd).
	var border := Polygon2D.new()
	border.polygon = Shapes.hexagon_points(HEX_SIZE)
	border.position = bbox / 2.0
	tile.add_child(border)

	var fill := Polygon2D.new()
	fill.polygon = Shapes.hexagon_points(HEX_SIZE - 4.0)
	fill.position = bbox / 2.0
	tile.add_child(fill)

	var label := Label.new()
	label.text = stage.title
	label.theme_type_variation = "Small"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.position = Vector2(10.0, 8.0)
	label.size = Vector2(bbox.x - 20.0, bbox.y - 16.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(label)

	var tick := Label.new()
	tick.text = "✓"
	tick.theme_type_variation = "Body"
	tick.add_theme_color_override("font_color", UiTheme.color("success"))
	tick.position = Vector2(bbox.x - 22.0, 2.0)
	tick.size = Vector2(20.0, 20.0)
	tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tick.visible = _is_completed(stage)
	tick.tooltip_text = "Completed." if stage.group == "challenge" else "Played before."
	tile.add_child(tick)

	# Added last so it draws (and receives clicks) on top of the shapes
	# and labels beneath it -- flat, so nothing it draws itself is visible.
	var button := Button.new()
	button.flat = true
	button.text = ""
	button.position = Vector2.ZERO
	button.size = bbox
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = stage.title
	tile.add_child(button)

	var level_value: int = stage.level
	button.pressed.connect(func(): _select_stage(stage))
	button.mouse_entered.connect(func(): _apply_hex_colors(level_value, "hover"))
	button.mouse_exited.connect(func(): _refresh_hex_state(level_value))

	_hex_nodes[level_value] = {"border": border, "fill": fill, "tick": tick}
	_apply_hex_colors(level_value, "normal")
	return tile

func _apply_hex_colors(level: int, state: String) -> void:
	if not _hex_nodes.has(level):
		return
	var nodes: Dictionary = _hex_nodes[level]
	var box := UiTheme.button_stylebox(state)
	nodes.fill.color = box.bg_color
	var border_color: Color = box.border_color
	if box.border_width_left == 0:
		border_color = UiTheme.color("panel_bg").lightened(0.15)
	nodes.border.color = border_color

func _refresh_hex_state(level: int) -> void:
	_apply_hex_colors(level, "selected" if level == _selected_level else "normal")

func _refresh_ticks() -> void:
	for level in _hex_nodes.keys():
		var stage := _stage_for_level(level)
		if stage.is_empty():
			continue
		_hex_nodes[level].tick.visible = _is_completed(stage)

func _stage_for_level(level: int) -> Dictionary:
	for stage in STAGES:
		if stage.level == level:
			return stage
	return {}

# --- selection and the detail pane ---------------------------------------

func _select_stage(stage: Dictionary) -> void:
	var previous := _selected_level
	_selected_level = stage.level
	_selected_preset_key = "standard"
	_custom_values.clear()
	if previous != -1 and previous != _selected_level:
		_refresh_hex_state(previous)
	_apply_hex_colors(_selected_level, "selected")
	_rebuild_detail_pane(stage)

func _rebuild_detail_pane(stage: Dictionary) -> void:
	for child in _detail_column.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = stage.title
	title.theme_type_variation = "Heading"
	_detail_column.add_child(title)

	var blurb := Label.new()
	blurb.text = stage.blurb
	blurb.theme_type_variation = "Body"
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(600, 0)
	_detail_column.add_child(blurb)

	if stage.group == "starter":
		_detail_column.add_child(_make_preset_row(stage))
		_detail_column.add_child(_make_preset_description())
		if _selected_preset_key == "custom":
			_detail_column.add_child(_make_custom_controls())
		if _is_scenario_played(stage.level):
			_detail_column.add_child(_make_note_label("Played before."))
	elif _is_challenge_complete(stage.level):
		_detail_column.add_child(_make_note_label("Completed."))

	var start_btn := Button.new()
	start_btn.text = "Start"
	start_btn.custom_minimum_size = Vector2(140, 32)
	_style_button(start_btn)
	start_btn.pressed.connect(func(): _choose(stage))
	_detail_column.add_child(UI.with_info(start_btn, "Restarts the run with this choice. Anything unsaved in the colony you have now is lost."))

func _make_note_label(text: String) -> Label:
	var note := Label.new()
	note.text = text
	note.theme_type_variation = "Small"
	note.add_theme_color_override("font_color", UiTheme.color("success"))
	return note

## The cog described in UI_PLAN.md section 5 ("its cog... is secondary
## and only appears once a scenario is selected") is this row plus the
## description/custom controls beneath it -- a difficulty preset is the
## one scenario-specific override this slice adds.
func _make_preset_row(stage: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for preset in ScenarioPresets.PRESETS:
		var btn := Button.new()
		btn.text = preset.label
		btn.custom_minimum_size = Vector2(90, 28)
		var key: String = preset.key
		_style_button(btn, key == _selected_preset_key)
		btn.pressed.connect(func():
			_selected_preset_key = key
			_custom_values.clear()
			_rebuild_detail_pane(stage)
		)
		row.add_child(btn)
	return row

func _make_preset_description() -> Control:
	var col := VBoxContainer.new()
	var preset := ScenarioPresets.get_preset(_selected_preset_key)
	for line in preset.plain_english:
		var lbl := Label.new()
		lbl.text = "• %s" % line
		lbl.theme_type_variation = "Small"
		col.add_child(lbl)
	return col

func _make_custom_controls() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	var preset := ScenarioPresets.get_preset("custom")
	for field in preset.customizable_keys:
		col.add_child(_make_custom_row(field))
	return col

func _make_custom_row(field: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var key: String = field.key
	var baseline: float = ScenarioPresets.BASELINE[key]

	var label := Label.new()
	label.text = field.label
	label.theme_type_variation = "Small"
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)

	var minus := Button.new()
	minus.text = "−"
	minus.custom_minimum_size = Vector2(26, 24)
	_style_button(minus)
	row.add_child(minus)

	var value_label := Label.new()
	value_label.theme_type_variation = "Small"
	value_label.custom_minimum_size = Vector2(50, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.text = "%.2f" % _custom_values.get(key, baseline)
	row.add_child(value_label)

	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(26, 24)
	_style_button(plus)
	row.add_child(plus)

	minus.pressed.connect(func():
		var v: float = max(field.min, float(_custom_values.get(key, baseline)) - float(field.step))
		_custom_values[key] = v
		value_label.text = "%.2f" % v
	)
	plus.pressed.connect(func():
		var v: float = min(field.max, float(_custom_values.get(key, baseline)) + float(field.step))
		_custom_values[key] = v
		value_label.text = "%.2f" % v
	)
	return row

# --- choosing --------------------------------------------------------

func _choose(stage: Dictionary) -> void:
	visible = false
	if stage.group == "challenge":
		level_chosen.emit(stage.level)
	else:
		scenario_chosen.emit(stage.level, _selected_preset_key, _custom_values.duplicate())

# --- small shared helpers ---------------------------------------------

func _style_button(button: Button, selected: bool = false) -> void:
	for state in UiTheme.BUTTON_STATES:
		if state == "normal":
			button.add_theme_stylebox_override("normal", UiTheme.button_stylebox("selected" if selected else "normal"))
		else:
			button.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))

func _is_challenge_complete(level: int) -> bool:
	return PlayerProfile.completed_challenges(_profile_data).has(level)

func _is_scenario_played(level: int) -> bool:
	var played: Dictionary = PlayerProfile.played_scenarios(_profile_data)
	for k in played.keys():
		if str(k).begins_with("%d_" % level):
			return true
	return false

func _is_completed(stage: Dictionary) -> bool:
	if stage.group == "challenge":
		return _is_challenge_complete(stage.level)
	return _is_scenario_played(stage.level)
