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

## hud.gd (4,098 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
28   # --- signals ------------------------------------------------------
123  # --- role controls ------------------------------------------------
135  static func hatch_options() -> Array
184  static func mode_command(role_id: int, mode_key: String) -> String
187  # --- shared layout constants --------------------------------------
223  # --- fields -------------------------------------------------------
553  # --- problem strip ------------------------------------------------
571  func _signal_color(severity: int) -> Color
578  # --- _ready and construction --------------------------------------
595  func _ready() -> void
672  func _on_viewport_size_changed() -> void
678  func _build_stage_marker_arrow() -> void
696  func set_stage_marker(global_position: Vector2, marker_visible: bool, in_hive: bool) -> void
701  func _make_label(pos: Vector2, variation: String = "Body") -> Label
709  func _info(text: String) -> Button
712  func _with_info(control: Control, tip: String) -> HBoxContainer
717  func _style_button(button: BaseButton) -> BaseButton
722  # --- speed controls -----------------------------------------------
746  func _build_top_right_bar() -> void
893  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
929  func _apply_interface_label_visibility() -> void
935  # --- Challenge goal readout ---------------------------------------
940  func _build_goal_shelf() -> void
1028 func set_settings_button_width(width: float) -> void
1042 func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
1070 func set_colony_goals(entries: Array) -> void
1102 func _apply_goals_collapsed() -> void
1114 func _add_goal_star(label: Control) -> void
1136 func _set_goal_star(label: Control, id: String, entries: Array) -> void
1151 func _on_goal_star_pressed(star: Button) -> void
1158 func _rebuild_favourites(entries: Array) -> void
1178 func _on_goals_button_pressed() -> void
1183 func set_speed_display(speed_scale: float) -> void
1188 # --- bottom row ---------------------------------------------------
1193 func _build_selection_panel() -> void
1320 func _build_favourite_star() -> Control
1351 func _set_favourite_star(bee) -> void
1379 func _field_control(field_name: String) -> Control
1393 func _build_selection_cog() -> Control
1420 func _theme_popup_on_open(popup: PopupMenu) -> void
1440 func _set_summary_cog_kind(kind: String) -> void
1452 func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
1472 func _apply_selection_field_visibility() -> void
1501 func _resize_selection_panel_to_content() -> void
1509 # --- command tray -------------------------------------------------
1521 func _build_command_tray() -> void
1624 func _build_tray_column(title: String) -> Array
1651 # --- cell popup ---------------------------------------------------
1667 func _build_cell_group(parent: VBoxContainer) -> void
1770 func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer
1798 func _build_priority_controls(column: VBoxContainer) -> void
1835 func _build_raises_controls(column: VBoxContainer) -> void
1939 func _build_closing_controls(column: VBoxContainer) -> void
1979 func _build_empty_controls(column: VBoxContainer) -> void
2052 func _make_hatch_menu(entry: Dictionary) -> Control
2082 func _fill_hatch_menu(popup: PopupMenu, role_value: int, options: Array) -> int
2098 func _build_warning_banner() -> void
2134 func show_warning(text: String, key: String = "", min_gap: float = 0.0, severity: int = 0) -> void
2151 func _show_warning_now(text: String, severity: int) -> void
2159 func _dismiss_warning() -> void
2164 func set_warnings_muted(value: bool) -> void
2178 func show_object_summary(kind: String, data) -> void
2205 func _refresh_flower_summary() -> void
2241 func _show_obstacle_summary(obstacle: Node2D) -> void
2247 func _show_soil_summary(count: int, reachable: int) -> void
2260 func _show_keep_clear_summary() -> void
2271 func _show_death_summary(info: Dictionary) -> void
2293 func show_cell_popup(cell: Node2D, count: int = 1) -> void
2315 func _cell_content_lines(cell, count: int) -> Array
2370 func _cell_state_lines(cell) -> Array
2392 func _cell_hatch_text(cell) -> String
2407 func _refresh_cell_popup() -> void
2450 func _apply_cell_popup_gating() -> void
2478 func _light_current_options() -> void
2497 func _set_lit(key: String, lit: bool) -> void
2508 func _process(_delta: float) -> void
2540 func _stage_marker_screen_position() -> Vector2
2544 func _update_stage_marker_arrow() -> void
2577 func _refresh_marker_exclusion_rects(viewport_size: Vector2) -> void
2588 func _append_marker_panel_exclusion(panel: Control, owner_rect: Rect2) -> void
2593 func _slide_arrow_along_edge(edge_point: Vector2, edge_bounds: Rect2) -> Vector2
2610 func _marker_arrow_obscured(point: Vector2) -> bool
2616 func _request_designation(type: String) -> void
2621 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
2626 func _request_empty(method: String) -> void
2631 func _request_priority(tier: int) -> void
2636 func _request_close(closed: bool) -> void
2641 func _request_fill_close() -> void
2646 # --- discard warning ----------------------------------------------
2653 func _build_discard_dialog() -> void
2668 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
2687 func confirm_discard(title: String, text: String, ok_text: String, cancel_text: String, action: Callable, offer_stop_warning: bool = true) -> void
2697 func _on_discard_confirmed() -> void
2700 func _on_discard_custom_action(action: StringName) -> void
2707 func _apply_discard() -> void
2721 # --- readouts -----------------------------------------------------
2726 func update_day(day: int, note: String = "") -> void
2744 func set_weather_note(text: String) -> void
2756 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
2769 func _refresh_stores_text() -> void
2779 func update_population(nectar_foragers: int, pollen_foragers: int, nurses: int, builders: int, miners: int, honey_makers: int) -> void
2785 func update_comb(text: String) -> void
2789 func update_energy(mean_fraction: float) -> void
2796 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
2807 func update_recruit_gap(text: String) -> void
2820 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
2826 func update_signals(lines: Array) -> void
2834 func _red_always_shows() -> bool
2839 func strip_lines() -> Array
2853 func _remove_signal(id: String) -> void
2858 func _corner_signature(strip: Array) -> String
2867 func _rebuild_corner_labels() -> void
2884 func _add_signal_row(entry: Array) -> void
2920 func _rebuild_corner_signals(strip: Array) -> void
2934 func _refresh_corner() -> void
2985 func _corner_line_width() -> float
2989 func _apply_corner_line_width() -> void
2998 func _fit_corner_line(line: Button) -> void
3008 func corner_bottom() -> float
3014 func selection_panel_top() -> float
3024 func pinned_stats_changed() -> void
3033 func refresh_speed_visibility() -> void
3040 func refresh_corner() -> void
3043 func update_selection(bees: Array) -> void
3077 func _selection_has_command_lock(bees: Array) -> bool
3098 static func _detach_and_free_children(container: Node) -> void
3111 func _rebuild_role_controls(bees: Array) -> void
3166 func _build_queen_build_row(column: VBoxContainer) -> void
3180 func _build_follow_control(bees: Array, first) -> void
3195 func _build_job_row(common_role: int, any_queen: bool, queen_bee = null) -> void
3227 func _build_doing_row(common_role: int, first) -> void
3265 func _build_mating_row(bees: Array, first) -> void
3286 func _set_nuptial_flights(queen, on: bool) -> void
3297 func _build_gyne_send_row(bees: Array, first) -> void
3312 func _send_gyne(gyne) -> void
3318 func _gyne_not_ready_reason(gyne) -> String
3323 func _refresh_gyne_send_button(gyne) -> void
3329 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
3346 func _build_orders_row(common_role: int, first) -> void
3394 func _build_restock_row(first) -> void
3431 func _build_fallback_row(common_role: int, first) -> void
3485 func _build_backup_order(row: HFlowContainer) -> void
3519 func _on_backup_editor_changed(keys: Array, focus: String) -> void
3525 func _secondary_items() -> Array
3541 func _column_row(parent: Container) -> HFlowContainer
3549 func _labelled_row(title: String) -> HFlowContainer
3568 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
3580 func _action_button(label: String, action: Callable, tip: String) -> Control
3589 func _current_role_marker(label: String) -> Control
3604 func _common_role(bees: Array) -> int
3621 func _common_working_role(bees: Array) -> int
3639 func _make_role_menu(label: String, tip: String, items: Array, node_name: String = "") -> Control
3660 func _selection_identity_text(b) -> String
3674 func _selection_energy_text(b) -> String
3683 func _selection_activity_text(b, instruction_runner, stuck: String) -> String
3711 func _selection_trait_text(b) -> String
3725 func _refresh_selection_text() -> void
3785 func _apply_selection_tray_width() -> void
3836 func _match_summary_header_button_heights() -> void
3854 func _tray_column_share(inner_width: float) -> float
3863 func _apply_even_column_widths(wrappers: Array) -> void
3891 func _update_command_tray_width() -> void
3912 func _resize_command_tray() -> void
3947 func _resettle_command_tray(generation: int, previous_content_min_y: float, stable_streak: int, pass_count: int) -> void
3961 func _apply_command_tray_rect() -> void
3979 func _on_command_content_minimum_size_changed() -> void
3986 func set_winter_button_visible(value: bool) -> void
3992 func set_view_label(in_hive: bool) -> void
4001 func set_allowed_role_keys(keys: Array) -> void
4009 func _role_offered(role_id: int, bee = null) -> bool
4015 func refresh_role_gating() -> void
4024 func set_command_locked_bees(bees: Array) -> void
4029 func set_allowed_mode_keys(keys: Array) -> void
4039 func set_allowed_designation_keys(keys: Array) -> void
4049 func set_queen_build_button_visible(value: bool) -> void
4054 # --- stage gates --------------------------------------------------
4062 func apply_gates(stage_gate) -> void
4080 func _register_gated_control(control_name: String, getter: Callable) -> void
4088 func _apply_gate_to_control(control_name: String) -> void
4097 func _is_gate_open(control_name: String) -> bool
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

