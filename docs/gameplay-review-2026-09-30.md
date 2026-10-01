# Gameplay systems consistency review -- 30 Sep 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 2e9f7b4 | Since: first run | Scope: everything this review owns -- role changes, needs, carried loads, cells and designation, brood, honey, seasons and winter, flowers, weather, Challenge stage goals and transitions, restores in place, win and loss; read from the transitions outwards rather than file by file | Previous: none

## Follow-through

None -- first run.

## Runs

Linux cloud session, official Godot 4.7 build and PowerShell 7 in the
session's scratch folder, `APPDATA` pointed at Godot's Linux `user://`.
Five headless runs, the limit: four fixtures through
`tools/run_scenario.py` and one `-s` probe script, all at seed 4242 and
30 fps, none kept in the repo (plus a one-line check that `-s` scripts get
the autoloads, which simulated nothing).

| Run | What | Result |
| --- | --- | --- |
| 1, 2 | Challenge 2 at 2.2: switch its forager to pollen, wait 20 s | 2.2 cleared, and so did the stages after it (see F1, and the first "Noted" line) |
| 3 | Enter 2.3 by the stage arrows, touch nothing for 2 s | 2.3 had cleared itself (F1) |
| 4 | Run 3 after F1's fix, then a designation | 2.3 held for 2 s; the assert that the designation led to 2.4 failed, because 2.4 clears on entry too (run 5 A) |
| 5 | Probe: A, 2.3 with the fix, then an explicit designation; B, a forager carrying 30 nectar made a Miner; C, a Nurse made Idle; D, a Miner as control | A: held 2 s, cleared 1 s after the designation, and 2.4 cleared on entry (stores 400 nectar, 197 pollen). B: 30 nectar still aboard 75 s later, in the hive, never delivered. C: in the meadow on `IDLING` 15 s later, energy falling at the base rate with no feed. D: ate normally |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | Challenge 2's 2.3 ("designate a cell") clears the moment it opens, so its lesson and Dr Gallerin's 2.3 lines are never seen: its check counts the automatic designation that stocking and every first deposit make. A second instance of the 1.13 pitfall, with no guard. | `challenge_stages.gd` 2.3's `cell_count` clauses lack `"explicit": true` (1.13's has it); `hive_cell.gd::add_resource` designates on first deposit; `world_building.gd::_stock_starting_comb`; runs 3 and 5 | high | Fixed -- `"explicit": true` on each clause, plus the missing guard `tests/source_checks.py::check_designation_goals_explicit` (it failed on the old data); run 5 shows 2.3 waiting, then clearing on an explicit designation; C-85 filed |
| F2 | A job change loses what the bee carries. No indoor job delivers a former forager's load, a Comb worker's or Honey worker's next lift overwrites it, and restock remnants go the same way. "Finish the job first" is off by default. Up to 50 nectar per forager moved. | `bee.gd::_apply_role`; `bee_foraging.gd::enter_hive`; `bee_building.gd::builder_go_to_haul_source`, `restock_go_to_source`, `restock_go_to_target`; `bee_honey.gd::honey_go_to_nectar`; run 5 B | medium | Queued -- GC-2 in `plans/now/gameplay-consistency.md` |
| F3 | Idle walks a bee out of the hive, and in the meadow she can never eat, so she starves about 590 s (under three game days) from full. The Idle tooltip says "They stay where they are". | `bee_status.gd::works_indoors` (no Idle); `bee.gd::_apply_role`; `bee_survival.gd::should_go_and_eat`, `after_feeding`; `roles.gd` Idle `tip`; run 5 C | medium | Queued -- GC-1 in `plans/now/gameplay-consistency.md` |
| F4 | Honey making creates energy: 2 nectar make 1 honey worth 4, against `.claude/rules/simulation.md`'s settled rule (26 Aug). No plan carried the fix; the winter forecast counts honey at x4, and WO-1 makes winter part of every Scenario. | `game_config.gd` `nectar_per_honey` 2.0, `honey_energy_factor` 4.0; `bee_honey.gd::honey_chew`; `bee_survival.gd::feed_self`; `year_winter.gd::_winter_forecast` | medium | Gated -- GC-3 in `plans/now/gameplay-consistency.md`, waiting for PE-2's arc as the multi-season evidence the rule asks for; the direction is Dave's decision (raise `nectar_per_honey` to 4.0), written into `.claude/rules/simulation.md` |
| F5 | Two calendars run one year. Flowers and gyne release follow a fixed 60-day flower year that never hears about winter, so after WO-1 winter (days 21 to 41) falls in the flowers' midsummer and the meadow blooms at peak all winter; gynes can leave from day 45 only by coincidence. Product scope §3 (gynes after winter), `season.gd`'s comment (before winter) and `flower.gd`'s comment (the season ends when winter starts) disagree. | `flower.gd::season_fraction`, `season_strength`; `season.gd::_gyne_season`, `_advance_winter`; WO-1's schedule in `plans/archive/winter-onset_2026-10-01.md` | medium | Decided -- Dave: one calendar, counted from the end of the last winter, controls flowers and gyne timing; flowers hold their floor and then die off in winter; gynes may leave any time but mate only in season, and timely drones and gynes earn genetic points. Written into `plans/design/product-scope.md` §6.2 for the Colony Run definition to specify |

