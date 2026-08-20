# Diagnostic logging system — implementation plan

Status: built, 19 Aug 2026 -- `source_checks.py`/`balance_tests.py` pass
and a Godot boot is clean, but this still needs Dave's own hands-on
check (Phase 4 below) before it's considered confirmed.

**Extended 20 Aug 2026** to answer a question Dave's own hands-on crab
spider playtest raised directly: watching bees get attacked in the
meadow doesn't tell you whether alarm pheromone, recruitment, floral
constancy or scouting are actually doing anything -- their effect is a
bee *not* doing something, which is invisible by eye. `diagnostic_log.gd`
now writes three new discrete event types and two new snapshot sections,
purely additive to what Phase 1-4 below already built:

- **`crab_spider_event`** (new type) -- one line per attack outcome
  (`"kill"`/`"escape"`) and per alarm-pheromone flee (`"alarm_flee"`),
  written from `crab_spider.gd`'s `resolve_attack()`/`flee_alarm()`
  (new). Carries `bee_id`, `role`, the flower's `species`, `outcome` and
  `location`. A `predators_on` run with zero of these lines is now
  direct evidence the mechanic isn't actually firing, rather than
  something only inferable from an absence of "crab spider ambush" in
  the death log (which only ever covers the kill case, not escapes or
  alarm flees). The summary line's `crab_spider_events` tallies each
  outcome for the whole run.
- **`recruitment_match`** (new type) -- one line whenever a seeker at the
  entrance is handed a mentor's patch in `wait_at_entrance()`. Carries
  both bees' ids, resource type, and the patch (start point + species)
  handed over. Summary's `recruitment_matches` tallies the run total.
- **`scouting_settled`** (new type) -- one line whenever a scouting bee's
  three bouts are all in and `_score_trip()` commits her (or fails to,
  if every bout came back empty -- `found_patch: false`). Summary's
  `scouting_settled` tallies the run total.
- **Snapshot gains `foraging_behaviour`** (`floral_constancy_on`/
  `scouting_on`/`auto_recruitment_on` echoed alongside live counts:
  `scouting_now`, `with_preferred_species` by species,
  `entrance_mentors_waiting`) and **`crab_spiders`** (`predators_on`/
  `alarm_pheromone_on`/`recruit_suppression_on` echoed alongside
  `preferred_species` and a live `active_spiders` count) -- so an hourly
  snapshot alone answers "is this system doing anything right now"
  without needing to have caught a discrete event in the same window.

None of this needed a `GameConfig` change (write-allowlist untouched)
or a new autoload -- everything hangs off the existing `DiagnosticLog`
singleton and its existing `_write()`/session-boundary machinery. See
`CRAB_SPIDER_PLAN.md`'s own 20 Aug follow-up entry for the two other
fixes this same playtest surfaced (the dev spider-reveal toggle and the
alarm-pheromone visual cue, both presentation-only).

