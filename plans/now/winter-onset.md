# Winter onset — winter comes by itself

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: WO-1 -- winter's countdown opens by itself on a set day, startable, its block below | Dependency: none | Verified: 2026-09-30

**Objective.** In every run whose level has winter on, winter's countdown
opens by itself on day `GameConfig.winter_countdown_start_day`, so a Scenario
(and later the Colony Run) meets its first winter. At today's defaults
(countdown 15 days, winter 20) that is winter from day 21 to day 41, which
`plans/design/product-scope.md` §3 places near the 60-minute outcome once the
player fast-forwards through the quiet weeks (its 3 Sep 2026 note). The day
(6) is provisional; PE-2's played arc is where it is tuned
(`plans/design/product-scope.md` §6.2, "Next design pass").

**Decision (Dave, 30 Sep 2026).** Winter is the played short season the code
already runs -- `season.gd::_advance_winter` keeps foragers in and lets the
ordinary energy rules decide who survives -- not a resolved event. Its
countdown opens by itself on a fixed day, `GameConfig.winter_countdown_start_day`,
in every run whose level has winter on. The event director may later replace
the fixed day with a readiness-aware trigger. This paragraph is the
authoritative statement; it settles `DESIGN_BACKLOG.md`'s deferred Winter
question, which now points here (asked in
`docs/product-review-2026-09-30.md`).

**State, verified 30 Sep 2026.** `year_winter.gd::begin_winter_countdown` is
the only thing that sets `Session.winter_coming`, and its only caller is the
debug panel's winter button (`debug_panel.gd`, through
`main.gd::begin_winter_countdown`). It has been that way since winter was
added on 13 Aug 2026, so no ordinary run has ever had a winter:
`season.gd::_advance_winter`, run on the season tick once a simulated second,
returns while `winter_coming` is false.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| WO-1 | On day 6 the Winter window opens by itself and names the day winter arrives | `scripts/season.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/scenario_actions.gd`, `test_scenarios/wo1_winter_onset_test.json`, `test_scenarios/alpha_arc_test.json` and the seven fixtures listed below | yes | medium |

**Required reading.** WO-1's section below, and the functions it names.
**Must not change:** the save format (`save_game.gd::FORMAT_VERSION`, the
persisted-settings set `tests/source_checks.py::ORIGINAL_SAVED_SETTINGS`);
how winter itself plays once it has begun; the debug button.

## WO-1 — winter's countdown opens by itself on a set day

Level: medium (a simulation change with an acceptance check; nothing per
frame, nothing saved that is not saved today).

**Change.**

- `scripts/game_config.gd`: next to `winter_countdown_days`, add
  `var winter_countdown_start_day: float = 6.0`, commented as the day a run's
  countdown opens by itself. Reword the comment above
  `winter_countdown_days` ("Whether one is *scheduled*, and when, is state of
  the run rather than a setting") to say the opening day is this setting and
  the schedule it produces stays Session state.
- `scripts/settings_catalogue.gd`: a `TUNABLES` row for it in the shape of
  the `winter_countdown_days` row, with `"persist": "none"`, label "Winter
  countdown opens on day", step 1.0, min 0.0, category "Winter", and a tip
  saying winter then arrives "Winter in days" later. `"none"`, not `"run"`:
  the schedule this value produces, `Session.winter_starts_day`, is already
  saved and restored, so saving the setting adds nothing a restore needs and
  leaves `ORIGINAL_SAVED_SETTINGS` alone. Reword `winter_countdown_days`'
  tip: it counts from the day the countdown opens, not from "Bring on
  winter".
- `scripts/season.gd::_advance_winter`: inside its opening
  `if not Session.winter_coming:` branch, before the `return`, call
  `world.begin_winter_countdown()` when `Session.winter_starts_day <= 0.0`
  and `world.day >= GameConfig.winter_countdown_start_day`.
  `winter_starts_day` is 0 until a countdown opens (`session.gd`'s reset),
  is saved and restored, and stays set after winter ends, so this opens one
  countdown per run, never re-opens it after winter, and leaves alone a run
  whose debug button already opened one. For a level with `"winter": false`
  (Challenges 1 and 2) `begin_winter_countdown` returns before changing
  anything, so the level flag stays read in one place and the check repeats
  once a simulated second at the cost of one dictionary read.
- `scripts/scenario_actions.gd::_evaluate_assert_condition`: beside
  `tree_paused`, two keys compared with `Session`: `winter_coming` and
  `winter_here`, each failing with a reason that names the actual value.
  Today an assert on either would fall through to `_when_met`, which drops
  keys it does not know and so passes without checking.
- Seven fixtures allow 30 days (`stop.max_days`) without `"winter": false`,
  so after this slice any that runs past day 20 would meet winter. Add
  `"winter": false` to each so they behave exactly as today: `a3_fixedfps_benchmark_test.json`,
  `a5_actions_resolved_test.json`, `a5_stop_when_test.json`,
  `slice3_timescale_8x_test.json`, `slice3_timescale_16x_test.json`,
  `slice3_timescale_30x_test.json` and `sv1_named_saves_test.json`, all in
  `test_scenarios/`. BS-4's fixture sets it already.
- `test_scenarios/alpha_arc_test.json`: `stop.max_days` 36 to 44, so the
  pacing arc runs past winter's end on day 41. Keep its winter on.
- `test_scenarios/wo1_winter_onset_test.json` (new): level 4's starting
  colony copied from `levels.gd` (15 cells, 8 nectar and 3 pollen foragers,
  2 nurses, 2 builders, 2 miners), `"random_seed": 4242`, winter left on.
  Four `assert` actions, each gated by `day_at_least`: day 5,
  `{"winter_coming": false}`; day 7, `{"winter_coming": true}`; day 20,
  `{"winter_here": false}`; day 22, `{"winter_here": true}`.
  `"stop": {"when_actions_resolved": true, "max_days": 23}`.

**Acceptance, from the player's seat** (the hands-on check this slice files
with `python tools/new_check.py --name "Winter's countdown opens by itself"
--owner plans/now/winter-onset.md`): start Scenario 4 with default settings
and play, fast-forward allowed, to day 6. PASS: on day 6, with no button
pressed, the Winter window opens on the left and a message says winter will
arrive on day 21. A failure means a player never sees winter coming.

**Escalate** if a check demands a save-format change or a
`ORIGINAL_SAVED_SETTINGS` edit: that is a save-compatibility decision for
Dave, not this slice's.

```queue
**[Claude] WO-1 -- winter's countdown opens by itself on a set day**
- Plan: `plans/now/winter-onset.md` -- "WO-1 — winter's countdown opens by itself on a set day"
- Files: `scripts/season.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/scenario_actions.gd`, `test_scenarios/wo1_winter_onset_test.json`, `test_scenarios/alpha_arc_test.json`, `test_scenarios/a3_fixedfps_benchmark_test.json`, `test_scenarios/a5_actions_resolved_test.json`, `test_scenarios/a5_stop_when_test.json`, `test_scenarios/slice3_timescale_8x_test.json`, `test_scenarios/slice3_timescale_16x_test.json`, `test_scenarios/slice3_timescale_30x_test.json`, `test_scenarios/sv1_named_saves_test.json`
- Check: `python tools/run_scenario.py test_scenarios/wo1_winter_onset_test.json` passes (countdown open by day 7, winter here by day 22 and not before day 21), the hands-on check is filed, and `tools/verify.ps1` is green
- Proof: `absent: scripts/game_config.gd :: winter_countdown_start_day`
- Next after: none -- plans/now/winter-onset.md is complete
```
