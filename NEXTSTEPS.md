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

1. **[Claude] V-1 -- verification regenerates its generated files instead of asserting them**
   - Plan: `plans/now/verification-cost.md` -- "V-1 — verification regenerates its generated files instead of asserting them"
   - Files: `tools/verify.ps1`, `tools/update_function_map.py`, `tools/stage_reference.py`, `tests/test_verify_generated.py`
   - Check: with `FUNCTION_MAP.md` made stale by hand, `.\tools\verify.ps1` completes green having rewritten it and said so in the stage output; a generator that exits non-zero still fails the stage; `tests/test_verify_generated.py` covers both
   - Proof: `present: tools/verify.ps1 :: -ScriptArgs @("--check")`
   - Next after: V-2 -- the lifecycle suite runs where it can fail.

2. **[Claude] F1s -- a shared window base class**
   - Plan: `plans/design/architecture-review.md` -- "F1s — a shared window base class"
   - Files: `scripts/game_panel.gd`, `scripts/colony_panel.gd`, `scripts/winter_panel.gd`, `scripts/foraging_panel.gd`, `scripts/nursery_panel.gd`, `scripts/gallerin_panel.gd`, `scripts/year_winter.gd`
   - Check: `tests/test_layout_regression.py` passes unchanged and every panel's on-screen rectangle is pixel-identical; one hands-on check filed for opening and closing each window at two text scales
   - Proof: `absent: scripts/foraging_panel.gd :: extends GamePanel`
   - Next after: F2s -- a declarative UI gate table.

3. **[Claude] CB-2 -- every build wall gets its own place to stand**
   - Plan: `plans/now/comb-builders.md` -- "CB-2 — the fix CB-1 identifies"
   - Files: `scripts/bee_building.gd`, `scripts/hive_cell.gd`, `test_scenarios/cb1_comb_builders_per_site_test.json`
   - Check: two runs of `test_scenarios/cb1_comb_builders_per_site_test.json` at seed 4242 report `min_builder_spacing_px` at or above 13.6 with `max_builders_per_site` still 6 and `building_without_slot` still 0, identical over the two runs; C-46 moves from `checks/blocked.md` to ready
   - Proof: `present: scripts/hive_cell.gd :: return position + edge_offset * 1.35`
   - Next after: none -- comb-builders is complete once C-46 is ready to re-run.

4. **[Claude] V-2 -- the lifecycle suite runs where it can fail**
   - Plan: `plans/now/verification-cost.md` -- "V-2 — the lifecycle suite runs where it can fail"
   - Files: `tools/verify.ps1`
   - Check: the two `lifecycle tests` failures of the last seven days are found and classified in the delivery note; if both are lifecycle-tooling defects, a branch touching only `scripts/*.gd` runs `.\tools\verify.ps1` without the 230s stage and prints why it skipped, while a branch touching `tools/slice.ps1` still runs it and `-Scope primary` always does
   - Proof: `present: tools/verify.ps1 :: $env:MEADOW_FINISH_VERIFY -ne "1"`
   - Next after: V-3 -- the routing rule's section headers actually exist.

5. **[Claude] V-3 -- the routing rule's section headers actually exist**
   - Plan: `plans/now/verification-cost.md` -- "V-3 — the routing rule's section headers actually exist"
   - Files: `scripts/settings_catalogue.gd`, `scripts/bee_foraging.gd`, `scripts/debug_panel.gd`, `scripts/challenge_runner.gd`, `scripts/diagnostic_log.gd`, `scripts/bee.gd`, `tools/update_function_map.py`
   - Check: each of the six files has `# --- section ---` headers at its real boundaries with no header inside a function and no code line moved; `python tools/update_function_map.py` warns for any file over 700 lines whose first header falls after its first tenth; `.\tools\verify.ps1` green including the Godot boot
   - Proof: `absent: scripts/bee_foraging.gd :: # ---`
   - Next after: none -- verification-cost is complete.

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude lane.

1. **[Codex] L-14 -- the stops ledger survives a non-ASCII stop cause**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-14 — the stops ledger survives a non-ASCII stop cause"
   - Files: `tools/slice.ps1`, `tools/session_cost.py`
   - Check: `python tools/session_cost.py --stops` prints a tally over the existing 39-record ledger with no hand editing; a stop cause containing an em dash is written and read back unchanged; a record with a corrupt byte costs that record and not the report
   - Proof: `present: tools/slice.ps1 :: Add-Content -LiteralPath (Join-Path $commonDir "meadow-slice-stops.jsonl")`
   - Next after: L-12 -- a plan's slice section carries the queue lines it is refilled from.

2. **[Codex] PERF-1 -- measure `find_food_cell` before changing it**
   - Plan: `plans/reference/technical-audit.md` -- "PERF-1 — measure `find_food_cell` before changing it"
   - Files: `scripts/hive.gd`, `docs/PERFORMANCE_BASELINE.md`
   - Check: two runs of `test_scenarios/recommendation_slice0_baseline.json` at `--fixed-fps 60` with perf enabled report the new `hive_find_food` section within 10% of each other, and the delivery note says whether it is trivial or worth a follow-up slice, with the numbers
   - Proof: `absent: scripts/hive.gd :: hive_find_food`
   - Next after: none -- technical-audit section A is complete unless PERF-1's numbers open a follow-up.

3. **[Codex] T-2 -- level drift joins on something that exists**
   - Plan: `plans/now/workflow-telemetry.md` -- "T-2 — level drift joins on something that exists"
   - Files: `tools/slice.ps1`, `tools/session_cost.py`, `tests/test_source_checks.py`
   - Check: a slice claimed after the change is reported by `python tools/session_cost.py --events` as assessed -- named under level drift or counted in-level -- rather than falling into `not assessable`; the 12 older claims are still counted, dated, and never raise; an older record missing the new key still parses
   - Proof: `present: tools/session_cost.py :: sessions_by_branch.get(e.get("branch"), [])`
   - Next after: T-1 -- `tool_bash` records the command that ran.

4. **[Codex] T-1 -- `tool_bash` records the command that ran, not the `cd` in front of it**
   - Plan: `plans/now/workflow-telemetry.md` -- "T-1 — `tool_bash` records the command that ran"
   - Files: `tools/hook_log.py`, `tools/session_cost.py`, `tests/test_source_checks.py`
   - Check: a `cd X && python tools/foo.py` payload records `python foo.py` and a `VAR=1 git status` payload records `git`, both covered in `tests/test_source_checks.py`; the field is still one short token with no path, argument or message in it; `python tools/session_cost.py --events` reports the same `bash tool calls` count as before
   - Proof: `present: tools/hook_log.py :: cmd=words[0] if words else ""`
   - Next after: T-3 -- a headless run that did not compile fails as a compile failure.

5. **[Codex] T-3 -- a headless run that did not compile fails as a compile failure**
   - Plan: `plans/now/workflow-telemetry.md` -- "T-3 — a headless run that did not compile fails as a compile failure"
   - Files: `tools/run_scenario.py`, `docs/headless-run-contract.md`
   - Check: a deliberate parse error in one script makes a scenario run fail naming that script, the first `SCRIPT ERROR:` line and the `process.log` path, instead of writing a session file of zeroes; with the error reverted, an ordinary run is unchanged in output, artefact names and timing
   - Proof: `absent: tools/run_scenario.py :: SCRIPT ERROR`
   - Next after: none -- workflow-telemetry is complete.

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
