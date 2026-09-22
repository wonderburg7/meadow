# Feedback build — something a tester can install, and evidence they never have to give us

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: FB-1 -- a Windows build anyone can run, queued in the Codex lane | Dependency: none -- FB-1 and FB-2 are independent of each other and of every Claude-lane slice | Verified: 2026-09-22

**Objective.** `plans/design/product-scope.md` §15 defines the closed alpha as
friends and family being able to *install*, save, resume and give useful
feedback without live instruction, and §14's evidence stream wants "internal
milestone play at 5/10/20/60/90 minutes". Neither is possible today: the
project has never been exported, and the headless harness cannot answer a
pacing question. This plan builds the two instruments, so that every later
balance slice is checked by a command rather than by an hour of Dave's play.

**Why this plan is the Codex lane.** Every slice here lives in `tools/`,
`tests/`, `test_scenarios/`, `export_presets.cfg` and `project.godot`. No slice
opens `scripts/`. That makes the lane permanently file-disjoint from the
Claude lane's game work, so the two never collide and neither has to wait.

## Current state

Verified 22 September 2026 against the repository.

- **`export_presets.cfg` does not exist.** `ls export_presets.cfg` fails. There
  is no way to produce anything you can send to a tester. `project.godot` has no
  `config/version` either, so a bug report could not name the build it came
  from.
- **`config/name` is `"Meadow - Claude"`** and has been since the prototype.
  That string is the window title a tester would see.
- **The headless harness is good and is the right owner to extend.**
  `tools/headless/verdicts.py` already validates and evaluates a scenario's
  declarative `expect` block against a completed run, over an allowlist of
  metrics whose own comment says "Slice 3's probe registry will widen this
  allowlist". `tools/headless/profiles.py`'s `balance` profile already captures
  `population.total`, `resources.food_stores` and `environment.winter_here` as
  per-day snapshots. `tools/analyze_session.py` already turns those into
  `population_curve`, `deaths_over_time` and `honey_fill_vs_winter`.
- **What the harness cannot do is answer "when".** Every metric it exposes is a
  final-run fact. `summary.gynes_released` says how many, never on which day.
  So no scenario can assert the 5/10/20/60/90-minute gates, and `grep -c
  milestones tools/analyze_session.py` returns 0.
- **A parse error is already caught.** `tools/godot_compile_check.py` exists and
  `tools/run_scenario.py` already surfaces `SCRIPT ERROR` as its primary
  diagnosis, so no slice here needs to build that.

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| FB-1 | Dave can produce a zipped Windows build and hand it to someone, and a bug report can name the build it came from. | `export_presets.cfg`, `project.godot`, `.gitignore`, `tools/build_alpha.ps1`, `tests/test_alpha_build.py`, `tools/verify.ps1` | yes | low |

`.gitignore` is in FB-1's scope but deliberately not on its `Files:` line: `check_docs.py`'s queue validator requires every listed path to have a file suffix, and `.gitignore` has none. Do not re-add it there.
| FB-2 | A scenario can assert *when* something happened, not just whether it did. | `tools/analyze_session.py`, `tools/headless/verdicts.py`, `tests/test_headless_verdicts.py` | yes | medium |
| FB-3 | `python tools/pacing_gates.py` prints the five milestone timings against their targets, so a balance change is judged by a command. | `tools/pacing_gates.py`, `test_scenarios/alpha_arc_test.json`, `tests/test_pacing_gates.py`, `tools/verify.ps1` | no — after FB-2 | medium |

**Dependencies, stated rather than implied by order.** FB-1 and FB-2 share no
file and may run in either order. FB-3 needs FB-2's metrics and nothing else.
No slice here depends on anything in `plans/now/alpha-progression-spine.md` or
`plans/now/named-saves.md`, and none of them depends on this plan.

**Required reading for any slice.** Its own section below.

## FB-1 — a Windows build anyone can run

Level: low.

**Decided by Dave, 22 September 2026:** the first distributable is **Windows
desktop only**. Web, Linux and macOS are not in this slice and are not to be
added to the preset "while we are here".

- **Required reading.** This heading. `project.godot`'s `[application]` section
  (the first 20 lines). `tools/verify.ps1`'s unittest module list — find it with
  `grep -n 'm unittest' tools/verify.ps1`.
- **Files to change.** `export_presets.cfg` (new), `project.godot`,
  `.gitignore`, `tools/build_alpha.ps1` (new), `tests/test_alpha_build.py`
  (new), `tools/verify.ps1`.
- **Files not to change.** Anything in `scripts/`. If the export reveals a
  runtime problem in a script, report it; do not fix it here.
