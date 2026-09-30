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

1. **[Claude] SK-1 -- the skill tree opens full-screen and pauses the game**
   - Plan: `plans/now/skill-screen.md` -- "SK-1 — the skill tree opens full-screen and pauses the game"
   - Files: `scripts/skill_tree_panel.gd`, `scripts/hud.gd`, `scripts/scenario_actions.gd`, `test_scenarios/ap3_skill_tree_window_test.json`
   - Check: `python tools/run_scenario.py test_scenarios/ap3_skill_tree_window_test.json` passes (skills full-screen, tree paused), `test_scenarios/ap6_bought_tarsal_test.json` still passes, and `tools/verify.ps1` is green
   - Proof: `present: scripts/skill_tree_panel.gd :: build_left_window(400)`
   - Next after: SK-2 -- skill names in big hexes, with drag and zoom

2. **[Claude] BS-3 -- the gate goes live: an unowned role cannot be assigned or worked**
   - Plan: `plans/now/brood-spine.md` -- "BS-3 — the gate goes live"
   - Files: `scripts/availability.gd`, `scripts/hud.gd`, `scripts/challenge_runner.gd`
   - Check: a level 7 run cannot assign or raise a nurse before buying Nurses and can after, Challenge 2's fixture `test_scenarios/f2s_challenge2_gate_table_test.json` still passes, and `tools/verify.ps1` is green
   - Proof: `absent: scripts/availability.gd :: "role_query"`
   - Next after: BS-4 -- a run buys Honey worker, makes honey and affords a tier-2 skill

3. **[Claude] BS-5 -- the developer table shows a run's sheet, read-only**
   - Plan: `plans/now/brood-spine.md` -- "BS-5 — the developer table shows a run's sheet, read-only"
   - Files: `scripts/run_availability_panel.gd`, `scripts/run_availability.gd`, `scripts/debug_panel.gd`
   - Check: with Developer mode on, the settings window lists a Run availability button that opens a read-only table of the run's skills with source and reason; with it off the button is absent, and `tools/verify.ps1` is green
   - Proof: `absent: scripts/debug_panel.gd :: run_availability_panel`
   - Next after: BS-6 -- developer edits to the table change what a run starts with

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] PE-1 -- pacing milestones are timed to the hour**
   - Plan: `plans/now/pacing-evidence.md` -- "PE-1 — pacing milestones are timed to the hour"
   - Files: `tools/analyze_session.py`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`, `tests/test_headless_verdicts.py`, `docs/headless-run-contract.md`
   - Check: `python -m unittest tests.test_pacing_gates tests.test_headless_verdicts` passes, including a first worker at day 1.5 reading in band at 200 s/day, `python tools/pacing_gates.py --repeat 1` prints a table with two-decimal median days, and `tools/verify.ps1` is green
   - Proof: `absent: tools/analyze_session.py :: milestone_times`
   - Next after: none -- plans/now/pacing-evidence.md is complete

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **BS-4 and BS-6** (`plans/now/brood-spine.md`) -- each waits for the earlier slice its plan's table names; BS-6 also waits for Dave's decision on where developer edits persist.
- **Progression Phase B step 8 onwards, and Phase C** (`plans/design/progression.md`) -- step 7 is `plans/now/brood-spine.md`; step 8 waits for BS-4 to prove a tier-2 purchase in a run.
- **Dr Gallerin guidance, the four-layer goal model and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **SK-2** (`plans/now/skill-screen.md`) -- waits for SK-1's full-screen skill view to merge.
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`
