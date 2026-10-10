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

1. **[Claude] BB-2 -- Nurses feed Bee Bread; a worker's outcome is fixed at emergence and saved**
   - Plan: `plans/now/bee-bread.md` -- "BB-2 -- Nurses feed Bee Bread; a worker's outcome is fixed at emergence and saved"
   - Files: `scripts/bee_nursery.gd`, `scripts/hive_cell.gd`, `scripts/bee.gd`, `scripts/bee_survival.gd`, `scripts/bee_foraging.gd`, `scripts/world_building.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/hud.gd`, `tests/test_bb2_bee_bread_nursing.py`, `test_scenarios/bb2_bee_bread_nursing.json`
   - Check: `python -m unittest tests.test_bb2_bee_bread_nursing` passes (a larva fed Bee Bread emerges with the 25-day, 105% outcome and one fed only pollen with the 15-day, 95% one; the outcome survives save and restore; a pre-BB-2 save loads its adults unchanged); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/game_config.gd :: brood_feed_bee_bread`
   - Next after: BB-3 -- Bee Bread is spendable on tier-3 recipes, from the cells that hold it

2. **[Claude] BB-3 -- Bee Bread is spendable on tier-3 recipes, from the cells that hold it**
   - Plan: `plans/now/bee-bread.md` -- "BB-3 -- Bee Bread is spendable on tier-3 recipes, from the cells that hold it"
   - Files: `scripts/skill_tree_panel.gd`, `tests/test_bb3_bee_bread_currency.py`, `test_scenarios/bb3_bee_bread_currency.json`
   - Check: `python -m unittest tests.test_bb3_bee_bread_currency` passes (a Bee Bread-priced skill is refused while the colony's only Bee Bread is unripe, is bought once it ripens, and the ripe cell loses exactly the recipe's Bee Bread); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/skill_tree_panel.gd :: Skills.BEE_BREAD`
   - Next after: BB-4 -- Challenges 1 and 2 and the Colony Run re-paced for 15-day unfed workers

3. **[Claude] NF-4 -- the detection skill: bees avoid fermented nectar, and honey makers take the oldest first**
   - Plan: `plans/now/nectar-fermentation.md` -- "NF-4 -- the detection skill: bees avoid fermented nectar, and honey makers take the oldest first"
   - Files: `scripts/skills.gd`, `scripts/hive.gd`, `scripts/bee_honey.gd`, `scripts/bee_survival.gd`, `scripts/bee_nursery.gd`, `scripts/bee_building.gd`, `plans/design/progression.md`, `tests/test_nf4_fermentation_sense.py`, `test_scenarios/nf4_fermentation_sense.json`
   - Check: `python -m unittest tests.test_nf4_fermentation_sense` passes (with the skill no bee goes tipsy while fresh food is left, nurses and restock orders never take from a fermented cell, and honey makers take the oldest nectar first; without it nurses and restock orders still take fermented nectar and honey makers take the closest); `tools/verify.ps1` is green
   - Proof: `absent: scripts/skills.gd :: skill.colony.fermentation_sense`
   - Next after: none -- nectar fermentation is complete

4. **[Claude] SP-2 -- the sprite exporter, the sprite table and the generated catalogue**
   - Plan: `plans/now/sprites.md` -- "SP-2 -- the sprite exporter, the sprite table and the generated catalogue"
   - Files: `tools/sprites.py`, `tests/test_sp2_sprites.py`, `assets/sprites/SPRITES.md`, `assets/sprites/comb/wax_cell_nectar.aseprite`, `assets/sprites/comb/wax_cell_pollen.aseprite`, `assets/sprites/meadow/hive_skep.png`, `assets/sprites/meadow/grass_base.png`, `assets/sprites/bees/bee_forager_meadow.aseprite`, `assets/sprites/environment/wax.cell.empty.png`, `scripts/sprite_catalogue.gd`, `scripts/hive_cell.gd`, `tools/verify.ps1`
   - Check: `python -m unittest tests.test_sp2_sprites` passes and `python tools/sprites.py --check` is clean; `tools/verify.ps1` is green
   - Proof: `present: scripts/hive_cell.gd :: const EMPTY_TEXTURE :=`
   - Next after: SP-4 -- nectar and pollen fill levels drawn from the sprites

