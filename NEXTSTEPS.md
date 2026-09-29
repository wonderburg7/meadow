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

1. **[Claude] HR-3 -- a bee waiting for room says it is waiting**
   - Plan: `plans/now/hive-readouts.md` -- "HR-3 — a bee waiting for room says it is waiting"
   - Files: `scripts/bee.gd`
   - Check: `tools/verify.ps1` is green, and `task_description` returns the waiting text when `state == IN_HIVE_TO_CELL` and `target_cell == null`
   - Proof: `absent: scripts/bee.gd :: no cell has room for it`
   - Next after: none -- plans/now/hive-readouts.md is complete

2. **[Claude] HF-1 -- panel textures actually draw (C-60)**
   - Plan: `plans/now/hud-followups.md` -- "HF-1 — panel textures actually draw (C-60)"
   - Files: `scripts/ui_theme.gd`, `scripts/ui_layout.gd`, `tests/source_checks.py`, `docs/known-pitfalls.md`
   - Check: `tools/verify.ps1` is green with the new source check in it, and `UiLayout.panel_chrome()` still returns `Vector2(24, 20)`
   - Proof: `present: scripts/ui_theme.gd :: var _base := StyleBoxFlat.new()`
   - Next after: HF-2 -- text scale waits until you stop clicking

3. **[Claude] HF-2 -- text scale waits until you stop clicking**
   - Plan: `plans/now/hud-followups.md` -- "HF-2 — text scale waits until you stop clicking"
   - Files: `scripts/debug_panel.gd`
   - Check: `tools/verify.ps1` is green, and `_adjust` on `text_scale` restarts the timer instead of calling `UiTheme.refresh_for_setting`
   - Proof: `absent: scripts/debug_panel.gd :: TEXT_SCALE_APPLY_DELAY`
   - Next after: HF-3 -- the top bar's second row spans the first

4. **[Claude] HF-3 -- the top bar's second row spans the first**
   - Plan: `plans/now/hud-followups.md` -- "HF-3 — the top bar's second row spans the first"
   - Files: `scripts/hud.gd`, `scripts/scenario_actions.gd`, `test_scenarios/hf3_top_bar_rows_test.json`
   - Check: `python tools/run_scenario.py test_scenarios/hf3_top_bar_rows_test.json` passes, and `tools/verify.ps1` is green
   - Proof: `absent: scripts/hud.gd :: top_bar_row2`
   - Next after: HF-4 -- the Winter forecast is a left-hand window

5. **[Claude] HF-4 -- the Winter forecast is a left-hand window**
   - Plan: `plans/now/hud-followups.md` -- "HF-4 — the Winter forecast is a left-hand window"
   - Files: `scripts/winter_panel.gd`, `scripts/year_winter.gd`, `scripts/main.gd`, `scripts/game_panel.gd`, `scripts/scenario_actions.gd`, `test_scenarios/hf4_winter_left_window_test.json`
   - Check: `python tools/run_scenario.py test_scenarios/hf4_winter_left_window_test.json` passes, and `tools/verify.ps1` is green
   - Proof: `present: scripts/winter_panel.gd :: build_top_right_window(`
   - Next after: HF-5 -- opening Nursery keeps the view you are in

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

- **BS-5** (`plans/now/brood-spine.md`) -- startable now (BS-1 and BS-D have landed); waits only for a free slot in the Claude lane, which is full at five.
- **BS-3, BS-4 and BS-6** (`plans/now/brood-spine.md`) -- each waits for the earlier slice its plan's table names; BS-6 also waits for Dave's decision on where developer edits persist.
- **Progression Phase B step 8 onwards, and Phase C** (`plans/design/progression.md`) -- step 7 is `plans/now/brood-spine.md`; step 8 waits for BS-4 to prove a tier-2 purchase in a run.
- **Dr Gallerin guidance, the four-layer goal model and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **SK-2** (`plans/now/skill-screen.md`) -- waits for SK-1's full-screen skill view to merge.
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`
