<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code / Codex | Next: CQ-R6 (hud.gd released by GP-5 and RR-14, 26-27 Oct 2026) then CQ-M5a in the Codex lane (CQ-R10 implementation ready, C-154 filed; CQ-R11 complete); CQ-M5b waits for RR-21 to release scripts/main.gd and the J-14 Jules branch to settle scripts/game_panel.gd; CQ-M6 waits for SP-14 to release scripts/hive_cell.gd and HS-2 to release scripts/bee.gd and scripts/soil_block.gd (RR-19 landed 28 Oct 2026); CQ-M8, CQ-S0b and CQ-L2 complete, 24-25 Oct 2026; CQ-L3 waits for both lanes to empty; CQ-M4 is deferred until the Claude lane releases scripts/save_game.gd and scripts/saving.gd (CQ-R12 complete, 24 Oct 2026) | Dependency: CQ-T3 follows CQ-R8 (CQ-L2 has released tests/source_checks.py); CQ-S1 to CQ-S5 and CQ-R2 wait for ED-3, RR-12, SP-8a and DR-1; the rest is in "Dependencies" | Verified: 2026-10-26

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
  - Jules's audit (23 Oct 2026) put four options to Dave, none backed by a
    measured problem, so none is pursued: UI moved into `.tscn` scenes
    (breaks the headless geometry checks), bee helpers as child nodes (5-10x
    the node count, and CQ-S4 assumes `bee.gd` owns its fields), signals in
    place of the epoch counters (signal dispatch on hot paths), and
    getters/setters around the fields the bee helpers read (call overhead
    per bee per frame). A profile showing one of those costs reopens it
    (`docs/agent-rules.md` rule 3).

**Rule texts each decision changes, and the slice that edits them:**

