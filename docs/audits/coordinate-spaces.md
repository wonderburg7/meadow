# Audit: hive and meadow coordinate spaces

Audited: 5d8fada on 24 May 2024 | Task: J-31 | Scope: 23 GDScript files in `scripts/` naming `hive_root`, `meadow_root`, `global_position`, `to_global`, `to_local`, `reparent` or `add_child` for world entities

## Summary

Read 23 GDScript files covering 82 coordinate-space operations across spatial checks, distance comparisons, node positioning, and root parent transitions. Found 2 findings total: 1 medium severity (potential cross-view distance comparison when `find_honey_source` is called from unexpected states) and 1 low severity (`year_winter.gd` camera focus using local position directly for camera target without explicit canvas transform checks). All core simulation movement and reparenting transitions between `hive_root` and `meadow_root` accurately convert positions at transfer points.

Top findings:
1. `scripts/bee_honey.gd:76` / `scripts/hive.gd:660`: `find_honey_source` calculates `from.distance_squared_to(cell.global_position)` using `bee.global_position`. When the bee is parented under `hive_root` (which is translated by `HIVE_WORLD_OFFSET`), `cell.global_position` is in world coordinates while `bee.global_position` is also in world coordinates, but if `find_honey_source` were invoked before entry reparenting completes, coordinates would mismatch.
2. `scripts/year_winter.gd:146`: Active camera positioning assigns `bee.global_position` directly to `camera.position` without converting to the camera parent's local space when camera nodes sit at non-zero offsets.

## Findings

| # | Where (path:line) | What | Why it matters | Confidence | Fix |
|---|---|---|---|---|---|
| 1 | `scripts/bee_honey.gd:76` | `bee.hive.find_honey_source(bee.global_position)` calculates distance to `cell.global_position`. | `docs/known-pitfalls.md` § "Simulation and behaviour" (A bee under `hive_root` is in hive-local coordinates; a flower is not) | Medium | Ensure `find_honey_source` takes hive-local coordinates or uses `cell.position` consistently when evaluating indoor distances. |
| 2 | `scripts/year_winter.gd:146` | `camera.position = selected_bees[0].global_position` assigns global position directly to camera local position. | Past coordinate space misalignment bugs when cameras or roots shift | Low | Use `camera.get_parent().to_local(bee.global_position)` or set global_position directly on the camera. |

## Candidate Jules tasks

### J-? -- Source check for direct distance comparisons across root boundaries
Files: `tests/source_checks.py`
After: none
Why: Prevents direct distance math between hive-local `position` and meadow-local `position` or `global_position` without explicit space conversions.
Do: Add a source check regex in `tests/source_checks.py` that flags any `.gd` file calling `distance_to` between a `hive_root` child's local `position` and `global_position`.

`python tools/jules_preflight.py tests/source_checks.py` output: `free  tests/source_checks.py`

## For Claude or Codex

- `scripts/bee_honey.gd`: `find_honey_source` call site passes `bee.global_position`. Plan: `plans/now/code-health.md`.

## Inventory

