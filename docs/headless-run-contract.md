# Headless-run contract

Status: Slice 5 implemented | Schema version: `1`

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

On Windows, every Godot launch is unattended: the runner disables Godot's
crash handler and temporarily applies the inherited no-dialog error mode while
starting the child process. An engine crash therefore returns an exit status
and is captured in the run artefacts; it must not leave an `Application Error`
dialog waiting for input.

## Diagnosing a Godot failure

`tools/slice.ps1 doctor -Lane <lane>` reports `godot_capability`, naming
which of five things is actually wrong before triage starts from scratch:

- `mcp_unavailable` -- the MCP command configured in `.mcp.json` (normally
  `npx`) cannot be resolved on PATH. Fix the MCP server's own setup; Godot
  itself has not been reached yet.
- `editor_unavailable` -- no Godot executable was found on PATH, in
  `GODOT_PATH`, or in `.codex/config.toml`. This is the one state that
  already blocks `doctor` itself; install Godot or point one of those at it.
- `import_cache_missing` -- the repository has no `.godot` directory, which
  is normal for a fresh worktree. The next headless run recompiles and
  passes; this is not a regression and not a reason to change anything.
- `environment_crash` -- the configured executable exists and the import
  cache is present, but a minimal `--headless --disable-crash-handler
  --quit-after 1` still exited non-zero or never returned. Something about
  this host's Godot install, not the project, is broken.
- `ready` -- the engine boots headlessly on its own. A failing scenario run
  is therefore a genuine scenario or product failure, not an environment one.

## Background jobs

Add `--background` when the same foreground command will take long enough
that waiting is wasteful. Submission returns immediately with one durable job
handle, for example:

```powershell
.\tools\run_headless.ps1 --experiment test_scenarios\predator_direction.json --background
# status=queued job_id=... status_file=...\status.json
```

The worker runs the ordinary foreground runner with the same timeout and
verdict rules; it does not tail a JSONL or invent a second Godot launch path.
The managed root permits one queued or running job at a time, so two Godot
simulations cannot contend accidentally.
Read its state without opening a log:

```powershell
& C:\path\to\python.exe tools\headless\jobs.py status C:\Temp\meadow-headless-jobs\job-...
```

Each job has `job.json` (the submitted foreground arguments), `status.json`
(`queued`, `running`, or a terminal `passed`, `failed`, `timed_out`, `crashed`
or `stale` state), `process.log`, the normal per-run artefacts under `runs/`,
and a job-level `result.json` that points to the underlying normal verdict.
The worker records a PID and process-start token solely to identify a vanished
or reused worker as `stale`; it does not expose a command to kill a Godot PID.

Jobs use a dedicated marked directory under the operating system temporary
folder. `--job-root` may choose another child of that temporary folder, but a
background job owns its internal `--result-root`, so the two options cannot be
combined. To remove terminal job directories only, use:

```powershell
& C:\path\to\python.exe tools\headless\jobs.py prune --older-than-seconds 86400
```

Pruning refuses unmarked roots, ignores non-job children and never stops a
process. Failed job artefacts remain until explicitly pruned.

## Artefacts

Each eventual run directory has these stable JSON artefacts:

- `result.json` is always written after a launched run reaches a terminal
  state. It is the compact machine verdict.
- `failure.json` is written only for a failed run or contract error. Its
  rendered form must be at most 4 KiB; raw JSONL and process output remain in
  the run directory.
- `report.json` is optional and is the selected report projection, never an
  automatic raw-log dump.
- Every verdict run also appends one `headless_run` event (fixture, status,
  classification, wall time, exit code) to the workflow diagnostic log that
  `python tools/session_cost.py --events` reads. Nothing in the run directory
  depends on it, and a logging failure never fails a run.

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

`status` is one of `passed`, `failed`, `contract_error`, `compile_error`,
`timed_out`, or `crashed`. A `compile_error` means Godot logged a script
compile or load failure even if it exited zero and wrote a session file; the
runner reports the first `SCRIPT ERROR:` line, its named script when Godot
supplies one, and the existing `process.log` path instead of treating
zero-valued session data as a gameplay result. In a
worktree with no `.godot` import cache, the first headless boot commonly
reveals such a pre-existing error. `outcome` may be `null` when Godot did not
write a summary. Paths in `artefacts` are relative to the result directory,
never scenario-supplied absolute paths.

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
`compile`, `timeout`, `crash`, or `missing_summary`. Event and action tails
are bounded; when data is omitted, `truncated` is true and the relevant
artefact path is present.

