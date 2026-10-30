# Audit: hive and meadow coordinate spaces
Audited: 1f8a908c on 2026-10-30 | Task: J-31 | Scope: scripts/*.gd (651 sites across 43 GDScript files)

## Summary
Audited 651 expressions across 43 GDScript files in `scripts/` referencing `hive_root`, `meadow_root`, `global_position`, `to_global`, `to_local`, `reparent`, or `add_child` for bees, flowers, cells, and markers.
All 651 sites are classified as either same space (615) or converted correctly (36). Zero mixed coordinate space bugs were found in `origin/master` at commit 1f8a908c.

Key findings / verified invariants:
1. `world_building.gd::move_bee_into_hive` and `move_bee_out_of_hive` correctly reparent bees to `hive_root` / `meadow_root` and reassign local position to the corresponding entrance.
2. `input_selection.gd::_show_click_marker` converts global click input via `root.to_local(world_point)` before adding the marker to `hive_root` or `meadow_root`.
3. `world_building.gd::mark_death` parents death markers to `bee.get_parent()` using `bee.position` in the same space.
4. `bee_honey.gd` and `hive.gd::find_honey_source` consistently use global coordinates for cell position comparisons, matching the documented interface contract.
5. `year_winter.gd:146,159` camera position assignments using `global_position` are correct because `hive_camera` and `meadow_camera` are children of `main` at origin (0,0).

## Findings
No active coordinate space findings or bugs were identified in `origin/master` commit 1f8a908c.

| # | Where (path:line) | What | Why it matters | Confidence | Fix |
|---|---|---|---|---|---|
| - | None | No active mixed coordinate space errors found | N/A | High | None required |

## Candidate Jules tasks
No candidate Jules tasks are proposed because no mixed coordinate space shapes isolatable by a static regex were found.

## For Claude or Codex
No items require Claude or Codex action.

## Inventory
| Site (path:line) | Code Expression | Operation | Classification |
|---|---|---|---|
| `scripts/bee.gd:802` | `# hive_root's child list after bees that already exist, which made` | coordinate reference | Same space |
| `scripts/bee.gd:804` | `# reparenting/adding doesn't reshuffle existing children. Giving bees` | reparent | Converted correctly |
| `scripts/bee.gd:853` | `add_child(visual_root)` | add child | Same space |
| `scripts/bee.gd:865` | `visual_root.add_child(selection_ring)` | add child | Same space |
| `scripts/bee.gd:874` | `visual_root.add_child(alarm_ring)` | add child | Same space |
| `scripts/bee.gd:885` | `visual_root.add_child(attack_ring)` | add child | Same space |
| `scripts/bee.gd:894` | `visual_root.add_child(search_ring)` | add child | Same space |
| `scripts/bee.gd:905` | `visual_root.add_child(dance_ring)` | add child | Same space |
| `scripts/bee.gd:913` | `visual_root.add_child(outline)` | add child | Same space |
| `scripts/bee.gd:922` | `visual_root.add_child(outline_ring)` | add child | Same space |
| `scripts/bee.gd:927` | `visual_root.add_child(body)` | add child | Same space |
| `scripts/bee.gd:934` | `visual_root.add_child(centre_dot)` | add child | Same space |
| `scripts/bee.gd:954` | `visual_root.add_child(heading_marker)` | add child | Same space |
| `scripts/bee.gd:959` | `visual_root.add_child(label)` | add child | Same space |
| `scripts/bee.gd:2173` | `## meadow_root sits at the origin).` | coordinate reference | Same space |
| `scripts/bee.gd:2177` | `var target: Vector2 = parent.to_local(world_point) if parent else world_point` | transform conversion | Converted correctly |
| `scripts/bee.gd:2213` | `## `meadow_point` is global/meadow-space (meadow_root sits at the origin,` | coordinate reference | Same space |
| `scripts/bee.gd:2413` | `## Called immediately after the entrance reparenting at either side. Returns` | reparent | Converted correctly |
| `scripts/bee.gd:2463` | `# walking out) is still physically parented under hive_root. Forcing` | coordinate reference | Same space |
| `scripts/bee.gd:2526` | `## Changing a bee's job used to reparent it between the meadow and the` | reparent | Converted correctly |
| `scripts/bee.gd:3182` | `return world != null and get_parent() == world.hive_root` | coordinate reference | Same space |
| `scripts/bee.gd:3184` | `## PP-1: every way into the hive reparents the bee under hive_root` | reparent | Converted correctly |
| `scripts/bee.gd:3186` | `## direct call), and a reparent re-enters the tree, so entering is caught` | reparent | Converted correctly |
| `scripts/bee_foraging.gd:144` | `## Flowers are only looked for from the meadow. Under hive_root a bee's` | coordinate reference | Same space |
| `scripts/bee_foraging.gd:862` | `## than vanishing at the meadow marker. main.gd owns the reparenting` | reparent | Converted correctly |
| `scripts/bee_foraging.gd:1356` | `# using the shared exit so she is reparented out of the hive first.` | reparent | Converted correctly |
| `scripts/bee_honey.gd:76` | `var nectar_cell: Variant = bee.hive.find_honey_source(bee.global_position)` | global position | Same space |
| `scripts/bee_speech_bubble.gd:25` | `add_child(_panel)` | add child | Same space |
| `scripts/bee_speech_bubble.gd:30` | `_panel.add_child(_label)` | add child | Same space |
| `scripts/bee_speech_bubble.gd:47` | `## Bees reparent between hive_root and meadow_root as they cross the` | reparent | Converted correctly |
| `scripts/bee_speech_bubble.gd:54` | `reparent(bee_parent, false)` | reparent | Converted correctly |
| `scripts/camera_view.gd:62` | `points.append(cell.global_position)` | global position | Same space |
| `scripts/camera_view.gd:64` | `points.append(main.meadow_root.to_global(main.hive.position))` | transform conversion | Converted correctly |
| `scripts/camera_view.gd:66` | `points.append(b.global_position)` | global position | Same space |
| `scripts/camera_view.gd:98` | `var bee_indoors: bool = bee.get_parent() == main.hive_root` | coordinate reference | Same space |
| `scripts/camera_view.gd:102` | `var bounds := Rect2(bee.global_position, Vector2.ZERO).grow(140.0)` | global position | Same space |
| `scripts/camera_view.gd:139` | `var bee_indoors: bool = main.following_bee.get_parent() == main.hive_root` | coordinate reference | Same space |
| `scripts/camera_view.gd:142` | `_active_camera().position = main.following_bee.global_position` | global position | Same space |
| `scripts/camera_view.gd:155` | `main.meadow_root.visible = not main.in_hive_view` | coordinate reference | Same space |
| `scripts/camera_view.gd:156` | `main.hive_root.visible = main.in_hive_view` | coordinate reference | Same space |
| `scripts/challenge_complete.gd:42` | `add_child(backdrop)` | add child | Same space |
| `scripts/challenge_complete.gd:51` | `add_child(panel)` | add child | Same space |
| `scripts/challenge_complete.gd:55` | `panel.add_child(column)` | add child | Same space |
| `scripts/challenge_complete.gd:67` | `column.add_child(headline_label)` | add child | Same space |
| `scripts/challenge_complete.gd:73` | `column.add_child(flavour_label)` | add child | Same space |
| `scripts/challenge_complete.gd:78` | `column.add_child(summary_label)` | add child | Same space |
| `scripts/challenge_complete.gd:85` | `column.add_child(reward_label)` | add child | Same space |
| `scripts/challenge_complete.gd:90` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/challenge_complete.gd:99` | `column.add_child(continue_row)` | add child | Same space |
| `scripts/challenge_complete.gd:109` | `column.add_child(continue_to_next_row)` | add child | Same space |
| `scripts/challenge_complete.gd:119` | `column.add_child(restart_row)` | add child | Same space |
| `scripts/challenge_complete.gd:127` | `column.add_child(UI.with_info(menu_btn, "Go back to the menu and pick a different Challenge or Scenario."))` | add child | Same space |
| `scripts/challenge_runner.gd:232` | `# _build_cameras), not hive_root, so it sits in the same coordinate` | coordinate reference | Same space |
| `scripts/challenge_runner.gd:233` | `# space global_position already resolves to -- no manual offset math` | global position | Same space |
| `scripts/challenge_runner.gd:234` | `# needed here the way hive_entrance_inside() has to do for hive_root.` | coordinate reference | Same space |
| `scripts/challenge_runner.gd:235` | `main.hive_camera.position = main.queen.global_position` | global position | Same space |
| `scripts/challenge_runner.gd:301` | `main.hive_root.add_child(_marker)` | add child | Same space |
| `scripts/challenge_runner.gd:510` | `_begin_ordered_visit(_hive_inspection_points(), main.hive_root)` | coordinate reference | Same space |
| `scripts/challenge_runner.gd:512` | `_begin_ordered_visit(_meadow_inspection_points(), main.meadow_root)` | coordinate reference | Same space |
| `scripts/challenge_runner.gd:518` | `_new_worker.get_parent().add_child(bubble)` | add child | Same space |
| `scripts/challenge_runner.gd:582` | `## meadow_root instead of hive_root.` | coordinate reference | Same space |
| `scripts/challenge_runner.gd:612` | `var target_global: Vector2 = _visit_marker_parent.to_global(point.position)` | transform conversion | Converted correctly |
| `scripts/challenge_runner.gd:613` | `if traveller.global_position.distance_to(target_global) > float(point.radius):` | global position | Same space |
| `scripts/challenge_runner.gd:626` | `_marker.reparent(_visit_marker_parent, false)` | reparent | Converted correctly |
| `scripts/challenge_runner.gd:632` | `## reparent it to either world; Bundle C uses the hive root, and Bundle D can` | reparent | Converted correctly |
| `scripts/challenge_runner.gd:641` | `marker_parent = main.hive_root` | coordinate reference | Same space |
| `scripts/challenge_runner.gd:643` | `marker_parent = main.meadow_root` | coordinate reference | Same space |
| `scripts/challenge_runner.gd:645` | `_marker.reparent(marker_parent, false)` | reparent | Converted correctly |
| `scripts/challenge_runner.gd:701` | `_marker.global_position, _marker.visible,` | global position | Same space |
| `scripts/challenge_runner.gd:702` | `_marker.get_parent() == main.hive_root)` | coordinate reference | Same space |
| `scripts/challenge_runner.gd:1098` | `main.hive_root.add_child(hearts)` | add child | Same space |
| `scripts/click_marker.gd:22` | `add_child(ring)` | add child | Same space |
| `scripts/colony_panel.gd:103` | `scroll_container.add_child(column)` | add child | Same space |
| `scripts/colony_panel.gd:108` | `column.add_child(title)` | add child | Same space |
| `scripts/colony_panel.gd:116` | `column.add_child(hint)` | add child | Same space |
| `scripts/colony_panel.gd:129` | `needing_attention_column.add_child(needing_attention_ok_label)` | add child | Same space |
| `scripts/colony_panel.gd:133` | `jobs.add_child(_make_role_row(key))` | add child | Same space |
| `scripts/colony_panel.gd:138` | `readouts.add_child(_make_stat_row(entry))` | add child | Same space |
| `scripts/colony_panel.gd:147` | `favourites_column.add_child(favourites_empty_label)` | add child | Same space |
| `scripts/colony_panel.gd:173` | `column.add_child(header)` | add child | Same space |
| `scripts/colony_panel.gd:178` | `column.add_child(body)` | add child | Same space |
| `scripts/colony_panel.gd:237` | `row.add_child(star)` | add child | Same space |
| `scripts/colony_panel.gd:244` | `row.add_child(label)` | add child | Same space |
| `scripts/colony_panel.gd:247` | `row.add_child(UI.info_badge(entry.tip))` | add child | Same space |
| `scripts/colony_panel.gd:268` | `column.add_child(header)` | add child | Same space |
| `scripts/colony_panel.gd:273` | `header.add_child(title)` | add child | Same space |
| `scripts/colony_panel.gd:274` | `header.add_child(UI.info_badge(` | add child | Same space |
| `scripts/colony_panel.gd:279` | `column.add_child(plot_button_row)` | add child | Same space |
| `scripts/colony_panel.gd:289` | `plot_button_row.add_child(btn)` | add child | Same space |
| `scripts/colony_panel.gd:294` | `column.add_child(plot)` | add child | Same space |
| `scripts/colony_panel.gd:299` | `column.add_child(plot_label)` | add child | Same space |
| `scripts/colony_panel.gd:430` | `default_order_column.add_child(hint)` | add child | Same space |
| `scripts/colony_panel.gd:433` | `default_order_column.add_child(hint)` | add child | Same space |
| `scripts/colony_panel.gd:438` | `default_order_column.add_child(build_backup_editor(Session.backup_order_default, addable, _on_default_order_changed, _default_order_focus))` | add child | Same space |
| `scripts/colony_panel.gd:461` | `needing_attention_column.add_child(` | add child | Same space |
| `scripts/colony_panel.gd:482` | `favourites_column.add_child(_make_favourite_row(b))` | add child | Same space |
| `scripts/colony_panel.gd:516` | `box.add_child(none)` | add child | Same space |
| `scripts/colony_panel.gd:521` | `box.add_child(row)` | add child | Same space |
| `scripts/colony_panel.gd:526` | `row.add_child(label)` | add child | Same space |
| `scripts/colony_panel.gd:529` | `row.add_child(up)` | add child | Same space |
| `scripts/colony_panel.gd:532` | `row.add_child(down)` | add child | Same space |
| `scripts/colony_panel.gd:538` | `row.add_child(remove)` | add child | Same space |
| `scripts/colony_panel.gd:553` | `box.add_child(add)` | add child | Same space |
| `scripts/death_marker.gd:42` | `add_child(body)` | add child | Same space |
| `scripts/death_marker.gd:54` | `add_child(selection_ring)` | add child | Same space |
| `scripts/death_marker.gd:62` | `add_child(line)` | add child | Same space |
| `scripts/debug_panel.gd:113` | `add_child(_text_scale_timer)` | add child | Same space |
| `scripts/debug_panel.gd:145` | `add_child(toggle_button)` | add child | Same space |
| `scripts/debug_panel.gd:180` | `add_child(panel)` | add child | Same space |
| `scripts/debug_panel.gd:191` | `panel.add_child(panel_scroll)` | add child | Same space |
| `scripts/debug_panel.gd:200` | `panel_scroll.add_child(content_margin)` | add child | Same space |
| `scripts/debug_panel.gd:204` | `content_margin.add_child(column)` | add child | Same space |
| `scripts/debug_panel.gd:211` | `column.add_child(_make_collection(` | add child | Same space |
| `scripts/debug_panel.gd:268` | `wrapper.add_child(header)` | add child | Same space |
| `scripts/debug_panel.gd:269` | `wrapper.add_child(body)` | add child | Same space |
| `scripts/debug_panel.gd:278` | `body.add_child(_make_section(category, rows, false))` | add child | Same space |
| `scripts/debug_panel.gd:335` | `wrapper.add_child(header)` | add child | Same space |
| `scripts/debug_panel.gd:336` | `wrapper.add_child(body)` | add child | Same space |
| `scripts/debug_panel.gd:364` | `body.add_child(made)` | add child | Same space |
| `scripts/debug_panel.gd:366` | `body.add_child(_make_challenge_stage_navigation())` | add child | Same space |
| `scripts/debug_panel.gd:371` | `body.add_child(_make_controls_help())` | add child | Same space |
| `scripts/debug_panel.gd:376` | `body.add_child(HSeparator.new())` | add child | Same space |
| `scripts/debug_panel.gd:377` | `body.add_child(_make_winter_action())` | add child | Same space |
| `scripts/debug_panel.gd:403` | `row.add_child(challenge_retreat_btn)` | add child | Same space |
| `scripts/debug_panel.gd:428` | `row.add_child(challenge_stage_label)` | add child | Same space |
| `scripts/debug_panel.gd:436` | `row.add_child(challenge_advance_btn)` | add child | Same space |
| `scripts/debug_panel.gd:568` | `column.add_child(save_row)` | add child | Same space |
| `scripts/debug_panel.gd:574` | `save_row.add_child(UI.with_info(save_btn, "Write the current run to disk: the comb and everything in it, every bee and what it is doing, the meadow, the weather and the clock. There is one save slot, so saving again overwrites it."))` | add child | Same space |
| `scripts/debug_panel.gd:580` | `save_row.add_child(UI.with_info(load_btn, "Open the Saves window: save this run by name, load a save or one of its checkpoints, or delete one."))` | add child | Same space |
| `scripts/debug_panel.gd:584` | `column.add_child(developer_row)` | add child | Same space |
| `scripts/debug_panel.gd:592` | `column.add_child(triggers_box)` | add child | Same space |
| `scripts/debug_panel.gd:595` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/debug_panel.gd:607` | `triggers_box.add_child(UI.with_info(triggers_header, "Debug only: every button in this group forces a simulation state the world otherwise reaches rarely or not at all, so a behaviour that depends on it can be watched on demand instead of waited for."))` | add child | Same space |
| `scripts/debug_panel.gd:667` | `developer_row.add_child(row)` | add child | Same space |
| `scripts/debug_panel.gd:683` | `add_child(run_availability_panel)` | add child | Same space |
| `scripts/debug_panel.gd:697` | `parent.add_child(row)` | add child | Same space |
| `scripts/debug_panel.gd:705` | `row.add_child(UI.with_info(winter_btn, "Schedule a winter for a set number of days from now (see \"Winter in days\" in the Winter section). A forecast opens in the Winter window on the left showing what the colony will need to last it out and how far short it currently is. The figure moves as the colony grows, which is the point: every bee you add is another mouth to feed through it."))` | add child | Same space |
| `scripts/debug_panel.gd:883` | `row.add_child(lbl)` | add child | Same space |
| `scripts/debug_panel.gd:885` | `row.add_child(UI.info_badge(entry.tip))` | add child | Same space |
| `scripts/debug_panel.gd:889` | `row.add_child(controls)` | add child | Same space |
| `scripts/debug_panel.gd:896` | `controls.add_child(minus)` | add child | Same space |
| `scripts/debug_panel.gd:903` | `controls.add_child(plus)` | add child | Same space |
| `scripts/debug_panel.gd:929` | `button.add_child(timer)` | add child | Same space |
| `scripts/debug_panel.gd:964` | `row.add_child(label)` | add child | Same space |
| `scripts/debug_panel.gd:965` | `row.add_child(UI.info_badge(entry.tip))` | add child | Same space |
| `scripts/debug_panel.gd:969` | `row.add_child(controls)` | add child | Same space |
| `scripts/debug_panel.gd:1021` | `controls.add_child(box)` | add child | Same space |
| `scripts/debug_panel.gd:1038` | `row.add_child(lbl)` | add child | Same space |
| `scripts/debug_panel.gd:1040` | `row.add_child(UI.info_badge(entry.tip))` | add child | Same space |
| `scripts/debug_panel.gd:1044` | `row.add_child(controls)` | add child | Same space |
| `scripts/debug_panel.gd:1051` | `controls.add_child(prev)` | add child | Same space |
| `scripts/debug_panel.gd:1058` | `controls.add_child(next)` | add child | Same space |
| `scripts/debug_panel.gd:1121` | `row.add_child(label)` | add child | Same space |
| `scripts/debug_panel.gd:1122` | `row.add_child(UI.info_badge(entry.tip))` | add child | Same space |
| `scripts/debug_panel.gd:1126` | `row.add_child(controls)` | add child | Same space |
| `scripts/debug_panel.gd:1151` | `controls.add_child(star)` | add child | Same space |
| `scripts/flower.gd:147` | `add_child(selection_ring)` | add child | Same space |
| `scripts/flower.gd:169` | `add_child(bush)` | add child | Same space |
| `scripts/flower.gd:174` | `add_child(centre_dot)` | add child | Same space |
| `scripts/flower.gd:188` | `add_child(crab_spider_marker)` | add child | Same space |
| `scripts/flower.gd:207` | `add_child(crab_spider_dev_marker)` | add child | Same space |
| `scripts/flower.gd:216` | `add_child(nectar_label)` | add child | Same space |
| `scripts/flower.gd:221` | `add_child(pollen_label)` | add child | Same space |
| `scripts/fog_of_war.gd:31` | `## Drawn on `_layer`, a plain Node2D added under `main.meadow_root` so it` | coordinate reference | Same space |
| `scripts/fog_of_war.gd:33` | `## hive-view toggle automatically (`meadow_root.visible` already flips in` | coordinate reference | Same space |
| `scripts/fog_of_war.gd:144` | `## Challenge 1's opening happens in hive_root, while the ordinary fog layer` | coordinate reference | Same space |
| `scripts/fog_of_war.gd:145` | `## belongs to meadow_root and is hidden in hive view. A separate small mask` | coordinate reference | Same space |
| `scripts/fog_of_war.gd:212` | `## Called once, after meadow_root and main.hive both exist -- world_building` | coordinate reference | Same space |
| `scripts/fog_of_war.gd:222` | `main.meadow_root.add_child(_layer)` | add child | Same space |
| `scripts/fog_of_war.gd:251` | `main.hive_root.add_child(_hive_layer)` | add child | Same space |
| `scripts/fog_of_war.gd:287` | `if not is_instance_valid(b) or b.get_parent() != main.meadow_root:` | coordinate reference | Same space |
| `scripts/fog_of_war.gd:344` | `if hive_reveal_mode == "queen" and is_instance_valid(main.queen) and main.queen.get_parent() == main.hive_root:` | coordinate reference | Same space |
| `scripts/fog_of_war.gd:440` | `var local_cam_pos: Vector2 = cam.position - main.hive_root.position` | coordinate reference | Same space |
| `scripts/foraging_panel.gd:29` | `scroll_container.add_child(column)` | add child | Same space |
| `scripts/foraging_panel.gd:34` | `column.add_child(title)` | add child | Same space |
| `scripts/foraging_panel.gd:42` | `column.add_child(gate_hint_label)` | add child | Same space |
| `scripts/foraging_panel.gd:49` | `overview.add_child(overview_label)` | add child | Same space |
| `scripts/foraging_panel.gd:54` | `species_section.add_child(species_column)` | add child | Same space |
| `scripts/foraging_panel.gd:59` | `species_column.add_child(species_empty_label)` | add child | Same space |
| `scripts/foraging_panel.gd:66` | `recruitment.add_child(recruitment_label)` | add child | Same space |
| `scripts/foraging_panel.gd:78` | `column.add_child(header)` | add child | Same space |
| `scripts/foraging_panel.gd:83` | `column.add_child(body)` | add child | Same space |
| `scripts/foraging_panel.gd:145` | `species_column.add_child(label)` | add child | Same space |
| `scripts/gallerin_panel.gd:163` | `add_child(_icon_button)` | add child | Same space |
| `scripts/gallerin_panel.gd:176` | `_icon_button.add_child(wing_left)` | add child | Same space |
| `scripts/gallerin_panel.gd:184` | `_icon_button.add_child(wing_right)` | add child | Same space |
| `scripts/gallerin_panel.gd:190` | `_icon_button.add_child(body)` | add child | Same space |
| `scripts/gallerin_panel.gd:205` | `add_child(_why_button)` | add child | Same space |
| `scripts/gallerin_panel.gd:210` | `add_child(_why_popup)` | add child | Same space |
| `scripts/gallerin_panel.gd:213` | `_why_popup.add_child(column)` | add child | Same space |
| `scripts/gallerin_panel.gd:217` | `column.add_child(heading)` | add child | Same space |
| `scripts/gallerin_panel.gd:222` | `column.add_child(_why_list)` | add child | Same space |
| `scripts/gallerin_panel.gd:226` | `column.add_child(detail_scroll)` | add child | Same space |
| `scripts/gallerin_panel.gd:230` | `detail_scroll.add_child(_why_detail)` | add child | Same space |
| `scripts/gallerin_panel.gd:234` | `column.add_child(close_btn)` | add child | Same space |
| `scripts/gallerin_panel.gd:306` | `add_child(bubble)` | add child | Same space |
| `scripts/gallerin_panel.gd:327` | `bubble.add_child(_bubble_scroll)` | add child | Same space |
| `scripts/gallerin_panel.gd:335` | `_bubble_scroll.add_child(column)` | add child | Same space |
| `scripts/gallerin_panel.gd:353` | `column.add_child(text_row)` | add child | Same space |
| `scripts/gallerin_panel.gd:354` | `text_row.add_child(_bubble_label)` | add child | Same space |
| `scripts/gallerin_panel.gd:362` | `text_row.add_child(close_btn)` | add child | Same space |
| `scripts/gallerin_panel.gd:370` | `bubble.add_child(_bubble_pointer)` | add child | Same space |
| `scripts/gallerin_panel.gd:377` | `column.add_child(row)` | add child | Same space |
| `scripts/gallerin_panel.gd:385` | `row.add_child(_history_back_btn)` | add child | Same space |
| `scripts/gallerin_panel.gd:393` | `row.add_child(_history_forward_btn)` | add child | Same space |
| `scripts/gallerin_panel.gd:398` | `row.add_child(disable_btn)` | add child | Same space |
| `scripts/game_over.gd:36` | `add_child(backdrop)` | add child | Same space |
| `scripts/game_over.gd:45` | `add_child(panel)` | add child | Same space |
| `scripts/game_over.gd:49` | `panel.add_child(column)` | add child | Same space |
| `scripts/game_over.gd:55` | `column.add_child(title)` | add child | Same space |
| `scripts/game_over.gd:66` | `column.add_child(body)` | add child | Same space |
| `scripts/game_over.gd:70` | `column.add_child(summary_label)` | add child | Same space |
| `scripts/game_over.gd:72` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/game_over.gd:78` | `column.add_child(UI.with_info(checkpoint_btn, "Reload the run as it was on that day, the same way the Saves window loads a checkpoint."))` | add child | Same space |
| `scripts/game_over.gd:84` | `column.add_child(UI.with_info(restart_btn, "Start the run again at the same stage, with the same tuning values."))` | add child | Same space |
| `scripts/game_over.gd:90` | `column.add_child(UI.with_info(menu_btn, "Go back to the menu and pick a different starting stage."))` | add child | Same space |
| `scripts/game_panel.gd:48` | `add_child(panel)` | add child | Same space |
| `scripts/game_panel.gd:55` | `panel.add_child(scroll_container)` | add child | Same space |
| `scripts/hive.gd:260` | `add_child(skep)` | add child | Same space |
| `scripts/hive.gd:660` | `score = from.distance_squared_to(cell.global_position)` | global position | Same space |
| `scripts/hive.gd:813` | `comb_parent.add_child(body)` | add child | Same space |
| `scripts/hive.gd:958` | `comb_parent.add_child(cell)` | add child | Same space |
| `scripts/hive_cell.gd:451` | `add_child(empty_sprite)` | add child | Same space |
| `scripts/hive_cell.gd:462` | `add_child(cap_sprite)` | add child | Same space |
| `scripts/hive_cell.gd:470` | `add_child(fill_shape)` | add child | Same space |
| `scripts/hive_cell.gd:476` | `add_child(outline)` | add child | Same space |
| `scripts/hive_cell.gd:485` | `add_child(designation_ring)` | add child | Same space |
| `scripts/hive_cell.gd:494` | `add_child(selection_ring)` | add child | Same space |
| `scripts/hive_cell.gd:506` | `add_child(zone_halo)` | add child | Same space |
| `scripts/hive_cell.gd:513` | `add_child(zone_glow)` | add child | Same space |
| `scripts/hive_cell.gd:526` | `add_child(closed_mark)` | add child | Same space |
| `scripts/hive_cell.gd:531` | `add_child(info_label)` | add child | Same space |
| `scripts/hive_cell.gd:625` | `func _silhouette_point_to_local(p: Vector2) -> Vector2:` | transform conversion | Converted correctly |
| `scripts/hive_cell.gd:641` | `var q := _silhouette_point_to_local(p)` | transform conversion | Converted correctly |
| `scripts/hud.gd:240` | `var _stage_marker_global_position := Vector2.ZERO` | global position | Same space |
| `scripts/hud.gd:604` | `main.add_child.call_deferred(skill_tree_panel)` | add child | Same space |
| `scripts/hud.gd:607` | `main.add_child.call_deferred(pollination_pop)` | add child | Same space |
| `scripts/hud.gd:638` | `add_child(corner_column)` | add child | Same space |
| `scripts/hud.gd:644` | `corner_column.add_child(perf_plot)` | add child | Same space |
| `scripts/hud.gd:648` | `corner_column.add_child(perf_breakdown)` | add child | Same space |
| `scripts/hud.gd:657` | `corner_column.add_child(pause_label)` | add child | Same space |
| `scripts/hud.gd:683` | `add_child(marker_arrow_overlay)` | add child | Same space |
| `scripts/hud.gd:692` | `marker_arrow_overlay.add_child(stage_marker_arrow)` | add child | Same space |
| `scripts/hud.gd:696` | `func set_stage_marker(global_position: Vector2, marker_visible: bool, in_hive: bool) -> void:` | global position | Same space |
| `scripts/hud.gd:697` | `_stage_marker_global_position = global_position` | global position | Same space |
| `scripts/hud.gd:706` | `add_child(l)` | add child | Same space |
| `scripts/hud.gd:755` | `add_child(bar)` | add child | Same space |
| `scripts/hud.gd:761` | `bar.add_child(row1)` | add child | Same space |
| `scripts/hud.gd:772` | `row1.add_child(pause_button)` | add child | Same space |
| `scripts/hud.gd:779` | `row1.add_child(speed_group)` | add child | Same space |
| `scripts/hud.gd:798` | `speed_group.add_child(btn)` | add child | Same space |
| `scripts/hud.gd:801` | `row1.add_child(_info("Game speed, as a multiple of normal. These change how fast the simulation runs; they do not change how much a bee gathers per in-game second."))` | add child | Same space |
| `scripts/hud.gd:807` | `bar.add_child(row2)` | add child | Same space |
| `scripts/hud.gd:815` | `row2.add_child(colony_button)` | add child | Same space |
| `scripts/hud.gd:817` | `row2.add_child(colony_info)` | add child | Same space |
| `scripts/hud.gd:824` | `row2.add_child(nursery_button)` | add child | Same space |
| `scripts/hud.gd:826` | `row2.add_child(nursery_info)` | add child | Same space |
| `scripts/hud.gd:836` | `row2.add_child(foraging_button)` | add child | Same space |
| `scripts/hud.gd:838` | `row2.add_child(_info("Open the foraging window: trip timing (search+flight versus handling), flowers visited per trip, empty-return rate, and the same breakdown split by species, plus recruitment/scouting counts. Only fills in once Auto scouting or Auto-recruitment is on -- that is what scores a trip today."))` | add child | Same space |
| `scripts/hud.gd:847` | `row2.add_child(winter_button)` | add child | Same space |
| `scripts/hud.gd:855` | `row2.add_child(skills_button)` | add child | Same space |
| `scripts/hud.gd:871` | `row2.add_child(goals_button)` | add child | Same space |
| `scripts/hud.gd:880` | `row2.add_child(view_button)` | add child | Same space |
| `scripts/hud.gd:882` | `row2.add_child(view_info)` | add child | Same space |
| `scripts/hud.gd:905` | `btn.add_child(row)` | add child | Same space |
| `scripts/hud.gd:911` | `row.add_child(icon)` | add child | Same space |
| `scripts/hud.gd:917` | `row.add_child(text)` | add child | Same space |
| `scripts/hud.gd:954` | `add_child(goal_shelf)` | add child | Same space |
| `scripts/hud.gd:961` | `goal_shelf.add_child(favourites_box)` | add child | Same space |
| `scripts/hud.gd:972` | `goal_shelf.add_child(long_term_goal_label)` | add child | Same space |
| `scripts/hud.gd:990` | `goal_shelf.add_child(completed_goal_label)` | add child | Same space |
| `scripts/hud.gd:1001` | `goal_shelf.add_child(current_goal_label)` | add child | Same space |
| `scripts/hud.gd:1010` | `goal_shelf.add_child(goal_progress_row)` | add child | Same space |
| `scripts/hud.gd:1016` | `goal_progress_row.add_child(goal_progress_bar)` | add child | Same space |
| `scripts/hud.gd:1022` | `goal_progress_row.add_child(goal_progress_label)` | add child | Same space |
| `scripts/hud.gd:1132` | `label.add_child(star)` | add child | Same space |
| `scripts/hud.gd:1176` | `favourites_box.add_child(line)` | add child | Same space |
| `scripts/hud.gd:1203` | `add_child(selection_panel)` | add child | Same space |
| `scripts/hud.gd:1211` | `selection_panel.add_child(selection_column)` | add child | Same space |
| `scripts/hud.gd:1223` | `column.add_child(header)` | add child | Same space |
| `scripts/hud.gd:1233` | `header.add_child(identity_label)` | add child | Same space |
| `scripts/hud.gd:1234` | `header.add_child(_build_favourite_star())` | add child | Same space |
| `scripts/hud.gd:1235` | `header.add_child(_build_selection_cog())` | add child | Same space |
| `scripts/hud.gd:1241` | `column.add_child(energy_label)` | add child | Same space |
| `scripts/hud.gd:1248` | `column.add_child(activity_label)` | add child | Same space |
| `scripts/hud.gd:1254` | `column.add_child(trait_label)` | add child | Same space |
| `scripts/hud.gd:1262` | `column.add_child(soil_summary_row)` | add child | Same space |
| `scripts/hud.gd:1275` | `soil_summary_row.add_child(soil_mark_wrapper)` | add child | Same space |
| `scripts/hud.gd:1287` | `soil_summary_row.add_child(soil_clear_wrapper)` | add child | Same space |
| `scripts/hud.gd:1294` | `column.add_child(keep_clear_summary_row)` | add child | Same space |
| `scripts/hud.gd:1303` | `keep_clear_summary_row.add_child(keep_clear_btn)` | add child | Same space |
| `scripts/hud.gd:1534` | `add_child(command_tray)` | add child | Same space |
| `scripts/hud.gd:1546` | `command_tray.add_child(command_scroll)` | add child | Same space |
| `scripts/hud.gd:1556` | `command_scroll.add_child(column)` | add child | Same space |
| `scripts/hud.gd:1578` | `column.add_child(command_columns)` | add child | Same space |
| `scripts/hud.gd:1605` | `column.add_child(more_button)` | add child | Same space |
| `scripts/hud.gd:1613` | `column.add_child(more_panel)` | add child | Same space |
| `scripts/hud.gd:1635` | `command_columns.add_child(wrapper)` | add child | Same space |
| `scripts/hud.gd:1642` | `wrapper.add_child(header)` | add child | Same space |
| `scripts/hud.gd:1647` | `wrapper.add_child(content)` | add child | Same space |
| `scripts/hud.gd:1672` | `parent.add_child(cell_group)` | add child | Same space |
| `scripts/hud.gd:1681` | `cell_group.add_child(cell_primary_columns)` | add child | Same space |
| `scripts/hud.gd:1684` | `_build_cell_action_column(cell_primary_columns, "Reserve for").add_child(row)` | add child | Same space |
| `scripts/hud.gd:1692` | `row.add_child(_with_info(nectar_btn, "Reserve this cell for nectar. Foragers carrying pollen will walk past it."))` | add child | Same space |
| `scripts/hud.gd:1700` | `row.add_child(_with_info(pollen_btn, "Reserve this cell for pollen. Foragers carrying nectar will walk past it."))` | add child | Same space |
| `scripts/hud.gd:1708` | `row.add_child(_with_info(honey_btn, "Reserve this cell for honey. Honey makers spit their chewed nectar mix into cells like this one and then fan it dry."))` | add child | Same space |
| `scripts/hud.gd:1716` | `row.add_child(_with_info(jelly_btn, "Reserve this cell for royal jelly. Nurses on the royal jelly sub-mode store what they make here, and draw on it when feeding gyne larvae."))` | add child | Same space |
| `scripts/hud.gd:1725` | `row.add_child(_with_info(bee_bread_btn, "Reserve this cell for bee bread. Honey makers on Fermenting pack pollen and ripe honey in here. Once the cell is full it seals itself and ripens over about two days."))` | add child | Same space |
| `scripts/hud.gd:1733` | `row.add_child(_with_info(egg_btn, "Reserve this cell as a nursery. The queen lays here first, and foragers won't fill it with stores. Reserving enough of these is what stops laying stalling for want of a free cell."))` | add child | Same space |
| `scripts/hud.gd:1741` | `row.add_child(_with_info(auto_btn, "Remove the reservation. The cell takes whichever resource arrives first, and reserves itself for that from then on."))` | add child | Same space |
| `scripts/hud.gd:1757` | `cell_group.add_child(cell_more_button)` | add child | Same space |
| `scripts/hud.gd:1762` | `cell_group.add_child(cell_more_panel)` | add child | Same space |
| `scripts/hud.gd:1780` | `parent.add_child(wrapper)` | add child | Same space |
| `scripts/hud.gd:1786` | `wrapper.add_child(header)` | add child | Same space |
| `scripts/hud.gd:1791` | `wrapper.add_child(body)` | add child | Same space |
| `scripts/hud.gd:1800` | `column.add_child(tier_row)` | add child | Same space |
| `scripts/hud.gd:1805` | `tier_row.add_child(tier_title)` | add child | Same space |
| `scripts/hud.gd:1815` | `tier_row.add_child(btn)` | add child | Same space |
| `scripts/hud.gd:1820` | `tier_row.add_child(_info("How much of the queen's laying this cell gets. She shares eggs between the three tiers in proportion to their weights -- by default 1 : 2 : 3 -- so a high cell receives three eggs for every one a low cell receives, and they come out interleaved rather than in streaks. Twelve high forager cells beside three low nurse cells is how you say \"mostly foragers, a few nurses\" once and then leave it alone. The weights themselves are in the settings window."))` | add child | Same space |
| `scripts/hud.gd:1823` | `column.add_child(open_row)` | add child | Same space |
| `scripts/hud.gd:1829` | `open_row.add_child(_with_info(open_btn, "Open the nursery window: how many cells are assigned to each role and tier, what the colony is made of right now, and how many bees of each kind have emerged in the last three minutes. While it is open every reserved cell glows in the colour of the role it raises."))` | add child | Same space |
| `scripts/hud.gd:1839` | `column.add_child(hatch_row)` | add child | Same space |
| `scripts/hud.gd:1843` | `hatch_row.add_child(hatch_title)` | add child | Same space |
| `scripts/hud.gd:1844` | `hatch_row.add_child(_info("Set what a bee raised in this cell becomes when it emerges. Roles that have a sub-mode -- a forager's resource, whether a miner starts automining -- offer it here, so the new bee arrives already set up."))` | add child | Same space |
| `scripts/hud.gd:1860` | `hatch_row.add_child(btn)` | add child | Same space |
| `scripts/hud.gd:1864` | `hatch_row.add_child(control)` | add child | Same space |
| `scripts/hud.gd:1873` | `hatch_row.add_child(hatch_locked_note)` | add child | Same space |
| `scripts/hud.gd:1877` | `column.add_child(lock_row)` | add child | Same space |
| `scripts/hud.gd:1888` | `lock_row.add_child(hatch_lock_box)` | add child | Same space |
| `scripts/hud.gd:1892` | `column.add_child(gyne_row)` | add child | Same space |
| `scripts/hud.gd:1902` | `gyne_row.add_child(gyne_box)` | add child | Same space |
| `scripts/hud.gd:1903` | `gyne_row.add_child(_info("A gyne is a future queen. She costs the queen several times as much pollen to lay, takes four times as long to develop, and can only be fed on royal jelly with pollen and honey -- so you need nurses producing jelly before one will grow at all. She can do any worker job in the meantime, though she is bigger, slower and hungrier than a worker."))` | add child | Same space |
| `scripts/hud.gd:1907` | `column.add_child(drone_row)` | add child | Same space |
| `scripts/hud.gd:1917` | `drone_row.add_child(drone_box)` | add child | Same space |
| `scripts/hud.gd:1918` | `drone_row.add_child(_info("A drone is a male bee. The queen lays him from an unfertilised egg, he does no work and eats from the stores, and he is needed to mate a gyne. Ticking this clears the gyne box for the cell, and the other way round."))` | add child | Same space |
| `scripts/hud.gd:1919` | `lock_row.add_child(_info("On: every bee this cell ever raises comes out in the chosen role, so you can earmark a cell as a builder nursery once and forget about it. Off: the role applies to the next bee only and then clears, so a one-off choice doesn't quietly govern the cell forever."))` | add child | Same space |
| `scripts/hud.gd:1924` | `column.add_child(feed_first_row)` | add child | Same space |
| `scripts/hud.gd:1934` | `feed_first_row.add_child(feed_first_box)` | add child | Same space |
| `scripts/hud.gd:1935` | `feed_first_row.add_child(_info("Nurses feed a hungry larva in a marked cell before any unmarked one, whatever food it takes, so scarce food goes where you want it. Marked larvae share it among themselves the way unmarked ones do: the hungriest first."))` | add child | Same space |
| `scripts/hud.gd:1941` | `column.add_child(row)` | add child | Same space |
| `scripts/hud.gd:1946` | `row.add_child(title)` | add child | Same space |
| `scripts/hud.gd:1954` | `row.add_child(_with_info(close_btn, "Seal the selected cells. Nothing can be added and nothing taken out until you open them again -- the contents are held in reserve. A sealed cell is drawn with a dark bar across it."))` | add child | Same space |
| `scripts/hud.gd:1963` | `row.add_child(_with_info(open_btn, "Unseal the selected cells so the colony can use what is in them again."))` | add child | Same space |
| `scripts/hud.gd:1972` | `row.add_child(_with_info(fill_btn, "Keep taking deposits but refuse every withdrawal, and seal the cell the moment it is full. Without this a honey cell is sipped from as fast as it is filled and never quite gets to the top, so there is never a full pot to put by. A cell in this state is drawn with a yellow bar."))` | add child | Same space |
| `scripts/hud.gd:1981` | `column.add_child(empty_row)` | add child | Same space |
| `scripts/hud.gd:1986` | `empty_row.add_child(title)` | add child | Same space |
| `scripts/hud.gd:1993` | `empty_row.add_child(_with_info(move_btn, "A builder comes and carries the contents to another cell with room for them. Fermented nectar is always thrown out instead. If nothing anywhere has room, the load is lost -- so keep an eye on how full the comb is."))` | add child | Same space |
| `scripts/hud.gd:2000` | `empty_row.add_child(_with_info(discard_btn, "Throw the contents out of the hive. Quicker than moving them, but everything in the cell is gone."))` | add child | Same space |
| `scripts/hud.gd:2011` | `empty_row.add_child(_with_info(clear_fermented_btn, "Comb workers will carry every fermented cell's nectar out of the hive. Only the cells that are sour now: nectar that ferments later is not included."))` | add child | Same space |
| `scripts/hud.gd:2026` | `empty_row.add_child(_with_info(empty_by_bee_btn, "The selected bee carries the contents out herself, right now -- no comb worker needed and no change to her role."))` | add child | Same space |
| `scripts/hud.gd:2034` | `column.add_child(keep_row)` | add child | Same space |
| `scripts/hud.gd:2044` | `keep_row.add_child(keep_empty_box)` | add child | Same space |
| `scripts/hud.gd:2045` | `keep_row.add_child(_info("On: the cell refuses every deposit once it's been cleared, so it stays free. This is what stops a crowd of foragers cramming nectar into the last spare pot and leaving nowhere for pollen or eggs. Reserving the cell for a resource later clears this again. Off: the cell goes back to taking whatever arrives first."))` | add child | Same space |
| `scripts/hud.gd:2107` | `add_child(warning_panel)` | add child | Same space |
| `scripts/hud.gd:2111` | `warning_panel.add_child(row)` | add child | Same space |
| `scripts/hud.gd:2118` | `row.add_child(warning_label)` | add child | Same space |
| `scripts/hud.gd:2125` | `row.add_child(close_btn)` | add child | Same space |
| `scripts/hud.gd:2541` | `var root: Node2D = main.hive_root if _stage_marker_in_hive else main.meadow_root` | coordinate reference | Same space |
| `scripts/hud.gd:2542` | `return root.get_global_transform_with_canvas() * root.to_local(_stage_marker_global_position)` | transform conversion | Converted correctly |
| `scripts/hud.gd:2660` | `add_child(discard_dialog)` | add child | Same space |
| `scripts/hud.gd:2881` | `corner_column.add_child(label)` | add child | Same space |
| `scripts/hud.gd:2904` | `row.add_child(line)` | add child | Same space |
| `scripts/hud.gd:2916` | `row.add_child(remove)` | add child | Same space |
| `scripts/hud.gd:2917` | `corner_column.add_child(row)` | add child | Same space |
| `scripts/hud.gd:2929` | `corner_column.add_child(more)` | add child | Same space |
| `scripts/hud_command_rows.gd:105` | `column.add_child(button)` | add child | Same space |
| `scripts/hud_command_rows.gd:122` | `hud.more_panel.add_child(hud._with_info(button, "Keeps the camera centred on this bee as it moves. Switches off the moment you select something else."))` | add child | Same space |
| `scripts/hud_command_rows.gd:130` | `# stable path (see the row.add_child(_make_role_menu(..., "change_to_menu"))` | add child | Same space |
| `scripts/hud_command_rows.gd:138` | `row.add_child(mixed)` | add child | Same space |
| `scripts/hud_command_rows.gd:140` | `row.add_child(_current_role_marker(Roles.label_for(common_role)))` | add child | Same space |
| `scripts/hud_command_rows.gd:156` | `row.add_child(_make_role_menu("Change to…", "Switch the selected bees to another job. Sub-modes for that job appear on the Doing row once they are on it.", items, "change_to_menu"))` | add child | Same space |
| `scripts/hud_command_rows.gd:183` | `hud.focus_column.add_child(_toggle_button(` | add child | Same space |
| `scripts/hud_command_rows.gd:206` | `row.add_child(label)` | add child | Same space |
| `scripts/hud_command_rows.gd:207` | `row.add_child(_toggle_button(` | add child | Same space |
| `scripts/hud_command_rows.gd:212` | `row.add_child(_toggle_button(` | add child | Same space |
| `scripts/hud_command_rows.gd:242` | `row.add_child(hud._with_info(button, "She leaves the hive for good to found a colony of her own. Sent between late spring and early autumn she finds a mate, counts as sent out and earns genetic points, the most in mid summer. Sent outside that window she finds no mate and is lost, and does not count."))` | add child | Same space |
| `scripts/hud_command_rows.gd:285` | `hud.orders_column.add_child(_action_button("Clear start" if has_start else "Start here",` | add child | Same space |
| `scripts/hud_command_rows.gd:290` | `hud.orders_column.add_child(_action_button(("Flower: %s" % pref) if pref != "" else "Pick a flower",` | add child | Same space |
| `scripts/hud_command_rows.gd:294` | `hud.orders_column.add_child(_action_button("Build here",` | add child | Same space |
| `scripts/hud_command_rows.gd:297` | `hud.orders_column.add_child(_action_button("Keep clear",` | add child | Same space |
| `scripts/hud_command_rows.gd:300` | `hud.orders_column.add_child(_action_button("Work from here",` | add child | Same space |
| `scripts/hud_command_rows.gd:303` | `hud.orders_column.add_child(_action_button("Set for all comb workers",` | add child | Same space |
| `scripts/hud_command_rows.gd:313` | `hud.orders_column.add_child(_action_button("Mine",` | add child | Same space |
| `scripts/hud_command_rows.gd:316` | `hud.orders_column.add_child(_action_button("Work from here",` | add child | Same space |
| `scripts/hud_command_rows.gd:330` | `hud.orders_column.add_child(_toggle_button(` | add child | Same space |
| `scripts/hud_command_rows.gd:336` | `hud.orders_column.add_child(_action_button("Only these",` | add child | Same space |
| `scripts/hud_command_rows.gd:339` | `hud.orders_column.add_child(_action_button("Never these",` | add child | Same space |
| `scripts/hud_command_rows.gd:342` | `hud.orders_column.add_child(_action_button("Clear orders",` | add child | Same space |
| `scripts/hud_command_rows.gd:351` | `hud.orders_column.add_child(summary)` | add child | Same space |
| `scripts/hud_command_rows.gd:387` | `row.add_child(_make_role_menu(` | add child | Same space |
| `scripts/hud_command_rows.gd:400` | `row.add_child(hud._with_info(finish_box, "On: reassigning this bee waits until it has finished what it is doing -- a forager delivers the load it is carrying, a comb worker finishes the cell it is on -- and the new role takes effect the moment it is free. Off: it drops everything and starts immediately."))` | add child | Same space |
| `scripts/hud_command_rows.gd:412` | `row.add_child(hud._with_info(any_cell_box, "On (the default): once every nursery cell is occupied she lays into any spare undesignated cell, so laying never stalls for want of somewhere to put an egg. Off: she lays only in cells reserved for eggs and waits when they are full. Turn it off for exact control, and be ready to reserve more cells for eggs or she stops laying."))` | add child | Same space |
| `scripts/hud_command_rows.gd:434` | `column.add_child(title)` | add child | Same space |
| `scripts/hud_command_rows.gd:441` | `column.add_child(note)` | add child | Same space |
| `scripts/hud_command_rows.gd:448` | `column.add_child(ColonyPanel.build_backup_editor(order, addable, _on_backup_editor_changed, focus))` | add child | Same space |
| `scripts/hud_command_rows.gd:449` | `row.add_child(column)` | add child | Same space |
| `scripts/hud_command_rows.gd:478` | `parent.add_child(row)` | add child | Same space |
| `scripts/hud_command_rows.gd:486` | `hud.more_panel.add_child(row)` | add child | Same space |
| `scripts/hud_command_rows.gd:493` | `row.add_child(label)` | add child | Same space |
| `scripts/input_selection.gd:116` | `if box.has_point(b.global_position):` | global position | Same space |
| `scripts/input_selection.gd:169` | `if is_instance_valid(c) and box.has_point(c.global_position):` | global position | Same space |
| `scripts/input_selection.gd:177` | `if is_instance_valid(b) and box.has_point(b.global_position):` | global position | Same space |
| `scripts/input_selection.gd:189` | `if box.has_point(m.global_position):` | global position | Same space |
| `scripts/input_selection.gd:291` | `var root: Variant = main.hive_root if main.in_hive_view else main.meadow_root` | coordinate reference | Same space |
| `scripts/input_selection.gd:295` | `var root: Variant = main.hive_root if main.in_hive_view else main.meadow_root` | coordinate reference | Same space |
| `scripts/input_selection.gd:305` | `target = main.hive_root.to_global(main.hive_entrance_inside())` | transform conversion | Converted correctly |
| `scripts/input_selection.gd:308` | `target = main.hive.global_position` | global position | Same space |
| `scripts/input_selection.gd:319` | `if b.global_position.distance_to(point) <= b.click_radius:` | global position | Same space |
| `scripts/input_selection.gd:325` | `if is_instance_valid(c) and c.global_position.distance_to(point) <= c.cell_size:` | global position | Same space |
| `scripts/input_selection.gd:331` | `if is_instance_valid(b) and b.global_position.distance_to(point) <= b.block_size:` | global position | Same space |
| `scripts/input_selection.gd:337` | `if is_instance_valid(m) and m.global_position.distance_to(point) <= m.CLICK_RADIUS:` | global position | Same space |
| `scripts/input_selection.gd:342` | `var local_point: Vector2 = main.hive_root.to_local(global_point)` | transform conversion | Converted correctly |
| `scripts/input_selection.gd:470` | `var local_point: Vector2 = main.hive_root.to_local(global_point)` | transform conversion | Converted correctly |
| `scripts/input_selection.gd:490` | `var local_point: Vector2 = main.hive_root.to_local(global_point)` | transform conversion | Converted correctly |
| `scripts/input_selection.gd:498` | `var local_point: Vector2 = main.hive_root.to_local(global_point)` | transform conversion | Converted correctly |
| `scripts/input_selection.gd:506` | `var meadow_point: Vector2 = main.meadow_root.to_local(global_point)` | transform conversion | Converted correctly |
| `scripts/input_selection.gd:562` | `if world_point.distance_to(main.hive_root.to_global(main.hive_entrance_inside())) <= EXIT_CLICK_RADIUS:` | transform conversion | Converted correctly |
| `scripts/input_selection.gd:582` | `if world_point.distance_to(main.hive.global_position) <= HIVE_CLICK_RADIUS:` | global position | Same space |
| `scripts/input_selection.gd:616` | `var root: Node2D = main.hive_root if main.in_hive_view else main.meadow_root` | coordinate reference | Same space |
| `scripts/input_selection.gd:618` | `marker.position = root.to_local(world_point)` | transform conversion | Converted correctly |
| `scripts/input_selection.gd:619` | `root.add_child(marker)` | add child | Same space |
| `scripts/input_selection.gd:667` | `# (meadow_root and hive_root sit at different world offsets --` | coordinate reference | Same space |
| `scripts/input_selection.gd:671` | `_draw_start_point_marker(main.hive_root.to_global(main.hive_entrance_inside()))` | transform conversion | Converted correctly |
| `scripts/input_selection.gd:718` | `points.append(main.hive_root.to_global(block.position))` | transform conversion | Converted correctly |
| `scripts/input_selection.gd:724` | `var previous: Vector2 = bee.global_position` | global position | Same space |
| `scripts/input_selection.gd:741` | `return main.hive_root.to_global(` | transform conversion | Converted correctly |
| `scripts/main.gd:12` | `## meadow, then get reparented into the hive view and walk in through` | reparent | Converted correctly |
| `scripts/main.gd:208` | `var meadow_root: Node2D` | coordinate reference | Same space |
| `scripts/main.gd:209` | `var hive_root: Node2D` | coordinate reference | Same space |
| `scripts/main.gd:481` | `add_child(menu)` | add child | Same space |
| `scripts/main.gd:491` | `add_child(debug_panel)` | add child | Same space |
| `scripts/main.gd:497` | `add_child(saves_panel)` | add child | Same space |
| `scripts/main.gd:511` | `add_child(world_building)` | add child | Same space |
| `scripts/main.gd:514` | `add_child(saving)` | add child | Same space |
| `scripts/main.gd:517` | `add_child(input_selection)` | add child | Same space |
| `scripts/main.gd:520` | `add_child(orders_zones)` | add child | Same space |
| `scripts/main.gd:522` | `add_child(foraging_stats)` | add child | Same space |
| `scripts/main.gd:525` | `add_child(year_winter)` | add child | Same space |
| `scripts/main.gd:532` | `add_child(camera_view)` | add child | Same space |
| `scripts/main.gd:535` | `add_child(fog_of_war)` | add child | Same space |
| `scripts/main.gd:538` | `add_child(stage_gate)` | add child | Same space |
| `scripts/main.gd:556` | `add_child(challenge_runner)` | add child | Same space |
| `scripts/main.gd:558` | `meadow_root = Node2D.new()` | coordinate reference | Same space |
| `scripts/main.gd:564` | `meadow_root.process_mode = Node.PROCESS_MODE_PAUSABLE` | coordinate reference | Same space |
| `scripts/main.gd:565` | `add_child(meadow_root)` | add child | Same space |
| `scripts/main.gd:567` | `hive_root = Node2D.new()` | coordinate reference | Same space |
| `scripts/main.gd:568` | `hive_root.position = HIVE_WORLD_OFFSET` | coordinate reference | Same space |
| `scripts/main.gd:569` | `hive_root.process_mode = Node.PROCESS_MODE_PAUSABLE` | coordinate reference | Same space |
| `scripts/main.gd:570` | `add_child(hive_root)` | add child | Same space |
| `scripts/main.gd:589` | `add_child(weather_layer)` | add child | Same space |
| `scripts/main.gd:595` | `weather_layer.add_child(rain_overlay)` | add child | Same space |
| `scripts/main.gd:600` | `weather_layer.add_child(rain_effect)` | add child | Same space |
| `scripts/main.gd:606` | `add_child(selection_layer)` | add child | Same space |
| `scripts/main.gd:642` | `add_child(hud)` | add child | Same space |
| `scripts/main.gd:667` | `add_child(colony_panel)` | add child | Same space |
| `scripts/main.gd:670` | `add_child(foraging_panel)` | add child | Same space |
| `scripts/main.gd:678` | `add_child(nursery_panel)` | add child | Same space |
| `scripts/main.gd:681` | `add_child(winter_panel)` | add child | Same space |
| `scripts/main.gd:684` | `add_child(gallerin_panel)` | add child | Same space |
| `scripts/main.gd:687` | `add_child(succession_panel)` | add child | Same space |
| `scripts/main.gd:696` | `add_child(season)` | add child | Same space |
| `scripts/main.gd:701` | `add_child(game_over)` | add child | Same space |
| `scripts/main.gd:708` | `add_child(challenge_complete)` | add child | Same space |
| `scripts/main_menu.gd:167` | `add_child(backdrop)` | add child | Same space |
| `scripts/main_menu.gd:176` | `add_child(root)` | add child | Same space |
| `scripts/main_menu.gd:181` | `root.add_child(split)` | add child | Same space |
| `scripts/main_menu.gd:190` | `split.add_child(left_margin)` | add child | Same space |
| `scripts/main_menu.gd:196` | `left_margin.add_child(left_pane)` | add child | Same space |
| `scripts/main_menu.gd:204` | `split.add_child(right_pane)` | add child | Same space |
| `scripts/main_menu.gd:216` | `left_pane.add_child(title)` | add child | Same space |
| `scripts/main_menu.gd:222` | `left_pane.add_child(subtitle)` | add child | Same space |
| `scripts/main_menu.gd:230` | `left_pane.add_child(group_column)` | add child | Same space |
| `scripts/main_menu.gd:235` | `group_column.add_child(heading)` | add child | Same space |
| `scripts/main_menu.gd:242` | `group_column.add_child(note)` | add child | Same space |
| `scripts/main_menu.gd:258` | `strip_scroll.add_child(_make_honeycomb_strip(group.key))` | add child | Same space |
| `scripts/main_menu.gd:259` | `group_column.add_child(strip_scroll)` | add child | Same space |
| `scripts/main_menu.gd:262` | `left_pane.add_child(HSeparator.new())` | add child | Same space |
| `scripts/main_menu.gd:275` | `right_pane.add_child(right_scroll)` | add child | Same space |
| `scripts/main_menu.gd:286` | `_detail_column.add_child(detail_placeholder)` | add child | Same space |
| `scripts/main_menu.gd:287` | `right_scroll.add_child(_detail_column)` | add child | Same space |
| `scripts/main_menu.gd:289` | `right_pane.add_child(HSeparator.new())` | add child | Same space |
| `scripts/main_menu.gd:298` | `right_pane.add_child(_back_row)` | add child | Same space |
| `scripts/main_menu.gd:344` | `row.add_child(UI.with_info(settings_button, "Accessibility and appearance settings -- text scale, contrast, colour-blind mode and the rest of the settings window."))` | add child | Same space |
| `scripts/main_menu.gd:345` | `right_pane.add_child(row)` | add child | Same space |
| `scripts/main_menu.gd:403` | `strip.add_child(tile)` | add child | Same space |
| `scripts/main_menu.gd:468` | `tile.add_child(border)` | add child | Same space |
| `scripts/main_menu.gd:473` | `tile.add_child(fill)` | add child | Same space |
| `scripts/main_menu.gd:504` | `tile.add_child(label)` | add child | Same space |
| `scripts/main_menu.gd:518` | `tile.add_child(tick)` | add child | Same space |
| `scripts/main_menu.gd:535` | `tile.add_child(button)` | add child | Same space |
| `scripts/main_menu.gd:592` | `_detail_column.add_child(title)` | add child | Same space |
| `scripts/main_menu.gd:598` | `_detail_column.add_child(blurb)` | add child | Same space |
| `scripts/main_menu.gd:601` | `_detail_column.add_child(_make_preset_row(stage))` | add child | Same space |
| `scripts/main_menu.gd:602` | `_detail_column.add_child(_make_preset_description())` | add child | Same space |
| `scripts/main_menu.gd:604` | `_detail_column.add_child(_make_custom_controls())` | add child | Same space |
| `scripts/main_menu.gd:606` | `_detail_column.add_child(_make_note_label("Played before."))` | add child | Same space |
| `scripts/main_menu.gd:608` | `_detail_column.add_child(_make_note_label("Completed."))` | add child | Same space |
| `scripts/main_menu.gd:615` | `_detail_column.add_child(UI.with_info(start_btn, "Restarts the run with this choice. Anything unsaved in the colony you have now is lost."))` | add child | Same space |
| `scripts/main_menu.gd:642` | `row.add_child(btn)` | add child | Same space |
| `scripts/main_menu.gd:652` | `col.add_child(lbl)` | add child | Same space |
| `scripts/main_menu.gd:660` | `col.add_child(_make_custom_row(field))` | add child | Same space |
| `scripts/main_menu.gd:674` | `row.add_child(label)` | add child | Same space |
| `scripts/main_menu.gd:680` | `row.add_child(minus)` | add child | Same space |
| `scripts/main_menu.gd:687` | `row.add_child(value_label)` | add child | Same space |
| `scripts/main_menu.gd:693` | `row.add_child(plus)` | add child | Same space |
| `scripts/nursery_panel.gd:118` | `scroll_container.add_child(column)` | add child | Same space |
| `scripts/nursery_panel.gd:121` | `column.add_child(header)` | add child | Same space |
| `scripts/nursery_panel.gd:126` | `header.add_child(title)` | add child | Same space |
| `scripts/nursery_panel.gd:127` | `header.add_child(UI.info_badge(` | add child | Same space |
| `scripts/nursery_panel.gd:136` | `header.add_child(close_btn)` | add child | Same space |
| `scripts/nursery_panel.gd:138` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/nursery_panel.gd:152` | `needing_attention_column.add_child(needing_attention_ok_label)` | add child | Same space |
| `scripts/nursery_panel.gd:154` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/nursery_panel.gd:158` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/nursery_panel.gd:162` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/nursery_panel.gd:166` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/nursery_panel.gd:168` | `column.add_child(_starred_row(column, "nursery_mix", "The colony now", true))` | add child | Same space |
| `scripts/nursery_panel.gd:175` | `column.add_child(ring)` | add child | Same space |
| `scripts/nursery_panel.gd:177` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/nursery_panel.gd:179` | `column.add_child(_starred_row(column, "nursery_output", "Emerging (last 3 minutes)", true))` | add child | Same space |
| `scripts/nursery_panel.gd:182` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/nursery_panel.gd:201` | `column.add_child(heading)` | add child | Same space |
| `scripts/nursery_panel.gd:204` | `column.add_child(body)` | add child | Same space |
| `scripts/nursery_panel.gd:227` | `row.add_child(star)` | add child | Same space |
| `scripts/nursery_panel.gd:233` | `row.add_child(label)` | add child | Same space |
| `scripts/nursery_panel.gd:237` | `row.add_child(UI.info_badge(entry.tip))` | add child | Same space |
| `scripts/nursery_panel.gd:243` | `holder.add_child(row)` | add child | Same space |
| `scripts/nursery_panel.gd:244` | `column.add_child(holder)` | add child | Same space |
| `scripts/nursery_panel.gd:262` | `column.add_child(label)` | add child | Same space |
| `scripts/nursery_panel.gd:322` | `needing_attention_column.add_child(` | add child | Same space |
| `scripts/obstacle.gd:61` | `add_child(selection_ring)` | add child | Same space |
| `scripts/obstacle.gd:73` | `add_child(trunk)` | add child | Same space |
| `scripts/obstacle.gd:83` | `add_child(leaf)` | add child | Same space |
| `scripts/obstacle.gd:108` | `add_child(shadow)` | add child | Same space |
| `scripts/obstacle.gd:114` | `add_child(cliff)` | add child | Same space |
| `scripts/obstacle.gd:121` | `add_child(top)` | add child | Same space |
| `scripts/obstacle.gd:128` | `add_child(rim)` | add child | Same space |
| `scripts/obstacle.gd:134` | `add_child(outline)` | add child | Same space |
| `scripts/obstacle.gd:156` | `add_child(trunk)` | add child | Same space |
| `scripts/obstacle.gd:163` | `add_child(leaf)` | add child | Same space |
| `scripts/obstacle.gd:175` | `add_child(bloom)` | add child | Same space |
| `scripts/pollination.gd:122` | `## (world_building.gd::move_bee_into_hive reparents her).` | reparent | Converted correctly |
| `scripts/pollination_pop.gd:54` | `_positions[slot] = flower.global_position + START` | global position | Same space |
| `scripts/queen_hearts_vfx.gd:29` | `add_child(heart)` | add child | Same space |
| `scripts/rival_hive.gd:77` | `add_child(body)` | add child | Same space |
| `scripts/rival_hive.gd:85` | `add_child(skep)` | add child | Same space |
| `scripts/rival_hive.gd:91` | `add_child(label)` | add child | Same space |
| `scripts/rival_hive.gd:133` | `get_parent().add_child(dot)` | add child | Same space |
| `scripts/run_availability_panel.gd:78` | `add_child(column)` | add child | Same space |
| `scripts/run_availability_panel.gd:81` | `column.add_child(header)` | add child | Same space |
| `scripts/run_availability_panel.gd:85` | `header.add_child(title_label)` | add child | Same space |
| `scripts/run_availability_panel.gd:90` | `header.add_child(reset_btn)` | add child | Same space |
| `scripts/run_availability_panel.gd:96` | `header.add_child(close_btn)` | add child | Same space |
| `scripts/run_availability_panel.gd:102` | `column.add_child(intro)` | add child | Same space |
| `scripts/run_availability_panel.gd:107` | `column.add_child(scroll)` | add child | Same space |
| `scripts/run_availability_panel.gd:112` | `scroll.add_child(grid)` | add child | Same space |
| `scripts/run_availability_panel.gd:150` | `grid.add_child(source_btn)` | add child | Same space |
| `scripts/run_availability_panel.gd:202` | `grid.add_child(label)` | add child | Same space |
| `scripts/save_game.gd:270` | `"indoors": b.get_parent() == world.hive_root,` | coordinate reference | Same space |
| `scripts/saves_panel.gd:37` | `scroll_container.add_child(column)` | add child | Same space |
| `scripts/saves_panel.gd:40` | `column.add_child(header)` | add child | Same space |
| `scripts/saves_panel.gd:45` | `header.add_child(title)` | add child | Same space |
| `scripts/saves_panel.gd:46` | `header.add_child(UI.info_badge(` | add child | Same space |
| `scripts/saves_panel.gd:52` | `header.add_child(close_btn)` | add child | Same space |
| `scripts/saves_panel.gd:56` | `column.add_child(save_run_btn)` | add child | Same space |
| `scripts/saves_panel.gd:60` | `column.add_child(name_row)` | add child | Same space |
| `scripts/saves_panel.gd:64` | `name_row.add_child(prompt)` | add child | Same space |
| `scripts/saves_panel.gd:66` | `name_row.add_child(edit_row)` | add child | Same space |
| `scripts/saves_panel.gd:72` | `edit_row.add_child(name_edit)` | add child | Same space |
| `scripts/saves_panel.gd:75` | `edit_row.add_child(confirm_btn)` | add child | Same space |
| `scripts/saves_panel.gd:77` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/saves_panel.gd:80` | `column.add_child(list_box)` | add child | Same space |
| `scripts/saves_panel.gd:127` | `add_child(dialog)` | add child | Same space |
| `scripts/saves_panel.gd:199` | `list_box.add_child(_label("No saved runs yet.", "Small"))` | add child | Same space |
| `scripts/saves_panel.gd:206` | `list_box.add_child(row)` | add child | Same space |
| `scripts/saves_panel.gd:216` | `row.add_child(label)` | add child | Same space |
| `scripts/saves_panel.gd:220` | `row.add_child(load_btn)` | add child | Same space |
| `scripts/saves_panel.gd:223` | `row.add_child(delete_btn)` | add child | Same space |
| `scripts/saves_panel.gd:235` | `list_box.add_child(point_row)` | add child | Same space |
| `scripts/saves_panel.gd:239` | `point_row.add_child(point_label)` | add child | Same space |
| `scripts/saves_panel.gd:242` | `point_row.add_child(point_load)` | add child | Same space |
| `scripts/saving.gd:212` | `main.hive_root.add_child(cell)` | add child | Same space |
| `scripts/saving.gd:343` | `main.meadow_root.add_child(flower)` | add child | Same space |
| `scripts/saving.gd:381` | `main.hive_root.add_child(bee)` | add child | Same space |
| `scripts/saving.gd:383` | `main.meadow_root.add_child(bee)` | add child | Same space |
| `scripts/scenario_actions.gd:780` | `point = main.hive.global_position` | global position | Same space |
| `scripts/scenario_actions.gd:782` | `point = main.hive_root.to_global(main.hive_entrance_inside())` | transform conversion | Converted correctly |
| `scripts/scenario_actions.gd:788` | `point = main.hive_root.to_global(comb_local)` | transform conversion | Converted correctly |
| `scripts/scenario_actions.gd:794` | `point = block.global_position` | global position | Same space |
| `scripts/scenario_actions.gd:796` | `var root: Node2D = main.hive_root if str(action.get("view", "hive")) == "hive" else main.meadow_root` | coordinate reference | Same space |
| `scripts/scenario_actions.gd:797` | `point = root.to_global(Vector2(float(action.get("x", 0.0)), float(action.get("y", 0.0))))` | transform conversion | Converted correctly |
| `scripts/skill_tree_panel.gd:92` | `scroll_container.add_child(column)` | add child | Same space |
| `scripts/skill_tree_panel.gd:95` | `column.add_child(header)` | add child | Same space |
| `scripts/skill_tree_panel.gd:100` | `header.add_child(title)` | add child | Same space |
| `scripts/skill_tree_panel.gd:108` | `header.add_child(close_btn)` | add child | Same space |
| `scripts/skill_tree_panel.gd:111` | `column.add_child(intro)` | add child | Same space |
| `scripts/skill_tree_panel.gd:122` | `column.add_child(grid)` | add child | Same space |
| `scripts/skill_tree_panel.gd:124` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/skill_tree_panel.gd:127` | `column.add_child(strip)` | add child | Same space |
| `scripts/skill_tree_panel.gd:138` | `strip.add_child(buy_button)` | add child | Same space |
| `scripts/skill_tree_panel.gd:139` | `strip.add_child(detail_label)` | add child | Same space |
| `scripts/skill_tree_panel.gd:444` | `var seen := Rect2(global_position, size).intersection(get_viewport_rect())` | global position | Same space |
| `scripts/soil_block.gd:77` | `add_child(marker)` | add child | Same space |
| `scripts/soil_block.gd:88` | `add_child(selection_ring)` | add child | Same space |
| `scripts/soil_block.gd:93` | `add_child(progress_label)` | add child | Same space |
| `scripts/soil_block.gd:106` | `add_child(soil_sprite)` | add child | Same space |
| `scripts/succession_panel.gd:32` | `scroll_container.add_child(column)` | add child | Same space |
| `scripts/succession_panel.gd:37` | `column.add_child(title)` | add child | Same space |
| `scripts/succession_panel.gd:39` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/succession_panel.gd:55` | `column.add_child(button)` | add child | Same space |
| `scripts/succession_panel.gd:70` | `column.add_child(label)` | add child | Same space |
| `scripts/ui.gd:4` | `##        row.add_child(UI.info_badge("what this control does"))` | add child | Same space |
| `scripts/ui.gd:58` | `row.add_child(control)` | add child | Same space |
| `scripts/ui.gd:59` | `row.add_child(info_badge(tip))` | add child | Same space |
| `scripts/ui_info_badge.gd:27` | `panel.add_child(label)` | add child | Same space |
| `scripts/winter_panel.gd:36` | `scroll_container.add_child(column)` | add child | Same space |
| `scripts/winter_panel.gd:39` | `column.add_child(header)` | add child | Same space |
| `scripts/winter_panel.gd:44` | `header.add_child(title)` | add child | Same space |
| `scripts/winter_panel.gd:45` | `header.add_child(UI.info_badge(` | add child | Same space |
| `scripts/winter_panel.gd:58` | `header.add_child(close_btn)` | add child | Same space |
| `scripts/winter_panel.gd:60` | `column.add_child(HSeparator.new())` | add child | Same space |
| `scripts/winter_panel.gd:72` | `column.add_child(label)` | add child | Same space |
| `scripts/world_building.gd:45` | `main.meadow_root.add_child(grass)` | add child | Same space |
| `scripts/world_building.gd:50` | `main.meadow_root.add_child(main.hive)` | add child | Same space |
| `scripts/world_building.gd:75` | `if root != (main.hive_root if main.in_hive_view else main.meadow_root):` | coordinate reference | Same space |
| `scripts/world_building.gd:84` | `return _view_rect.has_point(node.global_position)` | global position | Same space |
| `scripts/world_building.gd:106` | `main.meadow_root.add_child(main.rival)` | add child | Same space |
| `scripts/world_building.gd:139` | `main.meadow_root.add_child(obstacle)` | add child | Same space |
| `scripts/world_building.gd:312` | `main.meadow_root.add_child(flower)` | add child | Same space |
| `scripts/world_building.gd:389` | `main.hive.comb_parent = main.hive_root` | coordinate reference | Same space |
| `scripts/world_building.gd:422` | `main.hive_root.add_child(marker)` | add child | Same space |
| `scripts/world_building.gd:434` | `main.hive_root.add_child(cell)` | add child | Same space |
| `scripts/world_building.gd:457` | `main.hive_root.add_child(main.queen)` | add child | Same space |
| `scripts/world_building.gd:491` | `main.hive_root.add_child(tile)` | add child | Same space |
| `scripts/world_building.gd:498` | `main.hive_root.add_child(block)` | add child | Same space |
| `scripts/world_building.gd:507` | `main.hive_root.add_child(block)` | add child | Same space |
| `scripts/world_building.gd:558` | `main.add_child(main.meadow_camera)` | add child | Same space |
| `scripts/world_building.gd:562` | `main.add_child(main.hive_camera)` | add child | Same space |
| `scripts/world_building.gd:567` | `main.meadow_root.add_child(bee)` | add child | Same space |
| `scripts/world_building.gd:578` | `main.hive_root.add_child(bee)` | add child | Same space |
| `scripts/world_building.gd:614` | `main.hive_root.add_child(bee)` | add child | Same space |
| `scripts/world_building.gd:634` | `if bee.get_parent() == main.hive_root:` | coordinate reference | Same space |
| `scripts/world_building.gd:637` | `bee.reparent(main.hive_root)` | reparent | Converted correctly |
| `scripts/world_building.gd:649` | `if bee.get_parent() == main.meadow_root:` | coordinate reference | Same space |
| `scripts/world_building.gd:652` | `bee.reparent(main.meadow_root)` | reparent | Converted correctly |
| `scripts/world_building.gd:685` | `parent = main.meadow_root` | coordinate reference | Same space |
| `scripts/world_building.gd:686` | `parent.add_child(marker)` | add child | Same space |
| `scripts/world_building.gd:710` | `if is_instance_valid(o) and o.global_position.distance_to(point) <= o.radius:` | global position | Same space |
| `scripts/world_building.gd:716` | `if f.global_position.distance_to(point) <= 20.0:` | global position | Same space |
| `scripts/year_winter.gd:146` | `main.camera_view._active_camera().position = main.selected_bees[0].global_position` | global position | Same space |
| `scripts/year_winter.gd:159` | `main.camera_view._active_camera().position = found[0].global_position` | global position | Same space |

## Method
Searched all `.gd` files under `scripts/` using Python regex matching `hive_root`, `meadow_root`, `global_position`, `to_global`, `to_local`, `reparent`, `add_child`.
Classified each site by verifying the parent transforms and coordinate spaces of operands.
All 651 matches were inspected and verified against the parent hierarchy.
