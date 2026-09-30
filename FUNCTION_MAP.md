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

## hud.gd (3,435 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
26   # --- signals ------------------------------------------------------
112  # --- role controls ------------------------------------------------
124  static func hatch_options() -> Array
170  static func mode_command(role_id: int, mode_key: String) -> String
173  # --- shared layout constants --------------------------------------
209  # --- fields -------------------------------------------------------
510  # --- problem strip ------------------------------------------------
519  func _signal_color(severity: int) -> Color
526  # --- _ready and construction --------------------------------------
541  func _ready() -> void
600  func _on_viewport_size_changed() -> void
605  func _build_stage_marker_arrow() -> void
623  func set_stage_marker(global_position: Vector2, visible: bool, in_hive: bool) -> void
628  func _make_label(pos: Vector2, variation: String = "Body") -> Label
636  func _info(text: String) -> Button
639  func _with_info(control: Control, tip: String) -> HBoxContainer
644  func _style_button(button: BaseButton) -> BaseButton
649  # --- speed controls -----------------------------------------------
673  func _build_top_right_bar() -> void
812  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
848  func _apply_interface_label_visibility() -> void
854  # --- Challenge goal readout ---------------------------------------
859  func _build_goal_shelf() -> void
926  func set_settings_button_width(width: float) -> void
940  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
955  func set_speed_display(speed_scale: float) -> void
960  # --- bottom row ---------------------------------------------------
965  func _build_selection_panel() -> void
1092 func _build_favourite_star() -> Control
1123 func _set_favourite_star(bee) -> void
1151 func _field_control(field_name: String) -> Control
1165 func _build_selection_cog() -> Control
1193 func _set_summary_cog_kind(kind: String) -> void
1205 func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
1225 func _apply_selection_field_visibility() -> void
1254 func _resize_selection_panel_to_content() -> void
1262 # --- command tray -------------------------------------------------
1274 func _build_command_tray() -> void
1374 func _build_tray_column(title: String) -> Array
1401 # --- cell popup ---------------------------------------------------
1417 func _build_cell_group(parent: VBoxContainer) -> void
1511 func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer
1539 func _build_priority_controls(column: VBoxContainer) -> void
1576 func _build_raises_controls(column: VBoxContainer) -> void
1649 func _build_closing_controls(column: VBoxContainer) -> void
1689 func _build_empty_controls(column: VBoxContainer) -> void
1751 func _make_hatch_menu(entry: Dictionary) -> Control
1780 func _fill_hatch_menu(popup: PopupMenu, role_value: int, options: Array) -> int
1792 func _build_warning_banner() -> void
1828 func show_warning(text: String, key: String = "", min_gap: float = 0.0, severity: int = 0) -> void
1844 func _show_warning_now(text: String, severity: int) -> void
1852 func _dismiss_warning() -> void
1857 func set_warnings_muted(value: bool) -> void
1871 func show_object_summary(kind: String, data) -> void
1898 func _refresh_flower_summary() -> void
1934 func _show_obstacle_summary(obstacle: Node2D) -> void
1940 func _show_soil_summary(count: int, reachable: int) -> void
1953 func _show_keep_clear_summary() -> void
1964 func _show_death_summary(info: Dictionary) -> void
1986 func show_cell_popup(cell: Node2D, count: int = 1) -> void
2008 func _refresh_cell_popup() -> void
2118 func _apply_cell_popup_gating() -> void
2141 func _light_current_options() -> void
2159 func _set_lit(key: String, lit: bool) -> void
2170 func _process(_delta: float) -> void
2202 func _stage_marker_screen_position() -> Vector2
2206 func _update_stage_marker_arrow() -> void
2239 func _refresh_marker_exclusion_rects(viewport_size: Vector2) -> void
2250 func _append_marker_panel_exclusion(panel: Control, owner_rect: Rect2) -> void
2255 func _slide_arrow_along_edge(edge_point: Vector2, edge_bounds: Rect2) -> Vector2
2272 func _marker_arrow_obscured(point: Vector2) -> bool
2278 func _request_designation(type: String) -> void
2283 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
2288 func _request_empty(method: String) -> void
2293 func _request_priority(tier: int) -> void
2298 func _request_close(closed: bool) -> void
2303 func _request_fill_close() -> void
2308 # --- discard warning ----------------------------------------------
2314 func _build_discard_dialog() -> void
2329 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
2346 func confirm_discard(title: String, text: String, ok_text: String, cancel_text: String, action: Callable) -> void
2355 func _on_discard_confirmed() -> void
2358 func _on_discard_custom_action(action: StringName) -> void
2365 func _apply_discard() -> void
2378 # --- readouts -----------------------------------------------------
2383 func update_day(day: int, note: String = "") -> void
2393 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
2402 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
2408 func update_comb(text: String) -> void
2412 func update_energy(mean_fraction: float) -> void
2419 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
2430 func update_recruit_gap(text: String) -> void
2443 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
2449 func update_signals(lines: Array) -> void
2457 func _refresh_corner() -> void
2539 func corner_bottom() -> float
2545 func selection_panel_top() -> float
2555 func pinned_stats_changed() -> void
2564 func refresh_speed_visibility() -> void
2571 func refresh_corner() -> void
2574 func update_selection(bees: Array) -> void
2608 func _selection_has_command_lock(bees: Array) -> bool
2629 static func _detach_and_free_children(container: Node) -> void
2642 func _rebuild_role_controls(bees: Array) -> void
2692 func _build_queen_build_row(column: VBoxContainer) -> void
2706 func _build_follow_control(bees: Array, first) -> void
2721 func _build_job_row(common_role: int, any_queen: bool) -> void
2753 func _build_doing_row(common_role: int, first) -> void
2779 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2794 func _build_orders_row(common_role: int, first) -> void
2841 func _build_restock_row(first) -> void
2876 func _build_fallback_row(common_role: int, first) -> void
2926 func _secondary_items() -> Array
2942 func _column_row(parent: Container) -> HFlowContainer
2950 func _labelled_row(title: String) -> HFlowContainer
2969 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2981 func _action_button(label: String, action: Callable, tip: String) -> Control
2990 func _current_role_marker(label: String) -> Control
3005 func _common_role(bees: Array) -> int
3022 func _common_working_role(bees: Array) -> int
3040 func _make_role_menu(label: String, tip: String, items: Array, node_name: String = "") -> Control
3061 func _refresh_selection_text() -> void
3160 func _apply_selection_tray_width() -> void
3211 func _match_summary_header_button_heights() -> void
3229 func _tray_column_share(inner_width: float) -> float
3238 func _apply_even_column_widths(wrappers: Array) -> void
3266 func _update_command_tray_width() -> void
3287 func _resize_command_tray() -> void
3322 func _resettle_command_tray(generation: int, previous_content_min_y: float, stable_streak: int, pass_count: int) -> void
3337 func set_winter_button_visible(value: bool) -> void
3343 func set_view_label(in_hive: bool) -> void
3352 func set_allowed_role_keys(keys: Array) -> void
3362 func set_command_locked_bees(bees: Array) -> void
3367 func set_allowed_mode_keys(keys: Array) -> void
3377 func set_allowed_designation_keys(keys: Array) -> void
3387 func set_queen_build_button_visible(value: bool) -> void
3392 # --- stage gates --------------------------------------------------
3400 func apply_gates(stage_gate) -> void
3417 func _register_gated_control(control_name: String, getter: Callable) -> void
3425 func _apply_gate_to_control(control_name: String) -> void
3434 func _is_gate_open(control_name: String) -> bool
```

## bee.gd (2,413 lines)

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
2129 func _idle_backup_note() -> String
2139 func role_name_text() -> String
2165 func nurse_mode_name() -> String
2174 func architect_mode_name() -> String
2180 func carrying_text() -> String
2201 func age_days() -> float
2209 func leave_to_found_colony() -> void
2222 func days_remaining() -> float
2234 func _update_label() -> void
2254 func _update_alarm_ring() -> void
2265 func _update_heading_marker() -> void
2279 func _update_search_ring() -> void
2302 func _update_dance_ring() -> void
2335 func _update_wander_flight(delta: float) -> void
2366 func _update_dance_circle(delta: float) -> void
2380 func _terrain_speed_factor() -> float
2389 func _is_inside_hive() -> bool
2392 # --- getting round things in the meadow ---------------------------
2412 func clear_navigation_state() -> void
```

