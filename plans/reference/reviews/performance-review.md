# Runtime performance and update-policy review

<!-- CONTEXT: review-prompt | LOAD: only when running this review -->
Record key: performance-review
Watches: scripts docs/PERFORMANCE_BASELINE.md docs/performance.md .claude/rules/performance.md test_scenarios

**Owns:** how often things run and what they cost as the colony grows:
`_process` and `_physics_process`, timers and ticks, full-set scans,
pathfinding, visibility and fog, UI refresh cadence, flower and ecology
updates, bee decisions, spawning and freeing, allocation in hot paths,
caches, indexes and dirty flags; render cost at high population (draw calls,
sprite and comb drawing); and the measurement instruments themselves.

**Hand-offs:** structural catalogues: architecture review. Whether cached
state is correct after a restore: save review.

**Read first:** `.claude/rules/performance.md`, `docs/performance.md`,
`docs/PERFORMANCE_BASELINE.md`, and the "Deferred work" section of
`plans/reference/technical-audit.md` (those items stay deferred unless a
fresh, comparable profile says otherwise). On the first run (no record yet),
also `python tools/heading.py docs/codebase-review-2026-09-18.md "C. Runtime
and performance"`, and the
outcomes of the finished plans `plans/archive/hot-path-queries_2026-09-29.md`
and `plans/archive/render-scale_2026-10-07.md` (through `git show`, their
results sections only) so you do not redo them.

## Steps

1. **Measure first**, with the existing instruments (`scripts/perf.gd`,
   `scripts/perf_breakdown.gd`, the headless profiles in
   `docs/performance.md`, and for render cost `python tools/run_scenario.py
   <scenario> --windowed`). Use the baseline's scenarios and populations so
   numbers are comparable. Up to eight headless runs; extract only the
   timing fields.
2. **List the recurring work.** Grep for `_process`, `_physics_process`,
   `Timer`, `get_nodes_in_group` and loops over `get_children()`. For each
   system record its trigger, frequency, work per call, and how it scales
   with bees, cells and flowers. Open only the functions that rank highest
   on measured cost or on scaling.
3. **For each worthwhile finding** give: evidence; trigger frequency;
   measured or estimated cost at the current population and at the target
   population (from `ROADMAP.md` or the pacing targets; do not invent one);
   current and recommended policy (event, dirty flag, staggered tick,
   bounded query, only while visible); behavioural risk (event ordering,
   determinism); the measurement or regression check that proves the gain;
   affected files.
4. No invented budgets and no optimisation without evidence. Preserve
   simulation outcomes and event ordering; any change that might alter them
   needs `python tools/equivalence.py <scenario> <ref>`. Rank by measured or
   strongly evidenced benefit divided by effort. Slices go in the live plan
   that owns the area, or a new `plans/now/` file if none does.
