# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: T2-9 -- a skill not available in this run never blocks the tier above it (C-113, Dave 11 Oct 2026), waiting for room in the Claude lane (T2-6 landed 11 Oct 2026); then T2-7b -- the tier-2 price sweep T2-7 deferred (Dave, 11 Oct 2026: the alpha arc makes no honey, so no median can land in band until AR-4's arc buys a Honey worker) | Dependency: COL-4, COL-6, T2-4a, T2-4b, T2-6 and T2-7 landed (T2-7 on 11 Oct 2026, as the rule, snapshot field and pacing row); T2-7b waits for AR-4 (`plans/now/alpha-route-evidence.md`) | Verified: 2026-10-11

## Objective

`plans/design/progression.md` section 11, step 8: the tier-2 skills that
already have behaviour become purchases, and the alpha's new tier-2
behaviour (rain recall, associative learning, Shiver Cluster, cleaning the
dead) is built. Every design decision is recorded once, in
`plans/design/progression.md` step 8 ("Decisions", 6 and 7 Oct 2026) and
section 5.6 ("Shiver Cluster"); slices here restate them in a sentence and
never re-argue them.

## Current state

Verified 7 Oct 2026 against master:

- Only Nurses and Honey worker gate a role (`roles.gd` `skill` field, read
  by `availability.gd::role_query` and `action_query`). Comb worker and
  Miner carry `"skill": ""`.
- `action_query` lets the queen nurse without Nurses (BS-9) through an
  inline `Roles.NURSE` check. `role_query`, which the HUD's Job row
  (`hud.gd::_role_offered`) and `orders_zones.gd::_role_permitted` read,
  has no bee argument and no queen exemption.
- `mode_query` checks stage gates only; no mode is skill-gated. The Miner's
  "Dig on its own" is `actions.gd`'s `mine_automine_block` row; Comb
  workers' outward building is `comb_build` over `hive.gd`'s outward hex
  spiral.
- Value-switch skills use `enable_behaviour` effects read through a helper
  such as `bee_foraging.gd::tarsal_markers_on`. Adaptive constancy reads
  `GameConfig.adaptive_constancy_on` directly (three places in
  `bee_foraging.gd`, off by default).
- "Seeding implies owning" (`run_availability.gd::_seeded_skills`) is
  generic over every role with a skill and a `start_count_key`, so a run
  that seeds builders or miners will own their skills with no new code.
- Challenge 2 introduces Comb worker at stage 2.7 and Miner, with "Dig on
  its own", at 2.8 (`challenge_stages.gd`). A stage's `free_skills` waive
  cost while it is current; a skill must also be in `unlocked_keys` to be
  permitted. A tier opens only when every node of the tier below in that
  branch is owned (`progression.gd::branch_tier_open`), so Hive Mind tier 2
  needs Backup roles owned.
- Clearing (`comb_clean_cell`, Comb worker "maintain" mode, gated on
  Cleaning) clears dead larvae first and then, since T2-4b, carries out the
  bodies of bees who died inside the hive (`hive.gd`'s `bodies`,
  `scripts/hive_body.gd`), which count towards disease like dead larvae.
  A meadow death still leaves only the presentation-only death marker.
- Rain runs only while `GameConfig.weather_on` (false by default) and the
  level row allow it (`main.gd`, weather advance). `bee_status.gd` keeps
  bees in above `rain_forage_limit`.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| T2-9 | A skill not available in this run never blocks the tier above it (C-113) | `scripts/progression.gd`, `plans/design/progression.md`, `test_scenarios/t2_9_c2_comb_worker_test.json`, `tests/test_t2_9_unavailable_tier.py` | yes -- waits for room in the Claude lane (T2-7, which shared `scripts/progression.gd`, landed 11 Oct 2026) | medium |
| T2-7b | The tier-2 price sweep T2-7 deferred: tier-2 costs set so the arc's first tier-2 purchase lands around day 5 | `scripts/skills.gd`, `plans/design/progression.md`, tests; specified when AR-4 lands | no -- after AR-4 (`plans/now/alpha-route-evidence.md`), whose arc buys a Honey worker | medium |

**Dependencies.** T2-1, T2-2 and T2-3 run in that order in the Claude lane:
T2-1 and T2-2 share `roles.gd`, `availability.gd` and `challenge_stages.gd`,
and each adds a test module. They depend on
nothing else. T2-4a follows T2-2 (`actions.gd`, `challenge_stages.gd`).
T2-4b landed 9 Oct 2026, so it no longer shares files with NF-3
(`plans/archive/nectar-fermentation_2026-10-10.md`) or Bee Bread's BB-1
(`plans/now/bee-bread.md`).
T2-7 (landed 11 Oct 2026) measures the gates T2-1 to T2-3 built; T2-7b prices them. T2-6 shared `skills.gd` with
T2-7, so it ran after it in the Claude lane (NF-4 and BB-2, which shared
`skills.gd`, `bee_foraging.gd`, `game_config.gd` and `settings_catalogue.gd`, landed 10 Oct 2026).
Pollinator Points (`plans/now/pollination.md` PP-1) needs T2-6: foraging
tier 3 opens only when Associative learning is owned. T2-8 multiplies COL-6's one-step winter (landed 7 Oct 2026).
NF-4 (`plans/archive/nectar-fermentation_2026-10-10.md`) added a Colony tier-2 node in
`skills.gd` and landed 10 Oct 2026, before T2-7b, which prices it. T2-7b runs after
BB-2 (`plans/now/bee-bread.md`), so its sweep includes the 15-day
unfed-worker rule; BB-4 moves stage thresholds only, never prices.
T2-7b waits for AR-4 (`plans/now/alpha-route-evidence.md`): the alpha arc
makes no honey, so the sweep's median cannot land in band before AR-4's arc
buys a Honey worker (Dave, 11 Oct 2026). Open when T2-7b is specified:
whether BB-4's Challenge routes are re-checked at the new prices. A new test module no longer edits
`tools/verify.ps1`, which finds them itself since 7 Oct 2026, so adding a
test puts no shared file in either lane.

