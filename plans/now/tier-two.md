# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: T2-7 -- tier-2 costs tuned so the first purchase lands around day 5, specified below and queued in the Claude lane behind BB-2 and NF-4 (Dave, 10 Oct 2026); T2-6 -- Associative learning waits for Dave's decision (T2-4b, bodies, built 9 Oct 2026) | Dependency: COL-4, COL-6, T2-1 to T2-3, T2-4a and T2-4b landed; T2-7 runs after BB-2 and NF-4 (same lane); T2-6 waits for Dave | Verified: 2026-10-10

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
| T2-6 | Associative learning: per-bee, per-species familiarity, saved | `scripts/skills.gd`, `scripts/bee.gd`, `scripts/bee_foraging.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_t2_6_associative_learning.py`, `tests/t2_6_associative_learning_test.gd` | no -- rate and save acceptance need specification | high |
| T2-7 | Tier-2 costs tuned so the first purchase lands around day 5 | `scripts/skills.gd`, `scripts/progression.gd`, `scripts/diagnostic_log.gd`, `tools/analyze_session.py`, `tools/pacing_gates.py`, `plans/design/progression.md`, its test | yes -- queued in the Claude lane behind BB-2 and NF-4 | medium |

**Dependencies.** T2-1, T2-2 and T2-3 run in that order in the Claude lane:
T2-1 and T2-2 share `roles.gd`, `availability.gd` and `challenge_stages.gd`,
and each adds a test module. They depend on
nothing else. T2-4a follows T2-2 (`actions.gd`, `challenge_stages.gd`).
T2-4b landed 9 Oct 2026, so it no longer shares files with NF-3
(`plans/now/nectar-fermentation.md`) or Bee Bread's BB-1
(`plans/now/bee-bread.md`).
T2-6 and T2-7 wait for COL-4; T2-7 also for T2-1 to T2-3, whose
gates it prices. T2-8 multiplies COL-6's one-step winter (landed 7 Oct 2026).
NF-4 (`plans/now/nectar-fermentation.md`) adds a Colony tier-2 node and
shares `skills.gd`; it lands before T2-7, which prices it. T2-7 runs after
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

This successor needs its per-species gain and fade rates, handling-speed cap,
and old-save default specified before implementation. The intended behaviour
is recorded in "Later slices" below; T2-5 does not choose those values.

```queue-gated
**[Codex] T2-6 -- Associative learning**
- Plan: `plans/now/tier-two.md` -- "T2-6 -- Associative learning"
- Files: `scripts/skills.gd`, `scripts/bee.gd`, `scripts/bee_foraging.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_t2_6_associative_learning.py`, `tests/t2_6_associative_learning_test.gd`
- Check: a headless run shows per-bee, per-species familiarity rising on visits, fading while working other species, changing handling speed only when owned, and surviving save/load; `tools/verify.ps1` is green
- Proof: `absent: scripts/bee.gd :: species_familiarity`
- Next after: none -- step 8 is complete (T2-7 prices the tier-2 recipes first)
```

## T2-7 -- Tier-2 costs tuned so the first purchase lands around day 5

<!-- LAYER: immediate-task -->

**Decision (Dave, 10 Oct 2026).** T2-7 is specified now and queued behind
BB-2 and NF-4 in the Claude lane, so it prices against BB-2's 15-day
unfed-worker rule and includes NF-4's Colony tier-2 node. It adds the
missing first-tier-2 metric itself. BB-4 (`plans/now/bee-bread.md`) then
moves stage thresholds only, never skill prices; T2-6 keeps the price
T2-7 sets for Associative learning.

**True now.** The tier-2 `cost` amounts in `scripts/skills.gd` are guesses
(`plans/design/progression.md` step 8: "the amounts in `skills.gd` remain
guesses until it does"). `tools/pacing_gates.py` measures the five
product-scope gates over the PE-2 arc (`test_scenarios/alpha_arc_test.json`,
three seeds). It has no tier-2 fact. The scripted arc buys no skill, so a
purchase day cannot be read off it. Only `scripts/progression.gd` may read
the skill catalogue (`colony_milestones.gd` header). `progression.gd::can_afford`
is the one affordability rule. Snapshots already log `food_stores`,
`stored_nectar` and `stored_pollen` (`diagnostic_log.gd`).

**True afterwards.**

- `progression.gd` answers whether the given stores cover the cheapest
  first-tier-2 path. That path is Honey worker (the spine), plus one tier-1
  node and one tier-2 node of the same branch, summed per resource. Only
  nodes the skill tree offers count: not cut, and with their `all_of`
  prerequisites included. It extends `can_afford`; it does not add a
  second price rule.
- Each diagnostic snapshot carries that answer as one boolean under
  `resources`, through `Session.progression`. Runtime: once per snapshot,
  never per frame.
- `tools/analyze_session.py` records `first_tier2_day`, the first snapshot
  day it is true. `tools/pacing_gates.py` prints it on its own row against
  day 5 with the existing `BAND_FRACTION`. It is a diagnostic beside the five
  product-scope gates, not a sixth gate.
- One PE-2 sweep (`python tools/pacing_gates.py`, three seeds) sets the
  tier-2 `cost` amounts so the median `first_tier2_day` is in band. Tier-1
  and later tiers keep their prices. The amounts before and after, with
  each seed's day, are recorded in this section and replace the "guesses"
  sentence in `plans/design/progression.md` step 8.

**Must not change.** Tier-1, tier-3 and tier-4 prices; the five gates'
rows and verdicts; any stage threshold; the branch-tier rule.

**Out of scope.** Re-pacing the Challenges and the Colony Run for 15-day
workers (BB-4), T2-6's familiarity rates, and teaching the scripted arc to
buy skills (AR-4, `plans/now/alpha-route-evidence.md`, which shares
`tools/pacing_gates.py` and is gated).

```queue
**[Claude] T2-7 -- Tier-2 costs tuned so the first purchase lands around day 5**
- Plan: `plans/now/tier-two.md` -- "T2-7 -- Tier-2 costs tuned so the first purchase lands around day 5"
- Files: `scripts/skills.gd`, `scripts/progression.gd`, `scripts/diagnostic_log.gd`, `tools/analyze_session.py`, `tools/pacing_gates.py`, `plans/design/progression.md`, `tests/test_t2_7_tier_two_prices.py`
- Check: `python -m unittest tests.test_t2_7_tier_two_prices` passes (a snapshot whose stores cover the cheapest first-tier-2 path sets `first_tier2_day`, one that falls short by one unit of any resource does not, and pacing_gates prints the row against day 5 without changing the five gate rows); `python tools/pacing_gates.py` shows the median `first_tier2_day` in band, recorded before and after in the plan; `tools/verify.ps1` is green
- Proof: `absent: tools/analyze_session.py :: first_tier2_day`
- Next after: T2-6 -- Associative learning
```

## Not in the queue, and why

- T2-6 waits for its rates, cap, and old-save acceptance to be specified before the high-risk save change starts.

T2-8b shipped 2026-10-09; its specification is `plans/archive/T2-8b_2026-10-09.md`.

## Later slices -- outline only

<!-- LAYER: design -->

Each is specified, with its queue block and verified `Proof:`, when the
slice before it lands. The decisions they implement are in
`plans/design/progression.md` step 8 and section 5.6.

- **T2-6** -- familiarity per bee per species, saved, raising handling
  speed to the step 8 intent and fading while the bee works other species;
  rates from a headless sweep. Runtime: updated on a flower visit only.
