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

## hud.gd (3,278 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
24   # --- signals ------------------------------------------------------
128  # --- role controls ------------------------------------------------
140  static func hatch_options() -> Array
185  static func mode_command(role_id: int, mode_key: String) -> String
188  # --- shared layout constants --------------------------------------
224  # --- fields -------------------------------------------------------
518  # --- problem strip ------------------------------------------------
527  func _signal_color(severity: int) -> Color
534  # --- _ready and construction --------------------------------------
539  func _ready() -> void
593  func _on_viewport_size_changed() -> void
598  func _build_stage_marker_arrow() -> void
616  func set_stage_marker(global_position: Vector2, visible: bool, in_hive: bool) -> void
621  func _make_label(pos: Vector2, variation: String = "Body") -> Label
629  func _info(text: String) -> Button
632  func _with_info(control: Control, tip: String) -> HBoxContainer
637  func _style_button(button: BaseButton) -> BaseButton
642  # --- speed controls -----------------------------------------------
666  func _build_top_right_bar() -> void
775  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
811  func _apply_interface_label_visibility() -> void
817  # --- Challenge goal readout ---------------------------------------
822  func _build_goal_shelf() -> void
889  func set_settings_button_width(width: float) -> void
903  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
918  func set_speed_display(speed_scale: float) -> void
923  # --- bottom row ---------------------------------------------------
928  func _build_selection_panel() -> void
1038 func _build_favourite_star() -> Control
1069 func _set_favourite_star(bee) -> void
1097 func _field_control(field_name: String) -> Control
1111 func _build_selection_cog() -> Control
1139 func _set_summary_cog_kind(kind: String) -> void
1151 func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
1171 func _apply_selection_field_visibility() -> void
1200 func _resize_selection_panel_to_content() -> void
1208 # --- command tray -------------------------------------------------
1220 func _build_command_tray() -> void
1320 func _build_tray_column(title: String) -> Array
1347 # --- cell popup ---------------------------------------------------
1363 func _build_cell_group(parent: VBoxContainer) -> void
1454 func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer
1475 func _build_nursery_controls(column: VBoxContainer) -> void
1570 func _build_closing_controls(column: VBoxContainer) -> void
1610 func _build_empty_controls(column: VBoxContainer) -> void
1672 func _make_hatch_menu(entry: Dictionary) -> Control
1697 func _build_warning_banner() -> void
1733 func show_warning(text: String, key: String = "", min_gap: float = 0.0, severity: int = 0) -> void
1749 func _show_warning_now(text: String, severity: int) -> void
1757 func _dismiss_warning() -> void
1762 func set_warnings_muted(value: bool) -> void
1776 func show_object_summary(kind: String, data) -> void
1800 func _refresh_flower_summary() -> void
1836 func _show_obstacle_summary(obstacle: Node2D) -> void
1842 func _show_soil_summary(count: int, reachable: int) -> void
1858 func _show_death_summary(info: Dictionary) -> void
1880 func show_cell_popup(cell: Node2D, count: int = 1) -> void
1901 func _refresh_cell_popup() -> void
2011 func _apply_cell_popup_gating() -> void
2027 func _light_current_options() -> void
2045 func _set_lit(key: String, lit: bool) -> void
2056 func _process(_delta: float) -> void
2088 func _stage_marker_screen_position() -> Vector2
2092 func _update_stage_marker_arrow() -> void
2125 func _refresh_marker_exclusion_rects(viewport_size: Vector2) -> void
2136 func _append_marker_panel_exclusion(panel: Control, owner_rect: Rect2) -> void
2141 func _slide_arrow_along_edge(edge_point: Vector2, edge_bounds: Rect2) -> Vector2
2158 func _marker_arrow_obscured(point: Vector2) -> bool
2164 func _request_designation(type: String) -> void
2169 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
2174 func _request_empty(method: String) -> void
2179 func _request_priority(tier: int) -> void
2184 func _request_close(closed: bool) -> void
2189 func _request_fill_close() -> void
2194 # --- discard warning ----------------------------------------------
2200 func _build_discard_dialog() -> void
2215 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
2224 func _on_discard_confirmed() -> void
2227 func _on_discard_custom_action(action: StringName) -> void
2234 func _apply_discard() -> void
2242 # --- readouts -----------------------------------------------------
2247 func update_day(day: int, note: String = "") -> void
2257 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
2266 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
2272 func update_comb(text: String) -> void
2276 func update_energy(mean_fraction: float) -> void
2283 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
2294 func update_recruit_gap(text: String) -> void
2307 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
2313 func update_signals(lines: Array) -> void
2321 func _refresh_corner() -> void
2400 func corner_bottom() -> float
2406 func selection_panel_top() -> float
2416 func pinned_stats_changed() -> void
2425 func refresh_speed_visibility() -> void
2432 func refresh_corner() -> void
2435 func update_selection(bees: Array) -> void
2468 func _selection_has_command_lock(bees: Array) -> bool
2489 static func _detach_and_free_children(container: Node) -> void
2502 func _rebuild_role_controls(bees: Array) -> void
2552 func _build_queen_build_row(column: VBoxContainer) -> void
2566 func _build_follow_control(bees: Array, first) -> void
2581 func _build_job_row(common_role: int, any_queen: bool) -> void
2613 func _build_doing_row(common_role: int, first) -> void
2639 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2654 func _build_orders_row(common_role: int, first) -> void
2701 func _build_restock_row(first) -> void
2736 func _build_fallback_row(common_role: int, first) -> void
2786 func _secondary_items() -> Array
2802 func _column_row(parent: Container) -> HFlowContainer
2810 func _labelled_row(title: String) -> HFlowContainer
2829 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2841 func _action_button(label: String, action: Callable, tip: String) -> Control
2850 func _current_role_marker(label: String) -> Control
2865 func _common_role(bees: Array) -> int
2882 func _common_working_role(bees: Array) -> int
2900 func _make_role_menu(label: String, tip: String, items: Array, node_name: String = "") -> Control
2921 func _refresh_selection_text() -> void
3020 func _apply_selection_tray_width() -> void
3071 func _match_summary_header_button_heights() -> void
3089 func _tray_column_share(inner_width: float) -> float
3098 func _apply_even_column_widths(wrappers: Array) -> void
3126 func _update_command_tray_width() -> void
3147 func _resize_command_tray() -> void
3182 func _resettle_command_tray(generation: int, previous_content_min_y: float, stable_streak: int, pass_count: int) -> void
3195 func set_winter_button_visible(value: bool) -> void
3201 func set_view_label(in_hive: bool) -> void
3207 func set_colony_button_visible(value: bool) -> void
3213 func set_nursery_button_visible(value: bool) -> void
3219 func set_view_button_visible(value: bool) -> void
3225 func set_foraging_button_visible(value: bool) -> void
3232 func set_allowed_role_keys(keys: Array) -> void
3242 func set_command_locked_bees(bees: Array) -> void
3247 func set_allowed_mode_keys(keys: Array) -> void
3255 func set_allowed_designation_keys(keys: Array) -> void
3260 func set_hatch_lock_visible(value: bool) -> void
3265 func set_soil_marking_visible(value: bool) -> void
3275 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (2,472 lines)

