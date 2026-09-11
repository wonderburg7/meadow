# Meadow hive comb — auto-build order and cell feedback

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 5 -- a cell's outline takes the colour of what is in it | Dependency: none -- Dave answered both open questions on 11 Sep 2026 and Slices 4 and 5 are independent of each other | Verified: 2026-09-11

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

**Open slices.** Slices 4 and 5, below. **Both are startable.** Dave answered
the two questions they were waiting on, on 11 Sep 2026:

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| 4 | At most six builders per site, one to a wall | `hive.gd`, `bee_building.gd`, `hive_cell.gd` | yes | medium |
| 5 | A cell's outline takes the colour of what is in it | `hive_cell.gd` | yes | low |

They share `hive_cell.gd` but touch different parts of it -- Slice 4 the
working-positions block, Slice 5 the refresh's outline colour -- so they are
independent in substance, and whichever runs first the other rebases cleanly.
Run Slice 5 first: it is the smaller, and it is the one Dave will see.

**Authoritative files.** Site selection: `scripts/hive.gd`
(`create_next_cell_site`, `find_unfinished_cell`). Builder dispatch:
`scripts/bee.gd` (`_idle_dispatch`). Cell art: `scripts/hive_cell.gd`.

**Required reading.** This file only, plus `.claude/rules/simulation.md` for
Slice 4 (it is a balance change). The archives are provenance, never
orientation.

**Reasoning level.** Slice 4: medium -- it changes build throughput, but the
mechanism it uses already exists and the rule is now stated rather than
designed. Slice 5: low.

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

**Dave's answer, 11 Sep 2026.** "Comb workers should be capped at 6, one for
each side of the hexagonal cell, with each working from one of the sides."

**The mechanism already exists, and `bee_building.gd` says so in a comment.**
`hive_cell.gd::claim_slot(bee)` hands out one of six wall positions and
returns `-1` when all six are taken; `release_slot` gives one back;
`slot_position(index)` is the midpoint of that wall, nudged outside the
hexagon. `bee_building.gd::builder_go_to_site` deliberately does *not* use
it, and its comment (`:31-35`) explains why: "reusing the slot system here
would add a cap on simultaneous builders that never existed before." That cap
is now the intended behaviour, so the comment is the thing that changes along
with the code.

**Current owner.** `hive_cell.gd` owns the six wall slots and the builder
list. `hive.gd::find_unfinished_cell` owns which site an idle worker is sent
to. `bee_building.gd` owns where a builder stands.

**Required reading.** This heading. `hive_cell.gd`'s "working positions" and
"building" sections. `bee_building.gd::builder_go_to_site` and
`builder_build`. `hive.gd::find_unfinished_cell`.
`.claude/rules/simulation.md`, because this is a balance change.

**Files likely to change.** `scripts/hive.gd`, `scripts/bee_building.gd`,
`scripts/hive_cell.gd`.

**Files that must not be changed.** `scripts/bee.gd`'s `_idle_dispatch`
ordering -- a worker still looks for an unfinished cell before opening a new
site, and only which cell it is offered changes. `scripts/game_config.gd`:
six is the number of walls a hexagon has, not a tunable.

**Requirements.**

1. A builder claims a wall with `claim_slot` when it takes a site and stands
   at that wall's `slot_position`, instead of every builder standing at wall
   0. It releases the slot on every path that today releases the builder,
   including the no-route and target-invalid exits.
2. `find_unfinished_cell()` skips a cell whose six wall slots are all taken,
   so a seventh idle worker opens a new site rather than queueing. It still
   returns a site with a free wall, which is what keeps a part-built cell
   abandoned by a death resumable.
3. The slot a builder holds is stable for the whole trip. Do not recompute a
   nearest wall per frame -- the existing comment says why wall 0 was
   hardcoded, and the wavering it describes is the same either way.
4. Update `builder_go_to_site`'s comment: the cap it says never existed is
   now the rule, and the next reader should find the decision rather than the
   old reasoning.

**Constraints and invariants.** `add_build_progress` is called once per
builder per frame, so six builders still finish a cell six times faster than
one -- the cap bounds a site's speed, it does not slow one that was within it.
`slot_users` is also used by deposit and feed queues; a builder and a
depositor must not be given the same wall, which `claim_slot` already
guarantees since it is one shared array. Check that a builder holding a wall
does not starve a forager trying to deposit into the same cell -- a site is
unbuilt, so nothing can be deposited there yet, but say so in a comment rather
than leaving it to be rediscovered.

