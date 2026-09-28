# Hot-path queries — measure `find_food_cell` under the load it was written for

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: PERF-3 -- `find_food_cell` reads the content index, queued in the Codex lane | Dependency: PERF-2 measurement (28 Sep 2026) | Verified: 2026-09-28

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
| PERF-3 | `find_food_cell` reads the existing content buckets without changing its chosen cell | `scripts/hive.gd`, `docs/PERFORMANCE_BASELINE.md` | yes | high |

PERF-2 measured `hive_find_food` at 11.65--14.73% of frame time in the
intended hungry-indoor workload, so PERF-3 is warranted. Do not change
`find_cell_for` or `find_empty_cell`: the audit records why a bucket walk would
change which cell they choose.

PERF-2 shipped 2026-09-28; its specification is `plans/archive/PERF-2_2026-09-28-closeout.md`.

## PERF-3 -- `find_food_cell` reads the content index

Level: high -- changes a measured hot-path query.

- **Required reading.** This heading, `.claude/rules/performance.md`, and
  `plans/reference/technical-audit.md`, "A. `hive.gd`'s `find_*` functions
  bypass the content index that already exists".
- **Files to change.** `scripts/hive.gd`, `docs/PERFORMANCE_BASELINE.md`.
- **Requirements.** Replace the two full `cells` walks in `find_food_cell`
  with the existing `ripe_honey` then `nectar` buckets from `cells_holding`.
  Keep the current first-match ordering, `except`, validity, withdrawability,
  amount checks, return values, and the balanced `hive_find_food` Perf span.
  Do not alter index invalidation or any other `find_*` helper.
- **Validation.** Run the existing focused Godot compile check and the pinned
  hungry-indoor scenario twice at the default fixed FPS. Record both post-change
  `hive_find_food` mean/p95 readings and frame-time share beside PERF-2's table;
  the query must remain non-zero and materially below the pre-change readings.
  Review the diff against the audit's equivalence argument before hand-off.
- **Closeout.** This is high risk: commit and push, then hand the branch to
  Claude for full review and `finish`; do not merge it directly.

```queue
**[Codex] PERF-3 -- `find_food_cell` reads the content index**
- Plan: `plans/now/hot-path-queries.md` -- "PERF-3 -- `find_food_cell` reads the content index"
- Files: `scripts/hive.gd`, `docs/PERFORMANCE_BASELINE.md`
- Check: the focused Godot compile check is green; two `perf2_hungry_indoor.json` captures keep `hive_find_food` non-zero and materially below PERF-2's recorded mean
- Proof: `absent: docs/PERFORMANCE_BASELINE.md :: PERF-3 measurement`
- Next after: close candidate A in `plans/reference/technical-audit.md` if the index-backed runs preserve the fixture's outcome
```

## Read on demand

- `plans/reference/technical-audit.md`, "A. `hive.gd`'s `find_*` functions
  bypass the content index that already exists" -- the equivalence argument
  PERF-3 would rely on.
- `.claude/rules/performance.md` -- only if PERF-3 is written.
