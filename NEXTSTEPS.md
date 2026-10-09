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

1. **[Claude] SI-2 -- a checkpoint restore puts back soil dug since the checkpoint**
   - Plan: `plans/now/save-integrity.md` -- "SI-2 -- a checkpoint restore puts back soil dug since the checkpoint"
   - Files: `scripts/saving.gd`, `tests/si2_exact_rollback_test.gd`, `tests/test_si2_exact_rollback.py`
   - Check: `python -m unittest tests.test_si2_exact_rollback` passes with `SI2 PASS`; `python tools/run_scenario.py test_scenarios/sv1_named_saves_test.json` passes; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/saving.gd :: _add_soil_block`
   - Next after: SI-3 -- save, checkpoint and index writes are all-or-nothing

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] T2-5 -- Weather sensing's rain half, Rain recall, and rain on in the Colony Run**
   - Plan: `plans/now/tier-two.md` -- "T2-5 -- Weather sensing's rain half, Rain recall, and rain on in the Colony Run"
   - Files: `scripts/skills.gd`, `scripts/bee_status.gd`, `scripts/bee_foraging.gd`, `scripts/bee.gd`, `scripts/main.gd`, `scripts/levels.gd`, `tests/test_t2_5_rain_skills.py`, `tests/t2_5_rain_skills_test.gd`
   - Check: `python -m unittest tests.test_t2_5_rain_skills` passes (owned and unowned departures, outside recall, level weather policy); `python tools/pacing_gates.py` before and after is recorded here; `tools/verify.ps1` is green
   - Proof: `absent: scripts/bee_status.gd :: WEATHER_SENSING`
   - Next after: T2-6 -- Associative learning

2. **[Codex] WC-1 -- a deferral whose gate has cleared is flagged**
   - Plan: `plans/now/workflow-checks.md` -- "WC-1 -- a deferral whose gate has cleared is flagged"
   - Files: `tools/check_docs.py`, `tests/test_wc1_stale_deferrals.py`
   - Check: `python -m unittest tests.test_wc1_stale_deferrals` passes (a stale gate warns, an unshipped gate and a "landed" clause do not); `python tools/check_docs.py` on master prints the warning for NF-2's COL-4 and NF-1; `tools/verify.ps1` is green
   - Proof: `absent: tools/check_docs.py :: waits for an archived slice`
   - Next after: WC-2 -- a dry-lane warning names the missing deferral and the specified blocks that could serve the lane

3. **[Codex] WC-3 -- Codex's hooks log its sessions**
   - Plan: `plans/now/workflow-checks.md` -- "WC-3 -- Codex's hooks log its sessions"
   - Files: `.codex/hooks.json`, `tests/test_wc3_codex_hooks.py`
   - Check: `python -m unittest tests.test_wc3_codex_hooks` passes with `CLAUDE_PROJECT_DIR` unset; `tools/verify.ps1` is green
   - Proof: `present: .codex/hooks.json :: $CLAUDE_PROJECT_DIR/tools/hook_log.py`
   - Next after: WC-4 -- a queue id with whitespace fails the documentation check

4. **[Codex] FC-1 -- define the first-crisis readiness and evidence contract**
   - Plan: `plans/now/crisis-readiness.md` -- "FC-1 -- define the first-crisis readiness and evidence contract"
   - Files: `plans/now/crisis-readiness.md`, `plans/design/product-scope.md`
   - Check: `python tools/check_docs.py` passes and FC-1 names a trigger, readiness input, visible cause and deterministic scenario boundary
   - Proof: `present: scripts/main.gd :: func _advance_weather`
   - Next after: FC-2 -- implement the accepted crisis and deterministic scenario

5. **[Codex] CD-3 -- waiting and travel get a deterministic diagnostic boundary**
   - Plan: `plans/now/diagnostic-readiness.md` -- "CD-3 -- waiting and travel get a deterministic diagnostic boundary"
   - Files: `scripts/colony_diagnostics.gd`, `scripts/year_winter.gd`, `tests/test_colony_diagnostics.py`
   - Check: `python -m unittest tests.test_colony_diagnostics` passes with waiting, travelling and no-work fixtures; `tools/verify.ps1` is green
   - Proof: `present: scripts/year_winter.gd :: func _refresh_signals`
   - Next after: none -- diagnostic readiness is complete

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation, Bee Bread and the gyne route.
- **WC-2** (`plans/now/workflow-checks.md`) -- a dry-lane warning names the missing deferral and the specified blocks that could serve the lane; waits for WC-1 and room in the Codex lane.
- **WC-4** (`plans/now/workflow-checks.md`) -- a queue id with whitespace fails the documentation check; waits for WC-2 and room in the Codex lane.
- **WC-5** (`plans/now/workflow-checks.md`) -- the two level-to-model tables are tested against each other; waits for room in the Codex lane.
- **GD-2** (`plans/now/guidance-explanations.md`) -- implement the accepted persistent entry point and first explanations; waits for Dave's GD-1 decision.
- **FC-2** (`plans/now/crisis-readiness.md`) -- implement the accepted crisis and deterministic scenario; waits for Dave's FC-1 decision.
- **SI-3** (`plans/now/save-integrity.md`) -- save, checkpoint and index writes are all-or-nothing; waits for SI-2.
- **NF-2** (`plans/now/nectar-fermentation.md`) -- nectar ferments past an age; waits for COL-4 (Codex lane), which edits `scripts/game_config.gd` and `scripts/settings_catalogue.gd`, and for NF-1's evidence.
- **T2-8b** (`plans/now/tier-two.md`) -- the Shiver Cluster skill node and its run-start ownership; waits for T2-5 (Codex lane), which holds `scripts/skills.gd`; T2-4a and T2-8a have landed (8 Oct 2026).
- **T2-4b, T2-6 and T2-7** (`plans/now/tier-two.md`) -- the rest of progression step 8: T2-4b (bodies) is to be specified now T2-4a has landed (8 Oct 2026); T2-6 (Associative learning) is specified when T2-5, now in the Codex lane, lands; T2-7 (tier-2 prices) is to be specified now T2-1 to T2-3 and COL-4 have landed; T2-8b (Shiver Cluster's node) is its own line above.
- **BB-1 to BB-4** (`plans/now/bee-bread.md`) -- Bee Bread; BB-1 waits for COL-4 and NF-2 (`game_config.gd`, `hive_cell.gd`, `hive.gd`, the save files); the rest follow BB-1.
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
