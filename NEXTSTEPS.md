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

2. **[Claude] T2-1 -- Comb worker and Miner become bought roles, and the queen builds without the skill**
   - Plan: `plans/now/tier-two.md` -- "T2-1 -- Comb worker and Miner become bought roles, and the queen builds without the skill"
   - Files: `scripts/roles.gd`, `scripts/availability.gd`, `scripts/orders_zones.gd`, `scripts/hud.gd`, `scripts/challenge_stages.gd`, `tests/test_t2_1_comb_miner_gate.py`, `test_scenarios/t2_1_queen_builds.json`, `tools/verify.ps1`
   - Check: `python -m unittest tests.test_t2_1_comb_miner_gate` passes (the Colony Run queen draws a cell with no skill owned; no worker becomes a Comb worker or Miner unbought; Challenge 2's 2.7 and 2.8 free them); `python -m unittest tests.test_challenge2_checks` passes; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `absent: scripts/roles.gd :: "skill": "skill.colony.comb_worker"`
   - Next after: T2-2 -- Automation gates working outward

3. **[Claude] T2-2 -- Automation gates working outward**
   - Plan: `plans/now/tier-two.md` -- "T2-2 -- Automation gates working outward"
   - Files: `scripts/roles.gd`, `scripts/availability.gd`, `scripts/actions.gd`, `scripts/hive.gd`, `scripts/challenge_stages.gd`, `tests/test_t2_2_automation_gate.py`, `tools/verify.ps1`
   - Check: `python -m unittest tests.test_t2_2_automation_gate` passes (automine and outward building refused without Automation, allowed with it; marked work unaffected; Challenge 2's 2.8 frees Backup roles and Automation); `python -m unittest tests.test_challenge2_checks` passes; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `absent: scripts/actions.gd :: skill.hive_mind.automation`
   - Next after: T2-3 -- Adaptive constancy becomes a bought behaviour

4. **[Claude] T2-3 -- Adaptive constancy becomes a bought behaviour**
   - Plan: `plans/now/tier-two.md` -- "T2-3 -- Adaptive constancy becomes a bought behaviour"
   - Files: `scripts/skills.gd`, `scripts/bee_foraging.gd`, `tests/test_t2_3_adaptive_constancy.py`, `test_scenarios/t2_3_bought_constancy_test.json`, `tools/verify.ps1`
   - Check: `python -m unittest tests.test_t2_3_adaptive_constancy` passes (bought with the setting off, a forager re-evaluates its species; unbought, none does); `tools/verify.ps1` is green
   - Proof: `absent: scripts/bee_foraging.gd :: static func adaptive_constancy_on`
   - Next after: T2-4a -- Cleaning gates taking out the dead larvae

5. **[Claude] COL-6 -- winter is skipped and resolved in one step**
   - Plan: `plans/now/colony-run.md` -- "COL-6 -- winter is skipped and resolved in one step"
   - Files: `scripts/season.gd`, `scripts/year_winter.gd`, `tests/test_col6_winter_skip.py`, `test_scenarios/col6_winter_skip_test.json`, `tools/verify.ps1`
   - Check: `python -m unittest tests.test_col6_winter_skip` passes (a stocked colony crosses winter in one tick with nobody lost and the day advanced by winter's length; an under-stocked one loses its oldest workers first and keeps its queen); `python tools/pacing_gates.py` before and after is recorded here; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `absent: scripts/season.gd :: winter_bill`
   - Next after: COL-7 -- the mating window, genetic points and COL-2's narrower win

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] AR-1 -- headless snapshots carry the Colony Run milestone record**
   - Plan: `plans/now/alpha-route-evidence.md` -- "AR-1 -- headless snapshots carry the Colony Run milestone record"
   - Files: `scripts/headless/diagnostic_probes.gd`, `test_scenarios/alpha_arc_test.json`, `tests/test_headless_profiles.py`, `tools/headless/profiles.py`
   - Check: `python -m unittest tests.test_headless_profiles` passes, and `test_scenarios/alpha_arc_test.json` requests the allowlisted Colony Run milestone field
   - Proof: `absent: scripts/headless/diagnostic_probes.gd :: colony.milestone_days`
   - Next after: AR-2 -- analysis turns that record into named alpha-gate facts

2. **[Codex] AR-2 -- analysis turns that record into named alpha-gate facts**
   - Plan: `plans/now/alpha-route-evidence.md` -- "AR-2 -- analysis turns that record into named alpha-gate facts"
   - Files: `tools/analyze_session.py`, `tests/test_headless_verdicts.py`
   - Check: `python -m unittest tests.test_headless_verdicts` passes with a copied milestone record reporting first automation and first gyne by recorded day, and without changing existing pacing milestones
   - Proof: `absent: tools/analyze_session.py :: alpha_route`
   - Next after: AR-3 -- the pacing report presents every alpha gate and its evidence boundary

3. **[Codex] AR-3 -- the pacing report presents every alpha gate and its evidence boundary**
   - Plan: `plans/now/alpha-route-evidence.md` -- "AR-3 -- the pacing report presents every alpha gate and its evidence boundary"
   - Files: `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
   - Check: `python -m unittest tests.test_pacing_gates` passes with five named alpha-gate rows, and missing crisis or gyne facts render as unavailable rather than in-band
   - Proof: `present: tools/pacing_gates.py :: Not instrumented: 20m forage/weather crisis; 90m gyne release.`
   - Next after: AR-4 -- a scripted Colony Run reaches and records all five gates

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **COL-7** (`plans/now/colony-run.md`) -- the mating window, genetic points and COL-2's narrower win wait for COL-6, and are specified once it lands.
- **NF-2** (`plans/now/nectar-fermentation.md`) -- nectar ferments past an age; waits for COL-4 (Codex lane), which edits `scripts/game_config.gd` and `scripts/settings_catalogue.gd`, and for NF-1's evidence.
- **COL-11** (`plans/now/colony-run.md`) -- startable, but the Claude lane is full.
- **COL-12** (`plans/now/colony-run.md`) -- startable, but the Claude lane is full.
- **T2-4a to T2-8** (`plans/now/tier-two.md`) -- the rest of progression step 8: T2-4a waits for T2-2 (`actions.gd`, `challenge_stages.gd`); T2-4b (bodies) for T2-4a, COL-4 and COL-6; T2-5 (rain) and T2-7 (tier-2 prices) for COL-4's year; T2-6 (Associative learning) for COL-4 (`game_config.gd`); T2-8 (Shiver Cluster) for COL-6.
- **BB-1 to BB-4** (`plans/now/bee-bread.md`) -- Bee Bread; BB-1 waits for COL-4 and NF-2 (`game_config.gd`, `hive_cell.gd`, `hive.gd`, the save files) and T2-3 (`roles.gd`, `actions.gd`, `skills.gd`); the rest follow BB-1.
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
