# Code-health research -- 18 Oct 2026

<!-- CONTEXT: review | LOAD: on-demand -->
Reviewed: 5b633e0 | Scope: the research behind `plans/now/code-health.md` -- measured function lengths, decompositions, save restore order, the gdtoolkit trial and the D2 slice details -- for the session that writes a later slice's queue block | Previous: none

Read only the heading for the slice you are specifying
(`python tools/heading.py docs/code-health-research-2026-10-18.md "<heading>"`).
Line numbers are hints from `5b633e0`; confirm every name and proof string with grep
before writing it into a block. Nothing here is a decision -- those are in the plan.

## Measured long functions

Real length = `func` line to the next column-0 line, trailing blanks and comments dropped;
"code" excludes comments and blanks.

| Function | linter | real | code | Notes |
| --- | --- | --- | --- | --- |
| bee::_process | 309 | 301 | 206 | hot path |
| bee::_task_line | 164 | 160 | 160 | display text; once per hud refresh for the selected bee |
| bee::idle_reason | cx 38 | 53 | -- | display text; calls `hive.create_next_cell_site()` (T2-14) |
| bee::_build_visuals | 107 | 105 | 63 | once per bee |
| hive_cell::_refresh | 203 | 199 | 141 | hot: up to 6/s per visible cell, Perf `cells` |
| hive_cell::_ready | 132 | 124 | 75 | once per cell |
| diagnostic_log::_snapshot | 180 | 176 | 154 | hourly; JSON read by tests |
| diagnostic_log::start_session | 69 | 66 | 64 | |
| main::_ready | 305 | 297 | 183 | order documented in comments |
| main::_apply_scenario_boot_arg | 128 | 126 | 75 | moves with CQ-R1 |
| main_menu::_ready | 139 | 138 | 93 | |
| hud::_build_top_right_bar / _build_goal_shelf / _build_selection_panel / _build_cell_group / _build_raises_controls | 132/98/127/103/89 | 124/93/113/99/86 | 91/71/79/81/75 | builders |
| hud::_refresh_cell_popup / _refresh_corner / _refresh_selection_text | 125/110/110 | 119/108/103 | 107/89/84 | display text |
| input_selection::_finish_drag | 106 | 105 | 93 | cx~36 |
| saving::_restore_bees | 130 | 129 | 87 | absorbed by CQ-S4 |
| challenge_complete::_ready | 98 | 88 | 76 | |
| flower::setup | 118 | 105 | 67 | |
| world_building::_seed_flower | 82 | 80 | 69 | RNG order |

Comment-heavy (code under 60, shorten only when already in the file): challenge_runner
start / _check_c2_failure / _enter_stage, debug_panel _ready / _make_section /
_make_toggle_row, gallerin_panel::_build_bubble, game_over::_ready, hud _ready /
_build_command_tray / _build_empty_controls, input_selection _unhandled_input /
_issue_command, main::_process, main_menu::_make_hex_tile, nursery_panel::_ready,
perf::_process, saving _restore / _restore_cells, skill_tree_panel::_ready,
colony_panel::_draw_plot. Mismeasured or match-inflated (leave): bee
current_working_role, carrying_text, role_name_text, _try_role_work; hive_cell
effective_build_time, add_resource; session::record_run_skill_policy; ui_theme
`PanelBox._draw`; challenge_runner::_process; hud _build_orders_row, _build_fallback_row,
_apply_cell_popup_gating; main::_parse_scenario_performance_capture;
year_winter::_refresh_recruit_gap; fog_of_war::_update (hot -- do not touch).

## Decompositions (R slices)

A pure extract-method slice removes nothing, so its proof is
`absent: <path> :: func <new_helper>(` -- every helper name here was unused at
`5b633e0` (`_c2_pollen_rescue` is taken; use `_try_c2_pollen_rescue`).

- **CQ-R3 bee readout.** `idle_reason`, `_task_line`, `role_name_text`, `carrying_text`
  move to static scripts/bee_readout.gd (the bee_* helper pattern); callers
  `hud.gd` ~3579-3615 and `world_building.gd` ~658 go through bee wrappers.
  `_task_line`: about 30 fixed strings become a `TASK_LINE_FIXED` const keyed by State;
  formatted arms stay, split per role. `idle_reason`: `_nurse_idle_reason`,
  `_comb_idle_reason`, `_miner_idle_reason`. Coverage: CQ-R0, plus
  `tests/t2_10_automine_wake_test.gd`, `tests/t2_11_comb_cadence_test.gd`.
