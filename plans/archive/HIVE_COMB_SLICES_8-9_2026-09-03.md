# Hive comb — Slices 8 and 9, delivered 3 September 2026

<!-- CONTEXT: archive | LAYER: history -->
Status: archived | Owner: Dave / Claude Code | Next: None — archived record | Dependency: none | Verified: 2026-09-03

Provenance only. Slice 8's ring work was superseded by Slice 9, which cut
every ring from the sprite's measured silhouette; its hands-on
confirmation is C-9 in `checks/ready.md`. The live plan is
`plans/now/hive-comb.md`. Slices 1-3, 6 and 7 are at
`plans/archive/HIVE_COMB_SLICES_1-3_6-7.md`.

---

## Slice 8 — Cell highlight borders do not follow the cell sprite's silhouette (shipped 3 Sep 2026)

**Was:** `hive_cell.gd` built five outlines and only `selection_ring` knew
about the cup sprite's raised back wall. The base `outline`, the
`designation_ring` and the nursery `zone_glow`/`zone_halo` all went through
the flat `_set_outline_points()`, so with Cell art on they cut straight
through the wall the sprite draws. Slices 1-3 fixed the one ring their check
happened to name and left the other four.

**Now:** every ring goes through one `_apply_outline_points(line, size)`,
which makes the `Session.use_cell_sprites` decision once for the whole file;
`_set_selection_ring_points()` is a single call to it. `_refresh()` re-points
the four constant-size rings when, and only when, the setting flips under
them, so a live toggle reverts all of them without four Line2D rebuilds per
cell six times a second. The one deliberate exception is an unfinished
cell's stub outline, which stays flat at both settings: a site draws no cup
sprite, and the cup's raised wall is an absolute offset that would tower
over a 35%-size stub. No ring's size argument, `EMPTY_TEXTURE_BASE_Y`,
`EMPTY_SPRITE_SCALE_NUDGE` or `cell_size` changed.

**Hands-on check: failed 3 Sep 2026.** Dave re-ran it and the rings still
do not follow the art. Routing them all through one helper was right and
is kept; the silhouette that helper draws is wrong. See Slice 9.

## Slice 9 -- Rings must be cut from the sprite's measured silhouette, not from a hexagon with a guess added to it (shipped 3 Sep 2026)

**Symptom (Dave, 3 Sep 2026, re-running Slice 8's check).** "Cell highlight
borders: still not in alignment." The flat-hex half of that check passed --
turning Cell art off returns every ring to the flat hex within a fraction of
a second -- so `_apply_outline_points` is being called in the right places.
The shape it produces is wrong.

**Root cause -- the cup outline is a hexagon with two corners nudged
upwards, and the sprite is not that shape.** `_set_outline_points_cup()`
starts from `Shapes.hexagon_points(size, squashed)` and raises points 4 and
5 by `EMPTY_TEXTURE_BASE_Y * empty_scale`. Two things go wrong:

1. `Shapes.hexagon_points` draws a **regular** hexagon of radius `size`,
   optionally squashed vertically by `SQUASH` (1/sqrt 3) when the
   sprite-aligned grid is on. At `hive_cell_size = 17` that is 34 wide and
   either 34 or 19.6 tall. The sprite is 32 wide and 27 tall and does not
   change with the grid setting at all, so the ring and the art disagree on
   both axes before any corner is nudged.
2. The real silhouette is not a hexagon. Measured off
   `assets/sprites/environment/wax.cell.empty.png` (32x32 canvas, alpha
   scanned row by row): opaque rows run y=4..30; the top edge is 16px wide
   (x=8..23) at y=4; the bottom edge is 16px wide (x=8..23) at y=30; the
   full 32px width is held for eleven rows, y=12..22. It is a flat-topped
   hexagon with **vertical sides** -- eight corners, not six. Dave measured
   the same thing by eye: "top and bottom sides are 16px along, 27px high,
   32px across at its widest points, which are at 9-18px heights"
   (his heights are measured from the top of the shape, i.e. canvas rows
   13..22).

**Fix -- state the art's outline once, as data, and derive every ring from
it.** All of this is in `scripts/hive_cell.gd`.

- a) Add a const holding the measured silhouette in texture pixels, with a
  comment recording that it was measured off the PNG's alpha and how
  (so a resprite is re-measured, not re-guessed):

  ```gdscript
  ## The empty-cell sprite's own outline, in pixels on its 32x32 canvas.
  ## Measured off EMPTY_TEXTURE's alpha: opaque rows 4..30, a 16px flat top
  ## edge at y=4 (x=8..23), a 16px flat bottom edge at y=30, and the full
  ## 32px width held between y=12 and y=22. Eight corners, not six -- the
  ## cup has vertical sides, which is why a hexagon can never trace it.
  ## Re-measure this if wax.cell.empty.png is redrawn.
  const EMPTY_SILHOUETTE: Array = [
      Vector2(8.0, 4.0), Vector2(24.0, 4.0), Vector2(32.0, 12.0),
      Vector2(32.0, 23.0), Vector2(24.0, 31.0), Vector2(8.0, 31.0),
      Vector2(0.0, 23.0), Vector2(0.0, 12.0),
  ]
  ```

