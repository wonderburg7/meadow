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

**How to keep it updated:** when you add, remove, rename or move a
function in one of these six files, update its entry here in the same
pass. Regenerate a file's section from scratch with:

```
grep -n "^# --- \|^func \|^static func " scripts/<file>.gd
```

An out-of-date map is worse than no map -- don't skip this because the
change felt small.

Last regenerated: 19 Aug 2026 (hud.gd, bee.gd, debug_panel.gd, hive.gd and
main.gd, after the tutorial build added Challenge 1's UI hooks, the
right-click exit/collect commands, the auto-recruitment entrance queue
and the navigation off-by-one fix -- see `TUTORIAL_PLAN.md` and
`NEXTSTEPS.md`).

---

## hud.gd (1,720 lines)

Corner readouts, panels, popups, warnings, the problem strip, the
Challenge goal readout.

```
111  static func hatch_options() -> Array
151  static func mode_command(role_id: int, mode_key: String) -> String
277  func _ready() -> void
320  func _make_label(pos: Vector2, font_size: int) -> Label
327  func _info(text: String) -> Button
330  func _with_info(control: Control, tip: String) -> HBoxContainer
343  func _build_top_right_bar() -> void
429  func set_settings_button_width(width: float) -> void
437  func set_challenge_goal(text: String) -> void
441  func set_speed_display(speed_scale: float) -> void
445  func _build_selection_panel() -> void
481  # --- cell popup ---------------------------------------------------
501  func _build_cell_popup() -> void
617  func _cell_section(column: VBoxContainer, title: String, open_by_default: bool) -> VBoxContainer
652  func _build_zone_controls(column: VBoxContainer) -> void
703  func _build_closing_controls(column: VBoxContainer) -> void
740  func _build_empty_controls(column: VBoxContainer) -> void
780  func _make_hatch_menu(entry: Dictionary) -> Control
796  func _build_flower_popup() -> void
815  func _build_warning_banner() -> void
841  func show_warning(text: String) -> void
848  func set_warnings_muted(value: bool) -> void
853  func _build_obstacle_popup() -> void
863  func show_obstacle_popup(obstacle: Node2D, screen_position: Vector2) -> void
868  func show_flower_popup(flower: Node2D, screen_position: Vector2) -> void
874  func _refresh_flower_popup() -> void
901  func _build_soil_popup() -> void
927  func show_soil_popup(count: int, reachable: int, screen_position: Vector2) -> void
935  func show_cell_popup(cell: Node2D, screen_position: Vector2, count: int = 1) -> void
942  func _refresh_cell_popup() -> void
1029 func _light_current_options() -> void
1047 func _set_lit(key: String, lit: bool) -> void
1058 func _process(_delta: float) -> void
1072 func _request_designation(type: String) -> void
1077 func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void
1082 func _request_empty(method: String) -> void
1087 func _request_zone(in_zone: bool) -> void
1092 func _request_priority(tier: int) -> void
1097 func _request_close(closed: bool) -> void
1102 func _request_fill_close() -> void
1107 # --- discard warning ----------------------------------------------
1113 func _build_discard_dialog() -> void
1126 func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void
1135 func _on_discard_confirmed() -> void
1138 func _on_discard_custom_action(action: StringName) -> void
1144 func _apply_discard() -> void
1152 # --- readouts -----------------------------------------------------
1157 func update_day(day: int, note: String = "") -> void
1167 func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void
1176 func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void
1182 func update_comb(text: String) -> void
1186 func update_energy(mean_fraction: float) -> void
1193 func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void
1205 func update_fps(average: int, frame_ms: float, worst_ms: float) -> void
1210 func update_signals(lines: Array) -> void
1218 func _refresh_corner() -> void
1289 func pinned_stats_changed() -> void
1296 func refresh_corner() -> void
1299 func update_selection(bees: Array) -> void
1322 func _rebuild_role_controls(bees: Array) -> void
1349 func _build_queen_build_row() -> void
1361 func _build_favourite_row(bee) -> void
1371 func _build_job_row(common_role: int, any_queen: bool) -> void
1399 func _build_doing_row(common_role: int, first) -> void
1424 func _mode_is_active(role_id: int, bee, mode_key: String) -> bool
1439 func _build_orders_row(common_role: int, first) -> void
1487 func _build_restock_row(first) -> void
1518 func _build_fallback_row(common_role: int, first) -> void
1548 func _secondary_items() -> Array
1559 func _labelled_row(title: String) -> HBoxContainer
1576 func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control
1586 func _action_button(label: String, action: Callable, tip: String) -> Control
1593 func _current_role_marker(label: String) -> Control
1602 func _common_role(bees: Array) -> int
1615 func _make_role_menu(label: String, tip: String, items: Array) -> Control
1626 func _refresh_selection_text() -> void
1676 func set_winter_button_visible(value: bool) -> void
1680 func set_view_label(in_hive: bool) -> void
1683 func set_colony_button_visible(value: bool) -> void
1689 func set_nursery_button_visible(value: bool) -> void
1695 func set_view_button_visible(value: bool) -> void
1704 func set_allowed_role_keys(keys: Array) -> void
1709 func set_allowed_mode_keys(keys: Array) -> void
1717 func set_queen_build_button_visible(value: bool) -> void
```

