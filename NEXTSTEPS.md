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

1. **[Codex] CR-5 -- remove cross-lane shared-file conflicts.**
   Give each hands-on check an independently owned record, treat generated
   coordination documentation as an integration product, and make `doctor`
   account for lifecycle-owned files when it checks lane overlap.
   - Plan: `plans/now/codex-reliability.md` -- "CR-5 — remove cross-lane shared-file conflicts"
   - Files: `tools/slice.ps1`, `tools/check_docs.py`, `checks/ready.md`,
     `plans/now/codex-reliability.md`
   - Check: two mock lane branches can file checks and close in either order
   - Proof: `absent: tools/slice.ps1 :: Get-ImplicitLifecycleFiles`
   - Next after: CR-6 (make headless evidence bounded and causal)

2. **[Claude] HC-7 -- the command tray's content fills the tray's width.**
   Set `SIZE_EXPAND_FILL` on the `VBoxContainer` inside `command_scroll`, so
   the Job/Focus/Orders columns HC-1 sized correctly are given a container
   wide enough to hold them side by side, and derive `_tray_chrome_width`
   from `UiLayout.panel_chrome()` so the even-width split and the scroll
   budget cannot disagree by two border widths.
   - Plan: `plans/now/hud-controls.md` -- "HC-7 — the command tray's content fills the tray's width"
   - Files: `scripts/hud.gd`
   - Check: C-18, in `checks/ready.md`
   - Proof: `absent: scripts/hud.gd :: column.size_flags_horizontal`
   - Next after: HC-9 (every button follows the text-size setting)

3. **[Codex] C2-2 -- the collapse button does what its tooltip says.**
   The button picks its target from the nectar currently in the hive, which
   the rescue has just topped up by 150, so the second press does nothing and
   the third is the one that reaches the failure floor. Dave confirmed the
   third-press behaviour again on 9 Sep. Count presses instead. The rescue
   line also needs `clear_queue()` before `show_now()`, or the stage's next
   hint overwrites it.
   - Plan: `plans/now/challenge-2.md` -- "Slice 2 — the collapse button does what its tooltip says, and the rescue line survives"
   - Files: `scripts/debug_panel.gd`, `scripts/challenge_runner.gd`, `scripts/gallerin_panel.gd`
   - Check: C-5, in `checks/ready.md`
   - Proof: `absent: scripts/debug_panel.gd :: _c2_collapse_presses`
   - Next after: C2-3 (the colony still has the pollen to act on the advice)

4. **[Claude] HC-9 -- every button follows the text-size setting.**
   `ui_theme.gd` sets `font_size` for its four type variations and, for the
   `Label` and `Button` base types, only colour and font. Give the base types
   the scaled Body size in the same loop, so an unmarked button matches the
   body text beside it. Changes the size of every button in the game, so boot
   and look before merging.
   - Plan: `plans/now/hud-controls.md` -- "HC-9 — every button follows the text-size setting"
   - Files: `scripts/ui_theme.gd`
   - Check: C-32, in `checks/ready.md`
   - Proof: `absent: scripts/ui_theme.gd :: set_font_size("font_size", base_type`
   - Next after: Challenge 1 Slice 20 (the designation stage asks for the designation it names)

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.

- **Challenge 1 Slices 20 to 24** (`plans/now/challenge-1.md`) -- all five are
  fully specified and startable on their merits. All five edit
  `scripts/challenge_runner.gd`, which the Codex lane's C2-2 is currently in,
  so they cannot lead the Claude lane while C2-2 is open. Slice 20 is the one
  that matters most -- it is the confirmed cause of C-30, C-31 and most of
  C-7 -- and it becomes the Claude lane's leading item the moment C2-2 merges.
  Slice 21 additionally waits on Slice 20 by design: until stage 1.13 runs, no
  cell in the hive accepts pollen and every pollen symptom has that as a
  sufficient cause.
- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough. Not worth a sixth attempt until Slices 20 to 24 have made the
  pollen arc work unattended.
- **HC-8** (`plans/now/hud-controls.md`) -- the tray's height after a
  deselect-reselect with `More…` open. Its cause is a stale container minimum
  or is not; the slice says to measure first, and its automated check wants
  LAY-5's rectangle helper.
- **HC-10 and HC-11** (`plans/now/hud-controls.md`) -- the Favourite star's
  move to the summary header, and per-entity cog options. Both edit
  `scripts/hud.gd`, which HC-7 leads with; one Claude branch at a time.
- **HC-12** (`plans/now/hud-controls.md`) -- the four GDScript warnings. Edits
  `scripts/debug_panel.gd`, the Codex lane's C2-2 file.
- **HC-5 and HC-6** (`plans/now/hud-controls.md`) -- both edit
  `scripts/gallerin_panel.gd`, also C2-2's. They wait for the Codex lane to
  move past it (C2-2, then C2-3).
- **UI-U-1** (`plans/now/ui.md`) -- arrows in Game Settings > World and Start
  for stepping back and forth through a Challenge's stages, which is the
  instrument for reaching stages 1.12 to 1.14 without a full playthrough. It
  edits both `scripts/debug_panel.gd` and `scripts/challenge_runner.gd`, so it
  waits for both lanes to vacate them.
- **LAY-5 and LAY-6** (`plans/now/layout-regression.md`) -- LAY-5, the
  headless panel-rectangle assertion, is startable and was the Claude lane's
  leading item before this pass; HC-7 and HC-9 went ahead of it because each
  closes a check that has now failed twice. LAY-6 depends on LAY-5's
  `viewport_size` verb, and would have caught HC-7's defect without a human.
- **Challenge 2 Slice 3** (`plans/now/challenge-2.md`) -- Dr Gallerin suggests
  a pollen Forager only after stage 2.1 has spent the colony's pollen on
  nectar Foragers. It shares `challenge_runner.gd` with Slice 2, so it follows
  it rather than competing with it.
- **SB-1 and SB-2** (`plans/now/season-balance.md`) -- CR-6 must first prove
  the bounded baseline simulation succeeds. SB-1 then returns with exact
  `Files:` and `Proof:` values that pass `slice.ps1 doctor`; SB-2 follows it.
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
