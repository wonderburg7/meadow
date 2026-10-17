# Hot-path cadence -- judgements on the think tick, as bee.gd already says they run

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HP-1 -- a searching forager looks for flowers on her think tick | Dependency: HP-1 → HP-2 → HP-3 in lane order, all startable; HP-1 re-runs FR-1's table if FR-1 has landed (`plans/now/forager-recruitment.md`) | Verified: 2026-10-16

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
| HP-1 | a searching forager looks for flowers on her think tick | `scripts/bee_foraging.gd`, `test_scenarios/hp1_forager_search_perf.json`, `docs/PERFORMANCE_BASELINE.md` | yes | medium |
| HP-2 | idle nurses, comb workers and honey makers look for work on the think tick | `scripts/bee.gd`, `test_scenarios/hp2_idle_nurses_perf.json`, `docs/PERFORMANCE_BASELINE.md` | yes | medium |
| HP-3 | the bee label refreshes on the think tick, if it measures worth it | `scripts/bee.gd`, `test_scenarios/hp2_idle_nurses_perf.json`, `docs/PERFORMANCE_BASELINE.md` | yes | low |

HP-1 → HP-2 → HP-3 is lane order, not a code dependency; HP-2 and HP-3
share `bee.gd` and one fixture, so they run one after the other. A slice
reads its own section only. **Do not change** in any of them: `MINE_IDLE`'s
`_miner_dispatch_due` cadence, the think-tick jitter in `bee.gd::_process`,
or anything in `docs/performance.md` "Explicitly do not change".

## HP-1 -- a searching forager looks for flowers on her think tick

**True now.** `bee_foraging.gd::search_for_flower` calls
`_perceive_flower(bee)` on every frame of SEARCHING, before the spiral and
the movement. A searching bee has by definition found nothing, so most
calls run both the strict and the relaxed grid pass.

**True afterwards.** Only that perception block is gated:

```gdscript
	if bee.thinking:
		var best := _perceive_flower(bee)
		if best != null:
			_commit_to_flower(bee, best)
			return
```

and the later `best = nearest_flower(...)` line in the give-up branch
declares its own `var best`. The indoors walk-out, the grounded check, the
spiral radius and give-up branch, and `BeeMovement.move_towards` stay
per-frame. The function's doc comment says she re-checks "on each think
tick (`bee.gd::THINKS_PER_SECOND`, 8 a second)" instead of "each frame".
`bee.thinking` is set at the top of `bee.gd::_process` before the state
`match`, so it is current here. At `GameConfig.bee_speed` 110 px/s a bee
moves about 14 px between ticks against a 320 px perception radius.

**Invariants.** `seek_flower`, `nearest_flower`, the grid and every accept
rule are unchanged. No random call is added. Expected and accepted:
`tarsal_rejections` (counted per perception call) falls when tarsal markers
are on, and with weighted choice on the random sequence shifts, so a
single run no longer matches master trajectory for trajectory.

**Check, in this order.** (1) Before editing, create
`test_scenarios/hp1_forager_search_perf.json` as a copy of
`recommendation_slice0_baseline.json` whose `sections` are
`frame_time_ms`, `bee_state_forager`, `bee_search`, and run it twice with
`--fixed-fps 60 --report brief`; after the edit run it twice more.
`bee_search` mean must fall by at least half; record the four rows in a new
`docs/PERFORMANCE_BASELINE.md` section "HP-1 measurement". (2) Run
`python tools/run_scenario.py test_scenarios/foraging_features_off_seed12345_test.json --seeds 12345,2026,555 --report brief`
before and after: the three-seed mean of `forager_deliveries` and of
`flower_visits` each stays within 10% of before; record them too.
(3) If FR-1 has landed (its table is in `plans/now/forager-recruitment.md`'s
FR-1 section or its archive), run `python tools/forager_stages.py`: the
stage order must be unchanged. (4) `.\tools\verify.ps1` is green. Discard a
run whose output says `godot cache: seeded from the primary`, and rerun.

**Escalate** if `search_for_flower` is called from anywhere but the
SEARCHING arm of `bee.gd::_process`, if step 1 falls short, or if step 2
or 3 moves outside its bound.

