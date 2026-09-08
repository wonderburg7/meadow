# Three one-file UI fixes — Dave's 8 Sep 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: none | Dependency: none | Verified: 2026-09-08

**Objective.** Clear the three small, self-contained defects from Dave's
8 Sep 2026 hands-on pass: a 2px ring offset, a clipped hexagon point, and
settings sections that stay open across runs.

**Why these three are one file.** Each owns exactly one script that nothing
else in the queue touches, so they run in the lane opposite
`plans/now/ui-bottom-row.md` without any chance of a merge conflict. They are
independent of each other and may be taken in any order.

## Delivery

All three fixes from Dave's 8 Sep 2026 pass are delivered. UI-T-3 and UI-T-4
are archived below; UI-T-5 is archived at the end of this plan.

**Dependencies, stated rather than implied.** None. Three separate files,
three separate defects.

**Do not change** `scripts/hex_hit_area.gd`, `HEX_SIZE`, `HEX_STEP_X` or the
*relative* spacing of tile centres in UI-T-4: UI-M's exact-hexagon hit test is
built against the tile's real hexagon at its real position. UI-T-4 shifts
every tile by the same constant, which leaves each tile's own hit hexagon
exactly where it was inside the tile.

**Required reading for any slice here.** This file's own section and nothing
else -- the archives are provenance only, and no slice here needs the whole
of this file. `plans/now/ui.md`'s "Durable rules" apply to all of them.

**Check ids C-18 to C-25 are reserved** across this file,
`plans/now/ui-bottom-row.md` and `plans/now/season-balance.md`, so two lanes
filing checks at once cannot collide: C-18 UI-T-1, C-19 UI-T-2, C-20 UI-T-3,
C-21 UI-T-4, C-22 UI-T-5, C-23 UI-S-4b, C-24 SB-1, C-25 SB-2. UI-Q-3 re-files
C-4 rather than taking a new id.

UI-T-3's completed specification: `plans/archive/UI_T_3_2026-09-08.md`.

UI-T-4's completed specification: `plans/archive/UI_T_4_2026-09-08.md`.

UI-T-5's completed specification: `plans/archive/UI_T_5_2026-09-08.md`.

