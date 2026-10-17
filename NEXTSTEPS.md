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

1. **[Claude] FC-2 -- implement the accepted crisis and deterministic scenario**
   - Plan: `plans/now/crisis-readiness.md` -- "FC-2 -- implement the accepted crisis and deterministic scenario"
   - Files: `scripts/main.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/hud.gd`, `scripts/colony_diagnostics.gd`, `scripts/scenario_actions.gd`, `test_scenarios/fc2_first_crisis_prepared.json`, `test_scenarios/fc2_first_crisis_unprepared.json`, `tests/test_fc2_first_crisis.py`, `plans/now/crisis-readiness.md`
   - Check: `python tests/test_fc2_first_crisis.py` passes and traces one announced crisis, a usable warning-to-rain lead with a completed pre-rain forage response on the unprepared path, its weather/forage/store effect, and save/restore on both paths; file a played comprehension check
   - Proof: `present: scripts/main.gd :: func _advance_weather`
   - Next after: none -- crisis readiness is complete

2. **[Claude] L-27 -- a resumed finish re-verifies a branch that gained commits**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-27 -- a resumed finish re-verifies a branch that gained commits"
   - Files: `tools/slice.ps1`, `tests/test_slice_lifecycle.py`
   - Check: `python -m unittest tests.test_slice_lifecycle` passes, including the three resume cases (code commit re-verifies, Markdown-only commit skips, a journal without head re-verifies); `.\tools\verify.ps1` is green
   - Proof: `absent: tools/slice.ps1 :: function Test-JournalVerifiedHead`
   - Next after: L-28 -- archiving a slice leaves another slice's queue block in the plan

3. **[Claude] L-29 -- session_cost.py counts subagent transcripts and scripted edits**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-29 -- session_cost.py counts subagent transcripts and scripted edits"
   - Files: `tools/session_cost.py`, `tests/test_session_cost_scope.py`
   - Check: `python -m unittest tests.test_session_cost_scope` passes, including subagent files and both scripted-edit forms; `python tools/session_cost.py --days 11 --phases` prints a subagent transcript count and a slice-worker share; `.\tools\verify.ps1` is green
   - Proof: `absent: tools/session_cost.py :: def _subagent_transcripts`
   - Next after: None -- plan complete once L-27 and L-28 land

4. **[Claude] HP-1 -- a searching forager looks for flowers on her think tick**
   - Plan: `plans/now/hot-path-cadence.md` -- "HP-1 -- a searching forager looks for flowers on her think tick"
   - Files: `scripts/bee_foraging.gd`, `test_scenarios/hp1_forager_search_perf.json`, `docs/PERFORMANCE_BASELINE.md`, `plans/now/hot-path-cadence.md`
   - Check: `bee_search` mean in `test_scenarios/hp1_forager_search_perf.json` (`--fixed-fps 60`, two runs each side) falls by at least half; the three-seed means of `forager_deliveries` and `flower_visits` in `foraging_features_off_seed12345_test.json` (`--seeds 12345,2026,555`) stay within 10% of before; both recorded in `docs/PERFORMANCE_BASELINE.md`; FR-1's stage order unchanged if FR-1 has landed; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/bee_foraging.gd :: bee.thinking`
   - Next after: HP-2 -- idle nurses, comb workers and honey makers look for work on the think tick

5. **[Claude] TS-1 -- every typeface is the same width as Standard at the same text scale**
   - Plan: `plans/now/typeface-size.md` -- "TS-1 -- width-matched typeface sizes"
   - Files: `scripts/ui_theme.gd`, `scripts/main_menu.gd`, `scripts/gallerin_panel.gd`, `scripts/hive_cell.gd`, `tests/ts1_typeface_size_test.gd`, `tests/test_ts1_typeface_size.py`
   - Check: `python -m unittest tests.test_ts1_typeface_size` passes: at text scale 1 and 2, for every typeface in the Typeface setting, `REFERENCE_TEXT` drawn at `UiTheme.font_px(TYPE_SIZES["Body"])` in that face is within 8 % of its width in Standard; `python -m unittest tests.test_ho15_menu_hex_fit tests.test_rr5_hex_refit` still pass.
   - Proof: `absent: scripts/ui_theme.gd :: typeface_size_factor`
   - Next after: TS-2 -- the HUD's own size overrides follow the typeface too

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] RR-9 -- a skipped winter ages no nectar and no sealed bee bread**
   - Plan: `plans/now/run-repairs.md` -- "RR-9 -- a skipped winter ages no nectar and no sealed bee bread"
   - Files: `scripts/season.gd`, `tests/rr9_winter_ages_nothing_test.gd`, `tests/test_rr9_winter_ages_nothing.py`
   - Check: `python -m unittest tests.test_rr9_winter_ages_nothing` passes: a sealed nectar cell stocked one game-day before winter and a full bee-bread cell sealed one game-day before it come out of `season.gd::_resolve_winter` with `nectar_age()` and `bee_bread_ripen_fraction()` unchanged (to 0.01), the nectar cell's `is_fermented()` false, and `Session.sim_time` still moved on by `winter_length_days`; `python -m unittest tests.test_col6_winter_skip tests.test_col8_winter_dieback` still passes.
   - Proof: `absent: scripts/season.gd :: nectar_since`
   - Next after: RR-10 -- fermented nectar is neither counted nor spent by skill purchases

