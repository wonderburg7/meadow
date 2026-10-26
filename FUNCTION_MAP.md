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

## hud.gd (4,075 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
28   # --- signals ------------------------------------------------------
121  # --- role controls ------------------------------------------------
133  static func hatch_options() -> Array
182  static func mode_command(role_id: int, mode_key: String) -> String
185  # --- shared layout constants --------------------------------------
221  # --- fields -------------------------------------------------------
549  # --- problem strip ------------------------------------------------
567  func _signal_color(severity: int) -> Color
574  # --- _ready and construction --------------------------------------
591  func _ready() -> void
668  func _on_viewport_size_changed() -> void
674  func _build_stage_marker_arrow() -> void
692  func set_stage_marker(global_position: Vector2, marker_visible: bool, in_hive: bool) -> void
697  func _make_label(pos: Vector2, variation: String = "Body") -> Label
705  func _info(text: String) -> Button
708  func _with_info(control: Control, tip: String) -> HBoxContainer
713  func _style_button(button: BaseButton) -> BaseButton
718  # --- speed controls -----------------------------------------------
742  func _build_top_right_bar() -> void
889  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
925  func _apply_interface_label_visibility() -> void
931  # --- Challenge goal readout ---------------------------------------
936  func _build_goal_shelf() -> void
1024 func set_settings_button_width(width: float) -> void
1038 func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
1066 func set_colony_goals(entries: Array) -> void
1098 func _apply_goals_collapsed() -> void
1110 func _add_goal_star(label: Control) -> void
1132 func _set_goal_star(label: Control, id: String, entries: Array) -> void
1147 func _on_goal_star_pressed(star: Button) -> void
1154 func _rebuild_favourites(entries: Array) -> void
1174 func _on_goals_button_pressed() -> void
1179 func set_speed_display(speed_scale: float) -> void
1184 # --- bottom row ---------------------------------------------------
1189 func _build_selection_panel() -> void
1316 func _build_favourite_star() -> Control
1347 func _set_favourite_star(bee) -> void
1375 func _field_control(field_name: String) -> Control
1389 func _build_selection_cog() -> Control
1416 func _theme_popup_on_open(popup: PopupMenu) -> void
1436 func _set_summary_cog_kind(kind: String) -> void
1448 func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
1468 func _apply_selection_field_visibility() -> void
1497 func _resize_selection_panel_to_content() -> void
1505 # --- command tray -------------------------------------------------
1517 func _build_command_tray() -> void
1620 func _build_tray_column(title: String) -> Array
1647 # --- cell popup ---------------------------------------------------
1663 func _build_cell_group(parent: VBoxContainer) -> void
1766 func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer
1794 func _build_priority_controls(column: VBoxContainer) -> void
1831 func _build_raises_controls(column: VBoxContainer) -> void
1920 func _build_closing_controls(column: VBoxContainer) -> void
1960 func _build_empty_controls(column: VBoxContainer) -> void
2033 func _make_hatch_menu(entry: Dictionary) -> Control
2063 func _fill_hatch_menu(popup: PopupMenu, role_value: int, options: Array) -> int
2079 func _build_warning_banner() -> void
2115 func show_warning(text: String, key: String = "", min_gap: float = 0.0, severity: int = 0) -> void
2132 func _show_warning_now(text: String, severity: int) -> void
2140 func _dismiss_warning() -> void
2145 func set_warnings_muted(value: bool) -> void
2159 func show_object_summary(kind: String, data) -> void
2186 func _refresh_flower_summary() -> void
2222 func _show_obstacle_summary(obstacle: Node2D) -> void
2228 func _show_soil_summary(count: int, reachable: int) -> void
2241 func _show_keep_clear_summary() -> void
2252 func _show_death_summary(info: Dictionary) -> void
2274 func show_cell_popup(cell: Node2D, count: int = 1) -> void
2296 func _cell_content_lines(cell, count: int) -> Array
2351 func _cell_state_lines(cell) -> Array
2373 func _cell_hatch_text(cell) -> String
2388 func _refresh_cell_popup() -> void
2430 func _apply_cell_popup_gating() -> void
2456 func _light_current_options() -> void
2475 func _set_lit(key: String, lit: bool) -> void
2486 func _process(_delta: float) -> void
2518 func _stage_marker_screen_position() -> Vector2
2522 func _update_stage_marker_arrow() -> void
2555 func _refresh_marker_exclusion_rects(viewport_size: Vector2) -> void
2566 func _append_marker_panel_exclusion(panel: Control, owner_rect: Rect2) -> void
2571 func _slide_arrow_along_edge(edge_point: Vector2, edge_bounds: Rect2) -> Vector2
2588 func _marker_arrow_obscured(point: Vector2) -> bool
2594 func _request_designation(type: String) -> void
2599 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
2604 func _request_empty(method: String) -> void
2609 func _request_priority(tier: int) -> void
2614 func _request_close(closed: bool) -> void
2619 func _request_fill_close() -> void
2624 # --- discard warning ----------------------------------------------
2631 func _build_discard_dialog() -> void
2646 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
2665 func confirm_discard(title: String, text: String, ok_text: String, cancel_text: String, action: Callable, offer_stop_warning: bool = true) -> void
2675 func _on_discard_confirmed() -> void
2678 func _on_discard_custom_action(action: StringName) -> void
2685 func _apply_discard() -> void
2698 # --- readouts -----------------------------------------------------
2703 func update_day(day: int, note: String = "") -> void
2721 func set_weather_note(text: String) -> void
2733 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
2746 func _refresh_stores_text() -> void
2756 func update_population(nectar_foragers: int, pollen_foragers: int, nurses: int, builders: int, miners: int, honey_makers: int) -> void
2762 func update_comb(text: String) -> void
2766 func update_energy(mean_fraction: float) -> void
2773 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
2784 func update_recruit_gap(text: String) -> void
2797 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
2803 func update_signals(lines: Array) -> void
2811 func _red_always_shows() -> bool
2816 func strip_lines() -> Array
2830 func _remove_signal(id: String) -> void
2835 func _corner_signature(strip: Array) -> String
2844 func _rebuild_corner_labels() -> void
2861 func _add_signal_row(entry: Array) -> void
2897 func _rebuild_corner_signals(strip: Array) -> void
2911 func _refresh_corner() -> void
2962 func _corner_line_width() -> float
2966 func _apply_corner_line_width() -> void
2975 func _fit_corner_line(line: Button) -> void
2985 func corner_bottom() -> float
2991 func selection_panel_top() -> float
3001 func pinned_stats_changed() -> void
3010 func refresh_speed_visibility() -> void
3017 func refresh_corner() -> void
3020 func update_selection(bees: Array) -> void
3054 func _selection_has_command_lock(bees: Array) -> bool
3075 static func _detach_and_free_children(container: Node) -> void
3088 func _rebuild_role_controls(bees: Array) -> void
3143 func _build_queen_build_row(column: VBoxContainer) -> void
3157 func _build_follow_control(bees: Array, first) -> void
3172 func _build_job_row(common_role: int, any_queen: bool, queen_bee = null) -> void
3204 func _build_doing_row(common_role: int, first) -> void
3242 func _build_mating_row(bees: Array, first) -> void
3263 func _set_nuptial_flights(queen, on: bool) -> void
3274 func _build_gyne_send_row(bees: Array, first) -> void
3289 func _send_gyne(gyne) -> void
3295 func _gyne_not_ready_reason(gyne) -> String
3300 func _refresh_gyne_send_button(gyne) -> void
3306 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
3323 func _build_orders_row(common_role: int, first) -> void
3371 func _build_restock_row(first) -> void
3408 func _build_fallback_row(common_role: int, first) -> void
3462 func _build_backup_order(row: HFlowContainer) -> void
3496 func _on_backup_editor_changed(keys: Array, focus: String) -> void
3502 func _secondary_items() -> Array
3518 func _column_row(parent: Container) -> HFlowContainer
3526 func _labelled_row(title: String) -> HFlowContainer
3545 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
3557 func _action_button(label: String, action: Callable, tip: String) -> Control
3566 func _current_role_marker(label: String) -> Control
3581 func _common_role(bees: Array) -> int
3598 func _common_working_role(bees: Array) -> int
3616 func _make_role_menu(label: String, tip: String, items: Array, node_name: String = "") -> Control
3637 func _selection_identity_text(b) -> String
3651 func _selection_energy_text(b) -> String
3660 func _selection_activity_text(b, instruction_runner, stuck: String) -> String
3688 func _selection_trait_text(b) -> String
3702 func _refresh_selection_text() -> void
3762 func _apply_selection_tray_width() -> void
3813 func _match_summary_header_button_heights() -> void
3831 func _tray_column_share(inner_width: float) -> float
3840 func _apply_even_column_widths(wrappers: Array) -> void
3868 func _update_command_tray_width() -> void
3889 func _resize_command_tray() -> void
3924 func _resettle_command_tray(generation: int, previous_content_min_y: float, stable_streak: int, pass_count: int) -> void
3938 func _apply_command_tray_rect() -> void
3956 func _on_command_content_minimum_size_changed() -> void
3963 func set_winter_button_visible(value: bool) -> void
3969 func set_view_label(in_hive: bool) -> void
3978 func set_allowed_role_keys(keys: Array) -> void
3986 func _role_offered(role_id: int, bee = null) -> bool
3992 func refresh_role_gating() -> void
4001 func set_command_locked_bees(bees: Array) -> void
4006 func set_allowed_mode_keys(keys: Array) -> void
4016 func set_allowed_designation_keys(keys: Array) -> void
4026 func set_queen_build_button_visible(value: bool) -> void
4031 # --- stage gates --------------------------------------------------
4039 func apply_gates(stage_gate) -> void
4057 func _register_gated_control(control_name: String, getter: Callable) -> void
4065 func _apply_gate_to_control(control_name: String) -> void
4074 func _is_gate_open(control_name: String) -> bool
```

## bee.gd (3,182 lines)

A bee's dispatch loop, player commands, display text, vars.

```
23   # --- preloads and shared enums ------------------------------------
58   # --- the role action catalogue ------------------------------------
77   # --- stats copied from GameConfig ---------------------------------
88   # --- role, state and identity -------------------------------------
347  func current_working_role() -> int
372  static func work_priorities_owned() -> bool
377  func _keeps_backup_order() -> bool
383  func seed_backup_order() -> void
392  func backup_list() -> Array
399  func set_backup_order(order: Variant) -> void
408  func clear_backup_order() -> void
412  # --- floral constancy and the search pattern ----------------------
484  # --- patch memory and species experience --------------------------
511  # --- scouting -----------------------------------------------------
535  # --- trip rates and scoring ---------------------------------------
599  # --- recruitment and dancing --------------------------------------
639  # --- tipsiness (NF-3) ---------------------------------------------
660  # --- build and mine queues ----------------------------------------
684  # --- flower cooldowns and predator memory -------------------------
738  # --- pathfinding inside the hive ----------------------------------
744  # --- the visual nodes ---------------------------------------------
797  # --- _ready and construction --------------------------------------
798  func _ready() -> void
843  func _build_visuals() -> void
950  func _caste_size_factor() -> float
964  func become_drone() -> void
991  func become_queen() -> void
1009 # --- nuptial flights (COL-11) -------------------------------------
1015 func set_nuptial_flights(on: bool) -> void
1026 func _nuptial_flight_step(delta: float) -> void
1073 func _nuptial_flight_due() -> bool
1083 func _begin_nuptial_flight() -> void
1090 func _end_nuptial_flight() -> void
1099 # --- setup, stats and appearance ----------------------------------
1100 func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
1146 func _roll_fact() -> void
1160 func _default_state_for_role() -> int
1182 func _base_colour() -> Color
1195 func _tinted(c: Color) -> Color
1210 func _apply_stats() -> void
1242 func set_brood_outcome(outcome: String) -> void
1247 func outcome_stat_factor() -> float
1259 func outcome_lifespan_days() -> float
1269 func brood_outcome_text() -> String
1284 func trait_text() -> String
1293 func _update_role_marker() -> void
1312 # --- how often a bee thinks ---------------------------------------
1347 func _process(delta: float) -> void
1651 # --- life support -------------------------------------------------
1653 # --- eating -------------------------------------------------------
1655 # --- stall watchdog -----------------------------------------------
1661 func _reset_stall_watch() -> void
1665 # --- the tipsy wander (NF-3) --------------------------------------
1698 func _maybe_start_tipsy_wander(think_delta: float) -> void
1715 func _tipsy_wander(delta: float) -> void
1731 func _end_tipsy_wander() -> void
1740 func _tipsy_wander_target() -> Vector2
1754 func saved_state() -> int
1759 func saved_position() -> Vector2
1763 # --- foraging -----------------------------------------------------
1765 # --- entering and leaving the hive --------------------------------
1767 # --- nursery work -------------------------------------------------
1769 # --- royal jelly ---------------------------------------------------
1771 # --- idle work dispatch --------------------------------------------
1785 func _apply_pending_role() -> bool
1802 func _deliver_held_load() -> bool
1823 func _return_nurse_food() -> void
1851 func _return_ripe_bee_bread(amount: float) -> float
1872 func _return_bee_bread() -> void
1890 func _put_down_body() -> void
1900 func _is_busy() -> bool
1906 func _idle_dispatch() -> void
1940 func _dispatch_backup_list() -> void
1959 func _backup_job_permitted(job: int) -> bool
1973 func _record_work_search(found: bool) -> bool
1979 func is_waiting_for_work() -> bool
1985 func has_no_available_work() -> bool
1991 func is_travelling_for_work() -> bool
2009 func _maybe_break_off_secondary() -> void
2033 func _try_role_work(r: int) -> bool
2059 static func _build_actions_by_role() -> Dictionary
2074 func _action_available(action_id: String) -> bool
2084 func _action_mode_for_role(r: int) -> String
2095 # --- building -----------------------------------------------------
2097 # --- keeping cells topped up ---------------------------------------
2126 func set_restock_targets(cells: Array, resource: String) -> void
2129 func set_restock_sources(cells: Array, allowed: bool) -> void
2132 func clear_restock() -> void
2135 func has_restock_orders() -> bool
2137 # --- mining -------------------------------------------------------
2139 # --- honey making -------------------------------------------------
2141 # --- egg laying (queen only) --------------------------------------
2143 # --- player commands ----------------------------------------------
2153 func command_move_to(world_point: Vector2) -> void
2173 func command_move_through_entrance(world_point: Vector2, target_in_hive: bool) -> void
2185 func command_exit_hive() -> void
2195 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
2203 func has_forage_start_point() -> bool
2206 func set_preferred_species(species: String) -> void
2219 func set_manual_build_target(hex: Vector2i) -> void
2227 func queue_build_target(hex: Vector2i) -> void
2234 func clear_build_queue() -> void
2240 func _take_next_build_target() -> bool
2253 func set_mine_target(block: Node2D) -> void
2260 func queue_mine_target(block: Node2D) -> void
2268 func clear_mine_queue() -> void
2275 func _next_queued_block() -> Node2D
2283 func set_home_hex(hex: Vector2i) -> void
2292 func set_mine_home_hex(hex: Vector2i) -> void
2298 func _mine_reference_point() -> Vector2
2313 func command_collect_from(flower: Node2D) -> void
2329 func command_collect_from_after_exit(flower: Node2D) -> void
2342 func command_return_and_deposit() -> void
2352 func command_return_only() -> void
2358 func command_deposit_at(cell: Node2D) -> void
2371 func command_empty_cell(cell: Node2D) -> void
2386 func command_deposit_at_after_enter(cell: Node2D) -> void
2394 func resume_pending_zone_command() -> bool
2413 func _clear_pending_zone_command() -> void
2418 func set_focus(type: String) -> void
2475 func _has_deliverable_target() -> bool
2481 func set_secondary_role(new_role: int) -> void
2500 func can_take_role(new_role: int) -> bool
2512 func set_role(new_role: int) -> void
2529 func _apply_role(new_role: int) -> void
2573 func _release_everything() -> void
2590 func release_flower_reference(flower: Node2D) -> void
2596 func set_selected(value: bool) -> void
2600 # --- display ------------------------------------------------------
2602 func role_letter() -> String
2631 func challenge_vocabulary_limited() -> bool
2645 func idle_reason() -> String
2703 func task_description() -> String
2713 func _task_line() -> String
2877 func _idle_backup_note() -> String
2891 func role_name_text() -> String
2929 func architect_mode_name() -> String
2935 func carrying_text() -> String
2961 func age_days() -> float
2969 func leave_to_found_colony() -> void
2982 func days_remaining() -> float
2994 func _update_label() -> void
3014 func _update_alarm_ring() -> void
3025 func _update_heading_marker() -> void
3039 func _update_search_ring() -> void
3062 func _update_dance_ring() -> void
3095 func _update_wander_flight(delta: float) -> void
3126 func _update_dance_circle(delta: float) -> void
3140 func _terrain_speed_factor() -> float
3149 func _is_inside_hive() -> bool
3157 func _on_tree_entered() -> void
3161 # --- getting round things in the meadow ---------------------------
3181 func clear_navigation_state() -> void
```

## scenario_actions.gd (1,762 lines)

The headless verbs, `when` clauses and layout assertions.

```
25   # --- preloads -----------------------------------------------------
60   # --- run_pending --------------------------------------------------
66   static func run_pending(main: Node2D, actions: Array) -> void
95   # --- the comb build-site sampler ----------------------------------
105  static func sample_comb_build_sites(main: Node2D) -> void
144  # --- log_unresolved -----------------------------------------------
151  static func log_unresolved(actions: Array) -> void
158  # --- the settle, wait and window helpers --------------------------
170  static func _do_settle(action: Dictionary) -> bool
183  static func _do_wait(action: Dictionary) -> bool
198  static func _assert_window_closed(main: Node2D, action: Dictionary) -> bool
211  static func _sample_queen_watch(main: Node2D) -> void
218  # --- _execute -----------------------------------------------------
220  static func _execute(main: Node2D, action: Dictionary) -> void
286  # --- triggers -----------------------------------------------------
296  static func _when_met(main: Node2D, when: Dictionary) -> bool
374  static func _legacy_when_spec(main: Node2D, when: Dictionary) -> Dictionary
428  # --- selectors ------------------------------------------------------
432  static func _resolve_bees(main: Node2D, target: Dictionary) -> Array
464  static func _resolve_cell_ref(main: Node2D, ref: Dictionary) -> Node2D
471  static func _resolve_cell(main: Node2D, hex: Array) -> Node2D
481  static func _resolve_soil_block(main: Node2D, hex: Array) -> Node2D
491  # --- verbs ------------------------------------------------------------
508  static func _do_assign_role(main: Node2D, action: Dictionary) -> void
575  static func _do_designate_cell(main: Node2D, action: Dictionary) -> void
599  static func _do_queue_build(main: Node2D, action: Dictionary) -> void
625  static func _do_queue_mine(main: Node2D, action: Dictionary) -> void
650  static func _do_request_placement_tool(main: Node2D, action: Dictionary) -> void
663  static func _do_click_world(main: Node2D, action: Dictionary) -> void
699  static func _do_set_config(_main: Node2D, action: Dictionary) -> void
717  static func _do_hatch_role(main: Node2D, action: Dictionary) -> void
746  static func _do_mark_drone_cell(main: Node2D, action: Dictionary) -> void
767  static func _do_set_restock_order(main: Node2D, action: Dictionary) -> void
813  static func _do_select_bees(main: Node2D, action: Dictionary) -> void
844  static func _do_select_soil(main: Node2D, action: Dictionary) -> void
870  static func _do_select_cell(main: Node2D, action: Dictionary) -> void
889  static func _force_layout(node: Node) -> void
902  static func _do_open_window(main: Node2D, action: Dictionary) -> void
959  static func _do_close_window(main: Node2D, action: Dictionary) -> void
978  static func _do_viewport_size(main: Node2D, action: Dictionary) -> void
991  static func _do_show_gallerin_prompt(main: Node2D, action: Dictionary) -> void
1007 static func _do_retreat_challenge_stage(main: Node2D, action: Dictionary) -> void
1026 static func _do_advance_challenge_stage(main: Node2D, action: Dictionary) -> void
1052 static func _do_set_queen_load(main: Node2D, action: Dictionary) -> void
1083 static func _do_set_bee_load(main: Node2D, action: Dictionary) -> void
1100 static func _do_set_cell_contents(main: Node2D, action: Dictionary) -> void
1124 static func _do_empty_cell(main: Node2D, action: Dictionary) -> void
1137 static func _do_close_cell(main: Node2D, action: Dictionary) -> void
1147 static func _do_clear_fermented(main: Node2D) -> void
1154 static func _do_watch_queen_states(main: Node2D, action: Dictionary) -> void
1169 static func _do_save_run(main: Node2D, action: Dictionary) -> void
1176 static func _do_buy_skill(main: Node2D, action: Dictionary) -> void
1198 static func _do_grant_skill(action: Dictionary) -> void
1214 static func _do_restore_slot(main: Node2D, action: Dictionary) -> void
1233 # --- assertion checks -------------------------------------------------
1243 static func _do_assert(main: Node2D, action: Dictionary) -> bool
1253 static func _evaluate_assert_condition(main: Node2D, condition: Dictionary) -> Dictionary
1298 static func _check_save_slot(main: Node2D, condition: Dictionary) -> Dictionary
1326 static func _check_all_actions_available(main: Node2D) -> Dictionary
1338 static func _queen_summary(main: Node2D, condition: Dictionary) -> String
1366 static func _check_panel_rect(main: Node2D, condition: Dictionary) -> Dictionary
1461 static func _resolve_named_panel(main: Node2D, name: String) -> Control
1475 static func _game_panel(main: Node2D, key: String) -> GamePanel
1496 static func _check_control_rect(main: Node2D, condition: Dictionary) -> Dictionary
1574 static func _check_panel_texture_contrast(_condition: Dictionary) -> Dictionary
1601 static func _check_menu_items(main: Node2D, condition: Dictionary) -> Dictionary
1620 static func _label_leading(control: Control) -> Dictionary
1634 static func _check_even_columns(main: Node2D, condition: Dictionary) -> Dictionary
1674 static func _check_no_collapsed_controls(main: Node2D, condition: Dictionary) -> Dictionary
1691 static func _check_no_empty_labels(main: Node2D, condition: Dictionary) -> Dictionary
1702 static func _collect_empty_labels(node: Node, out: Array) -> void
1708 static func _collect_collapsed_controls(node: Node, out: Array) -> void
1728 static func _resolve_scoped_path(main: Node2D, path: String) -> Node
1761 static func _log(do: String, target_desc: String, result: String, reason: String) -> void
```

## settings_catalogue.gd (1,675 lines)

Every setting's key, label, range and tip, plus the read/write and Prerequisites-cascade functions the window is a view of.

```
22   # --- preloads and collection order --------------------------------
48   # --- the tunables table -------------------------------------------
1550 # --- settings owned by Session ------------------------------------
1564 # --- reading and writing a setting --------------------------------
1565 static func setting_get(key: String) -> Variant
1568 static func setting_set(key: String, value: Variant) -> void
1575 # --- resetting ----------------------------------------------------
1592 static func reset_config_to_defaults() -> void
1604 static func reset_config_keys(keys: Array) -> void
1610 # --- applying a setting with its cascades -------------------------
1619 static func apply_setting(key: String, value: Variant) -> void
1630 # --- the cascade helpers ------------------------------------------
1635 static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1653 static func _cascade_dependents_off_static(key: String) -> Array[String]
1667 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
```

## hive_cell.gd (1,552 lines)

One cell: contents, brood, honey ripening, how it draws.

```
25   # --- constants and colours ----------------------------------------
65   static func content_tone_strength(fraction: float) -> float
74   static func content_tone(base: Color, strength: float) -> Color
81   static func fill_frame(levels: Array, fraction: float) -> int
161  # --- cell state ---------------------------------------------------
219  # --- building state -----------------------------------------------
243  func effective_build_time() -> float
246  # --- designation and orders ---------------------------------------
291  # --- hatch settings -----------------------------------------------
327  # --- layout and display nodes -------------------------------------
375  # --- slots --------------------------------------------------------
389  # --- setup --------------------------------------------------------
391  func _ready() -> void
516  # --- overlay, selection and rings ---------------------------------
523  func set_overlay(mode: String) -> void
530  func _overlay_colour() -> Array
574  func set_selected(value: bool) -> void
586  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
597  func _set_outline_points(line: Line2D, size: float) -> void
608  func _silhouette_point_to_local(p: Vector2) -> Vector2
618  func _set_outline_points_cup(line: Line2D, size: float) -> void
641  func _apply_outline_points(line: Line2D, size: float) -> void
649  func _set_selection_ring_points() -> void
652  # --- per-frame update ---------------------------------------------
670  func _process(delta: float) -> void
691  # --- brood development --------------------------------------------
696  func _develop_brood(delta: float) -> void
717  func _health_factor() -> float
725  func _larva_dies() -> void
739  # --- index and display epochs -------------------------------------
745  func _invalidate_hive_index() -> void
755  func _invalidate_stock() -> void
769  func bump_display_epoch() -> void
772  # --- working positions --------------------------------------------
777  func claim_slot(bee: Node2D) -> int
788  func release_slot(bee: Node2D) -> void
795  func has_free_slot() -> bool
804  func slot_position(index: int) -> Vector2
816  # --- building -----------------------------------------------------
818  func start_as_site() -> void
823  func claim_builder(bee: Node2D) -> void
827  func release_builder(bee: Node2D) -> void
833  func add_build_progress(delta: float) -> void
844  func build_fraction() -> float
847  # --- contents -----------------------------------------------------
849  func is_empty() -> bool
854  func capacity_for(resource_type: String) -> float
862  func accepts(resource_type: String) -> bool
881  func is_nursery_cell() -> bool
884  func space_for(resource_type: String) -> float
906  func needs_eviction() -> bool
924  func add_resource(resource_type: String, requested: float) -> float
970  func nectar_age() -> float
982  func is_fermented() -> bool
991  func is_pre_fermented() -> bool
1002 func restore_bee_bread_seal() -> void
1015 func return_ripe_bee_bread(requested: float) -> float
1044 func is_bee_bread_sealed() -> bool
1050 func is_ripe_bee_bread() -> bool
1054 func bee_bread_ripen_fraction() -> float
1062 func take_resource(resource_type: String, requested: float) -> float
1098 func can_withdraw() -> bool
1103 func set_closed(value: bool) -> void
1110 func set_fill_then_close(value: bool) -> void
1119 func fill_fraction() -> float
1127 func set_designation(resource_type: String, explicit: bool = true) -> void
1135 # --- honey ---------------------------------------------------------
1137 func is_ripe_honey() -> bool
1141 func needs_fanning() -> bool
1146 func add_fanning_progress(delta: float) -> void
1156 func ripen_fraction() -> float
1159 # --- brood ---------------------------------------------------------
1161 func start_brood(as_gyne: bool = false, as_drone: bool = false) -> void
1175 func brood_kind_label() -> String
1185 func develop_time() -> float
1194 func feed_brood(seconds: float, on_honey: bool, on_bee_bread: bool = false) -> void
1201 func needs_feeding() -> bool
1205 func seconds_until_death() -> float
1210 # --- clearing a dead larva ------------------------------------------
1212 func needs_cleaning() -> bool
1218 func add_clean_progress(delta: float) -> bool
1224 func clean_fraction() -> float
1227 func brood_ready() -> bool
1230 func clear_cell() -> void
1246 # --- display ------------------------------------------------------
1251 func _resource_outline_colour(resource_type: String) -> Color
1267 func _refresh() -> void
1480 func _show_fill_art(sheet: String, frame: int) -> void
1493 func _show_cap(stage: int) -> void
1501 func _designation_tag() -> String
1525 func _priority_mark() -> String
1538 func _apply_fill_shading() -> void
1549 func development_percent() -> float
```

## bee_foraging.gd (1,539 lines)

The forager's search, scouting, recruitment and species-preference
behaviour.

```
8    # --- preloads and constants ---------------------------------------
27   # --- the autonomous-state choke point -----------------------------
43   static func autonomous_state(bee: Node2D, next: int) -> int
47   # --- capacity, rates and hive-side points -------------------------
48   static func max_capacity(bee: Node2D) -> float
52   static func collection_rate(bee: Node2D) -> float
60   static func _random_point_near_hive(bee: Node2D) -> Vector2
72   static func _jittered_point(base: Vector2, radius: float) -> Vector2
78   # --- orientation flights ------------------------------------------
84   static func take_orientation_flight(bee: Node2D) -> void
95   # --- seeking a flower ---------------------------------------------
102  static func seek_flower(bee: Node2D) -> void
139  static func start_seek_flower(bee: Node2D) -> bool
154  static func _walk_out_if_indoors(bee: Node2D) -> bool
163  static func _start_searching(bee: Node2D) -> void
182  # --- searching the meadow -----------------------------------------
191  static func search_for_flower(bee: Node2D, delta: float) -> void
243  static func advance_search_waypoint(bee: Node2D) -> void
259  static func _perceive_flower(bee: Node2D) -> Node2D
270  static func perception_radius(bee: Node2D) -> float
276  static func _commit_to_flower(bee: Node2D, flower: Node2D) -> void
284  # --- patch memory and the search spiral ---------------------------
290  static func _remember_patch(bee: Node2D, position: Vector2) -> void
303  static func _pick_known_patch(bee: Node2D) -> Vector2
327  static func _spiral_point(bee: Node2D, anchor: Vector2, angle: float) -> Vector2
339  # --- choosing a flower --------------------------------------------
357  static func nearest_flower(bee: Node2D, strict: bool, radius: float, allow_full_scan: bool = true) -> Node2D
454  static func _weighted_flower_choice(bee: Node2D, nodes: Array, accept: Callable, radius: float) -> Node2D
492  static func flower_grid(bee: Node2D) -> Variant
507  # --- inspecting, drinking and sheltering --------------------------
508  static func start_inspecting(bee: Node2D) -> void
513  static func inspect(bee: Node2D, delta: float) -> void
536  static func needs_a_drink(bee: Node2D) -> bool
544  static func drink_at_flower(bee: Node2D, delta: float) -> void
569  static func nectar_strength(_bee: Node2D) -> float
577  static func shelter(bee: Node2D, _delta: float) -> void
593  static func recall_for_rain(bee: Node2D) -> void
603  # --- skill-or-setting behaviour switches ---------------------------
608  static func adaptive_constancy_on() -> bool
612  static func tarsal_markers_on() -> bool
617  static func probabilistic_choice_on() -> bool
620  static func handling_experience_on() -> bool
627  static func record_species_visit(bee: Node2D, species: String) -> void
642  static func scouting_on() -> bool
647  static func orientation_flight_on() -> bool
653  # --- accepting or rejecting a flower ------------------------------
654  static func worth_feeding(bee: Node2D, f: Node2D) -> bool
667  static func reject_flower(bee: Node2D) -> void
685  # --- collecting ---------------------------------------------------
686  static func start_collecting(bee: Node2D) -> void
759  static func _handling_experience_scale(bee: Node2D, species: String) -> float
768  static func collect(bee: Node2D, delta: float) -> void
817  static func finish_collecting(bee: Node2D) -> void
860  # --- entering the hive and depositing -----------------------------
864  static func enter_hive(bee: Node2D) -> void
891  static func approach_cell(bee: Node2D, cell: Node2D, delta: float) -> int
906  static func release_cell_slot(bee: Node2D) -> void
913  static func go_to_deposit_cell(bee: Node2D, delta: float) -> void
1003 static func finish_depositing(bee: Node2D) -> void
1043 static func _after_delivery_state(bee: Node2D) -> int
1054 static func _resume_own_job_if_indoors(bee: Node2D) -> bool
1062 # --- scoring a trip -----------------------------------------------
1067 static func _score_trip(bee: Node2D) -> void
1145 # --- leaving the hive ---------------------------------------------
1146 static func go_to_exit(bee: Node2D, delta: float) -> void
1200 static func _entrance_wait_spot(bee: Node2D, side: int) -> Vector2
1212 static func _leave_hive_and_resume(bee: Node2D) -> void
1239 static func _send_to_scout_point(bee: Node2D) -> void
1250 # --- scouting -----------------------------------------------------
1256 static func start_scouting(bee: Node2D) -> void
1274 # --- waiting at the entrance --------------------------------------
1279 static func wait_at_entrance(bee: Node2D, delta: float) -> void
1373 # --- the recruitment dance ----------------------------------------
1381 static func _update_dance_eligibility(bee: Node2D) -> void
1404 static func leave_recruitment(bee: Node2D) -> void
1426 static func check_dance_proximity(bee: Node2D, _delta: float) -> void
1451 static func _start_dance(mentor: Node2D, seeker: Node2D) -> void
1471 static func dance(bee: Node2D, delta: float) -> void
1483 static func _end_dance(bee: Node2D) -> void
1505 static func _complete_dance(mentor: Node2D, seeker: Node2D) -> void
1532 # --- remote deposit -----------------------------------------------
1534 static func deposit_everything_remotely(bee: Node2D) -> void
```

## main.gd (1,500 lines)

Per-frame entry point and run wiring; headless scenario boot lives in headless/scenario_boot.gd.

```
37   # --- signals ------------------------------------------------------
51   # --- preloads and boot constants ----------------------------------
102  # --- delegate systems ---------------------------------------------
146  # --- world and meadow constants -----------------------------------
207  # --- state --------------------------------------------------------
415  # --- _ready and construction --------------------------------------
425  static func run_definition(level_id: int, developer_edits_allowed: bool, overrides_path: String = DeveloperOverrides.PATH) -> Dictionary
444  func _ready() -> void
743  # --- public surface other scripts call directly -------------------
750  func is_on_screen(node: Node2D) -> bool
753  func hive_entrance_inside() -> Vector2
756  func entrance_wait_point(side: int) -> Vector2
759  func move_bee_into_hive(bee: Node2D) -> void
762  func move_bee_out_of_hive(bee: Node2D) -> void
765  func mark_death(bee: Node2D) -> void
773  func _on_bee_died(bee: Node2D) -> void
777  func finish_mining(block: Node2D) -> void
780  func save_run() -> void
783  func begin_winter_countdown() -> void
786  # --- per-frame ----------------------------------------------------
796  func _process(delta: float) -> void
888  # --- the frame rate readout ----------------------------------------
907  func _sample_fps() -> void
930  func _reseed_meadow(delta: float) -> void
950  func _hatch_ready_brood() -> void
986  func _sample_day_stores() -> void
1005 func _advance_weather(delta: float) -> void
1038 func _apply_rain_overlay() -> void
1049 # --- the first crisis ----------------------------------------------
1055 static func _blank_first_crisis() -> Dictionary
1066 static func first_crisis_bounds() -> Dictionary
1072 static func first_crisis_cutoff() -> float
1076 func _first_crisis_applies() -> bool
1083 func _first_crisis_holds_weather() -> bool
1095 func _first_crisis_readiness() -> Dictionary
1099 func _advance_first_crisis(delta: float) -> void
1140 func _warn_first_crisis(starts_at: float, path: String, readiness: Dictionary) -> void
1172 func _first_crisis_warning_text(readiness: Dictionary, lead: float) -> String
1186 func _start_first_crisis() -> void
1203 func _show_first_crisis_note() -> void
1230 static func _minutes_text(seconds: float) -> String
1237 func _trace_first_crisis(phase: String, readiness: Dictionary = {}, extra: Dictionary = {}) -> void
1276 func restore_first_crisis(saved: Variant) -> void
1313 func _check_for_loss() -> void
1341 func _promote_gyne_to_queen() -> bool
1362 func _check_colony_energy(delta: float) -> void
1393 func invalidate_population() -> void
1404 func _role_counts(bees: Variant = null) -> Dictionary
1421 func _update_population_readout(bees: Variant = null) -> void
1435 func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
1441 func _prune_selection() -> void
1454 func _on_restart_after_loss() -> void
1460 func _on_level_chosen(level: int) -> void
1474 func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
1488 func _apply_scenario_boot_arg() -> void
1493 func _end_scenario_run(outcome: String) -> void
```

## challenge_runner.gd (1,263 lines)

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
254  func _reset_run_state() -> void
287  func _reset_queen_controls() -> void
295  func _build_stage_marker() -> void
303  func _process(delta: float) -> void
342  # --- goal polling -------------------------------------------------
350  func _should_check_goal(goal_id: String, goal_tick_due: bool) -> bool
367  # --- Challenge 2 failure and rescue -------------------------------
373  func _check_c2_failure() -> void
386  func _try_c2_pollen_rescue(pollen: float) -> bool
398  func _c2_nectar_rescue(nectar: float) -> bool
414  func _c2_restore_checkpoint() -> void
443  func _c2_index(stage_id: String) -> int
449  # --- entering a stage ---------------------------------------------
454  func _stage_unlock_keys(entries: Array) -> Array
475  func _queen_allowed_role_ids(entries: Array) -> Array
483  func _enter_stage() -> void
529  func _apply_c1_stage_rules(stage: Dictionary) -> void
549  func _record_c2_stage_entry() -> void
557  # --- counting cells -----------------------------------------------
558  func _built_cell_count() -> int
565  # --- ordered visits -----------------------------------------------
569  func _hive_inspection_points() -> Array
583  func _meadow_inspection_points() -> Array
595  func _begin_ordered_visit(points: Array, marker_parent: Node2D) -> void
601  func _clear_ordered_visit() -> void
606  func _ordered_visit_complete(traveller: Node2D) -> bool
619  func _show_current_visit_point() -> void
630  # --- the stage marker ---------------------------------------------
635  func _update_marker(stage_id: String) -> void
673  func _set_marker_visible(value: bool) -> void
697  func _publish_marker_to_hud() -> void
704  # --- advancing, leaving and completing a stage --------------------
709  func _show_goal(stage: Dictionary) -> void
716  func _advance() -> void
731  func _leave_stage() -> Dictionary
741  func _run_stage_effects(effects: Array) -> void
779  func debug_advance_stage() -> void
796  func debug_retreat_stage() -> void
806  func _complete() -> void
864  # --- the queen's build site ---------------------------------------
865  func on_queen_build_site_chosen(hex: Vector2i) -> void
873  # --- gating the UI ------------------------------------------------
882  func _apply_stage_gate_to_ui() -> void
915  func _on_gate_unlocked(_key: String) -> void
921  func is_bee_command_locked(bee: Node2D) -> bool
924  # --- the opening tunnel -------------------------------------------
930  func _setup_opening_tunnel() -> void
970  func _drive_opening_mine() -> void
982  func _opening_tunnel_cleared() -> bool
990  # --- Challenge 1 forage effects and overflow ----------------------
998  func _drive_c1_forage_effects() -> void
1026 func discards_overflow(bee: Node2D) -> bool
1041 func announce_overflow_discard(focus_switch: bool = false) -> void
1063 func _drive_c1_pollen_cell_nectar_prompt(delta: float) -> void
1077 # --- the new worker's greeting ------------------------------------
1083 func on_worker_hatched(bee: Node2D) -> void
1105 func _drive_greeting(delta: float) -> void
1119 # --- goal checks --------------------------------------------------
1142 func _goal_met(goal: String) -> bool
1154 func _goal_check_entrance_tunnel_cleared() -> bool
1157 func _goal_check_queen_reached_cavity() -> bool
1162 func _goal_check_queen_selected() -> bool
1165 func _goal_check_hive_points_visited() -> bool
1168 func _goal_check_nectar_target() -> bool
1174 func _goal_check_pollen_target() -> bool
1180 func _goal_check_queen_reached_meadow() -> bool
1183 func _goal_check_meadow_points_visited() -> bool
1186 func _goal_check_first_flower_collected() -> bool
1189 func _goal_check_second_flower_collected() -> bool
1192 func _goal_check_harvest_deposited() -> bool
1195 func _goal_check_new_bee_selected() -> bool
1201 func _goal_check_new_bee_left_hive() -> bool
1204 func _goal_check_complete() -> bool
1207 # --- Challenge 2 ---------------------------------------------
1208 func _goal_check_nectar_stabilized() -> bool
1215 func _goal_check_persistent_designation_used() -> bool
1223 func _goal_check_comb_worker_building() -> bool
1227 func _goal_check_miner_expansion() -> bool
1234 # --- goal progress readouts ---------------------------------------
1240 func _goal_progress(goal: String) -> Dictionary
1253 func _custom_goal_progress(method: String) -> Dictionary
```