One design change from the original plan as written: rather than wiring
`DiagnosticLog.start_session()` into each `reset_run_state()` call site
by hand, `Session` now emits a `run_reset` signal at the end of
`reset_run_state()` and `DiagnosticLog` listens for it -- found while
implementing that there are three call sites, not the two the plan
names (a third in `debug_panel.gd`'s own Restart button), so the signal
covers all of them, including any future one, without needing to be
re-audited. `start_session()` also calls `end_session("quit")` on itself
first (a no-op if the previous session already got a "collapsed"
summary), so a run abandoned mid-play without the queen dying still
gets a real summary line before the next file opens -- this subsumes
the plan's separate "menu-return route" wiring bullet.

This turns the spec Dave wrote into a
concrete build plan, grounded in what the codebase actually has (checked
19 Aug 2026 against `scripts/game_config.gd`, `bee_survival.gd`,
`bee_enums.gd`, `hive_cell.gd`, `session.gd`, `season.gd`, `main.gd`).
Each "open item" the spec flagged is answered below rather than left as
a to-do, and a few spec fields are adjusted to match what actually
exists so the log doesn't describe a game the code doesn't have yet.

Session boundary (confirmed with Dave): **one file per run**, not per
game launch. A new file starts at Restart Run, New Run, and Load — the
two places `main.gd` already calls `Session.reset_run_state()` (lines
~780 and ~788) are the hook points. Rotation (keep last 5, delete
oldest) fires at that same moment.

## What already exists that this can reuse

- **Three autoloads already do exactly this kind of job**: `GameConfig`
  (balance numbers), `Session` (run/UI state), `Perf` (instrumentation).
  `DiagnosticLog` should be a fourth, registered in `project.godot`'s
  `[autoload]` block next to them — it's instrumentation like `Perf`,
  not balance or UI state, so it doesn't fit CLAUDE.md's existing
  GameConfig/Session split.
- **One choke point for every death**: `BeeSurvival.die()` in
  `bee_survival.gd` is already the only place a bee dies (starvation,
  old age, and anywhere future causes get added). The death log entry
  hooks in here, not in `bee.gd`.
- **`Session.sim_time`** is the existing in-game clock (seconds,
  advanced by `main.gd`, already saved with the run) — this is
  `game_time` for every entry.
- **`world.day`** (int) is the existing day counter, read by
  `season.gd` for winter/gyne timing.
- **Rate averages already exist**: `hive.gd`'s comment at line 33-34
  points at "main.gd's rate-sampling" backing the colony panel's
  "rates" readout (nectar/pollen coming in, bees emerging, averaged
  over the last minute). The snapshot's `pollen_rate_avg`/
  `nectar_rate_avg` should read that existing sampler, not recompute
  their own average.
- **`hive.gd::total_honey()`** and **`cells_holding(content: String)`**
  already exist for totalling stores and counting cells by content —
  reuse both for `resources.food_stores` and `cells.by_contents`.
- **Enum-to-name without a hand-maintained list**: `bee_enums.gd`'s
  `Role` and `State` enums are Godot dictionaries under the hood, so
  `BeeEnums.Role.keys()[bee.role]` and `BeeEnums.State.keys()[bee.state]`
  give the string name directly. `bee_enums.gd`'s own header comment
  says new states/roles are always *appended*, never inserted, exactly
  so save-file ints never shift — which also means this reflection
  trick stays correct forever without maintenance.
- **Reflection also solves the config-snapshot to-do**: rather than
  hand-copying `game_config.gd`'s ~155 tunables into the log code (which
  will drift the next time a value is added, and there've been several
  added this month alone), read `GameConfig.get_property_list()` at
  runtime, filter to script-declared properties, and dump
  `GameConfig.get(name)` for each. This is the single biggest
  improvement over the spec as written — it's exactly the kind of list
  the spec says "needs a pass over the codebase" to build, and a runtime
  pass never goes stale the way a written-out list will.

## Spec fields that don't match what's built yet

The spec's JSON shapes assume a few systems that aren't in the code.
Rather than fake them, the plan below either substitutes the real
equivalent or leaves the field out with a comment explaining why.

- **`cause` (death event)** — not currently tracked as data. `die()`
  takes no reason; `_announce_death()` re-derives "old age" vs
  "starvation" from a ternary *after* the bee is already gone. Worth
  fixing properly rather than duplicating that ternary a third time (see
  Phase 1, and the bug below).
- **`by_mode` (population snapshot)** — the spec's idle/working/
  resting/sick isn't a real state grouping in the code. What exists is
  `Role` (7 values: forager, nursery, builder, egg_layer, idle, miner,
  honey_maker — no separate "drone" caste is implemented, only in the
  design doc) and `State` (54 granular values like `TO_FLOWER`,
  `CHEWING`, `SHELTERING`). Recommend logging **`by_role`** (the real
  caste-ish grouping already in the game) and **`by_state`** (raw
  counts per state, via the reflection trick above) instead of
  inventing a "mode" bucket that isn't backed by anything. This is
  richer than the spec's four-way split anyway, and Claude can bucket
  states into idle/working/travelling itself at review time if that
  view is useful — no need to bake a lossy grouping into the log.
- **`cells.by_contents`** — real `content_type` values are `""`
  (empty), `nectar`, `pollen`, `honey`, `brood` (covers egg *and*
  larva — no separate content type, only `brood_progress`), and
  `corpse`. There's no `capped_brood`; capping/sealing is a separate
  `closed` flag a player sets, orthogonal to content. Recommend logging
  the real content types plus a `sealed` count and an `unbuilt` count
  (build sites, `is_built == false`) rather than the spec's invented
  `capped_brood` bucket.
- **`environment.hive_temp`** — there is no hive temperature system at
  all yet (it's on the hive-management skill tree in the design doc,
  unbuilt). Leave this field out entirely rather than log a fake 0.0 —
  a diagnostic file with a permanently-zero field is worse than one
  that's honest about not having the data, and it's a five-minute add
  to `snapshot()` once temperature ships.
- **`environment.weather`** — there's no weather string, only
  `Session.rain_intensity` (float 0-1) and `GameConfig.weather_on`
  (bool). Log `rain_intensity` directly — it's strictly more useful for
  correlating with deaths than a coarse string would be (rain also
  raises flight energy burn via `GameConfig.rain_flight_burn_factor`,
  so intensity is exactly the number you'd want to check against a
  death cluster).
