# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: T2-9 -- a skill not available in this run never blocks the tier above it (C-113, Dave 11 Oct 2026) and T2-6 -- Associative learning, specified below with Dave's 10 Oct 2026 decisions and queued in the Claude lane (T2-7 landed 11 Oct 2026 as the rule, snapshot field and pacing row; its price sweep waits for AR-4) | Dependency: COL-4, COL-6, T2-4a and T2-4b landed; T2-7's predecessors BB-2 and NF-4 landed 10 Oct 2026; T2-6 follows T2-7 (shared `skills.gd`) | Verified: 2026-10-11

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
| T2-6 | Associative learning: the existing handling experience, gated by the skill, with a fade | `scripts/skills.gd`, `scripts/bee_foraging.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_t2_6_associative_learning.py`, `tests/t2_6_associative_learning_test.gd` | yes -- queued in the Claude lane behind T2-7 | medium |
| T2-9 | A skill not available in this run never blocks the tier above it (C-113) | `scripts/progression.gd`, `plans/design/progression.md`, `test_scenarios/t2_9_c2_comb_worker_test.json`, `tests/test_t2_9_unavailable_tier.py` | after T2-7 (shared `scripts/progression.gd`, `plans/design/progression.md`) | medium |

**Dependencies.** T2-1, T2-2 and T2-3 run in that order in the Claude lane:
T2-1 and T2-2 share `roles.gd`, `availability.gd` and `challenge_stages.gd`,
and each adds a test module. They depend on
nothing else. T2-4a follows T2-2 (`actions.gd`, `challenge_stages.gd`).
T2-4b landed 9 Oct 2026, so it no longer shares files with NF-3
(`plans/archive/nectar-fermentation_2026-10-10.md`) or Bee Bread's BB-1
(`plans/now/bee-bread.md`).
T2-7 prices the gates T2-1 to T2-3 built. T2-6 shares `skills.gd` with
T2-7, so it runs after it in the Claude lane (NF-4 and BB-2, which shared
`skills.gd`, `bee_foraging.gd`, `game_config.gd` and `settings_catalogue.gd`, landed 10 Oct 2026).
Pollinator Points (`plans/now/pollination.md` PP-1) needs T2-6: foraging
tier 3 opens only when Associative learning is owned. T2-8 multiplies COL-6's one-step winter (landed 7 Oct 2026).
NF-4 (`plans/archive/nectar-fermentation_2026-10-10.md`) added a Colony tier-2 node in
`skills.gd` and landed 10 Oct 2026, before T2-7, which prices it. T2-7 runs after
BB-2 (`plans/now/bee-bread.md`) so its sweep includes the 15-day
unfed-worker rule; BB-4 then moves stage thresholds only, never prices.
T2-7 shares `tools/pacing_gates.py` with gated AR-4
(`plans/now/alpha-route-evidence.md`). A new test module no longer edits
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

## T2-6 -- Associative learning

<!-- LAYER: immediate-task -->

**Level: medium.** Bounded, with an acceptance check; no save migration.
It runs after T2-7, which sets its price; T2-6 keeps that price.

**The behaviour already ships behind a developer toggle.** Slice 7's
handling experience (`GameConfig.handling_experience_on`, off by default)
counts each bee's finished visits per species in `bee.species_experience`
and shortens handling time towards `handling_experience_floor` (0.75, a
quarter faster) over `handling_experience_visits_to_floor` (10) visits:
`bee_foraging.gd::_handling_experience_scale`, read in the handling start
and incremented in `finish_collecting`. `bee.species_experience` is
already saved and restored (`save_game.gd`, `saving.gd`). That matches the
7 Oct intent, so this slice gates it and adds the fade, and changes no save
format.

**Decisions (Dave, 10 Oct 2026, plan-ahead session).**

- **Bees learn only once the colony owns the skill.** Nothing is counted
  before the purchase; the speed-up builds over the next visits. The
  developer toggle still forces it on, as Tarsal secretions' does.
- **Experience fades after about 15 visits elsewhere.** Each finished visit
  to one species takes `handling_experience_visits_to_floor / 15` visits'
  worth off the bee's experience with every other species, so full
  experience is gone after 15 visits to others. A loyal forager keeps her
  edge; a generalist never fully gets it. One `GameConfig` value,
  `handling_experience_forget_visits` (15), confirmed by the headless test
  below rather than a separate sweep.

**Change.**

1. `skills.gd`: Associative learning gains
   `{"type": "enable_behaviour", "key": "handling_experience_on"}` and its
   status becomes `existing`, so the tree stops calling it "Not built yet".
2. `bee_foraging.gd`: a `handling_experience_on()` helper beside
   `tarsal_markers_on()` (setting OR owned skill); both reads of
   `GameConfig.handling_experience_on` use it.
3. `bee_foraging.gd`, where `finish_collecting` counts a visit: experience
   becomes a float; after adding one to this species, subtract the fade from
   every other species in the bee's dictionary and erase entries that reach
   zero, so the dictionary stays bounded. Runtime: once per finished visit,
   over the handful of species one bee has worked; no per-frame cost.
4. `game_config.gd` and `settings_catalogue.gd`:
   `handling_experience_forget_visits` with a `"persist": "run"` row beside
   `handling_experience_visits_to_floor`.

**Must not change.** Handling time with neither the toggle nor the skill;
the save format (a pre-T2-6 save's integer counts load as floats); Adaptive
constancy's separate `species_confidence`.

```queue
**[Claude] T2-6 -- Associative learning**
- Plan: `plans/now/tier-two.md` -- "T2-6 -- Associative learning"
- Files: `scripts/skills.gd`, `scripts/bee_foraging.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_t2_6_associative_learning.py`, `tests/t2_6_associative_learning_test.gd`
- Check: `python -m unittest tests.test_t2_6_associative_learning` passes (with the toggle off, a bee's handling time and experience stay unchanged until Associative learning is bought; once owned, ten visits to one species bring its handling to 0.75 of a first-timer's, and fifteen visits to another species then erase that experience; experience survives save and restore); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/bee_foraging.gd :: static func handling_experience_on`
- Next after: PP-1 -- bees earn Pollinator Points and Contribution
```

T2-7 shipped 2026-10-11; its specification is `plans/archive/T2-7_2026-10-11.md`.

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
- Next after: T2-6 -- Associative learning
```

## Not in the queue, and why

- **T2-6** is admissible and waits only for room in the Claude lane, behind T2-7.
- **T2-9** is admissible and waits only for room in the Claude lane, behind T2-7 (shared `scripts/progression.gd`).

T2-8b shipped 2026-10-09; its specification is `plans/archive/T2-8b_2026-10-09.md`.
