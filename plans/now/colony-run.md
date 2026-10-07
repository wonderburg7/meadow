# Colony Run -- the flagship run's definition and first slices

Status: active | Owner: Dave / Claude Code | Next: COL-12 -- the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns, Codex lane (a COL-4 integration finding, Dave 7 Oct 2026); COL-7 -- the mating window, genetic points and COL-2's narrower win, Claude lane, startable now COL-11 has landed (decisions 7 and 10; the player sends a gyne, Dave 7 Oct 2026) (COL-11 landed: season.gd::mating_curve is the year's one mating curve, 0 outside late spring to early autumn and 1 at mid summer, and season.gd::nuptial_mating_chance is `nuptial_flight_peak_chance` (0.5, a settings row) times it; an unmated queen chooses laying drones or nuptial flights in the succession window or, at any time, the selected-bee panel's Mating row (hud.gd, Dave 7 Oct 2026); on flights she leaves through the entrance once a day, waits in the meadow a quarter of a day, comes home and rolls once, and mated she lays workers; the mode is not saved yet; COL-13 landed: tools/analyze_session.py dates a skipped winter from the game_time jump of winter's length, so the pacing arc shows both winter rows in band and every seed lived; COL-6 landed: winter is no longer played -- the day it arrives season.gd::_resolve_winter charges season.gd::winter_bill (bees x energy_burn_rate x winter_burn_factor x winter's seconds) out of the stores, sealed cells included, removes bees until the survivors' bill fits -- drones, then workers, then gynes, oldest first within each, Dave's decision 7 Oct 2026 -- and the queen last, only if the stores cannot cover her share, moves Session.sim_time on by winter's length and fires winter_survived once with the bees it took; year_winter.gd's forecast reads winter_bill and winter_stores; COL-4 landed: a year is `season_length_days` (30) playable days then `winter_length_days` (10) of winter, both saved run settings; the flower fraction restarts after every winter, and winter recurs each year with its countdown derived by season.gd::_winter_countdown_day, so `winter_countdown_start_day` is gone; a level with winter off has a year of only its playable season (Session.year_has_winter, Session.year_days); SF-1's tolerance is 0.20 until COL-12; COL-10 landed: when the queen dies the oldest adult gyne becomes an unmated queen on Egg layer through main.gd::_promote_gyne_to_queen, before colony_lost is set, and succession_panel.gd explains it once; with no gyne the run ends as before; COL-9 landed: an unmated queen (bee.gd::is_mated, saved, true by default) lays drone brood that hatches an Idle drone through main.gd's emergence loop, and set_role refuses him any other job; COL-5 landed: level rows no longer carry the unread unlocks and win_conditions keys; COL-3 landed: game_over.gd offers the latest checkpoint of a Colony Run through saves_panel.gd::reload_from; COL-2 landed: colony_milestones.check_victory records a victory day and opens the win screen with Colony Run wording; COL-1 landed: the goal shelf shows the next milestone via colony_milestones.show_next; PE-2 landed with its evidence below; CR-2 landed: scripts/colony_milestones.gd records the day each milestone is first met, saved as an additive field) | Dependency: none; COL-2 follows COL-1, and the year (COL-4, decisions 5-10) is queued in the Codex lane after GC-3, which shares `scripts/game_config.gd` and `scripts/settings_catalogue.gd` (Dave, 4 Oct 2026) | Verified: 2026-10-07

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
   **Superseded in part (Dave, 6 Oct 2026):** without the skill a colony
   pays decision 11's bill times a multiplier rather than failing outright
   -- `plans/design/progression.md` section 5.6, "Shiver Cluster". It is
   built as T2-8 in `plans/now/tier-two.md` after COL-6, and T2-4b there
   turns the winter bill's dead into bodies at spring through COL-6's hook.
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
| COL-12 | the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns | `scripts/main.gd`, `scripts/world_building.gd`, `tests/test_sf1_founding_flower_mix.py`, `test_scenarios/sf1_founding_flower_mix_test.json` | yes -- Codex lane (Dave, 7 Oct 2026); COL-13 has landed | medium |
| COL-7 | the mating window, genetic points and COL-2's narrower win | `scripts/season.gd`, `scripts/hud.gd`, `scripts/year_winter.gd`, `scripts/colony_milestones.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_col7_gyne_window.py`, `tests/col7_gyne_window_test.gd` | after COL-11 (its mating curve) | high |

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

COL-6 shipped 2026-10-07; its specification is `plans/archive/COL-6_2026-10-07.md`.

COL-11 shipped 2026-10-07; its specification is `plans/archive/COL-11_2026-10-07.md`.

## COL-7 -- the mating window, genetic points and COL-2's narrower win

<!-- LAYER: immediate-task -->

Level: high (a gameplay outcome, the win condition and a saved count;
simulated first). Specified 7 Oct 2026 from decisions 7 and 10, with two
answers from Dave that day: **the player sends a gyne** (none leaves by
herself), and **a gyne is worth `genetic_points_per_gyne` (10) x the mating
curve on the day she leaves, rounded**. Startable once COL-11 has landed,
since it reads COL-11's curve.

**True now** (verified against master, 7 Oct 2026).
`season.gd::_release_ready_gynes` sends every adult gyne whose energy is at
least `energy_capacity` x `gyne_release_energy` away by herself, on each
season tick when `_gyne_season()` allows it (`Flower.season_fraction() >=
GameConfig.gyne_release_day`, the old flower year). Each one adds 1 to
`Session.gynes_released` and emits `gyne_released`, which drives
`year_winter.gd::_on_gyne_released`'s notice, `colony_milestones.evaluate`
and `colony_milestones.check_victory`. Nothing counts genetic points. No
scenario or test waits for an automatic release (`grep gynes_released
test_scenarios` is empty).

**True afterwards.**
- No gyne leaves by herself. `_release_ready_gynes`, `_gyne_season` and
  `GameConfig.gyne_release_day` with its settings row go. (A saved settings
  file that still carries the key loads unchanged; if it would not, keep the
  field unread and say so here.)
- With one gyne selected who is ready (adult, and energy at the threshold
  release uses today), her readout in `hud.gd`'s selected-bee panel offers
  "Send her to found a colony". Pressing it calls a new
  `season.gd::send_gyne(bee)`. A gyne who isn't ready shows why, using the
  readout's existing hint pattern. This runs on the press, and the row is
  refreshed with the panel (only while it is visible), never per frame.
- `send_gyne` reads COL-11's mating curve for today (the same function, not a
  second one; `plans/README.md` rule 4).
  - Curve above 0: she leaves as a released gyne does today
    (`leave_to_found_colony`, `Session.gynes_released` + 1, `gyne_released`),
    and adds `round(genetic_points_per_gyne x curve)` genetic points.
  - Curve 0, outside late spring to early autumn: she leaves and is lost. A
    new `gyne_lost` signal drives a `year_winter.gd` notice saying she found
    no mate outside the mating season, so she doesn't count. No release is
    counted, no points, no victory.
