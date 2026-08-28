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

## hud.gd (2,432 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
125  static func hatch_options() -> Array
170  static func mode_command(role_id: int, mode_key: String) -> String
403  func _signal_color(severity: int) -> Color
414  func _ready() -> void
460  func _on_viewport_size_changed() -> void
464  func _make_label(pos: Vector2, variation: String = "Body") -> Label
472  func _info(text: String) -> Button
475  func _with_info(control: Control, tip: String) -> HBoxContainer
480  func _style_button(button: BaseButton) -> BaseButton
501  func _build_top_right_bar() -> void
615  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
651  func _apply_interface_label_visibility() -> void
661  func _build_goal_shelf() -> void
720  func set_settings_button_width(width: float) -> void
734  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
749  func set_speed_display(speed_scale: float) -> void
758  func _build_selection_panel() -> void
834  func _build_selection_cog() -> Control
854  func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
865  func _apply_selection_field_visibility() -> void
877  func _build_command_tray() -> void
939  func _build_tray_column(title: String) -> Array
957  # --- cell popup ---------------------------------------------------
973  func _build_cell_group(parent: VBoxContainer) -> void
1063 func _build_cell_action_column(parent: HBoxContainer, title: String) -> VBoxContainer
1084 func _build_nursery_controls(column: VBoxContainer) -> void
1179 func _build_closing_controls(column: VBoxContainer) -> void
1219 func _build_empty_controls(column: VBoxContainer) -> void
1262 func _make_hatch_menu(entry: Dictionary) -> Control
1286 func _build_warning_banner() -> void
1315 func show_warning(text: String) -> void
1322 func set_warnings_muted(value: bool) -> void
1335 func show_object_summary(kind: String, data) -> void
1353 func _refresh_flower_summary() -> void
1380 func _show_obstacle_summary(obstacle: Node2D) -> void
1386 func _show_soil_summary(count: int, reachable: int) -> void
1402 func _show_death_summary(info: Dictionary) -> void
1424 func show_cell_popup(cell: Node2D, count: int = 1) -> void
1443 func _refresh_cell_popup() -> void
1545 func _apply_cell_popup_gating() -> void
1559 func _light_current_options() -> void
1577 func _set_lit(key: String, lit: bool) -> void
1588 func _process(_delta: float) -> void
1613 func _request_designation(type: String) -> void
1618 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1623 func _request_empty(method: String) -> void
1628 func _request_priority(tier: int) -> void
1633 func _request_close(closed: bool) -> void
1638 func _request_fill_close() -> void
1643 # --- discard warning ----------------------------------------------
1649 func _build_discard_dialog() -> void
1664 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1673 func _on_discard_confirmed() -> void
1676 func _on_discard_custom_action(action: StringName) -> void
1683 func _apply_discard() -> void
1691 # --- readouts -----------------------------------------------------
1696 func update_day(day: int, note: String = "") -> void
1706 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1715 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1721 func update_comb(text: String) -> void
1725 func update_energy(mean_fraction: float) -> void
1732 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1743 func update_recruit_gap(text: String) -> void
1756 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
1762 func update_signals(lines: Array) -> void
1770 func _refresh_corner() -> void
1852 func pinned_stats_changed() -> void
1861 func refresh_speed_visibility() -> void
1868 func refresh_corner() -> void
1871 func update_selection(bees: Array) -> void
1892 func _selection_has_command_lock(bees: Array) -> bool
1907 func _rebuild_role_controls(bees: Array) -> void
1951 func _build_queen_build_row(column: VBoxContainer) -> void
1965 func _build_follow_control(bees: Array, first) -> void
1981 func _build_favourite_row(bee) -> void
1992 func _build_job_row(common_role: int, any_queen: bool) -> void
2020 func _build_doing_row(common_role: int, first) -> void
2046 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2061 func _build_orders_row(common_role: int, first) -> void
2108 func _build_restock_row(first) -> void
2136 func _build_fallback_row(common_role: int, first) -> void
2168 func _secondary_items() -> Array
2182 func _column_row(parent: Container) -> HBoxContainer
2188 func _labelled_row(title: String) -> HBoxContainer
2205 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2216 func _action_button(label: String, action: Callable, tip: String) -> Control
2224 func _current_role_marker(label: String) -> Control
2234 func _common_role(bees: Array) -> int
2247 func _make_role_menu(label: String, tip: String, items: Array) -> Control
2262 func _refresh_selection_text() -> void
2329 func _apply_selection_tray_width() -> void
2344 func _update_command_tray_width() -> void
2355 func set_winter_button_visible(value: bool) -> void
2361 func set_view_label(in_hive: bool) -> void
2367 func set_colony_button_visible(value: bool) -> void
2373 func set_nursery_button_visible(value: bool) -> void
2379 func set_view_button_visible(value: bool) -> void
2388 func set_allowed_role_keys(keys: Array) -> void
2396 func set_command_locked_bees(bees: Array) -> void
2401 func set_allowed_mode_keys(keys: Array) -> void
2409 func set_allowed_designation_keys(keys: Array) -> void
2414 func set_hatch_lock_visible(value: bool) -> void
2419 func set_soil_marking_visible(value: bool) -> void
2429 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (2,248 lines)

