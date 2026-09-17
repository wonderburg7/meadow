# Next steps

<!-- CONTEXT: current-queue | LOAD: never whole; tools/slice.ps1 reads it -->

Do not read this file to find work: `tools/slice.ps1 start -Lane Claude|Codex`
claims your lane's first item and prints the one `read` command you need.
This file holds the queue only -- detail lives in each item's `Plan:` section,
and history in Git and `plans/archive/` (the old log is
`plans/archive/NEXTSTEPS_LOG_2026-09-17.md`). Rules: `.claude/rules/documentation.md`.

## Next up

### Claude lane

Up to five items, worked top to bottom. No file here may appear in the Codex lane.

1. **[Claude] UI-W-2 -- Challenge 2's cell tray offers a Forager to raise**
   - Plan: `plans/now/ui-w.md` -- "UI-W-2 — Challenge 2's cell tray offers a Forager to raise"
   - Files: `scripts/hud.gd`, `scripts/scenario_actions.gd`, `scripts/challenge_runner.gd`
   - Check: a new test_scenarios/uiw2_challenge2_raises_forager_test.json fails on master and passes after the fix -- at 2.2 the Forager hatch menu is visible with a usable rect inside the command tray
   - Proof: `absent: scripts/scenario_actions.gd :: "select_cell"`
   - Next after: UI-W-3 -- a comb cell's tray uses three columns.

2. **[Claude] UI-W-1 -- the settings window: a quarter of the screen, a readable stage row, a tight Controls list**
   - Plan: `plans/now/ui-w.md` -- "UI-W-1 — the settings window: a quarter of the screen, a readable stage row, a tight Controls list"
   - Files: `scripts/debug_panel.gd`, `scripts/ui_layout.gd`, `tests/fixtures/settings_stage_row.json`
   - Check: `tests/fixtures/settings_stage_row.json` gains a width assertion -- the settings panel is 480±1 px wide inside a 1920x1080 viewport -- which fails on master, where `PANEL_WIDTH` is 320; `no_collapsed_controls` still passes there and at 800x600
   - Proof: `present: scripts/debug_panel.gd :: PANEL_WIDTH := 320.0`
   - Next after: UI-W-4 -- Dr Gallerin's bubble grows to a third of the window's height.

3. **[Claude] E1 -- one placement tool**
   - Plan: `plans/design/architecture-review.md` -- "E1 — one placement tool"
   - Files: `scripts/main.gd`, `scripts/input_selection.gd`, `scripts/hud.gd`, `scripts/challenge_runner.gd`
   - Check: a scenario fixture that activates Build cell, then Mine target, then clicks, asserting a mine target was set and no cell was placed (fails today)
   - Proof: `present: scripts/main.gd :: awaiting_build_cell`
   - Next after: F1s -- a shared window base class.

4. **[Claude] C1F-1 -- each Challenge 1 stage sets up the world it starts from**
   - Plan: `plans/now/c1-followups.md` -- "C1F-1 — each Challenge 1 stage sets up the world it starts from"
   - Files: `scripts/challenge_stage_setup.gd`, `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`, `scripts/scenario_actions.gd`
   - Check: a new test_scenarios/c1f1_stage_setup_test.json steps forward to 1.19 and back to 1.1 and asserts each stage stays put for 2 seconds; it fails on master at the first retreat into a met goal
   - Proof: `absent: scripts/challenge_runner.gd :: ChallengeStageSetup`
   - Next after: C1F-2 -- a headless run proves the queen's pollen departure and no discard loop.

5. **[Claude] CB-1 -- measure where comb builders stand and how many work one site**
   - Plan: `plans/now/comb-builders.md` -- "CB-1 — measure where comb builders stand and how many work one site"
   - Files: `scripts/scenario_actions.gd`, `test_scenarios/cb1_comb_builders_per_site_test.json`
   - Check: two headless runs of the new fixture report identical per-site builder counts and stand points, and the delivery note names which of H1-H3 the numbers support
   - Proof: `absent: scripts/scenario_actions.gd :: builders_per_site`
   - Next after: CB-2 -- the fix CB-1 identifies.

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude lane.