## bee.gd (1,685 lines)

A bee's dispatch loop, player commands, display text, vars.

```
293  func _ready() -> void
379  func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void
416  func _roll_fact() -> void
430  func _default_state_for_role() -> int
452  func _base_colour() -> Color
463  func _tinted(c: Color) -> Color
478  func _apply_stats() -> void
504  func trait_text() -> String
513  func _update_role_marker() -> void
532  # --- how often a bee thinks ---------------------------------------
556  func _process(delta: float) -> void
767  # --- life support -------------------------------------------------
769  # --- eating -------------------------------------------------------
771  # --- stall watchdog -----------------------------------------------
777  func _reset_stall_watch() -> void
780  # --- foraging -----------------------------------------------------
782  # --- entering and leaving the hive --------------------------------
784  # --- nursery work -------------------------------------------------
786  # --- royal jelly ---------------------------------------------------
788  # --- idle work dispatch --------------------------------------------
802  func _apply_pending_role() -> bool
814  func _is_busy() -> bool
820  func _idle_dispatch() -> void
841  func _try_role_work(r: int) -> bool
1006 # --- building -----------------------------------------------------
1008 # --- keeping cells topped up ---------------------------------------
1037 func set_restock_targets(cells: Array, resource: String) -> void
1040 func set_restock_sources(cells: Array, allowed: bool) -> void
1043 func clear_restock() -> void
1046 func has_restock_orders() -> bool
1048 # --- mining -------------------------------------------------------
1050 # --- honey making -------------------------------------------------
1052 # --- egg laying (queen only) --------------------------------------
1054 # --- player commands ----------------------------------------------
1064 func command_move_to(world_point: Vector2) -> void
1088 func command_exit_hive() -> void
1097 func set_forage_start_point(meadow_point: Vector2) -> void
1100 func has_forage_start_point() -> bool
1103 func set_preferred_species(species: String) -> void
1116 func set_manual_build_target(hex: Vector2i) -> void
1124 func queue_build_target(hex: Vector2i) -> void
1131 func clear_build_queue() -> void
1137 func _take_next_build_target() -> bool
1150 func set_mine_target(block: Node2D) -> void
1155 func queue_mine_target(block: Node2D) -> void
1161 func clear_mine_queue() -> void
1166 func _next_queued_block() -> Node2D
1174 func set_home_hex(hex: Vector2i) -> void
1183 func set_mine_home_hex(hex: Vector2i) -> void
1189 func _mine_reference_point() -> Vector2
1202 func command_collect_from(flower: Node2D) -> void
1214 func set_focus(type: String) -> void
1241 func set_secondary_role(new_role: int) -> void
1244 func can_take_role(new_role: int) -> bool
1254 func set_role(new_role: int) -> void
1271 func _apply_role(new_role: int) -> void
1296 func _release_everything() -> void
1313 func release_flower_reference(flower: Node2D) -> void
1319 func set_selected(value: bool) -> void
1323 # --- display ------------------------------------------------------
1325 func role_letter() -> String
1343 func idle_reason() -> String
1394 func task_description() -> String
1533 func _idle_backup_note() -> String
1538 func role_name_text() -> String
1562 func nurse_mode_name() -> String
1571 func architect_mode_name() -> String
1577 func carrying_text() -> String
1598 func age_days() -> float
1606 func leave_to_found_colony() -> void
1619 func days_remaining() -> float
1631 func _update_label() -> void
1652 func _terrain_speed_factor() -> float
1661 func _is_inside_hive() -> bool
1664 # --- getting round things in the meadow ---------------------------
1684 func clear_navigation_state() -> void
```

