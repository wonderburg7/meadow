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

## hud.gd (2,495 lines)

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
899  func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void
910  func _apply_selection_field_visibility() -> void
922  func _build_command_tray() -> void
984  func _build_tray_column(title: String) -> Array
1004 # --- cell popup ---------------------------------------------------
1020 func _build_cell_group(parent: VBoxContainer) -> void
1110 func _build_cell_action_column(parent: HBoxContainer, title: String) -> VBoxContainer
1131 func _build_nursery_controls(column: VBoxContainer) -> void
1226 func _build_closing_controls(column: VBoxContainer) -> void
1266 func _build_empty_controls(column: VBoxContainer) -> void
1309 func _make_hatch_menu(entry: Dictionary) -> Control
1333 func _build_warning_banner() -> void
1362 func show_warning(text: String) -> void
1369 func set_warnings_muted(value: bool) -> void
1382 func show_object_summary(kind: String, data) -> void
1400 func _refresh_flower_summary() -> void
1427 func _show_obstacle_summary(obstacle: Node2D) -> void
1433 func _show_soil_summary(count: int, reachable: int) -> void
1449 func _show_death_summary(info: Dictionary) -> void
1471 func show_cell_popup(cell: Node2D, count: int = 1) -> void
1490 func _refresh_cell_popup() -> void
1592 func _apply_cell_popup_gating() -> void
1608 func _light_current_options() -> void
1626 func _set_lit(key: String, lit: bool) -> void
1637 func _process(_delta: float) -> void
1662 func _request_designation(type: String) -> void
1667 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1672 func _request_empty(method: String) -> void
1677 func _request_priority(tier: int) -> void
1682 func _request_close(closed: bool) -> void
1687 func _request_fill_close() -> void
1692 # --- discard warning ----------------------------------------------
1698 func _build_discard_dialog() -> void
1713 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1722 func _on_discard_confirmed() -> void
1725 func _on_discard_custom_action(action: StringName) -> void
1732 func _apply_discard() -> void
1740 # --- readouts -----------------------------------------------------
1745 func update_day(day: int, note: String = "") -> void
1755 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1764 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1770 func update_comb(text: String) -> void
1774 func update_energy(mean_fraction: float) -> void
1781 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1792 func update_recruit_gap(text: String) -> void
1805 func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void
1811 func update_signals(lines: Array) -> void
1819 func _refresh_corner() -> void
1901 func pinned_stats_changed() -> void
1910 func refresh_speed_visibility() -> void
1917 func refresh_corner() -> void
1920 func update_selection(bees: Array) -> void
1941 func _selection_has_command_lock(bees: Array) -> bool
1956 func _rebuild_role_controls(bees: Array) -> void
2000 func _build_queen_build_row(column: VBoxContainer) -> void
2014 func _build_follow_control(bees: Array, first) -> void
2030 func _build_favourite_row(bee) -> void
2041 func _build_job_row(common_role: int, any_queen: bool) -> void
2069 func _build_doing_row(common_role: int, first) -> void
2095 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
2110 func _build_orders_row(common_role: int, first) -> void
2157 func _build_restock_row(first) -> void
2185 func _build_fallback_row(common_role: int, first) -> void
2217 func _secondary_items() -> Array
2233 func _column_row(parent: Container) -> HBoxContainer
2239 func _labelled_row(title: String) -> HBoxContainer
2256 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
2268 func _action_button(label: String, action: Callable, tip: String) -> Control
2277 func _current_role_marker(label: String) -> Control
2288 func _common_role(bees: Array) -> int
2301 func _make_role_menu(label: String, tip: String, items: Array) -> Control
2316 func _refresh_selection_text() -> void
2385 func _apply_selection_tray_width() -> void
2401 func _update_command_tray_width() -> void
2412 func set_winter_button_visible(value: bool) -> void
2418 func set_view_label(in_hive: bool) -> void
2424 func set_colony_button_visible(value: bool) -> void
2430 func set_nursery_button_visible(value: bool) -> void
2436 func set_view_button_visible(value: bool) -> void
2442 func set_foraging_button_visible(value: bool) -> void
2449 func set_allowed_role_keys(keys: Array) -> void
2459 func set_command_locked_bees(bees: Array) -> void
2464 func set_allowed_mode_keys(keys: Array) -> void
2472 func set_allowed_designation_keys(keys: Array) -> void
2477 func set_hatch_lock_visible(value: bool) -> void
2482 func set_soil_marking_visible(value: bool) -> void
2492 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (2,334 lines)

A bee's dispatch loop, player commands, display text, vars.

