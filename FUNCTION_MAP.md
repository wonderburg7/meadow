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

## hud.gd (3,980 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
27   # --- signals ------------------------------------------------------
121  # --- role controls ------------------------------------------------
133  static func hatch_options() -> Array
182  static func mode_command(role_id: int, mode_key: String) -> String
185  # --- shared layout constants --------------------------------------
221  # --- fields -------------------------------------------------------
548  # --- problem strip ------------------------------------------------
566  func _signal_color(severity: int) -> Color
573  # --- _ready and construction --------------------------------------
590  func _ready() -> void
668  func _on_viewport_size_changed() -> void
674  func _build_stage_marker_arrow() -> void
692  func set_stage_marker(global_position: Vector2, marker_visible: bool, in_hive: bool) -> void
697  func _make_label(pos: Vector2, variation: String = "Body") -> Label
705  func _info(text: String) -> Button
708  func _with_info(control: Control, tip: String) -> HBoxContainer
713  func _style_button(button: BaseButton) -> BaseButton
718  # --- speed controls -----------------------------------------------
742  func _build_top_right_bar() -> void
874  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
910  func _apply_interface_label_visibility() -> void
916  # --- Challenge goal readout ---------------------------------------
921  func _build_goal_shelf() -> void
1019 func set_settings_button_width(width: float) -> void
1033 func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
1061 func set_colony_goals(entries: Array) -> void
1093 func _apply_goals_collapsed() -> void
1105 func _add_goal_star(label: Control) -> void
1120 func _set_goal_star(label: Control, id: String, entries: Array) -> void
1135 func _on_goal_star_pressed(star: Button) -> void
1142 func _rebuild_favourites(entries: Array) -> void
1162 func _on_goals_header_pressed() -> void
1167 func set_speed_display(speed_scale: float) -> void
1172 # --- bottom row ---------------------------------------------------
1177 func _build_selection_panel() -> void
1304 func _build_favourite_star() -> Control
1335 func _set_favourite_star(bee) -> void
1363 func _field_control(field_name: String) -> Control
1377 func _build_selection_cog() -> Control
1404 func _theme_popup_on_open(popup: PopupMenu) -> void
1424 func _set_summary_cog_kind(kind: String) -> void
1436 func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
1456 func _apply_selection_field_visibility() -> void
1485 func _resize_selection_panel_to_content() -> void
1493 # --- command tray -------------------------------------------------
1505 func _build_command_tray() -> void
1608 func _build_tray_column(title: String) -> Array
1635 # --- cell popup ---------------------------------------------------
1651 func _build_cell_group(parent: VBoxContainer) -> void
1754 func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer
1782 func _build_priority_controls(column: VBoxContainer) -> void
1819 func _build_raises_controls(column: VBoxContainer) -> void
1908 func _build_closing_controls(column: VBoxContainer) -> void
1948 func _build_empty_controls(column: VBoxContainer) -> void
2021 func _make_hatch_menu(entry: Dictionary) -> Control
2051 func _fill_hatch_menu(popup: PopupMenu, role_value: int, options: Array) -> int
2063 func _build_warning_banner() -> void
2099 func show_warning(text: String, key: String = "", min_gap: float = 0.0, severity: int = 0) -> void
2116 func _show_warning_now(text: String, severity: int) -> void
2124 func _dismiss_warning() -> void
2129 func set_warnings_muted(value: bool) -> void
2143 func show_object_summary(kind: String, data) -> void
2170 func _refresh_flower_summary() -> void
2206 func _show_obstacle_summary(obstacle: Node2D) -> void
2212 func _show_soil_summary(count: int, reachable: int) -> void
2225 func _show_keep_clear_summary() -> void
2236 func _show_death_summary(info: Dictionary) -> void
2258 func show_cell_popup(cell: Node2D, count: int = 1) -> void
2280 func _refresh_cell_popup() -> void
2405 func _apply_cell_popup_gating() -> void
2431 func _light_current_options() -> void
2450 func _set_lit(key: String, lit: bool) -> void
2461 func _process(_delta: float) -> void
2493 func _stage_marker_screen_position() -> Vector2
2497 func _update_stage_marker_arrow() -> void
2530 func _refresh_marker_exclusion_rects(viewport_size: Vector2) -> void
2541 func _append_marker_panel_exclusion(panel: Control, owner_rect: Rect2) -> void
2546 func _slide_arrow_along_edge(edge_point: Vector2, edge_bounds: Rect2) -> Vector2
2563 func _marker_arrow_obscured(point: Vector2) -> bool
2569 func _request_designation(type: String) -> void
2574 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
2579 func _request_empty(method: String) -> void
2584 func _request_priority(tier: int) -> void
2589 func _request_close(closed: bool) -> void
2594 func _request_fill_close() -> void
2599 # --- discard warning ----------------------------------------------
2606 func _build_discard_dialog() -> void
2621 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
2640 func confirm_discard(title: String, text: String, ok_text: String, cancel_text: String, action: Callable, offer_stop_warning: bool = true) -> void
2650 func _on_discard_confirmed() -> void
2653 func _on_discard_custom_action(action: StringName) -> void
2660 func _apply_discard() -> void
2673 # --- readouts -----------------------------------------------------
2678 func update_day(day: int, note: String = "") -> void
2696 func set_weather_note(text: String) -> void
2708 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
2721 func _refresh_stores_text() -> void
2731 func update_population(nectar_foragers: int, pollen_foragers: int, nurses: int, builders: int, miners: int, honey_makers: int) -> void
2737 func update_comb(text: String) -> void
2741 func update_energy(mean_fraction: float) -> void
2748 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
2759 func update_recruit_gap(text: String) -> void
2772 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
2778 func update_signals(lines: Array) -> void
2786 func _red_always_shows() -> bool
2791 func strip_lines() -> Array
2805 func _remove_signal(id: String) -> void
2813 func _refresh_corner() -> void
2923 func _corner_line_width() -> float
2927 func _apply_corner_line_width() -> void
2936 func _fit_corner_line(line: Button) -> void
2944 func _on_corner_resized() -> void
2949 func corner_bottom() -> float
2955 func selection_panel_top() -> float
2965 func pinned_stats_changed() -> void
2974 func refresh_speed_visibility() -> void
2981 func refresh_corner() -> void
2984 func update_selection(bees: Array) -> void
3018 func _selection_has_command_lock(bees: Array) -> bool
3039 static func _detach_and_free_children(container: Node) -> void
3052 func _rebuild_role_controls(bees: Array) -> void
3107 func _build_queen_build_row(column: VBoxContainer) -> void
3121 func _build_follow_control(bees: Array, first) -> void
3136 func _build_job_row(common_role: int, any_queen: bool, queen_bee = null) -> void
3168 func _build_doing_row(common_role: int, first) -> void
3207 func _build_mating_row(bees: Array, first) -> void
3228 func _set_nuptial_flights(queen, on: bool) -> void
3239 func _build_gyne_send_row(bees: Array, first) -> void
3254 func _send_gyne(gyne) -> void
3260 func _gyne_not_ready_reason(gyne) -> String
3265 func _refresh_gyne_send_button(gyne) -> void
3271 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
3288 func _build_orders_row(common_role: int, first) -> void
3336 func _build_restock_row(first) -> void
3371 func _build_fallback_row(common_role: int, first) -> void
3421 func _secondary_items() -> Array
3437 func _column_row(parent: Container) -> HFlowContainer
3445 func _labelled_row(title: String) -> HFlowContainer
3464 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
3476 func _action_button(label: String, action: Callable, tip: String) -> Control
3485 func _current_role_marker(label: String) -> Control
3500 func _common_role(bees: Array) -> int
3517 func _common_working_role(bees: Array) -> int
3535 func _make_role_menu(label: String, tip: String, items: Array, node_name: String = "") -> Control
3557 func _refresh_selection_text() -> void
3667 func _apply_selection_tray_width() -> void
3718 func _match_summary_header_button_heights() -> void
3736 func _tray_column_share(inner_width: float) -> float
3745 func _apply_even_column_widths(wrappers: Array) -> void
3773 func _update_command_tray_width() -> void
3794 func _resize_command_tray() -> void
3829 func _resettle_command_tray(generation: int, previous_content_min_y: float, stable_streak: int, pass_count: int) -> void
3843 func _apply_command_tray_rect() -> void
3861 func _on_command_content_minimum_size_changed() -> void
3868 func set_winter_button_visible(value: bool) -> void
3874 func set_view_label(in_hive: bool) -> void
3883 func set_allowed_role_keys(keys: Array) -> void
3891 func _role_offered(role_id: int, bee = null) -> bool
3897 func refresh_role_gating() -> void
3906 func set_command_locked_bees(bees: Array) -> void
3911 func set_allowed_mode_keys(keys: Array) -> void
3921 func set_allowed_designation_keys(keys: Array) -> void
3931 func set_queen_build_button_visible(value: bool) -> void
3936 # --- stage gates --------------------------------------------------
3944 func apply_gates(stage_gate) -> void
3962 func _register_gated_control(control_name: String, getter: Callable) -> void
3970 func _apply_gate_to_control(control_name: String) -> void
3979 func _is_gate_open(control_name: String) -> bool
```

## bee.gd (3,027 lines)

A bee's dispatch loop, player commands, display text, vars.

```
23   # --- preloads and shared enums ------------------------------------
56   # --- the role action catalogue ------------------------------------
75   # --- stats copied from GameConfig ---------------------------------
86   # --- role, state and identity -------------------------------------
342  func current_working_role() -> int
345  # --- floral constancy and the search pattern ----------------------
417  # --- patch memory and species experience --------------------------
444  # --- scouting -----------------------------------------------------
468  # --- trip rates and scoring ---------------------------------------
532  # --- recruitment and dancing --------------------------------------
572  # --- tipsiness (NF-3) ---------------------------------------------
593  # --- build and mine queues ----------------------------------------
617  # --- flower cooldowns and predator memory -------------------------
671  # --- pathfinding inside the hive ----------------------------------
677  # --- the visual nodes ---------------------------------------------
730  # --- _ready and construction --------------------------------------
731  func _ready() -> void
776  func _build_visuals() -> void
883  func _caste_size_factor() -> float
897  func become_drone() -> void
923  func become_queen() -> void
940  # --- nuptial flights (COL-11) -------------------------------------
946  func set_nuptial_flights(on: bool) -> void
957  func _nuptial_flight_step(delta: float) -> void
1004 func _nuptial_flight_due() -> bool
1014 func _begin_nuptial_flight() -> void
1021 func _end_nuptial_flight() -> void
1030 # --- setup, stats and appearance ----------------------------------
1031 func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
1073 func _roll_fact() -> void
1087 func _default_state_for_role() -> int
1109 func _base_colour() -> Color
1122 func _tinted(c: Color) -> Color
1137 func _apply_stats() -> void
1169 func set_brood_outcome(outcome: String) -> void
1174 func outcome_stat_factor() -> float
1186 func outcome_lifespan_days() -> float
1196 func brood_outcome_text() -> String
1211 func trait_text() -> String
1220 func _update_role_marker() -> void
1239 # --- how often a bee thinks ---------------------------------------
1274 func _process(delta: float) -> void
1573 # --- life support -------------------------------------------------
1575 # --- eating -------------------------------------------------------
1577 # --- stall watchdog -----------------------------------------------
1583 func _reset_stall_watch() -> void
1587 # --- the tipsy wander (NF-3) --------------------------------------
1620 func _maybe_start_tipsy_wander(think_delta: float) -> void
1637 func _tipsy_wander(delta: float) -> void
1653 func _end_tipsy_wander() -> void
1662 func _tipsy_wander_target() -> Vector2
1676 func saved_state() -> int
1681 func saved_position() -> Vector2
1685 # --- foraging -----------------------------------------------------
1687 # --- entering and leaving the hive --------------------------------
1689 # --- nursery work -------------------------------------------------
1691 # --- royal jelly ---------------------------------------------------
1693 # --- idle work dispatch --------------------------------------------
1707 func _apply_pending_role() -> bool
1724 func _deliver_held_load() -> bool
1745 func _return_nurse_food() -> void
1773 func _return_ripe_bee_bread(amount: float) -> float
1794 func _return_bee_bread() -> void
1805 func _is_busy() -> bool
1811 func _idle_dispatch() -> void
1838 func _record_work_search(found: bool) -> bool
1844 func is_waiting_for_work() -> bool
1850 func has_no_available_work() -> bool
1856 func is_travelling_for_work() -> bool
1874 func _maybe_break_off_secondary() -> void
1898 func _try_role_work(r: int) -> bool
1924 static func _build_actions_by_role() -> Dictionary
1939 func _action_available(action_id: String) -> bool
1949 func _action_mode_for_role(r: int) -> String
1960 # --- building -----------------------------------------------------
1962 # --- keeping cells topped up ---------------------------------------
1991 func set_restock_targets(cells: Array, resource: String) -> void
1994 func set_restock_sources(cells: Array, allowed: bool) -> void
1997 func clear_restock() -> void
2000 func has_restock_orders() -> bool
2002 # --- mining -------------------------------------------------------
2004 # --- honey making -------------------------------------------------
2006 # --- egg laying (queen only) --------------------------------------
2008 # --- player commands ----------------------------------------------
2018 func command_move_to(world_point: Vector2) -> void
2038 func command_move_through_entrance(world_point: Vector2, target_in_hive: bool) -> void
2050 func command_exit_hive() -> void
2060 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
2068 func has_forage_start_point() -> bool
2071 func set_preferred_species(species: String) -> void
2084 func set_manual_build_target(hex: Vector2i) -> void
2092 func queue_build_target(hex: Vector2i) -> void
2099 func clear_build_queue() -> void
2105 func _take_next_build_target() -> bool
2118 func set_mine_target(block: Node2D) -> void
2125 func queue_mine_target(block: Node2D) -> void
2133 func clear_mine_queue() -> void
2140 func _next_queued_block() -> Node2D
2148 func set_home_hex(hex: Vector2i) -> void
2157 func set_mine_home_hex(hex: Vector2i) -> void
2163 func _mine_reference_point() -> Vector2
2178 func command_collect_from(flower: Node2D) -> void
2194 func command_collect_from_after_exit(flower: Node2D) -> void
2207 func command_return_and_deposit() -> void
2217 func command_return_only() -> void
2223 func command_deposit_at(cell: Node2D) -> void
2236 func command_empty_cell(cell: Node2D) -> void
2251 func command_deposit_at_after_enter(cell: Node2D) -> void
2259 func resume_pending_zone_command() -> bool
2278 func _clear_pending_zone_command() -> void
2283 func set_focus(type: String) -> void
2340 func _has_deliverable_target() -> bool
2346 func set_secondary_role(new_role: int) -> void
2354 func can_take_role(new_role: int) -> bool
2366 func set_role(new_role: int) -> void
2383 func _apply_role(new_role: int) -> void
2426 func _release_everything() -> void
2443 func release_flower_reference(flower: Node2D) -> void
2449 func set_selected(value: bool) -> void
2453 # --- display ------------------------------------------------------
2455 func role_letter() -> String
2484 func challenge_vocabulary_limited() -> bool
2497 func idle_reason() -> String
2553 func task_description() -> String
2562 func _task_line() -> String
2726 func _idle_backup_note() -> String
2736 func role_name_text() -> String
2774 func architect_mode_name() -> String
2780 func carrying_text() -> String
2806 func age_days() -> float
2814 func leave_to_found_colony() -> void
2827 func days_remaining() -> float
2839 func _update_label() -> void
2859 func _update_alarm_ring() -> void
2870 func _update_heading_marker() -> void
2884 func _update_search_ring() -> void
2907 func _update_dance_ring() -> void
2940 func _update_wander_flight(delta: float) -> void
2971 func _update_dance_circle(delta: float) -> void
2985 func _terrain_speed_factor() -> float
2994 func _is_inside_hive() -> bool
3002 func _on_tree_entered() -> void
3006 # --- getting round things in the meadow ---------------------------
3026 func clear_navigation_state() -> void
```

## scenario_actions.gd (1,716 lines)

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
361  static func _legacy_when_spec(main: Node2D, when: Dictionary) -> Dictionary
415  # --- selectors ------------------------------------------------------
419  static func _resolve_bees(main: Node2D, target: Dictionary) -> Array
451  static func _resolve_cell_ref(main: Node2D, ref: Dictionary) -> Node2D
458  static func _resolve_cell(main: Node2D, hex: Array) -> Node2D
468  static func _resolve_soil_block(main: Node2D, hex: Array) -> Node2D
478  # --- verbs ------------------------------------------------------------
495  static func _do_assign_role(main: Node2D, action: Dictionary) -> void
562  static func _do_designate_cell(main: Node2D, action: Dictionary) -> void
586  static func _do_queue_build(main: Node2D, action: Dictionary) -> void
612  static func _do_queue_mine(main: Node2D, action: Dictionary) -> void
637  static func _do_request_placement_tool(main: Node2D, action: Dictionary) -> void
650  static func _do_click_world(main: Node2D, action: Dictionary) -> void
686  static func _do_set_config(_main: Node2D, action: Dictionary) -> void
704  static func _do_hatch_role(main: Node2D, action: Dictionary) -> void
731  static func _do_set_restock_order(main: Node2D, action: Dictionary) -> void
777  static func _do_select_bees(main: Node2D, action: Dictionary) -> void
808  static func _do_select_soil(main: Node2D, action: Dictionary) -> void
834  static func _do_select_cell(main: Node2D, action: Dictionary) -> void
853  static func _force_layout(node: Node) -> void
866  static func _do_open_window(main: Node2D, action: Dictionary) -> void
923  static func _do_close_window(main: Node2D, action: Dictionary) -> void
942  static func _do_viewport_size(main: Node2D, action: Dictionary) -> void
955  static func _do_show_gallerin_prompt(main: Node2D, action: Dictionary) -> void
971  static func _do_retreat_challenge_stage(main: Node2D, action: Dictionary) -> void
990  static func _do_advance_challenge_stage(main: Node2D, action: Dictionary) -> void
1016 static func _do_set_queen_load(main: Node2D, action: Dictionary) -> void
1047 static func _do_set_bee_load(main: Node2D, action: Dictionary) -> void
1064 static func _do_set_cell_contents(main: Node2D, action: Dictionary) -> void
1088 static func _do_empty_cell(main: Node2D, action: Dictionary) -> void
1101 static func _do_clear_fermented(main: Node2D) -> void
1108 static func _do_watch_queen_states(main: Node2D, action: Dictionary) -> void
1123 static func _do_save_run(main: Node2D, action: Dictionary) -> void
1130 static func _do_buy_skill(main: Node2D, action: Dictionary) -> void
1152 static func _do_grant_skill(action: Dictionary) -> void
1168 static func _do_restore_slot(main: Node2D, action: Dictionary) -> void
1187 # --- assertion checks -------------------------------------------------
1197 static func _do_assert(main: Node2D, action: Dictionary) -> bool
1207 static func _evaluate_assert_condition(main: Node2D, condition: Dictionary) -> Dictionary
1252 static func _check_save_slot(main: Node2D, condition: Dictionary) -> Dictionary
1280 static func _check_all_actions_available(main: Node2D) -> Dictionary
1292 static func _queen_summary(main: Node2D, condition: Dictionary) -> String
1320 static func _check_panel_rect(main: Node2D, condition: Dictionary) -> Dictionary
1415 static func _resolve_named_panel(main: Node2D, name: String) -> Control
1429 static func _game_panel(main: Node2D, key: String) -> GamePanel
1450 static func _check_control_rect(main: Node2D, condition: Dictionary) -> Dictionary
1528 static func _check_panel_texture_contrast(_condition: Dictionary) -> Dictionary
1555 static func _check_menu_items(main: Node2D, condition: Dictionary) -> Dictionary
1574 static func _label_leading(control: Control) -> Dictionary
1588 static func _check_even_columns(main: Node2D, condition: Dictionary) -> Dictionary
1628 static func _check_no_collapsed_controls(main: Node2D, condition: Dictionary) -> Dictionary
1645 static func _check_no_empty_labels(main: Node2D, condition: Dictionary) -> Dictionary
1656 static func _collect_empty_labels(node: Node, out: Array) -> void
1662 static func _collect_collapsed_controls(node: Node, out: Array) -> void
1682 static func _resolve_scoped_path(main: Node2D, path: String) -> Node
1715 static func _log(do: String, target_desc: String, result: String, reason: String) -> void
```

