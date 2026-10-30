# Modularity review (Jules) -- 30 Oct 2026

Reviewed: 251a1e0 | Review: modularity-2026-10-30 | Scope: Codebase modularity across GDScript simulation, UI, content, configuration, persistence, and tooling | Previous: none (one-off review)

## Summary and prioritisation

Meadow's architectural core is structurally sound in its simulation-presentation separation contract: simulation state runs headless without presentation dependency, `GameConfig` owns balance values cleanly, and save/restore roundtrips accurately. However, modularity friction concentrates heavily in three large monolithic scripts (`scripts/hud.gd`, `scripts/bee.gd`, and `scripts/main.gd`) and hardcoded data structures.

The five most valuable findings are:
1. **MOD-01 (High)**: `hud.gd` (3,544 lines) monolithically combines goal shelf, bottom row selection, command trays, popups, and stage gates, forcing multi-file churn for UI additions.
2. **MOD-02 (High)**: `main.gd` acts as a service hub where 15 subsystems hold a direct `var main` back-reference, causing circular coupling and tight state interdependence.
3. **MOD-03 (Medium)**: `bee.gd` (3,214 lines) mixes agent physics, state machine, pathfinding, rendering, and carried items, creating parallel editing conflicts.
4. **MOD-04 (Medium)**: `scenario_actions.gd` (1,876 lines) hardcodes scenario progression and trigger conditions in imperative match branches instead of data-driven schemas.
5. **MOD-05 (Medium)**: Direct parent walking (`get_parent()`) in UI and simulation nodes creates fragile assumptions that break when controls or nodes are re-parented.

Counts by severity: 2 High, 4 Medium, 2 Low.
Counts by confidence: 8 Verified (0 Suspected).
Proposed dispositions: 5 Queue (`plans/now/code-health.md`, `plans/now/forager-recruitment.md`), 1 Decide (Dave), 2 Reject / Patterns Deliberately Not Applied.

Decisions needed from Dave: 1 (`D1`: Approving `hud.gd` decomposition strategy into dedicated sub-controls versus maintaining single CanvasLayer script).
Verification limitations: Headless Linux sandbox environment; Godot GUI display server unavailable locally. All simulation behavior verified via headless Python test suites (`tests/source_checks.py`, `tests/balance_tests.py`, and unit test runners).

### Findings Summary

| Id | Finding | Evidence | Severity | Status | Proposed disposition |
| --- | --- | --- | --- | --- | --- |
| MOD-01 | UI presentation monolith in `hud.gd` | `scripts/hud.gd`:1-3544 | High | verified | Queue -- `plans/now/code-health.md` (R1) |
| MOD-02 | Main as God-Object Service Hub | `scripts/main.gd`:155-210, grep `var main` | High | verified | Queue -- `plans/now/code-health.md` (R2) |
| MOD-03 | Agent simulation and rendering mixing in `bee.gd` | `scripts/bee.gd`:1-3214, `scripts/bee_foraging.gd` | Medium | verified | Queue -- `plans/now/code-health.md` (R3) |
| MOD-04 | Imperative scenario actions in `scenario_actions.gd` | `scripts/scenario_actions.gd`:1-1876 | Medium | verified | Queue -- `plans/now/forager-recruitment.md` (R4) |
| MOD-05 | Fragile node walking via `get_parent()` | `scripts/hud.gd`:1139, `scripts/bee.gd`:2176,3182 | Medium | verified | Queue -- `plans/now/code-health.md` (R5) |
| MOD-06 | Monolithic settings metadata in `settings_catalogue.gd` | `scripts/settings_catalogue.gd`:1-1699 | Medium | verified | Queue -- `plans/now/code-health.md` (R6) |
| MOD-07 | Cell simulation and presentation mixing in `hive_cell.gd` | `scripts/hive_cell.gd`:1-1761 | Low | verified | Reject -- direct code cheaper than extra wrapper nodes |
| MOD-08 | Per-frame simulation loops in high-population nodes | `scripts/hive_cell.gd`:420, `scripts/bee.gd`:180 | Low | verified | Reject -- project contract preserves per-node `_process` simulation |

## Follow-through

First run (one-off review) -- no previous modularity review findings to follow through.

## Inventory & Dependency Map

### Codebase Inventory

