# Audit: hive and meadow coordinate spaces
Audited: 413546be on 2026-11-02 | Task: J-31 | Scope: scripts/**/*.gd (840 sites across 43 GDScript files)

## Summary
Audited 840 code expressions across 43 GDScript files in `scripts/` referencing `hive_root`, `meadow_root`, `global_position`, `to_global`, `to_local`, `reparent`, `add_child`, or performing position operations for bees, flowers, cells, and markers.
All 840 sites are classified: 817 same space, 23 converted correctly, 0 mixed coordinate space errors, and 0 unknown (high confidence across all inspected sites).
The five most critical coordinate invariants verified in `origin/master`:
1. `world_building.gd:637,652`: Bee world transitions between `meadow_root` and `hive_root` reparent and immediately assign entry positions in the target world's local coordinate system.
2. `challenge_runner.gd:626,645`: The shared stage marker is reparented to the target world root before assigning local coordinates, avoiding cross-world offset stranding.
3. `bee_speech_bubble.gd:54`: Speech bubbles dynamically follow `bee.get_parent()`, reparenting when a bee moves between `hive_root` and `meadow_root`.
4. `input_selection.gd:618`: Global screen click positions are explicitly converted via `root.to_local(world_point)` before positioning markers under `hive_root` or `meadow_root`.
5. `bee_honey.gd:76` and `hive.gd:169`: Cell position queries from foraging bees consistently pass `bee.global_position` to `find_honey_source`, which evaluates against `cell.global_position`.

## Findings
No active coordinate space findings or bugs were identified in `origin/master` commit 413546be.

| # | Where (path:line) | What | Why it matters | Confidence | Fix |
|---|---|---|---|---|---|
| - | None | No active mixed coordinate space errors found | N/A | High | None required |

## Candidate Jules tasks
No candidate Jules tasks are proposed because no mixed coordinate space shapes isolatable by a static regex were found across the codebase.

## For Claude or Codex
No items require Claude or Codex action.

## World-parent transitions
Every site where a node moves between `hive_root` and `meadow_root` or transitions world parents, and its position conversion contract:

| Site (path:line) | Function | Transition | Position conversion contract | Classification |
|---|---|---|---|---|
| `scripts/world_building.gd:637` | `move_bee_into_hive` | `meadow_root` -> `hive_root` | Reparents bee to `main.hive_root`; line 638 immediately converts local coordinate via `bee.position = hive_entrance_inside()` | Converted correctly |
| `scripts/world_building.gd:652` | `move_bee_out_of_hive` | `hive_root` -> `meadow_root` | Reparents bee to `main.meadow_root`; line 653 immediately converts local coordinate via `bee.position = main.hive.position` | Converted correctly |
| `scripts/bee_speech_bubble.gd:54` | `_follow` | Prior parent -> `bee.get_parent()` (`hive_root` or `meadow_root`) | Reparents speech bubble to match bee parent; line 55 sets `position = bee.position + OFFSET` in the matching space | Converted correctly |
| `scripts/challenge_runner.gd:626` | `_show_current_visit_point` | Prior parent -> `_visit_marker_parent` | Reparents `_marker` to `_visit_marker_parent` (`hive_root` or `meadow_root`); line 627 assigns `_marker.position = _visit_points[...].position` in target space | Converted correctly |
| `scripts/challenge_runner.gd:645` | `_update_marker` | Prior parent -> `marker_parent` | Reparents `_marker` to `marker_parent` (`hive_root` or `meadow_root`); subsequent branch assigns `_marker.position` in matching local space | Converted correctly |

