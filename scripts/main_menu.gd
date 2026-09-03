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
const HexHitArea = preload("res://scripts/hex_hit_area.gd")

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
## Existing internal level ids stay unchanged for save/profile stability;
## new run definitions receive new ids even when their player-facing order is
## earlier. The menu's Scenario number is presentation, not an array index.
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
		"level": 7,
		"group": "starter",
		"title": "Scenario 1 — Queen alone",
		"blurb": "One queen, no workers and no comb. There is no scripted guidance: she must take on the colony's first jobs herself and build everything from nothing.",
	},
	{
		"level": 3,
		"group": "starter",
		"title": "Scenario 2 — A working colony",
		"blurb": "The queen, three cells, and two foragers — one on nectar, one on pollen. Both resources are coming in from the first moment.",
	},
	{
		"level": 4,
		"group": "starter",
		"title": "Scenario 3 — Established nest",
		"blurb": "Fifteen cells and a full crew: eleven foragers (eight on nectar, three on pollen), two nurses, two comb workers on both jobs, and two miners. Enough colony that keeping it fed is the challenge, not starting it.",
	},
	{
		"level": 5,
		"group": "starter",
		"title": "Scenario 4 — In full swing",
		"blurb": "Twenty-two foragers (sixteen on nectar, six on pollen), four nurses, three comb workers and three miners already digging. Twelve cells, four of them full of nectar and two of pollen, so the queen can lay from the first second. A colony big enough that what to do with it is the question.",
	},
	{
		"level": 6,
		"group": "starter",
		"title": "Scenario 5 — Thirty strong",
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

## Centre-to-corner distance of one hex tile. 1.5x the original 56 (UI-M)
## now that each honeycomb strip has a whole half of the left pane to
## itself instead of sharing a single narrow scrolling column.
const HEX_SIZE := 84.0
const HEX_BORDER_OVERLAP := 3.0
const LEFT_PANE_MARGIN := 32
## Horizontal centre-to-centre spacing for a touching row of hexagons
## (Dave's 29 Aug request: tiles' side edges meet exactly, no visible
## gap) -- 1.5x HEX_SIZE is the standard hex-grid step for a hexagon with
## vertices at its left/right extremes (shapes.gd::hexagon_points).
## Neighbouring tiles' *bounding boxes* do overlap at this spacing even
## though the hexagons themselves only touch -- HexHitArea (hex_hit_area.gd)
## gives each tile a hex-accurate click region instead of a rectangular
## one, so an overlapping corner never steals a click meant for the tile
## next to it, which is what the old wider HEX_GAP spacing used to avoid.
const HEX_STEP_X := HEX_SIZE * 1.5

## Floor width for the right-hand detail pane (blurb/preset/Start), so it
## can't compress unreadably at the game's minimum supported width the
## way a pure 2:1 stretch ratio would. Same floor-below-a-ratio pattern
## ui_layout.gd already uses for the in-run HUD's narrow breakpoint, sized
## here for this pane's actual content instead of reusing a HUD-specific
## constant that governs different panels.
## 4 preset buttons (90 wide, 6 gap) is this pane's widest row at 378px --
## the floor sits just above that so the preset row never has to
## overflow or wrap mid-button.
const DETAIL_PANE_MIN_WIDTH := 390.0

var root: Control
var backdrop: ColorRect
var settings_button: Button
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

	# Full-viewport control replacing the old single centred panel (UI-M) --
	# left:right stretch ratio 2:1, matching hud.gd's existing
	# SIZE_EXPAND_FILL + stretch-ratio pattern (UI-G) instead of fixed
	# pixel widths, so the split holds at any window size.
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.build_theme()
	add_child(root)

	var split := HBoxContainer.new()
	split.set_anchors_preset(Control.PRESET_FULL_RECT)
	split.add_theme_constant_override("separation", 24)
	root.add_child(split)

	# The full-viewport menu still uses the split's responsive 2:1 geometry,
	# while its left content now begins on a comfortable 32px inset.
	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", LEFT_PANE_MARGIN)
	left_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_margin.size_flags_stretch_ratio = 2.0
	left_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(left_margin)

	var left_pane := VBoxContainer.new()
	left_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_pane.add_theme_constant_override("separation", 10)
	left_margin.add_child(left_pane)

	var right_pane := VBoxContainer.new()
	right_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_pane.size_flags_stretch_ratio = 1.0
	right_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_pane.custom_minimum_size = Vector2(DETAIL_PANE_MIN_WIDTH, 0)
	right_pane.add_theme_constant_override("separation", 10)
	split.add_child(right_pane)

	_build_settings_button(right_pane)

	var title := Label.new()
	title.text = "Meadow"
	title.theme_type_variation = "Heading"
	left_pane.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose where to start. Everything else uses your current tuning values."
	subtitle.theme_type_variation = "Small"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_pane.add_child(subtitle)

	# Challenges upper-left, Scenarios lower-left (UI-M) -- each group gets
	# an equal EXPAND_FILL half instead of today's single stacked order.
	for group in GROUPS:
		var group_column := VBoxContainer.new()
		group_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		group_column.add_theme_constant_override("separation", 6)
		left_pane.add_child(group_column)

		var heading := Label.new()
		heading.text = group.heading
		heading.theme_type_variation = "Heading"
		group_column.add_child(heading)

		var note := Label.new()
		note.text = group.note
		note.theme_type_variation = "Small"
		note.add_theme_color_override("font_color", UiTheme.color("text_secondary"))
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		group_column.add_child(note)

		# The Scenarios strip (5 tiles at 1.5x size) is wider than the left
		# pane can offer down at MIN_SUPPORTED_WIDTH -- a horizontal
		# scroll keeps every tile reachable and unclipped there without
		# giving up the honeycomb's absolute-positioned stagger, rather
		# than rebuilding it as a wrapping flow layout.
		var strip_scroll := ScrollContainer.new()
		strip_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		# Vertical scrolling is off (the stagger is the only reason a strip
		# isn't a flat row), so the ScrollContainer needs its own floor
		# height or the surrounding VBoxContainer could squeeze it below
		# the tiles' real height and clip the lower row instead of
		# scrolling to it.
		strip_scroll.custom_minimum_size.y = _hex_row_height()
		strip_scroll.add_child(_make_honeycomb_strip(group.key))
		group_column.add_child(strip_scroll)

		if group.key != GROUPS[-1].key:
			left_pane.add_child(HSeparator.new())

	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Without this, a ScrollContainer sizes its child to the child's own
	# minimum width rather than stretching it to fit -- an autowrapping
	# Label inside then computes its wrap width against nearly nothing,
	# so it prints one letter per line instead of wrapping at the pane's
	# actual width (Dave's 29 Aug report on the placeholder text).
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_pane.add_child(right_scroll)

	var detail_placeholder := Label.new()
	detail_placeholder.text = "Choose a Challenge or Scenario on the left."
	detail_placeholder.theme_type_variation = "Body"
	detail_placeholder.add_theme_color_override("font_color", UiTheme.color("text_secondary"))
	detail_placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_detail_column = VBoxContainer.new()
	_detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_column.add_theme_constant_override("separation", 6)
	_detail_column.add_child(detail_placeholder)
	right_scroll.add_child(_detail_column)

	right_pane.add_child(HSeparator.new())

	var close_btn := Button.new()
	close_btn.text = "Back to the run"
	close_btn.custom_minimum_size = Vector2(0, 30)
	_style_button(close_btn)
	close_btn.pressed.connect(close)
	right_pane.add_child(UI.with_info(close_btn, "Close the menu and carry on with the colony you already have. Nothing is restarted."))

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

# --- settings ----------------------------------------------------------

## Top-right Settings button (UI-M) -- opens the same settings window
## hud.gd's in-run cog does, expanded straight to Accessibility and
## Appearance, so a player can fix contrast/text-scale/colour-blind mode
## before ever starting a run without this menu duplicating those controls.
## Placed as the first row of the right pane (itself the rightmost column
## of the full-viewport split) rather than free-floated over the top of
## everything else, so it reserves its own space instead of risking an
## overlap with whatever the right pane's ScrollContainer scrolls to.
func _build_settings_button(right_pane: VBoxContainer) -> void:
	settings_button = Button.new()
	_style_button(settings_button)
	# Same plain cog glyph the in-run settings button uses (debug_panel.gd),
	# rather than a separate text button -- Dave's 29 Aug ask, so the two
	# read as the same control rather than two different ones.
	settings_button.text = "⚙"
	settings_button.theme_type_variation = "Heading"
	settings_button.custom_minimum_size = Vector2(56, 44)
	settings_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	settings_button.pressed.connect(_on_settings_pressed)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(UI.with_info(settings_button, "Accessibility and appearance settings -- text scale, contrast, colour-blind mode and the rest of the settings window."))
	right_pane.add_child(row)

## debug_panel.gd is already built and in the "debug_panel" group by the
## time this menu shows (main.gd builds it before the menu, so it exists
## on a fresh boot too) -- same reach-across-the-tree pattern debug_panel.gd
## already uses the other way for its own "Return to Main Menu" button.
func _on_settings_pressed() -> void:
	var panels := get_tree().get_nodes_in_group("debug_panel")
	if panels.is_empty():
		push_warning("No settings window in the scene to open")
		return
	panels[0].open_to_categories(["Accessibility", "Appearance"])

# --- the honeycomb ------------------------------------------------------

## Vertical offset alternating tiles drop by so a touching row of
## flat-vertex hexagons tessellates correctly: half the hex's own height,
## the standard hex-grid offset between adjacent columns (paired with
## HEX_STEP_X above). A function rather than a further const since
## GDScript const expressions can't call sqrt() (see .claude/rules/
## gdscript.md's ":=" landmine note on the same const-folding limits).
func _hex_row_offset() -> float:
	return HEX_SIZE * sqrt(3.0) / 2.0

## Full pixel height one honeycomb strip needs -- a plain tile row plus
## the offset the odd tiles drop by. Shared by the strip itself and by the
## ScrollContainer wrapping it (_ready()), so the two can never drift out
## of sync.
func _hex_row_height() -> float:
	return HEX_SIZE * sqrt(3.0) + _hex_row_offset()

func _make_honeycomb_strip(group_key: String) -> Control:
	var stages_in_group: Array = []
	for stage in STAGES:
		if stage.group == group_key:
			stages_in_group.append(stage)

	var bbox := Vector2(HEX_SIZE * 2.0, HEX_SIZE * sqrt(3.0))
	var row_offset: float = _hex_row_offset()
	var strip := Control.new()
	strip.custom_minimum_size = Vector2(
		float(stages_in_group.size() - 1) * HEX_STEP_X + bbox.x,
		bbox.y + row_offset
	)
	strip.size = strip.custom_minimum_size

	for i in range(stages_in_group.size()):
		var tile := _make_hex_tile(stages_in_group[i])
		tile.position = Vector2(float(i) * HEX_STEP_X, row_offset if i % 2 == 1 else 0.0)
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
	# Paint only: real tile centres and HexHitArea retain HEX_SIZE, so making
	# this outer polygon overlap cannot reintroduce ambiguous edge clicks.
	border.polygon = Shapes.hexagon_points(HEX_SIZE + HEX_BORDER_OVERLAP)
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
	# Hex-shaped hit test (HexHitArea), not the full bounding rectangle --
	# see HEX_STEP_X's comment above for why that matters now the tiles
	# tessellate with touching, overlapping-bbox neighbours.
	var button := HexHitArea.new()
	button.hex_size = HEX_SIZE
	button.hex_center = bbox / 2.0
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
