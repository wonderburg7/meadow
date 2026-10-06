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
| SPR-1 | a windowed render baseline for the procedural bees | `tools/run_scenario.py`, `scripts/perf.gd`, `tests/test_run_scenario_launch.py`, `test_scenarios/spr1_render_baseline.json` | yes | medium |

## SPR-1 -- a windowed render baseline for the procedural bees

<!-- LAYER: immediate-task -->

Level: medium (a launcher flag, capture-only counters and one recorded
measurement, with a unit test).

**True now.** See "Current state": captures run only headless, and
`capture_summary()` has no render counters.

**True afterwards.**

- `python tools/run_scenario.py <scenario> --windowed` launches the same run
  without `--headless` and with `--disable-vsync` (Godot's own flag, listed
  by `Godot.exe --help`), so frame time is not pinned to the refresh rate.
  Everything else about the launch is unchanged, `--fixed-fps` included.
  Without `--windowed` the command line is byte-for-byte what it is today.
- `Perf.capture_summary()` gains a `render` entry: mean and p95 of
  `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME` and
  `RENDER_TOTAL_OBJECTS_IN_FRAME` over the measured frames, plus
  `OBJECT_NODE_COUNT` at the end of the capture. **Runtime policy:** sampled
  once per measured frame, only while a scenario capture is running, in the
  existing `_capture_frame`. Normal play never captures, so the per-frame
  path outside a capture is unchanged. Headless runs report zeros. That
  marks the dummy renderer, and is not a bug.
- `test_scenarios/spr1_render_baseline.json` copies
  `perf2_hungry_indoor.json`'s shape (indoor, `time_scale` 1, a
  `performance_capture` block), with a calm colony (no `hunger_threshold`
  override) and 200 bees, so the bees are on screen in the hive view.
- This section gains a short "Evidence" paragraph: one headless run and one
  `--windowed` run of that scenario on Dave's machine, giving frame time
  mean/p95, draw calls and node count for each. The windowed run briefly
  opens a game window. That is expected, and it closes itself at the
  scenario's stop.

**Must not change.** Any rendering, any `Polygon2D` construction in
`bee.gd`, the HUD's rolling perf instrumentation, the scenario keys that
`main.gd` accepts for `performance_capture`, and the headless command line.
**Stop and escalate** if the windowed run cannot finish on its own. That
would mean a scenario that needs a window has a different stop path, which
changes `main.gd` and this slice's file list.

**Evidence** (6 Oct 2026, `test_scenarios/spr1_render_baseline.json`, 200 bees
indoors, `--fixed-fps 30`, 480 measured frames). Headless: frame time mean
16.5 ms, p95 33.7 ms; draw calls and objects 0 (dummy renderer); node count
15292. `--windowed`: frame time mean 14.8 ms, p95 18.2 ms; draw calls 406
(mean and p95); objects 564; node count 15292.

```queue
**[Claude] SPR-1 -- a windowed render baseline for the procedural bees**
- Plan: `plans/now/sprites.md` -- "SPR-1 -- a windowed render baseline for the procedural bees"
- Files: `tools/run_scenario.py`, `scripts/perf.gd`, `tests/test_run_scenario_launch.py`, `test_scenarios/spr1_render_baseline.json`
- Check: `python -m unittest tests.test_run_scenario_launch` passes with a new case asserting that `--windowed` drops `--headless` and adds `--disable-vsync`, and that the default command line is unchanged; `python tools/run_scenario.py test_scenarios/spr1_render_baseline.json --windowed` exits 0 and its capture shows a draw-call mean above 0; `tools/verify.ps1` is green
- Proof: `absent: tools/run_scenario.py :: --windowed`
- Next after: none -- plans/now/sprites.md is complete once SPR-1 lands; whether a sprite path behind a simple-graphics fallback follows is decided with Dave from its numbers
```
