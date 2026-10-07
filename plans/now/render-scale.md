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
| SPR-2 | the windowed render baseline at 500 and 1,000 bees | `test_scenarios/spr2_render_500.json`, `test_scenarios/spr2_render_1000.json`, `docs/performance.md` | yes | low |

## SPR-2 -- the windowed render baseline at 500 and 1,000 bees

<!-- LAYER: immediate-task -->

Level: low (two scenario copies, four runs, and one recorded table).

**True now.** See "Current state": the render baseline stops at 200 bees.

**True afterwards.**

- `spr2_render_500.json` and `spr2_render_1000.json` copy
  `spr1_render_baseline.json` with `nurses` at 500 and 1,000, and nothing
  else changed except `cells` if the hive needs room for them.
- Each is run once with `--windowed` and once headless
  (`python tools/run_scenario.py <file> [--windowed] --report full`, from
  the worktree). The windowed minus headless frame time is the drawing
  share.
- `docs/performance.md` gains a short "Canvas cost by colony size (SPR-1,
  SPR-2)" table: population, draw calls, render objects, nodes, and
  windowed and headless frame time (mean and p95), for 200, 500 and 1,000
  bees. Under it goes one sentence naming the population where the windowed
  p95 first passes 16.7 ms, or saying it never does up to 1,000.

**Must not change.** Any code, any existing scenario, and the
"Explicitly do not change" list in `docs/performance.md`. The table
records evidence, and does not lift that list's MultiMesh rule.

```queue
**[Claude] SPR-2 -- the windowed render baseline at 500 and 1,000 bees**
- Plan: `plans/now/render-scale.md` -- "SPR-2 -- the windowed render baseline at 500 and 1,000 bees"
- Files: `test_scenarios/spr2_render_500.json`, `test_scenarios/spr2_render_1000.json`, `docs/performance.md`
- Check: `python tools/run_scenario.py test_scenarios/spr2_render_1000.json --windowed --report full` exits 0 with a draw-call mean above 0; `docs/performance.md` holds the table for 200, 500 and 1,000 bees; `python tools/check_docs.py` passes
- Proof: `absent: docs/performance.md :: SPR-2`
- Next after: none -- plans/now/render-scale.md is complete once SPR-2 lands; whether a sprite or batching pass follows is decided with Dave from the table
```