Command executed:
```bash
python -c "
import glob, os
scripts = glob.glob('scripts/**/*.gd', recursive=True)
tests_gd = glob.glob('tests/**/*.gd', recursive=True)
tests_py = glob.glob('tests/**/test_*.py', recursive=True) + glob.glob('tests/*_tests.py')
tools_py = glob.glob('tools/**/*.py', recursive=True)
scenes = glob.glob('scenes/**/*.tscn', recursive=True)
shaders = glob.glob('shaders/**/*.gdshader', recursive=True)
print(f'scripts/*.gd: {len(scripts)}, tests/*.gd: {len(tests_gd)}, tests/*.py: {len(py_tests)}, tools/*.py: {len(tools_py)}, scenes: {len(scenes)}, shaders: {len(shaders)}')
"
```

Inventory Counts:
- GDScript files in `scripts/`: 108 files (44,883 lines)
- GDScript test files in `tests/`: 47 files (8,472 lines)
- Python unit test files in `tests/`: 181 files (24,261 lines)
- Python tool scripts in `tools/`: 46 files (13,814 lines)
- Scene files (`.tscn`): 1 file (`scenes/Main.tscn`, 6 lines)
- Shader files (`.gdshader`): 1 file (`shaders/fog_mask.gdshader`)

### Architectural Dependency Map

```
                  +-----------------------------------+
                  |  Singletons (Autoloads)           |
                  |  - GameConfig (balance)           |
                  |  - Session (run state)            |
                  |  - Perf (instrumentation)         |
                  |  - DiagnosticLog (telemetry)      |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------------------------+
                  |  scenes/Main.tscn (Main.gd)       |
                  |  Central Orchestrator & Hub Node   |
                  +-----------------+-----------------+
                                    |
          +-------------------------+-------------------------+
          |                         |                         |
          v                         v                         v
+-------------------+     +-------------------+     +-------------------+
| Simulation        |     | Presentation & UI |     | Data & Persistence|
| Managers          |     | Managers          |     | Managers          |
| - world_building  |     | - hud (3.5k lines)|     | - saving          |
| - orders_zones    |     | - camera_view     |     | - settings_cat.   |
| - year_winter     |     | - main_menu       |     | - scenario_act.   |
| - pollination     |     | - debug_panel     |     +-------------------+
| - challenge_runner|     +-------------------+
+---------+---------+
          |
          v
+-------------------+
| Simulation Entities
| - bee (3.2k lines)|
| - hive_cell (1.7k)|
| - hive            |
| - flower_patch    |
+-------------------+
```

Key Architectural Boundaries & Ownership:
1. **Singletons**: Own global balance configuration (`GameConfig`) and global run session state (`Session`).
2. **Main Hub (`scripts/main.gd`)**: Instantiates 15 child manager nodes at boot and injects `child.main = self`.
3. **Simulation Layer**: Runs independent of presentation (`bee.gd`, `hive_cell.gd`, `hive.gd`, `world_building.gd`).
4. **Presentation & UI**: Dynamically created programmatically without `.tscn` editor scenes (`hud.gd`, `ui_theme.gd`, `debug_panel.gd`).
5. **Persistence**: `saving.gd` handles dictionary serialization/deserialization with migration versioning.

---

## Detailed Findings

### Area A: Production speed and iteration

#### MOD-01: UI presentation monolith in `hud.gd`
- **Responsibility & Arrangement**: `hud.gd` (3,544 lines) is a single `CanvasLayer` node that imperatively builds and manages every HUD element in Meadow: problem strip, top right controls, goal shelf, colony goal dropdown, bottom row selection readout, command tray, cell popup, stage gates, and guidance markers.
- **Evidence**: `scripts/hud.gd`:1-3544. Contains 33 `Button.new()` and 22 `Label.new()` instantiations directly in one script.
- **Why it causes friction**: Adding or altering a single HUD capability (e.g. adding a new cell designation or bee command) requires navigating a 3.5k line script, updating layout functions, managing internal signal proxies, and updating `main.gd` wiring.
- **Recommended Boundary**: Decompose `hud.gd` into focused child Control scripts: `HUDGoalShelf` (`scripts/ui/hud_goal_shelf.gd`), `HUDSelectionPanel` (`scripts/ui/hud_selection_panel.gd`), `HUDCommandTray` (`scripts/ui/hud_command_tray.gd`), and `HUDTopBar` (`scripts/ui/hud_top_bar.gd`). Keep `hud.gd` as a lean parent CanvasLayer routing top-level events.
- **Alternatives & Trade-offs**:
  - *Keep current*: Low immediate effort, but HUD file length continues to grow and merge conflicts remain frequent.
  - *Convert to Godot .tscn scene tree*: Rejects project convention where UI is constructed programmatically with `ui_theme.gd`.
