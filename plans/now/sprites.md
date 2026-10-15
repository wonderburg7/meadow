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
| SP-6 | meadow foragers drawn from the sheet: eight directions, flapping wings | `scripts/bee.gd`, the sprite table and catalogue, tests | no -- waits for the sheet on a 16x16 `sheet` grid | high (per-bee hot path) |

**Dependencies.** RR-11 (`plans/now/run-repairs.md`) waits for SP-11 to
release `scripts/hive_cell.gd`. SP-6 follows SP-8a
(`plans/now/meadow-terrain.md`) in the lane, since both edit `scripts/bee.gd`.

SP-1, SP-2, SP-4, SP-5, SP-7 (ad-hoc, on Dave's request), SP-9 and SP-10
shipped 9-15 Oct 2026; each has its record in `plans/archive/`, named by id
and date.

SP-11 shipped 2026-10-15; its specification is `plans/archive/SP-11_2026-10-15.md`.

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
