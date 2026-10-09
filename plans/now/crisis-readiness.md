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

**Current state, verified 9 Oct 2026.** `scripts/main.gd::_advance_weather`
rolls for rain six times per game day, chooses intensity and duration at random,
eases intensity in and out, and shows a warning when rain starts. It does not
schedule a first crisis against elapsed play or colony preparation. Rain already
dilutes nectar, increases flight cost and can keep foragers in; FC-2 should use
those simulation rules for the outcome rather than add a scripted loss.

**Decision for Dave before FC-2.** Which rule schedules the first serious
forage-and-weather crisis in the Colony Run? Reply `FC-1: A`, `FC-1: B` or
`FC-1: C`; record the accepted choice in this section before FC-2 starts.

| Trigger | Player consequence | Cost |
| --- | --- | --- |
| **A (proposed): bounded readiness gate.** Once the early automation milestone is reached, schedule one clearly announced heavy-rain episode in a bounded window around the 20-minute gate, provided the colony has a working forager and a measurable food reserve. If preparation is absent at the window's end, announce and run the episode anyway. | Preparation can matter, but waiting cannot make the first crisis disappear. A weak colony still sees the pressure and can respond. | Requires a one-time scheduler, a saved pending/used state, a concrete reserve predicate and a measured window. It must coexist with ordinary rain without overlapping storms. |
| **B: fixed first episode.** Announce and run one heavy-rain episode at a fixed elapsed-play or game-day point, independent of preparation. | The player can learn the timetable; a slow start may be hit before useful automation. | Simpler scheduling and replay; readiness affects only the result, so Easy's readiness-weighted timing would need a separate explicit rule. |
| **C: existing random rain only.** Keep the current rolls and let the first qualifying storm count. | Some runs may meet no serious crisis near 20 minutes; others may be hit too early. | No new scheduler, but it cannot by itself satisfy the 20-minute experience gate or give a bounded scenario. |

**Proposed readiness and outcome contract, if A is accepted.** A working
forager means at least one living worker assigned and able to forage, rather
than merely a purchased role. Food reserve means stored brood/adult food can
cover a measured rain-length interruption at the current consumption rate;
FC-2 must name the existing diagnostic or simulation owner that calculates
both inputs and choose the numeric threshold from scenario evidence. Readiness
can move the episode within its window but cannot cancel it. The episode's
pressure is reduced forage income through the existing rain rules. Running
short of food, brood loss or recovery follows ordinary simulation; the event
must not directly set stores, health, deaths or a victory/failure flag. A
colony lacking readiness gets a warning and time to respond, not a hidden
rescue. No weather timing, duration, intensity or economy constant changes in
FC-1.

**Visible cause and response.** The warning should name approaching heavy
rain, the forecast loss of forage income, current food cover and the action
space (build reserves or reassign workers). Once rain starts, the weather
indicator and persistent "Why is this happening?" explanation should connect
rain intensity to diluted nectar, wet-wing flight cost or grounded foragers,
and then to the observed change in stores. It must distinguish a worker who
cannot forage for another reason. The explanation states evidence and possible
responses, not a mandatory click sequence.

**Deterministic evidence boundary for FC-2.** In the Colony Run, run a pinned
seed and scripted preparation through the warning, peak rain and recovery;
repeat from the same initial state and seed with preparation withheld. Record
the trigger inputs, scheduled and actual start, warning availability, rain
intensity, active foragers, forage income, food stores, consumption and
brood/worker outcomes at fixed checkpoints before, during and after the
episode. The prepared and unprepared paths must both encounter exactly one
first crisis inside the accepted window, and the trace must show the expected
forage interruption and possible simulation response. A same-seed ordinary-
weather baseline can isolate the rain contribution. These automated traces
show that the causal information and response are available; only a played
check can establish whether someone understands the cause or chooses a useful
response. Do not claim comprehension from warning display, "Why?" use or a
scripted action alone.

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
