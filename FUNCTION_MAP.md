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

## hud.gd (3,678 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
26   # --- signals ------------------------------------------------------
116  # --- role controls ------------------------------------------------
128  static func hatch_options() -> Array
177  static func mode_command(role_id: int, mode_key: String) -> String
180  # --- shared layout constants --------------------------------------
216  # --- fields -------------------------------------------------------
528  # --- problem strip ------------------------------------------------
537  func _signal_color(severity: int) -> Color
544  # --- _ready and construction --------------------------------------
559  func _ready() -> void
629  func _on_viewport_size_changed() -> void
635  func _build_stage_marker_arrow() -> void
653  func set_stage_marker(global_position: Vector2, marker_visible: bool, in_hive: bool) -> void
658  func _make_label(pos: Vector2, variation: String = "Body") -> Label
666  func _info(text: String) -> Button
669  func _with_info(control: Control, tip: String) -> HBoxContainer
674  func _style_button(button: BaseButton) -> BaseButton
679  # --- speed controls -----------------------------------------------
703  func _build_top_right_bar() -> void
835  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
871  func _apply_interface_label_visibility() -> void
877  # --- Challenge goal readout ---------------------------------------
882  func _build_goal_shelf() -> void
949  func set_settings_button_width(width: float) -> void
963  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
978  func set_speed_display(speed_scale: float) -> void
983  # --- bottom row ---------------------------------------------------
988  func _build_selection_panel() -> void
1115 func _build_favourite_star() -> Control
1146 func _set_favourite_star(bee) -> void
1174 func _field_control(field_name: String) -> Control
1188 func _build_selection_cog() -> Control
1215 func _theme_popup_on_open(popup: PopupMenu) -> void
1235 func _set_summary_cog_kind(kind: String) -> void
1247 func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
1267 func _apply_selection_field_visibility() -> void
1296 func _resize_selection_panel_to_content() -> void
1304 # --- command tray -------------------------------------------------
1316 func _build_command_tray() -> void
1419 func _build_tray_column(title: String) -> Array
1446 # --- cell popup ---------------------------------------------------
1462 func _build_cell_group(parent: VBoxContainer) -> void
1565 func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer
1593 func _build_priority_controls(column: VBoxContainer) -> void
1630 func _build_raises_controls(column: VBoxContainer) -> void
1703 func _build_closing_controls(column: VBoxContainer) -> void
1743 func _build_empty_controls(column: VBoxContainer) -> void
1816 func _make_hatch_menu(entry: Dictionary) -> Control
1846 func _fill_hatch_menu(popup: PopupMenu, role_value: int, options: Array) -> int
1858 func _build_warning_banner() -> void
1894 func show_warning(text: String, key: String = "", min_gap: float = 0.0, severity: int = 0) -> void
1911 func _show_warning_now(text: String, severity: int) -> void
1919 func _dismiss_warning() -> void
1924 func set_warnings_muted(value: bool) -> void
1938 func show_object_summary(kind: String, data) -> void
1965 func _refresh_flower_summary() -> void
2001 func _show_obstacle_summary(obstacle: Node2D) -> void
2007 func _show_soil_summary(count: int, reachable: int) -> void
2020 func _show_keep_clear_summary() -> void
2031 func _show_death_summary(info: Dictionary) -> void
2053 func show_cell_popup(cell: Node2D, count: int = 1) -> void
2075 func _refresh_cell_popup() -> void
2197 func _apply_cell_popup_gating() -> void
2221 func _light_current_options() -> void
2240 func _set_lit(key: String, lit: bool) -> void
2251 func _process(_delta: float) -> void
2283 func _stage_marker_screen_position() -> Vector2
2287 func _update_stage_marker_arrow() -> void
2320 func _refresh_marker_exclusion_rects(viewport_size: Vector2) -> void
2331 func _append_marker_panel_exclusion(panel: Control, owner_rect: Rect2) -> void
2336 func _slide_arrow_along_edge(edge_point: Vector2, edge_bounds: Rect2) -> Vector2
2353 func _marker_arrow_obscured(point: Vector2) -> bool
2359 func _request_designation(type: String) -> void
2364 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
2369 func _request_empty(method: String) -> void
2374 func _request_priority(tier: int) -> void
2379 func _request_close(closed: bool) -> void
2384 func _request_fill_close() -> void
2389 # --- discard warning ----------------------------------------------
2396 func _build_discard_dialog() -> void
2411 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
2430 func confirm_discard(title: String, text: String, ok_text: String, cancel_text: String, action: Callable, offer_stop_warning: bool = true) -> void
2440 func _on_discard_confirmed() -> void
2443 func _on_discard_custom_action(action: StringName) -> void
2450 func _apply_discard() -> void
2463 # --- readouts -----------------------------------------------------
2468 func update_day(day: int, note: String = "") -> void
2478 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
2487 func update_population(nectar_foragers: int, pollen_foragers: int, nurses: int, builders: int, miners: int, honey_makers: int) -> void
2493 func update_comb(text: String) -> void
2497 func update_energy(mean_fraction: float) -> void
2504 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
2515 func update_recruit_gap(text: String) -> void
2528 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
2534 func update_signals(lines: Array) -> void
2542 func _refresh_corner() -> void
2627 func _corner_line_width() -> float
2631 func _apply_corner_line_width() -> void
2640 func _fit_corner_line(line: Button) -> void
2648 func _on_corner_resized() -> void
2653 func corner_bottom() -> float
2659 func selection_panel_top() -> float
2669 func pinned_stats_changed() -> void
2678 func refresh_speed_visibility() -> void
2685 func refresh_corner() -> void
2688 func update_selection(bees: Array) -> void
2722 func _selection_has_command_lock(bees: Array) -> bool
2743 static func _detach_and_free_children(container: Node) -> void
2756 func _rebuild_role_controls(bees: Array) -> void
2811 func _build_queen_build_row(column: VBoxContainer) -> void
2825 func _build_follow_control(bees: Array, first) -> void
2840 func _build_job_row(common_role: int, any_queen: bool, queen_bee = null) -> void
2872 func _build_doing_row(common_role: int, first) -> void
2910 func _build_mating_row(bees: Array, first) -> void
2931 func _set_nuptial_flights(queen, on: bool) -> void
2942 func _build_gyne_send_row(bees: Array, first) -> void
2957 func _send_gyne(gyne) -> void
2963 func _gyne_not_ready_reason(gyne) -> String
2968 func _refresh_gyne_send_button(gyne) -> void
2974 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2991 func _build_orders_row(common_role: int, first) -> void
3038 func _build_restock_row(first) -> void
3073 func _build_fallback_row(common_role: int, first) -> void
3123 func _secondary_items() -> Array
3139 func _column_row(parent: Container) -> HFlowContainer
3147 func _labelled_row(title: String) -> HFlowContainer
3166 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
3178 func _action_button(label: String, action: Callable, tip: String) -> Control
3187 func _current_role_marker(label: String) -> Control
3202 func _common_role(bees: Array) -> int
3219 func _common_working_role(bees: Array) -> int
3237 func _make_role_menu(label: String, tip: String, items: Array, node_name: String = "") -> Control
3259 func _refresh_selection_text() -> void
3365 func _apply_selection_tray_width() -> void
3416 func _match_summary_header_button_heights() -> void
3434 func _tray_column_share(inner_width: float) -> float
3443 func _apply_even_column_widths(wrappers: Array) -> void
3471 func _update_command_tray_width() -> void
3492 func _resize_command_tray() -> void
3527 func _resettle_command_tray(generation: int, previous_content_min_y: float, stable_streak: int, pass_count: int) -> void
3541 func _apply_command_tray_rect() -> void
3559 func _on_command_content_minimum_size_changed() -> void
3566 func set_winter_button_visible(value: bool) -> void
3572 func set_view_label(in_hive: bool) -> void
3581 func set_allowed_role_keys(keys: Array) -> void
3589 func _role_offered(role_id: int, bee = null) -> bool
3595 func refresh_role_gating() -> void
3604 func set_command_locked_bees(bees: Array) -> void
3609 func set_allowed_mode_keys(keys: Array) -> void
3619 func set_allowed_designation_keys(keys: Array) -> void
3629 func set_queen_build_button_visible(value: bool) -> void
3634 # --- stage gates --------------------------------------------------
3642 func apply_gates(stage_gate) -> void
3660 func _register_gated_control(control_name: String, getter: Callable) -> void
3668 func _apply_gate_to_control(control_name: String) -> void
3677 func _is_gate_open(control_name: String) -> bool
```

## bee.gd (2,864 lines)

A bee's dispatch loop, player commands, display text, vars.

```
23   # --- preloads and shared enums ------------------------------------
56   # --- the role action catalogue ------------------------------------
75   # --- stats copied from GameConfig ---------------------------------
86   # --- role, state and identity -------------------------------------
320  func current_working_role() -> int
323  # --- floral constancy and the search pattern ----------------------
395  # --- patch memory and species experience --------------------------
422  # --- scouting -----------------------------------------------------
446  # --- trip rates and scoring ---------------------------------------
510  # --- recruitment and dancing --------------------------------------
550  # --- tipsiness (NF-3) ---------------------------------------------
571  # --- build and mine queues ----------------------------------------
595  # --- flower cooldowns and predator memory -------------------------
642  # --- pathfinding inside the hive ----------------------------------
648  # --- the visual nodes ---------------------------------------------
701  # --- _ready and construction --------------------------------------
702  func _ready() -> void
746  func _build_visuals() -> void
853  func _caste_size_factor() -> float
867  func become_drone() -> void
890  func become_queen() -> void
907  # --- nuptial flights (COL-11) -------------------------------------
913  func set_nuptial_flights(on: bool) -> void
924  func _nuptial_flight_step(delta: float) -> void
971  func _nuptial_flight_due() -> bool
981  func _begin_nuptial_flight() -> void
988  func _end_nuptial_flight() -> void
997  # --- setup, stats and appearance ----------------------------------
998  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
1040 func _roll_fact() -> void
1054 func _default_state_for_role() -> int
1076 func _base_colour() -> Color
1089 func _tinted(c: Color) -> Color
1104 func _apply_stats() -> void
1130 func trait_text() -> String
1139 func _update_role_marker() -> void
1158 # --- how often a bee thinks ---------------------------------------
1190 func _process(delta: float) -> void
1489 # --- life support -------------------------------------------------
1491 # --- eating -------------------------------------------------------
1493 # --- stall watchdog -----------------------------------------------
1499 func _reset_stall_watch() -> void
1503 # --- the tipsy wander (NF-3) --------------------------------------
1536 func _maybe_start_tipsy_wander(think_delta: float) -> void
1553 func _tipsy_wander(delta: float) -> void
1569 func _end_tipsy_wander() -> void
1578 func _tipsy_wander_target() -> Vector2
1592 func saved_state() -> int
1597 func saved_position() -> Vector2
1601 # --- foraging -----------------------------------------------------
1603 # --- entering and leaving the hive --------------------------------
1605 # --- nursery work -------------------------------------------------
1607 # --- royal jelly ---------------------------------------------------
1609 # --- idle work dispatch --------------------------------------------
1623 func _apply_pending_role() -> bool
1640 func _deliver_held_load() -> bool
1661 func _return_nurse_food() -> void
1685 func _return_bee_bread() -> void
1696 func _is_busy() -> bool
1702 func _idle_dispatch() -> void
1730 func _maybe_break_off_secondary() -> void
1754 func _try_role_work(r: int) -> bool
1779 static func _build_actions_by_role() -> Dictionary
1794 func _action_available(action_id: String) -> bool
1804 func _action_mode_for_role(r: int) -> String
1815 # --- building -----------------------------------------------------
1817 # --- keeping cells topped up ---------------------------------------
1846 func set_restock_targets(cells: Array, resource: String) -> void
1849 func set_restock_sources(cells: Array, allowed: bool) -> void
1852 func clear_restock() -> void
1855 func has_restock_orders() -> bool
1857 # --- mining -------------------------------------------------------
1859 # --- honey making -------------------------------------------------
1861 # --- egg laying (queen only) --------------------------------------
1863 # --- player commands ----------------------------------------------
1873 func command_move_to(world_point: Vector2) -> void
1893 func command_move_through_entrance(world_point: Vector2, target_in_hive: bool) -> void
1905 func command_exit_hive() -> void
1915 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
1923 func has_forage_start_point() -> bool
1926 func set_preferred_species(species: String) -> void
1939 func set_manual_build_target(hex: Vector2i) -> void
1947 func queue_build_target(hex: Vector2i) -> void
1954 func clear_build_queue() -> void
1960 func _take_next_build_target() -> bool
1973 func set_mine_target(block: Node2D) -> void
1980 func queue_mine_target(block: Node2D) -> void
1988 func clear_mine_queue() -> void
1995 func _next_queued_block() -> Node2D
2003 func set_home_hex(hex: Vector2i) -> void
2012 func set_mine_home_hex(hex: Vector2i) -> void
2018 func _mine_reference_point() -> Vector2
2033 func command_collect_from(flower: Node2D) -> void
2049 func command_collect_from_after_exit(flower: Node2D) -> void
2062 func command_return_and_deposit() -> void
2072 func command_return_only() -> void
2078 func command_deposit_at(cell: Node2D) -> void
2091 func command_empty_cell(cell: Node2D) -> void
2106 func command_deposit_at_after_enter(cell: Node2D) -> void
2114 func resume_pending_zone_command() -> bool
2133 func _clear_pending_zone_command() -> void
2138 func set_focus(type: String) -> void
2195 func _has_deliverable_target() -> bool
2201 func set_secondary_role(new_role: int) -> void
2209 func can_take_role(new_role: int) -> bool
2221 func set_role(new_role: int) -> void
2238 func _apply_role(new_role: int) -> void
2279 func _release_everything() -> void
2296 func release_flower_reference(flower: Node2D) -> void
2302 func set_selected(value: bool) -> void
2306 # --- display ------------------------------------------------------
2308 func role_letter() -> String
2337 func challenge_vocabulary_limited() -> bool
2350 func idle_reason() -> String
2402 func task_description() -> String
2411 func _task_line() -> String
2575 func _idle_backup_note() -> String
2585 func role_name_text() -> String
2623 func architect_mode_name() -> String
2629 func carrying_text() -> String
2652 func age_days() -> float
2660 func leave_to_found_colony() -> void
2673 func days_remaining() -> float
2685 func _update_label() -> void
2705 func _update_alarm_ring() -> void
2716 func _update_heading_marker() -> void
2730 func _update_search_ring() -> void
2753 func _update_dance_ring() -> void
2786 func _update_wander_flight(delta: float) -> void
2817 func _update_dance_circle(delta: float) -> void
2831 func _terrain_speed_factor() -> float
2840 func _is_inside_hive() -> bool
2843 # --- getting round things in the meadow ---------------------------
2863 func clear_navigation_state() -> void
```

## scenario_actions.gd (1,649 lines)

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
278  # --- triggers -----------------------------------------------------
288  static func _when_met(main: Node2D, when: Dictionary) -> bool
332  static func _legacy_when_spec(main: Node2D, when: Dictionary) -> Dictionary
386  # --- selectors ------------------------------------------------------
390  static func _resolve_bees(main: Node2D, target: Dictionary) -> Array
422  static func _resolve_cell_ref(main: Node2D, ref: Dictionary) -> Node2D
429  static func _resolve_cell(main: Node2D, hex: Array) -> Node2D
439  static func _resolve_soil_block(main: Node2D, hex: Array) -> Node2D
449  # --- verbs ------------------------------------------------------------
466  static func _do_assign_role(main: Node2D, action: Dictionary) -> void
533  static func _do_designate_cell(main: Node2D, action: Dictionary) -> void
557  static func _do_queue_build(main: Node2D, action: Dictionary) -> void
583  static func _do_queue_mine(main: Node2D, action: Dictionary) -> void
608  static func _do_request_placement_tool(main: Node2D, action: Dictionary) -> void
620  static func _do_click_world(main: Node2D, action: Dictionary) -> void
650  static func _do_set_config(_main: Node2D, action: Dictionary) -> void
668  static func _do_hatch_role(main: Node2D, action: Dictionary) -> void
691  static func _do_set_restock_order(main: Node2D, action: Dictionary) -> void
737  static func _do_select_bees(main: Node2D, action: Dictionary) -> void
768  static func _do_select_soil(main: Node2D, action: Dictionary) -> void
794  static func _do_select_cell(main: Node2D, action: Dictionary) -> void
813  static func _force_layout(node: Node) -> void
826  static func _do_open_window(main: Node2D, action: Dictionary) -> void
883  static func _do_close_window(main: Node2D, action: Dictionary) -> void
902  static func _do_viewport_size(main: Node2D, action: Dictionary) -> void
915  static func _do_show_gallerin_prompt(main: Node2D, action: Dictionary) -> void
931  static func _do_retreat_challenge_stage(main: Node2D, action: Dictionary) -> void
950  static func _do_advance_challenge_stage(main: Node2D, action: Dictionary) -> void
976  static func _do_set_queen_load(main: Node2D, action: Dictionary) -> void
1007 static func _do_set_bee_load(main: Node2D, action: Dictionary) -> void
1024 static func _do_set_cell_contents(main: Node2D, action: Dictionary) -> void
1048 static func _do_empty_cell(main: Node2D, action: Dictionary) -> void
1061 static func _do_clear_fermented(main: Node2D) -> void
1068 static func _do_watch_queen_states(main: Node2D, action: Dictionary) -> void
1083 static func _do_save_run(main: Node2D, action: Dictionary) -> void
1090 static func _do_buy_skill(main: Node2D, action: Dictionary) -> void
1109 static func _do_restore_slot(main: Node2D, action: Dictionary) -> void
1120 # --- assertion checks -------------------------------------------------
1130 static func _do_assert(main: Node2D, action: Dictionary) -> bool
1140 static func _evaluate_assert_condition(main: Node2D, condition: Dictionary) -> Dictionary
1185 static func _check_save_slot(main: Node2D, condition: Dictionary) -> Dictionary
1213 static func _check_all_actions_available(main: Node2D) -> Dictionary
1225 static func _queen_summary(main: Node2D, condition: Dictionary) -> String
1253 static func _check_panel_rect(main: Node2D, condition: Dictionary) -> Dictionary
1348 static func _resolve_named_panel(main: Node2D, name: String) -> Control
1362 static func _game_panel(main: Node2D, key: String) -> GamePanel
1383 static func _check_control_rect(main: Node2D, condition: Dictionary) -> Dictionary
1461 static func _check_panel_texture_contrast(_condition: Dictionary) -> Dictionary
1488 static func _check_menu_items(main: Node2D, condition: Dictionary) -> Dictionary
1507 static func _label_leading(control: Control) -> Dictionary
1521 static func _check_even_columns(main: Node2D, condition: Dictionary) -> Dictionary
1561 static func _check_no_collapsed_controls(main: Node2D, condition: Dictionary) -> Dictionary
1578 static func _check_no_empty_labels(main: Node2D, condition: Dictionary) -> Dictionary
1589 static func _collect_empty_labels(node: Node, out: Array) -> void
1595 static func _collect_collapsed_controls(node: Node, out: Array) -> void
1615 static func _resolve_scoped_path(main: Node2D, path: String) -> Node
1648 static func _log(do: String, target_desc: String, result: String, reason: String) -> void
```

