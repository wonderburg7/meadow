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
`challenge-1.md`, `challenge-2.md` and `hive-comb.md`; they are listed at the
bottom, not mixed in above. What is left that needs nothing from Dave is
**Progression Phase B step 5** (`plans/design/progression.md` section 11) --
plumbing, no gameplay change, proved by `tests/` rather than by playing.
Phase A steps 1, 2 and 3 landed 4 and 6 Sep 2026 as PR-A1, PR-A2 and PR-A3;
step 4 is deferred deliberately (see "Ready, not yet in the queue" below).
Phase B step 6 is the first progression work that puts anything on screen,
so it stays out until the checks resume.

Everything under `## Next up` can be started today. `tools/check_docs.py`
accepts two to five items and requires both lanes to hold work.

## Next up

1. **[Claude] PR-B5 -- Grid geometry.**
   - Plan: `plans/design/progression.md` -- section 11, Phase B step 5, with
     sections 8.1 to 8.3 for the ring, wedge and connect-tile rules.
     Minimum reasoning: low.
   - Does: adds `Shapes.hex_line(a, b)` -- a standard cube-coordinate lerp
     and round, beside the existing hex helpers -- and section 9.2's grid
     validation group over the axial coordinates PR-A1 already authored:
     every skill tile's ring equals `2 * tier + 1`, its coordinate resolves
     to its declared sector by the wedge rule, no two nodes share a
     coordinate, and no generated connect tile lands on a skill coordinate.
     No panel, no gameplay change.
   - Files: `scripts/shapes.gd`, `tests/source_checks.py`.
   - Check: `tools/verify.ps1`. No player check and no Godot boot needed --
     nothing loads the new function at runtime yet, and the validators run
     in Python over the catalogue.
   - Proof: `absent: scripts/shapes.gd :: hex_line`
   - Why here: it is startable today and always was. PR-A1 authored the
     coordinates, so this validates data rather than inventing it, and it
     depends on nothing in PR-A3 or PR-A4. PR-A3 landed 6 Sep 2026 and named
     this as its `Next after:`; it shares no file with the Codex lane.
   - Next after: PR-A4 -- modifier resolution (section 11, Phase A step 4),
     which adds effective-value lookup to the resolver and section 9.2's
     reachability group, still without `GameConfig` ever being written.

2. **[Codex] FL-2 -- Out of season means "barely", not "not at all".**
   - Plan: `plans/now/flowers.md` -- Slice 2.
   - Does: gives out-of-season flowers a small recharge floor, faster ageing
     and rarer seeding, using three explicit `GameConfig` balance values.
   - Files: `scripts/game_config.gd`, `scripts/flower.gd`,
     `scripts/flower_species.gd`.
   - Check: `tools/verify.ps1`, plus baseline and branch runs of
     `test_scenarios/slice8_senescence_on_seed12345_test.json` as specified
     in the plan. One player check to file: the year-round species mix
     visibly follows the seasons without collapsing.
   - Proof: `absent: scripts/game_config.gd :: out_of_season_strength`
   - Why here: UI-R-2 shipped 3 Sep 2026 and this was already queued behind
     it as its `Next after:`; it shares no file with the Claude lane.
   - Next after: none -- this plan then has no open slice.

## Ready, not yet in the queue

Nothing. PR-A4 is the Claude lane's only remaining successor and is deferred
deliberately rather than for lack of readiness: it authors effect magnitudes,
and section 11 schedules it last of the three so it runs closest to step 6,
which is what will prove them. Its `effects` scope is bounded there to the
two foraging tier-1 nodes that map onto shipped `GameConfig` toggles, so it
is transcription rather than a second set of guessed numbers.

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
