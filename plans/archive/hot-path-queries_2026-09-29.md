# Hot-path queries — measure `find_food_cell` under the load it was written for

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Codex | Next: None — plan complete; follow-up: the other `find_*` rows of candidate A are closed unmeasured in `plans/reference/technical-audit.md` and reopen only as a new measurement slice | Dependency: none | Verified: 2026-09-29

**Objective.** Decide, from a measurement rather than a reading of the code,
whether `hive.gd::find_food_cell` should read the content index
(`plans/reference/technical-audit.md`, "A. `hive.gd`'s `find_*` functions
bypass the content index that already exists"). PERF-1 added the
`hive_find_food` Perf section, but its fixture produced no hungry indoor bees,
so both captures read 0.000 ms (`docs/PERFORMANCE_BASELINE.md`, "PERF-1
measurement -- 20 Sep 2026").

## Current state

`BeeSurvival.should_go_and_eat` calls `find_food_cell` on every think tick for
every bee that is inside the hive, not already feeding or mid-action, and at
or below `GameConfig.hunger_threshold` of its energy. `find_food_cell` walks
`cells` twice (ripe honey, then nectar) and returns `null` only after both
full passes. `Perf.capture_summary()` reports each captured section's
per-frame mean and p95 in ms; it does not count calls.

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |

PERF-2 measured `hive_find_food` at 11.65--14.73% of frame time in the
intended hungry-indoor workload, so PERF-3 is warranted. Do not change
`find_cell_for` or `find_empty_cell`: the audit records why a bucket walk would
change which cell they choose.

PERF-2 shipped 2026-09-28; its specification is `plans/archive/PERF-2_2026-09-28.md`.

PERF-3 shipped 2026-09-29; its specification is `plans/archive/PERF-3_2026-09-29.md`.

## Read on demand

- `plans/reference/technical-audit.md`, "A. `hive.gd`'s `find_*` functions
  bypass the content index that already exists" -- the equivalence argument
  PERF-3 would rely on.
- `.claude/rules/performance.md` -- only if PERF-3 is written.
