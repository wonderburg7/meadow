# Performance review -- 16 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 12c1393 | Since: first run | Scope: per-frame bee work (state machine, idle dispatch, forager search, presentation updates), flowers, cells, HUD and housekeeping cadence, render cost at 500 bees, the pinned baseline and the measurement instruments; the codebase review's section C (18 Sep 2026) and the hot-path-queries and render-scale plans' outcomes as the starting point | Previous: none

Eight headless or windowed runs, all at `12c1393` on Dave's machine:
the pinned fixture three times (`--fixed-fps 60`), SPR-2's 500-bee
scenario three times (one with a temporary idle-dispatch gate, two
windowed, one of those with a temporary colour guard) and its 1,000-bee
scenario once. Extra sections came from scratch copies of the fixtures
that only lengthen the `sections` list. Both temporary patches were
reverted; no code changed on this branch.

## Follow-through

None -- first run. The codebase review's section C was audited in place
of a previous record: its C-1 (F2 below) was planned as IDLE-1 in a
`plans/now` file (idle-dispatch) that was never created, so it was orphaned
and is routed below; its C-2 items are F8; its C-3 items are unchanged
and noted.

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | A SEARCHING forager runs two spatial-grid flower queries every frame, against `bee.gd`'s own rule that picking a flower runs on the 8 Hz think tick. It is the largest section in the pinned fixture: 6.42 ms mean (p95 11.98) of a 16.78 ms frame with 85 foragers, and scales with every searching forager. | `bee_foraging.gd::search_for_flower`, `_perceive_flower`; `bee.gd` comment above `THINKS_PER_SECOND`; pinned fixture with `bee_search` added to `sections` | high | Queued -- HP-1 in `plans/archive/hot-path-cadence_2026-10-18.md` |
| F2 | Idle nurses, comb workers and honey makers call `_idle_dispatch` every frame; only miners wait for a dispatch tick. 500 nurses: `bee_state_nurse` 5.14 ms; with a temporary `if thinking:` gate 2.27 ms, frame 17.36 → 14.48 ms, brief-report counters identical. | `bee.gd::_process` `NURSE_IDLE`/`BUILD_IDLE`/`HONEY_IDLE` arms; `grep -n "_idle_dispatch()" scripts/bee.gd`; `spr2_render_500.json` with extra sections | high | Queued -- HP-2 in `plans/archive/hot-path-cadence_2026-10-18.md` |
| F3 | The per-frame label and ring refresh costs 2.22 ms at 500 bees and 4.55 ms at 1,000; `_update_label` reformats text and recomputes colour every frame, but its share is unmeasured. | `bee.gd::_process` `bee_label` span, `_update_label`; 500- and 1,000-bee runs | medium | Queued -- HP-3 in `plans/archive/hot-path-cadence_2026-10-18.md` (measures first, changes only if it is at least half) |
| F4 | `docs/performance.md` recorded an unexplained 500-bee headless slowdown (33-39 ms, slower than 1,000 bees). It did not reproduce: 17.4 ms at 500, 32.1 ms at 1,000, `bees` 13.3 and 27.2 ms, linear. | `docs/performance.md` "Canvas cost by colony size"; `spr2_render_500.json`, `spr2_render_1000.json` | low | Fixed -- the paragraph now gives the 16 Oct re-run and what the 500-bee windowed frame is made of |
| F5 | A capture from the run that seeds a fresh worktree's Godot cache read 27.2 ms against 15.4 ms for the next identical run; two consecutive windowed runs of one build differed by 20%. A single-run comparison would read noise as a regression. | `run_scenario.py` output line `godot cache: seeded from the primary`; pinned fixture runs 1 and 2 | medium | Fixed -- "Repeatability" in `docs/performance.md`; HP-1 and HP-2 discard such a run |
| F6 | The pinned baseline table carries miner and fog rows only, while the frame it measures is now dominated by forager search, so the table could not show where the time goes. | `docs/PERFORMANCE_BASELINE.md`; pinned fixture run 3 | medium | Fixed -- "Performance review re-measure -- 16 Oct 2026" section with the comparable rows and the forager split |
| F7 | Hypothesis: writing `body.color` every frame forces each on-screen bee's Polygon2D to redraw. | `bee.gd::_update_label`; windowed 500 bees with and without an unchanged-colour guard (17.97 vs 21.55 ms, every section slower: noise) | low | Rejected -- measured no gain |
| F8 | Codebase review C-2: `debug_panel.gd::_process` refreshes the stage row every frame; `main.gd::_prune_selection` filters three arrays every frame. | `prune_selection` 0.005 ms, `hud` 0.007 ms at 500 bees; neither scales with the colony | low | Rejected -- microseconds a frame, constant |

## Hand-offs

- Product review: no colony size or frame budget exists to judge
  performance against -- `plans/observations/system-improvement-signals.md`,
  "2026-10-16 — no colony size or frame budget to judge performance
  against (from the performance review)".

## Noted, not pursued

- `bee_burn` 2.0-4.8 ms (about 4.8 µs a bee): ordinary GDScript cost in
  `bee_survival.gd::age_and_burn`, which also holds the per-frame death
  check; no single waste found.
- `flowers` 1.5-2.0 ms whatever the colony: ageing per frame, drawing
  already throttled by `presentation_timer`.
- Fog's p95 is 25-26 ms against 19.5 ms on 13 Sep, its mean within 20%;
  stays deferred under `plans/reference/technical-audit.md`.
- Codebase review C-3 (`find_empty_cell`/`find_cell_for` full passes,
  1 Hz `get_nodes_in_group("bees")` walks) unchanged and still small.
- The review file needed no correction (contract rule 10).

## Not reviewed

Pathfinding (on the do-not-change list), fog internals, the rival hive,
rain, save and restore cost, the Challenge runner, and windowed render
at 1,000 bees (SPR-2's jump from 253 to 1,181 draw calls was not
re-measured).

## Patterns deliberately not applied

- An obstacle spatial index, object pooling or MultiMesh: no measurement
  points at them (`docs/performance.md`, "Explicitly do not change").
- An unchanged-colour guard on `body.color` (F7): measured, no gain.
- Throttling `age_and_burn`: it carries the per-frame starvation and
  old-age death checks, a simulation outcome.
