# The HUD bottom row — Dave's 8 Sep 2026 pass

<!-- CONTEXT: plan-archive | LAYER: provenance -->
Status: complete | Owner: Dave / Claude Code | Verified: 2026-09-08

Retired from `plans/now/` on 2026-09-08 when its last open slice, UI-T-6,
merged. Every check it produced is filed live: C-4 (UI-Q-3), C-7 and C-18
(UI-T-6), C-23 (UI-S-4b) are all in `checks/ready.md`.

**Objective.** No persistent HUD panel leaves the screen or covers another,
and a double right-click stops closing the panels behind a selection that is
still there.

**UI-T-6 shipped 2026-09-08**
(`plans/archive/UI-T-6_2026-09-08.md`): the command tray now measures its
scrolled content instead of the scroller, and the summary panel can no
longer grow through its 16px gap. This was the plan's last open slice. C-18
is re-filed in `checks/ready.md`, and C-7 (`checks/ready.md`, owned by
`plans/archive/CHALLENGE1_2026-09-15.md` Slice 14) moved back there unchanged once its
blocker shipped.

**UI-T-1 shipped 2026-09-08.** The tray no longer runs off the bottom edge.

**Why the rest were one file.** Every one of them edits `scripts/hud.gd`, so
they were a single lane worked top to bottom. The three one-file fixes from
the same pass are archived separately in
`plans/archive/ui-small-fixes_2026-09-08.md`; they shared no file with these.

**UI-S-4b shipped 2026-09-08** (`plans/archive/UI-S-4b_2026-09-08.md`): the
duplicate `double_click` event is now ignored at the input boundary, and
`hud.gd`'s panel-hide sites are logged. C-23 replaced C-14 in
`checks/ready.md`.

**Check ids C-18 to C-25 were reserved** across this file,
`plans/archive/ui-small-fixes_2026-09-08.md` and `plans/now/season-balance.md`, so two lanes
filing checks at once could not collide: C-18 UI-T-1, C-19 UI-T-2, C-20 UI-T-3,
C-21 UI-T-4, C-22 UI-T-5, C-23 UI-S-4b, C-24 SB-1, C-25 SB-2. C-26 to C-28
were reserved by Dave's 8 Sep second pass: C-26 UI-W-2, C-27 UI-W-3/UI-W-4,
C-28 LAY-1 (`plans/now/ui-windows.md`, `plans/now/ui-layout-ownership.md`).
UI-Q-3 re-filed C-4 and UI-T-6 re-filed C-18, rather than taking new ids.

UI-T-2's completed specification: `plans/archive/UI-T-2_2026-09-08.md`.
UI-T-6's completed specification: `plans/archive/UI-T-6_2026-09-08.md`.

## UI-T — the bottom row's rectangles

UI-T-1, UI-T-2 and UI-T-6 all shipped 8 Sep 2026. UI-T-1 and UI-T-2's checks
came back with faults, and the two faults had the same shape:
`plans/now/ui-layout-ownership.md` holds the full four-cause diagnosis and
the panel hierarchy Dave asked for on 8 Sep 2026; UI-T-6 was the bottom row's
half of the repair, and LAY-1 in that file consolidates it.

## UI-S — from Dave's 3 Sep 2026 hands-on pass

UI-S-1, UI-S-2 and UI-S-3 shipped 3 Sep 2026 and are archived in
`plans/archive/UI_SHIPPED_2026-09-03.md`. Their checks came back on 8 Sep
2026: C-13's window behaviour passed except for the summary-panel overlap
owned by UI-T-2, and C-11/C-12 failed on the vertical containment owned by
UI-T-1.

UI-S-4 shipped 3 Sep 2026 and its check C-14 came back failing. The
diagnostic it added did its job: UI-S-4b shipped 2026-09-08 off the back of
it (`plans/archive/UI-S-4b_2026-09-08.md`).

## UI-Q — the warning banner: dwell and priority

UI-Q-1 and UI-Q-2 landed 1 Sep 2026 (archive). UI-Q-3 shipped 2026-09-08
(`plans/archive/UI-Q-3_2026-09-08.md`): messages now carry a minimum dwell
and a severity, and C-4 was re-filed in `checks/ready.md` against the new
rule.
