# Efficiency implementation plan

Status: in progress (Slices 1-3 done) | Owner: Dave / Claude Code | Next: Slice 4 (data-drive Challenge definitions), only once Challenge 3 is actively assigned | Dependency: `CHATGPT_EFFICIENCY_AUDIT.md` (Dave's decisions confirmed 2026-08-28) | Verified: 2026-08-28

Requires Dave's decisions in `CHATGPT_EFFICIENCY_AUDIT.md` and an isolated
`codex/...` worktree before any implementation. This plan deliberately does
not make `NEXTSTEPS.md` a Codex work queue.

## Acceptance rules for every slice

1. Record the comparable baseline command and result before and after a
   runtime-cost change. A static improvement is not an FPS claim.
2. Preserve seeded simulation outcomes unless the slice explicitly changes
   rules; prove that with a focused headless scenario or deterministic source
   test.
3. Add/update save migration coverage before writing a new persisted field.
4. Keep one catalogue/service as the authority for each moved fact; delete or
   validate the old duplicate in the same slice.
5. Keep changes isolated, document the changed contract and commit each slice
   separately for Claude's risk-proportional integration.

## Slice 0 — Measure and contract the chosen target

**Purpose:** replace the audit's priority hypotheses with a reproducible
baseline for one approved target: cell index, colony snapshot/HUD refresh, or
Challenge goal polling.

**Work:** add narrow `Perf` spans only where missing; record a fixed-FPS
baseline using `recommendation_slice0_baseline.json`; add a small scenario or
source test that exercises the chosen data mutation. Define the event/mutation
owners and the no-behaviour-change invariant.

**Exit:** baseline artefact, target acceptance threshold, and a test that
would fail if the cache/view became stale. No optimisation is required in this
slice.

**Risk:** low.

## Slice 1 — Make cell and colony derived state dirty-driven (done 2026-08-28)

**Purpose:** eliminate repeat work where multiple systems need the same cell
or colony facts.

**Work:** replace `Hive`'s frame-keyed content-index rebuild with a
mutation-owned dirty index; introduce a minimal immutable-ish colony snapshot
for requested summaries (role counts, free/brood/corpse cells, energy share).
Update cells/bee lifecycle/hive mutations to invalidate it. Retain a
development-only consistency assertion or source/unit test against a fresh
scan.

**Exit:** unchanged save/load and headless outcomes; the index rebuild count is
bounded by relevant mutations rather than render frames; existing HUD/panel
values remain correct after build, hatch, death, designation and load.

**Risk:** medium — shared simulation-derived state.

## Slice 2 — Bind views to revisions, not frames (done 2026-08-28)

**Purpose:** let visible UI pull updates only when something it shows changes.

**Work:** add revision/signature checks for cell popup, flower summary and
selection text; have the one-second signal/panel pass consume `ColonySnapshot`
instead of recounting. Keep time-sensitive fields on an explicit cadence and
refresh immediately on changed selection/pinned status/panel open.

**Exit:** no visible stale controls or numbers in manual meadow/hive checks;
the HUD's per-frame refresh path contains no formatting/rebuild when no shown
revision changed; corner signature behaviour remains intact.

**Risk:** medium — player-facing UI freshness.

## Slice 3 — Establish catalogues and availability authority (done 2026-08-28)

**Purpose:** make a mechanic's identity, availability and resource semantics
answerable from one place.

**Work:** add a `resources.gd` dictionary catalogue and a non-visual
availability service. The service composes code existence, config enabled,
level/Challenge unlock, entity eligibility, target validity and temporary
suppression, returning stable reason keys. Start with one vertical path (for
example a forager mode and one resource); use adapters so existing HUD and
stage-gate callers retain behaviour. Add catalogue completeness tests,
including alignment of `Roles` with the saved `BeeEnums` ordering.

**Exit:** an approved vertical feature no longer duplicates its label/colour/
eligibility/save key; UI displays the service's reason without owning the
rule; no save format change unless a newly persisted field was approved.

**Risk:** medium; high if it introduces a save migration or changes unlocked
content.

## Slice 4 — Data-drive Challenge definitions and feedback

**Purpose:** prepare Challenge 3 without making the runner a larger hotspot.

**Work:** extract stage records, prompt records and static target data from
`challenge_runner.gd` into a keyed table. Keep goal predicates in a small
registry and make each goal declare its cadence (event, throttled poll or
frame/position). Introduce named feedback definitions for at least Challenge
stage clear and one warning/toast; views render them while simulation emits
facts.

**Exit:** adding a simple new stage needs a data row, a named predicate and
view binding—not edits across runner, HUD and debug panel. Existing Challenge
1/2 checkpoints and unlock state load exactly as before.

**Risk:** medium. Do not mix tutorial text/product changes with this extraction.

## Slice 5 — Persistence and event boundaries

**Purpose:** make future catalogue/status additions safe to iterate.

**Work:** create ordered save migrations from every supported older format;
write tests for each fixture. Define the minimal domain events required by
Slices 1–4 (`BeeDied`, `CellChanged`, `StorageChanged`, `DayChanged`,
`RainChanged`, `ChallengeStageCleared`) with emitter, allowed listener and
save/load reconstruction rules. Replace only the direct reach-throughs that
these slices exposed.

**Exit:** old fixtures migrate deterministically; a save with unavailable but
persisted state has specified treatment; caches/snapshots rebuild directly on
load rather than relying on event replay.

**Risk:** high — persistence and cross-system contracts.

## Slice 6 — Measured optional simulation cohorts

**Purpose:** apply component-like filtered queries only if a post-slice Perf
capture names a remaining hot path.

**Work:** choose one measured target, likely rival local forage or a cohort
query. Reuse flower/cell indexes or add a narrow status index behind node APIs.
Keep Bee as the owning node; do not introduce a generic ECS framework.

**Exit:** named Perf span improves against the comparable baseline with no
seeded outcome regression; index invalidation has tests.

**Risk:** medium to high depending on the measured path.

## Recommended order and stop conditions

Execute Slices 0–2 first only if Dave selects the runtime target. Stop after
Slice 2 if the measured headroom is sufficient. Execute Slice 3 before adding
another resource, mode or availability-gated feature. Execute Slice 4 only
when Challenge 3 is actively assigned. Slice 5 precedes any schema change.
Slice 6 has no standing mandate: it starts only with a named measured span.

## Manual acceptance checklist

- In meadow and hive views, mutate cells, brood, resources and selection; open
  and close each relevant panel and confirm values/buttons update immediately.
- With a starred FPS readout, compare the same seed, colony size and fixed FPS
  configuration before/after. Check p95 and named sections individually;
  nested sections must not be summed.
- Load saves from each supported version with role/state, cell designations,
  weather/winter state and any approved availability data; verify caches and
  panels without replaying events.
- Run Challenge 1 and 2 through a stage boundary, checkpoint restore and
  completion; confirm the same UI unlocks, prompts and goals.

