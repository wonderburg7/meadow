extends RefCounted
## Bottom-row layout helpers shared by the summary panel, command tray and
## Dr Gallerin. The tray leads: it is centred, and its neighbours derive their
## widths from the space left on either side.
##
## Usage: const UiLayout = preload("res://scripts/ui_layout.gd")

const GallerinPanel = preload("res://scripts/gallerin_panel.gd")

## Floor width this project's UI is expected to still render at, per
## UI_PLAN.md section 14's acceptance criteria.
const MIN_SUPPORTED_WIDTH := 800.0

## Fixed left margin of the summary panel, and the shared clearance either
## side of the command tray.
const SELECTION_TRAY_LEFT_MARGIN := 16.0
const SELECTION_TRAY_GAP := 16.0
const SELECTION_TRAY_MIN_WIDTH := 160.0

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

static func left_window_max_height(viewport_height: float, top: float) -> float:
	return maxf(120.0, viewport_height - top - SELECTION_TRAY_GAP)

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