Godot prints `MEADOW_RESULT_PATH=<exact path>` after it closes the scenario
JSONL. The runner requires that sentinel and never infers a session directory
from the Godot project name, so `Meadow` and `Meadow - Claude` worktrees and
concurrent launches cannot select one another's logs.

### Foraging evidence campaign

`test_scenarios/foraging_evidence_campaign.json` is the pinned five-seed
campaign for recruitment, handling experience and flower senescence. Run it
without changing its seed list or base scenario, then render its compact
verdict artefact:

```powershell
.\tools\run_headless.ps1 --experiment test_scenarios\foraging_evidence_campaign.json
python tools\foraging_evidence_report.py <experiment-result.json>
```

The verdict reports outcome means/ranges, starvation deaths, handling-time
averages by prior `species_experience` bucket, flower replacement counts, and
the nectar/pollen recharge actually foregone due to senescence. Replacement is
expected with the feature both off and on; the two foregone-recharge counters
are the causal senescence-effect evidence and are zero by construction when it
is off.
A required zero-event channel is listed as `not_exercised`, not treated as
evidence that the mechanic had no effect.

**If the campaign dies mid-case, do not render a verdict from what it wrote.**
On 29 Aug 2026 the first `no_automation` case at seed `12345` exited with
`4294967295` after 48.6 seconds, writing no session summary and no diagnostic
events (`status: crashed`); a separate 30-second foreground probe of the base
scenario timed out rather than reporting a game assertion. A zero event count
from a run like that reads as "the mechanic did nothing" when the truth is
that the simulation never finished. Reproduce one pinned base scenario
interactively, or with Godot crash logging on, and identify the
native/runtime failure before rerunning the matched campaign. The verdict is
rendered only from a completed experiment `result.json`.

## Settling the layout before a geometry assertion

Actions are not a sequence: every unresolved one is checked each tick, in
file order, so a whole fixture normally fires on a single tick. Godot lays a
container out on the frame *after* its content changes, so a `panel`,
`control`, `container` or `root` assertion in the same tick as the selection
that changed it measures the previous frame's rectangle.

`settle` is the one action that is a barrier. Nothing after it in the file
runs until it has counted out its ticks:

```json
{"do": "settle", "ticks": 2}
```

Put one between an action and the assertions that measure what it changed.
`ticks` defaults to 1; 2 is what `tests/fixtures/layout_panels.json` uses.

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

## Challenge scenarios

A scenario can start either ordinary Challenge by supplying a top-level
`challenge` value of `1` or `2`. It uses that Challenge's normal starting
world and stage runner; without this field, scenario launches keep their
existing synthetic-level behaviour.

`advance_challenge_stage` reaches a named stage through the runner's existing
`debug_advance_stage()` seam, so every ordinary stage transition and its
effects run. It does not write the stage index. `challenge_stage_id` is
available in both an action's `when` clause and an assertion condition.

```json
{
  "challenge": 1,
  "actions": [
    {"do": "advance_challenge_stage", "stage_id": "1.14"},
    {"do": "assert", "when": {"challenge_stage_id": "1.14"},
     "condition": {"challenge_stage_id": "1.14"}}
  ],
  "stop": {"when_actions_resolved": true, "max_days": 1}
}
```

## Placement verbs

`request_placement_tool` arms one of the click-a-spot tools by its
`input_selection.gd::PLACEMENT_TOOLS` id (`{"do": "request_placement_tool",
"tool": "mine_target"}`), through the same function the HUD buttons reach.
It is rejected if the tool is unknown or no eligible bee is selected.
`click_world` delivers a left click by setting the drag start and end and
calling `_finish_drag(false)`: `x`, `y` and `view` (`hive` or `meadow`) give a
point local to that root, or `soil_hex: [q, r]` clicks that soil block.
`select_bees` also accepts `{"any_of": [selector, ...]}` to select several
roles at once, in the order given. The assertion condition
`selected_mine_queue_at_least` reads the first selected bee's mine queue.
`test_scenarios/e1_placement_exclusion_test.json` uses all of them.

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
`resources.food_stores`, `resources.stored_nectar`, `resources.stored_pollen`,
`environment.winter_here`, `environment.flowers_by_species`,
`role_outcomes.cells_completed_total`, `performance.fps`, and
`performance.top_sections_ms`. Unknown fields, event names, profiles or invalid
limits are `contract_error` before process launch. Counters and summary facts
remain available to actions and expectations even when their raw event lines
are filtered.

