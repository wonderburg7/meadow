# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane Claude`
(or `-Lane Codex`) to claim your lane's leading item and open its worktree,
open only the `Plan:` file and heading that item names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`).
Do not read the other lane's plan, the archive, `ROADMAP.md` or Git history
to work out what to do -- the script already decided.

**Dave's fourth 9-10 Sep 2026 hands-on pass ran eleven checks.** Four passed
and are archived. Four passed the fault their own slice named and failed on a
cause underneath it. Two failed outright on a cause already being worked. One
could not be run at all.

Every remaining fault in that pass has been traced to the line, so nothing
below is a guess:

1. Two tray controls, the summary panel's star, three empty summary labels
   and two Challenge-1 checkboxes are each one small, confirmed fault in
   `scripts/hud.gd`. Together they are HC-13, and HC-13 is also what unblocks
   C-34 -- the cell popup's "Raises:" menus never say they are menus.
2. The queen's nectar is destroyed whenever Challenge 1's comb is full.
   `challenge_runner.gd::discards_overflow` carries the stage restriction in
   its comment and not in its code, so a rule meant for the pollen stage
   fires at every stage. That is Slice 25, and it is the most severe finding
   in the pass: it loses resources the player gathered by hand and can
   dead-end the run.
3. Dr Gallerin's bubble is the one persistent panel that sets its own left
   edge instead of taking a rectangle from `ui_layout.gd`, which is why its
   gap to the tray is not the shared one. That is HC-14.

Dave answered two questions in the same session. Pixel-equal tray columns:
yes, unconditionally, which is HC-15. Soil-button labels wrapping at a small
viewport: not a fault, and C-32 keeps its stated pass condition.

## Next up

1. **[Codex] C1-20 -- the designation stage asks for the designation it names.**
   Keep Challenge 1 stage 1.13 open until the player explicitly reserves a
   cell for pollen, without changing Challenge 2's existing general
   designation goal. This repairs the shared root cause behind C-30 and C-31.
   - Plan: `plans/now/challenge-1.md` -- "Slice 20 — the designation stage asks for the designation it names"
   - Files: `scripts/challenge_runner.gd`, `scripts/challenge_stages.gd`, `docs/challenge-stages.md`
   - Check: re-file C-30 and C-31 unchanged after the automated regression test passes
   - Proof: `absent: scripts/challenge_runner.gd :: _goal_check_pollen_cell_designated`
   - Next after: C1-25 (the queen's harvest is never thrown away without her being told)

2. **[Claude] HC-13 -- the tray and summary panel's controls match their neighbours.**
   Five confirmed faults in `scripts/hud.gd`: two tray controls that render
   2px larger than the rest, a Favourite star shorter than the cog beside it,
   three empty summary labels that keep their line height, two Challenge-1
   checkboxes shown before they are taught, and a "Raises:" menu with nothing
   saying a menu opens from it.
   - Plan: `plans/now/hud-controls.md` -- "HC-13 — the tray and summary panel's controls match their neighbours"
   - Files: `scripts/hud.gd`, `tests/fixtures/layout_panels.json`
   - Check: one check covering all five requirements; move C-34 back to `checks/ready.md` with its id
   - Proof: `absent: scripts/hud.gd :: SUMMARY_HEADER_BUTTON_SIZE`
   - Next after: HC-15 (the tray's three columns take an equal third each)

3. **[Codex] C1-25 -- the queen's harvest is never thrown away without her being told.**
   Narrow Challenge 1's nectar-discard rule to the stage its own comment
   names, tell the player when it fires, and let the queen keep a load the
   comb cannot take at every other stage.
   - Plan: `plans/now/challenge-1.md` -- "Slice 25 — the queen's harvest is never thrown away without her being told"
   - Files: `scripts/challenge_runner.gd`, `scripts/challenge_stages.gd`, `scripts/bee_foraging.gd`
   - Check: one check reproducing Dave's 10 Sep 2026 sequence at stage 1.12
   - Proof: `absent: scripts/challenge_stages.gd :: C1_DISCARD_STAGES`
   - Next after: C1-21 (the queen forages pollen without being pushed)

4. **[Claude] HC-15 -- the tray's three columns take an equal third each.**
   LAY-6 measured the Job/Focus/Orders wrappers at 170/100/127px. Divide the
   tray's inner width into three equal parts and tighten `even_columns` from
   its 80px tolerance to 2px so it cannot drift back.
   - Plan: `plans/now/hud-controls.md` -- "HC-15 — the tray's three columns take an equal third each"
   - Files: `scripts/hud.gd`, `tests/fixtures/layout_panels.json`
   - Check: re-file C-18 unchanged; this answers the last of its conditions
   - Proof: `absent: scripts/hud.gd :: _tray_column_share`
   - Next after: HC-14 (Dr Gallerin's bubble is given its rectangle like every other panel)

5. **[Claude] HC-14 -- Dr Gallerin's bubble is given its rectangle like every other panel.**
   Route the bubble through `ui_layout.gd::gallerin_rect()` and
   `ui_panel_layout.gd::apply()`, so all three bottom-row panels get their
   horizontal edges from one owner and an assertion can prove the two gaps
   are equal.
   - Plan: `plans/now/hud-controls.md` -- "HC-14 — Dr Gallerin's bubble is given its rectangle like every other panel"
   - Files: `scripts/gallerin_panel.gd`, `scripts/ui_layout.gd`, `scripts/ui_panel_layout.gd`
   - Check: one check on the two bottom-row gaps at two viewport sizes
   - Proof: `absent: scripts/gallerin_panel.gd :: UiPanelLayout`
   - Next after: HC-5 (Dr Gallerin's bubble types its line out)

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.

- **Challenge 1 Slices 21 to 24 and 26** (`plans/now/challenge-1.md`) -- all
  five are specified. Slice 21 waits on Slice 20 by design: until stage 1.13
  runs, no cell in the hive accepts pollen and every pollen symptom has that
  as a sufficient cause. Slice 26 (the marker pulses and shows an off-screen
  arrow, both Dave's 10 Sep asks) waits on Slice 24, the other open change to
  the same marker node. Slices 22 and 23 are startable on their merits but
  sit behind C1-20 and C1-25 in the same lane.
- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough. Not worth a sixth attempt until Slices 20 to 26 have made the
  pollen arc work unattended.
- **HC-8** (`plans/now/hud-controls.md`) -- the tray is taller than its
  content until `More…` is toggled. Dave's 10 Sep report made this
  reproducible from the headless runner rather than by hand, so its own
  measurement step is now the implementer's to take. It is out of the queue
  only because it shares `scripts/hud.gd` with HC-13 and HC-15, which are
  ahead of it in the same lane.
- **HC-5 and HC-6** (`plans/now/hud-controls.md`) -- Dr Gallerin's bubble
  types its line out, and pages back through her history. Both edit
  `scripts/gallerin_panel.gd`, which HC-14 holds until it lands.
- **UI-M-2** (`plans/now/ui.md`) -- the pre-run menu's hexagon titles spill
  outside their tiles, plus Dave's request to drop the punctuation after the
  Challenge and Scenario numbers. Fully specified and startable on its
  merits; it is out only because the Claude lane already holds three items.
- **UI-U-1** (`plans/now/ui.md`) -- arrows in Game Settings > World and Start
  for stepping back and forth through a Challenge's stages, which is the
  instrument for reaching stages 1.12 to 1.14 without a full playthrough. It
  edits both `scripts/debug_panel.gd` and `scripts/challenge_runner.gd`, so it
  waits for both lanes to vacate them.
- **SB-1 and SB-2** (`plans/now/season-balance.md`) -- CR-6 now produces a
  bounded, classified baseline result, but the 9 Sep smoke baseline still
  exits `0xC0000005` before writing a summary. Diagnose or repair that Godot
  environment failure before SB-1 returns with exact `Files:` and `Proof:`
  values that pass `slice.ps1 doctor`; SB-2 follows it.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- Slice 4's
  headless trace found the mechanism (every idle Comb Worker piles onto one
  unfinished site), but capping builders per site changes build throughput,
  so it wants Dave's live look and a call on intended behaviour. Slice 5
  wants its own reproduction.
- **UI-P-5** (`plans/now/ui.md`) -- names two plausible causes and says to
  reproduce the symptom live before choosing between them. None of Dave's
  six passes since 8 Sep has reported on it.
- **Progression Phase B step 6 onwards** (`plans/design/progression.md`) --
  the foraging tier-1 vertical slice is where the tree panel, the HUD button
  and run saving first appear. Phase A (steps 1-4) is complete precisely
  because it stops short of it. Its acceptance is something Dave sees, so it
  wants a clear run of the UI work above rather than to compete with it.
- **The cell-art rings' last pixel** -- C-20 passed with "move the cell-art
  highlight rings 1 px higher". One constant, too small for a slice of its
  own; it rides with the next slice that opens the cell-art drawing, and is
  recorded in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md` under C-20 so it is
  not lost.
- **Save/load during an active Challenge** -- a settled design decision, not
  a defect. `DESIGN_BACKLOG.md` holds it; it is not restated here.

## Copy-paste prompts

Start a new session with one of these and nothing else.

Claude, implementing:

```
Implement the next slice.
```

Codex, implementing:

```
Read CHATGPT.md, then NEXTSTEPS.md. Implement the first unclaimed [Codex] item
in the Next up queue. Follow its Plan heading only. Claim it with
tools/slice.ps1 start -Lane Codex, implement, run tools/verify.ps1, then close
out per CHATGPT.md's "Risk-proportional closeout".
```

Claude, integrating a high-risk Codex branch (the only kind handed over):

```
Integrate the finished Codex branch and close it out.
```

Claude, when Dave has done a hands-on pass:

```
I've done a hands-on pass. Here's what I found: <notes>. Update the checks,
plans and queue.
```