- b) Add a helper that converts one silhouette point into this cell's local
  space using **exactly** the arithmetic `_ready()` already uses to place
  `empty_sprite`, so the ring and the sprite cannot drift apart:
  a texture point `p` lands at
  `((p.x - EMPTY_TEXTURE.get_width() * 0.5) * s,
    (p.y - (EMPTY_TEXTURE_BASE_Y + EMPTY_TEXTURE_BASE_H * 0.5)) * s + EMPTY_SPRITE_Y_NUDGE)`
  where `s = empty_scale * EMPTY_SPRITE_SCALE_NUDGE`. Derive it from the
  sprite's own `offset`/`scale` fields rather than re-typing the numbers if
  that reads more clearly; the test is that the outline sits exactly on the
  drawn cup at `hive_cell_spacing = 19`.

- c) Rewrite `_set_outline_points_cup(line, size)` to walk
  `EMPTY_SILHOUETTE`, convert each point with (b), then scale the result
  about the cell's origin by `size / cell_size` -- that ratio is how the
  five rings already differ (`cell_size - 3`, `cell_size`, `+2`, `+4`,
  `+6`), so their existing separation is preserved with no new constants.
  Close the loop by re-adding the first point, as `_set_outline_points`
  does. Delete the `cup_height` nudge and the "points 4 and 5" comment; no
  ring should refer to hexagon corner indices any more.

- d) Leave `_set_outline_points` (the flat hex, cell art off), the stub
  outline exception for an unfinished cell, `_apply_outline_points`'s
  routing, `_refresh`'s live re-point, `EMPTY_TEXTURE_BASE_Y`,
  `EMPTY_SPRITE_SCALE_NUDGE`, `cell_size` and every ring's size argument
  exactly as they are. This slice changes one function's contents and adds
  two definitions.

**Acceptance.** With Cell art on, at both settings of Sprite-aligned hex
grid: the base outline, the designation ring, the selection ring and the
nursery glow and halo all trace the cup's own silhouette -- flat top, flat
bottom, vertical sides -- rather than a hexagon, and none of them cuts
across the sprite's edge. The five remain visibly separated from each other.
With Cell art off, every one of them returns to the flat hex within a
fraction of a second (unchanged from Slice 8, and confirmed working on
3 Sep). A part-built cell's stub outline stays flat at both settings.

**Check:** `tools/verify.ps1`. One hands-on check to file, replacing the
Slice 8 entry in `checks/ready.md`.

**Files:** `scripts/hive_cell.gd`.

**Next after:** Slices 4 and 5 remain Dave's live look; this plan has no
other startable slice.

