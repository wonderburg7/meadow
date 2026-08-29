extends RefCounted
## Layout/reserve-rectangle helpers shared by every tray and drawer. See
## UI_PLAN.md section 2.
##
## Usage: const UiLayout = preload("res://scripts/ui_layout.gd")
##        var max_w := UiLayout.command_tray_max_width(viewport_width)

const GallerinPanel = preload("res://scripts/gallerin_panel.gd")

## Dr Gallerin's bubble width for this viewport -- shrinks alongside the
## summary panel's own narrow-width step so the role/command tray never
## has to guess how much space he still needs at a narrow window size.
static func gallerin_bubble_width(viewport_width: float) -> float:
	return GallerinPanel.BUBBLE_WIDTH * 0.75 if is_narrow(viewport_width) else GallerinPanel.BUBBLE_WIDTH

## Width of Dr Gallerin's bottom-right reserve for this viewport -- every
## other bottom-row tray subtracts this rather than guessing at his
## footprint. Built from his own bubble width plus his icon margin,
## rather than duplicating either number.
static func gallerin_reserve_width(viewport_width: float) -> float:
	return gallerin_bubble_width(viewport_width) + GallerinPanel.ICON_MARGIN

## Below this viewport width, the Gallerin reserve shrinks (see
## gallerin_bubble_width) rather than disappearing -- command_tray_max_width
## always leaves room for it, at any width, so the role/command tray can
## never render underneath the bubble (UI-J/UI-I; Dave's 29 Aug report was
## exactly this at a narrow window size).
const NARROW_BREAKPOINT := 1000.0

## Floor width this project's UI is expected to still render at, per
## UI_PLAN.md section 14's acceptance criteria.
const MIN_SUPPORTED_WIDTH := 800.0

## The nominal reservation command_tray_max_width assumes the bottom-left
## summary panel needs, above/below the responsive breakpoint. Not the
## panel's own rendered width any more (see selection_tray_width below,
## UI-H) -- just this tray's own budget input, so its share of the row
## doesn't depend on a circular read of the panel it shares the row with.
const SELECTION_TRAY_RESERVE := 390.0
const SELECTION_TRAY_RESERVE_NARROW := 312.0

## Fixed left margin hud.gd anchors the summary panel at (selection_panel
## .offset_left) and the gap Dave asked for (29 Aug) between the panel's
## own right edge and the command tray's reserved zone -- one constant so
## selection_tray_width and hud.gd's own anchor offset can't drift apart.
const SELECTION_TRAY_LEFT_MARGIN := 16.0
const SELECTION_TRAY_GAP := 16.0

static func is_narrow(viewport_width: float) -> bool:
	return viewport_width < NARROW_BREAKPOINT

## Max width the bottom-centre command tray may use: total width minus a
## nominal reservation for the summary panel and the Gallerin reserve, so
## the tray respects both by construction rather than a magic-number
## width. 10% more than before (Dave's 29 Aug tuning pass on UI-H's
## first-pass split) -- 0.7 -> 0.77.
static func command_tray_max_width(viewport_width: float) -> float:
	var reserve: float = SELECTION_TRAY_RESERVE_NARROW if is_narrow(viewport_width) else SELECTION_TRAY_RESERVE
	return (viewport_width - reserve - gallerin_reserve_width(viewport_width)) * 0.77

## The selection/summary panel's width for this viewport -- a function of
## viewport size alone, never of what the panel currently shows (UI-B).
## Rather than a fixed per-breakpoint width, it now fills whatever room is
## actually left between its own fixed left margin and the command tray's
## reserved zone, minus SELECTION_TRAY_GAP (Dave's 29 Aug ask) -- the tray
## is centred, so its reserved zone's left edge is symmetric about the
## viewport's centre.
static func selection_tray_width(viewport_width: float) -> float:
	var tray_cap: float = command_tray_max_width(viewport_width)
	var tray_left_edge: float = (viewport_width - tray_cap) / 2.0
	return tray_left_edge - SELECTION_TRAY_GAP - SELECTION_TRAY_LEFT_MARGIN
