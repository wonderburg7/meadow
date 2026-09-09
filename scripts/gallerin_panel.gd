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

var _icon_button: Button
var _bubble: PanelContainer
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
	_apply_layout()

func _process(delta: float) -> void:
	_stage_elapsed += delta
	_fire_due_prompts()
	if Session.text_scale != _last_text_scale:
		_last_text_scale = Session.text_scale
		_apply_bubble_font_size()

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
	_bubble = PanelContainer.new()
	_bubble.visible = false
	_bubble.custom_minimum_size = Vector2(BUBBLE_WIDTH, 0)
	_bubble.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_bubble.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_bubble.grow_vertical = Control.GROW_DIRECTION_BEGIN
	# The message belongs beside Gallerin, not above him: leave a small gap
	# between its pointer and the icon at the bottom-right corner.
	_bubble.offset_right = -(ICON_MARGIN + ICON_SIZE.x + BUBBLE_GAP)
	_bubble.offset_bottom = -ICON_MARGIN
	_bubble.theme = UiTheme.build_theme()
	_bubble.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	_bubble.mouse_entered.connect(func(): _hovering_bubble = true)
	_bubble.mouse_exited.connect(func(): _hovering_bubble = false)
	_bubble.resized.connect(_position_bubble_pointer)
	add_child(_bubble)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_bubble.add_child(column)

	_bubble_label = Label.new()
	_bubble_label.theme_type_variation = "Body"
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_label.custom_minimum_size = Vector2(BUBBLE_WIDTH - 28.0, 0)
	column.add_child(_bubble_label)
	_apply_bubble_font_size()

	_bubble_pointer = Polygon2D.new()
	_bubble_pointer.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(12, 0), Vector2(0, 8),
	])
	_bubble_pointer.color = UiTheme.color("panel_bg")
	_bubble.add_child(_bubble_pointer)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)

	var dismiss_btn := Button.new()
	dismiss_btn.text = "Dismiss"
	dismiss_btn.pressed.connect(func(): _bubble.visible = false)
	row.add_child(dismiss_btn)

	var disable_btn := Button.new()
	disable_btn.text = "Turn off Dr Gallerin"
	disable_btn.pressed.connect(_on_disable_pressed)
	row.add_child(disable_btn)

## ui_layout.gd already preloads this script (to read BUBBLE_WIDTH), so
## this side uses a runtime load() rather than a top-level preload const
## -- a two-way preload const would ask Godot's parser to resolve each
## script's type before the other has finished compiling.
func _ui_layout():
	return load("res://scripts/ui_layout.gd")

## Mirrors the summary panel's own viewport-driven width step
## (hud.gd::_apply_selection_tray_width) so the bubble never grows into
## the role/command tray's space at a narrow window size.
func _apply_layout() -> void:
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	var width: float = _ui_layout().gallerin_bubble_width(viewport_width)
	_bubble.custom_minimum_size.x = width
	_bubble_label.custom_minimum_size.x = width - 28.0
	_position_bubble_pointer()

func _position_bubble_pointer() -> void:
	if _bubble_pointer == null:
		return
	# Both controls share a bottom edge, so this is Gallerin's actual vertical
	# centre even when a longer message makes the bubble grow upward.
	_bubble_pointer.position = Vector2(_bubble.size.x, _bubble.size.y - ICON_SIZE.y / 2.0)

func _apply_bubble_font_size() -> void:
	_bubble_label.add_theme_font_size_override("font_size", int(round(BUBBLE_TEXT_SIZE * Session.text_scale)))

func _on_icon_pressed() -> void:
	if _last_message.is_empty():
		return
	_show_bubble(_last_message)

func _on_disable_pressed() -> void:
	Session.gallerin_enabled = false
	visible = false

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
	_last_message = text
	_bubble_label.text = text
	_bubble.visible = true
