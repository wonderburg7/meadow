# Meadow hive comb — active slice

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 9 (rings cut from the sprite's measured silhouette), either lane | Dependency: none for Slice 9; Slices 4 and 5 still need Dave's live look | Verified: 2026-09-03

No `plans/now/` file previously owned the empty-cell resprite / sprite-aligned
hex grid / cell-art settings cluster — it shipped and was tracked only as
`checks/ready.md` entries. Dave's 30 Aug hands-on pass confirmed most of it
outright and found four further items, none of them a regression of what
shipped. This is the first plan file for this area.

## Confirmed working (30 Aug hands-on pass, no action)

- Cell art toggle (on/off, instant revert to flat colour).
- Column-run z-order (a cell built later still paints correctly behind one
  built earlier but sitting lower on screen).
- Cells holding a resource are unaffected by the Cell art toggle either way.
- Sprite-aligned hex grid geometry and traversal (foragers, miner, queen).
- Direction-even hex speed, on and off, with no odd paths/stalling.
- Automine block selection.
- Typeface switching (all five faces, both text-scale extremes).

Slices 1-3, 6, 7 and 8 are shipped; 1-3, 6 and 7 are archived at
`plans/archive/HIVE_COMB_SLICES_1-3_6-7.md`. Dave's 2 Sep 2026 pass
confirmed their hands-on checks -- cell art, above-centre rows and wide-comb
routing all survive a save and load -- with one exception, which is Slice 8
below. Slices 4 and 5 still need Dave's live look before any code is
written, so neither appears in `NEXTSTEPS.md`.

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

## Slice 9 -- Rings must be cut from the sprite's measured silhouette, not from a hexagon with a guess added to it

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

## Slice 4 — Cell auto-building: spiral order looks wrong (live repro needed first)

**Symptom (Dave, 30 Aug, general play — distinct from the queen-specific
auto-spiral bug Challenge 1 Slice 8d already fixed, see
`plans/now/challenge-1.md`):** ordinary automatic Comb Worker building does
not appear to grow the comb in the expected spiralling-hexagon shape.

**Traced, not yet confirmed as a bug:** `hive.gd::create_next_cell_site()`
walks `Shapes.hex_spiral_at(index)` in increasing index order and returns
the first tile passing `_can_build_on()` — this is a spiral by construction,
so the spiral math itself is not the suspect. Two live-only candidate
causes:

1. Every idle Comb Worker calls `create_next_cell_site()` independently on
   its own think-tick. `_start_site_at()` registers the tile
   (`register_tile`/`invalidate_index`) synchronously inside the same call
   that creates it, which should make two same-frame calls safe — but this
   needs confirming live rather than assumed, since dispatch order across
   many idle bees in one frame hasn't been traced here.
2. `_can_build_on()` only offers *dug, walkable* tiles. What looks like "not
   spiralling" may actually be a correct spiral *selection* constrained by
   which ground has been dug so far — it will look uneven whenever mining
   hasn't kept pace symmetrically with comb growth, which is the normal case
   in an ordinary playthrough.

**Action:** reproduce in an isolated Scenario with generous pre-dug, symmetric
open floor and several idle Comb Workers (removing the digging-asymmetry
variable) before writing any fix to `create_next_cell_site()` — same
discipline `challenge-1.md`'s Slice 8d used for its own "confirmed-plausible,
pending live-boot confirmation" finding.

`test_scenarios/hive_comb_spiral_repro.json` is that reproducible setup: it
starts four automatic Comb Workers with no cells or miners, expands the fully
open interior to seven rings, and stops after 37 completed cells (the centre
plus the first three complete hex rings). Its bounded `build_target` trace
records every automatic target while the live boot supplies the visual answer;
it deliberately does not treat a target-order assertion as proof that the
drawn comb looks right. Run it with
`./tools/run_headless.ps1 test_scenarios/hive_comb_spiral_repro.json` for the
deterministic trace, then inspect the same `--scenario` boot visually before
scoping any change to `create_next_cell_site()`.

**Headless trace run (1 Sep, `run_id=b8cf41b4dc6c`, all 37 cells completed,
`queen_alive`/`actions_clean` both passed): candidate cause 1 confirmed by
the trace itself, no visual boot needed to see it.** Of 148 `assigned`
`build_target` events, 51 land on a `target_hex` that one or more other bees
were assigned in the very same tick. Tracing the first one: all four workers
get `target_hex=[0,0]` at `game_time=0.025`; all four `claimed` and
`completed` it together at `game_time≈2.6`; then all four get
`target_hex=[0,-1]` together next, and so on for the whole run. The comb
never grows at more than one site at a time — the four Comb Workers act as
a single herd walking the spiral tile-by-tile, rather than each opening its
own site and the ring filling in from several points in parallel.

Mechanism, read from `scripts/bee.gd:1359-1367` and
`scripts/hive.gd:553-557`: before calling `create_next_cell_site()`, an idle
Comb Worker first calls `hive.find_unfinished_cell()`, which returns the
first cell in `cells` with `is_built == false` — uncapped, so every idle
worker piles onto the single most recent unfinished site instead of a new
one opening once that site already has a builder. `find_unfinished_cell()`
is also what lets a worker resume a site abandoned mid-build (e.g. after a
death), which is correct; the bug is that it has no limit on how many
workers can queue onto the same site while other ring positions sit
untouched. This is a mechanism finding, not yet a scoped fix — capping
concurrent builders per site would speed up perceived spiral growth but
also changes overall build throughput (a balance question, not just a
visual one per `.claude/rules/simulation.md`), so it needs Dave's live-boot
look and a call on the intended behaviour before code changes. The `godot`
MCP server was unavailable both this session and the session that first
wrote this slice, so that visual step is still outstanding.

## Slice 5 — Cell-content feedback lag reading as "nothing happened" (design question, not confirmed a bug)

**Symptom (Dave, 30 Aug):** with Cell art on, a forager appears to be
contributing to a cell but the cell's look doesn't change until later.

**Likely explanation:** `empty_sprite` only shows while `content_type == ""`;
the moment any resource lands, the cell switches to its ordinary
fill-fraction shading (a washed-out body plus a full-strength `fill_shape`
scaled to the amount held) — which starts very pale at a low fill fraction
and is easy to miss next to the visually richer cup sprite it just replaced.
`add_resource()` does update `content_type`/`amount` the instant a deposit
lands, so this reads as a legibility gap, not a functional one, on current
evidence.

**Action:** confirm live that the switch away from the cup sprite really is
instant on first deposit (it should be, per `add_resource`) rather than
delayed. If confirmed instant, this becomes a follow-on design question —
whether a low-fill cell should keep a lighter version of the cup outline
instead of jumping straight to the current flat wash — not a code fix in
this slice.
