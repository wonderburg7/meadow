# Meadow efficiency audit

**Date:** 2026-08-27  
**Method:** static review of the current `master` checkout at
`c21b1cc0a39b7e52a3ab798d8bf0b78932d56eb6`. This is an architecture and
runtime-cost audit, not a profiler result. Treat the priority ordering below as
a hypothesis to validate with the existing `Perf` overlay and pinned headless
baseline before changing behaviour.

## Executive result

Meadow has already avoided several expensive failure modes. The forager uses a
flower spatial grid before its fallback scan (`bee_foraging.gd`), bee thinking
is staggered and capped at 8 Hz (`bee.gd`), flower recharge is lazy,
cell/flower presentation is throttled and hidden-view presentation is skipped,
and the project has both `Perf` sections and a fixed headless performance
fixture. Do **not** begin an ECS rewrite, pathfinding rewrite, obstacle spatial
index, object-pooling exercise, or off-screen simulation reduction without a
new measured bottleneck.

The remaining work is chiefly about making authority explicit and replacing
repeated polling/rebuilds with invalidation. The recommended first change is a
small indexed derived-state service for cell/colony summaries, with a dirty
HUD refresh contract. It has a short feedback loop, is useful to several
systems, and does not require changing the simulation model.

## Findings

| Priority | Finding | Evidence | Consequence | Recommended direction |
| --- | --- | --- | --- | --- |
| P0 | Roles have two authoritative integer definitions. | `roles.gd` repeats the IDs in `bee_enums.gd`; the comments explicitly say they must match. | A new/reordered role can corrupt saved integer state or make catalogue/UI identity drift. | Make `BeeEnums.Role` the persisted enum authority and derive/validate `Roles` entries against it at startup/source-test time. Keep stable string keys as the external/cross-file identity. |
| P0 | Availability exists in four partial forms. | `GameConfig` holds feature flags, `prerequisites.gd` only models settings dependencies, `levels.gd` gates level features, `stage_gate.gd` gates visible UI, and `challenge_runner.gd` additionally filters role/mode/designation keys. | A mechanic can exist, be enabled, be unavailable to a level, be hidden by a Challenge, or be invalid for a target with no single answer explaining why. | Add a non-visual availability query that composes these facts and returns a reason code. Migrate consumers incrementally; do not replace the UI gate's saved state. |
| P0 | Resources and commands are string-shaped facts spread between simulation, UI and persistence. | Literal resource keys occur in `flower.gd`, `hive.gd`, `hive_cell.gd`, `bee*.gd`, `hud.gd`, save code and diagnostics; commands/standing instructions similarly cross HUD signal names, `orders_zones.gd` and bee state. | Adding bee bread, a conversion, or a resource-specific UI/readout will require several coordinated edits and can silently omit a save or display path. | Introduce a small `resources.gd` catalogue first (stable key, label, colour, capacity/energy semantics, save policy). Treat commands as a later catalogue only after their current semantics are documented. |
| P1 | Challenge data, tutorial prose, unlocks and some rules live in the 958-line coordinator. | `challenge_runner.gd` contains `STAGES_1`, `STAGES_2`, target constants, UI unlock payloads, prompt copy, scenario setup and goal-specific branches. | Challenge 3 will make one file an editing hotspot and couple new data to runner logic. | Extract Challenge definitions into data-only tables keyed by challenge/stage. Keep the runner as an interpreter and retain goal predicates as named functions until events replace polling. |
| P1 | The cell index is rebuilt once per frame rather than when a relevant cell changes. | `hive.gd::_content_index()` rebuilds all buckets on first query each frame and `invalidate_index()` only forces another same-frame rebuild. | Multiple callers are protected from per-bee scans, but an unchanged 200-cell comb still pays a full bucket pass every frame in which any query occurs. | Make index invalidation mutation-owned: cell content/build/ripeness/close/designation changes mark only affected indexes dirty. Benchmark the baseline before accepting it; preserve a debug verification rebuild. |
| P1 | Several derived player readouts rescan bees/cells on a one-second poll. | `year_winter.gd::_refresh_signals()` and `_refresh_panels()` traverse bee/cell collections, compute role/energy/brood summaries, then refresh panels. | This is currently bounded and already throttled, but it duplicates existing `Hive`/role information and scales with colony size even when no interested view is open. | Publish a `ColonySnapshot`/derived-stat dirty value after relevant mutations. Recompute only requested snapshots; panels pull the latest one. Keep a one-second fallback while migrating. |
| P1 | Open HUD popups are rebuilt every frame. | `hud.gd::_process()` calls `_refresh_cell_popup`, `_refresh_flower_summary` or `_refresh_selection_text` every frame while their panel is visible. | Label text, button states and formatting can be repeated even when selection and state are unchanged. | Track selection identity plus a monotonic state revision; refresh only when either changes, with explicitly time-sensitive fields on a modest cadence. |
| P1 | Active Challenge goal checking polls every rendered frame. | `challenge_runner.gd::_process()` calls `_goal_met()` each frame; predicates include role recounts, cell loops and group-size queries. | Cost is small now but becomes a cadence and coupling trap as stages/conditions grow. | Give each goal an evaluation policy: event-driven where a mutation already emits a signal, 4–10 Hz for time/position predicates, and disabled outside the active stage. Do not make all gameplay events replay-dependent. |
| P1 | `main.gd`, `bee.gd` and `hud.gd` remain broad coordinators. | They are approximately 1,125, 2,204 and 2,388 lines respectively. `main.gd` wires UI directly to several subsystems; `year_winter.gd` and `challenge_runner.gd` also reach through `main` to both simulation and panels. | A feature often crosses coordinator, node state, UI and Challenge logic at once; dependency direction is informal. | Preserve the recent helper-module approach. Define narrow service interfaces (orders, availability, colony snapshot, feedback) before moving further functions. Avoid a mechanical file split with no new boundary. |
| P2 | The season boundary is mostly healthy but winter initiation/presentation is mixed. | `season.gd` owns disease/winter simulation; `year_winter.gd` owns forecast, history and messages, but `begin_winter_countdown()` changes `Session` state, opens a panel and writes a warning together. | A new adverse condition risks duplicating simulation, forecast and UI rules. | Keep the simulation in `season.gd`; move a non-visual `WinterPlan`/forecast command behind it and let `year_winter.gd` only render/announce resulting events. |
| P2 | Save versioning detects incompatibility but has no migration registry. | `save_game.gd` has `FORMAT_VERSION := 3` and only warns for older versions; save fields are manually enumerated and enums persist as integers. | Iteration on catalogues/availability can leave an old save partially interpreted rather than deterministically migrated. | Add ordered migration functions keyed by source version before schema-affecting work. Persist stable string keys where feasible; retain append-only integers only for legacy compatibility. |
| P2 | Event contracts are local, not a named domain boundary. | Godot signals exist for storage, season and UI intent, but systems frequently read each other's fields through `main` and group lookups. | The useful events (`CellFilled`, `BeeDied`, `DayChanged`, `RainStarted`, `ChallengeStageCleared`) cannot yet be audited for emitter/listener/persistence semantics. | Create a small domain-event vocabulary during slices that need it. Events should notify views/derived caches; save/load must rebuild state directly, not replay events. |
| P2 | The rival hive does a full flower scan once a second while enabled. | `rival_hive.gd::_local_forage_richness()` iterates all flowers; its visible target picker deliberately samples 12 candidates. | The scan is gated by a currently optional feature and once-per-second cadence, so it is not a first target; it will grow with meadow size. | When a profiler shows it matters, query the existing flower grid or maintain a local aggregate. Do not optimise it pre-emptively. |
| P2 | Some full scans are appropriate and should stay. | Saves/loads, diagnostics, selection actions, one-second season work and the fallback flower search use collection scans; obstacle count is explicitly tiny. | Blanket indexing would add invalidation bugs and make code harder to reason about. | Index only queries on a hot path, called by many entities, or shown by Perf. Keep save/load and diagnostic scans simple. |

