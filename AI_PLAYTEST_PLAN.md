# AI playtest / headless scenario harness — plan

Status: built, 20 Aug 2026 -- all six slices below done and
self-verified, `source_checks.py`/`balance_tests.py` pass. Slice 6 ran
`test_scenarios/slice6_crab_spider_test.json` for real and confirmed
`crab_spider_event` fires reliably (5/5 runs) at a kill ratio consistent
with `crab_spider_attack_success_chance` -- see `NEXTSTEPS.md`'s slice 6
write-up for the numbers. Written from a
planning conversation in the Meadow Cowork Project, checked against what
the codebase already has (`game_config.gd`, `levels.gd`, `diagnostic_log.gd`,
`session.gd`, `hud.gd`, `camera_view.gd`, `main.gd`, `project.godot`,
`.claude/rules/saving.md`) and against what the installed Godot MCP server
(`@coding-solo/godot-mcp`, configured in `.mcp.json`) actually exposes.

## The question this answers

Dave asked: can Claude Code "play the game" itself, to gather insight and
check things are working as intended, including building its own bespoke
test scenarios with chosen settings, even without literal screen control?

Short answer: partly, and the missing third is small. Two of the three
pieces a real answer needs already exist in this codebase; only the third
(driving an unattended run and turning its output into a verdict) is
missing, and it's a small addition on top of what's already there rather
than new architecture.

## What already exists that this can reuse