## debug_panel.gd (1,187 lines)

The settings window (the cog icon): tuner rows, save/load buttons, restart.

```
771  static func setting_get(key: String)
774  static func setting_set(key: String, value) -> void
790  func _ready() -> void
856  func _report_settings_button_width() -> void
861  func _rows_in(category: String) -> Array
883  func _make_section(category: String, entries: Array, start_open: bool) -> Control
920  func _make_controls_help() -> Control
953  func _build_actions(column: VBoxContainer) -> void
993  func _on_winter_pressed() -> void
999  func _on_save_pressed() -> void
1010 func _on_load_pressed() -> void
1022 func _toggle_panel() -> void
1028 func _make_row(entry: Dictionary) -> Control
1057 func _make_toggle_row(entry: Dictionary) -> Control
1098 func _cascade_prerequisites_on(key: String) -> void
1111 func _cascade_dependents_off(key: String) -> void
1123 func _make_star_row(entry: Dictionary) -> Control
1157 func _adjust(entry: Dictionary, delta: float) -> void
1163 func _format_value(v) -> String
1170 func _on_restart_pressed() -> void
1175 func _on_main_menu_pressed() -> void
1183 func _restart() -> void
```

## hive_cell.gd (845 lines)

One cell: contents, brood, honey ripening, how it draws.

```
166  func _ready() -> void
245  func set_overlay(mode: String) -> void
251  func _overlay_colour() -> Array
289  func set_selected(value: bool) -> void
297  func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE) -> void
305  func _set_outline_points(line: Line2D, size: float) -> void
329  func _process(delta: float) -> void
357  func _develop_brood(delta: float) -> void
381  func _health_factor() -> float
387  func _larva_dies() -> void
396  # --- working positions --------------------------------------------
401  func claim_slot(bee: Node2D) -> int
412  func release_slot(bee: Node2D) -> void
420  func slot_position(index: int) -> Vector2
427  # --- building -----------------------------------------------------
429  func start_as_site() -> void
433  func claim_builder(bee: Node2D) -> void
437  func release_builder(bee: Node2D) -> void
442  func add_build_progress(delta: float) -> void
451  func build_fraction() -> float
454  # --- contents -----------------------------------------------------
456  func is_empty() -> bool
461  func capacity_for(resource_type: String) -> float
470  func accepts(resource_type: String) -> bool
489  func is_nursery_cell() -> bool
492  func space_for(resource_type: String) -> float
508  func needs_eviction() -> bool
526  func add_resource(resource_type: String, requested: float) -> float
550  func take_resource(resource_type: String, requested: float) -> float
572  func can_withdraw() -> bool
577  func set_closed(value: bool) -> void
582  func set_fill_then_close(value: bool) -> void
589  func fill_fraction() -> float
596  func set_designation(resource_type: String) -> void
602  # --- honey ---------------------------------------------------------
604  func is_ripe_honey() -> bool
608  func needs_fanning() -> bool
611  func ripen_fraction() -> float
614  # --- brood ---------------------------------------------------------
616  func start_brood(as_gyne: bool = false) -> void
628  func develop_time() -> float
636  func feed_brood(seconds: float, on_honey: bool) -> void
641  func needs_feeding() -> bool
645  func seconds_until_death() -> float
650  # --- clearing a dead larva ------------------------------------------
652  func needs_cleaning() -> bool
658  func add_clean_progress(delta: float) -> bool
664  func clean_fraction() -> float
667  func brood_ready() -> bool
670  func clear_cell() -> void
682  # --- display ------------------------------------------------------
684  func _refresh() -> void
796  func _designation_tag() -> String
818  func _priority_mark() -> String
831  func _apply_fill_shading() -> void
842  func development_percent() -> float
```

## hive.gd (873 lines)

The comb as a whole: cells, navigation, finding a cell.

