# Audit: names the instructions point at that no longer exist

Audited: 4517ae0b on 28 Oct 2026 | Task: J-39 | Scope: .claude/rules/*.md, plans/reference/*.md, plans/reference/reviews/*.md, docs/known-pitfalls.md, docs/agent-rules.md, docs/headless-run-contract.md, CLAUDE.md, AGENTS.md

## Summary

Across 39 instruction files, 2349 sites were scanned for backticked references.
Total findings: 151 (12 high severity, 16 medium severity, 123 low severity).

Top 5 findings:
- .claude/rules/gdscript.md:18: Unprefixed file path `verify.ps1` - Update path to tools/verify.ps1 in .claude/rules/gdscript.md:18.
- .claude/rules/gdscript.md:26: Unprefixed file path `source_checks.py` - Update path to tests/source_checks.py in .claude/rules/gdscript.md:26.
- .claude/rules/gdscript.md:28: Unprefixed file path `bee_survival.gd` - Update path to scripts/bee_survival.gd in .claude/rules/gdscript.md:28.
- .claude/rules/gdscript.md:43: Unprefixed file path `input_selection.gd` - Update path to scripts/input_selection.gd in .claude/rules/gdscript.md:43.
- .claude/rules/gdscript.md:43: Unprefixed file path `fog_of_war.gd` - Update path to scripts/fog_of_war.gd in .claude/rules/gdscript.md:43.

## Findings

| # | Where (path:line) | What | Why it matters | Confidence | Fix |
|---|---|---|---|---|---|
| 1 | .claude/rules/gdscript.md:18 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in .claude/rules/gdscript.md:18. |
| 2 | .claude/rules/gdscript.md:26 | Unprefixed file path `source_checks.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tests/source_checks.py in .claude/rules/gdscript.md:26. |
| 3 | .claude/rules/gdscript.md:28 | Unprefixed file path `bee_survival.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/bee_survival.gd in .claude/rules/gdscript.md:28. |
| 4 | .claude/rules/gdscript.md:43 | Unprefixed file path `input_selection.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/input_selection.gd in .claude/rules/gdscript.md:43. |
| 5 | .claude/rules/gdscript.md:43 | Unprefixed file path `fog_of_war.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/fog_of_war.gd in .claude/rules/gdscript.md:43. |
| 6 | .claude/rules/gdscript.md:44 | Unprefixed file path `world_building.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/world_building.gd in .claude/rules/gdscript.md:44. |
| 7 | .claude/rules/gdscript.md:44 | Unprefixed file path `func.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/func.py in .claude/rules/gdscript.md:44. |
| 8 | .claude/rules/gdscript.md:46 | Unprefixed file path `bee.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/bee.gd in .claude/rules/gdscript.md:46. |
| 9 | .claude/rules/gdscript.md:46 | Stale tool/script `-m` | docs/agent-rules.md Rule 1: Invoking deleted scripts fails execution | high | Remove or update script reference in .claude/rules/gdscript.md:46. |
| 10 | .claude/rules/gdscript.md:46 | Stale tool/script `-m` | docs/agent-rules.md Rule 1: Invoking deleted scripts fails execution | high | Remove or update script reference in .claude/rules/gdscript.md:46. |
| 11 | .claude/rules/headless.md:24 | Non-existent file `failure.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in .claude/rules/headless.md:24. |
| 12 | .claude/rules/headless.md:29 | Unprefixed file path `game_config.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/game_config.gd in .claude/rules/headless.md:29. |
| 13 | .claude/rules/headless.md:32 | Unprefixed file path `challenge_runner.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/challenge_runner.gd in .claude/rules/headless.md:32. |
| 14 | .claude/rules/lifecycle-tooling.md:40 | Unprefixed file path `review_due.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/review_due.py in .claude/rules/lifecycle-tooling.md:40. |
| 15 | .claude/rules/lifecycle-tooling.md:42 | Stale tool/script `-m` | docs/agent-rules.md Rule 1: Invoking deleted scripts fails execution | high | Remove or update script reference in .claude/rules/lifecycle-tooling.md:42. |
| 16 | .claude/rules/performance.md:16 | Unprefixed file path `perf.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/perf.gd in .claude/rules/performance.md:16. |
| 17 | .claude/rules/saving.md:20 | Unprefixed file path `save_migrations.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/save_migrations.gd in .claude/rules/saving.md:20. |
| 18 | .claude/rules/saving.md:30 | Unprefixed file path `foraging_stats.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/foraging_stats.gd in .claude/rules/saving.md:30. |
| 19 | .claude/rules/saving.md:47 | Unprefixed file path `save_v1.json` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tests/fixtures/save_v1.json in .claude/rules/saving.md:47. |
| 20 | .claude/rules/saving.md:47 | Unprefixed file path `save_v2.json` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tests/fixtures/save_v2.json in .claude/rules/saving.md:47. |
| 21 | .claude/rules/saving.md:58 | Unprefixed file path `saving.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/saving.gd in .claude/rules/saving.md:58. |
| 22 | .claude/rules/simulation.md:23 | Unprefixed file path `roles.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/roles.gd in .claude/rules/simulation.md:23. |
| 23 | .claude/rules/simulation.md:26 | Unprefixed file path `roles.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/roles.gd in .claude/rules/simulation.md:26. |
| 24 | .claude/rules/simulation.md:26 | Unprefixed file path `bee.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/bee.gd in .claude/rules/simulation.md:26. |
| 25 | .claude/rules/simulation.md:56 | Unprefixed file path `hive.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/hive.gd in .claude/rules/simulation.md:56. |
| 26 | .claude/rules/simulation.md:56 | Unprefixed file path `world_building.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/world_building.gd in .claude/rules/simulation.md:56. |
| 27 | .claude/rules/ui.md:19 | Unprefixed file path `hud.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/hud.gd in .claude/rules/ui.md:19. |
| 28 | .claude/rules/ui.md:20 | Unprefixed file path `hud.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/hud.gd in .claude/rules/ui.md:20. |
| 29 | .claude/rules/ui.md:22 | Unprefixed file path `ui_layout.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/ui_layout.gd in .claude/rules/ui.md:22. |
| 30 | .claude/rules/ui.md:24 | Unprefixed file path `ui_theme.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/ui_theme.gd in .claude/rules/ui.md:24. |
| 31 | .claude/rules/ui.md:31 | Unprefixed file path `game_config.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/game_config.gd in .claude/rules/ui.md:31. |
| 32 | .claude/rules/ui.md:34 | Unprefixed file path `roles.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/roles.gd in .claude/rules/ui.md:34. |
| 33 | .claude/rules/ui.md:35 | Unprefixed file path `session.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/session.gd in .claude/rules/ui.md:35. |
| 34 | AGENTS.md:21 | Unprefixed file path `hive_cell.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/hive_cell.gd in AGENTS.md:21. |
| 35 | CLAUDE.md:45 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in CLAUDE.md:45. |
| 36 | docs/agent-rules.md:11 | Target doc `<file>` in heading command | docs/agent-rules.md Rule 1: File reference in instruction does not exist | high | Fix document path in docs/agent-rules.md:11. |
| 37 | docs/agent-rules.md:35 | Stale tool/script `tools/...` | docs/agent-rules.md Rule 1: Invoking deleted scripts fails execution | high | Remove or update script reference in docs/agent-rules.md:35. |
| 38 | docs/agent-rules.md:55 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in docs/agent-rules.md:55. |
| 39 | docs/headless-run-contract.md:75 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in docs/headless-run-contract.md:75. |
| 40 | docs/headless-run-contract.md:98 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in docs/headless-run-contract.md:98. |
| 41 | docs/headless-run-contract.md:99 | Unprefixed file path `run_scenario.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/run_scenario.py in docs/headless-run-contract.md:99. |
| 42 | docs/headless-run-contract.md:133 | Non-existent file `job.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/headless-run-contract.md:133. |
| 43 | docs/headless-run-contract.md:133 | Non-existent file `status.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/headless-run-contract.md:133. |
| 44 | docs/headless-run-contract.md:136 | Non-existent file `result.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/headless-run-contract.md:136. |
| 45 | docs/headless-run-contract.md:156 | Non-existent file `result.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/headless-run-contract.md:156. |
| 46 | docs/headless-run-contract.md:158 | Non-existent file `failure.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/headless-run-contract.md:158. |
| 47 | docs/headless-run-contract.md:161 | Non-existent file `report.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/headless-run-contract.md:161. |
| 48 | docs/headless-run-contract.md:171 | Non-existent file `result.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/headless-run-contract.md:171. |
| 49 | docs/headless-run-contract.md:201 | Non-existent file `failure.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/headless-run-contract.md:201. |
| 50 | docs/headless-run-contract.md:257 | Non-existent file `result.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/headless-run-contract.md:257. |
| 51 | docs/headless-run-contract.md:436 | Non-existent file `result.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/headless-run-contract.md:436. |
| 52 | docs/headless-run-contract.md:440 | Non-existent file `report.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/headless-run-contract.md:440. |
| 53 | docs/headless-run-contract.md:448 | Non-existent file `result.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/headless-run-contract.md:448. |
| 54 | docs/headless-run-contract.md:458 | Non-existent file `result.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/headless-run-contract.md:458. |
| 55 | docs/known-pitfalls.md:59 | Unprefixed file path `hud.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/hud.gd in docs/known-pitfalls.md:59. |
| 56 | docs/known-pitfalls.md:116 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in docs/known-pitfalls.md:116. |
| 57 | docs/known-pitfalls.md:121 | Unprefixed file path `ui_theme.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/ui_theme.gd in docs/known-pitfalls.md:121. |
| 58 | docs/known-pitfalls.md:153 | Unprefixed file path `main.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/main.gd in docs/known-pitfalls.md:153. |
| 59 | docs/known-pitfalls.md:153 | Unprefixed file path `source_checks.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tests/source_checks.py in docs/known-pitfalls.md:153. |
| 60 | docs/known-pitfalls.md:183 | Unprefixed file path `hud.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/hud.gd in docs/known-pitfalls.md:183. |
| 61 | docs/known-pitfalls.md:190 | Unprefixed file path `bee.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/bee.gd in docs/known-pitfalls.md:190. |
| 62 | docs/known-pitfalls.md:218 | Unprefixed file path `perf.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/perf.gd in docs/known-pitfalls.md:218. |
| 63 | docs/known-pitfalls.md:225 | Unprefixed file path `world_building.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/world_building.gd in docs/known-pitfalls.md:225. |
| 64 | docs/known-pitfalls.md:274 | Unprefixed file path `bee_foraging.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/bee_foraging.gd in docs/known-pitfalls.md:274. |
| 65 | docs/known-pitfalls.md:275 | Unprefixed file path `bee.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/bee.gd in docs/known-pitfalls.md:275. |
| 66 | docs/known-pitfalls.md:280 | Unprefixed file path `source_checks.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tests/source_checks.py in docs/known-pitfalls.md:280. |
| 67 | docs/known-pitfalls.md:298 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in docs/known-pitfalls.md:298. |
| 68 | docs/known-pitfalls.md:299 | Unprefixed file path `run_scenario.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/run_scenario.py in docs/known-pitfalls.md:299. |
| 69 | docs/known-pitfalls.md:412 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in docs/known-pitfalls.md:412. |
| 70 | docs/known-pitfalls.md:433 | Unprefixed file path `run_scenario.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/run_scenario.py in docs/known-pitfalls.md:433. |
| 71 | docs/known-pitfalls.md:448 | Unprefixed file path `godot_compile_check.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/godot_compile_check.py in docs/known-pitfalls.md:448. |
| 72 | docs/known-pitfalls.md:452 | Unprefixed file path `godot_compile_check.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/godot_compile_check.py in docs/known-pitfalls.md:452. |
| 73 | docs/known-pitfalls.md:452 | Unprefixed file path `godot_cache.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/godot_cache.py in docs/known-pitfalls.md:452. |
| 74 | docs/known-pitfalls.md:453 | Unprefixed file path `run_scenario.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/run_scenario.py in docs/known-pitfalls.md:453. |
| 75 | docs/known-pitfalls.md:456 | Unprefixed file path `slice.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/slice.ps1 in docs/known-pitfalls.md:456. |
| 76 | docs/known-pitfalls.md:463 | Unprefixed file path `slice.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/slice.ps1 in docs/known-pitfalls.md:463. |
| 77 | docs/known-pitfalls.md:471 | Unprefixed file path `slice.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/slice.ps1 in docs/known-pitfalls.md:471. |
| 78 | docs/known-pitfalls.md:471 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in docs/known-pitfalls.md:471. |
| 79 | docs/known-pitfalls.md:521 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in docs/known-pitfalls.md:521. |
| 80 | docs/known-pitfalls.md:522 | Stale tool/script `tools/headless/jobs.py::_pid_is_live` | docs/agent-rules.md Rule 1: Invoking deleted scripts fails execution | high | Remove or update script reference in docs/known-pitfalls.md:522. |
| 81 | docs/known-pitfalls.md:540 | Non-existent file `meadow_profile.json` | docs/agent-rules.md Rule 1: Document points to missing file | high | Update file reference in docs/known-pitfalls.md:540. |
| 82 | docs/known-pitfalls.md:544 | Unprefixed file path `layout_panels.json` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tests/fixtures/layout_panels.json in docs/known-pitfalls.md:544. |
| 83 | docs/known-pitfalls.md:562 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in docs/known-pitfalls.md:562. |
| 84 | docs/known-pitfalls.md:613 | Unprefixed tool path `../../tools/prefinish.py` | docs/known-pitfalls.md: Command without tools/ prefix fails in bash | high | Prefix tool path with tools/ in docs/known-pitfalls.md:613. |
| 85 | docs/known-pitfalls.md:617 | Stale tool/script `tools/...` | docs/agent-rules.md Rule 1: Invoking deleted scripts fails execution | high | Remove or update script reference in docs/known-pitfalls.md:617. |
| 86 | plans/reference/check-loop.md:21 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in plans/reference/check-loop.md:21. |
| 87 | plans/reference/check-loop.md:81 | Unprefixed file path `ui_layout.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/ui_layout.gd in plans/reference/check-loop.md:81. |
| 88 | plans/reference/check-loop.md:151 | Unprefixed file path `debug_panel.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/debug_panel.gd in plans/reference/check-loop.md:151. |
| 89 | plans/reference/closeout.md:74 | Unprefixed file path `refill_lane.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/refill_lane.py in plans/reference/closeout.md:74. |
| 90 | plans/reference/closeout.md:96 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in plans/reference/closeout.md:96. |
| 91 | plans/reference/colony-diagnostics.md:15 | Unprefixed file path `colony_diagnostics.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/colony_diagnostics.gd in plans/reference/colony-diagnostics.md:15. |
| 92 | plans/reference/colony-diagnostics.md:39 | Unprefixed file path `problem_messages.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/problem_messages.gd in plans/reference/colony-diagnostics.md:39. |
| 93 | plans/reference/colony-diagnostics.md:40 | Unprefixed file path `diagnostic_log.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/diagnostic_log.gd in plans/reference/colony-diagnostics.md:40. |
| 94 | plans/reference/colony-diagnostics.md:47 | Unprefixed file path `year_winter.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/year_winter.gd in plans/reference/colony-diagnostics.md:47. |
| 95 | plans/reference/colony-diagnostics.md:63 | Unprefixed file path `year_winter.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/year_winter.gd in plans/reference/colony-diagnostics.md:63. |
| 96 | plans/reference/colony-diagnostics.md:63 | Unprefixed file path `year_winter.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/year_winter.gd in plans/reference/colony-diagnostics.md:63. |
| 97 | plans/reference/colony-diagnostics.md:68 | Unprefixed file path `colony_diagnostics.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/colony_diagnostics.gd in plans/reference/colony-diagnostics.md:68. |
| 98 | plans/reference/colony-diagnostics.md:75 | Unprefixed file path `year_winter.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/year_winter.gd in plans/reference/colony-diagnostics.md:75. |
| 99 | plans/reference/colony-diagnostics.md:100 | Unprefixed file path `year_winter.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/year_winter.gd in plans/reference/colony-diagnostics.md:100. |
| 100 | plans/reference/jules.md:56 | Unprefixed file path `heading.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/heading.py in plans/reference/jules.md:56. |
| 101 | plans/reference/jules.md:96 | Stale tool/script `-m` | docs/agent-rules.md Rule 1: Invoking deleted scripts fails execution | high | Remove or update script reference in plans/reference/jules.md:96. |
| 102 | plans/reference/jules.md:198 | Unprefixed file path `SPRITES.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to assets/sprites/SPRITES.md in plans/reference/jules.md:198. |
| 103 | plans/reference/jules.md:201 | Unprefixed file path `SPRITES.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to assets/sprites/SPRITES.md in plans/reference/jules.md:201. |
| 104 | plans/reference/jules.md:241 | Unprefixed file path `session_cost.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/session_cost.py in plans/reference/jules.md:241. |
| 105 | plans/reference/jules.md:335 | Unprefixed file path `saving.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/saving.gd in plans/reference/jules.md:335. |
| 106 | plans/reference/jules.md:410 | Unprefixed file path `roles.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/roles.gd in plans/reference/jules.md:410. |
| 107 | plans/reference/jules.md:445 | Stale tool/script `tools/*.py` | docs/agent-rules.md Rule 1: Invoking deleted scripts fails execution | high | Remove or update script reference in plans/reference/jules.md:445. |
| 108 | plans/reference/jules.md:445 | Stale tool/script `tools/*.ps1` | docs/agent-rules.md Rule 1: Invoking deleted scripts fails execution | high | Remove or update script reference in plans/reference/jules.md:445. |
| 109 | plans/reference/jules.md:488 | Stale tool/script `tools/*.py` | docs/agent-rules.md Rule 1: Invoking deleted scripts fails execution | high | Remove or update script reference in plans/reference/jules.md:488. |
| 110 | plans/reference/review-contract.md:102 | Unprefixed file path `check_docs.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/check_docs.py in plans/reference/review-contract.md:102. |
| 111 | plans/reference/reviews/README.md:36 | Unprefixed file path `check-processor.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/check-processor.md in plans/reference/reviews/README.md:36. |
| 112 | plans/reference/reviews/README.md:37 | Unprefixed file path `product-review.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/product-review.md in plans/reference/reviews/README.md:37. |
| 113 | plans/reference/reviews/README.md:38 | Unprefixed file path `plan-review.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/plan-review.md in plans/reference/reviews/README.md:38. |
| 114 | plans/reference/reviews/README.md:39 | Unprefixed file path `architecture-review.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/architecture-review.md in plans/reference/reviews/README.md:39. |
| 115 | plans/reference/reviews/README.md:40 | Unprefixed file path `data-catalogue-review.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/data-catalogue-review.md in plans/reference/reviews/README.md:40. |
| 116 | plans/reference/reviews/README.md:41 | Unprefixed file path `gameplay-review.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/gameplay-review.md in plans/reference/reviews/README.md:41. |
| 117 | plans/reference/reviews/README.md:42 | Unprefixed file path `performance-review.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/performance-review.md in plans/reference/reviews/README.md:42. |
| 118 | plans/reference/reviews/README.md:43 | Unprefixed file path `save-review.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/save-review.md in plans/reference/reviews/README.md:43. |
| 119 | plans/reference/reviews/README.md:44 | Unprefixed file path `ui-review.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/ui-review.md in plans/reference/reviews/README.md:44. |
| 120 | plans/reference/reviews/README.md:45 | Unprefixed file path `verification-review.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/verification-review.md in plans/reference/reviews/README.md:45. |
| 121 | plans/reference/reviews/README.md:46 | Unprefixed file path `context-review.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/context-review.md in plans/reference/reviews/README.md:46. |
| 122 | plans/reference/reviews/README.md:47 | Unprefixed file path `agent-workflow-codex.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/agent-workflow-codex.md in plans/reference/reviews/README.md:47. |
| 123 | plans/reference/reviews/README.md:48 | Unprefixed file path `agent-workflow-review.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/agent-workflow-review.md in plans/reference/reviews/README.md:48. |
| 124 | plans/reference/reviews/agent-workflow-codex.md:8 | Unprefixed file path `agent-workflow-review.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to plans/reference/reviews/agent-workflow-review.md in plans/reference/reviews/agent-workflow-codex.md:8. |
| 125 | plans/reference/reviews/check-processor.md:31 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in plans/reference/reviews/check-processor.md:31. |
| 126 | plans/reference/reviews/context-review.md:39 | Unprefixed file path `check_docs.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/check_docs.py in plans/reference/reviews/context-review.md:39. |
| 127 | plans/reference/reviews/plan-review.md:23 | Unprefixed file path `check_docs.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/check_docs.py in plans/reference/reviews/plan-review.md:23. |
| 128 | plans/reference/slice-worker.md:34 | Stale tool/script `<that` | docs/agent-rules.md Rule 1: Invoking deleted scripts fails execution | high | Remove or update script reference in plans/reference/slice-worker.md:34. |
| 129 | plans/reference/slice-worker.md:55 | Unprefixed file path `simulation.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to .claude/rules/simulation.md in plans/reference/slice-worker.md:55. |
| 130 | plans/reference/slice-worker.md:55 | Unprefixed file path `saving.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to .claude/rules/saving.md in plans/reference/slice-worker.md:55. |
| 131 | plans/reference/slice-worker.md:55 | Unprefixed file path `performance.md` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to .claude/rules/performance.md in plans/reference/slice-worker.md:55. |
| 132 | plans/reference/slice-worker.md:71 | Unprefixed file path `verify.ps1` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/verify.ps1 in plans/reference/slice-worker.md:71. |
| 133 | plans/reference/slice-worker.md:74 | Unprefixed file path `godot_compile_check.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tools/godot_compile_check.py in plans/reference/slice-worker.md:74. |
| 134 | plans/reference/slice-worker.md:75 | Unprefixed file path `source_checks.py` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to tests/source_checks.py in plans/reference/slice-worker.md:75. |
| 135 | plans/reference/technical-audit.md:31 | Unprefixed file path `prerequisites.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/prerequisites.gd in plans/reference/technical-audit.md:31. |
| 136 | plans/reference/technical-audit.md:31 | Unprefixed file path `stage_gate.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/stage_gate.gd in plans/reference/technical-audit.md:31. |
| 137 | plans/reference/technical-audit.md:32 | Unprefixed file path `roles.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/roles.gd in plans/reference/technical-audit.md:32. |
| 138 | plans/reference/technical-audit.md:33 | Unprefixed file path `bee_enums.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/bee_enums.gd in plans/reference/technical-audit.md:33. |
| 139 | plans/reference/technical-audit.md:53 | Unprefixed file path `bee.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/bee.gd in plans/reference/technical-audit.md:53. |
| 140 | plans/reference/technical-audit.md:54 | Unprefixed file path `saving.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/saving.gd in plans/reference/technical-audit.md:54. |
| 141 | plans/reference/technical-audit.md:62 | Unprefixed file path `saving.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/saving.gd in plans/reference/technical-audit.md:62. |
| 142 | plans/reference/technical-audit.md:62 | Unprefixed file path `save_migrations.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/save_migrations.gd in plans/reference/technical-audit.md:62. |
| 143 | plans/reference/technical-audit.md:65 | Unprefixed file path `save_migrations.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/save_migrations.gd in plans/reference/technical-audit.md:65. |
| 144 | plans/reference/technical-audit.md:90 | Unprefixed file path `hive.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/hive.gd in plans/reference/technical-audit.md:90. |
| 145 | plans/reference/technical-audit.md:157 | Unprefixed file path `year_winter.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/year_winter.gd in plans/reference/technical-audit.md:157. |
| 146 | plans/reference/technical-audit.md:162 | Unprefixed file path `season.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/season.gd in plans/reference/technical-audit.md:162. |
| 147 | plans/reference/technical-audit.md:176 | Unprefixed file path `hive.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/hive.gd in plans/reference/technical-audit.md:176. |
| 148 | plans/reference/technical-audit.md:183 | Unprefixed file path `bee.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/bee.gd in plans/reference/technical-audit.md:183. |
| 149 | plans/reference/ui-rules.md:16 | Unprefixed file path `ui_layout.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/ui_layout.gd in plans/reference/ui-rules.md:16. |
| 150 | plans/reference/ui-rules.md:44 | Unprefixed file path `ui_layout.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/ui_layout.gd in plans/reference/ui-rules.md:44. |
| 151 | plans/reference/ui-rules.md:62 | Unprefixed file path `ui_layout.gd` | docs/agent-rules.md Rule 1: Stale path reference in doc | high | Update path to scripts/ui_layout.gd in plans/reference/ui-rules.md:62. |

## Candidate Jules tasks

### J-? -- Add documentation check for tools/heading.py title existence
Files: tools/check_docs.py
After: none
Why: Stale heading titles in instruction files cause heading command failures during agent execution.
Do: Add validation in tools/check_docs.py to parse heading.py references in .md files and confirm heading string exists in target markdown file.

free  tools/check_docs.py

## For Claude or Codex

- .claude/rules/gdscript.md:18: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- .claude/rules/gdscript.md:26: Unprefixed file path `source_checks.py` (plan: plans/now/code-health.md)
- .claude/rules/gdscript.md:28: Unprefixed file path `bee_survival.gd` (plan: plans/now/code-health.md)
- .claude/rules/gdscript.md:43: Unprefixed file path `input_selection.gd` (plan: plans/now/code-health.md)
- .claude/rules/gdscript.md:43: Unprefixed file path `fog_of_war.gd` (plan: plans/now/code-health.md)
- .claude/rules/gdscript.md:44: Unprefixed file path `world_building.gd` (plan: plans/now/code-health.md)
- .claude/rules/gdscript.md:44: Unprefixed file path `func.py` (plan: plans/now/code-health.md)
- .claude/rules/gdscript.md:46: Unprefixed file path `bee.gd` (plan: plans/now/code-health.md)
- .claude/rules/gdscript.md:46: Stale tool/script `-m` (plan: plans/now/code-health.md)
- .claude/rules/gdscript.md:46: Stale tool/script `-m` (plan: plans/now/code-health.md)
- .claude/rules/headless.md:24: Non-existent file `failure.json` (plan: plans/now/code-health.md)
- .claude/rules/headless.md:29: Unprefixed file path `game_config.gd` (plan: plans/now/code-health.md)
- .claude/rules/headless.md:32: Unprefixed file path `challenge_runner.gd` (plan: plans/now/code-health.md)
- .claude/rules/lifecycle-tooling.md:40: Unprefixed file path `review_due.py` (plan: plans/now/code-health.md)
- .claude/rules/lifecycle-tooling.md:42: Stale tool/script `-m` (plan: plans/now/code-health.md)
- .claude/rules/performance.md:16: Unprefixed file path `perf.gd` (plan: plans/now/code-health.md)
- .claude/rules/saving.md:20: Unprefixed file path `save_migrations.gd` (plan: plans/now/code-health.md)
- .claude/rules/saving.md:30: Unprefixed file path `foraging_stats.gd` (plan: plans/now/code-health.md)
- .claude/rules/saving.md:47: Unprefixed file path `save_v1.json` (plan: plans/now/code-health.md)
- .claude/rules/saving.md:47: Unprefixed file path `save_v2.json` (plan: plans/now/code-health.md)
- .claude/rules/saving.md:58: Unprefixed file path `saving.gd` (plan: plans/now/code-health.md)
- .claude/rules/simulation.md:23: Unprefixed file path `roles.gd` (plan: plans/now/code-health.md)
- .claude/rules/simulation.md:26: Unprefixed file path `roles.gd` (plan: plans/now/code-health.md)
- .claude/rules/simulation.md:26: Unprefixed file path `bee.gd` (plan: plans/now/code-health.md)
- .claude/rules/simulation.md:56: Unprefixed file path `hive.gd` (plan: plans/now/code-health.md)
- .claude/rules/simulation.md:56: Unprefixed file path `world_building.gd` (plan: plans/now/code-health.md)
- .claude/rules/ui.md:19: Unprefixed file path `hud.gd` (plan: plans/now/code-health.md)
- .claude/rules/ui.md:20: Unprefixed file path `hud.gd` (plan: plans/now/code-health.md)
- .claude/rules/ui.md:22: Unprefixed file path `ui_layout.gd` (plan: plans/now/code-health.md)
- .claude/rules/ui.md:24: Unprefixed file path `ui_theme.gd` (plan: plans/now/code-health.md)
- .claude/rules/ui.md:31: Unprefixed file path `game_config.gd` (plan: plans/now/code-health.md)
- .claude/rules/ui.md:34: Unprefixed file path `roles.gd` (plan: plans/now/code-health.md)
- .claude/rules/ui.md:35: Unprefixed file path `session.gd` (plan: plans/now/code-health.md)
- AGENTS.md:21: Unprefixed file path `hive_cell.gd` (plan: plans/now/code-health.md)
- CLAUDE.md:45: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- docs/agent-rules.md:11: Target doc `<file>` in heading command (plan: plans/now/code-health.md)
- docs/agent-rules.md:35: Stale tool/script `tools/...` (plan: plans/now/code-health.md)
- docs/agent-rules.md:55: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:75: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:98: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:99: Unprefixed file path `run_scenario.py` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:133: Non-existent file `job.json` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:133: Non-existent file `status.json` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:136: Non-existent file `result.json` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:156: Non-existent file `result.json` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:158: Non-existent file `failure.json` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:161: Non-existent file `report.json` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:171: Non-existent file `result.json` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:201: Non-existent file `failure.json` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:257: Non-existent file `result.json` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:436: Non-existent file `result.json` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:440: Non-existent file `report.json` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:448: Non-existent file `result.json` (plan: plans/now/code-health.md)
- docs/headless-run-contract.md:458: Non-existent file `result.json` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:59: Unprefixed file path `hud.gd` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:116: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:121: Unprefixed file path `ui_theme.gd` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:153: Unprefixed file path `main.gd` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:153: Unprefixed file path `source_checks.py` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:183: Unprefixed file path `hud.gd` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:190: Unprefixed file path `bee.gd` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:218: Unprefixed file path `perf.gd` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:225: Unprefixed file path `world_building.gd` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:274: Unprefixed file path `bee_foraging.gd` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:275: Unprefixed file path `bee.gd` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:280: Unprefixed file path `source_checks.py` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:298: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:299: Unprefixed file path `run_scenario.py` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:412: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:433: Unprefixed file path `run_scenario.py` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:448: Unprefixed file path `godot_compile_check.py` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:452: Unprefixed file path `godot_compile_check.py` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:452: Unprefixed file path `godot_cache.py` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:453: Unprefixed file path `run_scenario.py` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:456: Unprefixed file path `slice.ps1` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:463: Unprefixed file path `slice.ps1` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:471: Unprefixed file path `slice.ps1` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:471: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:521: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:522: Stale tool/script `tools/headless/jobs.py::_pid_is_live` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:540: Non-existent file `meadow_profile.json` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:544: Unprefixed file path `layout_panels.json` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:562: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:613: Unprefixed tool path `../../tools/prefinish.py` (plan: plans/now/code-health.md)
- docs/known-pitfalls.md:617: Stale tool/script `tools/...` (plan: plans/now/code-health.md)
- plans/reference/check-loop.md:21: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- plans/reference/check-loop.md:81: Unprefixed file path `ui_layout.gd` (plan: plans/now/code-health.md)
- plans/reference/check-loop.md:151: Unprefixed file path `debug_panel.gd` (plan: plans/now/code-health.md)
- plans/reference/closeout.md:74: Unprefixed file path `refill_lane.py` (plan: plans/now/code-health.md)
- plans/reference/closeout.md:96: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- plans/reference/colony-diagnostics.md:15: Unprefixed file path `colony_diagnostics.gd` (plan: plans/now/code-health.md)
- plans/reference/colony-diagnostics.md:39: Unprefixed file path `problem_messages.gd` (plan: plans/now/code-health.md)
- plans/reference/colony-diagnostics.md:40: Unprefixed file path `diagnostic_log.gd` (plan: plans/now/code-health.md)
- plans/reference/colony-diagnostics.md:47: Unprefixed file path `year_winter.gd` (plan: plans/now/code-health.md)
- plans/reference/colony-diagnostics.md:63: Unprefixed file path `year_winter.gd` (plan: plans/now/code-health.md)
- plans/reference/colony-diagnostics.md:63: Unprefixed file path `year_winter.gd` (plan: plans/now/code-health.md)
- plans/reference/colony-diagnostics.md:68: Unprefixed file path `colony_diagnostics.gd` (plan: plans/now/code-health.md)
- plans/reference/colony-diagnostics.md:75: Unprefixed file path `year_winter.gd` (plan: plans/now/code-health.md)
- plans/reference/colony-diagnostics.md:100: Unprefixed file path `year_winter.gd` (plan: plans/now/code-health.md)
- plans/reference/jules.md:56: Unprefixed file path `heading.py` (plan: plans/now/code-health.md)
- plans/reference/jules.md:96: Stale tool/script `-m` (plan: plans/now/code-health.md)
- plans/reference/jules.md:198: Unprefixed file path `SPRITES.md` (plan: plans/now/code-health.md)
- plans/reference/jules.md:201: Unprefixed file path `SPRITES.md` (plan: plans/now/code-health.md)
- plans/reference/jules.md:241: Unprefixed file path `session_cost.py` (plan: plans/now/code-health.md)
- plans/reference/jules.md:335: Unprefixed file path `saving.gd` (plan: plans/now/code-health.md)
- plans/reference/jules.md:410: Unprefixed file path `roles.gd` (plan: plans/now/code-health.md)
- plans/reference/jules.md:445: Stale tool/script `tools/*.py` (plan: plans/now/code-health.md)
- plans/reference/jules.md:445: Stale tool/script `tools/*.ps1` (plan: plans/now/code-health.md)
- plans/reference/jules.md:488: Stale tool/script `tools/*.py` (plan: plans/now/code-health.md)
- plans/reference/review-contract.md:102: Unprefixed file path `check_docs.py` (plan: plans/now/code-health.md)
- plans/reference/reviews/README.md:36: Unprefixed file path `check-processor.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/README.md:37: Unprefixed file path `product-review.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/README.md:38: Unprefixed file path `plan-review.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/README.md:39: Unprefixed file path `architecture-review.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/README.md:40: Unprefixed file path `data-catalogue-review.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/README.md:41: Unprefixed file path `gameplay-review.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/README.md:42: Unprefixed file path `performance-review.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/README.md:43: Unprefixed file path `save-review.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/README.md:44: Unprefixed file path `ui-review.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/README.md:45: Unprefixed file path `verification-review.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/README.md:46: Unprefixed file path `context-review.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/README.md:47: Unprefixed file path `agent-workflow-codex.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/README.md:48: Unprefixed file path `agent-workflow-review.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/agent-workflow-codex.md:8: Unprefixed file path `agent-workflow-review.md` (plan: plans/now/code-health.md)
- plans/reference/reviews/check-processor.md:31: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- plans/reference/reviews/context-review.md:39: Unprefixed file path `check_docs.py` (plan: plans/now/code-health.md)
- plans/reference/reviews/plan-review.md:23: Unprefixed file path `check_docs.py` (plan: plans/now/code-health.md)
- plans/reference/slice-worker.md:34: Stale tool/script `<that` (plan: plans/now/code-health.md)
- plans/reference/slice-worker.md:55: Unprefixed file path `simulation.md` (plan: plans/now/code-health.md)
- plans/reference/slice-worker.md:55: Unprefixed file path `saving.md` (plan: plans/now/code-health.md)
- plans/reference/slice-worker.md:55: Unprefixed file path `performance.md` (plan: plans/now/code-health.md)
- plans/reference/slice-worker.md:71: Unprefixed file path `verify.ps1` (plan: plans/now/code-health.md)
- plans/reference/slice-worker.md:74: Unprefixed file path `godot_compile_check.py` (plan: plans/now/code-health.md)
- plans/reference/slice-worker.md:75: Unprefixed file path `source_checks.py` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:31: Unprefixed file path `prerequisites.gd` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:31: Unprefixed file path `stage_gate.gd` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:32: Unprefixed file path `roles.gd` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:33: Unprefixed file path `bee_enums.gd` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:53: Unprefixed file path `bee.gd` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:54: Unprefixed file path `saving.gd` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:62: Unprefixed file path `saving.gd` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:62: Unprefixed file path `save_migrations.gd` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:65: Unprefixed file path `save_migrations.gd` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:90: Unprefixed file path `hive.gd` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:157: Unprefixed file path `year_winter.gd` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:162: Unprefixed file path `season.gd` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:176: Unprefixed file path `hive.gd` (plan: plans/now/code-health.md)
- plans/reference/technical-audit.md:183: Unprefixed file path `bee.gd` (plan: plans/now/code-health.md)
- plans/reference/ui-rules.md:16: Unprefixed file path `ui_layout.gd` (plan: plans/now/code-health.md)
- plans/reference/ui-rules.md:44: Unprefixed file path `ui_layout.gd` (plan: plans/now/code-health.md)
- plans/reference/ui-rules.md:62: Unprefixed file path `ui_layout.gd` (plan: plans/now/code-health.md)

## Inventory

| Path:Line | Item | Status |
|---|---|---|
| .claude/rules/documentation.md:10 | `NEXTSTEPS.md` | present |
| .claude/rules/documentation.md:12 | `Plan:` | present |
| .claude/rules/documentation.md:13 | `plans/archive/` | present |
| .claude/rules/documentation.md:15 | `## Next up` | present |
| .claude/rules/documentation.md:15 | `### Claude lane` | present |
| .claude/rules/documentation.md:15 | `### Codex lane` | present |
| .claude/rules/documentation.md:16 | `[Claude]` | present |
| .claude/rules/documentation.md:16 | `[Codex]` | present |
| .claude/rules/documentation.md:17 | `Plan:` | present |
| .claude/rules/documentation.md:17 | `Files:` | present |
| .claude/rules/documentation.md:17 | `Check:` | present |
| .claude/rules/documentation.md:17 | `Proof:` | present |
| .claude/rules/documentation.md:17 | `Next after:` | present |
| .claude/rules/documentation.md:22 | `finish` | present |
| .claude/rules/documentation.md:23 | `lane dry: <lane> -- refill before the next start` | present |
| .claude/rules/documentation.md:24 | `tools/check_docs.py` | present |
| .claude/rules/documentation.md:24 | `start` | present |
| .claude/rules/documentation.md:25 | `finish` | present |
| .claude/rules/documentation.md:26 | `Next after:` | present |
| .claude/rules/documentation.md:27 | `none -- <plan> is complete` | present |
| .claude/rules/documentation.md:30 | `advice.dry_after` | present |
| .claude/rules/documentation.md:36 | `queue` | present |
| .claude/rules/documentation.md:37 | `**[Lane] <id> -- <title>**` | present |
| .claude/rules/documentation.md:37 | `Plan:` | present |
| .claude/rules/documentation.md:37 | `Files:` | present |
| .claude/rules/documentation.md:37 | `Check:` | present |
| .claude/rules/documentation.md:38 | `Proof:` | present |
| .claude/rules/documentation.md:38 | `Next after:` | present |
| .claude/rules/documentation.md:38 | `tools/backlog.py` | present |
| .claude/rules/documentation.md:39 | `tools/refill_lane.py --add <id>` | present |
| .claude/rules/documentation.md:39 | `--top-up` | present |
| .claude/rules/documentation.md:40 | `tools/slice.ps1 finish` | present |
| .claude/rules/documentation.md:41 | `tools/check_docs.py` | present |
| .claude/rules/documentation.md:43 | `Proof:` | present |
| .claude/rules/documentation.md:47 | `queue-gated` | present |
| .claude/rules/documentation.md:50 | `## Not in the queue, and why` | present |
| .claude/rules/documentation.md:50 | `/run-queue` | present |
| .claude/rules/documentation.md:54 | `plans/reference/closeout.md` | present |
| .claude/rules/documentation.md:55 | `Proof:` | present |
| .claude/rules/documentation.md:56 | `Files:` | present |
| .claude/rules/documentation.md:61 | `Proof:` | present |
| .claude/rules/documentation.md:62 | `present:` | present |
| .claude/rules/documentation.md:62 | `absent: <path> :: <substring>` | present |
| .claude/rules/documentation.md:64 | `## Not in the queue, and why` | present |
| .claude/rules/documentation.md:65 | `Next after:` | present |
| .claude/rules/documentation.md:68 | `## Not in the queue, and why` | present |
| .claude/rules/documentation.md:69 | `tools/slice.ps1 finish` | present |
| .claude/rules/documentation.md:70 | `queue-gated` | present |
| .claude/rules/documentation.md:71 | `Next after:` | present |
| .claude/rules/documentation.md:71 | `none` | present |
| .claude/rules/documentation.md:73 | `tools/check_docs.py` | present |
| .claude/rules/documentation.md:74 | `finish` | present |
| .claude/rules/documentation.md:74 | `plans/reference/closeout.md` | present |
| .claude/rules/documentation.md:76 | `NEXTSTEPS.md` | present |
| .claude/rules/documentation.md:76 | `tools/slice.ps1 start` | present |
| .claude/rules/documentation.md:77 | `doctor` | present |
| .claude/rules/documentation.md:80 | `plans/now/` | present |
| .claude/rules/documentation.md:80 | `plans/active/` | present |
| .claude/rules/documentation.md:80 | `plans/design/` | present |
| .claude/rules/documentation.md:81 | `plans/reference/` | present |
| .claude/rules/documentation.md:85 | `plans/README.md` | present |
| .claude/rules/documentation.md:88 | `finish` | present |
| .claude/rules/documentation.md:89 | `plans/archive/` | present |
| .claude/rules/documentation.md:90 | `tools/archive_slice.py` | present |
| .claude/rules/documentation.md:90 | `tools/check_docs.py` | present |
| .claude/rules/documentation.md:90 | `plans/now/` | present |
| .claude/rules/documentation.md:96 | `ROADMAP.md` | present |
| .claude/rules/documentation.md:96 | `DESIGN_BACKLOG.md` | present |
| .claude/rules/documentation.md:98 | `tools/check_docs.py` | present |
| .claude/rules/documentation.md:98 | `tools/verify.ps1` | present |
| .claude/rules/documentation.md:100 | `Proof:` | present |
| .claude/rules/documentation.md:101 | `plans/README.md` | present |
| .claude/rules/documentation.md:105 | `plans/README.md` | present |
| .claude/rules/gdscript.md:8 | `docs/known-pitfalls.md` | present |
| .claude/rules/gdscript.md:9 | `python tools/heading.py` | present |
| .claude/rules/gdscript.md:16 | `-PythonPath` | present |
| .claude/rules/gdscript.md:16 | `PATH` | present |
| .claude/rules/gdscript.md:18 | `verify.ps1` | moved to tools/verify.ps1 |
| .claude/rules/gdscript.md:18 | `tools/gdscript_style.py` | present |
| .claude/rules/gdscript.md:18 | `gdlintrc` | present |
| .claude/rules/gdscript.md:18 | `# gdlint: ignore=<rule>` | present |
| .claude/rules/gdscript.md:20 | `CLAUDE.md` | present |
| .claude/rules/gdscript.md:20 | `mcp__godot__*` | present |
| .claude/rules/gdscript.md:23 | `:=` | present |
| .claude/rules/gdscript.md:23 | `var x := some_loosely_typed_ref.SomeClass.new()` | present |
| .claude/rules/gdscript.md:25 | `main.X` | present |
| .claude/rules/gdscript.md:25 | `:=` | present |
| .claude/rules/gdscript.md:26 | `source_checks.py` | moved to tests/source_checks.py |
| .claude/rules/gdscript.md:27 | `=` | present |
| .claude/rules/gdscript.md:28 | `bee_survival.gd` | moved to scripts/bee_survival.gd |
| .claude/rules/gdscript.md:28 | `_announce_death` | present |
| .claude/rules/gdscript.md:28 | `world_building.gd::mark_death` | present |
| .claude/rules/gdscript.md:29 | `main.DeathMarker.new()` | present |
| .claude/rules/gdscript.md:32 | `var comb workers := 0` | present |
| .claude/rules/gdscript.md:36 | `offset` | present |
| .claude/rules/gdscript.md:37 | `scale` | present |
| .claude/rules/gdscript.md:41 | `# --- section name ---` | present |
| .claude/rules/gdscript.md:42 | `FUNCTION_MAP.md` | present |
| .claude/rules/gdscript.md:43 | `python tools/func.py` | present |
| .claude/rules/gdscript.md:43 | `input_selection.gd` | moved to scripts/input_selection.gd |
| .claude/rules/gdscript.md:43 | `fog_of_war.gd` | moved to scripts/fog_of_war.gd |
| .claude/rules/gdscript.md:44 | `world_building.gd` | moved to scripts/world_building.gd |
| .claude/rules/gdscript.md:44 | `func.py` | moved to tools/func.py |
| .claude/rules/gdscript.md:46 | `bee.gd` | moved to scripts/bee.gd |
| .claude/rules/gdscript.md:46 | `task_description` | present |
| .claude/rules/gdscript.md:46 | `idle_reason` | present |
| .claude/rules/gdscript.md:46 | `role_name_text` | present |
| .claude/rules/gdscript.md:46 | `carrying_text` | present |
| .claude/rules/gdscript.md:46 | `info_label` | present |
| .claude/rules/gdscript.md:46 | `python -m unittest tests.test_display_text_golden` | gone |
| .claude/rules/gdscript.md:46 | `tests/fixtures/display_text_golden.json` | present |
| .claude/rules/gdscript.md:46 | `python -m tests.test_display_text_golden --update` | gone |
| .claude/rules/headless.md:13 | `docs/headless-run-contract.md` | present |
| .claude/rules/headless.md:14 | `python tools/heading.py` | present |
| .claude/rules/headless.md:19 | `scripts/scenario_actions.gd` | present |
| .claude/rules/headless.md:21 | `docs/challenge-stages.md` | present |
| .claude/rules/headless.md:22 | `python tools/stage_reference.py` | present |
| .claude/rules/headless.md:23 | `python tools/run_scenario.py test_scenarios/<name>.json` | present |
| .claude/rules/headless.md:24 | `failure.json` | gone |
| .claude/rules/headless.md:27 | `advance_challenge_stage` | present |
| .claude/rules/headless.md:28 | `debug_advance_stage()` | present |
| .claude/rules/headless.md:29 | `game_config.gd` | moved to scripts/game_config.gd |
| .claude/rules/headless.md:31 | `docs/agent-rules.md` | present |
| .claude/rules/headless.md:32 | `challenge_runner.gd` | moved to scripts/challenge_runner.gd |
| .claude/rules/headless.md:32 | `.claude/rules/saving.md` | present |
| .claude/rules/headless.md:34 | `docs/agent-rules.md` | present |
| .claude/rules/lifecycle-tooling.md:18 | `tools/slice.ps1` | present |
| .claude/rules/lifecycle-tooling.md:20 | `grep -n "^function <Name>" tools/slice.ps1` | present |
| .claude/rules/lifecycle-tooling.md:26 | `plans/archive/` | present |
| .claude/rules/lifecycle-tooling.md:28 | `tools/check_docs.py` | present |
| .claude/rules/lifecycle-tooling.md:28 | `finish` | present |
| .claude/rules/lifecycle-tooling.md:30 | `archive_slice.py --complete-plans` | present |
| .claude/rules/lifecycle-tooling.md:31 | `plans/archive/` | present |
| .claude/rules/lifecycle-tooling.md:32 | `finish` | present |
| .claude/rules/lifecycle-tooling.md:35 | `tests/test_source_checks.py` | present |
| .claude/rules/lifecycle-tooling.md:36 | `tests/test_slice_lifecycle.py` | present |
| .claude/rules/lifecycle-tooling.md:37 | `tests/test_two_lane_closeout.py` | present |
| .claude/rules/lifecycle-tooling.md:38 | `tests/test_codex_environment.py` | present |
| .claude/rules/lifecycle-tooling.md:39 | `tests/test_review_tools.py` | present |
| .claude/rules/lifecycle-tooling.md:39 | `new_check.py --confirm` | present |
| .claude/rules/lifecycle-tooling.md:40 | `review_due.py` | moved to tools/review_due.py |
| .claude/rules/lifecycle-tooling.md:40 | `tests/workflow_test_support.py` | present |
| .claude/rules/lifecycle-tooling.md:42 | `python -m unittest tests.<module>.<Class>.<test>` | gone |
| .claude/rules/performance.md:11 | `docs/performance.md` | present |
| .claude/rules/performance.md:14 | `_grounded()` | present |
| .claude/rules/performance.md:15 | `plans/archive/PERF_PLAN.md` | present |
| .claude/rules/performance.md:16 | `perf.gd` | moved to scripts/perf.gd |
| .claude/rules/performance.md:18 | `Perf.begin("name")` | present |
| .claude/rules/performance.md:19 | `Perf.end("name")` | present |
| .claude/rules/performance.md:21 | `end` | present |
| .claude/rules/performance.md:22 | `return` | present |
| .claude/rules/performance.md:35 | `speed * delta` | present |
| .claude/rules/performance.md:40 | `fog_of_war_update` | present |
| .claude/rules/performance.md:41 | `fog_of_war_relight` | present |
| .claude/rules/performance.md:43 | `docs/PERFORMANCE_BASELINE.md` | present |
| .claude/rules/saving.md:12 | `plans/reference/technical-audit.md` | present |
| .claude/rules/saving.md:13 | `plans/archive/AUDIT_PLAN_AUG_2026.md` | present |
| .claude/rules/saving.md:17 | `SaveGame.read()` | present |
| .claude/rules/saving.md:18 | `{}` | present |
| .claude/rules/saving.md:18 | `push_error` | present |
| .claude/rules/saving.md:19 | `version` | present |
| .claude/rules/saving.md:19 | `FORMAT_VERSION` | present |
| .claude/rules/saving.md:20 | `save_migrations.gd` | moved to scripts/save_migrations.gd |
| .claude/rules/saving.md:23 | `.get()` | present |
| .claude/rules/saving.md:24 | `FORMAT_VERSION` | present |
| .claude/rules/saving.md:25 | `starting_level` | present |
| .claude/rules/saving.md:25 | `skill_policy` | present |
| .claude/rules/saving.md:26 | `_migrate_N_to_N+1` | present |
| .claude/rules/saving.md:29 | `history_samples` | present |
| .claude/rules/saving.md:29 | `emergence_log` | present |
| .claude/rules/saving.md:29 | `day_store_totals` | present |
| .claude/rules/saving.md:30 | `foraging_stats.gd` | moved to scripts/foraging_stats.gd |
| .claude/rules/saving.md:30 | `readout_history` | present |
| .claude/rules/saving.md:34 | `plans/now/run-repairs.md` | present |
| .claude/rules/saving.md:37 | `_restore` | present |
| .claude/rules/saving.md:37 | `restore_slot` | present |
| .claude/rules/saving.md:42 | `runs` | present |
| .claude/rules/saving.md:43 | `tests/fixtures/saves/` | present |
| .claude/rules/saving.md:44 | `saving._restore` | present |
| .claude/rules/saving.md:44 | `restore_slot` | present |
| .claude/rules/saving.md:47 | `save_v1.json` | moved to tests/fixtures/save_v1.json |
| .claude/rules/saving.md:47 | `save_v2.json` | moved to tests/fixtures/save_v2.json |
| .claude/rules/saving.md:49 | `test_scenarios/cq_s0_*_capture.json` | present |
| .claude/rules/saving.md:51 | `KNOWN_DIFFERENCES` | present |
| .claude/rules/saving.md:55 | `queue_free()` | present |
| .claude/rules/saving.md:57 | `get_nodes_in_group(...)` | present |
| .claude/rules/saving.md:58 | `_restore_flowers()` | present |
| .claude/rules/saving.md:58 | `_restore_bees()` | present |
| .claude/rules/saving.md:58 | `saving.gd` | moved to scripts/saving.gd |
| .claude/rules/saving.md:60 | `flower_grid.rebuild()` | present |
| .claude/rules/saving.md:61 | `_retire_node(node, group_name)` | present |
| .claude/rules/saving.md:62 | `queue_free()` | present |
| .claude/rules/saving.md:66 | `SaveGame` | present |
| .claude/rules/saving.md:68 | `debug_panel.gd::set_save_load_enabled(false)` | present |
| .claude/rules/saving.md:69 | `challenge_runner.gd::start()` | present |
| .claude/rules/saving.md:69 | `_complete()` | present |
| .claude/rules/saving.md:70 | `SaveGame` | present |
| .claude/rules/saving.md:71 | `DESIGN_BACKLOG.md` | present |
| .claude/rules/saving.md:74 | `TutorialCheckpoint.clear()` | present |
| .claude/rules/saving.md:75 | `main.gd::_ready()` | present |
| .claude/rules/saving.md:78 | `clear()` | present |
| .claude/rules/saving.md:80 | `GameConfig` | present |
| .claude/rules/saving.md:81 | `GAMECONFIG_WRITE_ALLOWLIST` | present |
| .claude/rules/saving.md:81 | `tests/source_checks.py` | present |
| .claude/rules/saving.md:82 | `check_gameconfig_writes` | present |
| .claude/rules/saving.md:85 | `HiveCell.build_time_override` | present |
| .claude/rules/saving.md:85 | `effective_build_time()` | present |
| .claude/rules/simulation.md:14 | `docs/known-pitfalls.md` | present |
| .claude/rules/simulation.md:15 | `python tools/heading.py` | present |
| .claude/rules/simulation.md:18 | `main.gd.is_on_screen(node)` | present |
| .claude/rules/simulation.md:23 | `roles.gd` | moved to scripts/roles.gd |
| .claude/rules/simulation.md:26 | `roles.gd` | moved to scripts/roles.gd |
| .claude/rules/simulation.md:26 | `bee.gd` | moved to scripts/bee.gd |
| .claude/rules/simulation.md:27 | `Role.BUILDER` | present |
| .claude/rules/simulation.md:27 | `Role.NURSERY` | present |
| .claude/rules/simulation.md:30 | `GameConfig` | present |
| .claude/rules/simulation.md:30 | `Session` | present |
| .claude/rules/simulation.md:32 | `GameConfig` | present |
| .claude/rules/simulation.md:33 | `tests/source_checks.py` | present |
| .claude/rules/simulation.md:33 | `GAMECONFIG_WRITE_ALLOWLIST` | present |
| .claude/rules/simulation.md:34 | `.claude/rules/saving.md` | present |
| .claude/rules/simulation.md:35 | `Session` | present |
| .claude/rules/simulation.md:37 | `hive_root` | present |
| .claude/rules/simulation.md:37 | `meadow_root` | present |
| .claude/rules/simulation.md:38 | `position` | present |
| .claude/rules/simulation.md:48 | `bee_status.gd::grounded()` | present |
| .claude/rules/simulation.md:49 | `docs/known-pitfalls.md` | present |
| .claude/rules/simulation.md:55 | `docs/known-pitfalls.md` | present |
| .claude/rules/simulation.md:56 | `hive.gd` | moved to scripts/hive.gd |
| .claude/rules/simulation.md:56 | `world_building.gd` | moved to scripts/world_building.gd |
| .claude/rules/simulation.md:78 | `docs/headless-run-contract.md` | present |
| .claude/rules/simulation.md:79 | `nectar_per_honey` | present |
| .claude/rules/simulation.md:80 | `honey_energy_factor` | present |
| .claude/rules/simulation.md:81 | `tests/source_checks.py` | present |
| .claude/rules/simulation.md:82 | `check_honey_conserves_energy` | present |
| .claude/rules/simulation.md:86 | `season.gd::_resolve_winter` | present |
| .claude/rules/simulation.md:86 | `nectar_since` | present |
| .claude/rules/simulation.md:87 | `bee_bread_sealed_at` | present |
| .claude/rules/simulation.md:92 | `skill_tree_panel.gd::_stores` | present |
| .claude/rules/simulation.md:93 | `hive.gd::take("nectar")` | present |
| .claude/rules/ui.md:15 | `python tools/heading.py plans/reference/ui-rules.md "Durable rules"` | present |
| .claude/rules/ui.md:16 | `docs/known-pitfalls.md` | present |
| .claude/rules/ui.md:19 | `hud.gd` | moved to scripts/hud.gd |
| .claude/rules/ui.md:19 | `python tools/func.py scripts/hud.gd <name>` | present |
| .claude/rules/ui.md:20 | `FUNCTION_MAP.md` | present |
| .claude/rules/ui.md:20 | `hud.gd` | moved to scripts/hud.gd |
| .claude/rules/ui.md:22 | `ui_layout.gd` | moved to scripts/ui_layout.gd |
| .claude/rules/ui.md:23 | `ui_panel_layout.gd::apply()` | present |
| .claude/rules/ui.md:24 | `UiTheme` | present |
| .claude/rules/ui.md:24 | `ui_theme.gd` | moved to scripts/ui_theme.gd |
| .claude/rules/ui.md:25 | `scripts/scenario_actions.gd` | present |
| .claude/rules/ui.md:26 | `tests/fixtures/layout_panels.json` | present |
| .claude/rules/ui.md:31 | `game_config.gd` | moved to scripts/game_config.gd |
| .claude/rules/ui.md:32 | `GameConfig` | present |
| .claude/rules/ui.md:32 | `tests/source_checks.py` | present |
| .claude/rules/ui.md:33 | `GAMECONFIG_WRITE_ALLOWLIST` | present |
| .claude/rules/ui.md:34 | `roles.gd` | moved to scripts/roles.gd |
| .claude/rules/ui.md:35 | `Session` | present |
| .claude/rules/ui.md:35 | `session.gd` | moved to scripts/session.gd |
| .claude/rules/ui.md:36 | `.claude/rules/saving.md` | present |
| .claude/rules/ui.md:39 | `plans/reference/closeout.md` | present |
| AGENTS.md:10 | `tools/slice.ps1` | present |
| AGENTS.md:10 | `CHATGPT.md` | present |
| AGENTS.md:11 | `NEXTSTEPS.md` | present |
| AGENTS.md:11 | `plans/workstreams.md` | present |
| AGENTS.md:11 | `plans/now/` | present |
| AGENTS.md:11 | `checks/` | present |
| AGENTS.md:12 | `FUNCTION_MAP.md` | present |
| AGENTS.md:13 | `project.godot` | present |
| AGENTS.md:14 | `origin/master` | present |
| AGENTS.md:14 | `jules/<topic>` | present |
| AGENTS.md:17 | `GameConfig` | present |
| AGENTS.md:18 | `scripts/saving.gd` | present |
| AGENTS.md:19 | `to_dict` | present |
| AGENTS.md:19 | `from_dict` | present |
| AGENTS.md:20 | `_process` | present |
| AGENTS.md:21 | `hive_cell.gd` | moved to scripts/hive_cell.gd |
| AGENTS.md:22 | `is_instance_valid` | present |
| AGENTS.md:23 | `Perf.begin` | present |
| AGENTS.md:23 | `Perf.end` | present |
| AGENTS.md:24 | `python tests/source_checks.py` | present |
| AGENTS.md:24 | `python tests/balance_tests.py` | present |
| AGENTS.md:25 | `plans/reference/jules.md` | present |
| AGENTS.md:25 | `tests/` | present |
| AGENTS.md:26 | `unittest discover` | present |
| AGENTS.md:27 | `tools/verify.ps1` | present |
| AGENTS.md:30 | `plans/reference/jules.md` | present |
| AGENTS.md:31 | `python tools/jules_preflight.py --next` | present |
| AGENTS.md:32 | `python tools/heading.py plans/reference/jules.md "How to work"` | present |
| AGENTS.md:34 | `origin/master` | present |
| AGENTS.md:37 | `python tools/jules_preflight.py --scope` | present |
| AGENTS.md:37 | `off` | present |
| AGENTS.md:41 | `docs/agent-rules.md` | present |
| AGENTS.md:41 | `CHATGPT.md` | present |
| AGENTS.md:42 | `CHATGPT.md` | present |
| AGENTS.md:45 | `python tools/heading.py CHATGPT.md "Risk-proportional closeout"` | present |
| AGENTS.md:47 | `-- and never read` | present |
| AGENTS.md:50 | `run-queue` | present |
| AGENTS.md:50 | `.agents/skills/run-queue/SKILL.md` | present |
| AGENTS.md:51 | `CHATGPT.md` | present |
| AGENTS.md:52 | `plans/reference/slice-worker.md` | present |
| AGENTS.md:56 | `codex/...` | present |
| AGENTS.md:57 | `master` | present |
| AGENTS.md:59 | `tools/slice.ps1 finish` | present |
| AGENTS.md:60 | `[Codex]` | present |
| AGENTS.md:62 | `CHATGPT.md` | present |
| AGENTS.md:65 | `NEXTSTEPS.md` | present |
| AGENTS.md:65 | `plans/` | present |
| AGENTS.md:70 | `CHATGPT.md` | present |
| AGENTS.md:76 | `CHATGPT.md` | present |
| AGENTS.md:81 | `plans/reference/` | present |
| AGENTS.md:82 | `plans/design/` | present |
| AGENTS.md:82 | `plans/now/` | present |
| AGENTS.md:83 | `NEXTSTEPS.md` | present |
| AGENTS.md:84 | `plans/` | present |
| AGENTS.md:87 | `CLAUDE.md` | present |
| AGENTS.md:88 | `NEXTSTEPS.md` | present |
| AGENTS.md:108 | `docs/agent-rules.md` | present |
| CLAUDE.md:11 | `tools/slice.ps1 start -Lane Claude` | present |
| CLAUDE.md:12 | `id` | present |
| CLAUDE.md:12 | `plan` | present |
| CLAUDE.md:13 | `heading` | present |
| CLAUDE.md:13 | `files` | present |
| CLAUDE.md:13 | `check` | present |
| CLAUDE.md:13 | `proof` | present |
| CLAUDE.md:13 | `next_after` | present |
| CLAUDE.md:13 | `read` | present |
| CLAUDE.md:14 | `doctor -Lane Claude` | present |
| CLAUDE.md:15 | `read` | present |
| CLAUDE.md:16 | `NEXTSTEPS.md` | present |
| CLAUDE.md:16 | `ROADMAP.md` | present |
| CLAUDE.md:17 | `DESIGN_BACKLOG.md` | present |
| CLAUDE.md:17 | `plans/archive/` | present |
| CLAUDE.md:17 | `checks/` | present |
| CLAUDE.md:19 | `FUNCTION_MAP.md` | present |
| CLAUDE.md:20 | `.claude/rules/` | present |
| CLAUDE.md:21 | `plans/reference/closeout.md` | present |
| CLAUDE.md:23 | `tools/slice.ps1 finish` | present |
| CLAUDE.md:25 | `start` | present |
| CLAUDE.md:26 | `tools/slice.ps1 owner <each path it will edit>` | present |
| CLAUDE.md:26 | `owned` | present |
| CLAUDE.md:30 | `NEXTSTEPS.md` | present |
| CLAUDE.md:30 | `### Claude lane` | present |
| CLAUDE.md:31 | `### Codex lane` | present |
| CLAUDE.md:32 | `.claude/rules/documentation.md` | present |
| CLAUDE.md:38 | `.\tools\verify.ps1` | present |
| CLAUDE.md:38 | `-PythonPath` | present |
| CLAUDE.md:39 | `finish` | present |
| CLAUDE.md:41 | `python tools/prefinish.py` | present |
| CLAUDE.md:41 | `finish` | present |
| CLAUDE.md:43 | `tools/check_docs.py` | present |
| CLAUDE.md:45 | `docs/headless-run-contract.md` | present |
| CLAUDE.md:45 | `verify.ps1` | moved to tools/verify.ps1 |
| CLAUDE.md:46 | `finish` | present |
| CLAUDE.md:47 | `ScheduleWakeup` | present |
| CLAUDE.md:47 | `Monitor` | present |
| CLAUDE.md:53 | `finish` | present |
| CLAUDE.md:69 | `Merged: no` | present |
| CLAUDE.md:70 | `finish` | present |
| CLAUDE.md:70 | `Next model` | present |
| CLAUDE.md:70 | `Toggle` | present |
| CLAUDE.md:71 | `Get-SliceAdvice` | present |
| CLAUDE.md:71 | `tools/slice.ps1` | present |
| CLAUDE.md:71 | `doctor` | present |
| CLAUDE.md:71 | `start` | present |
| CLAUDE.md:72 | `advice` | present |
| CLAUDE.md:72 | `Connectors: active now` | present |
| CLAUDE.md:80 | `plans/reference/closeout.md` | present |
| CLAUDE.md:81 | `plans/workstreams.md` | present |
| CLAUDE.md:82 | `GameConfig` | present |
| CLAUDE.md:82 | `scripts/settings_catalogue.gd` | present |
| CLAUDE.md:82 | `FUNCTION_MAP.md` | present |
| CLAUDE.md:83 | `plans/reference/ui-rules.md` | present |
| CLAUDE.md:84 | `scripts/scenario_actions.gd` | present |
| CLAUDE.md:85 | `docs/challenge-stages.md` | present |
| CLAUDE.md:86 | `plans/reference/check-loop.md` | present |
| CLAUDE.md:87 | `plans/design/progression.md` | present |
| CLAUDE.md:88 | `.claude/rules/saving.md` | present |
| CLAUDE.md:89 | `.claude/rules/simulation.md` | present |
| CLAUDE.md:90 | `.claude/rules/performance.md` | present |
| CLAUDE.md:90 | `docs/performance.md` | present |
| CLAUDE.md:91 | `FUNCTION_MAP.md` | present |
| CLAUDE.md:92 | `docs/known-pitfalls.md` | present |
| CLAUDE.md:93 | `GAME_MODEL.md` | present |
| CLAUDE.md:94 | `checks/ready.md` | present |
| CLAUDE.md:94 | `git grep -n <id> HEAD -- plans/archive` | present |
| CLAUDE.md:95 | `python tools/session_cost.py --events` | present |
| CLAUDE.md:98 | `FUNCTION_MAP.md` | present |
| CLAUDE.md:98 | `# --- section ---` | present |
| docs/agent-rules.md:3 | `CLAUDE.md` | present |
| docs/agent-rules.md:4 | `CLAUDE.md` | present |
| docs/agent-rules.md:4 | `AGENTS.md` | present |
| docs/agent-rules.md:11 | `python tools/heading.py <file> "<heading>"` | gone |
| docs/agent-rules.md:12 | `python tools/func.py <file> <function> [<function> ...]` | present |
| docs/agent-rules.md:14 | `_backups/` | present |
| docs/agent-rules.md:14 | `tools/slice.ps1` | present |
| docs/agent-rules.md:17 | `scripts/roles.gd` | present |
| docs/agent-rules.md:18 | `GameConfig` | present |
| docs/agent-rules.md:18 | `Session` | present |
| docs/agent-rules.md:31 | `tools/slice.ps1 finish` | present |
| docs/agent-rules.md:31 | `python tools/prefinish.py` | present |
| docs/agent-rules.md:35 | `tools/verify.ps1` | present |
| docs/agent-rules.md:35 | `tools/...` | gone |
| docs/agent-rules.md:36 | `../../tools/...` | present |
| docs/agent-rules.md:42 | `plans/` | present |
| docs/agent-rules.md:49 | `&&` | present |
| docs/agent-rules.md:49 | `;` | present |
| docs/agent-rules.md:51 | `cd C:\Users\dl13860\Documents\Meadow\meadow` | present |
| docs/agent-rules.md:54 | `docs/challenge-stages.md` | present |
| docs/agent-rules.md:55 | `python tools/stage_reference.py` | present |
| docs/agent-rules.md:55 | `verify.ps1` | moved to tools/verify.ps1 |
| docs/headless-run-contract.md:3 | `1` | present |
| docs/headless-run-contract.md:7 | `expect` | present |
| docs/headless-run-contract.md:8 | `.claude/rules/headless.md` | present |
| docs/headless-run-contract.md:11 | `milestone_times` | present |
| docs/headless-run-contract.md:12 | `milestones` | present |
| docs/headless-run-contract.md:22 | `meadow-headless-results` | present |
| docs/headless-run-contract.md:24 | `.` | present |
| docs/headless-run-contract.md:25 | `--report brief` | present |
| docs/headless-run-contract.md:26 | `behaviour` | present |
| docs/headless-run-contract.md:26 | `balance` | present |
| docs/headless-run-contract.md:26 | `full` | present |
| docs/headless-run-contract.md:44 | `route=experiment capture=behaviour seeds=3 background=no report=verdict` | present |
| docs/headless-run-contract.md:45 | `--explain` | present |
| docs/headless-run-contract.md:47 | `needs-godot` | present |
| docs/headless-run-contract.md:48 | `adaptive` | present |
| docs/headless-run-contract.md:50 | `comparison` | present |
| docs/headless-run-contract.md:50 | `none` | present |
| docs/headless-run-contract.md:50 | `stochastic` | present |
| docs/headless-run-contract.md:50 | `paired` | present |
| docs/headless-run-contract.md:51 | `time-series` | present |
| docs/headless-run-contract.md:53 | `expected-seconds` | present |
| docs/headless-run-contract.md:56 | `adaptive=yes` | present |
| docs/headless-run-contract.md:56 | `needs-godot=no` | present |
| docs/headless-run-contract.md:60 | `tools/run_headless.ps1` | present |
| docs/headless-run-contract.md:66 | `python` | present |
| docs/headless-run-contract.md:66 | `python3` | present |
| docs/headless-run-contract.md:66 | `py -3` | present |
| docs/headless-run-contract.md:75 | `python tools/scenario_sweep.py` | present |
| docs/headless-run-contract.md:75 | `--only <name part>` | present |
| docs/headless-run-contract.md:75 | `verify.ps1` | moved to tools/verify.ps1 |
| docs/headless-run-contract.md:83 | `Application Error` | present |
| docs/headless-run-contract.md:88 | `tools/slice.ps1 doctor -Lane <lane>` | present |
| docs/headless-run-contract.md:88 | `godot_capability` | present |
| docs/headless-run-contract.md:91 | `mcp_unavailable` | present |
| docs/headless-run-contract.md:91 | `.mcp.json` | present |
| docs/headless-run-contract.md:92 | `npx` | present |
| docs/headless-run-contract.md:94 | `editor_unavailable` | present |
| docs/headless-run-contract.md:95 | `GODOT_PATH` | present |
| docs/headless-run-contract.md:95 | `.codex/config.toml` | present |
| docs/headless-run-contract.md:96 | `doctor` | present |
| docs/headless-run-contract.md:97 | `import_cache_missing` | present |
| docs/headless-run-contract.md:97 | `.godot` | present |
| docs/headless-run-contract.md:98 | `verify.ps1` | moved to tools/verify.ps1 |
| docs/headless-run-contract.md:99 | `run_scenario.py` | moved to tools/run_scenario.py |
| docs/headless-run-contract.md:100 | `godot --headless --import` | present |
| docs/headless-run-contract.md:102 | `tools/godot_cache.py` | present |
| docs/headless-run-contract.md:105 | `environment_crash` | present |
| docs/headless-run-contract.md:109 | `ready` | present |
| docs/headless-run-contract.md:114 | `--background` | present |
| docs/headless-run-contract.md:133 | `job.json` | gone |
| docs/headless-run-contract.md:133 | `status.json` | gone |
| docs/headless-run-contract.md:134 | `queued` | present |
| docs/headless-run-contract.md:134 | `running` | present |
| docs/headless-run-contract.md:134 | `passed` | present |
| docs/headless-run-contract.md:134 | `failed` | present |
| docs/headless-run-contract.md:134 | `timed_out` | present |
| docs/headless-run-contract.md:134 | `crashed` | present |
| docs/headless-run-contract.md:135 | `stale` | present |
| docs/headless-run-contract.md:135 | `process.log` | present |
| docs/headless-run-contract.md:135 | `runs/` | present |
| docs/headless-run-contract.md:136 | `result.json` | gone |
| docs/headless-run-contract.md:138 | `stale` | present |
| docs/headless-run-contract.md:141 | `--job-root` | present |
| docs/headless-run-contract.md:142 | `--result-root` | present |
| docs/headless-run-contract.md:156 | `result.json` | gone |
| docs/headless-run-contract.md:158 | `failure.json` | gone |
| docs/headless-run-contract.md:161 | `report.json` | gone |
| docs/headless-run-contract.md:163 | `headless_run` | present |
| docs/headless-run-contract.md:165 | `python tools/session_cost.py --events` | present |
| docs/headless-run-contract.md:168 | `schema_version: 1` | present |
| docs/headless-run-contract.md:171 | `result.json` | gone |
| docs/headless-run-contract.md:190 | `status` | present |
| docs/headless-run-contract.md:190 | `passed` | present |
| docs/headless-run-contract.md:190 | `failed` | present |
| docs/headless-run-contract.md:190 | `contract_error` | present |
| docs/headless-run-contract.md:190 | `compile_error` | present |
| docs/headless-run-contract.md:191 | `timed_out` | present |
| docs/headless-run-contract.md:191 | `crashed` | present |
| docs/headless-run-contract.md:191 | `compile_error` | present |
| docs/headless-run-contract.md:193 | `SCRIPT ERROR:` | present |
| docs/headless-run-contract.md:194 | `process.log` | present |
| docs/headless-run-contract.md:196 | `.godot` | present |
| docs/headless-run-contract.md:197 | `outcome` | present |
| docs/headless-run-contract.md:197 | `null` | present |
| docs/headless-run-contract.md:198 | `artefacts` | present |
| docs/headless-run-contract.md:201 | `failure.json` | gone |
| docs/headless-run-contract.md:217 | `reason.kind` | present |
| docs/headless-run-contract.md:217 | `expectation` | present |
| docs/headless-run-contract.md:217 | `action` | present |
| docs/headless-run-contract.md:217 | `assertion` | present |
| docs/headless-run-contract.md:217 | `contract` | present |
| docs/headless-run-contract.md:218 | `compile` | present |
| docs/headless-run-contract.md:218 | `timeout` | present |
| docs/headless-run-contract.md:218 | `crash` | present |
| docs/headless-run-contract.md:218 | `missing_summary` | present |
| docs/headless-run-contract.md:219 | `truncated` | present |
| docs/headless-run-contract.md:222 | `MEADOW_RESULT_PATH=<exact path>` | present |
| docs/headless-run-contract.md:224 | `Meadow` | present |
| docs/headless-run-contract.md:224 | `Meadow - Claude` | present |
| docs/headless-run-contract.md:229 | `test_scenarios/foraging_evidence_campaign.json` | present |
| docs/headless-run-contract.md:240 | `species_experience` | present |
| docs/headless-run-contract.md:245 | `not_exercised` | present |
| docs/headless-run-contract.md:249 | `no_automation` | present |
| docs/headless-run-contract.md:249 | `12345` | present |
| docs/headless-run-contract.md:250 | `4294967295` | present |
| docs/headless-run-contract.md:251 | `status: crashed` | present |
| docs/headless-run-contract.md:257 | `result.json` | gone |
| docs/headless-run-contract.md:263 | `panel` | present |
| docs/headless-run-contract.md:264 | `control` | present |
| docs/headless-run-contract.md:264 | `container` | present |
| docs/headless-run-contract.md:264 | `root` | present |
| docs/headless-run-contract.md:267 | `settle` | present |
| docs/headless-run-contract.md:275 | `ticks` | present |
| docs/headless-run-contract.md:275 | `tests/fixtures/layout_panels.json` | present |
| docs/headless-run-contract.md:279 | `expect` | present |
| docs/headless-run-contract.md:293 | `actions.problems` | present |
| docs/headless-run-contract.md:293 | `accepted` | present |
| docs/headless-run-contract.md:293 | `recorded` | present |
| docs/headless-run-contract.md:293 | `rejected` | present |
| docs/headless-run-contract.md:293 | `failed` | present |
| docs/headless-run-contract.md:293 | `unresolved` | present |
| docs/headless-run-contract.md:293 | `recorded` | present |
| docs/headless-run-contract.md:293 | `"pollination_log": true` | present |
| docs/headless-run-contract.md:293 | `actions.by_result` | present |
| docs/headless-run-contract.md:293 | `actions_clean` | present |
| docs/headless-run-contract.md:295 | `id` | present |
| docs/headless-run-contract.md:296 | `op` | present |
| docs/headless-run-contract.md:296 | `eq` | present |
| docs/headless-run-contract.md:296 | `ne` | present |
| docs/headless-run-contract.md:296 | `lt` | present |
| docs/headless-run-contract.md:296 | `lte` | present |
| docs/headless-run-contract.md:296 | `gt` | present |
| docs/headless-run-contract.md:296 | `gte` | present |
| docs/headless-run-contract.md:296 | `value` | present |
| docs/headless-run-contract.md:296 | `between` | present |
| docs/headless-run-contract.md:297 | `min` | present |
| docs/headless-run-contract.md:297 | `max` | present |
| docs/headless-run-contract.md:297 | `empty` | present |
| docs/headless-run-contract.md:297 | `not_empty` | present |
| docs/headless-run-contract.md:297 | `all_true` | present |
| docs/headless-run-contract.md:298 | `exists` | present |
| docs/headless-run-contract.md:299 | `contract_error` | present |
| docs/headless-run-contract.md:304 | `challenge` | present |
| docs/headless-run-contract.md:304 | `1` | present |
| docs/headless-run-contract.md:304 | `2` | present |
| docs/headless-run-contract.md:308 | `advance_challenge_stage` | present |
| docs/headless-run-contract.md:309 | `debug_advance_stage()` | present |
| docs/headless-run-contract.md:310 | `challenge_stage_id` | present |
| docs/headless-run-contract.md:311 | `when` | present |
| docs/headless-run-contract.md:327 | `request_placement_tool` | present |
| docs/headless-run-contract.md:328 | `input_selection.gd::PLACEMENT_TOOLS` | present |
| docs/headless-run-contract.md:331 | `click_world` | present |
| docs/headless-run-contract.md:332 | `_finish_drag(false)` | present |
| docs/headless-run-contract.md:332 | `x` | present |
| docs/headless-run-contract.md:332 | `y` | present |
| docs/headless-run-contract.md:332 | `view` | present |
| docs/headless-run-contract.md:332 | `hive` | present |
| docs/headless-run-contract.md:332 | `meadow` | present |
| docs/headless-run-contract.md:333 | `soil_hex: [q, r]` | present |
| docs/headless-run-contract.md:334 | `select_bees` | present |
| docs/headless-run-contract.md:334 | `{"any_of": [selector, ...]}` | present |
| docs/headless-run-contract.md:336 | `selected_mine_queue_at_least` | present |
| docs/headless-run-contract.md:337 | `test_scenarios/e1_placement_exclusion_test.json` | present |
| docs/headless-run-contract.md:341 | `diagnostics` | present |
| docs/headless-run-contract.md:341 | `--scenario` | present |
| docs/headless-run-contract.md:344 | `verdict` | present |
| docs/headless-run-contract.md:345 | `behaviour` | present |
| docs/headless-run-contract.md:346 | `balance` | present |
| docs/headless-run-contract.md:346 | `performance` | present |
| docs/headless-run-contract.md:346 | `custom` | present |
| docs/headless-run-contract.md:362 | `population.total` | present |
| docs/headless-run-contract.md:363 | `resources.food_stores` | present |
| docs/headless-run-contract.md:363 | `resources.stored_nectar` | present |
| docs/headless-run-contract.md:363 | `resources.stored_pollen` | present |
| docs/headless-run-contract.md:364 | `environment.winter_here` | present |
| docs/headless-run-contract.md:364 | `environment.flowers_by_species` | present |
| docs/headless-run-contract.md:364 | `flower_mix_by_day` | present |
| docs/headless-run-contract.md:365 | `role_outcomes.cells_completed_total` | present |
| docs/headless-run-contract.md:365 | `performance.fps` | present |
| docs/headless-run-contract.md:366 | `performance.top_sections_ms` | present |
| docs/headless-run-contract.md:367 | `contract_error` | present |
| docs/headless-run-contract.md:371 | `build_target` | present |
| docs/headless-run-contract.md:379 | `tools.headless.contracts.fits_stdout_budget` | present |
| docs/headless-run-contract.md:382 | `verdict` | present |
| docs/headless-run-contract.md:386 | `brief` | present |
| docs/headless-run-contract.md:386 | `behaviour` | present |
| docs/headless-run-contract.md:386 | `full` | present |
| docs/headless-run-contract.md:398 | `config_overrides` | present |
| docs/headless-run-contract.md:425 | `case.summary_field.statistic` | present |
| docs/headless-run-contract.md:425 | `statistic` | present |
| docs/headless-run-contract.md:425 | `min` | present |
| docs/headless-run-contract.md:425 | `mean` | present |
| docs/headless-run-contract.md:425 | `max` | present |
| docs/headless-run-contract.md:427 | `crab_spider_events` | present |
| docs/headless-run-contract.md:428 | `eq` | present |
| docs/headless-run-contract.md:428 | `ne` | present |
| docs/headless-run-contract.md:428 | `lt` | present |
| docs/headless-run-contract.md:428 | `lte` | present |
| docs/headless-run-contract.md:428 | `gt` | present |
| docs/headless-run-contract.md:428 | `gte` | present |
| docs/headless-run-contract.md:429 | `value` | present |
| docs/headless-run-contract.md:430 | `DiagnosticLog` | present |
| docs/headless-run-contract.md:435 | `cases/<case>/seed-<seed>/` | present |
| docs/headless-run-contract.md:436 | `result.json` | gone |
| docs/headless-run-contract.md:438 | `report.mode: "table"` | present |
| docs/headless-run-contract.md:440 | `report.json` | gone |
| docs/headless-run-contract.md:444 | `--experiment` | present |
| docs/headless-run-contract.md:446 | `tools/equivalence.py` | present |
| docs/headless-run-contract.md:448 | `result.json` | gone |
| docs/headless-run-contract.md:455 | `no differences: ...` | present |
| docs/headless-run-contract.md:458 | `result.json` | gone |
| docs/headless-run-contract.md:459 | `run_id` | present |
| docs/headless-run-contract.md:459 | `scenario` | present |
| docs/headless-run-contract.md:460 | `process.pid` | present |
| docs/headless-run-contract.md:460 | `execution` | present |
| docs/headless-run-contract.md:460 | `wall_seconds` | present |
| docs/headless-run-contract.md:461 | `--fields` | present |
| docs/headless-run-contract.md:468 | `plans/workstreams.md` | present |
| docs/headless-run-contract.md:471 | `random_seed` | present |
| docs/known-pitfalls.md:3 | `CLAUDE.md` | present |
| docs/known-pitfalls.md:4 | `plans/reference/technical-audit.md` | present |
| docs/known-pitfalls.md:5 | `.claude/rules/gdscript.md` | present |
| docs/known-pitfalls.md:5 | `.claude/rules/simulation.md` | present |
| docs/known-pitfalls.md:6 | `.gd` | present |
| docs/known-pitfalls.md:13 | `UI.with_info()` | present |
| docs/known-pitfalls.md:14 | `SIZE_EXPAND_FILL` | present |
| docs/known-pitfalls.md:17 | `no_collapsed_controls` | present |
| docs/known-pitfalls.md:18 | `scripts/scenario_actions.gd` | present |
| docs/known-pitfalls.md:19 | `tests/fixtures/settings_stage_row.json` | present |
| docs/known-pitfalls.md:20 | `Control.set_size()` | present |
| docs/known-pitfalls.md:21 | `panel.size.x = w` | present |
| docs/known-pitfalls.md:22 | `panel.size.y = h` | present |
| docs/known-pitfalls.md:22 | `panel.reset_size()` | present |
| docs/known-pitfalls.md:24 | `grow_vertical = GROW_DIRECTION_BEGIN` | present |
| docs/known-pitfalls.md:30 | `offset_left` | present |
| docs/known-pitfalls.md:30 | `offset_right` | present |
| docs/known-pitfalls.md:30 | `offset_top` | present |
| docs/known-pitfalls.md:30 | `offset_bottom` | present |
| docs/known-pitfalls.md:31 | `scripts/ui_panel_layout.gd` | present |
| docs/known-pitfalls.md:31 | `size` | present |
| docs/known-pitfalls.md:31 | `position` | present |
| docs/known-pitfalls.md:32 | `reset_size()` | present |
| docs/known-pitfalls.md:35 | `plans/archive/HUD_CONTROLS_2026-09-11.md` | present |
| docs/known-pitfalls.md:35 | `HFlowContainer` | present |
| docs/known-pitfalls.md:36 | `size_flags_horizontal` | present |
| docs/known-pitfalls.md:37 | `SIZE_EXPAND_FILL` | present |
| docs/known-pitfalls.md:38 | `clip_text = true` | present |
| docs/known-pitfalls.md:38 | `autowrap_mode` | present |
| docs/known-pitfalls.md:39 | `HBoxContainer` | present |
| docs/known-pitfalls.md:42 | `MenuButton` | present |
| docs/known-pitfalls.md:42 | `flat = true` | present |
| docs/known-pitfalls.md:43 | `normal` | present |
| docs/known-pitfalls.md:47 | `ui_layout.gd::gallerin_rect()` | present |
| docs/known-pitfalls.md:51 | `ui_panel_layout.gd::apply()` | present |
| docs/known-pitfalls.md:52 | `PANEL_GAP` | present |
| docs/known-pitfalls.md:53 | `plans/archive/HUD_CONTROLS_2026-09-11.md` | present |
| docs/known-pitfalls.md:57 | `Label` | present |
| docs/known-pitfalls.md:58 | `text = ""` | present |
| docs/known-pitfalls.md:59 | `hud.gd` | moved to scripts/hud.gd |
| docs/known-pitfalls.md:62 | `plans/archive/HUD_CONTROLS_2026-09-11.md` | present |
| docs/known-pitfalls.md:65 | `theme_type_variation` | present |
| docs/known-pitfalls.md:66 | `Button` | present |
| docs/known-pitfalls.md:66 | `Label` | present |
| docs/known-pitfalls.md:66 | `Session.text_scale` | present |
| docs/known-pitfalls.md:69 | `_current_role_marker` | present |
| docs/known-pitfalls.md:69 | `_make_role_menu` | present |
| docs/known-pitfalls.md:75 | `PRESET_CENTER_BOTTOM` | present |
| docs/known-pitfalls.md:77 | `* 0.924` | present |
| docs/known-pitfalls.md:81 | `plans/archive/ui_2026-09-20.md` | present |
| docs/known-pitfalls.md:82 | `ScrollContainer` | present |
| docs/known-pitfalls.md:84 | `ScrollContainer` | present |
| docs/known-pitfalls.md:85 | `SIZE_EXPAND` | present |
| docs/known-pitfalls.md:85 | `SIZE_FILL` | present |
| docs/known-pitfalls.md:86 | `SIZE_FILL` | present |
| docs/known-pitfalls.md:86 | `VBoxContainer` | present |
| docs/known-pitfalls.md:92 | `plans/archive/HUD_CONTROLS_2026-09-11.md` | present |
| docs/known-pitfalls.md:95 | `control_rect` | present |
| docs/known-pitfalls.md:95 | `even_columns` | present |
| docs/known-pitfalls.md:95 | `no_collapsed_controls` | present |
| docs/known-pitfalls.md:96 | `scripts/scenario_actions.gd` | present |
| docs/known-pitfalls.md:97 | `plans/archive/LAYOUT_REGRESSION_2026-09-09.md` | present |
| docs/known-pitfalls.md:99 | `ScrollContainer` | present |
| docs/known-pitfalls.md:101 | `ScrollContainer.get_minimum_size()` | present |
| docs/known-pitfalls.md:111 | `FlowContainer` | present |
| docs/known-pitfalls.md:112 | `gallerin_panel.gd::_build_bubble()` | present |
| docs/known-pitfalls.md:114 | `horizontal_scroll_mode` | present |
| docs/known-pitfalls.md:114 | `vertical_scroll_mode` | present |
| docs/known-pitfalls.md:114 | `SCROLL_MODE_AUTO` | present |
| docs/known-pitfalls.md:115 | `tests/test_layout_regression.py` | present |
| docs/known-pitfalls.md:116 | `verify.ps1` | moved to tools/verify.ps1 |
| docs/known-pitfalls.md:116 | `ScrollContainer` | present |
| docs/known-pitfalls.md:121 | `ui_theme.gd` | moved to scripts/ui_theme.gd |
| docs/known-pitfalls.md:121 | `font_size` | present |
| docs/known-pitfalls.md:122 | `Label` | present |
| docs/known-pitfalls.md:122 | `Button` | present |
| docs/known-pitfalls.md:128 | `plans/archive/HUD_CONTROLS_2026-09-11.md` | present |
| docs/known-pitfalls.md:129 | `_draw` | present |
| docs/known-pitfalls.md:129 | `StyleBoxFlat` | present |
| docs/known-pitfalls.md:130 | `StyleBoxFlat` | present |
| docs/known-pitfalls.md:130 | `StyleBoxTexture` | present |
| docs/known-pitfalls.md:130 | `StyleBoxLine` | present |
| docs/known-pitfalls.md:131 | `_draw` | present |
| docs/known-pitfalls.md:131 | `PanelBox extends StyleBoxFlat` | present |
| docs/known-pitfalls.md:133 | `StyleBox` | present |
| docs/known-pitfalls.md:133 | `_draw` | present |
| docs/known-pitfalls.md:134 | `StyleBoxFlat` | present |
| docs/known-pitfalls.md:134 | `StyleBox` | present |
| docs/known-pitfalls.md:135 | `PanelBox.flat` | present |
| docs/known-pitfalls.md:135 | `draw()` | present |
| docs/known-pitfalls.md:135 | `tests/source_checks.py` | present |
| docs/known-pitfalls.md:136 | `_draw` | present |
| docs/known-pitfalls.md:141 | `input_selection.gd::_draw_tile_outline` | present |
| docs/known-pitfalls.md:152 | `var comb workers := 0` | present |
| docs/known-pitfalls.md:153 | `main.gd` | moved to scripts/main.gd |
| docs/known-pitfalls.md:153 | `source_checks.py` | moved to tests/source_checks.py |
| docs/known-pitfalls.md:155 | `Array.has()` | present |
| docs/known-pitfalls.md:156 | `JSON.parse_string` | present |
| docs/known-pitfalls.md:156 | `[1]` | present |
| docs/known-pitfalls.md:156 | `[1.0]` | present |
| docs/known-pitfalls.md:156 | `1 == 1.0` | present |
| docs/known-pitfalls.md:157 | `[1.0].has(1)` | present |
| docs/known-pitfalls.md:157 | `player_profile.gd::mark_challenge_complete` | present |
| docs/known-pitfalls.md:158 | `1.0` | present |
| docs/known-pitfalls.md:160 | `completed_challenges()` | present |
| docs/known-pitfalls.md:161 | `int()` | present |
| docs/known-pitfalls.md:161 | `has()` | present |
| docs/known-pitfalls.md:161 | `find()` | present |
| docs/known-pitfalls.md:162 | `offset` | present |
| docs/known-pitfalls.md:163 | `scale` | present |
| docs/known-pitfalls.md:164 | `Array[T]` | present |
| docs/known-pitfalls.md:164 | `[]` | present |
| docs/known-pitfalls.md:165 | `bee.known_patches` | present |
| docs/known-pitfalls.md:165 | `Array[Vector2]` | present |
| docs/known-pitfalls.md:166 | `some_dynamically_typed_ref.known_patches = []` | present |
| docs/known-pitfalls.md:171 | `var x: Array[T] = []` | present |
| docs/known-pitfalls.md:174 | `saving.gd::_restore_bees()` | present |
| docs/known-pitfalls.md:175 | `plans/archive/HANDS_ON_FIXES_2026-08-31.md` | present |
| docs/known-pitfalls.md:176 | `Array[T]` | present |
| docs/known-pitfalls.md:176 | `Dictionary[K,V]` | present |
| docs/known-pitfalls.md:178 | `tools/typed_array_assign_check.py` | present |
| docs/known-pitfalls.md:179 | `<expr>.name = []` | present |
| docs/known-pitfalls.md:179 | `= {}` | present |
| docs/known-pitfalls.md:181 | `Edit` | present |
| docs/known-pitfalls.md:183 | `hud.gd` | moved to scripts/hud.gd |
| docs/known-pitfalls.md:184 | `CLAUDE.md` | present |
| docs/known-pitfalls.md:190 | `State.IDLING` | present |
| docs/known-pitfalls.md:190 | `bee.gd` | moved to scripts/bee.gd |
| docs/known-pitfalls.md:191 | `pass   # waits for orders and nothing else` | present |
| docs/known-pitfalls.md:192 | `_apply_role()` | present |
| docs/known-pitfalls.md:193 | `_default_state_for_role()` | present |
| docs/known-pitfalls.md:194 | `set_focus()` | present |
| docs/known-pitfalls.md:195 | `_go_to_exit()` | present |
| docs/known-pitfalls.md:196 | `freeze_bee:queen` | present |
| docs/known-pitfalls.md:198 | `hive_root` | present |
| docs/known-pitfalls.md:198 | `meadow_root` | present |
| docs/known-pitfalls.md:199 | `position` | present |
| docs/known-pitfalls.md:204 | `skirt_obstacle` | present |
| docs/known-pitfalls.md:208 | `_grounded()` | present |
| docs/known-pitfalls.md:210 | `if _grounded(): return true` | present |
| docs/known-pitfalls.md:213 | `bee_status.gd::grounded()` | present |
| docs/known-pitfalls.md:215 | `plans/archive/PERF_PLAN.md` | present |
| docs/known-pitfalls.md:218 | `perf.gd` | moved to scripts/perf.gd |
| docs/known-pitfalls.md:224 | `hive.gd::build_navigation` | present |
| docs/known-pitfalls.md:224 | `0..reach` | present |
| docs/known-pitfalls.md:225 | `world_building.gd` | moved to scripts/world_building.gd |
| docs/known-pitfalls.md:225 | `reach - 1` | present |
| docs/known-pitfalls.md:225 | `reach` | present |
| docs/known-pitfalls.md:227 | `_is_solid` | present |
| docs/known-pitfalls.md:236 | `challenge_runner.gd::_update_marker` | present |
| docs/known-pitfalls.md:242 | `plans/archive/CHALLENGE1_2026-09-15.md` | present |
| docs/known-pitfalls.md:243 | `hive_root` | present |
| docs/known-pitfalls.md:244 | `bee.position` | present |
| docs/known-pitfalls.md:251 | `bee_foraging.gd::_walk_out_if_indoors` | present |
| docs/known-pitfalls.md:251 | `bee.gd::set_focus` | present |
| docs/known-pitfalls.md:257 | `challenge_runner.gd::discards_overflow` | present |
| docs/known-pitfalls.md:263 | `plans/archive/CHALLENGE1_2026-09-15.md` | present |
| docs/known-pitfalls.md:264 | `cell_designated` | present |
| docs/known-pitfalls.md:274 | `bee_foraging.gd` | moved to scripts/bee_foraging.gd |
| docs/known-pitfalls.md:275 | `bee.gd` | moved to scripts/bee.gd |
| docs/known-pitfalls.md:276 | `manual_deposit_pending` | present |
| docs/known-pitfalls.md:276 | `role_change_locked` | present |
| docs/known-pitfalls.md:276 | `flower_switch_locked` | present |
| docs/known-pitfalls.md:280 | `source_checks.py` | moved to tests/source_checks.py |
| docs/known-pitfalls.md:282 | `plans/archive/CHALLENGE1_2026-09-15.md` | present |
| docs/known-pitfalls.md:286 | `HiveCell.add_resource` | present |
| docs/known-pitfalls.md:292 | `designation_is_explicit` | present |
| docs/known-pitfalls.md:293 | `plans/archive/CHALLENGE1_2026-09-15.md` | present |
| docs/known-pitfalls.md:295 | `godot_compile_check.py::find_godot` | present |
| docs/known-pitfalls.md:296 | `C:\Program Files\Godot` | present |
| docs/known-pitfalls.md:296 | `PATH` | present |
| docs/known-pitfalls.md:297 | `Godot_v4.7.2-stable_win64.exe` | present |
| docs/known-pitfalls.md:298 | `verify.ps1` | moved to tools/verify.ps1 |
| docs/known-pitfalls.md:299 | `run_scenario.py` | moved to tools/run_scenario.py |
| docs/known-pitfalls.md:299 | `WinError 2` | present |
| docs/known-pitfalls.md:299 | `find_godot` | present |
| docs/known-pitfalls.md:313 | `speed * delta` | present |
| docs/known-pitfalls.md:318 | `slice.ps1 finish` | present |
| docs/known-pitfalls.md:322 | `claude/youthful-panini-727953` | present |
| docs/known-pitfalls.md:325 | `finish` | present |
| docs/known-pitfalls.md:325 | `Push-Location $root` | present |
| docs/known-pitfalls.md:327 | `Pop-Location` | present |
| docs/known-pitfalls.md:327 | `Set-Location` | present |
| docs/known-pitfalls.md:329 | `finally` | present |
| docs/known-pitfalls.md:330 | `finally` | present |
| docs/known-pitfalls.md:331 | `Pop-Location` | present |
| docs/known-pitfalls.md:333 | `finally` | present |
| docs/known-pitfalls.md:336 | `-notlike "*` | present |
| docs/known-pitfalls.md:336 | `$path` | present |
| docs/known-pitfalls.md:336 | `*"` | present |
| docs/known-pitfalls.md:338 | `'a*b' -like 'a` | present |
| docs/known-pitfalls.md:339 | `'axxb' -like 'a` | present |
| docs/known-pitfalls.md:340 | `String.IndexOf` | present |
| docs/known-pitfalls.md:340 | `-like` | present |
| docs/known-pitfalls.md:340 | `-notlike` | present |
| docs/known-pitfalls.md:341 | `git commit` | present |
| docs/known-pitfalls.md:342 | `git add` | present |
| docs/known-pitfalls.md:344 | `git diff --cached --quiet` | present |
| docs/known-pitfalls.md:347 | `finish` | present |
| docs/known-pitfalls.md:350 | `finish` | present |
| docs/known-pitfalls.md:352 | `Test-Path` | present |
| docs/known-pitfalls.md:353 | `~/.config/git` | present |
| docs/known-pitfalls.md:354 | `Test-Path` | present |
| docs/known-pitfalls.md:354 | `UnauthorizedAccessException` | present |
| docs/known-pitfalls.md:355 | `try` | present |
| docs/known-pitfalls.md:361 | `%LOCALAPPDATA%\OpenAI\Codex\bin\<hash>\codex.exe` | present |
| docs/known-pitfalls.md:361 | `-c` | present |
| docs/known-pitfalls.md:362 | `~/.codex/config.toml` | present |
| docs/known-pitfalls.md:363 | `%LOCALAPPDATA%` | present |
| docs/known-pitfalls.md:363 | `CreateProcessAsUserW failed: 5` | present |
| docs/known-pitfalls.md:364 | `tools/godot_compile_check.py` | present |
| docs/known-pitfalls.md:367 | `icacls <dir> /deny "%USERNAME%:(RD,RA,REA,X)"` | present |
| docs/known-pitfalls.md:368 | `test_doctor_survives_an_excludes_folder_it_may_not_list` | present |
| docs/known-pitfalls.md:370 | `%APPDATA%` | present |
| docs/known-pitfalls.md:371 | `0x58` | present |
| docs/known-pitfalls.md:372 | `ensure_writable_user_dir` | present |
| docs/known-pitfalls.md:373 | `tempfile` | present |
| docs/known-pitfalls.md:374 | `os.access` | present |
| docs/known-pitfalls.md:375 | `os.access` | present |
| docs/known-pitfalls.md:375 | `TMP_MAX` | present |
| docs/known-pitfalls.md:377 | `Receive-Job -ErrorAction SilentlyContinue 2>&1` | present |
| docs/known-pitfalls.md:378 | `2>&1` | present |
| docs/known-pitfalls.md:379 | `FAIL:` | present |
| docs/known-pitfalls.md:382 | `-ErrorAction Continue 2>&1` | present |
| docs/known-pitfalls.md:383 | `$ErrorActionPreference = "Stop"` | present |
| docs/known-pitfalls.md:385 | `finish` | present |
| docs/known-pitfalls.md:386 | `finish` | present |
| docs/known-pitfalls.md:387 | `Slice landed:` | present |
| docs/known-pitfalls.md:387 | `slice finish stopped` | present |
| docs/known-pitfalls.md:388 | `tools/slice.ps1 status` | present |
| docs/known-pitfalls.md:389 | `running` | present |
| docs/known-pitfalls.md:390 | `last_run` | present |
| docs/known-pitfalls.md:391 | `plans/reference/closeout.md` | present |
| docs/known-pitfalls.md:396 | `environment_failure` | present |
| docs/known-pitfalls.md:397 | `Stop-Process -Force` | present |
| docs/known-pitfalls.md:397 | `Process.Kill` | present |
| docs/known-pitfalls.md:398 | `TerminateProcess(…, -1)` | present |
| docs/known-pitfalls.md:399 | `0xC0000005` | present |
| docs/known-pitfalls.md:402 | `missing_summary` | present |
| docs/known-pitfalls.md:403 | `munro.ttf` | present |
| docs/known-pitfalls.md:403 | `--verbose` | present |
| docs/known-pitfalls.md:404 | `reason=crash` | present |
| docs/known-pitfalls.md:404 | `outcome=actions_resolved` | present |
| docs/known-pitfalls.md:409 | `slice.ps1 finish` | present |
| docs/known-pitfalls.md:410 | `Get-Process Godot* | Stop-Process -Force` | present |
| docs/known-pitfalls.md:411 | `finish` | present |
| docs/known-pitfalls.md:412 | `finish` | present |
| docs/known-pitfalls.md:412 | `verify.ps1` | moved to tools/verify.ps1 |
| docs/known-pitfalls.md:413 | `tests/test_slice_lifecycle.py` | present |
| docs/known-pitfalls.md:413 | `tests/test_two_lane_closeout.py` | present |
| docs/known-pitfalls.md:414 | `finish` | present |
| docs/known-pitfalls.md:415 | `Stop-Process -Id <Godot PIDs> -Force` | present |
| docs/known-pitfalls.md:417 | `finish` | present |
| docs/known-pitfalls.md:418 | `Stop-WorktreeGodot` | present |
| docs/known-pitfalls.md:419 | `tests/test_source_checks.py` | present |
| docs/known-pitfalls.md:419 | `FinishGodotScopeTest` | present |
| docs/known-pitfalls.md:422 | `--verbose` | present |
| docs/known-pitfalls.md:423 | `EditorTheme: Generating new styles.` | present |
| docs/known-pitfalls.md:425 | `NVAPI: Error saving settings` | present |
| docs/known-pitfalls.md:430 | `0x58` | present |
| docs/known-pitfalls.md:430 | `0x6c5854` | present |
| docs/known-pitfalls.md:431 | `cmp byte [rcx+0x58]` | present |
| docs/known-pitfalls.md:433 | `0xC0000005` | present |
| docs/known-pitfalls.md:433 | `run_scenario.py` | moved to tools/run_scenario.py |
| docs/known-pitfalls.md:434 | `SEM_NOGPFAULTERRORBOX` | present |
| docs/known-pitfalls.md:438 | `user://logs/godot.log` | present |
| docs/known-pitfalls.md:439 | `%APPDATA%\Godot\app_userdata\<config/name>\logs` | present |
| docs/known-pitfalls.md:441 | `%APPDATA%` | present |
| docs/known-pitfalls.md:442 | `WorkerThreadPool:` | present |
| docs/known-pitfalls.md:443 | `--verbose` | present |
| docs/known-pitfalls.md:446 | `--experiment` | present |
| docs/known-pitfalls.md:448 | `godot_compile_check.py` | moved to tools/godot_compile_check.py |
| docs/known-pitfalls.md:452 | `godot_compile_check.py` | moved to tools/godot_compile_check.py |
| docs/known-pitfalls.md:452 | `godot_cache.py` | moved to tools/godot_cache.py |
| docs/known-pitfalls.md:453 | `run_scenario.py` | moved to tools/run_scenario.py |
| docs/known-pitfalls.md:453 | `ensure_writable_user_dir()` | present |
| docs/known-pitfalls.md:454 | `%APPDATA%\Godot` | present |
| docs/known-pitfalls.md:454 | `APPDATA` | present |
| docs/known-pitfalls.md:455 | `%TEMP%\meadow-godot-appdata` | present |
| docs/known-pitfalls.md:456 | `run_scenario.log_dir()` | present |
| docs/known-pitfalls.md:456 | `slice.ps1` | moved to tools/slice.ps1 |
| docs/known-pitfalls.md:457 | `Get-GodotCapability` | present |
| docs/known-pitfalls.md:458 | `environment_crash` | present |
| docs/known-pitfalls.md:460 | `. Adding` | present |
| docs/known-pitfalls.md:461 | `user://logs` | present |
| docs/known-pitfalls.md:463 | `--headless --quit-after 1` | present |
| docs/known-pitfalls.md:463 | `slice.ps1` | moved to tools/slice.ps1 |
| docs/known-pitfalls.md:464 | `project.godot` | present |
| docs/known-pitfalls.md:466 | `EditorTheme: Generating new styles.` | present |
| docs/known-pitfalls.md:471 | `Get-CimInstance Win32_Process` | present |
| docs/known-pitfalls.md:471 | `slice.ps1` | moved to tools/slice.ps1 |
| docs/known-pitfalls.md:471 | `verify.ps1` | moved to tools/verify.ps1 |
| docs/known-pitfalls.md:477 | `.git/index.lock` | present |
| docs/known-pitfalls.md:477 | `HEAD.lock` | present |
| docs/known-pitfalls.md:480 | `git commit` | present |
| docs/known-pitfalls.md:482 | `mv` | present |
| docs/known-pitfalls.md:482 | `rm` | present |
| docs/known-pitfalls.md:493 | `%USERNAME%` | present |
| docs/known-pitfalls.md:496 | `<machine>\CodexSandboxOffline` | present |
| docs/known-pitfalls.md:497 | `USERNAME` | present |
| docs/known-pitfalls.md:497 | `dl13860` | present |
| docs/known-pitfalls.md:498 | `icacls … /deny dl13860:(R)` | present |
| docs/known-pitfalls.md:499 | `NTAccount` | present |
| docs/known-pitfalls.md:501 | `test_doctor_survives_an_excludes_folder_it_may_not_list` | present |
| docs/known-pitfalls.md:501 | `doctor` | present |
| docs/known-pitfalls.md:506 | `whoami.exe /user /fo csv /nh` | present |
| docs/known-pitfalls.md:506 | `whoami` | present |
| docs/known-pitfalls.md:507 | `*S-1-…` | present |
| docs/known-pitfalls.md:508 | `try` | present |
| docs/known-pitfalls.md:508 | `finally` | present |
| docs/known-pitfalls.md:509 | `%TEMP%` | present |
| docs/known-pitfalls.md:511 | `os.kill(pid, 0)` | present |
| docs/known-pitfalls.md:513 | `os.kill(pid, 0)` | present |
| docs/known-pitfalls.md:515 | `signal.CTRL_C_EVENT` | present |
| docs/known-pitfalls.md:516 | `GenerateConsoleCtrlEvent(CTRL_C_EVENT, pid)` | present |
| docs/known-pitfalls.md:521 | `verify.ps1` | moved to tools/verify.ps1 |
| docs/known-pitfalls.md:522 | `tools/headless/jobs.py::_pid_is_live` | gone |
| docs/known-pitfalls.md:524 | `KeyboardInterrupt` | present |
| docs/known-pitfalls.md:524 | `-1073741510` | present |
| docs/known-pitfalls.md:525 | `STATUS_CONTROL_C_EXIT` | present |
| docs/known-pitfalls.md:530 | `OpenProcess` | present |
| docs/known-pitfalls.md:531 | `PROCESS_QUERY_LIMITED_INFORMATION | SYNCHRONIZE` | present |
| docs/known-pitfalls.md:532 | `returning` | present |
| docs/known-pitfalls.md:532 | `for "still running",` | present |
| docs/known-pitfalls.md:538 | `user://` | present |
| docs/known-pitfalls.md:538 | `app_userdata` | present |
| docs/known-pitfalls.md:539 | `--scenario=` | present |
| docs/known-pitfalls.md:539 | `_ready` | present |
| docs/known-pitfalls.md:540 | `meadow_profile.json` | gone |
| docs/known-pitfalls.md:541 | `set_config` | present |
| docs/known-pitfalls.md:542 | `Session.save_preferences()` | present |
| docs/known-pitfalls.md:543 | `text_scale 2.0` | present |
| docs/known-pitfalls.md:543 | `text_scale 1.0` | present |
| docs/known-pitfalls.md:544 | `layout_panels.json` | moved to tests/fixtures/layout_panels.json |
| docs/known-pitfalls.md:545 | `text_scale 2.0` | present |
| docs/known-pitfalls.md:549 | `player_profile.gd::_isolated` | present |
| docs/known-pitfalls.md:549 | `--scenario=` | present |
| docs/known-pitfalls.md:550 | `user://` | present |
| docs/known-pitfalls.md:555 | `--scenario=` | present |
| docs/known-pitfalls.md:555 | `user://scenario_saves/` | present |
| docs/known-pitfalls.md:556 | `save_slots.gd::use_scratch_root` | present |
| docs/known-pitfalls.md:557 | `diagnostic_log.gd::_prune_old_sessions` | present |
| docs/known-pitfalls.md:557 | `app_userdata` | present |
| docs/known-pitfalls.md:559 | `save_slot` | present |
| docs/known-pitfalls.md:559 | `restore_slot` | present |
| docs/known-pitfalls.md:561 | `tests.test_bb1_bee_bread` | present |
| docs/known-pitfalls.md:562 | `tests.test_nf2_fermentation` | present |
| docs/known-pitfalls.md:562 | `verify.ps1` | moved to tools/verify.ps1 |
| docs/known-pitfalls.md:563 | `slice.ps1 finish` | present |
| docs/known-pitfalls.md:564 | `tests.test_nf3_tipsy` | present |
| docs/known-pitfalls.md:566 | `APPDATA` | present |
| docs/known-pitfalls.md:569 | `run_scenario.private_user_env` | present |
| docs/known-pitfalls.md:569 | `run_once` | present |
| docs/known-pitfalls.md:570 | `APPDATA` | present |
| docs/known-pitfalls.md:570 | `XDG_DATA_HOME` | present |
| docs/known-pitfalls.md:571 | `.headless_user/<run id>/` | present |
| docs/known-pitfalls.md:573 | `scenario_saves_dir(session_file)` | present |
| docs/known-pitfalls.md:573 | `log_dir().parent` | present |
| docs/known-pitfalls.md:574 | `tests.test_run_scenario_launch` | present |
| docs/known-pitfalls.md:575 | `--scenario=` | present |
| docs/known-pitfalls.md:578 | `cd … && …` | present |
| docs/known-pitfalls.md:581 | `cd "<absolute path>" &&` | present |
| docs/known-pitfalls.md:583 | `cd` | present |
| docs/known-pitfalls.md:584 | `.worktrees/<id>` | present |
| docs/known-pitfalls.md:585 | `partially_denied` | present |
| docs/known-pitfalls.md:586 | `python tools/session_cost.py --classify` | present |
| docs/known-pitfalls.md:590 | `.claude/settings.json` | present |
| docs/known-pitfalls.md:591 | `plans/archive/` | present |
| docs/known-pitfalls.md:591 | `docs/archive/` | present |
| docs/known-pitfalls.md:596 | `.claude/settings.json` | present |
| docs/known-pitfalls.md:596 | `sed -n` | present |
| docs/known-pitfalls.md:596 | `grep` | present |
| docs/known-pitfalls.md:596 | `git show` | present |
| docs/known-pitfalls.md:599 | `Read` | present |
| docs/known-pitfalls.md:600 | `ROADMAP.md` | present |
| docs/known-pitfalls.md:600 | `DESIGN_BACKLOG.md` | present |
| docs/known-pitfalls.md:601 | `plans/archive/**` | present |
| docs/known-pitfalls.md:601 | `docs/archive/**` | present |
| docs/known-pitfalls.md:605 | `git show HEAD:<path>` | present |
| docs/known-pitfalls.md:606 | `.json` | present |
| docs/known-pitfalls.md:607 | `Read` | present |
| docs/known-pitfalls.md:609 | `../../` | present |
| docs/known-pitfalls.md:611 | `tools/verify.ps1` | present |
| docs/known-pitfalls.md:611 | `tools/prefinish.py` | present |
| docs/known-pitfalls.md:612 | `.worktrees/CD-3` | present |
| docs/known-pitfalls.md:613 | `python ../../tools/prefinish.py` | moved to tools/prefinish.py |
| docs/known-pitfalls.md:615 | `test_the_repo_sprites_are_current` | present |
| docs/known-pitfalls.md:617 | `tools/...` | gone |
| plans/reference/check-loop.md:4 | `plans/archive/CHECK_LOOP_P2_2026-09-04.md` | present |
| plans/reference/check-loop.md:14 | `CLAUDE.md` | present |
| plans/reference/check-loop.md:21 | `verify.ps1` | moved to tools/verify.ps1 |
| plans/reference/check-loop.md:26 | `camera_follow_queen` | present |
| plans/reference/check-loop.md:26 | `_apply_stage_gate_to_ui()` | present |
| plans/reference/check-loop.md:28 | `flower_switch_locked` | present |
| plans/reference/check-loop.md:28 | `IDLING` | present |
| plans/reference/check-loop.md:46 | `Acceptance` | present |
| plans/reference/check-loop.md:47 | `checks/ready/` | present |
| plans/reference/check-loop.md:47 | `python tools/new_check.py` | present |
| plans/reference/check-loop.md:53 | `plans/archive/HIVE_COMB_2026-09-12.md` | present |
| plans/reference/check-loop.md:65 | `test_scenarios/*.json` | present |
| plans/reference/check-loop.md:65 | `save_run` | present |
| plans/reference/check-loop.md:74 | `IDLING` | present |
| plans/reference/check-loop.md:75 | `player_driven` | present |
| plans/reference/check-loop.md:77 | `freeze_bee:queen` | present |
| plans/reference/check-loop.md:77 | `IDLING` | present |
| plans/reference/check-loop.md:79 | `plans/archive/CHALLENGE1_2026-09-15.md` | present |
| plans/reference/check-loop.md:81 | `ui_layout.gd` | moved to scripts/ui_layout.gd |
| plans/reference/check-loop.md:82 | `offset_top` | present |
| plans/reference/check-loop.md:82 | `offset_left` | present |
| plans/reference/check-loop.md:85 | `tests/source_checks.py` | present |
| plans/reference/check-loop.md:86 | `UiLayout` | present |
| plans/reference/check-loop.md:87 | `# fixed-inset` | present |
| plans/reference/check-loop.md:94 | `docs/headless-run-contract.md` | present |
| plans/reference/check-loop.md:98 | `docs/known-pitfalls.md` | present |
| plans/reference/check-loop.md:105 | `checks/` | present |
| plans/reference/check-loop.md:106 | `NEXTSTEPS.md` | present |
| plans/reference/check-loop.md:117 | `PASS:` | present |
| plans/reference/check-loop.md:125 | `Owner:` | present |
| plans/reference/check-loop.md:126 | `plans/archive/CHALLENGE1_2026-09-15.md` | present |
| plans/reference/check-loop.md:136 | `plans/archive/HUD_CONTROLS_2026-09-11.md` | present |
| plans/reference/check-loop.md:138 | `control_rect` | present |
| plans/reference/check-loop.md:138 | `even_columns` | present |
| plans/reference/check-loop.md:138 | `no_collapsed_controls` | present |
| plans/reference/check-loop.md:139 | `scripts/scenario_actions.gd` | present |
| plans/reference/check-loop.md:140 | `plans/archive/LAYOUT_REGRESSION_2026-09-09.md` | present |
| plans/reference/check-loop.md:148 | `tests/source_checks.py` | present |
| plans/reference/check-loop.md:148 | `check_offset_rect_literals` | present |
| plans/reference/check-loop.md:149 | `check_gameconfig_writes` | present |
| plans/reference/check-loop.md:150 | `plans/archive/CHECK_LOOP_P3_2026-09-03.md` | present |
| plans/reference/check-loop.md:151 | `debug_panel.gd` | moved to scripts/debug_panel.gd |
| plans/reference/check-loop.md:152 | `plans/archive/CHECK_LOOP_P2_2026-09-04.md` | present |
| plans/reference/check-loop.md:154 | `plans/reference/check-runner.md` | present |
| plans/reference/check-loop.md:155 | `check-runner` | present |
| plans/reference/check-loop.md:155 | `.claude/agents/check-runner.md` | present |
| plans/reference/check-runner.md:6 | `check-runner` | present |
| plans/reference/check-runner.md:6 | `check-runner-haiku` | present |
| plans/reference/check-runner.md:6 | `check-runner` | present |
| plans/reference/check-runner.md:7 | `check-runner-opus` | present |
| plans/reference/check-runner.md:8 | `ROOT` | present |
| plans/reference/check-runner.md:15 | `ROOT/checks/ready/` | present |
| plans/reference/check-runner.md:16 | `checks/` | present |
| plans/reference/check-runner.md:18 | `Runner:` | present |
| plans/reference/check-runner.md:22 | `Godot.exe` | present |
| plans/reference/check-runner.md:23 | `ROOT` | present |
| plans/reference/check-runner.md:24 | `"/c/Program Files/Godot/Godot.exe" --path .` | present |
| plans/reference/check-runner.md:30 | `cannot-run` | present |
| plans/reference/check-runner.md:30 | `needs_dave` | present |
| plans/reference/check-runner.md:35 | `checks/` | present |
| plans/reference/check-runner.md:35 | `tools/new_check.py` | present |
| plans/reference/check-runner.md:40 | `cannot-run` | present |
| plans/reference/check-runner.md:41 | `fail` | present |
| plans/reference/check-runner.md:53 | `cannot-run` | present |
| plans/reference/check-runner.md:55 | `evidence` | present |
| plans/reference/check-runner.md:61 | `checks/ready.md` | present |
| plans/reference/check-runner.md:61 | `Runner:` | present |
| plans/reference/check-runner.md:62 | `grep -h "^Runner:" checks/ready/C-<n>.md` | present |
| plans/reference/check-runner.md:66 | `haiku` | present |
| plans/reference/check-runner.md:66 | `check-runner-haiku` | present |
| plans/reference/check-runner.md:67 | `sonnet` | present |
| plans/reference/check-runner.md:67 | `check-runner` | present |
| plans/reference/check-runner.md:68 | `opus` | present |
| plans/reference/check-runner.md:68 | `check-runner-opus` | present |
| plans/reference/check-runner.md:69 | `dave` | present |
| plans/reference/check-runner.md:70 | `sonnet` | present |
| plans/reference/check-runner.md:72 | `ROOT` | present |
| plans/reference/check-runner.md:74 | `pass` | present |
| plans/reference/check-runner.md:74 | `fail` | present |
| plans/reference/check-runner.md:74 | `cannot-run` | present |
| plans/reference/check-runner.md:74 | `haiku` | present |
| plans/reference/check-runner.md:74 | `sonnet` | present |
| plans/reference/check-runner.md:75 | `needs_dave` | present |
| plans/reference/check-runner.md:75 | `check-runner-opus` | present |
| plans/reference/check-runner.md:77 | `needs_dave` | present |
| plans/reference/check-runner.md:77 | `opus` | present |
| plans/reference/check-runner.md:78 | `Runner:` | present |
| plans/reference/check-runner.md:83 | `python tools/new_check.py ... --runner <haiku|sonnet|opus|dave>` | present |
| plans/reference/check-runner.md:84 | `-- <why>` | present |
| plans/reference/check-runner.md:87 | `haiku` | present |
| plans/reference/check-runner.md:88 | `sonnet` | present |
| plans/reference/check-runner.md:90 | `opus` | present |
| plans/reference/check-runner.md:94 | `dave` | present |
| plans/reference/closeout.md:7 | `tools/slice.ps1 finish` | present |
| plans/reference/closeout.md:8 | `CLAUDE.md` | present |
| plans/reference/closeout.md:13 | `[Claude]` | present |
| plans/reference/closeout.md:13 | `[Codex]` | present |
| plans/reference/closeout.md:14 | `tools/check_docs.py` | present |
| plans/reference/closeout.md:14 | `NEXTSTEPS.md` | present |
| plans/reference/closeout.md:16 | `tools/slice.ps1 start` | present |
| plans/reference/closeout.md:17 | `plans/workstreams.md` | present |
| plans/reference/closeout.md:19 | `competing` | present |
| plans/reference/closeout.md:23 | `NEXTSTEPS.md` | present |
| plans/reference/closeout.md:23 | `plans/` | present |
| plans/reference/closeout.md:24 | `gates` | present |
| plans/reference/closeout.md:24 | `refill` | present |
| plans/reference/closeout.md:27 | `tools/slice.ps1 owner` | present |
| plans/reference/closeout.md:36 | `tools/verify.ps1` | present |
| plans/reference/closeout.md:39 | `Files:` | present |
| plans/reference/closeout.md:44 | `tools/slice.ps1 finish` | present |
| plans/reference/closeout.md:47 | `python tools/archive_slice.py <id>` | present |
| plans/reference/closeout.md:51 | `tools/check_docs.py` | present |
| plans/reference/closeout.md:52 | `<id> -- closeout: ...` | present |
| plans/reference/closeout.md:53 | `archived` | present |
| plans/reference/closeout.md:53 | `refilled` | present |
| plans/reference/closeout.md:55 | `<id> -- closeout on master: ...` | present |
| plans/reference/closeout.md:59 | `Next:` | present |
| plans/reference/closeout.md:60 | `Next: None — plan complete` | present |
| plans/reference/closeout.md:62 | `finish` | present |
| plans/reference/closeout.md:68 | `Next after:` | present |
| plans/reference/closeout.md:68 | `queue` | present |
| plans/reference/closeout.md:69 | `**[Lane] <id> -- <title>**` | present |
| plans/reference/closeout.md:71 | `queue-gated` | present |
| plans/reference/closeout.md:72 | `saying what it waits for.` | present |
| plans/reference/closeout.md:74 | `refill_lane.py` | moved to tools/refill_lane.py |
| plans/reference/closeout.md:74 | `finish` | present |
| plans/reference/closeout.md:77 | `Proof:` | present |
| plans/reference/closeout.md:80 | `finish` | present |
| plans/reference/closeout.md:85 | `finish` | present |
| plans/reference/closeout.md:89 | `finish` | present |
| plans/reference/closeout.md:95 | `verify.ps1 -Full` | present |
| plans/reference/closeout.md:96 | `verify.ps1` | moved to tools/verify.ps1 |
| plans/reference/closeout.md:96 | `finish` | present |
| plans/reference/closeout.md:98 | `run_in_background` | present |
| plans/reference/closeout.md:98 | `Slice landed:` | present |
| plans/reference/closeout.md:98 | `slice finish stopped` | present |
| plans/reference/closeout.md:101 | `finish` | present |
| plans/reference/closeout.md:103 | `finish` | present |
| plans/reference/closeout.md:104 | `tools/slice.ps1 status -Lane <lane>` | present |
| plans/reference/closeout.md:104 | `status` | present |
| plans/reference/closeout.md:105 | `implementing` | present |
| plans/reference/closeout.md:105 | `ready-to-finish` | present |
| plans/reference/closeout.md:105 | `verifying (<stage>, <elapsed>, last output <n>s ago)` | present |
| plans/reference/closeout.md:106 | `verify orphaned (PID gone, no result)` | present |
| plans/reference/closeout.md:106 | `closing at <phase>` | present |
| plans/reference/closeout.md:106 | `lane dry` | present |
| plans/reference/closeout.md:106 | `next` | present |
| plans/reference/closeout.md:108 | `tools/slice.ps1 stop-verify -Lane <lane>` | present |
| plans/reference/closeout.md:109 | `meadow-verify-status-<hash>.json` | present |
| plans/reference/closeout.md:110 | `start` | present |
| plans/reference/closeout.md:112 | `tools/slice.ps1 status` | present |
| plans/reference/closeout.md:113 | `running` | present |
| plans/reference/closeout.md:114 | `last_run` | present |
| plans/reference/closeout.md:114 | `outcome` | present |
| plans/reference/closeout.md:114 | `step` | present |
| plans/reference/closeout.md:115 | `cause` | present |
| plans/reference/closeout.md:116 | `meadow-slice-verify.log` | present |
| plans/reference/closeout.md:117 | `.git` | present |
| plans/reference/closeout.md:119 | `NEXTSTEPS.md` | present |
| plans/reference/closeout.md:125 | `finish` | present |
| plans/reference/closeout.md:127 | `finish` | present |
| plans/reference/closeout.md:128 | `CHATGPT.md` | present |
| plans/reference/closeout.md:129 | `git show --stat` | present |
| plans/reference/closeout.md:142 | `C-<n>.md` | present |
| plans/reference/closeout.md:142 | `checks/ready/` | present |
| plans/reference/closeout.md:143 | `checks/ready.md` | present |
| plans/reference/closeout.md:143 | `### C-<n> -- <name>` | present |
| plans/reference/closeout.md:144 | `PASS:` | present |
| plans/reference/closeout.md:144 | `Runner:` | present |
| plans/reference/closeout.md:145 | `plans/reference/check-runner.md` | present |
| plans/reference/closeout.md:146 | `Owner:` | present |
| plans/reference/closeout.md:147 | `python tools/new_check.py --name "<name>" --owner <plan> --runner <runner>` | present |
| plans/reference/closeout.md:149 | `finish` | present |
| plans/reference/closeout.md:151 | `new_check.py --renumber-clashes master` | present |
| plans/reference/closeout.md:151 | `finish` | present |
| plans/reference/closeout.md:153 | `checks/blocked.md` | present |
| plans/reference/closeout.md:154 | `python tools/new_check.py --confirm C-<n>` | present |
| plans/reference/closeout.md:156 | `plans/reference/check-loop.md` | present |
| plans/reference/closeout.md:159 | `Acceptance` | present |
| plans/reference/closeout.md:162 | `checks/blocked.md` | present |
| plans/reference/closeout.md:164 | `plans/reference/check-loop.md` | present |
| plans/reference/closeout.md:168 | `checks/ready.md` | present |
| plans/reference/closeout.md:173 | `finish` | present |
| plans/reference/closeout.md:177 | `plans/observations/system-improvement-signals.md` | present |
| plans/reference/colony-diagnostics.md:6 | `plans/design/product-scope.md` | present |
| plans/reference/colony-diagnostics.md:10 | `plans/archive/colony-run_2026-10-08.md` | present |
| plans/reference/colony-diagnostics.md:12 | `plans/design/product-scope.md` | present |
| plans/reference/colony-diagnostics.md:15 | `colony_diagnostics.gd` | moved to scripts/colony_diagnostics.gd |
| plans/reference/colony-diagnostics.md:15 | `Dictionary` | present |
| plans/reference/colony-diagnostics.md:36 | `main.gd::_role_counts()` | present |
| plans/reference/colony-diagnostics.md:36 | `Dictionary` | present |
| plans/reference/colony-diagnostics.md:36 | `_role_counts_cache` | present |
| plans/reference/colony-diagnostics.md:36 | `_role_counts_built_epoch` | present |
| plans/reference/colony-diagnostics.md:36 | `_population_epoch` | present |
| plans/reference/colony-diagnostics.md:36 | `Dictionary` | present |
| plans/reference/colony-diagnostics.md:37 | `hive.gd::_content_index()` | present |
| plans/reference/colony-diagnostics.md:37 | `content_type` | present |
| plans/reference/colony-diagnostics.md:37 | `nectar` | present |
| plans/reference/colony-diagnostics.md:37 | `pollen` | present |
| plans/reference/colony-diagnostics.md:37 | `honey` | present |
| plans/reference/colony-diagnostics.md:37 | `jelly` | present |
| plans/reference/colony-diagnostics.md:37 | `brood` | present |
| plans/reference/colony-diagnostics.md:37 | `corpse` | present |
| plans/reference/colony-diagnostics.md:37 | `unbuilt` | present |
| plans/reference/colony-diagnostics.md:37 | `ripe_honey` | present |
| plans/reference/colony-diagnostics.md:37 | `cells_holding()` | present |
| plans/reference/colony-diagnostics.md:37 | `cells_holding("brood")` | present |
| plans/reference/colony-diagnostics.md:37 | `cells_holding("")` | present |
| plans/reference/colony-diagnostics.md:38 | `year_winter.gd::_refresh_signals` | present |
| plans/reference/colony-diagnostics.md:38 | `starving` | present |
| plans/reference/colony-diagnostics.md:38 | `hungry` | present |
| plans/reference/colony-diagnostics.md:38 | `foragers` | present |
| plans/reference/colony-diagnostics.md:38 | `nurses` | present |
| plans/reference/colony-diagnostics.md:38 | `comb_workers` | present |
| plans/reference/colony-diagnostics.md:38 | `hungry_brood` | present |
| plans/reference/colony-diagnostics.md:38 | `free_cells` | present |
| plans/reference/colony-diagnostics.md:38 | `_refresh_panels` | present |
| plans/reference/colony-diagnostics.md:38 | `hungry_brood` | present |
| plans/reference/colony-diagnostics.md:38 | `free_cells` | present |
| plans/reference/colony-diagnostics.md:38 | `main.signal_timer` | present |
| plans/reference/colony-diagnostics.md:38 | `_winter_forecast` | present |
| plans/reference/colony-diagnostics.md:38 | `_refresh_panels` | present |
| plans/reference/colony-diagnostics.md:38 | `_refresh_winter` | present |
| plans/reference/colony-diagnostics.md:38 | `get_tree().get_nodes_in_group("bees")` | present |
| plans/reference/colony-diagnostics.md:38 | `plans/reference/technical-audit.md` | present |
| plans/reference/colony-diagnostics.md:39 | `problem_messages.gd` | moved to scripts/problem_messages.gd |
| plans/reference/colony-diagnostics.md:39 | `hud.show_warning` | present |
| plans/reference/colony-diagnostics.md:40 | `diagnostic_log.gd` | moved to scripts/diagnostic_log.gd |
| plans/reference/colony-diagnostics.md:40 | `docs/headless-run-contract.md` | present |
| plans/reference/colony-diagnostics.md:40 | `population.total` | present |
| plans/reference/colony-diagnostics.md:40 | `resources.food_stores` | present |
| plans/reference/colony-diagnostics.md:40 | `resources.stored_nectar` | present |
| plans/reference/colony-diagnostics.md:40 | `resources.stored_pollen` | present |
| plans/reference/colony-diagnostics.md:40 | `environment.winter_here` | present |
| plans/reference/colony-diagnostics.md:40 | `environment.flowers_by_species` | present |
| plans/reference/colony-diagnostics.md:40 | `role_outcomes.cells_completed_total` | present |
| plans/reference/colony-diagnostics.md:40 | `performance.fps` | present |
| plans/reference/colony-diagnostics.md:40 | `performance.top_sections_ms` | present |
| plans/reference/colony-diagnostics.md:47 | `year_winter.gd` | moved to scripts/year_winter.gd |
| plans/reference/colony-diagnostics.md:48 | `main.signal_timer` | present |
| plans/reference/colony-diagnostics.md:48 | `_refresh_signals` | present |
| plans/reference/colony-diagnostics.md:50 | `Dictionary` | present |
| plans/reference/colony-diagnostics.md:52 | `bees: Array` | present |
| plans/reference/colony-diagnostics.md:52 | `_refresh_signals` | present |
| plans/reference/colony-diagnostics.md:52 | `_refresh_panels(bees, facts, counts)` | present |
| plans/reference/colony-diagnostics.md:53 | `_refresh_winter(bees_count)` | present |
| plans/reference/colony-diagnostics.md:53 | `_winter_forecast(bees_count)` | present |
| plans/reference/colony-diagnostics.md:54 | `bees` | present |
| plans/reference/colony-diagnostics.md:54 | `counts` | present |
| plans/reference/colony-diagnostics.md:55 | `main._role_counts()` | present |
| plans/reference/colony-diagnostics.md:57 | `main.colony_facts` | present |
| plans/reference/colony-diagnostics.md:59 | `main.hud.corner_texts` | present |
| plans/reference/colony-diagnostics.md:63 | `year_winter.gd` | moved to scripts/year_winter.gd |
| plans/reference/colony-diagnostics.md:63 | `year_winter.gd` | moved to scripts/year_winter.gd |
| plans/reference/colony-diagnostics.md:68 | `colony_diagnostics.gd` | moved to scripts/colony_diagnostics.gd |
| plans/reference/colony-diagnostics.md:68 | `extends RefCounted` | present |
| plans/reference/colony-diagnostics.md:69 | `static func` | present |
| plans/reference/colony-diagnostics.md:69 | `main` | present |
| plans/reference/colony-diagnostics.md:69 | `bees` | present |
| plans/reference/colony-diagnostics.md:70 | `Dictionary` | present |
| plans/reference/colony-diagnostics.md:70 | `GAME_MODEL.md` | present |
| plans/reference/colony-diagnostics.md:75 | `year_winter.gd` | moved to scripts/year_winter.gd |
| plans/reference/colony-diagnostics.md:76 | `colony_diagnostics.gd::compute(main, bees) -> Dictionary` | present |
| plans/reference/colony-diagnostics.md:77 | `compute(main, bees, counts)` | present |
| plans/reference/colony-diagnostics.md:78 | `plans/archive/COLONY_DIAGNOSTICS_CD1_2026-09-04.md` | present |
| plans/reference/colony-diagnostics.md:82 | `Dictionary` | present |
| plans/reference/colony-diagnostics.md:83 | `docs/headless-run-contract.md` | present |
| plans/reference/colony-diagnostics.md:90 | `starving` | present |
| plans/reference/colony-diagnostics.md:90 | `hungry` | present |
| plans/reference/colony-diagnostics.md:90 | `foragers` | present |
| plans/reference/colony-diagnostics.md:90 | `nurses` | present |
| plans/reference/colony-diagnostics.md:90 | `comb_workers` | present |
| plans/reference/colony-diagnostics.md:90 | `hungry_brood` | present |
| plans/reference/colony-diagnostics.md:91 | `free_cells` | present |
| plans/reference/colony-diagnostics.md:100 | `year_winter.gd` | moved to scripts/year_winter.gd |
| plans/reference/colony-diagnostics.md:110 | `scripts/colony_diagnostics.gd` | present |
| plans/reference/colony-diagnostics.md:110 | `scripts/year_winter.gd` | present |
| plans/reference/colony-diagnostics.md:111 | `compute()` | present |
| plans/reference/colony-diagnostics.md:112 | `scripts/main.gd` | present |
| plans/reference/colony-diagnostics.md:112 | `_role_counts()` | present |
| plans/reference/colony-diagnostics.md:112 | `_role_counts_cache` | present |
| plans/reference/colony-diagnostics.md:115 | `plans/reference/technical-audit.md` | present |
| plans/reference/colony-diagnostics.md:118 | `docs/headless-run-contract.md` | present |
| plans/reference/jules.md:10 | `AGENTS.md` | present |
| plans/reference/jules.md:17 | `docs/known-pitfalls.md` | present |
| plans/reference/jules.md:29 | `git fetch origin` | present |
| plans/reference/jules.md:29 | `git switch -c jules/<id>-<topic> origin/master` | present |
| plans/reference/jules.md:30 | `python tools/jules_preflight.py --next` | present |
| plans/reference/jules.md:30 | `python tools/heading.py plans/reference/jules.md "Standing tasks"` | present |
| plans/reference/jules.md:30 | `git branch -r --list 'origin/jules/s-*'` | present |
| plans/reference/jules.md:31 | `python tools/heading.py plans/reference/jules.md "How to work"` | present |
| plans/reference/jules.md:32 | `Do:` | present |
| plans/reference/jules.md:32 | `python tools/jules_preflight.py --scope` | present |
| plans/reference/jules.md:32 | `off` | present |
| plans/reference/jules.md:32 | `J-<n>: <task title>` | present |
| plans/reference/jules.md:32 | `S-<n>:` | present |
| plans/reference/jules.md:36 | `--next` | present |
| plans/reference/jules.md:38 | `--scope` | present |
| plans/reference/jules.md:38 | `off` | present |
| plans/reference/jules.md:44 | `Files:` | present |
| plans/reference/jules.md:46 | `--scope` | present |
| plans/reference/jules.md:55 | `origin/master` | present |
| plans/reference/jules.md:55 | `--scope` | present |
| plans/reference/jules.md:55 | `off` | present |
| plans/reference/jules.md:56 | `heading.py` | moved to tools/heading.py |
| plans/reference/jules.md:63 | `python tools/jules_preflight.py --next` | present |
| plans/reference/jules.md:63 | `origin` | present |
| plans/reference/jules.md:65 | `jules/j-<n>-*` | present |
| plans/reference/jules.md:67 | `Files:` | present |
| plans/reference/jules.md:67 | `After:` | present |
| plans/reference/jules.md:67 | `Why:` | present |
| plans/reference/jules.md:67 | `Do:` | present |
| plans/reference/jules.md:68 | `Do:` | present |
| plans/reference/jules.md:71 | `must print` | present |
| plans/reference/jules.md:72 | `owned` | present |
| plans/reference/jules.md:79 | `origin/master` | present |
| plans/reference/jules.md:81 | `jules/j-<n>-<topic>` | present |
| plans/reference/jules.md:81 | `jules/s-<n>-<topic>` | present |
| plans/reference/jules.md:82 | `J-<n>:` | present |
| plans/reference/jules.md:82 | `S-<n>:` | present |
| plans/reference/jules.md:86 | `origin/master` | present |
| plans/reference/jules.md:88 | `"name"` | present |
| plans/reference/jules.md:88 | `call(` | present |
| plans/reference/jules.md:89 | `connect(` | present |
| plans/reference/jules.md:89 | `Callable(` | present |
| plans/reference/jules.md:89 | `.tscn` | present |
| plans/reference/jules.md:89 | `method=` | present |
| plans/reference/jules.md:92 | `path:line` | present |
| plans/reference/jules.md:93 | `origin/master` | present |
| plans/reference/jules.md:95 | `python tests/source_checks.py` | present |
| plans/reference/jules.md:95 | `python tests/balance_tests.py` | present |
| plans/reference/jules.md:96 | `python -m unittest tests.<your test module>` | gone |
| plans/reference/jules.md:106 | `python tools/jules_preflight.py --scope` | present |
| plans/reference/jules.md:107 | `origin/master` | present |
| plans/reference/jules.md:108 | `off` | present |
| plans/reference/jules.md:108 | `master` | present |
| plans/reference/jules.md:110 | `off` | present |
| plans/reference/jules.md:111 | `--scope` | present |
| plans/reference/jules.md:111 | `off` | present |
| plans/reference/jules.md:112 | `jules/j-*` | present |
| plans/reference/jules.md:113 | `Task:` | present |
| plans/reference/jules.md:114 | `Preflight:` | present |
| plans/reference/jules.md:114 | `Scope:` | present |
| plans/reference/jules.md:114 | `Ran:` | present |
| plans/reference/jules.md:115 | `Not run:` | present |
| plans/reference/jules.md:115 | `tools/verify.ps1` | present |
| plans/reference/jules.md:116 | `Covers:` | present |
| plans/reference/jules.md:117 | `Do:` | present |
| plans/reference/jules.md:118 | `Proof:` | present |
| plans/reference/jules.md:118 | `Follow-ups:` | present |
| plans/reference/jules.md:123 | `Files:` | present |
| plans/reference/jules.md:123 | `docs/audits/` | present |
| plans/reference/jules.md:129 | `# Audit: <title>` | present |
| plans/reference/jules.md:131 | `## Summary` | present |
| plans/reference/jules.md:133 | `## Findings` | present |
| plans/reference/jules.md:135 | `docs/known-pitfalls.md` | present |
| plans/reference/jules.md:135 | `docs/agent-rules.md` | present |
| plans/reference/jules.md:138 | `## Candidate Jules tasks` | present |
| plans/reference/jules.md:139 | `### J-? -- title` | present |
| plans/reference/jules.md:139 | `Files:` | present |
| plans/reference/jules.md:139 | `After:` | present |
| plans/reference/jules.md:139 | `Why:` | present |
| plans/reference/jules.md:139 | `Do:` | present |
| plans/reference/jules.md:141 | `python tools/jules_preflight.py <files>` | present |
| plans/reference/jules.md:143 | `## For Claude or Codex` | present |
| plans/reference/jules.md:144 | `owned` | present |
| plans/reference/jules.md:145 | `plans/` | present |
| plans/reference/jules.md:146 | `## Inventory` | present |
| plans/reference/jules.md:148 | `## Method` | present |
| plans/reference/jules.md:151 | `python tools/check_docs.py` | present |
| plans/reference/jules.md:152 | `Covers:` | present |
| plans/reference/jules.md:152 | `Do:` | present |
| plans/reference/jules.md:156 | `GameConfig` | present |
| plans/reference/jules.md:157 | `plans/now/code-health.md` | present |
| plans/reference/jules.md:157 | `NEXTSTEPS.md` | present |
| plans/reference/jules.md:158 | `plans/` | present |
| plans/reference/jules.md:158 | `checks/` | present |
| plans/reference/jules.md:158 | `FUNCTION_MAP.md` | present |
| plans/reference/jules.md:160 | `tools/heading.py` | present |
| plans/reference/jules.md:164 | `tools/new_check.py` | present |
| plans/reference/jules.md:168 | `tests/test_review_tools.py` | present |
| plans/reference/jules.md:168 | `used_ids` | present |
| plans/reference/jules.md:168 | `next_free_id` | present |
| plans/reference/jules.md:169 | `record_text` | present |
| plans/reference/jules.md:169 | `day_label` | present |
| plans/reference/jules.md:169 | `pass_heading` | present |
| plans/reference/jules.md:169 | `insert_entries` | present |
| plans/reference/jules.md:171 | `checks/` | present |
| plans/reference/jules.md:173 | `insert_entries` | present |
| plans/reference/jules.md:176 | `tools/update_function_map.py` | present |
| plans/reference/jules.md:180 | `_paren_balance` | present |
| plans/reference/jules.md:180 | `_joined_signature` | present |
| plans/reference/jules.md:182 | `FUNCTION_MAP.md` | present |
| plans/reference/jules.md:183 | `_paren_balance` | present |
| plans/reference/jules.md:184 | `(` | present |
| plans/reference/jules.md:184 | `[` | present |
| plans/reference/jules.md:184 | `{` | present |
| plans/reference/jules.md:185 | `"..."` | present |
| plans/reference/jules.md:185 | `'...'` | present |
| plans/reference/jules.md:185 | `\"` | present |
| plans/reference/jules.md:186 | `#` | present |
| plans/reference/jules.md:186 | `_joined_signature` | present |
| plans/reference/jules.md:188 | `func f(` | present |
| plans/reference/jules.md:188 | `a: int,` | present |
| plans/reference/jules.md:189 | `b: int,` | present |
| plans/reference/jules.md:189 | `) -> void:` | present |
| plans/reference/jules.md:189 | `func f(a: int, b: int) -> void:` | present |
| plans/reference/jules.md:190 | `[` | present |
| plans/reference/jules.md:193 | `tools/sprites.py` | present |
| plans/reference/jules.md:197 | `_hex_colour` | present |
| plans/reference/jules.md:197 | `parse_table` | present |
| plans/reference/jules.md:197 | `_parse_grid` | present |
| plans/reference/jules.md:198 | `_state_name` | present |
| plans/reference/jules.md:198 | `SPRITES.md` | moved to assets/sprites/SPRITES.md |
| plans/reference/jules.md:201 | `SPRITES.md` | moved to assets/sprites/SPRITES.md |
| plans/reference/jules.md:201 | `_hex_colour` | present |
| plans/reference/jules.md:201 | `#ff8000` | present |
| plans/reference/jules.md:201 | `FF8000` | present |
| plans/reference/jules.md:202 | `(255, 128, 0)` | present |
| plans/reference/jules.md:202 | `SpriteError` | present |
| plans/reference/jules.md:203 | `parse_table` | present |
| plans/reference/jules.md:203 | `---` | present |
| plans/reference/jules.md:204 | `-` | present |
| plans/reference/jules.md:205 | `2/5` | present |
| plans/reference/jules.md:205 | `3,4` | present |
| plans/reference/jules.md:206 | `; check both` | present |
| plans/reference/jules.md:207 | `SpriteError` | present |
| plans/reference/jules.md:207 | `VIEWS` | present |
| plans/reference/jules.md:208 | `>` | present |
| plans/reference/jules.md:210 | `_parse_grid` | present |
| plans/reference/jules.md:210 | `grid 16x24 rows=left,right` | present |
| plans/reference/jules.md:211 | `(16, 24, ["left", "right"])` | present |
| plans/reference/jules.md:211 | `grid 16 rows=a` | present |
| plans/reference/jules.md:212 | `grid 16x16` | present |
| plans/reference/jules.md:212 | `_state_name` | present |
| plans/reference/jules.md:215 | `tools/uncalled.py` | present |
| plans/reference/jules.md:219 | `find_gdscript_functions` | present |
| plans/reference/jules.md:219 | `preindex_file_contents` | present |
| plans/reference/jules.md:220 | `is_function_referenced` | present |
| plans/reference/jules.md:223 | `func used()` | present |
| plans/reference/jules.md:224 | `,` | present |
| plans/reference/jules.md:224 | `and` | present |
| plans/reference/jules.md:225 | `used()` | present |
| plans/reference/jules.md:225 | `find_gdscript_functions` | present |
| plans/reference/jules.md:226 | `scripts/` | present |
| plans/reference/jules.md:227 | `helper` | present |
| plans/reference/jules.md:227 | `_ready` | present |
| plans/reference/jules.md:228 | `[]` | present |
| plans/reference/jules.md:228 | `preindex_file_contents` | present |
| plans/reference/jules.md:230 | `is_function_referenced` | present |
| plans/reference/jules.md:230 | `used` | present |
| plans/reference/jules.md:230 | `unused` | present |
| plans/reference/jules.md:232 | `use` | present |
| plans/reference/jules.md:233 | `used` | present |
| plans/reference/jules.md:235 | `tools/session_cost.py` | present |
| plans/reference/jules.md:239 | `_row_texts` | present |
| plans/reference/jules.md:239 | `_extract_text` | present |
| plans/reference/jules.md:239 | `_first_timestamp` | present |
| plans/reference/jules.md:240 | `_is_slice_worker` | present |
| plans/reference/jules.md:240 | `_is_coordinator` | present |
| plans/reference/jules.md:241 | `session_cost.py` | moved to tools/session_cost.py |
| plans/reference/jules.md:243 | `_row_texts` | present |
| plans/reference/jules.md:244 | `message.content` | present |
| plans/reference/jules.md:244 | `text` | present |
| plans/reference/jules.md:244 | `content` | present |
| plans/reference/jules.md:245 | `text` | present |
| plans/reference/jules.md:245 | `rendered` | present |
| plans/reference/jules.md:245 | `content` | present |
| plans/reference/jules.md:246 | `_extract_text` | present |
| plans/reference/jules.md:247 | `""` | present |
| plans/reference/jules.md:248 | `None` | present |
| plans/reference/jules.md:248 | `_first_timestamp` | present |
| plans/reference/jules.md:249 | `timestamp` | present |
| plans/reference/jules.md:250 | `None` | present |
| plans/reference/jules.md:251 | `_is_slice_worker` | present |
| plans/reference/jules.md:251 | `<stem>.meta.json` | present |
| plans/reference/jules.md:252 | `agentType` | present |
| plans/reference/jules.md:252 | `slice-worker-low` | present |
| plans/reference/jules.md:252 | `Explore` | present |
| plans/reference/jules.md:253 | `_is_coordinator` | present |
| plans/reference/jules.md:253 | `<stem>/subagents/` | present |
| plans/reference/jules.md:254 | `Explore` | present |
| plans/reference/jules.md:260 | `docs/known-pitfalls.md` | present |
| plans/reference/jules.md:264 | `##` | present |
| plans/reference/jules.md:265 | `docs/known-pitfalls.md` | present |
| plans/reference/jules.md:280 | `docs/known-pitfalls.md` | present |
| plans/reference/jules.md:280 | `set_size()` | present |
| plans/reference/jules.md:283 | `scripts/` | present |
| plans/reference/jules.md:283 | `size` | present |
| plans/reference/jules.md:284 | `position` | present |
| plans/reference/jules.md:284 | `reset_size()` | present |
| plans/reference/jules.md:285 | `.gd` | present |
| plans/reference/jules.md:285 | `scripts/` | present |
| plans/reference/jules.md:286 | `size` | present |
| plans/reference/jules.md:286 | `position` | present |
| plans/reference/jules.md:286 | `global_position` | present |
| plans/reference/jules.md:286 | `set_size(` | present |
| plans/reference/jules.md:286 | `set_position(` | present |
| plans/reference/jules.md:287 | `reset_size()` | present |
| plans/reference/jules.md:288 | `scripts/ui_panel_layout.gd` | present |
| plans/reference/jules.md:289 | `position` | present |
| plans/reference/jules.md:290 | `HFlowContainer` | present |
| plans/reference/jules.md:291 | `size_flags_horizontal` | present |
| plans/reference/jules.md:291 | `clip_text` | present |
| plans/reference/jules.md:292 | `autowrap_mode` | present |
| plans/reference/jules.md:293 | `SIZE_EXPAND_FILL` | present |
| plans/reference/jules.md:294 | `plans/reference/ui-rules.md` | present |
| plans/reference/jules.md:302 | `docs/known-pitfalls.md` | present |
| plans/reference/jules.md:303 | `hive_root` | present |
| plans/reference/jules.md:303 | `meadow_root` | present |
| plans/reference/jules.md:304 | `hive_root` | present |
| plans/reference/jules.md:307 | `.gd` | present |
| plans/reference/jules.md:307 | `scripts/` | present |
| plans/reference/jules.md:307 | `hive_root` | present |
| plans/reference/jules.md:308 | `meadow_root` | present |
| plans/reference/jules.md:308 | `global_position` | present |
| plans/reference/jules.md:308 | `to_global` | present |
| plans/reference/jules.md:308 | `to_local` | present |
| plans/reference/jules.md:309 | `reparent` | present |
| plans/reference/jules.md:309 | `add_child` | present |
| plans/reference/jules.md:310 | `distance_to` | present |
| plans/reference/jules.md:315 | `hive_root` | present |
| plans/reference/jules.md:315 | `meadow_root` | present |
| plans/reference/jules.md:325 | `scripts/saving.gd` | present |
| plans/reference/jules.md:326 | `.claude/rules/saving.md` | present |
| plans/reference/jules.md:327 | `scripts/saving.gd` | present |
| plans/reference/jules.md:328 | `save_*` | present |
| plans/reference/jules.md:328 | `restore_*` | present |
| plans/reference/jules.md:329 | `var` | present |
| plans/reference/jules.md:330 | `_ready` | present |
| plans/reference/jules.md:335 | `saving.gd` | moved to scripts/saving.gd |
| plans/reference/jules.md:343 | `tools/uncalled.py` | present |
| plans/reference/jules.md:344 | `signal` | present |
| plans/reference/jules.md:345 | `scripts/` | present |
| plans/reference/jules.md:346 | `signal` | present |
| plans/reference/jules.md:346 | `scripts/` | present |
| plans/reference/jules.md:347 | `emit` | present |
| plans/reference/jules.md:347 | `emit_signal("name"` | present |
| plans/reference/jules.md:348 | `.connect(` | present |
| plans/reference/jules.md:348 | `connect("name"` | present |
| plans/reference/jules.md:348 | `[connection]` | present |
| plans/reference/jules.md:349 | `.tscn` | present |
| plans/reference/jules.md:351 | `is_connected` | present |
| plans/reference/jules.md:353 | `pressed` | present |
| plans/reference/jules.md:353 | `timeout` | present |
| plans/reference/jules.md:353 | `tree_exited` | present |
| plans/reference/jules.md:361 | `docs/known-pitfalls.md` | present |
| plans/reference/jules.md:366 | `_process` | present |
| plans/reference/jules.md:366 | `_physics_process` | present |
| plans/reference/jules.md:366 | `_draw` | present |
| plans/reference/jules.md:366 | `_input` | present |
| plans/reference/jules.md:367 | `scripts/` | present |
| plans/reference/jules.md:367 | `wait_time` | present |
| plans/reference/jules.md:369 | `scripts/hive_cell.gd` | present |
| plans/reference/jules.md:369 | `_process` | present |
| plans/reference/jules.md:372 | `Array` | present |
| plans/reference/jules.md:372 | `Dictionary` | present |
| plans/reference/jules.md:372 | `str()` | present |
| plans/reference/jules.md:373 | `%` | present |
| plans/reference/jules.md:373 | `get_children()` | present |
| plans/reference/jules.md:373 | `get_nodes_in_group(` | present |
| plans/reference/jules.md:374 | `find_child(` | present |
| plans/reference/jules.md:374 | `duplicate()` | present |
| plans/reference/jules.md:374 | `queue_redraw()` | present |
| plans/reference/jules.md:377 | `Perf.begin` | present |
| plans/reference/jules.md:377 | `Perf.end` | present |
| plans/reference/jules.md:383 | `GameConfig` | present |
| plans/reference/jules.md:387 | `.gd` | present |
| plans/reference/jules.md:387 | `scripts/` | present |
| plans/reference/jules.md:391 | `GameConfig` | present |
| plans/reference/jules.md:395 | `scripts/settings_catalogue.gd` | present |
| plans/reference/jules.md:402 | `scripts/roles.gd` | present |
| plans/reference/jules.md:403 | `Session` | present |
| plans/reference/jules.md:403 | `docs/known-pitfalls.md` | present |
| plans/reference/jules.md:408 | `match` | present |
| plans/reference/jules.md:408 | `if` | present |
| plans/reference/jules.md:409 | `scripts/roles.gd` | present |
| plans/reference/jules.md:410 | `roles.gd` | moved to scripts/roles.gd |
| plans/reference/jules.md:411 | `Session` | present |
| plans/reference/jules.md:411 | `scripts/session.gd` | present |
| plans/reference/jules.md:420 | `docs/known-pitfalls.md` | present |
| plans/reference/jules.md:425 | `tests/test_*.py` | present |
| plans/reference/jules.md:425 | `tests/source_checks.py` | present |
| plans/reference/jules.md:426 | `tests/balance_tests.py` | present |
| plans/reference/jules.md:427 | `tests/fixtures/` | present |
| plans/reference/jules.md:428 | `any(` | present |
| plans/reference/jules.md:440 | `tools/session_cost.py` | present |
| plans/reference/jules.md:441 | `tools/slice.ps1` | present |
| plans/reference/jules.md:441 | `tests/test_wc5_level_model_parity.py` | present |
| plans/reference/jules.md:445 | `tools/*.py` | gone |
| plans/reference/jules.md:445 | `tools/*.ps1` | gone |
| plans/reference/jules.md:445 | `scripts/*.gd` | present |
| plans/reference/jules.md:447 | `Status:` | present |
| plans/reference/jules.md:448 | `Proof:` | present |
| plans/reference/jules.md:459 | `.claude/rules/` | present |
| plans/reference/jules.md:459 | `docs/known-pitfalls.md` | present |
| plans/reference/jules.md:460 | `plans/reference/` | present |
| plans/reference/jules.md:460 | `tools/check_docs.py` | present |
| plans/reference/jules.md:463 | `.md` | present |
| plans/reference/jules.md:463 | `.claude/rules/` | present |
| plans/reference/jules.md:463 | `plans/reference/` | present |
| plans/reference/jules.md:464 | `reviews/` | present |
| plans/reference/jules.md:464 | `docs/known-pitfalls.md` | present |
| plans/reference/jules.md:465 | `docs/agent-rules.md` | present |
| plans/reference/jules.md:465 | `docs/headless-run-contract.md` | present |
| plans/reference/jules.md:465 | `CLAUDE.md` | present |
| plans/reference/jules.md:466 | `AGENTS.md` | present |
| plans/reference/jules.md:467 | `tools/heading.py` | present |
| plans/reference/jules.md:469 | `argparse` | present |
| plans/reference/jules.md:469 | `param()` | present |
| plans/reference/jules.md:477 | `tools/uncalled.py` | present |
| plans/reference/jules.md:478 | `scripts/progression.gd` | present |
| plans/reference/jules.md:478 | `for_group` | present |
| plans/reference/jules.md:478 | `milestone_ids` | present |
| plans/reference/jules.md:479 | `scripts/adaptations.gd` | present |
| plans/reference/jules.md:479 | `plans/design/progression.md` | present |
| plans/reference/jules.md:485 | `--next` | present |
| plans/reference/jules.md:485 | `none` | present |
| plans/reference/jules.md:488 | `tools/*.py` | gone |
| plans/reference/jules.md:490 | `def` | present |
| plans/reference/jules.md:490 | `tests/` | present |
| plans/reference/jules.md:491 | `git grep -c -w <name> -- tests` | present |
| plans/reference/jules.md:493 | `owned` | present |
| plans/reference/jules.md:494 | `python tools/uncalled.py` | present |
| plans/reference/jules.md:497 | `for_sector` | present |
| plans/reference/jules.md:498 | `sector_label` | present |
| plans/reference/jules.md:501 | `docs/known-pitfalls.md` | present |
| plans/reference/jules.md:502 | `tests/` | present |
| plans/reference/jules.md:503 | `tools/self_call_check.py` | present |
| plans/reference/jules.md:503 | `origin/master` | present |
| plans/reference/jules.md:504 | `docs/audits/` | present |
| plans/reference/jules.md:505 | `Audited:` | present |
| plans/reference/jules.md:505 | `master` | present |
| plans/reference/jules.md:506 | `Scope:` | present |
| plans/reference/jules.md:507 | `). Redo its task's` | present |
| plans/reference/jules.md:507 | `(` | present |
| plans/reference/jules.md:509 | `## Since last audit` | present |
| plans/reference/jules.md:510 | `jules/s-4-<topic>` | present |
| plans/reference/jules.md:519 | `Files:` | present |
| plans/reference/jules.md:520 | `python tools/jules_preflight.py <files>` | present |
| plans/reference/jules.md:522 | `docs/known-pitfalls.md` | present |
| plans/reference/jules.md:522 | `python tools/uncalled.py` | present |
| plans/reference/jules.md:523 | `Do:` | present |
| plans/reference/jules.md:524 | `METRICS` | present |
| plans/reference/jules.md:532 | `--queue` | present |
| plans/reference/jules.md:535 | `and take only the` | present |
| plans/reference/jules.md:536 | `git checkout origin/jules/<branch> -- <those files>` | present |
| plans/reference/jules.md:536 | `cd0b5a0e` | present |
| plans/reference/jules.md:541 | `--next` | present |
| plans/reference/jules.md:547 | `--scope` | present |
| plans/reference/jules.md:548 | `--scope J-n --ref` | present |
| plans/reference/jules.md:549 | `docs/audits/` | present |
| plans/reference/jules.md:553 | `python tools/jules_preflight.py <files>` | present |
| plans/reference/jules.md:555 | `plans/observations/system-improvement-signals.md` | present |
| plans/reference/jules.md:558 | `plans/reference/reviews/` | present |
| plans/reference/queue-steward.md:6 | `queue-steward` | present |
| plans/reference/queue-steward.md:6 | `/run-queue` | present |
| plans/reference/queue-steward.md:10 | `blocked` | present |
| plans/reference/queue-steward.md:12 | `ROOT` | present |
| plans/reference/queue-steward.md:12 | `JOB` | present |
| plans/reference/queue-steward.md:14 | `JOB` | present |
| plans/reference/queue-steward.md:20 | `python tools/check_docs.py` | present |
| plans/reference/queue-steward.md:22 | `python tools/admission.py --clear-landed <id>` | present |
| plans/reference/queue-steward.md:23 | `plans/now/` | present |
| plans/reference/queue-steward.md:24 | `ambiguous:` | present |
| plans/reference/queue-steward.md:26 | `python tools/admission.py --all` | present |
| plans/reference/queue-steward.md:27 | `queue-gated` | present |
| plans/reference/queue-steward.md:28 | `finish` | present |
| plans/reference/queue-steward.md:35 | `finish` | present |
| plans/reference/queue-steward.md:37 | `plans/archive/` | present |
| plans/reference/queue-steward.md:39 | `plans/now/` | present |
| plans/reference/queue-steward.md:40 | `Next:` | present |
| plans/reference/queue-steward.md:41 | `Next:` | present |
| plans/reference/queue-steward.md:43 | `plans/README.md` | present |
| plans/reference/queue-steward.md:44 | `queue` | present |
| plans/reference/queue-steward.md:45 | `.claude/rules/documentation.md` | present |
| plans/reference/queue-steward.md:46 | `**[Claude] <id> -- <title>**` | present |
| plans/reference/queue-steward.md:46 | `Plan:` | present |
| plans/reference/queue-steward.md:46 | `Files:` | present |
| plans/reference/queue-steward.md:46 | `Check:` | present |
| plans/reference/queue-steward.md:47 | `Proof:` | present |
| plans/reference/queue-steward.md:47 | `Next after:` | present |
| plans/reference/queue-steward.md:48 | `tools/slice.ps1 owner <path>` | present |
| plans/reference/queue-steward.md:49 | `Check:` | present |
| plans/reference/queue-steward.md:49 | `Proof:` | present |
| plans/reference/queue-steward.md:51 | `queue-gated` | present |
| plans/reference/queue-steward.md:51 | `## Not in the queue, and why` | present |
| plans/reference/queue-steward.md:54 | `python tools/refill_lane.py --top-up --lane Claude` | present |
| plans/reference/queue-steward.md:55 | `python tools/check_docs.py` | present |
| plans/reference/queue-steward.md:56 | `gates` | present |
| plans/reference/queue-steward.md:58 | `blocked` | present |
| plans/reference/queue-steward.md:59 | `plans/now/` | present |
| plans/reference/queue-steward.md:60 | `ROADMAP.md` | present |
| plans/reference/queue-steward.md:60 | `DESIGN_BACKLOG.md` | present |
| plans/reference/queue-steward.md:61 | `git -C <ROOT> show master:ROADMAP.md` | present |
| plans/reference/queue-steward.md:62 | `git -C <ROOT> show master:DESIGN_BACKLOG.md` | present |
| plans/reference/queue-steward.md:66 | `docs/agent-rules.md` | present |
| plans/reference/queue-steward.md:70 | `gates` | present |
| plans/reference/queue-steward.md:70 | `refill` | present |
| plans/reference/queue-steward.md:71 | `plans/workstreams.md` | present |
| plans/reference/queue-steward.md:73 | `tools/slice.ps1 owner` | present |
| plans/reference/queue-steward.md:75 | `tools/slice.ps1 owner <path>` | present |
| plans/reference/queue-steward.md:76 | `finish-stop` | present |
| plans/reference/queue-steward.md:81 | `slice.ps1 finish` | present |
| plans/reference/queue-steward.md:82 | `refill` | present |
| plans/reference/queue-steward.md:83 | `Proof:` | present |
| plans/reference/queue-steward.md:84 | `Proof:` | present |
| plans/reference/queue-steward.md:86 | `python tools/check_docs.py` | present |
| plans/reference/queue-steward.md:87 | `finish` | present |
| plans/reference/queue-steward.md:98 | `added` | present |
| plans/reference/queue-steward.md:98 | `cleared` | present |
| plans/reference/queue-steward.md:98 | `blocked` | present |
| plans/reference/review-contract.md:7 | `plans/reference/reviews/` | present |
| plans/reference/review-contract.md:7 | `plans/reference/reviews/README.md` | present |
| plans/reference/review-contract.md:11 | `tools/check_docs.py` | present |
| plans/reference/review-contract.md:20 | `,` | present |
| plans/reference/review-contract.md:21 | `FUNCTION_MAP.md` | present |
| plans/reference/review-contract.md:21 | `_backups/` | present |
| plans/reference/review-contract.md:22 | `ROADMAP.md` | present |
| plans/reference/review-contract.md:22 | `DESIGN_BACKLOG.md` | present |
| plans/reference/review-contract.md:23 | `plans/archive/**` | present |
| plans/reference/review-contract.md:23 | `docs/archive/**` | present |
| plans/reference/review-contract.md:24 | `git show HEAD:<path>` | present |
| plans/reference/review-contract.md:24 | `grep` | present |
| plans/reference/review-contract.md:24 | `sed` | present |
| plans/reference/review-contract.md:27 | `python tools/review_due.py <record key>` | present |
| plans/reference/review-contract.md:28 | `Reviewed:` | present |
| plans/reference/review-contract.md:28 | `SINCE` | present |
| plans/reference/review-contract.md:34 | `SINCE` | present |
| plans/reference/review-contract.md:47 | `slice.ps1 owner` | present |
| plans/reference/review-contract.md:49 | `plans/observations/system-improvement-signals.md` | present |
| plans/reference/review-contract.md:57 | `queue` | present |
| plans/reference/review-contract.md:57 | `Proof:` | present |
| plans/reference/review-contract.md:58 | `queue-gated` | present |
| plans/reference/review-contract.md:58 | `NEXTSTEPS.md` | present |
| plans/reference/review-contract.md:62 | `/run-reviews` | present |
| plans/reference/review-contract.md:65 | `plans/reference/review-runner.md` | present |
| plans/reference/review-contract.md:68 | `plans/README.md` | present |
| plans/reference/review-contract.md:69 | `.claude/rules/documentation.md` | present |
| plans/reference/review-contract.md:70 | `plans/reference/check-loop.md` | present |
| plans/reference/review-contract.md:73 | `Proof:` | present |
| plans/reference/review-contract.md:79 | `tools/slice.ps1 owner <path>` | present |
| plans/reference/review-contract.md:80 | `owned` | present |
| plans/reference/review-contract.md:82 | `NEXTSTEPS.md` | present |
| plans/reference/review-contract.md:83 | `finish` | present |
| plans/reference/review-contract.md:85 | `docs/<record key>-<YYYY-MM-DD>.md` | present |
| plans/reference/review-contract.md:88 | `python tools/check_docs.py` | present |
| plans/reference/review-contract.md:88 | `.\tools\verify.ps1` | present |
| plans/reference/review-contract.md:89 | `plans/reference/closeout.md` | present |
| plans/reference/review-contract.md:93 | `CLAUDE.md` | present |
| plans/reference/review-contract.md:93 | `Next model` | present |
| plans/reference/review-contract.md:93 | `Toggle` | present |
| plans/reference/review-contract.md:102 | `check_docs.py` | moved to tools/check_docs.py |
| plans/reference/review-contract.md:140 | `Record key:` | present |
| plans/reference/review-contract.md:141 | `plans/reference/reviews/` | present |
| plans/reference/review-contract.md:143 | `docs/PERFORMANCE_BASELINE.md` | present |
| plans/reference/review-contract.md:147 | `plans/reference/reviews/plan-review.md` | present |
| plans/reference/review-contract.md:148 | `plans/reference/reviews/product-review.md` | present |
| plans/reference/review-contract.md:149 | `plans/reference/reviews/architecture-review.md` | present |
| plans/reference/review-contract.md:150 | `plans/reference/reviews/gameplay-review.md` | present |
| plans/reference/review-contract.md:151 | `plans/reference/reviews/performance-review.md` | present |
| plans/reference/review-contract.md:152 | `plans/reference/reviews/save-review.md` | present |
| plans/reference/review-contract.md:153 | `plans/reference/reviews/ui-review.md` | present |
| plans/reference/review-contract.md:154 | `plans/reference/reviews/verification-review.md` | present |
| plans/reference/review-contract.md:155 | `plans/reference/reviews/context-review.md` | present |
| plans/reference/review-contract.md:156 | `plans/reference/reviews/agent-workflow-review.md` | present |
| plans/reference/review-contract.md:156 | `plans/reference/reviews/agent-workflow-codex.md` | present |
| plans/reference/review-contract.md:158 | `plans/reference/reviews/check-processor.md` | present |
| plans/reference/review-runner.md:4 | `plans/reference/review-contract.md` | present |
| plans/reference/review-runner.md:6 | `/run-reviews` | present |
| plans/reference/review-runner.md:10 | `KEY` | present |
| plans/reference/review-runner.md:11 | `plans/reference/reviews/` | present |
| plans/reference/review-runner.md:12 | `ROOT` | present |
| plans/reference/review-runner.md:12 | `WORKTREE` | present |
| plans/reference/review-runner.md:14 | `SINCE` | present |
| plans/reference/review-runner.md:14 | `first run` | present |
| plans/reference/review-runner.md:15 | `HANDOFFS` | present |
| plans/reference/review-runner.md:16 | `PHASE` | present |
| plans/reference/review-runner.md:16 | `review` | present |
| plans/reference/review-runner.md:16 | `decide` | present |
| plans/reference/review-runner.md:21 | `WORKTREE` | present |
| plans/reference/review-runner.md:21 | `git -C <WORKTREE> ...` | present |
| plans/reference/review-runner.md:22 | `(cd <WORKTREE> && ...)` | present |
| plans/reference/review-runner.md:23 | `ROOT` | present |
| plans/reference/review-runner.md:25 | `plans/reference/review-contract.md` | present |
| plans/reference/review-runner.md:26 | `WORKTREE` | present |
| plans/reference/review-runner.md:27 | `SINCE` | present |
| plans/reference/review-runner.md:29 | `HANDOFFS` | present |
| plans/reference/review-runner.md:40 | `python tools/check_docs.py` | present |
| plans/reference/review-runner.md:41 | `.\tools\verify.ps1` | present |
| plans/reference/review-runner.md:41 | `done` | present |
| plans/reference/review-runner.md:45 | `review` | present |
| plans/reference/review-runner.md:46 | `done` | present |
| plans/reference/review-runner.md:47 | `decisions` | present |
| plans/reference/review-runner.md:48 | `decide` | present |
| plans/reference/review-runner.md:50 | `Decided -- <file>` | present |
| plans/reference/review-runner.md:51 | `done` | present |
| plans/reference/review-runner.md:52 | `failed` | present |
| plans/reference/review-runner.md:52 | `tools/slice.ps1 owner` | present |
| plans/reference/review-runner.md:53 | `owned` | present |
| plans/reference/reviews/README.md:7 | `plans/reference/review-contract.md` | present |
| plans/reference/reviews/README.md:9 | `tools/check_docs.py` | present |
| plans/reference/reviews/README.md:14 | `tools/review_due.py` | present |
| plans/reference/reviews/README.md:16 | `Record key:` | present |
| plans/reference/reviews/README.md:16 | `docs/<record key>-<date>.md` | present |
| plans/reference/reviews/README.md:17 | `none` | present |
| plans/reference/reviews/README.md:18 | `Reasoning:` | present |
| plans/reference/reviews/README.md:18 | `medium` | present |
| plans/reference/reviews/README.md:18 | `high` | present |
| plans/reference/reviews/README.md:18 | `/run-reviews` | present |
| plans/reference/reviews/README.md:19 | `review-runner-<level>` | present |
| plans/reference/reviews/README.md:20 | `Watches:` | present |
| plans/reference/reviews/README.md:21 | `Watches:` | present |
| plans/reference/reviews/README.md:23 | `python tools/review_due.py` | present |
| plans/reference/reviews/README.md:28 | `/run-reviews [max] [keys]` | present |
| plans/reference/reviews/README.md:29 | `.claude/skills/run-reviews/SKILL.md` | present |
| plans/reference/reviews/README.md:32 | `plans/reference/review-runner.md` | present |
| plans/reference/reviews/README.md:36 | `check-processor.md` | moved to plans/reference/reviews/check-processor.md |
| plans/reference/reviews/README.md:37 | `product-review.md` | moved to plans/reference/reviews/product-review.md |
| plans/reference/reviews/README.md:38 | `plan-review.md` | moved to plans/reference/reviews/plan-review.md |
| plans/reference/reviews/README.md:39 | `architecture-review.md` | moved to plans/reference/reviews/architecture-review.md |
| plans/reference/reviews/README.md:40 | `data-catalogue-review.md` | moved to plans/reference/reviews/data-catalogue-review.md |
| plans/reference/reviews/README.md:41 | `gameplay-review.md` | moved to plans/reference/reviews/gameplay-review.md |
| plans/reference/reviews/README.md:42 | `performance-review.md` | moved to plans/reference/reviews/performance-review.md |
| plans/reference/reviews/README.md:43 | `save-review.md` | moved to plans/reference/reviews/save-review.md |
| plans/reference/reviews/README.md:44 | `ui-review.md` | moved to plans/reference/reviews/ui-review.md |
| plans/reference/reviews/README.md:45 | `verification-review.md` | moved to plans/reference/reviews/verification-review.md |
| plans/reference/reviews/README.md:46 | `context-review.md` | moved to plans/reference/reviews/context-review.md |
| plans/reference/reviews/README.md:47 | `agent-workflow-codex.md` | moved to plans/reference/reviews/agent-workflow-codex.md |
| plans/reference/reviews/README.md:48 | `agent-workflow-review.md` | moved to plans/reference/reviews/agent-workflow-review.md |
| plans/reference/reviews/agent-workflow-codex.md:4 | `agent-workflow-review` | present |
| plans/reference/reviews/agent-workflow-codex.md:8 | `agent-workflow-review.md` | moved to plans/reference/reviews/agent-workflow-review.md |
| plans/reference/reviews/agent-workflow-codex.md:12 | `Reviewed:` | present |
| plans/reference/reviews/agent-workflow-codex.md:13 | `python tools/review_due.py agent-workflow-review` | present |
| plans/reference/reviews/agent-workflow-codex.md:19 | `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` | present |
| plans/reference/reviews/agent-workflow-codex.md:20 | `and` | present |
| plans/reference/reviews/agent-workflow-codex.md:20 | `carry` | present |
| plans/reference/reviews/agent-workflow-codex.md:21 | `item.aggregated_output` | present |
| plans/reference/reviews/agent-workflow-codex.md:21 | `turn_context` | present |
| plans/reference/reviews/agent-workflow-codex.md:24 | `run-queue` | present |
| plans/reference/reviews/agent-workflow-codex.md:24 | `.agents/skills/run-queue/SKILL.md` | present |
| plans/reference/reviews/agent-workflow-codex.md:26 | `tools/heading.py` | present |
| plans/reference/reviews/agent-workflow-codex.md:27 | `tools/func.py` | present |
| plans/reference/reviews/agent-workflow-codex.md:27 | `prefinish` | present |
| plans/reference/reviews/agent-workflow-codex.md:34 | `tools/slice.ps1` | present |
| plans/reference/reviews/agent-workflow-codex.md:43 | `docs/agent-workflow-review-*.md` | present |
| plans/reference/reviews/agent-workflow-codex.md:44 | `plans/now/agent-lifecycle.md` | present |
| plans/reference/reviews/agent-workflow-codex.md:49 | `CODEX FINDINGS` | present |
| plans/reference/reviews/agent-workflow-review.md:9 | `tools/slice.ps1` | present |
| plans/reference/reviews/agent-workflow-review.md:9 | `tools/refill_lane.py` | present |
| plans/reference/reviews/agent-workflow-review.md:9 | `tools/prefinish.py` | present |
| plans/reference/reviews/agent-workflow-review.md:10 | `plans/workstreams.md` | present |
| plans/reference/reviews/agent-workflow-review.md:11 | `/run-queue` | present |
| plans/reference/reviews/agent-workflow-review.md:15 | `plans/observations/system-improvement-signals.md` | present |
| plans/reference/reviews/agent-workflow-review.md:20 | `CODEX FINDINGS` | present |
| plans/reference/reviews/agent-workflow-review.md:26 | `:` | present |
| plans/reference/reviews/agent-workflow-review.md:26 | `,` | present |
| plans/reference/reviews/agent-workflow-review.md:26 | `,` | present |
| plans/reference/reviews/agent-workflow-review.md:26 | `,` | present |
| plans/reference/reviews/agent-workflow-review.md:27 | `--events` | present |
| plans/reference/reviews/agent-workflow-review.md:27 | `--model-check` | present |
| plans/reference/reviews/agent-workflow-review.md:28 | `--coordinator` | present |
| plans/reference/reviews/agent-workflow-review.md:28 | `/run-queue` | present |
| plans/reference/reviews/agent-workflow-review.md:34 | `plans/reference/system-improvement-signals.md` | present |
| plans/reference/reviews/agent-workflow-review.md:49 | `plans/now/agent-lifecycle.md` | present |
| plans/reference/reviews/agent-workflow-review.md:50 | `plans/now/` | present |
| plans/reference/reviews/architecture-review.md:21 | `ROADMAP.md` | present |
| plans/reference/reviews/architecture-review.md:21 | `git show HEAD:ROADMAP.md` | present |
| plans/reference/reviews/architecture-review.md:22 | `plans/design/` | present |
| plans/reference/reviews/architecture-review.md:22 | `plans/now/` | present |
| plans/reference/reviews/architecture-review.md:32 | `scripts/actions.gd` | present |
| plans/reference/reviews/architecture-review.md:32 | `scripts/availability.gd` | present |
| plans/reference/reviews/architecture-review.md:33 | `scripts/roles.gd` | present |
| plans/reference/reviews/architecture-review.md:42 | `GameConfig` | present |
| plans/reference/reviews/check-processor.md:11 | `checks/ready.md` | present |
| plans/reference/reviews/check-processor.md:13 | `checks/blocked.md` | present |
| plans/reference/reviews/check-processor.md:14 | `checks/ready/` | present |
| plans/reference/reviews/check-processor.md:15 | `python tools/check_docs.py` | present |
| plans/reference/reviews/check-processor.md:16 | `Blocked by:` | present |
| plans/reference/reviews/check-processor.md:16 | `plans/archive/<id>_*.md` | present |
| plans/reference/reviews/check-processor.md:19 | `plans/reference/check-loop.md` | present |
| plans/reference/reviews/check-processor.md:20 | `plans/reference/closeout.md` | present |
| plans/reference/reviews/check-processor.md:21 | `checks/ready.md` | present |
| plans/reference/reviews/check-processor.md:22 | `checks/ready/` | present |
| plans/reference/reviews/check-processor.md:22 | `Owner:` | present |
| plans/reference/reviews/check-processor.md:27 | `plans/reference/check-runner.md` | present |
| plans/reference/reviews/check-processor.md:28 | `Runner:` | present |
| plans/reference/reviews/check-processor.md:29 | `ROOT=C:\Users\dl13860\Documents\Meadow\meadow` | present |
| plans/reference/reviews/check-processor.md:31 | `/run-queue` | present |
| plans/reference/reviews/check-processor.md:31 | `verify.ps1` | moved to tools/verify.ps1 |
| plans/reference/reviews/check-processor.md:32 | `Runner: dave` | present |
| plans/reference/reviews/check-processor.md:33 | `needs_dave` | present |
| plans/reference/reviews/check-processor.md:44 | `checks/ready.md` | present |
| plans/reference/reviews/check-processor.md:46 | `queue-gated` | present |
| plans/reference/reviews/check-processor.md:46 | `NEXTSTEPS.md` | present |
| plans/reference/reviews/check-processor.md:47 | `queue` | present |
| plans/reference/reviews/check-processor.md:47 | `Proof:` | present |
| plans/reference/reviews/check-processor.md:53 | `plans/now/` | present |
| plans/reference/reviews/check-processor.md:53 | `plans/README.md` | present |
| plans/reference/reviews/check-processor.md:54 | `cannot-run` | present |
| plans/reference/reviews/check-processor.md:55 | `checks/blocked.md` | present |
| plans/reference/reviews/check-processor.md:59 | `file::function` | present |
| plans/reference/reviews/check-processor.md:71 | `cannot-run` | present |
| plans/reference/reviews/check-processor.md:72 | `Runner:` | present |
| plans/reference/reviews/check-processor.md:80 | `Runner:` | present |
| plans/reference/reviews/context-review.md:9 | `CLAUDE.md` | present |
| plans/reference/reviews/context-review.md:9 | `AGENTS.md` | present |
| plans/reference/reviews/context-review.md:9 | `CHATGPT.md` | present |
| plans/reference/reviews/context-review.md:9 | `docs/agent-rules.md` | present |
| plans/reference/reviews/context-review.md:10 | `.claude/rules/` | present |
| plans/reference/reviews/context-review.md:10 | `.claude/settings.json` | present |
| plans/reference/reviews/context-review.md:11 | `.claude/agents/` | present |
| plans/reference/reviews/context-review.md:12 | `.claude/skills/` | present |
| plans/reference/reviews/context-review.md:12 | `.agents/skills/` | present |
| plans/reference/reviews/context-review.md:12 | `.codex/` | present |
| plans/reference/reviews/context-review.md:13 | `plans/reference/reviews/` | present |
| plans/reference/reviews/context-review.md:14 | `docs/` | present |
| plans/reference/reviews/context-review.md:14 | `FUNCTION_MAP.md` | present |
| plans/reference/reviews/context-review.md:14 | `GAME_MODEL.md` | present |
| plans/reference/reviews/context-review.md:14 | `README.md` | present |
| plans/reference/reviews/context-review.md:15 | `~/.claude/projects/` | present |
| plans/reference/reviews/context-review.md:26 | `wc` | present |
| plans/reference/reviews/context-review.md:27 | `CLAUDE.md` | present |
| plans/reference/reviews/context-review.md:27 | `docs/agent-rules.md` | present |
| plans/reference/reviews/context-review.md:28 | `AGENTS.md` | present |
| plans/reference/reviews/context-review.md:28 | `CHATGPT.md` | present |
| plans/reference/reviews/context-review.md:29 | `.claude/agents/*.md` | present |
| plans/reference/reviews/context-review.md:37 | `docs/agent-rules.md` | present |
| plans/reference/reviews/context-review.md:39 | `check_docs.py` | moved to tools/check_docs.py |
| plans/reference/reviews/context-review.md:43 | `docs/known-pitfalls.md` | present |
| plans/reference/reviews/context-review.md:44 | `plans/observations/system-improvement-signals.md` | present |
| plans/reference/reviews/context-review.md:47 | `CLAUDE.md` | present |
| plans/reference/reviews/context-review.md:48 | `plans/README.md` | present |
| plans/reference/reviews/context-review.md:49 | `FUNCTION_MAP.md` | present |
| plans/reference/reviews/context-review.md:52 | `.claude/settings.json` | present |
| plans/reference/reviews/context-review.md:53 | `.codex/rules/meadow.rules` | present |
| plans/reference/reviews/data-catalogue-review.md:7 | `Watches:` | present |
| plans/reference/reviews/data-catalogue-review.md:8 | `/run-reviews` | present |
| plans/reference/reviews/data-catalogue-review.md:17 | `plans/now/` | present |
| plans/reference/reviews/data-catalogue-review.md:18 | `Proof:` | present |
| plans/reference/reviews/data-catalogue-review.md:21 | `plans/README.md` | present |
| plans/reference/reviews/data-catalogue-review.md:22 | `scripts/game_config.gd` | present |
| plans/reference/reviews/data-catalogue-review.md:23 | `scripts/settings_catalogue.gd` | present |
| plans/reference/reviews/data-catalogue-review.md:24 | `scripts/roles.gd` | present |
| plans/reference/reviews/data-catalogue-review.md:25 | `docs/agent-rules.md` | present |
| plans/reference/reviews/data-catalogue-review.md:27 | `tools/stage_reference.py` | present |
| plans/reference/reviews/data-catalogue-review.md:28 | `scripts/challenge_stages.gd` | present |
| plans/reference/reviews/data-catalogue-review.md:29 | `tools/update_function_map.py` | present |
| plans/reference/reviews/data-catalogue-review.md:42 | `const` | present |
| plans/reference/reviews/data-catalogue-review.md:53 | `.tres` | present |
| plans/reference/reviews/data-catalogue-review.md:75 | `const` | present |
| plans/reference/reviews/data-catalogue-review.md:93 | `const` | present |
| plans/reference/reviews/data-catalogue-review.md:130 | `.tres` | present |
| plans/reference/reviews/data-catalogue-review.md:142 | `.tres` | present |
| plans/reference/reviews/data-catalogue-review.md:145 | `@export` | present |
| plans/reference/reviews/data-catalogue-review.md:145 | `@export_range` | present |
| plans/reference/reviews/data-catalogue-review.md:197 | `0` | present |
| plans/reference/reviews/data-catalogue-review.md:197 | `1` | present |
| plans/reference/reviews/data-catalogue-review.md:197 | `-1` | present |
| plans/reference/reviews/data-catalogue-review.md:215 | `const` | present |
| plans/reference/reviews/data-catalogue-review.md:265 | `@export` | present |
| plans/reference/reviews/data-catalogue-review.md:266 | `@export_range` | present |
| plans/reference/reviews/data-catalogue-review.md:307 | `.tres` | present |
| plans/reference/reviews/data-catalogue-review.md:312 | `.tres` | present |
| plans/reference/reviews/data-catalogue-review.md:314 | `@export` | present |
| plans/reference/reviews/data-catalogue-review.md:327 | `ConfigFile` | present |
| plans/reference/reviews/data-catalogue-review.md:358 | `.tres` | present |
| plans/reference/reviews/data-catalogue-review.md:361 | `.tres` | present |
| plans/reference/reviews/data-catalogue-review.md:412 | `.tres` | present |
| plans/reference/reviews/data-catalogue-review.md:561 | `const` | present |
| plans/reference/reviews/data-catalogue-review.md:561 | `.tres` | present |
| plans/reference/reviews/data-catalogue-review.md:561 | `enum` | present |
| plans/reference/reviews/data-catalogue-review.md:561 | `@export` | present |
| plans/reference/reviews/gameplay-review.md:13 | `docs/agent-rules.md` | present |
| plans/reference/reviews/gameplay-review.md:14 | `.claude/rules/simulation.md` | present |
| plans/reference/reviews/gameplay-review.md:14 | `GAME_MODEL.md` | present |
| plans/reference/reviews/gameplay-review.md:23 | `docs/known-pitfalls.md` | present |
| plans/reference/reviews/gameplay-review.md:24 | `checks/ready.md` | present |
| plans/reference/reviews/gameplay-review.md:24 | `checks/blocked.md` | present |
| plans/reference/reviews/gameplay-review.md:25 | `git log --stat --format=%s <SINCE>..HEAD -- scripts/` | present |
| plans/reference/reviews/gameplay-review.md:27 | `plans/archive/` | present |
| plans/reference/reviews/gameplay-review.md:37 | `file::function` | present |
| plans/reference/reviews/gameplay-review.md:46 | `docs/known-pitfalls.md` | present |
| plans/reference/reviews/gameplay-review.md:47 | `plans/reference/check-loop.md` | present |
| plans/reference/reviews/performance-review.md:9 | `_process` | present |
| plans/reference/reviews/performance-review.md:9 | `_physics_process` | present |
| plans/reference/reviews/performance-review.md:18 | `.claude/rules/performance.md` | present |
| plans/reference/reviews/performance-review.md:18 | `docs/performance.md` | present |
| plans/reference/reviews/performance-review.md:19 | `docs/PERFORMANCE_BASELINE.md` | present |
| plans/reference/reviews/performance-review.md:20 | `plans/reference/technical-audit.md` | present |
| plans/reference/reviews/performance-review.md:24 | `plans/archive/hot-path-queries_2026-09-29.md` | present |
| plans/reference/reviews/performance-review.md:25 | `plans/archive/render-scale_2026-10-07.md` | present |
| plans/reference/reviews/performance-review.md:25 | `git show` | present |
| plans/reference/reviews/performance-review.md:30 | `scripts/perf.gd` | present |
| plans/reference/reviews/performance-review.md:31 | `scripts/perf_breakdown.gd` | present |
| plans/reference/reviews/performance-review.md:32 | `docs/performance.md` | present |
| plans/reference/reviews/performance-review.md:36 | `_process` | present |
| plans/reference/reviews/performance-review.md:36 | `_physics_process` | present |
| plans/reference/reviews/performance-review.md:37 | `Timer` | present |
| plans/reference/reviews/performance-review.md:37 | `get_nodes_in_group` | present |
| plans/reference/reviews/performance-review.md:37 | `get_children()` | present |
| plans/reference/reviews/performance-review.md:43 | `ROADMAP.md` | present |
| plans/reference/reviews/performance-review.md:50 | `python tools/equivalence.py <scenario> <ref>` | present |
| plans/reference/reviews/performance-review.md:52 | `plans/now/` | present |
| plans/reference/reviews/plan-review.md:8 | `plans/now/` | present |
| plans/reference/reviews/plan-review.md:8 | `plans/design/` | present |
| plans/reference/reviews/plan-review.md:9 | `plans/reference/` | present |
| plans/reference/reviews/plan-review.md:9 | `plans/README.md` | present |
| plans/reference/reviews/plan-review.md:10 | `NEXTSTEPS.md` | present |
| plans/reference/reviews/plan-review.md:10 | `queue` | present |
| plans/reference/reviews/plan-review.md:10 | `queue-gated` | present |
| plans/reference/reviews/plan-review.md:10 | `Owner:` | present |
| plans/reference/reviews/plan-review.md:11 | `checks/ready/` | present |
| plans/reference/reviews/plan-review.md:11 | `checks/blocked.md` | present |
| plans/reference/reviews/plan-review.md:15 | `/plan-ahead` | present |
| plans/reference/reviews/plan-review.md:16 | `docs/` | present |
| plans/reference/reviews/plan-review.md:21 | `plans/README.md` | present |
| plans/reference/reviews/plan-review.md:22 | `.claude/rules/documentation.md` | present |
| plans/reference/reviews/plan-review.md:22 | `tools/check_docs.py` | present |
| plans/reference/reviews/plan-review.md:23 | `check_docs.py` | moved to tools/check_docs.py |
| plans/reference/reviews/plan-review.md:24 | `python tools/refill_lane.py --top-up --dry-run` | present |
| plans/reference/reviews/plan-review.md:31 | `Proof:` | present |
| plans/reference/reviews/plan-review.md:34 | `plans/README.md` | present |
| plans/reference/reviews/plan-review.md:35 | `queue-gated` | present |
| plans/reference/reviews/plan-review.md:41 | `Files:` | present |
| plans/reference/reviews/plan-review.md:44 | `queue` | present |
| plans/reference/reviews/plan-review.md:47 | `/run-queue` | present |
| plans/reference/reviews/plan-review.md:47 | `slice-worker-<level>` | present |
| plans/reference/reviews/plan-review.md:50 | `docs/agent-rules.md` | present |
| plans/reference/reviews/plan-review.md:55 | `Next after:` | present |
| plans/reference/reviews/plan-review.md:63 | `plans/README.md` | present |
| plans/reference/reviews/product-review.md:8 | `ROADMAP.md` | present |
| plans/reference/reviews/product-review.md:9 | `DESIGN_BACKLOG.md` | present |
| plans/reference/reviews/product-review.md:10 | `plans/design/` | present |
| plans/reference/reviews/product-review.md:10 | `docs/challenge-stages.md` | present |
| plans/reference/reviews/product-review.md:11 | `tools/pacing_gates.py` | present |
| plans/reference/reviews/product-review.md:11 | `scripts/game_config.gd` | present |
| plans/reference/reviews/product-review.md:12 | `scripts/settings_catalogue.gd` | present |
| plans/reference/reviews/product-review.md:17 | `/plan-ahead` | present |
| plans/reference/reviews/product-review.md:20 | `ROADMAP.md` | present |
| plans/reference/reviews/product-review.md:20 | `DESIGN_BACKLOG.md` | present |
| plans/reference/reviews/product-review.md:21 | `git show HEAD:<file>` | present |
| plans/reference/reviews/product-review.md:21 | `grep` | present |
| plans/reference/reviews/product-review.md:22 | `sed` | present |
| plans/reference/reviews/product-review.md:32 | `DESIGN_BACKLOG.md` | present |
| plans/reference/reviews/product-review.md:36 | `docs/challenge-stages.md` | present |
| plans/reference/reviews/product-review.md:41 | `plans/reference/check-runner.md` | present |
| plans/reference/reviews/product-review.md:43 | `python tools/pacing_gates.py` | present |
| plans/reference/reviews/product-review.md:45 | `docs/agent-rules.md` | present |
| plans/reference/reviews/product-review.md:47 | `,` | present |
| plans/reference/reviews/save-review.md:8 | `scripts/save_game.gd` | present |
| plans/reference/reviews/save-review.md:8 | `scripts/saving.gd` | present |
| plans/reference/reviews/save-review.md:9 | `scripts/save_migrations.gd` | present |
| plans/reference/reviews/save-review.md:9 | `scripts/save_slots.gd` | present |
| plans/reference/reviews/save-review.md:10 | `scripts/tutorial_checkpoint.gd` | present |
| plans/reference/reviews/save-review.md:12 | `tests/test_save_migrations.py` | present |
| plans/reference/reviews/save-review.md:17 | `.claude/rules/saving.md` | present |
| plans/reference/reviews/save-review.md:27 | `, new` | present |
| plans/reference/reviews/save-review.md:38 | `FORMAT_VERSION` | present |
| plans/reference/reviews/ui-review.md:20 | `plans/reference/ui-rules.md` | present |
| plans/reference/reviews/ui-review.md:20 | `scripts/ui_layout.gd` | present |
| plans/reference/reviews/ui-review.md:21 | `scripts/ui_theme.gd` | present |
| plans/reference/reviews/ui-review.md:21 | `plans/reference/check-loop.md` | present |
| plans/reference/reviews/ui-review.md:23 | `ROADMAP.md` | present |
| plans/reference/reviews/ui-review.md:36 | `GAME_MODEL.md` | present |
| plans/reference/reviews/ui-review.md:37 | `scripts/ui_layout.gd` | present |
| plans/reference/reviews/ui-review.md:38 | `scripts/scenario_actions.gd` | present |
| plans/reference/reviews/ui-review.md:42 | `plans/reference/check-runner.md` | present |
| plans/reference/reviews/ui-review.md:43 | `dave` | present |
| plans/reference/reviews/verification-review.md:8 | `tools/verify.ps1` | present |
| plans/reference/reviews/verification-review.md:9 | `tools/run_tests.py` | present |
| plans/reference/reviews/verification-review.md:10 | `tools/prefinish.py` | present |
| plans/reference/reviews/verification-review.md:10 | `tests/` | present |
| plans/reference/reviews/verification-review.md:11 | `test_scenarios/` | present |
| plans/reference/reviews/verification-review.md:11 | `tests/source_checks.py` | present |
| plans/reference/reviews/verification-review.md:12 | `tools/check_docs.py` | present |
| plans/reference/reviews/verification-review.md:12 | `tools/pacing_gates.py` | present |
| plans/reference/reviews/verification-review.md:12 | `tools/equivalence.py` | present |
| plans/reference/reviews/verification-review.md:14 | `Runner:` | present |
| plans/reference/reviews/verification-review.md:15 | `tools/build_alpha.ps1` | present |
| plans/reference/reviews/verification-review.md:15 | `export_presets.cfg` | present |
| plans/reference/reviews/verification-review.md:15 | `tests/test_alpha_build.py` | present |
| plans/reference/reviews/verification-review.md:21 | `docs/headless-run-contract.md` | present |
| plans/reference/reviews/verification-review.md:25 | `.\tools\verify.ps1` | present |
| plans/reference/reviews/verification-review.md:30 | `.claude/rules/*.md` | present |
| plans/reference/reviews/verification-review.md:31 | `docs/agent-rules.md` | present |
| plans/reference/reviews/verification-review.md:31 | `docs/known-pitfalls.md` | present |
| plans/reference/reviews/verification-review.md:43 | `checks/ready.md` | present |
| plans/reference/reviews/verification-review.md:45 | `Runner:` | present |
| plans/reference/reviews/verification-review.md:46 | `dave` | present |
| plans/reference/slice-worker.md:6 | `slice-worker-*` | present |
| plans/reference/slice-worker.md:7 | `/run-queue` | present |
| plans/reference/slice-worker.md:7 | `run-queue` | present |
| plans/reference/slice-worker.md:8 | `.agents/skills/` | present |
| plans/reference/slice-worker.md:9 | `tools/slice.ps1 start` | present |
| plans/reference/slice-worker.md:16 | `start` | present |
| plans/reference/slice-worker.md:16 | `id` | present |
| plans/reference/slice-worker.md:16 | `plan` | present |
| plans/reference/slice-worker.md:16 | `heading` | present |
| plans/reference/slice-worker.md:16 | `read` | present |
| plans/reference/slice-worker.md:16 | `files` | present |
| plans/reference/slice-worker.md:16 | `check` | present |
| plans/reference/slice-worker.md:17 | `proof` | present |
| plans/reference/slice-worker.md:17 | `next_after` | present |
| plans/reference/slice-worker.md:17 | `advice` | present |
| plans/reference/slice-worker.md:17 | `branch` | present |
| plans/reference/slice-worker.md:17 | `worktree` | present |
| plans/reference/slice-worker.md:18 | `ROOT` | present |
| plans/reference/slice-worker.md:19 | `ROOT/<worktree>` | present |
| plans/reference/slice-worker.md:21 | `.worktrees/<id>` | present |
| plans/reference/slice-worker.md:25 | `git -C <wt> show HEAD:<path> | sed -n '<a>,<b>p'` | present |
| plans/reference/slice-worker.md:26 | `grep -rn` | present |
| plans/reference/slice-worker.md:27 | `python tools/heading.py` | present |
| plans/reference/slice-worker.md:27 | `python tools/func.py` | present |
| plans/reference/slice-worker.md:28 | `(cd <wt> && python tools/func.py ...)` | present |
| plans/reference/slice-worker.md:29 | `* text=auto` | present |
| plans/reference/slice-worker.md:30 | `core.autocrlf` | present |
| plans/reference/slice-worker.md:30 | `newline=""` | present |
| plans/reference/slice-worker.md:30 | `\r\n` | present |
| plans/reference/slice-worker.md:31 | `\n` | present |
| plans/reference/slice-worker.md:32 | `sed -i` | present |
| plans/reference/slice-worker.md:34 | `python <that path>` | gone |
| plans/reference/slice-worker.md:34 | `cp` | present |
| plans/reference/slice-worker.md:38 | `(cd <wt> && ...)` | present |
| plans/reference/slice-worker.md:40 | `finish` | present |
| plans/reference/slice-worker.md:43 | `apply_patch` | present |
| plans/reference/slice-worker.md:45 | `cd` | present |
| plans/reference/slice-worker.md:46 | `\r` | present |
| plans/reference/slice-worker.md:50 | `read` | present |
| plans/reference/slice-worker.md:51 | `NEXTSTEPS.md` | present |
| plans/reference/slice-worker.md:51 | `ROADMAP.md` | present |
| plans/reference/slice-worker.md:52 | `DESIGN_BACKLOG.md` | present |
| plans/reference/slice-worker.md:52 | `plans/archive/` | present |
| plans/reference/slice-worker.md:53 | `FUNCTION_MAP.md` | present |
| plans/reference/slice-worker.md:54 | `.claude/rules/` | present |
| plans/reference/slice-worker.md:55 | `simulation.md` | moved to .claude/rules/simulation.md |
| plans/reference/slice-worker.md:55 | `saving.md` | moved to .claude/rules/saving.md |
| plans/reference/slice-worker.md:55 | `performance.md` | moved to .claude/rules/performance.md |
| plans/reference/slice-worker.md:56 | `files` | present |
| plans/reference/slice-worker.md:58 | `blocked` | present |
| plans/reference/slice-worker.md:61 | `check_run` | present |
| plans/reference/slice-worker.md:64 | `@warning_ignore` | present |
| plans/reference/slice-worker.md:66 | `tests/test_*.py` | present |
| plans/reference/slice-worker.md:66 | `tools/verify.ps1` | present |
| plans/reference/slice-worker.md:68 | `$testsNotInVerify` | present |
| plans/reference/slice-worker.md:69 | `check` | present |
| plans/reference/slice-worker.md:70 | `python tests/source_checks.py` | present |
| plans/reference/slice-worker.md:71 | `verify.ps1` | moved to tools/verify.ps1 |
| plans/reference/slice-worker.md:71 | `finish` | present |
| plans/reference/slice-worker.md:73 | `python tools/gdscript_warnings.py <the files>` | present |
| plans/reference/slice-worker.md:74 | `godot_compile_check.py` | moved to tools/godot_compile_check.py |
| plans/reference/slice-worker.md:75 | `source_checks.py` | moved to tests/source_checks.py |
| plans/reference/slice-worker.md:75 | `finish` | present |
| plans/reference/slice-worker.md:76 | `.gd` | present |
| plans/reference/slice-worker.md:76 | `.uid` | present |
| plans/reference/slice-worker.md:77 | `godot --headless --import` | present |
| plans/reference/slice-worker.md:78 | `.uid` | present |
| plans/reference/slice-worker.md:78 | `.import` | present |
| plans/reference/slice-worker.md:82 | `check` | present |
| plans/reference/slice-worker.md:85 | `files` | present |
| plans/reference/slice-worker.md:86 | `blocked` | present |
| plans/reference/slice-worker.md:87 | `ready` | present |
| plans/reference/slice-worker.md:88 | `plans/reference/closeout.md` | present |
| plans/reference/slice-worker.md:89 | `Next:` | present |
| plans/reference/slice-worker.md:90 | `next_after` | present |
| plans/reference/slice-worker.md:90 | `queue` | present |
| plans/reference/slice-worker.md:91 | `queue-gated` | present |
| plans/reference/slice-worker.md:91 | `Proof:` | present |
| plans/reference/slice-worker.md:93 | `git show master:<file> | grep -F '<text>'` | present |
| plans/reference/slice-worker.md:93 | `present:` | present |
| plans/reference/slice-worker.md:94 | `absent:` | present |
| plans/reference/slice-worker.md:94 | `finish` | present |
| plans/reference/slice-worker.md:97 | `plans/reference/check-runner.md` | present |
| plans/reference/slice-worker.md:99 | `check` | present |
| plans/reference/slice-worker.md:105 | `blocked` | present |
| plans/reference/slice-worker.md:111 | `files` | present |
| plans/reference/slice-worker.md:131 | `ready` | present |
| plans/reference/slice-worker.md:132 | `finish` | present |
| plans/reference/system-improvement-signals.md:5 | `plans/observations/system-improvement-signals.md` | present |
| plans/reference/system-improvement-signals.md:10 | `plans/observations/system-improvement-signals.md` | present |
| plans/reference/system-improvement-signals.md:13 | `meadow-diagnostics.jsonl` | present |
| plans/reference/system-improvement-signals.md:22 | `plans/reference/` | present |
| plans/reference/system-improvement-signals.md:22 | `plans/design/` | present |
| plans/reference/system-improvement-signals.md:22 | `plans/now/` | present |
| plans/reference/technical-audit.md:8 | `plans/archive/AUDIT_PLAN_AUG_2026.md` | present |
| plans/reference/technical-audit.md:14 | `docs/performance.md` | present |
| plans/reference/technical-audit.md:14 | `docs/PERFORMANCE_BASELINE.md` | present |
| plans/reference/technical-audit.md:16 | `.claude/rules/saving.md` | present |
| plans/reference/technical-audit.md:17 | `GameConfig` | present |
| plans/reference/technical-audit.md:20 | `docs/PERFORMANCE_BASELINE.md` | present |
| plans/reference/technical-audit.md:30 | `GameConfig` | present |
| plans/reference/technical-audit.md:31 | `prerequisites.gd` | moved to scripts/prerequisites.gd |
| plans/reference/technical-audit.md:31 | `stage_gate.gd` | moved to scripts/stage_gate.gd |
| plans/reference/technical-audit.md:32 | `roles.gd` | moved to scripts/roles.gd |
| plans/reference/technical-audit.md:33 | `bee_enums.gd` | moved to scripts/bee_enums.gd |
| plans/reference/technical-audit.md:42 | `plans/archive/architecture-review_2026-09-24.md` | present |
| plans/reference/technical-audit.md:51 | `DESIGN_BACKLOG.md` | present |
| plans/reference/technical-audit.md:53 | `avg_collection_rate` | present |
| plans/reference/technical-audit.md:53 | `grace_rate_sum` | present |
| plans/reference/technical-audit.md:53 | `trips_scored` | present |
| plans/reference/technical-audit.md:53 | `bee.gd` | moved to scripts/bee.gd |
| plans/reference/technical-audit.md:54 | `save_game.gd::_bees_data` | present |
| plans/reference/technical-audit.md:54 | `saving.gd` | moved to scripts/saving.gd |
| plans/reference/technical-audit.md:60 | `FORMAT_VERSION` | present |
| plans/reference/technical-audit.md:61 | `known_patches` | present |
| plans/reference/technical-audit.md:61 | `species_experience` | present |
| plans/reference/technical-audit.md:61 | `species_confidence` | present |
| plans/reference/technical-audit.md:62 | `.get()` | present |
| plans/reference/technical-audit.md:62 | `saving.gd` | moved to scripts/saving.gd |
| plans/reference/technical-audit.md:62 | `save_migrations.gd` | moved to scripts/save_migrations.gd |
| plans/reference/technical-audit.md:63 | `0.0` | present |
| plans/reference/technical-audit.md:63 | `0.0` | present |
| plans/reference/technical-audit.md:63 | `0` | present |
| plans/reference/technical-audit.md:65 | `save_migrations.gd` | moved to scripts/save_migrations.gd |
| plans/reference/technical-audit.md:68 | `is_scouting` | present |
| plans/reference/technical-audit.md:68 | `scout_bout` | present |
| plans/reference/technical-audit.md:68 | `scout_species` | present |
| plans/reference/technical-audit.md:69 | `scout_tried_species` | present |
| plans/reference/technical-audit.md:69 | `scout_best_species` | present |
| plans/reference/technical-audit.md:69 | `scout_best_rate` | present |
| plans/reference/technical-audit.md:70 | `scout_current_start_point` | present |
| plans/reference/technical-audit.md:70 | `scout_best_start_point` | present |
| plans/reference/technical-audit.md:72 | `search_angle` | present |
| plans/reference/technical-audit.md:73 | `move_target` | present |
| plans/reference/technical-audit.md:74 | `settled_rate_logged` | present |
| plans/reference/technical-audit.md:83 | `plans/archive/architecture-review_2026-09-24.md` | present |
| plans/reference/technical-audit.md:90 | `hive.gd` | moved to scripts/hive.gd |
| plans/reference/technical-audit.md:90 | `find_*` | present |
| plans/reference/technical-audit.md:92 | `find_food_cell` | present |
| plans/reference/technical-audit.md:94 | `ripe_honey` | present |
| plans/reference/technical-audit.md:94 | `nectar` | present |
| plans/reference/technical-audit.md:95 | `docs/PERFORMANCE_BASELINE.md` | present |
| plans/reference/technical-audit.md:101 | `find_food_cell` | present |
| plans/reference/technical-audit.md:102 | `honey_ripen_time` | present |
| plans/reference/technical-audit.md:103 | `ripe_honey` | present |
| plans/reference/technical-audit.md:107 | `total()` | present |
| plans/reference/technical-audit.md:108 | `find_*` | present |
| plans/reference/technical-audit.md:117 | `_content_index()` | present |
| plans/reference/technical-audit.md:118 | `"" / nectar / pollen / honey / jelly / brood / corpse / unbuilt / ripe_honey` | present |
| plans/reference/technical-audit.md:119 | `find_cell_with` | present |
| plans/reference/technical-audit.md:119 | `find_brood_cell` | present |
| plans/reference/technical-audit.md:119 | `find_cell_needing_cleaning` | present |
| plans/reference/technical-audit.md:120 | `has_gyne_brood` | present |
| plans/reference/technical-audit.md:124 | `find_food_cell` | present |
| plans/reference/technical-audit.md:124 | `cells` | present |
| plans/reference/technical-audit.md:124 | `ripe_honey` | present |
| plans/reference/technical-audit.md:124 | `nectar` | present |
| plans/reference/technical-audit.md:125 | `find_unfinished_cell` | present |
| plans/reference/technical-audit.md:125 | `unbuilt` | present |
| plans/reference/technical-audit.md:126 | `find_cell_needing_fanning` | present |
| plans/reference/technical-audit.md:126 | `is_instance_valid` | present |
| plans/reference/technical-audit.md:126 | `honey` | present |
| plans/reference/technical-audit.md:126 | `needs_fanning()` | present |
| plans/reference/technical-audit.md:127 | `find_cell_for` | present |
| plans/reference/technical-audit.md:127 | `""` | present |
| plans/reference/technical-audit.md:127 | `resource_type` | present |
| plans/reference/technical-audit.md:128 | `find_cell_needing_eviction` | present |
| plans/reference/technical-audit.md:129 | `find_empty_cell` | present |
| plans/reference/technical-audit.md:131 | `find_food_cell` | present |
| plans/reference/technical-audit.md:131 | `BeeSurvival.should_go_and_eat` | present |
| plans/reference/technical-audit.md:136 | `space_for()` | present |
| plans/reference/technical-audit.md:138 | `cells` | present |
| plans/reference/technical-audit.md:139 | `find_cell_for` | present |
| plans/reference/technical-audit.md:139 | `find_empty_cell` | present |
| plans/reference/technical-audit.md:140 | `best_empty` | present |
| plans/reference/technical-audit.md:140 | `almost_full` | present |
| plans/reference/technical-audit.md:144 | `hive_index_rebuild` | present |
| plans/reference/technical-audit.md:145 | `bee_state_nurse` | present |
| plans/reference/technical-audit.md:145 | `bee_state_forager` | present |
| plans/reference/technical-audit.md:148 | `plans/archive/PERF-1_2026-09-20.md` | present |
| plans/reference/technical-audit.md:152 | `plans/archive/architecture-review_2026-09-24.md` | present |
| plans/reference/technical-audit.md:153 | `ColonyDiagnostics.compute` | present |
| plans/reference/technical-audit.md:156 | `signals` | present |
| plans/reference/technical-audit.md:157 | `year_winter.gd` | moved to scripts/year_winter.gd |
| plans/reference/technical-audit.md:160 | `year_winter.gd::_refresh_signals` | present |
| plans/reference/technical-audit.md:161 | `get_nodes_in_group("bees")` | present |
| plans/reference/technical-audit.md:161 | `_winter_forecast` | present |
| plans/reference/technical-audit.md:162 | `_refresh_panels` | present |
| plans/reference/technical-audit.md:162 | `_refresh_winter` | present |
| plans/reference/technical-audit.md:162 | `season.gd` | moved to scripts/season.gd |
| plans/reference/technical-audit.md:163 | `cells_holding("")` | present |
| plans/reference/technical-audit.md:164 | `_refresh_signals` | present |
| plans/reference/technical-audit.md:164 | `free_cells` | present |
| plans/reference/technical-audit.md:164 | `_refresh_panels` | present |
| plans/reference/technical-audit.md:165 | `free_cells` | present |
| plans/reference/technical-audit.md:165 | `cells_holding("brood")` | present |
| plans/reference/technical-audit.md:166 | `hungry_brood` | present |
| plans/reference/technical-audit.md:168 | `bees` | present |
| plans/reference/technical-audit.md:169 | `_winter_forecast` | present |
| plans/reference/technical-audit.md:170 | `free_cells` | present |
| plans/reference/technical-audit.md:170 | `hungry_brood` | present |
| plans/reference/technical-audit.md:170 | `_refresh_signals` | present |
| plans/reference/technical-audit.md:171 | `_refresh_panels` | present |
| plans/reference/technical-audit.md:171 | `signals` | present |
| plans/reference/technical-audit.md:175 | `main._role_counts()` | present |
| plans/reference/technical-audit.md:176 | `hive.gd` | moved to scripts/hive.gd |
| plans/reference/technical-audit.md:177 | `invalidate_index()` | present |
| plans/reference/technical-audit.md:183 | `bee.gd` | moved to scripts/bee.gd |
| plans/reference/technical-audit.md:184 | `get_nodes_in_group("bees")` | present |
| plans/reference/technical-audit.md:185 | `fog_of_war._update` | present |
| plans/reference/technical-audit.md:187 | `bee_*.gd` | present |
| plans/reference/ui-rules.md:7 | `plans/archive/ui_2026-09-20.md` | present |
| plans/reference/ui-rules.md:7 | `Read` | present |
| plans/reference/ui-rules.md:8 | `CLAUDE.md` | present |
| plans/reference/ui-rules.md:9 | `.claude/rules/ui.md` | present |
| plans/reference/ui-rules.md:14 | `UiTheme` | present |
| plans/reference/ui-rules.md:16 | `ui_layout.gd` | moved to scripts/ui_layout.gd |
| plans/reference/ui-rules.md:21 | `ScrollContainer` | present |
| plans/reference/ui-rules.md:23 | `More…` | present |
| plans/reference/ui-rules.md:23 | `Control.size` | present |
| plans/reference/ui-rules.md:27 | `custom_minimum_size` | present |
| plans/reference/ui-rules.md:29 | `ScrollContainer` | present |
| plans/reference/ui-rules.md:33 | `ScrollContainer` | present |
| plans/reference/ui-rules.md:34 | `ScrollContainer` | present |
| plans/reference/ui-rules.md:35 | `_resize_command_tray` | present |
| plans/reference/ui-rules.md:37 | `UiTheme.panel_stylebox()` | present |
| plans/reference/ui-rules.md:43 | `plans/archive/LAY-1_2026-09-08.md` | present |
| plans/reference/ui-rules.md:44 | `ui_layout.gd` | moved to scripts/ui_layout.gd |
| plans/reference/ui-rules.md:45 | `ui_panel_layout.gd::apply()` | present |
| plans/reference/ui-rules.md:48 | `size` | present |
| plans/reference/ui-rules.md:48 | `position` | present |
| plans/reference/ui-rules.md:48 | `reset_size()` | present |
| plans/reference/ui-rules.md:48 | `Control.set_size()` | present |
| plans/reference/ui-rules.md:53 | `ui_panel_layout.gd::apply()` | present |
| plans/reference/ui-rules.md:59 | `plans/archive/LAYOUT_REGRESSION_2026-09-09.md` | present |
| plans/reference/ui-rules.md:61 | `tests/fixtures/layout_panels.json` | present |
| plans/reference/ui-rules.md:62 | `ui_layout.gd` | moved to scripts/ui_layout.gd |
| plans/reference/ui-rules.md:64 | `ui_layout.gd::gallerin_rect()` | present |
| plans/reference/ui-rules.md:66 | `plans/archive/HC-14_2026-09-10.md` | present |
| plans/reference/ui-rules.md:67 | `ui_panel_layout.gd::apply()` | present |
| plans/reference/ui-rules.md:71 | `Session` | present |

## Method

1. Parsed all backticked strings across all 39 instruction files in `.claude/rules/`, `plans/reference/`, `docs/`, `CLAUDE.md`, and `AGENTS.md`.
2. Verified file existence against `git ls-files`.
3. Parsed tool scripts and heading titles to verify existence.
4. Searched codebase for symbol names.
