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

## hud.gd (2,249 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
126  static func hatch_options() -> Array
171  static func mode_command(role_id: int, mode_key: String) -> String
360  func _ready() -> void
406  func _make_label(pos: Vector2, variation: String = "Body") -> Label
414  func _info(text: String) -> Button
417  func _with_info(control: Control, tip: String) -> HBoxContainer
422  func _style_button(button: BaseButton) -> BaseButton
443  func _build_top_right_bar() -> void
545  func _icon_button(shape: String, label: String, min_width: float) -> Button
576  func _build_goal_shelf() -> void
635  func set_settings_button_width(width: float) -> void
649  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
664  func set_speed_display(speed_scale: float) -> void
673  func _build_selection_panel() -> void
720  func _build_selection_cog() -> Control
740  func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
751  func _apply_selection_field_visibility() -> void
763  func _build_command_tray() -> void
807  # --- cell popup ---------------------------------------------------
827  func _build_cell_popup() -> void
959  func _cell_section(column: VBoxContainer, title: String, open_by_default: bool) -> VBoxContainer
995  func _build_zone_controls(column: VBoxContainer) -> void
1050 func _build_closing_controls(column: VBoxContainer) -> void
1090 func _build_empty_controls(column: VBoxContainer) -> void
1133 func _make_hatch_menu(entry: Dictionary) -> Control
1150 func _build_flower_popup() -> void
1171 func _build_warning_banner() -> void
1200 func show_warning(text: String) -> void
1207 func set_warnings_muted(value: bool) -> void
1212 func _build_obstacle_popup() -> void
1224 func show_obstacle_popup(obstacle: Node2D, screen_position: Vector2) -> void
1229 func show_flower_popup(flower: Node2D, screen_position: Vector2) -> void
1235 func _refresh_flower_popup() -> void
1262 func _build_soil_popup() -> void
1292 func show_soil_popup(count: int, reachable: int, screen_position: Vector2) -> void
1309 func _build_death_popup() -> void
1321 func show_death_popup(info: Dictionary, screen_position: Vector2) -> void
1339 func show_cell_popup(cell: Node2D, screen_position: Vector2, count: int = 1) -> void
1346 func _refresh_cell_popup() -> void
1436 func _apply_cell_popup_gating() -> void
1450 func _light_current_options() -> void
1468 func _set_lit(key: String, lit: bool) -> void
1479 func _process(_delta: float) -> void
1493 func _request_designation(type: String) -> void
1498 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1503 func _request_empty(method: String) -> void
1508 func _request_zone(in_zone: bool) -> void
1513 func _request_priority(tier: int) -> void
1518 func _request_close(closed: bool) -> void
1523 func _request_fill_close() -> void
1528 # --- discard warning ----------------------------------------------
1534 func _build_discard_dialog() -> void
1549 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1558 func _on_discard_confirmed() -> void
1561 func _on_discard_custom_action(action: StringName) -> void
1568 func _apply_discard() -> void
1576 # --- readouts -----------------------------------------------------
1581 func update_day(day: int, note: String = "") -> void
1591 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1600 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1606 func update_comb(text: String) -> void
1610 func update_energy(mean_fraction: float) -> void
1617 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1628 func update_recruit_gap(text: String) -> void
1638 func update_fps(average: int, frame_ms: float, worst_ms: float) -> void
1643 func update_signals(lines: Array) -> void
1651 func _refresh_corner() -> void
1726 func pinned_stats_changed() -> void
1735 func refresh_speed_visibility() -> void
1742 func refresh_corner() -> void
1745 func update_selection(bees: Array) -> void
1769 func _rebuild_role_controls(bees: Array) -> void
1805 func _build_queen_build_row() -> void
1818 func _build_follow_control(bees: Array, first) -> void
1834 func _build_favourite_row(bee) -> void
1844 func _build_job_row(common_role: int, any_queen: bool) -> void
1872 func _build_doing_row(common_role: int, first) -> void
1898 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
1913 func _build_orders_row(common_role: int, first) -> void
1960 func _build_restock_row(first) -> void
1988 func _build_fallback_row(common_role: int, first) -> void
2020 func _secondary_items() -> Array
2031 func _labelled_row(title: String) -> HBoxContainer
2048 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2059 func _action_button(label: String, action: Callable, tip: String) -> Control
2067 func _current_role_marker(label: String) -> Control
2077 func _common_role(bees: Array) -> int
2090 func _make_role_menu(label: String, tip: String, items: Array) -> Control
2105 func _refresh_selection_text() -> void
2174 func _update_command_tray_width() -> void
2181 func set_winter_button_visible(value: bool) -> void
2187 func set_view_label(in_hive: bool) -> void
2192 func set_colony_button_visible(value: bool) -> void
2198 func set_nursery_button_visible(value: bool) -> void
2204 func set_view_button_visible(value: bool) -> void
2213 func set_allowed_role_keys(keys: Array) -> void
2218 func set_allowed_mode_keys(keys: Array) -> void
2226 func set_allowed_designation_keys(keys: Array) -> void
2231 func set_hatch_lock_visible(value: bool) -> void
2236 func set_soil_marking_visible(value: bool) -> void
2246 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (1,931 lines)