## settings_catalogue.gd (1,544 lines)

Every setting's key, label, range and tip, plus the read/write and Prerequisites-cascade functions the window is a view of.

```
22   # --- preloads and collection order --------------------------------
48   # --- the tunables table -------------------------------------------
1419 # --- settings owned by Session ------------------------------------
1433 # --- reading and writing a setting --------------------------------
1434 static func setting_get(key: String)
1437 static func setting_set(key: String, value) -> void
1444 # --- resetting ----------------------------------------------------
1461 static func reset_config_to_defaults() -> void
1473 static func reset_config_keys(keys: Array) -> void
1479 # --- applying a setting with its cascades -------------------------
1488 static func apply_setting(key: String, value) -> void
1499 # --- the cascade helpers ------------------------------------------
1504 static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1522 static func _cascade_dependents_off_static(key: String) -> Array[String]
1536 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
```

## bee_foraging.gd (1,497 lines)

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
239  static func advance_search_waypoint(bee: Node2D) -> void
255  static func _perceive_flower(bee: Node2D) -> Node2D
266  static func perception_radius(bee: Node2D) -> float
272  static func _commit_to_flower(bee: Node2D, flower: Node2D) -> void
280  # --- patch memory and the search spiral ---------------------------
286  static func _remember_patch(bee: Node2D, position: Vector2) -> void
299  static func _pick_known_patch(bee: Node2D) -> Vector2
323  static func _spiral_point(bee: Node2D, anchor: Vector2, angle: float) -> Vector2
335  # --- choosing a flower --------------------------------------------
353  static func nearest_flower(bee: Node2D, strict: bool, radius: float, allow_full_scan: bool = true) -> Node2D
450  static func _weighted_flower_choice(bee: Node2D, nodes: Array, accept: Callable, radius: float) -> Node2D
488  static func flower_grid(bee: Node2D)
503  # --- inspecting, drinking and sheltering --------------------------
504  static func start_inspecting(bee: Node2D) -> void
509  static func inspect(bee: Node2D, delta: float) -> void
532  static func needs_a_drink(bee: Node2D) -> bool
540  static func drink_at_flower(bee: Node2D, delta: float) -> void
565  static func nectar_strength(_bee: Node2D) -> float
573  static func shelter(bee: Node2D, _delta: float) -> void
589  static func recall_for_rain(bee: Node2D) -> void
599  # --- skill-or-setting behaviour switches ---------------------------
604  static func adaptive_constancy_on() -> bool
608  static func tarsal_markers_on() -> bool
611  static func orientation_flight_on() -> bool
615  # --- accepting or rejecting a flower ------------------------------
616  static func worth_feeding(bee: Node2D, f: Node2D) -> bool
629  static func reject_flower(bee: Node2D) -> void
647  # --- collecting ---------------------------------------------------
648  static func start_collecting(bee: Node2D) -> void
721  static func _handling_experience_scale(bee: Node2D, species: String) -> float
730  static func collect(bee: Node2D, delta: float) -> void
779  static func finish_collecting(bee: Node2D) -> void
818  # --- entering the hive and depositing -----------------------------
822  static func enter_hive(bee: Node2D) -> void
849  static func approach_cell(bee: Node2D, cell: Node2D, delta: float) -> int
864  static func release_cell_slot(bee: Node2D) -> void
871  static func go_to_deposit_cell(bee: Node2D, delta: float) -> void
961  static func finish_depositing(bee: Node2D) -> void
1001 static func _after_delivery_state(bee: Node2D) -> int
1012 static func _resume_own_job_if_indoors(bee: Node2D) -> bool
1020 # --- scoring a trip -----------------------------------------------
1025 static func _score_trip(bee: Node2D) -> void
1103 # --- leaving the hive ---------------------------------------------
1104 static func go_to_exit(bee: Node2D, delta: float) -> void
1148 static func _entrance_wait_spot(bee: Node2D, side: int) -> Vector2
1160 static func _leave_hive_and_resume(bee: Node2D) -> void
1187 static func _send_to_scout_point(bee: Node2D) -> void
1198 # --- scouting -----------------------------------------------------
1204 static func start_scouting(bee: Node2D) -> void
1222 # --- waiting at the entrance --------------------------------------
1227 static func wait_at_entrance(bee: Node2D, delta: float) -> void
1331 # --- the recruitment dance ----------------------------------------
1339 static func _update_dance_eligibility(bee: Node2D) -> void
1362 static func leave_recruitment(bee: Node2D) -> void
1384 static func check_dance_proximity(bee: Node2D, _delta: float) -> void
1409 static func _start_dance(mentor: Node2D, seeker: Node2D) -> void
1429 static func dance(bee: Node2D, delta: float) -> void
1441 static func _end_dance(bee: Node2D) -> void
1463 static func _complete_dance(mentor: Node2D, seeker: Node2D) -> void
1490 # --- remote deposit -----------------------------------------------
1492 static func deposit_everything_remotely(bee: Node2D) -> void
```

## main.gd (1,343 lines)

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
661  # --- public surface other scripts call directly -------------------
668  func is_on_screen(node: Node2D) -> bool
671  func hive_entrance_inside() -> Vector2
674  func entrance_wait_point(side: int) -> Vector2
677  func move_bee_into_hive(bee: Node2D) -> void
680  func move_bee_out_of_hive(bee: Node2D) -> void
683  func mark_death(bee: Node2D) -> void
691  func _on_bee_died(bee: Node2D) -> void
695  func finish_mining(block: Node2D) -> void
698  func save_run() -> void
701  func begin_winter_countdown() -> void
704  # --- per-frame ----------------------------------------------------
714  func _process(delta: float) -> void
801  # --- the frame rate readout ----------------------------------------
820  func _sample_fps() -> void
843  func _reseed_meadow(delta: float) -> void
863  func _hatch_ready_brood() -> void
899  func _sample_day_stores() -> void
916  func _advance_weather(delta: float) -> void
946  func _apply_rain_overlay() -> void
973  func _check_for_loss() -> void
1001 func _promote_gyne_to_queen() -> bool
1022 func _check_colony_energy(delta: float) -> void
1053 func invalidate_population() -> void
1064 func _role_counts(bees = null) -> Dictionary
1081 func _update_population_readout(bees = null) -> void
1095 func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
1101 func _prune_selection() -> void
1114 func _on_restart_after_loss() -> void
1120 func _on_level_chosen(level: int) -> void
1133 func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
1151 func _apply_scenario_boot_arg() -> void
1276 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1316 func _is_whole_number(value: Variant) -> bool
1330 func _end_scenario_run(outcome: String) -> void
```

