# Function map

A line-numbered index of every function and section header in the six
scripts still over ~700 lines after the `bee.gd` / `main.gd` splits.
Smaller files don't need this -- grep their `# --- section ---` headers
directly, per CLAUDE.md.

**How to use it:** grep this file for the function name (or the area you
want, e.g. "popup", "restock") to get its line number, then either `Read`
the source file with an offset near that line, or grep the source file
directly for the exact signature before editing. Line numbers here are a
pointer, not a guarantee -- they drift as the file changes.

**How to keep it updated:** this file is generated, not hand-maintained.
After adding, removing, renaming or moving a function in one of the six
files below, run:

```
python3 tools/update_function_map.py
```

`--check` exits non-zero (and prints which files moved) instead of
writing, for a pre-commit or CI check. Whether the map was actually
regenerated after a given change is a `git log` question, not something
recorded in this file.

---

## hud.gd (2,374 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
126  static func hatch_options() -> Array
171  static func mode_command(role_id: int, mode_key: String) -> String
385  func _ready() -> void
427  func _make_label(pos: Vector2, variation: String = "Body") -> Label
435  func _info(text: String) -> Button
438  func _with_info(control: Control, tip: String) -> HBoxContainer
443  func _style_button(button: BaseButton) -> BaseButton
464  func _build_top_right_bar() -> void
576  func _icon_button(shape: String, label: String, min_width: float) -> Button
611  func _apply_interface_label_visibility() -> void
621  func _build_goal_shelf() -> void
680  func set_settings_button_width(width: float) -> void
694  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
709  func set_speed_display(speed_scale: float) -> void
718  func _build_selection_panel() -> void
782  func _build_selection_cog() -> Control
802  func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
813  func _apply_selection_field_visibility() -> void
825  func _build_command_tray() -> void
887  func _build_tray_column(title: String) -> Array
905  # --- cell popup ---------------------------------------------------
921  func _build_cell_group(parent: VBoxContainer) -> void
1071 func _build_cell_action_column(parent: HBoxContainer, title: String) -> VBoxContainer
1095 func _build_zone_controls(column: VBoxContainer) -> void
1150 func _build_closing_controls(column: VBoxContainer) -> void
1190 func _build_empty_controls(column: VBoxContainer) -> void
1233 func _make_hatch_menu(entry: Dictionary) -> Control
1257 func _build_warning_banner() -> void
1286 func show_warning(text: String) -> void
1293 func set_warnings_muted(value: bool) -> void
1306 func show_object_summary(kind: String, data) -> void
1324 func _refresh_flower_summary() -> void
1349 func _show_obstacle_summary(obstacle: Node2D) -> void
1355 func _show_soil_summary(count: int, reachable: int) -> void
1371 func _show_death_summary(info: Dictionary) -> void
1393 func show_cell_popup(cell: Node2D, count: int = 1) -> void
1409 func _refresh_cell_popup() -> void
1504 func _apply_cell_popup_gating() -> void
1518 func _light_current_options() -> void
1536 func _set_lit(key: String, lit: bool) -> void
1547 func _process(_delta: float) -> void
1562 func _request_designation(type: String) -> void
1567 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1572 func _request_empty(method: String) -> void
1577 func _request_zone(in_zone: bool) -> void
1582 func _request_priority(tier: int) -> void
1587 func _request_close(closed: bool) -> void
1592 func _request_fill_close() -> void
1597 # --- discard warning ----------------------------------------------
1603 func _build_discard_dialog() -> void
1618 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1627 func _on_discard_confirmed() -> void
1630 func _on_discard_custom_action(action: StringName) -> void
1637 func _apply_discard() -> void
1645 # --- readouts -----------------------------------------------------
1650 func update_day(day: int, note: String = "") -> void
1660 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1669 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1675 func update_comb(text: String) -> void
1679 func update_energy(mean_fraction: float) -> void
1686 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1697 func update_recruit_gap(text: String) -> void
1710 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
1716 func update_signals(lines: Array) -> void
1724 func _refresh_corner() -> void
1805 func pinned_stats_changed() -> void
1814 func refresh_speed_visibility() -> void
1821 func refresh_corner() -> void
1824 func update_selection(bees: Array) -> void
1845 func _selection_has_command_lock(bees: Array) -> bool
1862 func _rebuild_role_controls(bees: Array) -> void
1906 func _build_queen_build_row() -> void
1920 func _build_follow_control(bees: Array, first) -> void
1936 func _build_favourite_row(bee) -> void
1947 func _build_job_row(common_role: int, any_queen: bool) -> void
1975 func _build_doing_row(common_role: int, first) -> void
2001 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2016 func _build_orders_row(common_role: int, first) -> void
2063 func _build_restock_row(first) -> void
2091 func _build_fallback_row(common_role: int, first) -> void
2123 func _secondary_items() -> Array
2137 func _column_row(parent: Container) -> HBoxContainer
2143 func _labelled_row(title: String) -> HBoxContainer
2160 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2171 func _action_button(label: String, action: Callable, tip: String) -> Control
2179 func _current_role_marker(label: String) -> Control
2189 func _common_role(bees: Array) -> int
2202 func _make_role_menu(label: String, tip: String, items: Array) -> Control
2217 func _refresh_selection_text() -> void
2287 func _update_command_tray_width() -> void
2298 func set_winter_button_visible(value: bool) -> void
2304 func set_view_label(in_hive: bool) -> void
2309 func set_colony_button_visible(value: bool) -> void
2315 func set_nursery_button_visible(value: bool) -> void
2321 func set_view_button_visible(value: bool) -> void
2330 func set_allowed_role_keys(keys: Array) -> void
2338 func set_command_locked_bees(bees: Array) -> void
2343 func set_allowed_mode_keys(keys: Array) -> void
2351 func set_allowed_designation_keys(keys: Array) -> void
2356 func set_hatch_lock_visible(value: bool) -> void
2361 func set_soil_marking_visible(value: bool) -> void
2371 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (2,151 lines)

