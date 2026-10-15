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

1. **[Claude] RR-6 -- every new run gets its own default name, saved or not**
   - Plan: `plans/now/run-repairs.md` -- "RR-6 -- every new run gets its own default name, saved or not"
   - Files: `scripts/save_slots.gd`, `tests/test_rr3_fresh_run_name.py`
   - Check: `python -m unittest tests.test_rr3_fresh_run_name` passes, including a new case: with no slots at all, two calls to `SaveSlots.fresh_run_name("My colony")` return "My colony" and then "My colony 2", and a third with "My colony 2" saved returns "My colony 3".
   - Proof: `absent: scripts/save_slots.gd :: _issued_run_slugs`
   - Next after: RR-7 -- why Silkscreen at text scale 2 still splits a menu hexagon's word (investigation)

2. **[Claude] SP-10 -- hive soil blocks draw front over back everywhere**
   - Plan: `plans/now/sprites.md` -- "SP-10 -- hive soil blocks draw front over back everywhere"
   - Files: `scripts/shapes.gd`, `scripts/soil_block.gd`, `scripts/rock_block.gd`, `scripts/hive_cell.gd`, `tests/sp10_soil_depth_test.gd`, `tests/test_sp10_soil_depth.py`
   - Check: `python -m unittest tests.test_sp10_soil_depth` passes: every soil and rock block in a fresh hive has `z_index == Shapes.hex_draw_depth(axial)`, a block one row lower on screen has a higher `z_index` than the block above it, and a comb cell and a soil block on neighbouring hexes order the same way.
   - Proof: `absent: scripts/soil_block.gd :: z_index`
   - Next after: SP-11 -- every ring on a cell traces the cup's rim

3. **[Claude] SP-11 -- every ring on a cell traces the cup's rim**
   - Plan: `plans/now/sprites.md` -- "SP-11 -- every ring on a cell traces the cup's rim"
   - Files: `scripts/hive_cell.gd`, `tests/sp11_cell_rim_test.gd`, `tests/test_sp11_cell_rim.py`
   - Check: `python -m unittest tests.test_sp11_cell_rim` passes: with Cell art on, the selection ring's points are `EMPTY_RIM` taken through `_silhouette_point_to_local` and scaled about the rim's centre; the designation, zone and base rings use the same six points at their own sizes; with Cell art off every ring is still the hexagon.
   - Proof: `absent: scripts/hive_cell.gd :: EMPTY_RIM`
   - Next after: SP-8a -- the meadow floor drawn in blocks, with everything on it lifted

4. **[Claude] T2-10 -- a miner on Dig on its own starts as soon as Automation is bought, and an idle miner or comb worker says it needs Automation**
   - Plan: `plans/now/tier-two.md` -- "T2-10 -- a miner on Dig on its own starts as soon as Automation is bought"
   - Files: `scripts/bee.gd`, `tests/t2_10_automine_wake_test.gd`, `tests/test_t2_10_automine_wake.py`
   - Check: `python -m unittest tests.test_t2_10_automine_wake` passes: a miner with `automine` on and Automation not owned finds no work and its `idle_reason()` names Automation; Automation is then granted and `Availability.invalidate()` called, with no block marked and `hive.mining_work_epoch` unchanged, and the miner's next `_try_role_work(Role.MINER)` returns true; a comb worker in Build mode with nothing marked, room to build and no Automation gives an `idle_reason()` naming Automation.
   - Proof: `absent: scripts/bee.gd :: _mining_no_work_gate_epoch`
   - Next after: T2-11 -- why comb workers build comb unevenly (investigation)

