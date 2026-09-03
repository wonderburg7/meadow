# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

**The Claude lane is empty.** CD-1 shipped 4 Sep 2026 with no further slice
in its plan; P-2 shipped the same day and closed out `check-loop.md`'s last
open slice too (now `plans/reference/check-loop.md`, reference only). Every
other open plan (`ui.md`, `challenge-1.md`, `challenge-2.md`, `hive-comb.md`,
`flowers.md`, `progression.md`) was checked and its remaining work wants
Dave's hands-on pass, a live repro, or a product decision -- which is
exactly what does not belong in this list, and exactly why nothing was
promoted into the empty slot instead of inventing one. This is a genuine
stop, surfaced rather than papered over: `tools/check_docs.py` will report
"no [Claude] item" until Dave either does one of the things below, or
decides the Claude lane sits idle until Codex's FL-2 lands and opens
something new. This was not resolved by relaxing the check further --
unlike the queue-size floor (below), "both lanes must have work" is what
lets two sessions run in parallel without collision, and loosening it is
Dave's call, not something to decide unattended.

The fastest unblocks, in order of effort: (1) reply to one of the four
items under "Not in the queue" below with the evidence it is waiting on --
a live repro, a hands-on-check result, or a press of a developer trigger;
(2) greenlight Progression Phase A (`plans/design/progression.md`), parked
by product-scope choice rather than a technical gate; (3) accept the idle
lane and let Codex's FL-2 run alone for now.

`tools/check_docs.py`'s queue-size check accepts two to five items -- moot
while a lane is empty, but left at two rather than reverted to three, since
that relaxation (3 Sep 2026, then again 4 Sep 2026) is independent of this
one and still correctly describes the queue once a Claude item exists again.

**Everything in this file can be started right now.** Nothing here is waiting
on a hands-on check, a live repro, or a decision from Dave. Work that *is*
waiting is listed under "Not in the queue" at the bottom, with a pointer, and
is deliberately not mixed in above.

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane
Claude` (or `-Lane Codex`) to claim the lane's leading item and open its
worktree, open only the `Plan:` file and heading it names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`,
"End-of-slice report"). Do not read the other lane's plan, the archive,
`ROADMAP.md` or Git history to work out what to do -- the script already
decided.

## Next up

1. **[Codex] FL-2 -- Out of season means "barely", not "not at all".**
   - Plan: `plans/now/flowers.md` -- Slice 2.
   - Does: gives out-of-season flowers a small recharge floor, faster ageing
     and rarer seeding, using three explicit `GameConfig` balance values.
   - Files: `scripts/game_config.gd`, `scripts/flower.gd`,
     `scripts/flower_species.gd`.
   - Check: `tools/verify.ps1`, plus baseline and branch runs of
     `test_scenarios/slice8_senescence_on_seed12345_test.json` as specified
     in the plan. One hands-on check to file: the year-round species mix
     visibly follows the seasons without collapsing.
   - Proof: `absent: scripts/game_config.gd :: out_of_season_strength`
   - Why here: UI-R-2 shipped 3 Sep 2026 and this was already queued behind
     it as its `Next after:`; it shares no file with the Claude lane.
   - Next after: none -- this plan then has no open slice.

## Ready, not yet in the queue

Nothing. The Claude lane is empty (see the note at the top of this file);
the Codex lane's only item is already in the queue above. The next slot
refills from an owning plan the moment a plan below has real ready work
again -- which, for all of them, means Dave running something first.

## Not in the queue, and why

Each of these needs something from Dave, or something else to ship first.
They are listed so they are not lost, not so they are picked up.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough. C1-15 landed 3 Sep 2026; this is now Dave's run and the last
  thing that plan needs.
- **Challenge 2 Slice 2** (`plans/now/challenge-2.md`) -- fixing whichever
  of the rescue and recovery lines does not appear. C2-1 shipped 3 Sep 2026
  (its "Force Challenge 2 collapse" trigger is `checks/ready.md` C-5); this
  now waits on Dave to press it and report which line is missing. There is
  no static defect to fix blind, and guessing has already failed twice.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- Slice 4's
  headless trace found the mechanism (every idle Comb Worker piles onto one
  unfinished site), but capping builders per site changes build throughput,
  so it wants Dave's live look and a call on intended behaviour. Slice 5
  wants its own live repro.
- **UI-P-5 and UI-D** (`plans/now/ui.md`) -- both name two plausible causes
  and say to reproduce live before changing code. With UI-R-2 shipped, these
  two are all that plan has left.
- **Save/load during an active Challenge** -- a settled design decision, not
  a defect. `DESIGN_BACKLOG.md` § "Deferred product decisions" holds it; it is
  not restated here.
- **Progression Phase A** (`plans/design/progression.md`) -- `product-scope.md`
  §5.3 categorises the whole skill tree as "designed, not scheduled": product
  direction exists but has not entered `NEXTSTEPS.md`. The settings-catalogue
  work this was originally parked behind (Dave's 1 Sep call) has since
  shipped, but that does not by itself promote it -- entering the queue is a
  scheduling decision, not a dependency that just cleared.

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
