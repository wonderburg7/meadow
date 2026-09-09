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

## hud.gd (2,688 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
131  static func hatch_options() -> Array
176  static func mode_command(role_id: int, mode_key: String) -> String
464  func _signal_color(severity: int) -> Color
475  func _ready() -> void
528  func _on_viewport_size_changed() -> void
532  func _make_label(pos: Vector2, variation: String = "Body") -> Label
540  func _info(text: String) -> Button
543  func _with_info(control: Control, tip: String) -> HBoxContainer
548  func _style_button(button: BaseButton) -> BaseButton
576  func _build_top_right_bar() -> void
685  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
721  func _apply_interface_label_visibility() -> void
731  func _build_goal_shelf() -> void
798  func set_settings_button_width(width: float) -> void
812  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
827  func set_speed_display(speed_scale: float) -> void
836  func _build_selection_panel() -> void
922  func _build_selection_cog() -> Control
949  func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
960  func _apply_selection_field_visibility() -> void
972  func _build_command_tray() -> void
1050 func _build_tray_column(title: String) -> Array
1070 # --- cell popup ---------------------------------------------------
1086 func _build_cell_group(parent: VBoxContainer) -> void
1177 func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer
1198 func _build_nursery_controls(column: VBoxContainer) -> void
1293 func _build_closing_controls(column: VBoxContainer) -> void
1333 func _build_empty_controls(column: VBoxContainer) -> void
1376 func _make_hatch_menu(entry: Dictionary) -> Control
1400 func _build_warning_banner() -> void
1436 func show_warning(text: String, key: String = "", min_gap: float = 0.0, severity: int = 0) -> void
1452 func _show_warning_now(text: String, severity: int) -> void
1460 func _dismiss_warning() -> void
1465 func set_warnings_muted(value: bool) -> void
1479 func show_object_summary(kind: String, data) -> void
1497 func _refresh_flower_summary() -> void
1533 func _show_obstacle_summary(obstacle: Node2D) -> void
1539 func _show_soil_summary(count: int, reachable: int) -> void
1555 func _show_death_summary(info: Dictionary) -> void
1577 func show_cell_popup(cell: Node2D, count: int = 1) -> void
1596 func _refresh_cell_popup() -> void
1698 func _apply_cell_popup_gating() -> void
1714 func _light_current_options() -> void
1732 func _set_lit(key: String, lit: bool) -> void
1743 func _process(_delta: float) -> void
1771 func _request_designation(type: String) -> void
1776 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1781 func _request_empty(method: String) -> void
1786 func _request_priority(tier: int) -> void
1791 func _request_close(closed: bool) -> void
1796 func _request_fill_close() -> void
1801 # --- discard warning ----------------------------------------------
1807 func _build_discard_dialog() -> void
1822 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1831 func _on_discard_confirmed() -> void
1834 func _on_discard_custom_action(action: StringName) -> void
1841 func _apply_discard() -> void
1849 # --- readouts -----------------------------------------------------
1854 func update_day(day: int, note: String = "") -> void
1864 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1873 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1879 func update_comb(text: String) -> void
1883 func update_energy(mean_fraction: float) -> void
1890 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1901 func update_recruit_gap(text: String) -> void
1914 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
1920 func update_signals(lines: Array) -> void
1928 func _refresh_corner() -> void
2007 func corner_bottom() -> float
2013 func selection_panel_top() -> float
2023 func pinned_stats_changed() -> void
2032 func refresh_speed_visibility() -> void
2039 func refresh_corner() -> void
2042 func update_selection(bees: Array) -> void
2073 func _selection_has_command_lock(bees: Array) -> bool
2088 func _rebuild_role_controls(bees: Array) -> void
2133 func _build_queen_build_row(column: VBoxContainer) -> void
2147 func _build_follow_control(bees: Array, first) -> void
2163 func _build_favourite_row(bee) -> void
2174 func _build_job_row(common_role: int, any_queen: bool) -> void
2202 func _build_doing_row(common_role: int, first) -> void
2228 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2243 func _build_orders_row(common_role: int, first) -> void
2290 func _build_restock_row(first) -> void
2318 func _build_fallback_row(common_role: int, first) -> void
2350 func _secondary_items() -> Array
2366 func _column_row(parent: Container) -> HFlowContainer
2374 func _labelled_row(title: String) -> HFlowContainer
2393 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2405 func _action_button(label: String, action: Callable, tip: String) -> Control
2414 func _current_role_marker(label: String) -> Control
2425 func _common_role(bees: Array) -> int
2442 func _common_working_role(bees: Array) -> int
2456 func _make_role_menu(label: String, tip: String, items: Array) -> Control
2471 func _refresh_selection_text() -> void
2561 func _apply_selection_tray_width() -> void
2576 func _update_command_tray_width() -> void
2592 func _resize_command_tray() -> void
2605 func set_winter_button_visible(value: bool) -> void
2611 func set_view_label(in_hive: bool) -> void
2617 func set_colony_button_visible(value: bool) -> void
2623 func set_nursery_button_visible(value: bool) -> void
2629 func set_view_button_visible(value: bool) -> void
2635 func set_foraging_button_visible(value: bool) -> void
2642 func set_allowed_role_keys(keys: Array) -> void
2652 func set_command_locked_bees(bees: Array) -> void
2657 func set_allowed_mode_keys(keys: Array) -> void
2665 func set_allowed_designation_keys(keys: Array) -> void
2670 func set_hatch_lock_visible(value: bool) -> void
2675 func set_soil_marking_visible(value: bool) -> void
2685 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (2,448 lines)

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
1758 func command_deposit_at_after_enter(cell: Node2D) -> void
1766 func resume_pending_zone_command() -> bool
1785 func _clear_pending_zone_command() -> void
1790 func set_focus(type: String) -> void
1830 func set_secondary_role(new_role: int) -> void
1833 func can_take_role(new_role: int) -> bool
1843 func set_role(new_role: int) -> void
1860 func _apply_role(new_role: int) -> void
1893 func _release_everything() -> void
1910 func release_flower_reference(flower: Node2D) -> void
1916 func set_selected(value: bool) -> void
1920 # --- display ------------------------------------------------------
1922 func role_letter() -> String
1951 func challenge_vocabulary_limited() -> bool
1964 func idle_reason() -> String
2017 func task_description() -> String
2164 func _idle_backup_note() -> String
2174 func role_name_text() -> String
2200 func nurse_mode_name() -> String
2209 func architect_mode_name() -> String
2215 func carrying_text() -> String
2236 func age_days() -> float
2244 func leave_to_found_colony() -> void
2257 func days_remaining() -> float
2269 func _update_label() -> void
2289 func _update_alarm_ring() -> void
2300 func _update_heading_marker() -> void
2314 func _update_search_ring() -> void
2337 func _update_dance_ring() -> void
2370 func _update_wander_flight(delta: float) -> void
2401 func _update_dance_circle(delta: float) -> void
2415 func _terrain_speed_factor() -> float
2424 func _is_inside_hive() -> bool
2427 # --- getting round things in the meadow ---------------------------
2447 func clear_navigation_state() -> void
```

## debug_panel.gd (874 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
60   func _style_button(button: BaseButton) -> BaseButton
65   func _ready() -> void
168  func _report_settings_button_width() -> void
173  func _rows_in(category: String) -> Array
195  func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
226  func _set_open(header: Button, body: Control, label: String, open: bool) -> void
234  func open_to_categories(categories: Array) -> void
254  func collapse_all() -> void
262  func _make_section(category: String, entries: Array, start_open: bool) -> Control
316  func _make_controls_help() -> Control
350  func _build_actions(column: VBoxContainer) -> void
417  func _make_winter_action() -> Control
429  func _on_winter_pressed() -> void
435  func _on_challenge_advance_pressed() -> void
448  func _on_fire_test_warnings_pressed() -> void
483  func _on_force_c2_collapse_pressed() -> void
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

## settings_catalogue.gd (1,066 lines)

Every setting's key, label, range and tip, plus the read/write and Prerequisites-cascade functions the window is a view of.

```
959  static func setting_get(key: String)
962  static func setting_set(key: String, value) -> void
985  static func reset_config_to_defaults() -> void
997  static func reset_config_keys(keys: Array) -> void
1011 static func apply_setting(key: String, value) -> void
1026 static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1044 static func _cascade_dependents_off_static(key: String) -> Array[String]
1058 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
```

## hive_cell.gd (1,092 lines)

One cell: contents, brood, honey ripening, how it draws.

```
145  func effective_build_time() -> float
245  func _ready() -> void
364  func set_overlay(mode: String) -> void
370  func _overlay_colour() -> Array
408  func set_selected(value: bool) -> void
420  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
431  func _set_outline_points(line: Line2D, size: float) -> void
442  func _silhouette_point_to_local(p: Vector2) -> Vector2
454  func _set_outline_points_cup(line: Line2D, size: float) -> void
470  func _apply_outline_points(line: Line2D, size: float) -> void
478  func _set_selection_ring_points() -> void
497  func _process(delta: float) -> void
521  func _develop_brood(delta: float) -> void
542  func _health_factor() -> float
550  func _larva_dies() -> void
565  func _invalidate_hive_index() -> void
580  func bump_display_epoch() -> void
583  # --- working positions --------------------------------------------
588  func claim_slot(bee: Node2D) -> int
599  func release_slot(bee: Node2D) -> void
607  func slot_position(index: int) -> Vector2
614  # --- building -----------------------------------------------------
616  func start_as_site() -> void
621  func claim_builder(bee: Node2D) -> void
625  func release_builder(bee: Node2D) -> void
630  func add_build_progress(delta: float) -> void
641  func build_fraction() -> float
644  # --- contents -----------------------------------------------------
646  func is_empty() -> bool
651  func capacity_for(resource_type: String) -> float
660  func accepts(resource_type: String) -> bool
679  func is_nursery_cell() -> bool
682  func space_for(resource_type: String) -> float
698  func needs_eviction() -> bool
716  func add_resource(resource_type: String, requested: float) -> float
747  func take_resource(resource_type: String, requested: float) -> float
774  func can_withdraw() -> bool
779  func set_closed(value: bool) -> void
785  func set_fill_then_close(value: bool) -> void
793  func fill_fraction() -> float
800  func set_designation(resource_type: String, explicit: bool = true) -> void
808  # --- honey ---------------------------------------------------------
810  func is_ripe_honey() -> bool
814  func needs_fanning() -> bool
819  func add_fanning_progress(delta: float) -> void
828  func ripen_fraction() -> float
831  # --- brood ---------------------------------------------------------
833  func start_brood(as_gyne: bool = false) -> void
846  func develop_time() -> float
854  func feed_brood(seconds: float, on_honey: bool) -> void
859  func needs_feeding() -> bool
863  func seconds_until_death() -> float
868  # --- clearing a dead larva ------------------------------------------
870  func needs_cleaning() -> bool
876  func add_clean_progress(delta: float) -> bool
882  func clean_fraction() -> float
885  func brood_ready() -> bool
888  func clear_cell() -> void
901  # --- display ------------------------------------------------------
903  func _refresh() -> void
1043 func _designation_tag() -> String
1065 func _priority_mark() -> String
1078 func _apply_fill_shading() -> void
1089 func development_percent() -> float
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

