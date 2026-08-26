# Insights recommendation implementation plan

Status: proposed | Owner: Dave / implementer to be assigned | Next: Slice 0, establish the comparable performance baseline | Evidence: `insights_from_ChatGPT.md`, refreshed 22–23 Aug 2026

> **CHATGPT-OWNED PLANNING FILE.**
> This is an implementation roadmap for the current recommendations in
> `insights_from_ChatGPT.md`. It is not the integrated project queue and does
> not authorise work. Use one slice at a time in an isolated `codex/...`
> worktree after the overlap checks required by `CHATGPT.md`.

## Outcome

Make a large colony responsive and legible by removing repeated global work
from bee and fog hot paths, then fix the evidenced worker/forager failures
without turning diagnostics or AI tooling into a second simulation layer.

The roadmap deliberately puts measurement, identity-rich diagnostics and
invalidation contracts before behaviour changes. It leaves the three older
design choices as explicit product decisions rather than silently changing
economy or specialist behaviour.

## Non-negotiable implementation rules

- Preserve deterministic, pinned-seed reproduction. A performance or behaviour
  claim needs the same population, camera/zoom where visible FPS matters,
  fixed-step settings and measurement window before/after a change.
- A bee may do bounded local work on its scheduled think tick. It must not scan
  a colony-wide collection every frame merely because it is idle.
- Shared truth belongs to the owner that can invalidate it: hive work state for
  work availability/reservations, fog for reveal state, and one validated
  point helper for all externally supplied flight starts. Do not create a
  second polling manager or autoload.
- Prefer event-driven invalidation, compact queues/counts, stable IDs and
  bounded retry/backoff over repeated nearest-item searches, per-bee caches or
  broad periodic rescans.
- Keep player-facing simulation rules explainable: a bee abandons a task for a
  named reason, a reservation has one owner and expiry, and a failed path has
  an observable target identity. Do not hide a bad target by teleporting,
  randomising indefinitely or quietly changing balance.
- Diagnostics are opt-in, bounded and causal. Counters required for an
  assertion may remain cheap in memory; verbose events, snapshots and failure
  capsules must be selected only for a scenario or failure. Never make an AI
  tail raw logs during a successful run.
- Avoid save-format changes unless a slice demonstrably requires persistence.
  If a new save field becomes necessary, isolate migration/defaulting/tests in
  its own slice and classify it high risk.
- Keep tuning separate from correctness. First prove the mechanism and its
  negative control; only then propose a `GameConfig` value with a stated
  player-facing trade-off.

## Execution map

```text
0 Baseline/contracts ──> 1 Miner allocator ──> 2 Fog CPU path
       │                         │                    │
       │                         └────> 3 Build stall diagnosis/fix
       │                                              │
       ├────> 4 Forager survival/safe starts ────────┤
       ├────> 5 Narrow diagnostics + automation run ─┘
       └────> 6 Workflow/tool maintenance (independent, ownership-gated)

7 Product decisions (only after the relevant evidence; no default code change)
```

Slices 1 and 2 are intentionally serial: each must be measured against the
same baseline so the next bottleneck is real. Slices 3–6 can proceed after
Slice 0, provided separate worktrees do not overlap. Slice 5 should consume
the diagnostic contracts from `CHATGPT_HEADLESS_EFFICIENCY_PLAN.md` if its
core Slices 0–4 are approved; it must not reimplement that plan.

## Slice 0 — reproducible baseline and low-cost contracts

**Purpose:** turn the 22 Aug profile into a repeatable acceptance baseline;
define the tiny observability additions needed by later causal fixes.

**Likely scope:** performance/scenario harness and focused tests only;
existing `Perf`, `DiagnosticLog`, `tools/run_scenario.py` and
`tools/analyze_session.py` as evidence, not a new framework.

**Deliver:**

- One pinned-seed, fixed-population performance fixture that records the
  `bee_state_miner`, `fog_of_war_update` and `fog_of_war_relight` mean/p95
  plus total frame time. Record camera/zoom separately for visible FPS.
- A short machine-readable baseline table: 24 idle miners after mining is
  exhausted, 85 outdoor bees, fixed warm-up and measurement frames. Preserve
  the original 6-FPS/144.8-ms evidence as historical context, not an eternal
  hard threshold.
- Focused log fields behind a diagnostic profile/flag: build target cell/hex,
  reservation/claimed slot, path/approach result; starvation resource focus,
  load, distance home, target nectar and time since drink; flower ID and
  nearby-obstacle identity on a stall recovery.
