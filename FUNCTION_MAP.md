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

## hud.gd (2,594 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
125  static func hatch_options() -> Array
170  static func mode_command(role_id: int, mode_key: String) -> String
438  func _signal_color(severity: int) -> Color
449  func _ready() -> void
502  func _on_viewport_size_changed() -> void
506  func _make_label(pos: Vector2, variation: String = "Body") -> Label
514  func _info(text: String) -> Button
517  func _with_info(control: Control, tip: String) -> HBoxContainer
522  func _style_button(button: BaseButton) -> BaseButton
550  func _build_top_right_bar() -> void
659  func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button
695  func _apply_interface_label_visibility() -> void
705  func _build_goal_shelf() -> void
772  func set_settings_button_width(width: float) -> void
786  func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void
801  func set_speed_display(speed_scale: float) -> void
810  func _build_selection_panel() -> void
890  func _build_selection_cog() -> Control
913  func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
924  func _apply_selection_field_visibility() -> void
936  func _build_command_tray() -> void
1006 func _build_tray_column(title: String) -> Array
1026 # --- cell popup ---------------------------------------------------
1042 func _build_cell_group(parent: VBoxContainer) -> void
1133 func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer
1154 func _build_nursery_controls(column: VBoxContainer) -> void
1249 func _build_closing_controls(column: VBoxContainer) -> void
1289 func _build_empty_controls(column: VBoxContainer) -> void
1332 func _make_hatch_menu(entry: Dictionary) -> Control
1356 func _build_warning_banner() -> void
1389 func show_warning(text: String, key: String = "", min_gap: float = 0.0) -> void
1401 func set_warnings_muted(value: bool) -> void
1414 func show_object_summary(kind: String, data) -> void
1432 func _refresh_flower_summary() -> void
1468 func _show_obstacle_summary(obstacle: Node2D) -> void
1474 func _show_soil_summary(count: int, reachable: int) -> void
1490 func _show_death_summary(info: Dictionary) -> void
1512 func show_cell_popup(cell: Node2D, count: int = 1) -> void
1530 func _refresh_cell_popup() -> void
1632 func _apply_cell_popup_gating() -> void
1648 func _light_current_options() -> void
1666 func _set_lit(key: String, lit: bool) -> void
1677 func _process(_delta: float) -> void
1702 func _request_designation(type: String) -> void
1707 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1712 func _request_empty(method: String) -> void
1717 func _request_priority(tier: int) -> void
1722 func _request_close(closed: bool) -> void
1727 func _request_fill_close() -> void
1732 # --- discard warning ----------------------------------------------
1738 func _build_discard_dialog() -> void
1753 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1762 func _on_discard_confirmed() -> void
1765 func _on_discard_custom_action(action: StringName) -> void
1772 func _apply_discard() -> void
1780 # --- readouts -----------------------------------------------------
1785 func update_day(day: int, note: String = "") -> void
1795 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1804 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1810 func update_comb(text: String) -> void
1814 func update_energy(mean_fraction: float) -> void
1821 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1832 func update_recruit_gap(text: String) -> void
1845 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
1851 func update_signals(lines: Array) -> void
1859 func _refresh_corner() -> void
1938 func corner_bottom() -> float
1946 func pinned_stats_changed() -> void
1955 func refresh_speed_visibility() -> void
1962 func refresh_corner() -> void
1965 func update_selection(bees: Array) -> void
1988 func _selection_has_command_lock(bees: Array) -> bool
2003 func _rebuild_role_controls(bees: Array) -> void
2048 func _build_queen_build_row(column: VBoxContainer) -> void
2062 func _build_follow_control(bees: Array, first) -> void
2078 func _build_favourite_row(bee) -> void
2089 func _build_job_row(common_role: int, any_queen: bool) -> void
2117 func _build_doing_row(common_role: int, first) -> void
2143 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2158 func _build_orders_row(common_role: int, first) -> void
2205 func _build_restock_row(first) -> void
2233 func _build_fallback_row(common_role: int, first) -> void
2265 func _secondary_items() -> Array
2281 func _column_row(parent: Container) -> HFlowContainer
2289 func _labelled_row(title: String) -> HFlowContainer
2308 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2320 func _action_button(label: String, action: Callable, tip: String) -> Control
2329 func _current_role_marker(label: String) -> Control
2340 func _common_role(bees: Array) -> int
2357 func _common_working_role(bees: Array) -> int
2371 func _make_role_menu(label: String, tip: String, items: Array) -> Control
2386 func _refresh_selection_text() -> void
2470 func _apply_selection_tray_width() -> void
2481 func _update_command_tray_width() -> void
2502 func _resize_command_tray() -> void
2511 func set_winter_button_visible(value: bool) -> void
2517 func set_view_label(in_hive: bool) -> void
2523 func set_colony_button_visible(value: bool) -> void
2529 func set_nursery_button_visible(value: bool) -> void
2535 func set_view_button_visible(value: bool) -> void
2541 func set_foraging_button_visible(value: bool) -> void
2548 func set_allowed_role_keys(keys: Array) -> void
2558 func set_command_locked_bees(bees: Array) -> void
2563 func set_allowed_mode_keys(keys: Array) -> void
2571 func set_allowed_designation_keys(keys: Array) -> void
2576 func set_hatch_lock_visible(value: bool) -> void
2581 func set_soil_marking_visible(value: bool) -> void
2591 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (2,441 lines)

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
1823 func set_secondary_role(new_role: int) -> void
1826 func can_take_role(new_role: int) -> bool
1836 func set_role(new_role: int) -> void
1853 func _apply_role(new_role: int) -> void
1886 func _release_everything() -> void
1903 func release_flower_reference(flower: Node2D) -> void
1909 func set_selected(value: bool) -> void
1913 # --- display ------------------------------------------------------
1915 func role_letter() -> String
1944 func challenge_vocabulary_limited() -> bool
1957 func idle_reason() -> String
2010 func task_description() -> String
2157 func _idle_backup_note() -> String
2167 func role_name_text() -> String
2193 func nurse_mode_name() -> String
2202 func architect_mode_name() -> String
2208 func carrying_text() -> String
2229 func age_days() -> float
2237 func leave_to_found_colony() -> void
2250 func days_remaining() -> float
2262 func _update_label() -> void
2282 func _update_alarm_ring() -> void
2293 func _update_heading_marker() -> void
2307 func _update_search_ring() -> void
2330 func _update_dance_ring() -> void
2363 func _update_wander_flight(delta: float) -> void
2394 func _update_dance_circle(delta: float) -> void
2408 func _terrain_speed_factor() -> float
2417 func _is_inside_hive() -> bool
2420 # --- getting round things in the meadow ---------------------------
2440 func clear_navigation_state() -> void
```

## debug_panel.gd (862 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
60   func _style_button(button: BaseButton) -> BaseButton
65   func _ready() -> void
166  func _report_settings_button_width() -> void
171  func _rows_in(category: String) -> Array
193  func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
224  func _set_open(header: Button, body: Control, label: String, open: bool) -> void
232  func open_to_categories(categories: Array) -> void
250  func _make_section(category: String, entries: Array, start_open: bool) -> Control
304  func _make_controls_help() -> Control
338  func _build_actions(column: VBoxContainer) -> void
405  func _make_winter_action() -> Control
417  func _on_winter_pressed() -> void
423  func _on_challenge_advance_pressed() -> void
436  func _on_fire_test_warnings_pressed() -> void
471  func _on_force_c2_collapse_pressed() -> void
491  func set_save_load_enabled(enabled: bool) -> void
499  func set_toggle(key: String, value: bool) -> void
504  func _on_save_pressed() -> void
515  func _on_load_pressed() -> void
527  func _toggle_panel() -> void
541  func _apply_layer_for_context() -> void
546  func _make_row(entry: Dictionary) -> Control
589  func _make_control_slot() -> HBoxContainer
598  func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
628  func _make_toggle_row(entry: Dictionary) -> Control
699  func _make_options_row(entry: Dictionary) -> Control
732  func _option_display(entry: Dictionary, value) -> String
736  func _cycle_option(entry: Dictionary, direction: int) -> void
751  func _cascade_prerequisites_on(key: String) -> void
765  func _cascade_dependents_off(key: String) -> void
773  func _cascade_mutual_exclusion(key: String) -> void
782  func _make_star_row(entry: Dictionary) -> Control
823  func _adjust(entry: Dictionary, delta: float) -> void
838  func _format_value(v) -> String
845  func _on_restart_pressed() -> void
850  func _on_main_menu_pressed() -> void
858  func _restart() -> void
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

## hive_cell.gd (1,086 lines)

One cell: contents, brood, honey ripening, how it draws.

```
139  func effective_build_time() -> float
239  func _ready() -> void
358  func set_overlay(mode: String) -> void
364  func _overlay_colour() -> Array
402  func set_selected(value: bool) -> void
414  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
425  func _set_outline_points(line: Line2D, size: float) -> void
436  func _silhouette_point_to_local(p: Vector2) -> Vector2
448  func _set_outline_points_cup(line: Line2D, size: float) -> void
464  func _apply_outline_points(line: Line2D, size: float) -> void
472  func _set_selection_ring_points() -> void
491  func _process(delta: float) -> void
515  func _develop_brood(delta: float) -> void
536  func _health_factor() -> float
544  func _larva_dies() -> void
559  func _invalidate_hive_index() -> void
574  func bump_display_epoch() -> void
577  # --- working positions --------------------------------------------
582  func claim_slot(bee: Node2D) -> int
593  func release_slot(bee: Node2D) -> void
601  func slot_position(index: int) -> Vector2
608  # --- building -----------------------------------------------------
610  func start_as_site() -> void
615  func claim_builder(bee: Node2D) -> void
619  func release_builder(bee: Node2D) -> void
624  func add_build_progress(delta: float) -> void
635  func build_fraction() -> float
638  # --- contents -----------------------------------------------------
640  func is_empty() -> bool
645  func capacity_for(resource_type: String) -> float
654  func accepts(resource_type: String) -> bool
673  func is_nursery_cell() -> bool
676  func space_for(resource_type: String) -> float
692  func needs_eviction() -> bool
710  func add_resource(resource_type: String, requested: float) -> float
741  func take_resource(resource_type: String, requested: float) -> float
768  func can_withdraw() -> bool
773  func set_closed(value: bool) -> void
779  func set_fill_then_close(value: bool) -> void
787  func fill_fraction() -> float
794  func set_designation(resource_type: String, explicit: bool = true) -> void
802  # --- honey ---------------------------------------------------------
804  func is_ripe_honey() -> bool
808  func needs_fanning() -> bool
813  func add_fanning_progress(delta: float) -> void
822  func ripen_fraction() -> float
825  # --- brood ---------------------------------------------------------
827  func start_brood(as_gyne: bool = false) -> void
840  func develop_time() -> float
848  func feed_brood(seconds: float, on_honey: bool) -> void
853  func needs_feeding() -> bool
857  func seconds_until_death() -> float
862  # --- clearing a dead larva ------------------------------------------
864  func needs_cleaning() -> bool
870  func add_clean_progress(delta: float) -> bool
876  func clean_fraction() -> float
879  func brood_ready() -> bool
882  func clear_cell() -> void
895  # --- display ------------------------------------------------------
897  func _refresh() -> void
1037 func _designation_tag() -> String
1059 func _priority_mark() -> String
1072 func _apply_fill_shading() -> void
1083 func development_percent() -> float
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