```
563  func _ready() -> void
700  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
742  func _roll_fact() -> void
756  func _default_state_for_role() -> int
778  func _base_colour() -> Color
789  func _tinted(c: Color) -> Color
804  func _apply_stats() -> void
830  func trait_text() -> String
839  func _update_role_marker() -> void
858  # --- how often a bee thinks ---------------------------------------
890  func _process(delta: float) -> void
1162 # --- life support -------------------------------------------------
1164 # --- eating -------------------------------------------------------
1166 # --- stall watchdog -----------------------------------------------
1172 func _reset_stall_watch() -> void
1175 # --- foraging -----------------------------------------------------
1177 # --- entering and leaving the hive --------------------------------
1179 # --- nursery work -------------------------------------------------
1181 # --- royal jelly ---------------------------------------------------
1183 # --- idle work dispatch --------------------------------------------
1197 func _apply_pending_role() -> bool
1209 func _is_busy() -> bool
1215 func _idle_dispatch() -> void
1241 func _maybe_break_off_secondary() -> void
1265 func _try_role_work(r: int) -> bool
1449 # --- building -----------------------------------------------------
1451 # --- keeping cells topped up ---------------------------------------
1480 func set_restock_targets(cells: Array, resource: String) -> void
1483 func set_restock_sources(cells: Array, allowed: bool) -> void
1486 func clear_restock() -> void
1489 func has_restock_orders() -> bool
1491 # --- mining -------------------------------------------------------
1493 # --- honey making -------------------------------------------------
1495 # --- egg laying (queen only) --------------------------------------
1497 # --- player commands ----------------------------------------------
1507 func command_move_to(world_point: Vector2) -> void
1527 func command_move_through_entrance(world_point: Vector2, target_in_hive: bool) -> void
1539 func command_exit_hive() -> void
1549 func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2
1557 func has_forage_start_point() -> bool
1560 func set_preferred_species(species: String) -> void
1573 func set_manual_build_target(hex: Vector2i) -> void
1581 func queue_build_target(hex: Vector2i) -> void
1588 func clear_build_queue() -> void
1594 func _take_next_build_target() -> bool
1607 func set_mine_target(block: Node2D) -> void
1614 func queue_mine_target(block: Node2D) -> void
1622 func clear_mine_queue() -> void
1629 func _next_queued_block() -> Node2D
1637 func set_home_hex(hex: Vector2i) -> void
1646 func set_mine_home_hex(hex: Vector2i) -> void
1652 func _mine_reference_point() -> Vector2
1665 func command_collect_from(flower: Node2D) -> void
1681 func command_collect_from_after_exit(flower: Node2D) -> void
1694 func command_return_and_deposit() -> void
1704 func command_return_only() -> void
1710 func command_deposit_at(cell: Node2D) -> void
1718 func command_deposit_at_after_enter(cell: Node2D) -> void
1726 func resume_pending_zone_command() -> bool
1745 func _clear_pending_zone_command() -> void
1750 func set_focus(type: String) -> void
1777 func set_secondary_role(new_role: int) -> void
1780 func can_take_role(new_role: int) -> bool
1790 func set_role(new_role: int) -> void
1807 func _apply_role(new_role: int) -> void
1840 func _release_everything() -> void
1857 func release_flower_reference(flower: Node2D) -> void
1863 func set_selected(value: bool) -> void
1867 # --- display ------------------------------------------------------
1869 func role_letter() -> String
1887 func idle_reason() -> String
1938 func task_description() -> String
2083 func _idle_backup_note() -> String
2088 func role_name_text() -> String
2114 func nurse_mode_name() -> String
2123 func architect_mode_name() -> String
2129 func carrying_text() -> String
2150 func age_days() -> float
2158 func leave_to_found_colony() -> void
2171 func days_remaining() -> float
2183 func _update_label() -> void
2203 func _update_alarm_ring() -> void
2214 func _update_heading_marker() -> void
2228 func _update_search_ring() -> void
2256 func _update_wander_flight(delta: float) -> void
2287 func _update_dance_circle(delta: float) -> void
2301 func _terrain_speed_factor() -> float
2310 func _is_inside_hive() -> bool
2313 # --- getting round things in the meadow ---------------------------
2333 func clear_navigation_state() -> void
```

## debug_panel.gd (1,756 lines)

The settings window (the cog icon): tuner rows, save/load buttons,
restart.

