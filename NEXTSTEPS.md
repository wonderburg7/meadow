# Next steps

<!-- CONTEXT: current-queue | LOAD: never whole; tools/slice.ps1 reads it -->

Do not read this file to find work: `tools/slice.ps1 start -Lane Claude|Codex`
claims your lane's first item and prints the one `read` command you need.
This file holds the queue only -- detail lives in each item's `Plan:` section,
and history in Git and `plans/archive/` (the old log is
`plans/archive/NEXTSTEPS_LOG_2026-09-17.md`). Rules: `.claude/rules/documentation.md`.

Neither lane is written by hand any more. A lane refills itself from the
backlog: the fenced `queue` blocks in the plans, each holding the exact item
its slice would be queued as (`tools/backlog.py`). `tools/slice.ps1 finish`
deletes the closing item and tops its lane back up towards five in the same
run. Five is a ceiling the backlog reaches when it has admissible work, not a
number this file is padded out to -- a lane the backlog cannot fill stays
short and says which candidate it refused and why.

## Next up

### Claude lane

Up to five items, worked top to bottom. No file here may appear in the Codex
lane. Refilled by `python tools/refill_lane.py --top-up --lane Claude`.

1. **[Claude] CQ-T1 -- rules, simulation and gd tests typed, with the warning on**
   - Plan: `plans/now/code-health.md` -- "CQ-T1 -- rules, simulation and gd tests typed, with the warning on"
   - Files: `project.godot`, `tests/source_checks.py`, `tests/test_source_checks.py`, `scripts/conditions.gd`, `scripts/year_winter.gd`, `scripts/skills.gd`, `scripts/season.gd`, `scripts/availability.gd`, `scripts/resources.gd`, `scripts/adaptations.gd`, `scripts/colony_diagnostics.gd`, `scripts/pollination.gd`, `scripts/bee_foraging.gd`, `scripts/bee_nursery.gd`, `scripts/bee_honey.gd`, `scripts/colony_milestones.gd`, `scripts/guidance_policy.gd`, `scripts/foraging_stats.gd`, `scripts/bee.gd`, `scripts/run_availability.gd`, `scripts/progression.gd`, `scripts/features.gd`, `scripts/bee_building.gd`, `scripts/rival_hive.gd`, `scripts/hive_cell.gd`, `scripts/flower.gd`, `scripts/bee_mining.gd`, `scripts/bee_egg_laying.gd`, `tests/t2_4b_bodies_test.gd`, `tests/t2_11_comb_cadence_test.gd`, `tests/pp5_priority_cells_test.gd`, `tests/gp1_goals_dropdown_test.gd`, `tests/sp11_cell_rim_test.gd`, `tests/col7_gyne_window_test.gd`, `tests/rr9_winter_ages_nothing_test.gd`, `tests/t2_10_automine_wake_test.gd`, `tests/si2_exact_rollback_test.gd`, `tests/col8_winter_dieback_test.gd`, `tests/t3_1_weighted_choice_test.gd`, `tests/sp10_soil_depth_test.gd`, `tests/gp2_goal_favourites_test.gd`, `tests/bs14_saved_skill_policy_test.gd`, `tests/rr2_boot_saves_test.gd`, `tests/gp4_problem_strip_test.gd`, `FUNCTION_MAP.md`
   - Check: the `TYPED_FILES` source check reports zero untyped declarations in every listed script and test; `python tools/gdscript_warnings.py` on the listed scripts prints no warning; `python tools/equivalence.py test_scenarios/slice1_smoke_test.json master` matches; `.\tools\verify.ps1` is green
   - Proof: `absent: project.godot :: untyped_declaration`
   - Next after: CQ-T2

2. **[Claude] CQ-M1 -- parity checks for two hand-copied lists**
   - Plan: `plans/now/code-health.md` -- "CQ-M1 -- parity checks for two hand-copied lists"
   - Files: `tests/source_checks.py`, `tests/test_source_checks.py`
   - Check: both checks pass on today's tree and fail on their mutated inputs in `tests/test_source_checks.py`; `.\tools\verify.ps1` is green
   - Proof: `absent: tests/source_checks.py :: scenario_presets.gd`
   - Next after: CQ-M2

