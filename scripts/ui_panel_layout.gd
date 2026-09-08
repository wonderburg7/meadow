extends RefCounted
## Applies a UiLayout outer-rectangle budget to a persistent HUD panel --
## the floor/ceiling split each panel used to redo for itself, and
## sometimes get wrong (plans/archive/LAY-1_2026-09-08.md's Cause 1-3).
##
## Usage: const UiPanelLayout = preload("res://scripts/ui_panel_layout.gd")

const UiLayout = preload("res://scripts/ui_layout.gd")

## rect is the panel's outer budget for this layout pass.
##
## Every assignment here is to an offset, never to size: Control.set_size()
## -- which panel.size.x = w and reset_size() both call -- recomputes all
## four anchor offsets from the cached position, so it silently converts a
## bottom-anchored panel's bottom pin into a top pin and the panel then
## regrows downwards past the bottom of the viewport. This is the one place
## allowed to size a persistent panel; callers must never call reset_size()
## or assign panel.size/panel.size.x afterwards.
##
## bottom_margin >= 0.0 pins the panel that many pixels above the viewport's
## bottom edge (anchor_top = anchor_bottom = 1.0); the default, negative,
## pins it at rect.position.y from the top instead.
##
## scroll is the one control allowed to be smaller than its contents
## (Cause 1): rect's chrome-trimmed size is a ceiling on its
## custom_minimum_size, real because a ScrollContainer's own minimum on the
## axis it scrolls is ~0 (Cause 2 -- never read that minimum through the
## ScrollContainer itself; scroll.get_child(0) is what actually holds the
## content). The panel hugs shorter content rather than always filling the
## ceiling, so the budget is capped again at the child's own minimum height.
static func apply(panel: PanelContainer, scroll: ScrollContainer, rect: Rect2,
		bottom_margin: float = -1.0) -> void:
	# Horizontal. Every persistent panel here uses anchor_left =
	# anchor_right = 0 (PRESET_TOP_LEFT and PRESET_BOTTOM_LEFT both do),
	# so these two offsets are the rectangle's left and right edges outright.
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.offset_left = rect.position.x
	panel.offset_right = rect.position.x + rect.size.x

	if scroll != null:
		var budget: Vector2 = rect.size - UiLayout.panel_chrome()
		budget.x = maxf(0.0, budget.x)
		budget.y = maxf(0.0, budget.y)
		var content := scroll.get_child(0) as Control
		if content != null:
			budget.y = minf(budget.y, content.get_combined_minimum_size().y)
		scroll.custom_minimum_size = budget

	# Vertical. rect.size.y is the ceiling; the panel hugs shorter content.
	var height: float = minf(panel.get_combined_minimum_size().y, rect.size.y)
	if bottom_margin >= 0.0:
		panel.anchor_top = 1.0
		panel.anchor_bottom = 1.0
		panel.offset_bottom = -bottom_margin
		panel.offset_top = panel.offset_bottom - height
	else:
		panel.anchor_top = 0.0
		panel.anchor_bottom = 0.0
		panel.offset_top = rect.position.y
		panel.offset_bottom = rect.position.y + height
