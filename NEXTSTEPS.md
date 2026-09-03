# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Two ready slices in two lanes. CD-1 shipped 4 Sep 2026; its plan
(`colony-diagnostics.md`) turned out to have no further slice -- section 6
explicitly defers migrating any other colony-state read until a second
consumer needs the same fact, so there was nothing to promote in its place.
Every other open plan (`ui.md`, `challenge-1.md`, `challenge-2.md`,
`check-loop.md`, `hive-comb.md`, `flowers.md`, `progression.md`) was checked
and its remaining work wants Dave's hands-on pass, a live repro, or a product
decision -- which is exactly what does not belong in this list. The two
below are the whole of what a model can start today.

`tools/check_docs.py`'s queue-size check accepts two to five items. It was
five until 3 Sep 2026, when Dave relaxed it to four; the floor moved to three
the same day, for the same reason, when UI-R-2 landed and no plan had a
genuinely ready slice to promote. It moved to two on 4 Sep 2026, for the same
reason again, when CD-1 landed with nothing to replace it -- flagged to Dave
for review rather than held for a check-in, since the session was running
unattended. **The queue is now as dry as it gets without stalling a lane:
once FL-2 and P-2 land, refilling it takes Dave's Challenge 1 acceptance run
and his Challenge 2 collapse-trigger press (`checks/ready.md` C-5), not more
planning.**

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

2. **[Claude] check-loop P-2 -- one owner for panel rectangles, enforced.**
   - Plan: `plans/now/check-loop.md` -- P-2.
   - Does: adds a check to `tests/source_checks.py`, in the style of the
     existing `GameConfig` write allowlist, that fails on any numeric
     literal assigned to `offset_top`/`offset_left`/`offset_right`/
     `offset_bottom` in `hud.gd`, `colony_panel.gd`, `foraging_panel.gd`,
     `nursery_panel.gd`, `gallerin_panel.gd` or `debug_panel.gd`. A trailing
     `# fixed-inset` comment or a value read from `UiLayout` is allowed; the
     message names the file, line and `ui_layout.gd` as where the number
     belongs.
   - Files: `tests/source_checks.py`.
   - Check: `tools/verify.ps1`, including a deliberate break (a literal
     `offset_top = 60` in `colony_panel.gd`) and repair.
   - Proof: `absent: tests/source_checks.py :: fixed-inset`
   - Why here: UI-S-1 and UI-S-2, the panel-rect moves this check locks in,
     both shipped 3 Sep 2026, so the plan's last open slice is now startable.
     `tests/source_checks.py` collides with no other queued file.
   - Next after: none -- this plan then has no open slice.

## Ready, not yet in the queue

Nothing. Every slice that could be started today is in the queue above,
which is why it sits at two rather than five (see the note at the top of
this file). The next slot refills from an owning plan the moment a plan
below has real ready work again -- which, for all of them, means Dave
running something first.

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
- **Progression Phase A** (`plans/design/progression.md`) -- designed, not
  scheduled; parked behind the settings-catalogue work by Dave's 1 Sep call.

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
