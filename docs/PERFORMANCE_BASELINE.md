# Performance baseline contract

`test_scenarios/recommendation_slice0_baseline.json` is the pinned Slice-0
baseline: seed `20260825`, 85 nectar foragers, 24 miners with no automine
orders, a 120-frame warm-up, then a 480-frame measurement window. Run it with
the fixed-step setting stated alongside a result, for example:

```powershell
python tools/run_scenario.py test_scenarios/recommendation_slice0_baseline.json --fixed-fps 60 --report brief
```

The final JSONL `summary.performance` is the machine-readable comparison
table. It contains mean and p95 wall-clock milliseconds for total frame time
and the three target sections: `bee_state_miner`, `fog_of_war_update`, and
`fog_of_war_relight`. `section_totals_are_overlapping` is deliberately true:
the role span is nested in `bee_state`, and fog relight is nested in fog
update. Compare each section with itself; never add rows to explain a frame.

The prior exploratory profile (6 FPS / 144.8 ms) is historical context only,
not an acceptance threshold. A changed machine, renderer, zoom/camera or
fixed-step configuration requires a new comparable baseline rather than a
claim against that number. This fixture opts into the fog CPU path while still
skipping camera/input presentation; visible fog/FPS evidence must additionally
record camera position and zoom.

## Invalidation contracts for the following slices

The hive owns mining-work availability. Its work epoch must increment when an
order is added or removed, a block is marked or unmarked, a reservation is
acquired/released/expires, work completes, or topology changes. Idle miners
may compare that epoch, but may not invent a separate polling owner.

Miner dispatch is capped at 8 Hz and phase-offset by the stable bee ID, so a
new mark or other epoch change is observed within 125 ms. A miner that has
confirmed there is no suitable work records that epoch and does no further
global work search until the Hive invalidates it (or its automine mode changes).
The existing shared-progress rule is intentional: multiple miners may still
dig one marked block together after reaching it.

Fog owns temporary reveal contributions. A contribution is invalidated when
its source moves beyond the relight threshold, disappears/goes indoors, its
reveal radius changes, or world/fog topology changes. Permanent discovery is
separate and survives contribution removal.

## Slice 2 relight contract

The moving-disc path represents the shared reveal disc as exact horizontal
row spans. On a normal move it updates only the entering and leaving pieces
of each row; overlapping sources still use `_lit_count`, so removing one
source never unlights tiles lit by another. A first source, a departed source,
or a changed radius uses the complete row spans. `_paint_tile` always writes
the resulting temporary state, including `MASK_LIT`, to the persistent mask.

Manual acceptance remains necessary: with fog enabled at the target zoom,
move a bee one tile horizontally and diagonally, overlap two bees, then return
one indoors. The visible disc must not flicker, a tile covered by the remaining
bee must stay lit, and a tile discovered by either bee must remain explored.

## G2 re-measure -- 17 Sep 2026 (the catalogue dispatcher)

Same fixture (`test_scenarios/recommendation_slice0_baseline.json`), same
seed, same machine, run once per side within a few minutes of each other, so
these two rows compare with each other and not with the pinned baseline
below. The catalogue walk is not slower than the `match` it replaced.

| Row | master mean ms | G2 mean ms | master p95 ms | G2 p95 ms |
| --- | --- | --- | --- | --- |
| `frame_time_ms` | 10.35 | 10.13 | 19.12 | 17.32 |
| `bee_state_miner` | 0.077 | 0.085 | 0.104 | 0.106 |
| `fog_of_war_update` | 2.98 | 2.87 | 10.14 | 9.73 |
| `fog_of_war_relight` | 3.08 | 2.97 | 10.27 | 9.83 |

Every gameplay counter in the same runs' `report.json` summaries is identical
between the two sides; the timing rows above are the only difference the
comparison found.

## PERF-1 measurement -- 20 Sep 2026 (`find_food_cell`)

Same pinned fixture, seed, machine and fixed-step setting as above:
`test_scenarios/recommendation_slice0_baseline.json` at `--fixed-fps 60`,
with 15 cells and 109 bees (85 nectar foragers and 24 miners). Both 480-frame
captures recorded `hive_find_food` at a total of 0.000 ms, or 0.00% of frame
time: the section did not run because the fixture produced no hungry indoor
bees in its measurement window. The two readings match exactly, so they meet
the 10% repeatability check, but they do not establish that the query is
trivial under its intended hungry-bee workload.

| Run | `hive_find_food` total ms | Share of frame time |
| --- | ---: | ---: |
| 1 | 0.000 | 0.00% |
| 2 | 0.000 | 0.00% |

This is worth a follow-up measurement slice, `PERF-2`: give a pinned scenario
a controlled hungry indoor population, then capture this same section before
considering the content-index rewrite. No query rewrite is justified by the
zero-call baseline.

## Recorded baseline -- 13 Sep 2026 (A3, C-50)

Run by Claude Code on Dave's Windows 11 development machine, headless, with
`--fixed-fps 60`, from the primary checkout at `2a64a8e`. 120 warm-up frames,
480 measured. Compare each row only with the same row of a later run.

| Row | mean ms | p95 ms |
| --- | --- | --- |
| `frame_time_ms` | 12.83 | 29.95 |
| `bee_state_miner` | 0.09 | 0.12 |
| `fog_of_war_update` | 2.81 | 19.51 |
| `fog_of_war_relight` | 2.68 | 19.34 |

Run it from the primary checkout, or from a worktree whose Godot import cache
has been primed: the same command stalled at its config line four times
inside a fresh A3 worktree.
