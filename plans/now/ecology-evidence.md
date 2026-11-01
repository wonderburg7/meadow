# Ecology evidence -- what pollination changes in the meadow

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: EE-2 -- carryover into spring; EE-1 summer measurements complete | Dependency: EE-2 follows EE-1; no simulation or balance changes | Verified: 2026-10-31

## Objective

Measure the existing seed-set behaviour before proposing deeper ecology.
Dave selected new evidence work when the Codex lane ran short, 31 Oct 2026.
This takes the evidence pass from `DESIGN_BACKLOG.md`, "Future ecology";
it does not admit any new ecology mechanic or change the alpha route.

The immediate question is how much the meadow changes when seed-set
replacement is enabled, first within a summer and then after winter.
Report the measured differences, including small or mixed results. There
is no target effect size and no balance change in either slice.

## Current state

Verified against master `6797cc8`, 31 Oct 2026:

- `tests/test_pp4_seed_set.py` proves seed eligibility, nearby replacement,
  the seasonal fallback, spring weighting and save/restore. It uses seed
  6104 and a shortened on/off control; it is not a paired multi-seed report.
- `test_scenarios/pp4_seed_set.json` already supplies a specialist Clover
  workforce, accelerated seasons and the `pollination_log` switch.
- `scripts/pollination.gd` owns the seed ledger. Its scenario-only
  `pollination_withered`, `pollination_replant` and `pollination_spring`
  actions expose the required evidence. Existing saves expose species
  counts and the seed bank. No new runtime instrumentation is needed.
- `tools/run_scenario.py` owns isolated headless launches and session
  artefacts; `tools/analyze_session.py` reads the logs. Extend neither.
  The new reporter owns only this question's offline aggregation, using
  those existing helpers rather than a second runner or log reader.

The live pollination plan owns the gyne route and pricing. This campaign
is separate because it produces measurements from already shipped seed
set, owns no game files, and can close independently of that route.
`plans/design/product-scope.md`, section 10, remains the product contract.
Offspring quality and stewardship mechanics remain deferred.

## Open slices

| Slice | What it does | Files it owns | Level |
| --- | --- | --- | --- |
| EE-2 | Extend the comparison through winter into spring | `tools/seed_set_evidence.py`, `test_scenarios/ee2_seed_set_spring.json`, `tests/test_seed_set_evidence.py`, `plans/reference/seed-set-evidence.md` | medium |

EE-1 shipped 2026-10-31; its specification is `plans/archive/EE-1_2026-10-31.md`.

## EE-2 -- measure seed-set carryover into spring

Level: medium -- extend the measured summer comparison through one winter.

**True now.** PP-4 proves the spring weighting rule on seed 6104. EE-1
adds paired summer measurements; neither reports the observed spring
species shares across the same five seed pairs.

**When done.** `python tools/seed_set_evidence.py spring` uses the same five
paired seeds, serial launch and provenance contract as EE-1. Add
`test_scenarios/ee2_seed_set_spring.json`, based on PP-4's accelerated
season/winter controls and specialist workforce. Remove its restore
sequence so events describe one forward timeline. Save before winter
and after spring regrowth has finished; both arms run to that same
simulated day. Keep identical food support and actions between arms.

Extend the existing report with summer and spring live species counts,
Clover shares, seed-bank counts at each save, and observed spring
replacement counts by species. Separate logged spring weights from realised
species counts. Show within-arm summer-to-spring differences and paired
on-minus-off differences for each seed, with median and range. A species
absent from one arm is recorded as zero, not omitted from the comparison.

Extend synthetic checks for phase boundaries, incomplete spring coverage,
species missing from one arm and known paired spring differences. Run the
five-seed comparison and update the same reference with evidence,
limitations and whether any further evidence is warranted. Small, mixed
or null differences are valid findings; do not invent a target share.
Do not infer ordinary-run viability from the deliberately supported colony.

**Invariants.** EE-1's ownership and runtime restrictions remain. Existing
PP-4 tests stay intact. No new ecology mechanic is selected by this slice.
Close this plan when the measurements are complete; a proposed future
mechanic belongs in design, and a proven defect in its owning live plan.

**Open decisions:** none.

```queue
**[Codex] EE-2 -- measure seed-set carryover into spring**
- Plan: `plans/now/ecology-evidence.md` -- "EE-2 -- measure seed-set carryover into spring"
- Files: `tools/seed_set_evidence.py`, `test_scenarios/ee2_seed_set_spring.json`, `tests/test_seed_set_evidence.py`, `plans/reference/seed-set-evidence.md`
- Check: `python tests/test_seed_set_evidence.py` passes; `python tools/seed_set_evidence.py spring` completes ten serial runs and writes the paired spring report; `python tools/check_docs.py` passes
- Proof: `absent: plans/reference/seed-set-evidence.md :: ## Spring measurements`
- Next after: none -- seed-set evidence complete; further ecology needs an evidence-backed design decision
```
