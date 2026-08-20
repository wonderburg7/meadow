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

## hud.gd (1,794 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
116  static func hatch_options() -> Array
156  static func mode_command(role_id: int, mode_key: String) -> String
305  func _ready() -> void
348  func _make_label(pos: Vector2, font_size: int) -> Label
355  func _info(text: String) -> Button
358  func _with_info(control: Control, tip: String) -> HBoxContainer
371  func _build_top_right_bar() -> void
457  func set_settings_button_width(width: float) -> void
465  func set_challenge_goal(text: String) -> void
469  func set_speed_display(speed_scale: float) -> void
473  func _build_selection_panel() -> void
509  # --- cell popup ---------------------------------------------------
529  func _build_cell_popup() -> void
650  func _cell_section(column: VBoxContainer, title: String, open_by_default: bool) -> VBoxContainer
685  func _build_zone_controls(column: VBoxContainer) -> void
736  func _build_closing_controls(column: VBoxContainer) -> void
773  func _build_empty_controls(column: VBoxContainer) -> void
813  func _make_hatch_menu(entry: Dictionary) -> Control
829  func _build_flower_popup() -> void
848  func _build_warning_banner() -> void
874  func show_warning(text: String) -> void
881  func set_warnings_muted(value: bool) -> void
886  func _build_obstacle_popup() -> void
896  func show_obstacle_popup(obstacle: Node2D, screen_position: Vector2) -> void
901  func show_flower_popup(flower: Node2D, screen_position: Vector2) -> void
907  func _refresh_flower_popup() -> void
934  func _build_soil_popup() -> void
960  func show_soil_popup(count: int, reachable: int, screen_position: Vector2) -> void
970  func show_cell_popup(cell: Node2D, screen_position: Vector2, count: int = 1) -> void
977  func _refresh_cell_popup() -> void
1067 func _apply_cell_popup_gating() -> void
1081 func _light_current_options() -> void
1099 func _set_lit(key: String, lit: bool) -> void
1110 func _process(_delta: float) -> void
1124 func _request_designation(type: String) -> void
1129 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1134 func _request_empty(method: String) -> void
1139 func _request_zone(in_zone: bool) -> void
1144 func _request_priority(tier: int) -> void
1149 func _request_close(closed: bool) -> void
1154 func _request_fill_close() -> void
1159 # --- discard warning ----------------------------------------------
1165 func _build_discard_dialog() -> void
1178 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1187 func _on_discard_confirmed() -> void
1190 func _on_discard_custom_action(action: StringName) -> void
1196 func _apply_discard() -> void
1204 # --- readouts -----------------------------------------------------
1209 func update_day(day: int, note: String = "") -> void
1219 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1228 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1234 func update_comb(text: String) -> void
1238 func update_energy(mean_fraction: float) -> void
1245 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1257 func update_fps(average: int, frame_ms: float, worst_ms: float) -> void
1262 func update_signals(lines: Array) -> void
1270 func _refresh_corner() -> void
1341 func pinned_stats_changed() -> void
1348 func refresh_corner() -> void
1351 func update_selection(bees: Array) -> void
1374 func _rebuild_role_controls(bees: Array) -> void
1401 func _build_queen_build_row() -> void
1413 func _build_favourite_row(bee) -> void
1423 func _build_job_row(common_role: int, any_queen: bool) -> void
1451 func _build_doing_row(common_role: int, first) -> void
1478 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
1493 func _build_orders_row(common_role: int, first) -> void
1541 func _build_restock_row(first) -> void
1572 func _build_fallback_row(common_role: int, first) -> void
1602 func _secondary_items() -> Array
1613 func _labelled_row(title: String) -> HBoxContainer
1630 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
1640 func _action_button(label: String, action: Callable, tip: String) -> Control
1647 func _current_role_marker(label: String) -> Control
1656 func _common_role(bees: Array) -> int
1669 func _make_role_menu(label: String, tip: String, items: Array) -> Control
1680 func _refresh_selection_text() -> void
1730 func set_winter_button_visible(value: bool) -> void
1734 func set_view_label(in_hive: bool) -> void
1737 func set_colony_button_visible(value: bool) -> void
1743 func set_nursery_button_visible(value: bool) -> void
1749 func set_view_button_visible(value: bool) -> void
1758 func set_allowed_role_keys(keys: Array) -> void
1763 func set_allowed_mode_keys(keys: Array) -> void
1771 func set_allowed_designation_keys(keys: Array) -> void
1776 func set_hatch_lock_visible(value: bool) -> void
1781 func set_soil_marking_visible(value: bool) -> void
1791 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (1,735 lines)