## Audit by requested dimension

### Repeatable structs with parameters

Present: role entries, flower species, challenge stages/prompts, resource
semantics, availability rules, warning/toast data, diagnostic names and save
schema rules all have repeated record-like shapes. `roles.gd` and
`flower_species.gd` are good table-shaped precedents. Challenges are still
authored in their runner; resources, availability and feedback do not yet have
one equivalent authority. Godot dictionaries are the right immediate form;
only promote a repeated shape to a `Resource` after three independent
consumers need editor-facing validation/authoring.

### Scattered systems and misplaced functions

Present: availability spans configuration, prerequisites, levels, stage gate
and UI filtering; winter countdown combines domain state and UI; challenge
definitions are embedded in their executor; derived colony data is split
between `Hive`, `main` and `year_winter`. The correct direction is
data/catalogue -> simulation service -> coordinator/controller -> view. The
present system contains useful exceptions, but those exceptions should be
named interfaces rather than direct `main` reach-through.

### Full-set scans, indexes and dirty state

Already addressed: flower choice has a spatial grid, mining has an epoch, and
the hive has a per-frame content index. Remaining candidate work is the cell
index's frame-wide rebuild and the one-second derived colony/panel scan. The
first likely spatial follow-up is rival foraging, only if measured. Scans on
save/load, explicit selection and diagnostics are deliberately low priority.

