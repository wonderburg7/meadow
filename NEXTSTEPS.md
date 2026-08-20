# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log` and the Notion Build Log.

## Next up

1. **AI playtest harness is now built through slice 6 (the plan's whole
   suggested build order) and answered its first real question -- see
   below. Nothing in `AI_PLAYTEST_PLAN.md` is left to build; the whole
   six-slice diff (`levels.gd`, `main.gd`, `save_game.gd`,
   `tools/run_scenario.py`, `tools/analyze_session.py`, everything under
   `test_scenarios/`) is still uncommitted and waiting on Dave's review.**
2. **Crab spiders: a second round of playtest fixes, still waiting on
   Dave's hands-on re-check.** Death marks, dev-marker/alarm-ring/
   logging fixes, and three further issues plus a settings gap were all
   fixed in the 20 Aug session -- see `CRAB_SPIDER_PLAN.md`'s 20 Aug
   "Confirmed" entry for the full detail. `source_checks.py`/
   `balance_tests.py` pass, `FUNCTION_MAP.md` regenerated, a Godot boot
   is clean. **Needs Dave's re-check** on: the new
   `crab_spider_attack_success_chance` setting does something, an
   escaped bee's flower stays off-limits even when forage is tight,
   every attack (not just alarm-triggered avoidance) flashes red, and
   the dev marker now reads as a ring rather than a blob. Bundle 3
   (recruitment suppression) and Bundle 4's original checklist item
   still haven't had their own hands-on check; Bundle 6 (closeout) is
   last, once all of this settles.
