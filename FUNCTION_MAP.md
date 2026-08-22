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

## bee.gd (1,929 lines)

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
1203 # --- building -----------------------------------------------------
1205 # --- keeping cells topped up ---------------------------------------
1234 func set_restock_targets(cells: Array, resource: String) -> void
1237 func set_restock_sources(cells: Array, allowed: bool) -> void
1240 func clear_restock() -> void
1243 func has_restock_orders() -> bool
1245 # --- mining -------------------------------------------------------
1247 # --- honey making -------------------------------------------------
1249 # --- egg laying (queen only) --------------------------------------
1251 # --- player commands ----------------------------------------------
1261 func command_move_to(world_point: Vector2) -> void
1285 func command_exit_hive() -> void
1294 func set_forage_start_point(meadow_point: Vector2) -> void
1297 func has_forage_start_point() -> bool
1300 func set_preferred_species(species: String) -> void
1313 func set_manual_build_target(hex: Vector2i) -> void
1321 func queue_build_target(hex: Vector2i) -> void
1328 func clear_build_queue() -> void
1334 func _take_next_build_target() -> bool
1347 func set_mine_target(block: Node2D) -> void
1352 func queue_mine_target(block: Node2D) -> void
1358 func clear_mine_queue() -> void
1363 func _next_queued_block() -> Node2D
1371 func set_home_hex(hex: Vector2i) -> void
1380 func set_mine_home_hex(hex: Vector2i) -> void
1386 func _mine_reference_point() -> Vector2
1399 func command_collect_from(flower: Node2D) -> void
1412 func set_focus(type: String) -> void
1439 func set_secondary_role(new_role: int) -> void
1442 func can_take_role(new_role: int) -> bool
1452 func set_role(new_role: int) -> void
1469 func _apply_role(new_role: int) -> void
1495 func _release_everything() -> void
1512 func release_flower_reference(flower: Node2D) -> void
1518 func set_selected(value: bool) -> void
1522 # --- display ------------------------------------------------------
1524 func role_letter() -> String
1542 func idle_reason() -> String
1593 func task_description() -> String
1732 func _idle_backup_note() -> String
1737 func role_name_text() -> String
1761 func nurse_mode_name() -> String
1770 func architect_mode_name() -> String
1776 func carrying_text() -> String
1797 func age_days() -> float
1805 func leave_to_found_colony() -> void
1818 func days_remaining() -> float
1830 func _update_label() -> void
1850 func _update_alarm_ring() -> void
1873 func _update_wander_flight(delta: float) -> void
1896 func _terrain_speed_factor() -> float
1905 func _is_inside_hive() -> bool
1908 # --- getting round things in the meadow ---------------------------
1928 func clear_navigation_state() -> void
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

## main.gd (955 lines)

Per-frame entry point, everything not yet split out of main.

```
288  func _ready() -> void
509  # --- public surface other scripts call directly -------------------
516  func is_on_screen(node: Node2D) -> bool
519  func hive_entrance_inside() -> Vector2
522  func entrance_wait_point(side: int) -> Vector2
525  func move_bee_into_hive(bee: Node2D) -> void
528  func move_bee_out_of_hive(bee: Node2D) -> void
531  func mark_death(bee: Node2D) -> void
534  func finish_mining(block: Node2D) -> void
537  func save_run() -> void
540  func begin_winter_countdown() -> void
543  # --- per-frame ----------------------------------------------------
553  func _process(delta: float) -> void
599  # --- the frame rate readout ----------------------------------------
618  func _sample_fps() -> void
641  func _reseed_meadow(delta: float) -> void
656  func _hatch_ready_brood() -> void
686  func _advance_weather(delta: float) -> void
714  func _apply_rain_overlay() -> void
729  func _check_for_loss() -> void
751  func _check_colony_energy(delta: float) -> void
780  func _role_counts() -> Dictionary
794  func _update_population_readout(bees = null) -> void
815  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
821  func _prune_selection() -> void
834  func _on_restart_after_loss() -> void
840  func _on_level_chosen(level: int) -> void
853  func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
870  func _apply_scenario_boot_arg() -> void
945  func _end_scenario_run(outcome: String) -> void
```
