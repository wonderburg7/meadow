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

1. **[Claude] RR-3 -- A new run from the menu gets its own default name**
   - Plan: `plans/now/run-repairs.md` -- "RR-3 -- a new run from the menu gets its own default name"
   - Files: `scripts/save_slots.gd`, `scripts/main.gd`, `tests/test_rr3_fresh_run_name.py`
   - Check: `python -m unittest tests.test_rr3_fresh_run_name` passes (the three naming cases above); `tools/verify.ps1` is green
   - Proof: `absent: scripts/save_slots.gd :: func fresh_run_name`
   - Next after: RR-4 -- The window cannot be made smaller than 800x600

2. **[Claude] RR-4 -- The window cannot be made smaller than 800x600**
   - Plan: `plans/now/run-repairs.md` -- "RR-4 -- the window cannot be made smaller than 800x600"
   - Files: `scripts/ui_layout.gd`, `scripts/main.gd`, `tests/test_rr4_min_window.py`
   - Check: `python -m unittest tests.test_rr4_min_window` passes; `tools/verify.ps1` is green
   - Proof: `absent: scripts/ui_layout.gd :: MIN_SUPPORTED_HEIGHT`
   - Next after: RR-5 -- Hexagon names re-fit when the typeface changes

3. **[Claude] RR-5 -- Hexagon names re-fit when the typeface changes**
   - Plan: `plans/now/run-repairs.md` -- "RR-5 -- hexagon names re-fit when the typeface changes"
   - Files: `scripts/main_menu.gd`, `tests/rr5_hex_refit_test.gd`, `tests/test_rr5_hex_refit.py`
   - Check: `python -m unittest tests.test_rr5_hex_refit` passes (switching Munro to OpenDyslexic at scale 2 refits every hexagon name); `tools/verify.ps1` is green
   - Proof: `present: scripts/main_menu.gd :: font.get_rid().get_id()`
   - Next after: none -- plan complete

4. **[Claude] SP-5 -- the skep in the meadow, and the rival hive as a recoloured skep**
   - Plan: `plans/now/sprites.md` -- "SP-5 -- the skep in the meadow, and the rival hive"
   - Files: `scripts/hive.gd`, `scripts/rival_hive.gd`, `assets/sprites/SPRITES.md`, `scripts/sprite_catalogue.gd`, `tests/test_sp5_skep.py`
   - Check: `python -m unittest tests.test_sp5_skep` passes and `python tools/sprites.py --check` is clean; `tools/verify.ps1` is green
   - Proof: `present: scripts/hive.gd :: extends Polygon2D`
   - Next after: SP-6 -- meadow foragers drawn from the sheet: eight directions, flapping wings

5. **[Claude] PP-2 -- points are spendable and shown, with a +1 at the flower**
   - Plan: `plans/now/pollination.md` -- "PP-2 -- points are spendable and shown, with a +1 at the flower"
   - Files: `scripts/skill_tree_panel.gd`, `scripts/hud.gd`, `scripts/pollination.gd`, `scripts/pollination_pop.gd`, `tests/test_pp2_points_spendable.py`, `test_scenarios/pp2_points_spendable.json`
   - Check: `python -m unittest tests.test_pp2_points_spendable` passes (a tier-4 skill is refused with too few points, bought once enough are earned, and the ledger loses exactly the recipe's points); the frame-time comparison is recorded in this section; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/skill_tree_panel.gd :: Skills.POLLINATOR_POINTS`
   - Next after: PP-4 -- seed set: pollinated flowers replant nearby and the meadow remembers through winter

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] PP-3 -- Gyne rearing gates gyne cells and Royal jelly gates jelly**
   - Plan: `plans/now/pollination.md` -- "PP-3 -- Gyne rearing gates gyne cells and Royal jelly gates jelly"
   - Files: `scripts/roles.gd`, `scripts/actions.gd`, `scripts/orders_zones.gd`, `scripts/run_availability.gd`, `tests/test_pp3_gyne_gate.py`, `test_scenarios/pp3_gyne_gate.json`
   - Check: `python -m unittest tests.test_pp3_gyne_gate` passes (in a Colony Run a gyne-cell request is refused until Gyne rearing is owned and accepted after; nurses make no jelly until Royal jelly is owned; a Scenario run owns both from the start and raises a gyne as today); `tools/verify.ps1` is green
   - Proof: `absent: scripts/roles.gd :: skill.brood.royal_jelly`
   - Next after: PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **FC-2** (`plans/now/crisis-readiness.md`) -- implement the accepted crisis and deterministic scenario; Dave accepted FC-1's option A and T2-4b has landed, so it waits for CD-3 (Codex backlog, admissible now that no Claude-lane slice holds `scripts/bee.gd`) to release `scripts/colony_diagnostics.gd`; RR-3 and RR-4 (Claude lane) hold `scripts/main.gd` and PP-2 `scripts/hud.gd` meanwhile (RR-2 landed 11 Oct 2026).
- **PP-5** (`plans/now/pollination.md`) -- Priority cells; waits for PP-3 (Codex lane) to release `scripts/orders_zones.gd`.
- **PP-6** (`plans/now/pollination.md`) -- the route's pricing sweep; waits for PP-2 to PP-5 (PP-1 landed 11 Oct 2026), and is specified when they land.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
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
