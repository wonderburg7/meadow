# Sprites -- pixel art in the comb and the meadow, and one cheap way to add more

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SP-9, hive soil drawn from the art, is queued (SP-1 to SP-5 and SP-7 landed; the skep is in the meadow); SP-6 waits for Dave's repacked forager sheet; SP-8, the block terrain, is decided and waits to be cut into slices | Dependency: none to start; the files it shared with BB-2 and NF-4 are free since both landed 10 Oct 2026 (SP-1, BB-1 and NF-3 landed 9 Oct 2026) | Verified: 2026-10-12

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

Verified 9 Oct 2026 against master and the main checkout:

- `assets/sprites/environment/` tracks `wax.cell.empty.png` (with its
  `.resprite`) and `grass_base.png`. Nothing references `grass_base.png`.
  Untracked in the main checkout only: `wax.cell.nectar.aseprite`,
  `wax.cell.pollen.aseprite`, `Outside_forager_sprites.png` with
  `Outside_forager_sprites_aes.aseprite`, `hive.meadow.view.png`,
  `Sprite details.md`.
- Both cell files are 32x32. Layer 0 matches `wax.cell.empty.png` pixel
  for pixel, and each further layer is one fill level. The nectar file has
  7 levels (upper bounds 10/25/40/55/70/85/100 %), filled flat lime
  (187,248,36). The pollen file has 5 (20/40/60/80/100 %, redrawn 11 Oct), in oranges
  around (255,123,0). Neither has part-transparent pixels.
- The forager sheet is 52x100 with 8 rows x 4 wing frames. Each bee is
  9-12 px and drawn in 4 colours. It is **not on a regular grid**: rows
  start at y 1/12/23/35/46/59/73/86, and column spacing is 11-13 px and
  differs from row to row. The `.aseprite` has a hidden guide layer and an
  empty tilemap layer.
- The skep is 54x41 with 42x35 of drawing and 8 colours.
- `hive_cell.gd` shows `empty_sprite` (`EMPTY_TEXTURE`, scale 38/32) only
  for an empty cell while `Session.use_cell_sprites` is on. Filled cells
  draw a flat hex plus `fill_shape`. It sets no texture filter and no
  material, and `project.godot` sets no default canvas texture filter.
  Godot's linear default therefore blurs the art: that is the blur Dave
  sees when zoomed in.
- Bees are stacks of `Polygon2D` circles under `visual_root` (`bee.gd`,
  "the visual nodes"). `hive.gd` is itself a 60x60 square `Polygon2D`.
  `rival_hive.gd` draws a 52x52 square.
- Measured OKLab distance between the new pollen orange and today's
  `HONEY_COLOR` is 0.08, which reads as the same colour. Nectar lime to
  `FERMENTED_NECTAR_COLOR` is 0.28, which reads as distinct.
- SP-4 found the nectar cell art's liquid is dark green (72, 121, 8), not the
  lime of the flat fill, so the `fermented` variant recolours that green to
  `FERMENTED_NECTAR_COLOR`.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| SP-6 | meadow foragers drawn from the sheet: eight directions, flapping wings | `scripts/bee.gd`, the sprite table and catalogue, tests | no -- waits for Dave's repacked sheet | high (per-bee hot path) |
| SP-8 | the meadow floor built from stacked grass and soil blocks, with height in the simulation | to be cut: height map, save, flight, flowers, scouting | no -- needs cutting into slices first | high (save format, balance, multi-slice) |
| SP-9 | hive soil blocks drawn from the art, crumbling as they are mined | `scripts/soil_block.gd`, tests | yes -- Claude lane | medium |

Dependencies: SP-2 -> SP-4 -> SP-5 -> SP-6 (SP-1 and SP-3 landed 9 Oct 2026).

SP-1 shipped 2026-10-09; its specification is `plans/archive/SP-1_2026-10-09.md`.

SP-2 shipped 2026-10-10; its specification is `plans/archive/SP-2_2026-10-10.md`.