A bee's dispatch loop, player commands, display text, vars.

```
304  func _ready() -> void
390  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
427  func _roll_fact() -> void
441  func _default_state_for_role() -> int
463  func _base_colour() -> Color
474  func _tinted(c: Color) -> Color
489  func _apply_stats() -> void
515  func trait_text() -> String
524  func _update_role_marker() -> void
543  # --- how often a bee thinks ---------------------------------------
567  func _process(delta: float) -> void
787  # --- life support -------------------------------------------------
789  # --- eating -------------------------------------------------------
791  # --- stall watchdog -----------------------------------------------
797  func _reset_stall_watch() -> void
800  # --- foraging -----------------------------------------------------
802  # --- entering and leaving the hive --------------------------------
804  # --- nursery work -------------------------------------------------
806  # --- royal jelly ---------------------------------------------------
808  # --- idle work dispatch --------------------------------------------
822  func _apply_pending_role() -> bool
834  func _is_busy() -> bool
840  func _idle_dispatch() -> void
866  func _maybe_break_off_secondary() -> void
890  func _try_role_work(r: int) -> bool
1055 # --- building -----------------------------------------------------
1057 # --- keeping cells topped up ---------------------------------------
1086 func set_restock_targets(cells: Array, resource: String) -> void
1089 func set_restock_sources(cells: Array, allowed: bool) -> void
1092 func clear_restock() -> void
1095 func has_restock_orders() -> bool
1097 # --- mining -------------------------------------------------------
1099 # --- honey making -------------------------------------------------
1101 # --- egg laying (queen only) --------------------------------------
1103 # --- player commands ----------------------------------------------
1113 func command_move_to(world_point: Vector2) -> void
1137 func command_exit_hive() -> void
1146 func set_forage_start_point(meadow_point: Vector2) -> void
1149 func has_forage_start_point() -> bool
1152 func set_preferred_species(species: String) -> void
1165 func set_manual_build_target(hex: Vector2i) -> void
1173 func queue_build_target(hex: Vector2i) -> void
1180 func clear_build_queue() -> void
1186 func _take_next_build_target() -> bool
1199 func set_mine_target(block: Node2D) -> void
1204 func queue_mine_target(block: Node2D) -> void
1210 func clear_mine_queue() -> void
1215 func _next_queued_block() -> Node2D
1223 func set_home_hex(hex: Vector2i) -> void
1232 func set_mine_home_hex(hex: Vector2i) -> void
1238 func _mine_reference_point() -> Vector2
1251 func command_collect_from(flower: Node2D) -> void
1263 func set_focus(type: String) -> void
1290 func set_secondary_role(new_role: int) -> void
1293 func can_take_role(new_role: int) -> bool
1303 func set_role(new_role: int) -> void
1320 func _apply_role(new_role: int) -> void
1346 func _release_everything() -> void
1363 func release_flower_reference(flower: Node2D) -> void
1369 func set_selected(value: bool) -> void
1373 # --- display ------------------------------------------------------
1375 func role_letter() -> String
1393 func idle_reason() -> String
1444 func task_description() -> String
1583 func _idle_backup_note() -> String
1588 func role_name_text() -> String
1612 func nurse_mode_name() -> String
1621 func architect_mode_name() -> String
1627 func carrying_text() -> String
1648 func age_days() -> float
1656 func leave_to_found_colony() -> void
1669 func days_remaining() -> float
1681 func _update_label() -> void
1702 func _terrain_speed_factor() -> float
1711 func _is_inside_hive() -> bool
1714 # --- getting round things in the meadow ---------------------------
1734 func clear_navigation_state() -> void
```

