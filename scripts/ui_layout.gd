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
## Floor height, the same basis as the width above (RR-4).
const MIN_SUPPORTED_HEIGHT := 600.0

## One clearance value separates any two of the hierarchy's persistent
## panels -- command tray, bottom-row side bands, left-side windows -- and
## any one of them from a screen edge (plans/archive/LAY-1_2026-09-08.md,
## "The hierarchy, decided"). The three names below keep every existing
## call site working while leaving one number to change.
const PANEL_GAP := 16.0
const SELECTION_TRAY_LEFT_MARGIN := PANEL_GAP
const SELECTION_TRAY_GAP := PANEL_GAP
const SELECTION_TRAY_MIN_WIDTH := 160.0

## Width reserved on the right of any left-side window's content so a
## vertical ScrollContainer bar never covers it (Dave, 9 Sep 2026, C-26).
const SCROLLBAR_GUTTER := 14.0

## Shared bottom margin of the summary panel and the command tray, so the
## two sit level with each other.
const BOTTOM_ROW_MARGIN := PANEL_GAP

## The command tray takes half the viewport until either side needs its
## minimum band. It never becomes narrower than a usable control row.
const COMMAND_TRAY_WIDTH_FRACTION := 0.5
const COMMAND_TRAY_MIN_WIDTH := 200.0
const GALLERIN_BUBBLE_MIN_WIDTH := 200.0

## The bubble may grow no taller than this fraction of the viewport (Dave,
## 12 Sep 2026: "make it so it can take up to a third of the height of the
## window") -- a tighter ceiling than command_tray_max_height() everywhere
## except the narrowest windows, where that ceiling is already lower.
const GALLERIN_MAX_HEIGHT_FRACTION := 1.0 / 3.0

## The settings window: up to a quarter of the viewport's width, never
## narrower than its old fixed width (Dave: "up to 25%", UI-X-1).
const SETTINGS_WINDOW_MIN_WIDTH := 320.0
const SETTINGS_WINDOW_WIDTH_FRACTION := 0.25

static func settings_window_width(viewport_width: float) -> float:
	return maxf(SETTINGS_WINDOW_MIN_WIDTH, viewport_width * SETTINGS_WINDOW_WIDTH_FRACTION)

## Left-side windows start beneath the live corner column, then use the same
## clearance as the bottom-row panels. Their content scrolls within the
## remaining screen height rather than covering either edge.
static func left_window_top(corner_bottom: float) -> float:
	return corner_bottom + SELECTION_TRAY_GAP

## `bottom_row_top` is hud.selection_panel_top(): 0 when nothing is
## selected, otherwise the y the summary panel starts at. A left-side
## window shortens to clear it rather than covering it (Dave, 8 Sep 2026).
## Returns the window's outer height; ui_panel_layout.gd::apply() subtracts
## the chrome itself when it turns this into the scroll's budget.
static func left_window_max_height(
	viewport_height: float, top: float, bottom_row_top: float = 0.0
) -> float:
	var floor_y: float = viewport_height
	if bottom_row_top > 0.0:
		floor_y = bottom_row_top
	return maxf(120.0, floor_y - top - SELECTION_TRAY_GAP)

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
## icon margin and bubble-to-icon gap. GALLERIN_BUBBLE_MIN_WIDTH keeps it
## readable at narrow widths even when the band itself is narrower than
## that floor -- a content concern gallerin_panel.gd's wrapping button row
## absorbs (HC-14), not a width this function promises the band can hold.
static func gallerin_bubble_width(viewport_width: float) -> float:
	var tray_width := command_tray_width(viewport_width)
	var tray_right_edge := command_tray_left_edge(viewport_width) + tray_width
	var right_band := viewport_width - tray_right_edge
	var available := right_band - SELECTION_TRAY_GAP - GallerinPanel.ICON_SIZE.x - GallerinPanel.BUBBLE_GAP - GallerinPanel.ICON_MARGIN
	return clampf(available, GALLERIN_BUBBLE_MIN_WIDTH, GallerinPanel.BUBBLE_WIDTH)

## Chrome UiTheme.panel_stylebox() adds around a panel's content -- content
## margin plus border width, per axis. A budget for a panel's outer
## rectangle must subtract this before it is applied to a control living
## inside that panel; every such conversion goes through this rather than
## writing the sum out again. See ui_panel_layout.gd::apply().
static func panel_chrome() -> Vector2:
	var box := UiTheme.panel_stylebox()
	return Vector2(
		box.content_margin_left + box.content_margin_right + 2.0 * UiTheme.PANEL_BORDER_WIDTH,
		box.content_margin_top + box.content_margin_bottom + 2.0 * UiTheme.PANEL_BORDER_WIDTH
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
## height is capped at the same ceiling the tray gets -- the panel hugs
## shorter content already (see ui_panel_layout.gd::apply()).
static func summary_panel_rect(viewport_size: Vector2) -> Rect2:
	return Rect2(SELECTION_TRAY_LEFT_MARGIN, 0.0, selection_tray_width(viewport_size.x),
			command_tray_max_height(viewport_size.y))

## Dr Gallerin's bubble: the bottom-right counterpart of summary_panel_rect,
## its left edge PANEL_GAP past the command tray's right edge rather than a
## fixed left margin. Its width can fall short of reaching the icon when
## gallerin_bubble_width() clamps to its floor -- see that function's own
## comment; this rectangle does not compensate for it.
##
## Height is capped at GALLERIN_MAX_HEIGHT_FRACTION of the viewport (Dave,
## 12 Sep 2026), tighter than command_tray_max_height() except at the
## narrowest windows. `avoid`, when non-empty and sharing the bubble's
## horizontal span, is the settings window's rect (Dave, 17 Sep 2026: "unless
## the settings window is in the way ... shorten and use the scroll bar") --
## the ceiling then shortens to clear it by PANEL_GAP, floored at one line's
## height so the bubble never collapses to nothing.
static func gallerin_rect(viewport_size: Vector2, avoid: Rect2 = Rect2()) -> Rect2:
	var tray_right_edge := command_tray_left_edge(viewport_size.x) + command_tray_width(viewport_size.x)
	var width := gallerin_bubble_width(viewport_size.x)
	var left := tray_right_edge + PANEL_GAP
	var ceiling := minf(command_tray_max_height(viewport_size.y), viewport_size.y * GALLERIN_MAX_HEIGHT_FRACTION)
	if avoid.size != Vector2.ZERO and left < avoid.position.x + avoid.size.x and left + width > avoid.position.x:
		var bubble_bottom := viewport_size.y - GallerinPanel.ICON_MARGIN
		var one_line := GallerinPanel.BUBBLE_TEXT_SIZE * 2.0 + panel_chrome().y
		ceiling = maxf(one_line, minf(ceiling, bubble_bottom - (avoid.position.y + avoid.size.y + PANEL_GAP)))
	return Rect2(left, 0.0, width, ceiling)

## A left-side window (Colony/Foraging/Nursery): fixed width, x pinned at
## the shared left margin, top and height following the corner readout and
## the bottom row per left_window_top()/left_window_max_height().
static func left_window_rect(viewport_size: Vector2, width: float, corner_bottom: float, bottom_row_top: float = 0.0) -> Rect2:
	var top := left_window_top(corner_bottom)
	var height := left_window_max_height(viewport_size.y, top, bottom_row_top)
	return Rect2(SELECTION_TRAY_LEFT_MARGIN, top, width, height)