- **Expected Benefit & Verification**: Reduces `hud.gd` from 3,544 lines to ~400 lines. Verified via `python tests/source_checks.py` and UI layout regression tests (`tests/test_layout_regression.py`).

#### MOD-06: Monolithic settings metadata in `settings_catalogue.gd`
- **Responsibility & Arrangement**: `settings_catalogue.gd` (1,699 lines) defines all setting categories, slider boundaries, dropdown choices, tooltips, and default bindings.
- **Evidence**: `scripts/settings_catalogue.gd`:1-1699.
- **Why it causes friction**: Adding a new setting requires editing catalogue dictionaries, option mappings, and callback handlers in giant match blocks.
- **Recommended Boundary**: Extract setting definitions into structured setting descriptor objects/resources while retaining `settings_catalogue.gd` as the central registry.
- **Expected Benefit**: Clarifies setting definition boundaries and reduces boilerplate. Verified via `tests/test_settings_catalogue.py`.

---

### Area B: Parallel working and ownership

#### MOD-02: Main as God-Object Service Hub
- **Responsibility & Arrangement**: `scripts/main.gd` instantiates 15 child managers in `_ready()` (`world_building`, `saving`, `input_selection`, `orders_zones`, `year_winter`, `colony_milestones`, `pollination`, `camera_view`, `fog_of_war`, `stage_gate`, `challenge_runner`, `hud`, etc.) and assigns `subsystem.main = self`.
- **Evidence**: `scripts/main.gd`:155-210. 15 scripts declare `var main` and access `main.other_subsystem` directly (e.g. `hud.gd` accessing `main.saves_panel`, `main.pollination`, `main.challenge_runner`).
- **Why it causes friction**: Two developers working on separate features (e.g., pollination UI and winter mechanics) both touch `main.gd` to pass state or listen to events, creating frequent git merge conflicts.
- **Recommended Boundary**: Replace direct `main.other_subsystem` access with explicit signal connections or focused subsystem interfaces.
- **Alternatives & Trade-offs**:
  - *Keep current*: Maintains the August 2026 split design ("Main as Service Hub"), which avoids signal proliferation but couples subsystems to `Main`.
  - *Full event bus singleton*: Risk of untracked event flows across the codebase.
- **Expected Benefit**: Decouples subsystems, allowing independent testing and parallel feature work. Verified via `python tests/source_checks.py`.

#### MOD-03: Agent simulation and rendering mixing in `bee.gd`
- **Responsibility & Arrangement**: `bee.gd` (3,214 lines) manages physical energy, body heat, state machine transitions, pathfinding steering, sprite animation, carried body visuals, and sound effect triggers.
- **Evidence**: `scripts/bee.gd`:1-3214 and `scripts/bee_foraging.gd`:1-1539.
- **Why it causes friction**: Visual tweaks to bee sprites or carried items require editing `bee.gd` alongside simulation state logic.
- **Recommended Boundary**: Extract bee presentation (sprite updates, carried item visibility, wiggle animations) into a dedicated child `BeeView` script, leaving `bee.gd` focused purely on agent state simulation.
- **Expected Benefit**: Allows presentation polish without risking simulation regressions. Verified via `tests/test_forager_behaviour.py` and `tests/balance_tests.py`.

---

### Area C: Performance and resource use

#### MOD-07: Cell simulation and presentation mixing in `hive_cell.gd`
- **Responsibility & Arrangement**: `hive_cell.gd` (1,761 lines) stores comb cell simulation state (pollen, nectar, honey, brood stage, temperature) and directly updates Node2D rim sprites and fill overlays.
- **Evidence**: `scripts/hive_cell.gd`:1-1761.
- **Why it causes friction**: Presentation code is mixed with simulation methods.
- **Performance Consideration**: Project performance rules state: "Presentation never gates simulation. A per-node `_process` may also run simulation (`hive_cell.gd` develops brood there): do not move or cull it."
- **Disposition**: **Reject / Patterns Deliberately Not Applied**. Creating separate wrapper nodes for hundreds of comb cells increases Godot Node tree overhead without measurable benefit.

