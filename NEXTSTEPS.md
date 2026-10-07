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

1. **[Claude] COL-11 -- nuptial flights: an unmated queen can leave each day to find a mate**
   - Plan: `plans/now/colony-run.md` -- "COL-11 -- nuptial flights: an unmated queen can leave each day to find a mate"
   - Files: `scripts/season.gd`, `scripts/bee.gd`, `scripts/succession_panel.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_col11_nuptial_flight.py`, `tests/col11_nuptial_flight_test.gd`
   - Check: `python -m unittest tests.test_col11_nuptial_flight` passes (no mating where the curve is 0; a queen flying in mid summer mates within the test's days and then lays worker brood); `python tools/pacing_gates.py` before and after is recorded in this plan; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `absent: scripts/game_config.gd :: nuptial_flight_peak_chance`
   - Next after: COL-7 -- the mating window, genetic points and COL-2's narrower win

2. **[Claude] COL-12 -- the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns**
   - Plan: `plans/now/colony-run.md` -- "COL-12 -- the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns"
   - Files: `scripts/main.gd`, `scripts/world_building.gd`, `tests/test_sf1_founding_flower_mix.py`, `test_scenarios/sf1_founding_flower_mix_test.json`
   - Check: `python -m unittest tests.test_sf1_founding_flower_mix` passes at 0.05 on the pinned seed and three others; `python tools/pacing_gates.py` before and after is recorded here; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `present: tests/test_sf1_founding_flower_mix.py :: assertLessEqual(abs(initial_share - final_share), 0.20)`
   - Next after: COL-7 -- the mating window, genetic points and COL-2's narrower win

3. **[Claude] SI-1 -- disease, crab-spider species and the rival colony survive a load**
   - Plan: `plans/now/save-integrity.md` -- "SI-1 -- disease, crab-spider species and the rival colony survive a load"
   - Files: `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/rival_hive.gd`, `scripts/main.gd`, `tests/si1_run_state_test.gd`, `tests/test_si1_run_state.py`
   - Check: `python -m unittest tests.test_si1_run_state` passes with `SI1 PASS`; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/save_game.gd :: crab_spider_species`
   - Next after: SI-2 -- a checkpoint restore puts back soil dug since the checkpoint

4. **[Claude] SI-2 -- a checkpoint restore puts back soil dug since the checkpoint**
   - Plan: `plans/now/save-integrity.md` -- "SI-2 -- a checkpoint restore puts back soil dug since the checkpoint"
   - Files: `scripts/saving.gd`, `tests/si2_exact_rollback_test.gd`, `tests/test_si2_exact_rollback.py`
   - Check: `python -m unittest tests.test_si2_exact_rollback` passes with `SI2 PASS`; `python tools/run_scenario.py test_scenarios/sv1_named_saves_test.json` passes; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/saving.gd :: _add_soil_block`
   - Next after: SI-3 -- save, checkpoint and index writes are all-or-nothing

5. **[Claude] COL-13 -- the pacing arc sees a skipped winter**
   - Plan: `plans/now/colony-run.md` -- "COL-13 -- the pacing arc sees a skipped winter"
   - Files: `tools/analyze_session.py`, `tests/test_col13_skipped_winter_arc.py`
   - Check: `python -m unittest tests.test_col13_skipped_winter_arc` passes (a log whose clock jumps by winter's length dates winter entered and survived either side of the jump; a played-winter fixture reads as before); `python tools/pacing_gates.py` shows both winter rows in band; `tools/verify.ps1` is green
   - Proof: `absent: tools/analyze_session.py :: skipped winter`
   - Next after: COL-12 -- the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] AR-3 -- the pacing report presents every alpha gate and its evidence boundary**
   - Plan: `plans/now/alpha-route-evidence.md` -- "AR-3 -- the pacing report presents every alpha gate and its evidence boundary"
   - Files: `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
   - Check: `python -m unittest tests.test_pacing_gates` passes with five named alpha-gate rows, and missing crisis or gyne facts render as unavailable rather than in-band
   - Proof: `present: tools/pacing_gates.py :: Not instrumented: 20m forage/weather crisis; 90m gyne release.`
   - Next after: AR-4 -- a scripted Colony Run reaches and records all five gates

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **COL-7** (`plans/now/colony-run.md`) -- the mating window, genetic points and COL-2's narrower win wait for COL-6, and are specified once it lands.
- **NF-2** (`plans/now/nectar-fermentation.md`) -- nectar ferments past an age; waits for COL-4 (Codex lane), which edits `scripts/game_config.gd` and `scripts/settings_catalogue.gd`, and for NF-1's evidence.
- **T2-4a to T2-8** (`plans/now/tier-two.md`) -- the rest of progression step 8: T2-4a is specified and waits only for room in the lane (T2-2 landed 7 Oct 2026); T2-4b (bodies) for T2-4a, COL-4 and COL-6; T2-5 (rain) and T2-7 (tier-2 prices) for COL-4's year; T2-6 (Associative learning) for COL-4 (`game_config.gd`); T2-8 (Shiver Cluster) for COL-6.
- **BB-1 to BB-4** (`plans/now/bee-bread.md`) -- Bee Bread; BB-1 waits for COL-4 and NF-2 (`game_config.gd`, `hive_cell.gd`, `hive.gd`, the save files); the rest follow BB-1.
- **Dr Gallerin guidance and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. Gallerin guidance is the next design pass, now that step 8's ran on 6-7 Oct 2026 (booked by Dave, 5 Oct 2026); the event director waits for the Colony Run's year and difficulty (COL-4, COL-6). The four goal layers now belong to the Colony Run definition (Dave, 30 Sep 2026; `plans/now/colony-run.md`).
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