`build_target` is a custom-only event for diagnosing a comb-worker target. It
records the target hex, transition, release reason, approach/path outcome and
the number of builders already sharing that unfinished cell. It does not imply
an exclusive reservation.

## Output budgets

The Slice 0 fixtures make the baseline projections reproducible, and
`tools.headless.contracts.fits_stdout_budget` executes these limits. Slice 1
must apply it to the terminal presentation:

- passed `verdict` output: at most 1 KiB and normally one line;
- failed verdict output: at most 4 KiB; and
- expanded reports: retained as artefacts rather than printed by default.

The current `brief`, `behaviour`, and `full` projections are compatibility
baselines only; they are intentionally more verbose than the future verdict.

## Experiment manifests

Use an experiment when a claim needs matched seeds across configuration cases:

```powershell
.\tools\run_headless.ps1 --experiment test_scenarios\example_experiment.json
```

The manifest names one unchanged base scenario, one shared seed list, and
case-specific `config_overrides`. A case cannot override cells, population,
actions, stop conditions, diagnostics, or any other starting-state field. This
makes the base setup identical across every case while retaining Meadow's
existing GameConfig validation at launch.

```json
{
  "name": "predator direction",
  "base_scenario": "test_scenarios/predator_base.json",
  "seeds": [101, 202, 303],
  "cases": {
    "on": {"config_overrides": {"predators_on": true}},
    "off": {"config_overrides": {"predators_on": false}}
  },
  "expect": [
    {
      "id": "predator_events_increase",
      "left": "on.crab_spider_events.mean",
      "op": "gt",
      "right": "off.crab_spider_events.mean"
    }
  ],
  "report": {"mode": "table", "metrics": ["crab_spider_events", "total_deaths"]}
}
```

Expectation paths have exactly three components:
`case.summary_field.statistic`, where `statistic` is `min`, `mean`, or `max`.
The summary field is a numeric final-summary value; a summary dictionary of
numeric outcome counts (such as `crab_spider_events`) is summed before its
statistics are calculated. `eq`, `ne`, `lt`, `lte`, `gt`, and `gte` compare a
left path against either a right path or a numeric `value`. Fields are the
current `DiagnosticLog` numeric/count summary allowlist, so unknown fields
fail the manifest check before any case is launched.

The runner validates the complete manifest and base scenario before launching
Godot. Every case receives every seed, writes its merged scenario and normal
single-run artefacts under `cases/<case>/seed-<seed>/`, and records those
relative result paths in the experiment `result.json`. Any individual run,
contract, or aggregate expectation failure returns non-zero. Successful runs
print only one verdict; `report.mode: "table"` adds one compact aggregate JSON
table, never one summary per launched case/seed. The experiment-level
`report.json` always retains the selected aggregate projection.

## Behaviour-equivalence runs

`--experiment` compares configuration cases inside one build, by design --
it cannot say whether a code change moved a scenario's outcome. Use
`tools/equivalence.py` for that: it runs one scenario at a chosen git ref and
again in the working tree, with the same seed, and prints only the
`result.json` fields that differ.

```powershell
python tools\equivalence.py test_scenarios\slice1_smoke_test.json HEAD
python tools\equivalence.py test_scenarios\slice1_smoke_test.json main --fields outcome,expectations.passed
```

It exits 0 and prints `no differences: ...` when every compared field
matches, and exits non-zero and names each moved field otherwise (including
when the ref-side or working-tree run itself fails or crashes, since that is
itself a difference). The default field set is every `result.json` field
that describes behaviour rather than run identity -- `run_id`, `scenario`,
`process.pid`/`execution`/`wall_seconds` and every artefact path always
differ between two separate runs and are never compared. `--fields` narrows
the comparison to what a slice actually claims to preserve, since a
legitimately cadence-changing slice will move timing-derived fields while
leaving outcomes alone.

The ref side always runs from a throwaway detached worktree -- the ref is
never checked out over the working tree -- created and removed within the
one command; it is not registered in `plans/workstreams.md`, which is for
worktrees that outlive a single command. Both sides write into the tool's
own temporary result roots, never a path the scenario supplies. If the
scenario declares no `random_seed`, one is generated once and used for both
runs, since the comparison is only meaningful at a matched seed.
