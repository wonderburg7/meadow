# Alpha Route Evidence -- measure the promised five gates without inventing player understanding

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: AR-2 -- analysis turns that record into named alpha-gate facts | Dependency: AR-1 → AR-2 → AR-3; the playable end-to-end route remains gated on Tier 2, Bee Bread and Colony Run work | Verified: 2026-10-07

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
| AR-2 | analysis turns that record into named alpha-gate facts | `tools/analyze_session.py`, `tests/test_headless_verdicts.py` | after AR-1 | medium |
| AR-3 | the pacing report presents every alpha gate and its evidence boundary | `tools/pacing_gates.py`, `tests/test_pacing_gates.py` | after AR-2 | low |
| AR-4 | a scripted Colony Run reaches and records all five gates | the alpha scenario and its new evidence test | no -- after Tier 2 automation, Bee Bread and the gyne route are playable | high |

AR-1 shipped 2026-10-07; its specification is `plans/archive/AR-1_2026-10-07.md`.

## AR-2 -- analysis turns that record into named alpha-gate facts

<!-- LAYER: immediate-task -->

Level: medium (pure analysis of AR-1's snapshots, with fixture coverage).

**True now.** `analyze_session.py` derives pacing milestones only from
population, stores and winter snapshots. It cannot report first automation or
first gyne from the Colony Run record.

**True afterwards.** Analysis exposes first-worker, first-automation,
first-gyne and victory days from the copied record as named alpha facts. It
uses the record's integer day rather than fabricating sub-day precision, omits
absent facts, and preserves the existing food-security and winter calculations.
The fixture test covers a record arriving after prior snapshots and a missing
record.

**Must not change.** Existing `milestones`/`milestone_times` meanings, food
security, winter survival, or report profiles. The new facts are a separate
alpha-route record until AR-3 consumes them.

```queue
**[Codex] AR-2 -- analysis turns that record into named alpha-gate facts**
- Plan: `plans/now/alpha-route-evidence.md` -- "AR-2 -- analysis turns that record into named alpha-gate facts"
- Files: `tools/analyze_session.py`, `tests/test_headless_verdicts.py`
- Check: `python -m unittest tests.test_headless_verdicts` passes with a copied milestone record reporting first automation and first gyne by recorded day, and without changing existing pacing milestones
- Proof: `absent: tools/analyze_session.py :: alpha_route`
- Next after: AR-3 -- the pacing report presents every alpha gate and its evidence boundary
```

## AR-3 -- the pacing report presents every alpha gate and its evidence boundary

<!-- LAYER: immediate-task -->

Level: low (report wording and pure-Python table tests).

**True now.** `pacing_gates.py` labels food security as the 10-minute gate and
ends with one undifferentiated “Not instrumented” line for crisis and gyne
release.

**True afterwards.** Its table has one row for each product-scope gate: first
worker, first automation, crisis response, winter survival and gyne/victory.
Each row identifies whether the result is a measured fact, unavailable because
the scripted route has not reached it, or a hands-on question. First automation
and gyne/victory consume AR-2's recorded facts; food security stays in the
diagnostic detail but is no longer presented as the automation outcome. The
tests prove missing facts remain visibly missing.

**Must not change.** Target timing bands, season schedule derivation, scenario
execution, or balance. A diagnostic scorecard is not permission to claim the
route is playable.

```queue
**[Codex] AR-3 -- the pacing report presents every alpha gate and its evidence boundary**
- Plan: `plans/now/alpha-route-evidence.md` -- "AR-3 -- the pacing report presents every alpha gate and its evidence boundary"
- Files: `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
- Check: `python -m unittest tests.test_pacing_gates` passes with five named alpha-gate rows, and missing crisis or gyne facts render as unavailable rather than in-band
- Proof: `present: tools/pacing_gates.py :: Not instrumented: 20m forage/weather crisis; 90m gyne release.`
- Next after: AR-4 -- a scripted Colony Run reaches and records all five gates
```

## Not in the queue, and why

- **AR-4 -- a scripted Colony Run reaches and records all five gates** is gated on Tier 2 automation, Bee Bread and the gyne route. It cannot be an honest acceptance scenario while those mechanics are still incomplete; the first three slices make that absence visible instead of faking a successful run.
