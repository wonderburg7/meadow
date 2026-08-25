# Headless-run efficiency and selective diagnostics plan

Status: Slice 5 ready for integration | Owner: Dave / Codex | Next: integrate
Slices 0-5 complete | Evidence checked: 2026-08-25 from baseline `efc28f4`.
`6611871`

> **CHATGPT-OWNED PLANNING FILE.**
> This plan does not revive the abandoned mechanism-check queue in
> `CHATGPT_HEADLESS_CHECK_PLAN.md`. It designs shared infrastructure for
> specific current questions. Claude Code should use it only when Dave assigns
> this work or asks Claude to review/integrate its implementation.

## Outcome

Make a headless run cheap for either Claude or ChatGPT to choose, execute and
interpret:

1. choose the smallest adequate run class from a very short deterministic
   routing card;
2. prepare semantic actions and success conditions before launch whenever
   possible;
3. let Godot and Python run without live model supervision;
4. return a machine verdict whose successful output is one short line;
5. expose only the requested metrics to the AI;
6. retain full or targeted diagnostic artefacts on disk for failure
   investigation without automatically adding them to model context; and
7. allow a scenario to request named diagnostic channels, snapshot fields and
   capture triggers through an allowlisted dev-only contract.

The system must remain optional and scenario-gated. Ordinary play, ordinary
diagnostic logging, simulation decisions and save data must behave exactly as
before.

## The distinction that keeps this plan honest

A large JSONL file sitting on disk consumes no AI tokens. Tokens are spent when
an agent reads it or a tool prints it into the conversation. Therefore:

- **presentation filtering is the first token-saving layer;**
- **machine verdicts are the second;**
- **write-time diagnostic selection mainly saves simulation work, disk and
  later investigative reading;** and
- no successful run should cause an AI to open its raw log.

Do not delete useful raw evidence merely to make a terminal response shorter.
Keep capture, verdict and presentation as separate contracts.

## Current baseline to preserve

The existing harness already supplies most of the hard pieces:

- `tools/run_scenario.py` launches Godot directly with `--headless`,
  `--fixed-fps 30`, a unique run ID, per-run timeout and captured process
  output.
- `scripts/main.gd` accepts `--scenario`, a seed, starting state, config
  overrides, actions and early-stop conditions.
- `scripts/scenario_actions.gd` performs semantic player actions through the
  real command functions and supports causal triggers and assertions.
- `scripts/diagnostic_log.gd` keeps cheap counters, writes discrete events,
  builds snapshots and emits a final summary.
- `tools/analyze_session.py` already separates brief, behaviour, balance and
  full presentation profiles.
- failed or unresolved actions make the runner exit non-zero.

Keep these behaviours. This plan adds contracts and modularity rather than a
parallel playtest architecture.

Two current weaknesses must be fixed before building higher layers:

1. `run_scenario.py::log_dir()` assumes the project name is `Meadow` while
   Claude's isolated project can be `Meadow - Claude`. This produces false
   "no session file" failures and local monkeypatches.
2. An aggregate analysis can describe a bad result without necessarily
   producing a failing exit status. Action problems are machine failures;
   general metric expectations and A/B comparisons are not yet first-class
   verdicts.

## Target flow

    task
      |
      v
    deterministic route card
      |
      +-- Python/source check, no Godot
      +-- one scenario -> compact verdict
      +-- paired/multi-seed experiment -> aggregate verdict
      +-- long run -> same route, background modifier
      +-- adaptive decision genuinely required -> checkpointed AI exception
      |
      v
    scenario or experiment contract
      |
      +-- starting state / semantic actions / stop
      +-- expectations
      +-- diagnostic capture profile
      +-- AI-visible report projection
      |
      v
    isolated result directory
      |
      +-- result.json           compact stable verdict
      +-- report.json           requested projection only
      +-- session.jsonl         retained evidence
      +-- process.log           full stdout/stderr only when useful
      +-- failure.json          focused evidence capsule on failure
      |
      v
    one-line success or compact failure

## Token-efficient routing

### The routing card

Both AIs should be able to choose without reading this plan or inspecting the
runner source. Put the following card in `run_scenario.py --help` and one small
shared headless-run document:

1. **Can Python/source checks answer the question without real Godot
   behaviour?** Use them and stop.
2. **Does the run require a mid-run judgement that cannot be expressed as
   semantic actions, triggers or assertions?** Use checkpointed AI; otherwise
   stay scripted.
