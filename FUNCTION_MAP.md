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

## hud.gd (2,509 lines)

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
2006 func _build_queen_build_row(column: VBoxContainer) -> void
2020 func _build_follow_control(bees: Array, first) -> void
2036 func _build_favourite_row(bee) -> void
2047 func _build_job_row(common_role: int, any_queen: bool) -> void
2075 func _build_doing_row(common_role: int, first) -> void
2101 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2116 func _build_orders_row(common_role: int, first) -> void
2163 func _build_restock_row(first) -> void
2191 func _build_fallback_row(common_role: int, first) -> void
2223 func _secondary_items() -> Array
2239 func _column_row(parent: Container) -> HFlowContainer
2247 func _labelled_row(title: String) -> HFlowContainer
2266 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2278 func _action_button(label: String, action: Callable, tip: String) -> Control
2287 func _current_role_marker(label: String) -> Control
2298 func _common_role(bees: Array) -> int
2311 func _make_role_menu(label: String, tip: String, items: Array) -> Control
2326 func _refresh_selection_text() -> void
2395 func _apply_selection_tray_width() -> void
2411 func _update_command_tray_width() -> void
2426 func set_winter_button_visible(value: bool) -> void
2432 func set_view_label(in_hive: bool) -> void
2438 func set_colony_button_visible(value: bool) -> void
2444 func set_nursery_button_visible(value: bool) -> void
2450 func set_view_button_visible(value: bool) -> void
2456 func set_foraging_button_visible(value: bool) -> void
2463 func set_allowed_role_keys(keys: Array) -> void
2473 func set_command_locked_bees(bees: Array) -> void
2478 func set_allowed_mode_keys(keys: Array) -> void
2486 func set_allowed_designation_keys(keys: Array) -> void
2491 func set_hatch_lock_visible(value: bool) -> void
2496 func set_soil_marking_visible(value: bool) -> void
2506 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (2,340 lines)

A bee's dispatch loop, player commands, display text, vars.

```
567  func _ready() -> void
704  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
746  func _roll_fact() -> void
760  func _default_state_for_role() -> int
782  func _base_colour() -> Color
793  func _tinted(c: Color) -> Color
808  func _apply_stats() -> void
834  func trait_text() -> String
843  func _update_role_marker() -> void
862  # --- how often a bee thinks ---------------------------------------
894  func _process(delta: float) -> void
1166 # --- life support -------------------------------------------------
1168 # --- eating -------------------------------------------------------
1170 # --- stall watchdog -----------------------------------------------
1176 func _reset_stall_watch() -> void
1179 # --- foraging -----------------------------------------------------
1181 # --- entering and leaving the hive --------------------------------
1183 # --- nursery work -------------------------------------------------
1185 # --- royal jelly ---------------------------------------------------
1187 # --- idle work dispatch --------------------------------------------
1201 func _apply_pending_role() -> bool
1213 func _is_busy() -> bool
1219 func _idle_dispatch() -> void
1245 func _maybe_break_off_secondary() -> void
1269 func _try_role_work(r: int) -> bool
1453 # --- building -----------------------------------------------------
1455 # --- keeping cells topped up ---------------------------------------
1484 func set_restock_targets(cells: Array, resource: String) -> void
1487 func set_restock_sources(cells: Array, allowed: bool) -> void
1490 func clear_restock() -> void
1493 func has_restock_orders() -> bool
1495 # --- mining -------------------------------------------------------
1497 # --- honey making -------------------------------------------------
1499 # --- egg laying (queen only) --------------------------------------
1501 # --- player commands ----------------------------------------------
1511 func command_move_to(world_point: Vector2) -> void
1531 func command_move_through_entrance(world_point: Vector2, target_in_hive: bool) -> void
1543 func command_exit_hive() -> void
1553 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
1561 func has_forage_start_point() -> bool
1564 func set_preferred_species(species: String) -> void
1577 func set_manual_build_target(hex: Vector2i) -> void
1585 func queue_build_target(hex: Vector2i) -> void
1592 func clear_build_queue() -> void
1598 func _take_next_build_target() -> bool
1611 func set_mine_target(block: Node2D) -> void
1618 func queue_mine_target(block: Node2D) -> void
1626 func clear_mine_queue() -> void
1633 func _next_queued_block() -> Node2D
1641 func set_home_hex(hex: Vector2i) -> void
1650 func set_mine_home_hex(hex: Vector2i) -> void
1656 func _mine_reference_point() -> Vector2
1671 func command_collect_from(flower: Node2D) -> void
1687 func command_collect_from_after_exit(flower: Node2D) -> void
1700 func command_return_and_deposit() -> void
1710 func command_return_only() -> void
1716 func command_deposit_at(cell: Node2D) -> void
1724 func command_deposit_at_after_enter(cell: Node2D) -> void
1732 func resume_pending_zone_command() -> bool
1751 func _clear_pending_zone_command() -> void
1756 func set_focus(type: String) -> void
1783 func set_secondary_role(new_role: int) -> void
1786 func can_take_role(new_role: int) -> bool
1796 func set_role(new_role: int) -> void
1813 func _apply_role(new_role: int) -> void
1846 func _release_everything() -> void
1863 func release_flower_reference(flower: Node2D) -> void
1869 func set_selected(value: bool) -> void
1873 # --- display ------------------------------------------------------
1875 func role_letter() -> String
1893 func idle_reason() -> String
1944 func task_description() -> String
2089 func _idle_backup_note() -> String
2094 func role_name_text() -> String
2120 func nurse_mode_name() -> String
2129 func architect_mode_name() -> String
2135 func carrying_text() -> String
2156 func age_days() -> float
2164 func leave_to_found_colony() -> void
2177 func days_remaining() -> float
2189 func _update_label() -> void
2209 func _update_alarm_ring() -> void
2220 func _update_heading_marker() -> void
2234 func _update_search_ring() -> void
2262 func _update_wander_flight(delta: float) -> void
2293 func _update_dance_circle(delta: float) -> void
2307 func _terrain_speed_factor() -> float
2316 func _is_inside_hive() -> bool
2319 # --- getting round things in the meadow ---------------------------
2339 func clear_navigation_state() -> void
```

