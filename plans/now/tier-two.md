# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: T2-4b -- bodies, queued in the Claude lane (specified 9 Oct 2026, after T2-8b landed); T2-6 -- Associative learning waits for Dave's decision | Dependency: COL-4, COL-6 and T2-4a landed; T2-6 waits for Dave; T2-7 is still to be specified | Verified: 2026-10-09

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
| T2-4b | Bees that die in the hive leave bodies; winter's dead appear at spring | `scripts/hive_body.gd`, `scripts/hive.gd`, `scripts/bee_survival.gd`, `scripts/season.gd`, `scripts/bee_building.gd`, `scripts/bee.gd`, `scripts/actions.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/t2_4b_bodies_test.gd`, `tests/test_t2_4b_bodies.py` | yes -- T2-4a and COL-6 have landed; queued after SI-3 and NF-2, which share the save files and `hive.gd` | high |
| T2-6 | Associative learning: per-bee, per-species familiarity, saved | `scripts/skills.gd`, `scripts/bee.gd`, `scripts/bee_foraging.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_t2_6_associative_learning.py`, `tests/t2_6_associative_learning_test.gd` | no -- rate and save acceptance need specification | high |
| T2-7 | Tier-2 costs tuned so the first purchase lands around day 5 | specified when T2-1 to T2-3 and COL-4 have landed | no -- needs COL-4's year and the gates | medium |

**Dependencies.** T2-1, T2-2 and T2-3 run in that order in the Claude lane:
T2-1 and T2-2 share `roles.gd`, `availability.gd` and `challenge_stages.gd`,
and each adds a test module. They depend on
nothing else. T2-4a follows T2-2 (`actions.gd`, `challenge_stages.gd`).
T2-4b (COL-4 and COL-6 have landed) shares `hive.gd`, `save_game.gd` and
`saving.gd` with SI-3 (`plans/now/save-integrity.md`) and NF-2
(`plans/now/nectar-fermentation.md`), all in the Claude lane, so it runs after
them; Bee Bread's BB-1 (`plans/now/bee-bread.md`) shares the same files.
T2-6 and T2-7 wait for COL-4; T2-7 also for T2-1 to T2-3, whose
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

T2-5 shipped 2026-10-09; its specification is `plans/archive/T2-5_2026-10-09.md`.

## T2-4b -- Bees that die in the hive leave bodies; winter's dead appear at spring

<!-- LAYER: immediate-task -->

Level: high (a saved field with its old-save default, and a gameplay rule).
Implements `plans/design/progression.md` step 8, "Bodies" (Dave, 7 Oct 2026).

**True now** (verified 9 Oct 2026). An adult bee vanishes on death:
`bee_survival.gd::die` emits `bee_died`, whose listener
(`main.gd::_on_bee_died`) places a presentation-only death marker. The only
"corpse" is a dead larva in a cell; `season.gd::_advance_disease` counts
`cells_holding("corpse")` at `GameConfig.disease_per_corpse`, and Clearing
(`actions.gd` `comb_clean_cell`, gated on Cleaning since T2-4a) clears those
cells through `bee_building.gd::architect_clean` and the waste-exit walk.
The skipped winter's losses die through `BeeSurvival.die` inside
`season.gd::_resolve_winter`, just before the clock jumps to spring.

**True afterwards.**

- A bee that dies inside the hive leaves a body: a small node
  (`scripts/hive_body.gd`) at the point where she fell, blocking no cell,
  held in one list on `hive.gd`. A bee that dies in the meadow leaves
  nothing. Every bee the winter bill takes leaves one, at the nearest
  walkable point inside if she was outside, so they lie there at spring.
  `death_marker.gd` stays presentation only and unchanged.
- Disease counts bodies at a dead larva's rate:
  `season.gd::_advance_disease` adds the list's size to the corpse count.
- With Cleaning owned, a Comb worker in Clearing mode carries a body out
  through the existing waste-exit walk; dead-larva cells keep their priority
  over bodies. This extends `comb_clean_cell`'s cleaning path rather than
  adding a parallel job. Without Cleaning, bodies stay.
- `GameConfig.max_hive_bodies` (with its `settings_catalogue.gd` entry) caps
  the list; past it the oldest body goes. Its value comes from a headless
  count recorded in this section: the most bodies a colony without Cleaning
  holds over `test_scenarios/col6_winter_skip_test.json`, rounded up, so the
  cap guards against unbounded growth and never changes an ordinary run.
- Bodies are saved as an additive field (position and time of death each)
  and restored by `saving.gd`, including the in-place checkpoint restore
  SI-2 made exact: a restore replaces the list, never adds to it. An older
  save loads with no bodies (`.claude/rules/saving.md`).
- Runtime: the list changes on a death, a clear or the cap, never per frame;
  the disease tick reads its size.

**Must not change.** Dead-larva cells and their clearing order; a meadow
death; the death marker; `scripts/colony_diagnostics.gd` (Codex lane, CD-3),
which keeps counting corpse cells only.

**Check.** `tests/t2_4b_bodies_test.gd`, run by `tests/test_t2_4b_bodies.py`
in a headless Godot, prints `T2-4B PASS` when: an in-hive death leaves one
body and a meadow death none; bodies raise disease as dead larvae do; a
Comb worker with Cleaning carries one out and one without leaves it; the cap
drops the oldest; and bodies survive a save and load, an in-place checkpoint
restore leaves the saved count, and an old save loads with none.

```queue
**[Claude] T2-4b -- Bees that die in the hive leave bodies; winter's dead appear at spring**
- Plan: `plans/now/tier-two.md` -- "T2-4b -- Bees that die in the hive leave bodies; winter's dead appear at spring"
- Files: `scripts/hive_body.gd`, `scripts/hive.gd`, `scripts/bee_survival.gd`, `scripts/season.gd`, `scripts/bee_building.gd`, `scripts/bee.gd`, `scripts/actions.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/t2_4b_bodies_test.gd`, `tests/test_t2_4b_bodies.py`
- Check: `python -m unittest tests.test_t2_4b_bodies` passes with `T2-4B PASS`; `python tools/run_scenario.py test_scenarios/col6_winter_skip_test.json` passes; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/game_config.gd :: max_hive_bodies`
- Next after: T2-6 -- Associative learning
```

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
- Next after: T2-7 -- Tier-2 costs tuned so the first purchase lands around day 5
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
- **T2-7** -- one PE-2 arc sweep (`tools/pacing_gates.py`) prices the
  tier-2 recipes so a reasonable Colony Run's first tier-2 purchase lands
  around day 5; recorded with before/after.