## hive.gd (1,254 lines)

The comb as a whole: cells, navigation, finding a cell.

```
57   func add_entrance_mentor(bee: Node2D) -> void
61   func remove_entrance_mentor(bee: Node2D) -> void
78   func add_dance_eligible_mentor(bee: Node2D) -> void
82   func remove_dance_eligible_mentor(bee: Node2D) -> void
85   func add_dance_eligible_seeker(bee: Node2D) -> void
89   func remove_dance_eligible_seeker(bee: Node2D) -> void
92   func record_collection(resource_type: String, amount: float) -> void
100  func record_birth() -> void
103  # --- cell index ---------------------------------------------------
122  func _content_index() -> Dictionary
159  func invalidate_index() -> void
162  func cells_holding(content: String) -> Array
179  func invalidate_stock() -> void
182  func _stock() -> Dictionary
212  func register_tile(hex: Vector2i, node: Node2D) -> void
218  func invalidate_mining_work() -> void
222  func _advance_mining_work_epoch() -> void
225  func tile_is_free(hex: Vector2i) -> bool
230  func tile_is_interior(hex: Vector2i) -> bool
235  func cell_at_tile(hex: Vector2i) -> Node2D
241  func _ready() -> void
260  func deposit(resource_type: String, amount: float) -> float
283  func pay_reward(resource_type: String, amount: float) -> float
306  func take(resource_type: String, amount: float) -> float
323  func take_energy(energy_wanted: float) -> float
336  func total(resource_type: String) -> float
342  func total_sealed() -> float
346  func total_honey() -> float
349  # --- finding cells ------------------------------------------------
362  func find_cell_for(resource_type: String, except: Node2D = null) -> Node2D
386  func find_designated_cell_for(resource_type: String, except: Node2D = null) -> Node2D
424  func find_empty_cell() -> Node2D
470  func _lay_by_priority(pool: Array) -> Node2D
501  func _tier_weights() -> Array
516  func record_lay(cell: Node2D) -> void
530  func zone_summary() -> Dictionary
562  func brood_stage_counts() -> Dictionary
580  func find_food_cell(except: Node2D = null) -> Node2D
610  func senses_fermentation() -> bool
616  func avoids_as_sour(cell: Node2D) -> bool
619  func has_room_for_egg() -> bool
622  func find_cell_with(resource_type: String) -> Node2D
638  func find_honey_source(from: Vector2) -> Node2D
659  func find_brood_nectar() -> Node2D
671  func find_brood_cell() -> Node2D
686  func find_cell_needing_fanning() -> Node2D
694  func find_honey_target() -> Node2D
703  func find_bee_bread_target(except: Node2D = null) -> Node2D
712  func can_take(resource_type: String, amount: float) -> bool
722  func find_unfinished_cell() -> Node2D
731  func find_cell_needing_cleaning() -> Node2D
735  func find_cell_needing_eviction() -> Node2D
743  func has_gyne_brood() -> bool
751  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
754  # --- bodies -------------------------------------------------------
765  func add_body(point: Vector2, died_at: float) -> Node2D
779  func remove_body(body: Node2D) -> void
786  func find_body_to_clear() -> Node2D
795  func clear_bodies() -> void
800  func _free_body(body: Node2D) -> void
808  # --- growing the comb ---------------------------------------------
847  func has_room_to_build(around: Vector2i = Vector2i.ZERO) -> bool
855  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
872  func _first_free_spiral_hex(around: Vector2i) -> Variant
892  func set_keep_clear(hex: Vector2i, value: bool) -> void
898  func is_keep_clear(hex: Vector2i) -> bool
905  func can_build_on(hex: Vector2i) -> bool
908  func _can_build_on(hex: Vector2i) -> bool
911  func _start_site_at(hex: Vector2i) -> Node2D
933  func create_cell_site_at(hex: Vector2i) -> Node2D
938  # --- navigation ---------------------------------------------------
949  func build_navigation() -> void
990  func _is_solid(hex: Vector2i) -> bool
996  func _tile_cost(hex: Vector2i) -> float
999  func tile_is_walkable(hex: Vector2i) -> bool
1008 func nearest_walkable_point(point: Vector2) -> Vector2
1035 func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
1069 func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
1093 func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
1107 # --- mining -------------------------------------------------------
1116 func refresh_edge_flags() -> void
1138 func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
1166 func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
1190 func _is_markable_block(node: Variant) -> bool
1197 func mine_stand_hex(block: Node2D) -> Variant
1220 func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
1242 func remove_block(block: Node2D, floor_maker: Callable) -> void
1253 func announce() -> void
```

