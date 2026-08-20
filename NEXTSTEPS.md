# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log` and the Notion Build Log.

## Next up

1. **AI playtest harness, slice 3: test time_scale past the 8x ceiling
   for physics artifacts.** Slices 1 and 2 are built and self-verified
   (see below) -- full design in `AI_PLAYTEST_PLAN.md`, build order at
   its end. Slice 3 is `AI_PLAYTEST_PLAN.md`'s "Open risk" section:
   compare a short run's outcome at a few `Engine.time_scale` multipliers
   (8x, 16x, 30x) and check population/death numbers hold steady before
   trusting anything faster than the player-facing 8x cap for headless
   runs; whatever stays stable becomes the dev-path default. Slice 4
   (`tools/run_scenario.py`) is next after that.
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