2. **[Codex] RR-10 -- fermented nectar is neither counted nor spent by skill purchases**
   - Plan: `plans/now/run-repairs.md` -- "RR-10 -- fermented nectar is neither counted nor spent by skill purchases"
   - Files: `scripts/skill_tree_panel.gd`, `scripts/hive.gd`, `test_scenarios/rr10_fermented_not_currency.json`, `tests/test_rr10_fermented_not_currency.py`
   - Check: `python -m unittest tests.test_rr10_fermented_not_currency` passes: with one fermented nectar cell and one fresh one, a skill whose nectar price exceeds the fresh stock alone is refused and leaves both cells unchanged, and one priced within the fresh stock is bought, spends only fresh nectar and leaves the fermented cell's amount unchanged; `python -m unittest tests.test_bb3_bee_bread_currency tests.test_nf4_fermentation_sense` still passes.
   - Proof: `absent: scripts/skill_tree_panel.gd :: is_fermented`
   - Next after: RR-11 -- nectar shows a pre-fermented colour before it ferments, as a warning

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **RR-12** (`plans/now/run-repairs.md`) -- a loaded run keeps its readout history (Dave, 16 Oct 2026); waits for ED-3, the last of the alpha chain, which shares `scripts/main.gd` and the save files.
- **SP-8a** (`plans/now/meadow-terrain.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); waits for ED-3, the last of the alpha chain behind FC-2 (WP-2 to ED-3), which shares `scripts/main.gd` and the save files (Dave, 16 Oct 2026).
- **SP-6** (`plans/now/sprites.md`) -- meadow foragers drawn from the sheet (eight directions, flapping wings); waits for Dave's forager sheet on a 16x16 `sheet` grid in an `.aseprite` (the 11 Oct repack, committed 13 Oct as `bees/foragers_meadow_view.png`, is not on it yet), and is queued once that is committed (SP-5 landed 12 Oct 2026).
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **WP-2** (`plans/now/work-priorities.md`) -- each bee's backup an ordered list; waits only for FC-2 (Claude lane) to release the save files (WP-1 landed 14 Oct 2026; Dave's order, 13 Oct 2026: tier 3, then short-term goals, then Easy).
- **WP-3** (`plans/now/work-priorities.md`) -- the ordered list in the selection panel and the colony default; waits for WP-2.
- **SG-2** (`plans/now/short-term-goals.md`) -- goals offered, paid and saved in runs; waits for WP-3 (Dave's order) and FC-2 releasing the save files (SG-1 landed 14 Oct 2026).
- **SG-3** (`plans/now/short-term-goals.md`) -- the goals shown in the Goals drop-down; waits for SG-2 (GP-2 landed 13 Oct 2026).
- **ED-1** (`plans/now/difficulty.md`) -- every bee has health; waits for SG-3 (Dave's order) and FC-2 releasing the save files.
- **ED-2** (`plans/now/difficulty.md`) -- a run's difficulty and Easy's rules; waits for ED-1.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2.
- **The event director** (`plans/design/product-scope.md` §6.2) -- needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **PP-6** (`plans/now/pollination.md`) -- the sweep prices the gyne route so Gyne rearing is first affordable in the 11 days after the first winter; waits for FR-2, which puts Auto scouting on the route (Dave, 14 Oct 2026), and AR-5 (`plans/now/alpha-route-evidence.md`), whose reference queen lays early (Dave, 16 Oct 2026).
- **FR-2** (`plans/now/forager-recruitment.md`) -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight; waits for FR-1's measurement to show Auto scouting forages better (Dave, 14 Oct 2026).
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-6, which shares `scripts/skills.gd`.
- **TS-2** (`plans/now/typeface-size.md`) -- the HUD's own size overrides follow the typeface; waits for TS-1, and for FC-2 (Claude lane) to release `scripts/hud.gd`.
- **T2-12** (`plans/now/tier-two.md`) -- Dig on its own is offered only once Automation is owned (Dave, 14 Oct 2026); waits for FC-2 (Claude lane) to release `scripts/hud.gd`.
- **T2-13** (`plans/now/tier-two.md`) -- a bee whose role changes while it carries a body puts the body down; waits for T2-10 to release `scripts/bee.gd`.
- **RR-11** (`plans/now/run-repairs.md`) -- nectar shows a pre-fermented warning colour before it ferments (Dave, 15 Oct 2026); waits for SP-11 to release `scripts/hive_cell.gd`, then runs after RR-10.
- **L-30** (`plans/now/agent-lifecycle.md`) -- released work is visible to the sessions that release it; waits for the unmerged branch `claude/terminal-plan-state-field`, which owns `tools/check_docs.py`, to merge (Dave, 16 Oct 2026).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
