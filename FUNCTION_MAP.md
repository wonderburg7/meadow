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

## hud.gd (2,388 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
126  static func hatch_options() -> Array
171  static func mode_command(role_id: int, mode_key: String) -> String
381  func _signal_color(severity: int) -> Color
392  func _ready() -> void
434  func _make_label(pos: Vector2, variation: String = "Body") -> Label
442  func _info(text: String) -> Button
445  func _with_info(control: Control, tip: String) -> HBoxContainer
450  func _style_button(button: BaseButton) -> BaseButton
471  func _build_top_right_bar() -> void
585  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
621  func _apply_interface_label_visibility() -> void
631  func _build_goal_shelf() -> void
690  func set_settings_button_width(width: float) -> void
704  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
719  func set_speed_display(speed_scale: float) -> void
728  func _build_selection_panel() -> void
792  func _build_selection_cog() -> Control
812  func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
823  func _apply_selection_field_visibility() -> void
835  func _build_command_tray() -> void
897  func _build_tray_column(title: String) -> Array
915  # --- cell popup ---------------------------------------------------
931  func _build_cell_group(parent: VBoxContainer) -> void
1081 func _build_cell_action_column(parent: HBoxContainer, title: String) -> VBoxContainer
1105 func _build_zone_controls(column: VBoxContainer) -> void
1160 func _build_closing_controls(column: VBoxContainer) -> void
1200 func _build_empty_controls(column: VBoxContainer) -> void
1243 func _make_hatch_menu(entry: Dictionary) -> Control
1267 func _build_warning_banner() -> void
1296 func show_warning(text: String) -> void
1303 func set_warnings_muted(value: bool) -> void
1316 func show_object_summary(kind: String, data) -> void
1334 func _refresh_flower_summary() -> void
1361 func _show_obstacle_summary(obstacle: Node2D) -> void
1367 func _show_soil_summary(count: int, reachable: int) -> void
1383 func _show_death_summary(info: Dictionary) -> void
1405 func show_cell_popup(cell: Node2D, count: int = 1) -> void
1421 func _refresh_cell_popup() -> void
1516 func _apply_cell_popup_gating() -> void
1530 func _light_current_options() -> void
1548 func _set_lit(key: String, lit: bool) -> void
1559 func _process(_delta: float) -> void
1574 func _request_designation(type: String) -> void
1579 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1584 func _request_empty(method: String) -> void
1589 func _request_zone(in_zone: bool) -> void
1594 func _request_priority(tier: int) -> void
1599 func _request_close(closed: bool) -> void
1604 func _request_fill_close() -> void
1609 # --- discard warning ----------------------------------------------
1615 func _build_discard_dialog() -> void
1630 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1639 func _on_discard_confirmed() -> void
1642 func _on_discard_custom_action(action: StringName) -> void
1649 func _apply_discard() -> void
1657 # --- readouts -----------------------------------------------------
1662 func update_day(day: int, note: String = "") -> void
1672 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1681 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1687 func update_comb(text: String) -> void
1691 func update_energy(mean_fraction: float) -> void
1698 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1709 func update_recruit_gap(text: String) -> void
1722 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
1728 func update_signals(lines: Array) -> void
1736 func _refresh_corner() -> void
1818 func pinned_stats_changed() -> void
1827 func refresh_speed_visibility() -> void
1834 func refresh_corner() -> void
1837 func update_selection(bees: Array) -> void
1858 func _selection_has_command_lock(bees: Array) -> bool
1875 func _rebuild_role_controls(bees: Array) -> void
1919 func _build_queen_build_row() -> void
1933 func _build_follow_control(bees: Array, first) -> void
1949 func _build_favourite_row(bee) -> void
1960 func _build_job_row(common_role: int, any_queen: bool) -> void
1988 func _build_doing_row(common_role: int, first) -> void
2014 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2029 func _build_orders_row(common_role: int, first) -> void
2076 func _build_restock_row(first) -> void
2104 func _build_fallback_row(common_role: int, first) -> void
2136 func _secondary_items() -> Array
2150 func _column_row(parent: Container) -> HBoxContainer
2156 func _labelled_row(title: String) -> HBoxContainer
2173 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2184 func _action_button(label: String, action: Callable, tip: String) -> Control
2192 func _current_role_marker(label: String) -> Control
2202 func _common_role(bees: Array) -> int
2215 func _make_role_menu(label: String, tip: String, items: Array) -> Control
2230 func _refresh_selection_text() -> void
2300 func _update_command_tray_width() -> void
2311 func set_winter_button_visible(value: bool) -> void
2317 func set_view_label(in_hive: bool) -> void
2323 func set_colony_button_visible(value: bool) -> void
2329 func set_nursery_button_visible(value: bool) -> void
2335 func set_view_button_visible(value: bool) -> void
2344 func set_allowed_role_keys(keys: Array) -> void
2352 func set_command_locked_bees(bees: Array) -> void
2357 func set_allowed_mode_keys(keys: Array) -> void
2365 func set_allowed_designation_keys(keys: Array) -> void
2370 func set_hatch_lock_visible(value: bool) -> void
2375 func set_soil_marking_visible(value: bool) -> void
2385 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (2,218 lines)

