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

2. **[Codex] C2-2 -- the collapse button does what its tooltip says.**
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

3. **[Claude] HC-4 -- the default text size goes up by 2px.**
   Dave asked to increase the default text pixel size by 2. In
   `ui_theme.gd::TYPE_SIZES` (`:207`) add 2 to each value: Heading 16 → 18,
   Body 13 → 15, Small 11 → 13, Tiny 9 → 11. Then re-measure
   `UiLayout.SELECTION_TRAY_MIN_WIDTH`, `GallerinPanel.BUBBLE_WIDTH` and the
   100px column minimum in `hud.gd::_build_tray_column()` at 800x600, raising
   any that now clip text.
   - Plan: `plans/now/hud-controls.md` -- "HC-4 — the default text size goes up by 2px"
   - Files: `scripts/ui_theme.gd`
   - Check: a new check at 800x600 and the largest text scale
   - Proof: `present: scripts/ui_theme.gd :: "Heading": 16,`
   - Next after: HC-5 (Dr Gallerin's bubble types its line out)

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough, mostly Dave's run rather than a code slice; its own
  boot/checklist pass is startable now that Slice 19 has landed, but it is
  a session for Dave's hands rather than a queued code slice.
- **HC-5 and HC-6** (`plans/now/hud-controls.md`) -- both edit
  `scripts/gallerin_panel.gd`, and one Claude branch runs at a time; they
  follow HC-4 in order.
- **LAY-5 and LAY-6** (`plans/now/layout-regression.md`) -- the guard rail for
  both layout groups, and startable now that HC-1 and HC-2 have landed, but
  one Claude branch runs at a time; it follows HC-4 in the lane.
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
