# Audit: signal wiring

Audited: 5d8fada on 2026-10-27 | Task: J-33 | Scope: scripts/**/*.gd and scenes/**/*.tscn

## Summary

Read all 106 script files in `scripts/` and all 2 scene files in `scenes/` auditing custom signal declarations, emissions, connections, and engine signal lifecycle patterns.
Found 63 custom signal declarations across 58 unique signal names.
Total findings: 7 (2 High, 3 Medium, 2 Low).

Key findings:
1. `rain_changed` (declared in `scripts/main.gd:49`) is emitted 4 times but never connected anywhere.
2. `challenge_stage_cleared` (declared in `scripts/challenge_runner.gd:40`) is emitted twice but never connected.
3. String-based signal connection in `scripts/hive.gd:215` bypasses Godot 4 type checking and refactoring safety.
4. Duplicate signal connection of `bottom_row_changed` in `scripts/saves_panel.gd:91` and `scripts/game_panel.gd:63` without checks.
5. Re-runnable node construction functions connecting UI signals without clearing previous listeners or guarding.

## Findings

| # | Where (path:line) | What | Why it matters | Confidence | Fix |
|---|---|---|---|---|---|
| 1 | `scripts/main.gd:49` | Declared signal `rain_changed` is emitted in `main.gd` (lines 1019, 1028, 1156, 1195) but has zero listeners. | Violates clean interface design; dead signal emissions add noise (`docs/agent-rules.md` rule 1). | High | Remove unused `rain_changed` signal declaration and its `emit` calls or connect it to weather UI if needed. |
| 2 | `scripts/challenge_runner.gd:40` | Declared signal `challenge_stage_cleared` is emitted (lines 201, 259) but has zero listeners. | Unconnected signal emission (`docs/agent-rules.md` rule 1). | High | Connect `challenge_stage_cleared` to HUD/Challenge completion listener or remove signal if obsolete. |
| 3 | `scripts/hive.gd:215` | `node.connect("mining_work_changed", _advance_mining_work_epoch)` uses string-based signal connection. | String names break compile-time check and static analysis in Godot 4 (`docs/known-pitfalls.md`). | High | Change to typed Callable signal syntax: `node.mining_work_changed.connect(_advance_mining_work_epoch)`. |
| 4 | `scripts/game_panel.gd:63` | `connect_left_window_reflow` connects `main.hud.bottom_row_changed` without `is_connected` guard. | If called multiple times during window layout recalculations, signal fires multiple duplicate handlers. | Medium | Add `if not main.hud.bottom_row_changed.is_connected(_on_bottom_row_changed):` guard before connecting. |
| 5 | `scripts/saves_panel.gd:91` | `connect_hud_reflow` connects `main.hud.bottom_row_changed` without `is_connected` guard. | Multiple calls to `connect_hud_reflow` will attach duplicate listeners. | Medium | Add `if not main.hud.bottom_row_changed.is_connected(_on_bottom_row_changed):` guard before connecting. |
| 6 | `scripts/year_winter.gd:33` | `_connect_season` connects `main.season.gyne_lost` directly without `is_connected` guard. | Potential duplicate connection if season re-initialises or reconnects. | Medium | Add `if not main.season.gyne_lost.is_connected(_on_gyne_lost):` guard. |
| 7 | `scripts/colony_panel.gd:288` | Signal `pressed` connected to lambda inside loop over series buttons during rebuild. | Dynamic UI reconstruction creates new button instances without explicit disconnect on old nodes. | Low | Ensure parent container clears old children (`queue_free()`) before rebuilding or disconnect before freeing. |

## Candidate Jules tasks

### J-? -- Convert string signal connection in hive.gd to typed Callable
Files: `scripts/hive.gd`
After: none
Why: `hive.gd:215` connects `mining_work_changed` using string syntax `node.connect("mining_work_changed", ...)`, bypassing Godot 4 type checks.
Do: replace `node.connect("mining_work_changed", _advance_mining_work_epoch)` with `node.mining_work_changed.connect(_advance_mining_work_epoch)`.