- **CQ-R4 bee._process.** `_advance_think_clock(delta) -> float`,
  `_think_upkeep(think_delta)`, `_step_state(delta)` (the match, with its role Perf
  section), `_update_presentation(delta)` (bee_label and bee_wander blocks). Keep every
  Perf begin/end and early-return end. Fixtures: `test_scenarios/hp2_idle_nurses_perf.json`
  (sections frame_time_ms, bees, bee_state_nurse, bee_label; add bee_burn, bee_think,
  bee_state in a scratch copy) and `hp1_forager_search_perf.json` (bee_state_forager,
  bee_search). Also re-section bee.gd: the "display" section holds sim code
  (`leave_to_found_colony`, `_terrain_speed_factor`, `_is_inside_hive`,
  `_on_tree_entered`); ten empty two-line headers become one pointer comment.
- **CQ-R5 hive_cell.** `_refresh`: `_sync_label_settings()`, `_refresh_site()`,
  `_refresh_rings_and_designation()`, per-content appearance helpers writing members (no
  Dictionary per call), `_apply_cell_overlay()`, `_apply_fill_art(...)`. `_ready`:
  `_build_fill_sprites()`, `_build_rings()`, `_build_closed_mark()`. No fixture renders
  cells today (scenarios boot in the meadow, hive_root hidden, so `cells` measures brood
  only): add a copy of `spr2_render_500.json` that switches to hive view the way
  `hr2_click_view_switch_test.json` does (`click_world`), sections `["cells",
  "frame_time_ms"]`. Coverage: `tests/sp11_cell_rim_test.gd`, `nf2_fermentation.json`,
  `bb1_bee_bread.json`, CQ-R0.
- **CQ-R6 hud command rows.** Lines ~2984-3556 (bee command rows) move to
  scripts/hud_command_rows.gd; re-header the "readouts" section, which really covers
  command rows, selection text (~3557-3666) and tray sizing (~3667-3867). Keep node
  names. Coverage: `tests/test_layout_regression.py`, `test_hc8_tray_first_open`,
  `test_hc16_tray_reselect`; hands-on check of the command buttons.
- **CQ-R7 hud refreshes.** `_refresh_selection_text`: `_hide_selection_panels(prev)`,
  `_bee_identity_text(b)`, `_bee_activity_text(b)` (text + warning flag),
  `_bee_trait_text(b)`. `_refresh_cell_popup`: `_cell_content_lines`,
  `_cell_state_lines`, `_cell_raises_text`, `_sync_cell_popup_controls`.
  `_refresh_corner`: `_corner_signature`, `_rebuild_corner_stat_labels`,
  `_make_signal_row(entry)`, `_add_signal_overflow(n)`; keep its Perf sub-sections.
  Coverage: CQ-R0, `tests/gp4_problem_strip_test.gd`.
- **CQ-R8 hud builders.** `_build_cell_group`: seven copy-pasted designation buttons
  become a table + `_add_designation_button(row, key, label, tip)` (proof `present:
  scripts/hud.gd :: var nectar_btn := Button.new()`); `_build_top_right_bar` ->
  `_build_speed_row`, `_build_window_buttons_row`; `_build_selection_panel`,
  `_build_goal_shelf`, `_build_raises_controls` by sub-row. Coverage: layout regression,
  `test_gp1_goals_dropdown`, `test_gp2_goal_favourites`, `test_rr4_min_window`.
- **CQ-R9 diagnostic_log.** `_snapshot`: `_population_counts`,
  `_foraging_preference_counts`, `_cell_content_counts`, `_soil_block_counts`, one
  builder per section; `start_session`: `_open_session_file`, `_reset_counters`,
  `_write_config_line`. `_flower_season_counts`, first-tier-2-affordable and the
  top-sections code duplicate `scripts/headless/diagnostic_probes.gd`: keep them once,
  in the probes. Prove the snapshot line unchanged apart from `performance`. Coverage:
  `test_bb1_bee_bread.py`, `test_sf1_founding_flower_mix.py`, `test_headless_profiles.py`,
  `test_headless_verdicts.py`, `test_pacing_gates.py`.
