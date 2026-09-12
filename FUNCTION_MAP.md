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

## hud.gd (3,155 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
22   # --- signals ------------------------------------------------------
126  # --- role controls ------------------------------------------------
138  static func hatch_options() -> Array
183  static func mode_command(role_id: int, mode_key: String) -> String
186  # --- shared layout constants --------------------------------------
222  # --- fields -------------------------------------------------------
500  # --- problem strip ------------------------------------------------
509  func _signal_color(severity: int) -> Color
516  # --- _ready and construction --------------------------------------
521  func _ready() -> void
574  func _on_viewport_size_changed() -> void
578  func _make_label(pos: Vector2, variation: String = "Body") -> Label
586  func _info(text: String) -> Button
589  func _with_info(control: Control, tip: String) -> HBoxContainer
594  func _style_button(button: BaseButton) -> BaseButton
599  # --- speed controls -----------------------------------------------
623  func _build_top_right_bar() -> void
732  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
768  func _apply_interface_label_visibility() -> void
774  # --- Challenge goal readout ---------------------------------------
779  func _build_goal_shelf() -> void
846  func set_settings_button_width(width: float) -> void
860  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
875  func set_speed_display(speed_scale: float) -> void
880  # --- bottom row ---------------------------------------------------
885  func _build_selection_panel() -> void
995  func _build_favourite_star() -> Control
1026 func _set_favourite_star(bee) -> void
1054 func _field_control(field_name: String) -> Control
1068 func _build_selection_cog() -> Control
1096 func _set_summary_cog_kind(kind: String) -> void
1108 func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
1128 func _apply_selection_field_visibility() -> void
1157 func _resize_selection_panel_to_content() -> void
1165 # --- command tray -------------------------------------------------
1177 func _build_command_tray() -> void
1277 func _build_tray_column(title: String) -> Array
1304 # --- cell popup ---------------------------------------------------
1320 func _build_cell_group(parent: VBoxContainer) -> void
1411 func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer
1432 func _build_nursery_controls(column: VBoxContainer) -> void
1527 func _build_closing_controls(column: VBoxContainer) -> void
1567 func _build_empty_controls(column: VBoxContainer) -> void
1629 func _make_hatch_menu(entry: Dictionary) -> Control
1654 func _build_warning_banner() -> void
1690 func show_warning(text: String, key: String = "", min_gap: float = 0.0, severity: int = 0) -> void
1706 func _show_warning_now(text: String, severity: int) -> void
1714 func _dismiss_warning() -> void
1719 func set_warnings_muted(value: bool) -> void
1733 func show_object_summary(kind: String, data) -> void
1757 func _refresh_flower_summary() -> void
1793 func _show_obstacle_summary(obstacle: Node2D) -> void
1799 func _show_soil_summary(count: int, reachable: int) -> void
1815 func _show_death_summary(info: Dictionary) -> void
1837 func show_cell_popup(cell: Node2D, count: int = 1) -> void
1858 func _refresh_cell_popup() -> void
1968 func _apply_cell_popup_gating() -> void
1984 func _light_current_options() -> void
2002 func _set_lit(key: String, lit: bool) -> void
2013 func _process(_delta: float) -> void
2041 func _request_designation(type: String) -> void
2046 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
2051 func _request_empty(method: String) -> void
2056 func _request_priority(tier: int) -> void
2061 func _request_close(closed: bool) -> void
2066 func _request_fill_close() -> void
2071 # --- discard warning ----------------------------------------------
2077 func _build_discard_dialog() -> void
2092 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
2101 func _on_discard_confirmed() -> void
2104 func _on_discard_custom_action(action: StringName) -> void
2111 func _apply_discard() -> void
2119 # --- readouts -----------------------------------------------------
2124 func update_day(day: int, note: String = "") -> void
2134 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
2143 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
2149 func update_comb(text: String) -> void
2153 func update_energy(mean_fraction: float) -> void
2160 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
2171 func update_recruit_gap(text: String) -> void
2184 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
2190 func update_signals(lines: Array) -> void
2198 func _refresh_corner() -> void
2277 func corner_bottom() -> float
2283 func selection_panel_top() -> float
2293 func pinned_stats_changed() -> void
2302 func refresh_speed_visibility() -> void
2309 func refresh_corner() -> void
2312 func update_selection(bees: Array) -> void
2345 func _selection_has_command_lock(bees: Array) -> bool
2366 static func _detach_and_free_children(container: Node) -> void
2379 func _rebuild_role_controls(bees: Array) -> void
2429 func _build_queen_build_row(column: VBoxContainer) -> void
2443 func _build_follow_control(bees: Array, first) -> void
2458 func _build_job_row(common_role: int, any_queen: bool) -> void
2490 func _build_doing_row(common_role: int, first) -> void
2516 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2531 func _build_orders_row(common_role: int, first) -> void
2578 func _build_restock_row(first) -> void
2613 func _build_fallback_row(common_role: int, first) -> void
2663 func _secondary_items() -> Array
2679 func _column_row(parent: Container) -> HFlowContainer
2687 func _labelled_row(title: String) -> HFlowContainer
2706 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2718 func _action_button(label: String, action: Callable, tip: String) -> Control
2727 func _current_role_marker(label: String) -> Control
2742 func _common_role(bees: Array) -> int
2759 func _common_working_role(bees: Array) -> int
2777 func _make_role_menu(label: String, tip: String, items: Array, node_name: String = "") -> Control
2798 func _refresh_selection_text() -> void
2897 func _apply_selection_tray_width() -> void
2948 func _match_summary_header_button_heights() -> void
2966 func _tray_column_share(inner_width: float) -> float
2975 func _apply_even_column_widths(wrappers: Array) -> void
3003 func _update_command_tray_width() -> void
3024 func _resize_command_tray() -> void
3059 func _resettle_command_tray(generation: int, previous_content_min_y: float, stable_streak: int, pass_count: int) -> void
3072 func set_winter_button_visible(value: bool) -> void
3078 func set_view_label(in_hive: bool) -> void
3084 func set_colony_button_visible(value: bool) -> void
3090 func set_nursery_button_visible(value: bool) -> void
3096 func set_view_button_visible(value: bool) -> void
3102 func set_foraging_button_visible(value: bool) -> void
3109 func set_allowed_role_keys(keys: Array) -> void
3119 func set_command_locked_bees(bees: Array) -> void
3124 func set_allowed_mode_keys(keys: Array) -> void
3132 func set_allowed_designation_keys(keys: Array) -> void
3137 func set_hatch_lock_visible(value: bool) -> void
3142 func set_soil_marking_visible(value: bool) -> void
3152 func set_queen_build_button_visible(value: bool) -> void
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