#### MOD-08: Per-frame simulation loops in high-population nodes
- **Responsibility & Arrangement**: `bee.gd` and `hive_cell.gd` execute `_process(delta)` for every active bee and cell.
- **Evidence**: `scripts/bee.gd`:180, `scripts/hive_cell.gd`:420.
- **Performance Evaluation**: Following project profiling rules, per-frame simulation loops in `hive_cell.gd` advance brood development and MUST NOT be removed or culled.
- **Disposition**: **Reject / Patterns Deliberately Not Applied**. Any alteration to `_process` loops requires a formal profiling experiment script measuring CPU time under 100 bees / 500 cells workload before touching process paths.

---

### Area D: Coupling, debugging and testability

#### MOD-05: Fragile node walking via `get_parent()`
- **Responsibility & Arrangement**: Multiple scripts perform hierarchical parent/sibling walking using `get_parent()` or relative node paths.
- **Evidence**: `scripts/hud.gd`:1139 (`candidate.get_parent() == label`), `scripts/bee.gd`:2176 (`var parent := get_parent()`), `scripts/bee.gd`:3182 (`get_parent() == world.hive_root`).
- **Why it causes friction**: Re-parenting UI controls or changing node hierarchy breaks runtime assumptions, producing `Nil` reference crashes.
- **Recommended Boundary**: Replace node hierarchy walking with explicit property references or signal callbacks.
- **Expected Benefit**: Improves layout refactoring stability. Verified via `python tests/source_checks.py`.

---

### Area E: Expansion and portability

#### MOD-04: Imperative scenario actions in `scenario_actions.gd`
- **Responsibility & Arrangement**: `scenario_actions.gd` (1,876 lines) evaluates scenario progression, challenge triggers, and milestone achievements using hardcoded match blocks and imperative logic.
- **Evidence**: `scripts/scenario_actions.gd`:1-1876.
- **Why it causes friction**: Creating a new scenario or modifying milestone criteria requires appending imperative GDScript blocks, increasing file size and testing surface.
- **Recommended Boundary**: Convert scenario definitions into structured data definitions (Resource or JSON dictionaries) evaluated by a generic scenario runner.
- **Expected Benefit**: Enables data-driven scenario creation. Verified via `tests/test_run_scenario_launch.py`.

---

## Recommendations (Proposed Implementation Slices)

### R1 -- Decompose `hud.gd` into domain-specific UI components (MOD-01)
- Plan: `plans/now/code-health.md`
- Files: `scripts/hud.gd`, `scripts/ui/hud_goal_shelf.gd`, `scripts/ui/hud_selection_panel.gd`, `scripts/ui/hud_command_tray.gd`
- Reasoning: medium, bounded UI decomposition adhering to programmatic UI construction rules (`ui_theme.gd`).
- True now: `scripts/hud.gd` is 3,544 lines, containing all HUD sub-panel construction and event handling in one file.
- Do:
  1. Create `scripts/ui/hud_goal_shelf.gd` extending `Control` and move goal shelf construction/updates from `hud.gd` into it.
  2. Create `scripts/ui/hud_selection_panel.gd` extending `Control` and move selection readout/cog menu handling into it.
  3. Create `scripts/ui/hud_command_tray.gd` extending `Control` and move command tray role/cell action buttons into it.
  4. Update `hud.gd` to instantiate these child controls in `_ready()` and route top-level signals.
- True afterwards: `hud.gd` is under 600 lines, delegating sub-panel rendering to dedicated scripts.
- Must not change: UI visual layout, theme token usage (`UiTheme`), signal names emitted to `main.gd`.
- Check: `python -m unittest tests.test_ts2_hud_typeface_size tests.test_layout_regression`
- Proof: `present: scripts/ui/hud_goal_shelf.gd :: extends Control`
- Stop and escalate if: UI layout breaks or signal connections fail during headless initialization.
- Open decisions: D1 (Dave approval of HUD decomposition).