- A named invalidation contract before coding: which mutations increment the
  hive work epoch (order, mark/unmark, reservation, completion, topology),
  and which movements/topology updates invalidate a fog contribution.

**Acceptance:** repeated baseline samples produce comparable section names and
the profiler totals are interpreted without adding nested rows to their
parents. Diagnostic-off runs do not emit per-frame/per-bee traces or change
behaviour.

**Stop gate:** if a current sample no longer reproduces either hot path, update
the insight with the new evidence and reprioritise before optimisation.

**Risk:** low. No intended gameplay change.

## Slice 1 — shared miner work allocator

**Purpose:** remove failed mine-work searches from every idle miner every
frame while keeping miners responsive when work appears.

**Likely code area:** `scripts/bee.gd`, `scripts/bee_mining.gd`, the hive or
world owner of marked mining work, and a focused scenario/test fixture.

**Design:**

1. Make idle dispatch occur on stable, staggered think ticks. The cadence and
   phase derive from a stable bee identity/seed, not random per-frame timing.
2. Give the work owner compact availability state and, where ownership is
   required, a FIFO/priority work queue plus reservation. A queue entry is
   removed, invalidated or requeued by the mutation that changes it.
3. Cache the absence of mining work by epoch. An idle miner can make one cheap
   comparison, then waits until its next scheduled tick or an invalidating
   event—not re-run queued/marked/nearest-edge searches.
4. Define reservation expiry/cancellation for death, role change, unreachable
   target, mark removal and topology change. Never leave a stale claim that
   makes work disappear.

**Tests and checks:**

- no-work fixture: 24 miners remain `MINE_IDLE` with no global search on each
  frame;
- add/remove/complete work wakes a valid miner within the documented bounded
  tick latency;
- two miners cannot own one block; a cancelled reservation becomes available;
- pinned-seed regression confirms completed-mining totals and valid target
  choices; and
- reprofile the exact Slice-0 fixture. Report the miner section separately
  from total frame time.

**Acceptance:** idle-miner cost falls materially from the 43–45-ms baseline
without a visible command delay beyond the declared think-tick bound. Normal
mining completion remains correct.

**Risk:** medium: shared allocation and reservation lifecycle change.

## Slice 2 — fog relight bounded CPU path

**Purpose:** reduce dynamic-fog work from outdoor-bee-count × reveal-disc area
without changing permanent exploration or giving players a flickering map.

**Likely code area:** `scripts/fog_of_war.gd`, fog tests/fixtures and Perf
instrumentation. Keep ordinary rendering and permanent exploration separate.

**Stage A: choose the least invasive measured path.**

- Measure relight frequency, centre displacement distribution, reveal radius
  and dirty-tile writes. Confirm whether movement threshold/coalescing can
  reduce redundant updates without a visual regression.
- Budget/rephase relights across frames only if the resulting visibility age
  is bounded and imperceptible at the target zoom. Use a deterministic queue;
  do not let a busy frame starve one bee indefinitely.

**Stage B: replace membership scans if Stage A is insufficient.**

- Represent only the entering/leaving boundary of a moving disc as
  precomputed row spans/edge deltas. Update reference counts or an equivalent
  overlap-safe representation so neighbouring sources do not unlight each
  other.
- Rebuild only on a true radius/topology/source invalidation. Reuse immutable
  offset/span data; do not allocate per bee per frame.

**Escalation (not part of the default slice):** assess coarse-area shared light
sources, then a GPU dynamic mask, only if the CPU row-span implementation
still misses the agreed frame budget. GPU exploration state remains display
only; CPU permanent discovery remains authoritative.

**Tests and checks:** stationary source; one-tile move in each direction;
diagonal move; overlapping sources; source removal; permanent reveal survives
dynamic departure; and a manual moving-bee visual check at target zoom.

**Acceptance:** relight/update cost is materially lower than the Slice-0
baseline with identical explored/visible tiles for deterministic movement.

**Risk:** medium to high due to visibility correctness and hot-path impact.

## Slice 3 — unbuilt-cell diagnosis, then reservation/path repair

**Purpose:** establish why a build target persists before altering builder
selection, movement or the build economy.

**Likely code area:** builder state transitions in `scripts/bee.gd`, hive/cell
reservation owner and the diagnostic profile; no broad builder rewrite.

