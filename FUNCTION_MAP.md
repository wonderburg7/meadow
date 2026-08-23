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

## hud.gd (2,336 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
127  static func hatch_options() -> Array
172  static func mode_command(role_id: int, mode_key: String) -> String
380  func _ready() -> void
422  func _make_label(pos: Vector2, variation: String = "Body") -> Label
430  func _info(text: String) -> Button
433  func _with_info(control: Control, tip: String) -> HBoxContainer
438  func _style_button(button: BaseButton) -> BaseButton
459  func _build_top_right_bar() -> void
571  func _icon_button(shape: String, label: String, min_width: float) -> Button
606  func _apply_interface_label_visibility() -> void
616  func _build_goal_shelf() -> void
675  func set_settings_button_width(width: float) -> void
689  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
704  func set_speed_display(speed_scale: float) -> void
713  func _build_selection_panel() -> void
777  func _build_selection_cog() -> Control
797  func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
808  func _apply_selection_field_visibility() -> void
820  func _build_command_tray() -> void
882  func _build_tray_column(title: String) -> Array
900  # --- cell popup ---------------------------------------------------
928  func _build_cell_group(parent: VBoxContainer) -> void
1058 func _cell_section(column: VBoxContainer, title: String, open_by_default: bool) -> VBoxContainer
1091 func _build_zone_controls(column: VBoxContainer) -> void
1146 func _build_closing_controls(column: VBoxContainer) -> void
1186 func _build_empty_controls(column: VBoxContainer) -> void
1229 func _make_hatch_menu(entry: Dictionary) -> Control
1253 func _build_warning_banner() -> void
1282 func show_warning(text: String) -> void
1289 func set_warnings_muted(value: bool) -> void
1302 func show_object_summary(kind: String, data) -> void
1320 func _refresh_flower_summary() -> void
1345 func _show_obstacle_summary(obstacle: Node2D) -> void
1351 func _show_soil_summary(count: int, reachable: int) -> void
1367 func _show_death_summary(info: Dictionary) -> void
1391 func show_cell_popup(cell: Node2D, count: int = 1) -> void
1401 func _refresh_cell_popup() -> void
1491 func _apply_cell_popup_gating() -> void
1505 func _light_current_options() -> void
1523 func _set_lit(key: String, lit: bool) -> void
1534 func _process(_delta: float) -> void
1549 func _request_designation(type: String) -> void
1554 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1559 func _request_empty(method: String) -> void
1564 func _request_zone(in_zone: bool) -> void
1569 func _request_priority(tier: int) -> void
1574 func _request_close(closed: bool) -> void
1579 func _request_fill_close() -> void
1584 # --- discard warning ----------------------------------------------
1590 func _build_discard_dialog() -> void
1605 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1614 func _on_discard_confirmed() -> void
1617 func _on_discard_custom_action(action: StringName) -> void
1624 func _apply_discard() -> void
1632 # --- readouts -----------------------------------------------------
1637 func update_day(day: int, note: String = "") -> void
1647 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1656 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1662 func update_comb(text: String) -> void
1666 func update_energy(mean_fraction: float) -> void
1673 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1684 func update_recruit_gap(text: String) -> void
1697 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
1703 func update_signals(lines: Array) -> void
1711 func _refresh_corner() -> void
1786 func pinned_stats_changed() -> void
1795 func refresh_speed_visibility() -> void
1802 func refresh_corner() -> void
1805 func update_selection(bees: Array) -> void
1836 func _rebuild_role_controls(bees: Array) -> void
1880 func _build_queen_build_row() -> void
1894 func _build_follow_control(bees: Array, first) -> void
1910 func _build_favourite_row(bee) -> void
1921 func _build_job_row(common_role: int, any_queen: bool) -> void
1949 func _build_doing_row(common_role: int, first) -> void
1975 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
1990 func _build_orders_row(common_role: int, first) -> void
2037 func _build_restock_row(first) -> void
2065 func _build_fallback_row(common_role: int, first) -> void
2097 func _secondary_items() -> Array
2111 func _column_row(parent: Container) -> HBoxContainer
2117 func _labelled_row(title: String) -> HBoxContainer
2134 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2145 func _action_button(label: String, action: Callable, tip: String) -> Control
2153 func _current_role_marker(label: String) -> Control
2163 func _common_role(bees: Array) -> int
2176 func _make_role_menu(label: String, tip: String, items: Array) -> Control
2191 func _refresh_selection_text() -> void
2261 func _update_command_tray_width() -> void
2268 func set_winter_button_visible(value: bool) -> void
2274 func set_view_label(in_hive: bool) -> void
2279 func set_colony_button_visible(value: bool) -> void
2285 func set_nursery_button_visible(value: bool) -> void
2291 func set_view_button_visible(value: bool) -> void
2300 func set_allowed_role_keys(keys: Array) -> void
2305 func set_allowed_mode_keys(keys: Array) -> void
2313 func set_allowed_designation_keys(keys: Array) -> void
2318 func set_hatch_lock_visible(value: bool) -> void
2323 func set_soil_marking_visible(value: bool) -> void
2333 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (2,094 lines)

