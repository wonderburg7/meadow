# Alpha Route Evidence -- measure the promised five gates without inventing player understanding

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: AR-4 -- a scripted Colony Run reaches and records all five gates; it waits for PP-10 (`plans/now/pollination.md`), which prices the gyne route after EV-0 re-sets the calendar (AR-5 shipped 21 Oct 2026) | Dependency: AR-1 → AR-2 → AR-3 → AR-5 built; AR-4 follows PN-11 → EV-0 → PP-10; AR-6 shipped 5 Nov 2026 | Verified: 2026-11-05

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
| AR-4 | a scripted Colony Run reaches and records all five gates | the alpha scenario and its new evidence test | no -- after PP-10 (`plans/now/pollination.md`) | high |

AR-1, AR-2 and AR-3 shipped 7 Oct 2026; each has its record in `plans/archive/`, named by id and date.

## Not in the queue, and why

AR-4 is gated on PP-10 (`plans/now/pollination.md`), the gyne route's last
slice, which checks the route's order on EV-0's calendar. T2-7
(`plans/archive/tier-two_2026-11-05.md`, landed 11 Oct 2026) added a `first_tier2_day` row to
`tools/pacing_gates.py`; AR-4 keeps that row when it is admitted. T2-7b, the
tier-2 price sweep T2-7 deferred, was withdrawn (Dave, 5 Nov 2026, product review D5). AR-4 cannot be
an honest acceptance scenario while those mechanics are still incomplete; the
first three slices make that absence visible instead of faking a successful run.

AR-5 shipped 2026-10-21; its specification is `plans/archive/AR-5_2026-10-21.md`.

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
gate could never pass. PP-10 (`plans/now/pollination.md`) sets the day Gyne
rearing becomes affordable to the first 11 days after winter, which leaves
this window reachable.

Decisions (Dave, 5 Nov 2026, product review D2 and D3): AR-4 records the
first crisis on the calendar -- the day its warning shows and the day the
rain starts -- and reports whether the five outcomes keep the order of
`plans/design/product-scope.md` §3's table (D5: the order, not the day; the
crisis's draft days are 12 to 15 after PN-11), replacing the crisis's
"hands-on question" row. Drones and hard soil are alpha content: AR-4's
reference run marks drone cells as a player would and its evidence table
records the drones raised and the hard blocks dug, so their cost to the
five gates is visible. Its section is rewritten when PP-10 lands.

```queue-gated
**[Codex] AR-4 -- a scripted Colony Run reaches and records all five gates**
- Plan: `plans/now/alpha-route-evidence.md` -- "AR-4 -- a scripted Colony Run reaches and records all five gates"
- Files: `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`, `plans/design/product-scope.md`
- Check: `python -m unittest tests.test_pacing_gates` and the scripted Colony Run record all five product-scope gates; `pacing_gates.py` also prints the median of each seed's peak population, and twice that figure replaces the provisional 500 bees in `plans/design/product-scope.md` §6.1's frame-budget line (Dave, 16 Oct 2026)
- Proof: `present: tools/pacing_gates.py :: Not instrumented: 20m forage/weather crisis; 90m gyne release.`
- Next after: None -- plan complete
```

AR-6 shipped 2026-11-05; its specification is `plans/archive/AR-6_2026-11-05.md`.