## main.gd (1,660 lines)

Per-frame entry point, everything not yet split out of main.

```
37   # --- signals ------------------------------------------------------
51   # --- preloads and boot constants ----------------------------------
99   # --- delegate systems ---------------------------------------------
139  # --- world and meadow constants -----------------------------------
200  # --- state --------------------------------------------------------
395  # --- _ready and construction --------------------------------------
405  static func run_definition(level_id: int, developer_edits_allowed: bool, overrides_path: String = DeveloperOverrides.PATH) -> Dictionary
424  func _ready() -> void
722  # --- public surface other scripts call directly -------------------
729  func is_on_screen(node: Node2D) -> bool
732  func hive_entrance_inside() -> Vector2
735  func entrance_wait_point(side: int) -> Vector2
738  func move_bee_into_hive(bee: Node2D) -> void
741  func move_bee_out_of_hive(bee: Node2D) -> void
744  func mark_death(bee: Node2D) -> void
752  func _on_bee_died(bee: Node2D) -> void
756  func finish_mining(block: Node2D) -> void
759  func save_run() -> void
762  func begin_winter_countdown() -> void
765  # --- per-frame ----------------------------------------------------
775  func _process(delta: float) -> void
862  # --- the frame rate readout ----------------------------------------
881  func _sample_fps() -> void
904  func _reseed_meadow(delta: float) -> void
924  func _hatch_ready_brood() -> void
960  func _sample_day_stores() -> void
977  func _advance_weather(delta: float) -> void
1010 func _apply_rain_overlay() -> void
1021 # --- the first crisis ----------------------------------------------
1027 static func _blank_first_crisis() -> Dictionary
1038 static func first_crisis_bounds() -> Dictionary
1044 static func first_crisis_cutoff() -> float
1048 func _first_crisis_applies() -> bool
1055 func _first_crisis_holds_weather() -> bool
1067 func _first_crisis_readiness() -> Dictionary
1071 func _advance_first_crisis(delta: float) -> void
1112 func _warn_first_crisis(starts_at: float, path: String, readiness: Dictionary) -> void
1144 func _first_crisis_warning_text(readiness: Dictionary, lead: float) -> String
1158 func _start_first_crisis() -> void
1175 func _show_first_crisis_note() -> void
1202 static func _minutes_text(seconds: float) -> String
1209 func _trace_first_crisis(phase: String, readiness: Dictionary = {}, extra: Dictionary = {}) -> void
1248 func restore_first_crisis(saved) -> void
1285 func _check_for_loss() -> void
1313 func _promote_gyne_to_queen() -> bool
1334 func _check_colony_energy(delta: float) -> void
1365 func invalidate_population() -> void
1376 func _role_counts(bees = null) -> Dictionary
1393 func _update_population_readout(bees = null) -> void
1407 func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
1413 func _prune_selection() -> void
1426 func _on_restart_after_loss() -> void
1432 func _on_level_chosen(level: int) -> void
1446 func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
1465 func _apply_scenario_boot_arg() -> void
1593 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1633 func _is_whole_number(value: Variant) -> bool
1647 func _end_scenario_run(outcome: String) -> void
```

