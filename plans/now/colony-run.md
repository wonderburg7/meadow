# Colony Run -- the flagship run's definition and first slices

Status: active | Owner: Dave / Claude Code | Next: COL-1 -- the goal shelf shows the Colony Run's next milestone (PE-2 landed with its evidence below; CR-2 landed: scripts/colony_milestones.gd records the day each milestone is first met, saved as an additive field) | Dependency: none; COL-1 then COL-2 follow CR-2, and the year (COL-4) waits for PE-2's evidence | Verified: 2026-10-03

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
- COL-3, a doomed Colony Run offering a checkpoint restore (§11):
  `game_over.gd` offers only Restart and Main menu today. Specified after
  COL-2.
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
| COL-1 | the goal shelf shows the Colony Run's next milestone | `scripts/colony_milestones.gd`, `scripts/main.gd`, `tests/test_conditions.py` | after CR-2 | medium |
| COL-2 | surviving the first winter and sending out a gyne wins the Colony Run | `scripts/colony_milestones.gd`, `scripts/main.gd`, `scripts/challenge_complete.gd`, `tests/test_conditions.py` | after COL-1 | medium |

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

## COL-1 -- the goal shelf shows the Colony Run's next milestone

<!-- LAYER: immediate-task -->

Level: medium (presentation over CR-2's facts, with an acceptance check).

**True now** (verified 3 Oct 2026 on branch claude/CR-2). CR-2's
`colony_milestones.gd` records the day each of §7's six milestones is first
met, and nothing shows them. The goal shelf (`hud.gd::set_challenge_goal`:
goal text, the last completed goal struck through, an optional bar) is fed
only by `challenge_runner.gd::_show_goal`, so it is hidden in every
non-Challenge run. Dave accepted CR-2's three readings of stable income,
post-winter recovery and winter readiness on 3 Oct 2026.

**True afterwards.**
- In a Colony Run the goal shelf shows the first milestone not yet met, in
  `MILESTONES` order, as a short player-facing goal (each milestone gains one,
  such as "Raise your first worker"), with the last milestone met struck
  through beneath it. No bar: a milestone has no single number.
- It refreshes when a milestone is newly met, at the start of the run and
  after a load -- never per frame.
- Once all six are met the shelf says so and stays up.
- Nothing changes in any other run.

**Must not change.** How the Challenge runner drives the shelf; the
milestones' conditions and recorded days (CR-2).

```queue
**[Claude] COL-1 -- the goal shelf shows the Colony Run's next milestone**
- Plan: `plans/now/colony-run.md` -- "COL-1 -- the goal shelf shows the Colony Run's next milestone"
- Files: `scripts/colony_milestones.gd`, `scripts/main.gd`, `tests/test_conditions.py`
- Check: `python -m unittest tests.test_conditions` proves every milestone has a goal text and the shelf text follows the first unmet milestone; a Godot boot is clean; `tools/verify.ps1` is green; Dave starts a Colony Run and sees "Raise your first worker" on the goal shelf, then the next milestone once a worker emerges
- Proof: `absent: scripts/main.gd :: colony_milestones.show_next`
- Next after: COL-2 -- surviving the first winter and sending out a gyne wins the Colony Run
```

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
- Next after: COL-3 -- a doomed Colony Run offers a checkpoint restore
```
