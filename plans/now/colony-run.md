# Colony Run -- the flagship run's definition and first slices

Status: active | Owner: Dave / Claude Code | Next: PE-2 -- the played pacing arc starts from the Colony Run's start (CR-2 landed: scripts/colony_milestones.gd records the day each milestone is first met, saved as an additive field) | Dependency: none; CR-3 waits for PE-2, and the year waits for PE-2's evidence | Verified: 2026-10-03

This is the design pass that `plans/design/product-scope.md` §6.2 put next
(Dave, 30 Sep 2026): run policy for the flagship Colony Run. It ran on 3 Oct
2026 **without the 3-4 Oct feedback session's notes** (Dave, 3 Oct 2026, so
the lane would not run dry). When those notes arrive, re-read the decisions
below against them before CR-3 is specified.

## Decisions (Dave, 3 Oct 2026)

<!-- LAYER: design -->

1. **Identity.** The Colony Run is a `scripts/levels.gd` row carrying
   `"run_type": "colony"`. A save records `starting_level` as an additive
   field, and a save without it loads exactly as today. Run policy stays in
   level rows until a later consolidation earns its own catalogue.
2. **Start state.** A lone queen with no comb and no workers. She backs up as
   a Nurse (`plans/now/brood-spine.md` decision 5, `ORDINARY_QUEEN_BACKUP`),
   and builds the first cell herself as a Comb worker, a job her Job menu
   already offers (C-81). Winter is on.
3. **Victory, failure and continuing.** Victory: the colony survives its first
   winter and then releases a gyne in the next mating window. The victory
   screen offers Continue (play on across years) or End. Failure is §11's
   doomed state (the queen dead and no gynes), which offers a checkpoint
   restore rather than silently ending the run.
4. **Milestones.** A new evaluator over `scripts/conditions.gd` checks all of
   §7's milestones together. The Challenge stage runner stays Challenge-only.

**Taken as defaults, without a question** (from §2; revisit with the notes):
skill discovery for the early feedback run is the whole skill tree under its
existing stage gates, with no grants or bans.

## Still open -- not decided here

<!-- LAYER: design -->

