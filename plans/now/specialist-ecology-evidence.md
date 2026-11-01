# Next ecology evidence -- select a specific player-facing question

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: proposed | Owner: Dave / Codex | Next: Dave selects the evidence question below before any slice is admitted | Dependency: the completed seed-set evidence in `plans/reference/seed-set-evidence.md`; no game-code changes authorised | Verified: 2026-11-01

## Objective

Answer a specific ecology design question using existing mechanics and bounded,
reproducible measurements. Dave chose a new bounded ecology evidence plan rather
than reassigning T2-15 from Claude's backlog (Dave, 1 Nov 2026). The question
itself remains to be selected; this draft schedules no implementation.

## Current state

`plans/reference/seed-set-evidence.md`, "Spring measurements", reports five
matched seed-set on/off pairs with Clover specialists in a deliberately supported,
accelerated colony. Spring Clover share was higher with seed set enabled in all
five pairs, with a median difference of 20.2538 percentage points. That study
establishes neither ordinary-run survival nor ordinary-run effect size.

Its reopening rule requires a specific proposed ecology design question before
more measurement. `plans/design/product-scope.md`, "10. Pollination and ecology",
already intends worked patches to thicken and carry into spring. The current
fixture `test_scenarios/ee2_seed_set_spring.json` selects `forager_species` and
uses the existing specialist workforce; no new foraging or pollination mechanism
is needed to ask whether the choice of species affects that result.

## Question selection

| Rank | Candidate question | Stage | Why now | Cost and what it informs |
| --- | --- | --- | --- | --- |
| 1 | Can choosing Borage rather than Clover specialists steer next spring's flower mix? | Design decision pending | The previous campaign only worked Clover; tests the existing cultivation intent across a second species | Extend the offline reporter and matched fixture controls; informs whether specialist assignment can be explained as cultivation; no game or save changes |
| 2 | Is seed-set carryover still measurable at ordinary day and season lengths? | Design decision pending | Addresses the earlier study's pacing limitation | Longer serial runs and survival constraints; informs ordinary-run expectations without changing balance |
| 3 | Defer another ecology campaign | Available | The completed study found no defect requiring a follow-up | No new evidence slice; leaves the Codex lane without a successor after CF-2 |

**Recommendation:** candidate 1. Keep the existing supported-colony controls so
specialist species is the changed treatment; compare each species' seed-set
on/off effect before comparing treatments. A positive Clover result does not
predict a positive Borage result. Null and mixed findings are valid outcomes.
Do not use raw Clover-versus-Borage shares as a seed-set causal estimate.

## Open slices

| Slice | Outcome | Files owned | Startable | Minimum reasoning |
| --- | --- | --- | --- | --- |
| None admitted | Define only after Dave chooses the question | None | no | high for planning; bounded reporter/fixture work is expected to be medium |

## Scope and ownership

Existing `scripts/pollination.gd` owns seed ledgers and rollover;
`FlowerSpecies` owns seasonal draw weights. This work would observe their
current behaviour, using `tools/seed_set_evidence.py` and existing saved-run
and diagnostic output, rather than add a parallel game mechanism.

Any eventual slice is offline tooling, synthetic validation, scenario fixtures
and an evidence reference only. Preserve simulation, shipped GameConfig balance,
save fields, Challenges and player-facing UI. Retain provenance and run Godot
arms serially. Claims must distinguish supported fixtures from ordinary runs,
logged weights from actual replacements, and descriptive pairs from confidence
intervals. No threshold or balance change follows automatically.

## Dependencies and required reading

The selected question must become a deterministic acceptance contract and a
bounded campaign size before a queue block is written. Confirm file ownership
again at admission. CF-2 remains the leading Codex slice; this plan is its
proposed successor, not a new prerequisite for feedback functionality.

Required reading for specification: this file; `plans/reference/seed-set-evidence.md`
"Spring measurements"; `plans/design/product-scope.md` "10. Pollination and ecology".

## Open decisions

**Open decisions:** Dave selects specialist choice, ordinary pacing, or deferral.
This blocks slice specification and admission, not any already-implemented work.