## debug_panel.gd (1,209 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
771  static func setting_get(key: String)
774  static func setting_set(key: String, value) -> void
794  func _ready() -> void
860  func _report_settings_button_width() -> void
865  func _rows_in(category: String) -> Array
887  func _make_section(category: String, entries: Array, start_open: bool) -> Control
924  func _make_controls_help() -> Control
957  func _build_actions(column: VBoxContainer) -> void
997  func _on_winter_pressed() -> void
1008 func set_save_load_enabled(enabled: bool) -> void
1016 func set_toggle(key: String, value: bool) -> void
1021 func _on_save_pressed() -> void
1032 func _on_load_pressed() -> void
1044 func _toggle_panel() -> void
1050 func _make_row(entry: Dictionary) -> Control
1079 func _make_toggle_row(entry: Dictionary) -> Control
1120 func _cascade_prerequisites_on(key: String) -> void
1133 func _cascade_dependents_off(key: String) -> void
1145 func _make_star_row(entry: Dictionary) -> Control
1179 func _adjust(entry: Dictionary, delta: float) -> void
1185 func _format_value(v) -> String
1192 func _on_restart_pressed() -> void
1197 func _on_main_menu_pressed() -> void
1205 func _restart() -> void
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

## hive.gd (879 lines)

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
393  func find_food_cell(except: Node2D = null) -> Node2D
406  func has_room_for_egg() -> bool
409  func find_cell_with(resource_type: String) -> Node2D
422  func find_brood_cell() -> Node2D
437  func find_cell_needing_fanning() -> Node2D
445  func find_honey_target() -> Node2D
448  func find_unfinished_cell() -> Node2D
457  func find_cell_needing_cleaning() -> Node2D
461  func find_cell_needing_eviction() -> Node2D
469  func has_gyne_brood() -> bool
477  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
480  # --- growing the comb ---------------------------------------------
514  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
548  func set_keep_clear(hex: Vector2i, value: bool) -> void
554  func is_keep_clear(hex: Vector2i) -> bool
561  func can_build_on(hex: Vector2i) -> bool
564  func _can_build_on(hex: Vector2i) -> bool
567  func _start_site_at(hex: Vector2i) -> Node2D
583  func create_cell_site_at(hex: Vector2i) -> Node2D
588  # --- navigation ---------------------------------------------------
599  func build_navigation() -> void
640  func _is_solid(hex: Vector2i) -> bool
646  func _tile_cost(hex: Vector2i) -> float
649  func tile_is_walkable(hex: Vector2i) -> bool
658  func nearest_walkable_point(point: Vector2) -> Vector2
685  func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
719  func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
743  func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
753  # --- mining -------------------------------------------------------
762  func refresh_edge_flags() -> void
779  func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
801  func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
820  func _is_markable_block(node) -> bool
827  func mine_stand_hex(block: Node2D)
850  func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
868  func remove_block(block: Node2D, floor_maker: Callable) -> void
878  func announce() -> void
```

## main.gd (801 lines)

Per-frame entry point, everything not yet split out of main.

```
264  func _ready() -> void
468  # --- public surface other scripts call directly -------------------
475  func is_on_screen(node: Node2D) -> bool
478  func hive_entrance_inside() -> Vector2
481  func entrance_wait_point(side: int) -> Vector2
484  func move_bee_into_hive(bee: Node2D) -> void
487  func move_bee_out_of_hive(bee: Node2D) -> void
490  func mark_death(bee: Node2D) -> void
493  func finish_mining(block: Node2D) -> void
496  func save_run() -> void
499  func begin_winter_countdown() -> void
502  # --- per-frame ----------------------------------------------------
512  func _process(delta: float) -> void
551  # --- the frame rate readout ----------------------------------------
570  func _sample_fps() -> void
593  func _reseed_meadow(delta: float) -> void
608  func _hatch_ready_brood() -> void
638  func _advance_weather(delta: float) -> void
666  func _apply_rain_overlay() -> void
681  func _check_for_loss() -> void
700  func _check_colony_energy(delta: float) -> void
729  func _role_counts() -> Dictionary
743  func _update_population_readout(bees = null) -> void
764  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
770  func _prune_selection() -> void
783  func _on_restart_after_loss() -> void
789  func _on_level_chosen(level: int) -> void
```