## settings_catalogue.gd (1,608 lines)

Every setting's key, label, range and tip, plus the read/write and Prerequisites-cascade functions the window is a view of.

```
22   # --- preloads and collection order --------------------------------
48   # --- the tunables table -------------------------------------------
1483 # --- settings owned by Session ------------------------------------
1497 # --- reading and writing a setting --------------------------------
1498 static func setting_get(key: String)
1501 static func setting_set(key: String, value) -> void
1508 # --- resetting ----------------------------------------------------
1525 static func reset_config_to_defaults() -> void
1537 static func reset_config_keys(keys: Array) -> void
1543 # --- applying a setting with its cascades -------------------------
1552 static func apply_setting(key: String, value) -> void
1563 # --- the cascade helpers ------------------------------------------
1568 static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1586 static func _cascade_dependents_off_static(key: String) -> Array[String]
1600 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
```

## bee_foraging.gd (1,529 lines)

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
240  static func advance_search_waypoint(bee: Node2D) -> void
256  static func _perceive_flower(bee: Node2D) -> Node2D
267  static func perception_radius(bee: Node2D) -> float
273  static func _commit_to_flower(bee: Node2D, flower: Node2D) -> void
281  # --- patch memory and the search spiral ---------------------------
287  static func _remember_patch(bee: Node2D, position: Vector2) -> void
300  static func _pick_known_patch(bee: Node2D) -> Vector2
324  static func _spiral_point(bee: Node2D, anchor: Vector2, angle: float) -> Vector2
336  # --- choosing a flower --------------------------------------------
354  static func nearest_flower(bee: Node2D, strict: bool, radius: float, allow_full_scan: bool = true) -> Node2D
451  static func _weighted_flower_choice(bee: Node2D, nodes: Array, accept: Callable, radius: float) -> Node2D
489  static func flower_grid(bee: Node2D)
504  # --- inspecting, drinking and sheltering --------------------------
505  static func start_inspecting(bee: Node2D) -> void
510  static func inspect(bee: Node2D, delta: float) -> void
533  static func needs_a_drink(bee: Node2D) -> bool
541  static func drink_at_flower(bee: Node2D, delta: float) -> void
566  static func nectar_strength(_bee: Node2D) -> float
574  static func shelter(bee: Node2D, _delta: float) -> void
590  static func recall_for_rain(bee: Node2D) -> void
600  # --- skill-or-setting behaviour switches ---------------------------
605  static func adaptive_constancy_on() -> bool
609  static func tarsal_markers_on() -> bool
614  static func probabilistic_choice_on() -> bool
617  static func handling_experience_on() -> bool
624  static func record_species_visit(bee: Node2D, species: String) -> void
637  static func orientation_flight_on() -> bool
641  # --- accepting or rejecting a flower ------------------------------
642  static func worth_feeding(bee: Node2D, f: Node2D) -> bool
655  static func reject_flower(bee: Node2D) -> void
673  # --- collecting ---------------------------------------------------
674  static func start_collecting(bee: Node2D) -> void
747  static func _handling_experience_scale(bee: Node2D, species: String) -> float
756  static func collect(bee: Node2D, delta: float) -> void
805  static func finish_collecting(bee: Node2D) -> void
848  # --- entering the hive and depositing -----------------------------
852  static func enter_hive(bee: Node2D) -> void
879  static func approach_cell(bee: Node2D, cell: Node2D, delta: float) -> int
894  static func release_cell_slot(bee: Node2D) -> void
901  static func go_to_deposit_cell(bee: Node2D, delta: float) -> void
991  static func finish_depositing(bee: Node2D) -> void
1031 static func _after_delivery_state(bee: Node2D) -> int
1042 static func _resume_own_job_if_indoors(bee: Node2D) -> bool
1050 # --- scoring a trip -----------------------------------------------
1055 static func _score_trip(bee: Node2D) -> void
1133 # --- leaving the hive ---------------------------------------------
1134 static func go_to_exit(bee: Node2D, delta: float) -> void
1178 static func _entrance_wait_spot(bee: Node2D, side: int) -> Vector2
1190 static func _leave_hive_and_resume(bee: Node2D) -> void
1217 static func _send_to_scout_point(bee: Node2D) -> void
1228 # --- scouting -----------------------------------------------------
1234 static func start_scouting(bee: Node2D) -> void
1252 # --- waiting at the entrance --------------------------------------
1257 static func wait_at_entrance(bee: Node2D, delta: float) -> void
1363 # --- the recruitment dance ----------------------------------------
1371 static func _update_dance_eligibility(bee: Node2D) -> void
1394 static func leave_recruitment(bee: Node2D) -> void
1416 static func check_dance_proximity(bee: Node2D, _delta: float) -> void
1441 static func _start_dance(mentor: Node2D, seeker: Node2D) -> void
1461 static func dance(bee: Node2D, delta: float) -> void
1473 static func _end_dance(bee: Node2D) -> void
1495 static func _complete_dance(mentor: Node2D, seeker: Node2D) -> void
1522 # --- remote deposit -----------------------------------------------
1524 static func deposit_everything_remotely(bee: Node2D) -> void
```

## hive_cell.gd (1,484 lines)

One cell: contents, brood, honey ripening, how it draws.

```
25   # --- constants and colours ----------------------------------------
67   static func fill_frame(levels: Array, fraction: float) -> int
136  # --- cell state ---------------------------------------------------
194  # --- building state -----------------------------------------------
218  func effective_build_time() -> float
221  # --- designation and orders ---------------------------------------
263  # --- hatch settings -----------------------------------------------
286  # --- layout and display nodes -------------------------------------
334  # --- slots --------------------------------------------------------
348  # --- setup --------------------------------------------------------
350  func _ready() -> void
475  # --- overlay, selection and rings ---------------------------------
482  func set_overlay(mode: String) -> void
488  func _overlay_colour() -> Array
528  func set_selected(value: bool) -> void
540  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
551  func _set_outline_points(line: Line2D, size: float) -> void
562  func _silhouette_point_to_local(p: Vector2) -> Vector2
572  func _set_outline_points_cup(line: Line2D, size: float) -> void
595  func _apply_outline_points(line: Line2D, size: float) -> void
603  func _set_selection_ring_points() -> void
606  # --- per-frame update ---------------------------------------------
624  func _process(delta: float) -> void
645  # --- brood development --------------------------------------------
650  func _develop_brood(delta: float) -> void
671  func _health_factor() -> float
679  func _larva_dies() -> void
693  # --- index and display epochs -------------------------------------
699  func _invalidate_hive_index() -> void
709  func _invalidate_stock() -> void
723  func bump_display_epoch() -> void
726  # --- working positions --------------------------------------------
731  func claim_slot(bee: Node2D) -> int
742  func release_slot(bee: Node2D) -> void
749  func has_free_slot() -> bool
758  func slot_position(index: int) -> Vector2
770  # --- building -----------------------------------------------------
772  func start_as_site() -> void
777  func claim_builder(bee: Node2D) -> void
781  func release_builder(bee: Node2D) -> void
787  func add_build_progress(delta: float) -> void
798  func build_fraction() -> float
801  # --- contents -----------------------------------------------------
803  func is_empty() -> bool
808  func capacity_for(resource_type: String) -> float
816  func accepts(resource_type: String) -> bool
835  func is_nursery_cell() -> bool
838  func space_for(resource_type: String) -> float
860  func needs_eviction() -> bool
878  func add_resource(resource_type: String, requested: float) -> float
924  func nectar_age() -> float
936  func is_fermented() -> bool
944  func restore_bee_bread_seal() -> void
957  func return_ripe_bee_bread(requested: float) -> float
986  func is_bee_bread_sealed() -> bool
992  func is_ripe_bee_bread() -> bool
996  func bee_bread_ripen_fraction() -> float
1004 func take_resource(resource_type: String, requested: float) -> float
1040 func can_withdraw() -> bool
1045 func set_closed(value: bool) -> void
1052 func set_fill_then_close(value: bool) -> void
1061 func fill_fraction() -> float
1069 func set_designation(resource_type: String, explicit: bool = true) -> void
1077 # --- honey ---------------------------------------------------------
1079 func is_ripe_honey() -> bool
1083 func needs_fanning() -> bool
1088 func add_fanning_progress(delta: float) -> void
1098 func ripen_fraction() -> float
1101 # --- brood ---------------------------------------------------------
1103 func start_brood(as_gyne: bool = false, as_drone: bool = false) -> void
1117 func brood_kind_label() -> String
1127 func develop_time() -> float
1136 func feed_brood(seconds: float, on_honey: bool, on_bee_bread: bool = false) -> void
1143 func needs_feeding() -> bool
1147 func seconds_until_death() -> float
1152 # --- clearing a dead larva ------------------------------------------
1154 func needs_cleaning() -> bool
1160 func add_clean_progress(delta: float) -> bool
1166 func clean_fraction() -> float
1169 func brood_ready() -> bool
1172 func clear_cell() -> void
1188 # --- display ------------------------------------------------------
1193 func _resource_outline_colour(resource_type: String) -> Color
1209 func _refresh() -> void
1412 func _show_fill_art(sheet: String, frame: int) -> void
1425 func _show_cap(stage: int) -> void
1433 func _designation_tag() -> String
1457 func _priority_mark() -> String
1470 func _apply_fill_shading() -> void
1481 func development_percent() -> float
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