3. **A backlog of earlier hands-on checks is building up** -- none of
   these are blocked on anything, just not yet played:
   - Two Challenge 1/2 fixes from a few sessions ago (corner problem
     strip hidden during a Challenge; backup building/mining now breaks
     off promptly when primary work turns up) -- both boot clean,
     neither played.
   - Challenge 2's ten sub-stages -- built and checked, never played
     start to finish (see `TUTORIAL_PLAN.md`'s checklist).
   - Two older audit bundles: Bundle A (abandon Challenge 1 mid-build,
     confirm a fresh run's build time/Save-Load state reset cleanly)
     and Bundle B (save/load a few times, check population/flower
     counts and the queen panel's plain-comb checkbox stay in sync).

## What slice 6 of the playtest harness actually did

Built and self-verified this session (20 Aug 2026), on top of slices 1-5:

- `scripts/save_game.gd`: added `predators_on` and
  `crab_spider_attack_success_chance` to `SAVED_SETTINGS`. Needed because
  `Levels.apply_config_overrides` (slice 2) checks a scenario's
  `config_overrides` keys against that same list, and neither field was
  on it -- turning predators on from a scenario file was blocked by the
  very allowlist the plan says to reuse. Same fix as a side effect makes
  both fields survive an ordinary save/load too, which they didn't
  before (previously only reachable from the debug panel, per-session).
- `test_scenarios/slice6_crab_spider_test.json`: level 4's shape (15
  cells, 8/3 foragers, 2 nurses/builders/miners), weather/disease/
  rival_hive/winter all explicitly off to isolate the crab-spider effect
  from other death causes, `predators_on: true` and `seconds_per_day: 20`
  via `config_overrides`, 60-day stop. No `time_scale` override -- takes
  slice 3's now-default 30x.
- Ran it for real with `run_scenario.py --repeat 5 --full` (five live
  `Godot.exe --headless` launches). Result: `predators_on`'s
  `mechanic_firing` came back `fired: true` in all 5 runs
  (`runs_with_toggle_on: 5, runs_that_fired: 5`) -- not a one-run fluke.
  Across the 5 runs, `crab_spider_event` logged 23 events total (22
  escapes, 1 kill) -- a 1-in-23 (~4.3%) kill rate against the configured
  `crab_spider_attack_success_chance` of 5%, consistent with that number
  within the noise of a 23-sample run. `deaths_by_cause` showed "crab
  spider ambush" only where a kill actually landed (1 of 5 runs), "old
  age" as the rest of each run's ~20 deaths -- matches
  `balance_tests.py`'s own crab-spider model (~1 colony kill per 19-25
  days for the dominant flower species) rather than contradicting it.
  This directly answers `NEXTSTEPS.md`'s slice 6 question: the mechanic
  fires reliably and its observed kill ratio tracks its configured
  chance.
- `source_checks.py`, `balance_tests.py` and `FUNCTION_MAP.md --check`
  all clean.
- Not yet committed to git -- Dave hasn't reviewed the diff yet (this is
  on top of slices 2-5's still-uncommitted diffs below).

## What slice 5 of the playtest harness actually did

Built and self-verified this session (20 Aug 2026), on top of slices 1-4:

- `tools/analyze_session.py`: new module (imported by `run_scenario.py`,
  not a script of its own). `analyze(entries)` turns one run's parsed
  `session_*.jsonl` lines into the richer view `AI_PLAYTEST_PLAN.md`
  asks for -- a population curve (total + by-role per snapshot), deaths
  over time (each death with a running by-cause/by-role tally, so *when*
  a cause started piling up is visible, not just the final total),
  honey-cell fill fraction paired with `winter_here` per snapshot, and a
  `mechanic_firing` check that reads each run's own `config` settings
  snapshot (`predators_on`, `auto_recruitment_on`, `scouting_on`) against
  the matching summary count (`crab_spider_events`,
  `recruitment_matches`, `scouting_settled`) so a toggle-on-but-zero-count
  run is flagged directly. `aggregate_runs(analyses)` takes N of those
  and reports min/mean/max on total deaths, gynes released, and deaths by
  cause/role, plus (for mechanic firing) how many of the runs that had a
  toggle on actually logged at least one event -- one unlucky run not
  firing is expected, every run not firing points at something unwired.
- `tools/run_scenario.py`: added `--repeat N` (runs the scenario N times,
  prints each run's summary, then the aggregate range) and `--full`
  (prints the whole per-run analysis dict instead of just the summary
  line). Single-run, no-`--full` behaviour is unchanged from slice 4.
- Verified `analyze_session.py` against a real `session_*.jsonl` already
  on disk from earlier slices (config/snapshot/summary lines, no deaths
  or crab-spider events in that one) -- parses cleanly, all four analysis
  pieces come back the right shape. Verified `aggregate_runs` against
  synthetic two-run data with a deliberately-mixed `fired` flag, to
  confirm `all_fired` correctly comes back `false` when only one of two
  toggle-on runs logged an event.
- End-to-end: ran `slice1_smoke_test.json` with `--repeat 2` for real
  (two live `Godot.exe --headless` launches) -- one run had a death, the
  other didn't, and the aggregate's `total_deaths` range (`min:0,
  mean:0.5, max:1`) reflected that correctly rather than hiding it behind
  a single point. Also ran the same scenario with `--full` and got a
  correctly-shaped (if mostly flat, since the scenario is only ~2
  in-game days) population curve. `mechanic_firing` came back empty for
  both, as expected -- none of the existing test scenarios turn a
  toggle on; exercising that path for real is slice 6's job, not this
  one's.
- `source_checks.py`, `balance_tests.py` and `FUNCTION_MAP.md --check`
  all clean (no `.gd` changes this slice -- pure Python addition, same
  as slice 4).
- Not yet committed to git -- Dave hasn't reviewed the diff yet (this is
  on top of slices 2-4's still-uncommitted diffs below).

## What slice 4 of the playtest harness actually did

Built and self-verified this session (20 Aug 2026), on top of slices 1-3:

- `tools/run_scenario.py`: shells out to
  `Godot.exe --headless --path . -- --scenario=<path>` (same invocation
  slices 1-3 were verified with), waits with a real-world timeout
  (`--timeout`, default 300s) via `subprocess.run`, then finds the
  newest `session_*.jsonl` under
  `%APPDATA%\Godot\app_userdata\Meadow\logs\` that's newer than the
  run's own start time (so a stale file from an earlier run or Dave's
  own play can't be mistaken for this run's output), and prints its
  `summary` line as formatted JSON.
- Ran it against `test_scenarios/slice1_smoke_test.json`: completed in
  one command, printed the same `outcome: "max_days"` summary the slice
  1 manual check found by hand, no errors.
- `source_checks.py`, `balance_tests.py` and `FUNCTION_MAP.md --check`
  all clean (no `.gd` changes this slice -- pure Python addition).
- Not yet committed to git -- Dave hasn't reviewed the diff yet (this is
  on top of slice 3's still-uncommitted diff below).

## What slice 3 of the playtest harness actually did

Built and self-verified this session (20 Aug 2026), on top of slices 1-2:

- `main.gd::_apply_scenario_boot_arg()`: reads an optional top-level
  `"time_scale"` field from the scenario JSON (erased from the dict
  before it's handed to `Levels.scenario_override`, same pattern as
  `stop`/`config_overrides`) and sets `Engine.time_scale` from it instead
  of always hardcoding 8.0. Deliberately not routed through
  `Levels.apply_config_overrides`'s `GameConfig` allowlist -- it's an
  `Engine` setting, not a balance number.
- `test_scenarios/slice3_timescale_{8x,16x,30x}_test.json`: three
  otherwise-identical level-4-shaped scenarios (30-day stop,
  `seconds_per_day` overridden to 20 to keep the real-world run time
  short), one per multiplier, to answer `AI_PLAYTEST_PLAN.md`'s "Open
  risk" question directly.
- Ran all three headless via the same direct `Godot.exe --headless`
  invocation slice 1 used. Result: `total_deaths` (17),
  `deaths_by_cause` (`{"old age": 17}`) and `deaths_by_role`
  (`{"BUILDER":2,"FORAGER":11,"MINER":2,"NURSERY":2}`) came back
  byte-identical across 8x/16x/30x, and `game_time` at the day-30 cutoff
  matched to within half a second across all three. No corpses piling
  up, no negative resources, no errors logged at any multiplier. The
  small differences in the day-29 snapshot's exact role/state
  distribution between runs are ordinary frame-timing stochasticity
  (present between any two runs regardless of time_scale), not a
  time_scale artifact.
- Conclusion: 30x is safe for this scenario class (no rival hive, no
  crab spiders/disease active) and is now the dev-path default when a
  scenario doesn't set `"time_scale"` itself -- a scenario can still ask
  for a lower value if a future test finds a scenario class where 30x
  isn't safe (e.g. one with crab spiders or a rival hive active, not
  covered by this slice's scenario).
- `source_checks.py`, `balance_tests.py`, `FUNCTION_MAP.md --check`
  (regenerated) and a `mcp__godot__` boot (normal, non-scenario path) all
  clean. Re-ran the slice 1 smoke test scenario too, to confirm the new
  30x default doesn't break the existing auto-quit path -- no
  regression.
- Not yet committed to git -- Dave hasn't reviewed the diff yet.

## What slice 2 of the playtest harness actually did

Built and self-verified this session (20 Aug 2026), on top of slice 1:

- `levels.gd`: new `apply_config_overrides(overrides: Dictionary)` static
  func -- checks each key against `SaveGame.SAVED_SETTINGS` (the same
  per-field allowlist a save file is already restricted to), writes
  allowed keys straight to `GameConfig`, and `push_error`s + skips any
  unknown/disallowed key rather than aborting the whole boot or silently
  doing nothing. Lives in `levels.gd` (not `main.gd`) because
  `GameConfig` writes are file-allowlisted by
  `source_checks.py::check_gameconfig_writes`, and `levels.gd` is
  already on that list.
- `main.gd::_apply_scenario_boot_arg()`: pulls `config_overrides` out of
  the parsed scenario JSON (same pattern as the existing `stop` block)
  and calls `Levels.apply_config_overrides()` with it, before the level
  itself is built.
- `test_scenarios/slice2_config_overrides_test.json`: one real override
  (`seconds_per_day`) plus one deliberately-invalid key
  (`bogus_key_not_allowed`), to exercise both paths in one run.
- Verified with the same direct `Godot.exe --headless` invocation slice
  1 used: the bad key logs an `ERROR` and is skipped, the run still
  completes and quits at the configured day, and the resulting
  `session_*.jsonl`'s `config` line shows `seconds_per_day: 200.0`
  applied with no trace of the bogus key. Re-ran the slice 1 scenario
  too -- no regression. `source_checks.py`, `balance_tests.py` and
  `FUNCTION_MAP.md --check` (regenerated) all clean.
- Not yet committed to git -- Dave hasn't reviewed the diff yet.

## What slice 1 of the playtest harness actually did

Built and self-verified end-to-end this session (20 Aug 2026), no
waiting on Dave needed for this one -- it's the mechanism itself, not
anything judged by eye:

- `levels.gd`: added `SCENARIO_LEVEL_ID`, a `scenario_override`
  dictionary, and `get_level(id)` -- every site that used to read
  `LEVELS.get(Session.starting_level, {})` directly (`main.gd`,
  `world_building.gd` x4, `year_winter.gd`, `season.gd`) now calls
  `get_level()` instead, so a scenario-loaded level reuses the same
  lookup rather than a parallel one.
- `main.gd`: `_apply_scenario_boot_arg()` reads `--scenario=<path>`
  (`OS.get_cmdline_user_args()`), parses the JSON, installs it as
  `Levels.scenario_override`, points `Session.starting_level` at it,
  skips the main menu, sets `Engine.time_scale = 8.0` (the existing
  player-facing ceiling, not past it), and calls
  `Session.reset_run_state()` -- needed because `DiagnosticLog` only
  ever opens a session file off `Session.run_reset`, which a normal
  boot never fires (only Restart/New Run/Load do). `_end_scenario_run()`
  closes the diagnostic log and calls `get_tree().quit()`; wired into
  `_check_for_loss()` (queen death) and a new max-days check in
  `_process()`.
- `test_scenarios/slice1_smoke_test.json`: level 4's shape plus
  `stop.max_days`, used as the self-check scenario.
- Verified by running
  `"C:\Program Files\Godot\Godot.exe" --headless --path . -- --scenario=test_scenarios/slice1_smoke_test.json`
  directly: process exits on its own (exit code 0) at the right day, and
  the resulting `session_*.jsonl` under
  `%APPDATA%\Godot\app_userdata\Meadow\logs\` has a real `config` line,
  hourly `snapshot` lines with the scenario's exact starting population
  (11 foragers split 8/3, 2 nurses, 2 builders, 2 miners, 15 built cells
  + 1 unbuilt), and a `summary` line reading
  `"outcome":"max_days"` at the configured day. `source_checks.py`,
  `balance_tests.py`, `FUNCTION_MAP.md --check` and a `mcp__godot__`
  boot (normal, non-scenario path) all clean.
- Not yet committed to git -- Dave hasn't reviewed the diff yet.

## Waiting, lower priority

- The non-fog worst-frame cost (a genuine engine/render-thread cost, not
  anything in GDScript) -- `perf.gd` has hit its ceiling on it; next step
  is Godot's own Debugger > Profiler, not more work in `perf.gd`.
- Scouting/recruitment split and bee individuality -- shipped, exercised
  incidentally, never explicitly confirmed.
- Re-measure `bee_movement.gd` with `perf.gd`.
- Depth in what exists: nurse-mediated caste switching, comb temperature,
  multi-storey comb.
- A second hive site to move to.