## main.gd (1,200 lines)

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
922  func _role_counts() -> Dictionary
940  func _update_population_readout(bees = null) -> void
962  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
968  func _prune_selection() -> void
981  func _on_restart_after_loss() -> void
987  func _on_level_chosen(level: int) -> void
1000 func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
1018 func _apply_scenario_boot_arg() -> void
1133 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1173 func _is_whole_number(value: Variant) -> bool
1187 func _end_scenario_run(outcome: String) -> void
```

## challenge_runner.gd (1,143 lines)

The stage machine, goal checks and stage effects.

```
142  func _ready() -> void
145  func _reset_c2_pollen_rescue() -> void
148  func _stages() -> Array
153  func current_stage_instruction() -> String
164  func run_skill_grants() -> Array
167  func run_skill_bans() -> Array
170  func run_skill_delays() -> Dictionary
173  func start() -> void
250  func _process(delta: float) -> void
277  func _check_c2_failure() -> void
337  func _c2_index(stage_id: String) -> int
347  func _stage_unlock_keys(entries: Array) -> Array
368  func _queen_allowed_role_ids(entries: Array) -> Array
376  func _enter_stage() -> void
436  func _built_cell_count() -> int
445  func _brood_cell_count() -> int
455  func _hive_inspection_points() -> Array
469  func _meadow_inspection_points() -> Array
481  func _begin_ordered_visit(points: Array, marker_parent: Node2D) -> void
487  func _clear_ordered_visit() -> void
492  func _ordered_visit_complete(traveller: Node2D) -> bool
505  func _show_current_visit_point() -> void
520  func _update_marker(stage_id: String) -> void
553  func _show_goal(stage: Dictionary) -> void
560  func _advance() -> void
576  func _run_stage_effects(effects: Array) -> void
614  func debug_advance_stage() -> void
618  func _complete() -> void
674  func _on_queen_build_cell_requested() -> void
680  func on_queen_build_site_chosen(hex: Vector2i) -> void
696  func _apply_stage_gate_to_ui() -> void
738  func is_bee_command_locked(bee: Node2D) -> bool
746  func _setup_opening_tunnel() -> void
786  func _drive_opening_mine() -> void
798  func _opening_tunnel_cleared() -> bool
813  func _drive_c1_forage_effects() -> void
834  func discards_overflow(bee: Node2D) -> bool
846  func announce_overflow_discard() -> void
863  func _drive_c1_pollen_cell_nectar_prompt(delta: float) -> void
882  func on_worker_hatched(bee: Node2D) -> void
904  func _drive_greeting(delta: float) -> void
951  func _build_goal_registry() -> void
984  func _goal_met(goal: String) -> bool
990  func _goal_check_entrance_tunnel_cleared() -> bool
993  func _goal_check_queen_reached_cavity() -> bool
998  func _goal_check_queen_selected() -> bool
1001 func _goal_check_hive_points_visited() -> bool
1004 func _goal_check_first_cell_built() -> bool
1007 func _goal_check_second_cell_built() -> bool
1010 func _goal_check_third_cell_built() -> bool
1013 func _goal_check_nectar_target() -> bool
1019 func _goal_check_pollen_target() -> bool
1025 func _goal_check_first_egg_laid() -> bool
1028 func _goal_check_queen_reached_meadow() -> bool
1031 func _goal_check_meadow_points_visited() -> bool
1034 func _goal_check_first_flower_collected() -> bool
1037 func _goal_check_second_flower_collected() -> bool
1040 func _goal_check_harvest_deposited() -> bool
1043 func _goal_check_new_bee_selected() -> bool
1049 func _goal_check_new_bee_left_hive() -> bool
1052 func _goal_check_complete() -> bool
1055 # --- Challenge 1's 1.16 also uses this: the first hatch is a nectar
1057 func _goal_check_nectar_forager_hatched() -> bool
1060 # --- Challenge 2 ---------------------------------------------
1061 func _goal_check_nectar_stabilized() -> bool
1068 func _goal_check_pollen_foragers_raised() -> bool
1071 func _goal_check_cell_designated() -> bool
1077 func _goal_check_pollen_cell_designated() -> bool
1083 func _goal_check_interim_reserve() -> bool
1089 func _goal_check_nurse_raised() -> bool
1092 func _goal_check_persistent_designation_used() -> bool
1100 func _goal_check_comb_worker_building() -> bool
1104 func _goal_check_miner_expansion() -> bool
1111 func _goal_check_c2_complete() -> bool
1128 func _goal_progress(goal: String) -> Dictionary
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