A bee's dispatch loop, player commands, display text, vars.

```
241  func current_working_role() -> int
590  func _ready() -> void
738  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
780  func _roll_fact() -> void
794  func _default_state_for_role() -> int
816  func _base_colour() -> Color
827  func _tinted(c: Color) -> Color
842  func _apply_stats() -> void
868  func trait_text() -> String
877  func _update_role_marker() -> void
896  # --- how often a bee thinks ---------------------------------------
928  func _process(delta: float) -> void
1201 # --- life support -------------------------------------------------
1203 # --- eating -------------------------------------------------------
1205 # --- stall watchdog -----------------------------------------------
1211 func _reset_stall_watch() -> void
1214 # --- foraging -----------------------------------------------------
1216 # --- entering and leaving the hive --------------------------------
1218 # --- nursery work -------------------------------------------------
1220 # --- royal jelly ---------------------------------------------------
1222 # --- idle work dispatch --------------------------------------------
1236 func _apply_pending_role() -> bool
1248 func _is_busy() -> bool
1254 func _idle_dispatch() -> void
1280 func _maybe_break_off_secondary() -> void
1304 func _try_role_work(r: int) -> bool
1488 # --- building -----------------------------------------------------
1490 # --- keeping cells topped up ---------------------------------------
1519 func set_restock_targets(cells: Array, resource: String) -> void
1522 func set_restock_sources(cells: Array, allowed: bool) -> void
1525 func clear_restock() -> void
1528 func has_restock_orders() -> bool
1530 # --- mining -------------------------------------------------------
1532 # --- honey making -------------------------------------------------
1534 # --- egg laying (queen only) --------------------------------------
1536 # --- player commands ----------------------------------------------
1546 func command_move_to(world_point: Vector2) -> void
1566 func command_move_through_entrance(world_point: Vector2, target_in_hive: bool) -> void
1578 func command_exit_hive() -> void
1588 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
1596 func has_forage_start_point() -> bool
1599 func set_preferred_species(species: String) -> void
1612 func set_manual_build_target(hex: Vector2i) -> void
1620 func queue_build_target(hex: Vector2i) -> void
1627 func clear_build_queue() -> void
1633 func _take_next_build_target() -> bool
1646 func set_mine_target(block: Node2D) -> void
1653 func queue_mine_target(block: Node2D) -> void
1661 func clear_mine_queue() -> void
1668 func _next_queued_block() -> Node2D
1676 func set_home_hex(hex: Vector2i) -> void
1685 func set_mine_home_hex(hex: Vector2i) -> void
1691 func _mine_reference_point() -> Vector2
1706 func command_collect_from(flower: Node2D) -> void
1722 func command_collect_from_after_exit(flower: Node2D) -> void
1735 func command_return_and_deposit() -> void
1745 func command_return_only() -> void
1751 func command_deposit_at(cell: Node2D) -> void
1764 func command_empty_cell(cell: Node2D) -> void
1776 func command_deposit_at_after_enter(cell: Node2D) -> void
1784 func resume_pending_zone_command() -> bool
1803 func _clear_pending_zone_command() -> void
1808 func set_focus(type: String) -> void
1854 func set_secondary_role(new_role: int) -> void
1857 func can_take_role(new_role: int) -> bool
1867 func set_role(new_role: int) -> void
1884 func _apply_role(new_role: int) -> void
1917 func _release_everything() -> void
1934 func release_flower_reference(flower: Node2D) -> void
1940 func set_selected(value: bool) -> void
1944 # --- display ------------------------------------------------------
1946 func role_letter() -> String
1975 func challenge_vocabulary_limited() -> bool
1988 func idle_reason() -> String
2041 func task_description() -> String
2188 func _idle_backup_note() -> String
2198 func role_name_text() -> String
2224 func nurse_mode_name() -> String
2233 func architect_mode_name() -> String
2239 func carrying_text() -> String
2260 func age_days() -> float
2268 func leave_to_found_colony() -> void
2281 func days_remaining() -> float
2293 func _update_label() -> void
2313 func _update_alarm_ring() -> void
2324 func _update_heading_marker() -> void
2338 func _update_search_ring() -> void
2361 func _update_dance_ring() -> void
2394 func _update_wander_flight(delta: float) -> void
2425 func _update_dance_circle(delta: float) -> void
2439 func _terrain_speed_factor() -> float
2448 func _is_inside_hive() -> bool
2451 # --- getting round things in the meadow ---------------------------
2471 func clear_navigation_state() -> void
```

