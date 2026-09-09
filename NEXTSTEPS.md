# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane Claude`
(or `-Lane Codex`) to claim your lane's leading item and open its worktree,
open only the `Plan:` file and heading that item names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`).
Do not read the other lane's plan, the archive, `ROADMAP.md` or Git history
to work out what to do -- the script already decided.

**Dave's third 9 Sep 2026 hands-on pass reset the Claude lane.** Seven checks
were run and none passed outright. C-18 and C-32 failed for causes *beneath*
the ones HC-1 and HC-2 fixed, so both slices did what they specified and both
checks still fail. C-30 failed outright and turned out to be the cause of
C-31 and of most of C-7's pollen half as well. C-29's pollen half failed on
the camera only. C-5 failed again on its press count and is still the Codex
lane's C2-2, untouched by this pass.

Three confirmed root causes came out of it, each written up in
`docs/known-pitfalls.md`:

1. A Godot `ScrollContainer` gives its child the child's minimum width unless
   the child sets `SIZE_EXPAND`. The command tray's content never does, so
   HC-1's correct column widths were handed to a container one column wide.
   That is C-18, and the blank space Dave photographed with `More…` open.
2. `ui_theme.gd` scales the four named type variations and not the `Label`
   and `Button` base types, so no plain button in the game follows the
   text-size setting. That is C-32.
3. Challenge 1's stage 1.13 goal passes on *any* designated cell, and
   `HiveCell.add_resource` auto-designates a cell on its first deposit, so
   the first cell satisfied it at stage 1.10 and the stage cleared in the
   frame it opened. That is C-30, and it takes C-31 and the pollen arc with
   it.

Two more reports have confirmed causes and small fixes: a stage marker that
is shown without being reparented, which puts a yellow dot in the meadow
(Challenge 1 Slice 24), and four GDScript warnings on boot (HC-12). Two need
a measurement before a fix can be specified: the tray's height after a
reselect (HC-8) and the pollen stage's missing camera-follow (Challenge 1
Slice 22). Both say so in their own headings rather than guessing.

Every item below is specified down to the function and the line, because each
was diagnosed against the source during the 9 Sep pass.

## Next up

1. **[Codex] C1-20 -- the designation stage asks for the designation it names.**
   Keep Challenge 1 stage 1.13 open until the player explicitly reserves a
   cell for pollen, without changing Challenge 2's existing general
   designation goal. This repairs the shared root cause behind C-30 and C-31.
   - Plan: `plans/now/challenge-1.md` -- "Slice 20 — the designation stage asks for the designation it names"
   - Files: `scripts/challenge_runner.gd`, `scripts/challenge_stages.gd`, `docs/challenge-stages.md`
   - Check: re-file C-30 and C-31 unchanged after the automated regression test passes
   - Proof: `absent: scripts/challenge_runner.gd :: _goal_check_pollen_cell_designated`
   - Next after: C1-21 (investigate the queen's pollen-foraging stall after C1-20 lands)

2. **[Codex] C1-21 -- the queen forages pollen without being pushed.**
   After C1-20 lands and C-30 is re-run, trace the queen at stage 1.14 and
   repair only the confirmed reason a pollen focus change leaves her waiting.
   - Plan: `plans/now/challenge-1.md` -- "Slice 21 — the queen forages pollen without being pushed"
   - Files: `scripts/bee.gd`, `scripts/bee_foraging.gd`, `scripts/challenge_stages.gd`
   - Check: headless stage-1.14 scenario proves a focus change starts pollen foraging and preserves the nectar arc
   - Proof: `absent: scripts/bee_foraging.gd :: c1_pollen_focus_trace`
   - Next after: C1-22 (reach the pollen stage with the camera)

3. **[Claude] HC-10 -- the Favourite star's move to the summary header.**
   Dave, 9 Sep 2026: "There should not be a 'Mark: Favourite' button at the
   bottom of the command tray, this should be a single star without words to
   the left of the settings cog in the bee summary window." Delete
   `_build_favourite_row` and its `more_panel` call, and add a `☆`/`★` toggle
   to the summary header next to the cog instead.
   - Plan: `plans/now/hud-controls.md` -- "HC-10 — the Favourite star sits in the summary panel's header"
   - Files: `scripts/hud.gd`
   - Check: one hands-on check that the star appears left of the cog for a single bee, toggles, survives a reselect, and is absent for a cell
   - Proof: `present: scripts/hud.gd :: _build_favourite_row`
   - Next after: HC-11 (every summary panel's cog offers bee-only options)

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.

- **Challenge 1 Slices 20 to 24** (`plans/now/challenge-1.md`) -- all five are
  fully specified and startable on their merits, and no longer blocked by
  C2-2, but the Claude lane's leading item is HC-10 instead. Slice 20 is the
  one that matters most -- it is the confirmed cause of C-30, C-31 and most
  of C-7. Slice 21 additionally waits on Slice 20 by design: until stage 1.13
  runs, no cell in the hive accepts pollen and every pollen symptom has that
  as a sufficient cause.
- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough. Not worth a sixth attempt until Slices 20 to 24 have made the
  pollen arc work unattended.
- **HC-8** (`plans/now/hud-controls.md`) -- the tray's height after a
  deselect-reselect with `More…` open. Its cause is a stale container minimum
  or is not; the slice says to measure first. Its automated check can now use
  LAY-5's `panel_rect`/`control_rect` assertions (shipped 9 Sep 2026), but the
  live measurement is still the blocker.
- **HC-11** (`plans/now/hud-controls.md`) -- every summary panel's cog offers
  bee-only options. Edits `scripts/hud.gd`, free since HC-7 landed and ready
  on its merits, but the Claude lane's leading item is HC-10 instead. One
  Claude branch at a time; HC-11 is next after HC-10.
- **HC-12** (`plans/now/hud-controls.md`) -- the four GDScript warnings. Edits
  `scripts/hud.gd` and `scripts/debug_panel.gd`; the Claude lane's leading
  item (HC-10) already owns `hud.gd`, so it waits behind HC-10/HC-11.
- **HC-5 and HC-6** (`plans/now/hud-controls.md`) -- both edit
  `scripts/gallerin_panel.gd`. Not currently owned by either lane's leading
  item; worth re-checking against the live queue before assuming they still
  wait on anything.
- **UI-U-1** (`plans/now/ui.md`) -- arrows in Game Settings > World and Start
  for stepping back and forth through a Challenge's stages, which is the
  instrument for reaching stages 1.12 to 1.14 without a full playthrough. It
  edits both `scripts/debug_panel.gd` and `scripts/challenge_runner.gd`, so it
  waits for both lanes to vacate them.
- **The command tray's three columns are not pixel-even** -- LAY-6's new
  `even_columns` assertion (9 Sep 2026) measured the Job/Focus/Orders wrapper
  widths for a single selected forager at 170/100/127px, not equal. HC-1 (the
  same symptom) is archived as landed, and the catastrophic "bunched at the
  left edge" case it actually fixed stays fixed -- this is each wrapper
  sizing to its own content's natural width inside the `HFlowContainer`
  rather than to an equal one-third share, which the container was never
  changed to enforce. `tests/fixtures/layout_panels.json`'s own `even_columns`
  check uses a wide (80px) tolerance to pass on this, so it stays live for a
  worse regression. Wants Dave's call on whether true pixel-equal columns
  matter enough to justify a `GridContainer`-style layout change to
  `hud.gd::_build_command_tray`, before a slice is written.
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
  five passes since 8 Sep has reported on it.
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