A bee's dispatch loop, player commands, display text, vars.

```
523  func _ready() -> void
660  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
700  func _roll_fact() -> void
714  func _default_state_for_role() -> int
736  func _base_colour() -> Color
747  func _tinted(c: Color) -> Color
762  func _apply_stats() -> void
788  func trait_text() -> String
797  func _update_role_marker() -> void
816  # --- how often a bee thinks ---------------------------------------
848  func _process(delta: float) -> void
1120 # --- life support -------------------------------------------------
1122 # --- eating -------------------------------------------------------
1124 # --- stall watchdog -----------------------------------------------
1130 func _reset_stall_watch() -> void
1133 # --- foraging -----------------------------------------------------
1135 # --- entering and leaving the hive --------------------------------
1137 # --- nursery work -------------------------------------------------
1139 # --- royal jelly ---------------------------------------------------
1141 # --- idle work dispatch --------------------------------------------
1155 func _apply_pending_role() -> bool
1167 func _is_busy() -> bool
1173 func _idle_dispatch() -> void
1199 func _maybe_break_off_secondary() -> void
1223 func _try_role_work(r: int) -> bool
1407 # --- building -----------------------------------------------------
1409 # --- keeping cells topped up ---------------------------------------
1438 func set_restock_targets(cells: Array, resource: String) -> void
1441 func set_restock_sources(cells: Array, allowed: bool) -> void
1444 func clear_restock() -> void
1447 func has_restock_orders() -> bool
1449 # --- mining -------------------------------------------------------
1451 # --- honey making -------------------------------------------------
1453 # --- egg laying (queen only) --------------------------------------
1455 # --- player commands ----------------------------------------------
1465 func command_move_to(world_point: Vector2) -> void
1489 func command_exit_hive() -> void
1498 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
1506 func has_forage_start_point() -> bool
1509 func set_preferred_species(species: String) -> void
1522 func set_manual_build_target(hex: Vector2i) -> void
1530 func queue_build_target(hex: Vector2i) -> void
1537 func clear_build_queue() -> void
1543 func _take_next_build_target() -> bool
1556 func set_mine_target(block: Node2D) -> void
1563 func queue_mine_target(block: Node2D) -> void
1571 func clear_mine_queue() -> void
1578 func _next_queued_block() -> Node2D
1586 func set_home_hex(hex: Vector2i) -> void
1595 func set_mine_home_hex(hex: Vector2i) -> void
1601 func _mine_reference_point() -> Vector2
1614 func command_collect_from(flower: Node2D) -> void
1634 func command_return_and_deposit() -> void
1641 func set_focus(type: String) -> void
1668 func set_secondary_role(new_role: int) -> void
1671 func can_take_role(new_role: int) -> bool
1681 func set_role(new_role: int) -> void
1698 func _apply_role(new_role: int) -> void
1724 func _release_everything() -> void
1741 func release_flower_reference(flower: Node2D) -> void
1747 func set_selected(value: bool) -> void
1751 # --- display ------------------------------------------------------
1753 func role_letter() -> String
1771 func idle_reason() -> String
1822 func task_description() -> String
1967 func _idle_backup_note() -> String
1972 func role_name_text() -> String
1998 func nurse_mode_name() -> String
2007 func architect_mode_name() -> String
2013 func carrying_text() -> String
2034 func age_days() -> float
2042 func leave_to_found_colony() -> void
2055 func days_remaining() -> float
2067 func _update_label() -> void
2087 func _update_alarm_ring() -> void
2098 func _update_heading_marker() -> void
2112 func _update_search_ring() -> void
2140 func _update_wander_flight(delta: float) -> void
2171 func _update_dance_circle(delta: float) -> void
2185 func _terrain_speed_factor() -> float
2194 func _is_inside_hive() -> bool
2197 # --- getting round things in the meadow ---------------------------
2217 func clear_navigation_state() -> void
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

## hive.gd (970 lines)

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
102  func _content_index() -> Dictionary
126  func invalidate_index() -> void
129  func cells_holding(content: String) -> Array
141  func register_tile(hex: Vector2i, node: Node2D) -> void
147  func invalidate_mining_work() -> void
151  func _advance_mining_work_epoch() -> void
154  func tile_is_free(hex: Vector2i) -> bool
159  func tile_is_interior(hex: Vector2i) -> bool
164  func cell_at_tile(hex: Vector2i) -> Node2D
170  func _ready() -> void
180  func deposit(resource_type: String, amount: float) -> float
199  func take(resource_type: String, amount: float) -> float
214  func take_energy(energy_wanted: float) -> float
227  func total(resource_type: String) -> float
237  func total_sealed() -> float
245  func total_honey() -> float
252  # --- finding cells ------------------------------------------------
265  func find_cell_for(resource_type: String, except: Node2D = null) -> Node2D
289  func find_designated_cell_for(resource_type: String, except: Node2D = null) -> Node2D
327  func find_empty_cell() -> Node2D
373  func _lay_by_priority(pool: Array) -> Node2D
404  func _tier_weights() -> Array
419  func record_lay(cell: Node2D) -> void
433  func zone_summary() -> Dictionary
463  func brood_stage_counts() -> Dictionary
478  func find_food_cell(except: Node2D = null) -> Node2D
491  func has_room_for_egg() -> bool
494  func find_cell_with(resource_type: String) -> Node2D
507  func find_brood_cell() -> Node2D
522  func find_cell_needing_fanning() -> Node2D
530  func find_honey_target() -> Node2D
533  func find_unfinished_cell() -> Node2D
542  func find_cell_needing_cleaning() -> Node2D
546  func find_cell_needing_eviction() -> Node2D
554  func has_gyne_brood() -> bool
562  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
565  # --- growing the comb ---------------------------------------------
599  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
633  func set_keep_clear(hex: Vector2i, value: bool) -> void
639  func is_keep_clear(hex: Vector2i) -> bool
646  func can_build_on(hex: Vector2i) -> bool
649  func _can_build_on(hex: Vector2i) -> bool
652  func _start_site_at(hex: Vector2i) -> Node2D
668  func create_cell_site_at(hex: Vector2i) -> Node2D
673  # --- navigation ---------------------------------------------------
684  func build_navigation() -> void
725  func _is_solid(hex: Vector2i) -> bool
731  func _tile_cost(hex: Vector2i) -> float
734  func tile_is_walkable(hex: Vector2i) -> bool
743  func nearest_walkable_point(point: Vector2) -> Vector2
770  func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
804  func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
828  func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
838  # --- mining -------------------------------------------------------
847  func refresh_edge_flags() -> void
869  func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
891  func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
910  func _is_markable_block(node) -> bool
917  func mine_stand_hex(block: Node2D)
940  func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
958  func remove_block(block: Node2D, floor_maker: Callable) -> void
969  func announce() -> void
```