## scenario_actions.gd (1,486 lines)

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
264  # --- triggers -----------------------------------------------------
274  static func _when_met(main: Node2D, when: Dictionary) -> bool
318  static func _legacy_when_spec(main: Node2D, when: Dictionary) -> Dictionary
369  # --- selectors ------------------------------------------------------
373  static func _resolve_bees(main: Node2D, target: Dictionary) -> Array
405  static func _resolve_cell_ref(main: Node2D, ref: Dictionary) -> Node2D
412  static func _resolve_cell(main: Node2D, hex: Array) -> Node2D
422  static func _resolve_soil_block(main: Node2D, hex: Array) -> Node2D
432  # --- verbs ------------------------------------------------------------
449  static func _do_assign_role(main: Node2D, action: Dictionary) -> void
505  static func _do_designate_cell(main: Node2D, action: Dictionary) -> void
529  static func _do_queue_build(main: Node2D, action: Dictionary) -> void
555  static func _do_queue_mine(main: Node2D, action: Dictionary) -> void
580  static func _do_request_placement_tool(main: Node2D, action: Dictionary) -> void
592  static func _do_click_world(main: Node2D, action: Dictionary) -> void
622  static func _do_set_config(_main: Node2D, action: Dictionary) -> void
636  static func _do_hatch_role(main: Node2D, action: Dictionary) -> void
653  static func _do_set_restock_order(main: Node2D, action: Dictionary) -> void
699  static func _do_select_bees(main: Node2D, action: Dictionary) -> void
730  static func _do_select_soil(main: Node2D, action: Dictionary) -> void
756  static func _do_select_cell(main: Node2D, action: Dictionary) -> void
779  static func _do_open_window(main: Node2D, action: Dictionary) -> void
823  static func _do_close_window(main: Node2D, action: Dictionary) -> void
836  static func _do_viewport_size(main: Node2D, action: Dictionary) -> void
849  static func _do_show_gallerin_prompt(main: Node2D, action: Dictionary) -> void
865  static func _do_retreat_challenge_stage(main: Node2D, action: Dictionary) -> void
884  static func _do_advance_challenge_stage(main: Node2D, action: Dictionary) -> void
910  static func _do_set_queen_load(main: Node2D, action: Dictionary) -> void
942  static func _do_set_cell_contents(main: Node2D, action: Dictionary) -> void
966  static func _do_empty_cell(main: Node2D, action: Dictionary) -> void
980  static func _do_watch_queen_states(main: Node2D, action: Dictionary) -> void
995  static func _do_save_run(main: Node2D, action: Dictionary) -> void
1002 static func _do_buy_skill(main: Node2D, action: Dictionary) -> void
1013 static func _do_restore_slot(main: Node2D, action: Dictionary) -> void
1024 # --- assertion checks -------------------------------------------------
1034 static func _do_assert(main: Node2D, action: Dictionary) -> bool
1044 static func _evaluate_assert_condition(main: Node2D, condition: Dictionary) -> Dictionary
1074 static func _check_save_slot(main: Node2D, condition: Dictionary) -> Dictionary
1102 static func _check_all_actions_available(main: Node2D) -> Dictionary
1114 static func _queen_summary(main: Node2D, condition: Dictionary) -> String
1142 static func _check_panel_rect(main: Node2D, condition: Dictionary) -> Dictionary
1237 static func _resolve_named_panel(main: Node2D, name: String) -> Control
1251 static func _game_panel(main: Node2D, key: String) -> GamePanel
1272 static func _check_control_rect(main: Node2D, condition: Dictionary) -> Dictionary
1331 static func _check_menu_items(main: Node2D, condition: Dictionary) -> Dictionary
1350 static func _label_leading(control: Control) -> Dictionary
1364 static func _check_even_columns(main: Node2D, condition: Dictionary) -> Dictionary
1404 static func _check_no_collapsed_controls(main: Node2D, condition: Dictionary) -> Dictionary
1421 static func _check_no_empty_labels(main: Node2D, condition: Dictionary) -> Dictionary
1432 static func _collect_empty_labels(node: Node, out: Array) -> void
1438 static func _collect_collapsed_controls(node: Node, out: Array) -> void
1458 static func _resolve_scoped_path(main: Node2D, path: String) -> Node
1485 static func _log(do: String, target_desc: String, result: String, reason: String) -> void
```

## settings_catalogue.gd (1,440 lines)

Every setting's key, label, range and tip, plus the read/write and Prerequisites-cascade functions the window is a view of.

```
22   # --- preloads and collection order --------------------------------
48   # --- the tunables table -------------------------------------------
1315 # --- settings owned by Session ------------------------------------
1329 # --- reading and writing a setting --------------------------------
1330 static func setting_get(key: String)
1333 static func setting_set(key: String, value) -> void
1340 # --- resetting ----------------------------------------------------
1357 static func reset_config_to_defaults() -> void
1369 static func reset_config_keys(keys: Array) -> void
1375 # --- applying a setting with its cascades -------------------------
1384 static func apply_setting(key: String, value) -> void
1395 # --- the cascade helpers ------------------------------------------
1400 static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1418 static func _cascade_dependents_off_static(key: String) -> Array[String]
1432 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
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

