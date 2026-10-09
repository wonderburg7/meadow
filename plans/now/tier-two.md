# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: T2-5 -- Weather sensing's rain half, Rain recall, and rain on in the Colony Run | Dependency: COL-4 and COL-6 landed; T2-4b follows T2-4a; T2-6 follows T2-5 | Verified: 2026-10-08

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
| T2-4b | Bees that die in the hive leave bodies; winter's dead appear at spring | to be specified now T2-4a has landed (8 Oct 2026) | no -- not yet specified; T2-4a and COL-6 have landed | high |
| T2-5 | Weather sensing's rain half, Rain recall, and rain on in the Colony Run | `scripts/skills.gd`, `scripts/bee_status.gd`, `scripts/bee_foraging.gd`, `scripts/bee.gd`, `scripts/main.gd`, `scripts/levels.gd`, `tests/test_t2_5_rain_skills.py`, `tests/t2_5_rain_skills_test.gd` | yes -- COL-4 and T2-3 landed | medium |
| T2-6 | Associative learning: per-bee, per-species familiarity, saved | specified when T2-5 lands | no -- after COL-4 (`game_config.gd`, `settings_catalogue.gd`) | high |
| T2-7 | Tier-2 costs tuned so the first purchase lands around day 5 | specified when T2-1 to T2-3 and COL-4 have landed | no -- needs COL-4's year and the gates | medium |
| T2-8b | Shiver Cluster, the skill: the node, and owned at run start outside the Colony Run | `scripts/skills.gd`, `scripts/run_availability.gd`, `tests/test_t2_8a_shiver_bill.py`, `tests/test_t2_8b_shiver_skill.py` | no -- after T2-5 (Codex lane, `skills.gd`; T2-4a landed 8 Oct 2026); specified, fenced `queue-gated` | medium |

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

COL-4 shipped 2026-10-07; its specification is `plans/archive/COL-4_2026-10-07.md`.

T2-4a shipped 2026-10-08; its specification is `plans/archive/T2-4a_2026-10-08.md`.

## T2-5 -- Weather sensing's rain half, Rain recall, and rain on in the Colony Run

<!-- LAYER: immediate-task -->

Level: medium (bounded rain behaviour and run-specific weather policy).

**True now.** `bee_status.gd::grounded` stops new trips only when current rain
intensity passes `rain_forage_limit`. Bees already outside continue their work.
`main.gd::_advance_weather` requires `GameConfig.weather_on`, so the Colony
Run's level row cannot turn rain on when the global setting is off. Weather
sensing and Rain recall are authored in `skills.gd` but have no effect.

**True afterwards.** With Weather sensing owned, the departure check reads
the approaching `main.gd::rain_target` at the same forage limit; without it,
the check still reads current intensity. With Rain recall owned, bees already
outside head home when current intensity passes that limit. Neither skill
changes nectar dilution or flight cost. The Colony Run row explicitly enables
rain even if `GameConfig.weather_on` is false. Challenge rows keep rain off;
Scenario rows without a weather override still follow the setting. The two
skills become `existing` in the tree. Run PE-2's three-seed arc before and
after and record any pacing change here.

**Must not change.** Current rain safety without either skill, save fields for
weather, and the existing weather behaviour of Challenges and Scenarios.

```queue
**[Codex] T2-5 -- Weather sensing's rain half, Rain recall, and rain on in the Colony Run**
- Plan: `plans/now/tier-two.md` -- "T2-5 -- Weather sensing's rain half, Rain recall, and rain on in the Colony Run"
- Files: `scripts/skills.gd`, `scripts/bee_status.gd`, `scripts/bee_foraging.gd`, `scripts/bee.gd`, `scripts/main.gd`, `scripts/levels.gd`, `tests/test_t2_5_rain_skills.py`, `tests/t2_5_rain_skills_test.gd`
- Check: `python -m unittest tests.test_t2_5_rain_skills` passes (owned and unowned departures, outside recall, level weather policy); `python tools/pacing_gates.py` before and after is recorded here; `tools/verify.ps1` is green
- Proof: `absent: scripts/bee_status.gd :: WEATHER_SENSING`
- Next after: T2-6 -- Associative learning
```

T2-8a shipped 2026-10-08; its specification is `plans/archive/T2-8a_2026-10-08.md`.

## T2-8b -- Shiver Cluster, the skill

<!-- LAYER: immediate-task -->

Level: medium (one catalogue row and one derived starting rule; the bill and
the warning already exist). Gated: `scripts/skills.gd` is held by T2-5 in the
Codex lane (T2-4a, which held it first, landed 8 Oct 2026). The design is `plans/design/progression.md` "Shiver Cluster".

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
- **T2-8b** -- specified above, fenced `queue-gated` until T2-5 frees `skills.gd`.
