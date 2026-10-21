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

1. **[Claude] T2-14 -- a comb worker's idle reason asks whether there is room to build, without starting a site**
   - Plan: `plans/now/tier-two.md` -- "T2-14 -- a comb worker's idle reason asks whether there is room to build, without starting a site"
   - Files: `scripts/bee.gd`, `scripts/hive.gd`, `tests/t2_14_idle_reason_pure_test.gd`, `tests/test_t2_14_idle_reason_pure.py`
   - Check: `python -m unittest tests.test_t2_14_idle_reason_pure` passes: a comb worker in Build mode without Automation, in BUILD_IDLE with room to build, gives the Automation idle reason, and `hive.cells.size()` is unchanged after 20 `idle_reason()` calls; `hive.has_room_to_build()` is true exactly when `create_next_cell_site()` then returns a site; in `python -m unittest tests.test_t2_11_comb_cadence`'s no-Automation case the DAY 2 line, with a comb worker selected, says "0 sites started that day".
   - Proof: `present: scripts/bee.gd :: if hive.create_next_cell_site(home_hex if has_home_hex else Vector2i.ZERO) == null:`
   - Next after: T2-7b -- the tier-2 price sweep T2-7 deferred

2. **[Claude] CQ-T2 -- run, world and save glue typed**
   - Plan: `plans/now/code-health.md` -- "CQ-T2 -- run, world and save glue typed"
   - Files: `scripts/main.gd`, `scripts/scenario_actions.gd`, `scripts/world_building.gd`, `scripts/input_selection.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/orders_zones.gd`, `scripts/headless/diagnostic_profile.gd`, `scripts/perf.gd`, `scripts/settings_catalogue.gd`, `scripts/challenge_runner.gd`, `scripts/save_slots.gd`, `scripts/hive.gd`, `scripts/diagnostic_log.gd`, `scripts/tutorial_checkpoint.gd`, `scripts/developer_overrides.gd`, `scripts/challenge_stage_setup.gd`, `scripts/save_migrations.gd`, `scripts/player_profile.gd`, `scripts/headless/diagnostic_probes.gd`, `scripts/headless/scenario_boot.gd`, `tests/source_checks.py`, `FUNCTION_MAP.md`
   - Check: the `TYPED_FILES` source check reports zero untyped declarations in every listed script; `python tools/gdscript_warnings.py` on the listed scripts prints no warning; `tests/test_save_migrations.py`, `tests/test_si1_run_state.py`, `tests/test_si2_exact_rollback.py` and `tests/test_layout_regression.py` pass; `python tools/equivalence.py test_scenarios/slice1_smoke_test.json master` matches; `.\tools\verify.ps1` is green
   - Proof: `present: scripts/save_game.gd :: static func save(world, path`
   - Next after: CQ-T3

