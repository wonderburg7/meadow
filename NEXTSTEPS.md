# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane Claude`
(or `-Lane Codex`) to claim your lane's leading item and open its worktree,
open only the `Plan:` file and heading that item names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`).
Do not read the other lane's plan, the archive, `ROADMAP.md` or Git history
to work out what to do -- the script already decided.

**Hands-on checks are paused (Dave, 4 Sep 2026),** so no slice that depends
on one may enter the queue. That rules out every remaining item in `ui.md`,
`challenge-1.md`, `challenge-2.md` and `hive-comb.md`. FL-2 (the Codex
lane's last item) shipped 6 Sep 2026 and named no successor, which leaves
the Codex lane with nothing admissible -- see the note in its place below
and `checks/ready.md`'s D-1. Dave is running C-16, C-5 and C-13 now
(6 Sep 2026); the first of those to fail becomes the Codex lane's next
slice. **`tools/check_docs.py` will not pass while that lane is empty --
this is expected and pending that reply, not a code defect.** What is
left that needs nothing from Dave is **Progression Phase A step 4**
(`plans/design/progression.md` section 11) -- plumbing, no gameplay change,
proved by `tests/` rather than by playing. Phase A steps 1-3 landed 4 and
6 Sep 2026 as PR-A1, PR-A2 and PR-A3; Phase B step 5 landed 7 Sep 2026 as
PR-B5, which is what makes step 4 the correctly scheduled next step (section
11's "scheduled order is 3, then 5, then 4"), not merely next in the
numbering. Phase B step 6 is the first progression work that puts anything
on screen, so it stays out until the checks resume.

## Next up

1. **[Claude] PR-A4 -- Modifier resolution.**
   - Plan: `plans/design/progression.md` -- section 11, Phase A step 4, with
     section 3's resolver design for source-tracked modifiers.
     Minimum reasoning: medium.
   - Does: adds effective-value lookup to `progression.gd` -- base
     `GameConfig` plus additive and multiplicative modifiers with source
     tracking -- and section 9.2's reachability validation group. Authors
     `effects` only for Tarsal secretions and Orientation flight, the two
     foraging tier-1 nodes whose behaviour already ships as `GameConfig`
     toggles, so it is transcription rather than a guessed magnitude. Every
     other node's `effects` stays `[]`. `GameConfig` itself is never
     written, matching `progression.gd`'s existing write ban.
   - Files: `scripts/progression.gd`, `scripts/skills.gd`,
     `tests/source_checks.py`.
   - Check: `tools/verify.ps1`. No player check needed -- nothing calls the
     new lookup at runtime yet; proven by `tests/` over the resolver and
     catalogue. A Godot headless parse check is still worth running since
     `progression.gd` changes (section 11's note on that file).
   - Proof: `absent: scripts/progression.gd :: effective_value`
   - Why here: it is startable today. PR-B5 (grid geometry) landed 7 Sep
     2026 and named this as its `Next after:` -- section 11's scheduled
     order puts step 4 immediately after step 5, and it shares no file
     with PR-B5's `shapes.gd`/`source_checks.py` change or with the Codex
     lane.
   - Next after: Phase B step 6 (the foraging tier-1 vertical slice) is
     the plan's next step, but it needs the tree panel and a player-visible
     acceptance check, so it stays paused with the rest of "Not in the
     queue, and why" below until Dave's hands-on checks resume.

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

Nothing. PR-A4 was the Claude lane's only remaining Phase A/B successor and
is now the queue's head (above); Phase B step 6 is next after it but needs
the hands-on checks that are paused (see "Not in the queue, and why").

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.
They are listed so they are not lost, not so they are picked up. The first
four are paused as a group while the filed checks go unrun.

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
  Steps 3, 4 and 5 are queued precisely because they stop short of it.
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
