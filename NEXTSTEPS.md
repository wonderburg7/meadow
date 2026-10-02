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

1. **[Claude] SC-3 -- the project boots without GDScript warnings outside the HUD**
   - Plan: `plans/now/settings-and-corner.md` -- "SC-3 -- the project boots without GDScript warnings outside the HUD"
   - Files: `scripts/saves_panel.gd`, `scripts/debug_panel.gd`, `scripts/input_selection.gd`
   - Check: a headless boot prints no `GDScript::reload` warning for the three files, and `tools/verify.ps1` is green
   - Proof: `present: scripts/saves_panel.gd :: "%d min ago" % (seconds / 60)`
   - Next after: SC-4 -- the corner column holds PAUSED and its problem lines, and left windows follow its height

2. **[Claude] HO-9 -- "Back to the run" on a fresh boot leaves the menu up**
   - Plan: `plans/now/hands-on-findings.md` -- "HO-9 -- "Back to the run" on a fresh boot leaves the menu up"
   - Files: `scripts/main_menu.gd`
   - Check: on a fresh boot the menu shows no "Back to the run"; after starting a run and choosing Return to Main Menu it shows and resumes the run; a Godot boot is clean, a hands-on check is filed, and `tools/verify.ps1` is green
   - Proof: `absent: scripts/main_menu.gd :: _back_btn`
   - Next after: HO-12 -- a Challenge or Scenario hex breaks its name between words

3. **[Claude] HO-10 -- a queen who starves ends the run with "The queen is dead"**
   - Plan: `plans/now/hands-on-findings.md` -- "HO-10 -- a queen who starves ends the run with "The queen is dead""
   - Files: `scripts/main.gd`, `scripts/game_over.gd`, `tests/test_ho10_queen_starvation_ends_run.py`, `tests/ho10_queen_starvation_ends_run_test.gd`, `tools/verify.ps1`
   - Check: the new headless test fails on master before the fix and passes after it, a queen starved in Scenario 1 opens "The queen is dead", a Godot boot is clean, a hands-on check is filed, and `tools/verify.ps1` is green
   - Proof: `absent: tools/verify.ps1 :: tests.test_ho10_queen_starvation_ends_run`
   - Next after: HO-8 -- the HUD splits nectar and pollen Foragers and counts miners, so 2.9's shortfall can be read

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] SR-4 -- the command tray fits its content after a resize to 800x600**
   - Plan: `plans/now/scenario-reds.md` -- "SR-4 -- the command tray fits its content after a resize to 800x600"
   - Files: `scripts/hud.gd`, `scripts/ui_layout.gd`, `scripts/scenario_actions.gd`, `test_scenarios/uiw3_cell_tray_columns_test.json`
   - Check: `python tools/run_scenario.py test_scenarios/uiw3_cell_tray_columns_test.json` ends `status=passed` with its 800x600 asserts unchanged, and `tools/verify.ps1` is green
   - Proof: `present: test_scenarios/uiw3_cell_tray_columns_test.json :: {"do": "viewport_size", "w": 800, "h": 600}`
   - Next after: SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question

2. **[Codex] SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question**
   - Plan: `plans/now/scenario-reds.md` -- "SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question"
   - Files: `tests/test_sf1_founding_flower_mix.py`, `tests/source_checks.py`, `test_scenarios/sf1_founding_flower_mix_test.json`
   - Check: `python -m unittest tests.test_sf1_founding_flower_mix` passes with its `TESTS_NOT_IN_VERIFY` entry removed and `tools/verify.ps1` is green, or the slice stops with the evidence that the flower lifecycle is wrong
   - Proof: `present: tests/source_checks.py :: "test_sf1_founding_flower_mix":`
   - Next after: none -- plans/now/scenario-reds.md is complete

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **UT-4** (`plans/now/ui-texture-polish.md`) -- waits for UT-3, and for SR-4 (Codex lane) to land, since it edits `scripts/hud.gd`.
- **UT-5** (`plans/now/ui-texture-polish.md`) -- waits for UT-1 and UT-2, and for SR-2 and SR-4 (Codex lane) to land, since both edit `scripts/scenario_actions.gd`.
- **SC-4** (`plans/now/settings-and-corner.md`) -- waits for SR-4 (Codex lane) to land, since both edit `scripts/hud.gd`; it and UT-4 also share `hud.gd`, so they run one after the other.
- **BS-6** (`plans/now/brood-spine.md`) -- waits for SR-5 (Codex lane) to land, since both edit `tests/source_checks.py`; UI-F-2 freed `scripts/main.gd` on 1 Oct 2026.
- **Colony Run definition** (`plans/design/product-scope.md` §6.2, "Next design pass") -- a high-reasoning design pass Dave put next on 30 Sep 2026; startable since BS-4 landed (1 Oct 2026), it waits for the 3-4 Oct feedback session, whose notes feed it (Dave, 1 Oct 2026), and it specifies PE-2.
- **PE-2** (`plans/design/product-scope.md` §6.2) -- the played pacing arc waits for the Colony Run definition, which specifies it.
- **GC-3** (`plans/now/gameplay-consistency.md`) -- raising `nectar_per_honey` to 4.0 (Dave, 30 Sep 2026) waits for PE-2's arc as the multi-season evidence `.claude/rules/simulation.md` requires.
- **Progression Phase B step 8 onwards, and Phase C** (`plans/design/progression.md`) -- step 7 is `plans/now/brood-spine.md`; step 8 waits for the Colony Run definition, which Dave put first (30 Sep 2026); BS-4 proved a tier-2 purchase in a run on 1 Oct 2026.
- **Dr Gallerin guidance and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. The four goal layers now belong to the Colony Run definition (Dave, 30 Sep 2026).
- **HO-1** (`plans/now/hands-on-findings.md`) -- follows UT-2, which also edits `scripts/skill_tree_panel.gd`; HO-2 follows HO-1.
- **HO-3** (`plans/now/hands-on-findings.md`) -- follows SC-3, which also edits `scripts/debug_panel.gd`; HO-4 follows SC-3 (`scripts/saves_panel.gd`).
- **HO-5** (`plans/now/hands-on-findings.md`) -- waits for SC-4 and UT-4, which own its files; HO-6 follows HO-5 (`scripts/hud.gd`).
- **HO-8** (`plans/now/hands-on-findings.md`) -- specified (Dave, 2 Oct 2026); follows HO-7 (`scripts/challenge_runner.gd`), HO-6 (`scripts/hud.gd`) and BS-6 (`scripts/main.gd`).
- **BS-11** (`plans/now/brood-spine.md`) -- follows BS-6, which also edits `scripts/run_availability_panel.gd`.
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`