**What this will and will not fix.** It bounds the pile-up and it makes six
workers on one cell read as six bees at six walls rather than a heap. **It
will not change the growth order with six or fewer comb workers**, and the
1 Sep trace's four workers are inside the cap, so that fixture will still show
all four on one site. If the comb still does not read as a spiral afterwards,
the remaining cause is not the pile-up and this plan should say so rather than
raising the cap.

**Simulate before shipping.** Re-run
`test_scenarios/hive_comb_spiral_repro.json` unchanged, and a second copy of
it with ten comb workers instead of four. Report, for each and before and
after: total `cells_completed`, the game time to 37 cells, and how many
distinct `target_hex` values are open at once. The change is acceptable if the
four-worker run's completion time is unchanged and the ten-worker run opens at
least two sites at once where today it opens one.

**Acceptance (what Dave does and sees).** With more than six Comb Workers
idle, the comb grows at more than one place at once, and no cell ever has more
than six bees on it. With six or fewer, each stands at a different wall
instead of all at the same one.

**Check to file:** one check for the above.

## Slice 5 — a cell's outline takes the colour of what is in it

**Symptom (Dave, 30 Aug).** With Cell art on, a forager appears to be
contributing to a cell but the cell's look doesn't change until later.

**Cause, confirmed from the code 11 Sep 2026 -- there is no lag.**
`hive_cell.gd::add_resource` sets `content_type = resource_type`
synchronously on the deposit (`:731`), and the presentation gate (`:497-514`)
redraws at `REFRESHES_PER_SECOND` 6 with a 0.85-1.15 jitter, so at worst about
190 ms. `outline.visible = content_type != ""` already turns the outline on
for any amount at all. What is missing is not timing and not the outline: it
is that the outline is one brown, `Color(0.35, 0.28, 0.12)`, whatever the cell
holds, so a first deposit changes a pale fill nobody notices and nothing else.

**Dave's answer, 11 Sep 2026.** "Cells with any amount of a particular
resource should use the outline of that resource."

**Current owner.** `hive_cell.gd`'s refresh owns both the outline's colour and
the designation ring's, and the ring already carries the per-resource palette
this slice needs: nectar `(1.0, 0.85, 0.3)`, pollen `(0.7, 0.65, 1.0)`, honey
`(1.0, 0.55, 0.1)`, brood `(0.6, 1.0, 0.7)`, written as an if-chain a few
lines below the outline.

**Required reading.** This heading, and `hive_cell.gd`'s refresh from the
`polygon = Shapes.hexagon_points(cell_size, squashed)` line down past the
`designation_ring.default_color` chain.

**Files likely to change.** `scripts/hive_cell.gd`.

**Files that must not be changed.** `scripts/resources.gd` -- see the note on
the catalogue below. `scripts/ui_theme.gd`.

**Requirements.**

1. A built cell holding any amount of a resource draws its outline in that
   resource's colour rather than the shared brown. An empty cell is unchanged:
   no outline at all, which is what keeps open comb and open floor reading as
   one surface.
2. The outline and the designation ring read one colour lookup, not two. Hoist
   the existing if-chain into a single function on `hive_cell.gd` that maps a
   content key to a colour, and have both call it. The ring may keep a
   different alpha or width; only the hue is shared.
3. A content kind with no colour of its own -- corpse, jelly if it has none --
   falls back to today's brown rather than to nothing, so a kind added later
   cannot make an outline disappear.

**Constraints and invariants.** An unfinished site keeps its own outline
treatment (`_set_outline_points` at the drawn size, `Color(0.6, 0.5, 0.25,
0.9)`); this slice does not touch that branch. The cup-versus-flat choice
stays with `Session.use_cell_sprites` and guardrail 10's measured constants --
`_apply_outline_points` decides the *shape* and this slice only sets the
*colour*. Nothing about what a cell holds changes.

**Note for the architecture review's B1.** The colour lookup this slice
hoists is the same fact B1 puts in the resource catalogue, for all seven
content kinds rather than four. Write it as one function with a comment saying
B1 is its future home, so B1 moves it rather than discovering a second
definition. Do not extend `resources.gd` here: that file is B1's, and B1 is
held behind Challenge 1.

**Runtime policy.** Unchanged. The colour is set inside the existing 6 Hz
refresh, and the lookup is a dictionary read.

**Acceptance (what Dave does and sees).** A forager deposits into an empty
cell and the cell immediately gains an outline in that resource's colour, so
the first deposit is visible at a glance. A nectar cell and a pollen cell are
told apart by their outlines. An empty cell still has none.

**Check to file:** one check for the above.
