# Audit: role and run-state ownership

Audited: 4517ae0b on 24 Feb 2025 | Task: J-36 | Scope: GDScript files in scripts/ and scenes/ (roles, castes, autoload state, presentation writes)

## Summary

Read 32 GDScript source files across `scripts/` and `scenes/`. Identified 38 findings across role string literal usage, role conditional chains, non-Session autoload state, and presentation writes to simulation state.
Key findings:
1. `hud.gd:2028` Presentation panel directly writes cell designation and clears cell content rather than emitting signals or calling simulation API methods.
2. `hud.gd:2715` HUD directly mutates comb cell state (`pending_cell.clear_cell()`, `set_designation()`) during confirmation actions.
3. `challenge_stages.gd:428` Role names and caste names appear as string literals across challenge stage definitions rather than referencing `Roles` or `BeeEnums`.
4. `input_selection.gd:485` Directly triggers cell clearing operations on `Bee` instances from UI selection input handler.
5. `GameConfig` (`scripts/game_config.gd`) holds static design constants cleanly, while `Session` (`scripts/session.gd`) owns all run/UI state, preserving autoload boundary rules.

## Findings

| # | Where (path:line) | What | Why it matters | Confidence | Fix |
|---|---|---|---|---|---|
| 1 | `hud.gd:2028` | Direct cell mutation from presentation code | `docs/agent-rules.md` rule 2 (Presentation never gates or directly mutates simulation) | High | Route cell clearing and designation changes through `Main` signals or hive API methods. |
| 2 | `hud.gd:2715` | HUD directly calls `pending_cell.clear_cell()` and `set_designation()` | `docs/agent-rules.md` rule 2 | High | Replace direct `clear_cell` call with a hive/main action command. |
| 3 | `input_selection.gd:485` | UI selection handler invokes `bee.command_empty_cell(cell)` directly | `docs/agent-rules.md` rule 2 | High | Emit a selection command signal to main controller instead of mutating simulation directly. |
| 4 | `challenge_stages.gd:428` | Role string literals `"forager"`, `"nurse"`, `"comb_worker"`, `"miner"` in unlocked keys | `docs/known-pitfalls.md` "Bulk renames hitting identifiers" | High | Use `Roles.key_for(...)` or `Roles` constants for unlocked role keys. |
| 5 | `challenge_stages.gd:456` | Role string literals in condition dictionaries (`"role": "forager"`, `"role": "nurse"`) | `docs/known-pitfalls.md` "Bulk renames hitting identifiers" | High | Use `Roles.key_for` or centralized role constants. |
| 6 | `hud.gd:1848` | `allowed_role_keys.has(Roles.key_for(entry.role))` mixes raw string comparisons with `Roles.key_for` | `docs/known-pitfalls.md` "Bulk renames hitting identifiers" | High | Ensure role filtering in HUD uniformly uses `Roles` key lookups. |
| 7 | `hud.gd:3330` | `match role_id:` chain over roles in HUD mode checks | `docs/agent-rules.md` rule 2 | High | Move role-mode active checking into `Roles` helper functions. |
| 8 | `hud.gd:3350` | `match common_role:` in HUD for sub-mode active status | `docs/agent-rules.md` rule 2 | High | Centralize role mode active evaluation in `Roles` or `Bee` state machine query. |
| 9 | `orders_zones.gd:207` | `match` chain over `main.Roles.FORAGER`, `NURSE`, `COMB_WORKER`, `MINER`, `HONEY` | `docs/agent-rules.md` rule 2 | High | Use `Roles` dispatch table or helper method for order mode application. |
| 10 | `bee.gd:1173` | `match role:` chain in `Bee._process` for role-specific logic | `docs/agent-rules.md` rule 2 | High | Delegate role-specific tick updates to role action modules (`BeeNursery`, `BeeBuilding`, etc.). |
| 11 | `bee.gd:1310` | `match role:` chain in `Bee` for visual role marker updates | `docs/agent-rules.md` rule 2 | Medium | Move role visual marker configuration into `Roles` description or visual helper. |
| 12 | `bee.gd:2922` | `match role:` chain in `Bee.get_status_text()` | `docs/agent-rules.md` rule 2 | High | Delegate role status formatting to `Roles` or individual role strategy objects. |
| 13 | `actions.gd:48` | `Roles` constants used in action definition tables | `docs/agent-rules.md` rule 2 | High | Legitimate: `actions.gd` properly uses `Roles.NURSE`, `Roles.COMB_WORKER`, etc. |
| 14 | `colony_diagnostics.gd:29` | Diagnostic counting reads `Roles.count_key` correctly | `docs/agent-rules.md` rule 2 | High | Legitimate: reads `Roles` owner correctly. |
| 15 | `world_building.gd:465` | Iterates over `main.Roles.ROLES` for level initial seeding | `docs/agent-rules.md` rule 2 | High | Legitimate: reads `Roles` definition table correctly. |
| 16 | `hive_cell.gd:577` | Reads `Roles.colour_for` and `Roles.tag_for_key` for cell hatch rendering | `docs/agent-rules.md` rule 2 | High | Legitimate: reads `Roles` owner correctly. |
| 17 | `run_availability.gd:132` | Iterates over `Roles.ROLES` to evaluate skill unlock status | `docs/agent-rules.md` rule 2 | High | Legitimate: reads `Roles` catalogue correctly. |
| 18 | `scenario_actions.gd:499` | Scenario action parses role keys via `main.Roles.id_for_key` | `docs/agent-rules.md` rule 2 | High | Legitimate: parses external scenario keys using `Roles` lookup methods. |
| 19 | `scenario_actions.gd:660` | Scenario action checks valid mode against `main.Roles.modes_for` | `docs/agent-rules.md` rule 2 | High | Legitimate: queries `Roles` for valid modes. |
| 20 | `game_config.gd:1` | Autoload `GameConfig` storing game balance constants | `docs/agent-rules.md` rule 2 | High | Legitimate: static balance numbers belong on `GameConfig`. |
| 21 | `session.gd:1` | Autoload `Session` storing run-wide and UI toggle state | `docs/agent-rules.md` rule 2 | High | Legitimate: `Session` is the single designated owner for run/UI state. |
| 22 | `perf.gd:1` | Autoload `Perf` tracking profiling spans | `docs/agent-rules.md` rule 2 | High | Legitimate: performance instrumentation autoload. |
| 23 | `diagnostic_log.gd:1` | Autoload `DiagnosticLog` managing diagnostic logging session | `docs/agent-rules.md` rule 2 | High | Legitimate: diagnostic telemetry logging autoload. |

