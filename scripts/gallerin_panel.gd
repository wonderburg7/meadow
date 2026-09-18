extends CanvasLayer
## Dr Gallerin: the Challenge tutorial's non-blocking moth mentor. See
## TUTORIAL_PLAN.md's "Dr Gallerin" section for the character brief and
## the prompt-type list this scheduler works from.
##
## This is the UI half (a small bottom-right icon plus a speech bubble)
## and the small prompt scheduler that decides when a queued prompt
## actually appears. Nothing feeds it real prompts yet -- no Challenge
## sub-stage script exists to call queue_prompts()/show_now() -- so this
## is infrastructure the same way stage_gate.gd and tutorial_checkpoint.gd
## are: built and ready, not yet wired to a live Challenge.
##
## Never pauses the game and never blocks anything else on screen -- the
## icon and bubble are the only two controls here, both small, both in
## the bottom-right corner, and clicking through either is always
## possible. process_mode is ALWAYS so a bubble's countdown (and a
## welcome prompt firing right as a sub-stage starts) doesn't stall
## if something else has paused the tree.
##
## Drawn rather than imported, the same placeholder-art approach as the
## rest of the game (see debug_panel.gd's cog glyph and the meadow's
## plain Polygon2D scenery) -- two wing shapes and a body built from
## shapes.gd's circle_points, not a sprite.

const Shapes = preload("res://scripts/shapes.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")

const ICON_SIZE := Vector2(60, 60)
const ICON_MARGIN := 16.0
const BUBBLE_WIDTH := 460.0
## Matches UiTheme's Body text, which is what the summary panel uses.
const BUBBLE_TEXT_SIZE := 15

const BUBBLE_GAP := 8.0

## How fast the bubble's text types out. See _process()'s typing block.
const TYPE_CHARACTERS_PER_SECOND := 45.0

var _icon_button: Button
var bubble: PanelContainer
var _bubble_scroll: ScrollContainer
var _bubble_label: Label
var _bubble_pointer: Polygon2D
var _hovering_icon: bool = false
var _hovering_bubble: bool = false
var _last_message: String = ""
## The bubble's font-size override (unlike most labels, which read a
## theme_type_variation that UiTheme.refresh() updates for the whole game
## at once) is only ever set explicitly, so it needs its own live check --
## see _process(). Dave's 29 Aug report: the bubble's text stayed the old
## size after changing the text-scale setting mid-session.
var _last_text_scale: float = 1.0
## The line currently typing out and how many of its characters are
## revealed so far -- see _show_bubble() and _process()'s typing block.
var _typing_target: String = ""
var _typed_characters: float = 0.0

# --- history paging (HC-6) --------------------------------------------
## Every line shown so far, oldest first, capped at 50 entries so a long
## run cannot grow it without bound -- see _push_history().
var _history: Array[String] = []
## Index into _history of the entry currently on screen. -1 means nothing
## has been shown yet. Sits at _history.size() - 1 (the newest entry)
## except while the player is paging back with ◀ -- see _process()'s
## _fire_due_prompts() guard, which is what holds the queue while that's
## true.
var _history_index: int = -1
var _history_back_btn: Button
var _history_forward_btn: Button

