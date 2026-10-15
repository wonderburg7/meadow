# Sprites -- pixel art in the comb and the meadow, and one cheap way to add more

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SP-11 then SP-8a, from Dave's 14 Oct 2026 pass (rings trace the rim; the soil draw order, SP-10, landed 15 Oct 2026 with hands-on check C-133 in checks/ready/), then SP-8a (SP-1 to SP-5, SP-7 and SP-9 landed; the skep is in the meadow and hive soil is drawn from the art); SP-6 waits for Dave's forager sheet on a 16x16 `sheet` grid (his 11 Oct repack, `bees/foragers_meadow_view.png`, is committed unexported and is not on that grid yet); the hive and menu art is planned in `plans/now/hive-and-menu-art.md`; SP-8a, the meadow floor drawn in blocks with everything on it lifted, is specified below and gated on FC-2 (Codex lane) releasing `scripts/main.gd` and the save files -- CD-3 released `scripts/bee.gd` on 12 Oct 2026, and Dave put FC-2 first on 13 Oct 2026; height's effects (rest of SP-8) are cut after it | Dependency: none to start; the files it shared with BB-2 and NF-4 are free since both landed 10 Oct 2026 (SP-1, BB-1 and NF-3 landed 9 Oct 2026) | Verified: 2026-10-14

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
- The forager sheet (13 Oct 2026) is `bees/foragers_meadow_view.png`,
  48x104, 8 rows x 4 wing frames, row order as in Decisions item 4's
  notes. Its columns sit on a 12-px pitch; its rows do not (they start at
  y 1/14/28/41/52/65/78/91). It replaced the irregular 52x100
  `bee_forager_meadow.aseprite`. The exporter takes a grid only from an
  `.aseprite` layer named `sheet`, so it stays `unexported`.
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
| SP-11 | every ring on a cell traces the cup's rim (C-125, 14 Oct 2026) | `scripts/hive_cell.gd`, tests | yes (SP-10, which shares `hive_cell.gd`, landed 15 Oct 2026) | medium |
| SP-6 | meadow foragers drawn from the sheet: eight directions, flapping wings | `scripts/bee.gd`, the sprite table and catalogue, tests | no -- waits for the sheet on a 16x16 `sheet` grid | high (per-bee hot path) |
| SP-8a | the meadow floor drawn in blocks, with everything on it lifted | see its `Files:` line below | no -- waits for FC-2 (Codex lane) to release `main.gd` and the save files (Dave put FC-2 first, 13 Oct 2026; CD-3 released `bee.gd` 12 Oct 2026) | high |
| SP-8 (rest) | height's effects: flight cost, where flowers grow, scouting reach | to be cut after SP-8a | no -- after SP-8a | high (balance) |

Dependencies: SP-2 -> SP-4 -> SP-5 -> SP-6 (SP-1 and SP-3 landed 9 Oct 2026).
SP-10 -> SP-11 (both edit `scripts/hive_cell.gd`).
SP-8a and HM-1 (`plans/now/hive-and-menu-art.md`) both edit `scripts/hive.gd`
and `scripts/rival_hive.gd`; both are Claude lane, so whichever lands second merges master first.

SP-1 shipped 2026-10-09; its specification is `plans/archive/SP-1_2026-10-09.md`.

SP-2 shipped 2026-10-10; its specification is `plans/archive/SP-2_2026-10-10.md`.

SP-4 shipped 2026-10-11; its specification is `plans/archive/SP-4_2026-10-11.md`.

SP-7 (the whole comb drawn from Dave's cell art: honey, jelly, larva, both
bee breads, fermented nectar and the wax caps) shipped 2026-10-12 as ad-hoc
work on Dave's request; its record is `plans/archive/SP-7_2026-10-12.md`.

SP-5 shipped 2026-10-12; its specification is `plans/archive/SP-5_2026-10-12.md`.

