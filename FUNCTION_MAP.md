# Function map

A line-numbered index of every function and section header in the seven
scripts still over ~700 lines after the `bee.gd` / `main.gd` splits.
Smaller files don't need this -- grep their `# --- section ---` headers
directly, per CLAUDE.md.

**How to use it:** grep this file for the function name (or the area you
want, e.g. "popup", "restock") to get its line number, then either `Read`
the source file with an offset near that line, or grep the source file
directly for the exact signature before editing. Line numbers here are a
pointer, not a guarantee -- they drift as the file changes.

**How to keep it updated:** this file is generated, not hand-maintained.
After adding, removing, renaming or moving a function in one of the seven
files below, run:

```
python3 tools/update_function_map.py
```

`--check` exits non-zero (and prints which files moved) instead of
writing, for a pre-commit or CI check. Whether the map was actually
regenerated after a given change is a `git log` question, not something
recorded in this file.

---

## hud.gd (2,528 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
125  static func hatch_options() -> Array
170  static func mode_command(role_id: int, mode_key: String) -> String
427  func _signal_color(severity: int) -> Color
438  func _ready() -> void
491  func _on_viewport_size_changed() -> void
495  func _make_label(pos: Vector2, variation: String = "Body") -> Label
503  func _info(text: String) -> Button
506  func _with_info(control: Control, tip: String) -> HBoxContainer
511  func _style_button(button: BaseButton) -> BaseButton
539  func _build_top_right_bar() -> void
648  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
684  func _apply_interface_label_visibility() -> void
694  func _build_goal_shelf() -> void
761  func set_settings_button_width(width: float) -> void
775  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
790  func set_speed_display(speed_scale: float) -> void
799  func _build_selection_panel() -> void
879  func _build_selection_cog() -> Control
902  func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
913  func _apply_selection_field_visibility() -> void
925  func _build_command_tray() -> void
990  func _build_tray_column(title: String) -> Array
1010 # --- cell popup ---------------------------------------------------
1026 func _build_cell_group(parent: VBoxContainer) -> void
1116 func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer
1137 func _build_nursery_controls(column: VBoxContainer) -> void
1232 func _build_closing_controls(column: VBoxContainer) -> void
1272 func _build_empty_controls(column: VBoxContainer) -> void
1315 func _make_hatch_menu(entry: Dictionary) -> Control
1339 func _build_warning_banner() -> void
1368 func show_warning(text: String) -> void
1375 func set_warnings_muted(value: bool) -> void
1388 func show_object_summary(kind: String, data) -> void
1406 func _refresh_flower_summary() -> void
1433 func _show_obstacle_summary(obstacle: Node2D) -> void
1439 func _show_soil_summary(count: int, reachable: int) -> void
1455 func _show_death_summary(info: Dictionary) -> void
1477 func show_cell_popup(cell: Node2D, count: int = 1) -> void
1496 func _refresh_cell_popup() -> void
1598 func _apply_cell_popup_gating() -> void
1614 func _light_current_options() -> void
1632 func _set_lit(key: String, lit: bool) -> void
1643 func _process(_delta: float) -> void
1668 func _request_designation(type: String) -> void
1673 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1678 func _request_empty(method: String) -> void
1683 func _request_priority(tier: int) -> void
1688 func _request_close(closed: bool) -> void
1693 func _request_fill_close() -> void
1698 # --- discard warning ----------------------------------------------
1704 func _build_discard_dialog() -> void
1719 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1728 func _on_discard_confirmed() -> void
1731 func _on_discard_custom_action(action: StringName) -> void
1738 func _apply_discard() -> void
1746 # --- readouts -----------------------------------------------------
1751 func update_day(day: int, note: String = "") -> void
1761 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1770 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1776 func update_comb(text: String) -> void
1780 func update_energy(mean_fraction: float) -> void
1787 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1798 func update_recruit_gap(text: String) -> void
1811 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
1817 func update_signals(lines: Array) -> void
1825 func _refresh_corner() -> void
1907 func pinned_stats_changed() -> void
1916 func refresh_speed_visibility() -> void
1923 func refresh_corner() -> void
1926 func update_selection(bees: Array) -> void
1947 func _selection_has_command_lock(bees: Array) -> bool
1962 func _rebuild_role_controls(bees: Array) -> void
2007 func _build_queen_build_row(column: VBoxContainer) -> void
2021 func _build_follow_control(bees: Array, first) -> void
2037 func _build_favourite_row(bee) -> void
2048 func _build_job_row(common_role: int, any_queen: bool) -> void
2076 func _build_doing_row(common_role: int, first) -> void
2102 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2117 func _build_orders_row(common_role: int, first) -> void
2164 func _build_restock_row(first) -> void
2192 func _build_fallback_row(common_role: int, first) -> void
2224 func _secondary_items() -> Array
2240 func _column_row(parent: Container) -> HFlowContainer
2248 func _labelled_row(title: String) -> HFlowContainer
2267 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2279 func _action_button(label: String, action: Callable, tip: String) -> Control
2288 func _current_role_marker(label: String) -> Control
2299 func _common_role(bees: Array) -> int
2316 func _common_working_role(bees: Array) -> int
2330 func _make_role_menu(label: String, tip: String, items: Array) -> Control
2345 func _refresh_selection_text() -> void
2414 func _apply_selection_tray_width() -> void
2430 func _update_command_tray_width() -> void
2445 func set_winter_button_visible(value: bool) -> void
2451 func set_view_label(in_hive: bool) -> void
2457 func set_colony_button_visible(value: bool) -> void
2463 func set_nursery_button_visible(value: bool) -> void
2469 func set_view_button_visible(value: bool) -> void
2475 func set_foraging_button_visible(value: bool) -> void
2482 func set_allowed_role_keys(keys: Array) -> void
2492 func set_command_locked_bees(bees: Array) -> void
2497 func set_allowed_mode_keys(keys: Array) -> void
2505 func set_allowed_designation_keys(keys: Array) -> void
2510 func set_hatch_lock_visible(value: bool) -> void
2515 func set_soil_marking_visible(value: bool) -> void
2525 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (2,355 lines)

