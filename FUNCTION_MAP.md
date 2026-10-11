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

## hud.gd (3,682 lines)

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
3369 func _apply_selection_tray_width() -> void
3420 func _match_summary_header_button_heights() -> void
3438 func _tray_column_share(inner_width: float) -> float
3447 func _apply_even_column_widths(wrappers: Array) -> void
3475 func _update_command_tray_width() -> void
3496 func _resize_command_tray() -> void
3531 func _resettle_command_tray(generation: int, previous_content_min_y: float, stable_streak: int, pass_count: int) -> void
3545 func _apply_command_tray_rect() -> void
3563 func _on_command_content_minimum_size_changed() -> void
3570 func set_winter_button_visible(value: bool) -> void
3576 func set_view_label(in_hive: bool) -> void
3585 func set_allowed_role_keys(keys: Array) -> void
3593 func _role_offered(role_id: int, bee = null) -> bool
3599 func refresh_role_gating() -> void
3608 func set_command_locked_bees(bees: Array) -> void
3613 func set_allowed_mode_keys(keys: Array) -> void
3623 func set_allowed_designation_keys(keys: Array) -> void
3633 func set_queen_build_button_visible(value: bool) -> void
3638 # --- stage gates --------------------------------------------------
3646 func apply_gates(stage_gate) -> void
3664 func _register_gated_control(control_name: String, getter: Callable) -> void
3672 func _apply_gate_to_control(control_name: String) -> void
3681 func _is_gate_open(control_name: String) -> bool
```

## bee.gd (2,978 lines)

A bee's dispatch loop, player commands, display text, vars.

```
23   # --- preloads and shared enums ------------------------------------
56   # --- the role action catalogue ------------------------------------
75   # --- stats copied from GameConfig ---------------------------------
86   # --- role, state and identity -------------------------------------
338  func current_working_role() -> int
341  # --- floral constancy and the search pattern ----------------------
413  # --- patch memory and species experience --------------------------
440  # --- scouting -----------------------------------------------------
464  # --- trip rates and scoring ---------------------------------------
528  # --- recruitment and dancing --------------------------------------
568  # --- tipsiness (NF-3) ---------------------------------------------
589  # --- build and mine queues ----------------------------------------
613  # --- flower cooldowns and predator memory -------------------------
667  # --- pathfinding inside the hive ----------------------------------
673  # --- the visual nodes ---------------------------------------------
726  # --- _ready and construction --------------------------------------
727  func _ready() -> void
772  func _build_visuals() -> void
879  func _caste_size_factor() -> float
893  func become_drone() -> void
919  func become_queen() -> void
936  # --- nuptial flights (COL-11) -------------------------------------
942  func set_nuptial_flights(on: bool) -> void
953  func _nuptial_flight_step(delta: float) -> void
1000 func _nuptial_flight_due() -> bool
1010 func _begin_nuptial_flight() -> void
1017 func _end_nuptial_flight() -> void
1026 # --- setup, stats and appearance ----------------------------------
1027 func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
1069 func _roll_fact() -> void
1083 func _default_state_for_role() -> int
1105 func _base_colour() -> Color
1118 func _tinted(c: Color) -> Color
1133 func _apply_stats() -> void
1165 func set_brood_outcome(outcome: String) -> void
1170 func outcome_stat_factor() -> float
1182 func outcome_lifespan_days() -> float
1192 func brood_outcome_text() -> String
1207 func trait_text() -> String
1216 func _update_role_marker() -> void
1235 # --- how often a bee thinks ---------------------------------------
1267 func _process(delta: float) -> void
1566 # --- life support -------------------------------------------------
1568 # --- eating -------------------------------------------------------
1570 # --- stall watchdog -----------------------------------------------
1576 func _reset_stall_watch() -> void
1580 # --- the tipsy wander (NF-3) --------------------------------------
1613 func _maybe_start_tipsy_wander(think_delta: float) -> void
1630 func _tipsy_wander(delta: float) -> void
1646 func _end_tipsy_wander() -> void
1655 func _tipsy_wander_target() -> Vector2
1669 func saved_state() -> int
1674 func saved_position() -> Vector2
1678 # --- foraging -----------------------------------------------------
1680 # --- entering and leaving the hive --------------------------------
1682 # --- nursery work -------------------------------------------------
1684 # --- royal jelly ---------------------------------------------------
1686 # --- idle work dispatch --------------------------------------------
1700 func _apply_pending_role() -> bool
1717 func _deliver_held_load() -> bool
1738 func _return_nurse_food() -> void
1766 func _return_ripe_bee_bread(amount: float) -> float
1787 func _return_bee_bread() -> void
1798 func _is_busy() -> bool
1804 func _idle_dispatch() -> void
1832 func _maybe_break_off_secondary() -> void
1856 func _try_role_work(r: int) -> bool
1881 static func _build_actions_by_role() -> Dictionary
1896 func _action_available(action_id: String) -> bool
1906 func _action_mode_for_role(r: int) -> String
1917 # --- building -----------------------------------------------------
1919 # --- keeping cells topped up ---------------------------------------
1948 func set_restock_targets(cells: Array, resource: String) -> void
1951 func set_restock_sources(cells: Array, allowed: bool) -> void
1954 func clear_restock() -> void
1957 func has_restock_orders() -> bool
1959 # --- mining -------------------------------------------------------
1961 # --- honey making -------------------------------------------------
1963 # --- egg laying (queen only) --------------------------------------
1965 # --- player commands ----------------------------------------------
1975 func command_move_to(world_point: Vector2) -> void
1995 func command_move_through_entrance(world_point: Vector2, target_in_hive: bool) -> void
2007 func command_exit_hive() -> void
2017 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
2025 func has_forage_start_point() -> bool
2028 func set_preferred_species(species: String) -> void
2041 func set_manual_build_target(hex: Vector2i) -> void
2049 func queue_build_target(hex: Vector2i) -> void
2056 func clear_build_queue() -> void
2062 func _take_next_build_target() -> bool
2075 func set_mine_target(block: Node2D) -> void
2082 func queue_mine_target(block: Node2D) -> void
2090 func clear_mine_queue() -> void
2097 func _next_queued_block() -> Node2D
2105 func set_home_hex(hex: Vector2i) -> void
2114 func set_mine_home_hex(hex: Vector2i) -> void
2120 func _mine_reference_point() -> Vector2
2135 func command_collect_from(flower: Node2D) -> void
2151 func command_collect_from_after_exit(flower: Node2D) -> void
2164 func command_return_and_deposit() -> void
2174 func command_return_only() -> void
2180 func command_deposit_at(cell: Node2D) -> void
2193 func command_empty_cell(cell: Node2D) -> void
2208 func command_deposit_at_after_enter(cell: Node2D) -> void
2216 func resume_pending_zone_command() -> bool
2235 func _clear_pending_zone_command() -> void
2240 func set_focus(type: String) -> void
2297 func _has_deliverable_target() -> bool
2303 func set_secondary_role(new_role: int) -> void
2311 func can_take_role(new_role: int) -> bool
2323 func set_role(new_role: int) -> void
2340 func _apply_role(new_role: int) -> void
2381 func _release_everything() -> void
2398 func release_flower_reference(flower: Node2D) -> void
2404 func set_selected(value: bool) -> void
2408 # --- display ------------------------------------------------------
2410 func role_letter() -> String
2439 func challenge_vocabulary_limited() -> bool
2452 func idle_reason() -> String
2504 func task_description() -> String
2513 func _task_line() -> String
2677 func _idle_backup_note() -> String
2687 func role_name_text() -> String
2725 func architect_mode_name() -> String
2731 func carrying_text() -> String
2757 func age_days() -> float
2765 func leave_to_found_colony() -> void
2778 func days_remaining() -> float
2790 func _update_label() -> void
2810 func _update_alarm_ring() -> void
2821 func _update_heading_marker() -> void
2835 func _update_search_ring() -> void
2858 func _update_dance_ring() -> void
2891 func _update_wander_flight(delta: float) -> void
2922 func _update_dance_circle(delta: float) -> void
2936 func _terrain_speed_factor() -> float
2945 func _is_inside_hive() -> bool
2953 func _on_tree_entered() -> void
2957 # --- getting round things in the meadow ---------------------------
2977 func clear_navigation_state() -> void
```

## scenario_actions.gd (1,683 lines)

The headless verbs, `when` clauses and layout assertions.

```
25   # --- preloads -----------------------------------------------------
59   # --- run_pending --------------------------------------------------
65   static func run_pending(main: Node2D, actions: Array) -> void
94   # --- the comb build-site sampler ----------------------------------
104  static func sample_comb_build_sites(main: Node2D) -> void
143  # --- log_unresolved -----------------------------------------------
150  static func log_unresolved(actions: Array) -> void
157  # --- the settle, wait and window helpers --------------------------
169  static func _do_settle(action: Dictionary) -> bool
182  static func _do_wait(action: Dictionary) -> bool
197  static func _assert_window_closed(main: Node2D, action: Dictionary) -> bool
210  static func _sample_queen_watch(main: Node2D) -> void
217  # --- _execute -----------------------------------------------------
219  static func _execute(main: Node2D, action: Dictionary) -> void
281  # --- triggers -----------------------------------------------------
291  static func _when_met(main: Node2D, when: Dictionary) -> bool
345  static func _legacy_when_spec(main: Node2D, when: Dictionary) -> Dictionary
399  # --- selectors ------------------------------------------------------
403  static func _resolve_bees(main: Node2D, target: Dictionary) -> Array
435  static func _resolve_cell_ref(main: Node2D, ref: Dictionary) -> Node2D
442  static func _resolve_cell(main: Node2D, hex: Array) -> Node2D
452  static func _resolve_soil_block(main: Node2D, hex: Array) -> Node2D
462  # --- verbs ------------------------------------------------------------
479  static func _do_assign_role(main: Node2D, action: Dictionary) -> void
546  static func _do_designate_cell(main: Node2D, action: Dictionary) -> void
570  static func _do_queue_build(main: Node2D, action: Dictionary) -> void
596  static func _do_queue_mine(main: Node2D, action: Dictionary) -> void
621  static func _do_request_placement_tool(main: Node2D, action: Dictionary) -> void
633  static func _do_click_world(main: Node2D, action: Dictionary) -> void
663  static func _do_set_config(_main: Node2D, action: Dictionary) -> void
681  static func _do_hatch_role(main: Node2D, action: Dictionary) -> void
708  static func _do_set_restock_order(main: Node2D, action: Dictionary) -> void
754  static func _do_select_bees(main: Node2D, action: Dictionary) -> void
785  static func _do_select_soil(main: Node2D, action: Dictionary) -> void
811  static func _do_select_cell(main: Node2D, action: Dictionary) -> void
830  static func _force_layout(node: Node) -> void
843  static func _do_open_window(main: Node2D, action: Dictionary) -> void
900  static func _do_close_window(main: Node2D, action: Dictionary) -> void
919  static func _do_viewport_size(main: Node2D, action: Dictionary) -> void
932  static func _do_show_gallerin_prompt(main: Node2D, action: Dictionary) -> void
948  static func _do_retreat_challenge_stage(main: Node2D, action: Dictionary) -> void
967  static func _do_advance_challenge_stage(main: Node2D, action: Dictionary) -> void
993  static func _do_set_queen_load(main: Node2D, action: Dictionary) -> void
1024 static func _do_set_bee_load(main: Node2D, action: Dictionary) -> void
1041 static func _do_set_cell_contents(main: Node2D, action: Dictionary) -> void
1065 static func _do_empty_cell(main: Node2D, action: Dictionary) -> void
1078 static func _do_clear_fermented(main: Node2D) -> void
1085 static func _do_watch_queen_states(main: Node2D, action: Dictionary) -> void
1100 static func _do_save_run(main: Node2D, action: Dictionary) -> void
1107 static func _do_buy_skill(main: Node2D, action: Dictionary) -> void
1129 static func _do_grant_skill(action: Dictionary) -> void
1143 static func _do_restore_slot(main: Node2D, action: Dictionary) -> void
1154 # --- assertion checks -------------------------------------------------
1164 static func _do_assert(main: Node2D, action: Dictionary) -> bool
1174 static func _evaluate_assert_condition(main: Node2D, condition: Dictionary) -> Dictionary
1219 static func _check_save_slot(main: Node2D, condition: Dictionary) -> Dictionary
1247 static func _check_all_actions_available(main: Node2D) -> Dictionary
1259 static func _queen_summary(main: Node2D, condition: Dictionary) -> String
1287 static func _check_panel_rect(main: Node2D, condition: Dictionary) -> Dictionary
1382 static func _resolve_named_panel(main: Node2D, name: String) -> Control
1396 static func _game_panel(main: Node2D, key: String) -> GamePanel
1417 static func _check_control_rect(main: Node2D, condition: Dictionary) -> Dictionary
1495 static func _check_panel_texture_contrast(_condition: Dictionary) -> Dictionary
1522 static func _check_menu_items(main: Node2D, condition: Dictionary) -> Dictionary
1541 static func _label_leading(control: Control) -> Dictionary
1555 static func _check_even_columns(main: Node2D, condition: Dictionary) -> Dictionary
1595 static func _check_no_collapsed_controls(main: Node2D, condition: Dictionary) -> Dictionary
1612 static func _check_no_empty_labels(main: Node2D, condition: Dictionary) -> Dictionary
1623 static func _collect_empty_labels(node: Node, out: Array) -> void
1629 static func _collect_collapsed_controls(node: Node, out: Array) -> void
1649 static func _resolve_scoped_path(main: Node2D, path: String) -> Node
1682 static func _log(do: String, target_desc: String, result: String, reason: String) -> void
```

## settings_catalogue.gd (1,578 lines)

Every setting's key, label, range and tip, plus the read/write and Prerequisites-cascade functions the window is a view of.

```
22   # --- preloads and collection order --------------------------------
48   # --- the tunables table -------------------------------------------
1453 # --- settings owned by Session ------------------------------------
1467 # --- reading and writing a setting --------------------------------
1468 static func setting_get(key: String)
1471 static func setting_set(key: String, value) -> void
1478 # --- resetting ----------------------------------------------------
1495 static func reset_config_to_defaults() -> void
1507 static func reset_config_keys(keys: Array) -> void
1513 # --- applying a setting with its cascades -------------------------
1522 static func apply_setting(key: String, value) -> void
1533 # --- the cascade helpers ------------------------------------------
1538 static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1556 static func _cascade_dependents_off_static(key: String) -> Array[String]
1570 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
```

## bee_foraging.gd (1,521 lines)

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
611  static func handling_experience_on() -> bool
618  static func record_species_visit(bee: Node2D, species: String) -> void
631  static func orientation_flight_on() -> bool
635  # --- accepting or rejecting a flower ------------------------------
636  static func worth_feeding(bee: Node2D, f: Node2D) -> bool
649  static func reject_flower(bee: Node2D) -> void
667  # --- collecting ---------------------------------------------------
668  static func start_collecting(bee: Node2D) -> void
741  static func _handling_experience_scale(bee: Node2D, species: String) -> float
750  static func collect(bee: Node2D, delta: float) -> void
799  static func finish_collecting(bee: Node2D) -> void
842  # --- entering the hive and depositing -----------------------------
846  static func enter_hive(bee: Node2D) -> void
873  static func approach_cell(bee: Node2D, cell: Node2D, delta: float) -> int
888  static func release_cell_slot(bee: Node2D) -> void
895  static func go_to_deposit_cell(bee: Node2D, delta: float) -> void
985  static func finish_depositing(bee: Node2D) -> void
1025 static func _after_delivery_state(bee: Node2D) -> int
1036 static func _resume_own_job_if_indoors(bee: Node2D) -> bool
1044 # --- scoring a trip -----------------------------------------------
1049 static func _score_trip(bee: Node2D) -> void
1127 # --- leaving the hive ---------------------------------------------
1128 static func go_to_exit(bee: Node2D, delta: float) -> void
1172 static func _entrance_wait_spot(bee: Node2D, side: int) -> Vector2
1184 static func _leave_hive_and_resume(bee: Node2D) -> void
1211 static func _send_to_scout_point(bee: Node2D) -> void
1222 # --- scouting -----------------------------------------------------
1228 static func start_scouting(bee: Node2D) -> void
1246 # --- waiting at the entrance --------------------------------------
1251 static func wait_at_entrance(bee: Node2D, delta: float) -> void
1355 # --- the recruitment dance ----------------------------------------
1363 static func _update_dance_eligibility(bee: Node2D) -> void
1386 static func leave_recruitment(bee: Node2D) -> void
1408 static func check_dance_proximity(bee: Node2D, _delta: float) -> void
1433 static func _start_dance(mentor: Node2D, seeker: Node2D) -> void
1453 static func dance(bee: Node2D, delta: float) -> void
1465 static func _end_dance(bee: Node2D) -> void
1487 static func _complete_dance(mentor: Node2D, seeker: Node2D) -> void
1514 # --- remote deposit -----------------------------------------------
1516 static func deposit_everything_remotely(bee: Node2D) -> void
```