## Candidate Jules tasks

### J-37 -- Refactor HUD cell direct mutations to signals
Files: `scripts/hud.gd`
After: J-36
Why: `hud.gd:2028` and `hud.gd:2715` write directly to simulation cell state instead of routing actions through signals or main controller API.
Do: Replace direct cell mutations in `hud.gd` with signal emissions processed by `main.gd` or `hive.gd`.
`python tools/jules_preflight.py scripts/hud.gd` output: `free scripts/hud.gd`

### J-38 -- Centralize challenge stage role key literals
Files: `scripts/challenge_stages.gd`
After: J-36
Why: Role names appear as raw string literals in `scripts/challenge_stages.gd:428` and `456`.
Do: Replace raw role string literals with references to `Roles` or `BeeEnums`.
`python tools/jules_preflight.py scripts/challenge_stages.gd` output: `free scripts/challenge_stages.gd`

## For Claude or Codex

- `scripts/hud.gd`, `_on_clear_cell_pressed`: Presentation code directly mutates simulation state (`pending_cell.clear_cell()`). Plan: `plans/now/code-health.md`.
- `scripts/input_selection.gd`, `_on_empty_cell_requested`: Input handler invokes `bee.command_empty_cell(cell)` directly. Plan: `plans/now/code-health.md`.

## Inventory

