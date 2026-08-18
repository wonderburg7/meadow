# New features — technical blueprint (14 Aug 2026)

**Archived 19 Aug 2026 — shipped.** Kept as a record of the design. See
`docs/history.md` for what actually landed.

Architecture and data-flow only, for a lighter model to implement from.
No full scripts here — file/function references, the shape of each
change, and the risks worth knowing about before starting. Grounded in
a read of the actual current scripts (`shapes.gd`, `hive.gd`,
`hive_cell.gd`, `world_building.gd`, `bee.gd`, `bee_building.gd`,
`bee_survival.gd`, `season.gd`, `year_winter.gd`, `input_selection.gd`,
`hud.gd`, `debug_panel.gd`, `main.gd`, `save_game.gd`, `saving.gd`,
`roles.gd`, `game_config.gd`), not from the design docs alone.

**Terminology note**: the request calls the builder role "Cell workers".
In the codebase and on-screen labels this is the **Comb worker** role
(`Bee.Role.BUILDER`, `Roles.COMB_WORKER`). Treat the two as the same
thing throughout.

**Suggested build order**, independent items first, geometry last:
1. Nectar/pollen colours (5) — trivial, good warm-up.
2. Build-here hover border (6) — isolated, no new state.
3. Work-from-here scoping + its visual marker (3, then 4) — sequential,
   4 depends on 3's data already existing (it does).
4. Winter energy + lifespan (7) — isolated balance change, needs a
   simulation pass before shipping the numbers.
5. Hexagon reorientation + entrance redesign (1, then 2) — do last,
   in one slice. Biggest blast radius, and item 2 only makes sense once
   item 1 is in.

---

## 1 & 2. Flat-top hexagons + corner entrance with a single-file tunnel

These are one geometry change, not two, and the codebase is unusually
well set up for it: every hex→pixel and pixel→hex conversion already
goes through `shapes.gd`, and nothing else hand-rolls that maths. Fix
`shapes.gd` correctly and the rest of the hive (comb, floor tiles,
navigation, path smoothing, mining, the selection-order overlays)
should not need touching at all.

### The core change: `shapes.gd`

Hex grids come in two orientations — "pointy-top" (a point at 12
o'clock) and "flat-top" (a flat edge at 12 o'clock, which is what
gives a flat top *and* bottom edge on each cell). The project is
currently pointy-top throughout. Three functions carry the
orientation and need to change together; everything else is written
in terms of them:

- `hexagon_points(size)` — corner angle offset moves from `-30°` to
  `0°` (corners at 0°, 60°, 120°… instead of -30°, 30°, 90°…). This
  alone gives every hex — comb cells, floor tiles, the outline/
  selection/zone rings, the build/mine/keep-clear overlays drawn in
  `input_selection.gd` — its flat top and bottom, since they all call
  this one function.
- `hex_to_pixel(q, r, size)` — the flat-top formula is
  `x = size * 1.5 * q`, `y = size * sqrt(3) * (r + q / 2.0)` (currently
  the pointy-top form, `x = size*sqrt(3)*(q+r/2)`, `y = size*1.5*r`).
- `pixel_to_hex(point, size)` — the inverse flips the same way:
  `qf = (2.0/3.0 * x) / size`, `rf = (-1.0/3.0 * x + sqrt(3.0)/3.0 * y) / size`,
  then round in cube space exactly as now — `_axial_round` itself is
  orientation-independent and needs no change.

**What does *not* need to change**, and why: `hex_ring`, `hex_spiral`,
`hex_distance`, the `NEIGHBOUR_STEPS`/`directions` arrays repeated in
`hive.gd` and `world_building.gd`, and `hexagon_edge_midpoints` are all
defined purely in axial or cube coordinate space. The six neighbour
directions of an axial hex are the same regardless of which way the
hex is drawn on screen — only the *projection* to pixels differs. So
comb growth (`hex_spiral`), ring digging (`hex_ring`), pathfinding
(`hive.gd::build_navigation`, `path_between`), mining neighbour checks
(`mine_stand_hex`), and the six wall-slots a bee stands at
(`hexagon_edge_midpoints`, used by `hive_cell.gd::slot_position`) all
carry over unchanged — they'll just rotate 30° along with everything
else, which is invisible because it's consistent.

