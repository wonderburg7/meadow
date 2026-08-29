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

## hud.gd (2,464 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
125  static func hatch_options() -> Array
170  static func mode_command(role_id: int, mode_key: String) -> String
426  func _signal_color(severity: int) -> Color
437  func _ready() -> void
483  func _on_viewport_size_changed() -> void
487  func _make_label(pos: Vector2, variation: String = "Body") -> Label
495  func _info(text: String) -> Button
498  func _with_info(control: Control, tip: String) -> HBoxContainer
503  func _style_button(button: BaseButton) -> BaseButton
524  func _build_top_right_bar() -> void
630  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
666  func _apply_interface_label_visibility() -> void
676  func _build_goal_shelf() -> void
743  func set_settings_button_width(width: float) -> void
757  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
772  func set_speed_display(speed_scale: float) -> void
781  func _build_selection_panel() -> void
857  func _build_selection_cog() -> Control
877  func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
888  func _apply_selection_field_visibility() -> void
900  func _build_command_tray() -> void
962  func _build_tray_column(title: String) -> Array
982  # --- cell popup ---------------------------------------------------
998  func _build_cell_group(parent: VBoxContainer) -> void
1088 func _build_cell_action_column(parent: HBoxContainer, title: String) -> VBoxContainer
1109 func _build_nursery_controls(column: VBoxContainer) -> void
1204 func _build_closing_controls(column: VBoxContainer) -> void
1244 func _build_empty_controls(column: VBoxContainer) -> void
1287 func _make_hatch_menu(entry: Dictionary) -> Control
1311 func _build_warning_banner() -> void
1340 func show_warning(text: String) -> void
1347 func set_warnings_muted(value: bool) -> void
1360 func show_object_summary(kind: String, data) -> void
1378 func _refresh_flower_summary() -> void
1405 func _show_obstacle_summary(obstacle: Node2D) -> void
1411 func _show_soil_summary(count: int, reachable: int) -> void
1427 func _show_death_summary(info: Dictionary) -> void
1449 func show_cell_popup(cell: Node2D, count: int = 1) -> void
1468 func _refresh_cell_popup() -> void
1570 func _apply_cell_popup_gating() -> void
1584 func _light_current_options() -> void
1602 func _set_lit(key: String, lit: bool) -> void
1613 func _process(_delta: float) -> void
1638 func _request_designation(type: String) -> void
1643 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1648 func _request_empty(method: String) -> void
1653 func _request_priority(tier: int) -> void
1658 func _request_close(closed: bool) -> void
1663 func _request_fill_close() -> void
1668 # --- discard warning ----------------------------------------------
1674 func _build_discard_dialog() -> void
1689 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1698 func _on_discard_confirmed() -> void
1701 func _on_discard_custom_action(action: StringName) -> void
1708 func _apply_discard() -> void
1716 # --- readouts -----------------------------------------------------
1721 func update_day(day: int, note: String = "") -> void
1731 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1740 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1746 func update_comb(text: String) -> void
1750 func update_energy(mean_fraction: float) -> void
1757 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1768 func update_recruit_gap(text: String) -> void
1781 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
1787 func update_signals(lines: Array) -> void
1795 func _refresh_corner() -> void
1877 func pinned_stats_changed() -> void
1886 func refresh_speed_visibility() -> void
1893 func refresh_corner() -> void
1896 func update_selection(bees: Array) -> void
1917 func _selection_has_command_lock(bees: Array) -> bool
1932 func _rebuild_role_controls(bees: Array) -> void
1976 func _build_queen_build_row(column: VBoxContainer) -> void
1990 func _build_follow_control(bees: Array, first) -> void
2006 func _build_favourite_row(bee) -> void
2017 func _build_job_row(common_role: int, any_queen: bool) -> void
2045 func _build_doing_row(common_role: int, first) -> void
2071 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2086 func _build_orders_row(common_role: int, first) -> void
2133 func _build_restock_row(first) -> void
2161 func _build_fallback_row(common_role: int, first) -> void
2193 func _secondary_items() -> Array
2207 func _column_row(parent: Container) -> HBoxContainer
2213 func _labelled_row(title: String) -> HBoxContainer
2230 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2242 func _action_button(label: String, action: Callable, tip: String) -> Control
2251 func _current_role_marker(label: String) -> Control
2262 func _common_role(bees: Array) -> int
2275 func _make_role_menu(label: String, tip: String, items: Array) -> Control
2290 func _refresh_selection_text() -> void
2357 func _apply_selection_tray_width() -> void
2372 func _update_command_tray_width() -> void
2383 func set_winter_button_visible(value: bool) -> void
2389 func set_view_label(in_hive: bool) -> void
2395 func set_colony_button_visible(value: bool) -> void
2401 func set_nursery_button_visible(value: bool) -> void
2407 func set_view_button_visible(value: bool) -> void
2413 func set_foraging_button_visible(value: bool) -> void
2420 func set_allowed_role_keys(keys: Array) -> void
2428 func set_command_locked_bees(bees: Array) -> void
2433 func set_allowed_mode_keys(keys: Array) -> void
2441 func set_allowed_designation_keys(keys: Array) -> void
2446 func set_hatch_lock_visible(value: bool) -> void
2451 func set_soil_marking_visible(value: bool) -> void
2461 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (2,255 lines)