**Reads.** A slice reads its own section below and the step 8 decisions in
`plans/design/progression.md` (`python tools/heading.py
plans/design/progression.md "11. Implementation sequence"`, step 8 only).

T2-1 shipped 2026-10-07; its specification is `plans/archive/T2-1_2026-10-07.md`.

T2-2 shipped 2026-10-07; its specification is `plans/archive/T2-2_2026-10-07.md`.

T2-3 shipped 2026-10-07; its specification is `plans/archive/T2-3_2026-10-07.md`.

COL-4 shipped 2026-10-07; its specification is `plans/archive/COL-4_2026-10-07.md`.

T2-4a shipped 2026-10-08; its specification is `plans/archive/T2-4a_2026-10-08.md`.

T2-5 shipped 2026-10-09; its specification is `plans/archive/T2-5_2026-10-09.md`.

T2-4b shipped 2026-10-09; its specification is `plans/archive/T2-4b_2026-10-09.md`.

T2-6 shipped 2026-10-11; its specification is `plans/archive/T2-6_2026-10-11.md`.

## T2-9 -- A skill not available in this run never blocks the tier above it

<!-- LAYER: immediate-task -->

**Decision (Dave, 11 Oct 2026, from failed check C-113).** Branch-tier
progress counts only the lower-tier skills this run offers. A skill that is
cut, banned, not yet unlocked by the stage, or missing its feature no longer
keeps the tier above it shut. This makes `plans/design/progression.md`
section 9's rule ("a Challenge's grants/bans/delays cannot make branch
advancement impossible") hold.

**True now.** `progression.gd::branch_tier_open` returns false unless every
skill in the branch's tier below is owned. In Challenge 2 at 2.7 and 2.8,
Cell capacity (Colony's only tier-1 skill) is not in the stage's
`unlocked_keys`, so `is_permitted` refuses it and it cannot be bought. Comb
worker and Miner, Colony tier 2 and free at those stages, read "blocked:
needs a skill from the tier before it" (C-113, confirmed by an opus re-run
on 11 Oct 2026).

**True afterwards.**

- `progression.gd` has `_offered_in_run(skill_id) -> bool`, returning
  `is_permitted(skill_id) and feature_valid(skill_id)`.
  `branch_tier_open` skips a lower-tier sibling for which it is false. A
  tier whose siblings are all skipped counts as satisfied.
- `plans/design/progression.md` section 4.3's first rule reads "every skill
  in that branch's tier N that this run offers", with the decision's date.
- `purchase_blocker`'s order and every other gate are unchanged.

**Runtime.** Same call sites and count as now (`purchase_blocker`, on a
panel refresh or a purchase query). It adds two dictionary lookups per
sibling and nothing per frame.

**Must not change.** Skill prices (T2-7's); the rule when every lower-tier
skill is offered; mastered skills counting as owned; Challenge 2's stage
data.

**Escalate** if a test shows a Colony Run or Scenario tier opening earlier
than before because a stage-delayed skill now counts as not offered: that
would be a gameplay change beyond the Challenge case Dave decided.

**Test.** `test_scenarios/t2_9_c2_comb_worker_test.json` (`"challenge": 2`,
as `test_scenarios/bs9_c2_queen_nurses_test.json` starts): advance to 2.5
and `buy_skill` `skill.brood.nurses`, advance to 2.7, `buy_skill`
`skill.colony.comb_worker`, assert `skill_owned` true; advance to 2.8,
`buy_skill` `skill.colony.miner`, assert `skill_owned` true.
`tests/test_t2_9_unavailable_tier.py` runs it and also checks, from source,
that `branch_tier_open` calls `_offered_in_run`.

```queue
**[Claude] T2-9 -- A skill not available in this run never blocks the tier above it**
- Plan: `plans/now/tier-two.md` -- "T2-9 -- A skill not available in this run never blocks the tier above it"
- Files: `scripts/progression.gd`, `plans/design/progression.md`, `test_scenarios/t2_9_c2_comb_worker_test.json`, `tests/test_t2_9_unavailable_tier.py`
- Check: `python -m unittest tests.test_t2_9_unavailable_tier` passes (Challenge 2 buys Comb worker at 2.7 and Miner at 2.8 while Cell capacity stays unavailable); `tools/verify.ps1` is green
- Proof: `absent: scripts/progression.gd :: _offered_in_run`
- Next after: none -- T2-6 landed 11 Oct 2026, and T2-7b waits for AR-4
```

## Not in the queue, and why

- **T2-9** is admissible and waits only for room in the Claude lane.
- **T2-7b** -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4 (`plans/now/alpha-route-evidence.md`), whose arc buys a Honey worker, and is specified when it lands.

T2-8b shipped 2026-10-09; its specification is `plans/archive/T2-8b_2026-10-09.md`.
