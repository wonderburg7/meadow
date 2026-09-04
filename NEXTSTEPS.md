# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

**Hands-on checks are paused (Dave, 4 Sep 2026).** Everything in
`checks/ready.md` stays filed and unrun, so no slice that depends on one may
enter the queue. That ruled out every remaining item in `ui.md`,
`challenge-1.md`, `challenge-2.md` and `hive-comb.md` -- all four want Dave
to run something first -- and left exactly one body of ready work that needs
nothing from him: **Progression Phase A** (`plans/design/progression.md`
section 11), whose four steps are explicitly "plumbing, no gameplay change"
and are proved by `tests/`, not by playing.

Dave's instruction to fill the queue with work that does not wait on him is
read here as scheduling Phase A, and nothing beyond it: the parked item under
"Not in the queue" that said Phase A was a scheduling decision rather than a
technical gate is now taken as made. Phase B's vertical slice (step 6) is the
first progression work that puts anything on screen, so it stays out of the
queue until the checks resume.

**The runway, so it is clear how far this goes.** Phase A steps 1-4
(catalogue, resolver, run-definition fields, modifier resolution and
validation) and Phase B step 5 (the `Shapes.hex_line` helper and the grid
rules, pure maths) are five consecutive Claude slices that each finish on
`tools/verify.ps1` alone. Each becomes startable as its predecessor lands, so
the queue promotes them one at a time rather than listing four items nobody
can begin today.

**Everything in `## Next up` can be started right now.** Work that wants
something from Dave is under "Not in the queue" at the bottom, with a
pointer, and is deliberately not mixed in above.

`tools/check_docs.py`'s queue-size check accepts two to five items. Two is
correct here: each lane holds the one item it can actually begin.

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane
Claude` (or `-Lane Codex`) to claim the lane's leading item and open its
worktree, open only the `Plan:` file and heading it names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`,
"End-of-slice report"). Do not read the other lane's plan, the archive,
`ROADMAP.md` or Git history to work out what to do -- the script already
decided.

## Next up

1. **[Claude] PR-A1 -- Progression catalogue inventory.**
   - Plan: `plans/design/progression.md` -- section 11, Phase A step 1, with
     section 3 for each file's shape and section 5 for the node list.
     Minimum reasoning: medium.
   - Does: writes `skills.gd`, `adaptations.gd` and `features.gd` as static
     catalogue data on `roles.gd`'s shape -- stable IDs per section 3's
     convention, the baseline entries (5.7) and the open nodes (5.9) carried
     as data with empty effects. Nothing reads them yet, so the change is
     additive and cannot alter a running game.
   - Files: `scripts/skills.gd`, `scripts/adaptations.gd`,
     `scripts/features.gd`, `tests/source_checks.py`.
   - Check: `tools/verify.ps1`, extended with section 9.2's
     catalogue-integrity checks in `tests/source_checks.py` -- duplicate or
     missing IDs, references to absent entries, prerequisite cycles,
     `max_rank > 1`, a display string used as a key. No player check: the
     data draws nothing.
   - Proof: `absent: tests/source_checks.py :: skills.gd`
   - Why here: it is the one piece of ready work that finishes on
     `verify.ps1` alone while the filed checks sit unrun, and it shares no
     file with the Codex lane. `plans/README.md` guardrail 5 fixes it as
     first in the progression order.
   - Next after: PR-A2 -- the thin resolver (section 11, Phase A step 2),
     which answers ownership, afford and feature-validity against these
     catalogues and `stage_gate.gd`, proved in `tests/` against the existing
     foraging toggles rather than in-game.

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

Nothing that a session could open today. The Claude lane's successors --
PR-A2 (resolver), PR-A3 (run-definition fields in `levels.gd` and
`challenge_runner.gd`), PR-A4 (modifier resolution and section 9.2's
remaining validation) and PR-B5 (`Shapes.hex_line` plus the ring and wedge
rules) -- are each written against the thing before them, so each is promoted
into the lane as its predecessor merges rather than listed here as startable.

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
  Steps 1-5 above are queued precisely because they stop short of it.
- **Save/load during an active Challenge** -- a settled design decision, not
  a defect. `DESIGN_BACKLOG.md` § "Deferred product decisions" holds it; it is
  not restated here.

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
