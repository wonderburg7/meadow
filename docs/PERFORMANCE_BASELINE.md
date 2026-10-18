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

## PERF-2 measurement -- 28 Sep 2026 (`find_food_cell`)

`test_scenarios/perf2_hungry_indoor.json`, seed `20260927`, uses 100 indoor
nurses and 60 built, empty cells. It sets `hunger_threshold` to `1.0`, so the
full hungry population tries the query on its think ticks, while the empty
comb makes every call complete both passes and return `null`. Fog is excluded.
Each run used the runner's default fixed 30 FPS setting, after 120 warm-up
frames and across 480 measured frames.

| Run | `hive_find_food` mean ms | `hive_find_food` p95 ms | `frame_time_ms` mean ms | Share of frame time |
| --- | ---: | ---: | ---: | ---: |
| 1 | 2.175 | 3.604 | 18.103 | 12.01% |
| 2 | 0.821 | 1.076 | 5.575 | 14.73% |
| 3 | 2.083 | 3.621 | 17.884 | 11.65% |

The first two captures differed by more than 10%, so the third is recorded
rather than discarded; runs 1 and 3 agree within 5%. The section is non-zero
in every run and consumes well above the 2% decision threshold. **PERF-3 is
worth specifying:** preserve `find_food_cell`'s preference order while making
it read the existing ripe-honey and nectar content buckets.

## PERF-3 measurement -- 29 Sep 2026 (`find_food_cell` content index)

The same pinned hungry-indoor fixture, seed, default fixed 30 FPS setting,
warm-up and 480-frame window as PERF-2 ran twice after `find_food_cell` began
reading the existing `ripe_honey` then `nectar` content buckets. Both captures
completed the fixture with the same gameplay counters as PERF-2 (including no
deliveries, brood feeds, deaths, or cell changes). `hive_find_food` remains
non-zero while falling about 94% below PERF-2's comparable runs 1 and 3.

| Run | `hive_find_food` mean ms | `hive_find_food` p95 ms | `frame_time_ms` mean ms | Share of frame time |
| --- | ---: | ---: | ---: | ---: |
| 1 | 0.118 | 0.200 | 16.310 | 0.73% |
| 2 | 0.118 | 0.201 | 16.142 | 0.73% |

The readings agree within 1%; the rewrite therefore preserves the fixture's
outcome and removes a measured hot-path cost without changing the selected
cell's ordering.

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

## Performance review re-measure -- 16 Oct 2026

The pinned fixture at `--fixed-fps 60`, master `12c1393`, same machine,
headless, from the review's worktree. Runs 2 and 3 used scratch copies of
the fixture that only list more sections; the fixture is otherwise
identical. Run 1 seeded the worktree's Godot cache and is shown only to
say why it is discarded (`docs/performance.md`, "Repeatability").

| Row | run 1 (discarded) mean / p95 | run 2 mean / p95 | run 3 mean / p95 |
| --- | --- | --- | --- |
| `frame_time_ms` | 27.20 / 66.33 | 15.43 / 36.06 | 16.78 / 38.34 |
| `bee_state_miner` | 0.137 / 0.318 | 0.090 / 0.140 | 0.098 / 0.176 |
| `fog_of_war_update` | 5.81 / 26.01 | 3.14 / 24.93 | 3.33 / 25.82 |
| `fog_of_war_relight` | 5.61 / 25.82 | 3.01 / 24.70 | 3.19 / 25.61 |