3. **Is this one deterministic command/mechanism check?** Use `verdict` with
   one pinned seed.
4. **Is randomness or a comparison part of the claim?** Use `experiment` with
   three matched seeds; increase to five only if three disagree or lie near
   the threshold.
5. **Is a time series necessary to answer the question?** Add a named
   snapshot profile; otherwise use summary-only capture.
6. **Is expected wall time over 30 seconds?** Add the `background` modifier.
7. On failure, rerun only the failed seed with one targeted diagnostic profile.
   Never escalate all successful runs to full output.

This is deliberately a small decision tree, not another narrative policy.

### Machine-assisted route selection

Add a deterministic `tools/headless/route.py`. It must not call a model or
classify free-form prose. It accepts a handful of explicit facts:

    --needs-godot yes|no
    --adaptive yes|no
    --comparison none|stochastic|paired
    --time-series yes|no
    --expected-seconds N

Its output is one stable line, for example:

    route=experiment capture=behaviour seeds=3 background=no report=verdict

The AI still judges five simple facts about the task, but it does not
reconstruct seed, report, waiting or capture policy from project history.
`--explain` may print the matched rules for a human; default output stays one
line.

### Stable run classes

| Run class | Use | Default capture | Seeds | AI involvement |
|---|---|---|---:|---|
| `python` | Arithmetic, source shape, static invariants | None | N/A | Reads final check only |
| `verdict` | Boot, command plumbing, one causal mechanism | `verdict` | 1 pinned | Reads pass/fail only |
| `experiment` | Stochastic direction, A/B or parameter comparison | `behaviour` or named metrics | 3 matched | Reads aggregate verdict only |
| `trend` | A real time series is necessary | `balance` with selected fields | 1-3 | Reads projected series only |
| `performance` | Fixed-step profiler evidence | `performance` | Defined by benchmark | Reads retained metrics table |
| `checkpointed` | A decision cannot be scripted | Targeted observation packet | As designed | Model called only at checkpoints |

`background` is a modifier, not a separate evidence class.

## Three separate contracts

### 1. Capture contract: what the game records

A scenario may gain an optional `diagnostics` block:

    "diagnostics": {
      "profile": "custom",
      "events": ["action", "death", "stall_recovery"],
      "summary": [
        "outcome",
        "total_deaths",
        "deaths_by_cause",
        "stall_recoveries",
        "cells_completed"
      ],
      "snapshots": {
        "every_sim_seconds": 30,
        "fields": [
          "population.total",
          "resources.food_stores",
          "role_outcomes.cells_completed_total"
        ],
        "only_when_changed": true
      },
      "limits": {
        "event_lines_per_type": 100,
        "snapshot_lines": 200
      }
    }

Most scenarios should name a profile rather than list fields. `custom` is for a
specific diagnosed question, not the default.

### 2. Verdict contract: what counts as success

A scenario may gain `expect` for single-run invariants:

    "expect": [
      {"metric": "summary.outcome", "op": "eq", "value": "actions_resolved"},
      {"metric": "summary.total_deaths", "op": "lte", "value": 0},
      {"metric": "actions.problems", "op": "empty"}
    ]

Keep the operator vocabulary small and typed:

- `eq`, `ne`, `lt`, `lte`, `gt`, `gte`;
- `empty` / `not_empty`;
- `between`;
- `all_true`; and
- `exists`.

Unknown metric paths or type mismatches are contract errors, not failed game
assertions. Game assertions remain useful for causal early stopping; Python
expectations judge the finished evidence.

### 3. Presentation contract: what the AI sees

The runner or experiment manifest may request:

    "report": {
      "mode": "verdict",
      "metrics": [
        "summary.flower_visits",
        "summary.unique_flowers_visited",
        "summary.stall_recoveries"
      ]
    }

Modes:

- `verdict`: one line on success;
- `table`: named metrics only;
- `failure`: failed expectation, expected/actual, seed and relevant event tail;
- `artifact`: write JSON output to disk without printing it; and
- `debug`: explicit human request for expanded output.

Remove `full` from routine guidance. Retain it as an explicit diagnostic
escape hatch.

## Game-code support in a separate area

### Proposed layout

