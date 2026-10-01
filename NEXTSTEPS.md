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

1. **[Claude] FBB-1 -- the skill tree hides the cut skills and says which are not built**
   - Plan: `plans/now/feedback-build.md` -- "FBB-1 -- the skill tree hides the cut skills and says which are not built"
   - Files: `scripts/skills.gd`, `scripts/progression.gd`, `scripts/skill_tree_panel.gd`, `scripts/scenario_actions.gd`, `test_scenarios/fbb1_cut_skills_test.json`
   - Check: `python tools/run_scenario.py test_scenarios/fbb1_cut_skills_test.json` passes with Combat refused and Cell capacity bought, and `tools/verify.ps1` is green
   - Proof: `absent: scripts/skills.gd :: CUT_FROM_ALPHA`
   - Next after: none -- plans/now/feedback-build.md is complete

2. **[Claude] UI-F-2 -- warnings carry a severity and a pending one is never lost**
   - Plan: `plans/now/ui-feedback.md` -- "UI-F-2 -- warnings carry a severity and a pending one is never lost"
   - Files: `scripts/hud.gd`, `scripts/bee_survival.gd`, `scripts/crab_spider.gd`, `scripts/main.gd`, `scripts/year_winter.gd`
   - Check: `grep -c "SEVERITY_" scripts/bee_survival.gd scripts/crab_spider.gd scripts/main.gd scripts/year_winter.gd` prints at least 1 for each file, and `tools/verify.ps1` is green
   - Proof: `present: scripts/hud.gd :: _pending_warning = {"text": text, "severity": severity}`
   - Next after: none -- plans/now/ui-feedback.md is complete

3. **[Claude] BS-9 -- the queen nurses without the Nurses skill**
   - Plan: `plans/now/brood-spine.md` -- "BS-9 — the queen nurses without the Nurses skill"
   - Files: `scripts/availability.gd`, `test_scenarios/bs9_c2_queen_nurses_test.json`
   - Check: `python tools/run_scenario.py test_scenarios/bs9_c2_queen_nurses_test.json` passes with a pollen Forager hatched at Challenge 2's stage 2.2, `test_scenarios/bs3_nurse_gate_test.json` still passes, and `tools/verify.ps1` is green
   - Proof: `absent: scripts/availability.gd :: bee.is_queen`
   - Next after: BS-6 -- developer edits to the table change what a run starts with

4. **[Claude] L-16 -- master is synchronised with origin before a claim and before a merge**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-16 — master is synchronised with origin before a claim and before a merge"
   - Files: `tools/slice.ps1`, `tests/test_two_lane_closeout.py`, `tests/test_slice_lifecycle.py`
   - Check: `python -m unittest tests.test_two_lane_closeout tests.test_slice_lifecycle` passes with the remote-ahead case strict and the five new cases, and `tools/verify.ps1` is green
   - Proof: `absent: tools/slice.ps1 :: Sync-PrimaryMaster`
   - Next after: L-17 -- one console-encoding contract for the lifecycle, tested once

5. **[Claude] L-17 -- one console-encoding contract for the lifecycle, tested once**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-17 — one console-encoding contract for the lifecycle, tested once"
   - Files: `tools/slice.ps1`, `tests/test_slice_lifecycle.py`, `tests/test_source_checks.py`
   - Check: `python -m unittest tests.test_slice_lifecycle.ConsoleEncodingTest tests.test_source_checks` passes and `tools/verify.ps1` is green
   - Proof: `absent: tests/test_slice_lifecycle.py :: ConsoleEncodingTest`
   - Next after: none -- agent-lifecycle is complete once L-17 ships and the Objective's completion gate is met

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] UI-F-3 -- comb cell labels follow text scale**
   - Plan: `plans/now/ui-feedback.md` -- "UI-F-3 -- comb cell labels follow text scale"
   - Files: `scripts/hive_cell.gd`
   - Check: `grep -c "_label_font_size" scripts/hive_cell.gd` prints at least 2, and `tools/verify.ps1` is green
   - Proof: `present: scripts/hive_cell.gd :: info_label.add_theme_font_size_override("font_size", 9)`
   - Next after: UI-F-2 -- warnings carry a severity and a pending one is never lost

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **BS-6** (`plans/now/brood-spine.md`) -- startable since BS-8 landed (1 Oct 2026); waits for room in the Claude lane, which holds the feedback-build work Dave put first (1 Oct 2026).
- **Colony Run definition** (`plans/design/product-scope.md` §6.2, "Next design pass") -- a high-reasoning design pass Dave put next on 30 Sep 2026; startable since BS-4 landed (1 Oct 2026), it waits for the 3-4 Oct feedback session, whose notes feed it (Dave, 1 Oct 2026), and it specifies PE-2.
- **PE-2** (`plans/design/product-scope.md` §6.2) -- the played pacing arc waits for the Colony Run definition, which specifies it.
- **GC-3** (`plans/now/gameplay-consistency.md`) -- raising `nectar_per_honey` to 4.0 (Dave, 30 Sep 2026) waits for PE-2's arc as the multi-season evidence `.claude/rules/simulation.md` requires.
- **Progression Phase B step 8 onwards, and Phase C** (`plans/design/progression.md`) -- step 7 is `plans/now/brood-spine.md`; step 8 waits for the Colony Run definition, which Dave put first (30 Sep 2026); BS-4 proved a tier-2 purchase in a run on 1 Oct 2026.
- **Dr Gallerin guidance and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. The four goal layers now belong to the Colony Run definition (Dave, 30 Sep 2026).
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`
