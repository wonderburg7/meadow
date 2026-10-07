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

1. **[Claude] SPR-2 -- the windowed render baseline at 500 and 1,000 bees**
   - Plan: `plans/now/render-scale.md` -- "SPR-2 -- the windowed render baseline at 500 and 1,000 bees"
   - Files: `test_scenarios/spr2_render_500.json`, `test_scenarios/spr2_render_1000.json`, `docs/performance.md`
   - Check: `python tools/run_scenario.py test_scenarios/spr2_render_1000.json --windowed --report full` exits 0 with a draw-call mean above 0; `docs/performance.md` holds the table for 200, 500 and 1,000 bees; `python tools/check_docs.py` passes
   - Proof: `absent: docs/performance.md :: SPR-2`
   - Next after: none -- plans/now/render-scale.md is complete once SPR-2 lands; whether a sprite or batching pass follows is decided with Dave from the table

2. **[Claude] COL-6 -- winter is skipped and resolved in one step**
   - Plan: `plans/now/colony-run.md` -- "COL-6 -- winter is skipped and resolved in one step"
   - Files: `scripts/season.gd`, `scripts/year_winter.gd`, `tests/test_col6_winter_skip.py`, `test_scenarios/col6_winter_skip_test.json`, `tools/verify.ps1`
   - Check: `python -m unittest tests.test_col6_winter_skip` passes (a stocked colony crosses winter in one tick with nobody lost and the day advanced by winter's length; an under-stocked one loses its oldest workers first and keeps its queen); `python tools/pacing_gates.py` before and after is recorded here; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `absent: scripts/season.gd :: winter_bill`
   - Next after: COL-7 -- the mating window, genetic points and COL-2's narrower win

3. **[Claude] COL-11 -- nuptial flights: an unmated queen can leave each day to find a mate**
   - Plan: `plans/now/colony-run.md` -- "COL-11 -- nuptial flights: an unmated queen can leave each day to find a mate"
   - Files: `scripts/season.gd`, `scripts/bee.gd`, `scripts/succession_panel.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_col11_nuptial_flight.py`, `tests/col11_nuptial_flight_test.gd`, `tools/verify.ps1`
   - Check: `python -m unittest tests.test_col11_nuptial_flight` passes (no mating where the curve is 0; a queen flying in mid summer mates within the test's days and then lays worker brood); `python tools/pacing_gates.py` before and after is recorded in this plan; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `absent: scripts/game_config.gd :: nuptial_flight_peak_chance`
   - Next after: COL-7 -- the mating window, genetic points and COL-2's narrower win

4. **[Claude] COL-12 -- the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns**
   - Plan: `plans/now/colony-run.md` -- "COL-12 -- the meadow reseeds as fast as it dies, and SF-1's 0.05 check returns"
   - Files: `scripts/main.gd`, `scripts/world_building.gd`, `tests/test_sf1_founding_flower_mix.py`, `test_scenarios/sf1_founding_flower_mix_test.json`
   - Check: `python -m unittest tests.test_sf1_founding_flower_mix` passes at 0.05 on the pinned seed and three others; `python tools/pacing_gates.py` before and after is recorded here; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `present: tests/test_sf1_founding_flower_mix.py :: assertLessEqual(abs(initial_share - final_share), 0.20)`
   - Next after: COL-7 -- the mating window, genetic points and COL-2's narrower win

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] L-20 -- make Codex's closeout directions agree with what `finish` does**
   - Plan: `plans/now/codex-guidance.md` -- "L-20 -- make Codex's closeout directions agree with what `finish` does"
   - Files: `CHATGPT.md`
   - Check: `python tools/check_docs.py` passes, and `CHATGPT.md` says `finish` performs archive and refill rather than ordering them before `finish`
   - Proof: `present: CHATGPT.md :: run both, for your own lane only, **before** running`
   - Next after: none -- L-20 completes this plan

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **COL-7** (`plans/now/colony-run.md`) -- the mating window, genetic points and COL-2's narrower win wait for COL-6, and are specified once it lands.
- **NF-2** (`plans/now/nectar-fermentation.md`) -- nectar ferments past an age; waits for COL-4 (Codex lane), which edits `scripts/game_config.gd` and `scripts/settings_catalogue.gd`, and for NF-1's evidence.
- **Progression Phase B step 8 onwards, and Phase C** (`plans/design/progression.md`) -- step 8 and Shiver Cluster (`plans/now/colony-run.md` decision 9) wait for a design session with Dave, booked as the next planning pass (Dave, 5 Oct 2026): only Nurses and Honey worker are skill-gated today, gating Comb worker meets colony-run decision 2's queen building the first cell, and decisions 9 and 11 disagree on whether a colony can survive winter without Shiver Cluster. Shiver Cluster's build also waits for COL-6.
- **Dr Gallerin guidance and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. Gallerin guidance is booked after step 8's pass (Dave, 5 Oct 2026); the event director waits for the Colony Run's year and difficulty (COL-4, COL-6). The four goal layers now belong to the Colony Run definition (Dave, 30 Sep 2026; `plans/now/colony-run.md`).
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
