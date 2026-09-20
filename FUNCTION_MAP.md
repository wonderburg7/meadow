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

## hud.gd (3,314 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
24   # --- signals ------------------------------------------------------
108  # --- role controls ------------------------------------------------
120  static func hatch_options() -> Array
166  static func mode_command(role_id: int, mode_key: String) -> String
169  # --- shared layout constants --------------------------------------
205  # --- fields -------------------------------------------------------
502  # --- problem strip ------------------------------------------------
511  func _signal_color(severity: int) -> Color
518  # --- _ready and construction --------------------------------------
523  func _ready() -> void
577  func _on_viewport_size_changed() -> void
582  func _build_stage_marker_arrow() -> void
600  func set_stage_marker(global_position: Vector2, visible: bool, in_hive: bool) -> void
605  func _make_label(pos: Vector2, variation: String = "Body") -> Label
613  func _info(text: String) -> Button
616  func _with_info(control: Control, tip: String) -> HBoxContainer
621  func _style_button(button: BaseButton) -> BaseButton
626  # --- speed controls -----------------------------------------------
650  func _build_top_right_bar() -> void
759  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
795  func _apply_interface_label_visibility() -> void
801  # --- Challenge goal readout ---------------------------------------
806  func _build_goal_shelf() -> void
873  func set_settings_button_width(width: float) -> void
887  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
902  func set_speed_display(speed_scale: float) -> void
907  # --- bottom row ---------------------------------------------------
912  func _build_selection_panel() -> void
1022 func _build_favourite_star() -> Control
1053 func _set_favourite_star(bee) -> void
1081 func _field_control(field_name: String) -> Control
1095 func _build_selection_cog() -> Control
1123 func _set_summary_cog_kind(kind: String) -> void
1135 func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
1155 func _apply_selection_field_visibility() -> void
1184 func _resize_selection_panel_to_content() -> void
1192 # --- command tray -------------------------------------------------
1204 func _build_command_tray() -> void
1304 func _build_tray_column(title: String) -> Array
1331 # --- cell popup ---------------------------------------------------
1347 func _build_cell_group(parent: VBoxContainer) -> void
1441 func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer
1469 func _build_priority_controls(column: VBoxContainer) -> void
1506 func _build_raises_controls(column: VBoxContainer) -> void
1578 func _build_closing_controls(column: VBoxContainer) -> void
1618 func _build_empty_controls(column: VBoxContainer) -> void
1680 func _make_hatch_menu(entry: Dictionary) -> Control
1709 func _fill_hatch_menu(popup: PopupMenu, role_value: int, options: Array) -> int
1721 func _build_warning_banner() -> void
1757 func show_warning(text: String, key: String = "", min_gap: float = 0.0, severity: int = 0) -> void
1773 func _show_warning_now(text: String, severity: int) -> void
1781 func _dismiss_warning() -> void
1786 func set_warnings_muted(value: bool) -> void
1800 func show_object_summary(kind: String, data) -> void
1824 func _refresh_flower_summary() -> void
1860 func _show_obstacle_summary(obstacle: Node2D) -> void
1866 func _show_soil_summary(count: int, reachable: int) -> void
1882 func _show_death_summary(info: Dictionary) -> void
1904 func show_cell_popup(cell: Node2D, count: int = 1) -> void
1925 func _refresh_cell_popup() -> void
2035 func _apply_cell_popup_gating() -> void
2058 func _light_current_options() -> void
2076 func _set_lit(key: String, lit: bool) -> void
2087 func _process(_delta: float) -> void
2119 func _stage_marker_screen_position() -> Vector2
2123 func _update_stage_marker_arrow() -> void
2156 func _refresh_marker_exclusion_rects(viewport_size: Vector2) -> void
2167 func _append_marker_panel_exclusion(panel: Control, owner_rect: Rect2) -> void
2172 func _slide_arrow_along_edge(edge_point: Vector2, edge_bounds: Rect2) -> Vector2
2189 func _marker_arrow_obscured(point: Vector2) -> bool
2195 func _request_designation(type: String) -> void
2200 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
2205 func _request_empty(method: String) -> void
2210 func _request_priority(tier: int) -> void
2215 func _request_close(closed: bool) -> void
2220 func _request_fill_close() -> void
2225 # --- discard warning ----------------------------------------------
2231 func _build_discard_dialog() -> void
2246 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
2255 func _on_discard_confirmed() -> void
2258 func _on_discard_custom_action(action: StringName) -> void
2265 func _apply_discard() -> void
2273 # --- readouts -----------------------------------------------------
2278 func update_day(day: int, note: String = "") -> void
2288 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
2297 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
2303 func update_comb(text: String) -> void
2307 func update_energy(mean_fraction: float) -> void
2314 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
2325 func update_recruit_gap(text: String) -> void
2338 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
2344 func update_signals(lines: Array) -> void
2352 func _refresh_corner() -> void
2434 func corner_bottom() -> float
2440 func selection_panel_top() -> float
2450 func pinned_stats_changed() -> void
2459 func refresh_speed_visibility() -> void
2466 func refresh_corner() -> void
2469 func update_selection(bees: Array) -> void
2502 func _selection_has_command_lock(bees: Array) -> bool
2523 static func _detach_and_free_children(container: Node) -> void
2536 func _rebuild_role_controls(bees: Array) -> void
2586 func _build_queen_build_row(column: VBoxContainer) -> void
2600 func _build_follow_control(bees: Array, first) -> void
2615 func _build_job_row(common_role: int, any_queen: bool) -> void
2647 func _build_doing_row(common_role: int, first) -> void
2673 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2688 func _build_orders_row(common_role: int, first) -> void
2735 func _build_restock_row(first) -> void
2770 func _build_fallback_row(common_role: int, first) -> void
2820 func _secondary_items() -> Array
2836 func _column_row(parent: Container) -> HFlowContainer
2844 func _labelled_row(title: String) -> HFlowContainer
2863 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2875 func _action_button(label: String, action: Callable, tip: String) -> Control
2884 func _current_role_marker(label: String) -> Control
2899 func _common_role(bees: Array) -> int
2916 func _common_working_role(bees: Array) -> int
2934 func _make_role_menu(label: String, tip: String, items: Array, node_name: String = "") -> Control
2955 func _refresh_selection_text() -> void
3054 func _apply_selection_tray_width() -> void
3105 func _match_summary_header_button_heights() -> void
3123 func _tray_column_share(inner_width: float) -> float
3132 func _apply_even_column_widths(wrappers: Array) -> void
3160 func _update_command_tray_width() -> void
3181 func _resize_command_tray() -> void
3216 func _resettle_command_tray(generation: int, previous_content_min_y: float, stable_streak: int, pass_count: int) -> void
3229 func set_winter_button_visible(value: bool) -> void
3235 func set_view_label(in_hive: bool) -> void
3241 func set_colony_button_visible(value: bool) -> void
3247 func set_nursery_button_visible(value: bool) -> void
3253 func set_view_button_visible(value: bool) -> void
3259 func set_foraging_button_visible(value: bool) -> void
3266 func set_allowed_role_keys(keys: Array) -> void
3276 func set_command_locked_bees(bees: Array) -> void
3281 func set_allowed_mode_keys(keys: Array) -> void
3291 func set_allowed_designation_keys(keys: Array) -> void
3296 func set_hatch_lock_visible(value: bool) -> void
3301 func set_soil_marking_visible(value: bool) -> void
3311 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (2,369 lines)

