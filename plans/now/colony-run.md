# Colony Run -- the flagship run's definition and first slices

Status: active | Owner: Dave / Claude Code | Next: COL-12 -- the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns, Claude lane (a COL-4 integration finding, Dave 7 Oct 2026); COL-6 -- winter is skipped and resolved in one step, Claude lane (decision 11, Dave 5 Oct 2026); COL-11 -- nuptial flights: an unmated queen can leave each day to find a mate, Claude lane, after COL-6 since both edit `scripts/season.gd` (decision 12, Dave 5 Oct 2026) (COL-4 landed: a year is `season_length_days` (30) playable days then `winter_length_days` (10) of winter, both saved run settings; the flower fraction restarts after every winter, and winter recurs each year with its countdown derived by season.gd::_winter_countdown_day, so `winter_countdown_start_day` is gone; a level with winter off has a year of only its playable season (Session.year_has_winter, Session.year_days); SF-1's tolerance is 0.20 until COL-12; COL-10 landed: when the queen dies the oldest adult gyne becomes an unmated queen on Egg layer through main.gd::_promote_gyne_to_queen, before colony_lost is set, and succession_panel.gd explains it once; with no gyne the run ends as before; COL-9 landed: an unmated queen (bee.gd::is_mated, saved, true by default) lays drone brood that hatches an Idle drone through main.gd's emergence loop, and set_role refuses him any other job; COL-5 landed: level rows no longer carry the unread unlocks and win_conditions keys; COL-3 landed: game_over.gd offers the latest checkpoint of a Colony Run through saves_panel.gd::reload_from; COL-2 landed: colony_milestones.check_victory records a victory day and opens the win screen with Colony Run wording; COL-1 landed: the goal shelf shows the next milestone via colony_milestones.show_next; PE-2 landed with its evidence below; CR-2 landed: scripts/colony_milestones.gd records the day each milestone is first met, saved as an additive field) | Dependency: none; COL-2 follows COL-1, and the year (COL-4, decisions 5-10) is queued in the Codex lane after GC-3, which shares `scripts/game_config.gd` and `scripts/settings_catalogue.gd` (Dave, 4 Oct 2026) | Verified: 2026-10-07

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
   a Nurse (`plans/archive/brood-spine_2026-10-05.md` decision 5, `ORDINARY_QUEEN_BACKUP`),
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
- A gyne taking over from a dead queen -- settled 5 Oct 2026; see decision 12.
- COL-6's open question (how a skipped winter is charged, and who dies,
  before Shiver Cluster exists) -- settled 5 Oct 2026; see decision 11.
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
11. **A skipped winter is one bill** (Dave, 5 Oct 2026, for COL-6). At
    winter's start the colony pays, at once, what played winter would have
    burned: living bees x `energy_burn_rate` x `winter_burn_factor` x
    winter's length, the formula the winter forecast already shows. It comes
    out of the comb's stores. If they fall short, workers die oldest first
    until the survivors' bill fits; the queen dies only if the stores cannot
    cover even her share, and that is doom (COL-3). Until Shiver Cluster
    exists this is the whole of winter's cost.

12. **A gyne takes over from a dead queen** (Dave, 5 Oct 2026). When the
    queen dies and an adult gyne is in the hive, that gyne becomes the
    colony's queen and the run carries on. She has not mated, so she can lay
    only drones until she does. A window explains what happened and offers
    two modes: she lays drones in the hive, or she goes on nuptial flights --
    each day she leaves the colony for part of the day, with a chance of
    finding a mate that follows decision 7's curve (none outside late spring
    to early autumn, highest in mid summer). A flight never loses her. Once
    mated she lays as any queen does. Drones come first, as a minimal caste:
    an unfertilised egg becomes a drone, who eats, stays in the hive, does no
    work and ages out like a worker. The tier-4 Drones skill
    (`plans/design/progression.md` section 11, step 15) keeps deliberate
    drone rearing, and genetic points stay with COL-7. Decision 3's doom
    becomes the queen dead with no adult gyne to follow her.