Do not move the existing working files in the first implementation. Add a
separate area and route only scenario-specific behaviour through it:

    scripts/headless/
      headless_contract.gd
      diagnostic_profile.gd
      diagnostic_probes.gd
      capture_buffer.gd          # later slice, only if triggered capture ships

    tools/headless/
      route.py
      contracts.py
      verdicts.py
      experiments.py
      jobs.py                    # later background slice

`tools/run_scenario.py` and `tools/analyze_session.py` remain compatibility
entry points and import the new modules. Existing commands do not break.

### No new always-running autoload

Do not add a second diagnostic or headless autoload. `DiagnosticLog` remains
the single session logger. `main.gd` creates/parses a headless contract only
when `--scenario` is present, then passes the validated capture selection to
`DiagnosticLog`.

Ordinary play uses the existing `standard` profile and pays no new per-frame
selection work beyond one already-existing session-mode check.

### Centralised filtering

Gameplay systems should continue reporting semantic events to
`DiagnosticLog`. They must not learn about scenario JSON, profiles or report
formats.

Filtering happens inside `DiagnosticLog`:

- counters needed by assertions remain cheap in-memory counters;
- a discrete event is written only if its channel is selected;
- snapshot sections are built only if selected, rather than building the full
  snapshot and deleting fields afterwards; and
- report projection stays in Python, outside the game.

This avoids scattering `if headless` branches through bee, flower, hive and
season code.

### Probe registry

`diagnostic_probes.gd` owns the allowlisted names used by diagnostics,
expectations and reports. A probe has:

- stable name;
- value type;
- source: counter, summary, snapshot or event field;
- capture cost: free, cheap, scan or performance-sensitive; and
- profiles that may request it.

Examples:

| Probe | Type | Cost | Source |
|---|---|---|---|
| `population.total` | integer | cheap scan | bee group |
| `resources.food_stores` | number | cheap | hive |
| `events.flower_visits` | integer | free | counter |
| `events.stall_recoveries` | integer | free | counter |
| `performance.top_sections_ms` | object | existing Perf data | performance |

The registry lets the validator reject misspellings before launching Godot and
lets the router avoid expensive probes when a cheaper counter answers the
question.

Do not support arbitrary GDScript expressions, reflection paths supplied by a
scenario, method names or `eval`-like behaviour.

## Diagnostic profiles

### Built-in profiles

| Profile | Events | Snapshots | Intended use |
|---|---|---|---|
| `standard` | Current manual-play events | Current hourly snapshot | Ordinary play; compatibility baseline |
| `verdict` | Actions and failures only | None by default | Command/mechanism check |
| `behaviour` | Selected mechanic events, actions, deaths | Only requested behaviour totals | Stochastic mechanism |
| `balance` | Deaths and selected outcomes | Daily selected population/resource fields | Trend or economy |
| `performance` | Failures only | Fixed measurement-window Perf fields | Headless benchmark |
| `custom` | Explicit allowlist | Explicit allowlist | Diagnosed question only |

Every profile has a version. The config/result envelope records the effective
profile, its version and any custom additions so an old result remains
interpretable after the profile evolves.

### Fields that must always survive

Even the shortest log/result must retain:

- schema version;
- run ID;
- scenario path or stable scenario hash;
- effective random seed;
- effective diagnostic profile and selection;
- outcome and simulated time/day;
- rejected, failed or unresolved action count;
- failed expectation identifiers;
- process exit status; and
- artefact paths, recorded by the Python runner.

For reproducibility, the runner writes the scenario content/hash and
`config_overrides` into metadata. A summary-only profile does not need to dump
every `GameConfig` property into AI-visible output.

### Failures override silence

A filter must never hide why a run failed. On assertion failure, contract
failure, timeout, crash or unresolved action, emit a bounded failure capsule:

- run/seed/scenario identity;
- failed assertion or expectation;
- expected and actual values;
- last selected actions;
- last N relevant events;
- last selected snapshot; and
- path to complete process output and JSONL.

The capsule should have a hard byte budget, recommended 4 KB. Truncation names
the retained artefact path.

### Optional triggered capture

This is a later, separately approved slice. It is useful when the desired
evidence is "what happened just before and after the first starvation/stall",
without logging every bee every frame.

A bounded ring buffer can retain selected cheap observations in memory and
flush them only when a named trigger fires:

    "capture_on": [{
      "event": "death",
      "where": {"cause": "starvation"},
      "before_samples": 5,
      "after_sim_seconds": 10,
      "channels": ["bee_state", "food_access"]
    }]

