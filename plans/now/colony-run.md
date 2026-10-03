# Colony Run -- the flagship run's definition and first slices

Status: active | Owner: Dave / Claude Code | Next: COL-3 -- a doomed Colony Run offers its latest checkpoint (COL-2 landed: colony_milestones.check_victory records a victory day and opens challenge_complete.gd with Colony Run wording; COL-1 landed: the goal shelf shows the next milestone via colony_milestones.show_next; PE-2 landed with its evidence below; CR-2 landed: scripts/colony_milestones.gd records the day each milestone is first met, saved as an additive field) | Dependency: none; COL-2 follows COL-1, and the year (COL-4) waits for PE-2's evidence | Verified: 2026-10-03

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
- A gyne taking over from a dead queen (§11's "no gynes" half of doomed):
  not built in any run; COL-3 treats the queen's death as doom until it is.
- COL-4, the year (above): specified from PE-2's evidence once Dave settles
  its open questions.
- CR-2's readings, accepted by Dave on 3 Oct 2026 and shown by COL-1:
  *stable income* also asks that some nectar and pollen were collected in
  the window, or empty stores would meet it on day 5; *post-winter
  recovery* reads "an egg has been laid" as egg-stage brood after winter,
  since no owner counts lays; *winter readiness* is the winter window's
  "On track" test judged only on the countdown's last day. The first check
  is the first hook (a birth, death, gyne or day change), so a milestone
  true from the start records day 2 at the latest. The state is
  `colony_milestones.met_days` (id to day) and `day_met(id)`.

## Open slices at a glance

<!-- LAYER: immediate-task -->

| Id | Slice | Files | Startable | Level |
| --- | --- | --- | --- | --- |
| COL-2 | surviving the first winter and sending out a gyne wins the Colony Run | `scripts/colony_milestones.gd`, `scripts/main.gd`, `scripts/challenge_complete.gd`, `tests/test_conditions.py` | after COL-1 | medium |
| COL-3 | a doomed Colony Run offers its latest checkpoint | `scripts/game_over.gd`, `scripts/main.gd`, `scripts/saves_panel.gd` | after COL-2 (shares `main.gd`) | medium |

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

## COL-2 -- surviving the first winter and sending out a gyne wins the Colony Run

<!-- LAYER: immediate-task -->

Level: medium (one end-of-run beat, with an acceptance check).

**True now** (verified 3 Oct 2026). No run has a victory. `challenge_complete.gd`
is the Challenges' pause-and-celebrate screen, with "Continue playing" and
"Main menu" (decision 3's Continue and End), opened by
`challenge_runner.gd` with a headline and flavour text; `main.gd` wires its
Continue to close it and unpause. `season.gd` emits `gyne_released`, and
CR-2's evaluator already runs on it.

**True afterwards.**
- A Colony Run is won the first time a gyne leaves after the first winter
  has ended with the queen alive (decision 3). A gyne released before winter
  does not count.
- Winning records a `victory` day alongside the milestones, in CR-2's saved
  record, so a load never shows the screen twice and needs no new save field.
- On the win, `challenge_complete.gd` opens with Colony Run wording: Continue
  keeps the run going, Main menu ends it.

**Must not change.** The Challenges' use of `challenge_complete.gd`; any
other run; the milestones (CR-2) and the shelf (COL-1).

**Escalate** if `challenge_complete.gd`'s wiring is Challenge-specific in a
way that a headline and flavour cannot cover.

```queue
**[Claude] COL-2 -- surviving the first winter and sending out a gyne wins the Colony Run**
- Plan: `plans/now/colony-run.md` -- "COL-2 -- surviving the first winter and sending out a gyne wins the Colony Run"
- Files: `scripts/colony_milestones.gd`, `scripts/main.gd`, `scripts/challenge_complete.gd`, `tests/test_conditions.py`
- Check: `python -m unittest tests.test_conditions` proves a gyne before winter does not win, one after winter with the queen alive does, and a recorded victory is not shown again after a load; a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `absent: scripts/challenge_complete.gd :: Colony Run`
- Next after: COL-3 -- a doomed Colony Run offers its latest checkpoint
```

## COL-3 -- a doomed Colony Run offers its latest checkpoint

<!-- LAYER: immediate-task -->

Level: medium (one screen and the existing load path, with an acceptance check).

**True now** (verified 3 Oct 2026). `main.gd::_check_for_loss` ends the run
the moment the queen dies (HO-10, HO-13) and opens `game_over.gd`, which
offers Restart and Main menu only. The Colony Run checkpoints every few days
into three rolling slots (`saving.gd::checkpoint`, `save_slots.gd`), and the
Saves window loads one through `saves_panel.gd::_load`, which already puts
back the settings and, since CR-1, the run's level. No gyne can take over
from a dead queen in any run today, so §11's "doomed" (the queen dead and no
gynes) is, for now, the queen dead.

**True afterwards.**
- In a Colony Run with at least one checkpoint, the game-over screen also
  offers "Load the latest checkpoint", naming its day. It loads through the
  same path the Saves window uses -- reused, not copied
  (`plans/README.md` rule 4) -- so the run comes back as it was on that day.
- With no checkpoint yet, or in any other run, the screen is unchanged.

**Must not change.** When a run is lost; checkpoint timing and rotation;
Restart and Main menu; Challenge and Scenario game-over screens.

**Escalate** if reusing the Saves window's load path would mean moving it to
a new owner shared by both screens.

```queue
**[Claude] COL-3 -- a doomed Colony Run offers its latest checkpoint**
- Plan: `plans/now/colony-run.md` -- "COL-3 -- a doomed Colony Run offers its latest checkpoint"
- Files: `scripts/game_over.gd`, `scripts/main.gd`, `scripts/saves_panel.gd`
- Check: a Godot boot is clean; `tools/verify.ps1` is green; Dave loses a Colony Run after its first checkpoint and the game-over screen offers the latest checkpoint by day, which loads the run as it was; a Scenario's game-over screen is unchanged
- Proof: `absent: scripts/game_over.gd :: checkpoint`
- Next after: COL-4 -- one calendar for flowers and gynes, counted from the end of winter
```
