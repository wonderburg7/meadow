# The left-side windows and the settings window -- Dave's 8 Sep 2026 second pass

<!-- CONTEXT: plan-archive | LAYER: history -->
Status: complete | Owner: Dave / Claude Code | Verified: 2026-09-08

**Objective.** Colony, Foraging and Nursery sit clear of the bottom row at
every viewport height, draw all their text in the chosen typeface and scale,
and open the way the player left them rather than pre-expanded.

**Where these came from.** Dave ran C-19 and C-22 on 8 Sep 2026. C-19 passed
its main clause -- the windows do shorten and scroll rather than covering the
summary panel -- and returned three separate defects alongside it. C-22
passed and returned one ask about the other end of the same behaviour. Those
four were UI-W-1 to UI-W-4.

**The panel hierarchy these obey** is in
`plans/now/ui-layout-ownership.md`: command tray, then the bottom row's side
bands, then these windows, each separated by 16px. UI-W-1 was this file's
half of that repair (`plans/archive/UI-W-1_2026-09-08.md`); UI-T-6 was the
bottom row's half (`plans/archive/UI-T-6_2026-09-08.md`), and LAY-1
consolidates both.

**All four slices shipped 2026-09-08:**

- UI-W-1 -- `plans/archive/UI-W-1_2026-09-08.md`
- UI-W-2 -- `plans/archive/UI-W-2_2026-09-08.md`
- UI-W-3 -- `plans/archive/UI-W-3_2026-09-08.md`
- UI-W-4 -- `plans/archive/UI-W-4_2026-09-08.md`

**Check ids.** C-19 was re-filed by UI-W-1. C-26 was UI-W-2's. C-27 covers
UI-W-3 and UI-W-4 together and is ready for Dave's pass now that both have
landed. C-28 belongs to LAY-1 in `plans/now/ui-layout-ownership.md`.

**Follow-up.** None outstanding. LAY-1 (`plans/now/ui-layout-ownership.md`)
consolidates the chrome arithmetic this plan and UI-T-6 established; it is
its own plan, not a reopening of this one.