## hive_cell.gd (1,364 lines)

One cell: contents, brood, honey ripening, how it draws.

```
25   # --- constants and colours ----------------------------------------
109  # --- cell state ---------------------------------------------------
167  # --- building state -----------------------------------------------
191  func effective_build_time() -> float
194  # --- designation and orders ---------------------------------------
236  # --- hatch settings -----------------------------------------------
254  # --- layout and display nodes -------------------------------------
295  # --- slots --------------------------------------------------------
309  # --- setup --------------------------------------------------------
311  func _ready() -> void
428  # --- overlay, selection and rings ---------------------------------
435  func set_overlay(mode: String) -> void
441  func _overlay_colour() -> Array
481  func set_selected(value: bool) -> void
493  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
504  func _set_outline_points(line: Line2D, size: float) -> void
515  func _silhouette_point_to_local(p: Vector2) -> Vector2
526  func _set_outline_points_cup(line: Line2D, size: float) -> void
542  func _apply_outline_points(line: Line2D, size: float) -> void
550  func _set_selection_ring_points() -> void
553  # --- per-frame update ---------------------------------------------
571  func _process(delta: float) -> void
592  # --- brood development --------------------------------------------
597  func _develop_brood(delta: float) -> void
618  func _health_factor() -> float
626  func _larva_dies() -> void
640  # --- index and display epochs -------------------------------------
646  func _invalidate_hive_index() -> void
656  func _invalidate_stock() -> void
670  func bump_display_epoch() -> void
673  # --- working positions --------------------------------------------
678  func claim_slot(bee: Node2D) -> int
689  func release_slot(bee: Node2D) -> void
696  func has_free_slot() -> bool
705  func slot_position(index: int) -> Vector2
717  # --- building -----------------------------------------------------
719  func start_as_site() -> void
724  func claim_builder(bee: Node2D) -> void
728  func release_builder(bee: Node2D) -> void
734  func add_build_progress(delta: float) -> void
745  func build_fraction() -> float
748  # --- contents -----------------------------------------------------
750  func is_empty() -> bool
755  func capacity_for(resource_type: String) -> float
763  func accepts(resource_type: String) -> bool
782  func is_nursery_cell() -> bool
785  func space_for(resource_type: String) -> float
807  func needs_eviction() -> bool
825  func add_resource(resource_type: String, requested: float) -> float
871  func nectar_age() -> float
883  func is_fermented() -> bool
891  func restore_bee_bread_seal() -> void
904  func return_ripe_bee_bread(requested: float) -> float
933  func is_bee_bread_sealed() -> bool
939  func is_ripe_bee_bread() -> bool
943  func bee_bread_ripen_fraction() -> float
951  func take_resource(resource_type: String, requested: float) -> float
987  func can_withdraw() -> bool
992  func set_closed(value: bool) -> void
999  func set_fill_then_close(value: bool) -> void
1008 func fill_fraction() -> float
1016 func set_designation(resource_type: String, explicit: bool = true) -> void
1024 # --- honey ---------------------------------------------------------
1026 func is_ripe_honey() -> bool
1030 func needs_fanning() -> bool
1035 func add_fanning_progress(delta: float) -> void
1045 func ripen_fraction() -> float
1048 # --- brood ---------------------------------------------------------
1050 func start_brood(as_gyne: bool = false, as_drone: bool = false) -> void
1064 func brood_kind_label() -> String
1074 func develop_time() -> float
1083 func feed_brood(seconds: float, on_honey: bool, on_bee_bread: bool = false) -> void
1090 func needs_feeding() -> bool
1094 func seconds_until_death() -> float
1099 # --- clearing a dead larva ------------------------------------------
1101 func needs_cleaning() -> bool
1107 func add_clean_progress(delta: float) -> bool
1113 func clean_fraction() -> float
1116 func brood_ready() -> bool
1119 func clear_cell() -> void
1135 # --- display ------------------------------------------------------
1140 func _resource_outline_colour(resource_type: String) -> Color
1156 func _refresh() -> void
1313 func _designation_tag() -> String
1337 func _priority_mark() -> String
1350 func _apply_fill_shading() -> void
1361 func development_percent() -> float
```

