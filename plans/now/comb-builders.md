# Comb builders — at most six to a site, one to a wall

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: CB-1 -- measure where comb builders stand and how many work one site | Dependency: none | Verified: 2026-09-17

**Objective.** When idle comb workers build on their own, no more than six
work one unfinished cell, each stands at a different wall, and a seventh
starts a second site.

**State.** HCB-4 set out to do exactly this. It merged on 12 Sep 2026 in
`3d475c7`, and its plan is archived at `plans/archive/HIVE_COMB_2026-09-12.md`,
which is never reopened. C-46 failed in Dave's 12 Sep 2026 pass: "the comb
workers do not position themselves around the six walls" and "more than 6 comb
workers contribute to building a single cell". This is the second visible
failure of builder placement, so the first slice builds the instrument rather
than guessing at a fix (`CLAUDE.md`, "Working style").

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| CB-1 | A headless run reports, per unfinished cell, how many bees build it and where they stand | `scripts/scenario_actions.gd` (or the summary writer it names), a new fixture | yes | medium |
| CB-2 | The fix CB-1's numbers point to; C-46 passes | decided by CB-1 | no -- its cause is not yet known, and its files wait on G2 | decided by CB-1 |

CB-2 depends on CB-1, and also on the Codex lane's **G2**
(`plans/design/architecture-review.md`), which is rewriting `bee.gd`'s
dispatch and touches the `bee_*.gd` modules CB-2's fix would edit. Neither
slice changes balance values.

## CB-1 — measure where comb builders stand and how many work one site

**Purpose.** Replace "it looked like more than six" with numbers, so that
CB-2 fixes a confirmed cause.

**What HCB-4 changed (confirmed from its diff).**
- `bee_building.gd::builder_go_to_site` claims one of the cell's six shared
  `slot_users` walls with `claim_slot()` and walks to `slot_position(slot)`.
- `hive_cell.gd::release_builder()` now also releases the slot.
- `hive.gd::find_unfinished_cell()` skips a site with no free slot.
- `builder_build()` releases the slot when the cell finishes.

**Candidate causes. None is confirmed.**
- **H1: the stand point is overwritten.** Movement inside the hive runs every
  target through `hive.nearest_walkable_point()`
  (`bee.gd` near `_is_inside_hive() and hive`). A site's wall midpoints
  (`slot_position`: the edge midpoint × 1.35) may fall on tiles that are not
  walkable. If so, several walls snap to the same neighbouring tile centre and
  the builders bunch. That would explain "not around the six walls".
- **H2: progress without a slot.** `builder_build()` adds progress for any bee
  in `BUILDING` whose `target_cell` is the site, and never checks that the bee
  still holds a slot. If another path releases that bee's slot
  (`BeeForaging.release_cell_slot`, the feeding or eating claims that share
  `slot_users`, `_release_everything`), the bee keeps building while its wall
  is handed to a new builder. That would explain "more than six".
- **H3: observation.** Bees in `BUILD_IDLE` or `TO_BUILD_SITE` hovering near a
  site look like builders. The instrument separates them.

**Owner.** `bee_building.gd` owns builder states, `hive_cell.gd` owns slots and
`builders`, `hive.gd` owns site choice and walkable snapping, and `bee.gd` owns
movement dispatch.

**Required reading.** This section. In `bee_building.gd`: `builder_go_to_site`
and `builder_build`. In `hive_cell.gd`: the "working positions" and "building"
sections. In `hive.gd`: `find_unfinished_cell` and `nearest_walkable_point`.
In `bee.gd`: the in-hive target snap and `_release_everything`.
`docs/headless-run-contract.md`, only its section on summaries and assertions.
One existing builder fixture (`grep -l builders test_scenarios/*.json`).

**Files likely to change.** `scripts/scenario_actions.gd`, or whichever script
writes the scenario summary (find it from the contract doc), and a new
test_scenarios/cb1_comb_builders_per_site_test.json.

**Must not change.** Behaviour in `bee_building.gd`, `hive_cell.gd`, `hive.gd`
or `bee.gd`, and any `GameConfig` value. CB-1 observes and nothing else.