```queue
**[Claude] SP-10 -- hive soil blocks draw front over back everywhere**
- Plan: `plans/now/sprites.md` -- "SP-10 -- hive soil blocks draw front over back everywhere"
- Files: `scripts/shapes.gd`, `scripts/soil_block.gd`, `scripts/rock_block.gd`, `scripts/hive_cell.gd`, `tests/sp10_soil_depth_test.gd`, `tests/test_sp10_soil_depth.py`
- Check: `python -m unittest tests.test_sp10_soil_depth` passes: every soil and rock block in a fresh hive has `z_index == Shapes.hex_draw_depth(axial)`, a block one row lower on screen has a higher `z_index` than the block above it, and a comb cell and a soil block on neighbouring hexes order the same way.
- Proof: `absent: scripts/soil_block.gd :: z_index`
- Next after: SP-11 -- every ring on a cell traces the cup's rim
```
SP-10 shipped 2026-10-15; its specification is `plans/archive/SP-10_2026-10-15.md`.
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

**Hands-on check on landing** (move from `checks/blocked.md` to ready):
C-134.

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

Decisions (Dave, 12 Oct 2026, answering the /run-queue question on how to
cut SP-8):

7. **Grid.** One block per 32-art-px top face (48 world units across),
   heights -2 to +3 blocks in half steps, and a full block lifts what stands
   on it by 14 art px (21 world units).
8. **First cut.** SP-8a draws the height map *and* lifts everything on the
   ground -- flowers, the hive, landed bees, click targets included -- in
   one slice. Height's simulation effects follow as their own slices.

Cut so far: SP-8a, the height map with its drawing and the lift, below.
Still to cut, each its own slice after SP-8a lands: flight cost (balance,
which `GameConfig` owns and which is simulated first), where flowers grow,
and scouting reach. Water in the meadow does not exist yet; that effect
waits for it.

## SP-8a -- the meadow floor drawn in blocks, with everything on it lifted

Level: high (save field, per-bee hot path, click targets). Decisions: SP-8
above, items 1, 3-5 and 7-8. Height has no simulation effect in this slice.

**True now** (verified 12 Oct 2026 against master `01002c2`).

- `world_building.gd::_build_meadow` draws the meadow floor as one flat
  `Polygon2D` of `main.MEADOW_COLOR`, centred on `HIVE_MARKER_POSITION`,
  `FLOWER_FIELD_HALF_SIZE + GRASS_MARGIN` each way (4400 x 3400 world
  units). `grass_base` is in `sprite_catalogue.gd` but nothing draws it.
- `grass_block`, `grass_block_half`, `soil_block` and `soil_block_half` are
  exported and in `sprite_catalogue.gd` (`*_ANCHOR` is the top face's
  middle). The full block's top face is 32 x 16 art px with a 14 art px
  side under it; the half block's side is 7 art px.
- No height exists anywhere: nothing in `scripts/` names `MeadowTerrain`
  or `meadow_heights`. The RAISED obstacles (`obstacle.gd`, plateaus no bee
  may enter) are a separate mechanism and stay as they are.
- The meadow layout comes from the global RNG, seeded in `main.gd`
  (`seed(DEFAULT_RANDOM_SEED)`, or a scenario's `random_seed` in its
  scenario setup);
  flowers are saved (`save_game.gd` `"flowers"`), and obstacles are rebuilt
  from the seed.

**Owner.** Nothing owns meadow height today. A new
`scripts/meadow_terrain.gd` (`class_name MeadowTerrain`) owns it: the
height grid, its generation, `height_at(world_point)` and
`lift_at(world_point)` (world units), and `save_data()`/`restore(data)`.
It is simulation state: later SP-8 slices read the same map for flight cost,
flower placement and scouting reach. Presentation reads `lift_at` and
never writes the map.

**True afterwards.**

