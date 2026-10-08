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
| T2-4a | Cleaning gates taking out the dead larvae | `scripts/actions.gd`, `scripts/challenge_stages.gd`, `scripts/skills.gd`, `tests/test_t2_4a_cleaning_gate.py` | yes (T2-2 landed 7 Oct 2026); Codex lane (Dave, 7 Oct 2026) | medium |
| T2-4b | Bees that die in the hive leave bodies; winter's dead appear at spring | specified after T2-4a | no -- after T2-4a (COL-6 landed 7 Oct 2026) | high |
| T2-5 | Weather sensing's rain half, Rain recall, and rain on in the Colony Run | specified when T2-3 lands | no -- its PE-2 arc rerun reads COL-4's year | medium |
| T2-6 | Associative learning: per-bee, per-species familiarity, saved | specified when T2-5 lands | no -- after COL-4 (`game_config.gd`, `settings_catalogue.gd`) | high |
| T2-7 | Tier-2 costs tuned so the first purchase lands around day 5 | specified when T2-1 to T2-3 and COL-4 have landed | no -- needs COL-4's year and the gates | medium |
| T2-8b | Shiver Cluster, the skill: the node, and owned at run start outside the Colony Run | `scripts/skills.gd`, `scripts/run_availability.gd`, `tests/test_t2_8a_shiver_bill.py`, `tests/test_t2_8b_shiver_skill.py` | no -- after T2-4a (Codex lane, `skills.gd`); specified, fenced `queue-gated` | medium |

**Dependencies.** T2-1, T2-2 and T2-3 run in that order in the Claude lane:
T2-1 and T2-2 share `roles.gd`, `availability.gd` and `challenge_stages.gd`,
and each adds a test module. They depend on
nothing else. T2-4a follows T2-2 (`actions.gd`, `challenge_stages.gd`).
T2-4b needs a `GameConfig` cap (COL-4 holds `game_config.gd`) and COL-6's
winter bill. T2-6 and T2-7 wait for COL-4; T2-7 also for T2-1 to T2-3, whose
gates it prices. T2-8 multiplies COL-6's one-step winter (landed 7 Oct 2026).
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
**[Codex] T2-4a -- Cleaning gates taking out the dead larvae**
- Plan: `plans/now/tier-two.md` -- "T2-4a -- Cleaning gates taking out the dead larvae"
- Files: `scripts/actions.gd`, `scripts/challenge_stages.gd`, `scripts/skills.gd`, `tests/test_t2_4a_cleaning_gate.py`
- Check: `python -m unittest tests.test_t2_4a_cleaning_gate` passes; `tools/verify.ps1` is green
- Proof: `absent: scripts/actions.gd :: "skill": "skill.hive_mind.cleaning"`
- Next after: T2-5 -- Weather sensing's rain half
```

T2-8a shipped 2026-10-08; its specification is `plans/archive/T2-8a_2026-10-08.md`.

## T2-8b -- Shiver Cluster, the skill

<!-- LAYER: immediate-task -->

Level: medium (one catalogue row and one derived starting rule; the bill and
the warning already exist). Gated: `scripts/skills.gd` is held by T2-4a in the
Codex lane. The design is `plans/design/progression.md` "Shiver Cluster".

**True now (after T2-8a).** `season.gd::owns_shiver_cluster` asks
`progression.gd::is_owned_or_absent`, which answers owned while the catalogue
has no `skill.hive_mind.shiver_cluster`; the moment the node exists it is
plain ownership, and `winter_bill`,
`winter_panel.gd`'s note and `problem_messages.gd`'s `winter_unclustered`
row all follow it. `tests/test_t2_8a_shiver_bill.py` reaches the unowned path
through `season.gd`'s `shiver_cluster_skill` seam and asserts the node is
absent (`ABSENT_EXISTS false`).

**True afterwards.**
- `skill.hive_mind.shiver_cluster` is a Hive Mind tier-2 node in `skills.gd`,
  beside Automation and Cleaning, reached through Backup roles, in a free grid
  slot the grid validators accept, costing honey like every tier-2 node (the
  price is T2-7's to tune).
- `run_availability.gd::sheet_for` puts it in `"starting"` for every run whose
  definition has no `"run_type": "colony"`, derived like "seeding implies
  owning"; no level lists it by hand. A `skill_bans` entry still wins.
- So the Colony Run without it pays the multiplied bill and sees the warning;
  Scenarios and Challenges play as today.
- `tests/test_t2_8a_shiver_bill.py`'s absent-node case becomes "owned at the
  start of a non-Colony run"; its unowned cases use the real id.

**Hands-on.** Filed by this slice: in a Colony Run, open the Winter window
when the countdown starts and see the Shiver Cluster note and the doubled
figure; buy the node and see both go.

```queue-gated
**[Claude] T2-8b -- Shiver Cluster, the skill**
- Plan: `plans/now/tier-two.md` -- "T2-8b -- Shiver Cluster, the skill"
- Files: `scripts/skills.gd`, `scripts/run_availability.gd`, `tests/test_t2_8a_shiver_bill.py`, `tests/test_t2_8b_shiver_skill.py`
- Check: `python -m unittest tests.test_t2_8b_shiver_skill tests.test_t2_8a_shiver_bill` passes (the node is Hive Mind tier 2 behind Backup roles; a level row without `"run_type": "colony"` starts owning it and the Colony Run does not; the Colony Run's `winter_bill` is the multiplied one until it is bought); a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `absent: scripts/skills.gd :: shiver_cluster`
- Next after: T2-4b -- Bees that die in the hive leave bodies; winter's dead appear at spring
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
- **T2-8b** -- specified above, fenced `queue-gated` until T2-4a frees `skills.gd`.