A bee's dispatch loop, player commands, display text, vars.

```
393  func _ready() -> void
504  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
541  func _roll_fact() -> void
555  func _default_state_for_role() -> int
577  func _base_colour() -> Color
588  func _tinted(c: Color) -> Color
603  func _apply_stats() -> void
629  func trait_text() -> String
638  func _update_role_marker() -> void
657  # --- how often a bee thinks ---------------------------------------
681  func _process(delta: float) -> void
924  # --- life support -------------------------------------------------
926  # --- eating -------------------------------------------------------
928  # --- stall watchdog -----------------------------------------------
934  func _reset_stall_watch() -> void
937  # --- foraging -----------------------------------------------------
939  # --- entering and leaving the hive --------------------------------
941  # --- nursery work -------------------------------------------------
943  # --- royal jelly ---------------------------------------------------
945  # --- idle work dispatch --------------------------------------------
959  func _apply_pending_role() -> bool
971  func _is_busy() -> bool
977  func _idle_dispatch() -> void
1003 func _maybe_break_off_secondary() -> void
1027 func _try_role_work(r: int) -> bool
1205 # --- building -----------------------------------------------------
1207 # --- keeping cells topped up ---------------------------------------
1236 func set_restock_targets(cells: Array, resource: String) -> void
1239 func set_restock_sources(cells: Array, allowed: bool) -> void
1242 func clear_restock() -> void
1245 func has_restock_orders() -> bool
1247 # --- mining -------------------------------------------------------
1249 # --- honey making -------------------------------------------------
1251 # --- egg laying (queen only) --------------------------------------
1253 # --- player commands ----------------------------------------------
1263 func command_move_to(world_point: Vector2) -> void
1287 func command_exit_hive() -> void
1296 func set_forage_start_point(meadow_point: Vector2) -> void
1299 func has_forage_start_point() -> bool
1302 func set_preferred_species(species: String) -> void
1315 func set_manual_build_target(hex: Vector2i) -> void
1323 func queue_build_target(hex: Vector2i) -> void
1330 func clear_build_queue() -> void
1336 func _take_next_build_target() -> bool
1349 func set_mine_target(block: Node2D) -> void
1354 func queue_mine_target(block: Node2D) -> void
1360 func clear_mine_queue() -> void
1365 func _next_queued_block() -> Node2D
1373 func set_home_hex(hex: Vector2i) -> void
1382 func set_mine_home_hex(hex: Vector2i) -> void
1388 func _mine_reference_point() -> Vector2
1401 func command_collect_from(flower: Node2D) -> void
1414 func set_focus(type: String) -> void
1441 func set_secondary_role(new_role: int) -> void
1444 func can_take_role(new_role: int) -> bool
1454 func set_role(new_role: int) -> void
1471 func _apply_role(new_role: int) -> void
1497 func _release_everything() -> void
1514 func release_flower_reference(flower: Node2D) -> void
1520 func set_selected(value: bool) -> void
1524 # --- display ------------------------------------------------------
1526 func role_letter() -> String
1544 func idle_reason() -> String
1595 func task_description() -> String
1734 func _idle_backup_note() -> String
1739 func role_name_text() -> String
1763 func nurse_mode_name() -> String
1772 func architect_mode_name() -> String
1778 func carrying_text() -> String
1799 func age_days() -> float
1807 func leave_to_found_colony() -> void
1820 func days_remaining() -> float
1832 func _update_label() -> void
1852 func _update_alarm_ring() -> void
1875 func _update_wander_flight(delta: float) -> void
1898 func _terrain_speed_factor() -> float
1907 func _is_inside_hive() -> bool
1910 # --- getting round things in the meadow ---------------------------
1930 func clear_navigation_state() -> void
```

## debug_panel.gd (1,445 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
881  static func setting_get(key: String)
884  static func setting_set(key: String, value) -> void
899  static func apply_setting(key: String, value) -> void
912  static func _cascade_prerequisites_on_static(key: String) -> Array[String]
926  static func _cascade_dependents_off_static(key: String) -> Array[String]
951  func _style_button(button: BaseButton) -> BaseButton
956  func _ready() -> void
1032 func _report_settings_button_width() -> void
1037 func _rows_in(category: String) -> Array
1059 func _make_section(category: String, entries: Array, start_open: bool) -> Control
1099 func _make_controls_help() -> Control
1132 func _build_actions(column: VBoxContainer) -> void
1177 func _on_winter_pressed() -> void
1188 func set_save_load_enabled(enabled: bool) -> void
1196 func set_toggle(key: String, value: bool) -> void
1201 func _on_save_pressed() -> void
1212 func _on_load_pressed() -> void
1224 func _toggle_panel() -> void
1230 func _make_row(entry: Dictionary) -> Control
1261 func _make_toggle_row(entry: Dictionary) -> Control
1311 func _make_options_row(entry: Dictionary) -> Control
1340 func _option_display(entry: Dictionary, value) -> String
1344 func _cycle_option(entry: Dictionary, direction: int) -> void
1356 func _cascade_prerequisites_on(key: String) -> void
1363 func _cascade_dependents_off(key: String) -> void
1372 func _make_star_row(entry: Dictionary) -> Control
1408 func _adjust(entry: Dictionary, delta: float) -> void
1421 func _format_value(v) -> String
1428 func _on_restart_pressed() -> void
1433 func _on_main_menu_pressed() -> void
1441 func _restart() -> void
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

