# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: then T2-7b; T2-14 landed 21 Oct 2026 (a comb worker's idle reason asks whether there is room to build, without starting a site: T2-11's finding); T2-13 landed 20 Oct 2026 (a role change puts a carried body down; gameplay review, 15 Oct 2026) (T2-11 answered 17 Oct 2026: a comb worker's idle reason starts a site, so without Automation comb grows outward only while one is selected); T2-12 landed 20 Oct 2026 (Dig on its own waits for Automation; C-136 awaits Dave's check); then T2-7b (T2-9 landed 12 Oct 2026: branch-tier progress counts only the lower-tier skills the run offers, C-113) -- the tier-2 price sweep T2-7 deferred (Dave, 11 Oct 2026: the alpha arc makes no honey, so no median can land in band until AR-4's arc buys a Honey worker) | Dependency: COL-4, COL-6, T2-4a, T2-4b, T2-6 and T2-7 landed (T2-7 on 11 Oct 2026, as the rule, snapshot field and pacing row); T2-7b waits for AR-4 (`plans/now/alpha-route-evidence.md`) | Verified: 2026-10-21

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

**Dependencies.** T2-10 and T2-13 both edit `scripts/bee.gd`; T2-10
landed 16 Oct 2026, so T2-13 is open. T2-14 edits `scripts/bee.gd` too,
so it runs after T2-13, and `scripts/hive.gd`, held by RR-10 (Codex
lane). T2-12 landed 20 Oct 2026 (FC-2 released `scripts/hud.gd` on 17 Oct 2026). T2-7b waits for AR-4
(`plans/now/alpha-route-evidence.md`): the alpha arc makes no honey, so the
sweep's median cannot land in band before AR-4's arc buys a Honey worker
(Dave, 11 Oct 2026); it prices NF-4's Colony tier-2 node and includes
BB-2's 15-day unfed-worker rule. Open when T2-7b is specified: whether
BB-4's Challenge routes are re-checked at the new prices.

**Reads.** A slice reads its own section below and the step 8 decisions in
`plans/design/progression.md` (`python tools/heading.py
plans/design/progression.md "11. Implementation sequence"`, step 8 only).

T2-1 to T2-6, T2-8b, T2-9 and COL-4 shipped 7-12 Oct 2026; each has its record in `plans/archive/`, named by id and date.

T2-10 shipped 2026-10-16; its specification is `plans/archive/T2-10_2026-10-16.md`.

T2-11 shipped 2026-10-17; its specification is `plans/archive/T2-11_2026-10-17.md`.

**Code health (`plans/now/code-health.md`, 18 Oct 2026).** CQ-R3 moves `bee.gd`'s display text (`idle_reason`, `_task_line`) to scripts/bee_readout.gd and waits for T2-14, which removes `idle_reason`'s comb-site side effect; T2-12 and T2-13 share `hud.gd`/`bee.gd` with code-health slices in the same lane, one after the other.

T2-14 shipped 2026-10-21; its specification is `plans/archive/T2-14_2026-10-21.md`.

## Not in the queue, and why

- **T2-7b** -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4 (`plans/now/alpha-route-evidence.md`), whose arc buys a Honey worker, and is specified when it lands.