A bee's dispatch loop, player commands, display text, vars.

```
539  func _ready() -> void
676  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
718  func _roll_fact() -> void
732  func _default_state_for_role() -> int
754  func _base_colour() -> Color
765  func _tinted(c: Color) -> Color
780  func _apply_stats() -> void
806  func trait_text() -> String
815  func _update_role_marker() -> void
834  # --- how often a bee thinks ---------------------------------------
866  func _process(delta: float) -> void
1138 # --- life support -------------------------------------------------
1140 # --- eating -------------------------------------------------------
1142 # --- stall watchdog -----------------------------------------------
1148 func _reset_stall_watch() -> void
1151 # --- foraging -----------------------------------------------------
1153 # --- entering and leaving the hive --------------------------------
1155 # --- nursery work -------------------------------------------------
1157 # --- royal jelly ---------------------------------------------------
1159 # --- idle work dispatch --------------------------------------------
1173 func _apply_pending_role() -> bool
1185 func _is_busy() -> bool
1191 func _idle_dispatch() -> void
1217 func _maybe_break_off_secondary() -> void
1241 func _try_role_work(r: int) -> bool
1425 # --- building -----------------------------------------------------
1427 # --- keeping cells topped up ---------------------------------------
1456 func set_restock_targets(cells: Array, resource: String) -> void
1459 func set_restock_sources(cells: Array, allowed: bool) -> void
1462 func clear_restock() -> void
1465 func has_restock_orders() -> bool
1467 # --- mining -------------------------------------------------------
1469 # --- honey making -------------------------------------------------
1471 # --- egg laying (queen only) --------------------------------------
1473 # --- player commands ----------------------------------------------
1483 func command_move_to(world_point: Vector2) -> void
1507 func command_exit_hive() -> void
1516 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
1524 func has_forage_start_point() -> bool
1527 func set_preferred_species(species: String) -> void
1540 func set_manual_build_target(hex: Vector2i) -> void
1548 func queue_build_target(hex: Vector2i) -> void
1555 func clear_build_queue() -> void
1561 func _take_next_build_target() -> bool
1574 func set_mine_target(block: Node2D) -> void
1581 func queue_mine_target(block: Node2D) -> void
1589 func clear_mine_queue() -> void
1596 func _next_queued_block() -> Node2D
1604 func set_home_hex(hex: Vector2i) -> void
1613 func set_mine_home_hex(hex: Vector2i) -> void
1619 func _mine_reference_point() -> Vector2
1632 func command_collect_from(flower: Node2D) -> void
1652 func command_return_and_deposit() -> void
1661 func command_return_only() -> void
1666 func command_deposit_at(cell: Node2D) -> void
1671 func set_focus(type: String) -> void
1698 func set_secondary_role(new_role: int) -> void
1701 func can_take_role(new_role: int) -> bool
1711 func set_role(new_role: int) -> void
1728 func _apply_role(new_role: int) -> void
1761 func _release_everything() -> void
1778 func release_flower_reference(flower: Node2D) -> void
1784 func set_selected(value: bool) -> void
1788 # --- display ------------------------------------------------------
1790 func role_letter() -> String
1808 func idle_reason() -> String
1859 func task_description() -> String
2004 func _idle_backup_note() -> String
2009 func role_name_text() -> String
2035 func nurse_mode_name() -> String
2044 func architect_mode_name() -> String
2050 func carrying_text() -> String
2071 func age_days() -> float
2079 func leave_to_found_colony() -> void
2092 func days_remaining() -> float
2104 func _update_label() -> void
2124 func _update_alarm_ring() -> void
2135 func _update_heading_marker() -> void
2149 func _update_search_ring() -> void
2177 func _update_wander_flight(delta: float) -> void
2208 func _update_dance_circle(delta: float) -> void
2222 func _terrain_speed_factor() -> float
2231 func _is_inside_hive() -> bool
2234 # --- getting round things in the meadow ---------------------------
2254 func clear_navigation_state() -> void
```