**Stage A — reproduce and identify:**

- Run the pinned day-57+ reproduction until the first prolonged target stall.
- Emit one bounded transition event per target/claim change, not every frame:
  target ID/hex, owner/slot, state transition, approach point, path result,
  reservation action and reason for release.
- Add a watchdog that reports a diagnostic failure after a bounded no-progress
  interval; it must not silently complete, relocate or delete a cell.

**Stage B — fix only the proven cause:**

- If invalid target/approach geometry: validate/reselect before a reservation
  commits, and release immediately on invalidation.
- If stale reservation: make owner and expiry explicit and test all release
  paths.
- If path failure: retry with a bounded alternative approach, then return the
  job to the shared queue with a reason. Escalate only repeated target-specific
  failures to a diagnostic/warning state.

**Acceptance:** a deliberately blocked target produces a named diagnostic and
does not strand all builders; a valid final cell completes in the reproduction;
the normal build order and player intent remain unchanged.

**Risk:** medium. It corrects simulation state ownership but should not tune
build speed or worker counts.

## Slice 4 — forager survival and valid start points

**Purpose:** prevent avoidable outdoor starvation and invalid flight starts
while retaining the intended risk of a poor nectar season.

**Part A — evidence and emergency return:**

1. Add the Slice-0 starvation payload and reproduce a trough with the
   documented abundant-honey condition.
2. Add a `BeeSurvival`/foraging decision that compares current energy with a
   conservative estimated cost home plus a config-owned safety margin. Include
   a bounded allowance for return routing rather than a raw Euclidean-distance
   magic number.
3. On crossing the threshold, cancel/release the flower target and set an
   explicit emergency-return reason/state. Do not wait until a depleted flower
   has been reached, and do not grant energy or bypass the journey home.
4. Log the decision once on entry, plus success/failure at hive arrival. Tune
   the safety margin only after the behaviour is proven.

**Part B — one obstacle-clearing start-point helper:**

- Introduce one deterministic helper that projects/rejects a candidate point
  against trees and raised ground with a bounded search and clear fallback.
- Route manual starts, orientation/scout points and recruitment jitter through
  it. Preserve manual choice as closely as possible and expose a clear reason
  if it had to move/fallback.
- Keep flower placement separate: this helper validates starts, it does not
  mask difficult flower approach geometry.

**Tests and checks:**

- reserve calculation monotonic with distance/carrying state; low-energy bee
  starts the return once, releases target and can replenish at home;
- plentiful-honey trough reduces documented avoidable outdoor deaths without
  making a resource-empty colony immortal;
- candidate in a tree, raised ground and clear space each resolves
  deterministically; every start source passes the same helper; and
- multi-seed run reports starvation counts, delivery impact and return-abort
  count separately.

**Acceptance:** no starvation fix is claimed from one lucky run; comparison
uses at least three matched seeds, with the longer run from Slice 5 if needed.

**Risk:** medium. Player-facing survival behaviour; config/UX wording changes
travel with the code if added.

## Slice 5 — focused diagnostics and foraging automation evidence

**Purpose:** make the remaining ambiguity cheap to resolve, then decide
whether there is a real recruitment/automation defect.

**Deliver:**

- Replace `cells.by_contents[""]` with `cells.by_contents["empty"]`, and
  update parser/fixture compatibility in the same small slice.
- Keep existing snapshot invariants as tests: population role/state and cell
  totals reconcile; snapshot timing/counters remain valid.
- Extend stall recoveries with flower ID and nearby obstacle identity. Re-run a
  named seed; only alter steering after a recurring causal geometry is shown.
- For indoor hunger, report edible nectar and ripe honey amounts, committed
  food reservation/loss and zero-food result. If contention is confirmed, add
  a small food reservation and a visible waiting-for-food state; do not treat
  pollen as food or infer scarcity from occupied cells.
- Run a pre-hatch pinned-seed, feature-on automation comparison long enough
  for orientation, scouting, constancy and recruitment to have an opportunity
  to activate. Include orientation flights, matching/settling, flower visits,
  starvation, stalls and tarsal rejection rate.

**Use of headless infrastructure:** if approved, take only
`CHATGPT_HEADLESS_EFFICIENCY_PLAN.md` Slices 0–4 needed to make this output a
compact verdict/artefact workflow. Do not revive its abandoned H6/H7 queue or
add background jobs/checkpointed AI.

