# Persistent panel rectangles — the anchor bug and its guard rail

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: LAY-2, the command tray's bottom pin | Dependency: none — LAY-2 is startable today | Verified: 2026-09-09

**Objective.** A persistent HUD panel stays inside the viewport with a 16px
gap from its neighbours, on every pass, at every supported size — and a
deterministic check fails when one does not, so this stops costing a hands-on
round trip.

**State.** Dave's 9 Sep 2026 pass found the command tray off the bottom edge
for the fourth time (C-18), the left-side windows' gap too big for the second
time (C-19), and the nursery donut's key under the scrollbar (C-26). C-7 and
C-5 could not be run at all, because both need the tray's buttons. The root
cause of the tray failures is stated below and had never been written down;
LAY-1 refactored the call sites around it without removing it.

## Why this kept coming back

`Control.set_size()` — which is also what `panel.size.x = w`, `panel.size.y =
h` and `panel.reset_size()` call — recomputes **all four** anchor offsets from
the control's cached position and the new size. On a bottom-anchored panel
that silently replaces the bottom pin (`offset_bottom = -16`) with a top pin
at wherever the panel's top edge happened to be that frame. `grow_vertical =
GROW_DIRECTION_BEGIN` does not save it: grow direction only applies when the
combined minimum exceeds the offset-derived height, and it moves the cached
position without writing the offsets back.

`hud.gd::_resize_command_tray()` calls `set_size` four times in one pass
(`command_tray.size.x` in `_update_command_tray_width`, `panel.size.x` inside
`ui_panel_layout.gd::apply()`, and two `reset_size()` calls) while zeroing and
then restoring `command_scroll.custom_minimum_size.y` in between. The tray
therefore collapses to chrome height with its top still pinned, has its
offsets rewritten around that collapsed box, and then regrows to its content
height *downwards* from that top. Each pass leaves the bottom edge roughly
`previous_height - chrome_height` px lower than the 16px margin, so once the
tray has been tall once — a cell selected, `More…` opened, three columns
wrapping onto two rows — the next pass puts it off the bottom of the screen.
Dave's 9 Sep screenshot shows exactly that: the tray's "Job" header is level
with the bottom of the summary panel and the rest of the tray is below the
window edge.

UI-T-1, UI-T-6 and LAY-1 each changed *what height the tray was given*. None
of them changed the fact that giving a bottom-anchored panel a height
destroys the anchor that keeps its bottom edge on screen. That is the whole
reason for the repeat, and LAY-2 removes it rather than re-tuning a number.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| LAY-2 | Panel rectangles are written through offsets only; the tray stays on screen | `ui_panel_layout.gd`, `ui_layout.gd`, `hud.gd` | yes | medium |
| LAY-3 | The left-side windows' gap is a true 16px, and they grow when a section is expanded | `ui_layout.gd`, `colony_panel.gd`, `foraging_panel.gd`, `nursery_panel.gd` | after LAY-2 | low |
| LAY-4 | The nursery donut's key clears the scrollbar at every text scale | `nursery_panel.gd`, `ui_layout.gd` | after LAY-2 | low |

LAY-3 and LAY-4 both build on the `apply()` signature LAY-2 lands, so both
follow it, and they are independent of each other after that.

**The guard rail is LAY-5, in `plans/now/layout-regression.md`.** It asserts
the rule LAY-2 establishes and owns tooling files rather than UI ones, so it
sits in its own plan and runs after LAY-2 has shipped. Without it this group
fixes three symptoms and leaves the next one to another hands-on pass.

**Required reading for any slice here.** This file's own section and
`scripts/ui_layout.gd`. Nothing else — the archives are provenance only.

**Do not change** the panel hierarchy itself (command tray, then the bottom
row's side bands, then the left-side windows, 16px apart) or the values in
`ui_layout.gd`'s width helpers. Dave confirmed on 9 Sep that the horizontal
gap between the tray and the summary window is correct. Every slice here is
about the vertical axis and the scrollbar gutter.

## LAY-2 — write a persistent panel's rectangle through offsets only

**Minimum reasoning level: medium.**

**Change 1 — `scripts/ui_panel_layout.gd::apply()` never touches `size`.**
Replace the body so every assignment is to an offset. Add a fourth parameter
`bottom_margin: float = -1.0`; a value `>= 0.0` means the panel is pinned that
many pixels above the viewport's bottom edge, and a negative value means it is
pinned at `rect.position.y` from the top.

```gdscript
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
```

Rewrite the function's doc comment to say why: `set_size()` recomputes all
four offsets from the cached position, so it converts a bottom pin into a top
pin, and this file is the one place allowed to size a persistent panel.

**Change 2 — `summary_panel_rect()` gains a real ceiling.** In
`scripts/ui_layout.gd`, change it to
`Rect2(SELECTION_TRAY_LEFT_MARGIN, 0.0, selection_tray_width(viewport_size.x),
command_tray_max_height(viewport_size.y))` and update its comment: the height
is now the same ceiling the tray gets, not an unused placeholder.

**Change 3 — `hud.gd::_update_command_tray_width()` stops setting `size.x`.**
Delete the `command_tray.size.x = tray_width` line and the comment above it.
Nothing replaces it: LAY-2's `apply()` owns both horizontal offsets, and
`_update_command_tray_width` is always followed by `_resize_command_tray`,
which calls `apply()`. Keep the `offset_left` assignment and the three
`custom_minimum_size.x = 0.0` resets; keep the early return.

**Change 4 — `hud.gd::_resize_command_tray()` loses both `reset_size()`
calls.** The function becomes: early return, `_update_command_tray_width()`,
`command_scroll.custom_minimum_size.y = 0.0`, build the rect, then
`UiPanelLayout.apply(command_tray, command_scroll, rect,
UiLayout.BOTTOM_ROW_MARGIN)`. No `reset_size()` anywhere — `apply()` now sets
the height explicitly, and `reset_size()` is exactly the call that destroyed
the pin.

**Change 5 — `hud.gd::_apply_selection_tray_width()` pins its bottom too.**
Change its `UiPanelLayout.apply(selection_panel, null, rect)` call to
`UiPanelLayout.apply(selection_panel, null, rect,
UiLayout.BOTTOM_ROW_MARGIN)`. Leave the `selection_column.custom_minimum_size.x`
line below it exactly as it is.

**Out of scope, deliberately.** The summary panel has no `ScrollContainer`, so
content taller than its new ceiling would clip rather than scroll. It has
never been that tall and Dave confirmed it on screen on 9 Sep. Do not add a
scroll to it in this slice.

**Acceptance.** At 1920x1080, 1280x720 and 800x600, select a bee, then a comb
cell, then open `More…`, then select a bee again. The whole command tray is on
screen every time, its Job, Focus and Orders buttons are visible and
clickable, and its bottom edge stays 16px above the window's bottom edge
throughout. Opening `More…` grows the tray upwards or gives it a scrollbar; it
never pushes anything below the window edge. Re-files C-18.

**Proof the defect is present:** `absent: scripts/ui_panel_layout.gd ::
bottom_margin`.

## LAY-3 — the left-side windows' gap, and growing when a section opens

**Minimum reasoning level: low.**

**Change 1 — stop subtracting the chrome twice.** In
`scripts/ui_layout.gd::left_window_max_height()`, delete `- panel_chrome().y`
from the returned expression. It returns an *outer* rectangle height, and
`ui_panel_layout.gd::apply()` already subtracts the chrome when it converts
that rectangle into the scroll's budget. Subtracting it here as well is the
extra 20px on top of the 16px gap that Dave measured on 8 and 9 Sep. Update
the comment to say the return value is an outer height.

**Change 2 — a window regrows when a section is expanded.** In
`scripts/colony_panel.gd`, the section header's `pressed` handler (around line
193) sets `section_open[title]` and `body.visible` and stops. Add
`call_deferred("_apply_left_window_rect")` as its last statement, so the
window's height follows its new content on the next layout pass. Make the same
addition in `scripts/foraging_panel.gd`'s equivalent handler. `nursery_panel.gd`
has no collapsible sections, so it needs no change here.

Deferring matters: the body's minimum size is not final on the frame its
visibility changes, and `apply()` reads `get_combined_minimum_size()`.

**Acceptance.** With a bee selected, open Colony at 1280x720 and again at
800x600. The gap between the bottom of the window and the top of the summary
panel is the same as the gap between the summary panel and the left screen
edge. Expanding a section makes the window grow taller, up to the point where
its bottom would reach that gap, after which it scrolls instead. Collapsing
the section makes it shrink again. The same in Foraging. Re-files C-19.

**Proof the defect is present:** `present: scripts/ui_layout.gd ::
SELECTION_TRAY_GAP - panel_chrome().y`.

## LAY-4 — the nursery donut's key clears the scrollbar

**Minimum reasoning level: low.**

`nursery_panel.gd::_draw_ring()` draws the legend swatch at a literal x of
150 and the legend text at a literal x of 166, with no wrap width, inside a
`ring` control whose `custom_minimum_size.x` is a literal 300. At a large text
scale the legend runs past 300px, and the Nursery window's vertical scrollbar
covers it — Dave, 9 Sep 2026.

**Change 1 — one shared gutter constant.** Add to `scripts/ui_layout.gd`,
beside `PANEL_GAP`:

```gdscript
## Width reserved on the right of any left-side window's content so a
## vertical ScrollContainer bar never covers it (Dave, 9 Sep 2026, C-26).
const SCROLLBAR_GUTTER := 14.0
```

**Change 2 — the ring measures its own legend.** In `nursery_panel.gd`, add
two `const`s next to the other ring geometry — `RING_LEGEND_SWATCH_X := 150.0`
and `RING_LEGEND_TEXT_X := 166.0` — and use them in `_draw_ring()` in place of
the literals. Then extend `_update_ring_min_height()` to set the width as
well, renaming it `_update_ring_min_size()` and updating its two call sites:

```gdscript
var font := ring.get_theme_font("font", "Small")
var font_size := ring.get_theme_font_size("font_size", "Small")
var widest := 0.0
for slice in ring_slices:
	widest = maxf(widest, font.get_string_size(
		_ring_legend_text(slice), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
ring.custom_minimum_size.x = maxf(
	300.0, RING_LEGEND_TEXT_X + widest + UiLayout.SCROLLBAR_GUTTER)
```

**Change 3 — one function builds the legend string.** `_draw_ring()` currently
composes the legend line inline, including the colour-blind tag. Extract that
into `_ring_legend_text(slice) -> String` so the measurement above and the
drawing use the same string, and call it from both. Pass
`ring.size.x - RING_LEGEND_TEXT_X - UiLayout.SCROLLBAR_GUTTER` as
`draw_string`'s `width` argument in place of `-1`, so a legend line can never
draw into the gutter even if the measurement is a pixel out.

**Acceptance.** Open the Nursery window and look at the key beside the donut.
Set the text scale to its largest and try each typeface in turn. The key's
text follows the setting, and no line is covered by or runs under the window's
scrollbar at any scale. Re-files C-26.

**Proof the defect is present:** `absent: scripts/ui_layout.gd ::
SCROLLBAR_GUTTER`.
