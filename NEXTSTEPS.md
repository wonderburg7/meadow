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

1. **[Claude] AP-3 -- the skill tree panel**
   - Plan: `plans/now/alpha-progression-spine.md` -- "AP-3 — the skill tree panel"
   - Files: `scripts/skill_tree_panel.gd`, `scripts/hud.gd`
   - Check: a `GamePanel` subclass keyed `skills` draws the six sectors at their authored axial coordinates with `Shapes.hex_line` connect tiles, shows each node as owned/affordable/blocked with `purchase_blocker`'s reason, opens from a HUD Skills button, and takes its rectangle from `ui_layout.gd`; every other window still opens, closes and sits where it did
   - Proof: `absent: scripts/hud.gd :: skill_tree_panel`
   - Next after: AP-4 -- buying a skill, and the run remembering it.

2. **[Claude] SV-3 -- the cog's Load run opens the Saves window**
   - Plan: `plans/now/named-saves.md` -- "SV-3 — the cog's Load run opens the Saves window"
   - Files: `scripts/debug_panel.gd`
   - Check: outside a Challenge the cog's Load run opens the Saves window instead of reloading the newest save, inside a Challenge it behaves as before, and Save run is unchanged
   - Proof: `absent: scripts/debug_panel.gd :: saves_panel`
   - Next after: none -- named-saves is complete once SV-3 ships.

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] FB-3 -- the pacing gates become one command**
   - Plan: `plans/now/feedback-build.md` -- "FB-3 — the pacing gates become one command"
   - Files: `tools/pacing_gates.py`, `test_scenarios/alpha_arc_test.json`, `tests/test_pacing_gates.py`, `tools/verify.ps1`
   - Check: `python tools/pacing_gates.py` runs a fixed-seed arc scenario three times, prints one table of milestone, median day, the §3 target in days and whether it is inside band in under 40 lines, reports each run's wall clock, and `tests/test_pacing_gates.py` proves the band arithmetic without launching Godot
   - Proof: `absent: tools/verify.ps1 :: pacing_gates`
   - Next after: none -- feedback-build is complete once FB-3 ships.

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **PERF-2** (`plans/reference/technical-audit.md`) -- needs a pinned hungry-indoor scenario specification before it can be admitted to measure `find_food_cell` causally.
- **Progression Phase B steps 7 onwards, and Phase C** (`plans/design/progression.md`) -- step 6 is now `plans/now/alpha-progression-spine.md`'s AP-1 to AP-4; step 7 waits for those four to prove tier 1 in a running game.
- **Dr Gallerin guidance, the four-layer goal model and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **C1F-G1** (`plans/now/c1-followups.md`) -- a fixture that fails when `go_to_deposit_cell`'s `bee.target_cell = null` is reverted needs a higher-reasoning session to plan how to get the queen waiting at a full comb before 1.14 past the stage setup's `_release_queen`.
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`