# --- prompt scheduling ----------------------------------------------
## Each queued entry: {"id": String, "text": String, "delay": float,
## "repeatable": bool}. `delay` is seconds since the current sub-stage's
## queue_prompts() call -- a "welcome" entry uses 0.0, a "hint" and a
## "stronger_hint" use whatever gap the sub-stage calls for. Entries fire
## in delay order and are dropped once shown unless `repeatable` is true.
## `id` is how a non-repeatable entry is recognised as already shown --
## it only needs to be unique within one sub-stage's queue, not globally.
var _queue: Array = []
var _shown_ids: Dictionary = {}
var _stage_elapsed: float = 0.0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 15   # above the HUD, below the settings window and main menu
	add_to_group("gallerin")   # so debug_panel.gd's toggle can find this node live

	_build_icon()
	_build_bubble()
	_last_text_scale = Session.text_scale
	visible = Session.gallerin_enabled
	get_viewport().size_changed.connect(_apply_layout)
	# The settings window is built before this node (main.gd), so it's
	# already in the "debug_panel" group -- the same reach-across-the-tree
	# pattern main_menu.gd's Settings button uses the other way. Its
	# visibility/resize, not _process(), is what should trigger a re-layout
	# when it starts or stops sharing the bottom-right column (UI-X-4).
	var settings_panels := get_tree().get_nodes_in_group("debug_panel")
	if not settings_panels.is_empty():
		var settings_panel: PanelContainer = settings_panels[0].panel
		settings_panel.visibility_changed.connect(_apply_layout)
		settings_panel.resized.connect(_apply_layout)
	_apply_layout()

func _process(delta: float) -> void:
	_stage_elapsed += delta
	# The queue keeps accumulating while the player is paged back to an
	# older entry (HC-6) -- a prompt that comes due is shown the moment
	# they return to the newest one, rather than snatching the bubble away
	# from what they're reading.
	if _history_index == _history.size() - 1:
		_fire_due_prompts()
	if Session.text_scale != _last_text_scale:
		_last_text_scale = Session.text_scale
		_apply_bubble_font_size()
	if _typed_characters < _typing_target.length():
		# Godot multiplies the delta reaching _process() by Engine.time_scale
		# (camera_view.gd's 4x/etc game-speed control), so it has to be
		# divided back out here -- otherwise 4x game speed would type the
		# prompt 4x faster, which isn't what game speed means for dialogue.
		var unscaled_delta := delta
		if Engine.time_scale > 0.0:
			unscaled_delta = delta / Engine.time_scale
		_typed_characters += TYPE_CHARACTERS_PER_SECOND * unscaled_delta
		if _typed_characters >= _typing_target.length():
			_finish_typing()
		else:
			_bubble_label.visible_characters = int(_typed_characters)

# --- building the UI -------------------------------------------------

func _build_icon() -> void:
	_icon_button = Button.new()
	_icon_button.flat = true
	_icon_button.custom_minimum_size = ICON_SIZE
	_icon_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_icon_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_icon_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_icon_button.offset_right = -ICON_MARGIN
	_icon_button.offset_bottom = -ICON_MARGIN
	_icon_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_icon_button.tooltip_text = "Dr Gallerin -- click to see the last thing he said."
	_icon_button.pressed.connect(_on_icon_pressed)
	_icon_button.mouse_entered.connect(func(): _hovering_icon = true)
	_icon_button.mouse_exited.connect(func(): _hovering_icon = false)
	add_child(_icon_button)

	var centre := ICON_SIZE / 2.0

	# Two wings behind the body, angled outward, muted brown -- a moth
	# rather than anything bright or insect-cute.
	var wing_left := Polygon2D.new()
	wing_left.polygon = PackedVector2Array([
		Vector2(-2, -4), Vector2(-24, -15), Vector2(-27, 6), Vector2(-8, 10),
	])
	wing_left.color = Color(0.58, 0.50, 0.38, 0.92)
	wing_left.position = centre
	_icon_button.add_child(wing_left)

	var wing_right := Polygon2D.new()
	wing_right.polygon = PackedVector2Array([
		Vector2(2, -4), Vector2(24, -15), Vector2(27, 6), Vector2(8, 10),
	])
	wing_right.color = Color(0.58, 0.50, 0.38, 0.92)
	wing_right.position = centre
	_icon_button.add_child(wing_right)

	var body := Polygon2D.new()
	body.polygon = Shapes.circle_points(9.0, 14)
	body.color = Color(0.34, 0.27, 0.20)
	body.position = centre
	_icon_button.add_child(body)