```
free  scripts/hive.gd
```

### J-? -- Remove unconnected rain_changed signal from main.gd
Files: `scripts/main.gd`
After: none
Why: `rain_changed` signal is declared in `main.gd:49` and emitted in 4 places but never connected to any handler.
Do: remove `signal rain_changed` declaration and its 4 `.emit()` calls in `main.gd`.

```
free  scripts/main.gd
```

### J-? -- Guard bottom_row_changed connections in game_panel.gd and saves_panel.gd
Files: `scripts/game_panel.gd`, `scripts/saves_panel.gd`
After: none
Why: `bottom_row_changed` is connected in `connect_left_window_reflow` and `connect_hud_reflow` without checking if already connected.
Do: add `is_connected` check before calling `.connect()` in both files.

```
free  scripts/game_panel.gd
free  scripts/saves_panel.gd
```

## For Claude or Codex

- `scripts/challenge_runner.gd`: `challenge_stage_cleared` signal is emitted on stage completion but never connected. Needs design decision whether to wire it to UI challenge notifications or remove it (`plans/now/challenges.md`).

## Inventory

| Signal Name | Declared In | Emitted In | Connected In | Status / Notes |
|---|---|---|---|---|
| `backup_order_requested` | `scripts/hud.gd:100` | `scripts/hud.gd:3539` | `scripts/main.gd:638` | Connected & Emitted |
| `bee_died` | `scripts/main.gd:47` | `scripts/bee.gd:726` | `scripts/main.gd:711, 712` | Connected & Emitted |
| `bottom_row_changed` | `scripts/hud.gd:121` | `scripts/hud.gd:1020, 1035, 1045, 1055` | `scripts/game_panel.gd:63`, `scripts/saves_panel.gd:91` | Connected & Emitted |
| `cell_close_requested` | `scripts/hud.gd:81` | `scripts/hud.gd:1953, 1962` | `scripts/main.gd:632` | Connected & Emitted |
| `cell_designation_requested` | `scripts/hud.gd:36` | `scripts/hud.gd:1745` | `scripts/main.gd:615` | Connected & Emitted |
| `cell_drone_requested` | `scripts/hud.gd:59` | `scripts/hud.gd:1912` | `scripts/main.gd:623` | Connected & Emitted |
| `cell_empty_by_bee_requested` | `scripts/hud.gd:55` | `scripts/hud.gd:2021` | `scripts/main.gd:620` | Connected & Emitted |
| `cell_empty_requested` | `scripts/hud.gd:46` | `scripts/hud.gd:1992, 1999` | `scripts/main.gd:618` | Connected & Emitted |
| `cell_feed_first_requested` | `scripts/hud.gd:61` | `scripts/hud.gd:1929` | `scripts/main.gd:624` | Connected & Emitted |
| `cell_fill_close_requested` | `scripts/hud.gd:84` | `scripts/hud.gd:1971` | `scripts/main.gd:633` | Connected & Emitted |
| `cell_gyne_requested` | `scripts/hud.gd:57` | `scripts/hud.gd:1897` | `scripts/main.gd:622` | Connected & Emitted |
| `cell_hatch_lock_requested` | `scripts/hud.gd:42` | `scripts/hud.gd:1883` | `scripts/main.gd:617` | Connected & Emitted |
| `cell_hatch_role_requested` | `scripts/hud.gd:39` | `scripts/hud.gd:1859` | `scripts/main.gd:616` | Connected & Emitted |
| `cell_keep_empty_requested` | `scripts/hud.gd:50` | `scripts/hud.gd:2039` | `scripts/main.gd:621` | Connected & Emitted |
| `cell_priority_requested` | `scripts/hud.gd:79` | `scripts/hud.gd:1814` | `scripts/main.gd:631` | Connected & Emitted |
| `challenge_stage_cleared` | `scripts/challenge_runner.gd:40` | `scripts/challenge_runner.gd:201, 259` | None | Finding #2 (Unconnected) |
| `clear_fermented_requested` | `scripts/hud.gd:47` | `scripts/hud.gd:2007` | `scripts/main.gd:619` | Connected & Emitted |
| `closed` | `scripts/game_panel.gd:17` | `scripts/nursery_panel.gd:135` | `scripts/main.gd:675` | Connected & Emitted |
| `colony_panel_requested` | `scripts/hud.gd:33` | `scripts/hud.gd:813` | `scripts/main.gd:612` | Connected & Emitted |
| `continue_requested` | `scripts/challenge_complete.gd:15` | `scripts/challenge_complete.gd:111` | `scripts/main.gd:704` | Connected & Emitted |
| `continue_to_next_requested` | `scripts/challenge_complete.gd:16` | `scripts/challenge_complete.gd:113` | `scripts/main.gd:705` | Connected & Emitted |
| `day_changed` | `scripts/main.gd:48` | `scripts/main.gd:1085` | `scripts/main.gd:713, 715, 716` | Connected & Emitted |
| `favourite_requested` | `scripts/hud.gd:105` | `scripts/hud.gd:1339` | `scripts/main.gd:640` | Connected & Emitted |
| `favourite_selected` | `scripts/colony_panel.gd:31` | `scripts/colony_panel.gd:420` | `scripts/main.gd:663` | Connected & Emitted |
| `finish_first_requested` | `scripts/hud.gd:102` | `scripts/hud.gd:3467` | `scripts/main.gd:639` | Connected & Emitted |
| `follow_bee_toggled` | `scripts/hud.gd:111` | `scripts/hud.gd:3189, 3210` | `scripts/main.gd:641` | Connected & Emitted |
| `foraging_panel_requested` | `scripts/hud.gd:34` | `scripts/hud.gd:834` | `scripts/main.gd:613` | Connected & Emitted |
| `goal_star_toggled` | `scripts/hud.gd:31` | `scripts/hud.gd:1124` | `scripts/hud.gd:870` | Connected & Emitted |
| `gyne_lost` | `scripts/season.gd:20` | `scripts/season.gd:210` | `scripts/year_winter.gd:33` | Connected & Emitted |
| `gyne_released` | `scripts/season.gd:17` | `scripts/season.gd:200` | `scripts/main.gd:693, 694, 695` | Connected & Emitted |
| `keep_clear_clear_requested` | `scripts/hud.gd:95` | `scripts/hud.gd:1302` | `scripts/main.gd:630` | Connected & Emitted |
| `level_chosen` | `scripts/main_menu.gd:22` | `scripts/main_menu.gd:613` | `scripts/main.gd:479` | Connected & Emitted |
| `menu_requested` | `scripts/challenge_complete.gd:17`, `scripts/game_over.gd:18` | `scripts/challenge_complete.gd:117`, `scripts/game_over.gd:84` | `scripts/main.gd:700, 706` | Connected & Emitted |
| `mining_work_changed` | `scripts/soil_block.gd:25` | `scripts/soil_block.gd:80, 95, 110` | `scripts/hive.gd:215` | Connected via string (Finding #3) |
| `nursery_window_requested` | `scripts/hud.gd:86` | `scripts/hud.gd:822, 1828` | `scripts/main.gd:634` | Connected & Emitted |
| `pinned_changed` | `scripts/colony_panel.gd:28`, `scripts/nursery_panel.gd:22` | `scripts/colony_panel.gd:380`, `scripts/nursery_panel.gd:226` | `scripts/main.gd:662, 676` | Connected & Emitted |
| `placement_tool_requested` | `scripts/hud.gd:69` | `scripts/hud.gd:3172, 3354, 3359, 3363, 3366, 3369, 3372, 3382, 3385` | `scripts/main.gd:625` | Connected & Emitted |
| `points_earned` | `scripts/pollination.gd:58` | `scripts/pollination.gd:117` | `scripts/hud.gd:609, 610` | Connected & Emitted |
| `queen_lay_any_cell_toggled` | `scripts/hud.gd:116` | `scripts/hud.gd:3479` | `scripts/main.gd:658` | Connected & Emitted |
| `rain_changed` | `scripts/main.gd:49` | `scripts/main.gd:1019, 1028, 1156, 1195` | None | Finding #1 (Unconnected) |
| `restart_requested` | `scripts/challenge_complete.gd:18`, `scripts/game_over.gd:17` | `scripts/challenge_complete.gd:115`, `scripts/game_over.gd:82` | `scripts/main.gd:699, 707` | Connected & Emitted |
| `restock_clear_requested` | `scripts/hud.gd:76` | `scripts/hud.gd:3411` | `scripts/main.gd:628` | Connected & Emitted |
| `restock_sources_requested` | `scripts/hud.gd:75` | `scripts/hud.gd:3405, 3408` | `scripts/main.gd:627` | Connected & Emitted |
| `restock_targets_requested` | `scripts/hud.gd:72` | `scripts/hud.gd:3400` | `scripts/main.gd:626` | Connected & Emitted |
| `role_requested` | `scripts/hud.gd:29` | `scripts/hud.gd:3221, 3253` | `scripts/main.gd:610` | Connected & Emitted |
| `role_selection_requested` | `scripts/colony_panel.gd:26` | `scripts/colony_panel.gd:216` | `scripts/main.gd:661` | Connected & Emitted |
| `run_reset` | `scripts/session.gd:32` | `scripts/session.gd:413` | `scripts/challenge_runner.gd:174`, `scripts/colony_panel.gd:151`, `scripts/debug_panel.gd:113, 114`, `scripts/diagnostic_log.gd:136`, `scripts/saves_panel.gd:81` | Connected & Emitted |
| `scenario_chosen` | `scripts/main_menu.gd:25` | `scripts/main_menu.gd:713` | `scripts/main.gd:480` | Connected & Emitted |
| `secondary_role_requested` | `scripts/hud.gd:98` | `scripts/hud.gd:3526, 3533` | `scripts/main.gd:637` | Connected & Emitted |
| `signal_clicked` | `scripts/colony_panel.gd:36`, `scripts/hud.gd:91`, `scripts/nursery_panel.gd:25` | `scripts/colony_panel.gd:462`, `scripts/hud.gd:2903`, `scripts/nursery_panel.gd:323` | `scripts/main.gd:636, 666, 677` | Connected & Emitted |
| `soil_mark_requested` | `scripts/hud.gd:93` | `scripts/hud.gd:1272, 1284` | `scripts/main.gd:629` | Connected & Emitted |
| `speed_requested` | `scripts/hud.gd:35` | `scripts/hud.gd:771, 797` | `scripts/main.gd:614` | Connected & Emitted |
| `storage_changed` | `scripts/hive.gd:10` | `scripts/hive.gd:1265` | `scripts/main.gd:710` | Connected & Emitted |
| `unlocked_changed` | `scripts/stage_gate.gd:25` | `scripts/stage_gate.gd:79` | `scripts/challenge_runner.gd:265` | Connected & Emitted |
| `view_toggle_requested` | `scripts/hud.gd:32` | `scripts/hud.gd:878` | `scripts/main.gd:611` | Connected & Emitted |
| `winter_started` | `scripts/season.gd:15` | `scripts/season.gd:135` | `scripts/main.gd:691` | Connected & Emitted |
| `winter_survived` | `scripts/season.gd:16` | `scripts/season.gd:191` | `scripts/main.gd:692` | Connected & Emitted |
| `winter_window_requested` | `scripts/hud.gd:88` | `scripts/hud.gd:845` | `scripts/main.gd:635` | Connected & Emitted |

## Method

1. Searched all GDScript source files under `scripts/` using Python regular expressions for `signal <name>` declarations.
2. Cross-referenced each signal name against emission sites (`.emit(` and `emit_signal(`) and connection sites (`.connect(` and `connect(`).
3. Checked all `.tscn` files under the repository for signal wiring.
4. Analyzed string-based signal name references (`"signal_name"`).
5. Inspected connection calls inside loop structures and re-enterable UI construction methods to find potential reconnection / double-connection issues.