A bee's dispatch loop, player commands, display text, vars.

```
256  func current_working_role() -> int
605  func _ready() -> void
753  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
795  func _roll_fact() -> void
809  func _default_state_for_role() -> int
831  func _base_colour() -> Color
842  func _tinted(c: Color) -> Color
857  func _apply_stats() -> void
883  func trait_text() -> String
892  func _update_role_marker() -> void
911  # --- how often a bee thinks ---------------------------------------
943  func _process(delta: float) -> void
1216 # --- life support -------------------------------------------------
1218 # --- eating -------------------------------------------------------
1220 # --- stall watchdog -----------------------------------------------
1226 func _reset_stall_watch() -> void
1229 # --- foraging -----------------------------------------------------
1231 # --- entering and leaving the hive --------------------------------
1233 # --- nursery work -------------------------------------------------
1235 # --- royal jelly ---------------------------------------------------
1237 # --- idle work dispatch --------------------------------------------
1251 func _apply_pending_role() -> bool
1263 func _is_busy() -> bool
1269 func _idle_dispatch() -> void
1295 func _maybe_break_off_secondary() -> void
1319 func _try_role_work(r: int) -> bool
1342 static func _build_actions_by_role() -> Dictionary
1352 func _action_mode_for_role(r: int) -> String
1361 # --- building -----------------------------------------------------
1363 # --- keeping cells topped up ---------------------------------------
1392 func set_restock_targets(cells: Array, resource: String) -> void
1395 func set_restock_sources(cells: Array, allowed: bool) -> void
1398 func clear_restock() -> void
1401 func has_restock_orders() -> bool
1403 # --- mining -------------------------------------------------------
1405 # --- honey making -------------------------------------------------
1407 # --- egg laying (queen only) --------------------------------------
1409 # --- player commands ----------------------------------------------
1419 func command_move_to(world_point: Vector2) -> void
1439 func command_move_through_entrance(world_point: Vector2, target_in_hive: bool) -> void
1451 func command_exit_hive() -> void
1461 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
1469 func has_forage_start_point() -> bool
1472 func set_preferred_species(species: String) -> void
1485 func set_manual_build_target(hex: Vector2i) -> void
1493 func queue_build_target(hex: Vector2i) -> void
1500 func clear_build_queue() -> void
1506 func _take_next_build_target() -> bool
1519 func set_mine_target(block: Node2D) -> void
1526 func queue_mine_target(block: Node2D) -> void
1534 func clear_mine_queue() -> void
1541 func _next_queued_block() -> Node2D
1549 func set_home_hex(hex: Vector2i) -> void
1558 func set_mine_home_hex(hex: Vector2i) -> void
1564 func _mine_reference_point() -> Vector2
1579 func command_collect_from(flower: Node2D) -> void
1595 func command_collect_from_after_exit(flower: Node2D) -> void
1608 func command_return_and_deposit() -> void
1618 func command_return_only() -> void
1624 func command_deposit_at(cell: Node2D) -> void
1637 func command_empty_cell(cell: Node2D) -> void
1649 func command_deposit_at_after_enter(cell: Node2D) -> void
1657 func resume_pending_zone_command() -> bool
1676 func _clear_pending_zone_command() -> void
1681 func set_focus(type: String) -> void
1738 func _has_deliverable_target() -> bool
1744 func set_secondary_role(new_role: int) -> void
1747 func can_take_role(new_role: int) -> bool
1757 func set_role(new_role: int) -> void
1774 func _apply_role(new_role: int) -> void
1814 func _release_everything() -> void
1831 func release_flower_reference(flower: Node2D) -> void
1837 func set_selected(value: bool) -> void
1841 # --- display ------------------------------------------------------
1843 func role_letter() -> String
1872 func challenge_vocabulary_limited() -> bool
1885 func idle_reason() -> String
1938 func task_description() -> String
2085 func _idle_backup_note() -> String
2095 func role_name_text() -> String
2121 func nurse_mode_name() -> String
2130 func architect_mode_name() -> String
2136 func carrying_text() -> String
2157 func age_days() -> float
2165 func leave_to_found_colony() -> void
2178 func days_remaining() -> float
2190 func _update_label() -> void
2210 func _update_alarm_ring() -> void
2221 func _update_heading_marker() -> void
2235 func _update_search_ring() -> void
2258 func _update_dance_ring() -> void
2291 func _update_wander_flight(delta: float) -> void
2322 func _update_dance_circle(delta: float) -> void
2336 func _terrain_speed_factor() -> float
2345 func _is_inside_hive() -> bool
2348 # --- getting round things in the meadow ---------------------------
2368 func clear_navigation_state() -> void
```

