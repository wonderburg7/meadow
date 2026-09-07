# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane Claude`
(or `-Lane Codex`) to claim your lane's leading item and open its worktree,
open only the `Plan:` file and heading that item names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`).
Do not read the other lane's plan, the archive, `ROADMAP.md` or Git history
to work out what to do -- the script already decided.

**Hands-on checks are paused (Dave, 4 Sep 2026), and both lanes are now
empty of admissible work because of it.** That rules out every remaining
item in `ui.md`, `challenge-1.md`, `challenge-2.md` and `hive-comb.md`.
FL-2 (the Codex lane's last item) shipped 6 Sep 2026 and named no
successor. PR-A4 (the Claude lane's last item -- Progression Phase A step
4, modifier resolution) shipped 7 Sep 2026 and completed Phase A; its
successor, Phase B step 6, is the first progression work that puts
anything on screen, so it needs the same paused hands-on checks everything
else here is waiting on. Dave is running C-16, C-5 and C-13 now (6 Sep
2026); the first of those to fail becomes the Codex lane's next slice, and
his reply also unpauses Phase B step 6 and the four `ui.md`/`challenge-1.md`/
`challenge-2.md`/`hive-comb.md` items below. **`tools/check_docs.py` will
not pass while both lanes are empty -- this is expected and pending that
reply, not a code defect.**

## Next up

1. **[Claude] -- no admissible item.** PR-A4 (modifier resolution) shipped
   7 Sep 2026, archived at
   `plans/archive/PROGRESSION_PHASE_A_STEP4_2026-09-07.md`, and completed
   Phase A. Its named successor, Phase B step 6 (the foraging tier-1
   vertical slice), needs the tree panel, the HUD button and a
   player-visible acceptance check -- see "Not in the queue, and why".
   No other Claude-lane plan has a slice that does not also need Dave's
   hands-on checks. `tools/check_docs.py` fails while this lane holds no
   item -- expected, and resolved once the checks resume rather than by a
   fabricated entry here.

2. **[Codex] -- no admissible item.** FL-2 shipped 6 Sep 2026 (archived at
   `plans/archive/FLOWERS_SLICE_2_2026-09-06.md`) and named no successor.
   Every other Codex-lane plan (`ui.md`, `challenge-1.md`, `challenge-2.md`,
   `hive-comb.md`) needs a hands-on check or a live repro from Dave first --
   see "Not in the queue, and why" and `checks/ready.md`'s D-1. Dave is
   running C-16, C-5 and C-13 now (6 Sep 2026); the first of those to fail
   becomes this lane's next slice the moment he replies. `tools/check_docs.py`
   fails while this lane holds no item -- expected, and resolved by that
   reply rather than by a fabricated entry here.

## Ready, not yet in the queue

Nothing. Every remaining slice in every owning plan needs a hands-on check
or a live repro from Dave first (see "Not in the queue, and why").

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.
They are listed so they are not lost, not so they are picked up. All are
paused as a group while the filed checks go unrun.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough. C1-15 landed 3 Sep 2026; this is now Dave's run and the last
  thing that plan wants.
- **Challenge 2 Slice 2** (`plans/now/challenge-2.md`) -- fixing whichever
  of the rescue and recovery lines does not appear. C2-1 shipped 3 Sep 2026
  (its "Force Challenge 2 collapse" trigger is `checks/ready.md` C-5); this
  wants Dave to press it and report which line is missing. There is no
  static defect to fix blind, and guessing has already failed twice.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- Slice 4's
  headless trace found the mechanism (every idle Comb Worker piles onto one
  unfinished site), but capping builders per site changes build throughput,
  so it wants Dave's live look and a call on intended behaviour. Slice 5
  wants its own reproduction.
- **UI-P-5 and UI-D** (`plans/now/ui.md`) -- both name two plausible causes
  and say to reproduce the symptom live before changing code. With UI-R-2
  shipped, these two are all that plan has left.
- **Progression Phase B step 6 onwards** (`plans/design/progression.md`) --
  the foraging tier-1 vertical slice is where the tree panel, the HUD button
  and run saving first appear, and its acceptance is something Dave sees.
  Phase A (steps 1-4) is complete precisely because it stops short of it.
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
