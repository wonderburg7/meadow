# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: T2-7b -- the tier-2 price sweep T2-7 deferred (Dave, 11 Oct 2026: the alpha arc makes no honey, so no median can land in band until AR-4's arc buys a Honey worker); specified when AR-4 lands | Dependency: T2-7b waits for AR-4 (`plans/now/alpha-route-evidence.md`), which waits for PP-6 and FR-2 | Verified: 2026-10-24

## Objective

`plans/design/progression.md` section 11, step 8: the tier-2 skills that
already have behaviour become purchases, and the alpha's new tier-2
behaviour (rain recall, associative learning, Shiver Cluster, cleaning the
dead) is built. Every design decision is recorded once, in
`plans/design/progression.md` step 8 ("Decisions", 6 and 7 Oct 2026) and
section 5.6 ("Shiver Cluster"); slices here restate them in a sentence and
never re-argue them.

## Current state

Verified 15 Oct 2026 against master `b5e6751`. T2-1 to T2-6, T2-8b, T2-9 and
COL-4 have landed (T2-7 too, as the rule, snapshot field and pacing row).
What the open slices build on:

- Comb worker and Miner are skill-gated roles (`roles.gd`:
  `skill.colony.comb_worker`, `skill.colony.miner`), read by
  `availability.gd::role_query` and `action_query`.
- The Miner's "Dig on its own" (`actions.gd`'s `mine_automine_block`) and
  Comb workers' outward building (`comb_build_outward`) need
  `skill.hive_mind.automation`.
- A tier opens only when the lower-tier skills the run offers in that branch
  are owned (`progression.gd::branch_tier_open`, T2-9).
- Bodies of bees who die inside the hive lie in `hive.gd`'s `bodies`
  (`scripts/hive_body.gd`); a Comb worker in "maintain" mode carries them
  out (`bee_building.gd`), and they count towards disease.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| T2-7b | The tier-2 price sweep T2-7 deferred: tier-2 costs set so the arc's first tier-2 purchase lands around day 5 | `scripts/skills.gd`, `plans/design/progression.md`, tests; specified when AR-4 lands | no -- after AR-4 (`plans/now/alpha-route-evidence.md`), whose arc buys a Honey worker | medium |
| T2-15 | with Fermentation sense and Cleaning owned, cleaning comb workers discard sour nectar unasked | `scripts/hive.gd`, `scripts/bee_building.gd`, tests | yes -- DR-1 and CQ-M8 landed 25 Oct 2026 | medium |

**Dependencies.** T2-7b waits for AR-4
(`plans/now/alpha-route-evidence.md`): the alpha arc makes no honey, so the
sweep's median cannot land in band before AR-4's arc buys a Honey worker
(Dave, 11 Oct 2026); it prices NF-4's Colony tier-2 node and includes
BB-2's 15-day unfed-worker rule. FR-2 adds Auto scouting as a third
Foraging tier-2 node; PP-6 prices it, so T2-7b leaves it alone. Open when
T2-7b is specified: whether BB-4's Challenge routes are re-checked at the
new prices.

**Reads.** A slice reads its own section below and the step 8 decisions in
`plans/design/progression.md` (`python tools/heading.py
plans/design/progression.md "11. Implementation sequence"`, step 8 only).

T2-1 to T2-6, T2-8b, T2-9 and COL-4 shipped 7-12 Oct 2026; each has its record in `plans/archive/`, named by id and date.

T2-10 shipped 2026-10-16; its specification is `plans/archive/T2-10_2026-10-16.md`.

T2-11 shipped 2026-10-17; its specification is `plans/archive/T2-11_2026-10-17.md`.

T2-14 shipped 2026-10-21; its specification is `plans/archive/T2-14_2026-10-21.md`.

## T2-15 -- with Fermentation sense and Cleaning owned, cleaning comb workers discard sour nectar unasked

Level: medium -- claude-sonnet-5-5 at medium effort (a gameplay outcome).

**True now.** Dave: "when fermentation sense and cleaning are both active,
cleaning comb workers should automatically clear fermented nectar".
Cleaning (`skill.hive_mind.cleaning`) gates the `comb_clean_cell` task
(`actions.gd`, near l.67). Its finder,
`bee_building.gd::find_cell_needing_cleaning` (near l.22), looks only at
corpses (`hive.gd::find_cell_needing_cleaning`, near l.695) and bodies. Fermentation
sense is `skill.colony.fermentation_sense`, read through
`hive.gd::senses_fermentation` (near l.574). Sour nectar is cleared only by
the player's "Discard all sour nectar" or a Discard order (NF-5).

**When done:**

1. `hive.gd` has a helper returning the first fermented cell with stock and no
   `evict_requested`, when `senses_fermentation()`; null otherwise.
2. In `find_cell_needing_cleaning`, after corpses and bodies and only when the
   bee owns Cleaning, that cell is marked `evict_mode = "discard"` and
   `evict_requested = true` and the function returns false, so the existing
   `comb_evict_cell` task picks it up.
3. The closeout runs the reference arc before and after
   (`python tools/run_scenario.py test_scenarios/alpha_arc_test.json`) and
   reports the difference. Do not tune anything.

**Invariants.** Without both skills nothing changes. Corpses and bodies keep
priority. One cell is marked per call, so there is no per-frame sweep: the
helper runs only when a comb worker looks for work. No save change (the
eviction fields are saved already).

**Stop and escalate** if the arc's outcome changes by more than a day on any
gate.

**Open decisions:** none.

```queue
**[Claude] T2-15 -- with Fermentation sense and Cleaning owned, cleaning comb workers discard sour nectar unasked**
- Plan: `plans/now/tier-two.md` -- "T2-15 -- with Fermentation sense and Cleaning owned, cleaning comb workers discard sour nectar unasked"
- Files: `scripts/hive.gd`, `scripts/bee_building.gd`, `tests/test_nf5_clear_fermented.py`
- Check: `python -m unittest tests.test_nf5_clear_fermented` passes with new cases (with both skills a cleaning comb worker empties a sour cell unasked; with only one skill it does not; corpses still come first); the before/after `alpha_arc_test.json` outputs are recorded in the closeout; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/bee_building.gd :: senses_fermentation`
- Next after: none -- `plans/now/tier-two.md` has only T2-7b left
```

## Not in the queue, and why

- **T2-7b** -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4 (`plans/now/alpha-route-evidence.md`), whose arc buys a Honey worker, and is specified when it lands.