A bee's dispatch loop, player commands, display text, vars.

```
506  func _ready() -> void
643  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
680  func _roll_fact() -> void
694  func _default_state_for_role() -> int
716  func _base_colour() -> Color
727  func _tinted(c: Color) -> Color
742  func _apply_stats() -> void
768  func trait_text() -> String
777  func _update_role_marker() -> void
796  # --- how often a bee thinks ---------------------------------------
820  func _process(delta: float) -> void
1082 # --- life support -------------------------------------------------
1084 # --- eating -------------------------------------------------------
1086 # --- stall watchdog -----------------------------------------------
1092 func _reset_stall_watch() -> void
1095 # --- foraging -----------------------------------------------------
1097 # --- entering and leaving the hive --------------------------------
1099 # --- nursery work -------------------------------------------------
1101 # --- royal jelly ---------------------------------------------------
1103 # --- idle work dispatch --------------------------------------------
1117 func _apply_pending_role() -> bool
1129 func _is_busy() -> bool
1135 func _idle_dispatch() -> void
1161 func _maybe_break_off_secondary() -> void
1185 func _try_role_work(r: int) -> bool
1363 # --- building -----------------------------------------------------
1365 # --- keeping cells topped up ---------------------------------------
1394 func set_restock_targets(cells: Array, resource: String) -> void
1397 func set_restock_sources(cells: Array, allowed: bool) -> void
1400 func clear_restock() -> void
1403 func has_restock_orders() -> bool
1405 # --- mining -------------------------------------------------------
1407 # --- honey making -------------------------------------------------
1409 # --- egg laying (queen only) --------------------------------------
1411 # --- player commands ----------------------------------------------
1421 func command_move_to(world_point: Vector2) -> void
1445 func command_exit_hive() -> void
1454 func set_forage_start_point(meadow_point: Vector2) -> void
1459 func has_forage_start_point() -> bool
1462 func set_preferred_species(species: String) -> void
1475 func set_manual_build_target(hex: Vector2i) -> void
1483 func queue_build_target(hex: Vector2i) -> void
1490 func clear_build_queue() -> void
1496 func _take_next_build_target() -> bool
1509 func set_mine_target(block: Node2D) -> void
1514 func queue_mine_target(block: Node2D) -> void
1520 func clear_mine_queue() -> void
1525 func _next_queued_block() -> Node2D
1533 func set_home_hex(hex: Vector2i) -> void
1542 func set_mine_home_hex(hex: Vector2i) -> void
1548 func _mine_reference_point() -> Vector2
1561 func command_collect_from(flower: Node2D) -> void
1574 func set_focus(type: String) -> void
1601 func set_secondary_role(new_role: int) -> void
1604 func can_take_role(new_role: int) -> bool
1614 func set_role(new_role: int) -> void
1631 func _apply_role(new_role: int) -> void
1657 func _release_everything() -> void
1674 func release_flower_reference(flower: Node2D) -> void
1680 func set_selected(value: bool) -> void
1684 # --- display ------------------------------------------------------
1686 func role_letter() -> String
1704 func idle_reason() -> String
1755 func task_description() -> String
1900 func _idle_backup_note() -> String
1905 func role_name_text() -> String
1931 func nurse_mode_name() -> String
1940 func architect_mode_name() -> String
1946 func carrying_text() -> String
1967 func age_days() -> float
1975 func leave_to_found_colony() -> void
1988 func days_remaining() -> float
2000 func _update_label() -> void
2020 func _update_alarm_ring() -> void
2031 func _update_heading_marker() -> void
2045 func _update_search_ring() -> void
2073 func _update_wander_flight(delta: float) -> void
2104 func _update_dance_circle(delta: float) -> void
2118 func _terrain_speed_factor() -> float
2127 func _is_inside_hive() -> bool
2130 # --- getting round things in the meadow ---------------------------
2150 func clear_navigation_state() -> void
```