## debug_panel.gd (1,205 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
20   # --- preloads -----------------------------------------------------
45   # --- fields -------------------------------------------------------
93   # --- _ready and construction --------------------------------------
96   func _style_button(button: BaseButton) -> BaseButton
101  func _ready() -> void
220  func _apply_panel_width() -> void
225  func _report_settings_button_width() -> void
230  # --- collections and sections -------------------------------------
231  func _rows_in(category: String) -> Array
253  func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
284  func _set_open(header: Button, body: Control, label: String, open: bool) -> void
292  func open_to_categories(categories: Array) -> void
312  func collapse_all() -> void
320  func _make_section(category: String, entries: Array, start_open: bool) -> Control
381  # --- the Challenge stage navigator --------------------------------
386  func _make_challenge_stage_navigation() -> Control
443  func _process(_delta: float) -> void
449  func _refresh_pollination_readout() -> void
462  func _pollination_text(points: int, contribution: int) -> String
465  func _refresh_challenge_stage_navigation() -> void
485  # --- the controls help --------------------------------------------
491  func _make_controls_help() -> Control
538  # --- the action buttons -------------------------------------------
550  func _build_actions(column: VBoxContainer) -> void
597  func _rebuild_triggers() -> void
632  func _on_end_run_pressed() -> void
643  func _refresh_developer_row() -> void
670  func _make_run_availability_button() -> Button
679  func _on_run_availability_pressed() -> void
692  func _add_action_row(parent: Control, button: Button, tip: String) -> void
698  func _make_winter_action() -> Control
710  func _on_winter_pressed() -> void
716  func _on_challenge_advance_pressed() -> void
723  func _on_challenge_retreat_pressed() -> void
737  func _on_fire_test_warnings_pressed() -> void
770  func _on_force_c2_collapse_pressed() -> void
784  # --- save and load ------------------------------------------------
790  func set_save_load_enabled(enabled: bool) -> void
798  func set_toggle(key: String, value: bool) -> void
803  func _on_save_pressed() -> void
814  func _on_load_pressed() -> void
852  # --- showing and hiding the panel ---------------------------------
853  func _toggle_panel() -> void
867  func _apply_layer_for_context() -> void
872  # --- building a settings row --------------------------------------
873  func _make_row(entry: Dictionary) -> Control
916  func _make_control_slot() -> HBoxContainer
925  func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
955  func _make_toggle_row(entry: Dictionary) -> Control
1028 func _make_options_row(entry: Dictionary) -> Control
1061 func _option_display(entry: Dictionary, value) -> String
1065 func _cycle_option(entry: Dictionary, direction: int) -> void
1076 # --- prerequisite cascades ----------------------------------------
1080 func _cascade_prerequisites_on(key: String) -> void
1094 func _cascade_dependents_off(key: String) -> void
1102 func _cascade_mutual_exclusion(key: String) -> void
1107 # --- star rows and value editing ----------------------------------
1112 func _make_star_row(entry: Dictionary) -> Control
1153 func _adjust(entry: Dictionary, delta: float) -> void
1170 func _format_value(v) -> String
1177 # --- restart and main menu ----------------------------------------
1178 func _on_restart_pressed() -> void
1183 func _on_main_menu_pressed() -> void
1191 func _restart() -> void
```

## diagnostic_log.gd (1,173 lines)

The session JSONL writer, counters and capture profiles.

```
18   # --- preloads and constants ---------------------------------------
27   # --- session state ------------------------------------------------
77   # --- the running counters -----------------------------------------
134  # --- _ready and the session lifecycle -----------------------------
135  func _ready() -> void
143  func _notification(what: int) -> void
148  func start_session() -> void
155  func _open_session_file() -> void
169  func _reset_counters() -> void
217  func _write_config_line() -> void
227  # --- death and predation ------------------------------------------
228  func log_death(bee: Node2D) -> void
261  func log_crab_spider_event(bee: Node2D, flower: Node2D, outcome: String) -> void
276  # --- recruitment and scouting -------------------------------------
286  func log_recruitment_match(seeker: Node2D, mentor: Node2D, via: String = "queue") -> void
319  func log_recruitment_followup(bee: Node2D, trip_index: int, trip_rate: float) -> void
341  func count_recruit_partner_overlap() -> void
351  func log_forager_settled(bee: Node2D) -> void
369  func log_orientation_flight(bee: Node2D) -> void
382  # --- flowers and foraging counters --------------------------------
386  func count_flower_visit(flower: Node2D) -> void
395  func record_handling_visit(species: String, prior_experience: int, seconds: float) -> void
409  func count_forager_delivery(amount: float) -> void
416  func count_flower_senescence() -> void
423  func count_flower_senescence_loss(nectar: float, pollen: float) -> void
428  func _experience_bucket(prior_experience: int) -> String
440  # --- tarsal marks -------------------------------------------------
441  func count_tarsal_mark() -> void
450  func count_tarsal_rejection() -> void
454  # --- movement and stalls ------------------------------------------
462  func log_stall_recovery(bee: Node2D, goal: Vector2) -> void
491  func log_build_target(bee: Node2D, cell: Node2D, transition: String, reason: String,
516  func log_forager_return(bee: Node2D, phase: String, required_energy: float) -> void
526  func log_flight_start_resolved(bee: Node2D, source: String, requested: Vector2, resolved: Dictionary) -> void
538  func _nearby_obstacle_identity(bee: Node2D) -> String
561  func log_scouting_settled(bee: Node2D) -> void
576  # --- brood, comb and honey counters -------------------------------
579  func count_brood_feed() -> void
586  func count_brood_hatch(role: int, mode: String) -> void
593  func count_jelly_batch() -> void
598  func count_larval_death() -> void
604  func count_cell_completed() -> void
610  func count_cell_cleaned() -> void
617  func count_cell_evicted() -> void
623  func count_cell_restocked() -> void
629  func count_block_mined() -> void
635  func count_honey_batch_deposited() -> void
641  func count_cell_ripened() -> void
645  # --- player actions and commands ----------------------------------
650  func log_action(do: String, target_desc: String, result: String, reason: String) -> void
666  func log_command_issue(selected_count: int, commandable_count: int, branch: String,
695  func log_selection_panels_hidden(source: String, shown_count: int, selected_count: int) -> void
707  # --- reading events back ------------------------------------------
715  func event_count(type: String, subtype: String = "") -> int
761  # --- the per-frame tick and session end ---------------------------
766  func tick(delta: float, world: Node2D) -> void
802  func _sample_nectar_age_on_day_change(world: Node2D) -> void
835  func _nectar_age_summary() -> Dictionary
845  func end_session(outcome: String) -> void
903  # --- configuration ------------------------------------------------
904  func session_path() -> String
908  func set_queen_alive(alive: bool) -> void
912  func configure_scenario_diagnostics(raw: Variant) -> bool
921  func configure_performance_capture(config: Dictionary) -> void
925  func effective_diagnostics() -> Dictionary
931  func _snapshot_interval() -> float
944  func _selected_snapshot(world: Node2D) -> Dictionary
950  # --- building entries -----------------------------------------------
954  func _config_snapshot() -> Dictionary
962  # --- the snapshot -------------------------------------------------
963  func _snapshot(world: Node2D) -> Dictionary
972  func _population_section(bees: Array) -> Dictionary
987  func _resources_section(world: Node2D) -> Dictionary
994  func _cells_section(hive: Node2D) -> Dictionary
1011 func _environment_section(world: Node2D) -> Dictionary
1019 func _foraging_section(world: Node2D, bees: Array) -> Dictionary
1050 func _crab_spider_section(world: Node2D) -> Dictionary
1060 func _role_outcomes_section(world: Node2D) -> Dictionary
1089 func _performance_snapshot(world: Node2D) -> Dictionary
1106 func _rate(world: Node2D, key: String) -> float
1118 # --- writing to disk ----------------------------------------------
1122 func _current_day() -> int
1126 func _prune_old_sessions() -> void
1144 func _write(entry: Dictionary) -> void
1153 func _capture_entry(entry: Dictionary) -> bool
```

## game_config.gd (1,033 lines)

The balance fields.

```
8    # --- world ---
30   # --- flowers (per-species values are in flower_species.gd; these scale them) ---
416  # --- foraging ---
425  # --- hive ---
452  # --- the nursery zone ---
531  # --- eating ---
539  # --- flight ---
570  # --- gynes ---
585  # --- royal jelly ---
595  # --- bee bread (BB-1) ---
609  # --- bee bread nursing and a worker's outcome (BB-2) ---
628  # --- weather ---
660  # --- warnings ---
671  # --- honey ---
719  # --- comb building ---
739  # --- hive geometry ---
768  # --- bee life ---
773  # --- bee individuality ---
852  # --- the rival colony ---
905  # --- seasons ---
937  # --- disease ---
976  # --- gynes leaving ---
988  # --- nuptial flights ---
996  # --- winter ---
```

## main_menu.gd (735 lines)

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
444  func _make_hex_tile(stage: Dictionary) -> Control
537  func _apply_hex_colors(level: int, state: String) -> void
548  func _refresh_hex_state(level: int) -> void
551  func _refresh_ticks() -> void
558  func _stage_for_level(level: int) -> Dictionary
564  # --- selection and the detail pane ---------------------------------------
566  func _select_stage(stage: Dictionary) -> void
576  func _rebuild_detail_pane(stage: Dictionary) -> void
608  func _make_note_label(text: String) -> Label
619  func _make_preset_row(stage: Dictionary) -> Control
636  func _make_preset_description() -> Control
646  func _make_custom_controls() -> Control
654  func _make_custom_row(field: Dictionary) -> Control
698  # --- choosing --------------------------------------------------------
700  func _choose(stage: Dictionary) -> void
707  # --- small shared helpers ---------------------------------------------
712  func _uses_presets(stage: Dictionary) -> bool
715  func _style_button(button: Button, selected: bool = false) -> void
722  func _is_challenge_complete(level: int) -> bool
725  func _is_scenario_played(level: int) -> bool
732  func _is_completed(stage: Dictionary) -> bool
```

## world_building.gd (718 lines)

World layout, flower seeding and colony setup.

```
37   func _build_meadow() -> void
68   func _rebuild_flower_grid() -> void
73   func is_on_screen(node: Node2D) -> bool
86   func _place_rival_hive() -> void
108  func _scatter_obstacles() -> void
114  func _place_obstacles(placed: Array, count: int, kind: int, radius_range: Vector2, gap: float) -> void
144  func _spawn_starting_foragers() -> void
173  func _build_microhabitat_zones() -> void
195  func _random_point_in_zone(habitat: String) -> Vector2
209  func _seed_flower(founding: bool = false, max_units: int = 4) -> int
237  func _founding_birth_window(founding: bool) -> Array
253  func _pick_flower_anchor(species: Dictionary) -> Vector2
284  func _bush_unit_count(species: Dictionary, max_units: int) -> int
291  func _place_bush_unit(anchor: Vector2, unit: int) -> Vector2
309  func _add_flower(pos: Vector2, species_index: int, starting_age: float = -1.0) -> Node2D
318  func _plant_seed(ledger: Variant, entry: Array) -> int
330  func _in_field(point: Vector2) -> Vector2
336  func _is_clear_ground(point: Vector2) -> bool
344  func _clear_of_obstacles(point: Vector2) -> Vector2
362  func _random_zone_centre(radius: float) -> Vector2
369  func _random_field_point() -> Vector2
380  func _hive_centre_local() -> Vector2
383  func _build_hive_interior() -> void
399  func _dig_out_chamber(centre_local: Vector2, interior_rings: int, soil_depth: int, spacing: float) -> void
416  func _add_entrance_marker() -> void
424  func _build_starting_comb(centre_local: Vector2, spacing: float) -> void
440  func _stock_starting_comb(cells: Array, level: Dictionary) -> void
453  func _spawn_hive_occupants(centre_local: Vector2, interior_rings: int, spacing: float) -> void
474  func _is_open_tile(hex: Vector2i, ring: int, interior_rings: int) -> bool
482  func _add_floor_tile(hex: Vector2i, centre_local: Vector2, spacing: float) -> void
493  func _add_soil_block(hex: Vector2i, centre_local: Vector2, spacing: float) -> void
502  func _add_rock_block(hex: Vector2i, centre_local: Vector2, spacing: float) -> void
519  func _entrance_tiles(interior_rings: int, soil_depth: int) -> Dictionary
526  func hive_entrance_inside() -> Vector2
548  func entrance_wait_point(side: int) -> Vector2
555  func _build_cameras() -> void
564  func _spawn_bee(focus: String, preferred_species: String = "") -> void
574  func _spawn_hatched_bee(role: int, cell: Node2D, as_gyne: bool = false, focus_override: String = "") -> Node2D
607  func _spawn_indoor_bee(role: int) -> Node2D
623  func _stagger_starter_age(bee: Node2D) -> void
632  func move_bee_into_hive(bee: Node2D) -> void
647  func move_bee_out_of_hive(bee: Node2D) -> void
667  func mark_death(bee: Node2D) -> void
688  func _apply_scenery_setting() -> void
702  func finish_mining(block: Node2D) -> void
708  func _obstacle_at(point: Vector2) -> Node2D
714  func _flower_at(point: Vector2) -> Node2D
```

## input_selection.gd (717 lines)

Selection, drag and placement resolution.

```
15   func _unhandled_input(event: InputEvent) -> void
80   func _finish_drag(additive: bool, add_to_group_selection: bool = false) -> void
186  func _select_cells(cells: Array, additive: bool) -> void
206  func _clear_cell_selection() -> void
212  func _select_blocks(blocks: Array, additive: bool) -> void
236  func _clear_block_selection() -> void
242  func _select_world_object(kind: String, object: Node2D) -> void
250  func _clear_world_object_selection() -> void
255  func _on_soil_mark_requested(mark: bool) -> void
260  func _on_keep_clear_clear_requested() -> void
264  func _bees_in_current_view() -> Array
268  func _death_markers_in_current_view() -> Array
275  func _click_switches_view(point: Vector2) -> bool
291  func _bee_at(point: Vector2) -> Node2D
297  func _cell_at(point: Vector2) -> Node2D
303  func _soil_at(point: Vector2) -> Node2D
309  func _death_marker_at(point: Vector2) -> Node2D
315  func _hex_at(global_point: Vector2) -> Vector2i
358  func _placement_tool_def(tool_id: String) -> Dictionary
368  func request_placement_tool(tool_id: String) -> void
395  func clear_placement_tool() -> void
401  func _place_with_active_tool(ctrl_held: bool) -> void
409  func _place_build_cell(global_point: Vector2, keep_adding: bool) -> void
419  func _place_queen_build_cell(global_point: Vector2, _keep_adding: bool = false) -> void
426  func _place_mine_target(global_point: Vector2, keep_adding: bool) -> void
437  func _place_keep_clear(global_point: Vector2, _keep_adding: bool) -> void
442  func _place_home_cell(global_point: Vector2, _keep_adding: bool = false) -> void
453  func _on_cell_empty_by_bee_requested(cell: Node2D) -> void
462  func _place_home_cell_all(global_point: Vector2, _keep_adding: bool = false) -> void
470  func _place_mine_home(global_point: Vector2, _keep_adding: bool = false) -> void
478  func _place_forage_start(global_point: Vector2, _keep_adding: bool = false) -> void
484  func _place_floral_preference(global_point: Vector2, _keep_adding: bool = false) -> void
506  func _issue_command(world_point: Vector2) -> void
574  func _prune_invalid_selected_bees() -> void
583  func _show_click_marker(world_point: Vector2) -> void
589  func _on_role_selection_requested(role: int, focus: String) -> void
605  func _ensure_hive_view() -> void
610  func _draw_selection_box() -> void
627  func _draw_hive_orders() -> void
660  func _draw_build_hover() -> void
669  func _draw_home_marker(point: Vector2) -> void
675  func _build_queue_points(bee: Node2D) -> Array
681  func _mine_queue_points(bee: Node2D) -> Array
688  func _draw_order_chain(bee: Node2D, points: Array, colour: Color) -> void
698  func _draw_tile_outline(centre: Vector2, colour: Color, width: float, dashed: bool) -> void
707  func _tile_centre(hex: Vector2i) -> Vector2
712  func _draw_start_point_marker(point: Vector2) -> void
```

## skills.gd (703 lines)

The skill catalogue and tree layout: ids, names, costs, prerequisites and slots.

```
45   # --- cost currencies ----------------------------------------------
76   # --- sectors ------------------------------------------------------
92   # --- skill ids ----------------------------------------------------
143  # --- the catalogue ------------------------------------------------
633  # --- lookups ------------------------------------------------------
635  static func entry(skill_id: String) -> Dictionary
641  static func has(skill_id: String) -> bool
644  static func ids() -> Array
647  static func label_for(skill_id: String) -> String
650  static func cost_for(skill_id: String) -> Dictionary
653  static func is_baseline(skill_id: String) -> bool
665  static func is_cut(skill_id: String) -> bool
669  static func is_built(skill_id: String) -> bool
673  static func for_sector(sector_key: String) -> Array
676  static func for_sector_tier(sector_key: String, tier: int) -> Array
681  static func baseline_ids() -> Array
684  static func sector_keys() -> Array
690  static func sector_index(sector_key: String) -> int
696  static func sector_label(sector_key: String) -> String
702  static func ring_for_tier(tier: int) -> int
```