- **CQ-R10 input_selection.** No section headers yet -- add them. `_unhandled_input` ->
  `_handle_key`, `_handle_mouse_button`, `_handle_mouse_motion`; `_finish_drag` ->
  `_click_pick_in_hive(p, add) -> bool`, `_click_pick_in_meadow(p) -> bool`,
  `_box_pick_comb(box, add) -> bool`, `_apply_bee_pick(picked, additive)`;
  `_issue_command` -> `_command_in_hive`, `_command_in_meadow`. Coverage: `click_world`
  scenarios (`e1_placement_exclusion_test.json`, `hr2_click_view_switch_test.json`,
  `rr1_queen_builds_test.json`); box-select, keys, wheel and right-click commands have
  none -- hands-on check.
- **CQ-R11 world_building::_seed_flower.** `_founding_birth_window(founding) -> Array`,
  `_pick_flower_anchor(species)` (with the cluster_centers bookkeeping),
  `_bush_unit_count(species, max)`, `_place_bush_unit(anchor, unit)`. RNG call order
  exactly unchanged: `tools/equivalence.py` on `sf1_founding_flower_mix_test.json`,
  `pp4_seed_set.json`, `pp1_pollination_ledger.json`.
- **CQ-R12 challenge_runner.** `start` -> `_reset_run_state`, `_reset_queen_controls`,
  `_build_stage_marker`; `_check_c2_failure` -> `_try_c2_pollen_rescue(pollen) -> bool`,
  `_c2_nectar_rescue(nectar) -> bool`, `_c2_restore_checkpoint()`, and its inline
  Gallerin line ("A colony without pollen cannot raise any bee at all...") joins
  `challenge_feedback.gd` beside `challenge_2_rescue`; `_enter_stage` ->
  `_apply_c1_stage_rules(stage)`, `_record_c2_stage_entry()`. Coverage:
  `bb4_challenge1_route.json`, `bb4_challenge2_route.json`, `challenge2_checks_test.gd`,
  `h4_challenge1_stage_advance_test.json`, `c1f1_stage_setup_test.json`; the C2
  rescue path has none.
- **CQ-R13 main::_ready.** `_create_systems`, `_build_world_roots`,
  `_build_weather_layer`, `_build_hud` (about 30 signal connections), `_build_panels`,
  `_start_run`; the comments document the order. Coverage: `rr2_boot_saves_test.gd`,
  layout regression, any scenario boot.
- **CQ-R2 first crisis.** `main.gd` ~1027-1284 becomes a `first_crisis.gd` Node owned by
  main, like `season.gd`. The save key `first_crisis` is unchanged; `save_game.gd`
  (`world.first_crisis`), `saving.gd::_restore`, `colony_diagnostics.gd` ~65, the
  `scenario_actions.gd` when-clause (~310) and the hud note wiring move. The "first
  crisis" header also covers loss, colony energy and population -- re-header those.
  Proof by `tests/test_fc2_first_crisis.py` (prepared and unprepared).
- **CQ-R14.** flower: `_init_stats`, `_build_flower_visuals`, `_build_spider_visuals`;
  bee `_build_visuals`: `_build_status_rings`, `_build_body`, `_build_heading_markers`;
  main_menu and challenge_complete by sub-widget. Coverage: boot,
  `sp1_pixel_sprite_test.gd`, `ho15_menu_hex_fit`.

## Save restore (S slices)

- **Write side.** `save_game.gd::save` 87-166 (also starting_level, settings,
  first_crisis, skill_policy, developer_changes, rival); `_bodies_data`, `_cells_data`,
  `_soil_data`, `_bees_data`, `_flowers_data`; helpers `_hex_list`, `_point_list`,
  `_cell_refs`. Read side: `saving.gd::_restore` 62-132 (order: clock, weather, totals,
  session, hud, then soil, cells, hive, flowers, rival, bees, fog, pollination,
  seed_bank, guidance, skills, then nav/index/stock, readouts, first_crisis);
  `_cells_at`/`_blocks_at` resolve `[q, r]` through `hive.occupied_tiles`.