func _build_bubble() -> void:
	bubble = PanelContainer.new()
	bubble.visible = false
	# Outer rectangle comes from UiLayout.gallerin_rect() via
	# UiPanelLayout.apply() in _apply_layout() -- this preset only gives the
	# bubble the same starting anchors/grow direction as the tray and
	# summary panel before that first apply() call lands (HC-14).
	bubble.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bubble.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bubble.theme = UiTheme.build_theme()
	bubble.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	bubble.mouse_entered.connect(func(): _hovering_bubble = true)
	bubble.mouse_exited.connect(func(): _hovering_bubble = false)
	bubble.gui_input.connect(_on_bubble_gui_input)
	bubble.resized.connect(_position_bubble_pointer)
	add_child(bubble)

	# A plain column would report the button row's un-wrapped width as its
	# own minimum size and drag the panel wider than apply() sizes it to
	# (HC-14, requirement 3) -- a FlowContainer's minimum width is the sum
	# of its children on a single line, since it cannot know it will be
	# allowed to wrap until it is actually laid out. Routing through a
	# ScrollContainer hides that from the panel only on the axis where
	# scrolling is enabled -- Godot's ScrollContainer propagates a child's
	# minimum size upward on any axis where its own scroll mode is
	# DISABLED, since it has no way to let overflow there be reached. HC-14
	# left horizontal DISABLED on the assumption that disabling scroll was
	# what hid the width; it does the opposite, and the leaked width shows
	# up once the bubble is narrow enough to force a wrap (LAY-REGR,
	# 10 Sep 2026: gallerin's rect went 108px over budget at 800x600 after a
	# reselect). Both axes need AUTO so neither leaks; the row is still
	# expected to fit within whatever width it is actually given (no real
	# overflow), so no scrollbar should ever appear in practice.
	_bubble_scroll = ScrollContainer.new()
	_bubble_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_bubble_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	bubble.add_child(_bubble_scroll)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	# Without this the column (and everything under it) shrinks to its own
	# minimum width inside the scroll rather than using the width apply()
	# actually gives the bubble (same fix hud.gd's command_content needed).
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bubble_scroll.add_child(column)

	_bubble_label = Label.new()
	_bubble_label.theme_type_variation = "Body"
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The default, VC_CHARS_BEFORE_SHAPING, shapes only the characters
	# visible_characters currently reveals, so _show_bubble()'s
	# visible_characters = 0 measured the combined minimum height of an
	# empty line rather than the full message (UI-X-4). AFTER_SHAPING shapes
	# the whole line first and clips what's drawn afterwards, so the height
	# _apply_layout() reads is correct from the first frame.
	_bubble_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	column.add_child(_bubble_label)
	_apply_bubble_font_size()

	_bubble_pointer = Polygon2D.new()
	_bubble_pointer.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(12, 0), Vector2(0, 8),
	])
	_bubble_pointer.color = UiTheme.color("panel_bg")
	bubble.add_child(_bubble_pointer)

	# HFlowContainer, not HBoxContainer: at the narrowest band and the
	# largest text scale the two buttons no longer fit side by side and
	# must wrap onto a second line rather than pushing the panel wider.
	var row := HFlowContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)

	_history_back_btn = Button.new()
	_history_back_btn.text = "◀"
	_history_back_btn.tooltip_text = "See what Dr Gallerin said before this."
	_history_back_btn.disabled = true
	_history_back_btn.pressed.connect(_on_history_back_pressed)
	_style_button(_history_back_btn)
	row.add_child(_history_back_btn)

	_history_forward_btn = Button.new()
	_history_forward_btn.text = "▶"
	_history_forward_btn.tooltip_text = "Step forward toward the newest line."
	_history_forward_btn.disabled = true
	_history_forward_btn.pressed.connect(_on_history_forward_pressed)
	_style_button(_history_forward_btn)
	row.add_child(_history_forward_btn)

	var dismiss_btn := Button.new()
	dismiss_btn.text = "Dismiss"
	dismiss_btn.pressed.connect(func(): bubble.visible = false)
	row.add_child(dismiss_btn)

	var disable_btn := Button.new()
	disable_btn.text = "Turn off Dr Gallerin"
	disable_btn.pressed.connect(_on_disable_pressed)
	row.add_child(disable_btn)