```
43   func add_entrance_mentor(bee: Node2D) -> void
47   func remove_entrance_mentor(bee: Node2D) -> void
50   func record_collection(resource_type: String, amount: float) -> void
56   func record_birth() -> void
59   # --- cell index ---------------------------------------------------
69   func _content_index() -> Dictionary
93   func invalidate_index() -> void
96   func cells_holding(content: String) -> Array
103  func register_tile(hex: Vector2i, node: Node2D) -> void
106  func tile_is_free(hex: Vector2i) -> bool
111  func tile_is_interior(hex: Vector2i) -> bool
116  func cell_at_tile(hex: Vector2i) -> Node2D
122  func _ready() -> void
132  func deposit(resource_type: String, amount: float) -> float
151  func take(resource_type: String, amount: float) -> float
166  func take_energy(energy_wanted: float) -> float
179  func total(resource_type: String) -> float
189  func total_sealed() -> float
197  func total_honey() -> float
204  # --- finding cells ------------------------------------------------
217  func find_cell_for(resource_type: String, except: Node2D = null) -> Node2D
255  func find_empty_cell() -> Node2D
301  func _lay_by_priority(pool: Array) -> Node2D
332  func _tier_weights() -> Array
347  func record_lay(cell: Node2D) -> void
361  func zone_summary() -> Dictionary
388  func find_food_cell(except: Node2D = null) -> Node2D
401  func has_room_for_egg() -> bool
404  func find_cell_with(resource_type: String) -> Node2D
417  func find_brood_cell() -> Node2D
432  func find_cell_needing_fanning() -> Node2D
440  func find_honey_target() -> Node2D
443  func find_unfinished_cell() -> Node2D
452  func find_cell_needing_cleaning() -> Node2D
456  func find_cell_needing_eviction() -> Node2D
464  func has_gyne_brood() -> bool
472  func has_room_elsewhere(resource_type: String, except: Node2D) -> bool
475  # --- growing the comb ---------------------------------------------
509  func create_next_cell_site(around: Vector2i = Vector2i.ZERO) -> Node2D
543  func set_keep_clear(hex: Vector2i, value: bool) -> void
549  func is_keep_clear(hex: Vector2i) -> bool
556  func can_build_on(hex: Vector2i) -> bool
559  func _can_build_on(hex: Vector2i) -> bool
562  func _start_site_at(hex: Vector2i) -> Node2D
577  func create_cell_site_at(hex: Vector2i) -> Node2D
582  # --- navigation ---------------------------------------------------
593  func build_navigation() -> void
634  func _is_solid(hex: Vector2i) -> bool
640  func _tile_cost(hex: Vector2i) -> float
643  func tile_is_walkable(hex: Vector2i) -> bool
652  func nearest_walkable_point(point: Vector2) -> Vector2
679  func path_between(from_point: Vector2, to_point: Vector2) -> PackedVector2Array
713  func _smooth_path(from_point: Vector2, raw: PackedVector2Array) -> PackedVector2Array
737  func _line_is_clear(from_point: Vector2, to_point: Vector2) -> bool
747  # --- mining -------------------------------------------------------
756  func refresh_edge_flags() -> void
773  func find_marked_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
795  func find_nearest_edge_block(from_point: Vector2 = Vector2(INF, INF)) -> Node2D
814  func _is_markable_block(node) -> bool
821  func mine_stand_hex(block: Node2D)
844  func mine_stand_point(block: Node2D, from_point: Vector2) -> Vector2
862  func remove_block(block: Node2D, floor_maker: Callable) -> void
872  func announce() -> void
```

## main.gd (762 lines)

Per-frame entry point, everything not yet split out of main.

```
263  func _ready() -> void
455  # --- public surface other scripts call directly -------------------
462  func is_on_screen(node: Node2D) -> bool
465  func hive_entrance_inside() -> Vector2
468  func entrance_wait_point(side: int) -> Vector2
471  func move_bee_into_hive(bee: Node2D) -> void
474  func move_bee_out_of_hive(bee: Node2D) -> void
477  func mark_death(bee: Node2D) -> void
480  func finish_mining(block: Node2D) -> void
483  func save_run() -> void
486  func begin_winter_countdown() -> void
489  # --- per-frame ----------------------------------------------------
491  func _process(delta: float) -> void
518  # --- the frame rate readout ----------------------------------------
537  func _sample_fps() -> void
560  func _reseed_meadow(delta: float) -> void
575  func _hatch_ready_brood() -> void
605  func _advance_weather(delta: float) -> void
632  func _apply_rain_overlay() -> void
647  func _check_for_loss() -> void
665  func _check_colony_energy(delta: float) -> void
694  func _role_counts() -> Dictionary
705  func _update_population_readout() -> void
725  func _record_emergence(role: int, focus: String, as_gyne: bool) -> void
731  func _prune_selection() -> void
744  func _on_restart_after_loss() -> void
750  func _on_level_chosen(level: int) -> void
```