Against the 13 Sep row below, the miner row is unchanged and fog's mean is
within 20% (its p95 is higher); "measured, not a bottleneck" still holds
for fog. The frame is dominated by a section the pinned table does not
carry: in run 3 `bee_state_forager` was 7.07 ms, of which `bee_search`
(SEARCHING's per-frame flower check) was 6.42 ms. HP-1
(`plans/now/hot-path-cadence.md`) moves that check onto the think tick.

## HP-1 measurement

`test_scenarios/hp1_forager_search_perf.json`, `--fixed-fps 60`, same machine,
headless, from the HP-1 worktree. Each side's first run seeded or re-imported
the Godot cache and is discarded (`docs/performance.md`, "Repeatability");
the table shows the two kept runs per side, mean / p95 in ms.

| Row | before run 2 | before run 3 | after run 2 | after run 3 |
| --- | --- | --- | --- | --- |
| `frame_time_ms` | 13.78 / 31.19 | 13.64 / 32.55 | 9.67 / 26.19 | 9.43 / 26.38 |
| `bee_state_forager` | 5.66 / 7.93 | 5.67 / 7.92 | 1.84 / 2.69 | 1.80 / 2.62 |
| `bee_search` | 5.13 / 7.42 | 5.14 / 7.38 | 1.33 / 2.13 | 1.29 / 2.12 |

`bee_search` mean falls from about 5.13 ms to about 1.31 ms (-74%), against a
bound of at least half.

Behaviour guard: `foraging_features_off_seed12345_test.json --seeds
12345,2026,555`, three-seed means of the final `forager_deliveries` and
`flower_visits`, before and after:

| Counter | before (per seed; mean) | after (per seed; mean) |
| --- | --- | --- |
| `forager_deliveries` | 52, 40, 36; 42.67 | 52, 40, 36; 42.67 |
| `flower_visits` | 188, 179, 187; 184.67 | 188, 179, 187; 184.67 |

Identical, as that scenario's foragers do not reach SEARCHING in a way the
tick gate changes. `python tools/forager_stages.py` gives the same table
before and after (stage order and ratios 0.97x, 0.82x, 0.69x unchanged).

## HP-2 measurement

`test_scenarios/hp2_idle_nurses_perf.json` (500 nurses, a copy of
`spr2_render_500.json` with sections `frame_time_ms`, `bees`,
`bee_state_nurse`, `bee_label`), `--fixed-fps 60`, same machine, headless,
from the HP-2 worktree. Each side's first run is discarded (the first after
the edit re-imported the cache); the table shows the two kept runs per side,
mean / p95 in ms.

| Row | before run 2 | before run 3 | after run 2 | after run 3 |
| --- | --- | --- | --- | --- |
| `frame_time_ms` | 107.50 / 117.40 | 98.43 / 106.26 | 76.15 / 83.69 | 76.93 / 84.20 |
| `bees` | 85.17 / 93.80 | 77.75 / 84.59 | 55.75 / 61.74 | 56.28 / 62.27 |
| `bee_state_nurse` | 32.76 / 36.55 | 29.53 / 32.40 | 9.72 / 11.03 | 9.68 / 11.16 |
| `bee_label` | 13.12 / 14.83 | 12.02 / 13.07 | 11.62 / 13.06 | 11.73 / 13.05 |

`bee_state_nurse` mean falls from about 31.1 ms to about 9.7 ms (-69%),
against a bound of at least 40%. The absolute frame times are large because
the headless 500-nurse fixture is dense; the ratio is what carries.

Behaviour guard: `bs3_nurse_gate_test.json`, `c6_nurse_feed_test.json` and
`h3_restock_delivery_test.json` pass after the edit.
`bs4_honey_gate_test.json` fails identically before and after (its last
`buy_skill` for `skill.colony.comb_worker` is rejected `block.already_owned`)
so the edit did not change it.

## HP-3 measurement

`test_scenarios/hp2_idle_nurses_perf.json` with `bee_label_text` added to its
sections (a nested span around `_update_label()` in `bee.gd::_process`),
`--fixed-fps 60`, headless, same machine, from the HP-3 worktree. The first
run (after the edit re-imported the cache) is discarded; mean / p95 in ms.

| Row | run 2 | run 3 |
| --- | --- | --- |
| `bee_label` | 8.21 / 11.76 | 8.84 / 11.41 |
| `bee_label_text` | 2.26 / 3.31 | 2.43 / 3.21 |

`bee_label_text` is 27.5% and 27.4% of `bee_label`, under the half the plan
requires. Measured, not worth changing: `_update_label` stays per-frame and
the span stays in `bee.gd` as a permanent measurement point.
