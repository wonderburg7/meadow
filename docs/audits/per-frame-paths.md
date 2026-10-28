# Audit: per-frame paths

Audited: 4517ae0b on 2026-10-28 | Task: J-34 | Scope: scripts/ GDScript process, draw, input handlers and Timer instances

## Summary

Read 30 per-frame callback and draw sites across 22 GDScript files in `scripts/`. Timers under 0.1 s wait time were checked (0 found).
Found 7 performance and allocation issues across 2 high, 3 medium, and 2 low severity findings.

Top 5 findings:
1. `scripts/debug_panel.gd:443`: Debug panel `_process` runs `get_tree().get_nodes_in_group("world")` and string formatting every frame even when debug controls are hidden.
2. `scripts/hud.gd:2508`: HUD `_process` calls `_update_stage_marker_arrow()` every frame regardless of HUD element visibility or target movement.
3. `scripts/input_selection.gd:643`: Selection overlay `_draw_selection_box()` allocates `PackedVector2Array` instances per hex tile on every redrawn frame.
4. `scripts/skill_tree_panel.gd:467`: Skill tree `_draw()` formats string key `"%d|%d|%d"` and constructs `PackedVector2Array` points per skill tile per draw call.
5. `scripts/rain_effect.gd:46`: Rain effect `_process()` issues `queue_redraw()` every frame while rain intensity is non-zero without delta thresholding.

## Findings

| # | Where (path:line) | What | Why it matters | Confidence | Fix |
|---|---|---|---|---|---|
| 1 | `scripts/debug_panel.gd:443` | `_process` queries `get_tree().get_nodes_in_group("world")` twice and formats strings every frame when developer panel is invisible. | `docs/known-pitfalls.md` § "Performance" (allocation churn and node tree queries in per-frame hooks). | High | Early return in `_process` when the debug panel container is not visible. |
| 2 | `scripts/hud.gd:2508` | `_process` invokes `_update_stage_marker_arrow()` unconditionally every frame. | `docs/known-pitfalls.md` § "Performance" (redundant calculation on unneeded visual updates). | High | Guard stage marker arrow calculation with epoch/position change checks or offscreen status. |
| 3 | `scripts/input_selection.gd:643` | `_draw_selection_box()` re-calculates hex tile outlines and allocates `PackedVector2Array` arrays every frame. | `docs/known-pitfalls.md` § "Performance" (array literal and geometry allocation churn in draw loop). | High | Cache outline geometry array per hex spacing or reuse static point buffers. |
| 4 | `scripts/skill_tree_panel.gd:467` | `_draw()` constructs string format keys `%d|%d|%d` and `PackedVector2Array` polygon arrays for every tile every redraw. | `docs/known-pitfalls.md` § "Performance" (per-frame allocation churn). | High | Pre-calculate polygon points and string keys when skill tree layout is built or window resized. |
| 5 | `scripts/rain_effect.gd:46` | `_process()` calls `queue_redraw()` every frame when rain intensity > 0.01. | `docs/known-pitfalls.md` § "Performance" (unthrottled canvas redraws). | High | Skip `queue_redraw()` when window/intensity has not changed and drops position delta is beneath sub-pixel threshold. |
| 6 | `scripts/bee.gd:1359` | `_process()` evaluates `_miner_dispatch_timer` loop and calls `BeeSurvival.age_and_burn` for every bee every frame ($O(N_{\text{bees}})$). | `docs/known-pitfalls.md` § "Performance" (scaling work with population size). | High | Maintain per-bee think/dispatch interval batching and ensure dead/inactive checks exit early. |
| 7 | `scripts/gallerin_panel.gd:111` | `_process()` evaluates dialogue string lengths and scans prompt queues every frame when hidden or inactive. | `docs/known-pitfalls.md` § "Performance" (unnecessary loop iteration in UI ticks). | High | Gate prompt queue scanning behind visibility and index dirty flags. |

## Candidate Jules tasks

### J-35 -- Guard rain effect redraw calls
- Files: `scripts/rain_effect.gd`
- After: none
- Why: `docs/known-pitfalls.md` § "Performance"; `rain_effect.gd` calls `queue_redraw()` on every frame even when position delta is insignificant.
- Do: Add a check in `_process()` to avoid issuing `queue_redraw()` when rain effect is not visible or paused.

Preflight output for candidate task files:
```
free  scripts/rain_effect.gd
```

## For Claude or Codex

- `scripts/debug_panel.gd:443`, `_process`, `plans/now/code-health.md`
- `scripts/hud.gd:2508`, `_process`, `plans/now/code-health.md`
- `scripts/input_selection.gd:643`, `_draw_selection_box`, `plans/now/code-health.md`
- `scripts/skill_tree_panel.gd:467`, `_draw`, `plans/now/code-health.md`
- `scripts/bee.gd:1359`, `_process`, `plans/now/code-health.md`
- `scripts/gallerin_panel.gd:111`, `_process`, `plans/now/code-health.md`

## Inventory

