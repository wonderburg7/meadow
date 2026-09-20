# Next steps

<!-- CONTEXT: current-queue | LOAD: never whole; tools/slice.ps1 reads it -->

Do not read this file to find work: `tools/slice.ps1 start -Lane Claude|Codex`
claims your lane's first item and prints the one `read` command you need.
This file holds the queue only -- detail lives in each item's `Plan:` section,
and history in Git and `plans/archive/` (the old log is
`plans/archive/NEXTSTEPS_LOG_2026-09-17.md`). Rules: `.claude/rules/documentation.md`.

## Next up

### Claude lane

Up to five items, worked top to bottom. No file here may appear in the Codex lane.

1. **[Claude] F1s -- a shared window base class**
   - Plan: `plans/design/architecture-review.md` -- "F1s — a shared window base class"
   - Files: `scripts/game_panel.gd`, `scripts/colony_panel.gd`, `scripts/winter_panel.gd`, `scripts/foraging_panel.gd`, `scripts/nursery_panel.gd`, `scripts/gallerin_panel.gd`, `scripts/year_winter.gd`
   - Check: `tests/test_layout_regression.py` passes unchanged and every panel's on-screen rectangle is pixel-identical; one hands-on check filed for opening and closing each window at two text scales
   - Proof: `absent: scripts/foraging_panel.gd :: extends GamePanel`
   - Next after: F2s -- a declarative UI gate table.

2. **[Claude] CB-2 -- every build wall gets its own place to stand**
   - Plan: `plans/now/comb-builders.md` -- "CB-2 — the fix CB-1 identifies"
   - Files: `scripts/bee_building.gd`, `scripts/hive_cell.gd`, `test_scenarios/cb1_comb_builders_per_site_test.json`
   - Check: two runs of `test_scenarios/cb1_comb_builders_per_site_test.json` at seed 4242 report `min_builder_spacing_px` at or above 13.6 with `max_builders_per_site` still 6 and `building_without_slot` still 0, identical over the two runs; C-46 moves from `checks/blocked.md` to ready
   - Proof: `present: scripts/hive_cell.gd :: return position + edge_offset * 1.35`
   - Next after: none -- comb-builders is complete once C-46 is ready to re-run.

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude lane.

1. **[Codex] PERF-1 -- measure `find_food_cell` before changing it**
   - Plan: `plans/reference/technical-audit.md` -- "PERF-1 — measure `find_food_cell` before changing it"
   - Files: `scripts/hive.gd`, `docs/PERFORMANCE_BASELINE.md`
   - Check: two runs of `test_scenarios/recommendation_slice0_baseline.json` at `--fixed-fps 60` with perf enabled report the new `hive_find_food` section within 10% of each other, and the delivery note says whether it is trivial or worth a follow-up slice, with the numbers
   - Proof: `absent: scripts/hive.gd :: hive_find_food`
   - Next after: none -- technical-audit section A is complete unless PERF-1's numbers open a follow-up.

2. **[Codex] L-14 -- the stops ledger survives a non-ASCII stop cause**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-14 — the stops ledger survives a non-ASCII stop cause"
   - Files: `tools/slice.ps1`, `tools/session_cost.py`
   - Check: `python tools/session_cost.py --stops` prints a tally over the existing 39-record ledger with no hand editing; a stop cause containing an em dash is written and read back unchanged; a record with a corrupt byte costs that record and not the report
   - Proof: `present: tools/slice.ps1 :: Add-Content -LiteralPath (Join-Path $commonDir "meadow-slice-stops.jsonl")`
   - Next after: L-12 -- a plan's slice section carries the queue lines it is refilled from.

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **F2s, G3** (`plans/design/architecture-review.md`) -- F2s follows F1s; G3 follows F2s now that G2 has shipped.
- **Progression Phase B step 6 onwards** (`plans/design/progression.md`) -- wants a clear run of the UI work above.
- **L-12** (`plans/now/agent-lifecycle.md`) -- gated until `tools/session_cost.py --stops` shows the refill step among the two most frequent over ten or more stops.
- **C1F-G1** (`plans/now/c1-followups.md`) -- a fixture that fails when `go_to_deposit_cell`'s `bee.target_cell = null` is reverted needs a higher-reasoning session to plan how to get the queen waiting at a full comb before 1.14 past the stage setup's `_release_queen`.
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`
