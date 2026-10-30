# Meadow System Architecture, File Organisation and Context Strategy Report

Status: historical advisory report | Author: Jules / AI Engineering | Date: 24 Oct 2026
Audited snapshot: `599d7ff616e37dbd0102224aa5efc5201c98c2c3` (the report commit's parent, 24 Oct 2026). This report describes that snapshot, not current master. Architectural descriptions and recommendations are Jules' assessment; they do not establish ownership boundaries or approve changes to architecture, routing, or policy. Follow the current project entry points and queued plans.

Target Audience: Claude Code, Codex, LLM subagents, and human maintainers

---

## 1. Executive Summary & Purpose

This report provides a comprehensive review of Meadow's game organisation, file structure, subsystem boundaries, GDScript / Godot 4 standards compliance, and AI agent context management strategy.

As Meadow is developed collaboratively with AI models (Claude Code, Codex, and lower-reasoning worker subagents), providing clear, token-efficient system context is vital. This report evaluates the current codebase against game development and GDScript disciplinary standards, assesses existing documentation tools (`GAME_MODEL.md`, `FUNCTION_MAP.md`, `CLAUDE.md`), and outlines actionable recommendations for system summaries and "Where to Look / Where NOT to Look" boundaries.

---

## 2. Current Codebase Organisation & File Structure

Meadow operates as a Godot 4.7 simulation targeting a single scene (`scenes/Main.tscn`) backed by ~80 GDScript files in `scripts/`.

### 2.1 File System Topography

- **`scenes/`**: Contains only `scenes/Main.tscn`. All UI elements, HUD panels, popups, and buttons are constructed dynamically via GDScript rather than Godot `.tscn` visual scene compositions.
- **`scripts/`**: A flat directory containing all GDScript files except `scripts/headless/`.
  - *Strengths:* Flat structures eliminate deeply nested relative import paths (`res://` paths remain short) and prevent GDScript cyclic preloading dependencies.
  - *Weaknesses:* Browsing 80+ root-level `.gd` files without subdirectory categorization (`scripts/bees/`, `scripts/ui/`, `scripts/hive/`) relies entirely on file naming conventions or external indexes (`FUNCTION_MAP.md`).
- **`docs/`**: Rich architectural reviews, performance contracts, and system guidelines (`docs/agent-rules.md`, `docs/known-pitfalls.md`, `docs/headless-run-contract.md`).
- **`plans/`**: Structured planning and workstream tracking (`plans/now/`, `plans/design/`, `plans/reference/`, `plans/archive/`).

### 2.2 Subsystem Architectural Boundaries

Meadow categorises code into three architectural tier roles defined in `GAME_MODEL.md`:

1. **Coordinator (`main.gd`)**:
   - Holds the per-frame entry point (`_process`), world boot, and run lifecycle.
   - Delegates domain responsibilities to Controllers and Services.
2. **Controllers (`world_building.gd`, `input_selection.gd`, `camera_view.gd`, `orders_zones.gd`, `saving.gd`)**:
   - Single-instance Node children of `main.gd` managing domain state (e.g. soil/world setup, user selections, camera navigation, zone designations).
3. **Services (`bee_foraging.gd`, `bee_nursery.gd`, `bee_building.gd`, `bee_mining.gd`, `bee_honey.gd`, `bee_survival.gd`, `bee_egg_laying.gd`, `bee_movement.gd`)**:
   - Stateless `extends RefCounted` classes containing static functions that operate on bee instances passed as arguments. This design keeps memory footprints minimal when simulating hundreds of bees simultaneously.

---

## 3. Detailed Audit of Game Systems & Subsystems

### 3.1 Bee Roles, Behaviour & State Machine (`bee.gd`, `roles.gd`, `bee_*.gd`)
- **Intention:** Governs bee dispatch loops, state transitions, movement, survival, and role execution.
- **Related Systems:** `roles.gd` (single source of truth for role definitions), `hive.gd` (cell lookups), `game_config.gd` (stats/balance).
- **Inputs:** Role assignments, fallback roles (`secondary_role`), work modes, player commands, world state.
- **Outputs:** Physical movement, resource deposits, egg laying, comb building, mining progress.
- **Disciplinary Compliance:** High. Using stateless `RefCounted` service scripts for role logic prevents Godot Node instantiation bloat for high bee populations.

### 3.2 Hive, Comb & Grid Management (`hive.gd`, `hive_cell.gd`, `orders_zones.gd`)
- **Intention:** Manages hexagonal comb layout, cell content storage, brood incubation, and indoor navigation paths.
- **Related Systems:** `spatial_grid.gd` (world indexing), `roles.gd` (work dispatch), `saving.gd` (comb persistence).
- **Inputs:** Cell designations, resource deposits, fanning/cleaning progress, brood feeds.
- **Outputs:** Resource levels (nectar, pollen, honey, royal jelly), hatched bees, clear comb sites.
- **Disciplinary Compliance:** Excellent performance patterns. Uses invalidation epochs (`bump_display_epoch`, `_invalidate_stock`, `_invalidate_hive_index`) to eliminate costly per-frame grid recalculations.

### 3.3 Ecology, Weather & Meadow (`flower.gd`, `flower_species.gd`, `season.gd`, `year_winter.gd`, `spatial_grid.gd`, `crab_spider.gd`)
- **Intention:** Simulates the natural environment, flowering windows, weather transitions, predation, and seasonal winter pressure.
- **Related Systems:** `bee_foraging.gd` (flower visits), `hud.gd` (weather readouts), `game_config.gd` (flowering schedules).
- **Inputs:** Simulation time delta, seasonal progression, weather conditions (rain, temperature).
- **Outputs:** Nectar/pollen availability, forager hazards (crab spider attacks), winter food consumption.
- **Disciplinary Compliance:** Strong decoupling of static species configuration (`flower_species.gd`) from node runtime instances (`flower.gd`).

### 3.4 UI, HUD & Presentation (`hud.gd`, `debug_panel.gd`, `*_panel.gd`, `ui_theme.gd`, `guidance_policy.gd`)
- **Intention:** Renders corner readouts, selection panels, command trays, popups, and settings window.
- **Related Systems:** `Session` (interface state), `GameConfig` (tuning rows), `input_selection.gd` (selection triggers).
- **Inputs:** Colony metrics, selected entities, user UI clicks.
- **Outputs:** Visual panels, tooltips, warnings, mode toggles.
- **Disciplinary Compliance:** Good visual consistency using `ui_theme.gd` and dynamic control styling. However, `hud.gd` (4,069 lines) represents a major monolithic hotspot.

### 3.5 Persistence & Save System (`saving.gd`, `save_game.gd`, `save_migrations.gd`, `settings_catalogue.gd`)
- **Intention:** Serialises run state, colony metrics, comb layout, and user preferences to disk.
- **Related Systems:** All persistent game systems, `GameConfig` allowlist.
- **Inputs:** Live run state (`main.gd`, `hive.gd`, `bee.gd`).
- **Outputs:** Serialised JSON save files; restored game state on load.
- **Disciplinary Compliance:** High resilience. Explicit dictionary conversion functions (`to_dict` / `from_dict`) and explicit migration steps prevent GDScript property renames from corrupting existing saves.

### 3.6 Scenarios, Challenges & Headless Verification (`challenge_runner.gd`, `challenge_stages.gd`, `scenario_actions.gd`)
- **Intention:** Executes guided tutorial/challenge levels and automated headless simulation/assertion suites.
- **Related Systems:** `main.gd`, `hud.gd` (goal readouts), `diagnostic_log.gd`.
- **Inputs:** Scenario definitions, headless script actions (`when` triggers and layout assertions).
- **Outputs:** Challenge stage progress, headless pass/fail logs.
- **Disciplinary Compliance:** Industry-leading AI verification capability. Allows headless verification of layout and gameplay rules without launching a visual window.

---

## 4. Alignment with Disciplinary Standards

| Category | Standard / Best Practice | Meadow Implementation Standing |
| --- | --- | --- |
| **GDScript Type Safety** | Mandatory static typing (`var x: int`, `func f() -> void`) | **Excellent.** Enforced via `project.godot` warning (`untyped_declaration=1`) and `source_checks.py`. |
| **Simulation / Presentation Separation** | Visuals must never gate or alter simulation outcomes | **Strictly Adhered.** Off-screen bees/cells simulate identically to on-screen ones. Presentation loops check `is_on_screen`. |
| **Single Source of Truth** | Role, setting, and prerequisite definitions defined in dedicated data files | **Excellent.** `roles.gd` owns role IDs/labels; `settings_catalogue.gd` owns tunables; `prerequisites.gd` owns dependencies. |
| **Godot Autoload Usage** | Limit singletons to global session/config state | **Compliant.** Autoloads restricted to `GameConfig`, `Session`, `Perf`, `DiagnosticLog`, and helper tooling. |
| **Scene Compositions vs GDScript UI** | Standard Godot practice uses `.tscn` visual scenes for UI composition | **Divergent by Design.** Meadow constructs all UI in GDScript for fast loading and zero `.tscn` path-breakage risk. |
| **File Hierarchy** | Grouping scripts into subsystem folders | **Opportunity for Improvement.** Flat `scripts/` folder relies on prefixes (`bee_*`, `ui_*`, `colony_*`). |

---

## 5. Token-Efficient Context & System Summary Strategy

### 5.1 The Token Burden Challenge for LLM Agents
When an LLM agent (especially lower-reasoning models or those with tight context limits) works on Meadow:
1. Scanning entire files over 1,000 lines (e.g. `hud.gd`, `bee.gd`, `hive.gd`, `scenario_actions.gd`) consumes tens of thousands of tokens per turn.
2. Unclear system boundaries lead agents to edit the wrong layer (e.g. modifying simulation logic inside UI panels or balance values directly inside behaviour scripts).

### 5.2 The 9-Part System Template Solution
`GAME_MODEL.md` established the 9-part system template:
1. **Definition** — Core purpose of the system.
2. **Input** — Data sources, player commands, world parameters read.
3. **Evaluation** — Decision logic and state machine flow.
4. **Output** — State mutations, resource transfers, entity spawns.
5. **Connection** — Interfacing systems and state ownership bounds.
6. **Presentation** — Visuals, UI panels, labels (isolated from simulation).
7. **Availability** — Stage gates, prerequisites, lock states.
8. **Persistence** — Fields saved/restored vs fields rederived on load.
9. **Observability** — Debug readouts, `Perf` markers, `DiagnosticLog` events.

### 5.3 Boundary Guidance: "Where to Look" vs "Where NOT to Look"

To maximize agent efficiency, every system overview must explicitly provide negative boundaries ("Where NOT to Look"):

```
+-------------------------------------------------------------------------------+
| System: Bee Foraging                                                          |
+-------------------------------------------------------------------------------+
| WHERE TO LOOK:                                                                |
| - Search & flight logic: scripts/bee_foraging.gd                             |
| - Forager entity state & state machine: scripts/bee.gd                        |
| - Flower positions & resource levels: scripts/spatial_grid.gd, flower.gd      |
| - Entrance mentors & cell deposits: scripts/hive.gd                           |
|                                                                               |
| WHERE NOT TO LOOK:                                                            |
| - Nectar/pollen capacity & rates tuning: DO NOT edit bee_foraging.gd!        |
|   Edit scripts/game_config.gd instead.                                        |
| - Role names, colours, or UI icons: DO NOT edit bee_foraging.gd!              |
|   Edit scripts/roles.gd or scripts/ui_theme.gd.                               |
| - Foraging UI stats panel layout: DO NOT edit bee_foraging.gd!                |
|   Edit scripts/foraging_panel.gd or scripts/hud.gd.                            |
| - Save/restore field serialization: DO NOT edit bee_foraging.gd!              |
|   Edit scripts/saving.gd / scripts/save_game.gd.                             |
+-------------------------------------------------------------------------------+
```

---

## 6. Opportunities for Improvement

### 6.1 Documentation & System Summaries
1. **Complete 9-Part Cards for All Core Systems**:
   Expand `GAME_MODEL.md` to feature 9-part cards for remaining major systems:
   - Nursery & Brood Raising (`bee_nursery.gd`, `hive_cell.gd`)
   - Comb Construction & Mining (`bee_building.gd`, `bee_mining.gd`, `hive.gd`)
   - Weather & Seasons (`season.gd`, `year_winter.gd`, `flower_species.gd`)
   - Challenge Stage Machine & Gating (`challenge_runner.gd`, `stage_gate.gd`)
   - Save / Load & Migration Pipeline (`saving.gd`, `save_game.gd`)

2. **Integrate "Where NOT to Look" Rules into `.claude/rules/`**:
   Add explicit boundary rules to path-scoped rule files so lower-reasoning models automatically receive boundary guardrails when opening specific files.

### 6.2 Code Organisation & Refactoring
1. **Subsystem Folder Structure (Long-Term)**:
   While maintaining GDScript preloading safety, consider grouping `scripts/` into logically named subdirectories (`scripts/bee/`, `scripts/hive/`, `scripts/ui/`, `scripts/environment/`, `scripts/catalogues/`).
2. **Decouple Hotspot Files**:
   - `hud.gd` (4,069 lines): Continue delegating panel-specific UI creation out of `hud.gd` into individual `*_panel.gd` files.
   - `bee.gd` (3,179 lines): Ensure task descriptions and display text helpers are delegated where appropriate.

---

## 7. Conclusion

Meadow possesses a clear, disciplined architecture built around the Coordinator-Controller-Service pattern and strict simulation/presentation separation. By expanding the 9-part system template summaries and formalising "Where NOT to Look" boundary instructions in agent routing documentation, LLM subagents and Claude Code can navigate and modify the codebase with maximum precision and minimal token overhead.
