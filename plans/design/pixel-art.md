# Pixel art -- scale, sizes and conventions for every sprite

<!-- CONTEXT: plan | LAYER: design -->
Status: agreed art direction, built by `plans/now/sprites.md` | Owner: Dave | Next: Dave draws against the size tables below; the SP-2 exporter enforces the conventions | Dependency: none | Verified: 2026-10-12

What any new sprite must match so the game keeps one pixel style. Dave
reads the size tables when drawing in Resprite. A session reads the
conventions when adding a sprite. The slices that build all this are in
`plans/now/sprites.md`.

<!-- LAYER: durable-rules -->

## Two pixel scales, one per view (Dave, 9 Oct 2026)

The hive and the meadow are different scales. The hive is a closer view,
so the same bee takes more art pixels there: about 15 px indoors against
12 px outside. The two views use separate cameras and are never on screen
together (`camera_view.gd`, `main.in_hive_view`). So each view has one
fixed size of art pixel, and all art in that view uses it:

- **Hive: 1 art px = 1.1875 world units.** That is
  `GameConfig.hive_cell_spacing` (19) x 2 / 32, read off the 32-px cell.
- **Meadow: 1 art px = 1.5 world units.** At that scale both existing
  meadow pieces keep their in-game size: the 12-px forager makes today's
  18-unit bee, and the 42-px skep makes today's 60-unit hive square.

Art is never scaled in the editor, and never scaled by a non-integer
amount in the game except by these two constants. Mixing pixel sizes on
one screen is what breaks a pixel style.

## Pixel sizes for new art

"Today" is what the game draws now, in world units.

**Hive view (1 px = 1.1875 units)**

| Element | Today | Art | Canvas |
| --- | --- | --- | --- |
| Comb cell, every content | 38 across | 32 wide, 16-px floor + up to 14-px back wall | 32x32, the template for every hive tile |
| Soil, bedrock, hive floor, tunnel tiles | hex about 39 across | same footprint as a cell | 32x32, floor at Base Y 14, H 16 |
| Fill states (honey, brood, jelly, corpse, bee bread) | flat hex | layers over the empty cup, like nectar | 32x32 |
| Worker bee indoors | circle 18 | **at most 15 px long** | 16x16 |
| Drone / gyne / queen indoors | 21 / 24 / 28 | 18 / 20 / 23 px | 24x24 |
| Dead bee | 10 | 8 px | 8x8 |

The worker limit is real: bees stand at a cell's walls, and the stand
points on the squashed grid are only 12-20 units apart. A bee bigger
than 15 px covers its neighbour more than today's circle does.

**Meadow view (1 px = 1.5 units)**

| Element | Today | Art | Canvas |
| --- | --- | --- | --- |
| Forager (worker) | 18 | 12 px (today's art: 9-12, fine) | 16x16 grid cells |
| Drone on a mating flight | 21 | 14 px | 16x16 |
| Gyne / queen on a mating flight | 24 / 28 | 16 / 19 px | 24x24 |
| Your hive (skep) | 60x60 | 40 px (today's skep: 42x35, fine) | crop to 44x37 |
| Rival hive | 52x52 | the skep recoloured by the exporter | as the skep |
| Flower, per species | 28x28 | 19 px, centre about 7 px | 20x20 |
| Crab spider | 8 | 5 px is unreadable: draw 7 px | 8x8 |
| Tree | radius 22-34 | canopy 29-45 px | 32, 40 or 48, picked by radius |
| Raised ground | radius 130-240 | 173-320 px, too big for one sprite | a 16x16 edge tileset, later |
| Grass | whole meadow | 32x32 tile, repeated (`grass_base.png`, fine) | 32x32 |
| Dead bee | 10 | 7 px | 8x8 |

## Out of proportion, or off the pixel grid

1. **The hive is as big as a tree.** The skep (60 units) is as wide as
   the largest tree (68) and wider than most, so a 45-px canopy beside it
   reads as a shrub. Either keep that as stylisation or draw canopies that
   overhang their trunk circle, up to about twice the radius. Overhang is
   presentation only, so tree collision does not change.
2. **Crab spider:** at 5 px it cannot be read; draw it at 7 px.
3. **Forager body length varies by direction:** the up-facing row is
   12 px long, down-facing 11, side views 11x9 and diagonals 10x9. Even
   them out in the repack.
4. **Skep canvas:** it has 6 empty px on each side and 2-4 above and
   below. Crop to a 1-px margin so its anchor stays simple.
5. **Fog of war** tiles are 5 units, which is 3.33 meadow px, so fog edges
   never line up with art pixels. 6 units (4 px) or 4.5 (3 px) would. The
   fog is performance-sensitive, so this is a separate decision, not part
   of the sprites plan.

## Conventions every sprite file follows

- One `.aseprite` per sprite family, saved from Resprite or Aseprite, in
  assets/sprites/comb/, assets/sprites/meadow/ or assets/sprites/bees/,
  named in lowercase with underscores (`wax_cell_nectar.aseprite`). A
  single-image sprite with no layers may be a plain `.png`.
- **Layer sprites** (cells): the bottom layer is the base, drawn under
  every other layer. Each other layer is one state, named
  `<family>.<state>`. Layer visibility does not matter.
- **Frame-per-layer sprites** (overlays and stages: the wax caps, a soil
  block crumbling): each layer is a whole frame with no base under it.
- **Single sprites** made of layers flatten the visible layers; hidden ones
  are left out.
- **Grid sprites** (directions, animation): one layer named `sheet`, with
  frames on a fixed grid (16x16 or 24x24). Every frame is centred on the
  same body point and has at least 1 px of empty space around the art.
- Layers whose names start with `_` are guides and are ignored.
- No anti-aliasing. Translucency is allowed where it is the material
  (honey, the thin middle of a wax cap going on); the exporter blends it
  over the base (Dave's art, 12 Oct 2026).
- Each family gets one row in the sprite table (assets/sprites/SPRITES.md,
  created by SP-2). The row gives: file, what it shows, view, layout
  (layers, or grid + row order by direction name), level bounds, anchor
  and recolour variants. A recolour variant (for example fermented nectar
  or the rival hive) is a colour swap the exporter applies, so it needs no
  new drawing.

## Art still to draw (Dave)

- In-hive bees: worker 16x16, drone/gyne/queen 24x24.
- Cup layers: corpse. (Honey, brood, royal jelly, both bee breads and the
  wax caps were drawn on 10 Oct 2026.)
- Bedrock, floor and tunnel tiles on the 32x32 cup template. (Soil and
  grass blocks, full and half height, were drawn on 10-11 Oct 2026.)
- A flower per species (20x20).
- Trees (32/40/48).
- Crab spider (8x8).
- The repacked forager sheet.
- Meadow drones and queens for mating flights.