```
961  static func setting_get(key: String)
964  static func setting_set(key: String, value) -> void
979  static func apply_setting(key: String, value) -> void
994  static func _cascade_prerequisites_on_static(key: String) -> Array[String]
1008 static func _cascade_dependents_off_static(key: String) -> Array[String]
1022 static func _cascade_mutual_exclusion_static(key: String) -> Array[String]
1055 func _style_button(button: BaseButton) -> BaseButton
1060 func _ready() -> void
1152 func _report_settings_button_width() -> void
1157 func _rows_in(category: String) -> Array
1179 func _make_collection(collection_name: String, categories: Array, start_open: bool) -> Control
1210 func _set_open(header: Button, body: Control, label: String, open: bool) -> void
1218 func open_to_categories(categories: Array) -> void
1236 func _make_section(category: String, entries: Array, start_open: bool) -> Control
1290 func _make_controls_help() -> Control
1323 func _build_actions(column: VBoxContainer) -> void
1365 func _make_winter_action() -> Control
1377 func _on_winter_pressed() -> void
1383 func _on_challenge_advance_pressed() -> void
1394 func set_save_load_enabled(enabled: bool) -> void
1402 func set_toggle(key: String, value: bool) -> void
1407 func _on_save_pressed() -> void
1418 func _on_load_pressed() -> void
1430 func _toggle_panel() -> void
1444 func _apply_layer_for_context() -> void
1449 func _make_row(entry: Dictionary) -> Control
1492 func _make_control_slot() -> HBoxContainer
1501 func _wire_repeat_button(button: Button, entry: Dictionary, direction: float) -> void
1531 func _make_toggle_row(entry: Dictionary) -> Control
1602 func _make_options_row(entry: Dictionary) -> Control
1635 func _option_display(entry: Dictionary, value) -> String
1639 func _cycle_option(entry: Dictionary, direction: int) -> void
1653 func _cascade_prerequisites_on(key: String) -> void
1660 func _cascade_dependents_off(key: String) -> void
1667 func _cascade_mutual_exclusion(key: String) -> void
1676 func _make_star_row(entry: Dictionary) -> Control
1717 func _adjust(entry: Dictionary, delta: float) -> void
1732 func _format_value(v) -> String
1739 func _on_restart_pressed() -> void
1744 func _on_main_menu_pressed() -> void
1752 func _restart() -> void
```

## hive_cell.gd (994 lines)

One cell: contents, brood, honey ripening, how it draws.

```
119  func effective_build_time() -> float
212  func _ready() -> void
325  func set_overlay(mode: String) -> void
331  func _overlay_colour() -> Array
369  func set_selected(value: bool) -> void
381  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void
392  func _set_outline_points(line: Line2D, size: float) -> void
415  func _process(delta: float) -> void
439  func _develop_brood(delta: float) -> void
460  func _health_factor() -> float
468  func _larva_dies() -> void
483  func _invalidate_hive_index() -> void
498  func bump_display_epoch() -> void
501  # --- working positions --------------------------------------------
506  func claim_slot(bee: Node2D) -> int
517  func release_slot(bee: Node2D) -> void
525  func slot_position(index: int) -> Vector2
532  # --- building -----------------------------------------------------
534  func start_as_site() -> void
539  func claim_builder(bee: Node2D) -> void
543  func release_builder(bee: Node2D) -> void
548  func add_build_progress(delta: float) -> void
559  func build_fraction() -> float
562  # --- contents -----------------------------------------------------
564  func is_empty() -> bool
569  func capacity_for(resource_type: String) -> float
578  func accepts(resource_type: String) -> bool
597  func is_nursery_cell() -> bool
600  func space_for(resource_type: String) -> float
616  func needs_eviction() -> bool
634  func add_resource(resource_type: String, requested: float) -> float
665  func take_resource(resource_type: String, requested: float) -> float
692  func can_withdraw() -> bool
697  func set_closed(value: bool) -> void
703  func set_fill_then_close(value: bool) -> void
711  func fill_fraction() -> float
718  func set_designation(resource_type: String, explicit: bool = true) -> void
726  # --- honey ---------------------------------------------------------
728  func is_ripe_honey() -> bool
732  func needs_fanning() -> bool
737  func add_fanning_progress(delta: float) -> void
746  func ripen_fraction() -> float
749  # --- brood ---------------------------------------------------------
751  func start_brood(as_gyne: bool = false) -> void
764  func develop_time() -> float
772  func feed_brood(seconds: float, on_honey: bool) -> void
777  func needs_feeding() -> bool
781  func seconds_until_death() -> float
786  # --- clearing a dead larva ------------------------------------------
788  func needs_cleaning() -> bool
794  func add_clean_progress(delta: float) -> bool
800  func clean_fraction() -> float
803  func brood_ready() -> bool
806  func clear_cell() -> void
819  # --- display ------------------------------------------------------
821  func _refresh() -> void
945  func _designation_tag() -> String
967  func _priority_mark() -> String
980  func _apply_fill_shading() -> void
991  func development_percent() -> float
```

## hive.gd (1,009 lines)

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
862  # --- mining -------------------------------------------------------
871  func refresh_edge_flags() -> void
893  func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
921  func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
945  func _is_markable_block(node) -> bool
952  func mine_stand_hex(block: Node2D)
975  func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
997  func remove_block(block: Node2D, floor_maker: Callable) -> void
1008 func announce() -> void
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
