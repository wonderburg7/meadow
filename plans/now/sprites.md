# Sprites -- measure the procedural rendering before any sprite pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None -- plan complete; whether a sprite path behind a simple-graphics fallback follows is decided with Dave from the Evidence numbers in SPR-1 | Dependency: none -- no other live plan owns the files below | Verified: 2026-10-06

## Objective

`DESIGN_BACKLOG.md` "Deferred product decisions", **Sprites**: procedural
shapes stay the baseline. A sprite pass must keep a simple-graphics fallback
and must measure performance rather than assume sprites are cheaper. Dave
chose this direction as the next Claude-lane plan on 6 Oct 2026, from
`/run-queue`. This plan's first job is the measurement. Whether a sprite path
follows, and what it draws, is decided with Dave from SPR-1's numbers.

## Current state

Verified 6 Oct 2026 against master:

- Each bee builds about ten `Polygon2D` children in `scripts/bee.gd`
  (selection, alarm, attack, search and dance rings, outline, outline ring,
  body, centre dot, heading marker). Flowers, obstacles and death markers
  are `Polygon2D` as well. Only `hive_cell.gd` uses a `Sprite2D`.
- `scripts/perf.gd` already has a scenario-owned capture
  (`start_capture` / `capture_summary`, started from `main.gd` when a
  scenario declares `performance_capture`). It records frame time and named
  sections, but no render counters.
- `tools/run_scenario.py::run_once` always launches with `--headless`, which
  uses the dummy renderer. So every captured frame time so far excludes
  canvas and GPU cost entirely. Nobody has measured what the procedural
  shapes cost to draw.
- `docs/performance.md` "Explicitly do not change" forbids MultiMesh
  rendering or pooling without a measured bottleneck pointing at it. That
  rule stands. SPR-1 gathers the measurement it asks for and changes no
  rendering.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |

SPR-1 shipped 2026-10-06; its specification is `plans/archive/SPR-1_2026-10-06.md`.