## hive_cell.gd (1,320 lines)

One cell: contents, brood, honey ripening, how it draws.

```
25   # --- constants and colours ----------------------------------------
114  # --- cell state ---------------------------------------------------
164  # --- building state -----------------------------------------------
188  func effective_build_time() -> float
191  # --- designation and orders ---------------------------------------
233  # --- hatch settings -----------------------------------------------
251  # --- layout and display nodes -------------------------------------
292  # --- slots --------------------------------------------------------
306  # --- setup --------------------------------------------------------
308  func _ready() -> void
422  # --- overlay, selection and rings ---------------------------------
429  func set_overlay(mode: String) -> void
435  func _overlay_colour() -> Array
475  func set_selected(value: bool) -> void
487  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
498  func _set_outline_points(line: Line2D, size: float) -> void
509  func _silhouette_point_to_local(p: Vector2) -> Vector2
521  func _set_outline_points_cup(line: Line2D, size: float) -> void
537  func _apply_outline_points(line: Line2D, size: float) -> void
545  func _set_selection_ring_points() -> void
548  # --- per-frame update ---------------------------------------------
566  func _process(delta: float) -> void
587  # --- brood development --------------------------------------------
592  func _develop_brood(delta: float) -> void
613  func _health_factor() -> float
621  func _larva_dies() -> void
634  # --- index and display epochs -------------------------------------
640  func _invalidate_hive_index() -> void
650  func _invalidate_stock() -> void
664  func bump_display_epoch() -> void
667  # --- working positions --------------------------------------------
672  func claim_slot(bee: Node2D) -> int
683  func release_slot(bee: Node2D) -> void
690  func has_free_slot() -> bool
699  func slot_position(index: int) -> Vector2
711  # --- building -----------------------------------------------------
713  func start_as_site() -> void
718  func claim_builder(bee: Node2D) -> void
722  func release_builder(bee: Node2D) -> void
728  func add_build_progress(delta: float) -> void
739  func build_fraction() -> float
742  # --- contents -----------------------------------------------------
744  func is_empty() -> bool
749  func capacity_for(resource_type: String) -> float
757  func accepts(resource_type: String) -> bool
776  func is_nursery_cell() -> bool
779  func space_for(resource_type: String) -> float
801  func needs_eviction() -> bool
819  func add_resource(resource_type: String, requested: float) -> float
865  func nectar_age() -> float
877  func is_fermented() -> bool
885  func restore_bee_bread_seal() -> void
893  func is_bee_bread_sealed() -> bool
899  func is_ripe_bee_bread() -> bool
903  func bee_bread_ripen_fraction() -> float
911  func take_resource(resource_type: String, requested: float) -> float
947  func can_withdraw() -> bool
952  func set_closed(value: bool) -> void
959  func set_fill_then_close(value: bool) -> void
968  func fill_fraction() -> float
976  func set_designation(resource_type: String, explicit: bool = true) -> void
984  # --- honey ---------------------------------------------------------
986  func is_ripe_honey() -> bool
990  func needs_fanning() -> bool
995  func add_fanning_progress(delta: float) -> void
1005 func ripen_fraction() -> float
1008 # --- brood ---------------------------------------------------------
1010 func start_brood(as_gyne: bool = false, as_drone: bool = false) -> void
1023 func brood_kind_label() -> String
1033 func develop_time() -> float
1041 func feed_brood(seconds: float, on_honey: bool) -> void
1046 func needs_feeding() -> bool
1050 func seconds_until_death() -> float
1055 # --- clearing a dead larva ------------------------------------------
1057 func needs_cleaning() -> bool
1063 func add_clean_progress(delta: float) -> bool
1069 func clean_fraction() -> float
1072 func brood_ready() -> bool
1075 func clear_cell() -> void
1091 # --- display ------------------------------------------------------
1096 func _resource_outline_colour(resource_type: String) -> Color
1112 func _refresh() -> void
1269 func _designation_tag() -> String
1293 func _priority_mark() -> String
1306 func _apply_fill_shading() -> void
1317 func development_percent() -> float
```

