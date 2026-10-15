# Sprites -- pixel art in the comb and the meadow, and one cheap way to add more

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SP-6 waits for Dave's forager sheet on a 16x16 `sheet` grid; the meadow floor in blocks (SP-8, SP-8a) moved to `plans/now/meadow-terrain.md` on 15 Oct 2026, and the hive and menu art is `plans/now/hive-and-menu-art.md` | Dependency: none for SP-11; SP-6 waits for Dave's art | Verified: 2026-10-15

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
- The forager sheet (13 Oct 2026) is `bees/foragers_meadow_view.png`,
  48x104, 8 rows x 4 wing frames, row order as in Decisions item 4. Its
  columns sit on a 12-px pitch; its rows do not (they start at
  y 1/14/28/41/52/65/78/91). The exporter takes a grid only from an
  `.aseprite` layer named `sheet`, so it stays `unexported`.
- Meadow bees are still stacks of `Polygon2D` circles under `visual_root`
  (`bee.gd`, "the visual nodes").
- SP-4 found the nectar cell art's liquid is dark green (72, 121, 8), not the
  lime of the flat fill, so the `fermented` variant recolours that green to
  `FERMENTED_NECTAR_COLOR`.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| SP-11 | every ring on a cell traces the cup's rim (C-125, 14 Oct 2026) | `scripts/hive_cell.gd`, tests | yes | medium |
| SP-6 | meadow foragers drawn from the sheet: eight directions, flapping wings | `scripts/bee.gd`, the sprite table and catalogue, tests | no -- waits for the sheet on a 16x16 `sheet` grid | high (per-bee hot path) |

**Dependencies.** RR-11 (`plans/now/run-repairs.md`) waits for SP-11 to
release `scripts/hive_cell.gd`. SP-6 follows SP-8a
(`plans/now/meadow-terrain.md`) in the lane, since both edit `scripts/bee.gd`.

SP-1, SP-2, SP-4, SP-5, SP-7 (ad-hoc, on Dave's request), SP-9 and SP-10
shipped 9-15 Oct 2026; each has its record in `plans/archive/`, named by id
and date.

## SP-11 -- every ring on a cell traces the cup's rim

Level: medium. Dave, 14 Oct 2026 (C-125): with the new cell art the
selection ring "should now highlight the flat top of each of the cells
(the rim), rather than the whole shape", and every ring on a cell does
the same (his answer in the pass session), so they cannot disagree.

**True now** (verified 14 Oct 2026 against master `3e37ea6`).

- Every ring on a cell (`outline`, `designation_ring`, `selection_ring`,
  `zone_halo`, `zone_glow`) goes through `_apply_outline_points`; with
  Cell art on, `_set_outline_points_cup` walks the eight-point
  `EMPTY_SILHOUETTE` (the whole cup: rim, walls and base) and scales it
  by `size / cell_size` about the cell origin.
- The cup's rim is the bright outline (255,208,0 and 255,234,0) round
  the top face of frame 0 of `assets/sprites/comb/wax_cell_nectar_sheet.png`.
  Measured on 14 Oct 2026 by printing that frame's pixels as a grid
  (Python, PIL): a flat-topped hexagon with outer pixel edges top y 5
  (x 9..26), bottom y 21 (x 8..26), left x 1 and right x 32 at y 13.

**True afterwards.**

- `EMPTY_RIM` (const, six `Vector2`, in the frame's pixel space) holds
  the rim's outer edge: `(9,5), (26,5), (32,13), (26,21), (8,21),
  (1,13)`. Its comment states how it was measured, as `EMPTY_SILHOUETTE`'s
  does. Re-measure it the same way first; if any vertex is off by more
  than one pixel from the values above, use the new measurement and say
  so in the commit.
- `_set_outline_points_cup` walks `EMPTY_RIM`. Each point goes through
  `_silhouette_point_to_local` and is then scaled by `size / cell_size`
  about the rim's own centre (the mean of the six local points), not
  about the cell origin, so the larger zone rings stay centred on the rim.
- `_silhouette_point_to_local` no longer adds `RING_Y_NUDGE` (it
  corrected `EMPTY_SILHOUETTE`'s two-pixel-high measurement, and the rim
  is measured fresh). Delete `RING_Y_NUDGE` and `EMPTY_SILHOUETTE` if
  nothing else reads them (`git grep` first).
- Cell art off: unchanged, every ring is the hexagon.

**Invariants.** One rim definition for every ring; the sprite's own
placement (`EMPTY_SPRITE_Y_NUDGE`, `empty_scale`) is untouched; the ring
rebuild still happens only when `Session.use_cell_sprites` changes.

**Escalate** if the measured rim is not a six-sided figure: that means
the art changed, and Dave chooses the shape.

**Supersedes C-20's one-pixel nudge.** C-20 (`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`)
asked for the rings to sit 1 px higher, to ride with the next slice that
opens the cell-art drawing. This is that slice: the rim is measured fresh
and `RING_Y_NUDGE` goes, so no separate nudge is applied; C-134 judges the
alignment.

**Hands-on check on landing** (move from `checks/blocked.md` to ready):
C-134.

```queue
**[Claude] SP-11 -- every ring on a cell traces the cup's rim**
- Plan: `plans/now/sprites.md` -- "SP-11 -- every ring on a cell traces the cup's rim"
- Files: `scripts/hive_cell.gd`, `tests/sp11_cell_rim_test.gd`, `tests/test_sp11_cell_rim.py`
- Check: `python -m unittest tests.test_sp11_cell_rim` passes: with Cell art on, the selection ring's points are `EMPTY_RIM` taken through `_silhouette_point_to_local` and scaled about the rim's centre; the designation, zone and base rings use the same six points at their own sizes; with Cell art off every ring is still the hexagon.
- Proof: `absent: scripts/hive_cell.gd :: EMPTY_RIM`
- Next after: SP-8a -- the meadow floor drawn in blocks, with everything on it lifted
```

## SP-6 -- meadow foragers drawn from the sheet

**Gate:** Dave's sheet on a 16x16 grid, in an `.aseprite` with one layer
named `sheet`. `bees/foragers_meadow_view.png` (13 Oct 2026) has the
frames on a 12-px column pitch with irregular rows, as a plain `.png`,
which the exporter can only take as `single`. The slice renames its
sprite-table row's file to the `.aseprite` and sets `grid 16x16 rows=...`.

**True afterwards.**

- An outdoor worker draws as one sprite.
- Row: direction from `heading`, eight ways. Octant
  `k = round(angle / 45) mod 8` gives E, SE, S, SW, W, NW, N, NE, mapped
  to rows by name from the sprite table.
- Wing frame: a shared 4-frame clock offset by `wander_phase`.
- Body and outline circles are hidden outdoors. The load dot stays at
  about 2 art px. Selection, alarm and attack rings are unchanged.
- Indoors, drones, gynes and queens keep circles until their art exists.
- Runtime: the frame is computed in the existing display update and
  assigned only when it changes. Profile before and after (rule 3); one
  sprite replaces three or four polygons per bee.

## Read on demand

- `plans/design/pixel-art.md`: scales, sizes and conventions (SP-2 onwards)
- `scripts/hive_cell.gd`: "constants and colours", `_ready`, `_refresh`
- `scripts/bee.gd`: "the visual nodes", `_update_role_marker` (SP-3, SP-6)
- `docs/performance.md` before SP-6