A bee's dispatch loop, player commands, display text, vars.

```
235  func current_working_role() -> int
576  func _ready() -> void
713  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
755  func _roll_fact() -> void
769  func _default_state_for_role() -> int
791  func _base_colour() -> Color
802  func _tinted(c: Color) -> Color
817  func _apply_stats() -> void
843  func trait_text() -> String
852  func _update_role_marker() -> void
871  # --- how often a bee thinks ---------------------------------------
903  func _process(delta: float) -> void
1175 # --- life support -------------------------------------------------
1177 # --- eating -------------------------------------------------------
1179 # --- stall watchdog -----------------------------------------------
1185 func _reset_stall_watch() -> void
1188 # --- foraging -----------------------------------------------------
1190 # --- entering and leaving the hive --------------------------------
1192 # --- nursery work -------------------------------------------------
1194 # --- royal jelly ---------------------------------------------------
1196 # --- idle work dispatch --------------------------------------------
1210 func _apply_pending_role() -> bool
1222 func _is_busy() -> bool
1228 func _idle_dispatch() -> void
1254 func _maybe_break_off_secondary() -> void
1278 func _try_role_work(r: int) -> bool
1462 # --- building -----------------------------------------------------
1464 # --- keeping cells topped up ---------------------------------------
1493 func set_restock_targets(cells: Array, resource: String) -> void
1496 func set_restock_sources(cells: Array, allowed: bool) -> void
1499 func clear_restock() -> void
1502 func has_restock_orders() -> bool
1504 # --- mining -------------------------------------------------------
1506 # --- honey making -------------------------------------------------
1508 # --- egg laying (queen only) --------------------------------------
1510 # --- player commands ----------------------------------------------
1520 func command_move_to(world_point: Vector2) -> void
1540 func command_move_through_entrance(world_point: Vector2, target_in_hive: bool) -> void
1552 func command_exit_hive() -> void
1562 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
1570 func has_forage_start_point() -> bool
1573 func set_preferred_species(species: String) -> void
1586 func set_manual_build_target(hex: Vector2i) -> void
1594 func queue_build_target(hex: Vector2i) -> void
1601 func clear_build_queue() -> void
1607 func _take_next_build_target() -> bool
1620 func set_mine_target(block: Node2D) -> void
1627 func queue_mine_target(block: Node2D) -> void
1635 func clear_mine_queue() -> void
1642 func _next_queued_block() -> Node2D
1650 func set_home_hex(hex: Vector2i) -> void
1659 func set_mine_home_hex(hex: Vector2i) -> void
1665 func _mine_reference_point() -> Vector2
1680 func command_collect_from(flower: Node2D) -> void
1696 func command_collect_from_after_exit(flower: Node2D) -> void
1709 func command_return_and_deposit() -> void
1719 func command_return_only() -> void
1725 func command_deposit_at(cell: Node2D) -> void
1733 func command_deposit_at_after_enter(cell: Node2D) -> void
1741 func resume_pending_zone_command() -> bool
1760 func _clear_pending_zone_command() -> void
1765 func set_focus(type: String) -> void
1798 func set_secondary_role(new_role: int) -> void
1801 func can_take_role(new_role: int) -> bool
1811 func set_role(new_role: int) -> void
1828 func _apply_role(new_role: int) -> void
1861 func _release_everything() -> void
1878 func release_flower_reference(flower: Node2D) -> void
1884 func set_selected(value: bool) -> void
1888 # --- display ------------------------------------------------------
1890 func role_letter() -> String
1908 func idle_reason() -> String
1959 func task_description() -> String
2104 func _idle_backup_note() -> String
2109 func role_name_text() -> String
2135 func nurse_mode_name() -> String
2144 func architect_mode_name() -> String
2150 func carrying_text() -> String
2171 func age_days() -> float
2179 func leave_to_found_colony() -> void
2192 func days_remaining() -> float
2204 func _update_label() -> void
2224 func _update_alarm_ring() -> void
2235 func _update_heading_marker() -> void
2249 func _update_search_ring() -> void
2277 func _update_wander_flight(delta: float) -> void
2308 func _update_dance_circle(delta: float) -> void
2322 func _terrain_speed_factor() -> float
2331 func _is_inside_hive() -> bool
2334 # --- getting round things in the meadow ---------------------------
2354 func clear_navigation_state() -> void
```

