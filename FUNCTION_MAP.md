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

## hud.gd (3,632 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
26   # --- signals ------------------------------------------------------
115  # --- role controls ------------------------------------------------
127  static func hatch_options() -> Array
173  static func mode_command(role_id: int, mode_key: String) -> String
176  # --- shared layout constants --------------------------------------
212  # --- fields -------------------------------------------------------
523  # --- problem strip ------------------------------------------------
532  func _signal_color(severity: int) -> Color
539  # --- _ready and construction --------------------------------------
554  func _ready() -> void
624  func _on_viewport_size_changed() -> void
630  func _build_stage_marker_arrow() -> void
648  func set_stage_marker(global_position: Vector2, marker_visible: bool, in_hive: bool) -> void
653  func _make_label(pos: Vector2, variation: String = "Body") -> Label
661  func _info(text: String) -> Button
664  func _with_info(control: Control, tip: String) -> HBoxContainer
669  func _style_button(button: BaseButton) -> BaseButton
674  # --- speed controls -----------------------------------------------
698  func _build_top_right_bar() -> void
830  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
866  func _apply_interface_label_visibility() -> void
872  # --- Challenge goal readout ---------------------------------------
877  func _build_goal_shelf() -> void
944  func set_settings_button_width(width: float) -> void
958  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
973  func set_speed_display(speed_scale: float) -> void
978  # --- bottom row ---------------------------------------------------
983  func _build_selection_panel() -> void
1110 func _build_favourite_star() -> Control
1141 func _set_favourite_star(bee) -> void
1169 func _field_control(field_name: String) -> Control
1183 func _build_selection_cog() -> Control
1210 func _theme_popup_on_open(popup: PopupMenu) -> void
1230 func _set_summary_cog_kind(kind: String) -> void
1242 func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
1262 func _apply_selection_field_visibility() -> void
1291 func _resize_selection_panel_to_content() -> void
1299 # --- command tray -------------------------------------------------
1311 func _build_command_tray() -> void
1414 func _build_tray_column(title: String) -> Array
1441 # --- cell popup ---------------------------------------------------
1457 func _build_cell_group(parent: VBoxContainer) -> void
1551 func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer
1579 func _build_priority_controls(column: VBoxContainer) -> void
1616 func _build_raises_controls(column: VBoxContainer) -> void
1689 func _build_closing_controls(column: VBoxContainer) -> void
1729 func _build_empty_controls(column: VBoxContainer) -> void
1791 func _make_hatch_menu(entry: Dictionary) -> Control
1821 func _fill_hatch_menu(popup: PopupMenu, role_value: int, options: Array) -> int
1833 func _build_warning_banner() -> void
1869 func show_warning(text: String, key: String = "", min_gap: float = 0.0, severity: int = 0) -> void
1886 func _show_warning_now(text: String, severity: int) -> void
1894 func _dismiss_warning() -> void
1899 func set_warnings_muted(value: bool) -> void
1913 func show_object_summary(kind: String, data) -> void
1940 func _refresh_flower_summary() -> void
1976 func _show_obstacle_summary(obstacle: Node2D) -> void
1982 func _show_soil_summary(count: int, reachable: int) -> void
1995 func _show_keep_clear_summary() -> void
2006 func _show_death_summary(info: Dictionary) -> void
2028 func show_cell_popup(cell: Node2D, count: int = 1) -> void
2050 func _refresh_cell_popup() -> void
2160 func _apply_cell_popup_gating() -> void
2183 func _light_current_options() -> void
2201 func _set_lit(key: String, lit: bool) -> void
2212 func _process(_delta: float) -> void
2244 func _stage_marker_screen_position() -> Vector2
2248 func _update_stage_marker_arrow() -> void
2281 func _refresh_marker_exclusion_rects(viewport_size: Vector2) -> void
2292 func _append_marker_panel_exclusion(panel: Control, owner_rect: Rect2) -> void
2297 func _slide_arrow_along_edge(edge_point: Vector2, edge_bounds: Rect2) -> Vector2
2314 func _marker_arrow_obscured(point: Vector2) -> bool
2320 func _request_designation(type: String) -> void
2325 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
2330 func _request_empty(method: String) -> void
2335 func _request_priority(tier: int) -> void
2340 func _request_close(closed: bool) -> void
2345 func _request_fill_close() -> void
2350 # --- discard warning ----------------------------------------------
2357 func _build_discard_dialog() -> void
2372 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
2391 func confirm_discard(title: String, text: String, ok_text: String, cancel_text: String, action: Callable, offer_stop_warning: bool = true) -> void
2401 func _on_discard_confirmed() -> void
2404 func _on_discard_custom_action(action: StringName) -> void
2411 func _apply_discard() -> void
2424 # --- readouts -----------------------------------------------------
2429 func update_day(day: int, note: String = "") -> void
2439 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
2448 func update_population(nectar_foragers: int, pollen_foragers: int, nurses: int, builders: int, miners: int, honey_makers: int) -> void
2454 func update_comb(text: String) -> void
2458 func update_energy(mean_fraction: float) -> void
2465 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
2476 func update_recruit_gap(text: String) -> void
2489 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
2495 func update_signals(lines: Array) -> void
2503 func _refresh_corner() -> void
2588 func _corner_line_width() -> float
2592 func _apply_corner_line_width() -> void
2601 func _fit_corner_line(line: Button) -> void
2609 func _on_corner_resized() -> void
2614 func corner_bottom() -> float
2620 func selection_panel_top() -> float
2630 func pinned_stats_changed() -> void
2639 func refresh_speed_visibility() -> void
2646 func refresh_corner() -> void
2649 func update_selection(bees: Array) -> void
2683 func _selection_has_command_lock(bees: Array) -> bool
2704 static func _detach_and_free_children(container: Node) -> void
2717 func _rebuild_role_controls(bees: Array) -> void
2772 func _build_queen_build_row(column: VBoxContainer) -> void
2786 func _build_follow_control(bees: Array, first) -> void
2801 func _build_job_row(common_role: int, any_queen: bool, queen_bee = null) -> void
2833 func _build_doing_row(common_role: int, first) -> void
2866 func _build_mating_row(bees: Array, first) -> void
2887 func _set_nuptial_flights(queen, on: bool) -> void
2898 func _build_gyne_send_row(bees: Array, first) -> void
2913 func _send_gyne(gyne) -> void
2919 func _gyne_not_ready_reason(gyne) -> String
2924 func _refresh_gyne_send_button(gyne) -> void
2930 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2945 func _build_orders_row(common_role: int, first) -> void
2992 func _build_restock_row(first) -> void
3027 func _build_fallback_row(common_role: int, first) -> void
3077 func _secondary_items() -> Array
3093 func _column_row(parent: Container) -> HFlowContainer
3101 func _labelled_row(title: String) -> HFlowContainer
3120 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
3132 func _action_button(label: String, action: Callable, tip: String) -> Control
3141 func _current_role_marker(label: String) -> Control
3156 func _common_role(bees: Array) -> int
3173 func _common_working_role(bees: Array) -> int
3191 func _make_role_menu(label: String, tip: String, items: Array, node_name: String = "") -> Control
3213 func _refresh_selection_text() -> void
3319 func _apply_selection_tray_width() -> void
3370 func _match_summary_header_button_heights() -> void
3388 func _tray_column_share(inner_width: float) -> float
3397 func _apply_even_column_widths(wrappers: Array) -> void
3425 func _update_command_tray_width() -> void
3446 func _resize_command_tray() -> void
3481 func _resettle_command_tray(generation: int, previous_content_min_y: float, stable_streak: int, pass_count: int) -> void
3495 func _apply_command_tray_rect() -> void
3513 func _on_command_content_minimum_size_changed() -> void
3520 func set_winter_button_visible(value: bool) -> void
3526 func set_view_label(in_hive: bool) -> void
3535 func set_allowed_role_keys(keys: Array) -> void
3543 func _role_offered(role_id: int, bee = null) -> bool
3549 func refresh_role_gating() -> void
3558 func set_command_locked_bees(bees: Array) -> void
3563 func set_allowed_mode_keys(keys: Array) -> void
3573 func set_allowed_designation_keys(keys: Array) -> void
3583 func set_queen_build_button_visible(value: bool) -> void
3588 # --- stage gates --------------------------------------------------
3596 func apply_gates(stage_gate) -> void
3614 func _register_gated_control(control_name: String, getter: Callable) -> void
3622 func _apply_gate_to_control(control_name: String) -> void
3631 func _is_gate_open(control_name: String) -> bool
```

## bee.gd (2,668 lines)

A bee's dispatch loop, player commands, display text, vars.

```
23   # --- preloads and shared enums ------------------------------------
56   # --- the role action catalogue ------------------------------------
75   # --- stats copied from GameConfig ---------------------------------
86   # --- role, state and identity -------------------------------------
311  func current_working_role() -> int
314  # --- floral constancy and the search pattern ----------------------
386  # --- patch memory and species experience --------------------------
413  # --- scouting -----------------------------------------------------
437  # --- trip rates and scoring ---------------------------------------
501  # --- recruitment and dancing --------------------------------------
541  # --- build and mine queues ----------------------------------------
565  # --- flower cooldowns and predator memory -------------------------
612  # --- pathfinding inside the hive ----------------------------------
618  # --- the visual nodes ---------------------------------------------
671  # --- _ready and construction --------------------------------------
672  func _ready() -> void
716  func _build_visuals() -> void
823  func _caste_size_factor() -> float
837  func become_drone() -> void
860  func become_queen() -> void
877  # --- nuptial flights (COL-11) -------------------------------------
883  func set_nuptial_flights(on: bool) -> void
894  func _nuptial_flight_step(delta: float) -> void
941  func _nuptial_flight_due() -> bool
951  func _begin_nuptial_flight() -> void
958  func _end_nuptial_flight() -> void
967  # --- setup, stats and appearance ----------------------------------
968  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
1010 func _roll_fact() -> void
1024 func _default_state_for_role() -> int
1046 func _base_colour() -> Color
1059 func _tinted(c: Color) -> Color
1074 func _apply_stats() -> void
1100 func trait_text() -> String
1109 func _update_role_marker() -> void
1128 # --- how often a bee thinks ---------------------------------------
1160 func _process(delta: float) -> void
1438 # --- life support -------------------------------------------------
1440 # --- eating -------------------------------------------------------
1442 # --- stall watchdog -----------------------------------------------
1448 func _reset_stall_watch() -> void
1451 # --- foraging -----------------------------------------------------
1453 # --- entering and leaving the hive --------------------------------
1455 # --- nursery work -------------------------------------------------
1457 # --- royal jelly ---------------------------------------------------
1459 # --- idle work dispatch --------------------------------------------
1473 func _apply_pending_role() -> bool
1490 func _deliver_held_load() -> bool
1511 func _return_nurse_food() -> void
1532 func _is_busy() -> bool
1538 func _idle_dispatch() -> void
1566 func _maybe_break_off_secondary() -> void
1590 func _try_role_work(r: int) -> bool
1615 static func _build_actions_by_role() -> Dictionary
1630 func _action_available(action_id: String) -> bool
1640 func _action_mode_for_role(r: int) -> String
1649 # --- building -----------------------------------------------------
1651 # --- keeping cells topped up ---------------------------------------
1680 func set_restock_targets(cells: Array, resource: String) -> void
1683 func set_restock_sources(cells: Array, allowed: bool) -> void
1686 func clear_restock() -> void
1689 func has_restock_orders() -> bool
1691 # --- mining -------------------------------------------------------
1693 # --- honey making -------------------------------------------------
1695 # --- egg laying (queen only) --------------------------------------
1697 # --- player commands ----------------------------------------------
1707 func command_move_to(world_point: Vector2) -> void
1727 func command_move_through_entrance(world_point: Vector2, target_in_hive: bool) -> void
1739 func command_exit_hive() -> void
1749 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
1757 func has_forage_start_point() -> bool
1760 func set_preferred_species(species: String) -> void
1773 func set_manual_build_target(hex: Vector2i) -> void
1781 func queue_build_target(hex: Vector2i) -> void
1788 func clear_build_queue() -> void
1794 func _take_next_build_target() -> bool
1807 func set_mine_target(block: Node2D) -> void
1814 func queue_mine_target(block: Node2D) -> void
1822 func clear_mine_queue() -> void
1829 func _next_queued_block() -> Node2D
1837 func set_home_hex(hex: Vector2i) -> void
1846 func set_mine_home_hex(hex: Vector2i) -> void
1852 func _mine_reference_point() -> Vector2
1867 func command_collect_from(flower: Node2D) -> void
1883 func command_collect_from_after_exit(flower: Node2D) -> void
1896 func command_return_and_deposit() -> void
1906 func command_return_only() -> void
1912 func command_deposit_at(cell: Node2D) -> void
1925 func command_empty_cell(cell: Node2D) -> void
1937 func command_deposit_at_after_enter(cell: Node2D) -> void
1945 func resume_pending_zone_command() -> bool
1964 func _clear_pending_zone_command() -> void
1969 func set_focus(type: String) -> void
2026 func _has_deliverable_target() -> bool
2032 func set_secondary_role(new_role: int) -> void
2040 func can_take_role(new_role: int) -> bool
2052 func set_role(new_role: int) -> void
2069 func _apply_role(new_role: int) -> void
2109 func _release_everything() -> void
2126 func release_flower_reference(flower: Node2D) -> void
2132 func set_selected(value: bool) -> void
2136 # --- display ------------------------------------------------------
2138 func role_letter() -> String
2167 func challenge_vocabulary_limited() -> bool
2180 func idle_reason() -> String
2233 func task_description() -> String
2384 func _idle_backup_note() -> String
2394 func role_name_text() -> String
2429 func architect_mode_name() -> String
2435 func carrying_text() -> String
2456 func age_days() -> float
2464 func leave_to_found_colony() -> void
2477 func days_remaining() -> float
2489 func _update_label() -> void
2509 func _update_alarm_ring() -> void
2520 func _update_heading_marker() -> void
2534 func _update_search_ring() -> void
2557 func _update_dance_ring() -> void
2590 func _update_wander_flight(delta: float) -> void
2621 func _update_dance_circle(delta: float) -> void
2635 func _terrain_speed_factor() -> float
2644 func _is_inside_hive() -> bool
2647 # --- getting round things in the meadow ---------------------------
2667 func clear_navigation_state() -> void
```

## scenario_actions.gd (1,641 lines)

The headless verbs, `when` clauses and layout assertions.

```
25   # --- preloads -----------------------------------------------------
58   # --- run_pending --------------------------------------------------
64   static func run_pending(main: Node2D, actions: Array) -> void
93   # --- the comb build-site sampler ----------------------------------
103  static func sample_comb_build_sites(main: Node2D) -> void
142  # --- log_unresolved -----------------------------------------------
149  static func log_unresolved(actions: Array) -> void
156  # --- the settle, wait and window helpers --------------------------
168  static func _do_settle(action: Dictionary) -> bool
181  static func _do_wait(action: Dictionary) -> bool
196  static func _assert_window_closed(main: Node2D, action: Dictionary) -> bool
209  static func _sample_queen_watch(main: Node2D) -> void
216  # --- _execute -----------------------------------------------------
218  static func _execute(main: Node2D, action: Dictionary) -> void
276  # --- triggers -----------------------------------------------------
286  static func _when_met(main: Node2D, when: Dictionary) -> bool
330  static func _legacy_when_spec(main: Node2D, when: Dictionary) -> Dictionary
384  # --- selectors ------------------------------------------------------
388  static func _resolve_bees(main: Node2D, target: Dictionary) -> Array
420  static func _resolve_cell_ref(main: Node2D, ref: Dictionary) -> Node2D
427  static func _resolve_cell(main: Node2D, hex: Array) -> Node2D
437  static func _resolve_soil_block(main: Node2D, hex: Array) -> Node2D
447  # --- verbs ------------------------------------------------------------
464  static func _do_assign_role(main: Node2D, action: Dictionary) -> void
531  static func _do_designate_cell(main: Node2D, action: Dictionary) -> void
555  static func _do_queue_build(main: Node2D, action: Dictionary) -> void
581  static func _do_queue_mine(main: Node2D, action: Dictionary) -> void
606  static func _do_request_placement_tool(main: Node2D, action: Dictionary) -> void
618  static func _do_click_world(main: Node2D, action: Dictionary) -> void
648  static func _do_set_config(_main: Node2D, action: Dictionary) -> void
666  static func _do_hatch_role(main: Node2D, action: Dictionary) -> void
689  static func _do_set_restock_order(main: Node2D, action: Dictionary) -> void
735  static func _do_select_bees(main: Node2D, action: Dictionary) -> void
766  static func _do_select_soil(main: Node2D, action: Dictionary) -> void
792  static func _do_select_cell(main: Node2D, action: Dictionary) -> void
811  static func _force_layout(node: Node) -> void
824  static func _do_open_window(main: Node2D, action: Dictionary) -> void
881  static func _do_close_window(main: Node2D, action: Dictionary) -> void
900  static func _do_viewport_size(main: Node2D, action: Dictionary) -> void
913  static func _do_show_gallerin_prompt(main: Node2D, action: Dictionary) -> void
929  static func _do_retreat_challenge_stage(main: Node2D, action: Dictionary) -> void
948  static func _do_advance_challenge_stage(main: Node2D, action: Dictionary) -> void
974  static func _do_set_queen_load(main: Node2D, action: Dictionary) -> void
1005 static func _do_set_bee_load(main: Node2D, action: Dictionary) -> void
1022 static func _do_set_cell_contents(main: Node2D, action: Dictionary) -> void
1046 static func _do_empty_cell(main: Node2D, action: Dictionary) -> void
1060 static func _do_watch_queen_states(main: Node2D, action: Dictionary) -> void
1075 static func _do_save_run(main: Node2D, action: Dictionary) -> void
1082 static func _do_buy_skill(main: Node2D, action: Dictionary) -> void
1101 static func _do_restore_slot(main: Node2D, action: Dictionary) -> void
1112 # --- assertion checks -------------------------------------------------
1122 static func _do_assert(main: Node2D, action: Dictionary) -> bool
1132 static func _evaluate_assert_condition(main: Node2D, condition: Dictionary) -> Dictionary
1177 static func _check_save_slot(main: Node2D, condition: Dictionary) -> Dictionary
1205 static func _check_all_actions_available(main: Node2D) -> Dictionary
1217 static func _queen_summary(main: Node2D, condition: Dictionary) -> String
1245 static func _check_panel_rect(main: Node2D, condition: Dictionary) -> Dictionary
1340 static func _resolve_named_panel(main: Node2D, name: String) -> Control
1354 static func _game_panel(main: Node2D, key: String) -> GamePanel
1375 static func _check_control_rect(main: Node2D, condition: Dictionary) -> Dictionary
1453 static func _check_panel_texture_contrast(_condition: Dictionary) -> Dictionary
1480 static func _check_menu_items(main: Node2D, condition: Dictionary) -> Dictionary
1499 static func _label_leading(control: Control) -> Dictionary
1513 static func _check_even_columns(main: Node2D, condition: Dictionary) -> Dictionary
1553 static func _check_no_collapsed_controls(main: Node2D, condition: Dictionary) -> Dictionary
1570 static func _check_no_empty_labels(main: Node2D, condition: Dictionary) -> Dictionary
1581 static func _collect_empty_labels(node: Node, out: Array) -> void
1587 static func _collect_collapsed_controls(node: Node, out: Array) -> void
1607 static func _resolve_scoped_path(main: Node2D, path: String) -> Node
1640 static func _log(do: String, target_desc: String, result: String, reason: String) -> void
```

## settings_catalogue.gd (1,446 lines)

Every setting's key, label, range and tip, plus the read/write and Prerequisites-cascade functions the window is a view of.

```
22   # --- preloads and collection order --------------------------------
48   # --- the tunables table -------------------------------------------
1321 # --- settings owned by Session ------------------------------------
1335 # --- reading and writing a setting --------------------------------
1336 static func setting_get(key: String)
1339 static func setting_set(key: String, value) -> void
1346 # --- resetting ----------------------------------------------------
1363 static func reset_config_to_defaults() -> void
1375 static func reset_config_keys(keys: Array) -> void
1381 # --- applying a setting with its cascades -------------------------
1390 static func apply_setting(key: String, value) -> void
1401 # --- the cascade helpers ------------------------------------------
1406 static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1424 static func _cascade_dependents_off_static(key: String) -> Array[String]
1438 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
```

## bee_foraging.gd (1,440 lines)

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
569  static func adaptive_constancy_on() -> bool
573  static func tarsal_markers_on() -> bool
576  static func orientation_flight_on() -> bool
580  # --- accepting or rejecting a flower ------------------------------
581  static func worth_feeding(bee: Node2D, f: Node2D) -> bool
594  static func reject_flower(bee: Node2D) -> void
612  # --- collecting ---------------------------------------------------
613  static func start_collecting(bee: Node2D) -> void
686  static func _handling_experience_scale(bee: Node2D, species: String) -> float
695  static func collect(bee: Node2D, delta: float) -> void
744  static func finish_collecting(bee: Node2D) -> void
783  # --- entering the hive and depositing -----------------------------
787  static func enter_hive(bee: Node2D) -> void
814  static func approach_cell(bee: Node2D, cell: Node2D, delta: float) -> int
829  static func release_cell_slot(bee: Node2D) -> void
836  static func go_to_deposit_cell(bee: Node2D, delta: float) -> void
926  static func finish_depositing(bee: Node2D) -> void
966  static func _after_delivery_state(bee: Node2D) -> int
977  static func _resume_own_job_if_indoors(bee: Node2D) -> bool
985  # --- scoring a trip -----------------------------------------------
990  static func _score_trip(bee: Node2D) -> void
1068 # --- leaving the hive ---------------------------------------------
1069 static func go_to_exit(bee: Node2D, delta: float) -> void
1112 static func _entrance_wait_spot(bee: Node2D, side: int) -> Vector2
1124 static func _leave_hive_and_resume(bee: Node2D) -> void
1151 static func _send_to_scout_point(bee: Node2D) -> void
1162 # --- scouting -----------------------------------------------------
1168 static func start_scouting(bee: Node2D) -> void
1186 # --- waiting at the entrance --------------------------------------
1191 static func wait_at_entrance(bee: Node2D, delta: float) -> void
1295 # --- the recruitment dance ----------------------------------------
1303 static func _update_dance_eligibility(bee: Node2D) -> void
1327 static func check_dance_proximity(bee: Node2D, _delta: float) -> void
1352 static func _start_dance(mentor: Node2D, seeker: Node2D) -> void
1372 static func dance(bee: Node2D, delta: float) -> void
1384 static func _end_dance(bee: Node2D) -> void
1406 static func _complete_dance(mentor: Node2D, seeker: Node2D) -> void
1433 # --- remote deposit -----------------------------------------------
1435 static func deposit_everything_remotely(bee: Node2D) -> void
```