Constraints:

- only named triggers and channels;
- bounded samples and bytes;
- at most a small number of armed captures;
- no whole-colony/per-frame capture by default;
- no capture channel added to a hot path without measurement; and
- if pre-event state is unavailable cheaply, report that instead of silently
  performing an expensive global scan.

Triggered capture is preferable to an AI watching or repeatedly tailing the
log.

## Experiment manifests

Add a separate manifest format for repeated and paired work. Do not duplicate
whole scenario JSON files merely to vary seed or one setting:

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
          "left": "on.crab_spider_events.mean",
          "op": "gt",
          "right": "off.crab_spider_events.mean"
        },
        {
          "metric": "off.crab_spider_events.max",
          "op": "eq",
          "value": 0
        }
      ],
      "report": {
        "mode": "table",
        "metrics": ["crab_spider_events", "total_deaths"]
      }
    }

The experiment runner must:

- use matched seeds across cases;
- merge only allowlisted scenario/config fields;
- reject a comparison whose starting state differs unexpectedly;
- keep every per-run artefact;
- evaluate aggregate expectations;
- return non-zero on any run/contract/aggregate failure; and
- print no per-run success summaries unless requested.

Do not encode broad balance judgements as permanent thresholds without Dave's
explicit design decision. The tool proves declared invariants and comparisons;
it does not decide what good bee ecology means.

## Reliable artefact hand-off

### Explicit output location

The runner creates a unique result directory and passes an exact output path
to the game as a command-line argument. The output path must not come from the
scenario JSON, so an arbitrary fixture cannot write wherever it wants.

This replaces project-name inference and fixes the `Meadow` /
`Meadow - Claude` mismatch. Headless artefacts are managed by the runner;
ordinary manual sessions continue using `user://logs` and its current
retention.

The game should print one machine sentinel after closing the file:

    MEADOW_RESULT_PATH=<exact path>

The runner still knows the path it supplied, but the sentinel proves the game
used it.

### Retention

Recommended default:

- successful artefacts: keep the most recent 20 or seven days, whichever is
  smaller;
- failed artefacts: do not prune automatically during the same task;
- explicitly named baseline artefacts: retain until superseded; and
- process crash logs: retain with the failure capsule.

Retention runs in Python against the dedicated headless artefact root, never
against the repository or ordinary save/profile folder.

## Background execution

Implement only after verdict and artefact contracts are stable.

`tools/headless/jobs.py` can create a job directory, launch the same foreground
command and write:

- `job.json`: command, PID, start time and route;
- `status.json`: queued/running/passed/failed/timed_out;
- `result.json`: normal compact verdict; and
- `process.log`: full output.

Requirements:

- unique job IDs;
- no shared "latest log" lookup;
- PID and process-start validation before stop/cleanup;
- bounded concurrency, default one Godot job;
- explicit timeout;
- stale-job detection without killing an unrelated reused PID;
- hidden background window on Windows; and
- optional OS notification on completion.

Both AIs submit once and later read `status.json` or receive a notification.
They do not poll the diagnostic log. Backgrounding changes waiting, not
evidence or verdict logic.

## How Claude and ChatGPT use the same mechanism

The repository owns one command and one result contract. Do not maintain
separate Claude and ChatGPT implementations.

- `python tools/run_scenario.py --route-help` prints only the routing card.
- `python tools/run_scenario.py ...` remains the compatibility command.
- a short shared document describes schemas and examples.
- Claude's project command/skill and Codex's local Environment Action, if
  added, call the same wrapper.
- deterministic hooks may notify or enforce a result, but no model-based hook
  should review a successful run.
- use a cheaper model only for a bounded failure capsule that genuinely needs
  interpretation, not for launching, waiting, parsing or comparing numbers.

Policy/orientation files should contain one pointer to the routing command,
not copies of this plan. Any eventual edits to `CLAUDE.md`, `CHATGPT.md` or
`AGENTS.md` require their normal ownership/explicit-authorisation rules.

## Staged implementation

Each slice should be a focused commit in an isolated worktree. Do not combine
this with gameplay, balance or the old H6/H7 mechanism-check plan.

### Implementation record: Slice 0 (2026-08-24)

- Scope: contracts, synthetic evidence and compatibility baselines only; no
  Godot, scenario, diagnostic-log or runner behaviour changes.
