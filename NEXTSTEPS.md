# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane Claude`
(or `-Lane Codex`) to claim your lane's leading item and open its worktree,
open only the `Plan:` file and heading that item names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`).
Do not read the other lane's plan, the archive, `ROADMAP.md` or Git history
to work out what to do -- the script already decided.

**Dave's second 9 Sep 2026 hands-on pass reset both lanes.** C-19 and C-26
passed, so every slice `plans/archive/PANEL_LAYOUT_2026-09-09.md` owned has
landed and that plan is archived. C-18 passed on everything except its column
layout. C-7 failed in five ways and C-5 failed on its press count.

Two new plans came out of it. `plans/now/challenge-1.md` gained Slices 16 to
19: Challenge 1's automatic-foraging arc does not work, and the tutorial
stalls at the pollen stage with the queen holding a load nothing in the hive
will accept. `plans/now/hud-controls.md` gained HC-1 to HC-6, four controls
that do not occupy the space they were built for and two features Dave asked
for on Dr Gallerin's bubble.

The class of bug behind the second group is written up in
`docs/known-pitfalls.md`: a Godot container gives a child its minimum size,
and `HFlowContainer` ignores expand flags, `clip_text` plus autowrap makes the
minimum zero, and `MenuButton` is flat by default. LAY-6 in
`plans/now/layout-regression.md` is the assertion that would have caught all
three without a human.

Every item below is specified down to the function and the line, because each
was diagnosed against the source during the 9 Sep pass.

## Next up

1. **[Codex] CR-4 -- make the lifecycle failure-atomic and idempotent.**
   Add recoverable lifecycle states and commands, preflight rollback, and a
   repository lock so an interrupted claim or close can resume without manual
   Git repair.
   - Plan: `plans/now/codex-reliability.md` -- "CR-4 — make the lifecycle failure-atomic and idempotent"
   - Files: `tools/slice.ps1`, `tests/test_source_checks.py`,
     `plans/now/codex-reliability.md`
   - Check: injected lifecycle-phase failures recover through `resume`
   - Proof: `absent: tools/slice.ps1 :: Invoke-SliceResume`
   - Next after: CR-5 (remove cross-lane shared-file conflicts)

2. **[Claude] C1-19 -- the stage's automation switches off when the stage
   ends.** Dave reported 4x speed doesn't reset at the stage ends. Both
   `1.11` and the pollen stage declare an `on_exit` that resets it, but a
   stage that never completes never runs its `on_exit` -- make the reset
   independent of a stage completing normally by giving `_complete()` and
   the checkpoint-restore path their own explicit call.
   - Plan: `plans/now/challenge-1.md` -- "Slice 19 — the stage's automation switches off when the stage ends"
   - Files: `scripts/challenge_runner.gd`
   - Check: finishing 1.11 or the pollen stage returns the game to 1x speed and releases the camera; abandoning Challenge 1 does too
   - Proof: `absent: scripts/challenge_runner.gd :: _run_stage_effects(["camera_follow_off", "speed_multiplier:1.0"])`
   - Next after: C1-7 (Slice 7 — acceptance pass and documentation, the plan's last open slice)

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

4. **[Claude] HC-1 -- the command tray's three columns share its width.**
   The three column wrappers ask to expand, but their parent is an
   `HFlowContainer`, which lays children out at their minimum size and
   ignores expand flags. All three bunch against the tray's left edge.
   Compute an even third of the tray's inner width and fall back to wrapping
   when that is narrower than a column's own content.
   - Plan: `plans/now/hud-controls.md` -- "HC-1 — the command tray's three columns share its width evenly"
   - Files: `scripts/hud.gd`
   - Check: C-18, in `checks/ready.md`
   - Proof: `absent: scripts/hud.gd :: TRAY_COLUMN_SEPARATION`
   - Next after: HC-2 (the soil panel's two buttons take the panel's width)

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough, mostly Dave's run rather than a code slice, though its own
  boot/checklist pass is startable once Slice 19 lands. Starting it before
  Slice 19 lands only rediscovers C-7.
- **HC-2 to HC-6** (`plans/now/hud-controls.md`) -- all six edit
  `scripts/hud.gd`, `scripts/ui_theme.gd` or `scripts/gallerin_panel.gd`, and
  one Claude branch runs at a time; they follow HC-1 in order.
- **LAY-5 and LAY-6** (`plans/now/layout-regression.md`) -- the guard rail for
  both layout groups, and startable, but it asserts against the controls HC-1
  and HC-2 fix. Running it first would file assertions that describe the bug.
  LAY-5 leads the lane again once HC-2 lands.
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
  four passes since 8 Sep has reported on it.
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
