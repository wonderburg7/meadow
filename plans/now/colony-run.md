# Colony Run -- the flagship run's definition and first slices

Status: active | Owner: Dave / Claude Code | Next: CR-1 -- a Colony Run can be started from the menu, and a save remembers which run it is | Dependency: none; PE-2 waits for CR-1, and the year waits for PE-2's evidence | Verified: 2026-10-03

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
  once the evaluator's facts exist to show.

## Open slices at a glance

<!-- LAYER: immediate-task -->

| Id | Slice | Files | Startable | Level |
| --- | --- | --- | --- | --- |
| CR-1 | a Colony Run can be started from the menu, and a save remembers which run it is | `scripts/levels.gd`, `scripts/main_menu.gd`, `scripts/save_game.gd`, `scripts/save_migrations.gd`, `scripts/saves_panel.gd`, `scripts/debug_panel.gd`, `tests/test_save_migrations.py` | yes | high |
| CR-2 | the Colony Run records the day each milestone is first met | `scripts/colony_milestones.gd`, `scripts/conditions.gd`, `scripts/main.gd`, `scripts/save_game.gd`, `tests/test_conditions.py`, `tests/test_save_migrations.py` | after CR-1 (shares `save_game.gd`) | high |
| PE-2 | the played pacing arc (§6.2's bullet) | to be specified when CR-1 lands | after CR-1 | medium |

**Dependencies.** CR-1 then CR-2, one after the other in the Claude lane:
both edit `scripts/save_game.gd` and `tests/test_save_migrations.py`. PE-2
plays CR-1's start state. `plans/now/brood-spine.md`'s BS-6 also edits
`scripts/main.gd`; whichever lands second rebases.

## CR-1 -- a Colony Run can be started from the menu, and a save remembers which run it is

<!-- LAYER: immediate-task -->

Level: high (a save field and the load path).

**True now** (verified 3 Oct 2026 against master). No run type matches §2's
Colony Run: `levels.gd` holds Challenges 1-2, Scenario levels 3-7 and the
harness's `SCENARIO_LEVEL_ID` (999), and no row has a `run_type` key. A run
is `Session.starting_level`, set by `main.gd::_on_level_chosen` and
`_on_scenario_chosen`. `SaveGame.save` (`FORMAT_VERSION` 6) writes no
`starting_level`. A load sets `Session.load_path` (`saves_panel.gd`,
`debug_panel.gd`), and `main.gd` restores it after the world is rebuilt for
whichever level is current, so a save made in a Scenario and loaded after a
fresh boot comes back inside level 0's world.

**True afterwards.**
- `levels.gd` gains the Colony Run row at the next free id (8):
  `"run_type": "colony"`, `cells` 0, every worker count 0, winter on,
  `queen_laying_backup` `ORDINARY_QUEEN_BACKUP`, empty skill lists. No other
  row changes; a row without `run_type` behaves as today.
- The main menu's Scenarios strip leads with a "Colony Run" tile that starts
  level 8 through `_on_level_chosen` (no difficulty preset yet).
- A save records `starting_level`. Loading one sets `Session.starting_level`
  from it before the world is rebuilt, so a Colony Run save reloads as a
  Colony Run. A save without the field loads exactly as today. Whether
  `FORMAT_VERSION` moves, and the migration if it does, follow
  `.claude/rules/saving.md`.
- Checkpoints run in the Colony Run (`saving.gd::checkpoint` skips only
  levels 1 and 2; unchanged).

**Must not change.** Levels 1-7 and 999; every scenario fixture; how an
existing save loads; Challenge checkpoints (`tutorial_checkpoint.gd`).

**Escalate** if a run started at level 8 differs from decision 2 in anything
but its world layout, or if recording the level on a save would change how
any existing save loads.

```queue
**[Claude] CR-1 -- a Colony Run can be started from the menu, and a save remembers which run it is**
- Plan: `plans/now/colony-run.md` -- "CR-1 -- a Colony Run can be started from the menu, and a save remembers which run it is"
- Files: `scripts/levels.gd`, `scripts/main_menu.gd`, `scripts/save_game.gd`, `scripts/save_migrations.gd`, `scripts/saves_panel.gd`, `scripts/debug_panel.gd`, `tests/test_save_migrations.py`
- Check: `python -m unittest tests.test_save_migrations` proves a save written at level 8 restores `starting_level` 8 and a version-6 save without the field loads with the level unchanged; a Godot boot is clean; `tools/verify.ps1` is green; Dave starts a Colony Run from the menu, sees a lone queen and no comb, saves, reboots and loads back into a Colony Run
- Proof: `absent: scripts/levels.gd :: "run_type"`
- Next after: CR-2 -- the Colony Run records the day each milestone is first met
```

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
- Next after: PE-2 -- the played pacing arc starts from the Colony Run's start (CR-3, the milestone readout and the victory screen, is specified once CR-2 lands)
```
