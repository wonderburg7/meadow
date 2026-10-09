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

1. **[Claude] NF-2 -- nectar ferments past an age, changes colour, and is lost to honey makers**
   - Plan: `plans/now/nectar-fermentation.md` -- "NF-2 -- nectar ferments past an age, changes colour, and is lost to honey makers"
   - Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/hive_cell.gd`, `scripts/hive.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_nf2_fermentation.py`, `test_scenarios/nf2_fermentation.json`
   - Check: `python -m unittest tests.test_nf2_fermentation` passes (a cell ferments, honey makers skip it, a top-up leaves it fermented, its stamp survives save and restore); `tools/verify.ps1` is green
   - Proof: `absent: scripts/hive_cell.gd :: func is_fermented`
   - Next after: NF-3 -- a bee that drinks fermented nectar goes tipsy

2. **[Claude] T2-4b -- Bees that die in the hive leave bodies; winter's dead appear at spring**
   - Plan: `plans/now/tier-two.md` -- "T2-4b -- Bees that die in the hive leave bodies; winter's dead appear at spring"
   - Files: `scripts/hive_body.gd`, `scripts/hive.gd`, `scripts/bee_survival.gd`, `scripts/season.gd`, `scripts/bee_building.gd`, `scripts/bee.gd`, `scripts/actions.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/t2_4b_bodies_test.gd`, `tests/test_t2_4b_bodies.py`
   - Check: `python -m unittest tests.test_t2_4b_bodies` passes with `T2-4B PASS`; `python tools/run_scenario.py test_scenarios/col6_winter_skip_test.json` passes; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/game_config.gd :: max_hive_bodies`
   - Next after: T2-6 -- Associative learning

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] WC-3 -- Codex's hooks log its sessions**
   - Plan: `plans/now/workflow-checks.md` -- "WC-3 -- Codex's hooks log its sessions"
   - Files: `.codex/hooks.json`, `tests/test_wc3_codex_hooks.py`
   - Check: `python -m unittest tests.test_wc3_codex_hooks` passes with `CLAUDE_PROJECT_DIR` unset; `tools/verify.ps1` is green
   - Proof: `present: .codex/hooks.json :: $CLAUDE_PROJECT_DIR/tools/hook_log.py`
   - Next after: WC-4 -- a queue id with whitespace fails the documentation check

2. **[Codex] FC-1 -- define the first-crisis readiness and evidence contract**
   - Plan: `plans/now/crisis-readiness.md` -- "FC-1 -- define the first-crisis readiness and evidence contract"
   - Files: `plans/now/crisis-readiness.md`, `plans/design/product-scope.md`
   - Check: `python tools/check_docs.py` passes and FC-1 names a trigger, readiness input, visible cause and deterministic scenario boundary
   - Proof: `present: scripts/main.gd :: func _advance_weather`
   - Next after: FC-2 -- implement the accepted crisis and deterministic scenario

3. **[Codex] CD-3 -- waiting and travel get a deterministic diagnostic boundary**
   - Plan: `plans/now/diagnostic-readiness.md` -- "CD-3 -- waiting and travel get a deterministic diagnostic boundary"
   - Files: `scripts/colony_diagnostics.gd`, `scripts/year_winter.gd`, `tests/test_colony_diagnostics.py`
   - Check: `python -m unittest tests.test_colony_diagnostics` passes with waiting, travelling and no-work fixtures; `tools/verify.ps1` is green
   - Proof: `present: scripts/year_winter.gd :: func _refresh_signals`
   - Next after: none -- diagnostic readiness is complete

4. **[Codex] WC-5 -- the two level-to-model tables are tested against each other**
   - Plan: `plans/now/workflow-checks.md` -- "WC-5 -- the two level-to-model tables are tested against each other"
   - Files: `tools/session_cost.py`, `tests/test_wc5_level_model_parity.py`
   - Check: `python -m unittest tests.test_wc5_level_model_parity` passes, and fails when one `LEVEL_MODELS` entry is edited by hand; `tools/verify.ps1` is green
   - Proof: `present: tools/session_cost.py :: mirrors Get-SliceAdvice in`
   - Next after: none -- plans/now/workflow-checks.md is complete

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation, Bee Bread and the gyne route.
- **WC-2** (`plans/now/workflow-checks.md`) -- a dry-lane warning names the missing deferral and the specified blocks that could serve the lane; waits for WC-1 and room in the Codex lane.
- **WC-4** (`plans/now/workflow-checks.md`) -- a queue id with whitespace fails the documentation check; waits for WC-2 and room in the Codex lane.
- **GD-2** (`plans/now/guidance-explanations.md`) -- implement the accepted persistent entry point and first explanations; waits for Dave's GD-1 decision.
- **FC-2** (`plans/now/crisis-readiness.md`) -- implement the accepted crisis and deterministic scenario; waits for Dave's FC-1 decision.
- **T2-6 and T2-7** (`plans/now/tier-two.md`) -- the rest of progression step 8: T2-6 (Associative learning) is specified and fenced `queue-gated`, and waits for Dave's decision on its familiarity rates, handling-speed cap and old-save default; T2-7 (tier-2 prices) is still to be specified, and T2-6's block names it next. T2-8b landed 9 Oct 2026; T2-4b (bodies) is queued in the Claude lane.
- **BB-1 to BB-4** (`plans/now/bee-bread.md`) -- Bee Bread; BB-1 waits for NF-2, queued in the Claude lane (`game_config.gd`, `hive_cell.gd`, `hive.gd`, the save files; COL-4 has landed); the rest follow BB-1.
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
