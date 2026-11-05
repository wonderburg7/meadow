# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: T2-7b -- the tier-2 price sweep T2-7 deferred; it runs after EV-0 and before PP-10 (Dave, 5 Nov 2026, product review D4) and is specified by the product review once Dave answers its D5 (honey before Day 5) | Dependency: T2-7b waits for EV-0 (`plans/now/event-director.md`); PP-10 (`plans/now/pollination.md`) waits for T2-7b | Verified: 2026-11-05

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
| T2-7b | The tier-2 price sweep T2-7 deferred: tier-2 costs set so the arc's first tier-2 purchase lands around day 5 | `scripts/skills.gd`, `plans/design/progression.md`, tests; specified by the product review after D5 | no -- after EV-0 (`plans/now/event-director.md`); before PP-10 | medium |

**Dependencies.** T2-7b follows EV-0 (`plans/now/event-director.md`) and
precedes PP-10 (`plans/now/pollination.md`), so the gyne route is priced on
final tier-2 prices (Dave, 5 Nov 2026, product review D4). The 11 Oct reason for waiting on AR-4 (the arc
made no honey) no longer holds: PP-11's route reports `first_tier2_day` on
every seed (5 Nov 2026: days 24.16, 53.02 and 27.22). It prices NF-4's Colony tier-2 node and includes
BB-2's 15-day unfed-worker rule. FR-2 adds Auto scouting as a third
Foraging tier-2 node; PP-10 prices it, so T2-7b leaves it alone. Open when
T2-7b is specified: whether BB-4's Challenge routes are re-checked at the
new prices.

**Reads.** A slice reads its own section below and the step 8 decisions in
`plans/design/progression.md` (`python tools/heading.py
plans/design/progression.md "11. Implementation sequence"`, step 8 only).

T2-1 to T2-6, T2-8b, T2-9 and COL-4 shipped 7-12 Oct 2026; each has its record in `plans/archive/`, named by id and date.

T2-10 shipped 2026-10-16; its specification is `plans/archive/T2-10_2026-10-16.md`.

T2-11 shipped 2026-10-17; its specification is `plans/archive/T2-11_2026-10-17.md`.

T2-14 shipped 2026-10-21; its specification is `plans/archive/T2-14_2026-10-21.md`.

T2-15 shipped 2026-11-02; its specification is `plans/archive/T2-15_2026-11-02.md`.

## Not in the queue, and why

- **T2-7b** -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for EV-0 (`plans/now/event-director.md`) and runs before PP-10 (Dave, 5 Nov 2026, product review D4).
