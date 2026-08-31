# Meadow hive comb — active slice

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 1 (empty-cell sprite
nudges); Slice 6 (new, above-centre-row cell rendering) is the higher-priority
find of the two | Dependency: none | Verified: 2026-08-31

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

## Slice 1 — Empty-cell sprite: two pixel-level alignment nudges

**Symptoms (Dave, 30 Aug):** the empty-cell cup sprite reads as one pixel too
low; and a thin sliver of a neighbouring cell's shadowed edge shows through
in the two lower-side placements, as if the two cups aren't quite as close
together as the flat-colour hexes are.

**Files:** `scripts/hive_cell.gd`, `_ready()` (~line 208-250).

### 1a. Vertical position

`empty_sprite.offset = Vector2(0.0, canvas_mid - base_mid)` (~line 246)
already derives its vertical placement from the resprite's own exported
`EMPTY_TEXTURE_BASE_Y`/`EMPTY_TEXTURE_BASE_H` constants, not a guess — so
don't change those (they're read straight off the Resprite export and
describe the asset, not the alignment). Add a separate, explicitly-named
tunable nudge instead, so a future re-export of the asset doesn't quietly
undo a value someone tuned by eye:

```gdscript
## Fine visual nudge on top of the derived offset above, in screen pixels
## (negative = up). Exists because the derived offset can be correct by
## the asset's own numbers and still read as one pixel off on screen --
## tune by eye, not by re-deriving EMPTY_TEXTURE_BASE_Y.
const EMPTY_SPRITE_Y_NUDGE := -1.0
```

Apply it after `empty_scale` is known (reorder if needed so the scale exists
first): `empty_sprite.offset = Vector2(0.0, canvas_mid - base_mid + EMPTY_SPRITE_Y_NUDGE / empty_scale)`
— dividing by `empty_scale` keeps the nudge a constant *screen*-pixel amount
regardless of `hive_cell_spacing`, rather than a texture-pixel amount that
would scale with cell size.

### 1b. Horizontal tessellation gap

Reported only on the two lower-side neighbour placements, not all six —
consistent with this being the *rendered* cup's edge falling a hair short of
true tessellation (a single sprite can't be nudged differently toward
different neighbours, so this isn't a per-direction offset problem). Most
likely cause: `empty_scale := (sprite_size * 2.0) / EMPTY_TEXTURE.get_width()`
(~line 234) is derived correctly from `hive_cell_spacing`, but Godot's
default nearest/linear texture filtering can round the rendered edge in by a
sub-pixel amount, and it happens to be visible on the two lower-side edges
specifically because those are the ones each cup's own back-wall doesn't
already paint over (see the `z_index` comment just above `_ready`).

Add a second small tunable next to `EMPTY_SPRITE_Y_NUDGE`:

```gdscript
## Same idea as EMPTY_SPRITE_Y_NUDGE, but scales the cup very slightly
## larger than exact tessellation would need, closing a filtering-rounding
## seam on the two lower-side neighbours. 1.0 = exact size, no nudge.
const EMPTY_SPRITE_SCALE_NUDGE := 1.0
```

Apply as `empty_sprite.scale = Vector2(empty_scale, empty_scale) * EMPTY_SPRITE_SCALE_NUDGE`.
Tune both nudges by eye against a real column and a real lower-side pair —
this is a feel/visual slice, not something to guess a final value for
blind.

**Acceptance:** Dave's own hands-on look confirms both nudges read right at
the default `hive_cell_spacing`; add a fresh `checks/ready.md` entry once
implemented (remove it again once confirmed).

## Slice 2 — Selection ring should trace the cup, not just the hex floor

**Symptom (Dave, 30 Aug):** with Cell art on, the green multi-select ring
still only outlines the flat hex base, cutting through the taller cup
sprite instead of going all the way around it.

**Diagnosed:** `hive_cell.gd::_ready()`'s `selection_ring` (~line 273-280,
also true of `designation_ring`, `zone_halo`, `zone_glow` — same shape) is
built once from `_set_outline_points(ring, cell_size + N)`, a plain hex
outline. It has no idea the cup sprite (when `Session.use_cell_sprites` is
on) extends above that hex floor by the cup's back-wall height (the same
14px-of-32 that `EMPTY_TEXTURE_BASE_Y` already describes, scaled by
`empty_scale`).

**Fix:** add a second point-set that includes that extra vertical extent —
e.g. `_set_outline_points_cup(ring, cell_size)`, offsetting the top two/three
outline points upward by `EMPTY_TEXTURE_BASE_Y * empty_scale` — and switch
which set `selection_ring` (at minimum; check whether `designation_ring`,
`zone_halo`, `zone_glow` show the same clipped-base look and extend them too
if so) uses based on `Session.use_cell_sprites`, both at `_ready()` and
wherever the cell-art toggle already refreshes `empty_sprite.visible` live
(find that toggle handler — likely `_refresh()` — and add the ring-shape
swap right next to it, not a new signal).

