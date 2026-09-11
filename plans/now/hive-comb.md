# Meadow hive comb — auto-build order and cell feedback

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: None startable -- Slice 4 needs Dave's call on intended build throughput, Slice 5 is now a one-line design question for him | Dependency: Slice 4 wants Dave's call on capping builders per site; Slice 5 wants his answer on the low-fill cell's look | Verified: 2026-09-11

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
belongs in `NEXTSTEPS.md`,** and in both cases what they want is one answer
from Dave rather than more investigation. Slice 4 has its mechanism traced,
but capping builders per site is a build-throughput change, so it needs his
call on intended behaviour. Slice 5 no longer needs the live repro it asked
for -- the 11 Sep 2026 plan review answered it from the code (below) and it
is now a design question with two options. They are independent of each
other.

**Authoritative files.** Site selection: `scripts/hive.gd`
(`create_next_cell_site`, `find_unfinished_cell`). Builder dispatch:
`scripts/bee.gd` (`_idle_dispatch`). Cell art: `scripts/hive_cell.gd`.

**Required reading.** This file only, plus `.claude/rules/simulation.md` for
Slice 4 (it is a balance change). The archives are provenance, never
orientation.

**Reasoning level.** Slice 4: high -- it changes build throughput and touches
the idle-dispatch path. Slice 5: low once Dave has chosen between the two
options under it.

## Slice 4 — Cell auto-building: every idle builder piles onto one site

**Symptom (Dave, 30 Aug, general play — distinct from the queen-specific
auto-spiral bug Challenge 1 Slice 8d already fixed, see
`plans/now/challenge-1.md`):** ordinary automatic Comb Worker building does
not appear to grow the comb in the expected spiralling-hexagon shape.

**Cause, confirmed by the 1 Sep headless trace.** `hive.gd::create_next_cell_site()`
walks `Shapes.hex_spiral_at(index)` in increasing index order and returns the
first tile passing `_can_build_on()`, so the spiral maths was never the
suspect and is not the fault. The reproduction is
`test_scenarios/hive_comb_spiral_repro.json`: four automatic Comb Workers, no
cells and no miners, a fully open seven-ring interior, stopping after 37
completed cells. Run it with
`./tools/run_headless.ps1 test_scenarios/hive_comb_spiral_repro.json`. The
second candidate cause considered at the time -- that `_can_build_on()` only
offers dug, walkable tiles, so uneven mining would make a correct spiral look
wrong -- is ruled out by that fixture, which pre-digs the whole interior and
still reproduces the symptom.

**What the trace showed (1 Sep, `run_id=b8cf41b4dc6c`, all 37 cells
completed, `queen_alive`/`actions_clean` both passed).** Of 148 `assigned`
`build_target` events, 51 land on a `target_hex` that one or more other bees
were assigned in the very same tick. Tracing the first one: all four workers
get `target_hex=[0,0]` at `game_time=0.025`; all four `claimed` and
`completed` it together at `game_time≈2.6`; then all four get
`target_hex=[0,-1]` together next, and so on for the whole run. The comb
never grows at more than one site at a time — the four Comb Workers act as
a single herd walking the spiral tile-by-tile, rather than each opening its
own site and the ring filling in from several points in parallel.

Mechanism, read from `bee.gd::_idle_dispatch` (`:1398`) and
`hive.gd::find_unfinished_cell` (`:553`): before calling `create_next_cell_site()`, an idle
Comb Worker first calls `hive.find_unfinished_cell()`, which returns the
first cell in `cells` with `is_built == false` — uncapped, so every idle
worker piles onto the single most recent unfinished site instead of a new
one opening once that site already has a builder. `find_unfinished_cell()`
is also what lets a worker resume a site abandoned mid-build (e.g. after a
death), which is correct; the bug is that it has no limit on how many
workers can queue onto the same site while other ring positions sit
untouched.

**The one thing this slice waits on is Dave's answer, not more evidence.**
Capping concurrent builders per site would make the comb visibly grow at
several points at once, and would also change how fast the colony builds
overall -- a balance question, not a visual one
(`.claude/rules/simulation.md`). Three readings are available and the fix is
different for each: **one builder per site** (the comb opens a new site as
soon as the current one is claimed, fastest-looking, slowest per cell when
workers are few); **a cap of two or three** (a compromise, and the cap
becomes a `GameConfig` value); or **leave it** (the herd is how the comb
builds, and the symptom is a presentation expectation rather than a defect).
Whichever he picks, the slice that follows simulates the change before it
ships, per this plan's own rule.

## Slice 5 — Cell-content feedback lag reading as "nothing happened" (design question, not confirmed a bug)

**Symptom (Dave, 30 Aug):** with Cell art on, a forager appears to be
contributing to a cell but the cell's look doesn't change until later.

**Likely explanation:** `empty_sprite` only shows while `content_type == ""`;
the moment any resource lands, the cell switches to its ordinary
fill-fraction shading (a washed-out body plus a full-strength `fill_shape`
scaled to the amount held) — which starts very pale at a low fill fraction
and is easy to miss next to the visually richer cup sprite it just replaced.
That is a legibility gap, not a functional one.

**Confirmed from the code, 11 Sep 2026 plan review — there is no lag, and no
live repro is needed.** `hive_cell.gd::add_resource` sets
`content_type = resource_type` synchronously on the deposit itself (`:731`),
before it returns, so the cell stops being empty the instant the forager
delivers. The only thing between that and the screen is the presentation
gate at `:497-514`, which redraws at `REFRESHES_PER_SECOND` 6 with a
0.85-1.15 jitter -- at worst about 190 ms, far too fast to read as "nothing
happened". The plan's own legibility explanation is therefore the whole
story: what changes is instant, it is just faint.

**What is left is one question for Dave, not a slice.** Should a cell holding
a little of something keep a lighter version of the cup outline, instead of
jumping straight to the current pale flat wash? Yes makes a first deposit
legible at a glance and costs one drawing change in `hive_cell.gd`. No leaves
the comb reading purely by fill, which is what it does today. Nothing else in
this plan depends on the answer; it becomes a slice the moment there is one.
