# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: T2-4a -- Cleaning gates taking out the dead larvae | Dependency: none for T2-1 to T2-3; COL-4 for T2-4b, T2-5, T2-6 and T2-7; COL-6 for Shiver Cluster (T2-8) and T2-4b's winter bodies | Verified: 2026-10-07

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
- Clearing (`comb_clean_cell`, Comb worker "maintain" mode) is today's only
  cleaning; a "corpse" is a dead larva in a cell. Adult bees vanish on
  death (`main.gd::_on_bee_died` places a presentation-only death marker).
- Rain runs only while `GameConfig.weather_on` (false by default) and the
  level row allow it (`main.gd`, weather advance). `bee_status.gd` keeps
  bees in above `rain_forage_limit`.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| T2-3 | Adaptive constancy becomes a bought behaviour | `scripts/skills.gd`, `scripts/bee_foraging.gd`, `tests/test_t2_3_adaptive_constancy.py`, `test_scenarios/t2_3_bought_constancy_test.json` | yes, after T2-2 in the same lane | low |
| T2-4a | Cleaning gates taking out the dead larvae | `scripts/actions.gd`, `scripts/challenge_stages.gd`, `scripts/skills.gd`, `tests/test_t2_4a_cleaning_gate.py` | no -- after T2-2 (`actions.gd`, `challenge_stages.gd`) | medium |
| T2-4b | Bees that die in the hive leave bodies; winter's dead appear at spring | specified after T2-4a | no -- after T2-4a, COL-4 (`game_config.gd`) and COL-6 (the winter bill) | high |
| T2-5 | Weather sensing's rain half, Rain recall, and rain on in the Colony Run | specified when T2-3 lands | no -- its PE-2 arc rerun reads COL-4's year | medium |
| T2-6 | Associative learning: per-bee, per-species familiarity, saved | specified when T2-5 lands | no -- after COL-4 (`game_config.gd`, `settings_catalogue.gd`) | high |
| T2-7 | Tier-2 costs tuned so the first purchase lands around day 5 | specified when T2-1 to T2-3 and COL-4 have landed | no -- needs COL-4's year and the gates | medium |
| T2-8 | Shiver Cluster: the skill, the multiplied bill without it, the warning | specified when COL-6 lands | no -- after COL-6 (`plans/now/colony-run.md`) and T2-2 | high |

**Dependencies.** T2-1, T2-2 and T2-3 run in that order in the Claude lane:
T2-1 and T2-2 share `roles.gd`, `availability.gd` and `challenge_stages.gd`,
and each adds a test module. They depend on
nothing else. T2-4a follows T2-2 (`actions.gd`, `challenge_stages.gd`).
T2-4b needs a `GameConfig` cap (COL-4 holds `game_config.gd`) and COL-6's
winter bill. T2-6 and T2-7 wait for COL-4; T2-7 also for T2-1 to T2-3, whose
gates it prices. T2-8 waits for COL-6, whose one-step winter it multiplies.
NF-4 (`plans/now/nectar-fermentation.md`) adds a Colony tier-2 node; T2-7
re-prices it if it has landed by then. A new test module no longer edits
`tools/verify.ps1`, which finds them itself since 7 Oct 2026, so adding a
test puts no shared file in either lane.

**Reads.** A slice reads its own section below and the step 8 decisions in
`plans/design/progression.md` (`python tools/heading.py
plans/design/progression.md "11. Implementation sequence"`, step 8 only).

T2-1 shipped 2026-10-07; its specification is `plans/archive/T2-1_2026-10-07.md`.

T2-2 shipped 2026-10-07; its specification is `plans/archive/T2-2_2026-10-07.md`.

## T2-3 -- Adaptive constancy becomes a bought behaviour

<!-- LAYER: immediate-task -->

Level: low (one effect entry and one helper, the Tarsal secretions pattern).

**True now.** Adaptive constancy runs only when the
`adaptive_constancy_on` setting is on; buying the node changes nothing.

