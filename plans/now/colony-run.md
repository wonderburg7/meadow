# Colony Run -- the flagship run's definition and first slices

Status: active | Owner: Dave / Claude Code | Next: COL-5 -- level rows lose the two keys nothing reads (COL-3 landed: game_over.gd offers the latest checkpoint of a Colony Run through saves_panel.gd::reload_from; COL-2 landed: colony_milestones.check_victory records a victory day and opens the win screen with Colony Run wording; COL-1 landed: the goal shelf shows the next milestone via colony_milestones.show_next; PE-2 landed with its evidence below; CR-2 landed: scripts/colony_milestones.gd records the day each milestone is first met, saved as an additive field) | Dependency: none; COL-2 follows COL-1, and the year (COL-4, decisions 5-10) is queued | Verified: 2026-10-03

This is the design pass that `plans/design/product-scope.md` §6.2 put next
(Dave, 30 Sep 2026): run policy for the flagship Colony Run. It ran on 3 Oct
2026 **without the 3-4 Oct feedback session's notes** (Dave, 3 Oct 2026, so
the lane would not run dry). When those notes arrive, re-read the decisions
below against them before COL-2 ships.

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

- **The year** -- settled 4 Oct 2026; see "The year" below.
- Level 0 and the six "World & start" settings. (The `win_conditions` and
  `unlocks` keys nothing reads go in COL-5.)