A bee's dispatch loop, player commands, display text, vars.

```
490  func _ready() -> void
627  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
664  func _roll_fact() -> void
678  func _default_state_for_role() -> int
700  func _base_colour() -> Color
711  func _tinted(c: Color) -> Color
726  func _apply_stats() -> void
752  func trait_text() -> String
761  func _update_role_marker() -> void
780  # --- how often a bee thinks ---------------------------------------
804  func _process(delta: float) -> void
1053 # --- life support -------------------------------------------------
1055 # --- eating -------------------------------------------------------
1057 # --- stall watchdog -----------------------------------------------
1063 func _reset_stall_watch() -> void
1066 # --- foraging -----------------------------------------------------
1068 # --- entering and leaving the hive --------------------------------
1070 # --- nursery work -------------------------------------------------
1072 # --- royal jelly ---------------------------------------------------
1074 # --- idle work dispatch --------------------------------------------
1088 func _apply_pending_role() -> bool
1100 func _is_busy() -> bool
1106 func _idle_dispatch() -> void
1132 func _maybe_break_off_secondary() -> void
1156 func _try_role_work(r: int) -> bool
1334 # --- building -----------------------------------------------------
1336 # --- keeping cells topped up ---------------------------------------
1365 func set_restock_targets(cells: Array, resource: String) -> void
1368 func set_restock_sources(cells: Array, allowed: bool) -> void
1371 func clear_restock() -> void
1374 func has_restock_orders() -> bool
1376 # --- mining -------------------------------------------------------
1378 # --- honey making -------------------------------------------------
1380 # --- egg laying (queen only) --------------------------------------
1382 # --- player commands ----------------------------------------------
1392 func command_move_to(world_point: Vector2) -> void
1416 func command_exit_hive() -> void
1425 func set_forage_start_point(meadow_point: Vector2) -> void
1430 func has_forage_start_point() -> bool
1433 func set_preferred_species(species: String) -> void
1446 func set_manual_build_target(hex: Vector2i) -> void
1454 func queue_build_target(hex: Vector2i) -> void
1461 func clear_build_queue() -> void
1467 func _take_next_build_target() -> bool
1480 func set_mine_target(block: Node2D) -> void
1485 func queue_mine_target(block: Node2D) -> void
1491 func clear_mine_queue() -> void
1496 func _next_queued_block() -> Node2D
1504 func set_home_hex(hex: Vector2i) -> void
1513 func set_mine_home_hex(hex: Vector2i) -> void
1519 func _mine_reference_point() -> Vector2
1532 func command_collect_from(flower: Node2D) -> void
1545 func set_focus(type: String) -> void
1572 func set_secondary_role(new_role: int) -> void
1575 func can_take_role(new_role: int) -> bool
1585 func set_role(new_role: int) -> void
1602 func _apply_role(new_role: int) -> void
1628 func _release_everything() -> void
1645 func release_flower_reference(flower: Node2D) -> void
1651 func set_selected(value: bool) -> void
1655 # --- display ------------------------------------------------------
1657 func role_letter() -> String
1675 func idle_reason() -> String
1726 func task_description() -> String
1867 func _idle_backup_note() -> String
1872 func role_name_text() -> String
1896 func nurse_mode_name() -> String
1905 func architect_mode_name() -> String
1911 func carrying_text() -> String
1932 func age_days() -> float
1940 func leave_to_found_colony() -> void
1953 func days_remaining() -> float
1965 func _update_label() -> void
1985 func _update_alarm_ring() -> void
1996 func _update_heading_marker() -> void
2010 func _update_search_ring() -> void
2038 func _update_wander_flight(delta: float) -> void
2061 func _terrain_speed_factor() -> float
2070 func _is_inside_hive() -> bool
2073 # --- getting round things in the meadow ---------------------------
2093 func clear_navigation_state() -> void
```