Practical implication for the implementer: **grep for any hand-rolled
`sqrt(3)` / `* 1.5` hex maths outside `shapes.gd` before touching
anything else** — `world_building.gd::hive_entrance_inside()` is one
(see below), and it's worth checking `rival_hive.gd` too, since it
wasn't read for this blueprint. Anywhere that duplicates the pointy-top
formula instead of calling `Shapes.hex_to_pixel` is a second place
this change has to land, and a likely source of a "it works everywhere
except this one panel" bug.

### The entrance: corner, top, single-file tunnel

`world_building.gd::_dig_out_chamber` digs the hive as a stack of
`hex_ring()` shells — interior floor, then soil rings, then bedrock
rings — which makes the overall dug-out shape itself a big hexagon.
That big hexagon has six corners, at axial `(R,0)`, `(0,R)`, `(-R,R)`,
`(-R,0)`, `(0,-R)`, `(R,-R)` for outer ring index `R`. Once
`hex_to_pixel` is flat-top, working out the pixel `y` of each corner
shows `(0, -R)` is the unique topmost one (screen y is most negative
there) — no tie-breaking needed, it falls out of the geometry.

That corner is also the natural tunnel: every hex along `q = 0`, from
the surface down to the interior, has pixel `x = 0` — a perfectly
straight vertical line, one tile wide, because stepping from `(0,-r)`
to `(0,-(r-1))` is a single axial neighbour step. That directly
replaces the current mechanism, which is why today's tunnel comes out
"1, 2, 1, 2": `_entrance_tiles()` currently keeps any hex in each ring
whose *pixel x* falls within `hive_entrance_width * spacing` of centre
— and under pointy-top projection, rings alternate how many hexes
satisfy that near `x=0`, which is exactly the wobble described.

Proposed replacement, in `world_building.gd::_entrance_tiles`: instead
of a pixel-distance test, walk the fixed column directly —
`Vector2i(0, -ring)` for `ring` in the same range the function already
loops over (`interior_rings - 1` through the passed-in combined
soil+rock depth — the call site in `_dig_out_chamber` already passes
`soil_depth + rock_rings` together, so no change needed there). This
drops the pixel-distance test and the `hive_entrance_width` tunable
entirely from this function.

`hive_entrance_inside()` currently hand-derives the entrance world
position as `Vector2(0, -rings * spacing * 1.5)` — that literal `1.5`
is the pointy-top vertical step and would silently be wrong under the
new projection if left as-is. Replace it with
`Shapes.hex_to_pixel(0, -rings, spacing)` — same corner hex the tunnel
now walks to, computed the one way the rest of the file already trusts.
This is the general fix mentioned above: anywhere a position is
derived from an axial coordinate should go through `hex_to_pixel`,
never hand-rolled, so a future geometry change doesn't have to go
hunting for this a second time.