## main.gd (1,337 lines)

Per-frame entry point, everything not yet split out of main.

```
37   # --- signals ------------------------------------------------------
51   # --- preloads and boot constants ----------------------------------
97   # --- delegate systems ---------------------------------------------
130  # --- world and meadow constants -----------------------------------
191  # --- state --------------------------------------------------------
348  # --- _ready and construction --------------------------------------
358  static func run_definition(level_id: int, developer_edits_allowed: bool, overrides_path: String = DeveloperOverrides.PATH) -> Dictionary
377  func _ready() -> void
659  # --- public surface other scripts call directly -------------------
666  func is_on_screen(node: Node2D) -> bool
669  func hive_entrance_inside() -> Vector2
672  func entrance_wait_point(side: int) -> Vector2
675  func move_bee_into_hive(bee: Node2D) -> void
678  func move_bee_out_of_hive(bee: Node2D) -> void
681  func mark_death(bee: Node2D) -> void
689  func _on_bee_died(bee: Node2D) -> void
693  func finish_mining(block: Node2D) -> void
696  func save_run() -> void
699  func begin_winter_countdown() -> void
702  # --- per-frame ----------------------------------------------------
712  func _process(delta: float) -> void
799  # --- the frame rate readout ----------------------------------------
818  func _sample_fps() -> void
841  func _reseed_meadow(delta: float) -> void
856  func _hatch_ready_brood() -> void
892  func _sample_day_stores() -> void
909  func _advance_weather(delta: float) -> void
940  func _apply_rain_overlay() -> void
967  func _check_for_loss() -> void
995  func _promote_gyne_to_queen() -> bool
1016 func _check_colony_energy(delta: float) -> void
1047 func invalidate_population() -> void
1058 func _role_counts(bees = null) -> Dictionary
1075 func _update_population_readout(bees = null) -> void
1089 func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
1095 func _prune_selection() -> void
1108 func _on_restart_after_loss() -> void
1114 func _on_level_chosen(level: int) -> void
1127 func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
1145 func _apply_scenario_boot_arg() -> void
1270 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1310 func _is_whole_number(value: Variant) -> bool
1324 func _end_scenario_run(outcome: String) -> void
```