## diagnostic_log.gd (1,250 lines)

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
1135 func _flower_season_counts(world: Node2D) -> Dictionary
1163 func _performance_snapshot(world: Node2D) -> Dictionary
1183 func _rate(world: Node2D, key: String) -> float
1195 # --- writing to disk ----------------------------------------------
1199 func _current_day() -> int
1203 func _prune_old_sessions() -> void
1221 func _write(entry: Dictionary) -> void
1230 func _capture_entry(entry: Dictionary) -> bool
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

## hive.gd (1,139 lines)

The comb as a whole: cells, navigation, finding a cell.

```
51   func add_entrance_mentor(bee: Node2D) -> void
55   func remove_entrance_mentor(bee: Node2D) -> void
72   func add_dance_eligible_mentor(bee: Node2D) -> void
76   func remove_dance_eligible_mentor(bee: Node2D) -> void
79   func add_dance_eligible_seeker(bee: Node2D) -> void
83   func remove_dance_eligible_seeker(bee: Node2D) -> void
86   func record_collection(resource_type: String, amount: float) -> void
92   func record_birth() -> void
95   # --- cell index ---------------------------------------------------
114  func _content_index() -> Dictionary
151  func invalidate_index() -> void
154  func cells_holding(content: String) -> Array
171  func invalidate_stock() -> void
174  func _stock() -> Dictionary
204  func register_tile(hex: Vector2i, node: Node2D) -> void
210  func invalidate_mining_work() -> void
214  func _advance_mining_work_epoch() -> void
217  func tile_is_free(hex: Vector2i) -> bool
222  func tile_is_interior(hex: Vector2i) -> bool
227  func cell_at_tile(hex: Vector2i) -> Node2D
233  func _ready() -> void
243  func deposit(resource_type: String, amount: float) -> float
262  func take(resource_type: String, amount: float) -> float
277  func take_energy(energy_wanted: float) -> float
290  func total(resource_type: String) -> float
296  func total_sealed() -> float
300  func total_honey() -> float
303  # --- finding cells ------------------------------------------------
316  func find_cell_for(resource_type: String, except: Node2D = null) -> Node2D
340  func find_designated_cell_for(resource_type: String, except: Node2D = null) -> Node2D
378  func find_empty_cell() -> Node2D
424  func _lay_by_priority(pool: Array) -> Node2D
455  func _tier_weights() -> Array
470  func record_lay(cell: Node2D) -> void
484  func zone_summary() -> Dictionary
514  func brood_stage_counts() -> Dictionary
529  func find_food_cell(except: Node2D = null) -> Node2D
546  func has_room_for_egg() -> bool
549  func find_cell_with(resource_type: String) -> Node2D
562  func find_honey_source() -> Node2D
572  func find_brood_cell() -> Node2D
587  func find_cell_needing_fanning() -> Node2D
595  func find_honey_target() -> Node2D
604  func find_bee_bread_target(except: Node2D = null) -> Node2D
613  func can_take(resource_type: String, amount: float) -> bool
623  func find_unfinished_cell() -> Node2D
632  func find_cell_needing_cleaning() -> Node2D
636  func find_cell_needing_eviction() -> Node2D
644  func has_gyne_brood() -> bool
652  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
655  # --- bodies -------------------------------------------------------
666  func add_body(point: Vector2, died_at: float) -> Node2D
680  func remove_body(body: Node2D) -> void
687  func find_body_to_clear() -> Node2D
696  func clear_bodies() -> void
701  func _free_body(body: Node2D) -> void
709  # --- growing the comb ---------------------------------------------
743  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
777  func set_keep_clear(hex: Vector2i, value: bool) -> void
783  func is_keep_clear(hex: Vector2i) -> bool
790  func can_build_on(hex: Vector2i) -> bool
793  func _can_build_on(hex: Vector2i) -> bool
796  func _start_site_at(hex: Vector2i) -> Node2D
818  func create_cell_site_at(hex: Vector2i) -> Node2D
823  # --- navigation ---------------------------------------------------
834  func build_navigation() -> void
875  func _is_solid(hex: Vector2i) -> bool
881  func _tile_cost(hex: Vector2i) -> float
884  func tile_is_walkable(hex: Vector2i) -> bool
893  func nearest_walkable_point(point: Vector2) -> Vector2
920  func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
954  func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
978  func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
992  # --- mining -------------------------------------------------------
1001 func refresh_edge_flags() -> void
1023 func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
1051 func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
1075 func _is_markable_block(node) -> bool
1082 func mine_stand_hex(block: Node2D)
1105 func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
1127 func remove_block(block: Node2D, floor_maker: Callable) -> void
1138 func announce() -> void
```

## game_config.gd (968 lines)

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
573  # --- bee bread (BB-1) ---
587  # --- weather ---
605  # --- warnings ---
614  # --- honey ---
658  # --- comb building ---
678  # --- hive geometry ---
707  # --- bee life ---
712  # --- bee individuality ---
791  # --- the rival colony ---
840  # --- seasons ---
872  # --- disease ---
911  # --- gynes leaving ---
923  # --- nuptial flights ---
931  # --- winter ---
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
