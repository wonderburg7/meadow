# Ecology evidence -- what pollination changes in the meadow

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: EE-1 -- a paired summer seed-set comparison, then EE-2 -- carryover into spring | Dependency: EE-2 follows EE-1; no simulation or balance changes | Verified: 2026-10-31

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
| EE-1 | Paired summer comparison and a tested offline reporter | `tools/seed_set_evidence.py`, `test_scenarios/ee1_seed_set_summer.json`, `tests/test_seed_set_evidence.py`, `plans/reference/seed-set-evidence.md` | medium |
| EE-2 | Extend the comparison through winter into spring | `tools/seed_set_evidence.py`, `test_scenarios/ee2_seed_set_spring.json`, `tests/test_seed_set_evidence.py`, `plans/reference/seed-set-evidence.md` | medium |

## EE-1 -- measure summer seed-set replacement across five seeds

Level: medium -- bounded offline evidence work with deterministic parser checks.

**When done.** `python tools/seed_set_evidence.py summer` runs five paired
seeds (12345, 7, 2026, 90210, 555), serially, at fixed 30 fps. For each
seed, use identical initial conditions and actions, changing only the
scenario's `seed_set` flag. Start from PP-4's specialist Clover setup,
keep weather, disease and predators off, disable winter, and stop at day
10 with an end save. Use isolated scenario user directories through the
existing runner. Do not overwrite player saves or modify the PP-4 fixture.

Create `test_scenarios/ee1_seed_set_summer.json` for these controls. The
tool may create temporary case variants from it. Record all scenario
overrides: this is an accelerated diagnostic setup, not ordinary Colony
Run pacing. Both arms must finish their actions and produce complete logs
and the end save. Missing data, launch errors, malformed log payloads or
unresolved actions are failures, never zero-valued measurements.

Produce a JSON report and a readable table with one row per seed and arm:
elapsed simulated time, eligible flower deaths, all flower deaths, seed
and seasonal replacements, final live-flower counts by species and total,
and Clover's final share. Give paired differences for seed replacements
and Clover share, plus median and range across seeds. Count a replacement
from its logged event, not from the expected rule. Record species names,
denominators and the handling of an empty meadow explicitly. Do not claim
a causal per-flower or per-bee match after the arms' random streams diverge.

Retain full run artefacts outside tracked files. Reports identify baseline
commit, engine version, fixture hash, seeds, fixed fps, controls and source
artefact paths. Commit a compact evidence table and its interpretation to
`plans/reference/seed-set-evidence.md`, with the reproduction command and
limitations. Raw logs and generated bulk data are not committed.

**Checks.** `python tests/test_seed_set_evidence.py` tests aggregation using
small synthetic logs/saves, including failed/missing arms, malformed events,
zero denominators and known paired differences. The real five-seed command
must complete successfully. Check causal coverage (both eligible and
ineligible deaths; actual seed and seasonal replacements), not an invented
minimum improvement. If coverage is missing, report it and adjust only the
fixture within these controls; do not tune gameplay to manufacture a result.

**Invariants.** No game scripts, balance defaults, saves, production logging
or processing cadence change. All added work is offline or an explicitly
invoked scenario run. Unexpected gameplay behaviour is reported as evidence;
any proposed fix needs its own owning plan and normal admission.

**Open decisions:** none.

```queue
**[Codex] EE-1 -- measure summer seed-set replacement across five seeds**
- Plan: `plans/now/ecology-evidence.md` -- "EE-1 -- measure summer seed-set replacement across five seeds"
- Files: `tools/seed_set_evidence.py`, `test_scenarios/ee1_seed_set_summer.json`, `tests/test_seed_set_evidence.py`, `plans/reference/seed-set-evidence.md`
- Check: `python tests/test_seed_set_evidence.py` passes; `python tools/seed_set_evidence.py summer` completes ten serial runs and writes the paired report; `python tools/check_docs.py` passes
- Proof: `absent: plans/reference/seed-set-evidence.md :: ## Summer measurements`
- Next after: EE-2
```

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
