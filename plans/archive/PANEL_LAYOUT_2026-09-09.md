# Persistent panel rectangles — the anchor bug and its guard rail

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None — plan complete | Dependency: none | Verified: 2026-09-09
Archived 2026-09-09, the day Dave's hands-on pass confirmed C-19 and C-26.

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
around the root cause without removing it; LAY-2 removes it. **LAY-3 has
landed** (`plans/archive/LAY-3_2026-09-09.md`): `left_window_max_height()` no
longer subtracts the chrome twice, and Colony/Foraging re-apply their window
rectangle when a section expands or collapses. C-19 is re-filed in
`checks/ready.md`. **LAY-4 has landed** (`plans/archive/LAY-4_2026-09-09.md`):
the nursery ring's legend measures its own width and reserves
`UiLayout.SCROLLBAR_GUTTER`, so the key no longer runs under the Nursery
window's scrollbar at any text scale. C-26 is re-filed in `checks/ready.md`.
Every slice this plan owns has now landed; the guard rail it motivated,
LAY-5, is tracked in `plans/now/layout-regression.md` and is startable today.

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

## Outcome, confirmed 9 September 2026

All three slices landed and Dave's hands-on pass the same day confirmed two of
the three checks they filed:

- **C-19 passed.** The gap below an open left-side window matches the gap
  between the summary panel and the left screen edge, and expanding a section
  grows the window until its bottom reaches that gap, after which it scrolls.
- **C-26 passed.** The nursery donut's key follows the chosen typeface and
  text scale, and no line of it runs under the window's scrollbar.
- **C-18 passed on everything this plan owned** -- the tray is on screen at
  every size, its Job, Focus and Orders buttons and `More…` are visible and
  clickable, `More…` grows the tray upwards, and the 16px gaps to the summary
  panel and to the window's bottom edge hold. The one remaining fault is that
  the three columns bunch against the tray's left edge instead of sharing its
  width. That is a container flag inside the tray, not a panel rectangle, and
  it moved to `plans/now/hud-controls.md` HC-1.

The guard rail this plan motivated is LAY-5, in
`plans/now/layout-regression.md`, with LAY-6 added on 9 Sep to cover the
controls *inside* a panel as well as the panel itself.

LAY-2's specification archived to `plans/archive/LAY-2_2026-09-09.md`.
LAY-3's specification archived to `plans/archive/LAY-3_2026-09-09.md`.
LAY-4's specification archived to `plans/archive/LAY-4_2026-09-09.md`.
