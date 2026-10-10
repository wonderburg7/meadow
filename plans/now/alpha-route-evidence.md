# Alpha Route Evidence -- measure the promised five gates without inventing player understanding

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: AR-4 -- a scripted Colony Run reaches and records all five gates | Dependency: AR-1 → AR-2 → AR-3; the playable end-to-end route remains gated on Tier 2, Bee Bread and Colony Run work | Verified: 2026-10-07

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
| AR-4 | a scripted Colony Run reaches and records all five gates | the alpha scenario and its new evidence test | no -- after Tier 2 automation, Bee Bread and the gyne route are playable | high |

AR-1 shipped 2026-10-07; its specification is `plans/archive/AR-1_2026-10-07.md`.

AR-2 shipped 2026-10-07; its specification is `plans/archive/AR-2_2026-10-07.md`.

AR-3 shipped 2026-10-07; its specification is `plans/archive/AR-3_2026-10-07.md`.

## Not in the queue, and why

```queue-gated
**[Codex] AR-4 -- a scripted Colony Run reaches and records all five gates**
- Plan: `plans/now/alpha-route-evidence.md` -- "AR-4 -- a scripted Colony Run reaches and records all five gates"
- Files: `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
- Check: `python -m unittest tests.test_pacing_gates` and the scripted Colony Run record all five product-scope gates
- Proof: `present: tools/pacing_gates.py :: Not instrumented: 20m forage/weather crisis; 90m gyne release.`
- Next after: None -- plan complete
```

AR-4 is gated on Tier 2 automation, Bee Bread and the gyne route; the gyne
route is `plans/now/pollination.md`, whose last slice, PP-6, opens AR-4. T2-7
(`plans/now/tier-two.md`, Claude lane) adds a `first_tier2_day` row to
`tools/pacing_gates.py`; AR-4 keeps that row when it is admitted. It cannot be
an honest acceptance scenario while those mechanics are still incomplete; the
first three slices make that absence visible instead of faking a successful run.