## debug_panel.gd (1,702 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
939  static func setting_get(key: String)
942  static func setting_set(key: String, value) -> void
957  static func apply_setting(key: String, value) -> void
972  static func _cascade_prerequisites_on_static(key: String) -> Array[String]
986  static func _cascade_dependents_off_static(key: String) -> Array[String]
1000 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
1033 func _style_button(button: BaseButton) -> BaseButton
1038 func _ready() -> void
1119 func _report_settings_button_width() -> void
1124 func _rows_in(category: String) -> Array
1146 func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
1177 func _set_open(header: Button, body: Control, label: String, open: bool) -> void
1185 func open_to_categories(categories: Array) -> void
1202 func _make_section(category: String, entries: Array, start_open: bool) -> Control
1256 func _make_controls_help() -> Control
1289 func _build_actions(column: VBoxContainer) -> void
1331 func _make_winter_action() -> Control
1343 func _on_winter_pressed() -> void
1349 func _on_challenge_advance_pressed() -> void
1360 func set_save_load_enabled(enabled: bool) -> void
1368 func set_toggle(key: String, value: bool) -> void
1373 func _on_save_pressed() -> void
1384 func _on_load_pressed() -> void
1396 func _toggle_panel() -> void
1402 func _make_row(entry: Dictionary) -> Control
1445 func _make_control_slot() -> HBoxContainer
1454 func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
1484 func _make_toggle_row(entry: Dictionary) -> Control
1548 func _make_options_row(entry: Dictionary) -> Control
1581 func _option_display(entry: Dictionary, value) -> String
1585 func _cycle_option(entry: Dictionary, direction: int) -> void
1599 func _cascade_prerequisites_on(key: String) -> void
1606 func _cascade_dependents_off(key: String) -> void
1613 func _cascade_mutual_exclusion(key: String) -> void
1622 func _make_star_row(entry: Dictionary) -> Control
1663 func _adjust(entry: Dictionary, delta: float) -> void
1678 func _format_value(v) -> String
1685 func _on_restart_pressed() -> void
1690 func _on_main_menu_pressed() -> void
1698 func _restart() -> void
```

## hive_cell.gd (922 lines)

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
420  func _invalidate_hive_index() -> void
435  func bump_display_epoch() -> void
438  # --- working positions --------------------------------------------
443  func claim_slot(bee: Node2D) -> int
454  func release_slot(bee: Node2D) -> void
462  func slot_position(index: int) -> Vector2
469  # --- building -----------------------------------------------------
471  func start_as_site() -> void
476  func claim_builder(bee: Node2D) -> void
480  func release_builder(bee: Node2D) -> void
485  func add_build_progress(delta: float) -> void
496  func build_fraction() -> float
499  # --- contents -----------------------------------------------------
501  func is_empty() -> bool
506  func capacity_for(resource_type: String) -> float
515  func accepts(resource_type: String) -> bool
534  func is_nursery_cell() -> bool
537  func space_for(resource_type: String) -> float
553  func needs_eviction() -> bool
571  func add_resource(resource_type: String, requested: float) -> float
602  func take_resource(resource_type: String, requested: float) -> float
627  func can_withdraw() -> bool
632  func set_closed(value: bool) -> void
638  func set_fill_then_close(value: bool) -> void
646  func fill_fraction() -> float
653  func set_designation(resource_type: String) -> void
660  # --- honey ---------------------------------------------------------
662  func is_ripe_honey() -> bool
666  func needs_fanning() -> bool
671  func add_fanning_progress(delta: float) -> void
680  func ripen_fraction() -> float
683  # --- brood ---------------------------------------------------------
685  func start_brood(as_gyne: bool = false) -> void
698  func develop_time() -> float
706  func feed_brood(seconds: float, on_honey: bool) -> void
711  func needs_feeding() -> bool
715  func seconds_until_death() -> float
720  # --- clearing a dead larva ------------------------------------------
722  func needs_cleaning() -> bool
728  func add_clean_progress(delta: float) -> bool
734  func clean_fraction() -> float
737  func brood_ready() -> bool
740  func clear_cell() -> void
753  # --- display ------------------------------------------------------
755  func _refresh() -> void
873  func _designation_tag() -> String
895  func _priority_mark() -> String
908  func _apply_fill_shading() -> void
919  func development_percent() -> float
```

