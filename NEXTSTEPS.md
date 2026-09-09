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

1. **[Codex] C2-3 -- the colony still has the pollen to act on Dr Gallerin's advice.**
   Challenge 2 warns about pollen only after stage 2.1 has spent it on nectar
   Foragers, leaving the player unable to raise the pollen Forager that stage
   2.2 requests. Give the warning while it can still change the player's
   decision and supply a one-time pollen rescue if the stores bottom out.
   - Plan: `plans/now/challenge-2.md` -- "Slice 3 — the colony still has the pollen to act on Dr Gallerin's advice"
   - Files: `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`
   - Check: a hands-on check covering the stage-2.1 warning and one-time pollen top-up
   - Proof: `absent: scripts/challenge_stages.gd :: 2.1_pollen_reserve`
   - Next after: none -- admit the owning plan's next ready slice after C2-3 ships

2. **[Codex] CR-7 -- make the baseline's Godot environment failure reproducible.**
   Turn CR-6's `0xC0000005` outcome into a small, named baseline probe with
   engine/version evidence and a deterministic remediation or an explicit
   external-environment diagnosis. SB-1 stays blocked until the probe writes a
   summary.
   - Plan: `plans/now/codex-reliability.md` -- "CR-7 — make the baseline's Godot environment failure reproducible"
   - Files: `tools/run_scenario.py`, `test_scenarios/bee_movement_smoke_test.json`
   - Check: the CR-7 bounded baseline probe
   - Proof: `absent: tools/run_scenario.py :: HeadlessBaselineProbe`
   - Next after: SB-1 (return season balance with a successful bounded baseline)

3. **[Claude] LAY-5 -- a headless check fails when a panel leaves the viewport.**
   Four of Dave's hands-on passes have been spent re-finding the same class of
   defect: a persistent HUD panel losing its 16px gap or leaving the
   viewport, most recently HC-7's C-18. Add a `viewport_size` scenario verb
   and a `panel_rect` assertion so `tools/verify.ps1` catches it without a
   human, proven by reintroducing and then removing LAY-2's old bug in the
   same commit.
   - Plan: `plans/now/layout-regression.md` -- "LAY-5 — a headless check that fails when a panel leaves the viewport"
   - Files: `scripts/scenario_actions.gd`
   - Check: none -- the slice's own before/after test run is the acceptance evidence
   - Proof: `absent: scripts/scenario_actions.gd :: panel_rect`
   - Next after: LAY-6 (a headless check fails when a built control has no usable size)

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.

- **Challenge 1 Slices 20 to 24** (`plans/now/challenge-1.md`) -- all five are
  fully specified and startable on their merits. They are no longer blocked by
  C2-2, but the Claude lane is already working LAY-5. Slice 20 is the one
  that matters most -- it is the confirmed cause of C-30, C-31 and most of
  C-7 -- and it becomes the Claude lane's leading item when LAY-5 merges.
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
  `scripts/hud.gd`, free since HC-7 landed, and ready on their merits, but
  the Claude lane's leading item is LAY-5 instead -- the instrument that
  would have caught HC-7's and HC-9's classes of defect without a human. One
  Claude branch at a time; HC-10 is next after LAY-5.
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
- **LAY-6** (`plans/now/layout-regression.md`) -- depends on LAY-5's
  `viewport_size` verb and rectangle-reading helper. Becomes the Claude
  lane's leading item once LAY-5 merges.
- **Challenge 2 Slice 3** (`plans/now/challenge-2.md`) -- Dr Gallerin suggests
  a pollen Forager only after stage 2.1 has spent the colony's pollen on
  nectar Foragers. It shares `challenge_runner.gd` with Slice 2, so it follows
  it rather than competing with it.
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