- COL-2's win narrows by construction: `check_victory` still runs only on
  `gyne_released`, which only a gyne sent inside the window fires.
- Genetic points (decision 10: counted and saved now, spent later) live in
  `colony_milestones.gd`, the owner of the Colony Run's record, which already
  saves its victory day beside the milestone days (COL-2). Its saved record
  gains a `genetic_points` key, so `save_game.gd` and `saving.gd` (the Codex
  lane's SI-1) are untouched, and a save without the key loads with 0. Only a
  Colony Run counts them (`applies()`). The released notice names the points
  earned and the run's total.
- `genetic_points_per_gyne` is a `GameConfig` value with a settings row,
  starting at 10. The slice runs `tools/pacing_gates.py` before and after
  and records both here. The arc's gyne gate is not instrumented, so expect
  no change there; any other change needs explaining.

**Must not change.** COL-6's winter bill; COL-11's flights and curve; a
mated queen's laying; `Session.gynes_released`'s meaning (gynes sent inside
the window); the save format outside `colony_milestones`' own record.
Spending the points belongs to `plans/design/progression.md` (the tier-4
Drones skill thread), not here.

**Hands-on.** Dave selects a ready gyne in mid summer and sends her (the
notice names the points, and a first one after winter wins). Then he sends
one in early spring, and the lost notice shows with no win.

```queue
**[Claude] COL-7 -- the mating window, genetic points and COL-2's narrower win**
- Plan: `plans/now/colony-run.md` -- "COL-7 -- the mating window, genetic points and COL-2's narrower win"
- Files: `scripts/season.gd`, `scripts/hud.gd`, `scripts/year_winter.gd`, `scripts/colony_milestones.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_col7_gyne_window.py`, `tests/col7_gyne_window_test.gd`
- Check: `python -m unittest tests.test_col7_gyne_window` passes (a ready gyne stays put across many season ticks; sent in mid summer she counts, emits `gyne_released` and adds 10 points; sent where the curve is 0 she is gone, `gyne_lost` fires, and the release count, points and victory don't change; the points survive `save_data`/`restore`, and a record without them restores 0); `python tools/pacing_gates.py` before and after is recorded here; a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `absent: scripts/season.gd :: func send_gyne`
- Next after: COL-8 -- winter die-back and spring regrowth
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
**[Codex] COL-12 -- the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns**
- Plan: `plans/now/colony-run.md` -- "COL-12 -- the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns"
- Files: `scripts/main.gd`, `scripts/world_building.gd`, `tests/test_sf1_founding_flower_mix.py`, `test_scenarios/sf1_founding_flower_mix_test.json`
- Check: `python -m unittest tests.test_sf1_founding_flower_mix` passes at 0.05 on the pinned seed and three others; `python tools/pacing_gates.py` before and after is recorded here; a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `present: tests/test_sf1_founding_flower_mix.py :: assertLessEqual(abs(initial_share - final_share), 0.20)`
- Next after: COL-7 -- the mating window, genetic points and COL-2's narrower win
```

COL-13 shipped 2026-10-07; its specification is `plans/archive/COL-13_2026-10-07.md`.