## challenge_runner.gd (1,249 lines)

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
533  # --- counting cells -----------------------------------------------
534  func _built_cell_count() -> int
543  func _brood_cell_count() -> int
550  # --- ordered visits -----------------------------------------------
554  func _hive_inspection_points() -> Array
568  func _meadow_inspection_points() -> Array
580  func _begin_ordered_visit(points: Array, marker_parent: Node2D) -> void
586  func _clear_ordered_visit() -> void
591  func _ordered_visit_complete(traveller: Node2D) -> bool
604  func _show_current_visit_point() -> void
615  # --- the stage marker ---------------------------------------------
620  func _update_marker(stage_id: String) -> void
658  func _set_marker_visible(value: bool) -> void
682  func _publish_marker_to_hud() -> void
689  # --- advancing, leaving and completing a stage --------------------
694  func _show_goal(stage: Dictionary) -> void
701  func _advance() -> void
716  func _leave_stage() -> Dictionary
726  func _run_stage_effects(effects: Array) -> void
764  func debug_advance_stage() -> void
781  func debug_retreat_stage() -> void
791  func _complete() -> void
850  # --- the queen's build site ---------------------------------------
851  func on_queen_build_site_chosen(hex: Vector2i) -> void
863  # --- gating the UI ------------------------------------------------
872  func _apply_stage_gate_to_ui() -> void
905  func _on_gate_unlocked(_key: String) -> void
911  func is_bee_command_locked(bee: Node2D) -> bool
914  # --- the opening tunnel -------------------------------------------
920  func _setup_opening_tunnel() -> void
960  func _drive_opening_mine() -> void
972  func _opening_tunnel_cleared() -> bool
980  # --- Challenge 1 forage effects and overflow ----------------------
988  func _drive_c1_forage_effects() -> void
1016 func discards_overflow(bee: Node2D) -> bool
1031 func announce_overflow_discard(focus_switch: bool = false) -> void
1053 func _drive_c1_pollen_cell_nectar_prompt(delta: float) -> void
1067 # --- the new worker's greeting ------------------------------------
1073 func on_worker_hatched(bee: Node2D) -> void
1095 func _drive_greeting(delta: float) -> void
1109 # --- goal checks --------------------------------------------------
1132 func _goal_met(goal: String) -> bool
1144 func _goal_check_entrance_tunnel_cleared() -> bool
1147 func _goal_check_queen_reached_cavity() -> bool
1152 func _goal_check_queen_selected() -> bool
1155 func _goal_check_hive_points_visited() -> bool
1158 func _goal_check_nectar_target() -> bool
1164 func _goal_check_pollen_target() -> bool
1170 func _goal_check_queen_reached_meadow() -> bool
1173 func _goal_check_meadow_points_visited() -> bool
1176 func _goal_check_first_flower_collected() -> bool
1179 func _goal_check_second_flower_collected() -> bool
1182 func _goal_check_harvest_deposited() -> bool
1185 func _goal_check_new_bee_selected() -> bool
1191 func _goal_check_new_bee_left_hive() -> bool
1194 func _goal_check_complete() -> bool
1197 # --- Challenge 2 ---------------------------------------------
1198 func _goal_check_nectar_stabilized() -> bool
1205 func _goal_check_persistent_designation_used() -> bool
1213 func _goal_check_comb_worker_building() -> bool
1217 func _goal_check_miner_expansion() -> bool
1224 # --- goal progress readouts ---------------------------------------
1230 func _goal_progress(goal: String) -> Dictionary
1239 func _custom_goal_progress(method: String) -> Dictionary
```

## main.gd (1,202 lines)

Per-frame entry point, everything not yet split out of main.

```
37   # --- signals ------------------------------------------------------
51   # --- preloads and boot constants ----------------------------------
95   # --- delegate systems ---------------------------------------------
125  # --- world and meadow constants -----------------------------------
186  # --- state --------------------------------------------------------
329  # --- _ready and construction --------------------------------------
330  func _ready() -> void
590  # --- public surface other scripts call directly -------------------
597  func is_on_screen(node: Node2D) -> bool
600  func hive_entrance_inside() -> Vector2
603  func entrance_wait_point(side: int) -> Vector2
606  func move_bee_into_hive(bee: Node2D) -> void
609  func move_bee_out_of_hive(bee: Node2D) -> void
612  func mark_death(bee: Node2D) -> void
620  func _on_bee_died(bee: Node2D) -> void
624  func finish_mining(block: Node2D) -> void
627  func save_run() -> void
630  func begin_winter_countdown() -> void
633  # --- per-frame ----------------------------------------------------
643  func _process(delta: float) -> void
725  # --- the frame rate readout ----------------------------------------
744  func _sample_fps() -> void
767  func _reseed_meadow(delta: float) -> void
782  func _hatch_ready_brood() -> void
814  func _advance_weather(delta: float) -> void
844  func _apply_rain_overlay() -> void
859  func _check_for_loss() -> void
881  func _check_colony_energy(delta: float) -> void
912  func invalidate_population() -> void
923  func _role_counts(bees = null) -> Dictionary
940  func _update_population_readout(bees = null) -> void
952  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
958  func _prune_selection() -> void
971  func _on_restart_after_loss() -> void
977  func _on_level_chosen(level: int) -> void
990  func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
1008 func _apply_scenario_boot_arg() -> void
1135 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1175 func _is_whole_number(value: Variant) -> bool
1189 func _end_scenario_run(outcome: String) -> void
```

## diagnostic_log.gd (1,182 lines)

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
1067 func _flower_season_counts(world: Node2D) -> Dictionary
1095 func _performance_snapshot(world: Node2D) -> Dictionary
1115 func _rate(world: Node2D, key: String) -> float
1127 # --- writing to disk ----------------------------------------------
1131 func _current_day() -> int
1135 func _prune_old_sessions() -> void
1153 func _write(entry: Dictionary) -> void
1162 func _capture_entry(entry: Dictionary) -> bool
```

