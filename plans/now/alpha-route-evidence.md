# Alpha Route Evidence -- measure the promised five gates without inventing player understanding

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: AR-5 -- the first two gates on the calendar, and a reference queen who lays early (product review, 16 Oct 2026); then AR-4 -- a scripted Colony Run reaches and records all five gates | Dependency: AR-1 → AR-2 → AR-3; the playable end-to-end route remains gated on Tier 2 and Colony Run work (Bee Bread finished 11 Oct 2026) | Verified: 2026-10-16

## Objective

Make the 5/10/20/60/90-minute internal-alpha route report the facts the game
already records, while distinguishing an instrumented gameplay fact from a
claim about player comprehension. This plan changes diagnostic evidence only:
it never retunes the economy, changes a milestone condition, or makes an
unbuilt route look playable.

`plans/design/product-scope.md` §3 owns the five player outcomes. The current
`tools/pacing_gates.py` correctly says that the 20-minute forage/weather crisis
and 90-minute gyne release are not instrumented; its 10-minute `food secure`
proxy is not the promised first automation. Colony Run already records first
automation and first gyne in `colony_milestones.gd`, but selected scenario
snapshots do not expose that record to the analysis tools.

## Current state

The headless report can measure first worker, food security, winter entry and
winter survival from snapshots. A Colony Run separately persists the days of
first worker, first automation, stable income, winter readiness, winter
recovery, first gyne and victory. The two records are not connected, so no
deterministic report can yet say when the actual automation or gyne gates were
met. Readability of the crisis and a player's desire to continue remain
hands-on feedback questions, not diagnostics.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| AR-5 | the first two gates on the calendar, and a reference queen who lays early | `tools/pacing_gates.py`, `tests/test_pacing_gates.py`, `test_scenarios/alpha_arc_test.json` | yes | medium |
| AR-4 | a scripted Colony Run reaches and records all five gates | the alpha scenario and its new evidence test | no -- after Tier 2 automation and the gyne route are playable (Bee Bread finished 11 Oct 2026) | high |

AR-1, AR-2 and AR-3 shipped 7 Oct 2026; each has its record in `plans/archive/`, named by id and date.

## Not in the queue, and why

AR-4 is gated on Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026); the gyne
route is `plans/now/pollination.md`, whose last slice, PP-6, opens AR-4. T2-7
(`plans/now/tier-two.md`, landed 11 Oct 2026) added a `first_tier2_day` row to
`tools/pacing_gates.py`; AR-4 keeps that row when it is admitted. AR-4's arc
buying a Honey worker opens T2-7b, the tier-2 price sweep T2-7 deferred. It cannot be
an honest acceptance scenario while those mechanics are still incomplete; the
first three slices make that absence visible instead of faking a successful run.

## AR-5 -- the first two gates on the calendar, and a reference queen who lays early

<!-- LAYER: design -->

Level: medium. From the product review of 16 Oct 2026
(its findings F3 and F4).

Decision (Dave, 16 Oct 2026, product review D2): **the 5- and 10-minute
gates are judged on the run's calendar, as the 60- and 90-minute gates are.**
The first worker passes when the median `first_worker_day` is at most 3.0;
first automation passes when the median `first_automation_day` is from 5.0
to 8.0 inclusive (Dave set the first tier-2 purchase at about day 5, and
Automation needs Comb worker and Miner, both tier 2). Both days are on the
scale `pacing_gates.py` already prints in its "1st worker" column. The
minute-converted targets are still printed, for information only, as AR-4
does for the 90-minute gate. `plans/design/product-scope.md` §3 holds the
decision.

**True now** (product review run, 16 Oct 2026, seeds 20260923-25): `python
tools/pacing_gates.py` reports the first worker at a median of day 16.87
(16.87, 22.32, 16.87) against a target of day 1.50; seed 20260923's colony
died and the other two reached winter with 5 and 6 bees.
`test_scenarios/alpha_arc_test.json`'s queen builds and forages until its
`day_at_least: 17` action sets her to `laying`, so the reference player
raises nothing for sixteen days. `tools/pacing_gates.py::GATES` judges the
first two gates with `in_band` against `target_day(5|10, ...)`;
`tests/test_pacing_gates.py::test_first_worker_at_two_elapsed_days_is_outside_the_five_minute_band`
asserts the old reading.

**After:**

