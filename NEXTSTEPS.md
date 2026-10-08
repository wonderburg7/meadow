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

1. **[Claude] COL-8 -- winter die-back and spring regrowth**
   - Plan: `plans/now/colony-run.md` -- "COL-8 -- winter die-back and spring regrowth"
   - Files: `scripts/flower.gd`, `scripts/season.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_col8_winter_dieback.py`, `tests/col8_winter_dieback_test.gd`
   - Check: `python -m unittest tests.test_col8_winter_dieback` passes (an in-season flower holding nectar before the skip holds none just after it; on spring's first day its `season_strength()` is below the same date's value in a year with no winter behind it, and equal again by day 1 + `spring_regrowth_days`; the flower count is unchanged by the die-back; the run's first spring is unchanged); `python tools/pacing_gates.py` before and after is recorded here; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `absent: scripts/game_config.gd :: spring_regrowth_days`
   - Next after: T2-8 -- Shiver Cluster: the skill, the multiplied bill without it, the warning

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] SI-1 -- disease, crab-spider species and the rival colony survive a load**
   - Plan: `plans/now/save-integrity.md` -- "SI-1 -- disease, crab-spider species and the rival colony survive a load"
   - Files: `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/rival_hive.gd`, `scripts/main.gd`, `tests/si1_run_state_test.gd`, `tests/test_si1_run_state.py`
   - Check: `python -m unittest tests.test_si1_run_state` passes with `SI1 PASS`; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/save_game.gd :: crab_spider_species`
   - Next after: SI-2 -- a checkpoint restore puts back soil dug since the checkpoint

2. **[Codex] T2-4a -- Cleaning gates taking out the dead larvae**
   - Plan: `plans/now/tier-two.md` -- "T2-4a -- Cleaning gates taking out the dead larvae"
   - Files: `scripts/actions.gd`, `scripts/challenge_stages.gd`, `scripts/skills.gd`, `tests/test_t2_4a_cleaning_gate.py`
   - Check: `python -m unittest tests.test_t2_4a_cleaning_gate` passes; `tools/verify.ps1` is green
   - Proof: `absent: scripts/actions.gd :: "skill": "skill.hive_mind.cleaning"`
   - Next after: T2-5 -- Weather sensing's rain half

3. **[Codex] CD-2 -- missing workforce and blocked work become named, tested facts**
   - Plan: `plans/now/diagnostic-readiness.md` -- "CD-2 -- missing workforce and blocked work become named, tested facts"
   - Files: `scripts/colony_diagnostics.gd`, `scripts/year_winter.gd`, `tests/test_colony_diagnostics.py`
   - Check: `python -m unittest tests.test_colony_diagnostics` passes with empty, staffed and blocked-cell fixtures; `tools/verify.ps1` is green
   - Proof: `present: scripts/colony_diagnostics.gd :: static func compute`
   - Next after: CD-3 -- waiting and travel get a deterministic diagnostic boundary

4. **[Codex] GD-1 -- decide the causal-explanation contract**
   - Plan: `plans/now/guidance-explanations.md` -- "GD-1 -- decide the causal-explanation contract"
   - Files: `plans/now/guidance-explanations.md`, `plans/design/product-scope.md`
   - Check: `python tools/check_docs.py` passes and GD-1 records one owner for facts, trigger policy and presentation
   - Proof: `present: scripts/gallerin_panel.gd :: Nothing feeds it real prompts yet`
   - Next after: GD-2 -- implement the accepted persistent entry point and first explanations

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **COL-7** (`plans/now/colony-run.md`) -- already landed; it waits for nothing and is listed here only to resolve COL-12's recorded `Next after` during closeout.
- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation, Bee Bread and the gyne route.
- **WC-1** (`plans/now/workflow-checks.md`) -- a deferral whose gate has cleared is flagged; waits for room in the Codex lane.
- **WC-2** (`plans/now/workflow-checks.md`) -- a dry-lane warning names the missing deferral and the specified blocks that could serve the lane; waits for WC-1 and room in the Codex lane.
- **WC-3** (`plans/now/workflow-checks.md`) -- Codex's hooks log its sessions; waits for room in the Codex lane.
- **WC-4** (`plans/now/workflow-checks.md`) -- a queue id with whitespace fails the documentation check; waits for WC-2 and room in the Codex lane.
- **WC-5** (`plans/now/workflow-checks.md`) -- the two level-to-model tables are tested against each other; waits for room in the Codex lane.
- **CD-3** (`plans/now/diagnostic-readiness.md`) -- waiting and travel get a deterministic diagnostic boundary; waits for CD-2.
- **GD-2** (`plans/now/guidance-explanations.md`) -- implement the accepted persistent entry point and first explanations; waits for Dave's GD-1 decision.
- **CR-1** (`plans/now/crisis-readiness.md`) -- define the first-crisis readiness and evidence contract; waits for COL-8 and CD-2.
- **CR-2** (`plans/now/crisis-readiness.md`) -- implement the accepted crisis and deterministic scenario; waits for Dave's CR-1 decision.
- **SI-2** (`plans/now/save-integrity.md`) -- a checkpoint restore puts back soil dug since the checkpoint; waits for SI-1, which moved to the Codex lane (Dave, 7 Oct 2026) and shares `scripts/saving.gd`.
- **SI-3** (`plans/now/save-integrity.md`) -- save, checkpoint and index writes are all-or-nothing; waits for SI-2.
- **NF-2** (`plans/now/nectar-fermentation.md`) -- nectar ferments past an age; waits for COL-4 (Codex lane), which edits `scripts/game_config.gd` and `scripts/settings_catalogue.gd`, and for NF-1's evidence.
- **T2-4b to T2-8** (`plans/now/tier-two.md`) -- the rest of progression step 8: T2-4a is in the Codex lane (Dave, 7 Oct 2026); T2-4b (bodies) for T2-4a (COL-6 landed 7 Oct 2026); T2-5 (rain) and T2-7 (tier-2 prices) for COL-4's year; T2-6 (Associative learning) for COL-4 (`game_config.gd`); T2-8 (Shiver Cluster) is to be specified; COL-6 and T2-2 have landed, and its skill goes in `scripts/skills.gd`, which the Codex lane's T2-4a holds.
- **BB-1 to BB-4** (`plans/now/bee-bread.md`) -- Bee Bread; BB-1 waits for COL-4 and NF-2 (`game_config.gd`, `hive_cell.gd`, `hive.gd`, the save files); the rest follow BB-1.
- **Dr Gallerin guidance and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. Gallerin guidance is the next design pass, now that step 8's ran on 6-7 Oct 2026 (booked by Dave, 5 Oct 2026); the event director's wait on the Colony Run's year (COL-4, COL-6) has cleared; it still needs its design pass. The four goal layers now belong to the Colony Run definition (Dave, 30 Sep 2026; `plans/now/colony-run.md`).
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
