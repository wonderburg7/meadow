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

1. **[Claude] SP-6 -- meadow foragers drawn from the sheet**
   - Plan: `plans/now/sprites.md` -- "SP-6 -- meadow foragers drawn from the sheet"
   - Files: `scripts/bee.gd`, `tests/sp6_forager_sprite_test.gd`, `tests/test_sp6_forager_sprite.py`
   - Check: `python -m unittest tests.test_sp6_forager_sprite` passes: an outdoor worker heading into each of the eight octants shows that direction's row, its frame advances with the wing clock, and its body circles are hidden outdoors and shown indoors; a before/after profile of the display update is recorded in the plan; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/bee.gd :: FORAGERS_MEADOW_VIEW`
   - Next after: None -- plan complete

2. **[Claude] T2-15 -- with Fermentation sense and Cleaning owned, cleaning comb workers discard sour nectar unasked**
   - Plan: `plans/now/tier-two.md` -- "T2-15 -- with Fermentation sense and Cleaning owned, cleaning comb workers discard sour nectar unasked"
   - Files: `scripts/hive.gd`, `scripts/bee_building.gd`, `tests/test_nf5_clear_fermented.py`
   - Check: `python -m unittest tests.test_nf5_clear_fermented` passes with new cases (with both skills a cleaning comb worker empties a sour cell unasked; with only one skill it does not; corpses still come first); the before/after `alpha_arc_test.json` outputs are recorded in the closeout; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/bee_building.gd :: senses_fermentation`
   - Next after: T2-7b -- the deferred tier-2 price sweep

3. **[Claude] ED-1 -- every bee has health**
   - Plan: `plans/now/difficulty.md` -- "ED-1 -- every bee has health"
   - Files: `scripts/bee.gd`, `scripts/bee_survival.gd`, `scripts/bee_movement.gd`, `scripts/crab_spider.gd`, `scripts/game_config.gd`, `scripts/hud.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/ed1_exhaustion.json`, `tests/ed1_health_test.gd`, `tests/test_ed1_health.py`
   - Check: `python -m unittest tests.test_ed1_health` passes (a bee out of energy crawls at 25% speed, loses health and dies after about half a game-day unless it eats first; resting restores health and it leaves only past the thresholds; an ambush still kills; health survives save and restore and an old save loads at full health); the sweep's table is recorded in this section; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/bee.gd :: var health`
   - Next after: ED-2 -- a run's difficulty, and Easy's rules

4. **[Claude] CQ-R15 -- the Goals drop-down becomes scripts/hud_goal_shelf.gd**
   - Plan: `plans/now/code-health.md` -- "CQ-R15 -- the Goals drop-down becomes scripts/hud_goal_shelf.gd"
   - Files: `scripts/hud.gd`, `scripts/hud_goal_shelf.gd`, `tests/gp1_goals_dropdown_test.gd`, `tests/gp2_goal_favourites_test.gd`, `tests/ts2_hud_typeface_size_test.gd`, `FUNCTION_MAP.md`
   - Check: `python -m unittest tests.test_gp1_goals_dropdown tests.test_gp2_goal_favourites tests.test_ts2_hud_typeface_size tests.test_sg3_goal_shelf tests.test_layout_regression` passes with no assertion changed; `scripts/hud.gd` no longer defines `_rebuild_favourites`; `.\tools\verify.ps1` is green
   - Proof: `present: scripts/hud.gd :: func _rebuild_favourites(`
   - Next after: CQ-R8

