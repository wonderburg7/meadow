# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane Claude`
(or `-Lane Codex`) to claim your lane's leading item and open its worktree,
open only the `Plan:` file and heading that item names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`).
Do not read the other lane's plan, the archive, `ROADMAP.md` or Git history
to work out what to do -- the script already decided.

**Current state, after Dave's fourth hands-on pass (9-10 Sep 2026).** Eleven
checks ran, and everything that pass unblocked has now shipped. C1-25, the most
severe finding, landed on 11 Sep 2026: Challenge 1's nectar-discard rule now
names stage 1.14 in its code rather than only in a comment, so the queen keeps
a load the comb cannot take at every earlier stage and is told by Dr Gallerin
on the one stage that does discard it. Its check is C-42.

The pass's other three fixes (HC-13, HC-14 and HC-15) landed on 10 Sep 2026 and
their records are in `plans/archive/`. Thirteen hands-on checks are waiting in
`checks/ready.md`; by rule no queue item is held open for one.

## Next up

1. **[Codex] C1-23 -- Challenge 1's wax cell is full at 150 nectar, not 200.**
   Add a `NECTAR_TARGET` constant beside the existing `POLLEN_TARGET` and
   have the nectar stage's goal check and progress bar use it instead of the
   cell's full 200 capacity, so the queen stops filling it at 150 and the
   nectar stage stays a demonstration rather than a chore.
   - Plan: `plans/now/challenge-1.md` -- "Slice 23 — a Challenge 1 wax cell is full at 150 nectar"
   - Files: `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`
   - Check: one check confirming the nectar stage's goal bar fills and the queen stops at 150, not 200
   - Proof: `absent: scripts/challenge_stages.gd :: NECTAR_TARGET`
   - Next after: C1-24 (the stage marker is never left in the wrong world, at 1.12 and 1.15)

2. **[Claude] HC-16 -- the command tray's height matches its content on a reselection.**
   HC-8 (10 Sep 2026) fixed the tray for the *first* build after a
   selection; reselecting a different bee still leaves it wrong, with or
   without `More…` open -- one traced case left the tray 260px+ taller than
   its content even after 15 settle ticks. HC-8's own measurement found this
   is not a single stale frame but an unpredictable multi-pass Godot timing
   problem, so it needs a high slice, not a medium one -- see the heading's
   diagnostic evidence.
   - Plan: `plans/now/hud-controls.md` -- "HC-16 — the tray's height matches its content on a reselection"
   - Files: `scripts/hud.gd`
   - Check: one check covering a reselection (forager -> queen and the reverse) with More… open and without it, at two text scales
   - Proof: `absent: scripts/hud.gd :: HC-16`
   - Next after: none -- hud-controls.md is complete

3. **[Codex] C1-21 -- the queen forages pollen without being pushed.**
   At the pollen stage she stays put when the player switches her focus to
   Pollen, and only sets off once something else has moved her out of the
   hive. Trace it headlessly first: the standing hypothesis is that the
   nectar she is still carrying routes her to a deposit that does not exist,
   and C1-25 has just made her keep that load rather than lose it, so the
   stall is now the only way it can end. Fix what the trace shows.
   - Plan: `plans/now/challenge-1.md` -- "Slice 21 — the queen forages pollen without being pushed"
   - Files: `scripts/bee.gd`, `scripts/bee_foraging.gd`
   - Check: C-7's pollen half, re-run once she leaves on the focus change alone
   - Proof: `absent: scripts/bee_foraging.gd :: C1-21`
   - Next after: C1-22 (the stage's camera reaches the pollen stage)

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.

- **Challenge 1 Slices 22, 24 and 26** (`plans/now/challenge-1.md`) -- all
  three are specified. Slice 26 (the marker pulses and shows an off-screen
  arrow, both Dave's 10 Sep asks) waits on Slice 24, the other open change to
  the same marker node. Slice 22 is startable on its merits but sits behind
  C1-23 and C1-21 in the same lane, and is queued as C1-21's `Next after:`.
  Slice 24 is next after C1-23 and is queued as its `Next after:`. Slice 21
  itself is no longer held: Slice 20 has landed, so stage 1.13 runs and a
  pollen symptom no longer has that as a sufficient cause.
- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough. Not worth a sixth attempt until Slices 20 to 26 have made the
  pollen arc work unattended.
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
- **UI-P-5** (`plans/now/ui.md`) -- named two plausible causes; a 10 Sep 2026
  headless check ruled both out (the placeholder is present, visible and
  correctly positioned in a fresh boot), so the real cause needs Dave's own
  screen, not more static reading. None of Dave's six passes since 8 Sep has
  reported on it.
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
- **The Codex lifecycle's own success measure** -- CR-1 to CR-7 all shipped by
  9 Sep 2026 and the plan is archived at
  `plans/archive/CODEX_RELIABILITY_2026-09-09.md`, but its stated measure was
  ten throwaway lifecycle exercises including parallel lanes and injected
  failures, and those were never run. It is not a defect and nothing waits on
  it, so it is not a slice; it becomes one only if a lifecycle failure recurs.

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