| Site | Where (path:line) | Parent / Space | Classification | Notes |
|---|---|---|---|---|
| 1 | `scripts/bee.gd:804` | `hive_root` | Converted correctly | Re-adds/reparents bee under `hive_root`. |
| 2 | `scripts/bee.gd:1488` | `meadow_root` | Same space | Distance comparison between `position` and `current_flower.position` in meadow space. |
| 3 | `scripts/bee.gd:1504` | `meadow_root` | Same space | Distance comparison between `position` and `hive.position` in meadow space. |
| 4 | `scripts/bee.gd:1538` | `meadow_root` / `hive_root` | Same space | Distance comparison to `move_target` in active root local space. |
| 5 | `scripts/bee.gd:1731` | `meadow_root` / `hive_root` | Same space | Distance comparison to `tipsy_wander_point` in local space. |
| 6 | `scripts/bee.gd:1740` | `meadow_root` / `hive_root` | Same space | Distance comparison to `tipsy_resume_point` in local space. |
| 7 | `scripts/bee.gd:2168` | `meadow_root` / `hive_root` | Converted correctly | `parent.to_local(world_point)` converts world point to parent local space. |
| 8 | `scripts/bee.gd:2404` | `meadow_root` / `hive_root` | Converted correctly | Post-reparenting position adjustment at entrance/exit. |
| 9 | `scripts/bee.gd:3120` | `visual_root` | Same space | Visual offset distance check in local space. |
| 10 | `scripts/bee.gd:3162` | `hive_root` | Same space | `get_parent() == world.hive_root` check. |
| 11 | `scripts/bee_foraging.gd:230` | `meadow_root` | Same space | Distance to `search_waypoint` in meadow local space. |
| 12 | `scripts/bee_foraging.gd:292` | `meadow_root` | Same space | Known patch distance check in meadow space. |
| 13 | `scripts/bee_foraging.gd:439` | `meadow_root` | Same space | Forager distance to flower in meadow space. |
| 14 | `scripts/bee_foraging.gd:463` | `meadow_root` | Same space | Forager distance to candidate flower in meadow space. |
| 15 | `scripts/bee_foraging.gd:903` | `meadow_root` | Same space | Distance to stand point in meadow space. |
| 16 | `scripts/bee_foraging.gd:1437` | `meadow_root` | Same space | Recruit dance radius check in meadow space. |
| 17 | `scripts/bee_honey.gd:76` | `hive_root` | Mixed (Finding 1) | Passes `bee.global_position` to `find_honey_source`. |
| 18 | `scripts/camera_view.gd:64` | `main` | Converted correctly | Camera position assigned from view center. |
| 19 | `scripts/challenge_runner.gd:235` | `hive_camera` | Converted correctly | Camera position set to `queen.global_position`. |
| 20 | `scripts/challenge_runner.gd:301` | `hive_root` | Same space | Stage marker added to `hive_root`. |
| 21 | `scripts/challenge_runner.gd:510` | `hive_root` | Same space | Inspection points in hive root space. |
| 22 | `scripts/challenge_runner.gd:512` | `meadow_root` | Same space | Inspection points in meadow root space. |
| 23 | `scripts/challenge_runner.gd:612` | `_visit_marker_parent` | Converted correctly | `_visit_marker_parent.to_global(point.position)` distance check to `traveller.global_position`. |
| 24 | `scripts/challenge_runner.gd:626` | `_visit_marker_parent` | Converted correctly | Marker reparented to `_visit_marker_parent`. |
| 25 | `scripts/challenge_runner.gd:645` | `hive_root` / `meadow_root` | Converted correctly | Marker reparented between `hive_root` and `meadow_root`. |
| 26 | `scripts/challenge_runner.gd:1098` | `hive_root` | Same space | Queen hearts VFX added to `hive_root`. |
| 27 | `scripts/challenge_runner.gd:1158` | `hive_root` | Same space | Distance comparison on `queen.position`. |
| 28 | `scripts/debug_panel.gd:112` | `debug_panel` | Same space | UI control added to debug panel hierarchy. |
| 29 | `scripts/flower.gd:120` | `meadow_root` | Same space | Flower sprite positions in local space. |
| 30 | `scripts/fog_of_war.gd:88` | `meadow_root` | Same space | Fog of war vision calculations in meadow space. |
| 31 | `scripts/hive.gd:660` | `hive_root` | Mixed (Finding 1) | `from.distance_squared_to(cell.global_position)` comparison in `find_honey_source`. |
| 32 | `scripts/hive.gd:782` | `hive_root` | Same space | Hive body added to `comb_parent` (`hive_root`). |
| 33 | `scripts/hive.gd:927` | `hive_root` | Same space | Hive cell added to `comb_parent` (`hive_root`). |
| 34 | `scripts/hive_cell.gd:220` | `hive_root` | Same space | Cell position in hive space. |
| 35 | `scripts/hud.gd:2542` | `hive_root` / `meadow_root` | Converted correctly | Marker position converted via `root.get_global_transform_with_canvas() * root.to_local(...)`. |
| 36 | `scripts/input_selection.gd:116` | `meadow_root` / `hive_root` | Converted correctly | Selection box check using `b.global_position`. |
| 37 | `scripts/input_selection.gd:169` | `hive_root` | Converted correctly | Cell selection box check using `c.global_position`. |
| 38 | `scripts/input_selection.gd:177` | `hive_root` | Converted correctly | Soil block selection box check using `b.global_position`. |
| 39 | `scripts/input_selection.gd:189` | `meadow_root` | Converted correctly | Death marker selection box check using `m.global_position`. |
| 40 | `scripts/input_selection.gd:291` | `hive_root` / `meadow_root` | Converted correctly | View root selection based on `in_hive_view`. |
| 41 | `scripts/input_selection.gd:305` | `hive_root` | Converted correctly | `hive_root.to_global(hive_entrance_inside())` target conversion. |
| 42 | `scripts/input_selection.gd:319` | `meadow_root` / `hive_root` | Converted correctly | Click selection using `b.global_position.distance_to(point)`. |
| 43 | `scripts/input_selection.gd:342` | `hive_root` | Converted correctly | `hive_root.to_local(global_point)` conversion. |
| 44 | `scripts/input_selection.gd:470` | `hive_root` | Converted correctly | `hive_root.to_local(global_point)` conversion. |
| 45 | `scripts/input_selection.gd:490` | `hive_root` | Converted correctly | `hive_root.to_local(global_point)` conversion. |
| 46 | `scripts/input_selection.gd:498` | `hive_root` | Converted correctly | `hive_root.to_local(global_point)` conversion. |
| 47 | `scripts/input_selection.gd:506` | `meadow_root` | Converted correctly | `meadow_root.to_local(global_point)` conversion. |
| 48 | `scripts/input_selection.gd:562` | `hive_root` | Converted correctly | Entrance exit click distance check using `hive_root.to_global(...)`. |
| 49 | `scripts/input_selection.gd:582` | `meadow_root` | Converted correctly | Hive click distance check using `hive.global_position`. |
| 50 | `scripts/input_selection.gd:618` | `hive_root` / `meadow_root` | Converted correctly | Selection marker positioned via `root.to_local(world_point)`. |
| 51 | `scripts/input_selection.gd:671` | `hive_root` | Converted correctly | Marker drawn at `hive_root.to_global(hive_entrance_inside())`. |
| 52 | `scripts/input_selection.gd:718` | `hive_root` | Converted correctly | Block positions converted via `hive_root.to_global(...)`. |
| 53 | `scripts/input_selection.gd:741` | `hive_root` | Converted correctly | Local coordinate converted via `hive_root.to_global(...)`. |
| 54 | `scripts/main.gd:565` | `main` | Same space | `meadow_root` added as child of `main` at origin. |
| 55 | `scripts/main.gd:570` | `main` | Same space | `hive_root` added as child of `main` at `HIVE_WORLD_OFFSET`. |
| 56 | `scripts/pollination.gd:122` | `hive_root` / `meadow_root` | Converted correctly | Documented reparenting transition via `move_bee_into_hive`. |
| 57 | `scripts/pollination_pop.gd:54` | `meadow_root` | Same space | Pollination pop position using `flower.global_position`. |
| 58 | `scripts/save_game.gd:267` | `hive_root` | Same space | Indoor status check via `b.get_parent() == world.hive_root`. |
| 59 | `scripts/saving.gd:212` | `hive_root` | Same space | Cells restored to `hive_root`. |
| 60 | `scripts/saving.gd:339` | `meadow_root` | Same space | Flowers restored to `meadow_root`. |
| 61 | `scripts/saving.gd:377` | `hive_root` | Same space | Indoor bees restored to `hive_root`. |
| 62 | `scripts/saving.gd:379` | `meadow_root` | Same space | Outdoor bees restored to `meadow_root`. |
| 63 | `scripts/scenario_actions.gd:782` | `hive_root` | Converted correctly | Entrance inside point converted via `hive_root.to_global(...)`. |
| 64 | `scripts/scenario_actions.gd:788` | `hive_root` | Converted correctly | Comb local point converted via `hive_root.to_global(...)`. |
| 65 | `scripts/scenario_actions.gd:797` | `hive_root` / `meadow_root` | Converted correctly | Point converted via `root.to_global(...)`. |
| 66 | `scripts/skill_tree_panel.gd:444` | Viewport | Same space | Intersection check in viewport space. |
| 67 | `scripts/soil_block.gd:77` | `soil_block` | Same space | Marker added as child of soil block. |
| 68 | `scripts/world_building.gd:45` | `meadow_root` | Same space | Grass added to `meadow_root`. |
| 69 | `scripts/world_building.gd:50` | `meadow_root` | Same space | Hive added to `meadow_root`. |
| 70 | `scripts/world_building.gd:75` | `hive_root` / `meadow_root` | Same space | Root match check against active view root. |
| 71 | `scripts/world_building.gd:84` | Viewport | Converted correctly | Visibility check using `node.global_position`. |
| 72 | `scripts/world_building.gd:106` | `meadow_root` | Same space | Rival hive added to `meadow_root`. |
| 73 | `scripts/world_building.gd:139` | `meadow_root` | Same space | Obstacle added to `meadow_root`. |
| 74 | `scripts/world_building.gd:312` | `meadow_root` | Same space | Flower added to `meadow_root`. |
| 75 | `scripts/world_building.gd:422` | `hive_root` | Same space | Marker added to `hive_root`. |
| 76 | `scripts/world_building.gd:434` | `hive_root` | Same space | Cell added to `hive_root`. |
| 77 | `scripts/world_building.gd:457` | `hive_root` | Same space | Queen added to `hive_root`. |
| 78 | `scripts/world_building.gd:567` | `meadow_root` | Same space | Bee spawned in `meadow_root`. |
| 79 | `scripts/world_building.gd:578` | `hive_root` | Same space | Bee spawned in `hive_root`. |
| 80 | `scripts/world_building.gd:637` | `hive_root` | Converted correctly | `bee.reparent(main.hive_root)` transitions bee into hive view and sets hive-local position. |
| 81 | `scripts/world_building.gd:652` | `meadow_root` | Converted correctly | `bee.reparent(main.meadow_root)` transitions bee into meadow view and sets meadow-local position. |
| 82 | `scripts/year_winter.gd:146` | Camera | Mixed (Finding 2) | Active camera position set directly to `selected_bees[0].global_position`. |

## Method

- Executed regex scans for coordinate-space keywords (`hive_root`, `meadow_root`, `global_position`, `to_global`, `to_local`, `reparent`, `add_child`, `distance_to`) across `scripts/*.gd`.
- Inspected all 23 matching files in full context.
- Verified entity parent transitions in `world_building.gd` (`move_bee_into_hive` and `move_bee_out_of_hive`).
- Evaluated all position assignments, additions, and distance calculations against parent coordinate spaces.