**Order.** COL-4 (the calendar) first. Then, each specified when the one
before it lands: COL-6 winter is skipped and resolved in one step
(specified 5 Oct 2026 from decision 11, gated on COL-4);
COL-7 the mating window, genetic points and COL-2's narrower win; COL-8
winter die-back and spring regrowth; Shiver Cluster through the progression
plan. Succession (decision 12) runs beside them in the Claude lane: COL-9
the drone caste, then COL-10 a gyne takes over, then COL-11 nuptial
flights once COL-4's calendar exists. COL-11 builds the mating curve and
COL-7 reads the same one for genetic credit. Every one of them changes balance, so each is simulated first with
PE-2's arc (`tools/pacing_gates.py`).

## Open slices at a glance

<!-- LAYER: immediate-task -->

| Id | Slice | Files | Startable | Level |
| --- | --- | --- | --- | --- |
| COL-6 | winter is skipped and resolved in one step | `scripts/season.gd`, `scripts/year_winter.gd`, `tests/test_col6_winter_skip.py`, `test_scenarios/col6_winter_skip_test.json`, `tools/verify.ps1` | yes -- COL-4 has landed | high |
| COL-12 | the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns | `scripts/main.gd`, `scripts/world_building.gd`, `tests/test_sf1_founding_flower_mix.py`, `test_scenarios/sf1_founding_flower_mix_test.json` | yes | medium |
| COL-11 | nuptial flights: an unmated queen can leave each day to find a mate | `scripts/season.gd`, `scripts/bee.gd`, `scripts/succession_panel.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_col11_nuptial_flight.py`, `tests/col11_nuptial_flight_test.gd`, `tools/verify.ps1` | yes, after COL-6 in the Claude lane (both edit `season.gd`); COL-4 and COL-10 have landed | high |

**Dependencies.** COL-4 then COL-6: both edit `scripts/season.gd`, and
COL-6 needs COL-4's year clock. COL-4 runs in the Codex lane after GC-3
(`plans/archive/gameplay-consistency_2026-10-06.md`), which shares `scripts/game_config.gd`
and `scripts/settings_catalogue.gd`. NF-2 (`plans/now/nectar-fermentation.md`)
also waits for COL-4, for the same two files. COL-9 then COL-10 then COL-11, one after
the other in the Claude lane: each needs the one before, and COL-11 also
waits for COL-4.

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

COL-5 shipped 2026-10-04; its specification is `plans/archive/COL-5_2026-10-04.md`.

COL-4 shipped 2026-10-07; its specification is `plans/archive/COL-4_2026-10-07.md`.

## COL-6 -- winter is skipped and resolved in one step

<!-- LAYER: immediate-task -->

Level: high (event ordering at the year's turn, a balance change, and who
dies). Specified 5 Oct 2026 from decisions 5 and 11. Gated on COL-4: it
needs COL-4's year clock and edits `season.gd` after it.