## debug_panel.gd (1,502 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
901  static func setting_get(key: String)
904  static func setting_set(key: String, value) -> void
919  static func apply_setting(key: String, value) -> void
932  static func _cascade_prerequisites_on_static(key: String) -> Array[String]
946  static func _cascade_dependents_off_static(key: String) -> Array[String]
971  func _style_button(button: BaseButton) -> BaseButton
976  func _ready() -> void
1052 func _report_settings_button_width() -> void
1057 func _rows_in(category: String) -> Array
1079 func _make_section(category: String, entries: Array, start_open: bool) -> Control
1119 func _make_controls_help() -> Control
1152 func _build_actions(column: VBoxContainer) -> void
1197 func _on_winter_pressed() -> void
1208 func set_save_load_enabled(enabled: bool) -> void
1216 func set_toggle(key: String, value: bool) -> void
1221 func _on_save_pressed() -> void
1232 func _on_load_pressed() -> void
1244 func _toggle_panel() -> void
1250 func _make_row(entry: Dictionary) -> Control
1289 func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
1313 func _make_toggle_row(entry: Dictionary) -> Control
1368 func _make_options_row(entry: Dictionary) -> Control
1397 func _option_display(entry: Dictionary, value) -> String
1401 func _cycle_option(entry: Dictionary, direction: int) -> void
1413 func _cascade_prerequisites_on(key: String) -> void
1420 func _cascade_dependents_off(key: String) -> void
1429 func _make_star_row(entry: Dictionary) -> Control
1465 func _adjust(entry: Dictionary, delta: float) -> void
1478 func _format_value(v) -> String
1485 func _on_restart_pressed() -> void
1490 func _on_main_menu_pressed() -> void
1498 func _restart() -> void
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

## main.gd (1,042 lines)

Per-frame entry point, everything not yet split out of main.

```
317  func _ready() -> void
544  # --- public surface other scripts call directly -------------------
551  func is_on_screen(node: Node2D) -> bool
554  func hive_entrance_inside() -> Vector2
557  func entrance_wait_point(side: int) -> Vector2
560  func move_bee_into_hive(bee: Node2D) -> void
563  func move_bee_out_of_hive(bee: Node2D) -> void
566  func mark_death(bee: Node2D) -> void
569  func finish_mining(block: Node2D) -> void
572  func save_run() -> void
575  func begin_winter_countdown() -> void
578  # --- per-frame ----------------------------------------------------
588  func _process(delta: float) -> void
655  # --- the frame rate readout ----------------------------------------
674  func _sample_fps() -> void
697  func _reseed_meadow(delta: float) -> void
712  func _hatch_ready_brood() -> void
742  func _advance_weather(delta: float) -> void
770  func _apply_rain_overlay() -> void
785  func _check_for_loss() -> void
807  func _check_colony_energy(delta: float) -> void
836  func _role_counts() -> Dictionary
850  func _update_population_readout(bees = null) -> void
871  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
877  func _prune_selection() -> void
890  func _on_restart_after_loss() -> void
896  func _on_level_chosen(level: int) -> void
909  func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
926  func _apply_scenario_boot_arg() -> void
1032 func _end_scenario_run(outcome: String) -> void
```