## hive.gd (990 lines)

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
688  func create_cell_site_at(hex: Vector2i) -> Node2D
693  # --- navigation ---------------------------------------------------
704  func build_navigation() -> void
745  func _is_solid(hex: Vector2i) -> bool
751  func _tile_cost(hex: Vector2i) -> float
754  func tile_is_walkable(hex: Vector2i) -> bool
763  func nearest_walkable_point(point: Vector2) -> Vector2
790  func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
824  func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
848  func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
858  # --- mining -------------------------------------------------------
867  func refresh_edge_flags() -> void
889  func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
911  func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
930  func _is_markable_block(node) -> bool
937  func mine_stand_hex(block: Node2D)
960  func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
978  func remove_block(block: Node2D, floor_maker: Callable) -> void
989  func announce() -> void
```

## main.gd (1,201 lines)

Per-frame entry point, everything not yet split out of main.

```
334  func _ready() -> void
588  # --- public surface other scripts call directly -------------------
595  func is_on_screen(node: Node2D) -> bool
598  func hive_entrance_inside() -> Vector2
601  func entrance_wait_point(side: int) -> Vector2
604  func move_bee_into_hive(bee: Node2D) -> void
607  func move_bee_out_of_hive(bee: Node2D) -> void
610  func mark_death(bee: Node2D) -> void
618  func _on_bee_died(bee: Node2D) -> void
622  func finish_mining(block: Node2D) -> void
625  func save_run() -> void
628  func begin_winter_countdown() -> void
631  # --- per-frame ----------------------------------------------------
641  func _process(delta: float) -> void
723  # --- the frame rate readout ----------------------------------------
742  func _sample_fps() -> void
765  func _reseed_meadow(delta: float) -> void
780  func _hatch_ready_brood() -> void
812  func _advance_weather(delta: float) -> void
842  func _apply_rain_overlay() -> void
857  func _check_for_loss() -> void
879  func _check_colony_energy(delta: float) -> void
913  func invalidate_population() -> void
924  func _role_counts() -> Dictionary
942  func _update_population_readout(bees = null) -> void
964  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
970  func _prune_selection() -> void
983  func _on_restart_after_loss() -> void
989  func _on_level_chosen(level: int) -> void
1002 func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
1019 func _apply_scenario_boot_arg() -> void
1134 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1174 func _is_whole_number(value: Variant) -> bool
1188 func _end_scenario_run(outcome: String) -> void
```