1. `tools/pacing_gates.py` gains `FIRST_WORKER_BY_DAY = 3.0` and
   `FIRST_AUTOMATION_DAYS = (5.0, 8.0)`, and `build_rows` judges the
   "first worker" and "first automation" rows against them; `target_day`
   still prints the minute-converted figure in the row. The crisis, winter
   and gyne/victory rows are unchanged.
2. `tests/test_pacing_gates.py`: the two-elapsed-days test now expects "in
   band"; new tests put a first worker at 3.5 out of band, and first
   automation at 4.9 and 8.1 out of band and at 5.0 and 8.0 in band.
3. `alpha_arc_test.json`'s opening (every action before its first `day_at_least: 5`
   action) is replaced by: queen to `comb_worker`; `queue_build` at
   `[0, 0]`, then `[1, 0]` and `[0, 1]` with `"append": true`; when
   `cells_completed_at_least: 3`, queen to `forager_pollen`; when
   `{"hive_total": {"resource": "pollen", "at_least": 70}}`, queen to
   `forager_nectar`; when both that and `{"hive_total": {"resource":
   "nectar", "at_least": 20}}` hold (`all_of`), queen to `laying`. In the
   actions that follow, every one that sets the queen to `forager_nectar`
   or `forager_pollen` sets her to `laying` instead, so after her first lay
   she leaves laying only to build. Nothing else in the file changes: no
   `config_overrides`, no seed, no stop rule.

**Invariants.** No `GameConfig` or `skills.gd` value changes (balance is
PP-6's and T2-7b's). The winter rows' schedule logic and AR-4's gyne rule are
untouched. The scenario still runs as a Colony Run (`"run_type": "colony"`).

**Check.** `python -m unittest tests.test_pacing_gates` passes, then
`python tools/pacing_gates.py` once: record its table in this section. Expected:
the first worker's median is at most day 3.0 and at least as many seeds'
colonies live through winter as on 16 Oct (two of three).

**Stop and escalate** with the table, changing nothing further, if the
median first worker is still after day 3.0 or fewer colonies live: the
economy (60 pollen an egg, `egg_pollen_cost`) or the gate then needs Dave,
not a different script.

```queue
**[Codex] AR-5 -- the first two gates on the calendar, and a reference queen who lays early**
- Plan: `plans/now/alpha-route-evidence.md` -- "AR-5 -- the first two gates on the calendar, and a reference queen who lays early"
- Files: `tools/pacing_gates.py`, `tests/test_pacing_gates.py`, `test_scenarios/alpha_arc_test.json`, `plans/now/alpha-route-evidence.md`
- Check: `python -m unittest tests.test_pacing_gates` passes; `python tools/pacing_gates.py` judges the first worker by day 3.0 and first automation on days 5.0 to 8.0, its first-worker median is at most day 3.0 with at least two of three colonies living through winter, and the table is recorded in this section
- Proof: `absent: tools/pacing_gates.py :: FIRST_WORKER_BY_DAY`
- Next after: PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter
```

## AR-4 -- a scripted Colony Run reaches and records all five gates

<!-- LAYER: design -->

Its gated block is at the end of this section. Decision (Dave, 14 Oct 2026): **the 90-minute
gyne/victory gate is judged on the run's calendar, not on minutes.** It
passes when the run's first counted gyne -- one sent inside the mating
window, so `first_gyne_day` -- leaves inside the second summer's mating
window (`season.gd`'s `MATING_WINDOW_START` to `MATING_WINDOW_END` of the
season after the first winter, about days 47 to 65 on today's calendar).
`pacing_gates.py` reads that window from the run's logged settings, as
`winter_schedule` already does for the 60-minute gate; the target worked
out from minutes and day length is still printed, for information only. Today's
conversion puts 90 minutes at day 27, before the first winter ends, so the
gate could never pass. PP-6 (`plans/now/pollination.md`) sets the day Gyne
rearing becomes affordable to the first 11 days after winter, which leaves
this window reachable.

```queue-gated
**[Codex] AR-4 -- a scripted Colony Run reaches and records all five gates**
- Plan: `plans/now/alpha-route-evidence.md` -- "AR-4 -- a scripted Colony Run reaches and records all five gates"
- Files: `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
- Check: `python -m unittest tests.test_pacing_gates` and the scripted Colony Run record all five product-scope gates
- Proof: `present: tools/pacing_gates.py :: Not instrumented: 20m forage/weather crisis; 90m gyne release.`
- Next after: None -- plan complete
```