- **`environment.season`** — no season *name* string exists, only
  `Flower.season_fraction()` (0-1 through the year) and
  `GameConfig.seasons_on`. Log the fraction; it's what the game itself
  uses for the same decisions (gyne release timing, disease severity).
- **`outcome` (session summary)** — there's currently exactly one
  "game over" trigger: the queen dying (`game_over.gd`, "The queen is
  dead"). There's no win condition yet — `CLAUDE.md`'s definition of
  done and `DESIGN_BACKLOG.md` both still list win/loss beyond
  "survive winter" as undecided. Recommend three real values for now:
  `collapsed` (queen died), `quit` (returned to menu or closed the
  window with the colony still alive), and reserve `survived` for once
  an actual win condition ships — don't write a `survived` outcome that
  doesn't correspond to anything the game currently decides.

## A bug this surfaced

`bee_survival.gd::_announce_death()` (line 343) works out the death
cause **after** `die()` has already run, by re-checking
`age_seconds >= lifespan_seconds(bee)`. But `age_and_burn()` calls
`die(bee); return` on the starvation check *before* it ever reaches the
age check — so if a bee is both starving and past its lifespan in the
same frame, it dies via the starvation branch, but the epitaph text
will say "old age" (the ternary checks age first). Low-stakes today
(it only affects the toast wording), but it means the spec's `cause`
field can't just copy that ternary — it needs to record the *actual*
branch that fired, which Phase 1 below does by passing `cause` into
`die()` directly instead of re-deriving it.

## Implementation plan

### Phase 1 — death cause becomes real data (small, do first)

- Change `BeeSurvival.die(bee: Node2D)` to `die(bee: Node2D, cause: String)`.
- Update `age_and_burn()`'s two call sites to pass `"starvation"` and
  `"old age"` explicitly (fixes the bug above as a side effect).
- Store `bee.death_cause = cause` at the top of `die()`, on a new
  `var death_cause: String = ""` field in `bee.gd`.
- `_announce_death()` reads `bee.death_cause` instead of re-deriving it.
- Any other place that eventually calls `die()` (predators, pesticides —
  neither exists yet) will be forced to supply a cause by the signature
  change, so the log never silently gets an empty string once those
  ship.

### Phase 2 — `DiagnosticLog` autoload

New file `scripts/diagnostic_log.gd`, registered as a fourth autoload
in `project.godot`. Node-based (like `GameConfig`/`Session`/`Perf`),
since it needs to hold a file handle and small counters across frames,
not per-bee static helpers like the `bee_*.gd` files.

Responsibilities:

- `start_session()` — called from both `Session.reset_run_state()` call
  sites in `main.gd`. Closes any previous handle, prunes `user://logs/`
  to the 4 oldest-of-5 (so the new one becomes the 5th), opens
  `user://logs/session_<unix_time>.jsonl` for append, writes the config
  snapshot entry immediately, resets the in-memory death tally.
- `log_death(bee)` — called from `BeeSurvival.die()` right after
  `death_cause` is set. Writes and `flush()`s immediately (this is
  already a rare event, no separate buffering needed). Also increments
  the in-memory `deaths_by_cause`/`deaths_by_caste` tally kept for the
  summary, so the summary doesn't need to re-read the file.
- `_process(delta)` — mirrors `season.gd`'s own pattern: accumulate
  `delta`, only do anything once a full in-game hour has passed
  (`GameConfig.seconds_per_day / 24.0`), so this is a once-an-hour
  comparison, not per-frame work. Writes and flushes a snapshot entry.
- `end_session(outcome: String)` — called from `game_over.gd`'s trigger
  (outcome `"collapsed"`), from the menu-return path (`"quit"`), and
  from a new `NOTIFICATION_WM_CLOSE_REQUEST` handler (also `"quit"`) —
  **this notification doesn't exist anywhere in the codebase today**,
  so closing the game window currently loses whatever's only in memory.
  Writes the summary entry, flushes, closes the file handle. Guarded
  by a boolean the same way `bee.is_dying` guards `die()`, so a queen
  death followed immediately by a window close can't write two
  summaries for one run.

### Phase 3 — wiring

- `main.gd`: call `DiagnosticLog.start_session()` at both
  `Session.reset_run_state()` sites; add the close-request handler.
- `bee_survival.gd`: call `DiagnosticLog.log_death(bee)` in `die()`.
- `game_over.gd` or wherever it's shown from: call
  `DiagnosticLog.end_session("collapsed")`.
- Menu-return path (`game_over.menu_requested` handler in `main.gd`,
  and the ordinary "back to menu" route if the colony is still alive):
  call `DiagnosticLog.end_session("quit")`.

### Phase 4 — verification

- `python3 tests/source_checks.py` / `python3 tests/balance_tests.py`
  both stay clean (the new autoload adds no `GameConfig` writes, so the
  write-allowlist guardrail is untouched).
- Godot boot via `mcp__godot__run_project` / `get_debug_output`, no new
  parser/type errors.
- Dave's own check (this is the one thing nothing above substitutes
  for): play a short run to a restart, confirm exactly one
  `session_*.jsonl` file per run appears under `user://logs/`
  (`user://` on Windows is normally
  `%APPDATA%\Godot\app_userdata\Meadow\logs\`), that it has a config
  line, at least one hourly snapshot, and a summary line with sane
  totals; kill the window with the OS close button mid-run and confirm
  a summary line still lands; run six restarts in a row and confirm
  only 5 files remain.

## Entry shapes (as they'll actually ship)

```json
{"type": "config", "game_time": 0.0, "settings": { /* every GameConfig var, via reflection */ }}
```

```json
{"type": "death", "game_time": 8143.2, "bee_id": 42, "role": "forager",
 "is_queen": false, "is_gyne": false, "state": "TO_HIVE",
 "in_hive": false, "location": [812.4, -140.1], "cause": "starvation",
 "stats": {"energy": 0.0, "age_seconds": 71200.5}}
```

```json
{"type": "snapshot", "game_time": 8280.0, "day": 41,
 "population": {"total": 34, "by_role": {"forager": 14, "nursery": 6,
   "builder": 4, "egg_layer": 1, "idle": 3, "miner": 0, "honey_maker": 2,
   "gyne": 4}, "by_state": {"TO_FLOWER": 6, "SHELTERING": 2, "...": "..."}},
 "resources": {"pollen_rate_avg": 1.8, "nectar_rate_avg": 4.2,
   "food_stores": 3120.0},
 "cells": {"total": 60, "by_contents": {"": 12, "nectar": 14,
   "pollen": 6, "honey": 9, "brood": 15, "corpse": 1}, "sealed": 4,
   "unbuilt": 3},
 "environment": {"rain_intensity": 0.0, "season_fraction": 0.55,
   "disease": 0.02, "winter_here": false},
 "foraging_behaviour": {"floral_constancy_on": true, "scouting_on": true,
   "auto_recruitment_on": true, "scouting_now": 3,
   "with_preferred_species": {"Clover": 9, "Poppy": 2},
   "entrance_mentors_waiting": 1},
 "crab_spiders": {"predators_on": true, "alarm_pheromone_on": true,
   "recruit_suppression_on": true, "preferred_species": "Clover",
   "active_spiders": 4}}
```

```json
{"type": "summary", "game_time": 92100.0, "day": 63, "outcome": "collapsed",
 "total_deaths": 19, "deaths_by_cause": {"starvation": 15, "old age": 4},
 "deaths_by_role": {"forager": 11, "nursery": 5, "builder": 3},
 "gynes_released": 2, "crab_spider_events": {"escape": 6, "kill": 1, "alarm_flee": 4},
 "recruitment_matches": 9, "scouting_settled": 14}
```

Added 20 Aug 2026, alongside the snapshot's new `foraging_behaviour`/
`crab_spiders` sections shown in the snapshot example above:

```json
{"type": "crab_spider_event", "game_time": 15320.4, "bee_id": 17,
 "role": "forager", "species": "Clover", "outcome": "escape",
 "location": [640.2, -88.5]}
```

```json
{"type": "recruitment_match", "game_time": 15400.1, "seeker_id": 22,
 "mentor_id": 9, "resource_type": "nectar",
 "start_point": [712.0, -140.0], "species": "Clover"}
```

```json
{"type": "scouting_settled", "game_time": 15500.7, "bee_id": 22,
 "found_patch": true, "best_rate": 2.4,
 "start_point": [712.0, -140.0], "species": "Clover"}
```

(`stats` in the death event uses `energy`/`age_seconds` rather than the
spec's `hunger`/`temp`/`health`, because that's what a bee actually
tracks — there's no separate hunger, temperature, or health stat on a
bee, only `energy` and age against `lifespan_seconds()`.)

## Still worth Dave's call before Phase 2 starts

- **Hourly cadence at high time-acceleration**: if the game ever gets a
  fast-forward control, an in-game hour could pass in well under a
  second of real time. Not a problem today (no such control exists),
  but worth a mental note if that ships later — the snapshot cadence
  would need a minimum real-time gap too.
- **Is `by_state` (54 keys) too noisy for a quick read?** It's cheap to
  log and Claude can ignore keys that are all zero, so the plan above
  logs it in full — flag if a coarser view is actually preferred instead.