A bee's dispatch loop, player commands, display text, vars.

```
532  func _ready() -> void
669  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
711  func _roll_fact() -> void
725  func _default_state_for_role() -> int
747  func _base_colour() -> Color
758  func _tinted(c: Color) -> Color
773  func _apply_stats() -> void
799  func trait_text() -> String
808  func _update_role_marker() -> void
827  # --- how often a bee thinks ---------------------------------------
859  func _process(delta: float) -> void
1131 # --- life support -------------------------------------------------
1133 # --- eating -------------------------------------------------------
1135 # --- stall watchdog -----------------------------------------------
1141 func _reset_stall_watch() -> void
1144 # --- foraging -----------------------------------------------------
1146 # --- entering and leaving the hive --------------------------------
1148 # --- nursery work -------------------------------------------------
1150 # --- royal jelly ---------------------------------------------------
1152 # --- idle work dispatch --------------------------------------------
1166 func _apply_pending_role() -> bool
1178 func _is_busy() -> bool
1184 func _idle_dispatch() -> void
1210 func _maybe_break_off_secondary() -> void
1234 func _try_role_work(r: int) -> bool
1418 # --- building -----------------------------------------------------
1420 # --- keeping cells topped up ---------------------------------------
1449 func set_restock_targets(cells: Array, resource: String) -> void
1452 func set_restock_sources(cells: Array, allowed: bool) -> void
1455 func clear_restock() -> void
1458 func has_restock_orders() -> bool
1460 # --- mining -------------------------------------------------------
1462 # --- honey making -------------------------------------------------
1464 # --- egg laying (queen only) --------------------------------------
1466 # --- player commands ----------------------------------------------
1476 func command_move_to(world_point: Vector2) -> void
1500 func command_exit_hive() -> void
1509 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
1517 func has_forage_start_point() -> bool
1520 func set_preferred_species(species: String) -> void
1533 func set_manual_build_target(hex: Vector2i) -> void
1541 func queue_build_target(hex: Vector2i) -> void
1548 func clear_build_queue() -> void
1554 func _take_next_build_target() -> bool
1567 func set_mine_target(block: Node2D) -> void
1574 func queue_mine_target(block: Node2D) -> void
1582 func clear_mine_queue() -> void
1589 func _next_queued_block() -> Node2D
1597 func set_home_hex(hex: Vector2i) -> void
1606 func set_mine_home_hex(hex: Vector2i) -> void
1612 func _mine_reference_point() -> Vector2
1625 func command_collect_from(flower: Node2D) -> void
1645 func command_return_and_deposit() -> void
1654 func command_return_only() -> void
1659 func command_deposit_at(cell: Node2D) -> void
1664 func set_focus(type: String) -> void
1691 func set_secondary_role(new_role: int) -> void
1694 func can_take_role(new_role: int) -> bool
1704 func set_role(new_role: int) -> void
1721 func _apply_role(new_role: int) -> void
1754 func _release_everything() -> void
1771 func release_flower_reference(flower: Node2D) -> void
1777 func set_selected(value: bool) -> void
1781 # --- display ------------------------------------------------------
1783 func role_letter() -> String
1801 func idle_reason() -> String
1852 func task_description() -> String
1997 func _idle_backup_note() -> String
2002 func role_name_text() -> String
2028 func nurse_mode_name() -> String
2037 func architect_mode_name() -> String
2043 func carrying_text() -> String
2064 func age_days() -> float
2072 func leave_to_found_colony() -> void
2085 func days_remaining() -> float
2097 func _update_label() -> void
2117 func _update_alarm_ring() -> void
2128 func _update_heading_marker() -> void
2142 func _update_search_ring() -> void
2170 func _update_wander_flight(delta: float) -> void
2201 func _update_dance_circle(delta: float) -> void
2215 func _terrain_speed_factor() -> float
2224 func _is_inside_hive() -> bool
2227 # --- getting round things in the meadow ---------------------------
2247 func clear_navigation_state() -> void
```

