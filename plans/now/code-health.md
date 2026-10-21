<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: CQ-L1 -- gdlint runs in verify.ps1 with Dave's thresholds | Dependency: CQ-L1 waits for RR-10 (Codex lane) to release `scripts/hive.gd` and `scripts/skill_tree_panel.gd`; CQ-S1 to CQ-S5 and CQ-R2 wait for ED-3, RR-12 and SP-8a (Dave, 18 Oct 2026); the rest is in "Dependencies" | Verified: 2026-10-18

# Code health -- lint, types, save ownership, data and responsibility splits

## Objective

Make Meadow's GDScript cheaper to change without changing what the game does. The
track comes from the GDScript Linter report of 17 Oct 2026
(`code_quality_report.html`, 2,994 rows -- never read it whole) and Dave's decisions
of 18 Oct 2026 below. Every slice is behaviour-preserving and names the existing test
or headless scenario that proves it.

## Current state (verified 18 Oct 2026 against `5b633e0`)

- **Linter noise.** Of 55 critical long functions, four are mismeasured: the linter
  counted past the function's end. `bee.gd::current_working_role` is really 2 lines,
  `hive_cell.gd::effective_build_time` 2, `session.gd::record_run_skill_policy` 4 and
  `ui_theme.gd` `PanelBox._draw` about 15. About 12 critical complexity rows are
  match-arm inflation on short functions. About 20 more are long only in comments
  (fewer than 60 code lines). unused-variable, long-line, todo and print rows are
  noise. Real lengths are measured from the `func` line to the next column-0 line.
  The genuinely long functions are the R slices' targets.
- **gdtoolkit.** gdtoolkit 4.5.0, the newest on PyPI, is installed but not on PATH;
  use `python -m gdtoolkit.linter`. It parses 138 of 139 tracked `.gd` files. The
  139th, `tests/rr7_silkscreen_fit_test.gd`, starts with a UTF-8 BOM.
- **gdformat.** `gdformat` changes 136 files (+12,910/-3,768 lines). It is idempotent
  and changes no string value. It breaks 84 source checks, 7 Python test modules, 3
  balance tests, `tools/stage_reference.py` (2.6 and 2.9 goal text), `tools/sprites.py
  --check`, and the FUNCTION_MAP signature lines (38 wrapped). After formatting, four
  files cross 700 lines without a description.
- **Typing.** `project.godot` has no `[debug]` section. 637 declarations would warn
  under `untyped_declaration`: 230 lambda returns, 202 locals, 106 lambda parameters,
  88 parameters, 6 returns and 5 members. 66 files are already clean. Confirmed on
  Godot 4.7.2: `:=`, `const`, for-loop variables and match bindings are not flagged.
- **Saving.** `save_game.gd` writes (static `save()`, `_cells_data`, `_bees_data`,
  `_flowers_data`, ...). `saving.gd` restores (`_restore`, `_restore_*`).
  `save_migrations.gd` upgrades the whole dictionary (FORMAT_VERSION 7) before any
  restore. No entity has `to_save`/`from_save`. Five modules have
  `save_data()`/`restore()` instead: guidance_policy, colony_milestones, pollination,
  rival_hive and fog_of_war (`explored_list`). No test compares a whole save.
- **Data.** There is no `.tres` outside addons and no `@export`. Every node is built in
  code and no game data is loaded from JSON. `export_presets.cfg` has
  `include_filter=""`, so a JSON data file would not ship.

## Decisions (Dave, 18 Oct 2026)

Recorded once here; a slice may restate one in a sentence and point back.

- **D1** Split scripts by responsibility, never by a size cap. Split when a script
  handles unrelated tasks or holds logic shared across entities or systems; a long,
  well-organised file stays. Shorten long functions where behaviour is unchanged.
  Dave chose all four uncertain splits: the scenario boot out of `main.gd`, bee display
  text, hud command rows, and the first crisis. The hud cell popup is not split.
- **D2** Data catalogues and magic numbers follow
  `plans/reference/reviews/data-catalogue-review.md`. The classification is the
  section "D2 classification" below, and each migration is an M slice. Dave took the
  five recommended answers: "starving" and the rival starting stores become GameConfig
  rows; the plot's honey colour stays; UI spacing stays; `show_crab_spiders` stays a
  listed exception.
- **D3** Each entity owns `to_save()`/`from_save()`. The save format is unchanged, with
  a round-trip proof on existing saves, at high reasoning. Dave's answers:
  - `save_game.gd` stays the write orchestrator and `saving.gd` the restore
    orchestrator.
  - Scope is scene entities (Flower, HiveCell, Hive, SoilBlock, Bee), plus renaming the
    five existing `save_data`/`restore` pairs.
  - The harness is built now; the moves wait for the alpha chain's save slices.
- **D4** gdtoolkit runs in `tools/verify.ps1`. Dave's answers:
  - gdlint lands first, with the thresholds in CQ-L1.
  - `gdformat` comes later: CQ-L2 first makes every text parser survive formatted code.
    The one-off reformat (CQ-L3) lands when both lanes are empty
    (`plans/workstreams.md`).
  - The stray `godot-copy-all-errors-5ab5055.../` copy of an installed addon is deleted.
