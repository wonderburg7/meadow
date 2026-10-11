# Sprites -- pixel art in the comb and the meadow, and one cheap way to add more

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SP-5 -- the skep in the meadow, specified below and queued (SP-1 to SP-4 landed); SP-6 waits for Dave's repacked forager sheet | Dependency: none to start; the files it shared with BB-2 and NF-4 are free since both landed 10 Oct 2026 (SP-1, BB-1 and NF-3 landed 9 Oct 2026) | Verified: 2026-10-10

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
| SP-4 | nectar and pollen fill levels drawn from the sprites | `scripts/hive_cell.gd`, `scripts/settings_catalogue.gd`, the sprite table and catalogue, tests | no -- landed 11 Oct 2026 | medium |
| SP-5 | the skep in the meadow, and the rival hive as a recoloured skep | `scripts/hive.gd`, `scripts/rival_hive.gd`, the sprite table and catalogue, tests | yes -- SP-4 landed 11 Oct 2026 | medium |
| SP-6 | meadow foragers drawn from the sheet: eight directions, flapping wings | `scripts/bee.gd`, the sprite table and catalogue, tests | no -- waits for Dave's repacked sheet | high (per-bee hot path) |

Dependencies: SP-2 -> SP-4 -> SP-5 -> SP-6 (SP-1 and SP-3 landed 9 Oct 2026).

SP-1 shipped 2026-10-09; its specification is `plans/archive/SP-1_2026-10-09.md`.

SP-2 shipped 2026-10-10; its specification is `plans/archive/SP-2_2026-10-10.md`.

## SP-4 -- nectar and pollen fill levels drawn from the sprites

**True now.** A filled cell hides the cup and draws a flat hex plus
`fill_shape`, a hex scaled by sqrt(fraction).

**True afterwards.**

- With `use_cell_sprites` on, a nectar or pollen cell shows the
  catalogue frame for its level: the first level whose upper bound is at
  least amount / capacity, or the empty frame at 0.
- Fermented nectar shows a `fermented` recolour variant (lime ->
  `FERMENTED_NECTAR_COLOR`), which needs no new art.
- Flat body and `fill_shape` are hidden, and the rings follow the cup.
- Contents with no art keep today's flat look.
- The bounds are presentation, not balance, so they live in the sprite
  table, not `GameConfig`.
- The setting's tip text names filled cells too.
- Runtime: the frame is set in `_refresh`, and only when it changes.

```queue
**[Claude] SP-4 -- nectar and pollen fill levels drawn from the sprites**
- Plan: `plans/now/sprites.md` -- "SP-4 -- nectar and pollen fill levels drawn from the sprites"
- Files: `scripts/hive_cell.gd`, `scripts/settings_catalogue.gd`, `assets/sprites/SPRITES.md`, `scripts/sprite_catalogue.gd`, `tests/test_sp4_fill_sprites.py`
- Check: `python -m unittest tests.test_sp4_fill_sprites` passes and `python tools/sprites.py --check` is clean; `tools/verify.ps1` is green
- Proof: `present: scripts/hive_cell.gd :: const NECTAR_COLOR :=`
- Next after: SP-5 -- the skep in the meadow, and the rival hive as a recoloured skep
```

## SP-5 -- the skep in the meadow, and the rival hive

**True afterwards.**

- `hive.gd` gets a sprite child drawn at the meadow scale, with its
  footprint centred on the hive. The 60x60 square stays as the hit shape,
  drawn transparent.
- `rival_hive.gd` does the same with a darker recolour variant.
- Hands-on: the skep sits where the square was, and foragers arrive at its
  entrance.

```queue
**[Claude] SP-5 -- the skep in the meadow, and the rival hive as a recoloured skep**
- Plan: `plans/now/sprites.md` -- "SP-5 -- the skep in the meadow, and the rival hive"
- Files: `scripts/hive.gd`, `scripts/rival_hive.gd`, `assets/sprites/SPRITES.md`, `scripts/sprite_catalogue.gd`, `tests/test_sp5_skep.py`
- Check: `python -m unittest tests.test_sp5_skep` passes and `python tools/sprites.py --check` is clean; `tools/verify.ps1` is green
- Proof: `present: scripts/hive.gd :: extends Polygon2D`
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