**Acceptance:** each new field answers a named hypothesis and is absent from
normal success output. The longer comparison distinguishes “not exercised”,
“exercised but ineffective” and “regression”, rather than treating missing
events as failure.

**Risk:** low for schema/key/diagnostic-only work; medium for food reservation
or steering changes.

## Slice 6 — workflow and local-tool maintenance

**Purpose:** reduce wasted context/tool cost without changing game behaviour.

**Owner boundary:** this slice touches Claude-owned routing/configuration and
canonical queue files. Assign it to Claude Code, or explicitly authorise it
for a Codex isolated branch; do not alter it from advisory mode.

**Execute in this order, from `CHATGPT_WORKFLOW_AUDIT.md`:**

1. Repair the three `.claude/rules/` `scripts/...` path scopes and verify their
   activation in a fresh Claude session using representative files. Refresh
   durable fog guidance, pointing changing measurements to the insight.
2. Make active plan headers self-identifying; correct stale first-page status.
   Trim `NEXTSTEPS.md` to its stated three short pointers. Archive/remove only
   pure execution diaries after their durable architecture is captured.
3. Add one portable verification command that locates Python, runs read-only
   source/balance checks concurrently and runs the function-map check when
   relevant. Document one command, not per-host paths.
4. Set routine Codex work to Terra/medium and reserve Sol/high for ambiguous
   architecture/causal diagnosis. Use scripts, not a stronger model, for
   deterministic checks; do not add automatic subagents.
5. Ignore/prune local Claude state with narrow durable approvals; pin the same
   tested Godot MCP version in both client configs. Do this only after checking
   current repository ownership and test compatibility.
6. After two demonstrated repetitions, create only the focused run-review or
   slice-close-out skill that is proven useful. Install no speculative plugins.

**Acceptance:** a fresh session loads each intended rule; the verification
command works without a hard-coded runtime; canonical queue limits are true;
and local state/config edits have their own small, reviewable commit.

**Risk:** low to medium, depending on tool config and policy ownership; no
runtime game effect.

## Slice 7 — resolved product direction

Dave confirmed the following product decisions on 26 Aug 2026. They define
future implementation; this slice deliberately makes no speculative gameplay
change.

| Area | Confirmed direction | Implementation boundary |
|---|---|---|
| Queen backup nursing | The queen remains the default emergency/backup nurse. A challenge or scenario may override that default when it explicitly calls for a different rule. | Align player-facing teaching and tests with the fallback; do not remove the mechanic. |
| Stocking | Stocking is an indoor resource-moving role: assigned cell workers may move a resource from their cell to one or more other cells. Player management of the destinations/rules is a future feature. | Do not treat Stocking as clearing, eviction, or a generic flexible fallback. Design the player-management system before adding allocation behaviour. |
| Nectar to honey | Making honey converts and stores nectar; it must not create energy. Nectar spoilage is planned separately for a future feature. | Model the full economy and then change the conversion/configuration with a visible balance rationale and multi-season tests; do not fold spoilage into that change. |

Winter, weather, predators, rivals and disease remain unvalidated by this
summer run. Do not schedule balance work for them from these insights.

## Completion and hand-off for every code slice

1. Record current branch, baseline commit, both worktree statuses and exact
   slice scope before editing.
2. Keep one concern per commit where practical: diagnostic contract, shared
   allocation/visibility logic, and tuning must not be inseparable.
3. Run the relevant deterministic checks, the slice’s negative control and a
   Godot boot. Run a visible check when fog, player feedback or UI changes.
4. Reprofile after each hot-path slice; report measured section mean/p95,
   population/setup and remaining bottleneck—not just FPS.
5. Update the relevant player/developer documentation only if the merged
   behaviour/contracts make it inaccurate. Do not edit `NEXTSTEPS.md` or
   Claude policy files unless explicitly assigned.
6. Commit on the isolated `codex/...` branch and hand off scope, commits,
   changed-file summary, checks, risk tier and one concrete manual check (or
   `none`) under `CHATGPT.md`’s integration contract.

## Recommended first session

Start Slice 0, then Slice 1. Reprofile before deciding whether Slice 2 is
still the highest-value optimisation. In parallel only with separate ownership,
run Slice 3’s evidence-only reproduction or Slice 6’s workflow maintenance.
Do not begin fog redesign, food-reservation changes, or economy tuning until
their preceding stop gates have produced current evidence.
