# Audit: Control rectangle and minimum-size writes

Audited: be89c673 on 2026-10-27 | Task: J-30 | Scope: scripts/ (209 GDScript files)

## Summary

Read 209 GDScript files under `scripts/`. Identified 103 geometry write sites across Control and Node2D objects, 3 `HFlowContainer` child sizing sites, 1 Label with combined autowrap/clip_text, 2 autowrap Labels in HBoxContainers lacking expand flags, and 1 Control rectangle written across multiple functions. Found 5 issues (0 high, 3 medium, 2 low severity):

1. `scripts/hud.gd:1555`: `column` child of `command_columns` (`HFlowContainer`) sets `SIZE_EXPAND_FILL`, risking layout expansion and wrapping distortion in flow containers.
2. `scripts/hud.gd:1778`: `wrapper` child of `cell_primary_columns` and `cell_more_panel` (`HFlowContainer`s) sets `SIZE_EXPAND_FILL`, conflicting with flow wrapping logic.
3. `scripts/hud.gd:3570`: `button` returned by `_toggle_button` sets `SIZE_EXPAND_FILL` and is added to `_labelled_row` / `_column_row` (`HFlowContainer`s).
4. `scripts/colony_panel.gd:242`: autowrap `label` added to `HBoxContainer` without `SIZE_EXPAND_FILL` or wrapper expansion, relying on fixed custom minimum width.
5. `scripts/hud.gd:2116`: autowrap `warning_label` added to `HBoxContainer` without `SIZE_EXPAND_FILL`, relying on fixed custom minimum width.

## Findings

| # | Where (path:line) | What | Why it matters | Confidence | Fix |
|---|---|---|---|---|---|
| 1 | `scripts/hud.gd:1555` | `column.size_flags_horizontal = Control.SIZE_EXPAND_FILL` on child of `HFlowContainer` | `docs/known-pitfalls.md` § "UI layout and theme": giving `SIZE_EXPAND_FILL` to `HFlowContainer` children forces full-width expansion and prevents flow wrapping | High | Remove `SIZE_EXPAND_FILL` on flow column children or use standard containers for fixed column layouts |
| 2 | `scripts/hud.gd:1778` | `wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL` on child of `HFlowContainer` | `docs/known-pitfalls.md` § "UI layout and theme": flow container children with expand flags override flow wrapping | High | Remove `SIZE_EXPAND_FILL` or replace outer container with a non-flowing box container if expansion is intended |
| 3 | `scripts/hud.gd:3570` | `_toggle_button` sets `size_flags_horizontal = Control.SIZE_EXPAND_FILL` for items added to `_labelled_row` / `_column_row` (`HFlowContainer`) | `docs/known-pitfalls.md` § "UI layout and theme": expanding items inside `HFlowContainer` prevent multi-item row wrapping on narrow viewports | High | Remove `size_flags_horizontal` expand setting on toggle buttons inside flow rows |
| 4 | `scripts/colony_panel.gd:242` | Autowrap `label` in `HBoxContainer` without `SIZE_EXPAND_FILL` | `docs/known-pitfalls.md` § "UI layout and theme": autowrap labels in horizontal containers without `SIZE_EXPAND_FILL` collapse or require artificial minimum width | Medium | Add `size_flags_horizontal = Control.SIZE_EXPAND_FILL` to the autowrap label or wrap in an expanding container |
| 5 | `scripts/hud.gd:2116` | Autowrap `warning_label` in `HBoxContainer` without `SIZE_EXPAND_FILL` | `docs/known-pitfalls.md` § "UI layout and theme": autowrap labels in HBox containers without expansion can squeeze or overflow at varied resolutions | Medium | Set `size_flags_horizontal = Control.SIZE_EXPAND_FILL` on `warning_label` |

## Candidate Jules tasks

### J-? -- Source check: HFlowContainer child size_flags_horizontal
- Files: tests/source_checks.py
- After: none
- Why: `docs/known-pitfalls.md` § "UI layout and theme": `HFlowContainer` children given `SIZE_EXPAND_FILL` break flow wrapping. A source check prevents new instances.
- Do: add a check to `tests/source_checks.py` scanning `.gd` files under `scripts/` to verify no child added to an `HFlowContainer` sets `size_flags_horizontal = Control.SIZE_EXPAND_FILL`.

```
free  tests/source_checks.py
```

