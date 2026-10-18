# Hot-path cadence -- judgements on the think tick, as bee.gd already says they run

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None -- plan complete (HP-3 measured `bee_label_text` at 27% of `bee_label`, under the half bar, so no change; follow-up CQ-R4 is already filed in `plans/now/code-health.md`) | Dependency: HP-1, HP-2 and HP-3 landed 18 Oct | Verified: 2026-10-18

## Objective

`bee.gd`'s "how often a bee thinks" comment (above `THINKS_PER_SECOND`)
says the expensive judgements -- "searching the comb for work, picking a
flower" -- run 8 times a second while movement runs every frame. Two of
them still run every frame, and they are the two largest measured bee
costs. Bring them onto the think tick, then measure whether the per-frame
label refresh is worth the same.

## Current state

Verified 16 Oct 2026 against master `12c1393` by the performance review
(`docs/performance-review-2026-10-16.md`), headless, on Dave's machine:

- **Forager search.** `bee_foraging.gd::search_for_flower` calls
  `_perceive_flower` (two spatial-grid queries of 25 buckets each at the
  default 320 px radius) every frame for every SEARCHING forager. In the
  pinned fixture (`test_scenarios/recommendation_slice0_baseline.json`, 85
  nectar foragers, `--fixed-fps 60`) the `bee_search` section measured
  6.42 ms mean (p95 11.98) of a 16.78 ms frame: the largest single section.
- **Idle dispatch.** `bee.gd::_process`'s state `match` calls
  `_idle_dispatch()` every frame in `NURSE_IDLE`, `BUILD_IDLE` and
  `HONEY_IDLE`; `MINE_IDLE` alone waits for `_miner_dispatch_due`. With 500
  nurses in 100 cells, `bee_state_nurse` measured 5.14 ms; the review's
  temporary `if thinking:` gate on the three arms measured 2.27 ms (frame
  17.36 → 14.48 ms) with identical brief-report gameplay counters.
- **Label refresh.** `bee.gd::_process` runs `_update_label` and four ring
  updates every frame under `bee_label`: 2.22 ms at 500 bees, 4.55 ms at
  1,000. How much of that is `_update_label` is not yet measured.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |

HP-1 → HP-2 → HP-3 is lane order, not a code dependency; HP-2 and HP-3
share `bee.gd` and one fixture, so they run one after the other. A slice
reads its own section only. **Do not change** in any of them: `MINE_IDLE`'s
`_miner_dispatch_due` cadence, the think-tick jitter in `bee.gd::_process`,
or anything in `docs/performance.md` "Explicitly do not change".

HP-1 shipped 2026-10-17; its specification is `plans/archive/HP-1_2026-10-17.md`.

HP-2 shipped 2026-10-18; its specification is `plans/archive/HP-2_2026-10-18.md`.

**Code health (`plans/now/code-health.md`, 18 Oct 2026).** CQ-R4 splits `bee.gd::_process` into helpers and profiles it with `test_scenarios/hp2_idle_nurses_perf.json`; it runs after HP-3, so its before-profile includes HP-3's cadence.

HP-3 shipped 2026-10-18; its specification is `plans/archive/HP-3_2026-10-18.md`.