## scenario_actions.gd (1,876 lines)

The headless verbs, `when` clauses and layout assertions.

```
34   # --- preloads -----------------------------------------------------
69   # --- run_pending --------------------------------------------------
75   static func run_pending(main: Node2D, actions: Array) -> void
118  static func _rearm_if_repeating(main: Node2D, action: Dictionary) -> void
128  static func is_outstanding(action: Dictionary) -> bool
132  # --- the comb build-site sampler ----------------------------------
142  static func sample_comb_build_sites(main: Node2D) -> void
181  # --- log_unresolved -----------------------------------------------
188  static func log_unresolved(actions: Array) -> void
202  # --- the settle, wait and window helpers --------------------------
214  static func _do_settle(action: Dictionary) -> bool
227  static func _do_wait(action: Dictionary) -> bool
242  static func _assert_window_closed(main: Node2D, action: Dictionary) -> bool
255  static func _sample_queen_watch(main: Node2D) -> void
262  # --- _execute -----------------------------------------------------
264  static func _execute(main: Node2D, action: Dictionary) -> void
332  # --- triggers -----------------------------------------------------
342  static func _when_met(main: Node2D, when: Dictionary) -> bool
420  static func _legacy_when_spec(main: Node2D, when: Dictionary) -> Dictionary
474  # --- selectors ------------------------------------------------------
478  static func _resolve_bees(main: Node2D, target: Dictionary) -> Array
510  static func _resolve_cell_ref(main: Node2D, ref: Dictionary) -> Node2D
517  static func _resolve_cell(main: Node2D, hex: Array) -> Node2D
527  static func _resolve_soil_block(main: Node2D, hex: Array) -> Node2D
537  # --- verbs ------------------------------------------------------------
554  static func _do_assign_role(main: Node2D, action: Dictionary) -> void
611  static func _do_keep_role(main: Node2D, action: Dictionary) -> void
659  static func _parse_role_key(main: Node2D, key: String) -> Dictionary
676  static func _bee_holds(main: Node2D, bee: Node2D, parsed: Dictionary) -> bool
689  static func _do_designate_cell(main: Node2D, action: Dictionary) -> void
713  static func _do_queue_build(main: Node2D, action: Dictionary) -> void
739  static func _do_queue_mine(main: Node2D, action: Dictionary) -> void
764  static func _do_request_placement_tool(main: Node2D, action: Dictionary) -> void
777  static func _do_click_world(main: Node2D, action: Dictionary) -> void
813  static func _do_set_config(_main: Node2D, action: Dictionary) -> void
831  static func _do_hatch_role(main: Node2D, action: Dictionary) -> void
860  static func _do_mark_drone_cell(main: Node2D, action: Dictionary) -> void
881  static func _do_set_restock_order(main: Node2D, action: Dictionary) -> void
927  static func _do_select_bees(main: Node2D, action: Dictionary) -> void
958  static func _do_select_soil(main: Node2D, action: Dictionary) -> void
984  static func _do_select_cell(main: Node2D, action: Dictionary) -> void
1003 static func _force_layout(node: Node) -> void
1016 static func _do_open_window(main: Node2D, action: Dictionary) -> void
1073 static func _do_close_window(main: Node2D, action: Dictionary) -> void
1092 static func _do_viewport_size(main: Node2D, action: Dictionary) -> void
1105 static func _do_show_gallerin_prompt(main: Node2D, action: Dictionary) -> void
1121 static func _do_retreat_challenge_stage(main: Node2D, action: Dictionary) -> void
1140 static func _do_advance_challenge_stage(main: Node2D, action: Dictionary) -> void
1166 static func _do_set_queen_load(main: Node2D, action: Dictionary) -> void
1197 static func _do_set_bee_load(main: Node2D, action: Dictionary) -> void
1214 static func _do_set_cell_contents(main: Node2D, action: Dictionary) -> void
1238 static func _do_empty_cell(main: Node2D, action: Dictionary) -> void
1251 static func _do_close_cell(main: Node2D, action: Dictionary) -> void
1261 static func _do_clear_fermented(main: Node2D) -> void
1268 static func _do_watch_queen_states(main: Node2D, action: Dictionary) -> void
1283 static func _do_save_run(main: Node2D, action: Dictionary) -> void
1290 static func _do_buy_skill(main: Node2D, action: Dictionary) -> void
1312 static func _do_grant_skill(action: Dictionary) -> void
1328 static func _do_restore_slot(main: Node2D, action: Dictionary) -> void
1347 # --- assertion checks -------------------------------------------------
1357 static func _do_assert(main: Node2D, action: Dictionary) -> bool
1367 static func _evaluate_assert_condition(main: Node2D, condition: Dictionary) -> Dictionary
1412 static func _check_save_slot(main: Node2D, condition: Dictionary) -> Dictionary
1440 static func _check_all_actions_available(main: Node2D) -> Dictionary
1452 static func _queen_summary(main: Node2D, condition: Dictionary) -> String
1480 static func _check_panel_rect(main: Node2D, condition: Dictionary) -> Dictionary
1575 static func _resolve_named_panel(main: Node2D, name: String) -> Control
1589 static func _game_panel(main: Node2D, key: String) -> GamePanel
1610 static func _check_control_rect(main: Node2D, condition: Dictionary) -> Dictionary
1688 static func _check_panel_texture_contrast(_condition: Dictionary) -> Dictionary
1715 static func _check_menu_items(main: Node2D, condition: Dictionary) -> Dictionary
1734 static func _label_leading(control: Control) -> Dictionary
1748 static func _check_even_columns(main: Node2D, condition: Dictionary) -> Dictionary
1788 static func _check_no_collapsed_controls(main: Node2D, condition: Dictionary) -> Dictionary
1805 static func _check_no_empty_labels(main: Node2D, condition: Dictionary) -> Dictionary
1816 static func _collect_empty_labels(node: Node, out: Array) -> void
1822 static func _collect_collapsed_controls(node: Node, out: Array) -> void
1842 static func _resolve_scoped_path(main: Node2D, path: String) -> Node
1875 static func _log(do: String, target_desc: String, result: String, reason: String) -> void
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

## hive_cell.gd (1,553 lines)

One cell: contents, brood, honey ripening, how it draws.

```
25   # --- constants and colours ----------------------------------------
65   static func content_tone_strength(fraction: float) -> float
74   static func content_tone(base: Color, strength: float) -> Color
81   static func fill_frame(levels: Array, fraction: float) -> int
162  # --- cell state ---------------------------------------------------
220  # --- building state -----------------------------------------------
244  func effective_build_time() -> float
247  # --- designation and orders ---------------------------------------
292  # --- hatch settings -----------------------------------------------
328  # --- layout and display nodes -------------------------------------
376  # --- slots --------------------------------------------------------
390  # --- setup --------------------------------------------------------
392  func _ready() -> void
517  # --- overlay, selection and rings ---------------------------------
524  func set_overlay(mode: String) -> void
531  func _overlay_colour() -> Array
575  func set_selected(value: bool) -> void
587  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
598  func _set_outline_points(line: Line2D, size: float) -> void
609  func _silhouette_point_to_local(p: Vector2) -> Vector2
619  func _set_outline_points_cup(line: Line2D, size: float) -> void
642  func _apply_outline_points(line: Line2D, size: float) -> void
650  func _set_selection_ring_points() -> void
653  # --- per-frame update ---------------------------------------------
671  func _process(delta: float) -> void
692  # --- brood development --------------------------------------------
697  func _develop_brood(delta: float) -> void
718  func _health_factor() -> float
726  func _larva_dies() -> void
740  # --- index and display epochs -------------------------------------
746  func _invalidate_hive_index() -> void
756  func _invalidate_stock() -> void
770  func bump_display_epoch() -> void
773  # --- working positions --------------------------------------------
778  func claim_slot(bee: Node2D) -> int
789  func release_slot(bee: Node2D) -> void
796  func has_free_slot() -> bool
805  func slot_position(index: int) -> Vector2
817  # --- building -----------------------------------------------------
819  func start_as_site() -> void
824  func claim_builder(bee: Node2D) -> void
828  func release_builder(bee: Node2D) -> void
834  func add_build_progress(delta: float) -> void
845  func build_fraction() -> float
848  # --- contents -----------------------------------------------------
850  func is_empty() -> bool
855  func capacity_for(resource_type: String) -> float
863  func accepts(resource_type: String) -> bool
882  func is_nursery_cell() -> bool
885  func space_for(resource_type: String) -> float
907  func needs_eviction() -> bool
925  func add_resource(resource_type: String, requested: float) -> float
971  func nectar_age() -> float
983  func is_fermented() -> bool
992  func is_pre_fermented() -> bool
1003 func restore_bee_bread_seal() -> void
1016 func return_ripe_bee_bread(requested: float) -> float
1045 func is_bee_bread_sealed() -> bool
1051 func is_ripe_bee_bread() -> bool
1055 func bee_bread_ripen_fraction() -> float
1063 func take_resource(resource_type: String, requested: float) -> float
1099 func can_withdraw() -> bool
1104 func set_closed(value: bool) -> void
1111 func set_fill_then_close(value: bool) -> void
1120 func fill_fraction() -> float
1128 func set_designation(resource_type: String, explicit: bool = true) -> void
1136 # --- honey ---------------------------------------------------------
1138 func is_ripe_honey() -> bool
1142 func needs_fanning() -> bool
1147 func add_fanning_progress(delta: float) -> void
1157 func ripen_fraction() -> float
1160 # --- brood ---------------------------------------------------------
1162 func start_brood(as_gyne: bool = false, as_drone: bool = false) -> void
1176 func brood_kind_label() -> String
1186 func develop_time() -> float
1195 func feed_brood(seconds: float, on_honey: bool, on_bee_bread: bool = false) -> void
1202 func needs_feeding() -> bool
1206 func seconds_until_death() -> float
1211 # --- clearing a dead larva ------------------------------------------
1213 func needs_cleaning() -> bool
1219 func add_clean_progress(delta: float) -> bool
1225 func clean_fraction() -> float
1228 func brood_ready() -> bool
1231 func clear_cell() -> void
1247 # --- display ------------------------------------------------------
1252 func _resource_outline_colour(resource_type: String) -> Color
1268 func _refresh() -> void
1481 func _show_fill_art(sheet: String, frame: int) -> void
1494 func _show_cap(stage: int) -> void
1502 func _designation_tag() -> String
1526 func _priority_mark() -> String
1539 func _apply_fill_shading() -> void
1550 func development_percent() -> float
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