## hive_cell.gd (1,117 lines)

One cell: contents, brood, honey ripening, how it draws.

```
145  func effective_build_time() -> float
247  func _ready() -> void
366  func set_overlay(mode: String) -> void
372  func _overlay_colour() -> Array
410  func set_selected(value: bool) -> void
422  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
433  func _set_outline_points(line: Line2D, size: float) -> void
444  func _silhouette_point_to_local(p: Vector2) -> Vector2
456  func _set_outline_points_cup(line: Line2D, size: float) -> void
472  func _apply_outline_points(line: Line2D, size: float) -> void
480  func _set_selection_ring_points() -> void
499  func _process(delta: float) -> void
523  func _develop_brood(delta: float) -> void
544  func _health_factor() -> float
552  func _larva_dies() -> void
567  func _invalidate_hive_index() -> void
582  func bump_display_epoch() -> void
585  # --- working positions --------------------------------------------
590  func claim_slot(bee: Node2D) -> int
601  func release_slot(bee: Node2D) -> void
608  func has_free_slot() -> bool
617  func slot_position(index: int) -> Vector2
624  # --- building -----------------------------------------------------
626  func start_as_site() -> void
631  func claim_builder(bee: Node2D) -> void
635  func release_builder(bee: Node2D) -> void
641  func add_build_progress(delta: float) -> void
652  func build_fraction() -> float
655  # --- contents -----------------------------------------------------
657  func is_empty() -> bool
662  func capacity_for(resource_type: String) -> float
671  func accepts(resource_type: String) -> bool
690  func is_nursery_cell() -> bool
693  func space_for(resource_type: String) -> float
709  func needs_eviction() -> bool
727  func add_resource(resource_type: String, requested: float) -> float
758  func take_resource(resource_type: String, requested: float) -> float
785  func can_withdraw() -> bool
790  func set_closed(value: bool) -> void
796  func set_fill_then_close(value: bool) -> void
804  func fill_fraction() -> float
811  func set_designation(resource_type: String, explicit: bool = true) -> void
819  # --- honey ---------------------------------------------------------
821  func is_ripe_honey() -> bool
825  func needs_fanning() -> bool
830  func add_fanning_progress(delta: float) -> void
839  func ripen_fraction() -> float
842  # --- brood ---------------------------------------------------------
844  func start_brood(as_gyne: bool = false) -> void
857  func develop_time() -> float
865  func feed_brood(seconds: float, on_honey: bool) -> void
870  func needs_feeding() -> bool
874  func seconds_until_death() -> float
879  # --- clearing a dead larva ------------------------------------------
881  func needs_cleaning() -> bool
887  func add_clean_progress(delta: float) -> bool
893  func clean_fraction() -> float
896  func brood_ready() -> bool
899  func clear_cell() -> void
912  # --- display ------------------------------------------------------
917  func _resource_outline_colour(resource_type: String) -> Color
931  func _refresh() -> void
1068 func _designation_tag() -> String
1090 func _priority_mark() -> String
1103 func _apply_fill_shading() -> void
1114 func development_percent() -> float
```

