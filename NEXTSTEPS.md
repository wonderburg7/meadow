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

1. **[Claude] SR-4 -- the command tray fits its content after a resize to 800x600**
   - Plan: `plans/now/scenario-reds.md` -- "SR-4 -- the command tray fits its content after a resize to 800x600"
   - Files: `scripts/hud.gd`, `scripts/ui_layout.gd`, `scripts/scenario_actions.gd`, `test_scenarios/uiw3_cell_tray_columns_test.json`
   - Check: `python tools/run_scenario.py test_scenarios/uiw3_cell_tray_columns_test.json` ends `status=passed` with its 800x600 asserts unchanged, and `tools/verify.ps1` is green
   - Proof: `present: test_scenarios/uiw3_cell_tray_columns_test.json :: {"do": "viewport_size", "w": 800, "h": 600}`
   - Next after: SC-4 -- the corner column holds PAUSED and its problem lines, and left windows follow its height

2. **[Claude] SC-4 -- the corner column holds PAUSED and its problem lines, and left windows follow its height**
   - Plan: `plans/now/settings-and-corner.md` -- "SC-4 -- the corner column holds PAUSED and its problem lines, and left windows follow its height"
   - Files: `scripts/hud.gd`, `scripts/game_panel.gd`
   - Check: `python tools/gdscript_warnings.py scripts/hud.gd` passes, a hands-on check is filed for PAUSED, the wrapped strip and the Colony window at Text scale 2 in Open Sans, and `tools/verify.ps1` is green
   - Proof: `present: scripts/hud.gd :: pause_label = _make_label(Vector2(16, 300), "Heading")`
   - Next after: none -- plans/now/settings-and-corner.md is complete

3. **[Claude] UT-4 -- a theme change recolours the HUD, main menu and end screens**
   - Plan: `plans/now/ui-texture-polish.md` -- "UT-4 -- a theme change recolours the HUD, main menu and end screens"
   - Files: `scripts/hud.gd`, `scripts/main_menu.gd`, `scripts/game_over.gd`, `scripts/challenge_complete.gd`
   - Check: `grep -c 'add_theme_color_override("font_color", UiTheme.color' scripts/hud.gd scripts/main_menu.gd scripts/game_over.gd scripts/challenge_complete.gd` prints 0 for each file, a Godot boot is clean, and `tools/verify.ps1` is green
   - Proof: `present: scripts/main_menu.gd :: add_theme_color_override("font_color", UiTheme.color(`
   - Next after: UT-5 -- headless assertions for texture contrast and Buy clearance

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question**
   - Plan: `plans/now/scenario-reds.md` -- "SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question"
   - Files: `tests/test_sf1_founding_flower_mix.py`, `tests/source_checks.py`, `test_scenarios/sf1_founding_flower_mix_test.json`
   - Check: `python -m unittest tests.test_sf1_founding_flower_mix` passes with its `TESTS_NOT_IN_VERIFY` entry removed and `tools/verify.ps1` is green, or the slice stops with the evidence that the flower lifecycle is wrong
   - Proof: `present: tests/source_checks.py :: "test_sf1_founding_flower_mix":`
   - Next after: none -- plans/now/scenario-reds.md is complete

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **UT-5** (`plans/now/ui-texture-polish.md`) -- waits for SR-4 (now in the Claude lane) to land, since both edit `scripts/scenario_actions.gd`; UT-1, UT-2 and SR-2 have landed.
- **BS-6** (`plans/now/brood-spine.md`) -- waits for SR-5 (Codex lane) to land, since both edit `tests/source_checks.py`, and follows BS-11 (`scripts/run_availability_panel.gd`); UI-F-2 freed `scripts/main.gd` on 1 Oct 2026.
- **Colony Run definition** (`plans/design/product-scope.md` §6.2, "Next design pass") -- a high-reasoning design pass Dave put next on 30 Sep 2026; startable since BS-4 landed (1 Oct 2026), it waits for the 3-4 Oct feedback session, whose notes feed it (Dave, 1 Oct 2026), and it specifies PE-2.
- **PE-2** (`plans/design/product-scope.md` §6.2) -- the played pacing arc waits for the Colony Run definition, which specifies it.
- **GC-3** (`plans/now/gameplay-consistency.md`) -- raising `nectar_per_honey` to 4.0 (Dave, 30 Sep 2026) waits for PE-2's arc as the multi-season evidence `.claude/rules/simulation.md` requires.
- **Progression Phase B step 8 onwards, and Phase C** (`plans/design/progression.md`) -- step 7 is `plans/now/brood-spine.md`; step 8 waits for the Colony Run definition, which Dave put first (30 Sep 2026); BS-4 proved a tier-2 purchase in a run on 1 Oct 2026.
- **Dr Gallerin guidance and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. The four goal layers now belong to the Colony Run definition (Dave, 30 Sep 2026).
- **HO-5** (`plans/now/hands-on-findings.md`) -- waits for SC-4 and UT-4, which own its files; HO-6 follows HO-5 (`scripts/hud.gd`).
- **HO-8** (`plans/now/hands-on-findings.md`) -- specified (Dave, 2 Oct 2026); follows HO-7 (`scripts/challenge_runner.gd`), HO-6 (`scripts/hud.gd`) and BS-6 (`scripts/main.gd`).
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`
