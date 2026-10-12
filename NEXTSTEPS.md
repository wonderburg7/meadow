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

1. **[Claude] PP-4 -- seed set: pollinated flowers replant nearby and the meadow remembers through winter**
   - Plan: `plans/now/pollination.md` -- "PP-4 -- seed set: pollinated flowers replant nearby and the meadow remembers through winter"
   - Files: `scripts/flower.gd`, `scripts/world_building.gd`, `scripts/flower_species.gd`, `scripts/pollination.gd`, `scripts/levels.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_pp4_seed_set.py`, `test_scenarios/pp4_seed_set.json`
   - Check: `python -m unittest tests.test_pp4_seed_set` passes (a flower that set seed is replaced by its species nearby; one that did not is replaced by the seasonal draw; spring regrowth favours the species that set seed without losing any species; a Challenge replants as today; seed counts survive save and restore); the species-share table is recorded in this section; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/levels.gd :: seed_set`
   - Next after: PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter

2. **[Claude] SP-9 -- hive soil blocks drawn from Dave's art, crumbling as they are mined**
   - Plan: `plans/now/sprites.md` -- "SP-9 -- hive soil blocks drawn from Dave's art, crumbling as they are mined"
   - Files: `scripts/soil_block.gd`, `tests/test_sp9_soil_art.py`
   - Check: `python -m unittest tests.test_sp9_soil_art` passes; `tools/verify.ps1` is green
   - Proof: `absent: scripts/soil_block.gd :: SpriteCatalogue`
   - Next after: SP-6 -- meadow foragers drawn from the sheet: eight directions, flapping wings

3. **[Claude] T2-9 -- A skill not available in this run never blocks the tier above it**
   - Plan: `plans/now/tier-two.md` -- "T2-9 -- A skill not available in this run never blocks the tier above it"
   - Files: `scripts/progression.gd`, `plans/design/progression.md`, `test_scenarios/t2_9_c2_comb_worker_test.json`, `tests/test_t2_9_unavailable_tier.py`
   - Check: `python -m unittest tests.test_t2_9_unavailable_tier` passes (Challenge 2 buys Comb worker at 2.7 and Miner at 2.8 while Cell capacity stays unavailable); `tools/verify.ps1` is green
   - Proof: `absent: scripts/progression.gd :: _offered_in_run`
   - Next after: T2-7b -- the deferred tier-2 price sweep; waits for AR-4 and is specified when it lands

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
- **FC-2** (`plans/now/crisis-readiness.md`) -- implement the accepted crisis and deterministic scenario; Dave accepted FC-1's option A and T2-4b has landed, so it waits for CD-3 (Codex backlog, admissible now that no Claude-lane slice holds `scripts/bee.gd`) to release `scripts/colony_diagnostics.gd`; PP-2 (Claude lane) holds `scripts/hud.gd` meanwhile (RR-2 landed 11 Oct 2026, RR-3 and RR-4 landed 12 Oct 2026).
- **RR-1** (`plans/now/run-repairs.md`) -- the queen can build a cell in every run; waits for PP-3 (Codex lane) to release `scripts/orders_zones.gd`.
- **PP-5** (`plans/now/pollination.md`) -- Priority cells; waits for PP-3 (Codex lane) to release `scripts/orders_zones.gd`.
- **PP-6** (`plans/now/pollination.md`) -- the route's pricing sweep; waits for PP-2 to PP-5 (PP-1 landed 11 Oct 2026), and is specified when they land.
- **SP-8a** (`plans/now/sprites.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); waits for PP-4 (Claude lane) to release `scripts/world_building.gd`, `scripts/flower.gd`, `scripts/save_game.gd` and `scripts/saving.gd`. It shares `scripts/input_selection.gd` with RR-1, so whichever is queued second waits, and once queued it holds `scripts/bee.gd`, which CD-3 (Codex) needs free.
- **SP-6** (`plans/now/sprites.md`) -- meadow foragers drawn from the sheet (eight directions, flapping wings); waits for Dave's repack of the forager sheet onto a 16x16 `sheet` grid, which the exporter needs, and is queued once it is committed (SP-5 landed 12 Oct 2026).
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
