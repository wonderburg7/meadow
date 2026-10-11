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

1. **[Claude] T2-6 -- Associative learning**
   - Plan: `plans/now/tier-two.md` -- "T2-6 -- Associative learning"
   - Files: `scripts/skills.gd`, `scripts/bee_foraging.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_t2_6_associative_learning.py`, `tests/t2_6_associative_learning_test.gd`
   - Check: `python -m unittest tests.test_t2_6_associative_learning` passes (with the toggle off, a bee's handling time and experience stay unchanged until Associative learning is bought; once owned, ten visits to one species bring its handling to 0.75 of a first-timer's, and fifteen visits to another species then erase that experience; experience survives save and restore); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/bee_foraging.gd :: static func handling_experience_on`
   - Next after: PP-1 -- bees earn Pollinator Points and Contribution

2. **[Claude] BB-4 -- Challenges 1 and 2 and the Colony Run re-paced for 15-day unfed workers**
   - Plan: `plans/now/bee-bread.md` -- "BB-4 -- Challenges 1 and 2 and the Colony Run re-paced for 15-day unfed workers"
   - Files: `scripts/challenge_stages.gd`, `docs/challenge-stages.md`, `scripts/scenario_actions.gd`, `test_scenarios/bb4_challenge1_route.json`, `test_scenarios/bb4_challenge2_route.json`, `tests/test_bb4_challenge_pacing.py`
   - Check: `python -m unittest tests.test_bb4_challenge_pacing` passes (each route, run once on its pinned seed, reaches its Challenge's completion under BB-2's rule with no stage jumped after its start, and the test reads the thresholds from `scripts/challenge_stages.gd` rather than restating them); the three-seed reach days under the rule and with both pollen-raised factors at 1.0, and `python tools/pacing_gates.py`'s five rows, are recorded in the plan; `python tools/stage_reference.py --check` is clean; `.\tools\verify.ps1` is green
   - Proof: `present: scripts/challenge_stages.gd :: the rescue threshold -- first guesses`
   - Next after: none -- Bee Bread is complete

3. **[Claude] PP-1 -- bees earn Pollinator Points and Contribution**
   - Plan: `plans/now/pollination.md` -- "PP-1 -- bees earn Pollinator Points and Contribution"
   - Files: `scripts/pollination.gd`, `scripts/main.gd`, `scripts/bee.gd`, `scripts/bee_foraging.gd`, `scripts/flower.gd`, `scripts/skills.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/debug_panel.gd`, `tests/test_pp1_pollination_ledger.py`, `test_scenarios/pp1_pollination_ledger.json`
   - Check: `python -m unittest tests.test_pp1_pollination_ledger` passes (two same-species flowers in one trip earn one point only once Pollinator points is owned and not again from that flower until it has refilled; a trip's first flower earns nothing; arriving from another species counts one incompatible delivery; Contribution rises whether or not the skill is owned; the counters and flower counts survive save and restore); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/flower.gd :: compatible_visits`
   - Next after: PP-2 -- points are spendable and shown, with a +1 at the flower

4. **[Claude] SP-4 -- nectar and pollen fill levels drawn from the sprites**
   - Plan: `plans/now/sprites.md` -- "SP-4 -- nectar and pollen fill levels drawn from the sprites"
   - Files: `scripts/hive_cell.gd`, `scripts/settings_catalogue.gd`, `assets/sprites/SPRITES.md`, `scripts/sprite_catalogue.gd`, `tests/test_sp4_fill_sprites.py`
   - Check: `python -m unittest tests.test_sp4_fill_sprites` passes and `python tools/sprites.py --check` is clean; `tools/verify.ps1` is green
   - Proof: `present: scripts/hive_cell.gd :: const NECTAR_COLOR :=`
   - Next after: SP-5 -- the skep in the meadow, and the rival hive as a recoloured skep

5. **[Claude] RR-2 -- "Saves..." works on the main menu at boot**
   - Plan: `plans/now/run-repairs.md` -- "RR-2 -- \"Saves...\" works on the main menu at boot"
   - Files: `scripts/main.gd`, `scripts/hud.gd`, `scripts/saves_panel.gd`, `scripts/debug_panel.gd`, `tests/rr2_boot_saves_test.gd`, `tests/test_rr2_boot_saves.py`
   - Check: `python -m unittest tests.test_rr2_boot_saves` passes (on a fresh boot the menu's Saves... opens the Saves window with no script error); `tools/verify.ps1` is green
   - Proof: `absent: scripts/main.gd :: SavesPanel`
   - Next after: RR-3 -- A new run from the menu gets its own default name

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

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation, Bee Bread and the gyne route.
- **GD-2b** (`plans/now/guidance-explanations.md`) -- the shown ledger and Why history saved with the run; GD-2a landed 10 Oct 2026, so it waits only for the save files to be free of Claude-lane slices: PP-1 (Claude lane, fifth) holds them now, and PP-4 and PP-5 hold them later.
- **FC-2** (`plans/now/crisis-readiness.md`) -- implement the accepted crisis and deterministic scenario; Dave accepted FC-1's option A and T2-4b has landed, so it waits for CD-3 (Codex backlog; it needs `scripts/bee.gd`, which PP-1 in the Claude lane holds) to release `scripts/colony_diagnostics.gd`, and for PP-1 (Claude lane, fifth) to release `scripts/main.gd` and the save files; `scripts/hud.gd` is free since 10 Oct 2026.
- **PP-2 and PP-4** (`plans/now/pollination.md`) -- Pollinator Points made spendable, and seed set; wait for PP-1's ledger (`scripts/pollination.gd`).
- **PP-5** (`plans/now/pollination.md`) -- Priority cells; waits for PP-3 (Codex lane) to release `scripts/orders_zones.gd`.
- **PP-6** (`plans/now/pollination.md`) -- the route's pricing sweep; waits for PP-1 to PP-5, and is specified when they land.
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