## main.gd (1,348 lines)

Per-frame entry point, everything not yet split out of main.

```
37   # --- signals ------------------------------------------------------
51   # --- preloads and boot constants ----------------------------------
97   # --- delegate systems ---------------------------------------------
133  # --- world and meadow constants -----------------------------------
194  # --- state --------------------------------------------------------
351  # --- _ready and construction --------------------------------------
361  static func run_definition(level_id: int, developer_edits_allowed: bool, overrides_path: String = DeveloperOverrides.PATH) -> Dictionary
380  func _ready() -> void
666  # --- public surface other scripts call directly -------------------
673  func is_on_screen(node: Node2D) -> bool
676  func hive_entrance_inside() -> Vector2
679  func entrance_wait_point(side: int) -> Vector2
682  func move_bee_into_hive(bee: Node2D) -> void
685  func move_bee_out_of_hive(bee: Node2D) -> void
688  func mark_death(bee: Node2D) -> void
696  func _on_bee_died(bee: Node2D) -> void
700  func finish_mining(block: Node2D) -> void
703  func save_run() -> void
706  func begin_winter_countdown() -> void
709  # --- per-frame ----------------------------------------------------
719  func _process(delta: float) -> void
806  # --- the frame rate readout ----------------------------------------
825  func _sample_fps() -> void
848  func _reseed_meadow(delta: float) -> void
868  func _hatch_ready_brood() -> void
904  func _sample_day_stores() -> void
921  func _advance_weather(delta: float) -> void
951  func _apply_rain_overlay() -> void
978  func _check_for_loss() -> void
1006 func _promote_gyne_to_queen() -> bool
1027 func _check_colony_energy(delta: float) -> void
1058 func invalidate_population() -> void
1069 func _role_counts(bees = null) -> Dictionary
1086 func _update_population_readout(bees = null) -> void
1100 func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
1106 func _prune_selection() -> void
1119 func _on_restart_after_loss() -> void
1125 func _on_level_chosen(level: int) -> void
1138 func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
1156 func _apply_scenario_boot_arg() -> void
1281 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1321 func _is_whole_number(value: Variant) -> bool
1335 func _end_scenario_run(outcome: String) -> void
```

