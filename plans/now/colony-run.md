# Colony Run -- the flagship run's definition and first slices

Status: active | Owner: Dave / Claude Code | Next: None -- plan complete (COL-8 landed: winter empties every flower through flower.gd::die_back, and flower.gd::regrowth_factor, set per tick by season.gd::_update_regrowth, scales season_strength() up from 0 over `spring_regrowth_days` (3, a settings row) after a winter; hands-on check C-116) (COL-7 landed: no gyne leaves by herself; a single selected ready gyne's panel offers "Send her to found a colony" (hud.gd), which calls season.gd::send_gyne: inside the mating window she counts as released (Session.gynes_released, gyne_released) and earns round(`genetic_points_per_gyne` (10, a settings row) x season.gd::mating_curve) genetic points, counted in a Colony Run and saved in colony_milestones.gd's record under `genetic_points`; outside it she is lost (gyne_lost, year_winter.gd's notice) and nothing counts, so COL-2's win needs a gyne sent inside the window; `gyne_release_day` and its settings row are gone; COL-11 landed: season.gd::mating_curve is the year's one mating curve, 0 outside late spring to early autumn and 1 at mid summer, and season.gd::nuptial_mating_chance is `nuptial_flight_peak_chance` (0.5, a settings row) times it; an unmated queen chooses laying drones or nuptial flights in the succession window or, at any time, the selected-bee panel's Mating row (hud.gd, Dave 7 Oct 2026); on flights she leaves through the entrance once a day, waits in the meadow a quarter of a day, comes home and rolls once, and mated she lays workers; the mode is not saved yet; COL-13 landed: tools/analyze_session.py dates a skipped winter from the game_time jump of winter's length, so the pacing arc shows both winter rows in band and every seed lived; COL-6 landed: winter is no longer played -- the day it arrives season.gd::_resolve_winter charges season.gd::winter_bill (bees x energy_burn_rate x winter_burn_factor x winter's seconds) out of the stores, sealed cells included, removes bees until the survivors' bill fits -- drones, then workers, then gynes, oldest first within each, Dave's decision 7 Oct 2026 -- and the queen last, only if the stores cannot cover her share, moves Session.sim_time on by winter's length and fires winter_survived once with the bees it took; year_winter.gd's forecast reads winter_bill and winter_stores; COL-4 landed: a year is `season_length_days` (30) playable days then `winter_length_days` (10) of winter, both saved run settings; the flower fraction restarts after every winter, and winter recurs each year with its countdown derived by season.gd::_winter_countdown_day, so `winter_countdown_start_day` is gone; a level with winter off has a year of only its playable season (Session.year_has_winter, Session.year_days); COL-12 landed: SF-1's four-seed post-founder tolerance is 0.05, founding counts flower units, and reseeding carries elapsed time; COL-10 landed: when the queen dies the oldest adult gyne becomes an unmated queen on Egg layer through main.gd::_promote_gyne_to_queen, before colony_lost is set, and succession_panel.gd explains it once; with no gyne the run ends as before; COL-9 landed: an unmated queen (bee.gd::is_mated, saved, true by default) lays drone brood that hatches an Idle drone through main.gd's emergence loop, and set_role refuses him any other job; COL-5 landed: level rows no longer carry the unread unlocks and win_conditions keys; COL-3 landed: game_over.gd offers the latest checkpoint of a Colony Run through saves_panel.gd::reload_from; COL-2 landed: colony_milestones.check_victory records a victory day and opens the win screen with Colony Run wording; COL-1 landed: the goal shelf shows the next milestone via colony_milestones.show_next; PE-2 landed with its evidence below; CR-2 landed: scripts/colony_milestones.gd records the day each milestone is first met, saved as an additive field) | Dependency: none; COL-2 follows COL-1, and the year (COL-4, decisions 5-10) is queued in the Codex lane after GC-3, which shares `scripts/game_config.gd` and `scripts/settings_catalogue.gd` (Dave, 4 Oct 2026) | Verified: 2026-10-07

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
| COL-8 | winter die-back and spring regrowth | `scripts/flower.gd`, `scripts/season.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_col8_winter_dieback.py`, `tests/col8_winter_dieback_test.gd` | yes -- COL-7 has landed (both edit `season.gd`) | high |

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

COL-7 shipped 2026-10-07; its specification is `plans/archive/COL-7_2026-10-07.md`.

## Found while landing COL-6 to COL-7, not yet slices

<!-- LAYER: immediate-task -->

Follow-ups the 7 Oct 2026 run found in or beside this plan's slices. Each
needs a section and a queue block before it can be built; delete its line
when it gets one.

- `test_scenarios/wo1_winter_onset_test.json` still asserts `winter_here` on
  day 32. It has failed since COL-6, which never plays winter, but
  `verify.ps1` doesn't run it. Update it to a skipped winter or retire it.
- `plans/design/product-scope.md` (§6.2, the two `_gyne_season` mentions)
  still describes the automatic, late-year gyne release that COL-7 removed.