## challenge_runner.gd (1,249 lines)

The stage machine, goal checks and stage effects.

```
33   # --- signals and preloads -----------------------------------------
65   # --- fields -------------------------------------------------------
172  # --- _ready and the current stage ---------------------------------
173  func _ready() -> void
176  func _reset_c2_pollen_rescue() -> void
179  func _stages() -> Array
184  func current_stage_instruction() -> String
191  func current_stage_id() -> String
199  func current_stage_goal_text() -> String
204  func can_debug_retreat_stage() -> bool
207  func can_debug_advance_stage() -> bool
210  # --- starting and the per-frame loop ------------------------------
211  func start() -> void
295  func _process(delta: float) -> void
334  # --- goal polling -------------------------------------------------
342  func _should_check_goal(goal_id: String, goal_tick_due: bool) -> bool
359  # --- Challenge 2 failure and rescue -------------------------------
365  func _check_c2_failure() -> void
429  func _c2_index(stage_id: String) -> int
435  # --- entering a stage ---------------------------------------------
440  func _stage_unlock_keys(entries: Array) -> Array
461  func _queen_allowed_role_ids(entries: Array) -> Array
469  func _enter_stage() -> void
538  # --- counting cells -----------------------------------------------
539  func _built_cell_count() -> int
546  # --- ordered visits -----------------------------------------------
550  func _hive_inspection_points() -> Array
564  func _meadow_inspection_points() -> Array
576  func _begin_ordered_visit(points: Array, marker_parent: Node2D) -> void
582  func _clear_ordered_visit() -> void
587  func _ordered_visit_complete(traveller: Node2D) -> bool
600  func _show_current_visit_point() -> void
611  # --- the stage marker ---------------------------------------------
616  func _update_marker(stage_id: String) -> void
654  func _set_marker_visible(value: bool) -> void
678  func _publish_marker_to_hud() -> void
685  # --- advancing, leaving and completing a stage --------------------
690  func _show_goal(stage: Dictionary) -> void
697  func _advance() -> void
712  func _leave_stage() -> Dictionary
722  func _run_stage_effects(effects: Array) -> void
760  func debug_advance_stage() -> void
777  func debug_retreat_stage() -> void
787  func _complete() -> void
846  # --- the queen's build site ---------------------------------------
847  func on_queen_build_site_chosen(hex: Vector2i) -> void
859  # --- gating the UI ------------------------------------------------
868  func _apply_stage_gate_to_ui() -> void
901  func _on_gate_unlocked(_key: String) -> void
907  func is_bee_command_locked(bee: Node2D) -> bool
910  # --- the opening tunnel -------------------------------------------
916  func _setup_opening_tunnel() -> void
956  func _drive_opening_mine() -> void
968  func _opening_tunnel_cleared() -> bool
976  # --- Challenge 1 forage effects and overflow ----------------------
984  func _drive_c1_forage_effects() -> void
1012 func discards_overflow(bee: Node2D) -> bool
1027 func announce_overflow_discard(focus_switch: bool = false) -> void
1049 func _drive_c1_pollen_cell_nectar_prompt(delta: float) -> void
1063 # --- the new worker's greeting ------------------------------------
1069 func on_worker_hatched(bee: Node2D) -> void
1091 func _drive_greeting(delta: float) -> void
1105 # --- goal checks --------------------------------------------------
1128 func _goal_met(goal: String) -> bool
1140 func _goal_check_entrance_tunnel_cleared() -> bool
1143 func _goal_check_queen_reached_cavity() -> bool
1148 func _goal_check_queen_selected() -> bool
1151 func _goal_check_hive_points_visited() -> bool
1154 func _goal_check_nectar_target() -> bool
1160 func _goal_check_pollen_target() -> bool
1166 func _goal_check_queen_reached_meadow() -> bool
1169 func _goal_check_meadow_points_visited() -> bool
1172 func _goal_check_first_flower_collected() -> bool
1175 func _goal_check_second_flower_collected() -> bool
1178 func _goal_check_harvest_deposited() -> bool
1181 func _goal_check_new_bee_selected() -> bool
1187 func _goal_check_new_bee_left_hive() -> bool
1190 func _goal_check_complete() -> bool
1193 # --- Challenge 2 ---------------------------------------------
1194 func _goal_check_nectar_stabilized() -> bool
1201 func _goal_check_persistent_designation_used() -> bool
1209 func _goal_check_comb_worker_building() -> bool
1213 func _goal_check_miner_expansion() -> bool
1220 # --- goal progress readouts ---------------------------------------
1226 func _goal_progress(goal: String) -> Dictionary
1239 func _custom_goal_progress(method: String) -> Dictionary
```