- **Start by checking the templates, because the slice's shape depends on it.**
  Godot cannot export without matching export templates installed. Run
  `godot --headless --export-release "Windows Desktop" <path>` once and read the
  error. If templates are missing, **still deliver every file below** and finish
  the slice, reporting at closeout that Dave must install them once via the
  Godot editor's *Editor → Manage Export Templates… → Download and Install*, and
  that the build has therefore not been produced yet. Do not block on it.
- **Requirements.**
  1. `export_presets.cfg` holds exactly one preset, named `Windows Desktop`,
     `platform="Windows Desktop"`, `runnable=true`, export path
     `build/windows/Meadow.exe`, architecture `x86_64`, and
     `export_filter="all_resources"`. Set `application/product_name` and
     `application/file_description` to `Meadow` so the shipped executable is not
     called "Meadow - Claude". **Leave `config/name` in `project.godot`
     untouched** — it is what tells Dave's two worktree windows apart, and
     renaming the product is a separate decision.
  2. `project.godot` gains `config/version="0.1.0-alpha"` in `[application]`.
  3. `.gitignore` gains `build/` (in scope, but off the `Files:` line -- see the note under the table).
  4. `tools/build_alpha.ps1` runs the export into `build/windows/`, then zips it
     to `build/Meadow-<version>-windows.zip`, and prints the zip's path and size
     and nothing else. It states its own shell and directory in its header
     comment, per `CLAUDE.md`'s working style. It must fail loudly, with the
     Godot error, rather than producing a zip of a failed export.
  5. `tests/test_alpha_build.py` is pure Python and runs in under a second: it
     asserts `export_presets.cfg` parses as an INI with exactly one preset, that
     the preset's platform and export path are the two strings above, that
     `project.godot` carries a `config/version`, and that `.gitignore` ignores
     `build/`. **It must not run an export** — `verify.ps1` runs before every
     commit and a build is minutes.
  6. `tools/verify.ps1` gains `tests.test_alpha_build` to its existing
     `-m unittest` module list.
- **Invariants.** `verify.ps1` stays as fast as it is now, to within noise. No
  `scripts/` file changes, so no game behaviour changes.
- **Escalation.** If a release export fails for a reason other than missing
  templates — a missing resource, an addon that cannot be exported
  (`addons/godot_ai` and `addons/copy_all_errors` are editor plugins and should
  be excluded from the export, not shipped) — stop and describe it. A build that
  ships an editor addon to a tester is worth one escalation.

```queue
**[Codex] FB-1 -- a Windows build anyone can run**
- Plan: `plans/now/feedback-build.md` -- "FB-1 — a Windows build anyone can run"
- Files: `export_presets.cfg`, `project.godot`, `tools/build_alpha.ps1`, `tests/test_alpha_build.py`, `tools/verify.ps1`
- Check: one `Windows Desktop` x86_64 preset exporting to `build/windows/Meadow.exe` with product name `Meadow`, `project.godot` carrying `config/version`, `build/` gitignored, `tools/build_alpha.ps1` producing a zip or failing loudly with Godot's error, and `tests/test_alpha_build.py` asserting all of that in under a second without running an export
- Proof: `absent: project.godot :: config/version=`
- Next after: FB-2 -- a scenario can assert when something happened.
```

## FB-2 — a scenario can assert when something happened

Level: medium.

- **Required reading.** This heading. `tools/headless/verdicts.py` whole (145
  lines). `python tools/func.py tools/analyze_session.py analyze _honey_fill_vs_winter _last_snapshot_per_day`.
  `tools/headless/profiles.py`'s `SNAPSHOT_FIELDS` and `_DEFAULTS`.
- **Files to change.** `tools/analyze_session.py`, `tools/headless/verdicts.py`,
  `tests/test_headless_verdicts.py`.
- **The owner is the existing allowlist, not a new tool.** `verdicts.py`'s
  `_METRICS` comment already says a later slice widens it. Add to it. Do not
  build a second report path beside `analyze_session.py`; `_honey_fill_vs_winter`
  is the shape to copy.
- **Derive the milestones from snapshots that already exist.** Every milestone
  below comes from the per-day series the `balance` profile already captures, so
  **this slice writes no GDScript and touches no `scripts/` file**:
  - `milestones.first_worker_day` — the first snapshot day where
    `population.total` exceeds 1.
  - `milestones.winter_entered_day` — the first day `environment.winter_here`
    is true.
  - `milestones.winter_survived_day` — the first day after that where it is
    false again; absent if the run ended in winter.
  - `milestones.food_secure_day` — the first day `resources.food_stores`
    reaches `GameConfig`'s winter requirement, read from the run's own settings
    rather than hardcoded.