## main.gd (1,501 lines)

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
744  # --- public surface other scripts call directly -------------------
751  func is_on_screen(node: Node2D) -> bool
754  func hive_entrance_inside() -> Vector2
757  func entrance_wait_point(side: int) -> Vector2
760  func move_bee_into_hive(bee: Node2D) -> void
763  func move_bee_out_of_hive(bee: Node2D) -> void
766  func mark_death(bee: Node2D) -> void
774  func _on_bee_died(bee: Node2D) -> void
778  func finish_mining(block: Node2D) -> void
781  func save_run() -> void
784  func begin_winter_countdown() -> void
787  # --- per-frame ----------------------------------------------------
797  func _process(delta: float) -> void
889  # --- the frame rate readout ----------------------------------------
908  func _sample_fps() -> void
931  func _reseed_meadow(delta: float) -> void
951  func _hatch_ready_brood() -> void
987  func _sample_day_stores() -> void
1006 func _advance_weather(delta: float) -> void
1039 func _apply_rain_overlay() -> void
1050 # --- the first crisis ----------------------------------------------
1056 static func _blank_first_crisis() -> Dictionary
1067 static func first_crisis_bounds() -> Dictionary
1073 static func first_crisis_cutoff() -> float
1077 func _first_crisis_applies() -> bool
1084 func _first_crisis_holds_weather() -> bool
1096 func _first_crisis_readiness() -> Dictionary
1100 func _advance_first_crisis(delta: float) -> void
1141 func _warn_first_crisis(starts_at: float, path: String, readiness: Dictionary) -> void
1173 func _first_crisis_warning_text(readiness: Dictionary, lead: float) -> String
1187 func _start_first_crisis() -> void
1204 func _show_first_crisis_note() -> void
1231 static func _minutes_text(seconds: float) -> String
1238 func _trace_first_crisis(phase: String, readiness: Dictionary = {}, extra: Dictionary = {}) -> void
1277 func restore_first_crisis(saved: Variant) -> void
1314 func _check_for_loss() -> void
1342 func _promote_gyne_to_queen() -> bool
1363 func _check_colony_energy(delta: float) -> void
1394 func invalidate_population() -> void
1405 func _role_counts(bees: Variant = null) -> Dictionary
1422 func _update_population_readout(bees: Variant = null) -> void
1436 func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
1442 func _prune_selection() -> void
1455 func _on_restart_after_loss() -> void
1461 func _on_level_chosen(level: int) -> void
1475 func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
1489 func _apply_scenario_boot_arg() -> void
1494 func _end_scenario_run(outcome: String) -> void
```

## hive.gd (1,265 lines)

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
230  func site_at_tile(hex: Vector2i) -> Node2D
238  func tile_is_interior(hex: Vector2i) -> bool
243  func cell_at_tile(hex: Vector2i) -> Node2D
249  func _ready() -> void
268  func deposit(resource_type: String, amount: float) -> float
291  func pay_reward(resource_type: String, amount: float) -> float
314  func take(resource_type: String, amount: float) -> float
331  func take_energy(energy_wanted: float) -> float
344  func total(resource_type: String) -> float
350  func total_sealed() -> float
354  func total_honey() -> float
357  # --- finding cells ------------------------------------------------
370  func find_cell_for(resource_type: String, except: Node2D = null) -> Node2D
397  func find_designated_cell_for(resource_type: String, except: Node2D = null) -> Node2D
435  func find_empty_cell() -> Node2D
481  func _lay_by_priority(pool: Array) -> Node2D
512  func _tier_weights() -> Array
527  func record_lay(cell: Node2D) -> void
541  func zone_summary() -> Dictionary
573  func brood_stage_counts() -> Dictionary
591  func find_food_cell(except: Node2D = null) -> Node2D
621  func senses_fermentation() -> bool
627  func avoids_as_sour(cell: Node2D) -> bool
630  func has_room_for_egg() -> bool
633  func find_cell_with(resource_type: String) -> Node2D
649  func find_honey_source(from: Vector2) -> Node2D
670  func find_brood_nectar() -> Node2D
682  func find_brood_cell() -> Node2D
697  func find_cell_needing_fanning() -> Node2D
705  func find_honey_target() -> Node2D
714  func find_bee_bread_target(except: Node2D = null) -> Node2D
723  func can_take(resource_type: String, amount: float) -> bool
733  func find_unfinished_cell() -> Node2D
742  func find_cell_needing_cleaning() -> Node2D
746  func find_cell_needing_eviction() -> Node2D
754  func has_gyne_brood() -> bool
762  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
765  # --- bodies -------------------------------------------------------
776  func add_body(point: Vector2, died_at: float) -> Node2D
790  func remove_body(body: Node2D) -> void
797  func find_body_to_clear() -> Node2D
806  func clear_bodies() -> void
811  func _free_body(body: Node2D) -> void
819  # --- growing the comb ---------------------------------------------
858  func has_room_to_build(around: Vector2i = Vector2i.ZERO) -> bool
866  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
883  func _first_free_spiral_hex(around: Vector2i) -> Variant
903  func set_keep_clear(hex: Vector2i, value: bool) -> void
909  func is_keep_clear(hex: Vector2i) -> bool
916  func can_build_on(hex: Vector2i) -> bool
919  func _can_build_on(hex: Vector2i) -> bool
922  func _start_site_at(hex: Vector2i) -> Node2D
944  func create_cell_site_at(hex: Vector2i) -> Node2D
949  # --- navigation ---------------------------------------------------
960  func build_navigation() -> void
1001 func _is_solid(hex: Vector2i) -> bool
1007 func _tile_cost(hex: Vector2i) -> float
1010 func tile_is_walkable(hex: Vector2i) -> bool
1019 func nearest_walkable_point(point: Vector2) -> Vector2
1046 func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
1080 func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
1104 func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
1118 # --- mining -------------------------------------------------------
1127 func refresh_edge_flags() -> void
1149 func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
1177 func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
1201 func _is_markable_block(node: Variant) -> bool
1208 func mine_stand_hex(block: Node2D) -> Variant
1231 func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
1253 func remove_block(block: Node2D, floor_maker: Callable) -> void
1264 func announce() -> void
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

## game_config.gd (1,034 lines)

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
720  # --- comb building ---
740  # --- hive geometry ---
769  # --- bee life ---
774  # --- bee individuality ---
853  # --- the rival colony ---
906  # --- seasons ---
938  # --- disease ---
977  # --- gynes leaving ---
989  # --- nuptial flights ---
997  # --- winter ---
```