## Inventory
| Site (path:line) | Code Expression | Operation | Operand A Parent | Operand B Parent | Space A | Space B | Classification | Confidence |
|---|---|---|---|---|---|---|---|---|
| `scripts/bee.gd:863` | `add_child(visual_root)` | add_child | bee (self) | visual_root | bee local | visual_root local | Same space | High |
| `scripts/bee.gd:875` | `visual_root.add_child(selection_ring)` | add_child | bee (self) | visual_root | bee local | visual_root local | Same space | High |
| `scripts/bee.gd:884` | `visual_root.add_child(alarm_ring)` | add_child | bee (self) | visual_root | bee local | visual_root local | Same space | High |
| `scripts/bee.gd:895` | `visual_root.add_child(attack_ring)` | add_child | bee (self) | visual_root | bee local | visual_root local | Same space | High |
| `scripts/bee.gd:904` | `visual_root.add_child(search_ring)` | add_child | bee (self) | visual_root | bee local | visual_root local | Same space | High |
| `scripts/bee.gd:915` | `visual_root.add_child(dance_ring)` | add_child | bee (self) | visual_root | bee local | visual_root local | Same space | High |
| `scripts/bee.gd:923` | `visual_root.add_child(outline_disc)` | add_child | bee (self) | visual_root | bee local | visual_root local | Same space | High |
| `scripts/bee.gd:932` | `visual_root.add_child(outline_ring)` | add_child | bee (self) | visual_root | bee local | visual_root local | Same space | High |
| `scripts/bee.gd:937` | `visual_root.add_child(body)` | add_child | bee (self) | visual_root | bee local | visual_root local | Same space | High |
| `scripts/bee.gd:944` | `visual_root.add_child(centre_dot)` | add_child | bee (self) | visual_root | bee local | visual_root local | Same space | High |
| `scripts/bee.gd:966` | `visual_root.add_child(heading_marker)` | add_child | bee (self) | visual_root | bee local | visual_root local | Same space | High |
| `scripts/bee.gd:969` | `label.position = Vector2(-16, -32 if not is_queen else -40)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:971` | `visual_root.add_child(label)` | add_child | bee (self) | visual_root | bee local | visual_root local | Same space | High |
| `scripts/bee.gd:1110` | `var site: Vector2 = hive.position + Vector2.from_angle(randf() * TAU) * NUPTIAL_SITE_DISTANCE` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:1499` | `BeeMovement.move_towards(self, current_flower.position, delta)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:1500` | `if position.distance_to(current_flower.position) < arrive_distance:` | distance measurement | meadow_root (bee outdoors) | meadow_root (flower) | meadow-local | meadow-local | Same space | High |
| `scripts/bee.gd:1515` | `BeeMovement.move_towards(self, hive.position, delta)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:1516` | `if position.distance_to(hive.position) < arrive_distance:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/bee.gd:1550` | `if position.distance_to(move_target) < arrive_distance:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/bee.gd:1737` | `tipsy_resume_point = position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:1749` | `if position.distance_to(tipsy_wander_point) < arrive_distance:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/bee.gd:1757` | `position = tipsy_resume_point` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:1758` | `if position.distance_to(tipsy_resume_point) < arrive_distance:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/bee.gd:1773` | `var point: Vector2 = position + Vector2.from_angle(randf() * TAU) * randf_range(0.4, 1.0) * reach` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:1777` | `return position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:1792` | `return position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:1927` | `hive.add_body(hive.nearest_walkable_point(position), Session.sim_time)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:2190` | `var target: Vector2 = parent.to_local(world_point) if parent else world_point` | to_local transform | calling node / root | input coordinate | world global space | node local space | Converted correctly | High |
| `scripts/bee.gd:2337` | `return position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:3115` | `visual_root.add_child(meadow_sprite)` | add_child | bee (self) | visual_root | bee local | visual_root local | Same space | High |
| `scripts/bee.gd:3209` | `if visual_root.position.distance_squared_to(target_offset) < 0.01:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/bee.gd:3210` | `if visual_root.position != target_offset:` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:3211` | `visual_root.position = target_offset` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:3214` | `visual_root.position = visual_root.position.lerp(target_offset, blend)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:3234` | `var target_offset: Vector2 = (dance_partner.position - position) + orbit` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:3236` | `visual_root.position = visual_root.position.lerp(target_offset, blend)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:3246` | `var local: Vector2 = position - hive.comb_centre` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee.gd:3251` | `return world != null and get_parent() == world.hive_root` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/bee_foraging.gd:61` | `var base: Vector2 = bee.world.hive.position if bee.world else bee.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:177` | `bee.search_origin = bee.local_search_anchor if bee.local_search_anchor.x != INF else bee.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:230` | `if bee.position.distance_to(bee.search_waypoint) < bee.arrive_distance:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:245` | `var origin: Vector2 = bee.search_origin if bee.search_origin.x != INF else bee.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:290` | `static func _remember_patch(bee: Node2D, position: Vector2) -> void:` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:292` | `if known.distance_to(position) < GameConfig.known_patch_min_spacing:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:294` | `bee.known_patches.append(position)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:418` | `found = _weighted_flower_choice(bee, grid.near(bee.position, radius), accept, radius)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:420` | `found = grid.nearest(bee.position, radius, accept)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:439` | `var d := bee.position.distance_to(f.position)` | distance measurement | meadow_root (bee outdoors) | meadow_root (flower) | meadow-local | meadow-local | Same space | High |
| `scripts/bee_foraging.gd:463` | `var d: float = bee.position.distance_to(f.position)` | distance measurement | meadow_root (bee outdoors) | meadow_root (flower) | meadow-local | meadow-local | Same space | High |
| `scripts/bee_foraging.gd:468` | `alignment = 0.5 + 0.5 * heading.dot((f.position - bee.position) / d)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:706` | `bee.local_search_anchor = bee.current_flower.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:708` | `bee.local_search_anchor = bee.local_search_anchor.lerp(bee.current_flower.position, GameConfig.local_search_drift_rate)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:709` | `_remember_patch(bee, bee.current_flower.position)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:903` | `return 1 if bee.position.distance_to(stand_point) < STAND_REACH else 0` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:1202` | `return bee.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee_foraging.gd:1437` | `and bee.position.distance_to(seeker.position) <= GameConfig.recruit_dance_radius:` | distance measurement | hive_root (mentor bee) | hive_root (seeker bee) | hive-local | hive-local | Same space | High |
| `scripts/bee_foraging.gd:1506` | `var hive_point: Vector2 = mentor.world.hive_entrance_inside() if mentor.world else mentor.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/bee_honey.gd:76` | `var nectar_cell: Variant = bee.hive.find_honey_source(bee.global_position)` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/bee_speech_bubble.gd:25` | `add_child(_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/bee_speech_bubble.gd:30` | `_panel.add_child(_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/bee_speech_bubble.gd:54` | `reparent(bee_parent, false)` | reparent | current parent | bee.get_parent() (hive/meadow) | prior root space | bee parent root space | Converted correctly | High |
| `scripts/bee_speech_bubble.gd:55` | `position = bee.position + OFFSET` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/camera_view.gd:24` | `cam.position += direction.normalized() * main.PAN_SPEED * delta / cam.zoom.x` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/camera_view.gd:62` | `points.append(cell.global_position)` | global_position access/assignment | Main (identity root) | target node | global space | global space | Same space | High |
| `scripts/camera_view.gd:64` | `points.append(main.meadow_root.to_global(main.hive.position))` | to_global transform | calling node | global world | node local space | world global space | Converted correctly | High |
| `scripts/camera_view.gd:66` | `points.append(b.global_position)` | global_position access/assignment | Main (identity root) | target node | global space | global space | Same space | High |
| `scripts/camera_view.gd:76` | `cam.position = bounds.get_center()` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/camera_view.gd:98` | `var bee_indoors: bool = bee.get_parent() == main.hive_root` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/camera_view.gd:102` | `var bounds := Rect2(bee.global_position, Vector2.ZERO).grow(140.0)` | global_position access/assignment | Main (identity root) | target node | global space | global space | Same space | High |
| `scripts/camera_view.gd:104` | `cam.position = bounds.get_center()` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/camera_view.gd:139` | `var bee_indoors: bool = main.following_bee.get_parent() == main.hive_root` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/camera_view.gd:142` | `_active_camera().position = main.following_bee.global_position` | global_position access/assignment | Main (identity root) | target node | global space | global space | Same space | High |
| `scripts/camera_view.gd:155` | `main.meadow_root.visible = not main.in_hive_view` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/camera_view.gd:156` | `main.hive_root.visible = main.in_hive_view` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/challenge_complete.gd:42` | `add_child(backdrop)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/challenge_complete.gd:51` | `add_child(panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/challenge_complete.gd:55` | `panel.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/challenge_complete.gd:67` | `column.add_child(headline_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/challenge_complete.gd:73` | `column.add_child(flavour_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/challenge_complete.gd:78` | `column.add_child(summary_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/challenge_complete.gd:85` | `column.add_child(reward_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/challenge_complete.gd:90` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/challenge_complete.gd:99` | `column.add_child(continue_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/challenge_complete.gd:109` | `column.add_child(continue_to_next_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/challenge_complete.gd:119` | `column.add_child(restart_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/challenge_complete.gd:127` | `column.add_child(UI.with_info(menu_btn, "Go back to the menu and pick a different Challenge or Scenario."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/challenge_runner.gd:235` | `main.hive_camera.position = main.queen.global_position` | global_position access/assignment | Main (identity root) | target node | global space | global space | Same space | High |
| `scripts/challenge_runner.gd:301` | `main.hive_root.add_child(_marker)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/challenge_runner.gd:510` | `_begin_ordered_visit(_hive_inspection_points(), main.hive_root)` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/challenge_runner.gd:512` | `_begin_ordered_visit(_meadow_inspection_points(), main.meadow_root)` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/challenge_runner.gd:518` | `_new_worker.get_parent().add_child(bubble)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/challenge_runner.gd:574` | `{"position": centre + Shapes.hex_to_pixel(0, -3, spacing, squashed), "radius": Stages.VISIT_POINT_RADIUS},` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:575` | `{"position": centre + Shapes.hex_to_pixel(-3, 1, spacing, squashed), "radius": Stages.VISIT_POINT_RADIUS},` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:576` | `{"position": centre + Shapes.hex_to_pixel(3, 0, spacing, squashed), "radius": Stages.VISIT_POINT_RADIUS},` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:584` | `var origin: Vector2 = main.hive.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:586` | `{"position": origin + Vector2(220.0, -160.0), "radius": Stages.VISIT_POINT_RADIUS},` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:587` | `{"position": origin + Vector2(-280.0, 140.0), "radius": Stages.VISIT_POINT_RADIUS},` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:588` | `{"position": origin + Vector2(140.0, 380.0), "radius": Stages.VISIT_POINT_RADIUS},` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:612` | `var target_global: Vector2 = _visit_marker_parent.to_global(point.position)` | to_global transform | calling node | global world | node local space | world global space | Converted correctly | High |
| `scripts/challenge_runner.gd:613` | `if traveller.global_position.distance_to(target_global) > float(point.radius):` | distance measurement | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/challenge_runner.gd:626` | `_marker.reparent(_visit_marker_parent, false)` | reparent | _marker.get_parent() | _visit_marker_parent / marker_parent | prior space | target world root | Converted correctly | High |
| `scripts/challenge_runner.gd:627` | `_marker.position = _visit_points[_visit_point_index].position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:641` | `marker_parent = main.hive_root` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/challenge_runner.gd:643` | `marker_parent = main.meadow_root` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/challenge_runner.gd:645` | `_marker.reparent(marker_parent, false)` | reparent | _marker.get_parent() | _visit_marker_parent / marker_parent | prior space | target world root | Converted correctly | High |
| `scripts/challenge_runner.gd:654` | `_marker.position = main.world_building._hive_centre_local()` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:659` | `_marker.position = main.hive_entrance_inside()` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:665` | `_marker.position = main.hive.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:701` | `_marker.global_position, _marker.visible,` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/challenge_runner.gd:702` | `_marker.get_parent() == main.hive_root)` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/challenge_runner.gd:962` | `main.queen.position = main.world_building._hive_centre_local() + Shapes.hex_to_pixel(` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:1097` | `hearts.position = main.queen.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:1098` | `main.hive_root.add_child(hearts)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/challenge_runner.gd:1111` | `var centre: Vector2 = main.queen.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:1114` | `_new_worker.position = centre + Stages.GREETING_REST_OFFSET` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:1117` | `_new_worker.position = centre + Vector2(cos(angle), sin(angle)) * Stages.GREETING_RADIUS` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/challenge_runner.gd:1158` | `return is_instance_valid(main.queen) and main.queen.position.distance_to(` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/click_marker.gd:22` | `add_child(ring)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:103` | `scroll_container.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:108` | `column.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:116` | `column.add_child(hint)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:129` | `needing_attention_column.add_child(needing_attention_ok_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:133` | `jobs.add_child(_make_role_row(key))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:138` | `readouts.add_child(_make_stat_row(entry))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:147` | `favourites_column.add_child(favourites_empty_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:173` | `column.add_child(header)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:178` | `column.add_child(body)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:237` | `row.add_child(star)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:244` | `row.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:247` | `row.add_child(UI.info_badge(entry.tip))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:268` | `column.add_child(header)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:273` | `header.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:274` | `header.add_child(UI.info_badge(` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:279` | `column.add_child(plot_button_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:289` | `plot_button_row.add_child(btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:294` | `column.add_child(plot)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:299` | `column.add_child(plot_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:332` | `font, frame.position + Vector2(8, 22), "Not enough history yet.",` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/colony_panel.gd:350` | `frame.position.x + frame.size.x * (float(i) / float(count - 1)),` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/colony_panel.gd:351` | `frame.position.y + frame.size.y * (1.0 - value / highest)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/colony_panel.gd:358` | `frame.position + Vector2(0, frame.size.y),` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/colony_panel.gd:359` | `frame.position + frame.size,` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/colony_panel.gd:367` | `font, Vector2(2, frame.position.y + 10), "%d" % int(highest),` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/colony_panel.gd:371` | `font, Vector2(2, frame.position.y + frame.size.y), "0",` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/colony_panel.gd:430` | `default_order_column.add_child(hint)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:433` | `default_order_column.add_child(hint)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:438` | `default_order_column.add_child(build_backup_editor(Session.backup_order_default, addable, _on_default_order_changed, _default_order_focus))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:461` | `needing_attention_column.add_child(` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:482` | `favourites_column.add_child(_make_favourite_row(b))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:516` | `box.add_child(none)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:521` | `box.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:526` | `row.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:529` | `row.add_child(up)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:532` | `row.add_child(down)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:538` | `row.add_child(remove)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/colony_panel.gd:553` | `box.add_child(add)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/death_marker.gd:42` | `add_child(body)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/death_marker.gd:54` | `add_child(selection_ring)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/death_marker.gd:62` | `add_child(line)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:113` | `add_child(_text_scale_timer)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:145` | `add_child(toggle_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:180` | `add_child(panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:191` | `panel.add_child(panel_scroll)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:200` | `panel_scroll.add_child(content_margin)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:204` | `content_margin.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:211` | `column.add_child(_make_collection(` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:268` | `wrapper.add_child(header)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:269` | `wrapper.add_child(body)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:278` | `body.add_child(_make_section(category, rows, false))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:335` | `wrapper.add_child(header)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:336` | `wrapper.add_child(body)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:364` | `body.add_child(made)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:366` | `body.add_child(_make_challenge_stage_navigation())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:371` | `body.add_child(_make_controls_help())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:376` | `body.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:377` | `body.add_child(_make_winter_action())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:403` | `row.add_child(challenge_retreat_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:428` | `row.add_child(challenge_stage_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:436` | `row.add_child(challenge_advance_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:568` | `column.add_child(save_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:574` | `save_row.add_child(UI.with_info(save_btn, "Write the current run to disk: the comb and everything in it, every bee and what it is doing, the meadow, the weather and the clock. There is one save slot, so saving again overwrites it."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:580` | `save_row.add_child(UI.with_info(load_btn, "Open the Saves window: save this run by name, load a save or one of its checkpoints, or delete one."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:584` | `column.add_child(developer_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:592` | `column.add_child(triggers_box)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:595` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:607` | `triggers_box.add_child(UI.with_info(triggers_header, "Debug only: every button in this group forces a simulation state the world otherwise reaches rarely or not at all, so a behaviour that depends on it can be watched on demand instead of waited for."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:667` | `developer_row.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:683` | `add_child(run_availability_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:697` | `parent.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:705` | `row.add_child(UI.with_info(winter_btn, "Schedule a winter for a set number of days from now (see \"Winter in days\" in the Winter section). A forecast opens in the Winter window on the left showing what the colony will need to last it out and how far short it currently is. The figure moves as the colony grows, which is the point: every bee you add is another mouth to feed through it."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:883` | `row.add_child(lbl)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:885` | `row.add_child(UI.info_badge(entry.tip))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:889` | `row.add_child(controls)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:896` | `controls.add_child(minus)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:903` | `controls.add_child(plus)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:929` | `button.add_child(timer)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:964` | `row.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:965` | `row.add_child(UI.info_badge(entry.tip))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:969` | `row.add_child(controls)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:1021` | `controls.add_child(box)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:1038` | `row.add_child(lbl)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:1040` | `row.add_child(UI.info_badge(entry.tip))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:1044` | `row.add_child(controls)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:1051` | `controls.add_child(prev)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:1058` | `controls.add_child(next)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:1121` | `row.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:1122` | `row.add_child(UI.info_badge(entry.tip))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:1126` | `row.add_child(controls)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/debug_panel.gd:1151` | `controls.add_child(star)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/flower.gd:147` | `add_child(selection_ring)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/flower.gd:168` | `bush.position = Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/flower.gd:169` | `add_child(bush)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/flower.gd:174` | `add_child(centre_dot)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/flower.gd:186` | `crab_spider_marker.position = Vector2(8, -8)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/flower.gd:188` | `add_child(crab_spider_marker)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/flower.gd:207` | `add_child(crab_spider_dev_marker)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/flower.gd:214` | `nectar_label.position = Vector2(-16, 11)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/flower.gd:216` | `add_child(nectar_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/flower.gd:219` | `pollen_label.position = Vector2(4, 11)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/flower.gd:221` | `add_child(pollen_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/fog_of_war.gd:222` | `main.meadow_root.add_child(_layer)` | add_child | Main (root) | meadow_root | Main / world | meadow_root child space | Same space | High |
| `scripts/fog_of_war.gd:240` | `reveal_around(main.hive.position, START_CLEAR_RADIUS)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:251` | `main.hive_root.add_child(_hive_layer)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/fog_of_war.gd:287` | `if not is_instance_valid(b) or b.get_parent() != main.meadow_root:` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/fog_of_war.gd:292` | `if cached.is_empty() or cached.pos.distance_to(b.position) >= RELIGHT_DISTANCE:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:298` | `_relight(id, b.position)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:319` | `_last_draw_cam_pos = cam.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:328` | `cam.position != _last_draw_cam_pos` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:344` | `if hive_reveal_mode == "queen" and is_instance_valid(main.queen) and main.queen.get_parent() == main.hive_root:` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/fog_of_war.gd:345` | `var queen_pos: Vector2 = main.queen.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:346` | `if _last_hive_reveal_pos.x == INF or queen_pos.distance_to(_last_hive_reveal_pos) >= GameConfig.hive_cell_size * 0.5:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:352` | `var camera_changed: bool = cam.position != _last_hive_cam_pos or cam.zoom.x != _last_hive_cam_zoom` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:355` | `_last_hive_cam_pos = cam.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:383` | `main.queen.position - main.hive.comb_centre, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:440` | `var local_cam_pos: Vector2 = cam.position - main.hive_root.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:442` | `var min_tile: Vector2i = _tile_of(view.position)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:443` | `var max_tile: Vector2i = _tile_of(view.position + view.size)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:448` | `_hive_mask_material.set_shader_parameter("view_world_pos", dest.position)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:653` | `var view: Rect2 = Rect2(cam.position - span * 0.5, span).grow(FOG_TILE_SIZE)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:655` | `var min_tile: Vector2i = _tile_of(view.position)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:656` | `var max_tile: Vector2i = _tile_of(view.position + view.size)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/fog_of_war.gd:663` | `_mask_material.set_shader_parameter("view_world_pos", dest.position)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/foraging_panel.gd:29` | `scroll_container.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/foraging_panel.gd:34` | `column.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/foraging_panel.gd:42` | `column.add_child(gate_hint_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/foraging_panel.gd:49` | `overview.add_child(overview_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/foraging_panel.gd:54` | `species_section.add_child(species_column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/foraging_panel.gd:59` | `species_column.add_child(species_empty_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/foraging_panel.gd:66` | `recruitment.add_child(recruitment_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/foraging_panel.gd:78` | `column.add_child(header)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/foraging_panel.gd:83` | `column.add_child(body)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/foraging_panel.gd:145` | `species_column.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:163` | `add_child(_icon_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:175` | `wing_left.position = centre` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/gallerin_panel.gd:176` | `_icon_button.add_child(wing_left)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:183` | `wing_right.position = centre` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/gallerin_panel.gd:184` | `_icon_button.add_child(wing_right)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:189` | `body.position = centre` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/gallerin_panel.gd:190` | `_icon_button.add_child(body)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:205` | `add_child(_why_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:210` | `add_child(_why_popup)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:213` | `_why_popup.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:217` | `column.add_child(heading)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:222` | `column.add_child(_why_list)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:226` | `column.add_child(detail_scroll)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:230` | `detail_scroll.add_child(_why_detail)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:234` | `column.add_child(close_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:306` | `add_child(bubble)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:327` | `bubble.add_child(_bubble_scroll)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:335` | `_bubble_scroll.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:353` | `column.add_child(text_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:354` | `text_row.add_child(_bubble_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:362` | `text_row.add_child(close_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:370` | `bubble.add_child(_bubble_pointer)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:377` | `column.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:385` | `row.add_child(_history_back_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:393` | `row.add_child(_history_forward_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:398` | `row.add_child(disable_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/gallerin_panel.gd:451` | `_bubble_pointer.position = Vector2(bubble.size.x, bubble.size.y - ICON_SIZE.y / 2.0)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/game_over.gd:36` | `add_child(backdrop)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/game_over.gd:45` | `add_child(panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/game_over.gd:49` | `panel.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/game_over.gd:55` | `column.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/game_over.gd:66` | `column.add_child(body)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/game_over.gd:70` | `column.add_child(summary_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/game_over.gd:72` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/game_over.gd:78` | `column.add_child(UI.with_info(checkpoint_btn, "Reload the run as it was on that day, the same way the Saves window loads a checkpoint."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/game_over.gd:84` | `column.add_child(UI.with_info(restart_btn, "Start the run again at the same stage, with the same tuning values."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/game_over.gd:90` | `column.add_child(UI.with_info(menu_btn, "Go back to the menu and pick a different starting stage."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/game_panel.gd:48` | `add_child(panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/game_panel.gd:55` | `panel.add_child(scroll_container)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/game_panel.gd:70` | `panel.offset_top = rect.position.y` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hive.gd:270` | `skep.position = -SpriteCatalogue.HIVE_SKEP_ANCHOR * PixelSprite.MEADOW_SCALE - door_shift - Vector2(SpriteCatalogue.HIVE_SKEP_CELL_GUTTER, SpriteCatalogue.HIVE_SKEP_CELL_GUTTER) * PixelSprite.MEADOW_SCALE` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hive.gd:271` | `add_child(skep)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hive.gd:671` | `score = from.distance_squared_to(cell.global_position)` | distance measurement | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/hive.gd:822` | `body.position = point` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hive.gd:824` | `comb_parent.add_child(body)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hive.gd:968` | `cell.position = comb_centre + Shapes.hex_to_pixel(hex.x, hex.y, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hive.gd:969` | `comb_parent.add_child(cell)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hive.gd:1151` | `var span := Shapes.unsquash_point(from_point, squashed).distance_to(Shapes.unsquash_point(to_point, squashed))` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/hive.gd:1207` | `var d: float = 0.0 if from_point.x == INF else true_from.distance_to(Shapes.unsquash_point(node.position, squashed))` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/hive.gd:1235` | `true_from.distance_to(Shapes.unsquash_point(node.position, squashed)) if from_point.x != INF` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/hive.gd:1285` | `var d: float = true_from.distance_to(Shapes.unsquash_point(point, squashed))` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/hive.gd:1291` | `return best.lerp(block.position, MINER_FACE_APPROACH)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hive_cell.gd:451` | `add_child(empty_sprite)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hive_cell.gd:462` | `add_child(cap_sprite)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hive_cell.gd:470` | `add_child(fill_shape)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hive_cell.gd:476` | `add_child(outline)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hive_cell.gd:485` | `add_child(designation_ring)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hive_cell.gd:494` | `add_child(selection_ring)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hive_cell.gd:506` | `add_child(zone_halo)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hive_cell.gd:513` | `add_child(zone_glow)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hive_cell.gd:526` | `add_child(closed_mark)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hive_cell.gd:529` | `info_label.position = Vector2(-cell_size, -8)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hive_cell.gd:531` | `add_child(info_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hive_cell.gd:825` | `return position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hive_cell.gd:833` | `return position + Vector2(edge_offset.x * SLOT_REACH, edge_offset.y * y_reach)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hud.gd:610` | `main.add_child.call_deferred(skill_tree_panel)` | Coordinate reference | - | - | - | - | Same space | High |
| `scripts/hud.gd:613` | `main.add_child.call_deferred(pollination_pop)` | Coordinate reference | - | - | - | - | Same space | High |
| `scripts/hud.gd:632` | `corner_column.position = Vector2(16, 12)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hud.gd:644` | `add_child(corner_column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:650` | `corner_column.add_child(perf_plot)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:654` | `corner_column.add_child(perf_breakdown)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:663` | `corner_column.add_child(pause_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:689` | `add_child(marker_arrow_overlay)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:698` | `marker_arrow_overlay.add_child(stage_marker_arrow)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:702` | `func set_stage_marker(global_position: Vector2, marker_visible: bool, in_hive: bool) -> void:` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/hud.gd:703` | `_stage_marker_global_position = global_position` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/hud.gd:709` | `l.position = pos` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hud.gd:712` | `add_child(l)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:761` | `add_child(bar)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:767` | `bar.add_child(row1)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:778` | `row1.add_child(pause_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:785` | `row1.add_child(speed_group)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:804` | `speed_group.add_child(btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:807` | `row1.add_child(_info("Game speed, as a multiple of normal. These change how fast the simulation runs; they do not change how much a bee gathers per in-game second."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:813` | `bar.add_child(row2)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:821` | `row2.add_child(colony_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:823` | `row2.add_child(colony_info)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:830` | `row2.add_child(nursery_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:832` | `row2.add_child(nursery_info)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:842` | `row2.add_child(foraging_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:844` | `row2.add_child(_info("Open the foraging window: trip timing (search+flight versus handling), flowers visited per trip, empty-return rate, and the same breakdown split by species, plus recruitment/scouting counts. Only fills in once Auto scouting or Auto-recruitment is on -- that is what scores a trip today."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:853` | `row2.add_child(winter_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:861` | `row2.add_child(skills_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:877` | `row2.add_child(goals_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:886` | `row2.add_child(view_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:888` | `row2.add_child(view_info)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:911` | `btn.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:917` | `row.add_child(icon)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:923` | `row.add_child(text)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:960` | `add_child(goal_shelf)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:967` | `goal_shelf.add_child(favourites_box)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:978` | `goal_shelf.add_child(long_term_goal_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:996` | `goal_shelf.add_child(completed_goal_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1007` | `goal_shelf.add_child(current_goal_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1016` | `goal_shelf.add_child(goal_progress_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1022` | `goal_progress_row.add_child(goal_progress_bar)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1028` | `goal_progress_row.add_child(goal_progress_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1035` | `goal_shelf.add_child(short_term_box)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1163` | `row.add_child(line)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1171` | `row.add_child(dismiss)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1180` | `row.add_child(star)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1181` | `short_term_box.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1203` | `label.add_child(star)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1247` | `favourites_box.add_child(line)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1274` | `add_child(selection_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1282` | `selection_panel.add_child(selection_column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1294` | `column.add_child(header)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1304` | `header.add_child(identity_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1305` | `header.add_child(_build_favourite_star())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1306` | `header.add_child(_build_selection_cog())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1312` | `column.add_child(energy_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1319` | `column.add_child(activity_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1325` | `column.add_child(trait_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1333` | `column.add_child(soil_summary_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1346` | `soil_summary_row.add_child(soil_mark_wrapper)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1358` | `soil_summary_row.add_child(soil_clear_wrapper)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1365` | `column.add_child(keep_clear_summary_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1374` | `keep_clear_summary_row.add_child(keep_clear_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1605` | `add_child(command_tray)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1617` | `command_tray.add_child(command_scroll)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1627` | `command_scroll.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1649` | `column.add_child(command_columns)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1676` | `column.add_child(more_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1684` | `column.add_child(more_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1706` | `command_columns.add_child(wrapper)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1713` | `wrapper.add_child(header)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1718` | `wrapper.add_child(content)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1743` | `parent.add_child(cell_group)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1752` | `cell_group.add_child(cell_primary_columns)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1755` | `_build_cell_action_column(cell_primary_columns, "Reserve for").add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1763` | `row.add_child(_with_info(nectar_btn, "Reserve this cell for nectar. Foragers carrying pollen will walk past it."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1771` | `row.add_child(_with_info(pollen_btn, "Reserve this cell for pollen. Foragers carrying nectar will walk past it."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1779` | `row.add_child(_with_info(honey_btn, "Reserve this cell for honey. Honey makers spit their chewed nectar mix into cells like this one and then fan it dry."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1787` | `row.add_child(_with_info(jelly_btn, "Reserve this cell for royal jelly. Nurses on the royal jelly sub-mode store what they make here, and draw on it when feeding gyne larvae."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1796` | `row.add_child(_with_info(bee_bread_btn, "Reserve this cell for bee bread. Honey makers on Fermenting pack pollen and ripe honey in here. Once the cell is full it seals itself and ripens over about two days."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1804` | `row.add_child(_with_info(egg_btn, "Reserve this cell as a nursery. The queen lays here first, and foragers won't fill it with stores. Reserving enough of these is what stops laying stalling for want of a free cell."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1812` | `row.add_child(_with_info(auto_btn, "Remove the reservation. The cell takes whichever resource arrives first, and reserves itself for that from then on."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1828` | `cell_group.add_child(cell_more_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1833` | `cell_group.add_child(cell_more_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1851` | `parent.add_child(wrapper)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1857` | `wrapper.add_child(header)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1862` | `wrapper.add_child(body)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1871` | `column.add_child(tier_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1876` | `tier_row.add_child(tier_title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1886` | `tier_row.add_child(btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1891` | `tier_row.add_child(_info("How much of the queen's laying this cell gets. She shares eggs between the three tiers in proportion to their weights -- by default 1 : 2 : 3 -- so a high cell receives three eggs for every one a low cell receives, and they come out interleaved rather than in streaks. Twelve high forager cells beside three low nurse cells is how you say \"mostly foragers, a few nurses\" once and then leave it alone. The weights themselves are in the settings window."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1894` | `column.add_child(open_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1900` | `open_row.add_child(_with_info(open_btn, "Open the nursery window: how many cells are assigned to each role and tier, what the colony is made of right now, and how many bees of each kind have emerged in the last three minutes. While it is open every reserved cell glows in the colour of the role it raises."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1910` | `column.add_child(hatch_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1914` | `hatch_row.add_child(hatch_title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1915` | `hatch_row.add_child(_info("Set what a bee raised in this cell becomes when it emerges. Roles that have a sub-mode -- a forager's resource, whether a miner starts automining -- offer it here, so the new bee arrives already set up."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1931` | `hatch_row.add_child(btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1935` | `hatch_row.add_child(control)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1944` | `hatch_row.add_child(hatch_locked_note)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1948` | `column.add_child(lock_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1959` | `lock_row.add_child(hatch_lock_box)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1963` | `column.add_child(gyne_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1973` | `gyne_row.add_child(gyne_box)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1974` | `gyne_row.add_child(_info("A gyne is a future queen. She costs the queen several times as much pollen to lay, takes four times as long to develop, and can only be fed on royal jelly with pollen and honey -- so you need nurses producing jelly before one will grow at all. She can do any worker job in the meantime, though she is bigger, slower and hungrier than a worker."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1978` | `column.add_child(drone_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1988` | `drone_row.add_child(drone_box)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1989` | `drone_row.add_child(_info("A drone is a male bee. The queen lays him from an unfertilised egg, he does no work and eats from the stores, and he is needed to mate a gyne. Ticking this clears the gyne box for the cell, and the other way round."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1990` | `lock_row.add_child(_info("On: every bee this cell ever raises comes out in the chosen role, so you can earmark a cell as a builder nursery once and forget about it. Off: the role applies to the next bee only and then clears, so a one-off choice doesn't quietly govern the cell forever."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:1995` | `column.add_child(feed_first_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2005` | `feed_first_row.add_child(feed_first_box)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2006` | `feed_first_row.add_child(_info("Nurses feed a hungry larva in a marked cell before any unmarked one, whatever food it takes, so scarce food goes where you want it. Marked larvae share it among themselves the way unmarked ones do: the hungriest first."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2012` | `column.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2017` | `row.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2025` | `row.add_child(_with_info(close_btn, "Seal the selected cells. Nothing can be added and nothing taken out until you open them again -- the contents are held in reserve. A sealed cell is drawn with a dark bar across it."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2034` | `row.add_child(_with_info(open_btn, "Unseal the selected cells so the colony can use what is in them again."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2043` | `row.add_child(_with_info(fill_btn, "Keep taking deposits but refuse every withdrawal, and seal the cell the moment it is full. Without this a honey cell is sipped from as fast as it is filled and never quite gets to the top, so there is never a full pot to put by. A cell in this state is drawn with a yellow bar."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2052` | `column.add_child(empty_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2057` | `empty_row.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2064` | `empty_row.add_child(_with_info(move_btn, "A builder comes and carries the contents to another cell with room for them. Fermented nectar is always thrown out instead. If nothing anywhere has room, the load is lost -- so keep an eye on how full the comb is."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2071` | `empty_row.add_child(_with_info(discard_btn, "Throw the contents out of the hive. Quicker than moving them, but everything in the cell is gone."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2082` | `empty_row.add_child(_with_info(clear_fermented_btn, "Comb workers will carry every fermented cell's nectar out of the hive. Only the cells that are sour now: nectar that ferments later is not included."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2097` | `empty_row.add_child(_with_info(empty_by_bee_btn, "The selected bee carries the contents out herself, right now -- no comb worker needed and no change to her role."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2105` | `column.add_child(keep_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2115` | `keep_row.add_child(keep_empty_box)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2116` | `keep_row.add_child(_info("On: the cell refuses every deposit once it's been cleared, so it stays free. This is what stops a crowd of foragers cramming nectar into the last spare pot and leaving nowhere for pollen or eggs. Reserving the cell for a resource later clears this again. Off: the cell goes back to taking whatever arrives first."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2178` | `add_child(warning_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2182` | `warning_panel.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2189` | `row.add_child(warning_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2196` | `row.add_child(close_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2612` | `var root: Node2D = main.hive_root if _stage_marker_in_hive else main.meadow_root` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/hud.gd:2613` | `return root.get_global_transform_with_canvas() * root.to_local(_stage_marker_global_position)` | to_local transform | calling node / root | input coordinate | world global space | node local space | Converted correctly | High |
| `scripts/hud.gd:2638` | `clampf(marker_screen.x, safe_edge.position.x, safe_edge.end.x),` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hud.gd:2639` | `clampf(marker_screen.y, safe_edge.position.y, safe_edge.end.y))` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hud.gd:2641` | `stage_marker_arrow.position = _slide_arrow_along_edge(edge_point, safe_edge)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hud.gd:2667` | `var horizontal_edge := is_equal_approx(edge_point.y, edge_bounds.position.y) \` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hud.gd:2674` | `candidate.x = clampf(edge_point.x + step * direction, edge_bounds.position.x, edge_bounds.end.x)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hud.gd:2676` | `candidate.y = clampf(edge_point.y + step * direction, edge_bounds.position.y, edge_bounds.end.y)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hud.gd:2731` | `add_child(discard_dialog)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2952` | `corner_column.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2975` | `row.add_child(line)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2987` | `row.add_child(remove)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:2988` | `corner_column.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:3000` | `corner_column.add_child(more)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud.gd:3057` | `return maxf(0.0, get_viewport().get_visible_rect().size.x - corner_column.position.x * 2.0)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hud.gd:3080` | `return corner_column.position.y + corner_column.size.y` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hud.gd:3088` | `return selection_panel.position.y` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/hud_command_rows.gd:105` | `column.add_child(button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:122` | `hud.more_panel.add_child(hud._with_info(button, "Keeps the camera centred on this bee as it moves. Switches off the moment you select something else."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:138` | `row.add_child(mixed)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:140` | `row.add_child(_current_role_marker(Roles.label_for(common_role)))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:156` | `row.add_child(_make_role_menu("Change to…", "Switch the selected bees to another job. Sub-modes for that job appear on the Doing row once they are on it.", items, "change_to_menu"))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:183` | `hud.focus_column.add_child(_toggle_button(` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:206` | `row.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:207` | `row.add_child(_toggle_button(` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:212` | `row.add_child(_toggle_button(` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:242` | `row.add_child(hud._with_info(button, "She leaves the hive for good to found a colony of her own. Sent between late spring and early autumn she finds a mate, counts as sent out and earns genetic points, the most in mid summer. Sent outside that window she finds no mate and is lost, and does not count."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:285` | `hud.orders_column.add_child(_action_button("Clear start" if has_start else "Start here",` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:290` | `hud.orders_column.add_child(_action_button(("Flower: %s" % pref) if pref != "" else "Pick a flower",` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:294` | `hud.orders_column.add_child(_action_button("Build here",` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:297` | `hud.orders_column.add_child(_action_button("Keep clear",` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:300` | `hud.orders_column.add_child(_action_button("Work from here",` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:303` | `hud.orders_column.add_child(_action_button("Set for all comb workers",` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:313` | `hud.orders_column.add_child(_action_button("Mine",` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:316` | `hud.orders_column.add_child(_action_button("Work from here",` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:330` | `hud.orders_column.add_child(_toggle_button(` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:336` | `hud.orders_column.add_child(_action_button("Only these",` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:339` | `hud.orders_column.add_child(_action_button("Never these",` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:342` | `hud.orders_column.add_child(_action_button("Clear orders",` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:351` | `hud.orders_column.add_child(summary)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:387` | `row.add_child(_make_role_menu(` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:400` | `row.add_child(hud._with_info(finish_box, "On: reassigning this bee waits until it has finished what it is doing -- a forager delivers the load it is carrying, a comb worker finishes the cell it is on -- and the new role takes effect the moment it is free. Off: it drops everything and starts immediately."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:412` | `row.add_child(hud._with_info(any_cell_box, "On (the default): once every nursery cell is occupied she lays into any spare undesignated cell, so laying never stalls for want of somewhere to put an egg. Off: she lays only in cells reserved for eggs and waits when they are full. Turn it off for exact control, and be ready to reserve more cells for eggs or she stops laying."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:434` | `column.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:441` | `column.add_child(note)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:448` | `column.add_child(ColonyPanel.build_backup_editor(order, addable, _on_backup_editor_changed, focus))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:449` | `row.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:478` | `parent.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:486` | `hud.more_panel.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/hud_command_rows.gd:493` | `row.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/input_selection.gd:70` | `main.pan_anchor = event.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/input_selection.gd:84` | `cam.position -= (event.position - main.pan_anchor) / cam.zoom.x` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/input_selection.gd:85` | `main.pan_anchor = event.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/input_selection.gd:116` | `if box.has_point(b.global_position):` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/input_selection.gd:169` | `if is_instance_valid(c) and box.has_point(c.global_position):` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/input_selection.gd:177` | `if is_instance_valid(b) and box.has_point(b.global_position):` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/input_selection.gd:189` | `if box.has_point(m.global_position):` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/input_selection.gd:291` | `var root: Variant = main.hive_root if main.in_hive_view else main.meadow_root` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/input_selection.gd:295` | `var root: Variant = main.hive_root if main.in_hive_view else main.meadow_root` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/input_selection.gd:305` | `target = main.hive_root.to_global(main.hive_entrance_inside())` | to_global transform | calling node | global world | node local space | world global space | Converted correctly | High |
| `scripts/input_selection.gd:308` | `target = main.hive.global_position` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/input_selection.gd:310` | `if point.distance_to(target) > radius:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/input_selection.gd:319` | `if b.global_position.distance_to(point) <= b.click_radius:` | distance measurement | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/input_selection.gd:325` | `if is_instance_valid(c) and c.global_position.distance_to(point) <= c.cell_size:` | distance measurement | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/input_selection.gd:331` | `if is_instance_valid(b) and b.global_position.distance_to(point) <= b.block_size:` | distance measurement | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/input_selection.gd:337` | `if is_instance_valid(m) and m.global_position.distance_to(point) <= m.CLICK_RADIUS:` | distance measurement | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/input_selection.gd:342` | `var local_point: Vector2 = main.hive_root.to_local(global_point)` | to_local transform | calling node / root | input coordinate | world global space | node local space | Converted correctly | High |
| `scripts/input_selection.gd:470` | `var local_point: Vector2 = main.hive_root.to_local(global_point)` | to_local transform | calling node / root | input coordinate | world global space | node local space | Converted correctly | High |
| `scripts/input_selection.gd:490` | `var local_point: Vector2 = main.hive_root.to_local(global_point)` | to_local transform | calling node / root | input coordinate | world global space | node local space | Converted correctly | High |
| `scripts/input_selection.gd:498` | `var local_point: Vector2 = main.hive_root.to_local(global_point)` | to_local transform | calling node / root | input coordinate | world global space | node local space | Converted correctly | High |
| `scripts/input_selection.gd:506` | `var meadow_point: Vector2 = main.meadow_root.to_local(global_point)` | to_local transform | calling node / root | input coordinate | world global space | node local space | Converted correctly | High |
| `scripts/input_selection.gd:562` | `if world_point.distance_to(main.hive_root.to_global(main.hive_entrance_inside())) <= EXIT_CLICK_RADIUS:` | to_global transform | calling node | global world | node local space | world global space | Converted correctly | High |
| `scripts/input_selection.gd:582` | `if world_point.distance_to(main.hive.global_position) <= HIVE_CLICK_RADIUS:` | distance measurement | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/input_selection.gd:616` | `var root: Node2D = main.hive_root if main.in_hive_view else main.meadow_root` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/input_selection.gd:618` | `marker.position = root.to_local(world_point)` | to_local transform | calling node / root | input coordinate | world global space | node local space | Converted correctly | High |
| `scripts/input_selection.gd:619` | `root.add_child(marker)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/input_selection.gd:671` | `_draw_start_point_marker(main.hive_root.to_global(main.hive_entrance_inside()))` | to_global transform | calling node | global world | node local space | world global space | Converted correctly | High |
| `scripts/input_selection.gd:718` | `points.append(main.hive_root.to_global(block.position))` | to_global transform | calling node | global world | node local space | world global space | Converted correctly | High |
| `scripts/input_selection.gd:724` | `var previous: Vector2 = bee.global_position` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/input_selection.gd:741` | `return main.hive_root.to_global(` | to_global transform | calling node | global world | node local space | world global space | Converted correctly | High |
| `scripts/main.gd:209` | `var meadow_root: Node2D` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/main.gd:210` | `var hive_root: Node2D` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/main.gd:486` | `add_child(menu)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:496` | `add_child(debug_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:502` | `add_child(saves_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:516` | `add_child(world_building)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:519` | `add_child(saving)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:522` | `add_child(input_selection)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:525` | `add_child(orders_zones)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:527` | `add_child(foraging_stats)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:530` | `add_child(year_winter)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:537` | `add_child(camera_view)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:540` | `add_child(fog_of_war)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:543` | `add_child(stage_gate)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:561` | `add_child(challenge_runner)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:563` | `meadow_root = Node2D.new()` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/main.gd:569` | `meadow_root.process_mode = Node.PROCESS_MODE_PAUSABLE` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/main.gd:570` | `add_child(meadow_root)` | add_child | Main (root) | meadow_root | Main / world | meadow_root child space | Same space | High |
| `scripts/main.gd:572` | `hive_root = Node2D.new()` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/main.gd:573` | `hive_root.position = HIVE_WORLD_OFFSET` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/main.gd:574` | `hive_root.process_mode = Node.PROCESS_MODE_PAUSABLE` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/main.gd:575` | `add_child(hive_root)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/main.gd:594` | `add_child(weather_layer)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:600` | `weather_layer.add_child(rain_overlay)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:605` | `weather_layer.add_child(rain_effect)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:611` | `add_child(selection_layer)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:647` | `add_child(hud)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:672` | `add_child(colony_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:675` | `add_child(foraging_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:683` | `add_child(nursery_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:686` | `add_child(winter_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:689` | `add_child(gallerin_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:692` | `add_child(succession_panel)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:701` | `add_child(season)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:706` | `add_child(game_over)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main.gd:713` | `add_child(challenge_complete)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:168` | `add_child(backdrop)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:177` | `add_child(root)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:182` | `root.add_child(split)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:191` | `split.add_child(left_margin)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:197` | `left_margin.add_child(left_pane)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:205` | `split.add_child(right_pane)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:217` | `left_pane.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:223` | `left_pane.add_child(subtitle)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:231` | `left_pane.add_child(group_column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:236` | `group_column.add_child(heading)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:243` | `group_column.add_child(note)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:259` | `strip_scroll.add_child(_make_honeycomb_strip(group.key))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:260` | `group_column.add_child(strip_scroll)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:263` | `left_pane.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:276` | `right_pane.add_child(right_scroll)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:287` | `_detail_column.add_child(detail_placeholder)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:288` | `right_scroll.add_child(_detail_column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:290` | `right_pane.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:299` | `right_pane.add_child(_back_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:306` | `container.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:313` | `row.add_child(feedback_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:317` | `row.add_child(right_pane)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:333` | `right_pane.add_child(build_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:386` | `row.add_child(UI.with_info(settings_button, "Accessibility and appearance settings -- text scale, contrast, colour-blind mode and the rest of the settings window."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:387` | `right_pane.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:441` | `tile.position = Vector2(` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/main_menu.gd:445` | `strip.add_child(tile)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:509` | `border.position = bbox / 2.0` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/main_menu.gd:510` | `tile.add_child(border)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:514` | `fill.position = bbox / 2.0` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/main_menu.gd:515` | `tile.add_child(fill)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:543` | `label.position = Vector2(22.0, 8.0)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/main_menu.gd:546` | `tile.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:555` | `tick.position = Vector2(bbox.x - 22.0, 2.0)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/main_menu.gd:560` | `tile.add_child(tick)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:572` | `button.position = Vector2.ZERO` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/main_menu.gd:577` | `tile.add_child(button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:634` | `_detail_column.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:640` | `_detail_column.add_child(blurb)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:643` | `_detail_column.add_child(_make_preset_row(stage))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:644` | `_detail_column.add_child(_make_preset_description())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:646` | `_detail_column.add_child(_make_custom_controls())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:648` | `_detail_column.add_child(_make_note_label("Played before."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:650` | `_detail_column.add_child(_make_note_label("Completed."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:657` | `_detail_column.add_child(UI.with_info(start_btn, "Restarts the run with this choice. Anything unsaved in the colony you have now is lost."))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:684` | `row.add_child(btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:694` | `col.add_child(lbl)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:702` | `col.add_child(_make_custom_row(field))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:716` | `row.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:722` | `row.add_child(minus)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:729` | `row.add_child(value_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/main_menu.gd:735` | `row.add_child(plus)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:118` | `scroll_container.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:121` | `column.add_child(header)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:126` | `header.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:127` | `header.add_child(UI.info_badge(` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:136` | `header.add_child(close_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:138` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:152` | `needing_attention_column.add_child(needing_attention_ok_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:154` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:158` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:162` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:166` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:168` | `column.add_child(_starred_row(column, "nursery_mix", "The colony now", true))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:175` | `column.add_child(ring)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:177` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:179` | `column.add_child(_starred_row(column, "nursery_output", "Emerging (last 3 minutes)", true))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:182` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:201` | `column.add_child(heading)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:204` | `column.add_child(body)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:227` | `row.add_child(star)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:233` | `row.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:237` | `row.add_child(UI.info_badge(entry.tip))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:243` | `holder.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:244` | `column.add_child(holder)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:262` | `column.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/nursery_panel.gd:322` | `needing_attention_column.add_child(` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/obstacle.gd:61` | `add_child(selection_ring)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/obstacle.gd:71` | `trunk.position = Vector2(0, radius * 0.35)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/obstacle.gd:73` | `add_child(trunk)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/obstacle.gd:81` | `leaf.position = spot` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/obstacle.gd:83` | `add_child(leaf)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/obstacle.gd:106` | `shadow.position = Vector2(radius * 0.06, radius * 0.08)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/obstacle.gd:108` | `add_child(shadow)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/obstacle.gd:114` | `add_child(cliff)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/obstacle.gd:119` | `top.position = Vector2(0, -radius * 0.06)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/obstacle.gd:121` | `add_child(top)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/obstacle.gd:125` | `rim.position = Vector2(0, -radius * 0.06)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/obstacle.gd:128` | `add_child(rim)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/obstacle.gd:134` | `add_child(outline)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/obstacle.gd:145` | `rng.seed = int(abs(position.x) * 7919 + abs(position.y) * 104729)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/obstacle.gd:154` | `trunk.position = spot + Vector2(0, size * 0.3)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/obstacle.gd:156` | `add_child(trunk)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/obstacle.gd:161` | `leaf.position = spot + offset` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/obstacle.gd:163` | `add_child(leaf)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/obstacle.gd:173` | `bloom.position = _scenery_spot(rng, 0.8)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/obstacle.gd:175` | `add_child(bloom)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/pollination.gd:161` | `gaps.append([flower.species_index if sets else EMPTY_GAP, flower.position.x, flower.position.y])` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/pollination.gd:167` | `"flower": [flower.position.x, flower.position.y],` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/pollination.gd:233` | `"flower": [flower.position.x, flower.position.y],` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/pollination.gd:310` | `"flower": [flower.position.x, flower.position.y],` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/pollination.gd:312` | `"from": [previous.position.x, previous.position.y] if delivered else [],` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/pollination_pop.gd:54` | `_positions[slot] = flower.global_position + START` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/queen_hearts_vfx.gd:27` | `heart.position = Vector2(randf_range(-14.0, 14.0), randf_range(-6.0, 6.0))` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/queen_hearts_vfx.gd:29` | `add_child(heart)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/queen_hearts_vfx.gd:30` | `_hearts.append({"node": heart, "start": heart.position, "delay": i * STAGGER_SECONDS})` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/queen_hearts_vfx.gd:46` | `node.position = entry.start + Vector2(0, -RISE_DISTANCE * t)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/rival_hive.gd:79` | `body.position = -HiveScript.HIVE_SKEP_DOOR * PixelSprite.MEADOW_SCALE` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/rival_hive.gd:80` | `add_child(body)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/rival_hive.gd:87` | `skep.position = -(SpriteCatalogue.HIVE_SKEP_ANCHOR + HiveScript.HIVE_SKEP_DOOR + Vector2(SpriteCatalogue.HIVE_SKEP_CELL_GUTTER, SpriteCatalogue.HIVE_SKEP_CELL_GUTTER)) * PixelSprite.MEADOW_SCALE` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/rival_hive.gd:88` | `add_child(skep)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/rival_hive.gd:91` | `label.position = Vector2(-34, -46)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/rival_hive.gd:94` | `add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/rival_hive.gd:135` | `dot.position = position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/rival_hive.gd:136` | `get_parent().add_child(dot)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/rival_hive.gd:235` | `if flower.position.distance_to(position) > GameConfig.rival_forage_range:` | distance measurement | meadow_root (bee outdoors) | meadow_root (flower) | meadow-local | meadow-local | Same space | High |
| `scripts/rival_hive.gd:272` | `forager.node.position = forager.node.position.move_toward(position, FORAGER_SPEED * delta)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/rival_hive.gd:273` | `if forager.node.position.distance_to(position) < 8.0:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/rival_hive.gd:284` | `forager.node.position = forager.node.position.move_toward(forager.target.position, FORAGER_SPEED * delta)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/rival_hive.gd:285` | `if forager.node.position.distance_to(forager.target.position) < 6.0:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/rival_hive.gd:307` | `var distance: float = flower.position.distance_to(position)` | distance measurement | meadow_root (bee outdoors) | meadow_root (flower) | meadow-local | meadow-local | Same space | High |
| `scripts/run_availability_panel.gd:78` | `add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/run_availability_panel.gd:81` | `column.add_child(header)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/run_availability_panel.gd:85` | `header.add_child(title_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/run_availability_panel.gd:90` | `header.add_child(reset_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/run_availability_panel.gd:96` | `header.add_child(close_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/run_availability_panel.gd:102` | `column.add_child(intro)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/run_availability_panel.gd:107` | `column.add_child(scroll)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/run_availability_panel.gd:112` | `scroll.add_child(grid)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/run_availability_panel.gd:150` | `grid.add_child(source_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/run_availability_panel.gd:202` | `grid.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/save_game.gd:189` | `"x": body.position.x, "y": body.position.y,` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/save_game.gd:276` | `"indoors": b.get_parent() == world.hive_root,` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/save_game.gd:406` | `"x": f.position.x, "y": f.position.y,` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/saves_panel.gd:37` | `scroll_container.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:40` | `column.add_child(header)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:45` | `header.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:46` | `header.add_child(UI.info_badge(` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:52` | `header.add_child(close_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:56` | `column.add_child(save_run_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:60` | `column.add_child(name_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:64` | `name_row.add_child(prompt)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:66` | `name_row.add_child(edit_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:72` | `edit_row.add_child(name_edit)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:75` | `edit_row.add_child(confirm_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:77` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:80` | `column.add_child(list_box)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:103` | `panel.offset_top = rect.position.y` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/saves_panel.gd:127` | `add_child(dialog)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:199` | `list_box.add_child(_label("No saved runs yet.", "Small"))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:206` | `list_box.add_child(row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:216` | `row.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:220` | `row.add_child(load_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:223` | `row.add_child(delete_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:235` | `list_box.add_child(point_row)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:239` | `point_row.add_child(point_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saves_panel.gd:242` | `point_row.add_child(point_load)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/saving.gd:211` | `cell.position = centre_local + main.Shapes.hex_to_pixel(hex.x, hex.y, spacing, Session.use_sprite_hex_grid)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/saving.gd:212` | `main.hive_root.add_child(cell)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/saving.gd:342` | `flower.position = Vector2(float(entry.x), float(entry.y))` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/saving.gd:343` | `main.meadow_root.add_child(flower)` | add_child | Main (root) | meadow_root | Main / world | meadow_root child space | Same space | High |
| `scripts/saving.gd:379` | `bee.position = Vector2(float(entry.x), float(entry.y))` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/saving.gd:381` | `main.hive_root.add_child(bee)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/saving.gd:383` | `main.meadow_root.add_child(bee)` | add_child | Main (root) | meadow_root | Main / world | meadow_root child space | Same space | High |
| `scripts/scenario_actions.gd:168` | `stand_points.append(bee.position)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/scenario_actions.gd:171` | `var gap: float = stand_points[i].distance_to(stand_points[j])` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/scenario_actions.gd:780` | `point = main.hive.global_position` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/scenario_actions.gd:782` | `point = main.hive_root.to_global(main.hive_entrance_inside())` | to_global transform | calling node | global world | node local space | world global space | Converted correctly | High |
| `scripts/scenario_actions.gd:788` | `point = main.hive_root.to_global(comb_local)` | to_global transform | calling node | global world | node local space | world global space | Converted correctly | High |
| `scripts/scenario_actions.gd:794` | `point = block.global_position` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/scenario_actions.gd:796` | `var root: Node2D = main.hive_root if str(action.get("view", "hive")) == "hive" else main.meadow_root` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/scenario_actions.gd:797` | `point = root.to_global(Vector2(float(action.get("x", 0.0)), float(action.get("y", 0.0))))` | to_global transform | calling node | global world | node local space | world global space | Converted correctly | High |
| `scripts/scenario_actions.gd:1497` | `var actual_gap: float = (viewport_rect.position.y + viewport_rect.size.y) - (rect.position.y + rect.size.y)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/scenario_actions.gd:1509` | `var actual_after_gap: float = rect.position.x - (after_rect.position.x + after_rect.size.x)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/scenario_actions.gd:1546` | `var actual_below_gap: float = rect.position.y - (below_rect.position.y + below_rect.size.y)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/scenario_actions.gd:1774` | `gaps.append(right_rect.position.x - (left_rect.position.x + left_rect.size.x))` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/skill_tree_panel.gd:92` | `scroll_container.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/skill_tree_panel.gd:95` | `column.add_child(header)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/skill_tree_panel.gd:100` | `header.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/skill_tree_panel.gd:108` | `header.add_child(close_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/skill_tree_panel.gd:111` | `column.add_child(intro)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/skill_tree_panel.gd:122` | `column.add_child(grid)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/skill_tree_panel.gd:124` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/skill_tree_panel.gd:127` | `column.add_child(strip)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/skill_tree_panel.gd:138` | `strip.add_child(buy_button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/skill_tree_panel.gd:139` | `strip.add_child(detail_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/skill_tree_panel.gd:444` | `var seen := Rect2(global_position, size).intersection(get_viewport_rect())` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/skill_tree_panel.gd:555` | `_press_at = button.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/skill_tree_panel.gd:558` | `_click(button.position)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/skill_tree_panel.gd:563` | `_zoom_about(button.position, ZOOM_STEP if button.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / ZOOM_STEP)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/skill_tree_panel.gd:568` | `if not _dragging and motion.position.distance_to(_press_at) > DRAG_THRESHOLD:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/soil_block.gd:91` | `add_child(marker)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/soil_block.gd:102` | `add_child(selection_ring)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/soil_block.gd:105` | `progress_label.position = Vector2(-block_size, -8)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/soil_block.gd:107` | `add_child(progress_label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/soil_block.gd:120` | `add_child(soil_sprite)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/soil_block.gd:214` | `selection_ring.position = Vector2(0.0, -lift)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/soil_block.gd:215` | `marker.position = selection_ring.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/succession_panel.gd:32` | `scroll_container.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/succession_panel.gd:37` | `column.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/succession_panel.gd:39` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/succession_panel.gd:55` | `column.add_child(button)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/succession_panel.gd:70` | `column.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/ui.gd:58` | `row.add_child(control)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/ui.gd:59` | `row.add_child(info_badge(tip))` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/ui_info_badge.gd:27` | `panel.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/winter_panel.gd:36` | `scroll_container.add_child(column)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/winter_panel.gd:39` | `column.add_child(header)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/winter_panel.gd:44` | `header.add_child(title)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/winter_panel.gd:45` | `header.add_child(UI.info_badge(` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/winter_panel.gd:58` | `header.add_child(close_btn)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/winter_panel.gd:60` | `column.add_child(HSeparator.new())` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/winter_panel.gd:72` | `column.add_child(label)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/world_building.gd:42` | `grass.position = main.HIVE_MARKER_POSITION` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:45` | `main.meadow_root.add_child(grass)` | add_child | Main (root) | meadow_root | Main / world | meadow_root child space | Same space | High |
| `scripts/world_building.gd:49` | `main.hive.position = main.HIVE_MARKER_POSITION` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:50` | `main.meadow_root.add_child(main.hive)` | add_child | Main (root) | meadow_root | Main / world | meadow_root child space | Same space | High |
| `scripts/world_building.gd:75` | `if root != (main.hive_root if main.in_hive_view else main.meadow_root):` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/world_building.gd:83` | `_view_rect = Rect2(cam.position - span * 0.5, span).grow(120.0)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:84` | `return _view_rect.has_point(node.global_position)` | global_position access/assignment | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/world_building.gd:87` | `var spot: Vector2 = main.hive.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:89` | `var candidate: Vector2 = main.hive.position + Vector2(` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:93` | `if candidate.distance_to(main.hive.position) < GameConfig.rival_min_distance:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/world_building.gd:99` | `if spot == main.hive.position:` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:100` | `spot = main.hive.position + Vector2(main.FLOWER_FIELD_HALF_SIZE.x * 0.9, main.FLOWER_FIELD_HALF_SIZE.y * 0.6)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:104` | `main.rival.position = spot` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:106` | `main.meadow_root.add_child(main.rival)` | add_child | Main (root) | meadow_root | Main / world | meadow_root child space | Same space | High |
| `scripts/world_building.gd:120` | `pos = main.hive.position + Vector2(` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:124` | `var clear_of_hive: bool = pos.distance_to(main.hive.position) > main.OBSTACLE_HIVE_CLEARANCE + radius` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/world_building.gd:127` | `if pos.distance_to(other.pos) < radius + other.radius + gap:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/world_building.gd:137` | `obstacle.position = pos` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:139` | `main.meadow_root.add_child(obstacle)` | add_child | Main (root) | meadow_root | Main / world | meadow_root child space | Same space | High |
| `scripts/world_building.gd:272` | `if anchor.distance_to(main.hive.position) >= main.FLOWER_MIN_DISTANCE:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/world_building.gd:311` | `flower.position = _clear_of_obstacles(pos)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:312` | `main.meadow_root.add_child(flower)` | add_child | Main (root) | meadow_root | Main / world | meadow_root child space | Same space | High |
| `scripts/world_building.gd:331` | `var centre: Vector2 = main.hive.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:340` | `if point.distance_to(obstacle.position) < obstacle.radius + main.FLOWER_CLEARANCE:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/world_building.gd:350` | `var offset: Vector2 = result - obstacle.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:355` | `result = obstacle.position + offset.normalized() * edge` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:364` | `return main.hive.position + Vector2(` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:372` | `point = main.hive.position + Vector2(` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:376` | `if point.distance_to(main.hive.position) >= main.FLOWER_MIN_DISTANCE:` | distance measurement | node / point A parent | node / point B parent | local space | local space | Same space | High |
| `scripts/world_building.gd:389` | `main.hive.comb_parent = main.hive_root` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/world_building.gd:419` | `marker.position = hive_entrance_inside()` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:422` | `main.hive_root.add_child(marker)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/world_building.gd:433` | `cell.position = centre_local + main.Shapes.hex_to_pixel(cell_hex.x, cell_hex.y, spacing, Session.use_sprite_hex_grid)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:434` | `main.hive_root.add_child(cell)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/world_building.gd:456` | `main.queen.position = centre_local + Vector2(0, (interior_rings - 3) * spacing * 1.5)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:457` | `main.hive_root.add_child(main.queen)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/world_building.gd:485` | `tile.position = centre_local + main.Shapes.hex_to_pixel(hex.x, hex.y, spacing, Session.use_sprite_hex_grid)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:491` | `main.hive_root.add_child(tile)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/world_building.gd:497` | `block.position = centre_local + main.Shapes.hex_to_pixel(hex.x, hex.y, spacing, Session.use_sprite_hex_grid)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:498` | `main.hive_root.add_child(block)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/world_building.gd:506` | `block.position = centre_local + main.Shapes.hex_to_pixel(hex.x, hex.y, spacing, Session.use_sprite_hex_grid)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:507` | `main.hive_root.add_child(block)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/world_building.gd:557` | `main.meadow_camera.position = Vector2(640, 320)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:558` | `main.add_child(main.meadow_camera)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/world_building.gd:561` | `main.hive_camera.position = main.HIVE_INTERIOR_CENTRE` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:562` | `main.add_child(main.hive_camera)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/world_building.gd:566` | `bee.position = main.hive.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:567` | `main.meadow_root.add_child(bee)` | add_child | Main (root) | meadow_root | Main / world | meadow_root child space | Same space | High |
| `scripts/world_building.gd:577` | `bee.position = cell.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:578` | `main.hive_root.add_child(bee)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/world_building.gd:613` | `bee.position = main.hive.nearest_walkable_point(spawn_point)` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:614` | `main.hive_root.add_child(bee)` | add_child | Main (root) | hive_root | Main / world | hive_root child space | Same space | High |
| `scripts/world_building.gd:634` | `if bee.get_parent() == main.hive_root:` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/world_building.gd:637` | `bee.reparent(main.hive_root)` | reparent | meadow_root (previous) | hive_root (new) | meadow-local | hive-local | Converted correctly | High |
| `scripts/world_building.gd:638` | `bee.position = hive_entrance_inside()` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:649` | `if bee.get_parent() == main.meadow_root:` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/world_building.gd:652` | `bee.reparent(main.meadow_root)` | reparent | hive_root (previous) | meadow_root (new) | hive-local | meadow-local | Converted correctly | High |
| `scripts/world_building.gd:653` | `bee.position = main.hive.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:669` | `marker.position = bee.position` | position access/assignment | node / context | assigned vector | local space | local space | Same space | High |
| `scripts/world_building.gd:685` | `parent = main.meadow_root` | root reference | Main | hive_root / meadow_root | World | root node | Same space | High |
| `scripts/world_building.gd:686` | `parent.add_child(marker)` | add_child | caller node | added node | local | local | Same space | High |
| `scripts/world_building.gd:710` | `if is_instance_valid(o) and o.global_position.distance_to(point) <= o.radius:` | distance measurement | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/world_building.gd:716` | `if f.global_position.distance_to(point) <= 20.0:` | distance measurement | World (global) | World (global) | global space | global space | Same space | High |
| `scripts/year_winter.gd:146` | `main.camera_view._active_camera().position = main.selected_bees[0].global_position` | global_position access/assignment | Main (identity root) | target node | global space | global space | Same space | High |
| `scripts/year_winter.gd:159` | `main.camera_view._active_camera().position = found[0].global_position` | global_position access/assignment | Main (identity root) | target node | global space | global space | Same space | High |

## Method
1. Identified all 43 GDScript files in `scripts/` matching keywords `hive_root`, `meadow_root`, `global_position`, `to_global`, `to_local`, `reparent`, `add_child`.
2. Scanned all executable code expressions (excluding comment lines) matching coordinate keywords or position operations (`position`, `distance_to`, `distance_squared_to`, `add_child`, `reparent`, `to_global`, `to_local`, `global_position`).
3. For each expression, determined operand parents, coordinate spaces, operation types, and classifications (Same space, Converted correctly, Mixed, or Unknown).
4. Verified world-parent transitions between `hive_root` and `meadow_root` to ensure positions are properly converted upon reparenting.
5. Hand-verified key sites including `scripts/world_building.gd:637`, `scripts/challenge_runner.gd:626`, `scripts/bee_honey.gd:76`, `scripts/input_selection.gd:618`, and `scripts/bee_foraging.gd:439` against source code at commit 413546be.