- Isolated branch/baseline: `codex/headless-efficiency-slice-0` at
  `6715881fc5a1897fd47285062a353773ae08a5cf`.
- Primary worktree baseline: `master` at the same commit, with its pre-existing
  untracked `.claude/settings.local.json` left untouched. The isolated branch
  started clean. Existing Codex worktrees had no overlapping tracked edits;
  one had an unrelated untracked diagnostic artefact directory.
- The synthetic success fixture records deterministic current runner stdout
  sizes of 396 bytes (`brief`), 522 bytes (`behaviour`) and 808 bytes
  (`full`) using a stable fixture session path. The test locks these
  compatibility baselines while the new one-line verdict is built.
- `docs/headless-run-contract.md` is the schema source for Slice 1;
  `tools.headless.contracts` holds the version, allowed vocabulary and
  executable 1 KiB / 4 KiB output-budget limits.

### Implementation record: Slice 1 (2026-08-25)

- Scope: explicit per-run artefact paths, compact single-run verdicts and
  typed `expect` evaluation only. Existing explicit `brief`, `behaviour`,
  `balance` and `full` reports remain available; profiles and aggregate
  experiments remain later slices.
- Baseline: `2e44bb73d2fa772902f00e8205c9989251019d71` on
  `codex/headless-efficiency-slice-0`. The primary worktree had unrelated
  gameplay changes; this slice touched only the named headless runner,
  logger/main command-line boundary, smoke scenario, tests and contract docs.
- `run_scenario.py` now creates a unique directory under a managed temporary
  artefact root, supplies Godot an exact `--headless-session-path`, retains
  `session.jsonl` and `process.log`, writes `result.json` (plus `report.json`
  on success or bounded `failure.json` otherwise), and makes one-line
  `verdict` the default for one run. It verifies Godot's
  `MEADOW_RESULT_PATH` sentinel rather than inferring a `user://` directory
  from the project name.
- `expect` is evaluated after the final summary through a small allowlist of
  final summary/action facts. Invalid contracts return `contract_error`; a
  false expectation or an action problem returns non-zero with a focused
  failure capsule. The smoke scenario now protects clean actions, a living
  queen and zero deaths. `queen_alive` was added to the ordinary final
  summary, with no per-frame observation work.
- Evidence: 9 Python contract/baseline tests passed; `source_checks.py`
  checked 67 scripts; `balance_tests.py` passed all 15 checks. A real fixed
  FPS-30 smoke run (seed 4242) passed in 7.1s, stopped at simulated 92.75s on
  day 1, and produced the one-line result plus all expected artefacts. A
  disposable inverted zero-deaths expectation failed in 8.1s with
  `status=failed`, exit 1 and expected/actual evidence. The fixture was
  restored before final verification.

### Implementation record: Slice 2 (started 2026-08-25)

- Scope: deterministic route helper, runner routing card and a portable
  Windows entry point only. No Godot, scenario, diagnostic-log or simulation
  behaviour changes are in scope.
- Isolated branch/baseline: `codex/headless-efficiency-slice-0` at
  `6e3ee01975e9db2f8815de8f384de4c7649d1704`; the dedicated worktree started
  clean.
- Primary worktree check: `master` is at
  `6715881fc5a1897fd47285062a353773ae08a5cf` with pre-existing edits in
  gameplay and canonical project-state files. None overlap this Slice 2
  tooling/documentation scope. No primary-worktree file will be edited.
- Delivered: `tools/headless/route.py` maps only the five explicit facts to
  stable `python`, `verdict`, `experiment`, `trend` or `checkpointed` route
  lines; `--explain` adds the matched rule but the default stays one line.
  `run_scenario.py --route-help` prints the shared seven-rule card and exits
  before requiring a scenario or launching Godot. `tools/run_headless.ps1`
  provides the Windows shared entry point, resolving `python`, `python3` or
  `py -3`, with an explicit `-PythonPath` escape hatch and `-Route` mode.
- Evidence: the route decision table, CLI/card and existing verdict baselines
  passed (17 tests). A live wrapper route launch using an explicit bundled
  interpreter emitted the expected single verdict line. `source_checks.py`
  checked 67 scripts and `balance_tests.py` passed all 15 checks. No Godot
  run was needed because Slice 2 does not alter launch or game behaviour.

### Implementation record: Slice 3 (2026-08-25)

