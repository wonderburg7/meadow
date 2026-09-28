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

1. **[Claude] BS-D -- a developer mode setting, switched on from the main menu's settings**
   - Plan: `plans/now/brood-spine.md` -- "BS-D — a developer mode setting, switched on from the main menu's settings"
   - Files: `scripts/settings_catalogue.gd`, `scripts/game_config.gd`, `scripts/main_menu.gd`
   - Check: the settings window opened from the main menu lists a Developer mode toggle, off by default, that survives a restart, and `tools/verify.ps1` is green
   - Proof: `absent: scripts/settings_catalogue.gd :: developer_mode`
   - Next after: BS-5 -- the developer table shows a run's sheet, read-only

2. **[Claude] L-15 -- a busy lifecycle lock is waited for, not refused, and an open-worktree stop says what to do**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-15 — the other lane's lifecycle command waits for the lock, and an open-worktree stop says what to do"
   - Files: `tools/slice.ps1`, `tests/test_two_lane_closeout.py`, `tests/test_slice_lifecycle.py`
   - Check: a second `finish` started while another holds the lock prints one waiting line naming the holder and completes after it, `start` against an open worktree says whether to finish or abandon it, and `tools/verify.ps1` is green
   - Proof: `present: tools/slice.ps1 :: slice lifecycle is busy; retry this command`
   - Next after: none -- agent-lifecycle is complete once L-15 ships and the Objective's completion gate is met

3. **[Claude] BS-2 -- Challenge 2 offers Nurses free at 2.5**
   - Plan: `plans/now/brood-spine.md` -- "BS-2 — Challenge 2 offers Nurses free at 2.5"
   - Files: `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`, `scripts/progression.gd`, `scripts/skill_tree_panel.gd`, `test_scenarios/f2s_challenge2_gate_table_test.json`, `docs/challenge-stages.md`
   - Check: `test_scenarios/f2s_challenge2_gate_table_test.json` passes: Challenge 2 buys Nurses at 2.5 for nothing and still completes, `docs/challenge-stages.md` shows 2.5's new goal, and `tools/verify.ps1` is green
   - Proof: `absent: scripts/challenge_stages.gd :: "free_skills"`
   - Next after: BS-3 -- the gate goes live: an unowned role cannot be assigned or worked

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] PERF-3 -- `find_food_cell` reads the content index**
   - Plan: `plans/now/hot-path-queries.md` -- "PERF-3 -- `find_food_cell` reads the content index"
   - Files: `scripts/hive.gd`, `docs/PERFORMANCE_BASELINE.md`
   - Check: the focused Godot compile check is green; two `perf2_hungry_indoor.json` captures keep `hive_find_food` non-zero and materially below PERF-2's recorded mean
   - Proof: `absent: docs/PERFORMANCE_BASELINE.md :: PERF-3 measurement`
   - Next after: close candidate A in `plans/reference/technical-audit.md` if the index-backed runs preserve the fixture's outcome

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **BS-3 to BS-6** (`plans/now/brood-spine.md`) -- each waits for the earlier slice its plan's table names; BS-6 also waits for Dave's decision on where developer edits persist.
- **Progression Phase B step 8 onwards, and Phase C** (`plans/design/progression.md`) -- step 7 is `plans/now/brood-spine.md`; step 8 waits for BS-4 to prove a tier-2 purchase in a run.
- **Dr Gallerin guidance, the four-layer goal model and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`