## debug_panel.gd (1,666 lines)

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
1107 func _report_settings_button_width() -> void
1112 func _rows_in(category: String) -> Array
1134 func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
1164 func _make_section(category: String, entries: Array, start_open: bool) -> Control
1220 func _make_controls_help() -> Control
1253 func _build_actions(column: VBoxContainer) -> void
1295 func _make_winter_action() -> Control
1307 func _on_winter_pressed() -> void
1313 func _on_challenge_advance_pressed() -> void
1324 func set_save_load_enabled(enabled: bool) -> void
1332 func set_toggle(key: String, value: bool) -> void
1337 func _on_save_pressed() -> void
1348 func _on_load_pressed() -> void
1360 func _toggle_panel() -> void
1366 func _make_row(entry: Dictionary) -> Control
1409 func _make_control_slot() -> HBoxContainer
1418 func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
1448 func _make_toggle_row(entry: Dictionary) -> Control
1512 func _make_options_row(entry: Dictionary) -> Control
1545 func _option_display(entry: Dictionary, value) -> String
1549 func _cycle_option(entry: Dictionary, direction: int) -> void
1563 func _cascade_prerequisites_on(key: String) -> void
1570 func _cascade_dependents_off(key: String) -> void
1577 func _cascade_mutual_exclusion(key: String) -> void
1586 func _make_star_row(entry: Dictionary) -> Control
1627 func _adjust(entry: Dictionary, delta: float) -> void
1642 func _format_value(v) -> String
1649 func _on_restart_pressed() -> void
1654 func _on_main_menu_pressed() -> void
1662 func _restart() -> void
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

## main.gd (1,176 lines)

Per-frame entry point, everything not yet split out of main.

```
334  func _ready() -> void
572  # --- public surface other scripts call directly -------------------
579  func is_on_screen(node: Node2D) -> bool
582  func hive_entrance_inside() -> Vector2
585  func entrance_wait_point(side: int) -> Vector2
588  func move_bee_into_hive(bee: Node2D) -> void
591  func move_bee_out_of_hive(bee: Node2D) -> void
594  func mark_death(bee: Node2D) -> void
602  func _on_bee_died(bee: Node2D) -> void
606  func finish_mining(block: Node2D) -> void
609  func save_run() -> void
612  func begin_winter_countdown() -> void
615  # --- per-frame ----------------------------------------------------
625  func _process(delta: float) -> void
698  # --- the frame rate readout ----------------------------------------
717  func _sample_fps() -> void
740  func _reseed_meadow(delta: float) -> void
755  func _hatch_ready_brood() -> void
787  func _advance_weather(delta: float) -> void
817  func _apply_rain_overlay() -> void
832  func _check_for_loss() -> void
854  func _check_colony_energy(delta: float) -> void
888  func invalidate_population() -> void
899  func _role_counts() -> Dictionary
917  func _update_population_readout(bees = null) -> void
939  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
945  func _prune_selection() -> void
958  func _on_restart_after_loss() -> void
964  func _on_level_chosen(level: int) -> void
977  func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
994  func _apply_scenario_boot_arg() -> void
1109 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1149 func _is_whole_number(value: Variant) -> bool
1163 func _end_scenario_run(outcome: String) -> void
```
