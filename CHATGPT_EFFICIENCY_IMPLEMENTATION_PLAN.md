# Efficiency implementation plan

Status: in progress (Slices 1-5 done) | Owner: Dave / Claude Code | Next: Slice 6 has no standing mandate, starts only with a named measured span | Dependency: `CHATGPT_EFFICIENCY_AUDIT.md` (Dave's decisions confirmed 2026-08-28) | Verified: 2026-08-28

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

## Slice 4 — Data-drive Challenge definitions and feedback (done 2026-08-28)

**Purpose:** prepare Challenge 3 without making the runner a larger hotspot.
Done as extraction-only tech-debt prep ahead of the plan's own trigger
("only once Challenge 3 is actively assigned") -- Dave asked for the
structural groundwork now, with no Challenge 3 content added; Challenge 3
itself is still not scheduled (`NEXTSTEPS.md` has no Challenge 3 entry).

**Work:** `challenge_stages.gd` now holds STAGES_1/STAGES_2, all prompt
records and every static target/timing constant as pure data (no `main`/tree
access). `challenge_feedback.gd` holds named feedback definitions
(`stage_cleared`, `challenge_2_rescue`, `challenge_2_recovery`) -- the two
Challenge 2 ad-hoc `gallerin_panel.show_now()` dictionaries are now built
from named defs via `ChallengeFeedback.gallerin_prompt()`. `challenge_runner.gd`
keeps only the runner logic: its 28 goal predicates moved from one large
`match` into a `_goal_registry` Dictionary of bound `_goal_check_*` methods,
each with a declared `GOAL_CADENCE` entry (frame/event/poll) -- cadence is
documentation for a future optimisation pass only; every goal is still
checked once per `_process`, unchanged from before this slice.

**Exit:** adding a simple new stage needs a data row in `challenge_stages.gd`,
a `_goal_check_*` predicate plus registry/cadence row in `challenge_runner.gd`,
and (if needed) a feedback def in `challenge_feedback.gd` -- not edits
scattered across the runner, HUD and debug panel. Verified: `verify.ps1`
passes (75 scripts), every stage's `goal` id has a matching registry and
cadence entry (cross-checked by grep), a full Godot boot shows no new parse
errors, and no other script referenced the moved constants directly (grepped
clean). No save/behaviour change was intended; a hands-on Challenge 1/2
playthrough check is queued in `HANDS_ON_CHECKS.md` to confirm goals,
prompts and the rescue/recovery messages still fire exactly as before.

**Risk:** medium. Deliberately did not mix tutorial text/product changes into
this extraction -- no stage text, target number or goal rule changed.

## Slice 5 — Persistence and event boundaries (done 2026-08-28)

**Purpose:** make future catalogue/status additions safe to iterate. Done as
groundwork ahead of the plan's own trigger ("only once a schema change is
actually needed") -- Dave asked for the full scope now regardless, a
deliberate one-off exception to `.claude/rules/saving.md`'s normal guidance
against building a migration framework without a second format to bridge.

**Work:** `scripts/save_migrations.gd` holds an ordered, version-numbered
migration ladder (1→2, 2→3) run once by `save_game.gd::read()` before a
parsed save reaches `saving.gd`; `tests/fixtures/save_v1.json` and
`save_v2.json` plus `tests/test_save_migrations.py` cover both steps and
idempotency. `saving.gd`'s existing per-field `.get()` defaults (for the
several field additions that never bumped `FORMAT_VERSION`) were
deliberately left untouched -- they're already correct and unrelated to the
version ladder. Of the six named events, only `StorageChanged` pre-existed
(`hive.gd`); `BeeDied` (`main.gd`, replacing two direct calls from
`bee_survival.gd::die()`), `DayChanged` (`main.gd`, replacing a direct HUD
call in the day-advance loop) and `ChallengeStageCleared`
(`challenge_runner.gd`, no listener yet) are now real Godot signals.
`RainChanged` emits only on the two discrete start/stop transitions in
`_advance_weather()`, not every frame. `CellChanged` was deliberately **not**
turned into a signal: `Hive.invalidate_index()` is already the mutation
chokepoint every cell mutator calls several times per frame at real colony
sizes, so a real signal there would be pure per-mutation overhead with no
consumer -- it's documented as the event boundary instead, matching Slice
1/2's own choice of epoch/revision polling over push notification.

**Exit:** the two real fixtures migrate deterministically and idempotently
(`tests/test_save_migrations.py`); `saving.gd::_restore()` was audited and
confirmed to never emit any of the new signals -- a load sets state directly
and rebuilds caches once at the end (`invalidate_index()`,
`_update_population_readout()`), same as before this slice. `verify.ps1`
passes (76 scripts, `FUNCTION_MAP.md` regenerated). No Godot boot was
available this session to confirm parser-level correctness; a hands-on check
(death epitaph/marker, day rollover, rain start/stop, a Challenge stage
clear, save/load) is queued in `HANDS_ON_CHECKS.md`.

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
another resource, mode or availability-gated feature. Slice 4 is done (see its
own status note on why it landed ahead of Challenge 3 being assigned). Slice 5
is done (see its own status note on why it landed ahead of a concrete schema
change). Slice 6 has no standing mandate: it starts only with a named
measured span.

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