## settings_catalogue.gd (1,421 lines)

Every setting's key, label, range and tip, plus the read/write and Prerequisites-cascade functions the window is a view of.

```
1314 static func setting_get(key: String)
1317 static func setting_set(key: String, value) -> void
1340 static func reset_config_to_defaults() -> void
1352 static func reset_config_keys(keys: Array) -> void
1366 static func apply_setting(key: String, value) -> void
1381 static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1399 static func _cascade_dependents_off_static(key: String) -> Array[String]
1413 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
```

## bee_foraging.gd (1,381 lines)

The forager's search, scouting, recruitment and species-preference
behaviour.

```
38   static func autonomous_state(bee: Node2D, next: int) -> int
42   static func max_capacity(bee: Node2D) -> float
46   static func collection_rate(bee: Node2D) -> float
54   static func _random_point_near_hive(bee: Node2D) -> Vector2
66   static func _jittered_point(base: Vector2, radius: float) -> Vector2
77   static func take_orientation_flight(bee: Node2D) -> void
94   static func seek_flower(bee: Node2D) -> void
131  static func start_seek_flower(bee: Node2D) -> bool
146  static func _walk_out_if_indoors(bee: Node2D) -> bool
155  static func _start_searching(bee: Node2D) -> void
182  static func search_for_flower(bee: Node2D, delta: float) -> void
229  static func advance_search_waypoint(bee: Node2D) -> void
245  static func _perceive_flower(bee: Node2D) -> Node2D
252  static func _commit_to_flower(bee: Node2D, flower: Node2D) -> void
265  static func _remember_patch(bee: Node2D, position: Vector2) -> void
278  static func _pick_known_patch(bee: Node2D) -> Vector2
302  static func _spiral_point(bee: Node2D, anchor: Vector2, angle: float) -> Vector2
331  static func nearest_flower(bee: Node2D, strict: bool, radius: float, allow_full_scan: bool = true) -> Node2D
428  static func _weighted_flower_choice(bee: Node2D, nodes: Array, accept: Callable, radius: float) -> Node2D
466  static func flower_grid(bee: Node2D)
481  static func start_inspecting(bee: Node2D) -> void
486  static func inspect(bee: Node2D, delta: float) -> void
509  static func needs_a_drink(bee: Node2D) -> bool
517  static func drink_at_flower(bee: Node2D, delta: float) -> void
542  static func nectar_strength(_bee: Node2D) -> float
550  static func shelter(bee: Node2D, _delta: float) -> void
555  static func worth_feeding(bee: Node2D, f: Node2D) -> bool
568  static func reject_flower(bee: Node2D) -> void
586  static func start_collecting(bee: Node2D) -> void
659  static func _handling_experience_scale(bee: Node2D, species: String) -> float
668  static func collect(bee: Node2D, delta: float) -> void
717  static func finish_collecting(bee: Node2D) -> void
759  static func enter_hive(bee: Node2D) -> void
786  static func approach_cell(bee: Node2D, cell: Node2D, delta: float) -> int
801  static func release_cell_slot(bee: Node2D) -> void
808  static func go_to_deposit_cell(bee: Node2D, delta: float) -> void
895  static func finish_depositing(bee: Node2D) -> void
936  static func _score_trip(bee: Node2D) -> void
1014 static func go_to_exit(bee: Node2D, delta: float) -> void
1057 static func _entrance_wait_spot(bee: Node2D, side: int) -> Vector2
1069 static func _leave_hive_and_resume(bee: Node2D) -> void
1096 static func _send_to_scout_point(bee: Node2D) -> void
1112 static func start_scouting(bee: Node2D) -> void
1134 static func wait_at_entrance(bee: Node2D, delta: float) -> void
1245 static func _update_dance_eligibility(bee: Node2D) -> void
1269 static func check_dance_proximity(bee: Node2D, _delta: float) -> void
1294 static func _start_dance(mentor: Node2D, seeker: Node2D) -> void
1314 static func dance(bee: Node2D, delta: float) -> void
1326 static func _end_dance(bee: Node2D) -> void
1348 static func _complete_dance(mentor: Node2D, seeker: Node2D) -> void
1376 static func deposit_everything_remotely(bee: Node2D) -> void
```