```queue
**[Claude] HP-1 -- a searching forager looks for flowers on her think tick**
- Plan: `plans/now/hot-path-cadence.md` -- "HP-1 -- a searching forager looks for flowers on her think tick"
- Files: `scripts/bee_foraging.gd`, `test_scenarios/hp1_forager_search_perf.json`, `docs/PERFORMANCE_BASELINE.md`, `plans/now/hot-path-cadence.md`
- Check: `bee_search` mean in `test_scenarios/hp1_forager_search_perf.json` (`--fixed-fps 60`, two runs each side) falls by at least half; the three-seed means of `forager_deliveries` and `flower_visits` in `foraging_features_off_seed12345_test.json` (`--seeds 12345,2026,555`) stay within 10% of before; both recorded in `docs/PERFORMANCE_BASELINE.md`; FR-1's stage order unchanged if FR-1 has landed; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/bee_foraging.gd :: bee.thinking`
- Next after: HP-2 -- idle nurses, comb workers and honey makers look for work on the think tick
```

## HP-2 -- idle nurses, comb workers and honey makers look for work on the think tick

**True now.** In `bee.gd::_process`'s state `match`, the `NURSE_IDLE`,
`BUILD_IDLE` and `HONEY_IDLE` arms each call `_idle_dispatch()` every
frame. `_idle_dispatch`'s doc comment opens "Called every frame a bee is
sitting in one of the three "waiting for work" states" and lists three
states where there are four.

**True afterwards.** Each of those three arms calls `_idle_dispatch()`
only `if thinking:`, the shape `MINE_IDLE` already has with
`_miner_dispatch_due`. The doc comment says it is called on the think tick
in `NURSE_IDLE`, `BUILD_IDLE` and `HONEY_IDLE`, and on the miner dispatch
tick in `MINE_IDLE`. A bee that reaches an idle state notices work within
one tick (at most about 145 ms with the jitter), the contract miners
already have (`docs/PERFORMANCE_BASELINE.md`, "Invalidation contracts").

**Invariants.** `MINE_IDLE`, `_idle_dispatch`'s body, `_try_role_work`
and the think-tick block above the `match` are unchanged. No random call is
added or removed. Save format unchanged.

**Check, in this order.** (1) Before editing, create
`test_scenarios/hp2_idle_nurses_perf.json` as a copy of
`spr2_render_500.json` whose `sections` are `frame_time_ms`, `bees`,
`bee_state_nurse`, `bee_label`; run it twice with `--report brief`, then
twice after. `bee_state_nurse` mean must fall by at least 40%; record the
rows in a new `docs/PERFORMANCE_BASELINE.md` section "HP-2 measurement".
(2) Each of `bs3_nurse_gate_test.json`, `bs4_honey_gate_test.json`,
`c6_nurse_feed_test.json` and `h3_restock_delivery_test.json` in
`test_scenarios/` exits 0 with a pass verdict under
`python tools/run_scenario.py <file>`. (3) `.\tools\verify.ps1` is green.
Discard a run whose output says `godot cache: seeded from the primary`.

**Escalate** if any of the four scenarios that passed before the edit fails
after it, or if a slice has since given `_idle_dispatch` a caller outside
the four idle arms.

```queue
**[Claude] HP-2 -- idle nurses, comb workers and honey makers look for work on the think tick**
- Plan: `plans/now/hot-path-cadence.md` -- "HP-2 -- idle nurses, comb workers and honey makers look for work on the think tick"
- Files: `scripts/bee.gd`, `test_scenarios/hp2_idle_nurses_perf.json`, `docs/PERFORMANCE_BASELINE.md`, `plans/now/hot-path-cadence.md`
- Check: `bee_state_nurse` mean in `test_scenarios/hp2_idle_nurses_perf.json` (two runs each side) falls by at least 40% and is recorded in `docs/PERFORMANCE_BASELINE.md`; `bs3_nurse_gate_test.json`, `bs4_honey_gate_test.json`, `c6_nurse_feed_test.json` and `h3_restock_delivery_test.json` each pass under `python tools/run_scenario.py`; `.\tools\verify.ps1` is green
- Proof: `present: scripts/bee.gd :: ## Called every frame a bee is sitting in one of the three "waiting for`
- Next after: HP-3 -- the bee label refreshes on the think tick, if it measures worth it
```

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