## settings_catalogue.gd (1,071 lines)

Every setting's key, label, range and tip, plus the read/write and Prerequisites-cascade functions the window is a view of.

```
964  static func setting_get(key: String)
967  static func setting_set(key: String, value) -> void
990  static func reset_config_to_defaults() -> void
1002 static func reset_config_keys(keys: Array) -> void
1016 static func apply_setting(key: String, value) -> void
1031 static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1049 static func _cascade_dependents_off_static(key: String) -> Array[String]
1063 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
```

## hive.gd (1,015 lines)

The comb as a whole: cells, navigation, finding a cell.

```
48   func add_entrance_mentor(bee: Node2D) -> void
52   func remove_entrance_mentor(bee: Node2D) -> void
69   func add_dance_eligible_mentor(bee: Node2D) -> void
73   func remove_dance_eligible_mentor(bee: Node2D) -> void
76   func add_dance_eligible_seeker(bee: Node2D) -> void
80   func remove_dance_eligible_seeker(bee: Node2D) -> void
83   func record_collection(resource_type: String, amount: float) -> void
89   func record_birth() -> void
92   # --- cell index ---------------------------------------------------
111  func _content_index() -> Dictionary
146  func invalidate_index() -> void
149  func cells_holding(content: String) -> Array
161  func register_tile(hex: Vector2i, node: Node2D) -> void
167  func invalidate_mining_work() -> void
171  func _advance_mining_work_epoch() -> void
174  func tile_is_free(hex: Vector2i) -> bool
179  func tile_is_interior(hex: Vector2i) -> bool
184  func cell_at_tile(hex: Vector2i) -> Node2D
190  func _ready() -> void
200  func deposit(resource_type: String, amount: float) -> float
219  func take(resource_type: String, amount: float) -> float
234  func take_energy(energy_wanted: float) -> float
247  func total(resource_type: String) -> float
257  func total_sealed() -> float
265  func total_honey() -> float
272  # --- finding cells ------------------------------------------------
285  func find_cell_for(resource_type: String, except: Node2D = null) -> Node2D
309  func find_designated_cell_for(resource_type: String, except: Node2D = null) -> Node2D
347  func find_empty_cell() -> Node2D
393  func _lay_by_priority(pool: Array) -> Node2D
424  func _tier_weights() -> Array
439  func record_lay(cell: Node2D) -> void
453  func zone_summary() -> Dictionary
483  func brood_stage_counts() -> Dictionary
498  func find_food_cell(except: Node2D = null) -> Node2D
511  func has_room_for_egg() -> bool
514  func find_cell_with(resource_type: String) -> Node2D
527  func find_brood_cell() -> Node2D
542  func find_cell_needing_fanning() -> Node2D
550  func find_honey_target() -> Node2D
553  func find_unfinished_cell() -> Node2D
562  func find_cell_needing_cleaning() -> Node2D
566  func find_cell_needing_eviction() -> Node2D
574  func has_gyne_brood() -> bool
582  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
585  # --- growing the comb ---------------------------------------------
619  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
653  func set_keep_clear(hex: Vector2i, value: bool) -> void
659  func is_keep_clear(hex: Vector2i) -> bool
666  func can_build_on(hex: Vector2i) -> bool
669  func _can_build_on(hex: Vector2i) -> bool
672  func _start_site_at(hex: Vector2i) -> Node2D
694  func create_cell_site_at(hex: Vector2i) -> Node2D
699  # --- navigation ---------------------------------------------------
710  func build_navigation() -> void
751  func _is_solid(hex: Vector2i) -> bool
757  func _tile_cost(hex: Vector2i) -> float
760  func tile_is_walkable(hex: Vector2i) -> bool
769  func nearest_walkable_point(point: Vector2) -> Vector2
796  func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
830  func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
854  func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
868  # --- mining -------------------------------------------------------
877  func refresh_edge_flags() -> void
899  func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
927  func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
951  func _is_markable_block(node) -> bool
958  func mine_stand_hex(block: Node2D)
981  func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
1003 func remove_block(block: Node2D, floor_maker: Callable) -> void
1014 func announce() -> void
```

