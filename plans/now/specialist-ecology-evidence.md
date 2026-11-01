# Specialist ecology evidence -- does specialist choice steer the spring meadow?

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Codex | Next: retain plans/reference/specialist-ecology-evidence.md; no automatic successor | Dependency: existing PP-4 seed-set behaviour and EE-2 measurements; no game-code changes | Verified: 2026-11-01

## Objective and decision

**Decision (Dave, 1 Nov 2026):** answer whether assigning Borage rather than
Clover specialists can steer next spring's flower mix. Extend the existing
paired method; preserve game mechanics, balance and saves. This supersedes the
draft's pending question selection. Ordinary pacing is outside this campaign.

The evidence informs the existing cultivation intent in
`plans/design/product-scope.md`, "10. Pollination and ecology": the meadow the
colony pollinated comes back. It does not authorise a new UI claim or balance
change. Null and mixed results are valid outcomes, not failures to tune away.

## Current state

`plans/reference/seed-set-evidence.md`, "Spring measurements", reports five
seed-set on/off pairs with Clover specialists in a supported, accelerated colony.
Spring Clover share was higher on in all five pairs (median +20.2538 percentage
points). The report establishes neither ordinary-run survival nor ordinary-run
effect size; its reopening rule requires a specific design question, now selected.

SE-1 extended `tools/seed_set_evidence.py` with the matched specialist reporter.
SE-2 has now completed twenty serial arms with unchanged EE-2 controls and
recorded the full measurements and limitations in
`plans/reference/specialist-ecology-evidence.md`. Both specialist assignments
steered the corresponding flower share within this supported fixture.
No mechanical, balance, save or UI change follows from the evidence.

## Open slices

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| None | Specialist evidence complete; durable measurements retained in the reference | none | no automatic successor | -- |

**Dependencies:** SE-1 supplied the reporter; SE-2 used it without game-code
changes. No open implementation dependencies or automatic successor remain.

**Required reading:** retain the durable specialist reference and external
artefacts for any future explicit ecology design question.

**Closeout (1 Nov 2026):** SE-2 completed all twenty serial arms and recorded the
matched results in `plans/reference/specialist-ecology-evidence.md`. Dave explicitly
authorised SE-2 as this run's fifth and final slice even though it empties the
Codex lane; this one-run decision adds no successor or standing admission exception.
Any later ecology question requires a new explicit decision.

## Campaign contract

Run seeds 12345, 7, 2026, 90210 and 555 for all four treatments: Clover/off,
Clover/on, Borage/off, Borage/on. All 20 arms run serially, on one recorded game
baseline at fixed 30 fps. Re-run Clover arms on that baseline rather than splice
in EE-2's historical results. Specialist species and seed-set flag are the only
treatment changes; seed varies by pair. Retain EE-2's workforce, food support,
weather/disease/predator/rival controls, accelerated calendar, winter and regrowth
settings, and forward day-10/day-25 saves. The new fixture may retain the existing
EE2 summer/spring save action names for reporter compatibility.

For each seed, specialist and species, report seed-set on-minus-off differences
in spring live counts/shares, both seed ledgers and realised spring replacements.
Then report the per-species difference of those paired effects:
`(Borage specialist on - Borage specialist off) - (Clover specialist on - Clover specialist off)`.
Show raw arm data and each defined-pair denominator, median and range across five
seeds. Shares use all live flowers; absent species is zero and an empty meadow's
share is undefined, never silently zero. Include within-arm summer-to-spring
changes and logged draw-weight ranges separately from realised replacements.

Same seeds do not guarantee identical random draws after treatments diverge.
These are descriptive controlled comparisons, not confidence intervals. Report
missing biological coverage (including no Borage seed events) as a limitation;
do not vary controls to force a positive effect or invent an effect threshold.
Execution must still capture the complete treatment matrix, successful verdicts,
forward saves, expected spring interval and correct rollover behaviour. Reject
missing/duplicate/mislabeled arms or incompatible provenance before summarising.

SE-1 shipped 2026-11-01; its specification is `plans/archive/SE-1_2026-11-01.md`.

## SE-2 -- measure specialist steering in the matched spring campaign

Level: medium -- bounded serial evidence campaign and interpretation.

**When done:** add `test_scenarios/se2_specialist_spring.json` using the contract's
unchanged EE-2 controls. Run `python tools/seed_set_evidence.py specialists --fixture
test_scenarios/se2_specialist_spring.json` to a retained output directory outside
the checkout. Record the complete 20-arm results, paired summaries, contrasts,
coverage, provenance, reproduction command and artefact location in
`plans/reference/specialist-ecology-evidence.md` under `## Measurements`.
State what the evidence says about specialist steering within this fixture;
separate measured outcomes from proposed future UI or balance decisions. The
reference's continuing Next instruction must retain it as a durable reference.
Do not extend the reporter in this slice: if its contract is broken, report the
specific failing evidence and stop for a scoped correction.

**Invariants:** fixture/reference only plus owning-plan closeout; no mechanical
or balance changes. Every Godot arm is serial. No follow-up slice is automatic;
a future design question requires a new explicit decision.
**Open decisions:** none.

```queue
**[Codex] SE-2 -- measure specialist steering in the matched spring campaign**
- Plan: `plans/now/specialist-ecology-evidence.md` -- "SE-2 -- measure specialist steering in the matched spring campaign"
- Files: `test_scenarios/se2_specialist_spring.json`, `plans/reference/specialist-ecology-evidence.md`
- Check: `python tools/seed_set_evidence.py specialists --fixture test_scenarios/se2_specialist_spring.json` completes twenty serial arms and writes both reports; `python tests/test_seed_set_evidence.py` passes; `python tools/check_docs.py` passes
- Proof: `absent: plans/reference/specialist-ecology-evidence.md :: ## Measurements`
- Next after: none -- specialist evidence complete; any later ecology question is outside this plan
```