SP-4 shipped 2026-10-11; its specification is `plans/archive/SP-4_2026-10-11.md`.

SP-7 (the whole comb drawn from Dave's cell art: honey, jelly, larva, both
bee breads, fermented nectar and the wax caps) shipped 2026-10-12 as ad-hoc
work on Dave's request; its record is `plans/archive/SP-7_2026-10-12.md`.

SP-5 shipped 2026-10-12; its specification is `plans/archive/SP-5_2026-10-12.md`.

## SP-8 -- the meadow floor from stacked blocks (not yet cut)

Dave drew full and half-height grass blocks and soil blocks (10-11 Oct
2026), exported as `grass_block`, `grass_block_half`, `soil_block` (four
crumbling stages: 5 whole, 4, 2, 1) and `soil_block_half`.

Decisions (Dave, 12 Oct 2026):

1. **Look.** Grass blocks are not animated. The top layer is a grass block
   whose top face is the floor; flowers grow on it. Blocks stack, full or
   half height; only the top layer has the grass top, and the layers under
   it are soil or half soil blocks. Each block's anchor is the middle of
   its top face; a full block's side is 14 art px and a half block's 7, so
   each block in a stack draws that much higher than the one below.
2. **Height is simulation, not just drawing.** It changes flight cost
   (climbing costs a bee more, downhill less), where flowers grow (species
   favour high or low ground), water and wet ground (low ground collects
   it, high ground dries) and scouting reach (further from high ground).
3. **Shape.** Generated per run (gentle seeded hills and hollows), saved
   with the run.
4. **Range.** A few steps: about -2 to +3 blocks, in half-block steps.
5. **The flat `grass_base` tile goes** once blocks cover the meadow.
6. Meadow blocks are not dug; soil blocks crumble only in the hive (SP-9).

Before this is cut (multi-slice planning, high): it touches save format
(the height map), balance (flight cost, which `GameConfig` owns and which
is simulated first) and flower placement, so it splits into at least a
height map with its drawing, then each of the four effects as its own
slice. Water in the meadow does not exist yet; that effect waits for it.

## SP-9 -- hive soil blocks drawn from Dave's art, crumbling as they are mined

Dave, 12 Oct 2026: the soil block's stages are what a hive soil block
shows as it is mined.

**True afterwards.**

- With Cell art on (`Session.use_cell_sprites`), each hive soil block
  (`scripts/soil_block.gd`) draws a `soil_block` frame from the catalogue
  instead of its flat colour: stage 5 (whole) below 25 % mined, then 4, 2
  and 1 for each further quarter. At 100 % the block is gone and the
  site or floor already drawn there shows, which is the bare soil under
  it.
- The block's footprint lands on its hex like a comb cup: the catalogue
  anchor is the top face's middle, so the floor point is 14 art px lower
  (the side height); check it against the cup's 16,22 floor by eye.
- Cell art off keeps today's flat mass. The mining marker, selection ring
  and progress label are unchanged. The frame is set only when it changes.
- Hands-on: zoomed in on the hive wall, the blocks read as Dave's soil and
  a marked block crumbles through four stages as it is dug.

```queue
**[Claude] SP-9 -- hive soil blocks drawn from Dave's art, crumbling as they are mined**
- Plan: `plans/now/sprites.md` -- "SP-9 -- hive soil blocks drawn from Dave's art, crumbling as they are mined"
- Files: `scripts/soil_block.gd`, `tests/test_sp9_soil_art.py`
- Check: `python -m unittest tests.test_sp9_soil_art` passes; `tools/verify.ps1` is green
- Proof: `absent: scripts/soil_block.gd :: SpriteCatalogue`
- Next after: SP-6 -- meadow foragers drawn from the sheet: eight directions, flapping wings
```

## SP-6 -- meadow foragers drawn from the sheet

**Gate:** Dave's repack onto a 16x16 `sheet` grid. The exporter rejects
the current sheet.

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