- **Constraints.** `main.gd` ~43: `_restore` emits no `bee_died`/`day_changed`/rain
  signal -- `from_save` assigns, never calls mutators. `invalidate_index()` and
  `invalidate_stock()` stay once in `saving.gd` (`tests/source_checks.py` requires
  `main.hive.invalidate_stock()` there). `tests/test_save_migrations.py` pins exact
  lines (cells: `"drone": cell.brood_is_drone,`; bees ~517-527, including
  `bee.is_drone =` before `add_child(bee)`) -- move the pins with the code.
- **Restore order per entity** (CQ-S1 sets the pattern). Flowers: create, `add_child`,
  `setup(species)`, then `from_save` (the saved lifespan beats setup's re-roll), then
  `flower_grid.rebuild(created)`. Cells: clock and soil first; `add_child` (so `_ready`
  sets capacity and polygon) before `from_save`; `content_type` first; gyne before drone;
  `restore_bee_bread_seal` after `sealed_at`; `register_tile` after. Hive and soil marks:
  after cells, before flowers and bees. Bees: identity and position before `add_child`;
  parent chosen by `indoors`; `setup`; name and traits before `set_brood_outcome`
  (`_apply_stats` reads them); fact, state and secondary after `setup`;
  `set_forage_start_point` before the search anchor; build queue then manual build
  target; mine and restock queues last, through `occupied_tiles`.
- **S2 cells proof:** `present: scripts/saving.gd :: cell.hatch_focus = str(entry.get("hatch_focus", "nectar"))`.
  **S3 hive/soil proof:** `present: scripts/saving.gd :: main.hive._tier_credit = [float(credit[0])`
  (hive.gd gets `to_save`/`from_save` for keep_clear, tier_credit, brood_pointer, bodies
  via `clear_bodies` + `add_body`; `soil_block.gd` for its marked/progress entry; dug
  geometry and the floor-tile swap stay in `saving.gd`). **S4 bees proof:**
  `present: scripts/saving.gd :: bee.nurse_mode = str(entry.get("nurse_mode", "feed"))`
  (`main.queen`, `selected_bees`, `colony_lost`, `queen_seen_alive` stay in
  `saving.gd`; `known_patches` is `Array[Vector2]`).
- **S5 rename.** guidance_policy 37/42, colony_milestones 143/153 (restored by main.gd),
  pollination 247/252 plus `seed_save_data`/`restore_seed`, rival_hive 95/105, fog_of_war
  `explored_list` 670 / `restore` 679. Tests naming them: `test_gd2b_guidance_saved.py`,
  `test_fc2_first_crisis.py`, col7 and gp2. Stale comments: roles.gd ~26, bee.gd ~749
  and ~1133, hive.gd ~109 and ~167, hive_cell.gd ~178, ~213, ~922, save_migrations.gd
  ~12, ~23, ~78, pollination.gd ~25, ~54, fog_of_war.gd ~676.
- **Known gaps the harness may show.** `bee.setup` runs before saved fields return, so
  with `orientation_flight_on` a forager saved without `start_x` gains one on re-save;
  soil `present` and fog order follow dictionary order (compare as sets); `stats` is
  derived and write-only; colony milestones restore only on the load path.

## gdtoolkit trial (L slices)

- Run on scratch copies only. gdlint defaults: 2,052 problems (max-line-length 1,177,
  class-definitions-order 805, constant-name 18 enum aliases, max-returns 13,
  max-file-lines 12, max-public-methods 6, script-handle naming 12, duplicated-load 4,
  elif/else-return 4). With the plan's gdlintrc: 13, identical before and after
  formatting.
- gdformat: 1,613 blank-line hunks, 1,323 wrap/join hunks (dict literals one key per
  line), 497 parenthesis/trailing-comma hunks (all 20 backslash continuations), 144
  comment-alignment hunks; method chains become `(\n a\n . b(` (129 lines in 23 files).
  34 literals re-quoted, all 15,975 string values unchanged. Line length 120 or 140 does
  not avoid the parser breakage. The formatted tree boots with no script error and no new
  warning.
- After formatting, `challenge_stages.gd`, `skills.gd`, `world_building.gd` and
  `fog_of_war.gd` cross 700 lines and need `DESCRIPTIONS` entries in
  `tools/update_function_map.py` (CQ-L3). `scripts/sprite_catalogue.gd` is generated by
  `tools/sprites.py` (CQ-L2 makes it emit clean output).
- **CQ-L2 scope.** Formatting a scratch copy (`git archive HEAD`, then
  `python -m gdtoolkit.formatter`) breaks: `tests/source_checks.py` (about 70 false
  "call to undefined X()" from split method chains; about 14 catalogue readers broken by
  `"key":\nvalue` -- stage setup records, GOAL_CADENCE, roles `start_count_key`,
  resources-to-forager mode); `tools/stage_reference.py`'s `FIELD` regex (`[ ]*` where
  `\s*` is needed; proof `present: tools/stage_reference.py :: [ ]*:[ ]*`);
  `tools/update_function_map.py` `LINE_RE` (first signature line only); `tools/sprites.py`
  output; 3 of `tests/balance_tests.py`; `test_run_scenario_launch`, `test_save_migrations`,
  `test_signal_catalogue`, `test_source_checks`, `test_sp2_sprites`,
  `test_sp3_content_colours`, `test_t2_4a_cleaning_gate`. Dave's route: the call checker
  and catalogue readers read GDScript through gdtoolkit's parser; the two regexes take
  whitespace across lines; text pins go through one shared normaliser in
  `tests/workflow_test_support.py`; acceptance runs everything on the tree and on a
  formatted scratch copy. Escalate if a gdtoolkit-backed check cannot run in the Codex
  runtime; split into L2a (source checks) and L2b (tools, tests) if it outgrows a slice.