## input_selection.gd (750 lines)

Selection, drag and placement resolution.

```
15   # --- Keyboard and pointer input ---
16   func _unhandled_input(event: InputEvent) -> void
24   func _handle_key(event: InputEventKey) -> void
51   func _handle_mouse_button(event: InputEventMouseButton) -> void
81   func _handle_mouse_motion(event: InputEventMouseMotion) -> void
90   # --- Picking bees, comb and world objects ---
91   func _finish_drag(additive: bool, add_to_group_selection: bool = false) -> void
126  func _click_pick_in_hive(p: Vector2, add: bool) -> bool
151  func _click_pick_in_meadow(p: Vector2) -> bool
166  func _box_pick_comb(box: Rect2, add: bool) -> bool
185  func _box_pick_death_marker(box: Rect2) -> bool
196  func _apply_bee_pick(picked: Array, additive: bool) -> void
212  func _select_cells(cells: Array, additive: bool) -> void
232  func _clear_cell_selection() -> void
238  func _select_blocks(blocks: Array, additive: bool) -> void
262  func _clear_block_selection() -> void
268  func _select_world_object(kind: String, object: Node2D) -> void
276  func _clear_world_object_selection() -> void
281  func _on_soil_mark_requested(mark: bool) -> void
286  func _on_keep_clear_clear_requested() -> void
290  func _bees_in_current_view() -> Array
294  func _death_markers_in_current_view() -> Array
301  func _click_switches_view(point: Vector2) -> bool
317  func _bee_at(point: Vector2) -> Node2D
323  func _cell_at(point: Vector2) -> Node2D
329  func _soil_at(point: Vector2) -> Node2D
335  func _death_marker_at(point: Vector2) -> Node2D
341  func _hex_at(global_point: Vector2) -> Vector2i
345  # --- Click-to-place tools ---
385  func _placement_tool_def(tool_id: String) -> Dictionary
395  func request_placement_tool(tool_id: String) -> void
422  func clear_placement_tool() -> void
428  func _place_with_active_tool(ctrl_held: bool) -> void
436  func _place_build_cell(global_point: Vector2, keep_adding: bool) -> void
446  func _place_queen_build_cell(global_point: Vector2, _keep_adding: bool = false) -> void
453  func _place_mine_target(global_point: Vector2, keep_adding: bool) -> void
464  func _place_keep_clear(global_point: Vector2, _keep_adding: bool) -> void
469  func _place_home_cell(global_point: Vector2, _keep_adding: bool = false) -> void
480  func _on_cell_empty_by_bee_requested(cell: Node2D) -> void
489  func _place_home_cell_all(global_point: Vector2, _keep_adding: bool = false) -> void
497  func _place_mine_home(global_point: Vector2, _keep_adding: bool = false) -> void
505  func _place_forage_start(global_point: Vector2, _keep_adding: bool = false) -> void
511  func _place_floral_preference(global_point: Vector2, _keep_adding: bool = false) -> void
533  # --- Right-click orders ---
534  func _issue_command(world_point: Vector2) -> void
561  func _command_in_hive(world_point: Vector2, commandable: Array, targets_before: Array) -> void
580  func _command_in_meadow(world_point: Vector2, commandable: Array, targets_before: Array) -> void
606  func _prune_invalid_selected_bees() -> void
615  func _show_click_marker(world_point: Vector2) -> void
621  func _on_role_selection_requested(role: int, focus: String) -> void
637  func _ensure_hive_view() -> void
642  # --- Selection and order drawing ---
643  func _draw_selection_box() -> void
660  func _draw_hive_orders() -> void
693  func _draw_build_hover() -> void
702  func _draw_home_marker(point: Vector2) -> void
708  func _build_queue_points(bee: Node2D) -> Array
714  func _mine_queue_points(bee: Node2D) -> Array
721  func _draw_order_chain(bee: Node2D, points: Array, colour: Color) -> void
731  func _draw_tile_outline(centre: Vector2, colour: Color, width: float, dashed: bool) -> void
740  func _tile_centre(hex: Vector2i) -> Vector2
745  func _draw_start_point_marker(point: Vector2) -> void
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
