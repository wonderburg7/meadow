# Verification cost — stop paying for checks that carry no information

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: V-1 -- verification regenerates its generated files instead of asserting them, queued in the Claude lane | Dependency: none | Verified: 2026-09-20

**Objective.** `tools/verify.ps1` runs before every commit, so anything it
spends is multiplied by every slice. Two of its costs are measured and neither
buys information: a fifth of its failures are a generated file being out of
date, and five sixths of its wall-clock is one suite that rarely fails. Remove
both without removing a check.

**State.** Measured on 20 Sep 2026 from
`python tools/session_cost.py --events`, 1212 events over seven days, 489
verify stages:

- `verify failures  function map=16, doc checks=12, godot boot=9,
  source checks=4, lifecycle tests=2`. `function map` is the largest single
  category, over 78 runs. The stage is
  `tools/update_function_map.py --check`, which compares a **generated** file
  against its own generator; every failure is a stop, one regeneration command
  and a retry, with no judgement in between. `stage reference`
  (`tools/stage_reference.py --check`) is the same shape.
- `lifecycle tests 80 runs median 229.6s` against `godot boot 62 runs median
  6.9s` and under 2s for every other stage. That is roughly five hours of the
  week's verification wall-clock in one stage, paid by every branch-scope run
  whether or not the branch touched the lifecycle tooling, for 2 failures.
- CLAUDE.md routes a session into a large script by its
  `# --- section ---` headers. Three scripts over 700 lines have none at all
  and two have their first header past 70% of the file, so for those the
  routing rule silently degrades to reading the file.

Both measurements are recorded as untriaged signals in
`plans/observations/system-improvement-signals.md` (20 Sep 2026); this plan is
their promotion, and their disposition points here.

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| V-2 | The lifecycle suite runs on branches that touch lifecycle tooling, and in full on the primary checkout | `tools/verify.ps1` | yes | medium |
| V-3 | Every script over 700 lines carries the section headers the routing rule assumes | `scripts/settings_catalogue.gd`, `scripts/bee_foraging.gd`, `scripts/debug_panel.gd`, `scripts/challenge_runner.gd`, `scripts/diagnostic_log.gd`, `scripts/bee.gd`, `tools/update_function_map.py` | yes | low |

Dependencies, stated rather than implied. V-1 and V-2 both edit
`tools/verify.ps1`, so they run in that order in one lane; V-2 does not need
V-1's outcome, only its file. V-3 shares `tools/update_function_map.py` with
V-1 and so follows it. None of the three depends on the other lane.

**Files this plan may not take.** `tools/slice.ps1` and
`tools/session_cost.py` are the Codex lane's (L-14 and the telemetry plan
`plans/now/workflow-telemetry.md`), and `tests/test_source_checks.py` is
that lane's too. `scripts/hive.gd` is PERF-1's and `scripts/hive_cell.gd` is
CB-2's. V-1 and V-2 must therefore leave `Invoke-SliceFinish` alone; V-3 must
leave `hive.gd` and `hive_cell.gd` alone. If a fix turns out to need one of
them, stop and escalate rather than taking the file.

V-1 shipped 2026-09-20; its specification is `plans/archive/V-1_2026-09-20.md`.

## V-2 — the lifecycle suite runs where it can fail

`tools/verify.ps1` starts `lifecycle tests` as a background job on every
branch-scope run (line 196), except inside closeout, where SF-1 had to exclude
it with `MEADOW_FINISH_VERIFY` because the suite drives `finish` in temporary
repositories and recursed. So the stage that proves closeout is the one stage
closeout does not run, and every other branch pays 230s for it.

**Start by checking the failure history, and let it choose the shape.** Over
the seven days to 20 Sep 2026 the suite ran 80 times and failed twice. Find
those two failures (`python tools/session_cost.py --events`, then the branches
they sit on) and answer one question: did they catch a defect in lifecycle
tooling, or something else?

- If both were lifecycle-tooling defects, scope the stage: run it on a branch
  whose diff against `master` touches `tools/slice.ps1`, `tools/hook_log.py`,
  `tools/archive_slice.py`, `tools/refill_lane.py`, `tools/check_docs.py`,
  `NEXTSTEPS.md` or `tests/`, and skip it otherwise, printing `skipped --
  branch touches no lifecycle tooling` so the skip is visible. Run it
  unconditionally in the primary scope, which is where the post-merge run
  happens.
- If they caught something outside that set, the scoping rule is wrong and the
  suite needs reshaping rather than rescheduling. Record what the two failures
  were, leave the stage alone, and stop -- that is a finding, not a failure to
  deliver.

Fixed now either way:

- **Invariants.** The suite still runs in full somewhere on every change that
  can break it. A skip is printed and recorded in the `verify_stage` event
  with `skipped` rather than `ok`, so the rate of skipping is measurable.
  `-Scope primary` and `-Scope all` behaviour for the other stages is
  unchanged.
- **Out of scope.** Removing the `MEADOW_FINISH_VERIFY` guard needs
  `tools/slice.ps1`, which is the Codex lane's. Leave the guard in place and
  name the removal in the delivery note.
- **Proof it worked.** On a branch touching only `scripts/*.gd`,
  `.\tools\verify.ps1` completes without the 230s stage and says why; on a
  branch touching `tools/slice.ps1` it runs it.

Level: medium -- the decision is bounded and the evidence is named, but it
changes when a check runs, so the reasoning must be written down.

## V-3 — the routing rule's section headers actually exist

CLAUDE.md tells a session to read the routed section of a large script rather
than the file, and says: "Every script over 700 lines is indexed in
`FUNCTION_MAP.md`; for any other, search its `# --- section ---` headers."
H2 gave `hud.gd` ten headers and `main.gd` six on 11 Sep 2026 and stopped
there. Measured 20 Sep 2026:

| Script | Lines | Headers | First at |
| --- | --- | --- | --- |
| `settings_catalogue.gd` | 1421 | 0 | -- |
| `bee_foraging.gd` | 1381 | 0 | -- |
| `debug_panel.gd` | 1000 | 0 | -- |
| `challenge_runner.gd` | 1234 | 1 | 1183 |
| `diagnostic_log.gd` | 1163 | 1 | 872 |
| `bee.gd` | 2369 | 17 | 911 |

Give each of those six the same treatment `hud.gd` got: comment-only
`# --- name ---` headers at the boundaries that already exist in the file, so
`python tools/heading.py`-style routing and a plain grep both land in the
right region.

- **Invariants.**
  - Comments only. Not one line of code moves, and no function is reordered.
  - A header goes **between** functions, never inside one:
    `tools/func.py` treats `# ---` as a function boundary, so a header dropped
    mid-function would truncate what it prints.
  - `.\tools\verify.ps1` is green and the Godot boot passes -- a comment
    cannot break either, which is what makes this low.
- **Name the boundaries that are there.** Do not invent a structure the file
  does not have. Where a region is interleaved rather than contiguous, record
  that in the delivery note and leave it unheadered, as H2 did for "role
  controls" and "speed controls".
- **Keep it true afterwards.** Add a warning (not a failure) to
  `tools/update_function_map.py`, which already scans exactly the files over
  700 lines: name any of them whose first `# ---` header falls after the first
  tenth of the file, or that has none. A warning, so a new large file does not
  block a commit, but the gap is never invisible again.
- **Completion.** Archive this plan with `Next: None — plan complete`.

Level: low -- mechanical, comment-only, one acceptance check.
