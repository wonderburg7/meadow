# Pacing evidence — the headless gates can read in band

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: PE-1 -- pacing milestones are timed to the hour, startable, its block below; PE-2 (outline under "Later") waits for the Colony Run definition, BS-7 and WO-1 | Dependency: none | Verified: 2026-09-30

**Objective.** `python tools/pacing_gates.py` can say truthfully whether the
headless alpha arc meets each timing budget in `plans/design/product-scope.md`
§3, so a balance change can be judged against the 5/10/60/90-minute gates
without a playthrough.

**State.** `tools/pacing_gates.py` (FB-3, 24 Sep 2026) runs
`test_scenarios/alpha_arc_test.json` and compares four milestones from
`analyze_session.py::_milestones` with a +/-25% band around each target. Those
milestones are whole days taken from the last snapshot of each day
(`_last_snapshot_per_day`), so a gate whose band holds no whole day can never
read "in band": at the default 200 seconds a day the 5-minute gate's target is
day 1.5 and its band is days 1.125 to 1.875. The snapshots it needs are
already written -- the default cadence is one an in-game hour
(`diagnostic_log.gd::_snapshot_interval`, `seconds_per_day / 24`) and each
carries `game_time` -- the analysis throws the precision away.

**Measured 30 Sep 2026** (product review, `docs/product-review-2026-09-30.md`):
first worker missing (target day 1.5), food secure day 4.0 (target 3.0),
winter entered missing (18.0), winter survived missing (27.0). Precision is
the smaller problem. `alpha_arc_test.json` sets no starting colony and no
actions, so the run is a lone, unplayed queen who starves at game time 589 s
and the log idles to day 36; nothing but the debug panel starts winter (WO-1,
`plans/now/winter-onset.md`); and a colony with no bees reads food secure,
because its winter requirement is 0 (PE-1 fixes that below). PE-2, outlined
under "Later", makes the arc a played colony.

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| PE-1 | The pacing gates use each milestone's first hour, not its whole day | `tools/analyze_session.py`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`, `tests/test_headless_verdicts.py`, `docs/headless-run-contract.md` | yes (SF-2, which shared `analyze_session.py`, merged 30 Sep 2026) | medium |

**Required reading.** PE-1's section below only.

## PE-1 — pacing milestones are timed to the hour

Level: medium. Measurement only: no simulation, balance or save change, and
nothing per frame. Existing verdicts keep working because `milestones` keeps
its whole-day values.

**Change.**

- `analyze_session.py`: `analyze` adds `"milestone_times"`, a dictionary of
  the same four names as `milestones` (`first_worker_day`, `food_secure_day`,
  `winter_entered_day`, `winter_survived_day`) to the fractional in-game day
  of the **first** snapshot at which each became true:
  `game_time / settings.seconds_per_day`, walking every snapshot rather than
  the last one per day. `{}` when no snapshot carries `game_time` or the run
  recorded no positive `seconds_per_day`. The per-snapshot tests move into
  one helper that `_milestones` and the new walk both call, so the two cannot
  disagree about what a milestone means. Add the key to the `"balance"` and
  `"full"` entries of `REPORT_PROFILES`.
- That helper counts **food secure** and **winter survived** only when the
  snapshot's `population.total` is at least 1. Today a colony with no bees
  has a winter requirement of 0 (`_winter_food_requirement`), so the 30 Sep
  2026 run read food secure on day 4, after its queen had starved, and would
  read winter survived the same way. `milestones` changes only for a snapshot
  with no bees.
- Expect `milestone_times` to read up to a day earlier than `milestones`:
  `day` counts from 1 (the first day is day 1), `game_time / seconds_per_day`
  counts elapsed days from 0, and §3's budgets are elapsed time.
- `pacing_gates.py`: `build_rows` reads `milestone_times` instead of
  `milestones`; `render_table` prints the median day to two decimals. Its
  module docstring calls the forage/weather crisis "five-minute"; §3 puts it
  at twenty minutes, as `render_table`'s last line already says.
- `tests/test_pacing_gates.py`: a case where every run's first worker arrives
  at day 1.5 at 200 s/day reads in band, and one at day 2.0 reads out of band.
- `tests/test_headless_verdicts.py`: a case proving `milestone_times` takes
  the first qualifying snapshot inside a day, and that `milestones` is
  unchanged for the existing fixture; and a case where snapshots with
  `population.total` 0 set neither food secure nor winter survived.
- `docs/headless-run-contract.md`: one line naming `milestone_times`.

**Acceptance.** The unit tests above pass. Run
`python tools/pacing_gates.py --repeat 1` once and paste its table into this
plan's State line with the date, whatever it says: a gate out of band is
evidence for a later balance slice, not a failure of this one. No hands-on
check is filed.

```queue
**[Codex] PE-1 -- pacing milestones are timed to the hour**
- Plan: `plans/now/pacing-evidence.md` -- "PE-1 — pacing milestones are timed to the hour"
- Files: `tools/analyze_session.py`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`, `tests/test_headless_verdicts.py`, `docs/headless-run-contract.md`
- Check: `python -m unittest tests.test_pacing_gates tests.test_headless_verdicts` passes, including a first worker at day 1.5 reading in band at 200 s/day, `python tools/pacing_gates.py --repeat 1` prints a table with two-decimal median days, and `tools/verify.ps1` is green
- Proof: `absent: tools/analyze_session.py :: milestone_times`
- Next after: none -- plans/now/pacing-evidence.md is complete
```

## Later, not yet specified

- **The 10-minute gate measures a proxy.** `pacing_gates.py` times "food
  secure" against §3's "first useful automation", which a headless run with no
  player cannot perform. Replacing the proxy needs a decision on what counts as
  automation in a scripted run.
- **The 20-minute crisis and the 90-minute gyne release are not instrumented**
  (`render_table`'s last line). Each waits for its feature: a readiness-aware
  forage/weather crisis, and Gyne rearing (`plans/design/progression.md`
  Phase C step 15).
- **PE-2 -- the arc is a played colony.** Specified by the Colony Run
  definition pass, because the arc's start is the Colony Run's start
  (`plans/design/product-scope.md` §6.2, "Next design pass"). What it must
  settle is listed there, so it survives this plan being archived after PE-1.
  `plans/now/gameplay-consistency.md` GC-3 (honey stops creating energy)
  waits for this arc as its before-and-after evidence.
