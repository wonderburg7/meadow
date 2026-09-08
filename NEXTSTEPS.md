# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane Claude`
(or `-Lane Codex`) to claim your lane's leading item and open its worktree,
open only the `Plan:` file and heading that item names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`).
Do not read the other lane's plan, the archive, `ROADMAP.md` or Git history
to work out what to do -- the script already decided.

**Dave ran a full hands-on pass on 8 Sep 2026 and both lanes are stocked
again.** Fourteen checks went out; eleven came back confirmed and are
archived, three failed, and two could not be run because of the command tray
running off the bottom of the screen. Every item below is specified down to
the function and the line, because each one was diagnosed against the source
during that pass -- the plan sections say what to change and what not to
touch, so no slice below needs a fresh investigation.

## Next up

1. **[Claude] UI-Q-3 -- a message may not be cut to a fraction of its dwell.**
   Dave timed the three test warnings at ~6s, ~1-2s and ~12s; the second was
   cut short because "Run saved." arrived two seconds later and took the
   banner. Give each message a minimum dwell and a severity: a lower- or
   equal-severity message arriving inside another's minimum dwell queues
   behind it, a strictly higher-severity one still pre-empts immediately.
   - Plan: `plans/now/ui-bottom-row.md` -- "UI-Q-3 — a message may not be cut to a fraction of its dwell"
   - Files: `scripts/hud.gd`
   - Check: re-file C-4 against the new dwell rule
   - Proof: `absent: scripts/hud.gd :: min_dwell`
   - Next after: none named -- pull the next ready Claude-lane slice from an owning plan when this lands

2. **[Codex] SB-1 -- peak-season production is a rise, not a spike.**
   - Plan: `plans/now/season-balance.md` -- "SB-1 — peak-season production is a rise, not a spike"
   - Files: see the named plan heading
   - Check: file C-24
   - Proof: see the named plan heading
   - Next after: SB-2 (out-of-season species have a standing presence)

## Ready, not yet in the queue

These are fully specified and could be started today; they are out of the
queue only because it is capped at five. Promote them as the lanes drain, in
this order.

- **SB-2** (`plans/now/season-balance.md`) -- out-of-season species seed at
  0.15 of their usual weight, which reads as a standing presence rather than
  a rarity. One value. Codex lane, after SB-1 (same file).

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough, and Dave's run rather than a code slice. UI-T-1 shipped
  2026-09-08, so C-7 (`checks/ready.md`) can now be run; this waits on that.
- **Challenge 2 Slice 2** (`plans/now/challenge-2.md`) -- fixing whichever of
  the rescue and recovery lines does not appear. UI-T-1 shipped 2026-09-08,
  so C-5 (`checks/ready.md`) can now be run; nothing can be written here
  until it is, and guessing has already failed twice.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- Slice 4's
  headless trace found the mechanism (every idle Comb Worker piles onto one
  unfinished site), but capping builders per site changes build throughput,
  so it wants Dave's live look and a call on intended behaviour. Slice 5
  wants its own reproduction.
- **UI-P-5** (`plans/now/ui.md`) -- names two plausible causes and says to
  reproduce the symptom live before choosing between them. Dave's 8 Sep pass
  did not report on it. UI-D is now closed: C-3 passed on 8 Sep 2026.
- **Progression Phase B step 6 onwards** (`plans/design/progression.md`) --
  the foraging tier-1 vertical slice is where the tree panel, the HUD button
  and run saving first appear. Phase A (steps 1-4) is complete precisely
  because it stops short of it. Its acceptance is something Dave sees, so it
  wants a clear run of the UI work above rather than to compete with it.
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
