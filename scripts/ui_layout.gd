extends RefCounted
## Bottom-row layout helpers shared by the summary panel, command tray and
## Dr Gallerin. The tray leads: it is centred, and its neighbours derive their
## widths from the space left on either side.
##
## Usage: const UiLayout = preload("res://scripts/ui_layout.gd")

const GallerinPanel = preload("res://scripts/gallerin_panel.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")

## Floor width this project's UI is expected to still render at, per
## UI_PLAN.md section 14's acceptance criteria.
const MIN_SUPPORTED_WIDTH := 800.0

## One clearance value separates any two of the hierarchy's persistent
## panels -- command tray, bottom-row side bands, left-side windows -- and
## any one of them from a screen edge (plans/archive/LAY-1_2026-09-08.md,
## "The hierarchy, decided"). The three names below keep every existing
## call site working while leaving one number to change.
const PANEL_GAP := 16.0
const SELECTION_TRAY_LEFT_MARGIN := PANEL_GAP
const SELECTION_TRAY_GAP := PANEL_GAP
const SELECTION_TRAY_MIN_WIDTH := 160.0

## Shared bottom margin of the summary panel and the command tray, so the
## two sit level with each other.
const BOTTOM_ROW_MARGIN := PANEL_GAP

## The command tray takes half the viewport until either side needs its
## minimum band. It never becomes narrower than a usable control row.
const COMMAND_TRAY_WIDTH_FRACTION := 0.5
const COMMAND_TRAY_MIN_WIDTH := 200.0
const GALLERIN_BUBBLE_MIN_WIDTH := 200.0

## Left-side windows start beneath the live corner column, then use the same
## clearance as the bottom-row panels. Their content scrolls within the
## remaining screen height rather than covering either edge.
static func left_window_top(corner_bottom: float) -> float:
	return corner_bottom + SELECTION_TRAY_GAP

## `bottom_row_top` is hud.selection_panel_top(): 0 when nothing is
## selected, otherwise the y the summary panel starts at. A left-side
## window shortens to clear it rather than covering it (Dave, 8 Sep 2026).
static func left_window_max_height(
	viewport_height: float, top: float, bottom_row_top: float = 0.0
) -> float:
	var floor_y: float = viewport_height
	if bottom_row_top > 0.0:
		floor_y = bottom_row_top
	return maxf(120.0, floor_y - top - SELECTION_TRAY_GAP - panel_chrome().y)

## The tallest the bottom-row command tray may be: everything between the
## top of the screen and its own bottom margin, less the shared clearance.
## Nothing in the bottom row may exceed this -- see plans/now/ui.md's
## "No persistent panel may extend past a viewport edge" rule.
static func command_tray_max_height(viewport_height: float) -> float:
	return maxf(120.0, viewport_height - BOTTOM_ROW_MARGIN - SELECTION_TRAY_GAP)

## The minimum amount each half of the centred bottom row needs. The summary
## side includes its screen margin, while the Gallerin side includes the
## bubble, icon and their offsets. The latter is currently wider (300px), but
## keeping both expressions here makes the geometry remain true if either UI
## changes later.
static func _bottom_row_side_min_width() -> float:
	var selection_min := SELECTION_TRAY_LEFT_MARGIN + SELECTION_TRAY_GAP + SELECTION_TRAY_MIN_WIDTH
	var gallerin_min := SELECTION_TRAY_GAP + GALLERIN_BUBBLE_MIN_WIDTH + GallerinPanel.ICON_SIZE.x + GallerinPanel.BUBBLE_GAP + GallerinPanel.ICON_MARGIN
	return maxf(selection_min, gallerin_min)

## Width of the centred bottom command tray. It follows half the viewport
## until doing so would leave either neighbour less than its minimum band.
static func command_tray_width(viewport_width: float) -> float:
	var side_min := _bottom_row_side_min_width()
	var widest_that_keeps_bands := viewport_width - 2.0 * side_min
	return maxf(COMMAND_TRAY_MIN_WIDTH, minf(viewport_width * COMMAND_TRAY_WIDTH_FRACTION, widest_that_keeps_bands))

## The tray is centred because both side bands derive from it.
static func command_tray_left_edge(viewport_width: float) -> float:
	return (viewport_width - command_tray_width(viewport_width)) * 0.5