## Hand-offs

- **Product review.** Challenge 2's 2.4 reserve (175 nectar, 90 pollen) is
  below level 2's starting stock (400 and 200, at 200 per cell), so 2.4
  clears the moment 2.3 does (run 5 A). Whether a played 2.1 to 2.3 ever
  brings stores below it is a pacing question.
- **UI review.** `main.gd::_check_colony_energy` tells the player to "put
  more bees on nectar foraging" while winter or rain grounds every forager.
- **Save review.** A restore replays each bee's `state` without what it
  depends on: `move_target`, `timer` and `carrying_corpse` are not saved, so
  a bee saved in `MOVE_TO_POINT` heads for (0, 0). `season.gd`'s `disease`
  and `bees_at_winter_start` are not saved either: an in-place restore
  (Challenge 2's rescue, `restore_slot`) keeps the live values, and a fresh
  load reports no winter losses.
- **Architecture review.** The queen's default backup is decided twice,
  agreeing today: `bee.gd::setup` always gives her Nurse, so `levels.gd`'s
  `queen_laying_backup` reaches her only through `_apply_role` when she has
  none. `bee_status.gd::works_indoors` is a role list outside `roles.gd`.
- **Verification review.** The harness has no per-bee assert, so a load or a
  location can only be shown by a probe script (run 5); GC-2 adds
  `set_bee_load` and a `forager_delivery` count, no more.

## Noted, not pursued

- A focus change does not refresh the population cache (`bee.gd::set_focus`
  never calls `invalidate_population`), so the nectar and pollen split,
  Challenge 2's 2.2 and 2.9 counts and scenario role counts lag until any bee
  crosses the entrance (`world_building.gd::move_bee_into_hive` refreshes
  it). Runs 1 and 2 show 2.2 still clearing within one trip.
- `bee.gd`'s `energy_immune` comment says Challenge 1 only;
  `challenge_runner.gd::start` sets it for Challenge 2 as well.
- `bee_egg_laying.gd::queen_lay` can lay a gyne egg after eating only a
  worker egg's pollen, when her target cell changes to a gyne cell en route.
- `_apply_role` drops a nurse's brood food by design, a feed's worth at most.
- `bee_foraging.gd::finish_collecting` increments the Challenge runner's
  private `_c1_queen_collections`; harmless while only Challenge 1 reads it.

## Not reviewed

- Navigation (the hive graph, meadow steering), crab spiders, the rival hive,
  scouting and recruitment, and disease and weather balance: read only where
  a transition above touched them.
- Challenge 1 stage by stage (its own 25-slice plan and fixtures cover it),
  and Challenge 2's 2.5 to 2.9 beyond the reserve hand-off.
- The UI by hand: no windowed Godot here, so C-85 carries the player's view.

## Patterns deliberately not applied

- **A carried-load inventory.** GC-2 keeps the one `current_load` slot and
  adds one choke point (`_deliver_held_load`), as the "remembering to check
  a flag" pitfall asks.
- **Widening `works_indoors` to Idle.** Winter grounding and the entrance
  read it; GC-1 names Idle in the two places that walk her out.
- **Rewriting the comments Dave's calendar decision supersedes**
  (`season.gd::_gyne_season`, `flower.gd::season_fraction`) ahead of their
  code: a comment ahead of its predicate is itself a recorded pitfall.
- **Changing the honey values now**: the 26 Aug rule wants multi-season
  evidence first.
