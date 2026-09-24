# Function map

A line-numbered index of every function and section header in every
scripts/*.gd file over 700 lines. Smaller files don't need this --
grep their `# --- section ---` headers directly, per CLAUDE.md.

**How to use it:** grep this file for the function name (or the area you
want, e.g. "popup", "restock") to get its line number, then either `Read`
the source file with an offset near that line, or grep the source file
directly for the exact signature before editing. Line numbers here are a
pointer, not a guarantee -- they drift as the file changes.

**How to keep it updated:** this file is generated, not hand-maintained.
After adding, removing, renaming or moving a function in one of the files
below, run:

```
python3 tools/update_function_map.py
```

`--check` exits non-zero (and prints which files moved) instead of
writing, for a pre-commit or CI check. Whether the map was actually
regenerated after a given change is a `git log` question, not something
recorded in this file.

---

## hud.gd (3,405 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
26   # --- signals ------------------------------------------------------
110  # --- role controls ------------------------------------------------
122  static func hatch_options() -> Array
168  static func mode_command(role_id: int, mode_key: String) -> String
171  # --- shared layout constants --------------------------------------
207  # --- fields -------------------------------------------------------
507  # --- problem strip ------------------------------------------------
516  func _signal_color(severity: int) -> Color
523  # --- _ready and construction --------------------------------------
538  func _ready() -> void
597  func _on_viewport_size_changed() -> void
602  func _build_stage_marker_arrow() -> void
620  func set_stage_marker(global_position: Vector2, visible: bool, in_hive: bool) -> void
625  func _make_label(pos: Vector2, variation: String = "Body") -> Label
633  func _info(text: String) -> Button
636  func _with_info(control: Control, tip: String) -> HBoxContainer
641  func _style_button(button: BaseButton) -> BaseButton
646  # --- speed controls -----------------------------------------------
670  func _build_top_right_bar() -> void
810  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
846  func _apply_interface_label_visibility() -> void
852  # --- Challenge goal readout ---------------------------------------
857  func _build_goal_shelf() -> void
924  func set_settings_button_width(width: float) -> void
938  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
953  func set_speed_display(speed_scale: float) -> void
958  # --- bottom row ---------------------------------------------------
963  func _build_selection_panel() -> void
1075 func _build_favourite_star() -> Control
1106 func _set_favourite_star(bee) -> void
1134 func _field_control(field_name: String) -> Control
1148 func _build_selection_cog() -> Control
1176 func _set_summary_cog_kind(kind: String) -> void
1188 func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
1208 func _apply_selection_field_visibility() -> void
1237 func _resize_selection_panel_to_content() -> void
1245 # --- command tray -------------------------------------------------
1257 func _build_command_tray() -> void
1357 func _build_tray_column(title: String) -> Array
1384 # --- cell popup ---------------------------------------------------
1400 func _build_cell_group(parent: VBoxContainer) -> void
1494 func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer
1522 func _build_priority_controls(column: VBoxContainer) -> void
1559 func _build_raises_controls(column: VBoxContainer) -> void
1632 func _build_closing_controls(column: VBoxContainer) -> void
1672 func _build_empty_controls(column: VBoxContainer) -> void
1734 func _make_hatch_menu(entry: Dictionary) -> Control
1763 func _fill_hatch_menu(popup: PopupMenu, role_value: int, options: Array) -> int
1775 func _build_warning_banner() -> void
1811 func show_warning(text: String, key: String = "", min_gap: float = 0.0, severity: int = 0) -> void
1827 func _show_warning_now(text: String, severity: int) -> void
1835 func _dismiss_warning() -> void
1840 func set_warnings_muted(value: bool) -> void
1854 func show_object_summary(kind: String, data) -> void
1878 func _refresh_flower_summary() -> void
1914 func _show_obstacle_summary(obstacle: Node2D) -> void
1920 func _show_soil_summary(count: int, reachable: int) -> void
1936 func _show_death_summary(info: Dictionary) -> void
1958 func show_cell_popup(cell: Node2D, count: int = 1) -> void
1979 func _refresh_cell_popup() -> void
2089 func _apply_cell_popup_gating() -> void
2112 func _light_current_options() -> void
2130 func _set_lit(key: String, lit: bool) -> void
2141 func _process(_delta: float) -> void
2173 func _stage_marker_screen_position() -> Vector2
2177 func _update_stage_marker_arrow() -> void
2210 func _refresh_marker_exclusion_rects(viewport_size: Vector2) -> void
2221 func _append_marker_panel_exclusion(panel: Control, owner_rect: Rect2) -> void
2226 func _slide_arrow_along_edge(edge_point: Vector2, edge_bounds: Rect2) -> Vector2
2243 func _marker_arrow_obscured(point: Vector2) -> bool
2249 func _request_designation(type: String) -> void
2254 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
2259 func _request_empty(method: String) -> void
2264 func _request_priority(tier: int) -> void
2269 func _request_close(closed: bool) -> void
2274 func _request_fill_close() -> void
2279 # --- discard warning ----------------------------------------------
2285 func _build_discard_dialog() -> void
2300 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
2317 func confirm_discard(title: String, text: String, ok_text: String, cancel_text: String, action: Callable) -> void
2326 func _on_discard_confirmed() -> void
2329 func _on_discard_custom_action(action: StringName) -> void
2336 func _apply_discard() -> void
2349 # --- readouts -----------------------------------------------------
2354 func update_day(day: int, note: String = "") -> void
2364 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
2373 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
2379 func update_comb(text: String) -> void
2383 func update_energy(mean_fraction: float) -> void
2390 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
2401 func update_recruit_gap(text: String) -> void
2414 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
2420 func update_signals(lines: Array) -> void
2428 func _refresh_corner() -> void
2510 func corner_bottom() -> float
2516 func selection_panel_top() -> float
2526 func pinned_stats_changed() -> void
2535 func refresh_speed_visibility() -> void
2542 func refresh_corner() -> void
2545 func update_selection(bees: Array) -> void
2578 func _selection_has_command_lock(bees: Array) -> bool
2599 static func _detach_and_free_children(container: Node) -> void
2612 func _rebuild_role_controls(bees: Array) -> void
2662 func _build_queen_build_row(column: VBoxContainer) -> void
2676 func _build_follow_control(bees: Array, first) -> void
2691 func _build_job_row(common_role: int, any_queen: bool) -> void
2723 func _build_doing_row(common_role: int, first) -> void
2749 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2764 func _build_orders_row(common_role: int, first) -> void
2811 func _build_restock_row(first) -> void
2846 func _build_fallback_row(common_role: int, first) -> void
2896 func _secondary_items() -> Array
2912 func _column_row(parent: Container) -> HFlowContainer
2920 func _labelled_row(title: String) -> HFlowContainer
2939 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2951 func _action_button(label: String, action: Callable, tip: String) -> Control
2960 func _current_role_marker(label: String) -> Control
2975 func _common_role(bees: Array) -> int
2992 func _common_working_role(bees: Array) -> int
3010 func _make_role_menu(label: String, tip: String, items: Array, node_name: String = "") -> Control
3031 func _refresh_selection_text() -> void
3130 func _apply_selection_tray_width() -> void
3181 func _match_summary_header_button_heights() -> void
3199 func _tray_column_share(inner_width: float) -> float
3208 func _apply_even_column_widths(wrappers: Array) -> void
3236 func _update_command_tray_width() -> void
3257 func _resize_command_tray() -> void
3292 func _resettle_command_tray(generation: int, previous_content_min_y: float, stable_streak: int, pass_count: int) -> void
3307 func set_winter_button_visible(value: bool) -> void
3313 func set_view_label(in_hive: bool) -> void
3322 func set_allowed_role_keys(keys: Array) -> void
3332 func set_command_locked_bees(bees: Array) -> void
3337 func set_allowed_mode_keys(keys: Array) -> void
3347 func set_allowed_designation_keys(keys: Array) -> void
3357 func set_queen_build_button_visible(value: bool) -> void
3362 # --- stage gates --------------------------------------------------
3370 func apply_gates(stage_gate) -> void
3387 func _register_gated_control(control_name: String, getter: Callable) -> void
3395 func _apply_gate_to_control(control_name: String) -> void
3404 func _is_gate_open(control_name: String) -> bool
```

## bee.gd (2,409 lines)

A bee's dispatch loop, player commands, display text, vars.

```
23   # --- preloads and shared enums ------------------------------------
56   # --- the role action catalogue ------------------------------------
75   # --- stats copied from GameConfig ---------------------------------
86   # --- role, state and identity -------------------------------------
266  func current_working_role() -> int
269  # --- floral constancy and the search pattern ----------------------
341  # --- patch memory and species experience --------------------------
368  # --- scouting -----------------------------------------------------
392  # --- trip rates and scoring ---------------------------------------
456  # --- recruitment and dancing --------------------------------------
496  # --- build and mine queues ----------------------------------------
520  # --- flower cooldowns and predator memory -------------------------
567  # --- pathfinding inside the hive ----------------------------------
573  # --- the visual nodes ---------------------------------------------
626  # --- _ready and construction --------------------------------------
627  func _ready() -> void
775  # --- setup, stats and appearance ----------------------------------
776  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
818  func _roll_fact() -> void
832  func _default_state_for_role() -> int
854  func _base_colour() -> Color
865  func _tinted(c: Color) -> Color
880  func _apply_stats() -> void
906  func trait_text() -> String
915  func _update_role_marker() -> void
934  # --- how often a bee thinks ---------------------------------------
966  func _process(delta: float) -> void
1239 # --- life support -------------------------------------------------
1241 # --- eating -------------------------------------------------------
1243 # --- stall watchdog -----------------------------------------------
1249 func _reset_stall_watch() -> void
1252 # --- foraging -----------------------------------------------------
1254 # --- entering and leaving the hive --------------------------------
1256 # --- nursery work -------------------------------------------------
1258 # --- royal jelly ---------------------------------------------------
1260 # --- idle work dispatch --------------------------------------------
1274 func _apply_pending_role() -> bool
1286 func _is_busy() -> bool
1292 func _idle_dispatch() -> void
1318 func _maybe_break_off_secondary() -> void
1342 func _try_role_work(r: int) -> bool
1367 static func _build_actions_by_role() -> Dictionary
1382 func _action_available(action_id: String) -> bool
1392 func _action_mode_for_role(r: int) -> String
1401 # --- building -----------------------------------------------------
1403 # --- keeping cells topped up ---------------------------------------
1432 func set_restock_targets(cells: Array, resource: String) -> void
1435 func set_restock_sources(cells: Array, allowed: bool) -> void
1438 func clear_restock() -> void
1441 func has_restock_orders() -> bool
1443 # --- mining -------------------------------------------------------
1445 # --- honey making -------------------------------------------------
1447 # --- egg laying (queen only) --------------------------------------
1449 # --- player commands ----------------------------------------------
1459 func command_move_to(world_point: Vector2) -> void
1479 func command_move_through_entrance(world_point: Vector2, target_in_hive: bool) -> void
1491 func command_exit_hive() -> void
1501 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
1509 func has_forage_start_point() -> bool
1512 func set_preferred_species(species: String) -> void
1525 func set_manual_build_target(hex: Vector2i) -> void
1533 func queue_build_target(hex: Vector2i) -> void
1540 func clear_build_queue() -> void
1546 func _take_next_build_target() -> bool
1559 func set_mine_target(block: Node2D) -> void
1566 func queue_mine_target(block: Node2D) -> void
1574 func clear_mine_queue() -> void
1581 func _next_queued_block() -> Node2D
1589 func set_home_hex(hex: Vector2i) -> void
1598 func set_mine_home_hex(hex: Vector2i) -> void
1604 func _mine_reference_point() -> Vector2
1619 func command_collect_from(flower: Node2D) -> void
1635 func command_collect_from_after_exit(flower: Node2D) -> void
1648 func command_return_and_deposit() -> void
1658 func command_return_only() -> void
1664 func command_deposit_at(cell: Node2D) -> void
1677 func command_empty_cell(cell: Node2D) -> void
1689 func command_deposit_at_after_enter(cell: Node2D) -> void
1697 func resume_pending_zone_command() -> bool
1716 func _clear_pending_zone_command() -> void
1721 func set_focus(type: String) -> void
1778 func _has_deliverable_target() -> bool
1784 func set_secondary_role(new_role: int) -> void
1787 func can_take_role(new_role: int) -> bool
1797 func set_role(new_role: int) -> void
1814 func _apply_role(new_role: int) -> void
1854 func _release_everything() -> void
1871 func release_flower_reference(flower: Node2D) -> void
1877 func set_selected(value: bool) -> void
1881 # --- display ------------------------------------------------------
1883 func role_letter() -> String
1912 func challenge_vocabulary_limited() -> bool
1925 func idle_reason() -> String
1978 func task_description() -> String
2125 func _idle_backup_note() -> String
2135 func role_name_text() -> String
2161 func nurse_mode_name() -> String
2170 func architect_mode_name() -> String
2176 func carrying_text() -> String
2197 func age_days() -> float
2205 func leave_to_found_colony() -> void
2218 func days_remaining() -> float
2230 func _update_label() -> void
2250 func _update_alarm_ring() -> void
2261 func _update_heading_marker() -> void
2275 func _update_search_ring() -> void
2298 func _update_dance_ring() -> void
2331 func _update_wander_flight(delta: float) -> void
2362 func _update_dance_circle(delta: float) -> void
2376 func _terrain_speed_factor() -> float
2385 func _is_inside_hive() -> bool
2388 # --- getting round things in the meadow ---------------------------
2408 func clear_navigation_state() -> void
```

## settings_catalogue.gd (1,434 lines)

Every setting's key, label, range and tip, plus the read/write and Prerequisites-cascade functions the window is a view of.

```
22   # --- preloads and collection order --------------------------------
48   # --- the tunables table -------------------------------------------
1309 # --- settings owned by Session ------------------------------------
1323 # --- reading and writing a setting --------------------------------
1324 static func setting_get(key: String)
1327 static func setting_set(key: String, value) -> void
1334 # --- resetting ----------------------------------------------------
1351 static func reset_config_to_defaults() -> void
1363 static func reset_config_keys(keys: Array) -> void
1369 # --- applying a setting with its cascades -------------------------
1378 static func apply_setting(key: String, value) -> void
1389 # --- the cascade helpers ------------------------------------------
1394 static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1412 static func _cascade_dependents_off_static(key: String) -> Array[String]
1426 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
```

## scenario_actions.gd (1,426 lines)

The headless verbs, `when` clauses and layout assertions.

```
25   # --- preloads -----------------------------------------------------
48   # --- run_pending --------------------------------------------------
54   static func run_pending(main: Node2D, actions: Array) -> void
83   # --- the comb build-site sampler ----------------------------------
93   static func sample_comb_build_sites(main: Node2D) -> void
132  # --- log_unresolved -----------------------------------------------
139  static func log_unresolved(actions: Array) -> void
146  # --- the settle, wait and window helpers --------------------------
158  static func _do_settle(action: Dictionary) -> bool
171  static func _do_wait(action: Dictionary) -> bool
186  static func _assert_window_closed(main: Node2D, action: Dictionary) -> bool
199  static func _sample_queen_watch(main: Node2D) -> void
206  # --- _execute -----------------------------------------------------
208  static func _execute(main: Node2D, action: Dictionary) -> void
262  # --- triggers -----------------------------------------------------
272  static func _when_met(main: Node2D, when: Dictionary) -> bool
313  static func _legacy_when_spec(main: Node2D, when: Dictionary) -> Dictionary
364  # --- selectors ------------------------------------------------------
368  static func _resolve_bees(main: Node2D, target: Dictionary) -> Array
400  static func _resolve_cell_ref(main: Node2D, ref: Dictionary) -> Node2D
407  static func _resolve_cell(main: Node2D, hex: Array) -> Node2D
417  static func _resolve_soil_block(main: Node2D, hex: Array) -> Node2D
427  # --- verbs ------------------------------------------------------------
444  static func _do_assign_role(main: Node2D, action: Dictionary) -> void
500  static func _do_designate_cell(main: Node2D, action: Dictionary) -> void
524  static func _do_queue_build(main: Node2D, action: Dictionary) -> void
550  static func _do_queue_mine(main: Node2D, action: Dictionary) -> void
575  static func _do_request_placement_tool(main: Node2D, action: Dictionary) -> void
587  static func _do_click_world(main: Node2D, action: Dictionary) -> void
613  static func _do_set_config(_main: Node2D, action: Dictionary) -> void
627  static func _do_hatch_role(main: Node2D, action: Dictionary) -> void
644  static func _do_set_restock_order(main: Node2D, action: Dictionary) -> void
690  static func _do_select_bees(main: Node2D, action: Dictionary) -> void
721  static func _do_select_soil(main: Node2D, action: Dictionary) -> void
747  static func _do_select_cell(main: Node2D, action: Dictionary) -> void
770  static func _do_open_window(main: Node2D, action: Dictionary) -> void
814  static func _do_close_window(main: Node2D, action: Dictionary) -> void
827  static func _do_viewport_size(main: Node2D, action: Dictionary) -> void
840  static func _do_show_gallerin_prompt(main: Node2D, action: Dictionary) -> void
856  static func _do_retreat_challenge_stage(main: Node2D, action: Dictionary) -> void
875  static func _do_advance_challenge_stage(main: Node2D, action: Dictionary) -> void
901  static func _do_set_queen_load(main: Node2D, action: Dictionary) -> void
933  static func _do_set_cell_contents(main: Node2D, action: Dictionary) -> void
957  static func _do_empty_cell(main: Node2D, action: Dictionary) -> void
971  static func _do_watch_queen_states(main: Node2D, action: Dictionary) -> void
986  static func _do_save_run(main: Node2D, action: Dictionary) -> void
993  static func _do_restore_slot(main: Node2D, action: Dictionary) -> void
1004 # --- assertion checks -------------------------------------------------
1014 static func _do_assert(main: Node2D, action: Dictionary) -> bool
1024 static func _evaluate_assert_condition(main: Node2D, condition: Dictionary) -> Dictionary
1047 static func _check_save_slot(main: Node2D, condition: Dictionary) -> Dictionary
1075 static func _check_all_actions_available(main: Node2D) -> Dictionary
1087 static func _queen_summary(main: Node2D, condition: Dictionary) -> String
1115 static func _check_panel_rect(main: Node2D, condition: Dictionary) -> Dictionary
1206 static func _resolve_named_panel(main: Node2D, name: String) -> Control
1220 static func _game_panel(main: Node2D, key: String) -> GamePanel
1241 static func _check_control_rect(main: Node2D, condition: Dictionary) -> Dictionary
1290 static func _label_leading(control: Control) -> Dictionary
1304 static func _check_even_columns(main: Node2D, condition: Dictionary) -> Dictionary
1344 static func _check_no_collapsed_controls(main: Node2D, condition: Dictionary) -> Dictionary
1361 static func _check_no_empty_labels(main: Node2D, condition: Dictionary) -> Dictionary
1372 static func _collect_empty_labels(node: Node, out: Array) -> void
1378 static func _collect_collapsed_controls(node: Node, out: Array) -> void
1398 static func _resolve_scoped_path(main: Node2D, path: String) -> Node
1425 static func _log(do: String, target_desc: String, result: String, reason: String) -> void
```

## bee_foraging.gd (1,411 lines)

The forager's search, scouting, recruitment and species-preference
behaviour.

```
8    # --- preloads and constants ---------------------------------------
24   # --- the autonomous-state choke point -----------------------------
40   static func autonomous_state(bee: Node2D, next: int) -> int
44   # --- capacity, rates and hive-side points -------------------------
45   static func max_capacity(bee: Node2D) -> float
49   static func collection_rate(bee: Node2D) -> float
57   static func _random_point_near_hive(bee: Node2D) -> Vector2
69   static func _jittered_point(base: Vector2, radius: float) -> Vector2
75   # --- orientation flights ------------------------------------------
81   static func take_orientation_flight(bee: Node2D) -> void
92   # --- seeking a flower ---------------------------------------------
99   static func seek_flower(bee: Node2D) -> void
136  static func start_seek_flower(bee: Node2D) -> bool
151  static func _walk_out_if_indoors(bee: Node2D) -> bool
160  static func _start_searching(bee: Node2D) -> void
179  # --- searching the meadow -----------------------------------------
188  static func search_for_flower(bee: Node2D, delta: float) -> void
235  static func advance_search_waypoint(bee: Node2D) -> void
251  static func _perceive_flower(bee: Node2D) -> Node2D
258  static func _commit_to_flower(bee: Node2D, flower: Node2D) -> void
266  # --- patch memory and the search spiral ---------------------------
272  static func _remember_patch(bee: Node2D, position: Vector2) -> void
285  static func _pick_known_patch(bee: Node2D) -> Vector2
309  static func _spiral_point(bee: Node2D, anchor: Vector2, angle: float) -> Vector2
321  # --- choosing a flower --------------------------------------------
339  static func nearest_flower(bee: Node2D, strict: bool, radius: float, allow_full_scan: bool = true) -> Node2D
436  static func _weighted_flower_choice(bee: Node2D, nodes: Array, accept: Callable, radius: float) -> Node2D
474  static func flower_grid(bee: Node2D)
489  # --- inspecting, drinking and sheltering --------------------------
490  static func start_inspecting(bee: Node2D) -> void
495  static func inspect(bee: Node2D, delta: float) -> void
518  static func needs_a_drink(bee: Node2D) -> bool
526  static func drink_at_flower(bee: Node2D, delta: float) -> void
551  static func nectar_strength(_bee: Node2D) -> float
559  static func shelter(bee: Node2D, _delta: float) -> void
564  # --- skill-or-setting behaviour switches ---------------------------
569  static func tarsal_markers_on() -> bool
572  static func orientation_flight_on() -> bool
576  # --- accepting or rejecting a flower ------------------------------
577  static func worth_feeding(bee: Node2D, f: Node2D) -> bool
590  static func reject_flower(bee: Node2D) -> void
608  # --- collecting ---------------------------------------------------
609  static func start_collecting(bee: Node2D) -> void
682  static func _handling_experience_scale(bee: Node2D, species: String) -> float
691  static func collect(bee: Node2D, delta: float) -> void
740  static func finish_collecting(bee: Node2D) -> void
779  # --- entering the hive and depositing -----------------------------
783  static func enter_hive(bee: Node2D) -> void
810  static func approach_cell(bee: Node2D, cell: Node2D, delta: float) -> int
825  static func release_cell_slot(bee: Node2D) -> void
832  static func go_to_deposit_cell(bee: Node2D, delta: float) -> void
919  static func finish_depositing(bee: Node2D) -> void
956  # --- scoring a trip -----------------------------------------------
961  static func _score_trip(bee: Node2D) -> void
1039 # --- leaving the hive ---------------------------------------------
1040 static func go_to_exit(bee: Node2D, delta: float) -> void
1083 static func _entrance_wait_spot(bee: Node2D, side: int) -> Vector2
1095 static func _leave_hive_and_resume(bee: Node2D) -> void
1122 static func _send_to_scout_point(bee: Node2D) -> void
1133 # --- scouting -----------------------------------------------------
1139 static func start_scouting(bee: Node2D) -> void
1157 # --- waiting at the entrance --------------------------------------
1162 static func wait_at_entrance(bee: Node2D, delta: float) -> void
1266 # --- the recruitment dance ----------------------------------------
1274 static func _update_dance_eligibility(bee: Node2D) -> void
1298 static func check_dance_proximity(bee: Node2D, _delta: float) -> void
1323 static func _start_dance(mentor: Node2D, seeker: Node2D) -> void
1343 static func dance(bee: Node2D, delta: float) -> void
1355 static func _end_dance(bee: Node2D) -> void
1377 static func _complete_dance(mentor: Node2D, seeker: Node2D) -> void
1404 # --- remote deposit -----------------------------------------------
1406 static func deposit_everything_remotely(bee: Node2D) -> void
```

## challenge_runner.gd (1,246 lines)

The stage machine, goal checks and stage effects.

```
33   # --- signals and preloads -----------------------------------------
65   # --- fields -------------------------------------------------------
164  # --- _ready and the current stage ---------------------------------
165  func _ready() -> void
168  func _reset_c2_pollen_rescue() -> void
171  func _stages() -> Array
176  func current_stage_instruction() -> String
183  func current_stage_id() -> String
191  func current_stage_goal_text() -> String
196  func can_debug_retreat_stage() -> bool
199  func can_debug_advance_stage() -> bool
202  # --- skill grants, bans and delays --------------------------------
209  func run_skill_grants() -> Array
212  func run_skill_bans() -> Array
215  func run_skill_delays() -> Dictionary
218  # --- starting and the per-frame loop ------------------------------
219  func start() -> void
303  func _process(delta: float) -> void
335  # --- goal polling -------------------------------------------------
343  func _should_check_goal(goal_id: String, goal_tick_due: bool) -> bool
360  # --- Challenge 2 failure and rescue -------------------------------
366  func _check_c2_failure() -> void
426  func _c2_index(stage_id: String) -> int
432  # --- entering a stage ---------------------------------------------
437  func _stage_unlock_keys(entries: Array) -> Array
458  func _queen_allowed_role_ids(entries: Array) -> Array
466  func _enter_stage() -> void
530  # --- counting cells -----------------------------------------------
531  func _built_cell_count() -> int
540  func _brood_cell_count() -> int
547  # --- ordered visits -----------------------------------------------
551  func _hive_inspection_points() -> Array
565  func _meadow_inspection_points() -> Array
577  func _begin_ordered_visit(points: Array, marker_parent: Node2D) -> void
583  func _clear_ordered_visit() -> void
588  func _ordered_visit_complete(traveller: Node2D) -> bool
601  func _show_current_visit_point() -> void
612  # --- the stage marker ---------------------------------------------
617  func _update_marker(stage_id: String) -> void
655  func _set_marker_visible(value: bool) -> void
679  func _publish_marker_to_hud() -> void
686  # --- advancing, leaving and completing a stage --------------------
691  func _show_goal(stage: Dictionary) -> void
698  func _advance() -> void
713  func _leave_stage() -> Dictionary
723  func _run_stage_effects(effects: Array) -> void
761  func debug_advance_stage() -> void
778  func debug_retreat_stage() -> void
788  func _complete() -> void
847  # --- the queen's build site ---------------------------------------
848  func on_queen_build_site_chosen(hex: Vector2i) -> void
860  # --- gating the UI ------------------------------------------------
869  func _apply_stage_gate_to_ui() -> void
902  func _on_gate_unlocked(_key: String) -> void
908  func is_bee_command_locked(bee: Node2D) -> bool
911  # --- the opening tunnel -------------------------------------------
917  func _setup_opening_tunnel() -> void
957  func _drive_opening_mine() -> void
969  func _opening_tunnel_cleared() -> bool
977  # --- Challenge 1 forage effects and overflow ----------------------
985  func _drive_c1_forage_effects() -> void
1013 func discards_overflow(bee: Node2D) -> bool
1028 func announce_overflow_discard(focus_switch: bool = false) -> void
1050 func _drive_c1_pollen_cell_nectar_prompt(delta: float) -> void
1064 # --- the new worker's greeting ------------------------------------
1070 func on_worker_hatched(bee: Node2D) -> void
1092 func _drive_greeting(delta: float) -> void
1106 # --- goal checks --------------------------------------------------
1129 func _goal_met(goal: String) -> bool
1141 func _goal_check_entrance_tunnel_cleared() -> bool
1144 func _goal_check_queen_reached_cavity() -> bool
1149 func _goal_check_queen_selected() -> bool
1152 func _goal_check_hive_points_visited() -> bool
1155 func _goal_check_nectar_target() -> bool
1161 func _goal_check_pollen_target() -> bool
1167 func _goal_check_queen_reached_meadow() -> bool
1170 func _goal_check_meadow_points_visited() -> bool
1173 func _goal_check_first_flower_collected() -> bool
1176 func _goal_check_second_flower_collected() -> bool
1179 func _goal_check_harvest_deposited() -> bool
1182 func _goal_check_new_bee_selected() -> bool
1188 func _goal_check_new_bee_left_hive() -> bool
1191 func _goal_check_complete() -> bool
1194 # --- Challenge 2 ---------------------------------------------
1195 func _goal_check_nectar_stabilized() -> bool
1202 func _goal_check_persistent_designation_used() -> bool
1210 func _goal_check_comb_worker_building() -> bool
1214 func _goal_check_miner_expansion() -> bool
1221 # --- goal progress readouts ---------------------------------------
1227 func _goal_progress(goal: String) -> Dictionary
1236 func _custom_goal_progress(method: String) -> Dictionary
```

## main.gd (1,191 lines)

Per-frame entry point, everything not yet split out of main.

```
37   # --- signals ------------------------------------------------------
51   # --- preloads and boot constants ----------------------------------
93   # --- delegate systems ---------------------------------------------
123  # --- world and meadow constants -----------------------------------
184  # --- state --------------------------------------------------------
327  # --- _ready and construction --------------------------------------
328  func _ready() -> void
584  # --- public surface other scripts call directly -------------------
591  func is_on_screen(node: Node2D) -> bool
594  func hive_entrance_inside() -> Vector2
597  func entrance_wait_point(side: int) -> Vector2
600  func move_bee_into_hive(bee: Node2D) -> void
603  func move_bee_out_of_hive(bee: Node2D) -> void
606  func mark_death(bee: Node2D) -> void
614  func _on_bee_died(bee: Node2D) -> void
618  func finish_mining(block: Node2D) -> void
621  func save_run() -> void
624  func begin_winter_countdown() -> void
627  # --- per-frame ----------------------------------------------------
637  func _process(delta: float) -> void
719  # --- the frame rate readout ----------------------------------------
738  func _sample_fps() -> void
761  func _reseed_meadow(delta: float) -> void
776  func _hatch_ready_brood() -> void
808  func _advance_weather(delta: float) -> void
838  func _apply_rain_overlay() -> void
853  func _check_for_loss() -> void
875  func _check_colony_energy(delta: float) -> void
906  func invalidate_population() -> void
917  func _role_counts(bees = null) -> Dictionary
934  func _update_population_readout(bees = null) -> void
946  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
952  func _prune_selection() -> void
965  func _on_restart_after_loss() -> void
971  func _on_level_chosen(level: int) -> void
984  func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
1002 func _apply_scenario_boot_arg() -> void
1124 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1164 func _is_whole_number(value: Variant) -> bool
1178 func _end_scenario_run(outcome: String) -> void
```

## diagnostic_log.gd (1,179 lines)

The session JSONL writer, counters and capture profiles.

```
18   # --- preloads and constants ---------------------------------------
27   # --- session state ------------------------------------------------
77   # --- the running counters -----------------------------------------
128  # --- _ready and the session lifecycle -----------------------------
129  func _ready() -> void
137  func _notification(what: int) -> void
142  func start_session() -> void
208  # --- death and predation ------------------------------------------
209  func log_death(bee: Node2D) -> void
242  func log_crab_spider_event(bee: Node2D, flower: Node2D, outcome: String) -> void
257  # --- recruitment and scouting -------------------------------------
267  func log_recruitment_match(seeker: Node2D, mentor: Node2D, via: String = "queue") -> void
300  func log_recruitment_followup(bee: Node2D, trip_index: int, trip_rate: float) -> void
322  func count_recruit_partner_overlap() -> void
332  func log_forager_settled(bee: Node2D) -> void
350  func log_orientation_flight(bee: Node2D) -> void
363  # --- flowers and foraging counters --------------------------------
367  func count_flower_visit(flower: Node2D) -> void
376  func record_handling_visit(species: String, prior_experience: int, seconds: float) -> void
390  func count_forager_delivery(amount: float) -> void
397  func count_flower_senescence() -> void
404  func count_flower_senescence_loss(nectar: float, pollen: float) -> void
409  func _experience_bucket(prior_experience: int) -> String
421  # --- tarsal marks -------------------------------------------------
422  func count_tarsal_mark() -> void
431  func count_tarsal_rejection() -> void
435  # --- movement and stalls ------------------------------------------
443  func log_stall_recovery(bee: Node2D, goal: Vector2) -> void
472  func log_build_target(bee: Node2D, cell: Node2D, transition: String, reason: String,
497  func log_forager_return(bee: Node2D, phase: String, required_energy: float) -> void
507  func log_flight_start_resolved(bee: Node2D, source: String, requested: Vector2, resolved: Dictionary) -> void
519  func _nearby_obstacle_identity(bee: Node2D) -> String
542  func log_scouting_settled(bee: Node2D) -> void
557  # --- brood, comb and honey counters -------------------------------
560  func count_brood_feed() -> void
567  func count_brood_hatch(role: int, mode: String) -> void
574  func count_jelly_batch() -> void
579  func count_larval_death() -> void
585  func count_cell_completed() -> void
590  func cell_completed_count() -> int
596  func count_cell_cleaned() -> void
603  func count_cell_evicted() -> void
609  func count_cell_restocked() -> void
615  func count_block_mined() -> void
621  func count_honey_batch_deposited() -> void
627  func count_cell_ripened() -> void
631  # --- player actions and commands ----------------------------------
636  func log_action(do: String, target_desc: String, result: String, reason: String) -> void
652  func log_command_issue(selected_count: int, commandable_count: int, branch: String,
681  func log_selection_panels_hidden(source: String, shown_count: int, selected_count: int) -> void
693  # --- reading events back ------------------------------------------
700  func event_count(type: String, subtype: String = "") -> int
743  # --- the per-frame tick and session end ---------------------------
748  func tick(delta: float, world: Node2D) -> void
782  func end_session(outcome: String) -> void
839  # --- configuration ------------------------------------------------
840  func session_path() -> String
844  func set_queen_alive(alive: bool) -> void
848  func configure_scenario_diagnostics(raw: Variant) -> bool
857  func configure_performance_capture(config: Dictionary) -> void
861  func effective_diagnostics() -> Dictionary
867  func _snapshot_interval() -> float
880  func _selected_snapshot(world: Node2D) -> Dictionary
886  # --- building entries -----------------------------------------------
890  func _config_snapshot() -> Dictionary
898  # --- the snapshot -------------------------------------------------
899  func _snapshot(world: Node2D) -> Dictionary
1066 func _flower_season_counts(world: Node2D) -> Dictionary
1092 func _performance_snapshot(world: Node2D) -> Dictionary
1112 func _rate(world: Node2D, key: String) -> float
1124 # --- writing to disk ----------------------------------------------
1128 func _current_day() -> int
1132 func _prune_old_sessions() -> void
1150 func _write(entry: Dictionary) -> void
1159 func _capture_entry(entry: Dictionary) -> bool
```

## hive_cell.gd (1,149 lines)

One cell: contents, brood, honey ripening, how it draws.

```
151  func effective_build_time() -> float
258  func _ready() -> void
377  func set_overlay(mode: String) -> void
383  func _overlay_colour() -> Array
421  func set_selected(value: bool) -> void
433  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
444  func _set_outline_points(line: Line2D, size: float) -> void
455  func _silhouette_point_to_local(p: Vector2) -> Vector2
467  func _set_outline_points_cup(line: Line2D, size: float) -> void
483  func _apply_outline_points(line: Line2D, size: float) -> void
491  func _set_selection_ring_points() -> void
510  func _process(delta: float) -> void
534  func _develop_brood(delta: float) -> void
555  func _health_factor() -> float
563  func _larva_dies() -> void
579  func _invalidate_hive_index() -> void
589  func _invalidate_stock() -> void
603  func bump_display_epoch() -> void
606  # --- working positions --------------------------------------------
611  func claim_slot(bee: Node2D) -> int
622  func release_slot(bee: Node2D) -> void
629  func has_free_slot() -> bool
638  func slot_position(index: int) -> Vector2
650  # --- building -----------------------------------------------------
652  func start_as_site() -> void
657  func claim_builder(bee: Node2D) -> void
661  func release_builder(bee: Node2D) -> void
667  func add_build_progress(delta: float) -> void
678  func build_fraction() -> float
681  # --- contents -----------------------------------------------------
683  func is_empty() -> bool
688  func capacity_for(resource_type: String) -> float
696  func accepts(resource_type: String) -> bool
715  func is_nursery_cell() -> bool
718  func space_for(resource_type: String) -> float
734  func needs_eviction() -> bool
752  func add_resource(resource_type: String, requested: float) -> float
784  func take_resource(resource_type: String, requested: float) -> float
812  func can_withdraw() -> bool
817  func set_closed(value: bool) -> void
824  func set_fill_then_close(value: bool) -> void
833  func fill_fraction() -> float
840  func set_designation(resource_type: String, explicit: bool = true) -> void
848  # --- honey ---------------------------------------------------------
850  func is_ripe_honey() -> bool
854  func needs_fanning() -> bool
859  func add_fanning_progress(delta: float) -> void
869  func ripen_fraction() -> float
872  # --- brood ---------------------------------------------------------
874  func start_brood(as_gyne: bool = false) -> void
888  func develop_time() -> float
896  func feed_brood(seconds: float, on_honey: bool) -> void
901  func needs_feeding() -> bool
905  func seconds_until_death() -> float
910  # --- clearing a dead larva ------------------------------------------
912  func needs_cleaning() -> bool
918  func add_clean_progress(delta: float) -> bool
924  func clean_fraction() -> float
927  func brood_ready() -> bool
930  func clear_cell() -> void
944  # --- display ------------------------------------------------------
949  func _resource_outline_colour(resource_type: String) -> Color
963  func _refresh() -> void
1100 func _designation_tag() -> String
1122 func _priority_mark() -> String
1135 func _apply_fill_shading() -> void
1146 func development_percent() -> float
```

## hive.gd (1,049 lines)

The comb as a whole: cells, navigation, finding a cell.

```
50   func add_entrance_mentor(bee: Node2D) -> void
54   func remove_entrance_mentor(bee: Node2D) -> void
71   func add_dance_eligible_mentor(bee: Node2D) -> void
75   func remove_dance_eligible_mentor(bee: Node2D) -> void
78   func add_dance_eligible_seeker(bee: Node2D) -> void
82   func remove_dance_eligible_seeker(bee: Node2D) -> void
85   func record_collection(resource_type: String, amount: float) -> void
91   func record_birth() -> void
94   # --- cell index ---------------------------------------------------
113  func _content_index() -> Dictionary
150  func invalidate_index() -> void
153  func cells_holding(content: String) -> Array
170  func invalidate_stock() -> void
173  func _stock() -> Dictionary
203  func register_tile(hex: Vector2i, node: Node2D) -> void
209  func invalidate_mining_work() -> void
213  func _advance_mining_work_epoch() -> void
216  func tile_is_free(hex: Vector2i) -> bool
221  func tile_is_interior(hex: Vector2i) -> bool
226  func cell_at_tile(hex: Vector2i) -> Node2D
232  func _ready() -> void
242  func deposit(resource_type: String, amount: float) -> float
261  func take(resource_type: String, amount: float) -> float
276  func take_energy(energy_wanted: float) -> float
289  func total(resource_type: String) -> float
295  func total_sealed() -> float
299  func total_honey() -> float
302  # --- finding cells ------------------------------------------------
315  func find_cell_for(resource_type: String, except: Node2D = null) -> Node2D
339  func find_designated_cell_for(resource_type: String, except: Node2D = null) -> Node2D
377  func find_empty_cell() -> Node2D
423  func _lay_by_priority(pool: Array) -> Node2D
454  func _tier_weights() -> Array
469  func record_lay(cell: Node2D) -> void
483  func zone_summary() -> Dictionary
513  func brood_stage_counts() -> Dictionary
528  func find_food_cell(except: Node2D = null) -> Node2D
545  func has_room_for_egg() -> bool
548  func find_cell_with(resource_type: String) -> Node2D
561  func find_brood_cell() -> Node2D
576  func find_cell_needing_fanning() -> Node2D
584  func find_honey_target() -> Node2D
587  func find_unfinished_cell() -> Node2D
596  func find_cell_needing_cleaning() -> Node2D
600  func find_cell_needing_eviction() -> Node2D
608  func has_gyne_brood() -> bool
616  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
619  # --- growing the comb ---------------------------------------------
653  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
687  func set_keep_clear(hex: Vector2i, value: bool) -> void
693  func is_keep_clear(hex: Vector2i) -> bool
700  func can_build_on(hex: Vector2i) -> bool
703  func _can_build_on(hex: Vector2i) -> bool
706  func _start_site_at(hex: Vector2i) -> Node2D
728  func create_cell_site_at(hex: Vector2i) -> Node2D
733  # --- navigation ---------------------------------------------------
744  func build_navigation() -> void
785  func _is_solid(hex: Vector2i) -> bool
791  func _tile_cost(hex: Vector2i) -> float
794  func tile_is_walkable(hex: Vector2i) -> bool
803  func nearest_walkable_point(point: Vector2) -> Vector2
830  func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
864  func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
888  func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
902  # --- mining -------------------------------------------------------
911  func refresh_edge_flags() -> void
933  func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
961  func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
985  func _is_markable_block(node) -> bool
992  func mine_stand_hex(block: Node2D)
1015 func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
1037 func remove_block(block: Node2D, floor_maker: Callable) -> void
1048 func announce() -> void
```

## debug_panel.gd (1,021 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
20   # --- preloads -----------------------------------------------------
34   # --- fields -------------------------------------------------------
69   # --- _ready and construction --------------------------------------
72   func _style_button(button: BaseButton) -> BaseButton
77   func _ready() -> void
191  func _apply_panel_width() -> void
196  func _report_settings_button_width() -> void
201  # --- collections and sections -------------------------------------
202  func _rows_in(category: String) -> Array
224  func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
255  func _set_open(header: Button, body: Control, label: String, open: bool) -> void
263  func open_to_categories(categories: Array) -> void
283  func collapse_all() -> void
291  func _make_section(category: String, entries: Array, start_open: bool) -> Control
347  # --- the Challenge stage navigator --------------------------------
352  func _make_challenge_stage_navigation() -> Control
390  func _process(_delta: float) -> void
393  func _refresh_challenge_stage_navigation() -> void
412  # --- the controls help --------------------------------------------
418  func _make_controls_help() -> Control
463  # --- the action buttons -------------------------------------------
475  func _build_actions(column: VBoxContainer) -> void
543  func _add_action_row(parent: Control, button: Button, tip: String) -> void
549  func _make_winter_action() -> Control
561  func _on_winter_pressed() -> void
567  func _on_challenge_advance_pressed() -> void
574  func _on_challenge_retreat_pressed() -> void
588  func _on_fire_test_warnings_pressed() -> void
621  func _on_force_c2_collapse_pressed() -> void
635  # --- save and load ------------------------------------------------
641  func set_save_load_enabled(enabled: bool) -> void
649  func set_toggle(key: String, value: bool) -> void
654  func _on_save_pressed() -> void
665  func _on_load_pressed() -> void
683  # --- showing and hiding the panel ---------------------------------
684  func _toggle_panel() -> void
698  func _apply_layer_for_context() -> void
703  # --- building a settings row --------------------------------------
704  func _make_row(entry: Dictionary) -> Control
747  func _make_control_slot() -> HBoxContainer
756  func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
786  func _make_toggle_row(entry: Dictionary) -> Control
857  func _make_options_row(entry: Dictionary) -> Control
890  func _option_display(entry: Dictionary, value) -> String
894  func _cycle_option(entry: Dictionary, direction: int) -> void
905  # --- prerequisite cascades ----------------------------------------
909  func _cascade_prerequisites_on(key: String) -> void
923  func _cascade_dependents_off(key: String) -> void
931  func _cascade_mutual_exclusion(key: String) -> void
936  # --- star rows and value editing ----------------------------------
941  func _make_star_row(entry: Dictionary) -> Control
982  func _adjust(entry: Dictionary, delta: float) -> void
996  func _format_value(v) -> String
1003 # --- restart and main menu ----------------------------------------
1004 func _on_restart_pressed() -> void
1009 func _on_main_menu_pressed() -> void
1017 func _restart() -> void
```

## game_config.gd (891 lines)

The balance fields.

```
8    # --- world ---
30   # --- flowers (per-species values are in flower.gd; these scale them) ---
412  # --- foraging ---
421  # --- hive ---
448  # --- the nursery zone ---
509  # --- eating ---
517  # --- flight ---
548  # --- gynes ---
563  # --- royal jelly ---
573  # --- weather ---
591  # --- warnings ---
600  # --- honey ---
616  # --- comb building ---
636  # --- hive geometry ---
665  # --- bee life ---
670  # --- bee individuality ---
749  # --- the rival colony ---
798  # --- seasons ---
830  # --- disease ---
858  # --- gynes leaving ---
865  # --- winter ---
```