**Acceptance:** with Cell art on, the selection ring visibly outlines the
full cup silhouette on screen, not just its hex floor; with Cell art off,
the ring is pixel-identical to today.

## Slice 3 — Move four toggles from "Hive & comb" to "Appearance"

**Ask (Dave, 30 Aug):** Cell art, "Show cell contents text",
"Sprite-aligned hex grid" and "Direction-even hex speed" belong in
Settings > Appearance, not Settings > Hive & comb.

Trivial, zero-behaviour-risk: every setting in `scripts/debug_panel.gd` is
one dictionary entry with a plain `"category"` string — moving a control
between panel sections is a one-word edit per entry, exactly what that data
shape is for. Change `"category": "Hive & comb"` to `"category": "Appearance"`
for these four entries only, identified by `"key"`:

- `show_cell_contents_text` (~line 324-325)
- `use_cell_sprites`, labelled "Cell art" (~line 329-330)
- `use_sprite_hex_grid`, labelled "Sprite-aligned hex grid" (~line 334-335)
- `use_radial_hex_speed`, labelled "Direction-even hex speed" (~line 339-340)

Leave every `"label"`/`"tip"` untouched — the existing "only applies to a
freshly built hive" and "only matters while Sprite-aligned hex grid is on"
caveats stay accurate regardless of which tab they're filed under. Touch no
other `"category"` value.

**Acceptance:** all four controls appear under Settings > Appearance; none
remain under Settings > Hive & comb; every other Hive & comb entry is
unaffected.

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

## Slice 6 -- Cells above the comb's centre row don't render (new, 31 Aug 2026 pass)

**Symptom (Dave):** cells placed in rows above the central line of the comb
are not rendering.

**Confirmed-plausible, pending a live scene-inspector look -- same
discipline as Slice 9g in `plans/now/challenge-1.md`, which flagged exactly
this shape of bug as one of two candidates without yet pinning it down.**

`hive_cell.gd::_ready()` sets `z_index = 2 * axial.y + axial.x` (~line 221),
justified by a comment claiming "`Shapes.hex_to_pixel`'s y is always a
positive multiple of (2r + q)... regardless of where comb_centre sits."
That claim is false for any cell above the comb's origin: `hex_to_pixel(q,
r, ...)`'s y is `size * sqrt(3.0) * (r + q / 2.0) * y_scale`
(`shapes.gd:139-143`) -- proportional to `(2r + q)`, the exact same
expression `z_index` uses, and it goes negative whenever `r` (the cell's
`axial.y`) is negative and `q` isn't large enough positive to offset it,
i.e. exactly the row(s) above the centre. A cell with a negative `z_index`
still draws in Godot -- it doesn't vanish by itself -- but it now draws
*behind* anything else in the same tree with `z_index >= 0`, which very
plausibly includes the hive floor/background art painted at the default
`z_index = 0`. That would read as "the cell doesn't render" even though the
node exists, is built, and holds its content correctly (the same
"functionally exists, never paints" signature Slice 9g already named for a
different cell).

**Likely why this is surfacing only now:** the recent hex-grid
radial-symmetry fix (`1e0dc40`, `787495a`) specifically corrected
automine/build-spiral placement so it no longer drifts sideways under the
squashed-grid distance bug -- which means the comb can now grow evenly
upward (negative `axial.y`) for the first time, rather than being biased
away from that direction. This z_index formula's broken assumption may
always have been latent; it simply had nothing to expose it before.

**Fix:** the "always positive" property was never actually needed -- draw
order only needs a *consistent* ordering, not a positive one, and Godot's
own z_index range (-4096 to 4096) already supports negative values freely.
Two options, either acceptable:
1. Add a fixed offset comfortably clear of every other explicit z_index in
   the codebase (`fog_of_war.gd`'s hive-fog layer at 90, `main.gd`'s
   selection layer at 100) and any plausible real hive radius, e.g. `const
   CELL_Z_INDEX_OFFSET := 512` and `z_index = 2 * axial.y + axial.x +
   CELL_Z_INDEX_OFFSET` -- cheapest, one-line change, fixes both this and
   9g's identical paint-order candidate at once if that turns out to be the
   same mechanism.
2. Replace the z_index scheme with actual scene-tree ordering (`move_child`
   to keep cells sorted top-to-bottom as they're (re)built) -- more
   invasive, not needed unless option 1 is confirmed insufficient.

**Live confirmation needed before implementing:** inspect one
non-rendering above-centre cell's actual `z_index`, `visible`, and paint
order against the hive floor node in the remote scene inspector, confirming
the sign is genuinely negative and genuinely losing to an opaque node
above it, before picking option 1 over option 2 -- same discipline Slice
9g's own writeup already asks for.

**Cross-reference:** if this is confirmed, re-check Slice 9g
(`plans/now/challenge-1.md`) -- its "second manually-built cell never
renders" may be this same bug if that cell also happened to land above the
centre row, in which case one fix closes both.