**True afterwards.** Its `skills.gd` entry carries
`[{"type": "enable_behaviour", "key": "adaptive_constancy_on"}]`, and
`bee_foraging.gd::adaptive_constancy_on()` (setting **or** owned, as
`tarsal_markers_on`) replaces the three direct reads. The skill's `status`
becomes `"existing"`, so the tree drops its "Not built yet" note.
`test_scenarios/t2_3_bought_constancy_test.json` buys it on day 1 with the
setting off and records constancy switches; the same run unbought records
none (AP-6's shape). `tests/test_t2_3_adaptive_constancy.py` runs both.

**Must not change.** Behaviour with the setting on.

```queue
**[Claude] T2-3 -- Adaptive constancy becomes a bought behaviour**
- Plan: `plans/now/tier-two.md` -- "T2-3 -- Adaptive constancy becomes a bought behaviour"
- Files: `scripts/skills.gd`, `scripts/bee_foraging.gd`, `tests/test_t2_3_adaptive_constancy.py`, `test_scenarios/t2_3_bought_constancy_test.json`
- Check: `python -m unittest tests.test_t2_3_adaptive_constancy` passes (bought with the setting off, a forager re-evaluates its species; unbought, none does); `tools/verify.ps1` is green
- Proof: `absent: scripts/bee_foraging.gd :: static func adaptive_constancy_on`
- Next after: T2-4a -- Cleaning gates taking out the dead larvae
```

## T2-4a -- Cleaning gates taking out the dead larvae

<!-- LAYER: immediate-task -->

Level: medium (a gate plus a stage-data move, the T2-2 pattern).

**True now.** `comb_clean_cell` has no skill gate, so a Clearing comb worker
always takes out dead larvae.

**True afterwards.** `comb_clean_cell` carries `skill.hive_mind.cleaning`;
Clearing without it only evicts stores. Challenge 2's stage 2.7 frees Backup
roles and Cleaning (moving Backup roles from 2.8), and the skill's status
becomes `existing`. `tests/test_t2_4a_cleaning_gate.py` checks the gate data
and the stage move.

**Must not change.** Behaviour with Cleaning owned.

```queue
**[Claude] T2-4a -- Cleaning gates taking out the dead larvae**
- Plan: `plans/now/tier-two.md` -- "T2-4a -- Cleaning gates taking out the dead larvae"
- Files: `scripts/actions.gd`, `scripts/challenge_stages.gd`, `scripts/skills.gd`, `tests/test_t2_4a_cleaning_gate.py`
- Check: `python -m unittest tests.test_t2_4a_cleaning_gate` passes; `tools/verify.ps1` is green
- Proof: `absent: scripts/actions.gd :: "skill": "skill.hive_mind.cleaning"`
- Next after: T2-5 -- Weather sensing's rain half
```

## Later slices -- outline only

<!-- LAYER: design -->

Each is specified, with its queue block and verified `Proof:`, when the
slice before it lands. The decisions they implement are in
`plans/design/progression.md` step 8 and section 5.6.

- **T2-4a** -- `comb_clean_cell` carries `skill.hive_mind.cleaning`; Clearing
  without it only evicts stores. Stage 2.7 frees Backup roles and Cleaning
  (moving Backup roles from 2.8). The skill's status becomes `existing`.
- **T2-4b** -- a body object per in-hive death, held in one saved list in
  `hive.gd` (additive save field; an old save loads with none), adding
  disease at `disease_per_corpse`; Clearing with Cleaning carries it out; a
  `GameConfig` cap drops the oldest. Winter's bill dead appear at spring
  (COL-6's hook). Runtime: bodies change on a death or a clear, never per
  frame; the disease sum reads the list's size.
- **T2-5** -- Weather sensing (`enable_behaviour`) makes bees read the rain
  target rather than its intensity before setting out; Rain recall sends
  every bee outside home at `rain_forage_limit`; the Colony Run's level row
  turns rain on over `weather_on`, and only rows that say so. PE-2's arc
  rerun first, its before/after recorded here.
- **T2-6** -- familiarity per bee per species, saved, raising handling
  speed to the step 8 intent and fading while the bee works other species;
  rates from a headless sweep. Runtime: updated on a flower visit only.
- **T2-7** -- one PE-2 arc sweep (`tools/pacing_gates.py`) prices the
  tier-2 recipes so a reasonable Colony Run's first tier-2 purchase lands
  around day 5; recorded with before/after.
- **T2-8** -- `skill.hive_mind.shiver_cluster` in `skills.gd` (Hive Mind
  tier 2, a free grid slot found by the grid validators); owned from the
  start by any run without `"run_type": "colony"`; COL-6's bill multiplied
  by a `GameConfig` value when unowned; `winter_panel.gd`'s forecast and a
  `problem_messages.gd` urgent entry while unowned.