- **What is deliberately not here.** A gyne-release *time* needs an event the
  simulation does not emit, so it needs a `scripts/` change and belongs to the
  Claude lane. Say so at closeout rather than adding a fifth milestone that
  guesses.
- **Requirements.** `analyze(...)` gains a `milestones` section, absent-safe:
  a run with no snapshots gets an empty dict, not a crash. `_METRICS` gains the
  four keys above. A milestone that never happened evaluates as `None` and must
  make an `lt`/`lte` expectation **fail**, not pass — "it never happened" is not
  "it happened early", and this is the one subtle correctness question in the
  slice. `tests/test_headless_verdicts.py` covers each milestone, the
  never-happened case for every operator, and a run with no snapshots.
- **Runtime policy.** Pure Python over an already-loaded entry list, computed
  once per analysis in a single pass over the snapshot series. Do not re-walk
  the series per milestone.
- **Automated acceptance.** The new unit tests, plus one real run:
  `python tools/run_scenario.py test_scenarios/colony_30_bees_test.json --full`
  prints a `milestones` section with a plausible `first_worker_day`.

```queue
**[Codex] FB-2 -- a scenario can assert when something happened**
- Plan: `plans/now/feedback-build.md` -- "FB-2 — a scenario can assert when something happened"
- Files: `tools/analyze_session.py`, `tools/headless/verdicts.py`, `tests/test_headless_verdicts.py`
- Check: `analyze()` gains a `milestones` section computed in one pass over the existing per-day snapshots, `verdicts.py`'s `_METRICS` exposes `first_worker_day`, `winter_entered_day`, `winter_survived_day` and `food_secure_day`, a milestone that never happened fails an `lt`/`lte` expectation rather than passing it, a run with no snapshots yields an empty dict rather than a crash, and no `scripts/` file is touched
- Proof: `absent: tools/headless/verdicts.py :: milestones.`
- Next after: FB-3 -- the pacing gates become one command.
```

## FB-3 — the pacing gates become one command

Level: medium.

- **Required reading.** This heading. FB-2's result. `tools/run_scenario.py`'s
  `--repeat` and `--full` handling, and `plans/design/product-scope.md` §3's
  timing table only.
- **Files to change.** `tools/pacing_gates.py` (new),
  `test_scenarios/alpha_arc_test.json` (new), `tests/test_pacing_gates.py`
  (new), `tools/verify.ps1`.
- **Requirements.** One scenario that starts from the standard difficulty
  baseline and runs to the day winter ends, with the `balance` profile and a
  fixed seed. `pacing_gates.py` runs it a small number of times — **default
  three, never more without `--repeat`** — reads each run's `milestones`
  section, and prints one table: milestone, median day, the target from §3's
  table converted to days at the run's own `day_length_seconds`, and whether it
  is inside band. Under 40 lines of output. `tests/test_pacing_gates.py` tests
  the band arithmetic and the table rendering against fixture analyses; it never
  launches Godot, and it is what `verify.ps1` runs.
- **Runtime policy.** Three runs by default, and the script prints the wall
  clock each run took so the cost is visible. It is run deliberately before a
  balance decision, never from `verify.ps1`.
- **Escalation.** If a single arc run cannot finish inside `run_scenario.py`'s
  timeout, stop and report the wall-clock figure rather than raising the
  timeout — a harness that takes an hour is not an instrument anyone will use,
  and the answer may be a shorter scenario.

```queue-gated
**[Codex] FB-3 -- the pacing gates become one command**
- Plan: `plans/now/feedback-build.md` -- "FB-3 — the pacing gates become one command"
- Files: `tools/pacing_gates.py`, `test_scenarios/alpha_arc_test.json`, `tests/test_pacing_gates.py`, `tools/verify.ps1`
- Check: `python tools/pacing_gates.py` runs a fixed-seed arc scenario three times, prints one table of milestone, median day, the §3 target in days and whether it is inside band in under 40 lines, reports each run's wall clock, and `tests/test_pacing_gates.py` proves the band arithmetic without launching Godot
- Proof: `absent: tools/verify.ps1 :: pacing_gates`
- Next after: none -- feedback-build is complete once FB-3 ships.
```

## Read on demand

<!-- LAYER: on-demand -->

- `docs/headless-run-contract.md` — the contract FB-2 and FB-3 extend.
- `plans/design/product-scope.md` §3 (the timing table), §14 (the evidence
  stream) and §15 (what the closed alpha means). Nothing else in that file.