### J-? -- Source check: Autowrap Label in HBoxContainer expansion
- Files: tests/source_checks.py
- After: none
- Why: `docs/known-pitfalls.md` § "UI layout and theme": autowrap Labels in horizontal box containers collapse to zero width unless given `SIZE_EXPAND_FILL`.
- Do: add a check to `tests/source_checks.py` asserting autowrap Labels placed inside `HBoxContainer` specify `SIZE_EXPAND_FILL`.

```
free  tests/source_checks.py
```

## For Claude or Codex

- `scripts/hud.gd:_build_tray_column`: `column.size_flags_horizontal` on `HFlowContainer` child (`plans/now/code-health.md`).
- `scripts/hud.gd:_build_cell_action_column`: `wrapper.size_flags_horizontal` on `HFlowContainer` child (`plans/now/code-health.md`).
- `scripts/hud.gd:_toggle_button`: `button.size_flags_horizontal` on `HFlowContainer` row (`plans/now/code-health.md`).
- `scripts/colony_panel.gd:_add_stat_row`: autowrap `label` in `HBoxContainer` without `SIZE_EXPAND_FILL` (`plans/now/code-health.md`).
- `scripts/hud.gd:_build_warning_panel`: autowrap `warning_label` in `HBoxContainer` without `SIZE_EXPAND_FILL` (`plans/now/code-health.md`).

## Inventory