- Scope: scenario-selectable capture profiles only. The slice adds a shared
  pre-launch Python validator, matching Godot-side validation, central event
  filtering, selected snapshot construction and bounded capture. It does not
  alter simulation decisions, normal action counters, save data or manual-play
  logging.
- Baseline: `5e7a03b4d47e415dfe225a91c9d96770d12feac6` on
  `codex/headless-efficiency-slice-0`. The primary worktree contained an
  unrelated recruitment-log edit in `diagnostic_log.gd`; its separate lines
  were inspected before this isolated change, and Dave confirmed no further
  primary-tree edits would occur during the slice.
- Delivered: built-in `standard`, `verdict`, `behaviour`, `balance`,
  `performance` and `custom` profiles have a versioned allowlist. `verdict`
  retains action/death evidence but has no periodic snapshots by default;
  custom selection accepts only named events and six typed snapshot fields.
  Per-event and snapshot caps plus `only_when_changed` are enforced in
  `DiagnosticLog`, while counters and the final summary remain available to
  action assertions and Python expectations. Partial selected snapshots no
  longer make the legacy report parser crash.
- Evidence: 23 focused headless contract tests passed; `source_checks.py`
  checked 69 scripts and `balance_tests.py` passed all 15 checks. A real
  fixed-FPS-30 verdict smoke run passed with a JSONL containing only config,
  the accepted action and final summary (no snapshot). A real custom run
  passed with exactly `population.total`, `resources.food_stores` and
  `role_outcomes.cells_completed_total` in its two capped snapshots.

### Implementation record: Slice 4 (2026-08-25)

- Scope: `tools/headless/experiments.py`, the compatibility runner, focused
  Python tests and the shared contract document only. No scenario, Godot,
  logger, gameplay, balance or save-data change is included.
- Delivered: `--experiment <manifest>` accepts a named base scenario, shared
  integer seeds, cases restricted to `config_overrides`, aggregate
  expectations and a verdict/table report projection. Every case receives
  each exact seed; its merged scenario and normal single-run result remain
  addressable at `cases/<case>/seed-<seed>/`. The runner prints only one
  aggregate verdict (plus one compact table when requested), and emits a
  non-zero result for a malformed manifest, any failed case run or a failed
  aggregate expectation. The explicit current-summary allowlist rejects a
  misspelled metric before any Godot launch, and starting-state overlays are
  rejected before launch as well.
- Evidence: 29 focused headless Python tests passed, including matched seeds,
  retained per-run artefacts, pre-launch contract rejection and a non-zero
  aggregate negative control. `source_checks.py` checked 69 scripts and
  `balance_tests.py` passed all 15 checks. A real same-seed two-case smoke
  experiment could not complete because the local Godot 4.7.1 executable
  crashed with signal 11 before it wrote a session; the unchanged single smoke
  command crashed identically, so this is not evidence of an experiment
  verdict or a Slice 4 regression. Its temporary manifest, artefacts and
  crash-handler process were removed after inspection.

### Slice 0: measurements and contracts, no game behaviour change

Deliver:

- small synthetic JSONL fixtures for success, action failure, missing summary,
  timeout-shaped failure and long time series;
- unit tests around current analysis/aggregation;
- recorded current stdout byte counts for `brief`, `behaviour` and `full`;
- chosen `result.json`, `failure.json` and expectation schemas; and
- compatibility tests for current CLI arguments.

Acceptance:

- no scenario or gameplay change;
- tests demonstrate exactly which current bad aggregate returns zero;
- success-output budget and failure-output budget are executable assertions.

Target budgets:

- successful verdict stdout at most 1 KB and normally one line;
- failed verdict stdout at most 4 KB;
- expanded data written to artefacts, not stdout.

Risk: low.

### Slice 1: explicit result path and compact verdict

Likely files:

- `tools/run_scenario.py`;
- `tools/analyze_session.py`;
- new `tools/headless/contracts.py` and `verdicts.py`;
- `scripts/main.gd`;
- `scripts/diagnostic_log.gd`; and
- focused Python tests/scenarios.

Deliver:

- runner-created result directory;
- command-line diagnostic output path, independent of project name;
- machine sentinel;
- single-run `expect` evaluation;
- stable `result.json`;
- one-line success and bounded failure capsule;
- non-zero exits for contract and expectation failures.

Acceptance:

- works under both `Meadow` and `Meadow - Claude` project names;
- two simultaneous test launches cannot select one another's log;
- existing scenario commands remain valid;
- negative controls fail for the intended reason;
- full process output is retained but not printed.

Risk: low to medium. It changes dev-only launch/log plumbing, not simulation.

### Slice 2: deterministic route helper and shared entry point

Deliver:

- `tools/headless/route.py`;
- five-fact input contract;
- one-line route result;
- `--route-help` card;
- a portable shared command that locates Python according to the broader
  workflow-audit recommendation; and
- optional Codex Environment Action / Claude project command proposals that
  merely call the shared command.

Acceptance:

- routing unit tests cover every branch;
- no route reads project plans or invokes an AI;
- selection output stays within one line by default;
- invalid/contradictory facts fail explicitly.

Risk: low.

### Slice 3: selectable diagnostic profiles

Likely files:

- new `scripts/headless/headless_contract.gd`;
- new `scripts/headless/diagnostic_profile.gd`;
- new `scripts/headless/diagnostic_probes.gd`;
- `scripts/main.gd`;
- `scripts/diagnostic_log.gd`;
- `tools/analyze_session.py`; and
- profile fixtures/tests.

Deliver:

- `standard`, `verdict`, `behaviour`, `balance` and `performance` profiles;
- custom allowlisted events/summary/snapshot fields;
- profile/schema version in every result;
- central event filtering;
- selected snapshot-section construction;
- caps and `only_when_changed`;
- failure override rules.

Acceptance:

- ordinary manual session using `standard` retains the existing config,
  events, snapshots and summary schema;
- a `verdict` scenario writes no periodic snapshot unless requested;
- a custom three-field snapshot contains exactly its envelope plus those
  fields;
- unknown/expensive probe requests fail validation before the run;
- action assertions still see counters even when their raw event lines are
  filtered out;
- measured headless overhead is no worse than current standard capture and is
  lower for summary-only runs.

Risk: medium because `DiagnosticLog` is shared instrumentation. The
scenario-only gate and compatibility test are mandatory.

### Slice 4: experiment manifests and aggregate verdicts

Deliver:

- `tools/headless/experiments.py`;
- base scenario plus per-case overlays;
- matched seed execution;
- aggregate expectations;
- compact table projection;
- fail-fast contract validation before launching Godot.

Acceptance:

- paired control/candidate fixture proves matched seeds;
- changing an undeclared starting-state field is rejected;
- aggregate expectation failure returns non-zero;
- successful N-run experiment prints one verdict/table, not N summaries;
- all per-run artefacts remain addressable by case and seed.

Risk: low to medium, confined mainly to tooling.

### Slice 5: background job modifier

Implementation start record (2026-08-25): isolated branch
`codex/headless-efficiency-slice-0`, baseline
`efc28f44e6f43d8657d7b9f55d3aced39fa7b38c`, clean dedicated worktree. The
primary `master` worktree remains at `6715881fc5a1897fd47285062a353773ae08a5cf`
with pre-existing gameplay and canonical-plan changes. Slice 5 is restricted
to the headless Python runner/job wrapper, focused tests and this contract
documentation; it will not touch those primary-tree files.

Completed 25 Aug 2026. `tools/headless/jobs.py` submits the existing
foreground runner to a windowless worker and immediately returns a durable
job ID/status path. The worker owns a marked, dedicated subdirectory of the
system temporary folder; it records `job.json`, atomic `status.json`, full
`process.log`, normal nested runner artefacts and a job-level `result.json`
which points to the normal verdict. `--background` and `--job-root` expose the
modifier through the compatibility runner, while `jobs.py status` reads only
state and `prune` can remove terminal direct-child jobs only. No command
targets a Godot process. A worker PID/start token is used only to turn a
vanished or reused worker into a terminal `stale` state; cleanup refuses an
unmarked or non-temporary root and never stops a process.

Focused evidence passed: 35 headless contract/baseline tests, including prompt
submission, completed verdict discovery, timeout propagation, runner-crash
terminal status, stale-worker identification, safe pruning, one-active-job
enforcement and background argument isolation. `source_checks.py` checked 69 scripts and
`balance_tests.py` passed all 15 checks. A live smoke submission returned its
one-line queued handle. In this Codex command sandbox its descendant was
terminated before finalising (the local Godot executable had already been
observed to crash identically in Slice 4), so the completed job record could
not serve as a production Godot validation. It did reach a terminal state
rather than hanging. This slice changes tooling only; no gameplay, balance,
save-data or ordinary diagnostic path changed.

