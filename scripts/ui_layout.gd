extends RefCounted
## Layout/reserve-rectangle helpers shared by every tray and drawer. See
## UI_PLAN.md section 2.
##
## Usage: const UiLayout = preload("res://scripts/ui_layout.gd")
##        var max_w := UiLayout.command_tray_max_width(viewport_width, tray_w)

const GallerinPanel = preload("res://scripts/gallerin_panel.gd")

## Width of Dr Gallerin's bottom-right reserve above the responsive
## breakpoint -- every other bottom-row tray subtracts this rather than
## guessing at his footprint. Reads gallerin_panel.gd's own
## RESERVE_WIDTH constant rather than duplicating the number.
const GALLERIN_RESERVE_WIDTH := GallerinPanel.RESERVE_WIDTH

## Below this viewport width, the Gallerin reserve stops being a
## bottom-right box and becomes a full-width strip under the command
## tray instead (UI_PLAN.md section 2).
const NARROW_BREAKPOINT := 1000.0

## Floor width this project's UI is expected to still render at, per
## UI_PLAN.md section 14's acceptance criteria.
const MIN_SUPPORTED_WIDTH := 800.0

## Fixed width of the bottom-left summary/selection panel above the
## responsive breakpoint. Bee/cell/flower content must never change this
## (UI_PLAN.md UI-B) -- callers pair it with autowrap on every label rather
## than letting a long line stretch the panel.
const SELECTION_TRAY_WIDTH := 300.0

## Selection tray width once narrow, matching the command tray's own
## breakpoint so the two rows still fit side by side down to
## MIN_SUPPORTED_WIDTH.
const SELECTION_TRAY_WIDTH_NARROW := 240.0

static func is_narrow(viewport_width: float) -> bool:
	return viewport_width < NARROW_BREAKPOINT

## The selection/summary panel's width for this viewport -- a function of
## viewport size alone, never of what the panel currently shows.
static func selection_tray_width(viewport_width: float) -> float:
	return SELECTION_TRAY_WIDTH_NARROW if is_narrow(viewport_width) else SELECTION_TRAY_WIDTH

## Max width the bottom-centre command tray may use: total width minus
## the selection tray and the Gallerin reserve, so the tray respects the
## reserve by construction rather than a magic-number width. Once narrow,
## the reserve becomes its own full-width strip below instead of sharing
## the row, so the command tray only gives up the selection tray's width.
static func command_tray_max_width(viewport_width: float, selection_tray_width: float) -> float:
	if is_narrow(viewport_width):
		return viewport_width - selection_tray_width
	return viewport_width - selection_tray_width - GALLERIN_RESERVE_WIDTH
