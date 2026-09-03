# Meadow hive comb — auto-build order and cell feedback

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: None startable -- Slices 4 and 5 both need Dave's live look before code | Dependency: Slices 4 and 5 need Dave's live look | Verified: 2026-09-03

**Objective.** The comb reads correctly as it is built: cells grow in a
sensible order and a cell's art tells the player what is in it.

**State.** The rendering half is finished. Slices 1-3 and 6-9 are shipped and
archived (`plans/archive/HIVE_COMB_SLICES_1-3_6-7.md`,
`plans/archive/HIVE_COMB_SLICES_8-9_2026-09-03.md`); Slice 9's hands-on
check is C-9 in `checks/ready.md`. Dave's 30 Aug pass separately confirmed,
with no action needed: the Cell art toggle, column-run z-order, cells
holding a resource being unaffected by the toggle, sprite-aligned hex grid
geometry and traversal, direction-even hex speed, automine block selection
and typeface switching.

**Open slices.** Slices 4 and 5, below. **Neither is startable and neither
belongs in `NEXTSTEPS.md`.** Slice 4 has its mechanism already traced but
capping builders per site is a build-throughput change, so it needs Dave's
call on intended behaviour first; Slice 5 needs a live repro to say whether
there is a defect at all. They are independent of each other.

**Authoritative files.** Site selection: `scripts/hive.gd`
(`create_next_cell_site`, `find_unfinished_cell`). Builder dispatch:
`scripts/bee.gd` (`_idle_dispatch`). Cell art: `scripts/hive_cell.gd`.

**Required reading.** This file only, plus `.claude/rules/simulation.md` for
Slice 4 (it is a balance change). The archives are provenance, never
orientation.

**Reasoning level.** Slice 4: high -- it changes build throughput and touches
the idle-dispatch path. Slice 5: low once the live answer exists.

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
