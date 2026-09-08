# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane Claude`
(or `-Lane Codex`) to claim your lane's leading item and open its worktree,
open only the `Plan:` file and heading that item names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`).
Do not read the other lane's plan, the archive, `ROADMAP.md` or Git history
to work out what to do -- the script already decided.

**Dave's 9 Sep 2026 hands-on pass refilled the Claude lane, and LAY-2 and
LAY-3 have now landed.** C-4, C-27 and C-28 passed and are archived. C-18,
C-19 and C-26 failed and became LAY-2 to LAY-4 in `plans/now/panel-layout.md`;
C-7 and C-5 could not be run at all, because both need the command tray's
buttons, and moved to `checks/blocked.md`. LAY-2 shipped 2026-09-09
(`plans/archive/LAY-2_2026-09-09.md`), re-filing C-18 and unblocking C-7 and
C-5 back into `checks/ready.md`. LAY-3 shipped the same day
(`plans/archive/LAY-3_2026-09-09.md`), re-filing C-19. LAY-4 leads the Claude
lane now.

The command tray had escaped the viewport on four separate passes. The cause
was found on 9 Sep and is written up in `plans/now/panel-layout.md`, "Why
this kept coming back": `Control.set_size()` rewrites all four anchor offsets
from the cached position, so giving a bottom-anchored panel a height converts
its bottom pin into a top pin and the panel regrows downwards off the screen.
LAY-2 removed that; LAY-5 in `plans/now/layout-regression.md` adds the
headless assertion that would have caught it the first time.

Every item below is specified down to the function and the line, because each
one was diagnosed against the source during the 9 Sep pass.

## Next up

1. **[Codex] CR-2 -- make the standard runtime self-discovering.**
   Verification should locate Codex's bundled Python without a PATH edit;
   closeout keeps an explicit override, and `doctor` reports every runtime,
   Git-identity, ownership, remote and metadata-write failure in one pass.
   - Plan: `plans/now/codex-reliability.md` -- "CR-2 — make the standard runtime self-discovering"
   - Files: `tools/verify.ps1`, `tools/slice.ps1`,
     `tests/test_source_checks.py`, `.codex/config.toml`,
     `plans/now/codex-reliability.md`
   - Check: deterministic tooling tests and `tools/verify.ps1` with no PATH edit
   - Proof: `absent: tools/verify.ps1 :: codex-primary-runtime`
   - Next after: CR-3 (align permissions with the intended Git lifecycle)

2. **[Codex] Challenge 2 Slice 2 -- the collapse button does what its tooltip says.**
   The button picks its target from the nectar currently in the hive, which
   the rescue has just topped up by 150, so the second press does nothing and
   the third is the one that reaches the failure floor. Count presses instead.
   The rescue line also needs `clear_queue()` before `show_now()`, or the
   stage's next hint overwrites it.
   - Plan: `plans/now/challenge-2.md` -- "Slice 2 — the collapse button does what its tooltip says, and the rescue line survives"
   - Files: `scripts/debug_panel.gd`, `scripts/challenge_runner.gd`, `scripts/gallerin_panel.gd`
   - Check: C-5, now runnable in `checks/ready.md` since LAY-2 restored the tray
   - Proof: `absent: scripts/debug_panel.gd :: _c2_collapse_presses`
   - Next after: none -- `plans/now/challenge-2.md` is complete once this lands

3. **[Claude] LAY-4 -- the nursery donut's key clears the scrollbar.**
   `_draw_ring()` draws the legend at literal x positions inside a literal
   300px box, so at a large text scale the Nursery window's scrollbar covers
   its right-hand end. Measure the legend with the current font and reserve a
   shared scrollbar gutter.
   - Plan: `plans/now/panel-layout.md` -- "LAY-4 — the nursery donut's key clears the scrollbar"
   - Files: `scripts/nursery_panel.gd`, `scripts/ui_layout.gd`,
     `plans/now/panel-layout.md`
   - Check: re-file C-26
   - Proof: `absent: scripts/ui_layout.gd :: SCROLLBAR_GUTTER`
   - Next after: LAY-5 (the headless panel-rectangle assertion)

## Ready, not yet in the queue

These are fully specified and could be started today; they are out of the
queue only because it is capped at five. Promote them as the lanes drain, in
this order.

- **LAY-5 -- a headless check that fails when a persistent panel leaves the
  viewport** (`plans/now/layout-regression.md`). The guard rail for the whole
  LAY group: a `viewport_size` scenario verb, a `panel_rect` assertion, one
  fixture covering 1920x1080, 1280x720 and 800x600, and a test in `tests/`
  that skips cleanly where Godot is not installed. Its acceptance is to
  reintroduce LAY-2's bug on purpose and watch the check fail. It follows
  LAY-4 so it is written against shipped behaviour.

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.

- **SB-1 and SB-2** (`plans/now/season-balance.md`) -- CR-6 must first prove
  the bounded baseline simulation succeeds. SB-1 then returns with exact
  `Files:` and `Proof:` values that pass `slice.ps1 doctor`; SB-2 follows it.
- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough, and Dave's run rather than a code slice. It needs C-7, which
  is back in `checks/ready.md` now that LAY-2 has restored the command tray's
  Job button.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- Slice 4's
  headless trace found the mechanism (every idle Comb Worker piles onto one
  unfinished site), but capping builders per site changes build throughput,
  so it wants Dave's live look and a call on intended behaviour. Slice 5
  wants its own reproduction.
- **UI-P-5** (`plans/now/ui.md`) -- names two plausible causes and says to
  reproduce the symptom live before choosing between them. None of Dave's
  three passes since 8 Sep has reported on it.
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
