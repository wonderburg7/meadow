# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Five ready slices in two lanes, refilled 3 Sep 2026 after P-1 made
`checks/ready.md`'s entry format enforceable. The three `debug_panel.gd`
slices now sit in one lane, in the order `plans/now/check-loop.md` P-3 sets.

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

1. **[Codex] UI-R-2 -- Pre-run menu: the left edge still needs more room.**
   - Plan: `plans/now/ui.md` -- UI-R-2.
   - Does: raises `main_menu.gd`'s `LEFT_PANE_MARGIN` from 16 to 32. One
     constant; nothing about tile size, spacing, centres or hit-testing
     changes, so UI-M and UI-P-3 cannot regress.
   - Files: `scripts/main_menu.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: the left pane
     sits comfortably clear of the screen edge and tile clicking is
     unchanged.
   - Proof: `present: scripts/main_menu.gd :: LEFT_PANE_MARGIN := 16`
   - Next after: FL-2, already fifth in this lane.

2. **[Claude] P-3 -- Developer triggers have no home, and two slices are about to build one each.**
   - Plan: `plans/now/check-loop.md` -- P-3.
   - Does: promotes `debug_panel.gd`'s existing `challenge_row` into a
     labelled "Triggers" group in the developer area -- a small header, one
     `UI.with_info` badge saying everything in the group forces a state that
     is otherwise rare, and the existing "Advance Challenge stage" button
     moved in unchanged. No new trigger, no change to what that button does,
     no change to the developer-area visibility gate.
   - Files: `scripts/debug_panel.gd`.
   - Check: `tools/verify.ps1`. No hands-on check -- nothing a player can see
     changes, and by the check-loop plan's rule 4 a check whose failure would
     change nothing is not filed.
   - Proof: `absent: scripts/debug_panel.gd :: Triggers`
   - Why first in this lane: P-1 landed and its plan's `Next after:` is P-3.
     The plan reversed P-3's order on 3 Sep for a stated reason -- UI-R-3 and
     C2-1 would each write a row into `challenge_row` that P-3 then rewrites,
     and all three own `scripts/debug_panel.gd`, so they cannot run in
     parallel lanes. P-3 builds the empty section; the other two drop one
     button into it.
   - Next after: UI-R-3, third in this lane and now unblocked by this slice.

3. **[Claude] UI-R-3 -- No way to fire a warning-banner case on demand.**
   - Plan: `plans/now/ui.md` -- UI-R-3.
   - Does: adds a second button, "Fire test warnings", to `debug_panel.gd`'s
     Triggers group beside "Advance Challenge stage", styled with the same
     `_style_button` + `UI.with_info` pattern. It calls `hud.show_warning`
     three times off one `SceneTreeTimer` chain -- an epitaph-keyed message
     at t=0, a crab-spider-escape-keyed one at t=+8s and an unkeyed
     confirmation at t=+10s -- using the real `problem_messages.gd` entries
     and `GameConfig` gaps, not literals. Developer section only, so ordinary
     play cannot reach it.
   - Files: `scripts/debug_panel.gd`.
   - Check: `tools/verify.ps1`. It also unblocks `checks/blocked.md`'s C-4;
     move that entry to `checks/ready.md`, keeping its id, when this lands.
   - Proof: `absent: scripts/debug_panel.gd :: Fire test warnings`
   - Why in this lane, not Codex's: it owns the same file as P-3 and has to
     follow it, and `plans/now/check-loop.md` P-3 says all three
     `debug_panel.gd` slices belong in one lane. Moving it here is what keeps
     the two lanes collision-free.
   - Next after: FL-1, fourth in this lane.

4. **[Claude] FL-1 -- The flower panel says nothing about age or season.**
   - Plan: `plans/now/flowers.md` -- Slice 1.
   - Does: `hud.gd::_refresh_flower_summary()` already rebuilds the flower
     summary panel every frame it's open and already prints both effective
     rates, but says nothing about age or season. Builds one extra line --
     age in days against lifespan, and "in season (NN%)" / "out of season" /
     "seasons off" -- and puts it in `trait_label` above the scent-mark text
     (joined with a newline, not replacing it) using `age_seconds`,
     `lifespan_seconds` and `season_strength()`, all already public on
     `flower.gd`. Nothing new is computed in `flower.gd`.
   - Files: `scripts/hud.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: click a flower
     and the panel shows its age against its lifespan and whether it's in
     or out of season; watching one across a season boundary flips the line
     at the same moment the `+/s` figures fall away.
   - Proof: `absent: scripts/hud.gd :: season_strength`
   - Why here, not leading: it shares `scripts/hud.gd` with UI-S-4, the
     leading Codex item, so it sits below the lane's head rather than at it --
     promoting it would make both lanes' leading items collide. Landing
     either it or UI-S-4 clears the pairing.
   - Next after: FL-2 (`plans/now/flowers.md` Slice 2) -- a balance change,
     with its named headless run to quote before it merges.

5. **[Codex] FL-2 -- Out of season means "barely", not "not at all".**
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
   - Why here: it has no dependency on FL-1 and shares no file with the
     current Claude work; the plan makes its required headless comparison
     explicit before merge.
   - Next after: none -- this plan then has no open slice.

## Ready, not yet in the queue

All of these can be started today; they are out of the queue only because it
holds five. Take one when a lane empties, in roughly this order.

- **FL-2** (`plans/now/flowers.md` Slice 2) -- out of season means a small
  non-zero rate, faster ageing and rarer seeding. A balance change: it needs
  its named headless run before it merges.
- **C2-1** (`plans/now/challenge-2.md` Slice 1) -- a debug button that forces
  a Challenge 2 nectar collapse, so C-5 can be run at all. It drops into
  P-3's Triggers group, so take it in the same lane, after P-3.

## Not in the queue, and why

Each of these needs something from Dave, or something else to ship first.
They are listed so they are not lost, not so they are picked up.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough. C1-15 landed 3 Sep 2026; this is now Dave's run and the last
  thing that plan needs.
- **Challenge 2 Slice 2** (`plans/now/challenge-2.md`) -- fixing whichever
  of the rescue and recovery lines does not appear. Needs C2-1 to ship and
  Dave to press the button; there is no static defect to fix blind, and
  guessing has already failed twice.
- **check-loop P-2** (`plans/now/check-loop.md`) -- the panel-rect source
  check runs after UI-S-1 and UI-S-2 move the numbers. P-3 is no longer here:
  its plan reversed the order on 3 Sep, so it now runs *before* UI-R-3 and
  C2-1 rather than collecting after them, and it leads the Claude lane.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- Slice 4's
  headless trace found the mechanism (every idle Comb Worker piles onto one
  unfinished site), but capping builders per site changes build throughput,
  so it needs Dave's live look and a call on intended behaviour. Slice 5
  needs its own live repro.
- **UI-P-5 and UI-D** (`plans/now/ui.md`) -- both name two plausible causes
  and say to reproduce live before changing code.
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