| Site | Type / Context | Classification |
|---|---|---|
| `scripts/bee.gd:957` | `Label` on `Node2D` (bee) | Child laid out by world-space code |
| `scripts/bee.gd:1739` | `Node2D` (`position = tipsy_resume_point`) | Not a Control (Node2D position write) |
| `scripts/bee.gd:3122` | `Node2D` (`visual_root.position`) | Not a Control (Node2D position write) |
| `scripts/bee.gd:3125` | `Node2D` (`visual_root.position`) | Not a Control (Node2D position write) |
| `scripts/bee.gd:3147` | `Node2D` (`visual_root.position`) | Not a Control (Node2D position write) |
| `scripts/bee_movement.gd:373` | `Node2D` (`bee.position`) | Not a Control (Node2D position write) |
| `scripts/bee_movement.gd:396` | `Node2D` (`bee.position`) | Not a Control (Node2D position write) |
| `scripts/bee_movement.gd:400` | `Node2D` (`bee.position`) | Not a Control (Node2D position write) |
| `scripts/bee_movement.gd:403` | `Node2D` (`bee.position`) | Not a Control (Node2D position write) |
| `scripts/bee_speech_bubble.gd:55` | `Node2D` (`position = bee.position + OFFSET`) | Not a Control (Node2D position write) |
| `scripts/bee_survival.gd:386` | `Node2D` (`bee.position`) | Not a Control (Node2D position write) |
| `scripts/bee_survival.gd:392` | `Node2D` (`bee.position`) | Not a Control (Node2D position write) |
| `scripts/camera_view.gd:24` | `Camera2D` (`cam.position`) | Not a Control (Camera2D position write) |
| `scripts/camera_view.gd:76` | `Camera2D` (`cam.position`) | Not a Control (Camera2D position write) |
| `scripts/camera_view.gd:104` | `Camera2D` (`cam.position`) | Not a Control (Camera2D position write) |
| `scripts/camera_view.gd:142` | `Camera2D` (`_active_camera().position`) | Not a Control (Camera2D position write) |
| `scripts/challenge_runner.gd:235` | `Camera2D` (`main.hive_camera.position`) | Not a Control (Camera2D position write) |
| `scripts/challenge_runner.gd:627` | `Node2D` (`_marker.position`) | Not a Control (Node2D position write) |
| `scripts/challenge_runner.gd:654` | `Node2D` (`_marker.position`) | Not a Control (Node2D position write) |
| `scripts/challenge_runner.gd:659` | `Node2D` (`_marker.position`) | Not a Control (Node2D position write) |
| `scripts/challenge_runner.gd:665` | `Node2D` (`_marker.position`) | Not a Control (Node2D position write) |
| `scripts/challenge_runner.gd:962` | `Node2D` (`main.queen.position`) | Not a Control (Node2D position write) |
| `scripts/challenge_runner.gd:1097` | `Node2D` (`hearts.position`) | Not a Control (Node2D position write) |
| `scripts/challenge_runner.gd:1114` | `Node2D` (`_new_worker.position`) | Not a Control (Node2D position write) |
| `scripts/challenge_runner.gd:1117` | `Node2D` (`_new_worker.position`) | Not a Control (Node2D position write) |
| `scripts/challenge_stage_setup.gd:100` | `Node2D` (`queen.position`) | Not a Control (Node2D position write) |
| `scripts/challenge_stage_setup.gd:103` | `Node2D` (`queen.position`) | Not a Control (Node2D position write) |
| `scripts/challenge_stage_setup.gd:106` | `Node2D` (`queen.position`) | Not a Control (Node2D position write) |
| `scripts/challenge_stage_setup.gd:234` | `Node2D` (`bee.position`) | Not a Control (Node2D position write) |
| `scripts/flower.gd:168` | `Node2D` (`bush.position`) | Not a Control (Node2D position write) |
| `scripts/flower.gd:186` | `Node2D` (`crab_spider_marker.position`) | Not a Control (Node2D position write) |
| `scripts/flower.gd:214` | `Label` on `Node2D` (`nectar_label.position`) | Child laid out by world-space code |
| `scripts/flower.gd:219` | `Label` on `Node2D` (`pollen_label.position`) | Child laid out by world-space code |
| `scripts/gallerin_panel.gd:174` | `Polygon2D` (`wing_left.position`) | Not a Control (Polygon2D / Node2D position write) |
| `scripts/gallerin_panel.gd:182` | `Polygon2D` (`wing_right.position`) | Not a Control (Polygon2D / Node2D position write) |
| `scripts/gallerin_panel.gd:188` | `Polygon2D` (`body.position`) | Not a Control (Polygon2D / Node2D position write) |
| `scripts/gallerin_panel.gd:450` | `Polygon2D` (`_bubble_pointer.position`) | Not a Control (Polygon2D / Node2D position write) |
| `scripts/hive.gd:259` | `Sprite2D` (`skep.position`) | Not a Control (Sprite2D position write) |
| `scripts/hive.gd:780` | `Node2D` (`body.position`) | Not a Control (Node2D position write) |
| `scripts/hive.gd:926` | `Node2D` (`cell.position`) | Not a Control (Node2D position write) |
| `scripts/hive_cell.gd:513` | `Label` on `Node2D` (`info_label.position`) | Child laid out by world-space code |
| `scripts/hud.gd:626` | `VBoxContainer` on `CanvasLayer` (`corner_column.position`) | Child laid out by its own code |
| `scripts/hud.gd:703` | `Label` on `CanvasLayer` (`l.position`) | Child laid out by its own code |
| `scripts/hud.gd:2570` | `Polygon2D` (`stage_marker_arrow.position`) | Not a Control (Polygon2D position write) |
| `scripts/input_selection.gd:84` | `Camera2D` (`cam.position`) | Not a Control (Camera2D position write) |
| `scripts/input_selection.gd:618` | `Node2D` (`marker.position`) | Not a Control (Node2D position write) |
| `scripts/main.gd:568` | `Node2D` (`hive_root.position`) | Not a Control (Node2D position write) |
| `scripts/main_menu.gd:394` | `Control` (`strip.size = strip.custom_minimum_size`) | Transient popup or tooltip |
| `scripts/main_menu.gd:398` | `Control` (`tile.position`) | Child laid out by its own code |
| `scripts/main_menu.gd:415` | `int` local variable (`size -= 1`) | Not a Control (integer variable) |
| `scripts/main_menu.gd:456` | `Control` (`tile.size = bbox`) | Child laid out by its own code |
| `scripts/main_menu.gd:466` | `Polygon2D` (`border.position`) | Not a Control (Polygon2D position write) |
| `scripts/main_menu.gd:471` | `Polygon2D` (`fill.position`) | Not a Control (Polygon2D position write) |
| `scripts/main_menu.gd:500` | `Label` (`label.position`) | Child laid out by its own code |
| `scripts/main_menu.gd:501` | `Label` (`label.size`) | Child laid out by its own code |
| `scripts/main_menu.gd:512` | `Label` (`tick.position`) | Child laid out by its own code |
| `scripts/main_menu.gd:513` | `Label` (`tick.size`) | Child laid out by its own code |
| `scripts/main_menu.gd:529` | `Button` (`button.position`) | Child laid out by its own code |
| `scripts/main_menu.gd:530` | `Button` (`button.size`) | Child laid out by its own code |
| `scripts/obstacle.gd:71` | `Node2D` (`trunk.position`) | Not a Control (Node2D position write) |
| `scripts/obstacle.gd:81` | `Node2D` (`leaf.position`) | Not a Control (Node2D position write) |
| `scripts/obstacle.gd:106` | `Node2D` (`shadow.position`) | Not a Control (Node2D position write) |
| `scripts/obstacle.gd:119` | `Node2D` (`top.position`) | Not a Control (Node2D position write) |
| `scripts/obstacle.gd:125` | `Node2D` (`rim.position`) | Not a Control (Node2D position write) |
| `scripts/obstacle.gd:154` | `Node2D` (`trunk.position`) | Not a Control (Node2D position write) |
| `scripts/obstacle.gd:161` | `Node2D` (`leaf.position`) | Not a Control (Node2D position write) |
| `scripts/obstacle.gd:173` | `Node2D` (`bloom.position`) | Not a Control (Node2D position write) |
| `scripts/queen_hearts_vfx.gd:27` | `Node2D` (`heart.position`) | Not a Control (Node2D position write) |
| `scripts/queen_hearts_vfx.gd:46` | `Node2D` (`node.position`) | Not a Control (Node2D position write) |
| `scripts/rival_hive.gd:84` | `Sprite2D` (`skep.position`) | Not a Control (Sprite2D position write) |
| `scripts/rival_hive.gd:88` | `Label` on `Node2D` (`label.position`) | Child laid out by world-space code |
| `scripts/rival_hive.gd:132` | `Node2D` (`dot.position`) | Not a Control (Node2D position write) |
| `scripts/rival_hive.gd:269` | `Node2D` (`forager.node.position`) | Not a Control (Node2D position write) |
| `scripts/rival_hive.gd:281` | `Node2D` (`forager.node.position`) | Not a Control (Node2D position write) |
| `scripts/saving.gd:211` | `Node2D` (`cell.position`) | Not a Control (Node2D position write) |
| `scripts/saving.gd:338` | `Node2D` (`flower.position`) | Not a Control (Node2D position write) |
| `scripts/saving.gd:375` | `Node2D` (`bee.position`) | Not a Control (Node2D position write) |
| `scripts/scenario_actions.gd:1098` | `Window` (`main.get_window().size`) | Not a Control (Window size write) |
| `scripts/soil_block.gd:91` | `Label` on `Node2D` (`progress_label.position`) | Child laid out by world-space code |
| `scripts/soil_block.gd:172` | `Node2D` (`selection_ring.position`) | Not a Control (Node2D position write) |
| `scripts/soil_block.gd:173` | `Node2D` (`marker.position`) | Not a Control (Node2D position write) |
| `scripts/ui.gd:24` | `UiInfoBadge` / `Button` (`badge.size`) | Child laid out by its own code |
| `scripts/world_building.gd:42` | `Node2D` (`grass.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:49` | `Node2D` (`main.hive.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:104` | `Node2D` (`main.rival.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:137` | `Node2D` (`obstacle.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:311` | `Node2D` (`flower.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:419` | `Node2D` (`marker.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:433` | `Node2D` (`cell.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:456` | `Node2D` (`main.queen.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:485` | `Node2D` (`tile.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:497` | `Node2D` (`block.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:506` | `Node2D` (`block.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:557` | `Camera2D` (`main.meadow_camera.position`) | Not a Control (Camera2D position write) |
| `scripts/world_building.gd:561` | `Camera2D` (`main.hive_camera.position`) | Not a Control (Camera2D position write) |
| `scripts/world_building.gd:566` | `Node2D` (`bee.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:577` | `Node2D` (`bee.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:613` | `Node2D` (`bee.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:638` | `Node2D` (`bee.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:653` | `Node2D` (`bee.position`) | Not a Control (Node2D position write) |
| `scripts/world_building.gd:669` | `Node2D` (`marker.position`) | Not a Control (Node2D position write) |
| `scripts/year_winter.gd:146` | `Camera2D` (`_active_camera().position`) | Not a Control (Camera2D position write) |
| `scripts/year_winter.gd:159` | `Camera2D` (`_active_camera().position`) | Not a Control (Camera2D position write) |

## Method

- Scanned all 209 `.gd` files under `scripts/` using Python regexes for `size`, `position`, `global_position`, `set_size`, `set_position`, `reset_size`, `custom_minimum_size`, `HFlowContainer`, `clip_text`, `autowrap_mode`, `HBoxContainer`, and `size_flags_horizontal`.
- Cross-referenced node types against class definitions (`extends`) and variable initializations.
- Re-checked findings by hand against source code sha `be89c673`.
