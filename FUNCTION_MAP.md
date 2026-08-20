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

## hud.gd (1,833 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
116  static func hatch_options() -> Array
156  static func mode_command(role_id: int, mode_key: String) -> String
308  func _ready() -> void
352  func _make_label(pos: Vector2, font_size: int) -> Label
359  func _info(text: String) -> Button
362  func _with_info(control: Control, tip: String) -> HBoxContainer
375  func _build_top_right_bar() -> void
461  func set_settings_button_width(width: float) -> void
469  func set_challenge_goal(text: String) -> void
473  func set_speed_display(speed_scale: float) -> void
477  func _build_selection_panel() -> void
513  # --- cell popup ---------------------------------------------------
533  func _build_cell_popup() -> void
654  func _cell_section(column: VBoxContainer, title: String, open_by_default: bool) -> VBoxContainer
689  func _build_zone_controls(column: VBoxContainer) -> void
740  func _build_closing_controls(column: VBoxContainer) -> void
777  func _build_empty_controls(column: VBoxContainer) -> void
817  func _make_hatch_menu(entry: Dictionary) -> Control
833  func _build_flower_popup() -> void
852  func _build_warning_banner() -> void
878  func show_warning(text: String) -> void
885  func set_warnings_muted(value: bool) -> void
890  func _build_obstacle_popup() -> void
900  func show_obstacle_popup(obstacle: Node2D, screen_position: Vector2) -> void
905  func show_flower_popup(flower: Node2D, screen_position: Vector2) -> void
911  func _refresh_flower_popup() -> void
938  func _build_soil_popup() -> void
964  func show_soil_popup(count: int, reachable: int, screen_position: Vector2) -> void
981  func _build_death_popup() -> void
991  func show_death_popup(info: Dictionary, screen_position: Vector2) -> void
1009 func show_cell_popup(cell: Node2D, screen_position: Vector2, count: int = 1) -> void
1016 func _refresh_cell_popup() -> void
1106 func _apply_cell_popup_gating() -> void
1120 func _light_current_options() -> void
1138 func _set_lit(key: String, lit: bool) -> void
1149 func _process(_delta: float) -> void
1163 func _request_designation(type: String) -> void
1168 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1173 func _request_empty(method: String) -> void
1178 func _request_zone(in_zone: bool) -> void
1183 func _request_priority(tier: int) -> void
1188 func _request_close(closed: bool) -> void
1193 func _request_fill_close() -> void
1198 # --- discard warning ----------------------------------------------
1204 func _build_discard_dialog() -> void
1217 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1226 func _on_discard_confirmed() -> void
1229 func _on_discard_custom_action(action: StringName) -> void
1235 func _apply_discard() -> void
1243 # --- readouts -----------------------------------------------------
1248 func update_day(day: int, note: String = "") -> void
1258 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1267 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1273 func update_comb(text: String) -> void
1277 func update_energy(mean_fraction: float) -> void
1284 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1296 func update_fps(average: int, frame_ms: float, worst_ms: float) -> void
1301 func update_signals(lines: Array) -> void
1309 func _refresh_corner() -> void
1380 func pinned_stats_changed() -> void
1387 func refresh_corner() -> void
1390 func update_selection(bees: Array) -> void
1413 func _rebuild_role_controls(bees: Array) -> void
1440 func _build_queen_build_row() -> void
1452 func _build_favourite_row(bee) -> void
1462 func _build_job_row(common_role: int, any_queen: bool) -> void
1490 func _build_doing_row(common_role: int, first) -> void
1517 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
1532 func _build_orders_row(common_role: int, first) -> void
1580 func _build_restock_row(first) -> void
1611 func _build_fallback_row(common_role: int, first) -> void
1641 func _secondary_items() -> Array
1652 func _labelled_row(title: String) -> HBoxContainer
1669 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
1679 func _action_button(label: String, action: Callable, tip: String) -> Control
1686 func _current_role_marker(label: String) -> Control
1695 func _common_role(bees: Array) -> int
1708 func _make_role_menu(label: String, tip: String, items: Array) -> Control
1719 func _refresh_selection_text() -> void
1769 func set_winter_button_visible(value: bool) -> void
1773 func set_view_label(in_hive: bool) -> void
1776 func set_colony_button_visible(value: bool) -> void
1782 func set_nursery_button_visible(value: bool) -> void
1788 func set_view_button_visible(value: bool) -> void
1797 func set_allowed_role_keys(keys: Array) -> void
1802 func set_allowed_mode_keys(keys: Array) -> void
1810 func set_allowed_designation_keys(keys: Array) -> void
1815 func set_hatch_lock_visible(value: bool) -> void
1820 func set_soil_marking_visible(value: bool) -> void
1830 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (1,807 lines)

A bee's dispatch loop, player commands, display text, vars.