## debug_panel.gd (874 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
63   func _style_button(button: BaseButton) -> BaseButton
68   func _ready() -> void
172  func _report_settings_button_width() -> void
177  func _rows_in(category: String) -> Array
199  func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
230  func _set_open(header: Button, body: Control, label: String, open: bool) -> void
238  func open_to_categories(categories: Array) -> void
258  func collapse_all() -> void
266  func _make_section(category: String, entries: Array, start_open: bool) -> Control
320  func _make_controls_help() -> Control
354  func _build_actions(column: VBoxContainer) -> void
421  func _make_winter_action() -> Control
433  func _on_winter_pressed() -> void
439  func _on_challenge_advance_pressed() -> void
452  func _on_fire_test_warnings_pressed() -> void
485  func _on_force_c2_collapse_pressed() -> void
503  func set_save_load_enabled(enabled: bool) -> void
511  func set_toggle(key: String, value: bool) -> void
516  func _on_save_pressed() -> void
527  func _on_load_pressed() -> void
539  func _toggle_panel() -> void
553  func _apply_layer_for_context() -> void
558  func _make_row(entry: Dictionary) -> Control
601  func _make_control_slot() -> HBoxContainer
610  func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
640  func _make_toggle_row(entry: Dictionary) -> Control
711  func _make_options_row(entry: Dictionary) -> Control
744  func _option_display(entry: Dictionary, value) -> String
748  func _cycle_option(entry: Dictionary, direction: int) -> void
763  func _cascade_prerequisites_on(key: String) -> void
777  func _cascade_dependents_off(key: String) -> void
785  func _cascade_mutual_exclusion(key: String) -> void
794  func _make_star_row(entry: Dictionary) -> Control
835  func _adjust(entry: Dictionary, delta: float) -> void
850  func _format_value(v) -> String
857  func _on_restart_pressed() -> void
862  func _on_main_menu_pressed() -> void
870  func _restart() -> void
```

## game_config.gd (874 lines)

The balance fields.

```
8    # --- world ---
21   # --- flowers (per-species values are in flower.gd; these scale them) ---
403  # --- foraging ---
412  # --- hive ---
439  # --- the nursery zone ---
494  # --- eating ---
502  # --- flight ---
533  # --- gynes ---
548  # --- royal jelly ---
558  # --- weather ---
576  # --- warnings ---
585  # --- honey ---
601  # --- comb building ---
621  # --- hive geometry ---
650  # --- bee life ---
655  # --- bee individuality ---
734  # --- the rival colony ---
783  # --- seasons ---
813  # --- disease ---
841  # --- gynes leaving ---
848  # --- winter ---
```

## scenario_actions.gd (824 lines)

The headless verbs, `when` clauses and layout assertions.

```
32   static func run_pending(main: Node2D, actions: Array) -> void
55   static func log_unresolved(actions: Array) -> void
72   static func _do_settle(action: Dictionary) -> bool
81   static func _execute(main: Node2D, action: Dictionary) -> void
111  # --- triggers -----------------------------------------------------
116  static func _when_met(main: Node2D, when: Dictionary) -> bool
149  static func _population(main: Node2D, role_key: String) -> int
161  # --- selectors ------------------------------------------------------
165  static func _resolve_bees(main: Node2D, target: Dictionary) -> Array
183  static func _resolve_cell(main: Node2D, hex: Array) -> Node2D
193  static func _resolve_soil_block(main: Node2D, hex: Array) -> Node2D
203  # --- verbs ------------------------------------------------------------
220  static func _do_assign_role(main: Node2D, action: Dictionary) -> void
276  static func _do_designate_cell(main: Node2D, action: Dictionary) -> void
300  static func _do_queue_build(main: Node2D, action: Dictionary) -> void
326  static func _do_queue_mine(main: Node2D, action: Dictionary) -> void
357  static func _do_set_config(_main: Node2D, action: Dictionary) -> void
370  static func _do_hatch_role(main: Node2D, action: Dictionary) -> void
387  static func _do_set_restock_order(main: Node2D, action: Dictionary) -> void
433  static func _do_select_bees(main: Node2D, action: Dictionary) -> void
464  static func _do_select_soil(main: Node2D, action: Dictionary) -> void
490  static func _do_open_window(main: Node2D, action: Dictionary) -> void
530  static func _do_viewport_size(main: Node2D, action: Dictionary) -> void
543  static func _do_show_gallerin_prompt(main: Node2D, action: Dictionary) -> void
554  # --- assertion checks -------------------------------------------------
564  static func _do_assert(main: Node2D, action: Dictionary) -> bool
574  static func _evaluate_assert_condition(main: Node2D, condition: Dictionary) -> Dictionary
605  static func _check_panel_rect(main: Node2D, condition: Dictionary) -> Dictionary
647  static func _resolve_named_panel(main: Node2D, name: String) -> Control
676  static func _check_control_rect(main: Node2D, condition: Dictionary) -> Dictionary
715  static func _check_even_columns(main: Node2D, condition: Dictionary) -> Dictionary
755  static func _check_no_collapsed_controls(main: Node2D, condition: Dictionary) -> Dictionary
772  static func _check_no_empty_labels(main: Node2D, condition: Dictionary) -> Dictionary
783  static func _collect_empty_labels(node: Node, out: Array) -> void
789  static func _collect_collapsed_controls(node: Node, out: Array) -> void
802  static func _resolve_scoped_path(main: Node2D, path: String) -> Node
823  static func _log(do: String, target_desc: String, result: String, reason: String) -> void
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
