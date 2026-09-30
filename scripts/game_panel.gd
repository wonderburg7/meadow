class_name GamePanel
extends CanvasLayer
## Shared base for the HUD windows (colony, foraging, nursery, winter and the
## Gallerin bubble): owns process_mode, layer, group registration, the themed
## PanelContainer, the left-window rectangle and open/close/toggle/is_open.
## Each subclass keeps only its own content and its own refresh().
##
## Every panel joins the "game_panel" group under its window_key, so
## scenario_actions.gd resolves names by walking the group rather than by
## a hand-kept match. Left-side windows (Winter included) also join
## "left_window"; the Gallerin bubble deliberately does not.

const UiLayout = preload("res://scripts/ui_layout.gd")
const UiPanelLayout = preload("res://scripts/ui_panel_layout.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")

signal closed()

var panel: PanelContainer
var main: Node2D
var scroll_container: ScrollContainer
## The name scenario_actions.gd and the registry know this window by.
var window_key: String = ""

## Call first in _ready(). `group` is the panel's own legacy group name.
func setup_layer(key: String, group: String, layer_value: int = 11) -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = layer_value
	window_key = key
	add_to_group(group)
	add_to_group("game_panel")
	main = get_parent() as Node2D

## Builds the themed, initially hidden PanelContainer. Left windows anchor
## top-left with the tray margin and re-flow on viewport / bottom-row change.
func build_left_window(min_width: float) -> void:
	_build_panel(min_width)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = UiLayout.SELECTION_TRAY_LEFT_MARGIN
	add_to_group("left_window")

## Top-right anchoring for windows opened from the button bar.
func build_top_right_window(min_width: float, top: float, right: float) -> void:
	_build_panel(min_width)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_top = top
	panel.offset_right = right

func _build_panel(min_width: float) -> void:
	panel = PanelContainer.new()
	panel.theme = UiTheme.build_theme()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	panel.custom_minimum_size = Vector2(min_width, 0)
	panel.visible = false
	add_child(panel)

## Adds the standard vertically scrolling body to a left window.
func build_scroll_body() -> void:
	scroll_container = ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(scroll_container)

## Call last in a left window's _ready(), once main.hud exists.
func connect_left_window_reflow() -> void:
	get_viewport().size_changed.connect(_apply_left_window_rect)
	main.hud.bottom_row_changed.connect(_on_bottom_row_changed)

func _apply_left_window_rect() -> void:
	var rect := UiLayout.left_window_rect(
		get_viewport().get_visible_rect().size, panel.custom_minimum_size.x,
		main.hud.corner_bottom(), main.hud.selection_panel_top()
	)
	panel.offset_top = rect.position.y
	UiPanelLayout.apply(panel, scroll_container, rect)

## The bottom row (summary panel) changed height while this window may
## already be open -- reflow it rather than waiting for the next open().
func _on_bottom_row_changed() -> void:
	if panel.visible:
		_apply_left_window_rect()

## The control whose rectangle layout assertions measure.
func rect_control() -> Control:
	return panel

func toggle() -> void:
	if is_open():
		close()
	else:
		open()

func open() -> void:
	if is_in_group("left_window"):
		_apply_left_window_rect()
	panel.visible = true

func close() -> void:
	panel.visible = false
	closed.emit()

func is_open() -> bool:
	return panel.visible