## diagnostic_log.gd (1,260 lines)

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
958  func _first_tier2_affordable(hive: Object) -> bool
965  func _snapshot(world: Node2D) -> Dictionary
1145 func _flower_season_counts(world: Node2D) -> Dictionary
1173 func _performance_snapshot(world: Node2D) -> Dictionary
1193 func _rate(world: Node2D, key: String) -> float
1205 # --- writing to disk ----------------------------------------------
1209 func _current_day() -> int
1213 func _prune_old_sessions() -> void
1231 func _write(entry: Dictionary) -> void
1240 func _capture_entry(entry: Dictionary) -> bool
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

## debug_panel.gd (1,190 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
20   # --- preloads -----------------------------------------------------
45   # --- fields -------------------------------------------------------
91   # --- _ready and construction --------------------------------------
94   func _style_button(button: BaseButton) -> BaseButton
99   func _ready() -> void
218  func _apply_panel_width() -> void
223  func _report_settings_button_width() -> void
228  # --- collections and sections -------------------------------------
229  func _rows_in(category: String) -> Array
251  func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
282  func _set_open(header: Button, body: Control, label: String, open: bool) -> void
290  func open_to_categories(categories: Array) -> void
310  func collapse_all() -> void
318  func _make_section(category: String, entries: Array, start_open: bool) -> Control
374  # --- the Challenge stage navigator --------------------------------
379  func _make_challenge_stage_navigation() -> Control
436  func _process(_delta: float) -> void
442  func _refresh_pollination_readout() -> void
455  func _pollination_text(points: int, contribution: int) -> String
458  func _refresh_challenge_stage_navigation() -> void
478  # --- the controls help --------------------------------------------
484  func _make_controls_help() -> Control
531  # --- the action buttons -------------------------------------------
543  func _build_actions(column: VBoxContainer) -> void
593  func _rebuild_triggers() -> void
628  func _on_end_run_pressed() -> void
639  func _refresh_developer_row() -> void
663  func _make_run_availability_button() -> Button
672  func _on_run_availability_pressed() -> void
682  func _add_action_row(parent: Control, button: Button, tip: String) -> void
688  func _make_winter_action() -> Control
700  func _on_winter_pressed() -> void
706  func _on_challenge_advance_pressed() -> void
713  func _on_challenge_retreat_pressed() -> void
727  func _on_fire_test_warnings_pressed() -> void
760  func _on_force_c2_collapse_pressed() -> void
774  # --- save and load ------------------------------------------------
780  func set_save_load_enabled(enabled: bool) -> void
788  func set_toggle(key: String, value: bool) -> void
793  func _on_save_pressed() -> void
804  func _on_load_pressed() -> void
837  # --- showing and hiding the panel ---------------------------------
838  func _toggle_panel() -> void
852  func _apply_layer_for_context() -> void
857  # --- building a settings row --------------------------------------
858  func _make_row(entry: Dictionary) -> Control
901  func _make_control_slot() -> HBoxContainer
910  func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
940  func _make_toggle_row(entry: Dictionary) -> Control
1013 func _make_options_row(entry: Dictionary) -> Control
1046 func _option_display(entry: Dictionary, value) -> String
1050 func _cycle_option(entry: Dictionary, direction: int) -> void
1061 # --- prerequisite cascades ----------------------------------------
1065 func _cascade_prerequisites_on(key: String) -> void
1079 func _cascade_dependents_off(key: String) -> void
1087 func _cascade_mutual_exclusion(key: String) -> void
1092 # --- star rows and value editing ----------------------------------
1097 func _make_star_row(entry: Dictionary) -> Control
1138 func _adjust(entry: Dictionary, delta: float) -> void
1155 func _format_value(v) -> String
1162 # --- restart and main menu ----------------------------------------
1163 func _on_restart_pressed() -> void
1168 func _on_main_menu_pressed() -> void
1176 func _restart() -> void
```

## hive.gd (1,190 lines)

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
532  func find_food_cell(except: Node2D = null) -> Node2D
562  func senses_fermentation() -> bool
568  func avoids_as_sour(cell: Node2D) -> bool
571  func has_room_for_egg() -> bool
574  func find_cell_with(resource_type: String) -> Node2D
590  func find_honey_source(from: Vector2) -> Node2D
611  func find_brood_nectar() -> Node2D
623  func find_brood_cell() -> Node2D
638  func find_cell_needing_fanning() -> Node2D
646  func find_honey_target() -> Node2D
655  func find_bee_bread_target(except: Node2D = null) -> Node2D
664  func can_take(resource_type: String, amount: float) -> bool
674  func find_unfinished_cell() -> Node2D
683  func find_cell_needing_cleaning() -> Node2D
687  func find_cell_needing_eviction() -> Node2D
695  func has_gyne_brood() -> bool
703  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
706  # --- bodies -------------------------------------------------------
717  func add_body(point: Vector2, died_at: float) -> Node2D
731  func remove_body(body: Node2D) -> void
738  func find_body_to_clear() -> Node2D
747  func clear_bodies() -> void
752  func _free_body(body: Node2D) -> void
760  # --- growing the comb ---------------------------------------------
794  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
828  func set_keep_clear(hex: Vector2i, value: bool) -> void
834  func is_keep_clear(hex: Vector2i) -> bool
841  func can_build_on(hex: Vector2i) -> bool
844  func _can_build_on(hex: Vector2i) -> bool
847  func _start_site_at(hex: Vector2i) -> Node2D
869  func create_cell_site_at(hex: Vector2i) -> Node2D
874  # --- navigation ---------------------------------------------------
885  func build_navigation() -> void
926  func _is_solid(hex: Vector2i) -> bool
932  func _tile_cost(hex: Vector2i) -> float
935  func tile_is_walkable(hex: Vector2i) -> bool
944  func nearest_walkable_point(point: Vector2) -> Vector2
971  func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
1005 func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
1029 func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
1043 # --- mining -------------------------------------------------------
1052 func refresh_edge_flags() -> void
1074 func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
1102 func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
1126 func _is_markable_block(node) -> bool
1133 func mine_stand_hex(block: Node2D)
1156 func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
1178 func remove_block(block: Node2D, floor_maker: Callable) -> void
1189 func announce() -> void
```

## game_config.gd (991 lines)

The balance fields.

```
8    # --- world ---
30   # --- flowers (per-species values are in flower.gd; these scale them) ---
416  # --- foraging ---
425  # --- hive ---
452  # --- the nursery zone ---
513  # --- eating ---
521  # --- flight ---
552  # --- gynes ---
567  # --- royal jelly ---
577  # --- bee bread (BB-1) ---
591  # --- bee bread nursing and a worker's outcome (BB-2) ---
610  # --- weather ---
628  # --- warnings ---
637  # --- honey ---
681  # --- comb building ---
701  # --- hive geometry ---
730  # --- bee life ---
735  # --- bee individuality ---
814  # --- the rival colony ---
863  # --- seasons ---
895  # --- disease ---
934  # --- gynes leaving ---
946  # --- nuptial flights ---
954  # --- winter ---
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
