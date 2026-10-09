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

1. **[Claude] BB-1 -- Fermenters make Bee Bread in a store cell**
   - Plan: `plans/now/bee-bread.md` -- "BB-1 -- Fermenters make Bee Bread in a store cell"
   - Files: `scripts/resources.gd`, `scripts/hive_cell.gd`, `scripts/hive.gd`, `scripts/roles.gd`, `scripts/bee.gd`, `scripts/bee_enums.gd`, `scripts/bee_honey.gd`, `scripts/actions.gd`, `scripts/skills.gd`, `scripts/availability.gd`, `scripts/hud.gd`, `scripts/orders_zones.gd`, `scripts/diagnostic_log.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_bb1_bee_bread.py`, `test_scenarios/bb1_bee_bread.json`
   - Check: `python -m unittest tests.test_bb1_bee_bread` passes (Fermenting honey workers fill a Bee Bread cell, it seals, ripens only after `bee_bread_ripen_hours`, no adult eats it, and the cell and the bees' mode survive save and restore); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/game_config.gd :: bee_bread_ripen_hours`
   - Next after: BB-2 -- Nurses feed Bee Bread; a worker's outcome is fixed at emergence and saved

2. **[Claude] NF-5 -- clear fermented cells**
   - Plan: `plans/now/nectar-fermentation.md` -- "NF-5 -- clear fermented cells"
   - Files: `scripts/bee_building.gd`, `scripts/orders_zones.gd`, `scripts/hud.gd`, `scripts/main.gd`, `scripts/scenario_actions.gd`, `tests/test_nf5_clear_fermented.py`, `test_scenarios/nf5_clear_fermented.json`
   - Check: `python -m unittest tests.test_nf5_clear_fermented` passes (the order marks exactly the fermented cells, comb workers carry them out, the marks survive save and restore, a fresh cell is untouched, and moving a fermented cell puts nothing into another cell); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/orders_zones.gd :: is_fermented`
   - Next after: NF-4 -- the detection skill: bees avoid fermented nectar, and honey makers take the oldest first

3. **[Claude] SP-1 -- crisp pixels on the comb cell**
   - Plan: `plans/now/sprites.md` -- "SP-1 -- crisp pixels on the comb cell"
   - Files: `assets/shaders/pixel_sharp.gdshader`, `scripts/pixel_sprite.gd`, `scripts/hive_cell.gd`, `tests/sp1_pixel_sprite_test.gd`, `tests/test_sp1_pixel_sprite.py`
   - Check: `python -m unittest tests.test_sp1_pixel_sprite` passes (an empty HiveCell's sprite carries PixelSprite's shared material, linear filtering and the hive pixel scale); `tools/verify.ps1` is green
   - Proof: `absent: scripts/hive_cell.gd :: PixelSprite`
   - Next after: SP-2 -- the sprite exporter, the sprite table and the generated catalogue

4. **[Claude] SP-3 -- cell colours follow the new sprites**
   - Plan: `plans/now/sprites.md` -- "SP-3 -- cell colours follow the new sprites"
   - Files: `scripts/hive_cell.gd`, `scripts/bee.gd`, `tests/test_sp3_content_colours.py`
   - Check: `python -m unittest tests.test_sp3_content_colours` passes (nectar and pollen equal the sprite fills, and every pair of cell-content colours is at least 0.10 apart in OKLab); `tools/verify.ps1` is green
   - Proof: `present: scripts/hive_cell.gd :: const NECTAR_COLOR := Color(0.747, 0.834, 0.8525)`
   - Next after: SP-4 -- nectar and pollen fill levels drawn from the sprites

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] WC-2 -- a dry-lane warning names the missing deferral and the specified blocks that could serve the lane**
   - Plan: `plans/now/workflow-checks.md` -- "WC-2 -- a dry-lane warning names the missing deferral and the specified blocks that could serve the lane"
   - Files: `tools/refill_lane.py`, `tools/check_docs.py`, `tests/test_wc2_dry_lane_report.py`
   - Check: `python -m unittest tests.test_wc2_dry_lane_report` passes (an undeferred successor is named; a file-disjoint low/medium other-lane block is listed as borrowable; a high-level, gated, colliding or already-queued one is not; the existing keys are unchanged); `python -m unittest tests.test_slice_lifecycle` passes; `tools/verify.ps1` is green
   - Proof: `absent: tools/refill_lane.py :: borrowable`
   - Next after: WC-4 -- a queue id with whitespace fails the documentation check

2. **[Codex] WC-4 -- a queue id with whitespace fails the documentation check**
   - Plan: `plans/now/workflow-checks.md` -- "WC-4 -- a queue id with whitespace fails the documentation check"
   - Files: `tools/check_docs.py`, `tests/test_wc4_spaced_ids.py`
   - Check: `python -m unittest tests.test_wc4_spaced_ids` passes; `python tools/check_docs.py` passes on master; `tools/verify.ps1` is green
   - Proof: `absent: tools/check_docs.py :: id contains whitespace`
   - Next after: none -- workflow checks are complete

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation, Bee Bread and the gyne route.
- **CD-3** (`plans/now/diagnostic-readiness.md`) -- waiting and travel get a deterministic diagnostic boundary; waits for BB-1, queued in the Claude lane, to release `scripts/bee.gd` (NF-3 landed 9 Oct 2026).
- **GD-2** (`plans/now/guidance-explanations.md`) -- implement the accepted persistent entry point and first explanations; waits for Dave's GD-1 decision.
- **FC-2** (`plans/now/crisis-readiness.md`) -- implement the accepted crisis and deterministic scenario; Dave accepted FC-1's option A and T2-4b has landed, so it waits for BB-1 and NF-5 (Claude lane) to release the save, HUD and scenario files and for CD-3 to release diagnostics (NF-3 landed 9 Oct 2026).
- **T2-6 and T2-7** (`plans/now/tier-two.md`) -- the rest of progression step 8: T2-6 (Associative learning) is specified and fenced `queue-gated`, and waits for Dave's decision on its familiarity rates, handling-speed cap and old-save default; T2-7 (tier-2 prices) is still to be specified, and T2-6's block names it next. T2-8b and T2-4b (bodies) landed 9 Oct 2026.
- **BB-2 to BB-4** (`plans/now/bee-bread.md`) -- the rest of Bee Bread; BB-2 and BB-3 wait for BB-1, queued in the Claude lane, and BB-4 for BB-2.
- **NF-4** (`plans/now/nectar-fermentation.md`) -- the detection skill: bees avoid fermented nectar, and honey makers take the oldest first; outlined and fenced `queue-gated` now that NF-3 has landed (9 Oct 2026); waits for Dave's answers on whether nurses may carry fermented nectar to brood and whether Restocking may draw from a fermented cell (the plan's "Still open").
- **Dr Gallerin guidance and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. Gallerin guidance is the next design pass, now that step 8's ran on 6-7 Oct 2026 (booked by Dave, 5 Oct 2026); the event director's wait on the Colony Run's year (COL-4, COL-6) has cleared; it still needs its design pass. The four goal layers now belong to the Colony Run definition (Dave, 30 Sep 2026; `plans/archive/colony-run_2026-10-08.md`).
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