- **`DiagnosticLog`** (`scripts/diagnostic_log.gd`, autoload, built
  19-20 Aug 2026, see `DIAGNOSTIC_LOGGING_PLAN.md`). Writes one
  `session_<unix_time>.jsonl` file per run to `user://logs/`
  (`%APPDATA%\Godot\app_userdata\Meadow\logs\` on Windows), keeping the
  last 5. Entry types: `config` (every `GameConfig` value via reflection),
  `death` (cause, role, location, stats), hourly `snapshot` (population by
  role/state, resources, cell contents, environment, foraging behaviour,
  crab spider activity), `crab_spider_event`, `recruitment_match`,
  `scouting_settled`, and a `summary` at session end (outcome, totals,
  deaths by cause/role, gynes released). This is already the exact shape
  of data a playtest question needs an answer from — it just currently
  only gets written during Dave's own hands-on play or a `mcp__godot__`
  boot-and-watch check, never a run built specifically to answer a
  question.
- **`levels.gd`**'s `LEVELS` dict is already a clean starting-state preset
  format (`cells`, `nectar_foragers`, `pollen_foragers`, `nurses`,
  `builders`, `miners`, `weather`, `disease`, `rival_hive`, `winter`,
  `stock`, `unlocks`, `win_conditions`) — a scenario format doesn't need
  inventing, it needs reusing.
- **`GameConfig`**'s write-allowlist (`.claude/rules/saving.md`) already
  defines which balance numbers are safe to override and from where — any
  scenario-driven override should go through the same allowlist, not
  around it.
- **`Engine.time_scale`** already scales the whole simulation (used by
  the in-game speed control: `hud.gd`'s `SPEEDS` array up to 8x, applied
  in `camera_view.gd::_on_speed_requested`, reset to `1.0` in several
  places in `main.gd`/`debug_panel.gd`). Nothing in the engine caps it at
  8x — that's a UI choice — so a dev-only path can push it further.
  "Presentation may be skipped; simulation may not" already establishes
  that off-screen and on-screen bees must behave identically, which is
  the same guarantee a headless, unrendered run needs.
- **`balance_tests.py`** already exists and says outright what it can't
  do: "There is no Godot here, so these can't test behaviour — only
  arithmetic and the feedback loops." This harness is that sentence's
  natural next step, not a replacement for it.

## What's missing

Confirmed by checking `@coding-solo/godot-mcp`'s actual tool list
(`launch_editor`, `run_project`, `get_debug_output`, `stop_project`,
`get_godot_version`, `list_projects`, `get_project_info`, scene/UID
tools): it launches the editor/project and reads console output, nothing
more. No headless flag, no input injection, no runtime GDScript execution,
no screenshots. Today it's a boot-and-watch-for-crashes tool, which is
exactly how `CLAUDE.md`/`.claude/rules/gdscript.md` already use it — not
a playtesting tool.

So three things don't exist yet:

1. A way to start a run with a chosen scenario without a human clicking
   through the main menu.
2. A way to let that run play out fast and unattended, then stop itself
   and record why.
3. A way to turn the resulting `session_*.jsonl` into an answer, without
   a human reading raw JSON.

## Proposed design

### 1. Headless scenario boot path (in-game, small addition)

- A `--scenario=<path>` command-line argument, read via
  `OS.get_cmdline_user_args()` at boot. Guarded so it only ever applies
  in this dev path — never reachable from the main menu.
- When present: skip the main menu, load the JSON, apply it as a
  `levels.gd`-shaped starting state (reusing the existing loader path,
  not a parallel one) plus a small explicit `GameConfig` override block
  — same allowlist mechanism `saving.md` already enforces, so a scenario
  file can't touch anything a save file couldn't already touch.
- Set a stop condition from the scenario file: queen death (already a
  real trigger, `game_over.gd`), a day limit, or an event-count limit
  (e.g. stop once 20 `crab_spider_event`s have logged). On stop, call the
  existing `DiagnosticLog.end_session(...)` and `get_tree().quit()`, so
  one run is one command with a defined exit rather than something that
  has to be watched.
- Launch it headless with Godot's own `--headless` flag directly against
  the installed binary (`C:\Program Files\Godot\Godot.exe`, per
  `.mcp.json`), not through `mcp__godot__run_project` — that tool doesn't
  expose headless mode or a way to pass this argument through.

### 2. Scenario files (the bespoke settings Claude chooses)

Plain JSON in a new `test_scenarios/` folder, one file per question being
asked, e.g.:

```json
{
  "cells": 10, "nectar_foragers": 4, "pollen_foragers": 4,
  "nurses": 2, "builders": 1, "miners": 0,
  "weather": true, "disease": true, "rival_hive": false, "winter": true,
  "config_overrides": {"crab_spider_density": 2.0},
  "stop": {"max_days": 90, "on_queen_death": true}
}
```

`config_overrides` keys are checked against the existing `GameConfig`
write-allowlist at load time — an unknown or disallowed key fails loudly
rather than silently doing nothing.

### 3. Runner + analysis (outside Godot, Python — mirrors `balance_tests.py`)

- `tools/run_scenario.py`: shells out to
  `Godot.exe --headless --path . -- --scenario=test_scenarios/x.json`,
  waits with a real-world timeout (a runaway sim shouldn't hang a
  session), then finds the newest `session_*.jsonl` and hands it to the
  analyser.
- Analysis turns the log into the actual insight: population curve,
  deaths by cause/role over time, honey-cell fill rate against the winter
  countdown, and specifically whether `crab_spider_event` /
  `recruitment_match` / `scouting_settled` counts are nonzero when their
  toggles are on — the exact "is this mechanic actually firing" question
  `DIAGNOSTIC_LOGGING_PLAN.md`'s 20 Aug extension was written to answer,
  now answerable without Dave watching the meadow by eye.
- Bee behaviour has randomness (scouting, trait rolls), so the runner
  should support N repeats of one scenario and report a range, not a
  single point, before Claude concludes anything about balance from it.

## What this deliberately doesn't attempt

Real input injection or literally controlling the screen moment to
moment (clicking, dragging, watching the UI render). The installed Godot
MCP server doesn't support it, and building a custom debug RPC into the
running game to allow it is a much bigger lift for a narrower payoff than
the headless route above, which answers the balance/behaviour questions
that actually motivated the ask. For anything that can only be judged
visually — art, animation, UI layout, a bug that only reproduces by
clicking through a specific sequence — the existing pattern stays the
answer: `mcp__godot__run_project` to boot and watch for errors, and
Dave's own hands-on play for everything else. `CLAUDE.md` already says
this outright about today's tooling ("Nothing here replaces Dave's
hands-on check... say so rather than implying it's verified") and that
stays true once this harness exists too.

If literal screen control is ever worth the cost later (confirming a
visual regression from a written repro, say), the device's own
`computer_*` screen-control tools are the fallback route, not the Godot
MCP — worth knowing it's there, not worth building around for balance
work.

## Open risk to test before trusting results

Very high `Engine.time_scale` multipliers mean very large per-frame
`delta` values. Steering/movement code that assumes reasonably small
steps (`bee_movement.gd`) could behave differently at, say, 30x than at
the player-facing 8x ceiling — overshooting a target in one frame that
would normally take several. Before trusting any scenario result run
above 8x, compare a short run's outcome at a few multipliers (8x, 16x,
30x) against each other; if population/death numbers hold steady across
them, the speed is safe to use for that class of question. If they don't,
cap headless runs at whatever multiplier stays stable rather than
assuming faster is free.

## Suggested build order (small slices)

All six done -- see `NEXTSTEPS.md` for what each slice actually built.

1. `--scenario=` boot arg + auto-quit on queen death, reusing the
   *existing* `LEVELS` shape untouched and the *existing* 8x speed cap.
   No new JSON format, no config overrides yet — this slice only proves
   the unattended run-to-collapse mechanism works and that
   `DiagnosticLog`'s summary line is trustworthy end to end.
2. Add the `config_overrides` block and the allowlist check.
3. Test time_scale past 8x for the physics-artifact risk above; set
   whatever ceiling turns out stable as the dev-path default.
4. `tools/run_scenario.py` — single scenario, single run, print the
   summary line.
5. N-repeat batch mode plus the richer analysis (curves, mechanic-firing
   checks).
6. First real scenario: something crab-spider-related, given how much
   attention that system has had this week (`CRAB_SPIDER_PLAN.md`) and
   that `DIAGNOSTIC_LOGGING_PLAN.md`'s own crab-spider event types exist
   specifically because that mechanic's effect is invisible by eye.

Each slice keeps `source_checks.py`/`balance_tests.py` passing and a
`mcp__godot__` boot clean, same as every other slice in this codebase.