## The five states a plain Godot Button actually looks up -- see
## debug_panel.gd's identical helper.
func _style_button(button: BaseButton) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))

## ui_layout.gd already preloads this script (to read BUBBLE_WIDTH), so
## this side uses a runtime load() rather than a top-level preload const
## -- a two-way preload const would ask Godot's parser to resolve each
## script's type before the other has finished compiling. ui_panel_layout.gd
## preloads ui_layout.gd itself, so the same cycle rules out preloading it
## here too.
func _ui_layout():
	return load("res://scripts/ui_layout.gd")

func _ui_panel_layout():
	return load("res://scripts/ui_panel_layout.gd")

## Gives the bubble its rectangle the way the tray and summary panel get
## theirs (HC-14), on show and on viewport resize only -- see this script's
## own _ready() and get_viewport().size_changed connection; _process() must
## not gain layout work.
func _apply_layout() -> void:
	var ui_layout = _ui_layout()
	var rect: Rect2 = ui_layout.gallerin_rect(get_viewport().get_visible_rect().size, _settings_panel_rect())
	# The label needs its content-area width before apply() reads the
	# panel's combined minimum height below, or that height is computed
	# from whatever width the label last had.
	_bubble_label.custom_minimum_size.x = rect.size.x - ui_layout.panel_chrome().x
	_ui_panel_layout().apply(bubble, _bubble_scroll, rect, ICON_MARGIN)
	_position_bubble_pointer()

## Empty when the settings window is closed or not yet built (a fresh boot's
## first _apply_layout() call, before _ready() connects its signals below) --
## gallerin_rect() treats an empty rect as "nothing to avoid".
func _settings_panel_rect() -> Rect2:
	var settings_panels := get_tree().get_nodes_in_group("debug_panel")
	if settings_panels.is_empty():
		return Rect2()
	var settings_panel: PanelContainer = settings_panels[0].panel
	if settings_panel == null or not settings_panel.visible:
		return Rect2()
	return settings_panel.get_global_rect()

func _position_bubble_pointer() -> void:
	if _bubble_pointer == null:
		return
	# Both controls share a bottom edge, so this is Gallerin's actual vertical
	# centre even when a longer message makes the bubble grow upward.
	_bubble_pointer.position = Vector2(bubble.size.x, bubble.size.y - ICON_SIZE.y / 2.0)

func _apply_bubble_font_size() -> void:
	_bubble_label.add_theme_font_size_override("font_size", int(round(BUBBLE_TEXT_SIZE * Session.text_scale)))

## Reveals the rest of the current line at once -- shared by click-to-finish
## and by _show_bubble() replacing a still-typing line with a new one.
func _finish_typing() -> void:
	_typed_characters = _typing_target.length()
	_bubble_label.visible_characters = -1

func _on_bubble_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_typing()

func _on_icon_pressed() -> void:
	if _last_message.is_empty():
		return
	_show_bubble(_last_message)

func _on_disable_pressed() -> void:
	Session.gallerin_enabled = false
	visible = false

func _on_history_back_pressed() -> void:
	if _history_index <= 0:
		return
	_history_index -= 1
	_show_history_entry(_history_index)

func _on_history_forward_pressed() -> void:
	if _history_index >= _history.size() - 1:
		return
	_history_index += 1
	_show_history_entry(_history_index)

