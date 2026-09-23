# Verification cost — stop paying for checks that carry no information

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: None — plan complete | Dependency: none | Verified: 2026-09-23

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

Dependencies, stated rather than implied. V-1 and V-2 both edit
`tools/verify.ps1`, so they run in that order in one lane; V-2 does not need
V-1's outcome, only its file. V-3 shares `tools/update_function_map.py` with
V-1 and so follows it. None of the three depends on the other lane.

**Files this plan may not take.** `tools/slice.ps1` and
`tools/session_cost.py` are the Codex lane's (L-14 and the telemetry plan,
archived at `plans/archive/workflow-telemetry_2026-09-20.md`), and
`tests/test_source_checks.py` is that lane's too. `scripts/hive.gd` is
PERF-1's and `scripts/hive_cell.gd` is CB-2's. V-1 and V-2 must therefore
leave `Invoke-SliceFinish` alone; V-3 and V-4 must leave `hive.gd` and
`hive_cell.gd` alone. If a fix turns out to need one of
them, stop and escalate rather than taking the file.

V-4 shipped 2026-09-23; its specification is `plans/archive/V-4_2026-09-23.md`.
