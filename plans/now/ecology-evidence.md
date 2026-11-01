# Ecology evidence -- what pollination changes in the meadow

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Codex | Next: None — plan complete | Dependency: none; no simulation or balance changes | Verified: 2026-11-01

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

Measurements are complete. Summer and spring evidence, limitations and the
reopening criterion are recorded in `plans/reference/seed-set-evidence.md`.
No further slice or mechanic is proposed by these findings.

| Slice | What it does | Files it owns | Level |
| --- | --- | --- | --- |

EE-1 shipped 2026-10-31; its specification is `plans/archive/EE-1_2026-10-31.md`.

EE-2 shipped 2026-11-01; its specification is `plans/archive/EE-2_2026-11-01.md`.