## debug_panel.gd (1,781 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
961  static func setting_get(key: String)
964  static func setting_set(key: String, value) -> void
979  static func reset_config_to_defaults() -> void
995  static func apply_setting(key: String, value) -> void
1010 static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1024 static func _cascade_dependents_off_static(key: String) -> Array[String]
1038 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
1071 func _style_button(button: BaseButton) -> BaseButton
1076 func _ready() -> void
1177 func _report_settings_button_width() -> void
1182 func _rows_in(category: String) -> Array
1204 func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
1235 func _set_open(header: Button, body: Control, label: String, open: bool) -> void
1243 func open_to_categories(categories: Array) -> void
1261 func _make_section(category: String, entries: Array, start_open: bool) -> Control
1315 func _make_controls_help() -> Control
1348 func _build_actions(column: VBoxContainer) -> void
1390 func _make_winter_action() -> Control
1402 func _on_winter_pressed() -> void
1408 func _on_challenge_advance_pressed() -> void
1419 func set_save_load_enabled(enabled: bool) -> void
1427 func set_toggle(key: String, value: bool) -> void
1432 func _on_save_pressed() -> void
1443 func _on_load_pressed() -> void
1455 func _toggle_panel() -> void
1469 func _apply_layer_for_context() -> void
1474 func _make_row(entry: Dictionary) -> Control
1517 func _make_control_slot() -> HBoxContainer
1526 func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
1556 func _make_toggle_row(entry: Dictionary) -> Control
1627 func _make_options_row(entry: Dictionary) -> Control
1660 func _option_display(entry: Dictionary, value) -> String
1664 func _cycle_option(entry: Dictionary, direction: int) -> void
1678 func _cascade_prerequisites_on(key: String) -> void
1685 func _cascade_dependents_off(key: String) -> void
1692 func _cascade_mutual_exclusion(key: String) -> void
1701 func _make_star_row(entry: Dictionary) -> Control
1742 func _adjust(entry: Dictionary, delta: float) -> void
1757 func _format_value(v) -> String
1764 func _on_restart_pressed() -> void
1769 func _on_main_menu_pressed() -> void
1777 func _restart() -> void
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

## main.gd (1,202 lines)

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
1020 func _apply_scenario_boot_arg() -> void
1135 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1175 func _is_whole_number(value: Variant) -> bool
1189 func _end_scenario_run(outcome: String) -> void
```
