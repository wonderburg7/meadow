# Pixel art -- scale, sizes and conventions for every sprite

<!-- CONTEXT: plan | LAYER: design -->
Status: agreed art direction, built by `plans/now/sprites.md` | Owner: Dave | Next: Dave draws against the size tables below; the SP-2 exporter enforces the conventions | Dependency: none | Verified: 2026-10-30

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
| Drone indoors | 21 | same as the worker (Dave, 30 Oct 2026): 15 px, the worker sheet or a recolour of it | 16x16 |
| Gyne / queen indoors | 24 / 28 | 20 / 23 px, drawn separately from the meadow ones | 24x24 |
| Wax moth, resting (infested hive; no moth exists in the sim yet) | none | 14 px, at most 15, duller than the bees | 16x16 |
| Dead bee | 10 | 8 px | 8x8 |

The worker limit is real: bees stand at a cell's walls, and the stand
points on the squashed grid are only 12-20 units apart. A bee bigger
than 15 px covers its neighbour more than today's circle does.

**Meadow view (1 px = 1.5 units)**

| Element | Today | Art | Canvas |
| --- | --- | --- | --- |
| Forager (worker) | 18 | 12 px (today's art: 9-12, fine) | 16x16 grid cells |
| Drone on a mating flight | 21 | same as the worker (Dave, 30 Oct 2026): 12 px, the forager sheet or a recolour of it | 16x16 |
| Gyne / queen on a mating flight | 24 / 28 | 16 / 19 px, drawn separately from the hive ones | 24x24 |
| Butterfly (decoration; none in the game yet) | none | wingspan 18-22 px, 4 flap frames | 24x24 |
| Your hive (skep) | 60x60 | 40 px (today's skep: 42x35, fine) | crop to 44x37 |
| Rival hive | 52x52 | the skep recoloured by the exporter | as the skep |
| Flower, per species | 28x28 | the whole plant (bloom, stem, leaves), bloom 20-24 px so a 10-12 px bee fits on it | 32 wide, height by species: see "Plants" below |
| Crab spider | 8 | 5 px is unreadable: draw 7 px | 8x8 |
| Tree | radius 22-34 | canopy 29-45 px wide, upright | portrait 32x48, 40x60 or 48x72, picked by radius; anchor bottom-centre at the trunk foot |
| Raised ground | radius 130-240 | 173-320 px, too big for one sprite | a 16x16 edge tileset, later |
| Grass | whole meadow | 32x32 tile, repeated (`grass_base.png`, fine) | 32x32 |
| Dead bee | 10 | 7 px | 8x8 |

## Plants (Dave, 30 Oct 2026)

The meadow floor is drawn as blocks with a visible side face, so the view
is oblique and plants are drawn upright on portrait canvases. The old
19 px flower only carried over the 28-unit placeholder square; the numbers
here replace it. The sizes marked * are proposals Dave has not yet drawn
against.

| Plant | Bloom | Canvas | Landing point |
| --- | --- | --- | --- |
| Clover* | 20 | 32x32 | middle of the head |
| Dandelion* | 22 | 32x32 | middle of the disc |
| Poppy* | 24 | 32x40 | middle of the cup |
| Borage* | 22 | 32x40 | middle of the star |
| Foxglove* | 24 wide spike | 32x48 | mouth of the lowest open bell |
| Bramble bloom* | 20 | 24x24 | middle of the bloom |
| Bramble bush backdrop* | about 36 wide, no blooms painted on, 2-3 variants | 40x40 | none |

- **The anchor is the landing pixel.** A forager flies to the Flower
  node's origin and feeds there, so the anchor is the middle of the bloom,
  not the middle of the canvas. Mark it with one pixel on a layer named
  `_anchor` (ignored by the exporter); the sprite-table row's Anchor
  column is read off it.
- **A bramble bush is 2-4 separate Flower nodes** (`bush_min_units` /
  `bush_max_units`), each with its own feeding slot and its own backdrop,
  so the blooms stay separate sprites and the backdrop carries no bloom.
  Painting blooms into one bush sprite would need fixed landing points in
  code, a separate decision.
- **The bee hides the middle.** A 12 px bee covers about 12x9 px of the
  bloom: put the species' identifying shape and colour in the outer
  petals, and keep yellow-and-black bees off yellow centres.
- **Keep a clear petal patch about 5 px up and right of the landing
  point** for the 7 px crab spider.
- **No opacity states.** The current fade (35 % to opaque with fullness)
  and the grey 0.7-scale out-of-season look both go once the frames exist
  (0.7 is a non-integer scale). Each flower has two frames: `fresh` (the
  full bloom) and `spent` (the same plant, same canvas, same anchor, but
  drained: drooped, closed or dulled, with a colour change as well as a
  shape change). One `spent` frame covers both "emptied by bees" and "out
  of season" until Dave asks for two. Dandelion's is the white seed puff;
  poppy's has dropped petals and the seed capsule.
- **Sway frames are optional.** One file per species, `flower_<species>.aseprite`,
  a `sheet` layer, rows `fresh` then `spent`, sway frames along each row.
  The exporter wants the same frame count in every row, so decide the
  count before drawing. Keep the landing pixel fixed through the sway and
  move only leaves and outer petals. The animation is presentation only.
- **Trees** are portrait and anchored bottom-centre at the trunk foot,
  where the collision circle sits. The canvas width is the canopy width.
  If canopies overhang the trunk circle (see 1 below), widen those
  canvases by about 1.5x.
- **Code that must follow the art** (none changed yet): drone size factor
  1.18 to 1.0 in `bee.gd`; flower click radius and selection ring re-fitted
  to the bigger sprites; the fade and the 0.7 scale in `flower.gd` replaced
  by the `fresh` / `spent` swap.

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
  assets/sprites/comb/, assets/sprites/meadow/, assets/sprites/bees/ or
  assets/sprites/menu/ (top-bar icons, 32x32),
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

- In-hive bees: worker 16x16 (drones reuse it), gyne and queen 24x24.
- Meadow gyne and queen for mating flights, 24x24 (meadow drones reuse
  the forager sheet; the forager sheet itself landed 22 Oct 2026).
- A flower per species, `fresh` and `spent` frames, sway optional (see
  "Plants"), and the bramble bush backdrop.
- Trees, portrait 32x48 / 40x60 / 48x72.
- Crab spider (8x8).
- Dead bee, hive and meadow (8x8).
- Cup layers: corpse. (Honey, brood, royal jelly, both bee breads and the
  wax caps were drawn on 10 Oct 2026.)
- Bedrock, floor and tunnel tiles on the 32x32 cup template. (Soil and
  grass blocks, full and half height, were drawn on 10-11 Oct 2026.)
- Wax moth, resting, 16x16, and butterflies, 24x24 with 4 flap frames:
  neither creature exists in the sim yet.
- Later: the raised-ground 16x16 edge tileset.
- Drawn, waiting for export (not Dave's to draw): the two hive-in-meadow
  sprites and the five top-bar icons (HM-1, HM-2).
