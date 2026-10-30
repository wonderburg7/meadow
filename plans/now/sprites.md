# Sprites -- pixel art in the comb and the meadow, and one cheap way to add more

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SP-6 -- meadow foragers drawn from the sheet, in the Claude backlog (Dave's sheet landed and CQ-L1 released `scripts/bee.gd`, 22 Oct 2026); the meadow floor in blocks (SP-8, SP-8a) moved to `plans/now/meadow-terrain.md` on 15 Oct 2026, and the hive and menu art is `plans/now/hive-and-menu-art.md`; SP-13 (the skep door on `hive.position`) landed 30 Oct 2026, hands-on check C-161 filed | Dependency: none left | Verified: 2026-10-30

## Objective

Dave drew the first pixel-art set on 9 Oct 2026: nectar and pollen cells
with fill levels, an eight-direction meadow forager and a straw skep for
the meadow hive. This plan puts them in the game so they look like crisp
pixel art at every zoom. It also sets up one standard route for adding
the next sprite: Dave saves a file and adds one table row, and one
command does the rest. A session never opens an image.

The pixel scale per view, the size every element should be drawn at, and
the file conventions live in `plans/design/pixel-art.md`. This plan
builds them and does not restate them.

## Decisions (Dave, 9 Oct 2026)

1. **Formats.** `.aseprite` is the source of truth, saved from Resprite or
   Aseprite. The game loads PNG sheets generated from it by the SP-2
   exporter. `.resprite` files are not read. No Aseprite install is
   needed: the exporter is plain Python.
2. **Colours follow the art.** Nectar is lime and pollen is orange. The
   game's flat colours, overlays and load dots change to match. Honey
   moves off orange so it cannot be mistaken for pollen (SP-3).
3. **Bee art is per view.** The forager sheet is for the meadow only.
   Dave will draw larger bees for inside the hive.
4. **Forager sheet.** Dave will repack it onto a regular grid later.
   Row order today: 1 left, 2 right, 3 down-left, 4 down-right,
   5 up-right, 6 up-left, 7 down, 8 up.
5. **One pixel scale per view:** hive 1.1875, meadow 1.5 world units per
   art pixel (`plans/design/pixel-art.md`).
6. **Sharp-pixel shader rather than plain nearest filtering.** The camera
   zooms smoothly (0.4-3.0) and cells sit at 1.1875x. Plain nearest
   filtering would leave pixels unevenly sized (1 or 2 screen px each) and
   make them shimmer while zooming. A shared sharp-bilinear shader keeps
   the pixels square at any zoom (SP-1).

## Current state

Verified 15 Oct 2026 against master `b5e6751`. SP-1 to SP-5, SP-7, SP-9 and
SP-10 have landed: the comb is drawn from Dave's cell art through the
sharp-pixel shader, the skep stands in the meadow, and hive soil is drawn
from the art in front-over-back order. What the open slices build on:

- Every ring on a cell goes through `hive_cell.gd::_apply_outline_points`;
  with Cell art on it walks `EMPTY_RIM`, the cup's top face (SP-11).
- The forager sheet (22 Oct 2026) is `bees/foragers_meadow_view.png`,
  96x128: 8 rows x 6 wing frames on a 16x16 grid, row order as in
  Decisions item 4. The exporter cuts it as a plain `.png` grid into
  `foragers_meadow_view_sheet.png`, and `sprite_catalogue.gd` names its
  frames `<row>.<n>` (`left.0` ... `up.5`). Frames bob up and down within
  their cells, and the `up` row's sting reaches the cell's bottom edge, so
  the exporter now refuses only art that runs across a grid line, not art
  that touches one.
- Meadow bees are still stacks of `Polygon2D` circles under `visual_root`
  (`bee.gd`, "the visual nodes").
- SP-4 found the nectar cell art's liquid is dark green (72, 121, 8), not the
  lime of the flat fill, so the `fermented` variant recolours that green to
  `FERMENTED_NECTAR_COLOR`.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| SP-6 | meadow foragers drawn from the sheet: eight directions, flapping wings | `scripts/bee.gd`, tests | yes (CQ-L1 landed 22 Oct 2026) | high (per-bee hot path) |
| SP-12 | every outline on a comb cell sits on the cup's rim, proved by a new pixel assertion | `scripts/input_selection.gd`, `scripts/hive_cell.gd`, `scripts/scenario_actions.gd`, tests | yes -- DR-1 landed 25 Oct 2026 | medium |
| SP-14 | no outline on an unselected comb cell while cell art is on | `scripts/hive_cell.gd` | yes -- DR-1 landed 25 Oct 2026 | low |

**Dependencies.** RR-11 (`plans/now/run-repairs.md`) waits for SP-11 to
release `scripts/hive_cell.gd`. SP-6's last gate, CQ-L1
(`plans/now/code-health.md`), landed 22 Oct 2026; it no longer
follows SP-8a (`plans/now/meadow-terrain.md`), though both edit
`scripts/bee.gd`, so whichever is queued first runs first (Dave,
22 Oct 2026). CQ-S0b (`plans/now/code-health.md`) also edits
`scripts/bee.gd`'s `setup()`; the same order applies.

SP-1, SP-2, SP-4, SP-5, SP-7 (ad-hoc, on Dave's request), SP-9 and SP-10
shipped 9-15 Oct 2026; each has its record in `plans/archive/`, named by id
and date.

SP-11 shipped 2026-10-15; its specification is `plans/archive/SP-11_2026-10-15.md`.

## SP-6 -- meadow foragers drawn from the sheet

**Gate:** none left: CQ-L1 landed 22 Oct 2026, releasing `scripts/bee.gd`. The sheet gate cleared on
22 Oct 2026: Dave's sheet is committed on a 16x16 grid and exported, with
its sprite-table row and catalogue entry (`FORAGERS_MEADOW_VIEW_*`).

**True afterwards.**

- An outdoor worker draws as one sprite.
- Row: direction from `heading`, eight ways. Octant
  `k = round(angle / 45) mod 8` gives E, SE, S, SW, W, NW, N, NE, mapped
  to rows by name from the catalogue's frame names (`right`, `down_right`,
  `down`, `down_left`, `left`, `up_left`, `up`, `up_right`).
- Wing frame: a shared 6-frame clock offset by `wander_phase`. The frames
  bob the body as well as the wings, so the clock reads as flight.
- Body and outline circles are hidden outdoors. The load dot stays at
  about 2 art px. Selection, alarm and attack rings are unchanged.
- Indoors, drones, gynes and queens keep circles until their art exists.
- Runtime: the frame is computed in the existing display update and
  assigned only when it changes. Profile before and after (rule 3); one
  sprite replaces three or four polygons per bee.
- Hands-on (Dave): foragers in the meadow face the way they fly in all
  eight directions and flap without flicker at every zoom.

```queue
**[Claude] SP-6 -- meadow foragers drawn from the sheet**
- Plan: `plans/now/sprites.md` -- "SP-6 -- meadow foragers drawn from the sheet"
- Files: `scripts/bee.gd`, `tests/sp6_forager_sprite_test.gd`, `tests/test_sp6_forager_sprite.py`
- Check: `python -m unittest tests.test_sp6_forager_sprite` passes: an outdoor worker heading into each of the eight octants shows that direction's row, its frame advances with the wing clock, and its body circles are hidden outdoors and shown indoors; a before/after profile of the display update is recorded in the plan; `.	ools
erify.ps1` is green
- Proof: `absent: scripts/bee.gd :: FORAGERS_MEADOW_VIEW`
- Next after: None -- plan complete
```

## SP-12 -- every outline on a comb cell sits on the cup's rim, proved against the drawn pixels

Level: medium -- claude-sonnet-5-5 at medium effort.

**True now.** C-125 and then C-134 failed on the same misfit: the keep-clear,
build-hover and order-chain outlines sit about 10 px below the cup's rim.
`input_selection.gd::_draw_tile_outline` draws a flat
`Shapes.hexagon_points(hive_cell_size + 1)` on `_tile_centre`, the floor
centre. The cup's rim centre sits about 9 art px x 1.1875 (about 10.7 px)
above the floor centre (`EMPTY_FLOOR_MID_Y` 22, rim centre y 13).
`EMPTY_RIM` in `hive_cell.gd` has an x extent of 1..32, which centres on 16.5
and not 16: probably measured with the sheet's 1 px gutter included. Nothing
checks an outline against the drawn pixels, which is why the same fault came
back.

**When done:**

1. `EMPTY_RIM` is re-measured against the cup frame's opaque pixels and
   centres on the frame's own centre (16), with the gutter excluded.
2. `hive_cell.gd` exposes a static rim-points helper, mapped to local space by
   `_silhouette_point_to_local`. With `Session.use_cell_sprites` on,
   `_draw_tile_outline` draws that rim polygon, not the flat hexagon, and
   exposes the points it draws through one function that returns them.
   With the cell art off it draws exactly what it draws today.
3. The instrument, because this is the second failure: a new assert condition
   `cell_outline_matches_sprite` with a `tol_px` field in
   `scenario_actions.gd::_evaluate_assert_condition` (assertion checks
   section). It compares the opaque-pixel bounding box of the cup frame (read
   from the empty sprite's texture image data, mapped by the sprite's scale and
   offset) with the bounding box of the selection ring and of the points
   `_draw_tile_outline` returns, and passes when each edge is within `tol_px`.
4. `test_scenarios/sp_outline_rim.json` selects a cell, hovers a build site and
   starts an order chain with cell art on, then asserts the condition at
   `tol_px` 1.5; `tests/test_sp_outline_rim.py` runs it.
5. Dave's hands-on check is filed at closeout (click-driven, visual): hover,
   keep-clear and an order chain on a comb cell, each outline on the cup's rim.
   It is reachable in under five minutes from a fresh hive, so no skip save.

**Invariants.** Presentation only. The flat hexagon is unchanged when cell art
is off. `python -m unittest tests.test_sp11_cell_rim` still passes. No per-frame
cost is added: the rim points are built once and cached.

**Open decisions:** none.

```queue
**[Claude] SP-12 -- every outline on a comb cell sits on the cup's rim, proved against the drawn pixels**
- Plan: `plans/now/sprites.md` -- "SP-12 -- every outline on a comb cell sits on the cup's rim, proved against the drawn pixels"
- Files: `scripts/input_selection.gd`, `scripts/hive_cell.gd`, `scripts/scenario_actions.gd`, `test_scenarios/sp_outline_rim.json`, `tests/test_sp_outline_rim.py`, `tests/sp11_cell_rim_test.gd`, `tests/test_sp11_cell_rim.py`
- Check: `python -m unittest tests.test_sp_outline_rim` passes (the `cell_outline_matches_sprite` assertion holds for the selection ring and the tile outline within 1.5 px, and fails when the outline is moved 10 px); `python -m unittest tests.test_sp11_cell_rim` passes; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
- Proof: `absent: scripts/scenario_actions.gd :: cell_outline_matches_sprite`
- Next after: none -- SP-13 and SP-14 in `plans/now/sprites.md` do not depend on it
```

SP-13 shipped 2026-10-30; its specification is `plans/archive/SP-13_2026-10-30.md`.

## SP-14 -- no outline on an unselected comb cell while the cell art is on

Level: low -- claude-haiku-5-5.

**True now.** Dave: "remove the hexes which sit on each cell even when not
selected". `hive_cell.gd` creates an `outline` Line2D (near l.419) and
`_refresh` makes it visible whenever the cell holds something (near l.1277),
on an unfinished build site (near l.1261) and under an overlay (near l.1410),
even with `Session.use_cell_sprites` on, where the cup art already draws the
cell.

**When done:**

1. With `Session.use_cell_sprites` on, `outline` is hidden unless an overlay is
   showing; with it off, nothing changes.
2. Dave's hands-on check is filed at closeout and asks whether the thin rim
   that remains is the cup art's own baked edge. If it is and he means that, it
   is an art change and goes to `plans/now/hive-and-menu-art.md`.

**Invariants.** Selection, designation and zone rings are untouched.
`python -m unittest tests.test_sp11_cell_rim` still passes. It shares
`scripts/hive_cell.gd` with SP-12 and RR-13 (`plans/now/run-repairs.md`):
whichever is queued first runs first.

**Open decisions:** none.

```queue
**[Claude] SP-14 -- no outline on an unselected comb cell while the cell art is on**
- Plan: `plans/now/sprites.md` -- "SP-14 -- no outline on an unselected comb cell while the cell art is on"
- Files: `scripts/hive_cell.gd`
- Check: `python -m unittest tests.test_sp11_cell_rim` passes; with cell art on, a cell holding nectar has `outline.visible` false and a cell under an overlay has it true; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
- Proof: `absent: scripts/hive_cell.gd :: outline.visible = content_type != "" and not`
- Next after: none -- `plans/now/sprites.md` is complete once SP-6, SP-12 and SP-13 have landed
```

## Read on demand

- `plans/design/pixel-art.md`: scales, sizes and conventions (SP-2 onwards)
- `scripts/hive_cell.gd`: "constants and colours", `_ready`, `_refresh`
- `scripts/bee.gd`: "the visual nodes", `_update_role_marker` (SP-3, SP-6)
- `docs/performance.md` before SP-6