- **Grid.** One column per 48 x 24 world units (the 32 x 16 art px top face
  at the meadow's 1.5 world units per art px), covering the area today's
  flat polygon covers. Heights run from -2 to +3 blocks in half-block steps.
  A full block lifts what stands on it by 21 world units (14 art px) and a
  half block by 10.5, so `lift_at` = height x 21. Height 0 draws exactly
  where the flat meadow does today.
- **Generation.** Gentle seeded hills and hollows (a few broad rises and
  dips, not noise per column), made by the terrain's own
  `RandomNumberGenerator`, seeded from the run's random seed, which
  `main.gd` keeps in a field. The global RNG is never drawn from, so for any
  seed the flowers, obstacles and starting foragers are where they are on
  master today. The hive's column, and every column within
  `FLOWER_MIN_DISTANCE` of `HIVE_MARKER_POSITION`, are height 0. The
  steward chose this so that bees go in and out of the entrance on level
  ground; Dave may change it at the hands-on check.
- **Drawing.** The flat polygon goes. Each column draws as a stack: a
  grass block (full or half) on top, and under it the soil blocks needed to
  show its side down to the column in front. It is drawn back to front, so
  a nearer column covers the one behind it. The floor is static: it is
  built once, when the meadow is built and when a save is restored, never
  per frame. It uses batched layers (for example one `TileMapLayer` per
  half-step level, offset by its lift), not a node per block. Record the
  meadow-view frame time before and after in this section
  (`docs/performance.md`).
- **Lifting.** Everything that stands on the ground draws raised by
  `lift_at` of its position, and its children move with it: each flower
  (with its crab-spider marker), the hive, the rival hive, trees and
  plateaus, and every bee that is on the ground or on a flower (load dot,
  rings and speech bubble included). A flying bee's lift eases toward the
  ground under it, over about 0.25 s, so it never jumps at a block edge.
  The lift is a drawing offset only: positions, distances, the spatial
  grids and every simulation result stay what they are on master. Bees work
  out the lift in their existing display update, by one grid lookup, and
  set it only when it changes (`.claude/rules/performance.md`; profile
  before and after).
- **Click targets.** Clicking or drag-selecting compares against where a
  thing is drawn, not its flat position: `input_selection.gd`'s bee, flower,
  obstacle and hive hit tests, and the drag box. A command on open ground
  goes to the column whose drawn top face is under the cursor, checking the
  nearest column first.
- **Save.** `meadow_heights` is an additive field in the save
  (`.claude/rules/saving.md`): an old save without it loads flat, with no
  `FORMAT_VERSION` bump. A checkpoint restore brings back the exact map.
- **Hands-on** (filed at closeout): in a Colony Run's meadow, the floor
  reads as Dave's stacked blocks, with hills up to three blocks high and
  hollows two deep. Flowers, the hive, trees and landed bees sit on their
  block's top face. Clicking a flower or a bee on a hill selects it.

**Must not change.** Flight, foraging, flower placement and scouting
results (the scenario baselines `verify.ps1` runs stay green), the hive
interior, and the RAISED obstacles' blocking.

```queue-gated
**[Claude] SP-8a -- the meadow floor drawn in blocks, with everything on it lifted**
- Plan: `plans/now/sprites.md` -- "SP-8a -- the meadow floor drawn in blocks, with everything on it lifted"
- Files: `scripts/meadow_terrain.gd`, `scripts/main.gd`, `scripts/world_building.gd`, `scripts/flower.gd`, `scripts/hive.gd`, `scripts/rival_hive.gd`, `scripts/obstacle.gd`, `scripts/bee.gd`, `scripts/input_selection.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/sp8a_meadow_height_test.gd`, `tests/test_sp8a_meadow_height.py`
- Check: `python -m unittest tests.test_sp8a_meadow_height` passes. It checks that a seeded map lies in -2 to +3 in half steps, that the same seed gives the same map, and that the hive's ground is 0. For the default seed, flower and obstacle positions match master. A flower and a landed bee on a raised column draw lifted by height x 21, and a click at the drawn point selects them. The map survives save and restore, and an old save loads flat. The frame-time comparison is recorded in this section, and `.\tools\verify.ps1` is green.
- Proof: `absent: scripts/world_building.gd :: MeadowTerrain`
- Next after: SP-6 -- meadow foragers drawn from the sheet: eight directions, flapping wings
```

SP-9 shipped 2026-10-12; its specification is `plans/archive/SP-9_2026-10-12.md`.

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