## diagnostic_log.gd (1,239 lines)

The session JSONL writer, counters and capture profiles.

```
18   # --- preloads and constants ---------------------------------------
27   # --- session state ------------------------------------------------
77   # --- the running counters -----------------------------------------
134  # --- _ready and the session lifecycle -----------------------------
135  func _ready() -> void
143  func _notification(what: int) -> void
148  func start_session() -> void
216  # --- death and predation ------------------------------------------
217  func log_death(bee: Node2D) -> void
250  func log_crab_spider_event(bee: Node2D, flower: Node2D, outcome: String) -> void
265  # --- recruitment and scouting -------------------------------------
275  func log_recruitment_match(seeker: Node2D, mentor: Node2D, via: String = "queue") -> void
308  func log_recruitment_followup(bee: Node2D, trip_index: int, trip_rate: float) -> void
330  func count_recruit_partner_overlap() -> void
340  func log_forager_settled(bee: Node2D) -> void
358  func log_orientation_flight(bee: Node2D) -> void
371  # --- flowers and foraging counters --------------------------------
375  func count_flower_visit(flower: Node2D) -> void
384  func record_handling_visit(species: String, prior_experience: int, seconds: float) -> void
398  func count_forager_delivery(amount: float) -> void
405  func count_flower_senescence() -> void
412  func count_flower_senescence_loss(nectar: float, pollen: float) -> void
417  func _experience_bucket(prior_experience: int) -> String
429  # --- tarsal marks -------------------------------------------------
430  func count_tarsal_mark() -> void
439  func count_tarsal_rejection() -> void
443  # --- movement and stalls ------------------------------------------
451  func log_stall_recovery(bee: Node2D, goal: Vector2) -> void
480  func log_build_target(bee: Node2D, cell: Node2D, transition: String, reason: String,
505  func log_forager_return(bee: Node2D, phase: String, required_energy: float) -> void
515  func log_flight_start_resolved(bee: Node2D, source: String, requested: Vector2, resolved: Dictionary) -> void
527  func _nearby_obstacle_identity(bee: Node2D) -> String
550  func log_scouting_settled(bee: Node2D) -> void
565  # --- brood, comb and honey counters -------------------------------
568  func count_brood_feed() -> void
575  func count_brood_hatch(role: int, mode: String) -> void
582  func count_jelly_batch() -> void
587  func count_larval_death() -> void
593  func count_cell_completed() -> void
598  func cell_completed_count() -> int
604  func count_cell_cleaned() -> void
611  func count_cell_evicted() -> void
617  func count_cell_restocked() -> void
623  func count_block_mined() -> void
629  func count_honey_batch_deposited() -> void
635  func count_cell_ripened() -> void
639  # --- player actions and commands ----------------------------------
644  func log_action(do: String, target_desc: String, result: String, reason: String) -> void
660  func log_command_issue(selected_count: int, commandable_count: int, branch: String,
689  func log_selection_panels_hidden(source: String, shown_count: int, selected_count: int) -> void
701  # --- reading events back ------------------------------------------
708  func event_count(type: String, subtype: String = "") -> int
754  # --- the per-frame tick and session end ---------------------------
759  func tick(delta: float, world: Node2D) -> void
795  func _sample_nectar_age_on_day_change(world: Node2D) -> void
828  func _nectar_age_summary() -> Dictionary
838  func end_session(outcome: String) -> void
896  # --- configuration ------------------------------------------------
897  func session_path() -> String
901  func set_queen_alive(alive: bool) -> void
905  func configure_scenario_diagnostics(raw: Variant) -> bool
914  func configure_performance_capture(config: Dictionary) -> void
918  func effective_diagnostics() -> Dictionary
924  func _snapshot_interval() -> float
937  func _selected_snapshot(world: Node2D) -> Dictionary
943  # --- building entries -----------------------------------------------
947  func _config_snapshot() -> Dictionary
955  # --- the snapshot -------------------------------------------------
956  func _snapshot(world: Node2D) -> Dictionary
1124 func _flower_season_counts(world: Node2D) -> Dictionary
1152 func _performance_snapshot(world: Node2D) -> Dictionary
1172 func _rate(world: Node2D, key: String) -> float
1184 # --- writing to disk ----------------------------------------------
1188 func _current_day() -> int
1192 func _prune_old_sessions() -> void
1210 func _write(entry: Dictionary) -> void
1219 func _capture_entry(entry: Dictionary) -> bool
```