- **The year** (§6.2's bullet, from `docs/gameplay-review-2026-09-30.md` F5):
  one calendar counting from the end of the last winter; how long flowers
  hold their floor, how the meadow regrows, any winter-flowering species, the
  mating window (Dave's working assumption: mid to late summer), drones and
  what genetic points buy. It changes balance, so PE-2's played arc is its
  evidence and comes first. Until then, decision 3's "next mating window" is
  today's `season.gd::_gyne_season`.
- Level 0 and the six "World & start" settings; the `win_conditions` and
  `unlocks` keys every `levels.gd` row carries and nothing reads.
- §7's short-term goals (the Dr Gallerin guidance pass owns them) and urgent
  problems (today's problem strip and signal catalogue already cover them).
- Difficulty presets for the Colony Run.
- CR-3, the milestone readout and the victory screen: specified after CR-2,
  once the evaluator's facts exist to show. CR-2 (3 Oct 2026) took three
  readings CR-3 should confirm with Dave before showing them: *stable income*
  also asks that some nectar and pollen were collected in the window, or a
  colony with empty stores meets it on day 5; *post-winter recovery* reads
  "an egg has been laid" as brood in its egg stage after winter, since no
  owner counts lays (an egg laid in winter's last days can count); *winter
  readiness* is the winter window's "On track" test judged only on the
  countdown's last day (to the boundary winter arrives on), so it describes
  the colony winter finds, not the one the countdown opened on; and the
  first check is the first hook (a birth, death, gyne or day change), so a
  milestone true from the start records day 2 at the latest. The milestones' state is `colony_milestones.met_days` (id to
  day) and `day_met(id)`.

## Open slices at a glance

<!-- LAYER: immediate-task -->

| Id | Slice | Files | Startable | Level |
| --- | --- | --- | --- | --- |
| CR-2 | the Colony Run records the day each milestone is first met | `scripts/colony_milestones.gd`, `scripts/conditions.gd`, `scripts/main.gd`, `scripts/save_game.gd`, `tests/test_conditions.py`, `tests/test_save_migrations.py` | after CR-1 (shares `save_game.gd`) | high |
| PE-2 | the played pacing arc starts from the Colony Run's start | `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py` | yes (CR-1 landed) | medium |

**Dependencies.** CR-1 then CR-2, one after the other in the Claude lane:
both edit `scripts/save_game.gd` and `tests/test_save_migrations.py`. PE-2
plays CR-1's start state. `plans/now/brood-spine.md`'s BS-6 also edits
`scripts/main.gd`; whichever lands second rebases.

**Ids.** This plan reuses the ids CR-1 and CR-2 from two slices archived on
8-9 Sep 2026 under an earlier plan: the queue had claimed CR-1 before the
clash surfaced, and `tools/slice.ps1 finish`'s archive gate tells the records
apart by heading. CR-3 onwards should take ids no archive record uses.

CR-1 shipped 2026-10-03; its specification is `plans/archive/CR-1_2026-10-03.md`.

## CR-2 -- the Colony Run records the day each milestone is first met

<!-- LAYER: immediate-task -->

Level: high (a second save field, and a new evaluator on two event hooks).

**True now** (verified 3 Oct 2026). `conditions.gd` evaluates condition
dictionaries for Challenge stages, with keys such as `role_count`,
`hive_total`, `skill_owned`, `event_count` and `all_of`; it has no key for a
rate of income. No run tracks milestones. `Skills.AUTOMATION`
(`skill.hive_mind.automation`) exists.

**True afterwards.**
- New `scripts/colony_milestones.gd` holds §7's six milestones as data, each
  a `conditions.gd` condition: first worker (a non-queen adult exists); first
  automation (`skill_owned` `Skills.AUTOMATION`); stable resource income (net
  nectar and pollen income non-negative over the last three days, through a
  new `conditions.gd` rate key); winter readiness (the winter panel's own
  readiness measure, met before winter begins); post-winter recovery (after
  winter ends, the queen is alive and an egg has been laid); first gyne (a
  gyne has left the hive).
- It runs only when the level's `run_type` is `"colony"`, on day change and
  on population change -- the hooks `main.gd` already has -- never per frame.
  It records the day each milestone is first met; a met milestone is never
  re-checked.
- The recorded days are saved as an additive field and restored on load; a
  save without it reads as nothing met.
- Before adding the rate key's history, find whether something already keeps
  per-day store totals and extend it (`plans/README.md` rule 4).

**Must not change.** Challenge stage evaluation; any non-Colony run; balance.

**Escalate** if the winter panel has no readiness measure to reuse, or if a
milestone needs a fact no existing owner provides.

```queue
**[Claude] CR-2 -- the Colony Run records the day each milestone is first met**
- Plan: `plans/now/colony-run.md` -- "CR-2 -- the Colony Run records the day each milestone is first met"
- Files: `scripts/colony_milestones.gd`, `scripts/conditions.gd`, `scripts/main.gd`, `scripts/save_game.gd`, `tests/test_conditions.py`, `tests/test_save_migrations.py`
- Check: `python -m unittest tests.test_conditions` covers the rate key; `python -m unittest tests.test_save_migrations` proves recorded milestone days survive a save and load; a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `absent: scripts/conditions.gd :: income`
- Next after: PE-2 -- the played pacing arc starts from the Colony Run's start
```

## PE-2 -- the played pacing arc starts from the Colony Run's start

<!-- LAYER: immediate-task -->

Level: medium (one scenario and its measuring tool, with an acceptance check).

**True now** (verified 3 Oct 2026). `test_scenarios/alpha_arc_test.json` is
an unplayed queen: no `actions`, no `queen_laying_backup`, one pinned
`random_seed` (20260923), and `stop.max_days` 44. A scenario's top-level keys
act as its level row (`main.gd`, where `Levels.scenario_override` is set), and
cells and forager counts default to 0, so its start is close to CR-1's but
not the same. `tools/pacing_gates.py::run` replays that one seed `--repeat`
times (default 3), so its three runs are one run three times. WO-1's winter
falls on days 21 to 41 (`plans/archive/winter-onset_2026-10-01.md`).

**True afterwards.**
- The arc starts as `levels.gd` row 8 does: its start keys (cells, worker
  counts, `winter`, `queen_laying_backup`) are copied into the scenario,
  since the harness has no key to borrow a level row.
- A scripted reference player drives it through `actions`, using only the
  `when` keys `scenario_actions.gd::_legacy_when_spec` honours: the queen
  builds the first cell, lays, and the player raises workers into the roles
  a colony needs as it grows. It plays plainly well, not optimally.
- The run stops after winter ends, not at a fixed 44 days.
- `pacing_gates.py` gives each repeat its own seed (the `--random-seed=`
  route `main.gd` already honours), and prints the seeds it used.
- Winter rows are judged against WO-1's schedule and a live colony (the
  queen alive and workers present after winter), not against 1x minutes.
- The evidence -- each seed's rows and whether the colony lived -- is
  recorded under this heading. It is what the year and GC-3
  (`plans/now/gameplay-consistency.md`) wait for.

**Must not change.** Simulation code, `GameConfig` defaults, every other
scenario, and `tests/test_pacing_gates.py`'s existing assertions beyond the
seed change.

**Escalate** if the reference player cannot bring a colony through winter on
any seed (a gameplay finding for Dave, not something to tune here), or if it
needs an action or `when` key the harness lacks.

```queue
**[Claude] PE-2 -- the played pacing arc starts from the Colony Run's start**
- Plan: `plans/now/colony-run.md` -- "PE-2 -- the played pacing arc starts from the Colony Run's start"
- Files: `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
- Check: `python -m unittest tests.test_pacing_gates` passes; `python tools/pacing_gates.py` runs three different seeds from the Colony Run's start, through winter, and the plan records each seed's rows and whether the colony lived; `tools/verify.ps1` is green
- Proof: `absent: test_scenarios/alpha_arc_test.json :: "actions"`
- Next after: CR-3 -- the milestone readout and the victory screen
```