## debug_panel.gd (1,664 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
938  static func setting_get(key: String)
941  static func setting_set(key: String, value) -> void
956  static func apply_setting(key: String, value) -> void
971  static func _cascade_prerequisites_on_static(key: String) -> Array[String]
985  static func _cascade_dependents_off_static(key: String) -> Array[String]
999  static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
1025 func _style_button(button: BaseButton) -> BaseButton
1030 func _ready() -> void
1105 func _report_settings_button_width() -> void
1110 func _rows_in(category: String) -> Array
1132 func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
1162 func _make_section(category: String, entries: Array, start_open: bool) -> Control
1218 func _make_controls_help() -> Control
1251 func _build_actions(column: VBoxContainer) -> void
1293 func _make_winter_action() -> Control
1305 func _on_winter_pressed() -> void
1311 func _on_challenge_advance_pressed() -> void
1322 func set_save_load_enabled(enabled: bool) -> void
1330 func set_toggle(key: String, value: bool) -> void
1335 func _on_save_pressed() -> void
1346 func _on_load_pressed() -> void
1358 func _toggle_panel() -> void
1364 func _make_row(entry: Dictionary) -> Control
1407 func _make_control_slot() -> HBoxContainer
1416 func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
1446 func _make_toggle_row(entry: Dictionary) -> Control
1510 func _make_options_row(entry: Dictionary) -> Control
1543 func _option_display(entry: Dictionary, value) -> String
1547 func _cycle_option(entry: Dictionary, direction: int) -> void
1561 func _cascade_prerequisites_on(key: String) -> void
1568 func _cascade_dependents_off(key: String) -> void
1575 func _cascade_mutual_exclusion(key: String) -> void
1584 func _make_star_row(entry: Dictionary) -> Control
1625 func _adjust(entry: Dictionary, delta: float) -> void
1640 func _format_value(v) -> String
1647 func _on_restart_pressed() -> void
1652 func _on_main_menu_pressed() -> void
1660 func _restart() -> void
```

## hive_cell.gd (883 lines)

One cell: contents, brood, honey ripening, how it draws.

```
101  func effective_build_time() -> float
183  func _ready() -> void
262  func set_overlay(mode: String) -> void
268  func _overlay_colour() -> Array
306  func set_selected(value: bool) -> void
318  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
329  func _set_outline_points(line: Line2D, size: float) -> void
352  func _process(delta: float) -> void
376  func _develop_brood(delta: float) -> void
397  func _health_factor() -> float
405  func _larva_dies() -> void
415  # --- working positions --------------------------------------------
420  func claim_slot(bee: Node2D) -> int
431  func release_slot(bee: Node2D) -> void
439  func slot_position(index: int) -> Vector2
446  # --- building -----------------------------------------------------
448  func start_as_site() -> void
452  func claim_builder(bee: Node2D) -> void
456  func release_builder(bee: Node2D) -> void
461  func add_build_progress(delta: float) -> void
471  func build_fraction() -> float
474  # --- contents -----------------------------------------------------
476  func is_empty() -> bool
481  func capacity_for(resource_type: String) -> float
490  func accepts(resource_type: String) -> bool
509  func is_nursery_cell() -> bool
512  func space_for(resource_type: String) -> float
528  func needs_eviction() -> bool
546  func add_resource(resource_type: String, requested: float) -> float
570  func take_resource(resource_type: String, requested: float) -> float
594  func can_withdraw() -> bool
599  func set_closed(value: bool) -> void
604  func set_fill_then_close(value: bool) -> void
611  func fill_fraction() -> float
618  func set_designation(resource_type: String) -> void
624  # --- honey ---------------------------------------------------------
626  func is_ripe_honey() -> bool
630  func needs_fanning() -> bool
635  func add_fanning_progress(delta: float) -> void
643  func ripen_fraction() -> float
646  # --- brood ---------------------------------------------------------
648  func start_brood(as_gyne: bool = false) -> void
660  func develop_time() -> float
668  func feed_brood(seconds: float, on_honey: bool) -> void
673  func needs_feeding() -> bool
677  func seconds_until_death() -> float
682  # --- clearing a dead larva ------------------------------------------
684  func needs_cleaning() -> bool
690  func add_clean_progress(delta: float) -> bool
696  func clean_fraction() -> float
699  func brood_ready() -> bool
702  func clear_cell() -> void
714  # --- display ------------------------------------------------------
716  func _refresh() -> void
834  func _designation_tag() -> String
856  func _priority_mark() -> String
869  func _apply_fill_shading() -> void
880  func development_percent() -> float
```

## hive.gd (949 lines)

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
102  func _content_index() -> Dictionary
126  func invalidate_index() -> void
129  func cells_holding(content: String) -> Array
136  func register_tile(hex: Vector2i, node: Node2D) -> void
139  func tile_is_free(hex: Vector2i) -> bool
144  func tile_is_interior(hex: Vector2i) -> bool
149  func cell_at_tile(hex: Vector2i) -> Node2D
155  func _ready() -> void
165  func deposit(resource_type: String, amount: float) -> float
184  func take(resource_type: String, amount: float) -> float
199  func take_energy(energy_wanted: float) -> float
212  func total(resource_type: String) -> float
222  func total_sealed() -> float
230  func total_honey() -> float
237  # --- finding cells ------------------------------------------------
250  func find_cell_for(resource_type: String, except: Node2D = null) -> Node2D
274  func find_designated_cell_for(resource_type: String, except: Node2D = null) -> Node2D
312  func find_empty_cell() -> Node2D
358  func _lay_by_priority(pool: Array) -> Node2D
389  func _tier_weights() -> Array
404  func record_lay(cell: Node2D) -> void
418  func zone_summary() -> Dictionary
448  func brood_stage_counts() -> Dictionary
463  func find_food_cell(except: Node2D = null) -> Node2D
476  func has_room_for_egg() -> bool
479  func find_cell_with(resource_type: String) -> Node2D
492  func find_brood_cell() -> Node2D
507  func find_cell_needing_fanning() -> Node2D
515  func find_honey_target() -> Node2D
518  func find_unfinished_cell() -> Node2D
527  func find_cell_needing_cleaning() -> Node2D
531  func find_cell_needing_eviction() -> Node2D
539  func has_gyne_brood() -> bool
547  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
550  # --- growing the comb ---------------------------------------------
584  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
618  func set_keep_clear(hex: Vector2i, value: bool) -> void
624  func is_keep_clear(hex: Vector2i) -> bool
631  func can_build_on(hex: Vector2i) -> bool
634  func _can_build_on(hex: Vector2i) -> bool
637  func _start_site_at(hex: Vector2i) -> Node2D
653  func create_cell_site_at(hex: Vector2i) -> Node2D
658  # --- navigation ---------------------------------------------------
669  func build_navigation() -> void
710  func _is_solid(hex: Vector2i) -> bool
716  func _tile_cost(hex: Vector2i) -> float
719  func tile_is_walkable(hex: Vector2i) -> bool
728  func nearest_walkable_point(point: Vector2) -> Vector2
755  func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
789  func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
813  func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
823  # --- mining -------------------------------------------------------
832  func refresh_edge_flags() -> void
849  func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
871  func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
890  func _is_markable_block(node) -> bool
897  func mine_stand_hex(block: Node2D)
920  func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
938  func remove_block(block: Node2D, floor_maker: Callable) -> void
948  func announce() -> void
```

