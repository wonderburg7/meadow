Landed 2026-09-28 on `codex/PERF-2`. Live plan: `plans/now/hot-path-queries.md`.

## PERF-2 -- a pinned hungry-indoor scenario measures `find_food_cell`

Level: medium.

- **Required reading.** This heading,
  `test_scenarios/recommendation_slice0_baseline.json` (the capture shape to
  copy), `scripts/levels.gd::apply_config_overrides`, and the scenario verbs
  list in `scripts/scenario_actions.gd`'s `# --- _execute ---` section only.
- **Files to change.** `test_scenarios/perf2_hungry_indoor.json` (new),
  `docs/PERFORMANCE_BASELINE.md`.
- **Requirements.** A fixed-seed scenario with a large indoor population
  (nurses, around 100) on a comb of around 60 built cells, a
  `performance_capture` block like the baseline's with `hive_find_food` and
  `frame_time_ms`, and `include_fog` false so fog cost does not swamp the
  reading. Make the hungry path run on every think tick for every indoor bee
  in the window: override `hunger_threshold` to `1.0` through
  `config_overrides`, and make sure no cell holds ripe honey or nectar during
  the window (empty any starting stores with the existing verbs), so every
  call is the worst case -- two full passes returning `null`. Name the file
  without a `_test` suffix, as the baseline is, so no suite runs it.
- **Measurement.** Run it twice with `python tools/run_scenario.py
  test_scenarios/perf2_hungry_indoor.json` at the default fixed fps and read
  only `sections_ms` and `frame_time_ms` from each result. Add a "PERF-2
  measurement" section to `docs/PERFORMANCE_BASELINE.md`, below PERF-1's,
  with the fixture, seed, population and cell count, both runs'
  `hive_find_food` mean and p95, its share of frame time, and one line of
  verdict: PERF-3 is worth specifying if the mean share is 2% or more of
  frame time, otherwise the audit's candidate A is closed as measured-trivial.
- **Escalation.** If the scenario cannot keep both stores empty with existing
  verbs, or the population will not stay indoors, stop and report which --
  do not add a scenario verb or change `hive.gd` in this slice. If the two
  runs differ by more than 10%, run a third and report all three rather than
  choosing.

```queue
**[Codex] PERF-2 -- a pinned hungry-indoor scenario measures find_food_cell**
- Plan: `plans/now/hot-path-queries.md` -- "PERF-2 — a pinned hungry-indoor scenario measures `find_food_cell`"
- Files: `test_scenarios/perf2_hungry_indoor.json`, `docs/PERFORMANCE_BASELINE.md`
- Check: two runs of `python tools/run_scenario.py test_scenarios/perf2_hungry_indoor.json` both record a non-zero `hive_find_food` mean within 10% of each other, and `docs/PERFORMANCE_BASELINE.md` records both readings, their share of frame time and whether PERF-3 is worth specifying
- Proof: `absent: docs/PERFORMANCE_BASELINE.md :: PERF-2 measurement`
- Next after: PERF-3 -- `find_food_cell` reads the content index, specified only if PERF-2 finds the section non-trivial
```