3. **[Claude] CQ-M2 -- the starving threshold becomes a GameConfig row**
   - Plan: `plans/now/code-health.md` -- "CQ-M2 -- the starving threshold becomes a GameConfig row"
   - Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/colony_diagnostics.gd`, `scripts/problem_messages.gd`, `scripts/year_winter.gd`, `docs/agent-rules.md`, `FUNCTION_MAP.md`
   - Check: `tests/test_colony_diagnostics.py`, `tests/test_signal_catalogue.py` and the settings-row source checks pass; `python tools/equivalence.py test_scenarios/slice1_smoke_test.json master` matches; `.\tools\verify.ps1` is green
   - Proof: `present: scripts/colony_diagnostics.gd :: GameConfig.energy_capacity * 0.15`
   - Next after: CQ-M3

4. **[Claude] CQ-R0 -- display-text golden harness**
   - Plan: `plans/now/code-health.md` -- "CQ-R0 -- display-text golden harness"
   - Files: `tests/display_text_golden_test.gd`, `tests/test_display_text_golden.py`, `tests/fixtures/display_text_golden.json`, `.claude/rules/gdscript.md`
   - Check: `python -m unittest tests.test_display_text_golden` passes against the master capture and fails when one character of a captured string is changed; `.\tools\verify.ps1` is green
   - Proof: `absent: .claude/rules/gdscript.md :: display_text_golden`
   - Next after: CQ-R7

5. **[Claude] CQ-R1 -- headless scenario boot leaves main.gd**
   - Plan: `plans/now/code-health.md` -- "CQ-R1 -- headless scenario boot leaves main.gd"
   - Files: `scripts/main.gd`, `scripts/headless/scenario_boot.gd`, `scripts/scenario_actions.gd`, `scripts/diagnostic_log.gd`, `scripts/scenario_presets.gd`, `tools/update_function_map.py`, `FUNCTION_MAP.md`, `.claude/rules/gdscript.md`, `docs/agent-rules.md`
   - Check: `tests/test_run_scenario_launch.py` passes; `python tools/equivalence.py test_scenarios/slice1_smoke_test.json master` and `test_scenarios/sv1_named_saves_test.json` match; a performance-capture scenario still writes its capture; `.\tools\verify.ps1` is green
   - Proof: `present: scripts/main.gd :: func _apply_scenario_boot_arg(`
   - Next after: CQ-R2

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] AR-5 -- the first two gates on the calendar, and a reference queen who lays early**
   - Plan: `plans/now/alpha-route-evidence.md` -- "AR-5 -- the first two gates on the calendar, and a reference queen who lays early"
   - Files: `tools/pacing_gates.py`, `tests/test_pacing_gates.py`, `test_scenarios/alpha_arc_test.json`, `plans/now/alpha-route-evidence.md`
   - Check: `python -m unittest tests.test_pacing_gates` passes; `python tools/pacing_gates.py` judges the first worker by day 3.0 and first automation on days 5.0 to 8.0, its first-worker median is at most day 3.0 with at least two of three colonies living through winter, and the table is recorded in this section
   - Proof: `absent: tools/pacing_gates.py :: FIRST_WORKER_BY_DAY`
   - Next after: PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **RR-12** (`plans/now/run-repairs.md`) -- a loaded run keeps its readout history (Dave, 16 Oct 2026); waits for ED-3, the last of the alpha chain, which shares `scripts/main.gd` and the save files.
- **SP-8a** (`plans/now/meadow-terrain.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); waits for ED-3, the last of the alpha chain (WP-2 to ED-3), which shares `scripts/main.gd` and the save files (Dave, 16 Oct 2026).
- **SP-6** (`plans/now/sprites.md`) -- meadow foragers drawn from the sheet (eight directions, flapping wings); waits for Dave's forager sheet on a 16x16 `sheet` grid in an `.aseprite` (the 11 Oct repack, committed 13 Oct as `bees/foragers_meadow_view.png`, is not on it yet), and is queued once that is committed (SP-5 landed 12 Oct 2026).
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **WP-3** (`plans/now/work-priorities.md`) -- the ordered list in the selection panel and the colony default; waits for WP-2.
- **SG-2** (`plans/now/short-term-goals.md`) -- goals offered, paid and saved in runs; waits for WP-3 (Dave's order; FC-2 landed 17 Oct 2026, freeing the save files; SG-1 landed 14 Oct 2026).
- **SG-3** (`plans/now/short-term-goals.md`) -- the goals shown in the Goals drop-down; waits for SG-2 (GP-2 landed 13 Oct 2026).
- **ED-1** (`plans/now/difficulty.md`) -- every bee has health; waits for SG-3 (Dave's order; FC-2 landed 17 Oct 2026, freeing the save files).
- **ED-2** (`plans/now/difficulty.md`) -- a run's difficulty and Easy's rules; waits for ED-1.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2.
- **The event director** (`plans/design/product-scope.md` §6.2) -- needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **PP-6** (`plans/now/pollination.md`) -- the sweep prices the gyne route so Gyne rearing is first affordable in the 11 days after the first winter; waits for FR-2, which puts Auto scouting on the route (Dave, 14 Oct 2026), and AR-5 (`plans/now/alpha-route-evidence.md`), whose reference queen lays early (Dave, 16 Oct 2026).
- **FR-2** (`plans/now/forager-recruitment.md`) -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight; waits for FR-1b (Codex backlog) to tune the stage order FR-1 measured, so Auto scouting forages better (FR-1 landed 17 Oct 2026; Dave, 14 Oct 2026).
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-6, which shares `scripts/skills.gd`.
- **RR-11** (`plans/now/run-repairs.md`) -- nectar shows a pre-fermented warning colour before it ferments (Dave, 15 Oct 2026); waits for RR-10 (Codex lane), whose test it extends (SP-11 landed 15 Oct 2026, releasing `scripts/hive_cell.gd`).
- **T2-14** (`plans/now/tier-two.md`) -- a comb worker's idle reason asks whether there is room to build, without starting a site (found by T2-11, which landed 17 Oct 2026); waits for RR-10 (Codex lane) to release `scripts/hive.gd`, and runs after T2-13 (both edit `scripts/bee.gd`).
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (WP-2, SG-2, ED-1, ED-2, RR-12, SP-8a) and ED-3 (Dave, 18 Oct 2026), and for CQ-S0's round-trip harness.
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