## hive.gd (921 lines)

The comb as a whole: cells, navigation, finding a cell.

```
48   func add_entrance_mentor(bee: Node2D) -> void
52   func remove_entrance_mentor(bee: Node2D) -> void
55   func record_collection(resource_type: String, amount: float) -> void
61   func record_birth() -> void
64   # --- cell index ---------------------------------------------------
74   func _content_index() -> Dictionary
98   func invalidate_index() -> void
101  func cells_holding(content: String) -> Array
108  func register_tile(hex: Vector2i, node: Node2D) -> void
111  func tile_is_free(hex: Vector2i) -> bool
116  func tile_is_interior(hex: Vector2i) -> bool
121  func cell_at_tile(hex: Vector2i) -> Node2D
127  func _ready() -> void
137  func deposit(resource_type: String, amount: float) -> float
156  func take(resource_type: String, amount: float) -> float
171  func take_energy(energy_wanted: float) -> float
184  func total(resource_type: String) -> float
194  func total_sealed() -> float
202  func total_honey() -> float
209  # --- finding cells ------------------------------------------------
222  func find_cell_for(resource_type: String, except: Node2D = null) -> Node2D
246  func find_designated_cell_for(resource_type: String, except: Node2D = null) -> Node2D
284  func find_empty_cell() -> Node2D
330  func _lay_by_priority(pool: Array) -> Node2D
361  func _tier_weights() -> Array
376  func record_lay(cell: Node2D) -> void
390  func zone_summary() -> Dictionary
420  func brood_stage_counts() -> Dictionary
435  func find_food_cell(except: Node2D = null) -> Node2D
448  func has_room_for_egg() -> bool
451  func find_cell_with(resource_type: String) -> Node2D
464  func find_brood_cell() -> Node2D
479  func find_cell_needing_fanning() -> Node2D
487  func find_honey_target() -> Node2D
490  func find_unfinished_cell() -> Node2D
499  func find_cell_needing_cleaning() -> Node2D
503  func find_cell_needing_eviction() -> Node2D
511  func has_gyne_brood() -> bool
519  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
522  # --- growing the comb ---------------------------------------------
556  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
590  func set_keep_clear(hex: Vector2i, value: bool) -> void
596  func is_keep_clear(hex: Vector2i) -> bool
603  func can_build_on(hex: Vector2i) -> bool
606  func _can_build_on(hex: Vector2i) -> bool
609  func _start_site_at(hex: Vector2i) -> Node2D
625  func create_cell_site_at(hex: Vector2i) -> Node2D
630  # --- navigation ---------------------------------------------------
641  func build_navigation() -> void
682  func _is_solid(hex: Vector2i) -> bool
688  func _tile_cost(hex: Vector2i) -> float
691  func tile_is_walkable(hex: Vector2i) -> bool
700  func nearest_walkable_point(point: Vector2) -> Vector2
727  func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
761  func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
785  func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
795  # --- mining -------------------------------------------------------
804  func refresh_edge_flags() -> void
821  func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
843  func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
862  func _is_markable_block(node) -> bool
869  func mine_stand_hex(block: Node2D)
892  func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
910  func remove_block(block: Node2D, floor_maker: Callable) -> void
920  func announce() -> void
```

## main.gd (1,026 lines)

Per-frame entry point, everything not yet split out of main.

```
307  func _ready() -> void
528  # --- public surface other scripts call directly -------------------
535  func is_on_screen(node: Node2D) -> bool
538  func hive_entrance_inside() -> Vector2
541  func entrance_wait_point(side: int) -> Vector2
544  func move_bee_into_hive(bee: Node2D) -> void
547  func move_bee_out_of_hive(bee: Node2D) -> void
550  func mark_death(bee: Node2D) -> void
553  func finish_mining(block: Node2D) -> void
556  func save_run() -> void
559  func begin_winter_countdown() -> void
562  # --- per-frame ----------------------------------------------------
572  func _process(delta: float) -> void
639  # --- the frame rate readout ----------------------------------------
658  func _sample_fps() -> void
681  func _reseed_meadow(delta: float) -> void
696  func _hatch_ready_brood() -> void
726  func _advance_weather(delta: float) -> void
754  func _apply_rain_overlay() -> void
769  func _check_for_loss() -> void
791  func _check_colony_energy(delta: float) -> void
820  func _role_counts() -> Dictionary
834  func _update_population_readout(bees = null) -> void
855  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
861  func _prune_selection() -> void
874  func _on_restart_after_loss() -> void
880  func _on_level_chosen(level: int) -> void
893  func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
910  func _apply_scenario_boot_arg() -> void
1016 func _end_scenario_run(outcome: String) -> void
```