## scenario_actions.gd (1,338 lines)

The headless verbs, `when` clauses and layout assertions.

```
47   static func run_pending(main: Node2D, actions: Array) -> void
84   static func sample_comb_build_sites(main: Node2D) -> void
128  static func log_unresolved(actions: Array) -> void
145  static func _do_settle(action: Dictionary) -> bool
158  static func _do_wait(action: Dictionary) -> bool
173  static func _assert_window_closed(main: Node2D, action: Dictionary) -> bool
186  static func _sample_queen_watch(main: Node2D) -> void
193  static func _execute(main: Node2D, action: Dictionary) -> void
243  # --- triggers -----------------------------------------------------
253  static func _when_met(main: Node2D, when: Dictionary) -> bool
294  static func _legacy_when_spec(main: Node2D, when: Dictionary) -> Dictionary
345  # --- selectors ------------------------------------------------------
349  static func _resolve_bees(main: Node2D, target: Dictionary) -> Array
381  static func _resolve_cell_ref(main: Node2D, ref: Dictionary) -> Node2D
388  static func _resolve_cell(main: Node2D, hex: Array) -> Node2D
398  static func _resolve_soil_block(main: Node2D, hex: Array) -> Node2D
408  # --- verbs ------------------------------------------------------------
425  static func _do_assign_role(main: Node2D, action: Dictionary) -> void
481  static func _do_designate_cell(main: Node2D, action: Dictionary) -> void
505  static func _do_queue_build(main: Node2D, action: Dictionary) -> void
531  static func _do_queue_mine(main: Node2D, action: Dictionary) -> void
556  static func _do_request_placement_tool(main: Node2D, action: Dictionary) -> void
568  static func _do_click_world(main: Node2D, action: Dictionary) -> void
594  static func _do_set_config(_main: Node2D, action: Dictionary) -> void
608  static func _do_hatch_role(main: Node2D, action: Dictionary) -> void
625  static func _do_set_restock_order(main: Node2D, action: Dictionary) -> void
671  static func _do_select_bees(main: Node2D, action: Dictionary) -> void
702  static func _do_select_soil(main: Node2D, action: Dictionary) -> void
728  static func _do_select_cell(main: Node2D, action: Dictionary) -> void
751  static func _do_open_window(main: Node2D, action: Dictionary) -> void
795  static func _do_close_window(main: Node2D, action: Dictionary) -> void
808  static func _do_viewport_size(main: Node2D, action: Dictionary) -> void
821  static func _do_show_gallerin_prompt(main: Node2D, action: Dictionary) -> void
837  static func _do_retreat_challenge_stage(main: Node2D, action: Dictionary) -> void
856  static func _do_advance_challenge_stage(main: Node2D, action: Dictionary) -> void
882  static func _do_set_queen_load(main: Node2D, action: Dictionary) -> void
914  static func _do_set_cell_contents(main: Node2D, action: Dictionary) -> void
938  static func _do_empty_cell(main: Node2D, action: Dictionary) -> void
952  static func _do_watch_queen_states(main: Node2D, action: Dictionary) -> void
965  # --- assertion checks -------------------------------------------------
975  static func _do_assert(main: Node2D, action: Dictionary) -> bool
985  static func _evaluate_assert_condition(main: Node2D, condition: Dictionary) -> Dictionary
1002 static func _queen_summary(main: Node2D, condition: Dictionary) -> String
1030 static func _check_panel_rect(main: Node2D, condition: Dictionary) -> Dictionary
1121 static func _resolve_named_panel(main: Node2D, name: String) -> Control
1135 static func _game_panel(main: Node2D, key: String) -> GamePanel
1155 static func _check_control_rect(main: Node2D, condition: Dictionary) -> Dictionary
1202 static func _label_leading(control: Control) -> Dictionary
1216 static func _check_even_columns(main: Node2D, condition: Dictionary) -> Dictionary
1256 static func _check_no_collapsed_controls(main: Node2D, condition: Dictionary) -> Dictionary
1273 static func _check_no_empty_labels(main: Node2D, condition: Dictionary) -> Dictionary
1284 static func _collect_empty_labels(node: Node, out: Array) -> void
1290 static func _collect_collapsed_controls(node: Node, out: Array) -> void
1310 static func _resolve_scoped_path(main: Node2D, path: String) -> Node
1337 static func _log(do: String, target_desc: String, result: String, reason: String) -> void
```