## challenge_runner.gd (1,244 lines)

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
845  # --- the queen's build site ---------------------------------------
846  func on_queen_build_site_chosen(hex: Vector2i) -> void
854  # --- gating the UI ------------------------------------------------
863  func _apply_stage_gate_to_ui() -> void
896  func _on_gate_unlocked(_key: String) -> void
902  func is_bee_command_locked(bee: Node2D) -> bool
905  # --- the opening tunnel -------------------------------------------
911  func _setup_opening_tunnel() -> void
951  func _drive_opening_mine() -> void
963  func _opening_tunnel_cleared() -> bool
971  # --- Challenge 1 forage effects and overflow ----------------------
979  func _drive_c1_forage_effects() -> void
1007 func discards_overflow(bee: Node2D) -> bool
1022 func announce_overflow_discard(focus_switch: bool = false) -> void
1044 func _drive_c1_pollen_cell_nectar_prompt(delta: float) -> void
1058 # --- the new worker's greeting ------------------------------------
1064 func on_worker_hatched(bee: Node2D) -> void
1086 func _drive_greeting(delta: float) -> void
1100 # --- goal checks --------------------------------------------------
1123 func _goal_met(goal: String) -> bool
1135 func _goal_check_entrance_tunnel_cleared() -> bool
1138 func _goal_check_queen_reached_cavity() -> bool
1143 func _goal_check_queen_selected() -> bool
1146 func _goal_check_hive_points_visited() -> bool
1149 func _goal_check_nectar_target() -> bool
1155 func _goal_check_pollen_target() -> bool
1161 func _goal_check_queen_reached_meadow() -> bool
1164 func _goal_check_meadow_points_visited() -> bool
1167 func _goal_check_first_flower_collected() -> bool
1170 func _goal_check_second_flower_collected() -> bool
1173 func _goal_check_harvest_deposited() -> bool
1176 func _goal_check_new_bee_selected() -> bool
1182 func _goal_check_new_bee_left_hive() -> bool
1185 func _goal_check_complete() -> bool
1188 # --- Challenge 2 ---------------------------------------------
1189 func _goal_check_nectar_stabilized() -> bool
1196 func _goal_check_persistent_designation_used() -> bool
1204 func _goal_check_comb_worker_building() -> bool
1208 func _goal_check_miner_expansion() -> bool
1215 # --- goal progress readouts ---------------------------------------
1221 func _goal_progress(goal: String) -> Dictionary
1234 func _custom_goal_progress(method: String) -> Dictionary
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
600  func _rebuild_triggers() -> void
635  func _on_end_run_pressed() -> void
646  func _refresh_developer_row() -> void
673  func _make_run_availability_button() -> Button
682  func _on_run_availability_pressed() -> void
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