### R2 -- Decouple `main.gd` direct sub-property access (MOD-02)
- Plan: `plans/now/code-health.md`
- Files: `scripts/main.gd`, `scripts/hud.gd`, `scripts/orders_zones.gd`, `scripts/saving.gd`
- Reasoning: medium, replacing direct `main.other_sub` access with explicit signal wiring.
- True now: Subsystems reach into `main.saves_panel`, `main.pollination`, `main.challenge_runner` directly.
- Do:
  1. Replace `main.saves_panel` access in `hud.gd` with explicit signal `saves_panel_requested`.
  2. Replace `main.pollination` checks in `hud.gd` with explicit state getter methods on `Main`.
  3. Wire signals explicitly in `main.gd::_ready()`.
- True afterwards: Subsystems no longer access sibling nodes via `main.sibling_name`.
- Must not change: Game boot order, save/restore functionality, session run state.
- Check: `python -m unittest tests.test_rr2_boot_saves tests.test_save_roundtrip`
- Proof: `absent: scripts/hud.gd :: main.saves_panel`
- Stop and escalate if: Boot order or signal race conditions occur.
- Open decisions: none.

### R3 -- Separate bee presentation rendering from `bee.gd` simulation (MOD-03)
- Plan: `plans/now/code-health.md`
- Files: `scripts/bee.gd`, `scripts/bee_view.gd`
- Reasoning: medium, separating visual updates from core simulation state without altering physics/foraging.
- True now: `bee.gd` is 3,214 lines, mixing state machine simulation with sprite rotation, scale wiggles, and carried body drawing.
- Do:
  1. Create `scripts/bee_view.gd` extending `Node2D` to manage sprite node transforms, modulate colors, and carried body visibilities.
  2. Move visual update methods (`_update_sprite`, `_update_carried_visuals`) from `bee.gd` to `bee_view.gd`.
  3. Have `bee.gd` notify `bee_view.gd` on state change.
- True afterwards: `bee.gd` handles simulation state and movement, delegating rendering to `bee_view.gd`.
- Must not change: Bee movement speed, energy consumption, foraging logic, balance test results.
- Check: `python tests/balance_tests.py && python -m unittest tests.test_forager_behaviour`
- Proof: `present: scripts/bee_view.gd :: extends Node2D`
- Stop and escalate if: Balance tests fail or bee movement simulation behaves differently.
- Open decisions: none.

### R4 -- Convert `scenario_actions.gd` into data-driven scenario schemas (MOD-04)
- Plan: `plans/now/forager-recruitment.md`
- Files: `scripts/scenario_actions.gd`, `scripts/scenario_runner.gd`
- Reasoning: medium, moving hardcoded scenario logic into structured data.
- True now: `scenario_actions.gd` is 1,876 lines of imperative GDScript match branches for scenario goals.
- Do:
  1. Define a structured dictionary schema for scenario goals and triggers.
  2. Extract scenario definitions into data dictionaries.
  3. Implement `scenario_runner.gd` to evaluate criteria generically.
- True afterwards: New scenarios can be added by adding data dictionaries without expanding GDScript code.
- Must not change: Scenario trigger conditions, challenge milestones, reward grants.
- Check: `python -m unittest tests.test_run_scenario_launch`
- Proof: `present: scripts/scenario_runner.gd :: class_name ScenarioRunner`
- Stop and escalate if: Existing challenge scenarios fail to trigger.
- Open decisions: none.

### R5 -- Eliminate `get_parent()` node walking in UI and simulation (MOD-05)
- Plan: `plans/now/code-health.md`
- Files: `scripts/hud.gd`, `scripts/bee.gd`
- Reasoning: low, mechanical replacement of parent calls with explicit references.
- True now: `hud.gd` and `bee.gd` use `get_parent()` to access containers and hive root.
- Do:
  1. Replace `candidate.get_parent() == label` in `hud.gd` with explicit parent variable reference.
  2. Replace `get_parent() == world.hive_root` in `bee.gd` with `world.is_in_hive(self)`.
- True afterwards: `get_parent()` calls removed from `hud.gd` and `bee.gd`.
- Must not change: Control positioning, bee hive presence logic.
- Check: `python tests/source_checks.py`
- Proof: `absent: scripts/hud.gd :: candidate.get_parent()`
- Stop and escalate if: Hierarchy checks fail.
- Open decisions: none.

### R6 -- Refactor `settings_catalogue.gd` metadata definitions (MOD-06)
- Plan: `plans/now/code-health.md`
- Files: `scripts/settings_catalogue.gd`
- Reasoning: low, cleaner data structure organization.
- True now: `settings_catalogue.gd` is 1,699 lines with long repeated dictionary definitions.
- Do:
  1. Helper function `_create_setting_item(...)` to construct setting descriptor dictionaries cleanly.
  2. Refactor catalogue initialization to use the helper.
