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

1. **[Claude] CQ-R1 -- headless scenario boot leaves main.gd**
   - Plan: `plans/now/code-health.md` -- "CQ-R1 -- headless scenario boot leaves main.gd"
   - Files: `scripts/main.gd`, `scripts/headless/scenario_boot.gd`, `scripts/scenario_actions.gd`, `scripts/diagnostic_log.gd`, `scripts/scenario_presets.gd`, `tools/update_function_map.py`, `FUNCTION_MAP.md`, `.claude/rules/gdscript.md`, `docs/agent-rules.md`
   - Check: `tests/test_run_scenario_launch.py` passes; `python tools/equivalence.py test_scenarios/slice1_smoke_test.json master` and `test_scenarios/sv1_named_saves_test.json` match; a performance-capture scenario still writes its capture; `.\tools\verify.ps1` is green
   - Proof: `present: scripts/main.gd :: func _apply_scenario_boot_arg(`
   - Next after: CQ-R2

2. **[Claude] TS-2 -- the HUD's own size overrides follow the typeface too**
   - Plan: `plans/now/typeface-size.md` -- "TS-2 -- the HUD's own size overrides"
   - Files: `scripts/hud.gd`, `tests/ts2_hud_typeface_size_test.gd`, `tests/test_ts2_hud_typeface_size.py`
   - Check: `python -m unittest tests.test_ts2_hud_typeface_size` passes: with OpenDyslexic at text scale 1, the corner readouts and goal lines carry `UiTheme.font_px` of their base sizes, and switching typeface rebuilds the corner.
   - Proof: `absent: scripts/hud.gd :: UiTheme.font_px`
   - Next after: none -- plans/now/typeface-size.md is complete

3. **[Claude] WP-2 -- owned, each bee follows an ordered backup list**
   - Plan: `plans/now/work-priorities.md` -- "WP-2 -- owned, each bee follows an ordered backup list"
   - Files: `scripts/bee.gd`, `scripts/session.gd`, `scripts/skills.gd`, `scripts/orders_zones.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/wp2_backup_order_test.gd`, `tests/test_wp2_backup_order.py`
   - Check: `python -m unittest tests.test_wp2_backup_order` passes (unowned, a bee falls back on its one backup as today; owned, an idle bee whose role and first backup have no work takes the next job on its list that does; a bee born after purchase takes the colony default; the lists and the default survive save and restore; an old save loads each bee with its backup first); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/bee.gd :: backup_order`
   - Next after: WP-3 -- the ordered list in the selection panel and the colony default

4. **[Claude] RR-11 -- nectar shows a pre-fermented colour before it ferments, as a warning**
   - Plan: `plans/now/run-repairs.md` -- "RR-11 -- nectar shows a pre-fermented colour before it ferments, as a warning"
   - Files: `scripts/hive_cell.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/rr11_pre_fermented_test.gd`, `tests/test_rr11_pre_fermented.py`
   - Check: `python -m unittest tests.test_rr11_pre_fermented` passes: a nectar cell aged 0.5, 0.8 and 1.1 times `nectar_ferment_hours` gives `is_pre_fermented()` false, true, false and `is_fermented()` false, false, true; at 0.8 with cell sprites off the cell's flat colour is `PRE_FERMENTED_NECTAR_COLOR`, `hive.find_honey_source` returns it and `hive.take("nectar", 1.0)` takes from it; `python -m unittest tests.test_sp3_content_colours tests.test_nf2_fermentation` still passes.
   - Proof: `absent: scripts/hive_cell.gd :: func is_pre_fermented(`
   - Next after: none -- RR-12, the plan's last slice, waits for ED-3

5. **[Claude] T2-14 -- a comb worker's idle reason asks whether there is room to build, without starting a site**
   - Plan: `plans/now/tier-two.md` -- "T2-14 -- a comb worker's idle reason asks whether there is room to build, without starting a site"
   - Files: `scripts/bee.gd`, `scripts/hive.gd`, `tests/t2_14_idle_reason_pure_test.gd`, `tests/test_t2_14_idle_reason_pure.py`
   - Check: `python -m unittest tests.test_t2_14_idle_reason_pure` passes: a comb worker in Build mode without Automation, in BUILD_IDLE with room to build, gives the Automation idle reason, and `hive.cells.size()` is unchanged after 20 `idle_reason()` calls; `hive.has_room_to_build()` is true exactly when `create_next_cell_site()` then returns a site; in `python -m unittest tests.test_t2_11_comb_cadence`'s no-Automation case the DAY 2 line, with a comb worker selected, says "0 sites started that day".
   - Proof: `present: scripts/bee.gd :: if hive.create_next_cell_site(home_hex if has_home_hex else Vector2i.ZERO) == null:`
   - Next after: T2-7b -- the tier-2 price sweep T2-7 deferred

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
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (WP-2, SG-2, ED-1, ED-2, RR-12, SP-8a) and ED-3 (Dave, 18 Oct 2026), and for CQ-S0's round-trip harness.
- **CQ-T2** (`plans/now/code-health.md`) -- the run, world and save glue typed (20 scripts), the second typing slice; waits for CQ-R1 (`scripts/main.gd`, `scripts/scenario_actions.gd`, `scripts/diagnostic_log.gd`) and CQ-M2 (`scripts/settings_catalogue.gd`), Claude-lane slices that edit its files (CQ-T1 landed 21 Oct 2026).
- **CQ-M3** (`plans/now/code-health.md`) -- the rival's starting nectar, pollen, forager share and minimum population become GameConfig rows, and its rebalance numbers named consts; waits for RR-11 (Claude lane), which shares `scripts/game_config.gd` and `scripts/settings_catalogue.gd` and holds the lane's fifth slot (CQ-M2 landed 21 Oct 2026).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