## Shows one already-recorded line in full, never typed out (HC-6's
## acceptance: "a history entry is shown in full, not typed out"), and
## without touching _history itself.
func _show_history_entry(index: int) -> void:
	var text: String = _history[index]
	_bubble_label.text = text
	_typing_target = text
	_typed_characters = text.length()
	_bubble_label.visible_characters = -1
	bubble.visible = true
	_apply_layout()
	_update_history_buttons()

## Records a newly-shown line for ◀/▶ paging, skipping an exact repeat of
## the last entry so redisplaying the same message (e.g. the icon click
## re-showing _last_message) doesn't duplicate it. Caps at 50 entries,
## dropping the oldest, so a long run cannot grow the array without bound.
func _push_history(text: String) -> void:
	if _history.is_empty() or _history[-1] != text:
		_history.append(text)
		if _history.size() > 50:
			_history.pop_front()
	_history_index = _history.size() - 1

## Disables ◀ on the oldest entry and ▶ on the newest, so the ends are
## visible rather than silent (HC-6's acceptance).
func _update_history_buttons() -> void:
	if _history_back_btn == null:
		return
	_history_back_btn.disabled = _history_index <= 0
	_history_forward_btn.disabled = _history_index >= _history.size() - 1

# --- prompt scheduling ------------------------------------------------

## Called at the start of a sub-stage with its prompt list -- typically a
## "welcome" entry at delay 0.0, then a "hint" and a "stronger_hint" at
## increasing delays, per TUTORIAL_PLAN.md's timing pattern. Replaces
## whatever was queued for the previous sub-stage.
func queue_prompts(prompts: Array) -> void:
	_queue = prompts.duplicate()
	_stage_elapsed = 0.0

## Drops whatever's left in the queue -- called once a sub-stage's goal
## is met, so a "still no progress" hint can't fire after the thing it
## was nudging toward has already happened.
func clear_queue() -> void:
	_queue.clear()

## Shows a prompt immediately, bypassing the delay queue -- for
## completion congratulations and soft-failure recovery lines, which
## fire the instant their triggering event happens rather than on a timer.
func show_now(prompt: Dictionary) -> void:
	if not Session.gallerin_enabled:
		return
	var id: String = prompt.get("id", "")
	if id != "" and not bool(prompt.get("repeatable", false)) and _shown_ids.has(id):
		return
	if id != "":
		_shown_ids[id] = true
	_show_bubble(str(prompt.get("text", "")))

func _fire_due_prompts() -> void:
	if _queue.is_empty():
		return
	# Sorted by delay each time rather than kept pre-sorted, since a
	# queue is short-lived (one sub-stage's worth) and rebuilt often
	# enough that the cost of sorting never shows up.
	_queue.sort_custom(func(a, b): return float(a.get("delay", 0.0)) < float(b.get("delay", 0.0)))
	while not _queue.is_empty() and float(_queue[0].get("delay", 0.0)) <= _stage_elapsed:
		show_now(_queue.pop_front())

func _show_bubble(text: String) -> void:
	if not Session.gallerin_enabled:
		return
	# A new prompt arriving finishes whatever was mid-type rather than
	# leaving it half-revealed underneath the line that replaces it.
	_finish_typing()
	_last_message = text
	_push_history(text)
	_update_history_buttons()
	# The label always holds the whole line so the bubble is laid out (and
	# sized by _apply_layout() below) at its final size from the first
	# frame -- visible_characters clips what's drawn without re-running
	# layout, so the bubble never grows as it types. That relies on
	# _bubble_label.visible_characters_behavior being VC_CHARS_AFTER_SHAPING
	# (set in _build_bubble()); the default shapes only what's visible, so
	# an empty first line would size the bubble to nothing (UI-X-4).
	_bubble_label.text = text
	_typing_target = text
	_typed_characters = 0.0
	_bubble_label.visible_characters = 0
	bubble.visible = true
	# A resize while hidden updates nothing below (Godot does not re-layout
	# an invisible control), so the rectangle could otherwise be stale from
	# whatever viewport size was current the last time the bubble was shown.
	_apply_layout()
