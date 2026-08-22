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

## hud.gd (2,176 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
125  static func hatch_options() -> Array
170  static func mode_command(role_id: int, mode_key: String) -> String
359  func _ready() -> void
405  func _make_label(pos: Vector2, font_size: int) -> Label
412  func _info(text: String) -> Button
415  func _with_info(control: Control, tip: String) -> HBoxContainer
434  func _build_top_right_bar() -> void
532  func _icon_button(shape: String, label: String, min_width: float) -> Button
562  func _build_goal_shelf() -> void
618  func set_settings_button_width(width: float) -> void
632  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
647  func set_speed_display(speed_scale: float) -> void
656  func _build_selection_panel() -> void
701  func _build_selection_cog() -> Control
720  func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
731  func _apply_selection_field_visibility() -> void
743  func _build_command_tray() -> void
784  # --- cell popup ---------------------------------------------------
804  func _build_cell_popup() -> void
925  func _cell_section(column: VBoxContainer, title: String, open_by_default: bool) -> VBoxContainer
960  func _build_zone_controls(column: VBoxContainer) -> void
1011 func _build_closing_controls(column: VBoxContainer) -> void
1048 func _build_empty_controls(column: VBoxContainer) -> void
1088 func _make_hatch_menu(entry: Dictionary) -> Control
1104 func _build_flower_popup() -> void
1123 func _build_warning_banner() -> void
1149 func show_warning(text: String) -> void
1156 func set_warnings_muted(value: bool) -> void
1161 func _build_obstacle_popup() -> void
1171 func show_obstacle_popup(obstacle: Node2D, screen_position: Vector2) -> void
1176 func show_flower_popup(flower: Node2D, screen_position: Vector2) -> void
1182 func _refresh_flower_popup() -> void
1209 func _build_soil_popup() -> void
1235 func show_soil_popup(count: int, reachable: int, screen_position: Vector2) -> void
1252 func _build_death_popup() -> void
1262 func show_death_popup(info: Dictionary, screen_position: Vector2) -> void
1280 func show_cell_popup(cell: Node2D, screen_position: Vector2, count: int = 1) -> void
1287 func _refresh_cell_popup() -> void
1377 func _apply_cell_popup_gating() -> void
1391 func _light_current_options() -> void
1409 func _set_lit(key: String, lit: bool) -> void
1420 func _process(_delta: float) -> void
1434 func _request_designation(type: String) -> void
1439 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1444 func _request_empty(method: String) -> void
1449 func _request_zone(in_zone: bool) -> void
1454 func _request_priority(tier: int) -> void
1459 func _request_close(closed: bool) -> void
1464 func _request_fill_close() -> void
1469 # --- discard warning ----------------------------------------------
1475 func _build_discard_dialog() -> void
1488 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1497 func _on_discard_confirmed() -> void
1500 func _on_discard_custom_action(action: StringName) -> void
1507 func _apply_discard() -> void
1515 # --- readouts -----------------------------------------------------
1520 func update_day(day: int, note: String = "") -> void
1530 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1539 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1545 func update_comb(text: String) -> void
1549 func update_energy(mean_fraction: float) -> void
1556 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1567 func update_recruit_gap(text: String) -> void
1577 func update_fps(average: int, frame_ms: float, worst_ms: float) -> void
1582 func update_signals(lines: Array) -> void
1590 func _refresh_corner() -> void
1661 func pinned_stats_changed() -> void
1670 func refresh_speed_visibility() -> void
1677 func refresh_corner() -> void
1680 func update_selection(bees: Array) -> void
1704 func _rebuild_role_controls(bees: Array) -> void
1740 func _build_queen_build_row() -> void
1752 func _build_follow_control(bees: Array, first) -> void
1767 func _build_favourite_row(bee) -> void
1777 func _build_job_row(common_role: int, any_queen: bool) -> void
1805 func _build_doing_row(common_role: int, first) -> void
1831 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
1846 func _build_orders_row(common_role: int, first) -> void
1893 func _build_restock_row(first) -> void
1921 func _build_fallback_row(common_role: int, first) -> void
1951 func _secondary_items() -> Array
1962 func _labelled_row(title: String) -> HBoxContainer
1979 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
1989 func _action_button(label: String, action: Callable, tip: String) -> Control
1996 func _current_role_marker(label: String) -> Control
2005 func _common_role(bees: Array) -> int
2018 func _make_role_menu(label: String, tip: String, items: Array) -> Control
2032 func _refresh_selection_text() -> void
2101 func _update_command_tray_width() -> void
2108 func set_winter_button_visible(value: bool) -> void
2114 func set_view_label(in_hive: bool) -> void
2119 func set_colony_button_visible(value: bool) -> void
2125 func set_nursery_button_visible(value: bool) -> void
2131 func set_view_button_visible(value: bool) -> void
2140 func set_allowed_role_keys(keys: Array) -> void
2145 func set_allowed_mode_keys(keys: Array) -> void
2153 func set_allowed_designation_keys(keys: Array) -> void
2158 func set_hatch_lock_visible(value: bool) -> void
2163 func set_soil_marking_visible(value: bool) -> void
2173 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (1,918 lines)

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
1192 # --- building -----------------------------------------------------
1194 # --- keeping cells topped up ---------------------------------------
1223 func set_restock_targets(cells: Array, resource: String) -> void
1226 func set_restock_sources(cells: Array, allowed: bool) -> void
1229 func clear_restock() -> void
1232 func has_restock_orders() -> bool
1234 # --- mining -------------------------------------------------------
1236 # --- honey making -------------------------------------------------
1238 # --- egg laying (queen only) --------------------------------------
1240 # --- player commands ----------------------------------------------
1250 func command_move_to(world_point: Vector2) -> void
1274 func command_exit_hive() -> void
1283 func set_forage_start_point(meadow_point: Vector2) -> void
1286 func has_forage_start_point() -> bool
1289 func set_preferred_species(species: String) -> void
1302 func set_manual_build_target(hex: Vector2i) -> void
1310 func queue_build_target(hex: Vector2i) -> void
1317 func clear_build_queue() -> void
1323 func _take_next_build_target() -> bool
1336 func set_mine_target(block: Node2D) -> void
1341 func queue_mine_target(block: Node2D) -> void
1347 func clear_mine_queue() -> void
1352 func _next_queued_block() -> Node2D
1360 func set_home_hex(hex: Vector2i) -> void
1369 func set_mine_home_hex(hex: Vector2i) -> void
1375 func _mine_reference_point() -> Vector2
1388 func command_collect_from(flower: Node2D) -> void
1401 func set_focus(type: String) -> void
1428 func set_secondary_role(new_role: int) -> void
1431 func can_take_role(new_role: int) -> bool
1441 func set_role(new_role: int) -> void
1458 func _apply_role(new_role: int) -> void
1484 func _release_everything() -> void
1501 func release_flower_reference(flower: Node2D) -> void
1507 func set_selected(value: bool) -> void
1511 # --- display ------------------------------------------------------
1513 func role_letter() -> String
1531 func idle_reason() -> String
1582 func task_description() -> String
1721 func _idle_backup_note() -> String
1726 func role_name_text() -> String
1750 func nurse_mode_name() -> String
1759 func architect_mode_name() -> String
1765 func carrying_text() -> String
1786 func age_days() -> float
1794 func leave_to_found_colony() -> void
1807 func days_remaining() -> float
1819 func _update_label() -> void
1839 func _update_alarm_ring() -> void
1862 func _update_wander_flight(delta: float) -> void
1885 func _terrain_speed_factor() -> float
1894 func _is_inside_hive() -> bool
1897 # --- getting round things in the meadow ---------------------------
1917 func clear_navigation_state() -> void
```

## debug_panel.gd (1,387 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
880  static func setting_get(key: String)
883  static func setting_set(key: String, value) -> void
904  func _ready() -> void
976  func _report_settings_button_width() -> void
981  func _rows_in(category: String) -> Array
1003 func _make_section(category: String, entries: Array, start_open: bool) -> Control
1042 func _make_controls_help() -> Control
1075 func _build_actions(column: VBoxContainer) -> void
1115 func _on_winter_pressed() -> void
1126 func set_save_load_enabled(enabled: bool) -> void
1134 func set_toggle(key: String, value: bool) -> void
1139 func _on_save_pressed() -> void
1150 func _on_load_pressed() -> void
1162 func _toggle_panel() -> void
1168 func _make_row(entry: Dictionary) -> Control
1197 func _make_toggle_row(entry: Dictionary) -> Control
1246 func _make_options_row(entry: Dictionary) -> Control
1273 func _option_display(entry: Dictionary, value) -> String
1277 func _cycle_option(entry: Dictionary, direction: int) -> void
1290 func _cascade_prerequisites_on(key: String) -> void
1303 func _cascade_dependents_off(key: String) -> void
1315 func _make_star_row(entry: Dictionary) -> Control
1350 func _adjust(entry: Dictionary, delta: float) -> void
1363 func _format_value(v) -> String
1370 func _on_restart_pressed() -> void
1375 func _on_main_menu_pressed() -> void
1383 func _restart() -> void
```