## challenge_runner.gd (1,234 lines)

The stage machine, goal checks and stage effects.

```
162  func _ready() -> void
165  func _reset_c2_pollen_rescue() -> void
168  func _stages() -> Array
173  func current_stage_instruction() -> String
180  func current_stage_id() -> String
188  func current_stage_goal_text() -> String
193  func can_debug_retreat_stage() -> bool
196  func can_debug_advance_stage() -> bool
205  func run_skill_grants() -> Array
208  func run_skill_bans() -> Array
211  func run_skill_delays() -> Dictionary
214  func start() -> void
294  func _process(delta: float) -> void
333  func _should_check_goal(goal_id: String, goal_tick_due: bool) -> bool
355  func _check_c2_failure() -> void
415  func _c2_index(stage_id: String) -> int
425  func _stage_unlock_keys(entries: Array) -> Array
446  func _queen_allowed_role_ids(entries: Array) -> Array
454  func _enter_stage() -> void
518  func _built_cell_count() -> int
527  func _brood_cell_count() -> int
537  func _hive_inspection_points() -> Array
551  func _meadow_inspection_points() -> Array
563  func _begin_ordered_visit(points: Array, marker_parent: Node2D) -> void
569  func _clear_ordered_visit() -> void
574  func _ordered_visit_complete(traveller: Node2D) -> bool
587  func _show_current_visit_point() -> void
602  func _update_marker(stage_id: String) -> void
640  func _set_marker_visible(value: bool) -> void
664  func _publish_marker_to_hud() -> void
675  func _show_goal(stage: Dictionary) -> void
682  func _advance() -> void
697  func _leave_stage() -> Dictionary
707  func _run_stage_effects(effects: Array) -> void
745  func debug_advance_stage() -> void
762  func debug_retreat_stage() -> void
772  func _complete() -> void
831  func on_queen_build_site_chosen(hex: Vector2i) -> void
849  func _apply_stage_gate_to_ui() -> void
901  func is_bee_command_locked(bee: Node2D) -> bool
909  func _setup_opening_tunnel() -> void
949  func _drive_opening_mine() -> void
961  func _opening_tunnel_cleared() -> bool
976  func _drive_c1_forage_effects() -> void
1004 func discards_overflow(bee: Node2D) -> bool
1019 func announce_overflow_discard(focus_switch: bool = false) -> void
1041 func _drive_c1_pollen_cell_nectar_prompt(delta: float) -> void
1060 func on_worker_hatched(bee: Node2D) -> void
1082 func _drive_greeting(delta: float) -> void
1118 func _goal_met(goal: String) -> bool
1130 func _goal_check_entrance_tunnel_cleared() -> bool
1133 func _goal_check_queen_reached_cavity() -> bool
1138 func _goal_check_queen_selected() -> bool
1141 func _goal_check_hive_points_visited() -> bool
1144 func _goal_check_nectar_target() -> bool
1150 func _goal_check_pollen_target() -> bool
1156 func _goal_check_queen_reached_meadow() -> bool
1159 func _goal_check_meadow_points_visited() -> bool
1162 func _goal_check_first_flower_collected() -> bool
1165 func _goal_check_second_flower_collected() -> bool
1168 func _goal_check_harvest_deposited() -> bool
1171 func _goal_check_new_bee_selected() -> bool
1177 func _goal_check_new_bee_left_hive() -> bool
1180 func _goal_check_complete() -> bool
1183 # --- Challenge 2 ---------------------------------------------
1184 func _goal_check_nectar_stabilized() -> bool
1191 func _goal_check_persistent_designation_used() -> bool
1199 func _goal_check_comb_worker_building() -> bool
1203 func _goal_check_miner_expansion() -> bool
1215 func _goal_progress(goal: String) -> Dictionary
1224 func _custom_goal_progress(method: String) -> Dictionary
```