## main.gd (1,125 lines)

Per-frame entry point, everything not yet split out of main.

```
320  func _ready() -> void
555  # --- public surface other scripts call directly -------------------
562  func is_on_screen(node: Node2D) -> bool
565  func hive_entrance_inside() -> Vector2
568  func entrance_wait_point(side: int) -> Vector2
571  func move_bee_into_hive(bee: Node2D) -> void
574  func move_bee_out_of_hive(bee: Node2D) -> void
577  func mark_death(bee: Node2D) -> void
580  func finish_mining(block: Node2D) -> void
583  func save_run() -> void
586  func begin_winter_countdown() -> void
589  # --- per-frame ----------------------------------------------------
599  func _process(delta: float) -> void
672  # --- the frame rate readout ----------------------------------------
691  func _sample_fps() -> void
714  func _reseed_meadow(delta: float) -> void
729  func _hatch_ready_brood() -> void
759  func _advance_weather(delta: float) -> void
787  func _apply_rain_overlay() -> void
802  func _check_for_loss() -> void
824  func _check_colony_energy(delta: float) -> void
853  func _role_counts() -> Dictionary
867  func _update_population_readout(bees = null) -> void
888  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
894  func _prune_selection() -> void
907  func _on_restart_after_loss() -> void
913  func _on_level_chosen(level: int) -> void
926  func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void
943  func _apply_scenario_boot_arg() -> void
1058 func _parse_scenario_performance_capture(raw: Variant) -> Dictionary
1098 func _is_whole_number(value: Variant) -> bool
1112 func _end_scenario_run(outcome: String) -> void
```