## hive.gd (1,201 lines)

The comb as a whole: cells, navigation, finding a cell.

```
53   func add_entrance_mentor(bee: Node2D) -> void
57   func remove_entrance_mentor(bee: Node2D) -> void
74   func add_dance_eligible_mentor(bee: Node2D) -> void
78   func remove_dance_eligible_mentor(bee: Node2D) -> void
81   func add_dance_eligible_seeker(bee: Node2D) -> void
85   func remove_dance_eligible_seeker(bee: Node2D) -> void
88   func record_collection(resource_type: String, amount: float) -> void
94   func record_birth() -> void
97   # --- cell index ---------------------------------------------------
116  func _content_index() -> Dictionary
153  func invalidate_index() -> void
156  func cells_holding(content: String) -> Array
173  func invalidate_stock() -> void
176  func _stock() -> Dictionary
206  func register_tile(hex: Vector2i, node: Node2D) -> void
212  func invalidate_mining_work() -> void
216  func _advance_mining_work_epoch() -> void
219  func tile_is_free(hex: Vector2i) -> bool
224  func tile_is_interior(hex: Vector2i) -> bool
229  func cell_at_tile(hex: Vector2i) -> Node2D
235  func _ready() -> void
254  func deposit(resource_type: String, amount: float) -> float
273  func take(resource_type: String, amount: float) -> float
288  func take_energy(energy_wanted: float) -> float
301  func total(resource_type: String) -> float
307  func total_sealed() -> float
311  func total_honey() -> float
314  # --- finding cells ------------------------------------------------
327  func find_cell_for(resource_type: String, except: Node2D = null) -> Node2D
351  func find_designated_cell_for(resource_type: String, except: Node2D = null) -> Node2D
389  func find_empty_cell() -> Node2D
435  func _lay_by_priority(pool: Array) -> Node2D
466  func _tier_weights() -> Array
481  func record_lay(cell: Node2D) -> void
495  func zone_summary() -> Dictionary
525  func brood_stage_counts() -> Dictionary
543  func find_food_cell(except: Node2D = null) -> Node2D
573  func senses_fermentation() -> bool
579  func avoids_as_sour(cell: Node2D) -> bool
582  func has_room_for_egg() -> bool
585  func find_cell_with(resource_type: String) -> Node2D
601  func find_honey_source(from: Vector2) -> Node2D
622  func find_brood_nectar() -> Node2D
634  func find_brood_cell() -> Node2D
649  func find_cell_needing_fanning() -> Node2D
657  func find_honey_target() -> Node2D
666  func find_bee_bread_target(except: Node2D = null) -> Node2D
675  func can_take(resource_type: String, amount: float) -> bool
685  func find_unfinished_cell() -> Node2D
694  func find_cell_needing_cleaning() -> Node2D
698  func find_cell_needing_eviction() -> Node2D
706  func has_gyne_brood() -> bool
714  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
717  # --- bodies -------------------------------------------------------
728  func add_body(point: Vector2, died_at: float) -> Node2D
742  func remove_body(body: Node2D) -> void
749  func find_body_to_clear() -> Node2D
758  func clear_bodies() -> void
763  func _free_body(body: Node2D) -> void
771  # --- growing the comb ---------------------------------------------
805  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
839  func set_keep_clear(hex: Vector2i, value: bool) -> void
845  func is_keep_clear(hex: Vector2i) -> bool
852  func can_build_on(hex: Vector2i) -> bool
855  func _can_build_on(hex: Vector2i) -> bool
858  func _start_site_at(hex: Vector2i) -> Node2D
880  func create_cell_site_at(hex: Vector2i) -> Node2D
885  # --- navigation ---------------------------------------------------
896  func build_navigation() -> void
937  func _is_solid(hex: Vector2i) -> bool
943  func _tile_cost(hex: Vector2i) -> float
946  func tile_is_walkable(hex: Vector2i) -> bool
955  func nearest_walkable_point(point: Vector2) -> Vector2
982  func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
1016 func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
1040 func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
1054 # --- mining -------------------------------------------------------
1063 func refresh_edge_flags() -> void
1085 func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
1113 func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
1137 func _is_markable_block(node) -> bool
1144 func mine_stand_hex(block: Node2D)
1167 func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
1189 func remove_block(block: Node2D, floor_maker: Callable) -> void
1200 func announce() -> void
```