- A forager mid-trip when COL-6's clock jumps logs one trip and one flower
  visit about 2,000 s long (`bee_foraging.gd` `trip_start_time`,
  `flower_visit_started_at`). Reset those timers at the jump if anything
  but diagnostics reads them.
- COL-7's `gyne_lost` is connected in `year_winter.gd`'s deferred `_ready`,
  because `main.gd`, where season's other signals are wired, was outside its
  files. Move it beside the others.
- A ready gyne nobody sends now sits in the hive eating, with no prompt
  (COL-7). A problem-strip signal for a ready gyne would surface her.
- An unmated queen's nuptial-flight mode is not saved (COL-11; SI-1 holds the
  save files), so a load puts her back to laying drones. Save it once SI-1 has
  landed.
- `tools/analyze_session.py` (COL-13) reads any snapshot gap of at least
  winter's length as a skipped winter. That's harmless in today's logs, but a
  sparse log would date a winter that never came.
- A save made during a played winter, before COL-6, reports only the bill's
  losses in the spring notice, not the bees that died earlier that winter.

## COL-8 -- winter die-back and spring regrowth

<!-- LAYER: immediate-task -->

Level: high (`flower.gd::season_strength` runs for every flower every frame,
and the die-back is ordered against COL-6's winter step). Specified 7 Oct
2026 from decision 8 ("plants die back over winter and regrow over the first
days of spring").

**True now** (verified against master, 7 Oct 2026). Nothing dies back.
Worse, a skipped winter refills the meadow: `flower.gd::_sync_recharge`
catches a flower's nectar and pollen up lazily from `_last_recharge_update`
to `Session.sim_time`, so the first read after COL-6's jump
(`season.gd::_resolve_winter` adds winter's length to `sim_time`) credits
the whole skipped winter at the flower's current `season_strength()`.
Spring's first day opens with in-season flowers full. `season_strength()`
reads only `season_fraction()`, so the first spring after a winter flowers
exactly like the run's first spring.

**True afterwards.**
- At winter's skip, after the bill and before the clock moves,
  `season.gd::_resolve_winter` has every flower die back: a new
  `flower.gd::die_back()` empties its nectar and pollen and sets
  `_last_recharge_update` to the post-jump time, so the skipped days credit
  nothing. Plants stay where they are (the `in_season` comment's rule), so
  the flower count and COL-12's founding-share check are untouched. This runs
  once a winter, over the `flowers` group.
- Over the first `spring_regrowth_days` (a new `GameConfig` value with a
  settings row, starting at an unsimulated 3) after a winter has ended, every
  flower's `season_strength()` is scaled by a regrowth factor rising from 0
  to 1, so production and the meadow's look recover together. The run's
  first spring, with no winter behind it, is unchanged, and so is a level
  with winter off. The factor is worked out once per season tick by
  `season.gd` into a static on `flower.gd` that `season_strength()`
  multiplies by: one float read per flower per frame, no per-flower date
  maths.
- The slice runs `tools/pacing_gates.py` before and after and records both
  here. The winter-survived and post-winter rows may move: explain any
  change.

**Must not change.** COL-6's bill and its ordering (bill, then die-back,
then the clock jump); COL-11's mating curve (it reads `season_fraction`,
not `season_strength`); `main.gd::_reseed_meadow` and
`world_building.gd` (the Codex lane's COL-12); flower count and placement.

**Pacing gates, before and after (8 Oct 2026).** Identical on every row: first worker 16.87, winter entered 30.01 and survived 40.01 on seeds 20260924 and 20260925, seed 20260923 died both times. Only difference: seed 20260924 ends with 9 bees after, 8 before (post-winter flowers no longer start full, so spring foraging differs slightly; no gate moves).

**Hands-on.** Dave plays a Colony Run through its first winter: on spring's
first day the meadow is bare, and it is back in flower about three days
later.

```queue
**[Claude] COL-8 -- winter die-back and spring regrowth**
- Plan: `plans/now/colony-run.md` -- "COL-8 -- winter die-back and spring regrowth"
- Files: `scripts/flower.gd`, `scripts/season.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_col8_winter_dieback.py`, `tests/col8_winter_dieback_test.gd`
- Check: `python -m unittest tests.test_col8_winter_dieback` passes (an in-season flower holding nectar before the skip holds none just after it; on spring's first day its `season_strength()` is below the same date's value in a year with no winter behind it, and equal again by day 1 + `spring_regrowth_days`; the flower count is unchanged by the die-back; the run's first spring is unchanged); `python tools/pacing_gates.py` before and after is recorded here; a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `absent: scripts/game_config.gd :: spring_regrowth_days`
- Next after: T2-8 -- Shiver Cluster: the skill, the multiplied bill without it, the warning
```

COL-12 shipped 2026-10-08; its specification is `plans/archive/COL-12_2026-10-08.md`.