## hive_cell.gd (1,215 lines)

One cell: contents, brood, honey ripening, how it draws.

```
25   # --- constants and colours ----------------------------------------
99   # --- cell state ---------------------------------------------------
144  # --- building state -----------------------------------------------
168  func effective_build_time() -> float
171  # --- designation and orders ---------------------------------------
213  # --- hatch settings -----------------------------------------------
231  # --- layout and display nodes -------------------------------------
272  # --- slots --------------------------------------------------------
286  # --- setup --------------------------------------------------------
288  func _ready() -> void
402  # --- overlay, selection and rings ---------------------------------
409  func set_overlay(mode: String) -> void
415  func _overlay_colour() -> Array
453  func set_selected(value: bool) -> void
465  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
476  func _set_outline_points(line: Line2D, size: float) -> void
487  func _silhouette_point_to_local(p: Vector2) -> Vector2
499  func _set_outline_points_cup(line: Line2D, size: float) -> void
515  func _apply_outline_points(line: Line2D, size: float) -> void
523  func _set_selection_ring_points() -> void
526  # --- per-frame update ---------------------------------------------
544  func _process(delta: float) -> void
565  # --- brood development --------------------------------------------
570  func _develop_brood(delta: float) -> void
591  func _health_factor() -> float
599  func _larva_dies() -> void
612  # --- index and display epochs -------------------------------------
618  func _invalidate_hive_index() -> void
628  func _invalidate_stock() -> void
642  func bump_display_epoch() -> void
645  # --- working positions --------------------------------------------
650  func claim_slot(bee: Node2D) -> int
661  func release_slot(bee: Node2D) -> void
668  func has_free_slot() -> bool
677  func slot_position(index: int) -> Vector2
689  # --- building -----------------------------------------------------
691  func start_as_site() -> void
696  func claim_builder(bee: Node2D) -> void
700  func release_builder(bee: Node2D) -> void
706  func add_build_progress(delta: float) -> void
717  func build_fraction() -> float
720  # --- contents -----------------------------------------------------
722  func is_empty() -> bool
727  func capacity_for(resource_type: String) -> float
735  func accepts(resource_type: String) -> bool
754  func is_nursery_cell() -> bool
757  func space_for(resource_type: String) -> float
773  func needs_eviction() -> bool
791  func add_resource(resource_type: String, requested: float) -> float
827  func nectar_age() -> float
835  func take_resource(resource_type: String, requested: float) -> float
864  func can_withdraw() -> bool
869  func set_closed(value: bool) -> void
876  func set_fill_then_close(value: bool) -> void
885  func fill_fraction() -> float
892  func set_designation(resource_type: String, explicit: bool = true) -> void
900  # --- honey ---------------------------------------------------------
902  func is_ripe_honey() -> bool
906  func needs_fanning() -> bool
911  func add_fanning_progress(delta: float) -> void
921  func ripen_fraction() -> float
924  # --- brood ---------------------------------------------------------
926  func start_brood(as_gyne: bool = false, as_drone: bool = false) -> void
939  func brood_kind_label() -> String
949  func develop_time() -> float
957  func feed_brood(seconds: float, on_honey: bool) -> void
962  func needs_feeding() -> bool
966  func seconds_until_death() -> float
971  # --- clearing a dead larva ------------------------------------------
973  func needs_cleaning() -> bool
979  func add_clean_progress(delta: float) -> bool
985  func clean_fraction() -> float
988  func brood_ready() -> bool
991  func clear_cell() -> void
1006 # --- display ------------------------------------------------------
1011 func _resource_outline_colour(resource_type: String) -> Color
1025 func _refresh() -> void
1166 func _designation_tag() -> String
1188 func _priority_mark() -> String
1201 func _apply_fill_shading() -> void
1212 func development_percent() -> float
```

