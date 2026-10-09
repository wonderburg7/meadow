# Crisis readiness -- decide a readable first pressure event before implementing it

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Codex | Next: FC-1 -- define the first-crisis readiness and evidence contract | Dependency: COL-8's season change and CD-2's diagnostic vocabulary both landed (8 and 9 Oct 2026) | Verified: 2026-10-09

## Objective

Turn the unmeasured 20-minute forage/weather crisis into a bounded, readable
event contract. The design decides pressure and readiness; simulation decides
the outcome. FC-1 and FC-2 were CR-1 and CR-2 until 9 Oct 2026; the Colony
Run's archived CR-1 and CR-2 already hold those ids.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| FC-1 | decide trigger, readiness, failure boundary and scenario evidence | this plan, `plans/design/product-scope.md` | yes -- COL-8 and CD-2 landed | high |
| FC-2 | implement the accepted crisis and deterministic scenario | specified by FC-1 | after Dave accepts FC-1 | high |

## FC-1 -- define the first-crisis readiness and evidence contract

<!-- LAYER: immediate-task -->

State alternatives and costs for the trigger, what preparation counts as
readiness, how the player sees the cause, and the scenario evidence that can
measure availability without pretending to measure comprehension. Do not alter
weather timing or balance.

```queue
**[Codex] FC-1 -- define the first-crisis readiness and evidence contract**
- Plan: `plans/now/crisis-readiness.md` -- "FC-1 -- define the first-crisis readiness and evidence contract"
- Files: `plans/now/crisis-readiness.md`, `plans/design/product-scope.md`
- Check: `python tools/check_docs.py` passes and FC-1 names a trigger, readiness input, visible cause and deterministic scenario boundary
- Proof: `present: scripts/main.gd :: func _advance_weather`
- Next after: FC-2 -- implement the accepted crisis and deterministic scenario
```

## FC-2 -- implement the accepted crisis and deterministic scenario

Specified only after FC-1 records Dave's decision and owns no file held by the
season work.

```queue-gated
**[Codex] FC-2 -- implement the accepted crisis and deterministic scenario**
- Plan: `plans/now/crisis-readiness.md` -- "FC-2 -- implement the accepted crisis and deterministic scenario"
- Files: specified by FC-1
- Check: specified by FC-1
- Proof: `present: plans/now/crisis-readiness.md :: ## FC-1 -- define the first-crisis readiness and evidence contract`
- Next after: none -- crisis readiness is complete
```