5. **[Claude] T2-7 -- Tier-2 costs tuned so the first purchase lands around day 5**
   - Plan: `plans/now/tier-two.md` -- "T2-7 -- Tier-2 costs tuned so the first purchase lands around day 5"
   - Files: `scripts/skills.gd`, `scripts/progression.gd`, `scripts/diagnostic_log.gd`, `tools/analyze_session.py`, `tools/pacing_gates.py`, `plans/design/progression.md`, `tests/test_t2_7_tier_two_prices.py`
   - Check: `python -m unittest tests.test_t2_7_tier_two_prices` passes (a snapshot whose stores cover the cheapest first-tier-2 path sets `first_tier2_day`, one that falls short by one unit of any resource does not, and pacing_gates prints the row against day 5 without changing the five gate rows); `python tools/pacing_gates.py` shows the median `first_tier2_day` in band, recorded before and after in the plan; `tools/verify.ps1` is green
   - Proof: `absent: tools/analyze_session.py :: first_tier2_day`
   - Next after: T2-6 -- Associative learning

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] GD-2a -- the guidance policy, the first two explanations and the Why list**
   - Plan: `plans/now/guidance-explanations.md` -- "GD-2a -- the guidance policy, the first two explanations and the Why list"
   - Files: `scripts/guidance_policy.gd`, `scripts/guidance_catalogue.gd`, `scripts/gallerin_panel.gd`, `scripts/year_winter.gd`, `tests/test_gd2a_guidance.py`, `test_scenarios/gd2a_guidance.json`
   - Check: `python -m unittest tests.test_gd2a_guidance` passes (a colony with brood and no nurse gets the missing-nurse explanation once, only after it renders; it stays eligible while a Challenge prompt is due; the Why list holds it after the fact clears; a warning without a CD-2 fact starts nothing); `tools/verify.ps1` is green
   - Proof: `absent: scripts/gallerin_panel.gd :: guidance_policy`
   - Next after: GD-2b -- the shown ledger and Why history saved with the run

2. **[Codex] PP-3 -- Gyne rearing gates gyne cells and Royal jelly gates jelly**
   - Plan: `plans/now/pollination.md` -- "PP-3 -- Gyne rearing gates gyne cells and Royal jelly gates jelly"
   - Files: `scripts/roles.gd`, `scripts/actions.gd`, `scripts/orders_zones.gd`, `scripts/run_availability.gd`, `tests/test_pp3_gyne_gate.py`, `test_scenarios/pp3_gyne_gate.json`
   - Check: `python -m unittest tests.test_pp3_gyne_gate` passes (in a Colony Run a gyne-cell request is refused until Gyne rearing is owned and accepted after; nurses make no jelly until Royal jelly is owned; a Scenario run owns both from the start and raises a gyne as today); `tools/verify.ps1` is green
   - Proof: `absent: scripts/roles.gd :: skill.brood.royal_jelly`
   - Next after: PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation, Bee Bread and the gyne route.
- **CD-3** (`plans/now/diagnostic-readiness.md`) -- waiting and travel get a deterministic diagnostic boundary; waits for BB-2, queued in the Claude lane, to release `scripts/bee.gd` (BB-1, NF-3 and SP-3 landed 9 Oct 2026).
- **GD-2b** (`plans/now/guidance-explanations.md`) -- the shown ledger and Why history saved with the run; waits for GD-2a, and for the save files to be free of Claude-lane slices (BB-2 now; PP-1, PP-4 and PP-5 later).
- **FC-2** (`plans/now/crisis-readiness.md`) -- implement the accepted crisis and deterministic scenario; Dave accepted FC-1's option A and T2-4b has landed, so it waits for BB-2 (Claude lane) to release the save and HUD files and for CD-3 to release diagnostics (BB-1, NF-3 and NF-5 landed 9 Oct 2026).
- **T2-6** (`plans/now/tier-two.md`) -- Associative learning, specified with Dave's 10 Oct 2026 decisions; admissible, and waits only for room in the Claude lane behind T2-7.
- **PP-1** (`plans/now/pollination.md`) -- bees earn Pollinator Points; admissible, and waits for room in the Claude lane behind T2-6, which it needs owned.
- **PP-2 and PP-4** (`plans/now/pollination.md`) -- Pollinator Points made spendable, and seed set; wait for PP-1's ledger (`scripts/pollination.gd`).
- **PP-5** (`plans/now/pollination.md`) -- Priority cells; waits for PP-3 (Codex lane) to release `scripts/orders_zones.gd`.
- **PP-6** (`plans/now/pollination.md`) -- the route's pricing sweep; waits for PP-1 to PP-5 and T2-7, and is specified when they land.
- **BB-4** (`plans/now/bee-bread.md`) -- Challenges 1 and 2 and the Colony Run re-paced for 15-day unfed workers; waits for BB-2, queued in the Claude lane, and is specified when it lands (BB-1 landed 9 Oct 2026; BB-2 and BB-3 are queued).
- **The event director** (`plans/design/product-scope.md` §6.2) -- needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. Dr Gallerin guidance now has its plan, `plans/now/guidance-explanations.md`.
- **SP-4** (`plans/now/sprites.md`) -- nectar and pollen fill levels drawn from the sprites; waits for SP-2, queued in the Claude lane, and gets its block when it lands (SP-3 landed 9 Oct 2026).
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