5. **[Claude] TS-1 -- every typeface is the same width as Standard at the same text scale**
   - Plan: `plans/now/typeface-size.md` -- "TS-1 -- width-matched typeface sizes"
   - Files: `scripts/ui_theme.gd`, `scripts/main_menu.gd`, `scripts/gallerin_panel.gd`, `scripts/hive_cell.gd`, `tests/ts1_typeface_size_test.gd`, `tests/test_ts1_typeface_size.py`
   - Check: `python -m unittest tests.test_ts1_typeface_size` passes: at text scale 1 and 2, for every typeface in the Typeface setting, `REFERENCE_TEXT` drawn at `UiTheme.font_px(TYPE_SIZES["Body"])` in that face is within 8 % of its width in Standard; `python -m unittest tests.test_ho15_menu_hex_fit tests.test_rr5_hex_refit` still pass.
   - Proof: `absent: scripts/ui_theme.gd :: typeface_size_factor`
   - Next after: TS-2 -- the HUD's own size overrides follow the typeface too

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] GD-2b -- the shown ledger and Why history saved with the run**
   - Plan: `plans/now/guidance-explanations.md` -- "GD-2b -- the shown ledger and Why history saved with the run"
   - Files: `scripts/guidance_policy.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_gd2b_guidance_saved.py`
   - Check: `python -m unittest tests.test_gd2b_guidance_saved` passes (an explanation shown before a save is not shown again after loading it, and the Why history survives; an older save loads with an empty ledger); `tools/verify.ps1` is green
   - Proof: `absent: scripts/save_game.gd :: guidance`
   - Next after: none -- guidance explanations are complete

2. **[Codex] FR-1 -- the three foraging stages measured on the same Colony Run seeds**
   - Plan: `plans/now/forager-recruitment.md` -- "FR-1 -- the three foraging stages measured on the same Colony Run seeds"
   - Files: `tools/forager_stages.py`, `tests/test_forager_stages.py`, `test_scenarios/fr1_forager_stages_test.json`, `tools/scenario_sweep.py`
   - Check: `python -m unittest tests.test_forager_stages` passes; `python tools/forager_stages.py` prints food per forager per day for the four stages on five seeds, and the table is recorded in this plan's FR-1 section; `tools/verify.ps1` is green
   - Proof: `absent: tools/scenario_sweep.py :: ^fr1_`
   - Next after: FR-2 -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **FC-2** (`plans/now/crisis-readiness.md`) -- implement the accepted crisis and deterministic scenario; Dave accepted FC-1's option A and T2-4b has landed; `scripts/main.gd`, `scripts/save_game.gd` and `scripts/saving.gd` were released 13 Oct 2026, and `scripts/scenario_actions.gd` the same day, so it waits only for the Claude lane's GP-4 to release `scripts/hud.gd` (the restocking purchase slice released it 14 Oct 2026).
- **SP-8a** (`plans/now/sprites.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); Dave put FC-2 first (13 Oct 2026), so it waits for FC-2 (Codex lane) to release `scripts/main.gd`, `scripts/save_game.gd` and `scripts/saving.gd`.
- **SP-6** (`plans/now/sprites.md`) -- meadow foragers drawn from the sheet (eight directions, flapping wings); waits for Dave's forager sheet on a 16x16 `sheet` grid in an `.aseprite` (the 11 Oct repack, committed 13 Oct as `bees/foragers_meadow_view.png`, is not on it yet), and is queued once that is committed (SP-5 landed 12 Oct 2026).
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **WP-2** (`plans/now/work-priorities.md`) -- each bee's backup an ordered list; waits only for FC-2 (Codex lane) to release the save files (WP-1 landed 14 Oct 2026; Dave's order, 13 Oct 2026: tier 3, then short-term goals, then Easy).
- **WP-3** (`plans/now/work-priorities.md`) -- the ordered list in the selection panel and the colony default; waits for WP-2.
- **SG-2** (`plans/now/short-term-goals.md`) -- goals offered, paid and saved in runs; waits for WP-3 (Dave's order) and FC-2 releasing the save files (SG-1 landed 14 Oct 2026).
- **SG-3** (`plans/now/short-term-goals.md`) -- the goals shown in the Goals drop-down; waits for SG-2 (GP-2 landed 13 Oct 2026).
- **ED-1** (`plans/now/difficulty.md`) -- every bee has health; waits for SG-3 (Dave's order) and FC-2 releasing the save files.
- **ED-2** (`plans/now/difficulty.md`) -- a run's difficulty and Easy's rules; waits for ED-1.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2.
- **The event director** (`plans/design/product-scope.md` §6.2) -- needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. Dr Gallerin guidance now has its plan, `plans/now/guidance-explanations.md`.
- **PP-6** (`plans/now/pollination.md`) -- the sweep prices the gyne route so Gyne rearing is first affordable in the 11 days after the first winter; waits for FR-2, which puts Auto scouting on the route (Dave, 14 Oct 2026).
- **FR-2** (`plans/now/forager-recruitment.md`) -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight; waits for FR-1's measurement to show Auto scouting forages better (Dave, 14 Oct 2026).
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-6, which shares `scripts/skills.gd`.
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
