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

1. **[Claude] PP-5 -- Priority cells: marked brood cells are fed first**
   - Plan: `plans/now/pollination.md` -- "PP-5 -- Priority cells: marked brood cells are fed first"
   - Files: `scripts/bee_nursery.gd`, `scripts/hive_cell.gd`, `scripts/hud.gd`, `scripts/orders_zones.gd`, `scripts/main.gd`, `scripts/skills.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_pp5_priority_cells.py`, `test_scenarios/pp5_priority_cells.json`
   - Check: `python -m unittest tests.test_pp5_priority_cells` passes (with food for one larva, a nurse feeds the marked larva first for each food type; unowned, the mark cannot be set and feeding order is today's; the mark survives save and restore); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/hive_cell.gd :: priority_cell`
   - Next after: PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter

2. **[Claude] RR-1 -- The queen can build a cell in every run**
   - Plan: `plans/now/run-repairs.md` -- "RR-1 -- the queen can build a cell in every run"
   - Files: `scripts/challenge_runner.gd`, `scripts/hud.gd`, `scripts/input_selection.gd`, `scripts/orders_zones.gd`, `scripts/scenario_actions.gd`, `test_scenarios/rr1_queen_builds_test.json`, `tests/test_rr1_queen_builds.py`
   - Check: `python -m unittest tests.test_rr1_queen_builds` passes (a lone queen outside any Challenge is offered Build cell and builds one cell within two days); `tools/verify.ps1` is green
   - Proof: `absent: scripts/orders_zones.gd :: func queen_build_at`
   - Next after: none -- plan complete (RR-2 to RR-5 landed)

3. **[Claude] GP-1 -- The goals drop-down and the long-term line**
   - Plan: `plans/now/goal-presentation.md` -- "GP-1 -- the goals drop-down and the long-term line"
   - Files: `scripts/hud.gd`, `scripts/colony_milestones.gd`, `scripts/session.gd`, `scripts/player_profile.gd`, `tests/gp1_goals_dropdown_test.gd`, `tests/test_gp1_goals_dropdown.py`
   - Check: `python -m unittest tests.test_gp1_goals_dropdown` passes (in a Colony Run the shelf shows a Goals header, the long-term line for each phase and the next milestone; collapsed it shows the header alone and stays inside the viewport at the minimum width; the collapsed state survives a profile reload; a Challenge's shelf is unchanged); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/session.gd :: goals_collapsed`
   - Next after: GP-2 -- favourite goals stay on screen when the drop-down is collapsed

4. **[Claude] GP-2 -- Favourite goals stay on screen when the drop-down is collapsed**
   - Plan: `plans/now/goal-presentation.md` -- "GP-2 -- favourite goals"
   - Files: `scripts/hud.gd`, `scripts/colony_milestones.gd`, `tests/gp2_goal_favourites_test.gd`, `tests/test_gp2_goal_favourites.py`
   - Check: `python -m unittest tests.test_gp2_goal_favourites` passes (a starred line shows when collapsed; a met favourite shows struck through until the next day change, then drops and unstars; stars survive save and load; a save without them loads with none); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/colony_milestones.gd :: FAVOURITES`
   - Next after: GP-3 -- one short-term goal at a time, dismissable until it clears

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] CD-3 -- waiting and travel get a deterministic diagnostic boundary**
   - Plan: `plans/now/diagnostic-readiness.md` -- "CD-3 -- waiting and travel get a deterministic diagnostic boundary"
   - Files: `scripts/bee.gd`, `scripts/colony_diagnostics.gd`, `scripts/year_winter.gd`, `tests/test_colony_diagnostics.py`
   - Check: `python -m unittest tests.test_colony_diagnostics` passes with waiting, travelling and no-work fixtures; `tools/verify.ps1` is green
   - Proof: `present: scripts/year_winter.gd :: func _refresh_signals`
   - Next after: none -- diagnostic readiness is complete

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **FC-2** (`plans/now/crisis-readiness.md`) -- implement the accepted crisis and deterministic scenario; Dave accepted FC-1's option A and T2-4b has landed, so it waits for CD-3 (Codex backlog, admissible now that no Claude-lane slice holds `scripts/bee.gd`) to release `scripts/colony_diagnostics.gd`; PP-5 and RR-1 (Claude lane, queued 12 Oct 2026) hold `scripts/hud.gd` next (PP-2 landed 12 Oct 2026, RR-2 landed 11 Oct 2026, RR-3 and RR-4 landed 12 Oct 2026).
- **PP-6** (`plans/now/pollination.md`) -- the route's pricing sweep; waits for PP-5 (PP-1 to PP-4 landed 11-12 Oct 2026); its gated block is written.
- **SP-8a** (`plans/now/sprites.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); waits for CD-3 (Codex lane) to release `scripts/bee.gd` (PP-4 landed 12 Oct 2026, releasing `scripts/world_building.gd`, `scripts/flower.gd` and the save files).
- **SP-6** (`plans/now/sprites.md`) -- meadow foragers drawn from the sheet (eight directions, flapping wings); waits for Dave's repack of the forager sheet onto a 16x16 `sheet` grid, which the exporter needs, and is queued once it is committed (SP-5 landed 12 Oct 2026).
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **GP-3** (`plans/now/goal-presentation.md`) -- one short-term goal at a time; waits for GP-2 and for CD-3 (Codex lane) to release `scripts/year_winter.gd`; its gated block is written.
- **GP-4** (`plans/now/goal-presentation.md`) -- the problem strip stops blocking play; waits for GP-3 (Dave's order, 12 Oct 2026); its gated block is written.
- **The event director** (`plans/design/product-scope.md` §6.2) -- needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. Dr Gallerin guidance now has its plan, `plans/now/guidance-explanations.md`.
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