## main.gd (1,056 lines)

Per-frame entry point, everything not yet split out of main.

```
317  func _ready() -> void
543  # --- public surface other scripts call directly -------------------
550  func is_on_screen(node: Node2D) -> bool
553  func hive_entrance_inside() -> Vector2
556  func entrance_wait_point(side: int) -> Vector2
559  func move_bee_into_hive(bee: Node2D) -> void
562  func move_bee_out_of_hive(bee: Node2D) -> void
565  func mark_death(bee: Node2D) -> void
568  func finish_mining(block: Node2D) -> void
571  func save_run() -> void
574  func begin_winter_countdown() -> void
577  # --- per-frame ----------------------------------------------------
587  func _process(delta: float) -> void
654  # --- the frame rate readout ----------------------------------------
673  func _sample_fps() -> void
696  func _reseed_meadow(delta: float) -> void
711  func _hatch_ready_brood() -> void
741  func _advance_weather(delta: float) -> void
769  func _apply_rain_overlay() -> void
784  func _check_for_loss() -> void
806  func _check_colony_energy(delta: float) -> void
835  func _role_counts() -> Dictionary
849  func _update_population_readout(bees = null) -> void
870  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
876  func _prune_selection() -> void
889  func _on_restart_after_loss() -> void
895  func _on_level_chosen(level: int) -> void
908  func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
925  func _apply_scenario_boot_arg() -> void
1043 func _end_scenario_run(outcome: String) -> void
```