5. **[Claude] CQ-R16 -- drag and pan state moves from main.gd to input_selection.gd**
   - Plan: `plans/now/code-health.md` -- "CQ-R16 -- drag and pan state moves from main.gd to input_selection.gd"
   - Files: `scripts/main.gd`, `scripts/input_selection.gd`, `scripts/scenario_actions.gd`
   - Check: `python tools/equivalence.py test_scenarios/hr2_click_view_switch_test.json master` and `python tools/equivalence.py test_scenarios/e1_placement_exclusion_test.json master` report no difference; `python -m unittest tests.test_rr1_queen_builds` passes; `.\tools\verify.ps1` is green
   - Proof: `present: scripts/main.gd :: var pan_anchor`
   - Next after: CQ-R13

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] SE-2 -- measure specialist steering in the matched spring campaign**
   - Plan: `plans/now/specialist-ecology-evidence.md` -- "SE-2 -- measure specialist steering in the matched spring campaign"
   - Files: `test_scenarios/se2_specialist_spring.json`, `plans/reference/specialist-ecology-evidence.md`
   - Check: `python tools/seed_set_evidence.py specialists --fixture test_scenarios/se2_specialist_spring.json` completes twenty serial arms and writes both reports; `python tests/test_seed_set_evidence.py` passes; `python tools/check_docs.py` passes
   - Proof: `absent: plans/reference/specialist-ecology-evidence.md :: ## Measurements`
   - Next after: none -- specialist evidence complete; any later ecology question is outside this plan

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **CQ-M5b** (`plans/now/code-health.md`) -- the last CanvasLayer readers and the bare-layer source check; waits for the Claude lane's ED-1 and CQ-R15 to release `scripts/hud.gd` and CQ-R16 to release `scripts/main.gd`, and the Jules J-14 branch to settle `scripts/game_panel.gd`.
- **CQ-M4** (`plans/now/code-health.md`) -- name Challenge level ids; waits for the Claude lane to release `scripts/save_game.gd` and `scripts/saving.gd`.
- **RR-22** (`plans/now/run-repairs.md`) -- select a number of bees from a multi-selection; waits for the Codex lane's CQ-R6 to release `scripts/hud.gd`, which both name.
- **RR-12** (`plans/now/run-repairs.md`) -- a loaded run keeps its readout history (Dave, 16 Oct 2026); waits for ED-3, the last of the alpha chain, which shares `scripts/main.gd` and the save files.
- **SP-8a** (`plans/now/meadow-terrain.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); waits for ED-3, the last of the alpha chain (ED-1 to ED-3; WP-2 landed 21 Oct 2026, WP-3 landed 22 Oct 2026, SG-2 landed 26 Oct 2026), which shares `scripts/main.gd` and the save files (Dave, 16 Oct 2026).
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **ED-2** (`plans/now/difficulty.md`) -- a run's difficulty and Easy's rules; waits for ED-1.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2.
- **The event director** (`plans/design/product-scope.md` §6.2) -- needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-10 (`plans/now/pollination.md`, after EV-0), which shares `scripts/skills.gd`.
- **EV-0** (`plans/now/event-director.md`) -- one Calendar and events settings group, and winter a week later; waits for PN-11, which re-pins the first crisis to days 12-15 on `claude/dave-hands-on-checks-784f2a`.
- **PP-10** (`plans/now/pollination.md`) -- the sweep prices the route so Gyne rearing is first affordable after the first winter; waits for EV-0, so it prices the route once, on the new calendar (Dave, 1 Nov 2026).
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (ED-1, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026 and WP-3 landed 22 Oct 2026) and ED-3 (Dave, 18 Oct 2026); CQ-S0's round-trip harness landed 22 Oct 2026.
- **CQ-R2** (`plans/now/code-health.md`) -- the first crisis moves out of `scripts/main.gd` into a new first_crisis.gd, touching the save files; waits, gated with CQ-S1, for the save slices of the alpha chain (ED-1, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026) and ED-3 (Dave, 18 Oct 2026); its plan section is written when that gate clears.
- **CQ-R8** (`plans/now/code-health.md`) -- hud builders shortened and hud sections re-headed; waits for CQ-R15, which shares `scripts/hud.gd`.
- **CQ-R3** (`plans/now/code-health.md`) -- bee display text moves into a new bee_readout.gd; waits for SP-6 and ED-1 to release `scripts/bee.gd`.
- **CQ-T3** (`plans/now/code-health.md`) -- the UI scripts typed and the untyped warning made an error; needs its section and block after CQ-R8 (CQ-L2 released `tests/source_checks.py` 24 Oct 2026).
- **CQ-M6** (`plans/now/code-health.md`) -- selection green and caste appearance named; waits for the Claude lane's SP-6 and ED-1 to release `scripts/bee.gd` and CQ-R16 to release `scripts/input_selection.gd`.
- **CQ-M7** (`plans/now/code-health.md`) -- world draw order named; waits for CQ-M6 and then needs its section and block.
- **CQ-S2** (`plans/now/code-health.md`) -- HiveCell owns its save fields; waits for CQ-S1, which sets the `to_save()`/`from_save()` pattern and shares the save files.
- **FR-4** (`plans/now/forager-recruitment.md`) -- a headless assertion replaces the C-143 hands-on check; `scripts/scenario_actions.gd` was released 25 Oct 2026, but `tools/admission.py` reads C-143, the check it retires, as an unlanded slice, so its block stays `queue-gated` until admission ignores check ids.

## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