### Cadence and unnecessary work

Strong existing policies: movement stays per frame; bee decisions are
staggered; flowers/cell presentation is throttled; season and rival simulation
tick once per second; headless mode skips presentation. Candidates to make
explicit are Challenge goal checks and HUD popup refreshes. Weather has a
feature/level guard, predator work has a feature guard, and hidden
cell/flower presentation exits early; retain those gates as acceptance
criteria.

### ECS suitability

Do not convert Meadow to a general ECS. The current node/behaviour approach is
well suited to the small, visual simulation and existing saved-object model.
Use ECS-shaped *queries* where they pay: indexed bee cohorts, cell-content
sets, flower spatial buckets, and temporary status predicates. Keep Bee as a
facade/owner for identity, presentation and persistence; move only separable
data such as load, energy, navigation and transient status behind clear
accessors when a measured feature needs cohort iteration.

### Persistence, dependency direction and validation

The save format is versioned, but needs ordered migrations before new
catalogues/schema. Role/state integer ordering remains append-only until a
careful migration establishes string-key storage. `Perf` and the headless
baseline are the right verification route: compare the same seed and fixed
FPS, measure named spans, and add source/unit tests for catalogue completeness
and index invalidation. Do not claim an FPS gain from this static audit.

## Decisions requested from Dave

1. **Availability scope:** approve a single query module for all mechanic
   availability (recommended), or limit the first pass to settings
   prerequisites and Challenge/UI gates.
2. **Resource authority:** approve a dictionary catalogue now with stable keys
   and explicit save policy (recommended), or defer resource consolidation
   until bee bread/another resource is selected.
3. **Challenge authoring:** move only Challenge 3 into a definition table and
   migrate old Challenges later (recommended), or first extract Challenges 1
   and 2 as a no-behaviour-change refactor.
4. **Runtime target:** prioritise derived colony/HUD dirty refreshes
   (recommended), cell-index dirty invalidation, or wait for a new Perf
   capture to rank them.
5. **ECS boundary:** approve no broad ECS rewrite and permit only
   component-like indexes behind current node APIs (recommended), or request a
   separately scoped prototype first.
6. **Save policy:** require migration coverage before any new persisted
   catalogue/availability field (recommended), or accept a temporary
   incompatible-development-save policy.

## Non-goals and guardrails

- No broad rewrite of `bee.gd`, `main.gd`, or `hud.gd` solely to reduce line
  count.
- No spatial index for the small obstacle set; no speculative A* replacement.
- No change to simulation frequency/off-screen fidelity without a comparable
  fixed-FPS measurement and a no-outcome-change check.
- No event bus that hides ownership. Events must have typed/named payloads,
  defined listeners and direct save/load reconstruction.
- Do not change existing uncommitted work in `FORAGING_ECOLOGY_PLAN.md`,
  `FUNCTION_MAP.md`, `HANDS_ON_CHECKS.md`, `scripts/bee.gd`,
  `scripts/bee_foraging.gd` or `scripts/game_config.gd`.

## Evidence and validation baseline

- Runtime instrumentation and investigation rules: `docs/performance.md`.
- Comparable performance fixture: `docs/PERFORMANCE_BASELINE.md` and
  `test_scenarios/recommendation_slice0_baseline.json`.
- Headless execution contract: `docs/headless-run-contract.md`.
- Existing tested optimisations include flower spatial lookup, miner work epoch,
  hidden/throttled cell/flower presentation and the per-frame Hive index.