## main.gd (1,193 lines)

Per-frame entry point, everything not yet split out of main.

```
327  func _ready() -> void
582  # --- public surface other scripts call directly -------------------
589  func is_on_screen(node: Node2D) -> bool
592  func hive_entrance_inside() -> Vector2
595  func entrance_wait_point(side: int) -> Vector2
598  func move_bee_into_hive(bee: Node2D) -> void
601  func move_bee_out_of_hive(bee: Node2D) -> void
604  func mark_death(bee: Node2D) -> void
612  func _on_bee_died(bee: Node2D) -> void
616  func finish_mining(block: Node2D) -> void
619  func save_run() -> void
622  func begin_winter_countdown() -> void
625  # --- per-frame ----------------------------------------------------
635  func _process(delta: float) -> void
717  # --- the frame rate readout ----------------------------------------
736  func _sample_fps() -> void
759  func _reseed_meadow(delta: float) -> void
774  func _hatch_ready_brood() -> void
806  func _advance_weather(delta: float) -> void
836  func _apply_rain_overlay() -> void
851  func _check_for_loss() -> void
873  func _check_colony_energy(delta: float) -> void
904  func invalidate_population() -> void
915  func _role_counts() -> Dictionary
933  func _update_population_readout(bees = null) -> void
955  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
961  func _prune_selection() -> void
974  func _on_restart_after_loss() -> void
980  func _on_level_chosen(level: int) -> void
993  func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
1011 func _apply_scenario_boot_arg() -> void
1126 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1166 func _is_whole_number(value: Variant) -> bool
1180 func _end_scenario_run(outcome: String) -> void
```