1. **[Codex] G2 -- the dispatcher reads the catalogue**
   - Plan: `plans/design/architecture-review.md` -- "G2 — the dispatcher reads the catalogue"
   - Files: `scripts/bee.gd`, `scripts/bee_building.gd`, `scripts/bee_egg_laying.gd`, `scripts/bee_foraging.gd`, `scripts/bee_honey.gd`, `scripts/bee_mining.gd`, `scripts/bee_nursery.gd`
   - Check: a headless equivalence run of `test_scenarios/recommendation_slice0_baseline.json` and `test_scenarios/colony_30_bees_test.json` to their fixed day counts, with identical population, stock and emergence summaries before and after; record frame time against `docs/PERFORMANCE_BASELINE.md`
   - Proof: `present: scripts/bee.gd :: func _try_role_work`
   - Next after: G3 -- actions become gateable.

2. **[Codex] SM-1 -- find why the smoke scenario never completes a cell**
   - Plan: `plans/now/smoke-scenario.md` -- "SM-1 — find why the smoke scenario never completes a cell"
   - Files: `test_scenarios/slice1_smoke_test.json`
   - Check: `python tools/run_scenario.py test_scenarios/slice1_smoke_test.json` returns status=passed twice on the same seed, and the delivery note classifies the cause as stale fixture or product defect with numbers
   - Proof: `present: test_scenarios/slice1_smoke_test.json :: "cells_completed_at_least": 1`
   - Next after: none -- smoke-scenario is complete.

3. **[Codex] SF-1 -- a new run's meadow starts with the season mix it will settle into**
   - Plan: `plans/now/season-feel.md` -- "SF-1 — a new run's meadow starts with the season mix it will settle into"
   - Files: `scripts/world_building.gd`, `scripts/flower.gd`, `scripts/flower_species.gd`, `scripts/diagnostic_log.gd`, `test_scenarios/sf1_founding_flower_mix_test.json`
   - Check: the fixture's run summary at Season days 5 -- the day-0 out-of-season share of flowers is within 5 points of the day-5 share and below 15%, asserted in a Python test that reads the two new DiagnosticLog counters; hands-on check C-25 moves to ready
   - Proof: `present: scripts/flower_species.gd :: static func season_weight(species: Dictionary) -> float:`
   - Next after: none -- season-feel is complete.

4. **[Codex] PERF-1 -- measure `find_food_cell` before changing it**
   - Plan: `plans/reference/technical-audit.md` -- "PERF-1 — measure `find_food_cell` before changing it"
   - Files: `scripts/hive.gd`, `docs/PERFORMANCE_BASELINE.md`
   - Check: two runs of `test_scenarios/recommendation_slice0_baseline.json` at `--fixed-fps 60` with perf enabled report the new `hive_find_food` section within 10% of each other, and the delivery note says whether it is trivial or worth a follow-up slice, with the numbers
   - Proof: `absent: scripts/hive.gd :: hive_find_food`
   - Next after: none -- technical-audit section A is complete unless PERF-1's numbers open a follow-up.

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **UI-W-3** (`plans/now/ui-w.md`) -- uses UI-W-2's `select_cell` action.
- **UI-W-4** (`plans/now/ui-w.md`) -- follows UI-W-1 in `scripts/ui_layout.gd`.
- **CB-2** (`plans/now/comb-builders.md`) -- its cause is what CB-1 measures, and its fix waits for G2 to finish with the `bee_*.gd` modules.
- **C1F-2** (`plans/now/c1-followups.md`) -- starts its run through C1F-1's stage setup.
- **F1s, F2s, G3** (`plans/design/architecture-review.md`) -- F1s needs `scripts/scenario_actions.gd` clear of the Claude lane; F2s follows F1s; G3 follows G2 and F2s.
- **Progression Phase B step 6 onwards** (`plans/design/progression.md`) -- wants a clear run of the UI work above.
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`
