extends RefCounted
## Layout/reserve-rectangle helpers shared by every tray and drawer. See
## UI_PLAN.md section 2.
##
## Usage: const UiLayout = preload("res://scripts/ui_layout.gd")
##        var max_w := UiLayout.command_tray_max_width(viewport_width, tray_w)

## Width of Dr Gallerin's bottom-right reserve above the responsive
## breakpoint -- every other bottom-row tray subtracts this rather than
## guessing at his footprint. Matches gallerin_panel.gd's current
## BUBBLE_WIDTH (260) plus its ICON_MARGIN (16) from the screen edge,
## since the speech bubble, not the icon, is the widest thing that can
## appear in that corner. Becoming a constant gallerin_panel.gd itself
## reads is a follow-up for whichever slice touches that file next
## (UI_PLAN.md section 15, slice 3) -- for now this is the number every
## *other* tray is built against.
const GALLERIN_RESERVE_WIDTH := 276.0

## Below this viewport width, the Gallerin reserve stops being a
## bottom-right box and becomes a full-width strip under the command
## tray instead (UI_PLAN.md section 2).
const NARROW_BREAKPOINT := 1000.0

## Floor width this project's UI is expected to still render at, per
## UI_PLAN.md section 14's acceptance criteria.
const MIN_SUPPORTED_WIDTH := 800.0

static func is_narrow(viewport_width: float) -> bool:
	return viewport_width < NARROW_BREAKPOINT

## Max width the bottom-centre command tray may use: total width minus
## the selection tray and the Gallerin reserve, so the tray respects the
## reserve by construction rather than a magic-number width. Once narrow,
## the reserve becomes its own full-width strip below instead of sharing
## the row, so the command tray only gives up the selection tray's width.
static func command_tray_max_width(viewport_width: float, selection_tray_width: float) -> float:
	if is_narrow(viewport_width):
		return viewport_width - selection_tray_width
	return viewport_width - selection_tray_width - GALLERIN_RESERVE_WIDTH