## debug_panel.gd (777 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
58   func _style_button(button: BaseButton) -> BaseButton
63   func _ready() -> void
164  func _report_settings_button_width() -> void
169  func _rows_in(category: String) -> Array
191  func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
222  func _set_open(header: Button, body: Control, label: String, open: bool) -> void
230  func open_to_categories(categories: Array) -> void
248  func _make_section(category: String, entries: Array, start_open: bool) -> Control
302  func _make_controls_help() -> Control
335  func _build_actions(column: VBoxContainer) -> void
377  func _make_winter_action() -> Control
389  func _on_winter_pressed() -> void
395  func _on_challenge_advance_pressed() -> void
406  func set_save_load_enabled(enabled: bool) -> void
414  func set_toggle(key: String, value: bool) -> void
419  func _on_save_pressed() -> void
430  func _on_load_pressed() -> void
442  func _toggle_panel() -> void
456  func _apply_layer_for_context() -> void
461  func _make_row(entry: Dictionary) -> Control
504  func _make_control_slot() -> HBoxContainer
513  func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
543  func _make_toggle_row(entry: Dictionary) -> Control
614  func _make_options_row(entry: Dictionary) -> Control
647  func _option_display(entry: Dictionary, value) -> String
651  func _cycle_option(entry: Dictionary, direction: int) -> void
666  func _cascade_prerequisites_on(key: String) -> void
680  func _cascade_dependents_off(key: String) -> void
688  func _cascade_mutual_exclusion(key: String) -> void
697  func _make_star_row(entry: Dictionary) -> Control
738  func _adjust(entry: Dictionary, delta: float) -> void
753  func _format_value(v) -> String
760  func _on_restart_pressed() -> void
765  func _on_main_menu_pressed() -> void
773  func _restart() -> void
```

## settings_catalogue.gd (1,049 lines)

Every setting's key, label, range and tip, plus the read/write and Prerequisites-cascade functions the window is a view of.

```
953  static func setting_get(key: String)
956  static func setting_set(key: String, value) -> void
979  static func reset_config_to_defaults() -> void
994  static func apply_setting(key: String, value) -> void
1009 static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1027 static func _cascade_dependents_off_static(key: String) -> Array[String]
1041 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
```

## hive_cell.gd (1,034 lines)

One cell: contents, brood, honey ripening, how it draws.

```
127  func effective_build_time() -> float
223  func _ready() -> void
339  func set_overlay(mode: String) -> void
345  func _overlay_colour() -> Array
383  func set_selected(value: bool) -> void
395  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
406  func _set_outline_points(line: Line2D, size: float) -> void
416  func _set_outline_points_cup(line: Line2D, size: float) -> void
428  func _set_selection_ring_points() -> void
452  func _process(delta: float) -> void
476  func _develop_brood(delta: float) -> void
497  func _health_factor() -> float
505  func _larva_dies() -> void
520  func _invalidate_hive_index() -> void
535  func bump_display_epoch() -> void
538  # --- working positions --------------------------------------------
543  func claim_slot(bee: Node2D) -> int
554  func release_slot(bee: Node2D) -> void
562  func slot_position(index: int) -> Vector2
569  # --- building -----------------------------------------------------
571  func start_as_site() -> void
576  func claim_builder(bee: Node2D) -> void
580  func release_builder(bee: Node2D) -> void
585  func add_build_progress(delta: float) -> void
596  func build_fraction() -> float
599  # --- contents -----------------------------------------------------
601  func is_empty() -> bool
606  func capacity_for(resource_type: String) -> float
615  func accepts(resource_type: String) -> bool
634  func is_nursery_cell() -> bool
637  func space_for(resource_type: String) -> float
653  func needs_eviction() -> bool
671  func add_resource(resource_type: String, requested: float) -> float
702  func take_resource(resource_type: String, requested: float) -> float
729  func can_withdraw() -> bool
734  func set_closed(value: bool) -> void
740  func set_fill_then_close(value: bool) -> void
748  func fill_fraction() -> float
755  func set_designation(resource_type: String, explicit: bool = true) -> void
763  # --- honey ---------------------------------------------------------
765  func is_ripe_honey() -> bool
769  func needs_fanning() -> bool
774  func add_fanning_progress(delta: float) -> void
783  func ripen_fraction() -> float
786  # --- brood ---------------------------------------------------------
788  func start_brood(as_gyne: bool = false) -> void
801  func develop_time() -> float
809  func feed_brood(seconds: float, on_honey: bool) -> void
814  func needs_feeding() -> bool
818  func seconds_until_death() -> float
823  # --- clearing a dead larva ------------------------------------------
825  func needs_cleaning() -> bool
831  func add_clean_progress(delta: float) -> bool
837  func clean_fraction() -> float
840  func brood_ready() -> bool
843  func clear_cell() -> void
856  # --- display ------------------------------------------------------
858  func _refresh() -> void
985  func _designation_tag() -> String
1007 func _priority_mark() -> String
1020 func _apply_fill_shading() -> void
1031 func development_percent() -> float
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

## main.gd (1,203 lines)

Per-frame entry point, everything not yet split out of main.

```
335  func _ready() -> void
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
914  func invalidate_population() -> void
925  func _role_counts() -> Dictionary
943  func _update_population_readout(bees = null) -> void
965  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
971  func _prune_selection() -> void
984  func _on_restart_after_loss() -> void
990  func _on_level_chosen(level: int) -> void
1003 func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
1021 func _apply_scenario_boot_arg() -> void
1136 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1176 func _is_whole_number(value: Variant) -> bool
1190 func _end_scenario_run(outcome: String) -> void
```