**Requirements.**
1. **Fixture.** An open interior with no queued builds, 12 comb workers on
   the Building focus, a fixed seed, and one simulated day.
2. **Sampling.** Sample every 0.5 simulated seconds, in scenario runs only.
   `scenario_actions.gd` is already called once per `_process` tick while
   `main.scenario_active` (its file header says so), so accumulate the
   elapsed time there rather than adding a timer or a `_process` of your own.
   Walk the unfinished cells and, for each, its own `slot_users` and
   `builders` -- never every bee against every cell -- and keep running
   maxima instead of an array of samples, so a day of sampling allocates
   nothing per tick. For each unfinished cell record:
   - bees in `BUILDING` targeting it;
   - bees holding one of its slots;
   - distinct slot indices in use;
   - `BUILDING` bees that are not in its `slot_users`;
   - the smallest distance between any two of its `BUILDING` bees.

   Write the maxima across the whole run, and the minimum spacing, to the
   summary as `comb_build_sites`.
3. **Assertions.** `max_builders_per_site <= 6`, `building_without_slot == 0`
   and `min_builder_spacing_px >= 0.8 * GameConfig.hive_cell_size`. Record
   which of them fail today.
4. Read back only the `comb_build_sites` fields, never the raw output.

**Runtime policy.** Sampling exists only under `--scenario`. Normal play gains
no work.

**Edge cases.** A cell completing between samples. Builders breaking off to
eat. The queen's Challenge 1 building uses the same code but is not in this
fixture.

**Acceptance.** Two runs give identical numbers. The delivery note states
which hypothesis the numbers support, with those numbers, and CB-2's section
below is rewritten into a concrete specification.

**Regression.** `tools/verify.ps1`. (`slice1_smoke_test.json` is covered by
the shipped Codex **SM-1**, `plans/archive/SMOKE_SCENARIO_2026-09-19.md`.
Read its delivery note before treating a smoke failure as an H2 regression.)

**Escalate if** every assertion passes. If the colony already does what HCB-4
intended, C-46 is seeing something else, and Dave's clarification (a
screenshot, or which bees he counted) is needed before CB-2.

## CB-2 — the fix CB-1 identifies

**CB-1 result (2026-09-19, fixture `cb1_comb_builders_per_site_test.json`,
seed 4242, 12 comb workers on Building, one day, 200 samples, identical over
two runs).** `max_builders_per_site` 6 (pass), `building_without_slot` 0
(pass), `min_builder_spacing_px` 11.47 against the 13.6 needed (fail).
The numbers support **H1**: the slot cap holds and nobody builds without a
slot, but two builders at one site stand closer than 0.8 of a cell size apart,
which matches builders bunching rather than ringing the six walls. H2 is not
supported. H3 is not separated by these numbers. CB-1 did not record the
snapped stand points themselves, so CB-2 starts by confirming the snap
(`hive.nearest_walkable_point()` on each `slot_position`) is what merges them.

CB-2 is the H1 fix; startable once G2 has merged. Fixed now:

- **Invariants.**
  - CB-1's assertions pass.
  - One builder still contributes the same build progress per second.
  - The six-slot cap for depositing and feeding is unchanged.
  - A site with a free wall is still found by `find_unfinished_cell()`.
- **Guidance, not decisions.**
  - For H1: give each slot a reachable stand point of its own (snap each wall
    to a distinct walkable point), rather than letting every approach snap to
    one tile.
  - For H2: `builder_build()` requires `target_cell.slot_users.has(bee)` and
    otherwise sends the bee back to `TO_BUILD_SITE`.
- **Hot path.** `builder_build()` runs for every building bee every frame.
  Count the calls and the builder population before adding any check
  (`.claude/rules/performance.md`). A scan of six slots is acceptable; an
  allocation is not.
- **Save/load.** Read `.claude/rules/saving.md` first. A restored run must not
  leave a `BUILDING` bee without a slot.
- **Sequencing.** Do not start until G2 has merged: it is sole owner of
  `bee.gd` and reshapes the `bee_*.gd` signatures this fix would edit.
- **Completion.** Move C-46 from `checks/blocked.md` back to ready. Archive
  this plan with `Next: None — plan complete`.
