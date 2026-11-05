# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None -- plan complete; T2-7b was withdrawn (Dave, 5 Nov 2026, product review D5), and tier-2 prices stay drafts, edited directly when play shows a need | Dependency: none | Verified: 2026-11-05

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
| none | T2-7b was withdrawn on 5 Nov 2026 (below) | -- | -- | -- |

**T2-7b withdrawn (Dave, 5 Nov 2026, product review D5).** The sweep was to
set tier-2 costs so the first purchase landed around day 5. The reference
route stores no honey before Days 19-22 and every tier-2 recipe names 20-25
honey, so no price could reach day 5; Dave moved the target to follow the
first honey and made every timing a draft (`plans/design/product-scope.md`
§3). Tier-2 amounts in `skills.gd` stay as they are and are edited directly
when play shows a need.

**Reads.** A slice reads its own section below and the step 8 decisions in
`plans/design/progression.md` (`python tools/heading.py
plans/design/progression.md "11. Implementation sequence"`, step 8 only).

T2-1 to T2-6, T2-8b, T2-9 and COL-4 shipped 7-12 Oct 2026; each has its record in `plans/archive/`, named by id and date.

T2-10 shipped 2026-10-16; its specification is `plans/archive/T2-10_2026-10-16.md`.

T2-11 shipped 2026-10-17; its specification is `plans/archive/T2-11_2026-10-17.md`.

T2-14 shipped 2026-10-21; its specification is `plans/archive/T2-14_2026-10-21.md`.

T2-15 shipped 2026-11-02; its specification is `plans/archive/T2-15_2026-11-02.md`.

## Not in the queue, and why

- None: T2-7b was withdrawn (product review D5, 5 Nov 2026).
