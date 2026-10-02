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

1. **[Claude] BS-10 -- C-81 tests the one run that buys Nurses**
   - Plan: `plans/now/brood-spine.md` -- "BS-10 — C-81 tests the one run that buys Nurses"
   - Files: `checks/ready/C-81.md`
   - Check: `checks/ready/C-81.md` starts Challenge 2 rather than level 7, and `python tools/check_docs.py` passes
   - Proof: `present: checks/ready/C-81.md :: start level 7 from the main menu`
   - Next after: BS-6 -- developer edits to the table change what a run starts with

2. **[Claude] SC-1 -- the settings window does not move under a Text scale click**
   - Plan: `plans/now/settings-and-corner.md` -- "SC-1 -- the settings window does not move under a Text scale click"
   - Files: `scripts/debug_panel.gd`, `checks/ready/C-72.md`
   - Check: run 1's sequence in `checks/ready/C-72.md` reproduces before the change and not after it, and `tools/verify.ps1` is green
   - Proof: `present: scripts/debug_panel.gd :: _text_scale_timer.timeout.connect(func() -> void: UiTheme.refresh_for_setting("text_scale"))`
   - Next after: SC-2 -- cycling the typeface logs no engine error

3. **[Claude] GC-4 -- a nurse moved to another job does not lose the brood food she carries**
   - Plan: `plans/now/gameplay-consistency.md` -- "GC-4 — a nurse moved to another job does not lose the brood food she carries"
   - Files: `scripts/bee.gd`, `test_scenarios/gc4_nurse_role_change_keeps_food_test.json`
   - Check: `test_scenarios/gc4_nurse_role_change_keeps_food_test.json` passes headless, a Godot boot is clean, and `tools/verify.ps1` is green
   - Proof: `present: scripts/bee.gd :: brood food a nurse was carrying isn't any use in another job`
   - Next after: GC-3 -- honey stops creating energy

5. **[Claude] UT-3 -- a theme change recolours the in-run panels' text**
   - Plan: `plans/now/ui-texture-polish.md` -- "UT-3 -- a theme change recolours the in-run panels' text"
   - Files: `scripts/ui_theme.gd`, `scripts/colony_panel.gd`, `scripts/foraging_panel.gd`, `scripts/nursery_panel.gd`, `scripts/winter_panel.gd`
   - Check: `grep -c 'add_theme_color_override("font_color", UiTheme.color' scripts/colony_panel.gd scripts/foraging_panel.gd scripts/nursery_panel.gd scripts/winter_panel.gd` prints 0 for each file, a Godot boot is clean, and `tools/verify.ps1` is green
   - Proof: `present: scripts/colony_panel.gd :: hint.add_theme_color_override("font_color", UiTheme.color("text_secondary"))`
   - Next after: UT-4 -- a theme change recolours the HUD, main menu and end screens

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] SR-2 -- the G3 fixture owns the Honey worker skill**
   - Plan: `plans/now/scenario-reds.md` -- "SR-2 -- the G3 fixture owns the Honey worker skill"
   - Files: `test_scenarios/g3_actions_offered_test.json`, `scripts/scenario_actions.gd`
   - Check: `python tools/run_scenario.py test_scenarios/g3_actions_offered_test.json` ends `status=passed`, and `tools/verify.ps1` is green
   - Proof: `absent: test_scenarios/g3_actions_offered_test.json :: skill.brood.honey_worker`
   - Next after: SR-3 -- the disease-off fixture starts every bee newborn

2. **[Codex] SR-3 -- the disease-off fixture starts every bee newborn**
   - Plan: `plans/now/scenario-reds.md` -- "SR-3 -- the disease-off fixture starts every bee newborn"
   - Files: `test_scenarios/h5_disease_off_test.json`
   - Check: `python tools/run_scenario.py test_scenarios/h5_disease_off_test.json` ends `status=passed`, and `tools/verify.ps1` is green
   - Proof: `absent: test_scenarios/h5_disease_off_test.json :: starter_age_spread`
   - Next after: SR-4 -- the command tray fits its content after a resize to 800x600