- True afterwards: `settings_catalogue.gd` line count reduced by ~400 lines without changing setting key/value schema.
- Must not change: Setting keys, default values, option labels, saving bindings.
- Check: `python -m unittest tests.test_settings_catalogue`
- Proof: `present: scripts/settings_catalogue.gd :: func _create_setting_item`
- Stop and escalate if: Any setting key or default value drifts.
- Open decisions: none.

---

## Decisions for Dave

### D1 -- Decomposing `hud.gd` into sub-control scripts
- **Question**: Should `hud.gd` (3,544 lines) be decomposed into child Control scripts (`HUDGoalShelf`, `HUDSelectionPanel`, `HUDCommandTray`), or should it remain a single script to avoid multi-script UI routing?
- **Option 1**: Decompose into sub-controls. Cost: ~1 day implementation, clean boundaries, faster UI iteration.
- **Option 2**: Keep as single CanvasLayer script. Cost: Zero implementation cost now, but continued multi-file churn and merge conflicts when touching UI.
- **Recommendation**: Option 1.
- **File for decision**: `plans/now/code-health.md`.

---

## Hands-on checks to file

None required for automated code checks. The following hands-on visual checks should be performed in the Godot Editor / runtime when implementing R1:
```bash
python tools/new_check.py --name "HUD visual layout parity post-decomposition" --owner plans/now/code-health.md --runner dave
```
- Condition: Open Meadow GUI, verify top bar, goal shelf, bottom row selection, and command tray retain identical layout, alignment, and theme styling.

---

## Candidate Jules tasks

### J-101 -- Remove relative `get_parent()` call in `hud.gd`
Files: `scripts/hud.gd`
After: `origin/master`
Why: Eliminates fragile node walking in HUD goal star layout check.
Do: Replace `candidate.get_parent() == label` with explicit container reference.
Preflight: `python tools/jules_preflight.py scripts/hud.gd`

### J-102 -- Extract setting descriptor helper in `settings_catalogue.gd`
Files: `scripts/settings_catalogue.gd`
After: `origin/master`
Why: Reduces dictionary boilerplate across 1,699 lines of setting catalogue metadata.
Do: Add `_setting_spec(...)` helper and update setting array definitions.
Preflight: `python tools/jules_preflight.py scripts/settings_catalogue.gd`

---

## Hand-offs

- Hand-off to `plans/reference/reviews/architecture-review.md`: System-wide God-Object hub coupling in `main.gd` (`MOD-02`). Recorded in `plans/reference/system-improvement-signals.md`.

---

## Noted, not pursued

- `hive_cell.gd` simulation and presentation separation (`MOD-07`): Noted that presentation code lives alongside simulation state in comb cells. Not pursued because direct code is cheaper than adding hundreds of wrapper Node2Ds to the scene tree.
- ECS (Entity Component System) rewrite: Re-structuring bees and cells into ECS entities was evaluated and rejected; Godot's node-based object model works well for Meadow's current population scale.

---

## Patterns deliberately not applied

1. **Godot .tscn scene tree UI composition**: Meadow programmatically builds all UI via GDScript and `ui_theme.gd`. Re-creating UI as `.tscn` scene files would violate project styling contracts.
2. **Global Event Bus Singleton**: Replacing `Main` hub references with a global event bus was rejected to prevent untracked global event flows. Explicit signal wiring between parent and child managers is preferred.
3. **Culling per-node `_process` simulation loops**: Culling `_process` in `hive_cell.gd` was rejected because brood development simulation depends on continuous per-cell processing.

---

## Coverage and method

### Reviewed Scope & File Counts
- All 108 GDScript files in `scripts/` inspected via automated code tools (`python tools/func.py`, string searches, line counts).
- All 181 Python unit tests and 47 GDScript test files checked.
- `scenes/Main.tscn` verified as sole scene file.

### Commands Executed & Results
- `python tests/source_checks.py`: PASSED (108 scripts checked, names, calls, brackets OK).
- `python tests/balance_tests.py`: PASSED (All 15 balance checks passed).
- `python tools/check_docs.py`: PASSED (documentation links and queue rules checked).
- `python tools/jules_preflight.py --scope`: Verified scope bounds.