Deliver:

- `tools/headless/jobs.py`;
- status/result files;
- concurrency and stale-job handling;
- notification adapter;
- foreground command remains the underlying implementation.

Acceptance:

- a submitted job returns its ID promptly;
- completion is observable without log polling;
- timeout and crash become terminal statuses;
- cleanup cannot target ordinary Godot sessions or repository files.

Risk: medium due to process lifecycle, not gameplay.

### Slice 6: targeted triggered capture, only after a real need

Do not implement speculatively. First name a diagnostic question that profiles
and finished summaries cannot answer cheaply.

Deliver only if justified:

- bounded capture buffer;
- named trigger/filter/channel validation;
- pre/post-event failure capsule;
- overhead measurement for the affected path.

Acceptance:

- capture is dormant outside an armed headless scenario;
- memory and line budgets are enforced;
- the named reproduction becomes diagnosable without full-run tracing.

Risk: medium to high if it touches a hot simulation path.

### Slice 7: checkpointed AI, exceptional and separately approved

This remains parked unless a concrete task cannot be expressed through the
semantic action/trigger language.

Before implementation, prove:

1. the missing decision is genuinely adaptive;
2. adding one reusable semantic trigger/action would be worse;
3. the observation packet has a strict schema and token budget; and
4. the run can pause safely without changing simulation results.

Never make checkpointed AI the automatic fallback merely because a scenario is
hard to write.

Risk: high, both architecturally and for reproducibility.

## Test and verification matrix

### Pure Python

- route decision table;
- scenario/experiment schema validation;
- metric path and type checking;
- verdict operators;
- stdout byte budgets;
- aggregate expectations;
- report projection;
- artefact retention boundaries;
- job state transitions;
- malformed/truncated JSONL;
- large failure output truncation.

### Real Godot

- existing fast smoke scenario;
- one positive and negative expectation;
- each built-in diagnostic profile;
- custom field selection;
- unknown field rejection;
- explicit result path with spaces;
- exact run ID/path matching;
- matched-seed A/B pair;
- timeout and unresolved action;
- two concurrent result directories if concurrency is supported.

### Project checks

- source checks;
- balance tests;
- function-map check when a mapped large script changes;
- clean Godot boot;
- manual-play `standard` log compatibility;
- measured profile overhead where snapshot construction changes.

### Negative controls

Every verdict slice must demonstrate at least one deliberately failing
expectation. Every selected diagnostic channel must demonstrate both inclusion
and exclusion. A passing positive alone does not prove the harness can catch
the regression it names.

## Guardrails

- Never alter a balance value merely to make a headless expectation pass.
- A headless profile controls observation, never simulation.
- An absent requested field is an error, not zero.
- Filtered-out data is "not captured", never interpreted as zero.
- Report projections must preserve units and seed/case identity.
- No AI-generated arbitrary code or expressions in scenario JSON.
- No raw log tailing as routine monitoring.
- No automatic model call on success.
- No broad scheduled suite until named stable checks genuinely repeat.
- No expansion of `scenario_actions.gd` without a current scenario requiring
  the new semantic action.
- Visual, pacing and comprehension claims remain Dave's hands-on checks.

## Documentation and integration

When implementation is assigned:

1. keep the detailed schemas in one shared headless-run document close to the
   tooling;
2. make `--help` / `--route-help` the cheapest authoritative routing source;
3. update ordinary technical documentation made inaccurate by the change;
4. add at most a one-line pointer in each AI's orientation/policy, with the
   required owner approval;
5. do not copy profile tables into multiple instruction files;
6. classify the diagnostic-profile slice at least medium risk unless evidence
   proves the shared logger path is runtime-neutral; and
7. hand Claude the commit hashes, checks, output-budget evidence and manual-log
   compatibility result, not a second narrative review.

## Recommended scope to approve

Approve Slices 0-4 as the core implementation:

1. compact result/verdict and reliable artefact path;
2. deterministic route helper;
3. selectable diagnostic profiles; and
4. experiment manifests.

Treat background execution as an optional follow-up once measured runs justify
it. Keep triggered capture and checkpointed AI parked until a specific failure
cannot be diagnosed through the core system.

This ordering gives both AIs the token savings first and prevents the game-code
instrumentation from becoming a speculative general-purpose bot framework.
