# Headless-run contract

Status: Slice 0 baseline | Schema version: `1`

This is the single contract reference for the headless runner. It records the
formats that Slice 1 will produce; it does not change the current runner yet.
The runner remains the compatibility entry point, and existing scenario JSON
continues to work without any of the optional fields below.

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

## Output budgets

The Slice 0 fixtures make the baseline projections reproducible, and
`tools.headless.contracts.fits_stdout_budget` executes these limits. Slice 1
must apply it to the terminal presentation:

- passed `verdict` output: at most 1 KiB and normally one line;
- failed verdict output: at most 4 KiB; and
- expanded reports: retained as artefacts rather than printed by default.

The current `brief`, `behaviour`, and `full` projections are compatibility
baselines only; they are intentionally more verbose than the future verdict.