- `tools/verify.ps1`: `Invoke-PythonStage` runs a script, not `-m`, hence the wrapper.
  Python resolution order: `-PythonPath`, PATH, then Codex's runtime Python, which may
  lack gdtoolkit. The repo declares no Python dependencies.

## Typing count (T slices)

Counter: a regex port of Godot 4.7.2's rules (checked against a probe project: flags
untyped `var`, parameters including defaulted ones, missing `-> T` including `_ready`,
lambda parameters and returns, untyped signal parameters; not `:=`, `: Variant`, `const`,
`enum`, for-loop variables, match bindings, property `set(value)`).
`tools/gdscript_warnings.py` sees only scripts loaded at boot, so tests are covered by
the ratchet and, at level 2, by their `tests/test_*.py` wrappers. A runtime script error
under `-d` drops into `debug>` and waits for the 180 s timeout.

CQ-T2's files and counts (219): `main` 46, `scenario_actions` 32, `world_building` 30,
`input_selection` 29, `save_game` 15, `saving` 13, `orders_zones` 11,
`headless/diagnostic_profile` 7, `perf` 6, `settings_catalogue` 5, `challenge_runner` 5,
`save_slots` 4, `hive` 4, `diagnostic_log` 3, `tutorial_checkpoint` 2,
`developer_overrides` 2, `challenge_stage_setup` 2, `save_migrations` 1, `player_profile` 1,
`headless/diagnostic_probes` 1. Save-dictionary values are floats or `Variant`, never
`int`. Proof suggestion: `present: scripts/save_game.gd :: static func save(world, path`.
Checks: `test_save_migrations`, `test_si1_run_state`, `test_si2_exact_rollback`,
`test_layout_regression`, equivalence on `slice1_smoke_test.json`.

CQ-T3's files and counts: `hud` 116, `debug_panel` 21, `gallerin_panel` 13,
`saves_panel` 11, `colony_panel` 10, `problem_messages` 8, `main_menu` 7,
`skill_tree_panel` 5, `camera_view` 5, `nursery_panel` 4, `challenge_complete` 4,
`succession_panel` 2, `game_over` 2, `winter_panel` 1, `ui_theme` 1, `ui` 1,
`foraging_panel` 1. Mostly `-> void` on lambdas. Proof suggestion:
`absent: project.godot :: untyped_declaration=2`. Duck-typed cases: `availability.gd`'s
`progression` receives a stub `Owned.new()` in `tests/t2_2_automation_gate_test.gd`;
`bee_foraging.gd` ~1282 and `pollination.gd` ~96 stay untyped on purpose (freed objects).

