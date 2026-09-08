extends RefCounted
## Applies a UiLayout outer-rectangle budget to a persistent HUD panel --
## the floor/ceiling split each panel used to redo for itself, and
## sometimes get wrong (plans/archive/LAY-1_2026-09-08.md's Cause 1-3).
##
## Usage: const UiPanelLayout = preload("res://scripts/ui_panel_layout.gd")

const UiLayout = preload("res://scripts/ui_layout.gd")

## rect is the panel's outer budget for this layout pass.
##
## offset_left/size.x are always set from rect -- the one axis every
## persistent panel repositions and widths every call. The vertical axis is
## never set here: a bottom-anchored panel (the command tray, the summary
## panel) auto-grows to its content on that axis already, and a top-anchored
## one (a left-side window) sets its own offset_top, since only its caller
## knows whether that edge is free or pinned.
##
## scroll is the one control allowed to be smaller than its contents
## (Cause 1): rect's chrome-trimmed size is a ceiling on its
## custom_minimum_size, real because a ScrollContainer's own minimum on the
## axis it scrolls is ~0 (Cause 2 -- never read that minimum through the
## ScrollContainer itself; scroll.get_child(0) is what actually holds the
## content). The panel hugs shorter content rather than always filling the
## ceiling, so the budget is capped again at the child's own minimum height.
## With no scroll, rect.size is set on the panel directly; below its
## content's combined minimum this is a no-op (a Control cannot be sized
## smaller than that), which is what makes it safe to call unconditionally
## on a panel that auto-grows -- see hud.gd::_apply_selection_tray_width.
static func apply(panel: PanelContainer, scroll: ScrollContainer, rect: Rect2) -> void:
	panel.offset_left = rect.position.x
	panel.size.x = rect.size.x
	if scroll != null:
		var budget: Vector2 = rect.size - UiLayout.panel_chrome()
		budget.x = maxf(0.0, budget.x)
		budget.y = maxf(0.0, budget.y)
		var content := scroll.get_child(0) as Control
		if content != null:
			budget.y = minf(budget.y, content.get_combined_minimum_size().y)
		scroll.custom_minimum_size = budget
	else:
		panel.size.y = rect.size.y
