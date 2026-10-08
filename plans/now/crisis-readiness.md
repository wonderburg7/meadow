# Crisis readiness -- decide a readable first pressure event before implementing it

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Codex | Next: CR-1 -- define the first-crisis readiness and evidence contract | Dependency: waits for COL-8's season change and CD-2's diagnostic vocabulary | Verified: 2026-10-08

## Objective

Turn the unmeasured 20-minute forage/weather crisis into a bounded, readable
event contract. The design decides pressure and readiness; simulation decides
the outcome.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| CR-1 | decide trigger, readiness, failure boundary and scenario evidence | this plan, `plans/design/product-scope.md` | after COL-8 and CD-2 | high |
| CR-2 | implement the accepted crisis and deterministic scenario | specified by CR-1 | after Dave accepts CR-1 | high |

## CR-1 -- define the first-crisis readiness and evidence contract

<!-- LAYER: immediate-task -->

State alternatives and costs for the trigger, what preparation counts as
readiness, how the player sees the cause, and the scenario evidence that can
measure availability without pretending to measure comprehension. Do not alter
weather timing or balance.

```queue-gated
**[Codex] CR-1 -- define the first-crisis readiness and evidence contract**
- Plan: `plans/now/crisis-readiness.md` -- "CR-1 -- define the first-crisis readiness and evidence contract"
- Files: `plans/now/crisis-readiness.md`, `plans/design/product-scope.md`
- Check: `python tools/check_docs.py` passes and CR-1 names a trigger, readiness input, visible cause and deterministic scenario boundary
- Proof: `present: scripts/main.gd :: func _advance_weather`
- Next after: CR-2 -- implement the accepted crisis and deterministic scenario
```

## CR-2 -- implement the accepted crisis and deterministic scenario

Specified only after CR-1 records Dave's decision and owns no file held by the
season work.

```queue-gated
**[Codex] CR-2 -- implement the accepted crisis and deterministic scenario**
- Plan: `plans/now/crisis-readiness.md` -- "CR-2 -- implement the accepted crisis and deterministic scenario"
- Files: specified by CR-1
- Check: specified by CR-1
- Proof: `present: plans/now/crisis-readiness.md :: ## CR-1 -- define the first-crisis readiness and evidence contract`
- Next after: none -- crisis readiness is complete
```