## hive_cell.gd (859 lines)

One cell: contents, brood, honey ripening, how it draws.

```
102  func effective_build_time() -> float
181  func _ready() -> void
260  func set_overlay(mode: String) -> void
266  func _overlay_colour() -> Array
304  func set_selected(value: bool) -> void
312  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE) -> void
320  func _set_outline_points(line: Line2D, size: float) -> void
344  func _process(delta: float) -> void
372  func _develop_brood(delta: float) -> void
393  func _health_factor() -> float
401  func _larva_dies() -> void
410  # --- working positions --------------------------------------------
415  func claim_slot(bee: Node2D) -> int
426  func release_slot(bee: Node2D) -> void
434  func slot_position(index: int) -> Vector2
441  # --- building -----------------------------------------------------
443  func start_as_site() -> void
447  func claim_builder(bee: Node2D) -> void
451  func release_builder(bee: Node2D) -> void
456  func add_build_progress(delta: float) -> void
465  func build_fraction() -> float
468  # --- contents -----------------------------------------------------
470  func is_empty() -> bool
475  func capacity_for(resource_type: String) -> float
484  func accepts(resource_type: String) -> bool
503  func is_nursery_cell() -> bool
506  func space_for(resource_type: String) -> float
522  func needs_eviction() -> bool
540  func add_resource(resource_type: String, requested: float) -> float
564  func take_resource(resource_type: String, requested: float) -> float
586  func can_withdraw() -> bool
591  func set_closed(value: bool) -> void
596  func set_fill_then_close(value: bool) -> void
603  func fill_fraction() -> float
610  func set_designation(resource_type: String) -> void
616  # --- honey ---------------------------------------------------------
618  func is_ripe_honey() -> bool
622  func needs_fanning() -> bool
625  func ripen_fraction() -> float
628  # --- brood ---------------------------------------------------------
630  func start_brood(as_gyne: bool = false) -> void
642  func develop_time() -> float
650  func feed_brood(seconds: float, on_honey: bool) -> void
655  func needs_feeding() -> bool
659  func seconds_until_death() -> float
664  # --- clearing a dead larva ------------------------------------------
666  func needs_cleaning() -> bool
672  func add_clean_progress(delta: float) -> bool
678  func clean_fraction() -> float
681  func brood_ready() -> bool
684  func clear_cell() -> void
696  # --- display ------------------------------------------------------
698  func _refresh() -> void
810  func _designation_tag() -> String
832  func _priority_mark() -> String
845  func _apply_fill_shading() -> void
856  func development_percent() -> float
```