## D2 slice details (M slices)

- **CQ-M3.** `rival_starting_nectar/_pollen/_forager_share/_min_population` with rows
  under "The rival colony", used by `_ready` and `restore`; `_rebalance` step and
  thresholds named beside MIN/MAX_FORAGER_SHARE; `tests/balance_tests.py` reads GameConfig
  instead of its own copies; `tests/si1_run_state_test.gd` asserts a fresh rival and
  `restore({})` give 120/40/0.7; `tests/test_save_migrations.py`. Proof `present:
  scripts/rival_hive.gd :: nectar = float(data.get("nectar", 120.0))`.
- **CQ-M4.** `levels.gd` CHALLENGE_1 := 1, CHALLENGE_2 := 2, CHALLENGE_LEVELS,
  `is_challenge()`; readers `challenge_runner.gd`, `saving.gd`, `save_game.gd`
  (CHALLENGE_LEVELS), `main.gd`, `debug_panel.gd`, `challenge_complete.gd`,
  `world_building.gd`. Proof `present: scripts/saving.gd :: if Session.starting_level in [1, 2]:`.
  Equivalence on `h4_challenge1_stage_advance_test.json`, `bb4_challenge1_route.json`.
- **CQ-M5.** New leaf scripts/canvas_layers.gd (not `ui_layout.gd`: it preloads
  gallerin_panel, a cycle). Edits `hud.gd`, `main.gd`, `main_menu.gd`, `debug_panel.gd`,
  `saves_panel.gd`, `game_over.gd`, `challenge_complete.gd`, `game_panel.gd`,
  `gallerin_panel.gd`, `skill_tree_panel.gd`; a source check forbids a numeric
  `layer = <int>` elsewhere. Proof `present: scripts/game_over.gd :: layer = 25`.
- **CQ-M6.** New leaf scripts/world_draw.gd SELECTION_COLOUR (each site keeps its
  alpha); caste colours and QUEEN_SIZE_FACTOR named in `bee.gd`. Edits `bee.gd`,
  `death_marker.gd`, `flower.gd`, `hive_cell.gd`, `input_selection.gd`, `obstacle.gd`,
  `soil_block.gd`. Proof `present: scripts/obstacle.gd :: selection_ring.default_color = Color(0.2, 1.0, 0.4, 0.95)`.
  Coverage: `sp11_cell_rim_test.gd`, `test_sp9_soil_art.py`, `col9_drones_test.gd`.
- **CQ-M7.** `world_draw.gd` gains BEES=5, RAIN=50, OVERLAY=90 and the rest; edits
  `bee.gd`, `bee_speech_bubble.gd`, `challenge_runner.gd`, `click_marker.gd`,
  `death_marker.gd`, `fog_of_war.gd`, `hive_body.gd`, `main.gd`, `pollination_pop.gd`,
  `queen_hearts_vfx.gd`, `rain_effect.gd`, `rival_hive.gd`, `world_building.gd`. Proof
  `present: scripts/fog_of_war.gd :: _layer.z_index = 90`. Report, do not change, whether
  `Shapes.hex_draw_depth` (2y+x) lets comb cells exceed the bees' 5.
- **CQ-M8.** `BeeMovement.walk_to_hive_exit(bee, delta) -> bool` and HIVE_EXIT_REACH
  (all three modules already preload BeeMovement). Proof `present: scripts/bee_mining.gd
  :: if bee.position.distance_to(exit_point) < 8.0:`. Equivalence on
  `slice1_smoke_test.json`, `bee_movement_smoke_test.json`,
  `cb1_comb_builders_per_site_test.json`; perf counters unchanged.
- **CQ-M9.** Proof `present: scripts/colony_panel.gd :: {"key": "nectar", "label": "Nectar", "colour": Color(0.95, 0.72, 0.20)},`.
- **CQ-M10.** Proof `present: scripts/main.gd :: GameConfig.rain_chance_per_day / 6.0`.
