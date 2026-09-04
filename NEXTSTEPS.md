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
`tools/verify.ps1` alone. Steps 1 and 2 landed on 4 Sep 2026 as PR-A1 and
PR-A2; the remaining three each become startable as its predecessor lands, so
the queue promotes them one at a time rather than listing two items nobody
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

1. **[Claude] PR-A3 -- Run-definition fields.**
   - Plan: `plans/design/progression.md` -- section 11, Phase A step 3, with
     section 4.1 for Challenge policy overriding mastered ownership and
     section 4.5 for what "permitted by the run/Challenge stage" means.
     Minimum reasoning: medium.
   - Does: adds `skill_grants`/`skill_bans`/`skill_delays` to the existing
     run-definition shape in `levels.gd` and `challenge_runner.gd`, and
     reads them inside `progression.gd`'s `is_permitted()`, which PR-A2 left
     as the single place run policy lands. Challenges 1 and 2 keep working
     unchanged while the three fields are empty, so no run behaves
     differently.
   - Files: `scripts/levels.gd`, `scripts/challenge_runner.gd`,
     `scripts/progression.gd`, `tests/source_checks.py`.
   - Check: `tools/verify.ps1`, extended so a run definition naming a skill
     that is not in `skills.gd` fails, and so a granted skill and a banned
     one are proved to override ownership and the stage gate in the right
     order. Plus a Godot boot, since `challenge_runner.gd` is loaded at
     runtime. No player check: with the fields empty nothing on screen
     changes, and a Challenge that does use them is Phase B step 6's work.
   - Proof: `absent: scripts/levels.gd :: skill_grants`
   - Why here: PR-A2 landed 4 Sep 2026 and named this as its `Next after:`.
     The resolver exists with a deliberate hole where run policy goes, which
     is exactly the gap this closes; it shares no file with the Codex lane.
   - Next after: PR-A4 -- modifier resolution and validation (section 11,
     Phase A step 4), which adds effective-value lookup to the resolver and
     section 9.2's remaining validation groups, still without `GameConfig`
     ever being written.

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
PR-A4 (modifier resolution and section 9.2's remaining validation) and PR-B5
(`Shapes.hex_line` plus the ring and wedge rules) -- are each written against
the thing before them, so each is promoted into the lane as its predecessor
merges rather than listed here as startable. PR-A4 in particular waits on
data that does not exist: every `effects` array in `skills.gd` is empty, and
the slice that fills them is the one that also resolves them. PR-B5 has the
opposite problem solved for it -- PR-A1 authored every node's axial
coordinate, so that slice validates coordinates rather than inventing them.

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
