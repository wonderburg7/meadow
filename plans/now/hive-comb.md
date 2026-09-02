# Meadow hive comb — active slice

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 8 (cell highlight borders do not follow the sprite silhouette), Claude lane; Slices 4 and 5 still need Dave's live look | Dependency: none for Slice 8 | Verified: 2026-09-02

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

Slices 1-3, 6 and 7 are shipped and archived at
`plans/archive/HIVE_COMB_SLICES_1-3_6-7.md`. Dave's 2 Sep 2026 pass
confirmed their hands-on checks -- cell art, above-centre rows and wide-comb
routing all survive a save and load -- with one exception, which is Slice 8
below. Slices 4 and 5 still need Dave's live look before any code is
written, so neither appears in `NEXTSTEPS.md`.

## Slice 8 — Cell highlight borders do not follow the cell sprite's silhouette

**Symptom (Dave, 2 Sep 2026):** cell highlight borders do not match the
shape of the cell sprites.

**Diagnosed.** `hive_cell.gd` builds five outlines and only one of them
knows about the sprite. `_set_outline_points_cup()` raises hexagon points 4
and 5 by `EMPTY_TEXTURE_BASE_Y * empty_scale * EMPTY_SPRITE_SCALE_NUDGE` so
the ring traces the cup's raised back wall, and `_set_selection_ring_points()`
is the only caller — and only when `Session.use_cell_sprites` is on. The
base `outline` (`cell_size`), `designation_ring` (`cell_size - 3.0`),
`zone_halo` (`cell_size + 6.0`) and `zone_glow` (`cell_size + 4.0`) all still
go through the flat `_set_outline_points()`, so with cell art on they cut
straight through the back wall the sprite draws. Slice 1-3 fixed the ring
the check happened to name and left the other four.

**Fix.**

- a) Add `func _apply_outline_points(line: Line2D, size: float) -> void`
  next to the two existing helpers: it calls `_set_outline_points_cup` when
  `Session.use_cell_sprites` is true and `_set_outline_points` otherwise.
  Rewrite `_set_selection_ring_points()` to be one call to it, so there is
  one silhouette decision in the file rather than five.
- b) Route `outline`, `designation_ring`, `zone_halo` and `zone_glow`
  through `_apply_outline_points` at their build sites, keeping each one's
  existing size argument unchanged.
- c) The Cell art toggle must revert all five immediately, exactly as the
  selection ring already does. Find where `_set_selection_ring_points()` is
  re-called on a toggle/refresh and re-point the other four in the same
  place; if that is `_refresh()`, do it there.

**Do not** change `EMPTY_TEXTURE_BASE_Y`, `EMPTY_SPRITE_SCALE_NUDGE`,
`cell_size`, the fill polygon, or any ring's size argument — this slice
changes which silhouette a ring traces, nothing about where it sits.

**Acceptance:** with Cell art on, multi-select a cup, pin a cell to a
resource, and open the nursery window over the comb: all four rings follow
the cup's raised back wall rather than cutting through it, and none of them
overlap each other (their `+6.0`/`+4.0`/`+2.0`/`-3.0` spacing is preserved).
Turn Cell art off mid-run: all four immediately return to the flat hex
outline.

**Check:** `tools/verify.ps1`. One hands-on check to file: the acceptance
above, replacing the ring half of the archived Slices 1-3 entry.

**Files:** `scripts/hive_cell.gd`.

**Next after:** Slice 4 or 5, whichever Dave's next live look unblocks.

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