- **Settled while planning (Dave may overrule):**
  - Shared save helpers (`_hex_list`, `_point_list`, `_cell_refs`, `_cells_at`,
    `_blocks_at`) become public statics in `save_game.gd`, which already owns them. No
    new file.
  - `saving.md`'s `paths:` is unchanged. Each entity's `to_save` carries a one-line
    pointer to it instead, because loading the rule on every `bee.gd` edit costs
    context.
  - `tools/gdscript_style.py` skips with a message when gdtoolkit is missing (the Codex
    runtime).
  - `bee.gd::idle_reason` starting a comb site is fixed by T2-14 in
    `plans/now/tier-two.md`, not here.

**Rule texts each decision changes, and the slice that edits them:**

| Decision | Text | Edited by |
| --- | --- | --- |
| D1 | `docs/agent-rules.md` rule 2: add "a script splits by responsibility, never by size". `tools/update_function_map.py` header: "700 lines decides what is indexed, never what is split". Its `main.gd` description. `.claude/rules/gdscript.md` "Section headers" | CQ-R1 |
| D2 | `docs/agent-rules.md` rule 2: "a balance value is a GameConfig field with a settings row; a structural constant is a named const in its owning file". No owner changes | CQ-M2 |
| D2 | `plans/reference/ui-rules.md`: canvas layers live in scripts/canvas_layers.gd | CQ-M5 |
| D3 | `.claude/rules/saving.md`: the round-trip harness | CQ-S0 |
| D3 | `.claude/rules/saving.md`: "where a field goes" (the entity's `to_save`/`from_save`; the `.get()` default lives in `from_save`; migrations stay central) and the creation paragraph (nodes are still created in `saving.gd`). `docs/agent-rules.md` rule 2: each entity owns its save fields; `save_game.gd` writes, `saving.gd` restores, `save_migrations.gd` migrates | CQ-S1 |
| D3 | Stale "field's line in save_game.gd and saving.gd" comments (`roles.gd`, `bee.gd`, `hive.gd`, `hive_cell.gd`, `save_migrations.gd`, `pollination.gd`, `fog_of_war.gd`) | each S slice for its own entity; CQ-S5 for the rest |
| D4 | `.claude/rules/gdscript.md`: verify runs gdlint, and a hit is fixed or carries `# gdlint: ignore=<rule>` with its reason | CQ-L1 |

## Open slices

| Slice | Outcome | Files it owns (block has the full list) | Startable | Level |
| --- | --- | --- | --- | --- |
| CQ-L1 | gdlint in verify with Dave's thresholds | `gdlintrc`, `tools/gdscript_style.py`, `tools/verify.ps1`, 13 hit sites | yes (RR-10 and L-30 landed 18 Oct 2026) | medium |
| CQ-L2 | every tool that reads GDScript as text survives `gdformat` | `tests/source_checks.py`, `tools/stage_reference.py`, `tools/update_function_map.py`, `tools/sprites.py`, tests | after CQ-L1 | medium |
| CQ-L3 | one-off `gdformat`; `--check` joins verify | every tracked `.gd` | gated: CQ-L2 and both lanes empty | medium |
| CQ-T2 | run, world and save glue typed | 20 scripts | gated: CQ-R1, CQ-M2 | low |
| CQ-T3 | UI typed; warning becomes an error | 17 UI scripts, `project.godot` | after CQ-T2 | low |
| CQ-S0 | golden-save round-trip harness | `tests/save_roundtrip_test.gd`, fixtures | yes | high |
| CQ-S1 | Flower owns its save fields | `flower.gd`, `save_game.gd`, `saving.gd` | gated: ED-3, RR-12, SP-8a | high |
| CQ-S2 | HiveCell owns its save fields | `hive_cell.gd`, `save_game.gd`, `saving.gd` | after CQ-S1 | high |
| CQ-S3 | Hive (keep-clear, tier credit, bodies) and SoilBlock marks | `hive.gd`, `soil_block.gd`, save files | after CQ-S2 | high |
| CQ-S4 | Bee owns its save fields (absorbs `saving.gd::_restore_bees`) | `bee.gd`, save files | after CQ-S3 | high |
| CQ-S5 | five `save_data`/`restore` pairs renamed; comment closeout | 5 modules, save files, `main.gd`, tests | after CQ-S4 | high |
| CQ-M3 | rival starting stores become GameConfig rows; rebalance consts named | `rival_hive.gd`, `game_config.gd`, `settings_catalogue.gd`, `tests/balance_tests.py` | gated: RR-11 (lane full, shared files) | medium |
| CQ-M4 | Challenge level ids named in `levels.gd` | `levels.gd` + 7 readers | yes | medium |
| CQ-M5 | CanvasLayer order in scripts/canvas_layers.gd | 10 UI scripts | yes | medium |
| CQ-M6 | selection green and caste look named (scripts/world_draw.gd) | 8 world scripts | yes | low |
| CQ-M7 | world z-order named in `world_draw.gd` | 13 world scripts | after CQ-M6 | medium |
| CQ-M8 | `BeeMovement.walk_to_hive_exit`; reach distances named | `bee_movement.gd`, 3 bee modules | yes | low |
| CQ-M9 | colony plot reads `Resources` colours; width const | `colony_panel.gd` | yes | low |
| CQ-M10 | `WEATHER_ROLLS_PER_DAY` | `main.gd` | yes | low |
| CQ-R0 | display-text golden harness | `tests/display_text_golden_test.gd`, fixture | yes | medium |
| CQ-R1 | headless scenario boot leaves `main.gd` | `main.gd`, `scripts/headless/scenario_boot.gd` | yes | medium |
| CQ-R2 | first crisis becomes scripts/first_crisis.gd | `main.gd`, save files, `colony_diagnostics.gd`, `scenario_actions.gd`, `hud.gd` | gated with CQ-S1 | high |
| CQ-R3 | bee display text becomes scripts/bee_readout.gd | `bee.gd`, `hud.gd`, `world_building.gd` | after CQ-R0 and T2-14 | medium |
| CQ-R4 | `bee.gd::_process` into four helpers, profiled | `bee.gd` | after HP-3 | high |
| CQ-R5 | `hive_cell.gd::_refresh`/`_ready` decomposed, profiled | `hive_cell.gd`, new hive-view perf fixture | after CQ-R0 | high |
| CQ-R6 | hud bee command rows become scripts/hud_command_rows.gd | `hud.gd` | yes | medium |
| CQ-R7 | hud selection text, cell popup and corner refreshes decomposed | `hud.gd` | after CQ-R0 | medium |
| CQ-R8 | hud builders shortened (designation button table) | `hud.gd` | yes | medium |
| CQ-R9 | `diagnostic_log.gd` snapshot shortened; probe duplicates kept once | `diagnostic_log.gd`, `scripts/headless/diagnostic_probes.gd` | yes | medium |
| CQ-R10 | `input_selection.gd` decomposed and sectioned | `input_selection.gd` | yes | medium |
| CQ-R11 | `world_building.gd::_seed_flower` decomposed, RNG order kept | `world_building.gd` | yes | medium |
| CQ-R12 | `challenge_runner.gd` start, C2 failure, stage entry shortened | `challenge_runner.gd`, `challenge_feedback.gd` | yes | medium |
| CQ-R13 | `main.gd::_ready` into build steps | `main.gd` | after CQ-R1, CQ-R2 | medium |
| CQ-R14 | mid-size builders: `main_menu._ready`, `challenge_complete._ready`, `flower.setup`, `bee._build_visuals` | those four | yes | low |

Only the first slice of each chain carries a full section and block. A row without one
gets its block written by the session that claims its predecessor, from this table,
the classification below and the research record named under "Rules for every slice" (`documentation.md`: no
claim while `dry_after`).

## Dependencies

- **Chains** (each needs the one before):
  - CQ-L1 → L2 → L3
  - CQ-T1 → T2 → T3
  - CQ-S0 → S1 → S2 → S3 → S4 → S5
  - CQ-M2 → M3; CQ-M6 → M7
  - CQ-R0 → R3, R5 and R7
  - CQ-R1 and CQ-R2 → R13
- **Shared files** (one after another, any order): `hud.gd` (M5, R3, R6, R7, R8);
  `bee.gd` (T1, M6, M7, R3, R4, S4); `main.gd` (T2, M4, M10, R1, R2, R13);
  `tests/source_checks.py` (T1, M1, L2). CQ-S4 comes after CQ-R3 and CQ-R4 have
  settled `bee.gd`.
- **Other plans:**
  - RR-10 (`plans/now/run-repairs.md`, Codex lane) held `hive.gd` and
    `skill_tree_panel.gd`; it landed 18 Oct 2026, clearing CQ-L1.
  - L-30 (`plans/now/agent-lifecycle.md`) held `tools/verify.ps1`; it landed 18 Oct 2026, clearing CQ-L1.
  - HP-3 (`plans/archive/hot-path-cadence_2026-10-18.md`) changes `bee.gd::_process`: CQ-R4 profiles
    after it.
  - T2-12, T2-13 and T2-14 (`plans/now/tier-two.md`) hold `hud.gd` and `bee.gd`, and
    T2-14 fixes `idle_reason`: CQ-R3 waits for T2-14.
  - The save moves (CQ-S1 to S5 and CQ-R2) wait for every specified slice that edits
    `save_game.gd`/`saving.gd`: WP-2, SG-2, ED-1, ED-2 (difficulty, ending at ED-3),
    RR-12 and SP-8a. Each of those plans carries the reverse pointer.
  - CQ-L3 needs both lanes empty, per `plans/workstreams.md`.

## Rules for every slice

<!-- LAYER: durable-rules -->

- **Do not change:**
  - the save format (FORMAT_VERSION 7, every key and default);
  - the RNG call order (`world_building.gd`, `bee.gd`, `flower.gd`);
  - `Perf.begin`/`end` section names;
  - node names that the LAY-6 layout assertions find;
  - `docs/performance.md` "Explicitly do not change";
  - any display string.

  Display text is proved byte-identical through CQ-R0's harness. A slice that would
  change any of these stops and escalates.
- **Hot paths** (`bee.gd::_process`, `hive_cell.gd::_refresh`, anything per bee or per
  cell per frame) are profiled before and after with `docs/performance.md`
  "Repeatability": discard the seeding run, take at least two runs a side, and compare
  sections, not frame totals. Record both in `docs/PERFORMANCE_BASELINE.md`. A split
  that regresses a comparable section does not ship. No new per-frame allocation: a
  helper writes members, it does not return a Dictionary.
- **Typing** annotates the type a value already has.
  - Use `:=` only from a statically typed right-hand side. A dictionary lookup or
    `.get()` gets its real type or `: Variant`. Save and JSON numbers are floats.
  - Never add `Array[T]`/`Dictionary[K, V]` to a value from an untyped source.
  - `var x = null`, and anything that may hold a freed object, becomes `: Variant`.
  - Duck-typed parameters take their common base type (`main: Node2D`, the existing
    convention).
  - Never change a number's kind.
  - Signal lambdas take the signal's types; side-effect lambdas get `-> void`.
- **Behaviour proof:** `python tools/equivalence.py <scenario> master` (same seed, same
  `result.json`) for simulation code; the named test for the rest.
  `python tools/update_function_map.py` runs after any edit to a mapped script.
- **Click-driven changes** (CQ-R6, CQ-R10) file a hands-on check per
  `plans/reference/check-loop.md`.
- **Research notes** for rows without a block (function measurements, helper names,
  coverage, restore order, proof strings) are in
  `docs/code-health-research-2026-10-18.md`, one heading per track. Read only your
  slice's heading, and re-verify against the code when writing a block: a line number
  is never the address.

## D2 classification

**Part A -- catalogues.** No catalogue changes format, so no JSON, no `.tres` and no
`res://data/`. The rows are typed native consts beside the code that reads them.
Python checks parse them as text (14 test files read `skills.gd`), so a format move
would cost five or more parser rewrites and an export filter for no gain.

| Catalogue | Today | Decision |
| --- | --- | --- |
| Settings (`settings_catalogue.gd` TUNABLES, 254 rows; values in `game_config.gd`, 232 vars) | const, checked both ways by `source_checks.py` | keep; GameConfig stays owner (rule 2) |
| Skills (`skills.gd` SKILLS, 40) | const, read only by CATALOGUE_READERS | keep |
| Challenge stages (`challenge_stages.gd`, 85 ids) | const, one field per line for `stage_reference.py` | keep |
| Roles (`roles.gd`), resources, actions, flower species (6), levels and menu stages | const | keep |
| Adaptations (`adaptations.gd`) | const, unbuilt | keep; no speculative format |
| Text catalogues (guidance, problem messages, challenge feedback, goals, names) | const | keep; copy is tied to format arguments |
| Scenario presets BASELINE (4 hand-copied GameConfig defaults) | const, unchecked | keep + parity check (CQ-M1) |
| Profile PREFERENCE_KEYS vs Session SESSION_KEYS | hand-kept | keep + containment check (CQ-M1) |
| `sprite_catalogue.gd`; save_migrations frozen settings | generated / frozen | keep |
| `test_scenarios/*.json`, `tests/fixtures/*.json` | JSON | keep |

**Part B -- literals.** A is structural, B is an identifier, C is scene config, D is
balance. "Leave" is a deliberate decision.

| Where | Value | Cat. | Action |
| --- | --- | --- | --- |
| `colony_diagnostics` ×2, `problem_messages` ×2, `year_winter` | `energy_capacity * 0.15` "starving" | D | GameConfig `starving_energy_level` + Interface row (CQ-M2) |
| `rival_hive` `_ready`/`restore`, `balance_tests.py` | nectar 120, pollen 40, share 0.7, min pop 4 | D | GameConfig `rival_starting_*` rows (CQ-M3) |
| `rival_hive` `_rebalance` | step 0.05, 90 days, ×0.75 | D internal | named consts in place (CQ-M3) |
| ~25 sites (`challenge_runner` 16) | `starting_level == 1`, `in [1, 2]` | B, saved | `levels.gd` CHALLENGE_1/2, `is_challenge()`; same ints (CQ-M4) |
| 10 UI files | CanvasLayer 5-25 | B | scripts/canvas_layers.gd (CQ-M5) |
| 8 world files | `Color(0.2, 1.0, 0.4, a)` ×11; queen 1.55 and caste colours | A | `world_draw.gd` SELECTION_COLOUR; caste names beside DRONE_* (CQ-M6) |
| ~13 world files | z_index -10 to 100 | B | `world_draw.gd` names; report `hex_draw_depth` overlap, change nothing (CQ-M7) |
| `bee_building`/`bee_foraging`/`bee_mining` | hive-exit block ×3; reach 2/6/8/10 | A | one helper + named per-module reaches (CQ-M8) |
| `colony_panel` | plot nectar/pollen colours; width 300 ×4 | dup / A | read `Resources.colour_for`; const (CQ-M9) |
| `main.gd` weather | `/ 6.0` ×2 | A pair | `WEATHER_ROLLS_PER_DAY` (CQ-M10) |
| ~35 sites | 0.001 / 0.0001 tolerances | A | leave (`is_zero_approx` changes the threshold) |
| bee, flower, hive_cell | `randf_range(0.85, 1.15)` stagger | A | leave (hot path) |
| 33 files | `"nectar"`/`"pollen"`/`"honey"`/`"bee_bread"` | B, saved | leave; prefer `Resources.*` when touching a file |
| 15 UI files | separations 2-10; world label fonts 10-12 | A/C | leave (Dave: no spacing scale) |
| obstacle, ui_icon, hive_body art | geometry | A | leave |
| `world_building` | retry bounds 6-40 | A | leave (RNG sequence) |
| `main.gd` FLOWER_FIELD_*, `bee.gd` NUPTIAL_*, `bee_foraging` SCOUT_BOUTS | already named | C/D | leave; only a simulated balance pass promotes them (rule 2) |
| stage timings, skill costs, species values | per entity | D | leave in their catalogues |

## CQ-L1 -- gdlint runs in verify.ps1 with Dave's thresholds

**True now.** gdtoolkit is installed but nothing runs it. There is no `gdlintrc`, and
`tests/rr7_silkscreen_fit_test.gd` starts with a BOM (`EF BB BF`), which gdtoolkit
rejects. `godot-copy-all-errors-5ab5055222311666b16982270e1fac051cdd17aa/` duplicates
the installed `addons/copy_all_errors` byte for byte, and Godot imports it as a second
folder.

**When done:**

1. A root `gdlintrc` holds exactly this:
   - `disable:` `class-definitions-order`, `max-file-lines`, `max-line-length`
   - `constant-name: (_?[A-Z][A-Z0-9]*(_[A-Z0-9]+)*|([A-Z][a-z0-9]*)+)`
   - `class-variable-name: (_?[a-z][a-z0-9]*(_[a-z0-9]+)*|([A-Z][a-z0-9]*)+)`
   - `function-variable-name: ([a-z][a-z0-9]*(_[a-z0-9]+)*|([A-Z][a-z0-9]*)+)`
   - `function-arguments-number: 7`, `max-public-methods: 80`, `max-returns: 12`
2. `tools/gdscript_style.py` runs `python -m gdtoolkit.linter` on
   `git ls-files '*.gd'`, excluding `addons/`. It skips with one clear line when
   gdtoolkit is missing, and pins `gdtoolkit==4.5.0` in its docstring.
3. `tools/verify.ps1` runs it as a fail-fast stage named `gdscript style`, straight
   after `godot boot`.
4. The BOM is stripped and the stray folder is `git rm`-ed.
5. The 13 hits are fixed:
   - duplicated-load: `fog_of_war.gd:247`, `skill_tree_panel.gd:374`, two tests;
   - no-elif-return: `hive.gd` ×2, `bee_foraging.gd`;
   - no-else-return: `flower.gd`;
   - max-returns: `bee.gd::idle_reason`, `bee.gd::_task_line`,
     `diagnostic_log.gd::event_count`, `hive_cell.gd::_overlay_colour`,
     `input_selection.gd::_finish_drag`. Each carries
     `# gdlint: ignore=max-returns` naming the R slice that will shorten it.
6. The rule-text edit for D4 is made.

**Invariants.** Each early-return rewrite keeps the same branches. Nothing else is
restyled.

```queue
**[Claude] CQ-L1 -- gdlint runs in verify.ps1 with Dave's thresholds**
- Plan: `plans/now/code-health.md` -- "CQ-L1 -- gdlint runs in verify.ps1 with Dave's thresholds"
- Files: `gdlintrc`, `tools/gdscript_style.py`, `tests/test_gdscript_style.py`, `tools/verify.ps1`, `tests/rr7_silkscreen_fit_test.gd`, `godot-copy-all-errors-5ab5055222311666b16982270e1fac051cdd17aa/`, `scripts/fog_of_war.gd`, `scripts/skill_tree_panel.gd`, `scripts/hive.gd`, `scripts/bee_foraging.gd`, `scripts/flower.gd`, `scripts/bee.gd`, `scripts/diagnostic_log.gd`, `scripts/hive_cell.gd`, `scripts/input_selection.gd`, `tests/bs14_saved_skill_policy_test.gd`, `tests/col10_succession_test.gd`, `.claude/rules/gdscript.md`, `FUNCTION_MAP.md`
- Check: `python tools/gdscript_style.py` exits 0 with zero gdlint problems over every tracked `.gd` outside `addons/`; `tests/test_gdscript_style.py` covers the missing-gdtoolkit skip; `.\tools\verify.ps1` shows a green `gdscript style` stage
- Proof: `absent: tools/verify.ps1 :: gdscript style`
- Next after: CQ-L2
```

CQ-T1 shipped 2026-10-21; its specification is `plans/archive/CQ-T1_2026-10-21.md`.

## CQ-T2 -- run, world and save glue typed

**True now** (21 Oct 2026, after CQ-T1). CQ-T1 turned Godot's `untyped_declaration`
warning on (level 1) and holds its 25 scripts and 16 tests at zero through the
`TYPED_FILES` ratchet in `tests/source_checks.py`. The run, world and save glue is not
in it. The ratchet's counter (which also counts untyped for-loop variables) finds 515
declarations in these 20 scripts: `input_selection` 68, `scenario_actions` 67,
`world_building` 60, `main` 57, `hive` 47, `orders_zones` 38, `saving` 31,
`save_game` 29, `diagnostic_log` 21, `challenge_runner` 20, `perf` 14, `save_slots` 12,
`challenge_stage_setup` 11, `headless/diagnostic_profile` 9, `settings_catalogue` 8,
`developer_overrides` 6, `headless/diagnostic_probes` 6, `player_profile` 5,
`save_migrations` 4, `tutorial_checkpoint` 2. `save_game.gd` still opens with
`static func save(world, path`. Godot's own count for the same files was 219 on
18 Oct (research record, "Typing count (T slices)").

**When done:**

- Every declaration in the 20 scripts, plus `scripts/headless/scenario_boot.gd`
  (CQ-R1 moves the headless boot there), is typed under "Rules for every slice":
  locals, parameters, returns, lambdas and for-loop variables.
- Save-dictionary values are `float` or `: Variant`, never `int`; a value read back from
  a save or from JSON keeps its float kind. `world`/`main` parameters take `Node2D`.
- Every one of those files is added to `TYPED_FILES`, so the ratchet holds them at
  zero.
- `python tools/update_function_map.py` has refreshed the signature lines.

**Invariants.** No save key, default or FORMAT_VERSION changes. No RNG call moves in
`world_building.gd`. No `Perf` section name, node name or display string changes.

**Gate.** CQ-R1 moves code out of `main.gd` and edits `scenario_actions.gd` and
`diagnostic_log.gd`; CQ-M2 adds a row to `settings_catalogue.gd`. Typing those files
while either is open would type code that is about to move, so this waits for both.

```queue-gated
**[Claude] CQ-T2 -- run, world and save glue typed**
- Plan: `plans/now/code-health.md` -- "CQ-T2 -- run, world and save glue typed"
- Files: `scripts/main.gd`, `scripts/scenario_actions.gd`, `scripts/world_building.gd`, `scripts/input_selection.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/orders_zones.gd`, `scripts/headless/diagnostic_profile.gd`, `scripts/perf.gd`, `scripts/settings_catalogue.gd`, `scripts/challenge_runner.gd`, `scripts/save_slots.gd`, `scripts/hive.gd`, `scripts/diagnostic_log.gd`, `scripts/tutorial_checkpoint.gd`, `scripts/developer_overrides.gd`, `scripts/challenge_stage_setup.gd`, `scripts/save_migrations.gd`, `scripts/player_profile.gd`, `scripts/headless/diagnostic_probes.gd`, `scripts/headless/scenario_boot.gd`, `tests/source_checks.py`, `FUNCTION_MAP.md`
- Check: the `TYPED_FILES` source check reports zero untyped declarations in every listed script; `python tools/gdscript_warnings.py` on the listed scripts prints no warning; `tests/test_save_migrations.py`, `tests/test_si1_run_state.py`, `tests/test_si2_exact_rollback.py` and `tests/test_layout_regression.py` pass; `python tools/equivalence.py test_scenarios/slice1_smoke_test.json master` matches; `.\tools\verify.ps1` is green
- Proof: `present: scripts/save_game.gd :: static func save(world, path`
- Next after: CQ-T3
```

## CQ-S0 -- golden-save round-trip harness

**True now.** No test compares a whole save. `tests/test_save_migrations.py` runs the
migration ladder in Python on two empty-world fixtures. The GDScript save tests spot-check
fields after settling.

**When done:**

- `tests/save_roundtrip_test.gd` loads each golden save and re-saves it in the same
  frame, with the tree paused as in `si1_run_state_test.gd`. It does this by two routes,
  the load path and in-place `saving._restore`, then compares canonical JSON (sorted
  keys; soil `present`, `keep_clear` and fog compared as sets).
- The goldens are captured on master with `save_run` from new `test_scenarios/cq_s0_*`
  captures:
  - an early Colony Run;
  - a mid run with brood, bodies, restock and mine queues, bee bread and drones;
  - winter;
  - a Challenge 2 checkpoint (in place only);
  - a fresh forager with `orientation_flight_on`.
- `tests/fixtures/save_v1.json`, `save_v2.json` and a v6 save are loaded, re-saved and
  recorded.
- `.claude/rules/saving.md` names the harness.

**If a route is not idempotent today** (the suspected case: a forager gains
`start_x`/`start_y` on reload with orientation flight on), record it as a named known
difference in the test and escalate to Dave. Do not fix it here: that would be a
gameplay change.

```queue
**[Claude] CQ-S0 -- golden-save round-trip harness**
- Plan: `plans/now/code-health.md` -- "CQ-S0 -- golden-save round-trip harness"
- Files: `tests/save_roundtrip_test.gd`, `tests/test_save_roundtrip.py`, `tests/fixtures/saves/`, `test_scenarios/cq_s0_early_capture.json`, `test_scenarios/cq_s0_mid_capture.json`, `test_scenarios/cq_s0_winter_capture.json`, `test_scenarios/cq_s0_challenge2_capture.json`, `test_scenarios/cq_s0_orientation_capture.json`, `.claude/rules/saving.md`
- Check: `python -m unittest tests.test_save_roundtrip` passes, comparing every golden save's load-then-save output to its input by both routes, with any known difference named and escalated; `.\tools\verify.ps1` is green
- Proof: `absent: .claude/rules/saving.md :: round-trip`
- Next after: CQ-S1
```

## CQ-S1 -- Flower owns its save fields

**True now.** `save_game.gd::_flowers_data` writes a flower's 10 fields, and
`saving.gd::_restore_flowers` reads them back.

**When done:**

- `flower.gd` has `to_save()`/`from_save(entry)`. Creation, `add_child`,
  `setup(species)` and `flower_grid.rebuild(created)` stay in `saving.gd`, and
  `from_save` runs after `setup`, so the saved lifespan beats setup's re-roll.
- `from_save` assigns fields only: no mutator, no signal. `main.gd` documents that
  `_restore` emits none.
- The save helpers become public statics in `save_game.gd`.
- D3's rule-text edits are made.

This slice sets the pattern for CQ-S2 to S4; their restore orders are in the research
record, "Save restore".

```queue-gated
**[Claude] CQ-S1 -- Flower owns its save fields**
- Plan: `plans/now/code-health.md` -- "CQ-S1 -- Flower owns its save fields"
- Files: `scripts/flower.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `.claude/rules/saving.md`, `docs/agent-rules.md`, `FUNCTION_MAP.md`
- Check: `python -m unittest tests.test_save_roundtrip` passes with unchanged goldens; `tests/test_save_migrations.py` passes; `.\tools\verify.ps1` is green
- Proof: `present: scripts/saving.gd :: flower.nectar_amount = float(entry.get("nectar", 0.0))`
- Next after: CQ-S2
```

CQ-M1 shipped 2026-10-21; its specification is `plans/archive/CQ-M1_2026-10-21.md`.

CQ-M2 shipped 2026-10-21; its specification is `plans/archive/CQ-M2_2026-10-21.md`.

## CQ-M3 -- rival starting stores become GameConfig rows; rebalance consts named

**True now** (21 Oct 2026, after CQ-M2). `rival_hive.gd` starts the rival with
`nectar = 120.0` and `pollen = 40.0` in `_ready`, and `restore` repeats both as its
`data.get` defaults. `forager_share` starts at 0.7 in its `var` line and again as
`restore`'s default. Both `_ready` and `restore` floor the population with
`max(4.0, GameConfig.rival_starting_bees)`. `_rebalance` uses three bare numbers:
`rival_brood_gate_days * 0.75`, a step of `0.05` and `days_of_food > 90.0`.
`tests/balance_tests.py::test_rival` keeps its own copies of all of them
(`120.0, 40.0, 0.0, 0.7`, `* 0.75`, `0.05`, `90.0`). It already reads
`MIN_FORAGER_SHARE`/`MAX_FORAGER_SHARE` out of `rival_hive.gd` by regex. D2 classes
the starting stores as balance values (rule 2: a GameConfig field with a settings row)
and the rebalance numbers as structural constants ("D2 classification" above).

**When done:**

- GameConfig has `rival_starting_nectar := 120.0`, `rival_starting_pollen := 40.0`,
  `rival_starting_forager_share := 0.7` and `rival_starting_min_population := 4.0`.
  Each has a row under "The rival colony" next to `rival_starting_bees`, with the same
  shape: `persist: "none"` and a tip ending "Takes effect on Restart Run."
- `_ready`, the `forager_share` initialiser and `restore`'s defaults read those
  fields. No literal 120, 40, 0.7 or 4 is left in those lines.
- `_rebalance`'s three numbers are named consts beside `MIN_FORAGER_SHARE`/
  `MAX_FORAGER_SHARE` (for example `REBALANCE_STEP`, `SHORT_OF_FOOD_FACTOR`,
  `COMFORTABLE_DAYS`), with the same values.
- `tests/balance_tests.py::test_rival` reads the four fields through `cfg()` and the
  three consts by regex from `rival_hive.gd`, the way it already reads
  MIN/MAX_FORAGER_SHARE. It keeps no copy of its own.
- `tests/si1_run_state_test.gd` asserts that a fresh rival and `restore({})` both give
  nectar 120, pollen 40 and forager share 0.7.

**Invariants.** Every default value stays the same, so a run plays exactly as it does
now. The rival's save keys and the FORMAT_VERSION do not change. `persist: "none"`
puts the new rows in no save or profile. No existing display string changes.

**Gate.** It could start today, but the Claude lane already holds five items, and the
last of them, RR-11 (`plans/now/run-repairs.md`), also edits `game_config.gd` and
`settings_catalogue.gd`. Whoever lands RR-11 opens this fence.

```queue-gated
**[Claude] CQ-M3 -- rival starting stores become GameConfig rows; rebalance consts named**
- Plan: `plans/now/code-health.md` -- "CQ-M3 -- rival starting stores become GameConfig rows; rebalance consts named"
- Files: `scripts/rival_hive.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/balance_tests.py`, `tests/si1_run_state_test.gd`, `FUNCTION_MAP.md`
- Check: `python tests/balance_tests.py` passes with its rival section unchanged; `python -m unittest tests.test_si1_run_state` passes, including the new fresh-rival and `restore({})` assertions; `tests/test_save_migrations.py`, `tests/test_signal_catalogue.py` and the settings-row source checks pass; `.\tools\verify.ps1` is green
- Proof: `present: scripts/rival_hive.gd :: nectar = float(data.get("nectar", 120.0))`
- Next after: none -- CQ-M3 ends the CQ-M2 chain; the other M slices (CQ-M4 to CQ-M10) are unspecified table rows
```

## CQ-R0 -- display-text golden harness

**True now.** Nothing in `tests/`, `test_scenarios/` or `scenario_actions.gd` reads
these: `bee.gd::_task_line`, `idle_reason`, `role_name_text`, `carrying_text`; the
hud selection text, cell popup or corner signal rows; or a cell's `info_label`. A
decomposition of any of them has no proof that the text is unchanged.

**When done:**

- `tests/display_text_golden_test.gd` drives a bee through each role and state, and a
  cell through each content type and overlay. It writes every string to JSON, and
  `tests/test_display_text_golden.py` compares that JSON byte for byte with
  `tests/fixtures/display_text_golden.json`, which is captured on master.
- `.claude/rules/gdscript.md` says a display-text refactor proves itself with it.
- The harness only reads text: no state is created only to make a string appear, other
  than through a bee's or cell's existing setters.

```queue
**[Claude] CQ-R0 -- display-text golden harness**
- Plan: `plans/now/code-health.md` -- "CQ-R0 -- display-text golden harness"
- Files: `tests/display_text_golden_test.gd`, `tests/test_display_text_golden.py`, `tests/fixtures/display_text_golden.json`, `.claude/rules/gdscript.md`
- Check: `python -m unittest tests.test_display_text_golden` passes against the master capture and fails when one character of a captured string is changed; `.\tools\verify.ps1` is green
- Proof: `absent: .claude/rules/gdscript.md :: display_text_golden`
- Next after: CQ-R7
```

## CQ-R7 -- hud selection text, cell popup and corner refreshes decomposed

**True now.** `hud.gd::_refresh_selection_text` (one bee: identity, energy, activity,
trait lines), `_refresh_cell_popup` (content lines, state lines, hatch line, control
state) and `_refresh_corner` (signature, labels, signal rows) are each long and mix
building a string with writing it to a node. CQ-R0's golden harness now reads their
output.

**When done:**

- Each of the three becomes a short function that calls named helpers; the helpers that
  only build text return a `String` or `Array` and touch no node, e.g.
  `_selection_activity_text(bee)` and `_cell_content_lines(cell)`.
- No string, ordering or colour changes: `python -m unittest tests.test_display_text_golden`
  passes against the unchanged fixture, and it is not regenerated.
- `FUNCTION_MAP.md` lists the new helpers.

```queue
**[Claude] CQ-R7 -- hud selection text, cell popup and corner refreshes decomposed**
- Plan: `plans/now/code-health.md` -- "CQ-R7 -- hud selection text, cell popup and corner refreshes decomposed"
- Files: `scripts/hud.gd`, `FUNCTION_MAP.md`
- Check: `python -m unittest tests.test_display_text_golden` passes against the unchanged fixture; `tests/test_layout_regression.py` passes; `.	oolserify.ps1` is green
- Proof: `absent: scripts/hud.gd :: func _selection_activity_text(`
- Next after: none -- the other CQ-R hud slices (CQ-R6, CQ-R8) are independent table rows
```

## CQ-R1 -- headless scenario boot leaves main.gd

**True now.** `main.gd` lines ~1465-1660 hold the `--scenario` boot:
`_apply_scenario_boot_arg`, `_parse_scenario_performance_capture`, `_is_whole_number`
and `_end_scenario_run`. FUNCTION_MAP calls `main.gd` "everything not yet split out of
main". `scenario_actions.gd`, `diagnostic_log.gd` and `scenario_presets.gd` call into
it.

**When done:**

- The bodies move to a static `scripts/headless/scenario_boot.gd` that takes `main`.
  The `scenario_*` fields stay on `main`, because other scripts read them.
- Callers either keep calling `main`'s public names through one-line forwarders, or
  move to the new file. Whichever is chosen applies to all of them.
- D1's rule texts are edited.

```queue
**[Claude] CQ-R1 -- headless scenario boot leaves main.gd**
- Plan: `plans/now/code-health.md` -- "CQ-R1 -- headless scenario boot leaves main.gd"
- Files: `scripts/main.gd`, `scripts/headless/scenario_boot.gd`, `scripts/scenario_actions.gd`, `scripts/diagnostic_log.gd`, `scripts/scenario_presets.gd`, `tools/update_function_map.py`, `FUNCTION_MAP.md`, `.claude/rules/gdscript.md`, `docs/agent-rules.md`
- Check: `tests/test_run_scenario_launch.py` passes; `python tools/equivalence.py test_scenarios/slice1_smoke_test.json master` and `test_scenarios/sv1_named_saves_test.json` match; a performance-capture scenario still writes its capture; `.\tools\verify.ps1` is green
- Proof: `present: scripts/main.gd :: func _apply_scenario_boot_arg(`
- Next after: CQ-R2
```