| Decision | Text | Edited by |
| --- | --- | --- |
| D1 | `docs/agent-rules.md` rule 2: add "a script splits by responsibility, never by size". `tools/update_function_map.py` header: "700 lines decides what is indexed, never what is split". Its `main.gd` description. `.claude/rules/gdscript.md` "Section headers" | CQ-R1 |
| D2 | `docs/agent-rules.md` rule 2: "a balance value is a GameConfig field with a settings row; a structural constant is a named const in its owning file". No owner changes | CQ-M2 |
| D2 | `plans/reference/ui-rules.md`: canvas layers live in scripts/canvas_layers.gd | CQ-M5a |
| D3 | `.claude/rules/saving.md`: the round-trip harness | CQ-S0 |
| D3 | `.claude/rules/saving.md`: "where a field goes" (the entity's `to_save`/`from_save`; the `.get()` default lives in `from_save`; migrations stay central) and the creation paragraph (nodes are still created in `saving.gd`). `docs/agent-rules.md` rule 2: each entity owns its save fields; `save_game.gd` writes, `saving.gd` restores, `save_migrations.gd` migrates | CQ-S1 |
| D3 | Stale "field's line in save_game.gd and saving.gd" comments (`roles.gd`, `bee.gd`, `hive.gd`, `hive_cell.gd`, `save_migrations.gd`, `pollination.gd`, `fog_of_war.gd`) | each S slice for its own entity; CQ-S5 for the rest |
| D4 | `.claude/rules/gdscript.md`: verify runs gdlint, and a hit is fixed or carries `# gdlint: ignore=<rule>` with its reason | CQ-L1 |

## Open slices

| Slice | Outcome | Files it owns (block has the full list) | Startable | Level |
| --- | --- | --- | --- | --- |
| CQ-L3 | one-off `gdformat`; `--check` joins verify | every tracked `.gd` | gated: CQ-L2 and both lanes empty | medium |
| CQ-T3 | UI typed; warning becomes an error | 17 UI scripts, `project.godot`, `tests/source_checks.py`, `FUNCTION_MAP.md` | section needed, after CQ-R8 (CQ-L2 released `tests/source_checks.py` 24 Oct 2026) | low |
| CQ-S1 | Flower owns its save fields | `flower.gd`, `save_game.gd`, `saving.gd` | gated: ED-3, RR-12, SP-8a, DR-1 | high |
| CQ-S2 | HiveCell owns its save fields | `hive_cell.gd`, `save_game.gd`, `saving.gd` | after CQ-S1 | high |
| CQ-S3 | Hive (keep-clear, tier credit, bodies) and SoilBlock marks | `hive.gd`, `soil_block.gd`, save files | after CQ-S2 | high |
| CQ-S4 | Bee owns its save fields (absorbs `saving.gd::_restore_bees`) | `bee.gd`, save files | after CQ-S3 | high |
| CQ-S5 | five `save_data`/`restore` pairs renamed; comment closeout | 5 modules, save files, `main.gd`, tests | after CQ-S4 | high |
| CQ-M4 | Challenge level ids named in `levels.gd` | `levels.gd` + 7 readers | yes | medium |
| CQ-M5a | scripts/canvas_layers.gd names every CanvasLayer; 7 UI scripts read it | `canvas_layers.gd`, 7 UI scripts, `ui-rules.md` | yes -- after CQ-R14 releases `main_menu.gd`/`challenge_complete.gd` (specified 27 Oct 2026) | medium |
| CQ-M5b | `hud.gd`, `main.gd`, `game_panel.gd` read it; a source check forbids a bare `layer = <int>` | those three, `tests/source_checks.py` | gated -- RR-21 owns `main.gd`, Jules J-14 holds `game_panel.gd` | low |
| CQ-M6 | selection green and caste look named (scripts/world_draw.gd) | 8 world scripts | gated -- SP-14 owns `hive_cell.gd`, HS-2 `bee.gd` and `soil_block.gd` | low |
| CQ-M7 | world z-order named in `world_draw.gd` | 13 world scripts | after CQ-M6 | medium |
| CQ-R2 | first crisis becomes scripts/first_crisis.gd | `main.gd`, save files, `colony_diagnostics.gd`, `scenario_actions.gd`, `hud.gd` | gated with CQ-S1 | high |
| CQ-R3 | bee display text becomes scripts/bee_readout.gd | `bee.gd`, `hud.gd`, `world_building.gd` | once its section is written (CQ-R7 released `hud.gd` and WP-3 landed 22 Oct 2026; T2-14 and CQ-R0 21 Oct 2026) | medium |
| CQ-R4 | `bee.gd::_process` into four helpers, profiled | `bee.gd` | after HP-3 | high |
| CQ-R5 | `hive_cell.gd::_refresh`/`_ready` decomposed, profiled | `hive_cell.gd`, new hive-view perf fixture | yes (CQ-R0 landed 21 Oct 2026) | high |
| CQ-R6 | hud bee command rows become scripts/hud_command_rows.gd | `hud.gd` | yes -- GP-5 and RR-14 released `scripts/hud.gd`, 26-27 Oct 2026 | medium |
| CQ-R8 | hud builders shortened (designation button table) | `hud.gd`, `FUNCTION_MAP.md` | section needed | medium |
| CQ-R13 | `main.gd::_ready` into build steps | `main.gd` | after CQ-R2 (CQ-R1 landed 21 Oct 2026) | medium |

Only the first slice of each chain carries a full section and block. A row without one
gets its block written by the session that claims its predecessor, from this table,
the classification below and the research record named under "Rules for every slice" (`documentation.md`: no
claim while `dry_after`).

## Dependencies

- **Chains** (each needs the one before):
  - CQ-L1 → L2 → L3
  - CQ-T1 → T2 → T3
  - CQ-S0 → S1 → S2 → S3 → S4 → S5; CQ-S0b (from CQ-S0's harness) any time before CQ-S4
  - CQ-M2 → M3 → M8 (M8 by queue order: it shares no file with M3); CQ-M6 → M7;
    CQ-M5a → M5b
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
  - T2-14 (`plans/now/tier-two.md`) fixed `idle_reason` before CQ-R3 moves it; it
    landed 21 Oct 2026, clearing CQ-R3 of everything but the `hud.gd` order.
  - CQ-T3 types `hud.gd` after the queued slices that reshape it (WP-3, landed
    22 Oct 2026, then CQ-R7), as CQ-T2 waited for CQ-R1's moves; CQ-L1, which held
    `skill_tree_panel.gd` ahead of it, landed 22 Oct 2026. CQ-R7 landed 22 Oct
    2026. CQ-R8 should precede CQ-T3 to avoid typing the builders twice;
    both still need sections. For Codex admission, CQ-T3 also waited for
    Claude's CQ-L2 to release `tests/source_checks.py` (released 24 Oct 2026); `FUNCTION_MAP.md` is
    unowned (Dave, 23 Oct 2026) and gates nothing. This is a lane
    ownership gate, not unshipped functional prerequisites (verified
    23 Oct 2026 against `a49ac59` and both lanes' `Files:` lists).
  - CQ-M9 is independent of those gates: `colony_panel.gd` is below the
    function-map threshold and no Claude queue item owns it. CQ-M10's
    Codex block stays `queue-gated` until it is opened by hand.
  - The save moves (CQ-S1 to S5 and CQ-R2) wait for every specified slice that edits
    `save_game.gd`/`saving.gd`: WP-2, SG-2, ED-1, ED-2 (difficulty, ending at ED-3),
    RR-12, SP-8a and DR-1 (`plans/now/drones.md`). Each of those plans carries the reverse pointer.
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
| 10 UI files | CanvasLayer 5-25 | B | scripts/canvas_layers.gd (CQ-M5a, CQ-M5b) |
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

CQ-L1 shipped 2026-10-22; its specification is `plans/archive/CQ-L1_2026-10-22.md`.

CQ-L2 shipped 2026-10-24; its specification is `plans/archive/CQ-L2_2026-10-24.md`.

## CQ-L3 -- one-off gdformat, then `--check` joins verify

Level: medium. Gated: both lanes must be empty (`plans/workstreams.md`), because
the reformat touches every tracked `.gd`.

**True now.** CQ-L2 landed 24 Oct 2026: `tests/test_gdformat_survival.py` shows
`tests/source_checks.py`, `tools/stage_reference.py`, `tools/update_function_map.py`
and `tools/sprites.py` give the same answers on a gdformat-ed copy. Two things it
found stay as they are: `FUNCTION_MAP.md` indexes a hand-wrapped signature by its
first line only, while a formatted one is shown whole; and gdformat writes a
wrapped chain as `. name(` on its own line.

**When done:**

1. `gdformat` (gdtoolkit 4.5.0) has run once over every tracked `.gd` outside
   `addons/`, in one commit that changes nothing else.
2. `python tools/update_function_map.py` and `python tools/stage_reference.py`
   have been re-run, so the generated files match the formatted source.
3. `tools/verify.ps1` runs `gdformat --check` over the same files.
4. `.\tools\verify.ps1` is green and a headless boot is unchanged.

```queue-gated
**[Claude] CQ-L3 -- one-off gdformat, then `--check` joins verify**
- Plan: `plans/now/code-health.md` -- "CQ-L3 -- one-off gdformat, then `--check` joins verify"
- Files: every tracked `.gd` outside `addons/`, `tools/verify.ps1`, `FUNCTION_MAP.md`, `docs/challenge-stages.md`
- Check: `gdformat --check` over every tracked `.gd` outside `addons/` reports nothing to change; `.\tools\verify.ps1` is green
- Proof: `absent: tools/verify.ps1 :: gdformat`
- Next after: CQ-T3
```

## Not in the queue, and why

- **CQ-M4** -- deferred until the Claude lane releases `scripts/save_game.gd`
  and `scripts/saving.gd`; its ownership overlaps that lane's current work.
- **CQ-M5b** -- waits for the Claude lane's RR-21 to release `scripts/main.gd`
  and for the Jules J-14 branch (which deletes code in `scripts/game_panel.gd`)
  to be merged or closed; keep its block gated until both clear.
- **CQ-M6** -- waits for the Claude lane's SP-14 to release
  `scripts/hive_cell.gd` and HS-2 to release `scripts/bee.gd` and
  `scripts/soil_block.gd` (RR-19 landed 28 Oct 2026); keep its queue block
  gated until that ownership clears. CQ-R10 also uses `scripts/input_selection.gd`, so take it first.

CQ-S0b shipped 2026-10-25; its specification is `plans/archive/CQ-S0b_2026-10-25.md`.

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
- Files: `scripts/flower.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `.claude/rules/saving.md`, `docs/agent-rules.md`
- Check: `python -m unittest tests.test_save_roundtrip` passes with unchanged goldens; `tests/test_save_migrations.py` passes; `.\tools\verify.ps1` is green
- Proof: `present: scripts/saving.gd :: flower.nectar_amount = float(entry.get("nectar", 0.0))`
- Next after: CQ-S2
```

CQ-M1 shipped 2026-10-21; its specification is `plans/archive/CQ-M1_2026-10-21.md`.

CQ-M2 shipped 2026-10-21; its specification is `plans/archive/CQ-M2_2026-10-21.md`.

CQ-M3 shipped 2026-10-22; its specification is `plans/archive/CQ-M3_2026-10-22.md`.

CQ-M8 shipped 2026-10-25; its specification is `plans/archive/CQ-M8_2026-10-25.md`.

## CQ-M4 -- Challenge level ids named in `levels.gd`

Replace the duplicated Challenge 1 and Challenge 2 level literals with
`Levels.CHALLENGE_1`, `Levels.CHALLENGE_2`, `Levels.CHALLENGE_LEVELS` and
`Levels.is_challenge()`. Keep the integer values and all save behaviour
unchanged. Update the readers in `challenge_runner.gd`, `saving.gd`,
`save_game.gd`, `main.gd`, `debug_panel.gd`, `challenge_complete.gd` and
`world_building.gd`.

Prove unchanged simulation with the Challenge 1 stage-advance and full route
scenarios, then regenerate `FUNCTION_MAP.md` and run the relevant source
checks. Stop if the replacement changes a save compatibility decision.

```queue-gated
**[Codex] CQ-M4 -- Challenge level ids named in `levels.gd`**
- Plan: `plans/now/code-health.md` -- "CQ-M4 -- Challenge level ids named in `levels.gd`"
- Files: `scripts/levels.gd`, `scripts/challenge_runner.gd`, `scripts/saving.gd`, `scripts/save_game.gd`, `scripts/main.gd`, `scripts/debug_panel.gd`, `scripts/challenge_complete.gd`, `scripts/world_building.gd`, `FUNCTION_MAP.md`
- Check: `python tools/equivalence.py test_scenarios/h4_challenge1_stage_advance_test.json master` and `python tools/equivalence.py test_scenarios/bb4_challenge1_route.json master` report no difference; `python tests/source_checks.py`, `python tools/prefinish.py` and `./tools/verify.ps1` are green
- Proof: `present: scripts/saving.gd :: if Session.starting_level in [1, 2]:`
- Next after: CQ-M5b -- the last CanvasLayer readers and the bare-layer source check
```

CQ-R11 shipped 2026-10-26; its specification is `plans/archive/CQ-R11_2026-10-26.md`.

## CQ-R6 -- extract the HUD bee-command rows

**Now.** `hud.gd` still builds the bee-command rows in the selection-panel
section. The D2 research record identifies the row builders and existing
layout coverage; the section heading still groups commands with readouts and
tray sizing. GP-5 (26 Oct) and RR-14 (27 Oct 2026) have landed, and
`tools/slice.ps1 owner` reports `hud.gd` and `hud_command_rows.gd` clear on
27 Oct 2026.

**Target.** Move the command-row builders into the new leaf
`scripts/hud_command_rows.gd` and give the surrounding HUD sections accurate
headings. Preserve every button, node name, display string and command
behaviour. Regenerate `FUNCTION_MAP.md`; file one hands-on check for the
command buttons with `python tools/new_check.py` as the check-loop requires.
Reasoning: **medium**.

**Open decisions:** none.

```queue
**[Codex] CQ-R6 -- extract the HUD bee-command rows**
- Plan: `plans/now/code-health.md` -- "CQ-R6 -- extract the HUD bee-command rows"
- Files: `scripts/hud.gd`, `scripts/hud_command_rows.gd`, `FUNCTION_MAP.md`
- Check: `python -m unittest tests.test_layout_regression tests.test_hc8_tray_first_open tests.test_hc16_tray_reselect` and `python tools/prefinish.py` pass; a hands-on check covers the command buttons
- Proof: `present: scripts/hud.gd :: func _rebuild_role_controls(`
- Next after: CQ-M5a -- name every CanvasLayer in scripts/canvas_layers.gd
```

## CQ-M5a -- name every CanvasLayer in `canvas_layers.gd`

**Now** (verified 27 Oct 2026). The UI's stacking order is eleven bare
integers spread over ten scripts: weather 5 (`main.gd`, the weather layer in
the world build), HUD 9 and marker arrows 16 (`hud.gd`, the second already
`MARKER_ARROW_LAYER`), debug 10 (`debug_panel.gd::_ready`), the ordinary
panel 11 (`game_panel.gd::setup_layer`'s default), skill tree 14
(`skill_tree_panel.gd` `LAYER`), Gallerin 15 (`gallerin_panel.gd`'s
`setup_layer` call), main menu 20, over-the-menu 21 (debug and saves windows
while the menu shows: `debug_panel.gd::_apply_layer_for_context`,
`saves_panel.gd::_apply_menu_context`), challenge complete 24 and game over
25. `scripts/canvas_layers.gd` does not exist. `main.gd` is RR-21's,
`game_panel.gd` sits on the unmerged Jules J-14 branch, and `hud.gd` goes
to CQ-R6 first, so this slice builds the file and moves the seven readers
that are free; CQ-M5b moves the other three.

**When done.**

1. New leaf `scripts/canvas_layers.gd` (`extends RefCounted`; not
   `ui_layout.gd`, which preloads `gallerin_panel.gd` -- a cycle) holds one
   named const per layer, in ascending order, each with a short comment on
   what it must sit above: `WEATHER` 5, `HUD` 9, `DEBUG` 10, `PANEL` 11,
   `SKILL_TREE` 14, `GALLERIN` 15, `MARKER_ARROWS` 16, `MAIN_MENU` 20,
   `OVER_MENU` 21, `CHALLENGE_COMPLETE` 24, `GAME_OVER` 25. It includes the
   three only CQ-M5b reads, so the file is built once.
2. `main_menu.gd`, `challenge_complete.gd`, `game_over.gd`, `debug_panel.gd`,
   `saves_panel.gd`, `gallerin_panel.gd` and `skill_tree_panel.gd` reach it
   as `const CanvasLayers = preload("res://scripts/canvas_layers.gd")` (the
   way `levels.gd` is reached) and use the names. `skill_tree_panel.gd`'s
   `LAYER` const goes; `saves_panel.gd` passes `CanvasLayers.PANEL` to
   `setup_layer`. Comments that quote a number ("the menu's CanvasLayer
   (20)") name the const instead.
3. Every layer keeps its integer, so nothing draws in a different order.
   No display string, node name or simulation code changes.
4. `plans/reference/ui-rules.md` gains decision D2's line: canvas layers
   live in `scripts/canvas_layers.gd`, and a new layer is added there.
5. `python tools/update_function_map.py` has run.

Reasoning: **medium**. **Open decisions:** none.

```queue
**[Codex] CQ-M5a -- name every CanvasLayer in `canvas_layers.gd`**
- Plan: `plans/now/code-health.md` -- "CQ-M5a -- name every CanvasLayer in `canvas_layers.gd`"
- Files: `scripts/canvas_layers.gd`, `scripts/main_menu.gd`, `scripts/challenge_complete.gd`, `scripts/game_over.gd`, `scripts/debug_panel.gd`, `scripts/saves_panel.gd`, `scripts/gallerin_panel.gd`, `scripts/skill_tree_panel.gd`, `plans/reference/ui-rules.md`, `FUNCTION_MAP.md`
- Check: `python -m unittest tests.test_ho15_menu_hex_fit tests.test_layout_regression` and `python tools/prefinish.py` pass; `git grep -nE "layer = [0-9]|:= 14$" -- scripts/main_menu.gd scripts/challenge_complete.gd scripts/game_over.gd scripts/debug_panel.gd scripts/saves_panel.gd scripts/gallerin_panel.gd scripts/skill_tree_panel.gd` finds nothing
- Proof: `present: scripts/game_over.gd :: layer = 25`
- Next after: CQ-M5b -- the last CanvasLayer readers and the bare-layer source check
```

## CQ-M5b -- the last CanvasLayer readers and the bare-layer source check

**When CQ-M5a has landed and its gates clear.** `hud.gd` (HUD 9 and
`MARKER_ARROW_LAYER`, which goes), `main.gd` (the weather layer) and
`game_panel.gd::setup_layer`'s default read `scripts/canvas_layers.gd`, and
`tests/source_checks.py` fails any `layer = <integer>` assignment in
`scripts/` outside `canvas_layers.gd`. Integers unchanged; regenerate
`FUNCTION_MAP.md`. Re-verify the line numbers and the J-14 outcome when
claiming. Reasoning: **low**. **Open decisions:** none.

```queue-gated
**[Codex] CQ-M5b -- the last CanvasLayer readers and the bare-layer source check**
- Plan: `plans/now/code-health.md` -- "CQ-M5b -- the last CanvasLayer readers and the bare-layer source check"
- Files: `scripts/hud.gd`, `scripts/main.gd`, `scripts/game_panel.gd`, `tests/source_checks.py`, `FUNCTION_MAP.md`
- Check: `python tests/source_checks.py` passes and fails on a planted `layer = 3` in a scratch copy of `scripts/hud.gd`; `python -m unittest tests.test_layout_regression` and `python tools/prefinish.py` pass
- Proof: `present: scripts/main.gd :: weather_layer.layer = 5`
- Next after: CQ-M4 -- gated until the Claude lane releases the save files
```

## CQ-M6 -- name selection green and caste appearance

**Now.** The same selection-ring green is repeated across world scripts, with
each site choosing its own alpha. `bee.gd` also holds unnamed caste colours
and a queen size factor. The D2 classification and research record identify
these as presentation constants; `scripts/obstacle.gd` still assigns
`Color(0.2, 1.0, 0.4, 0.95)` to its selection ring on master (verified
26 Oct 2026). The Claude lane owns none of the files listed below, as checked
with `tools/slice.ps1 owner` on 26 Oct 2026.

**When done.** After CT-1 releases `scripts/hive_cell.gd`, add a leaf
`scripts/world_draw.gd` with `SELECTION_COLOUR` and
use it at the existing selection sites while preserving each site's alpha.
Name the caste colours and `QUEEN_SIZE_FACTOR` beside their present use in
`bee.gd`. Keep the rendered colours, sizes, display strings, RNG calls and
simulation outcomes unchanged. Extend the existing owner; do not add a new
drawing service. Regenerate `FUNCTION_MAP.md` if a mapped function changes.
Reasoning: **low**.

**Open decisions:** none.

```queue-gated
**[Codex] CQ-M6 -- name selection green and caste appearance**
- Plan: `plans/now/code-health.md` -- "CQ-M6 -- name selection green and caste appearance"
- Files: `scripts/world_draw.gd`, `scripts/bee.gd`, `scripts/death_marker.gd`, `scripts/flower.gd`, `scripts/hive_cell.gd`, `scripts/input_selection.gd`, `scripts/obstacle.gd`, `scripts/soil_block.gd`, `FUNCTION_MAP.md`
- Check: `python -m unittest tests.test_sp11_cell_rim tests.test_sp9_soil_art tests.test_col9_drones` and `python tools/prefinish.py` pass; rendered selection alphas and caste sizes remain unchanged
- Proof: `present: scripts/obstacle.gd :: selection_ring.default_color = Color(0.2, 1.0, 0.4, 0.95)`
- Next after: CQ-M7 -- name world draw order
```

CQ-R10 shipped 2026-10-27; its specification is `plans/archive/CQ-R10_2026-10-27.md`.

CQ-R14 shipped 2026-10-27; its specification is `plans/archive/CQ-R14_2026-10-27.md`.