## hive.gd (897 lines)

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
260  func find_empty_cell() -> Node2D
306  func _lay_by_priority(pool: Array) -> Node2D
337  func _tier_weights() -> Array
352  func record_lay(cell: Node2D) -> void
366  func zone_summary() -> Dictionary
396  func brood_stage_counts() -> Dictionary
411  func find_food_cell(except: Node2D = null) -> Node2D
424  func has_room_for_egg() -> bool
427  func find_cell_with(resource_type: String) -> Node2D
440  func find_brood_cell() -> Node2D
455  func find_cell_needing_fanning() -> Node2D
463  func find_honey_target() -> Node2D
466  func find_unfinished_cell() -> Node2D
475  func find_cell_needing_cleaning() -> Node2D
479  func find_cell_needing_eviction() -> Node2D
487  func has_gyne_brood() -> bool
495  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
498  # --- growing the comb ---------------------------------------------
532  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
566  func set_keep_clear(hex: Vector2i, value: bool) -> void
572  func is_keep_clear(hex: Vector2i) -> bool
579  func can_build_on(hex: Vector2i) -> bool
582  func _can_build_on(hex: Vector2i) -> bool
585  func _start_site_at(hex: Vector2i) -> Node2D
601  func create_cell_site_at(hex: Vector2i) -> Node2D
606  # --- navigation ---------------------------------------------------
617  func build_navigation() -> void
658  func _is_solid(hex: Vector2i) -> bool
664  func _tile_cost(hex: Vector2i) -> float
667  func tile_is_walkable(hex: Vector2i) -> bool
676  func nearest_walkable_point(point: Vector2) -> Vector2
703  func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
737  func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
761  func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
771  # --- mining -------------------------------------------------------
780  func refresh_edge_flags() -> void
797  func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
819  func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
838  func _is_markable_block(node) -> bool
845  func mine_stand_hex(block: Node2D)
868  func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
886  func remove_block(block: Node2D, floor_maker: Callable) -> void
896  func announce() -> void
```

## main.gd (948 lines)

Per-frame entry point, everything not yet split out of main.

```
286  func _ready() -> void
502  # --- public surface other scripts call directly -------------------
509  func is_on_screen(node: Node2D) -> bool
512  func hive_entrance_inside() -> Vector2
515  func entrance_wait_point(side: int) -> Vector2
518  func move_bee_into_hive(bee: Node2D) -> void
521  func move_bee_out_of_hive(bee: Node2D) -> void
524  func mark_death(bee: Node2D) -> void
527  func finish_mining(block: Node2D) -> void
530  func save_run() -> void
533  func begin_winter_countdown() -> void
536  # --- per-frame ----------------------------------------------------
546  func _process(delta: float) -> void
592  # --- the frame rate readout ----------------------------------------
611  func _sample_fps() -> void
634  func _reseed_meadow(delta: float) -> void
649  func _hatch_ready_brood() -> void
679  func _advance_weather(delta: float) -> void
707  func _apply_rain_overlay() -> void
722  func _check_for_loss() -> void
744  func _check_colony_energy(delta: float) -> void
773  func _role_counts() -> Dictionary
787  func _update_population_readout(bees = null) -> void
808  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
814  func _prune_selection() -> void
827  func _on_restart_after_loss() -> void
833  func _on_level_chosen(level: int) -> void
846  func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
863  func _apply_scenario_boot_arg() -> void
938  func _end_scenario_run(outcome: String) -> void
```