- §7's short-term goals (the Dr Gallerin guidance pass owns them) and urgent
  problems (today's problem strip and signal catalogue already cover them).
- Difficulty presets for the Colony Run.
- A gyne taking over from a dead queen (§11's "no gynes" half of doomed):
  not built in any run; COL-3 treats the queen's death as doom until it is.
- COL-6's open question: how a skipped winter is charged, and who dies,
  before Shiver Cluster exists.
- CR-2's readings, accepted by Dave on 3 Oct 2026 and shown by COL-1:
  *stable income* also asks that some nectar and pollen were collected in
  the window, or empty stores would meet it on day 5; *post-winter
  recovery* reads "an egg has been laid" as egg-stage brood after winter,
  since no owner counts lays; *winter readiness* is the winter window's
  "On track" test judged only on the countdown's last day. The first check
  is the first hook (a birth, death, gyne or day change), so a milestone
  true from the start records day 2 at the latest. The state is
  `colony_milestones.met_days` (id to day) and `day_met(id)`.

## The year (Dave, 4 Oct 2026)

<!-- LAYER: design -->

Settled after PE-2's arc landed (three seeds from the Colony Run's start: two
lived, one starved on day 32; no honey was ever made). These supersede the
"year" bullet under "Still open" and §6.2's 30 Sep framing of it.

5. **Four seasons, and winter is not played.** A year runs spring, summer,
   autumn, then winter. Winter is not a playable stretch: the run skips from
   the end of autumn to the start of spring. Winter may later get an activity
   of its own (not yet designed). Every year has a full bloom curve before
   winter.
6. **Editable lengths.** The year's length and a day's length are settings,
   so changing either later breaks nothing. For now a year is 40 days: 30
   playable (spring to autumn) and 10 of winter.
7. **Mating and genetic credit.** A gyne may leave at any time. Genetic credit
   follows a curve from late spring to early autumn, peaking in mid summer.
   A gyne leaving outside that window is lost without mating: shown, but no
   victory (this narrows COL-2's win) and no credit.
8. **Winter flowers.** Plants die back over winter and regrow over the first
   days of spring.
9. **Shiver Cluster.** A skill (Colony or Hive Mind tree) in which bees
   surround the queen and shiver to keep her warm through winter. It is the
   colony's main winter energy cost and what the player gathers for; without
   it a colony does not survive winter. It starts a future thermoregulation
   thread. Its tree, cost and numbers belong to `plans/design/progression.md`.
10. **Genetic points** are counted and saved now, and spent later.

**Order.** COL-4 (the calendar) first. Then, each specified when the one
before it lands: COL-6 winter is skipped and resolved in one step (open: how
winter's cost is charged, and who dies, before Shiver Cluster exists);
COL-7 the mating window, genetic points and COL-2's narrower win; COL-8
winter die-back and spring regrowth; Shiver Cluster through the progression
plan. Every one of them changes balance, so each is simulated first with
PE-2's arc (`tools/pacing_gates.py`).

## Open slices at a glance

<!-- LAYER: immediate-task -->

| Id | Slice | Files | Startable | Level |
| --- | --- | --- | --- | --- |
| COL-5 | level rows lose the two keys nothing reads | `scripts/levels.gd`, `scripts/main.gd`, `test_scenarios/bs4_honey_gate_test.json`, `test_scenarios/colony_30_bees_test.json` | after COL-3 (shares `main.gd`) | low |
| COL-4 | one editable year: thirty playable days, then winter | `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/flower.gd`, `scripts/flower_species.gd`, `scripts/season.gd`, `scripts/world_building.gd`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py` | yes | high |

**Dependencies.** CR-1 then CR-2, one after the other in the Claude lane:
both edit `scripts/save_game.gd` and `tests/test_save_migrations.py`. PE-2
plays CR-1's start state. `plans/now/brood-spine.md`'s BS-6 also edits
`scripts/main.gd`; whichever lands second rebases.

**Ids.** This plan reuses the ids CR-1 and CR-2 from two slices archived on
8-9 Sep 2026 under an earlier plan: the queue had claimed CR-1 before the
clash surfaced, and `tools/slice.ps1 finish`'s archive gate tells the records
apart by heading. Later slices take the COL- prefix, since CR-3 to CR-7 have archive records too.

CR-1 shipped 2026-10-03; its specification is `plans/archive/CR-1_2026-10-03.md`.

CR-2 shipped 2026-10-03; its specification is `plans/archive/CR-2_2026-10-03.md`.

PE-2 shipped 2026-10-03; its specification is `plans/archive/PE-2_2026-10-03.md`.

COL-1 shipped 2026-10-03; its specification is `plans/archive/COL-1_2026-10-03.md`.

COL-2 shipped 2026-10-03; its specification is `plans/archive/COL-2_2026-10-03.md`.

COL-3 shipped 2026-10-04; its specification is `plans/archive/COL-3_2026-10-04.md`.

## COL-5 -- level rows lose the two keys nothing reads

<!-- LAYER: immediate-task -->

Level: low (mechanical removal across one data file, its one writer and two fixtures).

**True now** (verified 3 Oct 2026 by grep). Every `levels.gd` row carries
`"unlocks": []` and `"win_conditions": []`; `main.gd`'s scenario setup
defaults both on a scenario's row; `test_scenarios/bs4_honey_gate_test.json`
and `colony_30_bees_test.json` set them empty. Nothing in `scripts/`,
`tests/` or `tools/` reads either. The Colony Run's goals are CR-2's
milestones and COL-2's victory (decision 4), so neither key has a future
owner here; Challenges keep their goals in `challenge_runner.gd`.

**True afterwards.** Neither key appears in `scripts/` or `test_scenarios/`,
and `levels.gd`'s header no longer describes them. No run, scenario or save
behaves differently.

```queue
**[Claude] COL-5 -- level rows lose the two keys nothing reads**
- Plan: `plans/now/colony-run.md` -- "COL-5 -- level rows lose the two keys nothing reads"
- Files: `scripts/levels.gd`, `scripts/main.gd`, `test_scenarios/bs4_honey_gate_test.json`, `test_scenarios/colony_30_bees_test.json`
- Check: `grep -rn "win_conditions" scripts test_scenarios` and the same for `"unlocks"` find nothing; a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `present: scripts/levels.gd :: "win_conditions"`
- Next after: COL-4 -- one calendar for flowers and gynes, counted from the end of winter
```

## COL-4 -- one editable year: thirty playable days, then winter

<!-- LAYER: immediate-task -->

Level: high (the run's clock, a balance change, and saved settings).

**True now** (verified 4 Oct 2026). Flowers follow
`flower.gd::season_fraction`, a `season_length_days` (60) cycle from day 1
that never hears about winter; `season.gd::_gyne_season` reads the same
fraction against `gyne_release_day` (0.75). Winter is WO-1's: the countdown
opens on `winter_countdown_start_day` (6), lasts `winter_countdown_days`
(15), and winter lasts `winter_length_days` (20), so it falls on days 21 to
41, in the flowers' spring, and once per run. `season_length_days` is also
read by `flower_species.gd` and `world_building.gd`, and is a saved setting.
`tools/pacing_gates.py` hard-codes winter on days 21 and 41.

**True afterwards.**
- One year clock (decisions 5-6): a year is the playable season
  (`season_length_days`, default 30) followed by winter
  (`winter_length_days`, default 10). The season fraction runs 0 to 1 over
  the playable days and restarts at each winter's end, so every year has its
  full bloom curve before winter. Spring, summer and autumn are its thirds.
- Winter arrives at the end of each year's playable days, every year, and
  the countdown opens `winter_countdown_days` before it. Winter's onset is
  derived from the year, so `winter_countdown_start_day` goes (or becomes
  derived); the settings window edits the two lengths and day length, each
  safely. Winter is still played, as today; COL-6 skips it.
- With the defaults, year 1's winter falls on days 31 to 41.
- A save keeps its own saved lengths, so an old save keeps its 60-day year.
- `pacing_gates.py` reads winter's days from the year instead of constants.
  PE-2's arc is run before and after, and the plan records both.

**Must not change.** How winter is simulated while it lasts; CR-2's
milestones and COL-2's win (both read winter through `Session`); any
Challenge (`seasons_on` and its own levels).

**Escalate** if the arc's survival drops sharply against PE-2's record (two
seeds of three), or if deriving onset would change a Challenge.

```queue
**[Claude] COL-4 -- one editable year: thirty playable days, then winter**
- Plan: `plans/now/colony-run.md` -- "COL-4 -- one editable year: thirty playable days, then winter"
- Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/flower.gd`, `scripts/flower_species.gd`, `scripts/season.gd`, `scripts/world_building.gd`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
- Check: `python -m unittest tests.test_pacing_gates` passes; `python tools/pacing_gates.py` before and after shows winter on days 31 to 41 and the plan records both; a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `present: scripts/game_config.gd :: var season_length_days: float = 60.0`
- Next after: COL-6 -- winter is skipped and resolved in one step
```