| File:Line | Scope / Method | Domain | Skip Logic | Scaling | Allocations / Redraws |
|---|---|---|---|---|---|
| `scripts/session.gd:48` | `_process` | Simulation | Early return if backup orders seeded or epoch unchanged | Once | None |
| `scripts/ui_theme.gd:157` | `_draw` | Presentation | Early return if high contrast or texture null | Per panel | None |
| `scripts/gallerin_panel.gd:111` | `_process` | Presentation | Evaluates visibility, dialogue typing, prompt queue | Once | String ops (`_typing_target.rfind`) |
| `scripts/challenge_runner.gd:303` | `_process` | Simulation | Early return if inactive or paused | Once | None |
| `scripts/colony_panel.gd:323` | `_draw_plot` | Presentation | Called on demand / queue_redraw | Once | Array allocations |
| `scripts/main.gd:797` | `_process` | Both | Early return on `Session.menu_pending` | Once | Calls camera, fog, scenery |
| `scripts/nursery_panel.gd:469` | `_draw_ring` | Presentation | Called on demand / queue_redraw | Once | Arc geometry |
| `scripts/fog_of_war.gd:432` | `_draw_hive_fog` | Presentation | Called on demand from `_update` | Once | Polygon points allocation |
| `scripts/fog_of_war.gd:611` | `_draw_fog` | Presentation | Called on demand from `_update` | Once | MultiMesh / Image updates |
| `scripts/fog_of_war.gd:642` | `_draw_fog_body` | Presentation | Called on demand from `_update` | Once | Polygon points allocation |
| `scripts/hive_cell.gd:687` | `_process` | Both | Staggered refresh timer (`REFRESHES_PER_SECOND`) | Per cell | None |
| `scripts/hive_body.gd:38` | `_draw` | Presentation | Direct Godot draw call | Per body | Circle / Line primitives |
| `scripts/bee_speech_bubble.gd:38` | `_process` | Presentation | Destroys on lifetime expiry | Per bubble | Node reparenting |
| `scripts/rival_hive.gd:136` | `_process` | Simulation | Tick timer (1.0 s) | Per rival hive | None |
| `scripts/ui_icon.gd:18` | `_draw` | Presentation | Direct Godot draw call | Per icon | Hexagon points allocation |
| `scripts/hud.gd:2508` | `_process` | Presentation | Cadence checks for popups (`POPUP_REFRESH_CADENCE`) | Once | `_update_stage_marker_arrow` per frame |
| `scripts/queen_hearts_vfx.gd:32` | `_process` | Presentation | Destroys on lifetime expiry | Per heart VFX | Array element modification |
| `scripts/death_marker.gd:69` | `_process` | Presentation | Destroys on lifetime expiry | Per death marker | Modulate alpha update |
| `scripts/pollination_pop.gd:59` | `_process` | Presentation | Disables process when inactive | Per pop | None in `_process`; draw string in `_draw` |
| `scripts/pollination_pop.gd:69` | `_draw` | Presentation | Triggered via `queue_redraw()` | Per pop | `global_transform.affine_inverse()` |
| `scripts/perf.gd:203` | `_process` | Presentation | Early return if `not Session.perf_enabled` | Once | `_window_worst_totals = _totals.duplicate()` |
| `scripts/perf_plot.gd:19` | `_process` | Presentation | Early return if invisible or `history_version` unchanged | Once | `queue_redraw()` when version changes |
| `scripts/perf_plot.gd:27` | `_draw` | Presentation | Redrawn on demand | Once | Iterates frame history |
| `scripts/flower.gd:270` | `_process` | Both | Presentation timer throttled (`PRESENTATION_PER_SECOND`) | Per flower | `_update_labels()` |
| `scripts/bee.gd:1359` | `_process` | Both | Staggered think timer (`THINKS_PER_SECOND`) | Per bee | `BeeSurvival.age_and_burn` |
| `scripts/perf_breakdown.gd:26` | `_process` | Presentation | Early return if invisible or `history_version` unchanged | Once | String format & `join()` |
| `scripts/click_marker.gd:24` | `_process` | Presentation | Destroys on lifetime expiry | Per click | `Shapes.circle_points` array allocation |
| `scripts/debug_panel.gd:443` | `_process` | Presentation | Unconditional call | Once | `get_tree().get_nodes_in_group("world")`, string format |
| `scripts/skill_tree_panel.gd:164` | `_input` | Presentation | Early return if closed or not key event | Once | Viewport input setting |
| `scripts/skill_tree_panel.gd:467` | `_draw` | Presentation | Drawn when open | Once | `Shapes.hexagon_points`, string format `%d|%d|%d` |
| `scripts/skill_tree_panel.gd:548` | `_gui_input` | Presentation | Event-driven input processing | Once | Mouse event handling & pan updates |
| `scripts/season.gd:37` | `_process` | Simulation | Tick timer (1.0 s) | Once | `get_nodes_in_group("bees")` once per sec |
| `scripts/rain_effect.gd:46` | `_process` | Presentation | Early return if invisible or rain intensity <= 0.01 | Once | `queue_redraw()` per frame |
| `scripts/rain_effect.gd:68` | `_draw` | Presentation | Redrawn per frame | Once | Line primitive drawing |
| `scripts/input_selection.gd:16` | `_unhandled_input` | Presentation | Event-driven input processing | Once | Input event branching |

## Method

1. Searched `scripts/` recursively for GDScript process, draw, and input callback methods:
   - `func _process`
   - `func _physics_process`
   - `func _draw`
   - `func _input`
   - `func _unhandled_input`
   - `func _gui_input`
2. Searched `scripts/` and scene files for `Timer` nodes and `wait_time` configurations < 0.1 s.
3. Inspected each site line-by-line to record domain, skip logic, scaling factor, and per-frame memory allocation or draw calls.
4. Verified path references and documentation cross-references using `python tools/check_docs.py`.