```
346  func _ready() -> void
452  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
489  func _roll_fact() -> void
503  func _default_state_for_role() -> int
525  func _base_colour() -> Color
536  func _tinted(c: Color) -> Color
551  func _apply_stats() -> void
577  func trait_text() -> String
586  func _update_role_marker() -> void
605  # --- how often a bee thinks ---------------------------------------
629  func _process(delta: float) -> void
850  # --- life support -------------------------------------------------
852  # --- eating -------------------------------------------------------
854  # --- stall watchdog -----------------------------------------------
860  func _reset_stall_watch() -> void
863  # --- foraging -----------------------------------------------------
865  # --- entering and leaving the hive --------------------------------
867  # --- nursery work -------------------------------------------------
869  # --- royal jelly ---------------------------------------------------
871  # --- idle work dispatch --------------------------------------------
885  func _apply_pending_role() -> bool
897  func _is_busy() -> bool
903  func _idle_dispatch() -> void
929  func _maybe_break_off_secondary() -> void
953  func _try_role_work(r: int) -> bool
1118 # --- building -----------------------------------------------------
1120 # --- keeping cells topped up ---------------------------------------
1149 func set_restock_targets(cells: Array, resource: String) -> void
1152 func set_restock_sources(cells: Array, allowed: bool) -> void
1155 func clear_restock() -> void
1158 func has_restock_orders() -> bool
1160 # --- mining -------------------------------------------------------
1162 # --- honey making -------------------------------------------------
1164 # --- egg laying (queen only) --------------------------------------
1166 # --- player commands ----------------------------------------------
1176 func command_move_to(world_point: Vector2) -> void
1200 func command_exit_hive() -> void
1209 func set_forage_start_point(meadow_point: Vector2) -> void
1212 func has_forage_start_point() -> bool
1215 func set_preferred_species(species: String) -> void
1228 func set_manual_build_target(hex: Vector2i) -> void
1236 func queue_build_target(hex: Vector2i) -> void
1243 func clear_build_queue() -> void
1249 func _take_next_build_target() -> bool
1262 func set_mine_target(block: Node2D) -> void
1267 func queue_mine_target(block: Node2D) -> void
1273 func clear_mine_queue() -> void
1278 func _next_queued_block() -> Node2D
1286 func set_home_hex(hex: Vector2i) -> void
1295 func set_mine_home_hex(hex: Vector2i) -> void
1301 func _mine_reference_point() -> Vector2
1314 func command_collect_from(flower: Node2D) -> void
1327 func set_focus(type: String) -> void
1354 func set_secondary_role(new_role: int) -> void
1357 func can_take_role(new_role: int) -> bool
1367 func set_role(new_role: int) -> void
1384 func _apply_role(new_role: int) -> void
1410 func _release_everything() -> void
1427 func release_flower_reference(flower: Node2D) -> void
1433 func set_selected(value: bool) -> void
1437 # --- display ------------------------------------------------------
1439 func role_letter() -> String
1457 func idle_reason() -> String
1508 func task_description() -> String
1647 func _idle_backup_note() -> String
1652 func role_name_text() -> String
1676 func nurse_mode_name() -> String
1685 func architect_mode_name() -> String
1691 func carrying_text() -> String
1712 func age_days() -> float
1720 func leave_to_found_colony() -> void
1733 func days_remaining() -> float
1745 func _update_label() -> void
1765 func _update_alarm_ring() -> void
1774 func _terrain_speed_factor() -> float
1783 func _is_inside_hive() -> bool
1786 # --- getting round things in the meadow ---------------------------
1806 func clear_navigation_state() -> void
```

## debug_panel.gd (1,259 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
821  static func setting_get(key: String)
824  static func setting_set(key: String, value) -> void
844  func _ready() -> void
910  func _report_settings_button_width() -> void
915  func _rows_in(category: String) -> Array
937  func _make_section(category: String, entries: Array, start_open: bool) -> Control
974  func _make_controls_help() -> Control
1007 func _build_actions(column: VBoxContainer) -> void
1047 func _on_winter_pressed() -> void
1058 func set_save_load_enabled(enabled: bool) -> void
1066 func set_toggle(key: String, value: bool) -> void
1071 func _on_save_pressed() -> void
1082 func _on_load_pressed() -> void
1094 func _toggle_panel() -> void
1100 func _make_row(entry: Dictionary) -> Control
1129 func _make_toggle_row(entry: Dictionary) -> Control
1170 func _cascade_prerequisites_on(key: String) -> void
1183 func _cascade_dependents_off(key: String) -> void
1195 func _make_star_row(entry: Dictionary) -> Control
1229 func _adjust(entry: Dictionary, delta: float) -> void
1235 func _format_value(v) -> String
1242 func _on_restart_pressed() -> void
1247 func _on_main_menu_pressed() -> void
1255 func _restart() -> void
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

## main.gd (893 lines)

Per-frame entry point, everything not yet split out of main.

```
274  func _ready() -> void
484  # --- public surface other scripts call directly -------------------
491  func is_on_screen(node: Node2D) -> bool
494  func hive_entrance_inside() -> Vector2
497  func entrance_wait_point(side: int) -> Vector2
500  func move_bee_into_hive(bee: Node2D) -> void
503  func move_bee_out_of_hive(bee: Node2D) -> void
506  func mark_death(bee: Node2D) -> void
509  func finish_mining(block: Node2D) -> void
512  func save_run() -> void
515  func begin_winter_countdown() -> void
518  # --- per-frame ----------------------------------------------------
528  func _process(delta: float) -> void
570  # --- the frame rate readout ----------------------------------------
589  func _sample_fps() -> void
612  func _reseed_meadow(delta: float) -> void
627  func _hatch_ready_brood() -> void
657  func _advance_weather(delta: float) -> void
685  func _apply_rain_overlay() -> void
700  func _check_for_loss() -> void
722  func _check_colony_energy(delta: float) -> void
751  func _role_counts() -> Dictionary
765  func _update_population_readout(bees = null) -> void
786  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
792  func _prune_selection() -> void
805  func _on_restart_after_loss() -> void
811  func _on_level_chosen(level: int) -> void
826  func _apply_scenario_boot_arg() -> void
884  func _end_scenario_run(outcome: String) -> void
```
