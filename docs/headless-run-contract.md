# Headless-run contract

Status: Slice 3 implemented | Schema version: `1`

This is the single contract reference for the headless runner. The runner
remains the compatibility entry point, and existing scenario JSON continues
to work without an `expect` block.

Run one deterministic scenario with the compact default:

```
python tools/run_scenario.py test_scenarios/slice1_smoke_test.json
```

It creates a unique result directory under the system temporary directory
(`meadow-headless-results` by default), passes Godot an exact JSONL path, and
prints one line such as `status=passed run_id=... outcome=actions_resolved
result=.../result.json`. `--result-root` changes the managed artefact root;
the scenario cannot supply an output path. Explicit `--report brief`,
`behaviour`, `balance`, or `full` keeps the legacy presentation path.

## Choosing a run

Use the routing card instead of reading project plans or runner source:

```powershell
.\tools\run_headless.ps1 --route-help
```

It prints the seven short routing rules and exits without launching Godot. To
turn the five explicit facts into one deterministic route, use:

```powershell
.\tools\run_headless.ps1 -Route --needs-godot yes --adaptive no --comparison paired --time-series no --expected-seconds 12
```

The default response is exactly one line, for example
`route=experiment capture=behaviour seeds=3 background=no report=verdict`.
Pass `--explain` only when a human needs the matched rule. The facts are:

- `needs-godot`: whether Python/source checks cannot answer the question;
- `adaptive`: whether a required mid-run decision cannot be expressed by the
  existing semantic actions, triggers and assertions;
- `comparison`: `none`, `stochastic` or `paired`;
- `time-series`: whether a series is necessary rather than a final summary;
  and
- `expected-seconds`: expected wall-clock duration, which enables the
  background modifier above 30 seconds.

`adaptive=yes` with `needs-godot=no`, a negative duration and unknown enum
values are contract errors. The helper does not inspect a scenario, project
plan or natural-language task, and never calls a model.

`tools/run_headless.ps1` is the supported Windows entry point for the runner:

```powershell
.\tools\run_headless.ps1 test_scenarios/slice1_smoke_test.json
```

It resolves `python`, `python3` or the Windows `py -3` launcher, in that
order. If none is available, supply an explicit interpreter without embedding
a machine-specific path in repository instructions:

```powershell
.\tools\run_headless.ps1 -PythonPath C:\path\to\python.exe test_scenarios/slice1_smoke_test.json
```

## Artefacts

Each eventual run directory has these stable JSON artefacts:

- `result.json` is always written after a launched run reaches a terminal
  state. It is the compact machine verdict.
- `failure.json` is written only for a failed run or contract error. Its
  rendered form must be at most 4 KiB; raw JSONL and process output remain in
  the run directory.
- `report.json` is optional and is the selected report projection, never an
  automatic raw-log dump.

All three envelopes use `schema_version: 1`. New optional fields are allowed;
changing the meaning or type of an existing field requires a new version.

### `result.json`

```json
{
  "schema_version": 1,
  "status": "passed",
  "run_id": "a1b2c3d4",
  "scenario": {"path": "test_scenarios/example.json", "sha256": "..."},
  "seed": 4242,
  "diagnostics": {"profile": "verdict", "version": 1},
  "outcome": "actions_resolved",
  "simulated": {"seconds": 12.5, "day": 1},
  "actions": {"rejected": 0, "failed": 0, "unresolved": 0},
  "expectations": {"passed": ["queen_alive"], "failed": []},
  "process": {"exit_code": 0},
  "artefacts": {"session": "session.jsonl", "process_log": "process.log"}
}
```

`status` is one of `passed`, `failed`, `contract_error`, `timed_out`, or
`crashed`. `outcome` may be `null` when Godot did not write a summary. Paths
in `artefacts` are relative to the result directory, never scenario-supplied
absolute paths.

### `failure.json`

```json
{
  "schema_version": 1,
  "status": "failed",
  "run_id": "a1b2c3d4",
  "reason": {"kind": "expectation", "id": "no_deaths", "expected": 0, "actual": 1},
  "actions": [],
  "events": [],
  "snapshot": null,
  "artefacts": {"session": "session.jsonl", "process_log": "process.log"},
  "truncated": false
}
```

`reason.kind` is one of `expectation`, `action`, `assertion`, `contract`,
`timeout`, `crash`, or `missing_summary`. Event and action tails are bounded;
when data is omitted, `truncated` is true and the relevant artefact path is
present.

Godot prints `MEADOW_RESULT_PATH=<exact path>` after it closes the scenario
JSONL. The runner requires that sentinel and never infers a session directory
from the Godot project name, so `Meadow` and `Meadow - Claude` worktrees and
concurrent launches cannot select one another's logs.

## Scenario expectations

`expect` is optional. It is evaluated by Python only after the final evidence
is available, so it does not replace GDScript action assertions that stop a
run causally.

```json
{
  "expect": [
    {"id": "actions_clean", "metric": "actions.problems", "op": "empty"},
    {"id": "queen_alive", "metric": "summary.queen_alive", "op": "eq", "value": true},
    {"id": "death_bound", "metric": "summary.total_deaths", "op": "between", "min": 0, "max": 2}
  ]
}
```

An expectation has a unique optional `id`, a required allowlisted metric path
and `op`. `eq`, `ne`, `lt`, `lte`, `gt`, `gte` require `value`; `between`
requires numeric `min` and `max`; and `empty`, `not_empty`, `all_true`, and
`exists` take no comparison value. Unknown paths, unsupported operators and
type mismatches are `contract_error`, not failed game assertions.

## Diagnostic capture profiles

`diagnostics` is optional and applies only to a `--scenario` session; ordinary
manual play keeps its existing standard event and hourly-snapshot schema.
The runner validates the profile before it launches Godot, and the game applies
the same allowlist at boot. `verdict` retains action/death evidence and writes
no periodic snapshots by default. `behaviour` retains the named mechanic event
channels; `balance` and `performance` take a daily selected snapshot; `custom`
requires explicit allowlisted events and fields.

```json
"diagnostics": {
  "profile": "custom",
  "events": ["stall_recovery"],
  "snapshots": {
    "every_sim_seconds": 30,
    "fields": ["population.total", "resources.food_stores", "role_outcomes.cells_completed_total"],
    "only_when_changed": true
  },
  "limits": {"event_lines_per_type": 100, "snapshot_lines": 200}
}
```

Available snapshot fields are deliberately small and typed: `population.total`,
`resources.food_stores`, `environment.winter_here`,
`role_outcomes.cells_completed_total`, `performance.fps`, and
`performance.top_sections_ms`. Unknown fields, event names, profiles or invalid
limits are `contract_error` before process launch. Counters and summary facts
remain available to actions and expectations even when their raw event lines
are filtered.

## Output budgets

The Slice 0 fixtures make the baseline projections reproducible, and
`tools.headless.contracts.fits_stdout_budget` executes these limits. Slice 1
must apply it to the terminal presentation:

- passed `verdict` output: at most 1 KiB and normally one line;
- failed verdict output: at most 4 KiB; and
- expanded reports: retained as artefacts rather than printed by default.

The current `brief`, `behaviour`, and `full` projections are compatibility
baselines only; they are intentionally more verbose than the future verdict.
