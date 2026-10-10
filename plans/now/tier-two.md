# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: T2-6 -- Associative learning, specified below with Dave's 10 Oct 2026 decisions and queued in the Claude lane; T2-7 is specified and fenced `queue-gated` until BB-4 lands | Dependency: COL-4, COL-6, T2-4a and T2-4b landed; T2-6 follows NF-4 and BB-2 in the Claude lane (shared files); T2-7 waits for BB-4, T2-6 and NF-4 | Verified: 2026-10-10

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
| T2-6 | Associative learning: the existing handling experience, gated by the skill, with a fade | `scripts/skills.gd`, `scripts/bee_foraging.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_t2_6_associative_learning.py`, `tests/t2_6_associative_learning_test.gd` | yes -- queued in the Claude lane | medium |
| T2-7 | Tier-2 costs tuned so the first purchase lands around day 5 | `scripts/skills.gd`, `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, `tests/test_t2_7_tier_two_prices.py`, `plans/design/progression.md` | no -- after BB-4, T2-6 and NF-4 | medium |

**Dependencies.** T2-1, T2-2 and T2-3 run in that order in the Claude lane:
T2-1 and T2-2 share `roles.gd`, `availability.gd` and `challenge_stages.gd`,
and each adds a test module. They depend on
nothing else. T2-4a follows T2-2 (`actions.gd`, `challenge_stages.gd`).
T2-4b landed 9 Oct 2026, so it no longer shares files with NF-3
(`plans/now/nectar-fermentation.md`) or Bee Bread's BB-1
(`plans/now/bee-bread.md`).
T2-6 shares `skills.gd` with NF-4 and `bee_foraging.gd`, `game_config.gd`
and `settings_catalogue.gd` with BB-2, so it runs after both in the Claude
lane. T2-7 waits for BB-4 (`plans/now/bee-bread.md`), which re-paces the
Colony Run, and for T2-6 and NF-4, whose nodes it prices. Pollinator Points
(`plans/now/pollination.md`) needs T2-6: foraging tier 3 opens only when
Associative learning is owned. T2-8 multiplies COL-6's one-step winter (landed 7 Oct 2026).
NF-4 (`plans/now/nectar-fermentation.md`) adds a Colony tier-2 node; T2-7
re-prices it if it has landed by then. A new test module no longer edits
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
- Next after: T2-7 -- Tier-2 costs tuned so the first purchase lands around day 5
```

## T2-7 -- Tier-2 costs tuned so the first purchase lands around day 5

<!-- LAYER: immediate-task -->

**Level: medium.** A balance slice, simulated first.

Intent (Dave, 6 Oct 2026, `plans/design/progression.md` step 8): a Colony
Run played reasonably makes its first tier-2 purchase around day 5. Today
the reference player in `test_scenarios/alpha_arc_test.json` buys no skill
at all, and `tools/pacing_gates.py` does not report purchases, so nothing
measures that intent.

**Change.**

1. `alpha_arc_test.json`: the reference player buys the tier-1 nodes it
   needs and then each tier-2 node as soon as it is affordable, using
   `scenario_actions.gd`'s existing `buy_skill` action and only the `when`
   keys the harness honours.
2. `pacing_gates.py`: report the day of the first tier-2 purchase across
   the repeats, beside the existing gates.
3. `skills.gd`: set the tier-2 recipe amounts (every tier-2 node, NF-4's
   Fermentation sense included) so the median first purchase lands on day
   4 to 6; record the before and after table in this section.
4. `plans/design/progression.md` step 8: replace "the amounts in
   `skills.gd` remain guesses until it does" with the measured result.

**Waits for** BB-4 (`plans/now/bee-bread.md`), which re-paces the Colony Run
for 15-day unfed workers -- pricing before it would be pricing the wrong
colony -- and for T2-6 and NF-4, whose nodes it prices. All three are in the
Claude lane, so when BB-4 lands this block's fence opens.

```queue-gated
**[Claude] T2-7 -- Tier-2 costs tuned so the first purchase lands around day 5**
- Plan: `plans/now/tier-two.md` -- "T2-7 -- Tier-2 costs tuned so the first purchase lands around day 5"
- Files: `scripts/skills.gd`, `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, `tests/test_t2_7_tier_two_prices.py`, `plans/design/progression.md`
- Check: `python tools/pacing_gates.py` reports a median first tier-2 purchase on day 4 to 6 of the Colony Run; `python -m unittest tests.test_t2_7_tier_two_prices` passes; `.\tools\verify.ps1` is green
- Proof: `absent: tools/pacing_gates.py :: first tier-2 purchase`
- Next after: none -- tier-two skills are complete
```

## Not in the queue, and why

- **T2-7** waits for BB-4 (`plans/now/bee-bread.md`), which re-paces the Colony Run for 15-day unfed workers, and for T2-6 and NF-4, whose nodes it prices.

T2-8b shipped 2026-10-09; its specification is `plans/archive/T2-8b_2026-10-09.md`.
