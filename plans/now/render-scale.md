# Render scale -- where drawing the procedural bees stops fitting a frame

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: nothing further -- SPR-2 landed; a sprite or batching pass is decided with Dave from the table in docs/performance.md | Dependency: none | Verified: 2026-10-06

## Objective

Decide from measurement whether a sprite pass, or batching the bee
polygons, is needed for performance at all. `DESIGN_BACKLOG.md`'s
"Sprites" decision stands: procedural shapes stay the baseline, and a
sprite pass must keep a simple-graphics fallback. Dave chose this scale
test on 6 Oct 2026 as the step after SPR-1.

## Current state

Verified 6 Oct 2026. SPR-1 (`plans/archive/sprites_2026-10-06.md`) added
`run_scenario.py --windowed` and `Perf.capture_summary()["render"]`. Its
baseline, `test_scenarios/spr1_render_baseline.json`, has 200 nurses in
the hive view. It measured 406 draw calls, 564 render objects and 15,292
nodes, with a mean frame time of 13.6-14.8 ms (p95 16-18 ms) across two
windowed runs: inside 60 fps, with little headroom. Nobody has measured a
larger colony.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |

SPR-2 shipped 2026-10-07; its specification is `plans/archive/SPR-2_2026-10-07.md`.