3. **[Claude] WP-3 -- the ordered list in the selection panel and the colony default**
   - Plan: `plans/now/work-priorities.md` -- "WP-3 -- the ordered list in the selection panel and the colony default"
   - Files: `scripts/hud.gd`, `scripts/colony_panel.gd`, `scripts/orders_zones.gd`, `scripts/main.gd`, `test_scenarios/wp3_backup_order_ui.json`, `tests/test_wp3_backup_order_ui.py`
   - Check: `python -m unittest tests.test_wp3_backup_order_ui` passes (owned, moving a job up in the selection panel reorders every selected bee's list; the Colony window list changes what a newly emerged bee takes; unowned, the single Backup choice is unchanged); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/hud.gd :: backup_order`
   - Next after: none -- the Work Priorities plan is complete; SG-2 in `plans/now/short-term-goals.md` follows in Dave's order

4. **[Claude] CQ-S0 -- golden-save round-trip harness**
   - Plan: `plans/now/code-health.md` -- "CQ-S0 -- golden-save round-trip harness"
   - Files: `tests/save_roundtrip_test.gd`, `tests/test_save_roundtrip.py`, `tests/fixtures/saves/cq_s0_early.json`, `tests/fixtures/saves/cq_s0_mid.json`, `tests/fixtures/saves/cq_s0_winter.json`, `tests/fixtures/saves/cq_s0_challenge2.json`, `tests/fixtures/saves/cq_s0_orientation.json`, `test_scenarios/cq_s0_early_capture.json`, `test_scenarios/cq_s0_mid_capture.json`, `test_scenarios/cq_s0_winter_capture.json`, `test_scenarios/cq_s0_challenge2_capture.json`, `test_scenarios/cq_s0_orientation_capture.json`, `.claude/rules/saving.md`
   - Check: `python -m unittest tests.test_save_roundtrip` passes, comparing every golden save's load-then-save output to its input by both routes, with any known difference named and escalated; `.\tools\verify.ps1` is green
   - Proof: `absent: .claude/rules/saving.md :: round-trip`
   - Next after: CQ-S1

5. **[Claude] CQ-L1 -- gdlint runs in verify.ps1 with Dave's thresholds**
   - Plan: `plans/now/code-health.md` -- "CQ-L1 -- gdlint runs in verify.ps1 with Dave's thresholds"
   - Files: `tools/gdscript_style.py`, `tests/test_gdscript_style.py`, `tools/verify.ps1`, `tests/rr7_silkscreen_fit_test.gd`, `godot-copy-all-errors-5ab5055222311666b16982270e1fac051cdd17aa/README.md`, `godot-copy-all-errors-5ab5055222311666b16982270e1fac051cdd17aa/addons/copy_all_errors/plugin.cfg`, `godot-copy-all-errors-5ab5055222311666b16982270e1fac051cdd17aa/addons/copy_all_errors/plugin.gd`, `scripts/fog_of_war.gd`, `scripts/skill_tree_panel.gd`, `scripts/hive.gd`, `scripts/bee_foraging.gd`, `scripts/flower.gd`, `scripts/bee.gd`, `scripts/diagnostic_log.gd`, `scripts/hive_cell.gd`, `scripts/input_selection.gd`, `tests/bs14_saved_skill_policy_test.gd`, `tests/col10_succession_test.gd`, `.claude/rules/gdscript.md`, `FUNCTION_MAP.md`
   - Check: `python tools/gdscript_style.py` exits 0 with zero gdlint problems over every tracked `.gd` outside `addons/`; `tests/test_gdscript_style.py` covers the missing-gdtoolkit skip; `.\tools\verify.ps1` shows a green `gdscript style` stage
   - Proof: `absent: tools/verify.ps1 :: gdscript style`
   - Next after: CQ-L2

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
- **SP-8a** (`plans/now/meadow-terrain.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); waits for ED-3, the last of the alpha chain (WP-3 to ED-3; WP-2 landed 21 Oct 2026), which shares `scripts/main.gd` and the save files (Dave, 16 Oct 2026).
- **SP-6** (`plans/now/sprites.md`) -- meadow foragers drawn from the sheet (eight directions, flapping wings); waits for Dave's forager sheet on a 16x16 `sheet` grid in an `.aseprite` (the 11 Oct repack, committed 13 Oct as `bees/foragers_meadow_view.png`, is not on it yet), and is queued once that is committed (SP-5 landed 12 Oct 2026).
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **SG-2** (`plans/now/short-term-goals.md`) -- goals offered, paid and saved in runs; waits for WP-3 (Dave's order; FC-2 landed 17 Oct 2026, freeing the save files; SG-1 landed 14 Oct 2026).
- **SG-3** (`plans/now/short-term-goals.md`) -- the goals shown in the Goals drop-down; waits for SG-2 (GP-2 landed 13 Oct 2026).
- **ED-1** (`plans/now/difficulty.md`) -- every bee has health; waits for SG-3 (Dave's order; FC-2 landed 17 Oct 2026, freeing the save files).
- **ED-2** (`plans/now/difficulty.md`) -- a run's difficulty and Easy's rules; waits for ED-1.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2.
- **The event director** (`plans/design/product-scope.md` §6.2) -- needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **PP-6** (`plans/now/pollination.md`) -- the sweep prices the gyne route so Gyne rearing is first affordable in the 11 days after the first winter; waits for FR-2, which puts Auto scouting on the route (Dave, 14 Oct 2026), and AR-5 (`plans/now/alpha-route-evidence.md`), whose reference queen lays early (Dave, 16 Oct 2026).
- **FR-2** (`plans/now/forager-recruitment.md`) -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight; waits for FR-1b (Codex backlog) to tune the stage order FR-1 measured, so Auto scouting forages better (FR-1 landed 17 Oct 2026; Dave, 14 Oct 2026).
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-6, which shares `scripts/skills.gd`.
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (SG-2, ED-1, ED-2, RR-12, SP-8a; WP-2 landed 21 Oct 2026) and ED-3 (Dave, 18 Oct 2026), and for CQ-S0's round-trip harness.
- **CQ-M3** (`plans/now/code-health.md`) -- the rival's starting nectar, pollen, forager share and minimum population become GameConfig rows, and its rebalance numbers named consts; waits for RR-11 (Claude lane), which shares `scripts/game_config.gd` and `scripts/settings_catalogue.gd` and holds the lane's fifth slot (CQ-M2 landed 21 Oct 2026).
- **CQ-R2** (`plans/now/code-health.md`) -- the first crisis moves out of `scripts/main.gd` into a new first_crisis.gd, touching the save files; waits, gated with CQ-S1, for the save slices of the alpha chain (SG-2, ED-1, ED-2, RR-12, SP-8a; WP-2 landed 21 Oct 2026) and ED-3 (Dave, 18 Oct 2026); its plan section is written when that gate clears.
- **CQ-R8** (`plans/now/code-health.md`) -- hud builders shortened (the designation button table); waits for CQ-R7 (Claude lane), which shares `scripts/hud.gd`; its section and block are written when CQ-R7 lands.
- **CQ-L2** (`plans/now/code-health.md`) -- every tool that reads GDScript as text survives `gdformat`; waits for CQ-L1 (Claude backlog), which puts gdlint into verify first.
- **CQ-T3** (`plans/now/code-health.md`) -- the UI scripts typed and the untyped warning made an error; waits for CQ-T2, the second typing slice.
- **CQ-S2** (`plans/now/code-health.md`) -- HiveCell owns its save fields; waits for CQ-S1, which sets the `to_save()`/`from_save()` pattern and shares the save files.
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