## settings_catalogue.gd (1,407 lines)

Every setting's key, label, range and tip, plus the read/write and Prerequisites-cascade functions the window is a view of.

```
1300 static func setting_get(key: String)
1303 static func setting_set(key: String, value) -> void
1326 static func reset_config_to_defaults() -> void
1338 static func reset_config_keys(keys: Array) -> void
1352 static func apply_setting(key: String, value) -> void
1367 static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1385 static func _cascade_dependents_off_static(key: String) -> Array[String]
1399 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
```

## bee_foraging.gd (1,329 lines)

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
122  static func _start_searching(bee: Node2D) -> void
149  static func search_for_flower(bee: Node2D, delta: float) -> void
194  static func advance_search_waypoint(bee: Node2D) -> void
210  static func _perceive_flower(bee: Node2D) -> Node2D
217  static func _commit_to_flower(bee: Node2D, flower: Node2D) -> void
230  static func _remember_patch(bee: Node2D, position: Vector2) -> void
243  static func _pick_known_patch(bee: Node2D) -> Vector2
267  static func _spiral_point(bee: Node2D, anchor: Vector2, angle: float) -> Vector2
296  static func nearest_flower(bee: Node2D, strict: bool, radius: float, allow_full_scan: bool = true) -> Node2D
393  static func _weighted_flower_choice(bee: Node2D, nodes: Array, accept: Callable, radius: float) -> Node2D
431  static func flower_grid(bee: Node2D)
446  static func start_inspecting(bee: Node2D) -> void
451  static func inspect(bee: Node2D, delta: float) -> void
474  static func needs_a_drink(bee: Node2D) -> bool
482  static func drink_at_flower(bee: Node2D, delta: float) -> void
507  static func nectar_strength(_bee: Node2D) -> float
515  static func shelter(bee: Node2D, _delta: float) -> void
520  static func worth_feeding(bee: Node2D, f: Node2D) -> bool
533  static func reject_flower(bee: Node2D) -> void
551  static func start_collecting(bee: Node2D) -> void
624  static func _handling_experience_scale(bee: Node2D, species: String) -> float
633  static func collect(bee: Node2D, delta: float) -> void
682  static func finish_collecting(bee: Node2D) -> void
724  static func enter_hive(bee: Node2D) -> void
751  static func approach_cell(bee: Node2D, cell: Node2D, delta: float) -> int
766  static func release_cell_slot(bee: Node2D) -> void
773  static func go_to_deposit_cell(bee: Node2D, delta: float) -> void
843  static func finish_depositing(bee: Node2D) -> void
884  static func _score_trip(bee: Node2D) -> void
962  static func go_to_exit(bee: Node2D, delta: float) -> void
1005 static func _entrance_wait_spot(bee: Node2D, side: int) -> Vector2
1017 static func _leave_hive_and_resume(bee: Node2D) -> void
1044 static func _send_to_scout_point(bee: Node2D) -> void
1060 static func start_scouting(bee: Node2D) -> void
1082 static func wait_at_entrance(bee: Node2D, delta: float) -> void
1193 static func _update_dance_eligibility(bee: Node2D) -> void
1217 static func check_dance_proximity(bee: Node2D, _delta: float) -> void
1242 static func _start_dance(mentor: Node2D, seeker: Node2D) -> void
1262 static func dance(bee: Node2D, delta: float) -> void
1274 static func _end_dance(bee: Node2D) -> void
1296 static func _complete_dance(mentor: Node2D, seeker: Node2D) -> void
1324 static func deposit_everything_remotely(bee: Node2D) -> void
```

## challenge_runner.gd (1,196 lines)

The stage machine, goal checks and stage effects.

```
161  func _ready() -> void
164  func _reset_c2_pollen_rescue() -> void
167  func _stages() -> Array
172  func current_stage_instruction() -> String
179  func current_stage_id() -> String
187  func current_stage_goal_text() -> String
192  func can_debug_retreat_stage() -> bool
195  func can_debug_advance_stage() -> bool
204  func run_skill_grants() -> Array
207  func run_skill_bans() -> Array
210  func run_skill_delays() -> Dictionary
213  func start() -> void
292  func _process(delta: float) -> void
331  func _should_check_goal(goal_id: String, goal_tick_due: bool) -> bool
353  func _check_c2_failure() -> void
413  func _c2_index(stage_id: String) -> int
423  func _stage_unlock_keys(entries: Array) -> Array
444  func _queen_allowed_role_ids(entries: Array) -> Array
452  func _enter_stage() -> void
516  func _built_cell_count() -> int
525  func _brood_cell_count() -> int
535  func _hive_inspection_points() -> Array
549  func _meadow_inspection_points() -> Array
561  func _begin_ordered_visit(points: Array, marker_parent: Node2D) -> void
567  func _clear_ordered_visit() -> void
572  func _ordered_visit_complete(traveller: Node2D) -> bool
585  func _show_current_visit_point() -> void
600  func _update_marker(stage_id: String) -> void
638  func _set_marker_visible(value: bool) -> void
662  func _publish_marker_to_hud() -> void
673  func _show_goal(stage: Dictionary) -> void
680  func _advance() -> void
695  func _leave_stage() -> Dictionary
705  func _run_stage_effects(effects: Array) -> void
743  func debug_advance_stage() -> void
750  func debug_retreat_stage() -> void
758  func _complete() -> void
814  func _on_queen_build_cell_requested() -> void
820  func on_queen_build_site_chosen(hex: Vector2i) -> void
836  func _apply_stage_gate_to_ui() -> void
878  func is_bee_command_locked(bee: Node2D) -> bool
886  func _setup_opening_tunnel() -> void
926  func _drive_opening_mine() -> void
938  func _opening_tunnel_cleared() -> bool
953  func _drive_c1_forage_effects() -> void
974  func discards_overflow(bee: Node2D) -> bool
986  func announce_overflow_discard() -> void
1003 func _drive_c1_pollen_cell_nectar_prompt(delta: float) -> void
1022 func on_worker_hatched(bee: Node2D) -> void
1044 func _drive_greeting(delta: float) -> void
1080 func _goal_met(goal: String) -> bool
1092 func _goal_check_entrance_tunnel_cleared() -> bool
1095 func _goal_check_queen_reached_cavity() -> bool
1100 func _goal_check_queen_selected() -> bool
1103 func _goal_check_hive_points_visited() -> bool
1106 func _goal_check_nectar_target() -> bool
1112 func _goal_check_pollen_target() -> bool
1118 func _goal_check_queen_reached_meadow() -> bool
1121 func _goal_check_meadow_points_visited() -> bool
1124 func _goal_check_first_flower_collected() -> bool
1127 func _goal_check_second_flower_collected() -> bool
1130 func _goal_check_harvest_deposited() -> bool
1133 func _goal_check_new_bee_selected() -> bool
1139 func _goal_check_new_bee_left_hive() -> bool
1142 func _goal_check_complete() -> bool
1145 # --- Challenge 2 ---------------------------------------------
1146 func _goal_check_nectar_stabilized() -> bool
1153 func _goal_check_persistent_designation_used() -> bool
1161 func _goal_check_comb_worker_building() -> bool
1165 func _goal_check_miner_expansion() -> bool
1177 func _goal_progress(goal: String) -> Dictionary
1186 func _custom_goal_progress(method: String) -> Dictionary
```

## main.gd (1,195 lines)

Per-frame entry point, everything not yet split out of main.

```
37   # --- signals ------------------------------------------------------
51   # --- preloads and boot constants ----------------------------------
93   # --- delegate systems ---------------------------------------------
122  # --- world and meadow constants -----------------------------------
183  # --- state --------------------------------------------------------
332  # --- _ready and construction --------------------------------------
333  func _ready() -> void
589  # --- public surface other scripts call directly -------------------
596  func is_on_screen(node: Node2D) -> bool
599  func hive_entrance_inside() -> Vector2
602  func entrance_wait_point(side: int) -> Vector2
605  func move_bee_into_hive(bee: Node2D) -> void
608  func move_bee_out_of_hive(bee: Node2D) -> void
611  func mark_death(bee: Node2D) -> void
619  func _on_bee_died(bee: Node2D) -> void
623  func finish_mining(block: Node2D) -> void
626  func save_run() -> void
629  func begin_winter_countdown() -> void
632  # --- per-frame ----------------------------------------------------
642  func _process(delta: float) -> void
724  # --- the frame rate readout ----------------------------------------
743  func _sample_fps() -> void
766  func _reseed_meadow(delta: float) -> void
781  func _hatch_ready_brood() -> void
813  func _advance_weather(delta: float) -> void
843  func _apply_rain_overlay() -> void
858  func _check_for_loss() -> void
880  func _check_colony_energy(delta: float) -> void
911  func invalidate_population() -> void
922  func _role_counts(bees = null) -> Dictionary
939  func _update_population_readout(bees = null) -> void
951  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
957  func _prune_selection() -> void
970  func _on_restart_after_loss() -> void
976  func _on_level_chosen(level: int) -> void
989  func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
1007 func _apply_scenario_boot_arg() -> void
1128 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1168 func _is_whole_number(value: Variant) -> bool
1182 func _end_scenario_run(outcome: String) -> void
```

## diagnostic_log.gd (1,134 lines)

The session JSONL writer, counters and capture profiles.

```
121  func _ready() -> void
129  func _notification(what: int) -> void
134  func start_session() -> void
197  func log_death(bee: Node2D) -> void
230  func log_crab_spider_event(bee: Node2D, flower: Node2D, outcome: String) -> void
254  func log_recruitment_match(seeker: Node2D, mentor: Node2D, via: String = "queue") -> void
287  func log_recruitment_followup(bee: Node2D, trip_index: int, trip_rate: float) -> void
309  func count_recruit_partner_overlap() -> void
319  func log_forager_settled(bee: Node2D) -> void
337  func log_orientation_flight(bee: Node2D) -> void
353  func count_flower_visit(flower: Node2D) -> void
362  func record_handling_visit(species: String, prior_experience: int, seconds: float) -> void
376  func count_forager_delivery(amount: float) -> void
383  func count_flower_senescence() -> void
390  func count_flower_senescence_loss(nectar: float, pollen: float) -> void
395  func _experience_bucket(prior_experience: int) -> String
407  func count_tarsal_mark() -> void
416  func count_tarsal_rejection() -> void
427  func log_stall_recovery(bee: Node2D, goal: Vector2) -> void
456  func log_build_target(bee: Node2D, cell: Node2D, transition: String, reason: String,
481  func log_forager_return(bee: Node2D, phase: String, required_energy: float) -> void
491  func log_flight_start_resolved(bee: Node2D, source: String, requested: Vector2, resolved: Dictionary) -> void
503  func _nearby_obstacle_identity(bee: Node2D) -> String
526  func log_scouting_settled(bee: Node2D) -> void
543  func count_brood_feed() -> void
550  func count_brood_hatch(role: int, mode: String) -> void
557  func count_jelly_batch() -> void
562  func count_larval_death() -> void
568  func count_cell_completed() -> void
573  func cell_completed_count() -> int
579  func count_cell_cleaned() -> void
586  func count_cell_evicted() -> void
592  func count_cell_restocked() -> void
598  func count_block_mined() -> void
604  func count_honey_batch_deposited() -> void
610  func count_cell_ripened() -> void
618  func log_action(do: String, target_desc: String, result: String, reason: String) -> void
634  func log_command_issue(selected_count: int, commandable_count: int, branch: String,
663  func log_selection_panels_hidden(source: String, shown_count: int, selected_count: int) -> void
681  func event_count(type: String, subtype: String = "") -> int
728  func tick(delta: float, world: Node2D) -> void
762  func end_session(outcome: String) -> void
815  func session_path() -> String
819  func set_queen_alive(alive: bool) -> void
823  func configure_scenario_diagnostics(raw: Variant) -> bool
832  func configure_performance_capture(config: Dictionary) -> void
836  func effective_diagnostics() -> Dictionary
842  func _snapshot_interval() -> float
855  func _selected_snapshot(world: Node2D) -> Dictionary
861  # --- building entries -----------------------------------------------
865  func _config_snapshot() -> Dictionary
873  func _snapshot(world: Node2D) -> Dictionary
1048 func _performance_snapshot(world: Node2D) -> Dictionary
1068 func _rate(world: Node2D, key: String) -> float
1083 func _current_day() -> int
1087 func _prune_old_sessions() -> void
1105 func _write(entry: Dictionary) -> void
1114 func _capture_entry(entry: Dictionary) -> bool
```

## hive_cell.gd (1,132 lines)

One cell: contents, brood, honey ripening, how it draws.

```
146  func effective_build_time() -> float
248  func _ready() -> void
367  func set_overlay(mode: String) -> void
373  func _overlay_colour() -> Array
411  func set_selected(value: bool) -> void
423  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
434  func _set_outline_points(line: Line2D, size: float) -> void
445  func _silhouette_point_to_local(p: Vector2) -> Vector2
457  func _set_outline_points_cup(line: Line2D, size: float) -> void
473  func _apply_outline_points(line: Line2D, size: float) -> void
481  func _set_selection_ring_points() -> void
500  func _process(delta: float) -> void
524  func _develop_brood(delta: float) -> void
545  func _health_factor() -> float
553  func _larva_dies() -> void
569  func _invalidate_hive_index() -> void
579  func _invalidate_stock() -> void
593  func bump_display_epoch() -> void
596  # --- working positions --------------------------------------------
601  func claim_slot(bee: Node2D) -> int
612  func release_slot(bee: Node2D) -> void
619  func has_free_slot() -> bool
628  func slot_position(index: int) -> Vector2
635  # --- building -----------------------------------------------------
637  func start_as_site() -> void
642  func claim_builder(bee: Node2D) -> void
646  func release_builder(bee: Node2D) -> void
652  func add_build_progress(delta: float) -> void
663  func build_fraction() -> float
666  # --- contents -----------------------------------------------------
668  func is_empty() -> bool
673  func capacity_for(resource_type: String) -> float
679  func accepts(resource_type: String) -> bool
698  func is_nursery_cell() -> bool
701  func space_for(resource_type: String) -> float
717  func needs_eviction() -> bool
735  func add_resource(resource_type: String, requested: float) -> float
767  func take_resource(resource_type: String, requested: float) -> float
795  func can_withdraw() -> bool
800  func set_closed(value: bool) -> void
807  func set_fill_then_close(value: bool) -> void
816  func fill_fraction() -> float
823  func set_designation(resource_type: String, explicit: bool = true) -> void
831  # --- honey ---------------------------------------------------------
833  func is_ripe_honey() -> bool
837  func needs_fanning() -> bool
842  func add_fanning_progress(delta: float) -> void
852  func ripen_fraction() -> float
855  # --- brood ---------------------------------------------------------
857  func start_brood(as_gyne: bool = false) -> void
871  func develop_time() -> float
879  func feed_brood(seconds: float, on_honey: bool) -> void
884  func needs_feeding() -> bool
888  func seconds_until_death() -> float
893  # --- clearing a dead larva ------------------------------------------
895  func needs_cleaning() -> bool
901  func add_clean_progress(delta: float) -> bool
907  func clean_fraction() -> float
910  func brood_ready() -> bool
913  func clear_cell() -> void
927  # --- display ------------------------------------------------------
932  func _resource_outline_colour(resource_type: String) -> Color
946  func _refresh() -> void
1083 func _designation_tag() -> String
1105 func _priority_mark() -> String
1118 func _apply_fill_shading() -> void
1129 func development_percent() -> float
```

## hive.gd (1,045 lines)

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
541  func has_room_for_egg() -> bool
544  func find_cell_with(resource_type: String) -> Node2D
557  func find_brood_cell() -> Node2D
572  func find_cell_needing_fanning() -> Node2D
580  func find_honey_target() -> Node2D
583  func find_unfinished_cell() -> Node2D
592  func find_cell_needing_cleaning() -> Node2D
596  func find_cell_needing_eviction() -> Node2D
604  func has_gyne_brood() -> bool
612  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
615  # --- growing the comb ---------------------------------------------
649  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
683  func set_keep_clear(hex: Vector2i, value: bool) -> void
689  func is_keep_clear(hex: Vector2i) -> bool
696  func can_build_on(hex: Vector2i) -> bool
699  func _can_build_on(hex: Vector2i) -> bool
702  func _start_site_at(hex: Vector2i) -> Node2D
724  func create_cell_site_at(hex: Vector2i) -> Node2D
729  # --- navigation ---------------------------------------------------
740  func build_navigation() -> void
781  func _is_solid(hex: Vector2i) -> bool
787  func _tile_cost(hex: Vector2i) -> float
790  func tile_is_walkable(hex: Vector2i) -> bool
799  func nearest_walkable_point(point: Vector2) -> Vector2
826  func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
860  func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
884  func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
898  # --- mining -------------------------------------------------------
907  func refresh_edge_flags() -> void
929  func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
957  func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
981  func _is_markable_block(node) -> bool
988  func mine_stand_hex(block: Node2D)
1011 func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
1033 func remove_block(block: Node2D, floor_maker: Callable) -> void
1044 func announce() -> void
```

## debug_panel.gd (962 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
70   func _style_button(button: BaseButton) -> BaseButton
75   func _ready() -> void
179  func _report_settings_button_width() -> void
184  func _rows_in(category: String) -> Array
206  func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
237  func _set_open(header: Button, body: Control, label: String, open: bool) -> void
245  func open_to_categories(categories: Array) -> void
265  func collapse_all() -> void
273  func _make_section(category: String, entries: Array, start_open: bool) -> Control
333  func _make_challenge_stage_navigation() -> Control
362  func _process(_delta: float) -> void
365  func _refresh_challenge_stage_navigation() -> void
389  func _make_controls_help() -> Control
427  func _build_actions(column: VBoxContainer) -> void
495  func _add_action_row(parent: Control, button: Button, tip: String) -> void
501  func _make_winter_action() -> Control
513  func _on_winter_pressed() -> void
519  func _on_challenge_advance_pressed() -> void
526  func _on_challenge_retreat_pressed() -> void
540  func _on_fire_test_warnings_pressed() -> void
573  func _on_force_c2_collapse_pressed() -> void
591  func set_save_load_enabled(enabled: bool) -> void
599  func set_toggle(key: String, value: bool) -> void
604  func _on_save_pressed() -> void
615  func _on_load_pressed() -> void
627  func _toggle_panel() -> void
641  func _apply_layer_for_context() -> void
646  func _make_row(entry: Dictionary) -> Control
689  func _make_control_slot() -> HBoxContainer
698  func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
728  func _make_toggle_row(entry: Dictionary) -> Control
799  func _make_options_row(entry: Dictionary) -> Control
832  func _option_display(entry: Dictionary, value) -> String
836  func _cycle_option(entry: Dictionary, direction: int) -> void
851  func _cascade_prerequisites_on(key: String) -> void
865  func _cascade_dependents_off(key: String) -> void
873  func _cascade_mutual_exclusion(key: String) -> void
882  func _make_star_row(entry: Dictionary) -> Control
923  func _adjust(entry: Dictionary, delta: float) -> void
938  func _format_value(v) -> String
945  func _on_restart_pressed() -> void
950  func _on_main_menu_pressed() -> void
958  func _restart() -> void
```

## scenario_actions.gd (889 lines)

The headless verbs, `when` clauses and layout assertions.

```
45   static func run_pending(main: Node2D, actions: Array) -> void
68   static func log_unresolved(actions: Array) -> void
85   static func _do_settle(action: Dictionary) -> bool
94   static func _execute(main: Node2D, action: Dictionary) -> void
126  # --- triggers -----------------------------------------------------
136  static func _when_met(main: Node2D, when: Dictionary) -> bool
151  static func _legacy_when_spec(main: Node2D, when: Dictionary) -> Dictionary
202  # --- selectors ------------------------------------------------------
206  static func _resolve_bees(main: Node2D, target: Dictionary) -> Array
224  static func _resolve_cell(main: Node2D, hex: Array) -> Node2D
234  static func _resolve_soil_block(main: Node2D, hex: Array) -> Node2D
244  # --- verbs ------------------------------------------------------------
261  static func _do_assign_role(main: Node2D, action: Dictionary) -> void
317  static func _do_designate_cell(main: Node2D, action: Dictionary) -> void
341  static func _do_queue_build(main: Node2D, action: Dictionary) -> void
367  static func _do_queue_mine(main: Node2D, action: Dictionary) -> void
398  static func _do_set_config(_main: Node2D, action: Dictionary) -> void
411  static func _do_hatch_role(main: Node2D, action: Dictionary) -> void
428  static func _do_set_restock_order(main: Node2D, action: Dictionary) -> void
474  static func _do_select_bees(main: Node2D, action: Dictionary) -> void
505  static func _do_select_soil(main: Node2D, action: Dictionary) -> void
531  static func _do_open_window(main: Node2D, action: Dictionary) -> void
571  static func _do_viewport_size(main: Node2D, action: Dictionary) -> void
584  static func _do_show_gallerin_prompt(main: Node2D, action: Dictionary) -> void
598  static func _do_advance_challenge_stage(main: Node2D, action: Dictionary) -> void
619  # --- assertion checks -------------------------------------------------
629  static func _do_assert(main: Node2D, action: Dictionary) -> bool
639  static func _evaluate_assert_condition(main: Node2D, condition: Dictionary) -> Dictionary
670  static func _check_panel_rect(main: Node2D, condition: Dictionary) -> Dictionary
712  static func _resolve_named_panel(main: Node2D, name: String) -> Control
741  static func _check_control_rect(main: Node2D, condition: Dictionary) -> Dictionary
780  static func _check_even_columns(main: Node2D, condition: Dictionary) -> Dictionary
820  static func _check_no_collapsed_controls(main: Node2D, condition: Dictionary) -> Dictionary
837  static func _check_no_empty_labels(main: Node2D, condition: Dictionary) -> Dictionary
848  static func _collect_empty_labels(node: Node, out: Array) -> void
854  static func _collect_collapsed_controls(node: Node, out: Array) -> void
867  static func _resolve_scoped_path(main: Node2D, path: String) -> Node
888  static func _log(do: String, target_desc: String, result: String, reason: String) -> void
```

## game_config.gd (880 lines)

The balance fields.

```
8    # --- world ---
21   # --- flowers (per-species values are in flower.gd; these scale them) ---
403  # --- foraging ---
412  # --- hive ---
439  # --- the nursery zone ---
500  # --- eating ---
508  # --- flight ---
539  # --- gynes ---
554  # --- royal jelly ---
564  # --- weather ---
582  # --- warnings ---
591  # --- honey ---
607  # --- comb building ---
627  # --- hive geometry ---
656  # --- bee life ---
661  # --- bee individuality ---
740  # --- the rival colony ---
789  # --- seasons ---
819  # --- disease ---
847  # --- gynes leaving ---
854  # --- winter ---
```

## input_selection.gd (701 lines)

Selection, drag and placement resolution.

```
13   func _unhandled_input(event: InputEvent) -> void
77   func _finish_drag(additive: bool, add_to_group_selection: bool = false) -> void
197  func _select_cells(cells: Array, additive: bool) -> void
217  func _clear_cell_selection() -> void
223  func _select_blocks(blocks: Array, additive: bool) -> void
247  func _clear_block_selection() -> void
253  func _select_world_object(kind: String, object: Node2D) -> void
261  func _clear_world_object_selection() -> void
266  func _on_soil_mark_requested(mark: bool) -> void
271  func _bees_in_current_view() -> Array
275  func _death_markers_in_current_view() -> Array
279  func _bee_at(point: Vector2) -> Node2D
285  func _cell_at(point: Vector2) -> Node2D
291  func _soil_at(point: Vector2) -> Node2D
297  func _death_marker_at(point: Vector2) -> Node2D
303  func _hex_at(global_point: Vector2) -> Vector2i
307  func _place_build_cell(global_point: Vector2, keep_adding: bool) -> void
321  func _place_queen_build_cell(global_point: Vector2) -> void
325  func _on_build_cell_requested() -> void
332  func _place_mine_target(global_point: Vector2, keep_adding: bool) -> void
347  func _on_mine_target_requested() -> void
354  func _place_keep_clear(global_point: Vector2, keep_adding: bool) -> void
362  func _on_keep_clear_requested() -> void
366  func _place_home_cell(global_point: Vector2) -> void
379  func _on_cell_empty_by_bee_requested(cell: Node2D) -> void
391  func _on_home_cell_requested() -> void
406  func _place_home_cell_all(global_point: Vector2) -> void
415  func _on_home_cell_all_requested() -> void
421  func _place_mine_home(global_point: Vector2) -> void
431  func _on_mine_home_requested() -> void
440  func _place_forage_start(global_point: Vector2) -> void
448  func _place_floral_preference(global_point: Vector2) -> void
472  func _issue_command(world_point: Vector2) -> void
540  func _prune_invalid_selected_bees() -> void
549  func _show_click_marker(world_point: Vector2) -> void
555  func _on_role_selection_requested(role: int, focus: String) -> void
571  func _on_forage_start_point_requested() -> void
580  func _on_floral_preference_requested() -> void
589  func _ensure_hive_view() -> void
594  func _draw_selection_box() -> void
611  func _draw_hive_orders() -> void
644  func _draw_build_hover() -> void
653  func _draw_home_marker(point: Vector2) -> void
659  func _build_queue_points(bee: Node2D) -> Array
665  func _mine_queue_points(bee: Node2D) -> Array
672  func _draw_order_chain(bee: Node2D, points: Array, colour: Color) -> void
682  func _draw_tile_outline(centre: Vector2, colour: Color, width: float, dashed: bool) -> void
691  func _tile_centre(hex: Vector2i) -> Vector2
696  func _draw_start_point_marker(point: Vector2) -> void
```