## hive_cell.gd (1,173 lines)

One cell: contents, brood, honey ripening, how it draws.

```
25   # --- constants and colours ----------------------------------------
99   # --- cell state ---------------------------------------------------
133  # --- building state -----------------------------------------------
157  func effective_build_time() -> float
160  # --- designation and orders ---------------------------------------
202  # --- hatch settings -----------------------------------------------
220  # --- layout and display nodes -------------------------------------
258  # --- slots --------------------------------------------------------
272  # --- setup --------------------------------------------------------
274  func _ready() -> void
388  # --- overlay, selection and rings ---------------------------------
395  func set_overlay(mode: String) -> void
401  func _overlay_colour() -> Array
439  func set_selected(value: bool) -> void
451  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
462  func _set_outline_points(line: Line2D, size: float) -> void
473  func _silhouette_point_to_local(p: Vector2) -> Vector2
485  func _set_outline_points_cup(line: Line2D, size: float) -> void
501  func _apply_outline_points(line: Line2D, size: float) -> void
509  func _set_selection_ring_points() -> void
512  # --- per-frame update ---------------------------------------------
530  func _process(delta: float) -> void
551  # --- brood development --------------------------------------------
556  func _develop_brood(delta: float) -> void
577  func _health_factor() -> float
585  func _larva_dies() -> void
597  # --- index and display epochs -------------------------------------
603  func _invalidate_hive_index() -> void
613  func _invalidate_stock() -> void
627  func bump_display_epoch() -> void
630  # --- working positions --------------------------------------------
635  func claim_slot(bee: Node2D) -> int
646  func release_slot(bee: Node2D) -> void
653  func has_free_slot() -> bool
662  func slot_position(index: int) -> Vector2
674  # --- building -----------------------------------------------------
676  func start_as_site() -> void
681  func claim_builder(bee: Node2D) -> void
685  func release_builder(bee: Node2D) -> void
691  func add_build_progress(delta: float) -> void
702  func build_fraction() -> float
705  # --- contents -----------------------------------------------------
707  func is_empty() -> bool
712  func capacity_for(resource_type: String) -> float
720  func accepts(resource_type: String) -> bool
739  func is_nursery_cell() -> bool
742  func space_for(resource_type: String) -> float
758  func needs_eviction() -> bool
776  func add_resource(resource_type: String, requested: float) -> float
808  func take_resource(resource_type: String, requested: float) -> float
836  func can_withdraw() -> bool
841  func set_closed(value: bool) -> void
848  func set_fill_then_close(value: bool) -> void
857  func fill_fraction() -> float
864  func set_designation(resource_type: String, explicit: bool = true) -> void
872  # --- honey ---------------------------------------------------------
874  func is_ripe_honey() -> bool
878  func needs_fanning() -> bool
883  func add_fanning_progress(delta: float) -> void
893  func ripen_fraction() -> float
896  # --- brood ---------------------------------------------------------
898  func start_brood(as_gyne: bool = false) -> void
912  func develop_time() -> float
920  func feed_brood(seconds: float, on_honey: bool) -> void
925  func needs_feeding() -> bool
929  func seconds_until_death() -> float
934  # --- clearing a dead larva ------------------------------------------
936  func needs_cleaning() -> bool
942  func add_clean_progress(delta: float) -> bool
948  func clean_fraction() -> float
951  func brood_ready() -> bool
954  func clear_cell() -> void
968  # --- display ------------------------------------------------------
973  func _resource_outline_colour(resource_type: String) -> Color
987  func _refresh() -> void
1124 func _designation_tag() -> String
1146 func _priority_mark() -> String
1159 func _apply_fill_shading() -> void
1170 func development_percent() -> float
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

## debug_panel.gd (1,046 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
20   # --- preloads -----------------------------------------------------
38   # --- fields -------------------------------------------------------
74   # --- _ready and construction --------------------------------------
77   func _style_button(button: BaseButton) -> BaseButton
82   func _ready() -> void
201  func _apply_panel_width() -> void
206  func _report_settings_button_width() -> void
211  # --- collections and sections -------------------------------------
212  func _rows_in(category: String) -> Array
234  func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
265  func _set_open(header: Button, body: Control, label: String, open: bool) -> void
273  func open_to_categories(categories: Array) -> void
293  func collapse_all() -> void
301  func _make_section(category: String, entries: Array, start_open: bool) -> Control
357  # --- the Challenge stage navigator --------------------------------
362  func _make_challenge_stage_navigation() -> Control
400  func _process(_delta: float) -> void
403  func _refresh_challenge_stage_navigation() -> void
422  # --- the controls help --------------------------------------------
428  func _make_controls_help() -> Control
473  # --- the action buttons -------------------------------------------
485  func _build_actions(column: VBoxContainer) -> void
553  func _add_action_row(parent: Control, button: Button, tip: String) -> void
559  func _make_winter_action() -> Control
571  func _on_winter_pressed() -> void
577  func _on_challenge_advance_pressed() -> void
584  func _on_challenge_retreat_pressed() -> void
598  func _on_fire_test_warnings_pressed() -> void
631  func _on_force_c2_collapse_pressed() -> void
645  # --- save and load ------------------------------------------------
651  func set_save_load_enabled(enabled: bool) -> void
659  func set_toggle(key: String, value: bool) -> void
664  func _on_save_pressed() -> void
675  func _on_load_pressed() -> void
705  # --- showing and hiding the panel ---------------------------------
706  func _toggle_panel() -> void
720  func _apply_layer_for_context() -> void
725  # --- building a settings row --------------------------------------
726  func _make_row(entry: Dictionary) -> Control
769  func _make_control_slot() -> HBoxContainer
778  func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
808  func _make_toggle_row(entry: Dictionary) -> Control
879  func _make_options_row(entry: Dictionary) -> Control
912  func _option_display(entry: Dictionary, value) -> String
916  func _cycle_option(entry: Dictionary, direction: int) -> void
927  # --- prerequisite cascades ----------------------------------------
931  func _cascade_prerequisites_on(key: String) -> void
945  func _cascade_dependents_off(key: String) -> void
953  func _cascade_mutual_exclusion(key: String) -> void
958  # --- star rows and value editing ----------------------------------
963  func _make_star_row(entry: Dictionary) -> Control
1004 func _adjust(entry: Dictionary, delta: float) -> void
1021 func _format_value(v) -> String
1028 # --- restart and main menu ----------------------------------------
1029 func _on_restart_pressed() -> void
1034 func _on_main_menu_pressed() -> void
1042 func _restart() -> void
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

## input_selection.gd (712 lines)

Selection, drag and placement resolution.

```
15   func _unhandled_input(event: InputEvent) -> void
79   func _finish_drag(additive: bool, add_to_group_selection: bool = false) -> void
185  func _select_cells(cells: Array, additive: bool) -> void
205  func _clear_cell_selection() -> void
211  func _select_blocks(blocks: Array, additive: bool) -> void
235  func _clear_block_selection() -> void
241  func _select_world_object(kind: String, object: Node2D) -> void
249  func _clear_world_object_selection() -> void
254  func _on_soil_mark_requested(mark: bool) -> void
259  func _on_keep_clear_clear_requested() -> void
263  func _bees_in_current_view() -> Array
267  func _death_markers_in_current_view() -> Array
274  func _click_switches_view(point: Vector2) -> bool
290  func _bee_at(point: Vector2) -> Node2D
296  func _cell_at(point: Vector2) -> Node2D
302  func _soil_at(point: Vector2) -> Node2D
308  func _death_marker_at(point: Vector2) -> Node2D
314  func _hex_at(global_point: Vector2) -> Vector2i
357  func _placement_tool_def(tool_id: String) -> Dictionary
367  func request_placement_tool(tool_id: String) -> void
394  func clear_placement_tool() -> void
400  func _place_with_active_tool(ctrl_held: bool) -> void
408  func _place_build_cell(global_point: Vector2, keep_adding: bool) -> void
418  func _place_queen_build_cell(global_point: Vector2, _keep_adding: bool = false) -> void
421  func _place_mine_target(global_point: Vector2, keep_adding: bool) -> void
432  func _place_keep_clear(global_point: Vector2, keep_adding: bool) -> void
437  func _place_home_cell(global_point: Vector2, _keep_adding: bool = false) -> void
448  func _on_cell_empty_by_bee_requested(cell: Node2D) -> void
457  func _place_home_cell_all(global_point: Vector2, _keep_adding: bool = false) -> void
465  func _place_mine_home(global_point: Vector2, _keep_adding: bool = false) -> void
473  func _place_forage_start(global_point: Vector2, _keep_adding: bool = false) -> void
479  func _place_floral_preference(global_point: Vector2, _keep_adding: bool = false) -> void
501  func _issue_command(world_point: Vector2) -> void
569  func _prune_invalid_selected_bees() -> void
578  func _show_click_marker(world_point: Vector2) -> void
584  func _on_role_selection_requested(role: int, focus: String) -> void
600  func _ensure_hive_view() -> void
605  func _draw_selection_box() -> void
622  func _draw_hive_orders() -> void
655  func _draw_build_hover() -> void
664  func _draw_home_marker(point: Vector2) -> void
670  func _build_queue_points(bee: Node2D) -> Array
676  func _mine_queue_points(bee: Node2D) -> Array
683  func _draw_order_chain(bee: Node2D, points: Array, colour: Color) -> void
693  func _draw_tile_outline(centre: Vector2, colour: Color, width: float, dashed: bool) -> void
702  func _tile_centre(hex: Vector2i) -> Vector2
707  func _draw_start_point_marker(point: Vector2) -> void
```