3. **[Codex] SR-4 -- the command tray fits its content after a resize to 800x600**
   - Plan: `plans/now/scenario-reds.md` -- "SR-4 -- the command tray fits its content after a resize to 800x600"
   - Files: `scripts/hud.gd`, `scripts/ui_layout.gd`, `scripts/scenario_actions.gd`, `test_scenarios/uiw3_cell_tray_columns_test.json`
   - Check: `python tools/run_scenario.py test_scenarios/uiw3_cell_tray_columns_test.json` ends `status=passed` with its 800x600 asserts unchanged, and `tools/verify.ps1` is green
   - Proof: `present: test_scenarios/uiw3_cell_tray_columns_test.json :: {"do": "viewport_size", "w": 800, "h": 600}`
   - Next after: SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question

4. **[Codex] SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question**
   - Plan: `plans/now/scenario-reds.md` -- "SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question"
   - Files: `tests/test_sf1_founding_flower_mix.py`, `tests/source_checks.py`, `test_scenarios/sf1_founding_flower_mix_test.json`
   - Check: `python -m unittest tests.test_sf1_founding_flower_mix` passes with its `TESTS_NOT_IN_VERIFY` entry removed and `tools/verify.ps1` is green, or the slice stops with the evidence that the flower lifecycle is wrong
   - Proof: `present: tests/source_checks.py :: "test_sf1_founding_flower_mix":`
   - Next after: none -- plans/now/scenario-reds.md is complete

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **UT-4** (`plans/now/ui-texture-polish.md`) -- waits for UT-3, and for SR-4 (Codex lane) to land, since it edits `scripts/hud.gd`.
- **UT-5** (`plans/now/ui-texture-polish.md`) -- waits for UT-1 and UT-2, and for SR-2 and SR-4 (Codex lane) to land, since both edit `scripts/scenario_actions.gd`.
- **SC-2** (`plans/now/settings-and-corner.md`) -- startable, but the Claude lane is full; it follows UT-1 and UT-3, which also edit `scripts/ui_theme.gd`.
- **SC-3** (`plans/now/settings-and-corner.md`) -- startable, but the Claude lane is full; it follows SC-1, which also edits `scripts/debug_panel.gd`.
- **SC-4** (`plans/now/settings-and-corner.md`) -- waits for SR-4 (Codex lane) to land, since both edit `scripts/hud.gd`; it and UT-4 also share `hud.gd`, so they run one after the other.
- **BS-6** (`plans/now/brood-spine.md`) -- waits for SR-5 (Codex lane) to land, since both edit `tests/source_checks.py`; UI-F-2 freed `scripts/main.gd` on 1 Oct 2026.
- **Colony Run definition** (`plans/design/product-scope.md` §6.2, "Next design pass") -- a high-reasoning design pass Dave put next on 30 Sep 2026; startable since BS-4 landed (1 Oct 2026), it waits for the 3-4 Oct feedback session, whose notes feed it (Dave, 1 Oct 2026), and it specifies PE-2.
- **PE-2** (`plans/design/product-scope.md` §6.2) -- the played pacing arc waits for the Colony Run definition, which specifies it.
- **GC-3** (`plans/now/gameplay-consistency.md`) -- raising `nectar_per_honey` to 4.0 (Dave, 30 Sep 2026) waits for PE-2's arc as the multi-season evidence `.claude/rules/simulation.md` requires.
- **Progression Phase B step 8 onwards, and Phase C** (`plans/design/progression.md`) -- step 7 is `plans/now/brood-spine.md`; step 8 waits for the Colony Run definition, which Dave put first (30 Sep 2026); BS-4 proved a tier-2 purchase in a run on 1 Oct 2026.
- **Dr Gallerin guidance and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. The four goal layers now belong to the Colony Run definition (Dave, 30 Sep 2026).
- **HO-7** (`plans/now/hands-on-findings.md`) -- startable (Dave chose (b), 2 Oct 2026), but the Claude lane is full.
- **HO-1** (`plans/now/hands-on-findings.md`) -- follows UT-2, which also edits `scripts/skill_tree_panel.gd`; HO-2 follows HO-1.
- **HO-3** (`plans/now/hands-on-findings.md`) -- follows SC-1 and SC-3, which also edit `scripts/debug_panel.gd`; HO-4 follows SC-3 (`scripts/saves_panel.gd`).
- **HO-5** (`plans/now/hands-on-findings.md`) -- waits for SC-4, UT-3 and UT-4, which own its files; HO-6 follows HO-5 (`scripts/hud.gd`).
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