**Open decision for Dave**: `hive_entrance_width` (currently "tiles
left out of the soil for the doorway") becomes unused by the new
`_entrance_tiles`. Options: drop the tunable outright (simplest, and
matches "single row" being the whole point), or keep it and repurpose
it later for a wider doorway (e.g. also carving `q = 1`/`q = -1`
alongside `q = 0`) — worth a quick multiple-choice check-in with Dave
rather than guessing, since it's currently a saved/tunable setting
(`save_game.gd::SAVED_SETTINGS`).

### Risk: existing saves and the entrance

This is worth flagging clearly rather than discovering it in
playtesting. `saving.gd::_restore` runs **after** the world (including
`_build_hive_interior`) is already built fresh under whatever geometry
is current — the load path only removes soil the save says was mined
(`_restore_soil`), it never adds soil back, and `_restore_cells`
re-creates the save's comb cells at their saved axial coordinates via
`main.hive.register_tile(hex, cell)` **unconditionally**, with no check
for what's already occupying that tile.

Concretely: a save made under the old (pointy-top, off-centre-bottom
entrance) layout will, on load under the new geometry, get a freshly
dug chamber whose open/soil pattern near the old entrance no longer
matches where the save's comb cells actually are. Any saved cell that
now lands on a hex the fresh dig considered soil will silently
overwrite that tile's entry in `occupied_tiles` — the soil block's
node is never freed, so it's still parented under `hive_root` and
still drawn, just no longer tracked as occupying that tile. Net
effect: a leftover, doubled-up visual (soil block rendered under/over
a comb cell) rather than a crash, but a real correctness bug, and one
that's specific to this change (it's not present today because the
dig pattern hasn't moved before).

Two ways to handle it, worth putting to Dave rather than picking
silently:
- **Simple**: treat this as a save-breaking change — bump
  `SaveGame.FORMAT_VERSION` and let `has_save()`/`read()` refuse an
  old-version file with a clear message, rather than partially loading
  it. Matches how Dave actually plays (mostly fresh runs per the
  README/state-of-play notes).
- **Robust**: make `_restore_cells` (and the equivalent soil/rock
  restore path) explicitly `queue_free()` and erase whatever currently
  occupies a hex before registering the loaded node there. More work,
  but protects against *any* future geometry tweak, not just this one.

---

## 3. "Work from here" — scope to one bee, add an explicit all-workers button

### Current behaviour

`home_hex`/`has_home_hex` already exist per-bee on `bee.gd`
(`set_home_hex`, read by `create_next_cell_site` as the spiral's
starting point), and the UI already follows the project's established
"click the button, then click a tile" placement-mode pattern used for
five other orders (Build here, Mine, Keep clear, Work from here for
miners, Start here). The bug is scope: `hud.gd`'s "Work from here"
button (in `_build_orders_row`, Comb worker branch) fires
`home_cell_requested`, which `input_selection.gd::_on_home_cell_requested`
handles by snapshotting **every currently selected Comb worker** into
`main.pending_home_bees` — so if several Comb workers are box-selected
when the button is pressed, the next tile click sets all of their home
cells at once, not just the one bee whose panel you're looking at.

### The fix

Follow the same placement-mode idiom, narrowed:

- `input_selection.gd::_on_home_cell_requested` — change the filter
  from "every selected Comb worker" to just the first bee in the
  selection (`main.selected_bees[0]`, guarded for validity and role).
  `_place_home_cell` doesn't need to change at all; it already loops
  over whatever's in `pending_home_bees`, which will now just hold at
  most one bee.
- Add a genuinely separate, explicit **colony-wide** path rather than
  overloading the existing one:
  - New signal on `hud.gd`, `home_cell_all_requested()`, wired in
    `main.gd` next to the existing `home_cell_requested` connection.
  - New button in the same row in `hud.gd::_build_orders_row`, "Set for
    all Comb workers" — tooltip should say plainly that it affects
    every Comb worker in the colony, not just the selection, matching
    the existing "Keep clear" button's tooltip pattern of calling out
    a colony-wide effect explicitly.
  - New state on `main.gd`, `awaiting_home_cell_all: bool`, and a
    branch in `input_selection.gd::_finish_drag` alongside the existing
    `awaiting_home_cell` one.
  - New handler, `_place_home_cell_all`, resolves the clicked hex the
    same way `_place_home_cell` does, then loops **every bee in the
    `"bees"` group with `role == Bee.Role.BUILDER`** (not the
    selection) and calls `set_home_hex` on each. No snapshot/pending
    array needed here — "all Comb workers" is unambiguous at the
    moment of the click, unlike a selection which could have changed.

This is a pure narrow-then-add change: nothing about `bee.gd`'s
`home_hex` data or `create_next_cell_site`'s use of it needs to move.

---

## 4. Visual marker for a selected bee's home cell

### Where it plugs in

`input_selection.gd::_draw_hive_orders()` already runs every frame
while in hive view (via `selection_layer`'s `draw` signal, redrawn
unconditionally each frame by `main.gd::_process`), and already draws
one thing per selected bee depending on role — build/mine queues via
`_draw_order_chain`, and colony-wide keep-clear tiles. Add a third
case: for each selected bee with `role == BUILDER` and `has_home_hex`,
draw a marker at that hex's world position.

### What to draw

Two existing helpers cover this without inventing a new drawing
primitive:
- `_draw_tile_outline(centre, colour, width, dashed)` — already used
  for build/mine/keep-clear tiles. Reusing it for the home marker
  would read as "just another queued tile", which underplays what it
  actually means.
- `_draw_start_point_marker(point)` — used today for a forager's
  meadow "start here" point: a soft filled circle plus a ring plus a
  crosshair. This reads as "this is *the* reference point", which is
  the right semantic for a home cell too. Recommend adapting this
  style (circle + crosshair, at the cell's world position, sized to
  sit clearly inside/around the hex) rather than the plain hex
  outline, so a home cell is visually distinct from a queued build
  order at a glance.

Add a new colour constant alongside the existing
`BUILD_ORDER_COLOUR` / `MINE_ORDER_COLOUR` / `KEEP_CLEAR_COLOUR` block
in `main.gd` (e.g. `HOME_CELL_COLOUR`), so the marker has its own
identity rather than borrowing `BUILD_ORDER_COLOUR`.

### Open question for Dave

Miners have the identical data shape already (`mine_home_hex`/
`has_mine_home`, set via the miner's own "Work from here" button) but
the request only mentions Comb workers explicitly. Recommend giving
miners the same marker for consistency (near-zero extra cost, same
draw call with the miner's fields), but worth a quick confirm rather
than assuming — a "yes, same for miners" / "no, comb workers only"
multiple-choice would settle it in one round.

---

## 5. Nectar/pollen stored-resource colours

### Current state and an important rendering detail

`hive_cell.gd` defines `NECTAR_COLOR := Color(0.95, 0.7, 0.15)` (amber)
and `POLLEN_COLOR := Color(0.4, 0.35, 0.8)` (purple-blue), used in
three places in that file: the plain fill (`_refresh`'s `match
content_type`), the "contents" overlay, and the "reserved" overlay tag
colours. Changing the two constants alone updates all three call
sites — no other edit needed inside `hive_cell.gd`.

Worth knowing before picking exact values: `_apply_fill_shading`
already blends the cell's *outer* body colour toward `EMPTY_COLOR`
(the tan/wax colour) at a fixed 0.35 mix, so the "sitting in a yellow
wax container" effect the request describes is already partly
happening automatically for any content colour — that blend is what
makes a half-full cell read as lighter than a full one. The *fill
shape* (the part that scales with how full the cell is) uses the raw
constant at full strength, though, so that's the part that actually
needs the colour change to land correctly.

Proposed direction (exact values are a look-and-feel call for Dave,
not an architecture one):
- **Pollen** → close to the *current* nectar colour, nudged lighter
  and slightly more yellow — e.g. starting from `(0.95, 0.7, 0.15)`
  and raising both brightness and green a touch, something like
  `(0.97, 0.78, 0.22)`.
- **Nectar** → pale blue with a little yellow mixed in, e.g. a pale
  blue base like `(0.75, 0.85, 0.95)` blended a small amount (~10–15%)
  toward a yellow like `(0.9, 0.8, 0.3)`, rather than a single
  hand-picked literal — defining it as a named pale-blue constant
  `lerp`'d toward a named yellow constant keeps the intent readable in
  the source and easy for Dave to nudge by eye later without redoing
  the maths.

### A pre-existing duplication, worth a one-line flag (not in scope here)

Nectar/pollen colours are independently defined in **four** places
that already drift slightly from each other: `hive_cell.gd`
(`NECTAR_COLOR`/`POLLEN_COLOR`, the cell fill), `roles.gd`
(`FORAGER_FOCUS_COLOURS`, the role-badge colour), `colony_panel.gd`
(a hand-copied legend matching `roles.gd`'s values), and `bee.gd`
(the small dot shown on a bee carrying a load — which, incidentally,
*already* uses pale blue for a nectar-carrying bee and warm yellow for
pollen, i.e. the carried-load visual already speaks the language this
request wants for the stored version). These serve different purposes
(role badge vs. stored resource vs. carried load) so merging them
isn't obviously correct, but it's worth naming as a separate,
optional cleanup — not something to fold into this ticket, since it
would widen the change well past "recolour two constants".

---

## 6. Hover border on clear hexes while placing "Build here"

### Why this is a small change

`main.gd::awaiting_build_cell` already stays `true` for the whole
"Build here" session, including through Ctrl-click queueing
(`input_selection.gd::_place_build_cell`'s `keep_adding` branch
returns without clearing it) — so a hover indicator wired to that flag
automatically covers the entire queueing session, not just the first
click, with no extra state to track.

Better still: `main.gd::_process` already calls
`selection_layer.queue_redraw()` unconditionally every frame, and
`input_selection.gd::_draw_selection_box` is the callback that runs on
that redraw. That means the hover tile doesn't need its own
mouse-motion tracking or cached state at all — it can simply be
computed fresh at draw time from the current mouse position, the same
way `_draw_hive_orders` already reads `main.selected_bees` fresh each
call.

### The change

In `_draw_selection_box` (or a new helper called from it), when
`main.awaiting_build_cell and main.in_hive_view`:
- Resolve the hex under the cursor the same way `_place_build_cell`
  does today — `_hex_at(main.get_global_mouse_position())` (already a
  private helper in this file).
- Check `main.hive.can_build_on(hex)` (already exists on `hive.gd`,
  already the exact test `create_cell_site_at` uses to accept or
  reject a placement) to decide whether to draw at all, or to draw in
  a different colour for "not buildable" — worth confirming with Dave
  which reading of "any clear space hexagons that the mouse hovers
  over" is intended: only highlight when the tile *is* buildable
  (matches the literal wording), versus always highlighting the
  hovered tile with buildable/not-buildable as two colours (more
  information, slightly busier).
- Draw with the existing `_draw_tile_outline(centre, colour, width,
  dashed)` helper — no new drawing primitive needed, just a new call
  site and (recommended) a new colour constant alongside
  `BUILD_ORDER_COLOUR` so the live hover reads as distinct from the
  already-queued tiles it sits among.

This mechanism generalises for free: the same pattern (check an
`awaiting_*` flag, resolve the hex at draw time, outline it) would
cover the other five placement modes later if Dave wants hover
feedback on those too — not asked for here, but worth knowing it's a
one-line-per-mode extension, not a new subsystem each time.

---

## 7. Winter energy needs and bee longevity

### What's already there, and what's actually missing

This one is smaller than it looks, because `GameConfig.winter_burn_factor`
(`0.15`) **already exists** — but it is currently only read in the
*forecast* shown to the player (`year_winter.gd::_winter_forecast`,
which is what the top-right winter readout is built from). It is
**never applied to the live simulation**: `bee_survival.gd::age_and_burn`
burns every bee at the full, unmodified `GameConfig.energy_burn_rate`
(and `flight_energy_burn`) regardless of season. So today, a colony
that meets the forecast's stated requirement can still starve for
real once winter arrives, because actual consumption is roughly
6–7× what the forecast promised. That's a pre-existing correctness
bug this feature request happens to expose, not a new decision to
design from scratch — the fix is largely "make the simulation honour
the number the forecast already assumes".

There is genuinely nothing today for the lifespan side: bees age and
die at the ordinary `bee_lifespan_days` rate straight through winter,
unaffected by season. The forecast's own maths already *implicitly*
assumes a static population across the whole winter — it takes one
`bees` count at the moment winter starts and never adjusts it — so
adding a real lifespan extension doesn't just satisfy the request, it
also makes the simulation match an assumption the forecast is already
silently making.

### Where each half belongs

Follow the same shape disease pressure already uses — a single
multiplier read from one place, not a parallel mechanism:

- **Burn rate** lives in `bee_survival.gd`, where burn already lives.
  In `age_and_burn`, multiply `upkeep` (and, for correctness/symmetry
  against a bee that's still outside right as winter starts, `flight`)
  by `GameConfig.winter_burn_factor` when `Session.winter_here` is
  true — `Session.winter_here` is already read directly from bee code
  elsewhere (`bee.gd` checks it for the foraging-stopped rule), so
  this needs no new plumbing through `world`.
- **Lifespan** lives in `season.gd`, where the equivalent disease logic
  (`lifespan_factor()`) already lives, and which `bee_survival.gd`
  already calls into (`lifespan_seconds()` multiplies by
  `bee.world.season.lifespan_factor()`). Fold a new
  `GameConfig.winter_lifespan_factor` into that same function — e.g.
  the existing `1.0 - _severity() * GameConfig.disease_lifespan_penalty`
  result, further multiplied by `winter_lifespan_factor` when
  `Session.winter_here` — rather than adding a second, separate check
  in `bee_survival.gd`. One function keeps answering "how much
  longer/shorter does a bee live right now"; `bee_survival.gd` doesn't
  need to change for this half at all.

Because `lifespan_seconds()` is evaluated live every frame rather than
cached at spawn, this takes effect immediately for every bee the
moment winter starts (including one already close to its normal
lifespan) and relaxes back the moment winter ends — no snapshot logic
needed either way.

### A consequence worth stating explicitly

Once real burn during winter is actually reduced by
`winter_burn_factor`, `year_winter.gd::_winter_forecast()` needs **no
change at all** — it already multiplies by that same factor, so
forecast and reality become consistent as a side effect of fixing the
simulation side, not a separate edit.

### Before shipping the numbers

Per this project's own rule ("never trust a balance number that
hasn't been simulated" — `CLAUDE.md`, and this exact system, winter
storage, is named there as a system that has shipped broken before):
`winter_lifespan_factor` needs a value chosen by simulation, not
guessed. Worth a short throwaway Python model (same pattern as
`tests/balance_tests.py`) checking two things together: that a
plausible pre-winter honey/nectar store covers
`bees_at_winter_start * energy_burn_rate * winter_burn_factor *
winter_length_days * seconds_per_day`, and that the chosen
`winter_lifespan_factor` is large enough that close to zero bees die
of old age during a winter for a colony with a realistic age spread —
otherwise the forecast's "population stays static" assumption quietly
breaks again, just from the other direction. Once a value is settled,
it's a good candidate to add as a permanent assertion in
`tests/balance_tests.py` rather than only ever being checked once by
hand.

### Housekeeping

- `debug_panel.gd` needs a new tuning row for `winter_lifespan_factor`
  in the existing "Winter" category, alongside the existing "Winter
  burn x" row.
- Neither `winter_burn_factor` nor (the new) `winter_lifespan_factor`
  are currently in `save_game.gd::SAVED_SETTINGS` — `winter_length_days`
  and `winter_countdown_days` are, but the burn factor was apparently
  missed when it was added. Worth adding both while touching this area,
  flagged here as adjacent cleanup rather than something the request
  asked for directly.

---

## Summary of files touched, by feature

| Feature | Files |
|---|---|
| 1. Flat-top hexagons | `shapes.gd` (core), spot-check for hand-rolled hex maths elsewhere (`rival_hive.gd` unverified) |
| 2. Corner entrance, single-file tunnel | `world_building.gd` (`_entrance_tiles`, `hive_entrance_inside`), `save_game.gd` (decide `hive_entrance_width`'s fate), optionally `save_game.gd` `FORMAT_VERSION` |
| 3. Work-from-here scoping | `input_selection.gd`, `hud.gd`, `main.gd` |
| 4. Home-cell marker | `input_selection.gd`, `main.gd` (new colour constant) |
| 5. Nectar/pollen colours | `hive_cell.gd` |
| 6. Build-here hover | `input_selection.gd`, `main.gd` (new colour constant) |
| 7. Winter energy/lifespan | `bee_survival.gd`, `season.gd`, `debug_panel.gd`, `save_game.gd`, `tests/balance_tests.py` |

Items 1–2 are the only ones that touch shared geometry; everything
else is additive and low-risk in isolation. Recommend running
`python3 tests/source_checks.py` and `python3 tests/balance_tests.py`
after each slice, per the usual workflow, and treating the hex
reorientation as its own commit separate from the entrance change so
a problem in one is easy to bisect from the other.