## The selection/summary panel fills the space between its fixed left margin
## and the command tray, keeping the shared gap clear.
static func selection_tray_width(viewport_width: float) -> float:
	return maxf(0.0, command_tray_left_edge(viewport_width) - SELECTION_TRAY_GAP - SELECTION_TRAY_LEFT_MARGIN)

## Dr Gallerin's bubble fills the right side band after the tray gap, icon,
## icon margin and bubble-to-icon gap. It remains readable at narrow widths.
static func gallerin_bubble_width(viewport_width: float) -> float:
	var tray_width := command_tray_width(viewport_width)
	var tray_right_edge := command_tray_left_edge(viewport_width) + tray_width
	var right_band := viewport_width - tray_right_edge
	var available := right_band - SELECTION_TRAY_GAP - GallerinPanel.ICON_SIZE.x - GallerinPanel.BUBBLE_GAP - GallerinPanel.ICON_MARGIN
	return clampf(available, GALLERIN_BUBBLE_MIN_WIDTH, GallerinPanel.BUBBLE_WIDTH)

## Dr Gallerin's complete bottom-right footprint, for callers that need it.
static func gallerin_reserve_width(viewport_width: float) -> float:
	return gallerin_bubble_width(viewport_width) + GallerinPanel.ICON_SIZE.x + GallerinPanel.BUBBLE_GAP + GallerinPanel.ICON_MARGIN

## Chrome UiTheme.panel_stylebox() adds around a panel's content -- content
## margin plus border width, per axis. A budget for a panel's outer
## rectangle must subtract this before it is applied to a control living
## inside that panel; every such conversion goes through this rather than
## writing the sum out again. See ui_panel_layout.gd::apply().
static func panel_chrome() -> Vector2:
	var box := UiTheme.panel_stylebox()
	return Vector2(
		box.content_margin_left + box.content_margin_right + box.border_width_left + box.border_width_right,
		box.content_margin_top + box.content_margin_bottom + box.border_width_top + box.border_width_bottom
	)

## --- persistent-rectangle owners ---------------------------------------
## One function per rectangle in the hierarchy, each returning the panel's
## outer Rect2 for a given viewport. The width/edge/height helpers above
## are these functions' internals now -- a panel script calls one of the
## four below and ui_panel_layout.gd::apply(), never the helpers directly.

## The bottom-centre command tray: centred, sized by its own content up to
## command_tray_max_height(). Rect.size.y is that ceiling, not the tray's
## actual height -- the tray shrinks below it to fit shorter content, which
## only apply()'s caller can measure (see hud.gd::_resize_command_tray).
static func command_tray_rect(viewport_size: Vector2) -> Rect2:
	var width := command_tray_width(viewport_size.x)
	var height := command_tray_max_height(viewport_size.y)
	return Rect2(command_tray_left_edge(viewport_size.x), viewport_size.y - BOTTOM_ROW_MARGIN - height, width, height)

## The bottom-left summary panel: takes the width the tray leaves. Its
## height is uncapped -- position.y/size.y are unused (0) placeholders, since
## the panel auto-grows to its content on every axis apply() does not set
## explicitly (see ui_panel_layout.gd::apply()'s no-scroll branch).
static func summary_panel_rect(viewport_size: Vector2) -> Rect2:
	return Rect2(SELECTION_TRAY_LEFT_MARGIN, 0.0, selection_tray_width(viewport_size.x), 0.0)

## Dr Gallerin's bubble: the bottom-right counterpart of summary_panel_rect,
## anchored from the tray's right edge rather than the left margin. Not yet
## wired to a caller -- gallerin_panel.gd manages its own bottom-right
## anchoring and keeps calling gallerin_bubble_width() directly.
static func gallerin_rect(viewport_size: Vector2) -> Rect2:
	var width := gallerin_bubble_width(viewport_size.x)
	var right := viewport_size.x - (GallerinPanel.ICON_MARGIN + GallerinPanel.ICON_SIZE.x + GallerinPanel.BUBBLE_GAP)
	return Rect2(right - width, 0.0, width, 0.0)

## A left-side window (Colony/Foraging/Nursery): fixed width, x pinned at
## the shared left margin, top and height following the corner readout and
## the bottom row per left_window_top()/left_window_max_height().
static func left_window_rect(viewport_size: Vector2, width: float, corner_bottom: float, bottom_row_top: float = 0.0) -> Rect2:
	var top := left_window_top(corner_bottom)
	var height := left_window_max_height(viewport_size.y, top, bottom_row_top)
	return Rect2(SELECTION_TRAY_LEFT_MARGIN, top, width, height)