## debug_panel.gd (1,157 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
20   # --- preloads -----------------------------------------------------
45   # --- fields -------------------------------------------------------
87   # --- _ready and construction --------------------------------------
90   func _style_button(button: BaseButton) -> BaseButton
95   func _ready() -> void
214  func _apply_panel_width() -> void
219  func _report_settings_button_width() -> void
224  # --- collections and sections -------------------------------------
225  func _rows_in(category: String) -> Array
247  func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
278  func _set_open(header: Button, body: Control, label: String, open: bool) -> void
286  func open_to_categories(categories: Array) -> void
306  func collapse_all() -> void
314  func _make_section(category: String, entries: Array, start_open: bool) -> Control
370  # --- the Challenge stage navigator --------------------------------
375  func _make_challenge_stage_navigation() -> Control
432  func _process(_delta: float) -> void
435  func _refresh_challenge_stage_navigation() -> void
455  # --- the controls help --------------------------------------------
461  func _make_controls_help() -> Control
508  # --- the action buttons -------------------------------------------
520  func _build_actions(column: VBoxContainer) -> void
570  func _rebuild_triggers() -> void
605  func _on_end_run_pressed() -> void
616  func _refresh_developer_row() -> void
630  func _make_run_availability_button() -> Button
639  func _on_run_availability_pressed() -> void
649  func _add_action_row(parent: Control, button: Button, tip: String) -> void
655  func _make_winter_action() -> Control
667  func _on_winter_pressed() -> void
673  func _on_challenge_advance_pressed() -> void
680  func _on_challenge_retreat_pressed() -> void
694  func _on_fire_test_warnings_pressed() -> void
727  func _on_force_c2_collapse_pressed() -> void
741  # --- save and load ------------------------------------------------
747  func set_save_load_enabled(enabled: bool) -> void
755  func set_toggle(key: String, value: bool) -> void
760  func _on_save_pressed() -> void
771  func _on_load_pressed() -> void
804  # --- showing and hiding the panel ---------------------------------
805  func _toggle_panel() -> void
819  func _apply_layer_for_context() -> void
824  # --- building a settings row --------------------------------------
825  func _make_row(entry: Dictionary) -> Control
868  func _make_control_slot() -> HBoxContainer
877  func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
907  func _make_toggle_row(entry: Dictionary) -> Control
980  func _make_options_row(entry: Dictionary) -> Control
1013 func _option_display(entry: Dictionary, value) -> String
1017 func _cycle_option(entry: Dictionary, direction: int) -> void
1028 # --- prerequisite cascades ----------------------------------------
1032 func _cascade_prerequisites_on(key: String) -> void
1046 func _cascade_dependents_off(key: String) -> void
1054 func _cascade_mutual_exclusion(key: String) -> void
1059 # --- star rows and value editing ----------------------------------
1064 func _make_star_row(entry: Dictionary) -> Control
1105 func _adjust(entry: Dictionary, delta: float) -> void
1122 func _format_value(v) -> String
1129 # --- restart and main menu ----------------------------------------
1130 func _on_restart_pressed() -> void
1135 func _on_main_menu_pressed() -> void
1143 func _restart() -> void
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