## main.gd (1,181 lines)

Per-frame entry point, everything not yet split out of main.

```
37   # --- signals ------------------------------------------------------
51   # --- preloads and boot constants ----------------------------------
93   # --- delegate systems ---------------------------------------------
122  # --- world and meadow constants -----------------------------------
183  # --- state --------------------------------------------------------
326  # --- _ready and construction --------------------------------------
327  func _ready() -> void
575  # --- public surface other scripts call directly -------------------
582  func is_on_screen(node: Node2D) -> bool
585  func hive_entrance_inside() -> Vector2
588  func entrance_wait_point(side: int) -> Vector2
591  func move_bee_into_hive(bee: Node2D) -> void
594  func move_bee_out_of_hive(bee: Node2D) -> void
597  func mark_death(bee: Node2D) -> void
605  func _on_bee_died(bee: Node2D) -> void
609  func finish_mining(block: Node2D) -> void
612  func save_run() -> void
615  func begin_winter_countdown() -> void
618  # --- per-frame ----------------------------------------------------
628  func _process(delta: float) -> void
710  # --- the frame rate readout ----------------------------------------
729  func _sample_fps() -> void
752  func _reseed_meadow(delta: float) -> void
767  func _hatch_ready_brood() -> void
799  func _advance_weather(delta: float) -> void
829  func _apply_rain_overlay() -> void
844  func _check_for_loss() -> void
866  func _check_colony_energy(delta: float) -> void
897  func invalidate_population() -> void
908  func _role_counts(bees = null) -> Dictionary
925  func _update_population_readout(bees = null) -> void
937  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
943  func _prune_selection() -> void
956  func _on_restart_after_loss() -> void
962  func _on_level_chosen(level: int) -> void
975  func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
993  func _apply_scenario_boot_arg() -> void
1114 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1154 func _is_whole_number(value: Variant) -> bool
1168 func _end_scenario_run(outcome: String) -> void
```