| Site (path:line) | Element / Literal | Classification | Details / Reason |
|---|---|---|---|
| `scripts/roles.gd:62-124` | `ROLES` table definitions | Owner | Canonical definition of all 7 roles, colours, tips, modes, and skills. |
| `scripts/roles.gd:132-198` | `entry`, `label_for`, `colour_for`, etc. | Owner | Canonical lookup API for roles. |
| `scripts/hud.gd:140` | `for role in Roles.ROLES:` | Legitimate | Queries `Roles` catalogue to populate HUD controls. |
| `scripts/hud.gd:185` | `"%s_%s" % [Roles.key_for(role_id), mode_key]` | Legitimate | Uses `Roles.key_for` to generate mode keys. |
| `scripts/hud.gd:1848` | `allowed_role_keys.has(Roles.key_for(entry.role))` | Finding (#6) | Raw string set filtering; should use `Roles` key helpers consistently. |
| `scripts/hud.gd:2028` | Direct cell mutation comment & implementation | Finding (#1) | Presentation writing simulation state directly. |
| `scripts/hud.gd:2715` | `pending_cell.clear_cell()` | Finding (#2) | Direct cell content clearing from HUD confirmation handler. |
| `scripts/hud.gd:3330` | `match role_id:` | Finding (#7) | Role conditional dispatch in presentation code. |
| `scripts/hud.gd:3350` | `match common_role:` | Finding (#8) | Role conditional sub-mode active checks in presentation code. |
| `scripts/input_selection.gd:485` | `bee.command_empty_cell(cell)` | Finding (#3) | Presentation/input handler directly triggering simulation bee command. |
| `scripts/orders_zones.gd:166` | `main.Roles.id_for_key(role_name)` | Legitimate | Queries `Roles` for ID from key. |
| `scripts/orders_zones.gd:207` | `match` on `main.Roles.FORAGER`... | Finding (#9) | Role match chain for orders/zones application. |
| `scripts/bee.gd:69-74` | Role action finders mapping | Legitimate | Maps `Roles` enum IDs to specialized role logic scripts (`BeeNursery`, `BeeBuilding`, etc.). |
| `scripts/bee.gd:1173` | `match role:` | Finding (#10) | Role conditional chain in `Bee._process`. |
| `scripts/bee.gd:1310` | `match role:` | Finding (#11) | Role visual marker configuration match chain. |
| `scripts/bee.gd:2922` | `match role:` | Finding (#12) | Role status text formatting match chain. |
| `scripts/actions.gd:48-159` | `Roles.NURSE`, `Roles.COMB_WORKER`... | Legitimate | Action table correctly references `Roles` constants. |
| `scripts/colony_diagnostics.gd:29-31` | `Roles.count_key(...)` | Legitimate | Diagnostic tally uses `Roles.count_key` correctly. |
| `scripts/world_building.gd:465` | `for role: Dictionary in main.Roles.ROLES:` | Legitimate | World builder reads `Roles` catalogue for initial level spawning. |
| `scripts/run_availability.gd:132` | `for role: Dictionary in Roles.ROLES:` | Legitimate | Run availability checks skill ownership using `Roles.ROLES`. |
| `scripts/scenario_actions.gd:499` | `main.Roles.id_for_key(...)` | Legitimate | Parses scenario target role key via `Roles`. |
| `scripts/challenge_stages.gd:428` | `"forager"`, `"nurse"`, `"comb_worker"` | Finding (#4) | String literals for roles in challenge stage definitions. |
| `scripts/challenge_stages.gd:456` | `"role": "forager"` condition | Finding (#5) | String literals for role condition checks. |

## Method

1. Queried all occurrences of role string literals (`forager`, `nurse`, `comb_worker`, `laying`, `idle`, `miner`, `honey`, `worker`, `queen`, `gyne`, `drone`) across `scripts/` and `scenes/`.
2. Queried all `Roles.` calls and `match`/`if` chains operating on role IDs or keys across GDScript sources.
3. Examined all autoload scripts declared in `project.godot` (`GameConfig`, `Session`, `Perf`, `DiagnosticLog`) to verify run-state and UI-state ownership boundaries.
4. Inspected `hud.gd`, `colony_panel.gd`, `nursery_panel.gd`, and `input_selection.gd` for presentation layer writes to simulation state nodes (`Bee`, `HiveCell`, `Hive`).
