# Hot-path cadence -- judgements on the think tick, as bee.gd already says they run

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HP-3 -- the bee label refreshes on the think tick, if it measures worth it | Dependency: HP-1 and HP-2 landed 18 Oct; HP-3 startable; HP-1 re-runs FR-1's table if FR-1 has landed (`plans/now/forager-recruitment.md`) | Verified: 2026-10-16

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
| HP-3 | the bee label refreshes on the think tick, if it measures worth it | `scripts/bee.gd`, `test_scenarios/hp2_idle_nurses_perf.json`, `docs/PERFORMANCE_BASELINE.md` | yes | low |

HP-1 → HP-2 → HP-3 is lane order, not a code dependency; HP-2 and HP-3
share `bee.gd` and one fixture, so they run one after the other. A slice
reads its own section only. **Do not change** in any of them: `MINE_IDLE`'s
`_miner_dispatch_due` cadence, the think-tick jitter in `bee.gd::_process`,
or anything in `docs/performance.md` "Explicitly do not change".

HP-1 shipped 2026-10-17; its specification is `plans/archive/HP-1_2026-10-17.md`.

HP-2 shipped 2026-10-18; its specification is `plans/archive/HP-2_2026-10-18.md`.

## HP-3 -- the bee label refreshes on the think tick, if it measures worth it

**True now.** `bee.gd::_process` calls `_update_label()` every frame under
`Perf.begin("bee_label")`, beside four ring and marker updates.
`_update_label` formats the label text and recomputes the body colour each
frame for every on-screen bee; its share of `bee_label` is unmeasured.

**Step 1, always.** If `test_scenarios/hp2_idle_nurses_perf.json` does not
exist yet, create it as HP-2's check step 1 describes. Wrap the
`_update_label()` call in its own nested `Perf.begin("bee_label_text")` /
`Perf.end("bee_label_text")`, add `bee_label_text` to the fixture's
`sections`, and run it twice with `--report brief`. If `bee_label_text` is
under half of `bee_label`, stop: record the two runs in
`docs/PERFORMANCE_BASELINE.md` section "HP-3 measurement", keep the new
section, and close the slice as measured, not worth changing.

**Step 2, only if it is at least half.** Call `_update_label()` only
`if thinking:`. The four ring and marker updates stay per-frame (the search
and dance rings pulse). Label text, its visibility and the energy
darkening then lag by at most one think tick. Run the fixture twice more:
`bee_label` mean must fall by at least a third; record all four runs.

**Invariants.** Presentation only: nothing in the simulation reads the
label or the body colour. No random call added. A bee's per-frame
`body.color` write stays as it is apart from the cadence: the review
measured an unchanged-colour guard and it bought nothing.

```queue
**[Claude] HP-3 -- the bee label refreshes on the think tick, if it measures worth it**
- Plan: `plans/now/hot-path-cadence.md` -- "HP-3 -- the bee label refreshes on the think tick, if it measures worth it"
- Files: `scripts/bee.gd`, `test_scenarios/hp2_idle_nurses_perf.json`, `docs/PERFORMANCE_BASELINE.md`, `plans/now/hot-path-cadence.md`
- Check: `bee_label_text` is measured in `test_scenarios/hp2_idle_nurses_perf.json` and recorded in `docs/PERFORMANCE_BASELINE.md`; if it is at least half of `bee_label`, `_update_label` runs only on the think tick and `bee_label` mean falls by at least a third; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/bee.gd :: bee_label_text`
- Next after: none -- hot-path-cadence is complete
```