**True now** (verified 5 Oct 2026, before COL-4). Winter is played:
`season.gd::_advance_winter` opens the countdown, sets `Session.winter_here`
for `winter_length_days`, and on its last day emits `winter_survived(losses)`
(bees at winter's start minus survivors). While `winter_here` is true,
foragers stay in, `bee_survival.gd::age_and_burn` burns at
`energy_burn_rate x winter_burn_factor`, and lifespans stretch by
`winter_lifespan_factor`; a bee that finds the comb empty starves.
`year_winter.gd::_winter_forecast` already computes what winter will cost
(bees x `energy_burn_rate` x `winter_burn_factor` x winter's seconds) and
what the comb holds (nectar plus honey x `honey_energy_factor`), for the
forecast panel only. `winter_bill` appears nowhere.

**True afterwards.**
- When winter arrives (the day COL-4's year clock puts it on), the run
  resolves it at once instead of playing it, and the next tick is the first
  day of spring: the day counter jumps by winter's length, and
  `Session.winter_here`/`winter_coming` end as they do after a winter
  survived today. Nobody ages, eats or forages through the skipped days.
- The bill is decision 11's formula, computed once by `season.gd`
  (simulation owns it): `season.gd::winter_bill(bees)` returns the energy,
  and `year_winter.gd::_winter_forecast` reads it instead of keeping its
  own copy, so the forecast and the charge can never disagree.
- The bill comes out of the comb's stores in the forecast's energy units
  (`honey_energy_factor`, as GC-3 leaves it). If they cover it, everyone
  lives. If not, workers are removed oldest first (by `age_seconds`) until
  the survivors' bill fits what is held; the stores end at what is left. The
  queen goes only if the stores cannot cover her share alone, through the
  existing queen-death path, so COL-3 offers the checkpoint. Brood is left
  as it is, outside the bill.
- `winter_survived(losses)` still fires once, with the bees the bill took,
  so CR-2's milestones (post-winter recovery) and COL-2's win hear winter
  exactly as before, and the player sees the existing post-winter notice.
- A level with winter off is unaffected. No Challenge changes.
- PE-2's arc is run before and after (`python tools/pacing_gates.py`), and
  this section records both.

**Must not change.** How a bee eats outside winter; CR-2's milestones and
COL-2's win (both read winter through `Session` and `winter_survived`); the
forecast panel's wording; any Challenge; saves (a save made mid-winter
before this slice still loads: the skip finishes that winter at once on the
next tick).

**Escalate** if the arc's survival drops sharply against COL-4's record (two
seeds of three), if no existing field tells a worker from a gyne or the
queen (gynes are not workers and are never billed away), or if a save made during a played winter
cannot be finished safely by the skip.

```queue
**[Claude] COL-6 -- winter is skipped and resolved in one step**
- Plan: `plans/now/colony-run.md` -- "COL-6 -- winter is skipped and resolved in one step"
- Files: `scripts/season.gd`, `scripts/year_winter.gd`, `tests/test_col6_winter_skip.py`, `test_scenarios/col6_winter_skip_test.json`, `tools/verify.ps1`
- Check: `python -m unittest tests.test_col6_winter_skip` passes (a stocked colony crosses winter in one tick with nobody lost and the day advanced by winter's length; an under-stocked one loses its oldest workers first and keeps its queen); `python tools/pacing_gates.py` before and after is recorded here; a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `absent: scripts/season.gd :: winter_bill`
- Next after: COL-7 -- the mating window, genetic points and COL-2's narrower win
```

COL-9 shipped 2026-10-06; its specification is `plans/archive/COL-9_2026-10-06.md`.

COL-10 shipped 2026-10-06; its specification is `plans/archive/COL-10_2026-10-06.md`.

## COL-11 -- nuptial flights: an unmated queen can leave each day to find a mate

<!-- LAYER: immediate-task -->

Level: high (a new balance value and the year's mating curve, simulated
first). Specified 5 Oct 2026 from decision 12; startable once COL-4 and
COL-10 have landed.

**True now** (verified 5 Oct 2026). No mating exists.
`season.gd::_gyne_season` gates gyne release on the old 60-day flower year
(`Flower.season_fraction() >= GameConfig.gyne_release_day`), which COL-4
replaces with decisions 5 and 6's year. Decision 7's curve is not built.

**True afterwards.**
- `season.gd`, which owns the calendar once COL-4 lands, answers one mating
  curve: 0 outside late spring to early autumn, rising to 1 at mid summer.
  This slice builds it; COL-7 reads the same function for genetic credit
  rather than writing a second (`plans/README.md` rule 4), and says so when
  it is specified.
- COL-10's window gains "Nuptial flights", and the queen's readout can
  switch between the two modes at any time while she is unmated.
- In flight mode she leaves through the entrance once a day, is away for part
  of the day (laying nothing meanwhile) and comes back. Each return rolls
  once: chance = `nuptial_flight_peak_chance` x the curve that day. Success
  sets `is_mated`; she then lays as any queen does and the modes go. A flight
  never loses her.
- `nuptial_flight_peak_chance` is a `GameConfig` value with a settings row,
  starting at an unsimulated 0.5. The slice runs `tools/pacing_gates.py`
  before and after and records both here.

**Must not change.** Gyne release (`_release_ready_gynes`); COL-6's winter
bill; a mated queen's laying.

```queue
**[Claude] COL-11 -- nuptial flights: an unmated queen can leave each day to find a mate**
- Plan: `plans/now/colony-run.md` -- "COL-11 -- nuptial flights: an unmated queen can leave each day to find a mate"
- Files: `scripts/season.gd`, `scripts/bee.gd`, `scripts/succession_panel.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_col11_nuptial_flight.py`, `tests/col11_nuptial_flight_test.gd`, `tools/verify.ps1`
- Check: `python -m unittest tests.test_col11_nuptial_flight` passes (no mating where the curve is 0; a queen flying in mid summer mates within the test's days and then lays worker brood); `python tools/pacing_gates.py` before and after is recorded in this plan; a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `absent: scripts/game_config.gd :: nuptial_flight_peak_chance`
- Next after: COL-7 -- the mating window, genetic points and COL-2's narrower win
```

## COL-12 -- the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns

<!-- LAYER: immediate-task -->

Level: medium (one bounded fix with an acceptance check; it changes every
headless run's meadow, so PE-2's arc is run before and after).

**True now** (found integrating COL-4, 7 Oct 2026). SF-1's test
(`tests/test_sf1_founding_flower_mix.py`) compares the founding meadow's
out-of-season share with the same phase a year later, within 0.05. It held on
master only on its pinned seed (two of four seeds failed), and only in total:
per species, founders and next year already differed by up to 0.07. COL-4
moved the year's start to fraction 0, the share then drifted +0.11 to +0.19 on
every seed, and the tolerance is 0.20 until this slice. Two causes, both
measured with temporary edits:
- `world_building.gd::_build_meadow` seeds `flower_count` (800) founding
  events, but bushy species plant several units each, so ~950 flowers start;
  `main.gd::_reseed_meadow` only tops up below 800, so nothing is reseeded for
  about the first day. That gap in births falls at the start of the year and
  starves the early species (Dandelion, Poppy, Clover).
- `_reseed_meadow` seeds at most one flower per frame and resets its timer
  rather than carrying the remainder, so at headless speed the fixture's
  meadow drains from ~950 to ~130 flowers in five days. With reseeding allowed
  to catch up, it holds at ~790.

**True afterwards.**
- Reseeding carries its timer and seeds every flower owed in a frame, up to
  the room below `flower_count`, so the meadow's renewal does not depend on
  frame rate.
- The founding meadow does not leave reseeding idle on day 1: founding counts
  flower units against `flower_count` rather than seeding events.
- SF-1's tolerance is back to 0.05 and holds on its pinned seed and on at
  least three others, with the fixture comparing a phase after the founders
  have turned over if that is what it needs.

**Must not change.** Which species a founder or a replacement gets (SF-1's
birth-season choice and COL-4's year); `flower_count` and the regrow interval
as settings.

**Escalate** if PE-2's arc changes its two-of-three survival record.

```queue
**[Claude] COL-12 -- the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns**
- Plan: `plans/now/colony-run.md` -- "COL-12 -- the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns"
- Files: `scripts/main.gd`, `scripts/world_building.gd`, `tests/test_sf1_founding_flower_mix.py`, `test_scenarios/sf1_founding_flower_mix_test.json`
- Check: `python -m unittest tests.test_sf1_founding_flower_mix` passes at 0.05 on the pinned seed and three others; `python tools/pacing_gates.py` before and after is recorded here; a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `present: tests/test_sf1_founding_flower_mix.py :: assertLessEqual(abs(initial_share - final_share), 0.20)`
- Next after: COL-7 -- the mating window, genetic points and COL-2's narrower win
```