## game_config.gd (905 lines)

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
617  # --- comb building ---
637  # --- hive geometry ---
666  # --- bee life ---
671  # --- bee individuality ---
750  # --- the rival colony ---
799  # --- seasons ---
831  # --- disease ---
859  # --- gynes leaving ---
871  # --- nuptial flights ---
879  # --- winter ---
```

## main_menu.gd (728 lines)

The main menu overlay: the honeycomb of stage hexes, their name fitting,
and the menu buttons.

```
150  # --- lifecycle -------------------------------------------------------
152  func _ready() -> void
291  func open() -> void
304  func close() -> void
311  # --- settings ----------------------------------------------------------
321  func _build_settings_button(right_pane: VBoxContainer) -> void
342  func _on_settings_pressed() -> void
349  # --- the honeycomb ------------------------------------------------------
357  func _hex_row_offset() -> float
364  func _hex_row_height() -> float
367  func _make_honeycomb_strip(group_key: String) -> Control
402  static func hex_fit_size(font: Font, text: String, avail: Vector2, base: int, line_spacing: int) -> int
411  static func hex_text_fits(font: Font, text: String, avail: Vector2, size: int, line_spacing: int) -> bool
421  func _fit_hex_label(label: Label) -> void
437  func _make_hex_tile(stage: Dictionary) -> Control
530  func _apply_hex_colors(level: int, state: String) -> void
541  func _refresh_hex_state(level: int) -> void
544  func _refresh_ticks() -> void
551  func _stage_for_level(level: int) -> Dictionary
557  # --- selection and the detail pane ---------------------------------------
559  func _select_stage(stage: Dictionary) -> void
569  func _rebuild_detail_pane(stage: Dictionary) -> void
601  func _make_note_label(text: String) -> Label
612  func _make_preset_row(stage: Dictionary) -> Control
629  func _make_preset_description() -> Control
639  func _make_custom_controls() -> Control
647  func _make_custom_row(field: Dictionary) -> Control
691  # --- choosing --------------------------------------------------------
693  func _choose(stage: Dictionary) -> void
700  # --- small shared helpers ---------------------------------------------
705  func _uses_presets(stage: Dictionary) -> bool
708  func _style_button(button: Button, selected: bool = false) -> void
715  func _is_challenge_complete(level: int) -> bool
718  func _is_scenario_played(level: int) -> bool
725  func _is_completed(stage: Dictionary) -> bool
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
432  func _place_keep_clear(global_point: Vector2, _keep_adding: bool) -> void
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
