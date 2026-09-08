# Persistent panel rectangles — the anchor bug and its guard rail

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: LAY-3, the left-side windows' gap and growing sections | Dependency: none — LAY-3 is startable today | Verified: 2026-09-09

**Objective.** A persistent HUD panel stays inside the viewport with a 16px
gap from its neighbours, on every pass, at every supported size — and a
deterministic check fails when one does not, so this stops costing a hands-on
round trip.

**State.** Dave's 9 Sep 2026 pass found the command tray off the bottom edge
for the fourth time (C-18), the left-side windows' gap too big for the second
time (C-19), and the nursery donut's key under the scrollbar (C-26). C-7 and
C-5 could not be run at all, because both need the tray's buttons. **LAY-2
has landed** (`plans/archive/LAY-2_2026-09-09.md`): `ui_panel_layout.gd::apply()`
now writes a persistent panel's rectangle through offsets only, C-18 is
re-filed in `checks/ready.md` awaiting Dave's pass, and C-7/C-5 are unblocked
back into `checks/ready.md` alongside it. LAY-1 had refactored the call sites
around the root cause without removing it; LAY-2 removes it.

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
| LAY-3 | The left-side windows' gap is a true 16px, and they grow when a section is expanded | `ui_layout.gd`, `colony_panel.gd`, `foraging_panel.gd`, `nursery_panel.gd` | yes | low |
| LAY-4 | The nursery donut's key clears the scrollbar at every text scale | `nursery_panel.gd`, `ui_layout.gd` | yes | low |

Both build on the `apply()` signature LAY-2 landed, and are independent of
each other.

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

LAY-2's specification archived to `plans/archive/LAY-2_2026-09-09.md`.

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