## diagnostic_log.gd (1,163 lines)

The session JSONL writer, counters and capture profiles.

```
125  func _ready() -> void
133  func _notification(what: int) -> void
138  func start_session() -> void
204  func log_death(bee: Node2D) -> void
237  func log_crab_spider_event(bee: Node2D, flower: Node2D, outcome: String) -> void
261  func log_recruitment_match(seeker: Node2D, mentor: Node2D, via: String = "queue") -> void
294  func log_recruitment_followup(bee: Node2D, trip_index: int, trip_rate: float) -> void
316  func count_recruit_partner_overlap() -> void
326  func log_forager_settled(bee: Node2D) -> void
344  func log_orientation_flight(bee: Node2D) -> void
360  func count_flower_visit(flower: Node2D) -> void
369  func record_handling_visit(species: String, prior_experience: int, seconds: float) -> void
383  func count_forager_delivery(amount: float) -> void
390  func count_flower_senescence() -> void
397  func count_flower_senescence_loss(nectar: float, pollen: float) -> void
402  func _experience_bucket(prior_experience: int) -> String
414  func count_tarsal_mark() -> void
423  func count_tarsal_rejection() -> void
434  func log_stall_recovery(bee: Node2D, goal: Vector2) -> void
463  func log_build_target(bee: Node2D, cell: Node2D, transition: String, reason: String,
488  func log_forager_return(bee: Node2D, phase: String, required_energy: float) -> void
498  func log_flight_start_resolved(bee: Node2D, source: String, requested: Vector2, resolved: Dictionary) -> void
510  func _nearby_obstacle_identity(bee: Node2D) -> String
533  func log_scouting_settled(bee: Node2D) -> void
550  func count_brood_feed() -> void
557  func count_brood_hatch(role: int, mode: String) -> void
564  func count_jelly_batch() -> void
569  func count_larval_death() -> void
575  func count_cell_completed() -> void
580  func cell_completed_count() -> int
586  func count_cell_cleaned() -> void
593  func count_cell_evicted() -> void
599  func count_cell_restocked() -> void
605  func count_block_mined() -> void
611  func count_honey_batch_deposited() -> void
617  func count_cell_ripened() -> void
625  func log_action(do: String, target_desc: String, result: String, reason: String) -> void
641  func log_command_issue(selected_count: int, commandable_count: int, branch: String,
670  func log_selection_panels_hidden(source: String, shown_count: int, selected_count: int) -> void
688  func event_count(type: String, subtype: String = "") -> int
735  func tick(delta: float, world: Node2D) -> void
769  func end_session(outcome: String) -> void
826  func session_path() -> String
830  func set_queen_alive(alive: bool) -> void
834  func configure_scenario_diagnostics(raw: Variant) -> bool
843  func configure_performance_capture(config: Dictionary) -> void
847  func effective_diagnostics() -> Dictionary
853  func _snapshot_interval() -> float
866  func _selected_snapshot(world: Node2D) -> Dictionary
872  # --- building entries -----------------------------------------------
876  func _config_snapshot() -> Dictionary
884  func _snapshot(world: Node2D) -> Dictionary
1051 func _flower_season_counts(world: Node2D) -> Dictionary
1077 func _performance_snapshot(world: Node2D) -> Dictionary
1097 func _rate(world: Node2D, key: String) -> float
1112 func _current_day() -> int
1116 func _prune_old_sessions() -> void
1134 func _write(entry: Dictionary) -> void
1143 func _capture_entry(entry: Dictionary) -> bool
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

## debug_panel.gd (1,000 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
68   func _style_button(button: BaseButton) -> BaseButton
73   func _ready() -> void
187  func _apply_panel_width() -> void
192  func _report_settings_button_width() -> void
197  func _rows_in(category: String) -> Array
219  func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
250  func _set_open(header: Button, body: Control, label: String, open: bool) -> void
258  func open_to_categories(categories: Array) -> void
278  func collapse_all() -> void
286  func _make_section(category: String, entries: Array, start_open: bool) -> Control
346  func _make_challenge_stage_navigation() -> Control
384  func _process(_delta: float) -> void
387  func _refresh_challenge_stage_navigation() -> void
411  func _make_controls_help() -> Control
467  func _build_actions(column: VBoxContainer) -> void
535  func _add_action_row(parent: Control, button: Button, tip: String) -> void
541  func _make_winter_action() -> Control
553  func _on_winter_pressed() -> void
559  func _on_challenge_advance_pressed() -> void
566  func _on_challenge_retreat_pressed() -> void
580  func _on_fire_test_warnings_pressed() -> void
613  func _on_force_c2_collapse_pressed() -> void
631  func set_save_load_enabled(enabled: bool) -> void
639  func set_toggle(key: String, value: bool) -> void
644  func _on_save_pressed() -> void
655  func _on_load_pressed() -> void
667  func _toggle_panel() -> void
681  func _apply_layer_for_context() -> void
686  func _make_row(entry: Dictionary) -> Control
729  func _make_control_slot() -> HBoxContainer
738  func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
768  func _make_toggle_row(entry: Dictionary) -> Control
839  func _make_options_row(entry: Dictionary) -> Control
872  func _option_display(entry: Dictionary, value) -> String
876  func _cycle_option(entry: Dictionary, direction: int) -> void
890  func _cascade_prerequisites_on(key: String) -> void
904  func _cascade_dependents_off(key: String) -> void
912  func _cascade_mutual_exclusion(key: String) -> void
921  func _make_star_row(entry: Dictionary) -> Control
962  func _adjust(entry: Dictionary, delta: float) -> void
976  func _format_value(v) -> String
983  func _on_restart_pressed() -> void
988  func _on_main_menu_pressed() -> void
996  func _restart() -> void
```

## game_config.gd (886 lines)

The balance fields.

```
8    # --- world ---
25   # --- flowers (per-species values are in flower.gd; these scale them) ---
407  # --- foraging ---
416  # --- hive ---
443  # --- the nursery zone ---
504  # --- eating ---
512  # --- flight ---
543  # --- gynes ---
558  # --- royal jelly ---
568  # --- weather ---
586  # --- warnings ---
595  # --- honey ---
611  # --- comb building ---
631  # --- hive geometry ---
660  # --- bee life ---
665  # --- bee individuality ---
744  # --- the rival colony ---
793  # --- seasons ---
825  # --- disease ---
853  # --- gynes leaving ---
860  # --- winter ---
```
