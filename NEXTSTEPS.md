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
   and two Challenge-1 checkboxes were each one small fault in
   `scripts/hud.gd`. That was HC-13, which landed on 10 Sep 2026 as C-37 and
   released C-34 back into `checks/ready.md`.
2. The queen's nectar is destroyed whenever Challenge 1's comb is full.
   `challenge_runner.gd::discards_overflow` carries the stage restriction in
   its comment and not in its code, so a rule meant for the pollen stage
   fires at every stage. That is Slice 25, and it is the most severe finding
   in the pass: it loses resources the player gathered by hand and can
   dead-end the run.
3. Dr Gallerin's bubble was the one persistent panel that set its own left
   edge instead of taking a rectangle from `ui_layout.gd`, which is why its
   gap to the tray was not the shared one. That was HC-14, which landed on
   10 Sep 2026 (`plans/archive/HC-14_2026-09-10.md`) and released HC-5 into
   the queue.

Dave answered two questions in the same session. Pixel-equal tray columns:
yes, unconditionally, which landed on 10 Sep 2026 as HC-15 (whenever three
columns genuinely fit on the row -- see `plans/archive/HC-15_2026-09-10.md`
for why the specified `GridContainer` swap did not survive 800x600). Soil-
button labels wrapping at a small viewport: not a fault, and C-32 keeps its
stated pass condition.

## Next up

1. **[Codex] C1-25 -- the queen's harvest is never thrown away without her being told.**
   Narrow Challenge 1's nectar-discard rule to the stage its own comment
   names, tell the player when it fires, and let the queen keep a load the
   comb cannot take at every other stage.
   - Plan: `plans/now/challenge-1.md` -- "Slice 25 — the queen's harvest is never thrown away without her being told"
   - Files: `scripts/challenge_runner.gd`, `scripts/challenge_stages.gd`, `scripts/bee_foraging.gd`
   - Check: one check reproducing Dave's 10 Sep 2026 sequence at stage 1.12
   - Proof: `absent: scripts/challenge_stages.gd :: C1_DISCARD_STAGES`
   - Next after: C1-21 (the queen forages pollen without being pushed)

2. **[Codex] C1-23 -- Challenge 1's wax cell is full at 150 nectar, not 200.**
   Add a `NECTAR_TARGET` constant beside the existing `POLLEN_TARGET` and
   have the nectar stage's goal check and progress bar use it instead of the
   cell's full 200 capacity, so the queen stops filling it at 150 and the
   nectar stage stays a demonstration rather than a chore.
   - Plan: `plans/now/challenge-1.md` -- "Slice 23 — a Challenge 1 wax cell is full at 150 nectar"
   - Files: `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`
   - Check: one check confirming the nectar stage's goal bar fills and the queen stops at 150, not 200
   - Proof: `absent: scripts/challenge_stages.gd :: NECTAR_TARGET`
   - Next after: C1-24 (the stage marker is never left in the wrong world, at 1.12 and 1.15)

3. **[Claude] UI-M-2 -- a hexagon's title fits inside it, at every text size.**
   The pre-run menu's tiles size their text from the theme and their label box
   from a fixed constant, so the longest Challenge title paints outside its
   hexagon. Clip the label, make the title fit at every text scale, and drop
   the punctuation after the Challenge and Scenario numbers.
   - Plan: `plans/now/ui.md` -- "UI-M-2 — a hexagon's title fits inside it, at every text size"
   - Files: `scripts/main_menu.gd`, `tests/fixtures/layout_panels.json`
   - Check: one check on the longest title at the largest text scale, plus the new title punctuation
   - Proof: `absent: scripts/main_menu.gd :: clip_text`
   - Next after: UI-P-5 (the pre-run menu's placeholder text is missing)

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.

- **Challenge 1 Slices 21, 22, 24 and 26** (`plans/now/challenge-1.md`) --
  all four are specified. Slice 21 waits on Slice 20 by design: until stage
  1.13 runs, no cell in the hive accepts pollen and every pollen symptom has
  that as a sufficient cause. Slice 26 (the marker pulses and shows an
  off-screen arrow, both Dave's 10 Sep asks) waits on Slice 24, the other
  open change to the same marker node. Slice 22 is startable on its merits
  but sits behind C1-25 and C1-23 in the same lane. Slice 24 is next after
  C1-23 and is queued as its `Next after:`.
- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough. Not worth a sixth attempt until Slices 20 to 26 have made the
  pollen arc work unattended.
- **HC-8** (`plans/now/hud-controls.md`) -- the tray is taller than its
  content until `More…` is toggled. Dave's 10 Sep report made this
  reproducible from the headless runner rather than by hand, but its own
  heading still calls for a measurement pass to confirm the cause before a
  fix is specified, which is why it is not a queue item yet.
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
