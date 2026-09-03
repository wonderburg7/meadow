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
## footprint. Built from the bubble, icon and shared gap constants rather
## than a duplicate magic number.
static func gallerin_reserve_width(viewport_width: float) -> float:
	# The bubble now sits left of Gallerin's icon, so the protected bottom-right
	# footprint includes both controls and the gap between them.
	return gallerin_bubble_width(viewport_width) + GallerinPanel.ICON_SIZE.x + GallerinPanel.BUBBLE_GAP + GallerinPanel.ICON_MARGIN

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
## A real floor for the command tray.  At the narrowest supported width the
## nominal reservations can leave less than a usable control width; both the
## tray and the summary-panel calculation must use this same floor so their
## rectangles still remain disjoint.
const COMMAND_TRAY_MIN_WIDTH := 200.0

## Breathing room between the command tray and each of its two neighbours:
## the summary panel's reserved zone on the left, Dr Gallerin's on the
## right. UI-R-1 replaced a `* 0.924` shrink with this. That factor was
## standing in for a centring correction the tray never actually applied
## -- the tray was anchored to the viewport's centre while its two reserves
## are unequal (390 left, 544 right), so it sat 77px right of the band's
## own centre. The factor clawed back only half of that, which left a 39px
## overlap into Gallerin's reserve at 1920 and a 64px one at 1280, and cost
## tray width at every other size. The edge is now stated outright instead
## (command_tray_left_edge), so no fudge factor is needed.
const COMMAND_TRAY_SIDE_GAP := 16.0

static func is_narrow(viewport_width: float) -> bool:
	return viewport_width < NARROW_BREAKPOINT

## Everything the bottom row reserves to the left of the command tray: the
## summary panel's fixed left margin, the panel's nominal width for this
## viewport, and the gap Dave asked for (29 Aug) between the panel and the
## tray. The tray's left edge is one COMMAND_TRAY_SIDE_GAP right of this.
static func command_tray_left_reserve(viewport_width: float) -> float:
	var reserve: float = SELECTION_TRAY_RESERVE_NARROW if is_narrow(viewport_width) else SELECTION_TRAY_RESERVE
	return SELECTION_TRAY_LEFT_MARGIN + reserve + SELECTION_TRAY_GAP

## Max width the bottom command tray may use: the whole band left between
## the two reserves, less one side gap at each end, so the tray respects
## both by construction rather than by a magic-number width or a shrink
## factor. The shared floor keeps the selection panel from reserving a
## narrower rectangle than the tray can use.
static func command_tray_max_width(viewport_width: float) -> float:
	var band: float = viewport_width - command_tray_left_reserve(viewport_width) - gallerin_reserve_width(viewport_width)
	return maxf(COMMAND_TRAY_MIN_WIDTH, band - 2.0 * COMMAND_TRAY_SIDE_GAP)

## Where the command tray's left edge sits (UI-R-1). hud.gd anchors the
## tray to this rather than to the viewport's centre, which is what used to
## push it right into Dr Gallerin's reserve: the two reserves are unequal,
## so the band's centre is not the viewport's.
##
## Clamped on both sides. Once COMMAND_TRAY_MIN_WIDTH's floor takes over at
## a very narrow viewport the band is smaller than the tray, and something
## has to give: the tray slides left, so it keeps clear of Gallerin's
## reserve and eats into the summary panel's instead, rather than vanishing
## off the right-hand edge. It never moves left of the panel's own margin.
static func command_tray_left_edge(viewport_width: float) -> float:
	var nominal: float = command_tray_left_reserve(viewport_width) + COMMAND_TRAY_SIDE_GAP
	var rightmost: float = viewport_width - gallerin_reserve_width(viewport_width) - command_tray_max_width(viewport_width)
	return maxf(SELECTION_TRAY_LEFT_MARGIN, minf(nominal, rightmost))

## The selection/summary panel's width for this viewport -- a function of
## viewport size alone, never of what the panel currently shows (UI-B).
## Rather than a fixed per-breakpoint width, it fills whatever room is left
## between its own fixed left margin and the command tray's left edge,
## minus SELECTION_TRAY_GAP (Dave's 29 Aug ask). Since UI-R-1 it reads that
## edge from command_tray_left_edge rather than recomputing it from the
## tray's cap, so the panel and the tray cannot disagree about where the
## boundary between them is.
static func selection_tray_width(viewport_width: float) -> float:
	return maxf(0.0, command_tray_left_edge(viewport_width) - SELECTION_TRAY_GAP - SELECTION_TRAY_LEFT_MARGIN)