## game_config.gd (1,005 lines)

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
642  # --- warnings ---
651  # --- honey ---
695  # --- comb building ---
715  # --- hive geometry ---
744  # --- bee life ---
749  # --- bee individuality ---
828  # --- the rival colony ---
877  # --- seasons ---
909  # --- disease ---
948  # --- gynes leaving ---
960  # --- nuptial flights ---
968  # --- winter ---
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

## input_selection.gd (716 lines)

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
425  func _place_mine_target(global_point: Vector2, keep_adding: bool) -> void
436  func _place_keep_clear(global_point: Vector2, _keep_adding: bool) -> void
441  func _place_home_cell(global_point: Vector2, _keep_adding: bool = false) -> void
452  func _on_cell_empty_by_bee_requested(cell: Node2D) -> void
461  func _place_home_cell_all(global_point: Vector2, _keep_adding: bool = false) -> void
469  func _place_mine_home(global_point: Vector2, _keep_adding: bool = false) -> void
477  func _place_forage_start(global_point: Vector2, _keep_adding: bool = false) -> void
483  func _place_floral_preference(global_point: Vector2, _keep_adding: bool = false) -> void
505  func _issue_command(world_point: Vector2) -> void
573  func _prune_invalid_selected_bees() -> void
582  func _show_click_marker(world_point: Vector2) -> void
588  func _on_role_selection_requested(role: int, focus: String) -> void
604  func _ensure_hive_view() -> void
609  func _draw_selection_box() -> void
626  func _draw_hive_orders() -> void
659  func _draw_build_hover() -> void
668  func _draw_home_marker(point: Vector2) -> void
674  func _build_queue_points(bee: Node2D) -> Array
680  func _mine_queue_points(bee: Node2D) -> Array
687  func _draw_order_chain(bee: Node2D, points: Array, colour: Color) -> void
697  func _draw_tile_outline(centre: Vector2, colour: Color, width: float, dashed: bool) -> void
706  func _tile_centre(hex: Vector2i) -> Vector2
711  func _draw_start_point_marker(point: Vector2) -> void
```
